import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cost_sharing/domain/entities/cost_share.dart';
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
    double? totalAmount,
  }) async {
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

      final storagePath = '$roomId/${_uuid.v4()}.jpg';
      await _client.storage.from('receipts').upload(
            storagePath,
            File(localPath),
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      if (totalAmount != null && totalAmount > 0) {
        try {
          await _client.rpc(
            'save_uploaded_receipt',
            params: {
              'p_room_id': roomId,
              'p_storage_path': storagePath,
              'p_total': totalAmount,
              'p_status': 'uploaded',
            },
          );
        } catch (e) {
          if (!_isMissingSaveReceiptRpc(e)) rethrow;
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
        }
      } else {
        await _client.from('receipts').upsert({
          'room_id': roomId,
          'storage_path': storagePath,
          'uploaded_by': userId,
          'status': SupabaseMappers.receiptStatusToDb(ReceiptStatus.uploaded),
        });
        await _client.from('rooms').update({
          'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.costReview),
        }).eq('id', roomId);
      }

      // Best-effort seed of cost draft (host RLS may block non-host writers).
      try {
        await _seedCostDraft(
          roomId: roomId,
          receiptTotal: totalAmount ?? 0,
        );
      } catch (_) {}

      return Success(
        Receipt(
          roomId: roomId,
          status: ReceiptStatus.uploaded,
          localPath: localPath,
          storagePath: storagePath,
          imageUrl: await _signedUrl(storagePath),
          totalAmount: totalAmount,
          uploadedBy: userId,
        ),
      );
    } catch (e, st) {
      return Failed(_mapReceiptError(e, st));
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

      try {
        await _seedCostDraft(roomId: roomId, receiptTotal: ordersTotal);
      } catch (_) {}

      await _client.from('rooms').update({
        'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.costReview),
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
        .asyncMap((rows) => _mapReceiptRow(roomId, rows));
  }

  @override
  Future<Result<Receipt>> getReceipt(String roomId) async {
    try {
      final rows = await _client
          .from('receipts')
          .select()
          .eq('room_id', roomId)
          .limit(1);
      return Success(await _mapReceiptRow(roomId, rows));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  Future<Receipt> _mapReceiptRow(String roomId, List<dynamic> rows) async {
    if (rows.isEmpty) {
      return Receipt(roomId: roomId, status: ReceiptStatus.none);
    }
    final r = Map<String, dynamic>.from(rows.first as Map);
    final path = r['storage_path'] as String?;
    return Receipt(
      roomId: roomId,
      status: SupabaseMappers.receiptStatusFromDb(r['status'] as String?),
      storagePath: path,
      imageUrl: await _signedUrl(path),
      totalAmount: r['total_amount'] == null
          ? null
          : SupabaseMappers.asDouble(r['total_amount']),
      uploadedBy: r['uploaded_by'] as String?,
    );
  }

  Future<String?> _signedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await _client.storage.from('receipts').createSignedUrl(
            path,
            60 * 60 * 24,
          );
    } catch (_) {
      return null;
    }
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
    final draft = CostShareDraft.fromOrders(
      roomId: roomId,
      receiptTotal: receiptTotal,
      additionalCosts: const AdditionalCosts(),
      orders: [
        for (final o in orders)
          (
            userId: o.userId,
            displayName: o.userId,
            subtotal: o.subtotal,
          ),
      ],
    );

    await _client.from('cost_shares').upsert({
      'room_id': roomId,
      'receipt_total': receiptTotal,
      'expected_orders_total': draft.expectedOrdersTotal,
      'delivery_fee': 0,
      'service_fee': 0,
      'tax': 0,
      'discount': 0,
      'other_fee': 0,
      'confirmed': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _client.from('participant_shares').delete().eq('room_id', roomId);
    if (draft.shares.isNotEmpty) {
      await _client.from('participant_shares').insert([
        for (final s in draft.shares)
          {
            'room_id': roomId,
            'user_id': s.userId,
            'order_subtotal': s.orderSubtotal,
            'extras_share': s.extrasShare,
            'adjustment': s.adjustment,
            'final_amount': s.finalAmount,
          },
      ]);
    }
  }

  bool _isMissingSaveReceiptRpc(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('save_uploaded_receipt') &&
        (text.contains('does not exist') ||
            text.contains('42883') ||
            text.contains('pgrst202') ||
            text.contains('could not find the function'));
  }

  Failure _mapReceiptError(Object error, StackTrace stackTrace) {
    final text = error.toString().toLowerCase();
    if (text.contains('row-level security') ||
        text.contains('bucket not found') ||
        text.contains('not found') && text.contains('receipts')) {
      return const PermissionFailure("Couldn't upload the receipt. Try again.");
    }
    return SupabaseMappers.mapError(error, stackTrace);
  }
}

class _OrderSubtotal {
  const _OrderSubtotal({required this.userId, required this.subtotal});
  final String userId;
  final double subtotal;
}
