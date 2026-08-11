import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';

class ReceiptSupabaseRepository implements ReceiptRepository {
  ReceiptSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();

  @override
  Future<Result<Receipt>> uploadReceipt({
    required String roomId,
    required String localPath,
    required double totalAmount,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    if (totalAmount <= 0) {
      return const Failed(ValidationFailure('Enter receipt total.'));
    }

    try {
      final member = await _client
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      if (member == null) return const Failed(PermissionFailure());

      final storagePath = '$roomId/${_uuid.v4()}.jpg';
      await _client.storage.from('receipts').upload(
            storagePath,
            File(localPath),
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      await _client.from('receipts').upsert({
        'room_id': roomId,
        'storage_path': storagePath,
        'total_amount': totalAmount,
        'uploaded_by': userId,
        'status': SupabaseMappers.receiptStatusToDb(ReceiptStatus.uploaded),
      });

      await _client.from('rooms').update({
        'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.costReview),
      }).eq('id', roomId);

      // Best-effort seed of cost draft (host RLS may block non-host writers).
      try {
        await _seedCostDraft(roomId: roomId, receiptTotal: totalAmount);
      } catch (_) {}

      return Success(
        Receipt(
          roomId: roomId,
          status: ReceiptStatus.uploaded,
          localPath: localPath,
          totalAmount: totalAmount,
          uploadedBy: userId,
        ),
      );
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<Receipt>> skipReceipt(String roomId) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final member = await _client
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      if (member == null) return const Failed(PermissionFailure());

      final orders = await _loadSubmittedOrders(roomId);
      if (orders.isEmpty) {
        return const Failed(
          ValidationFailure('No submitted orders to split.'),
        );
      }

      final ordersTotal =
          orders.fold<double>(0, (s, o) => s + o.subtotal);

      await _client.from('receipts').upsert({
        'room_id': roomId,
        'total_amount': ordersTotal,
        'uploaded_by': userId,
        'status': SupabaseMappers.receiptStatusToDb(ReceiptStatus.skipped),
        'storage_path': null,
      });

      // Each person pays own subtotal — no extras / receipt delta.
      final shares = orders
          .map(
            (o) => {
              'room_id': roomId,
              'user_id': o.userId,
              'order_subtotal': o.subtotal,
              'extras_share': 0,
              'adjustment': 0,
              'final_amount': o.subtotal,
            },
          )
          .toList();

      await _client.from('cost_shares').upsert({
        'room_id': roomId,
        'receipt_total': ordersTotal,
        'expected_orders_total': ordersTotal,
        'delivery_fee': 0,
        'service_fee': 0,
        'tax': 0,
        'discount': 0,
        'other_fee': 0,
        'confirmed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _client
          .from('participant_shares')
          .delete()
          .eq('room_id', roomId);
      await _client.from('participant_shares').insert(shares);

      await _client.from('payments').upsert(
        [
          for (final o in orders)
            {
              'room_id': roomId,
              'user_id': o.userId,
              'amount': o.subtotal,
              'paid': false,
              'payment_requested': false,
            },
        ],
        onConflict: 'room_id,user_id',
      );

      await _client.from('rooms').update({
        'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.paymentSummary),
      }).eq('id', roomId);

      return Success(
        Receipt(
          roomId: roomId,
          status: ReceiptStatus.skipped,
          totalAmount: ordersTotal,
          uploadedBy: userId,
        ),
      );
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<Receipt> watchReceipt(String roomId) {
    return _client
        .from('receipts')
        .stream(primaryKey: ['room_id'])
        .eq('room_id', roomId)
        .map((rows) {
          if (rows.isEmpty) {
            return Receipt(roomId: roomId, status: ReceiptStatus.none);
          }
          final r = rows.first;
          return Receipt(
            roomId: roomId,
            status: SupabaseMappers.receiptStatusFromDb(
              r['status'] as String?,
            ),
            localPath: r['storage_path'] as String?,
            totalAmount: r['total_amount'] == null
                ? null
                : SupabaseMappers.asDouble(r['total_amount']),
            uploadedBy: r['uploaded_by'] as String?,
          );
        });
  }

  Future<List<_OrderSubtotal>> _loadSubmittedOrders(String roomId) async {
    final orders = await _client
        .from('orders')
        .select('id, user_id, submitted')
        .eq('room_id', roomId)
        .eq('submitted', true);

    final result = <_OrderSubtotal>[];
    for (final o in orders as List) {
      final items = await _client
          .from('order_items')
          .select('quantity, price')
          .eq('order_id', o['id'] as String);
      final subtotal = (items as List).fold<double>(
        0,
        (s, i) =>
            s +
            SupabaseMappers.asInt(i['quantity'], 1) *
                SupabaseMappers.asDouble(i['price']),
      );
      result.add(
        _OrderSubtotal(userId: o['user_id'] as String, subtotal: subtotal),
      );
    }
    return result;
  }

  Future<void> _seedCostDraft({
    required String roomId,
    required double receiptTotal,
  }) async {
    final orders = await _loadSubmittedOrders(roomId);
    final expected = orders.fold<double>(0, (s, o) => s + o.subtotal);
    final memberCount = orders.isEmpty ? 1 : orders.length;
    final diff = receiptTotal - expected;
    final diffPer = diff / memberCount;

    final shares = <Map<String, dynamic>>[];
    for (final o in orders) {
      final finalAmount =
          double.parse((o.subtotal + diffPer).toStringAsFixed(2));
      shares.add({
        'room_id': roomId,
        'user_id': o.userId,
        'order_subtotal': o.subtotal,
        'extras_share': diffPer,
        'adjustment': 0,
        'final_amount': finalAmount,
      });
    }
    if (shares.isNotEmpty) {
      final sum = shares.fold<double>(
        0,
        (s, p) => s + SupabaseMappers.asDouble(p['final_amount']),
      );
      final delta = double.parse((receiptTotal - sum).toStringAsFixed(2));
      if (delta != 0) {
        final last = shares.last;
        last['adjustment'] = delta;
        last['final_amount'] = double.parse(
          (SupabaseMappers.asDouble(last['final_amount']) + delta)
              .toStringAsFixed(2),
        );
      }
    }

    await _client.from('cost_shares').upsert({
      'room_id': roomId,
      'receipt_total': receiptTotal,
      'expected_orders_total': expected,
      'delivery_fee': 0,
      'service_fee': 0,
      'tax': 0,
      'discount': 0,
      'other_fee': 0,
      'confirmed': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _client.from('participant_shares').delete().eq('room_id', roomId);
    if (shares.isNotEmpty) {
      await _client.from('participant_shares').insert(shares);
    }
  }
}

class _OrderSubtotal {
  const _OrderSubtotal({required this.userId, required this.subtotal});
  final String userId;
  final double subtotal;
}
