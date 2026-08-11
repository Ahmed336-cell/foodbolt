import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/cost_share.dart';
import '../../domain/repositories/cost_sharing_repository.dart';

class CostSharingSupabaseRepository implements CostSharingRepository {
  CostSharingSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Result<CostShareDraft>> calculate({
    required String roomId,
    required double receiptTotal,
    required AdditionalCosts additionalCosts,
    Map<String, double>? adjustments,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('host_id')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (room['host_id'] != userId) {
        return const Failed(PermissionFailure());
      }

      final draft = await _recalculate(
        roomId: roomId,
        receiptTotal: receiptTotal,
        extras: additionalCosts,
        adjustments: adjustments,
      );

      await _client.from('cost_shares').upsert({
        'room_id': roomId,
        'receipt_total': draft.receiptTotal,
        'expected_orders_total': draft.expectedOrdersTotal,
        'delivery_fee': additionalCosts.deliveryFee,
        'service_fee': additionalCosts.serviceFee,
        'tax': additionalCosts.tax,
        'discount': additionalCosts.discount,
        'other_fee': additionalCosts.other,
        'confirmed': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _client
          .from('participant_shares')
          .delete()
          .eq('room_id', roomId);
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

      return Success(draft);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<CostShareDraft>> confirm(String roomId) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('host_id')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (room['host_id'] != userId) {
        return const Failed(PermissionFailure());
      }

      final draft = await _loadDraft(roomId);
      if (draft == null) {
        return const Failed(ValidationFailure('Calculate the split first.'));
      }

      final sum = draft.sharesTotal;
      if ((sum - draft.receiptTotal).abs() > 0.05) {
        return Failed(
          ValidationFailure(
            'Shares ($sum) must equal receipt (${draft.receiptTotal}).',
          ),
        );
      }

      await _client.from('cost_shares').update({
        'confirmed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('room_id', roomId);

      await _client.from('payments').upsert(
        [
          for (final s in draft.shares)
            {
              'room_id': roomId,
              'user_id': s.userId,
              'amount': s.finalAmount,
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
        CostShareDraft(
          roomId: draft.roomId,
          receiptTotal: draft.receiptTotal,
          expectedOrdersTotal: draft.expectedOrdersTotal,
          additionalCosts: draft.additionalCosts,
          shares: draft.shares,
          confirmed: true,
        ),
      );
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<CostShareDraft> watchCostShare(String roomId) {
    late StreamController<CostShareDraft> controller;
    final subs = <StreamSubscription<dynamic>>[];

    Future<void> push() async {
      if (controller.isClosed) return;
      try {
        final draft = await _loadDraft(roomId);
        if (draft != null) controller.add(draft);
      } catch (_) {}
    }

    controller = StreamController<CostShareDraft>(
      onListen: () {
        push();
        subs.add(
          _client
              .from('cost_shares')
              .stream(primaryKey: ['room_id'])
              .eq('room_id', roomId)
              .listen((_) => push()),
        );
        subs.add(
          _client
              .from('participant_shares')
              .stream(primaryKey: ['room_id', 'user_id'])
              .eq('room_id', roomId)
              .listen((_) => push()),
        );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        await controller.close();
      },
    );

    return controller.stream;
  }

  Future<CostShareDraft> _recalculate({
    required String roomId,
    required double receiptTotal,
    required AdditionalCosts extras,
    Map<String, double>? adjustments,
  }) async {
    final orderRows = await _client
        .from('orders')
        .select('id, user_id')
        .eq('room_id', roomId)
        .eq('submitted', true);

    final orderList = <({String userId, String displayName, double subtotal})>[];
    final userIds = <String>{
      for (final o in orderRows as List) o['user_id'] as String,
    };
    final names = await _profileNames(userIds);

    for (final o in orderRows as List) {
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
      final uid = o['user_id'] as String;
      orderList.add((
        userId: uid,
        displayName: names[uid] ?? 'User',
        subtotal: subtotal,
      ));
    }

    final expected = orderList.fold<double>(0, (s, o) => s + o.subtotal);
    final memberCount = orderList.isEmpty ? 1 : orderList.length;
    final extrasPer = extras.netExtras / memberCount;
    final diff = receiptTotal - (expected + extras.netExtras);
    final diffPer = diff / memberCount;

    final shares = orderList.map((o) {
      final adj = adjustments?[o.userId] ?? 0;
      final finalAmount = o.subtotal + extrasPer + diffPer + adj;
      return ParticipantShare(
        userId: o.userId,
        displayName: o.displayName,
        orderSubtotal: o.subtotal,
        extrasShare: extrasPer + diffPer,
        adjustment: adj,
        finalAmount: double.parse(finalAmount.toStringAsFixed(2)),
      );
    }).toList();

    if (shares.isNotEmpty) {
      final sum = shares.fold<double>(0, (s, p) => s + p.finalAmount);
      final delta = double.parse((receiptTotal - sum).toStringAsFixed(2));
      if (delta != 0) {
        final last = shares.last;
        shares[shares.length - 1] = ParticipantShare(
          userId: last.userId,
          displayName: last.displayName,
          orderSubtotal: last.orderSubtotal,
          extrasShare: last.extrasShare,
          adjustment: last.adjustment + delta,
          finalAmount:
              double.parse((last.finalAmount + delta).toStringAsFixed(2)),
        );
      }
    }

    return CostShareDraft(
      roomId: roomId,
      receiptTotal: receiptTotal,
      expectedOrdersTotal: expected,
      additionalCosts: extras,
      shares: shares,
    );
  }

  Future<CostShareDraft?> _loadDraft(String roomId) async {
    final cost = await _client
        .from('cost_shares')
        .select()
        .eq('room_id', roomId)
        .maybeSingle();
    if (cost == null) return null;

    final shareRows = await _client
        .from('participant_shares')
        .select()
        .eq('room_id', roomId);
    final userIds = <String>{
      for (final s in shareRows as List) s['user_id'] as String,
    };
    final names = await _profileNames(userIds);

    final shares = (shareRows as List)
        .map(
          (s) {
            final uid = s['user_id'] as String;
            return ParticipantShare(
              userId: uid,
              displayName: names[uid] ?? 'User',
              orderSubtotal: SupabaseMappers.asDouble(s['order_subtotal']),
              extrasShare: SupabaseMappers.asDouble(s['extras_share']),
              adjustment: SupabaseMappers.asDouble(s['adjustment']),
              finalAmount: SupabaseMappers.asDouble(s['final_amount']),
            );
          },
        )
        .toList();

    return CostShareDraft(
      roomId: roomId,
      receiptTotal: SupabaseMappers.asDouble(cost['receipt_total']),
      expectedOrdersTotal:
          SupabaseMappers.asDouble(cost['expected_orders_total']),
      additionalCosts: AdditionalCosts(
        deliveryFee: SupabaseMappers.asDouble(cost['delivery_fee']),
        serviceFee: SupabaseMappers.asDouble(cost['service_fee']),
        tax: SupabaseMappers.asDouble(cost['tax']),
        discount: SupabaseMappers.asDouble(cost['discount']),
        other: SupabaseMappers.asDouble(cost['other_fee']),
      ),
      shares: shares,
      confirmed: cost['confirmed'] as bool? ?? false,
    );
  }

  Future<Map<String, String>> _profileNames(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', ids.toList());
    return {
      for (final r in rows as List)
        r['id'] as String: r['display_name'] as String? ?? 'User',
    };
  }
}
