import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentSupabaseRepository implements PaymentRepository {
  PaymentSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Result<void>> requestPaid({
    required String roomId,
    required String userId,
  }) async {
    final me = SupabaseMappers.requireUserId(_client);
    if (me == null) return const Failed(AuthFailure());
    if (me != userId) return const Failed(PermissionFailure());

    try {
      final existing = await _client
          .from('payments')
          .select('paid')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null) return const Failed(NotFoundFailure());
      if (existing['paid'] == true) return const Success(null);

      await _client.from('payments').update({
        'payment_requested': true,
      }).eq('room_id', roomId).eq('user_id', userId);

      return const Success(null);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<void>> markPaid({
    required String roomId,
    required String userId,
  }) async {
    final me = SupabaseMappers.requireUserId(_client);
    if (me == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('host_id')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (room['host_id'] != me) {
        return const Failed(PermissionFailure());
      }

      final existing = await _client
          .from('payments')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null) return const Failed(NotFoundFailure());

      await _client.from('payments').update({
        'paid': true,
        'payment_requested': false,
      }).eq('room_id', roomId).eq('user_id', userId);

      final all = await _client
          .from('payments')
          .select('paid')
          .eq('room_id', roomId);
      final everyonePaid =
          (all as List).isNotEmpty && all.every((p) => p['paid'] == true);
      if (everyonePaid) {
        await _client.from('rooms').update({
          'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.completed),
        }).eq('id', roomId);
      }

      return const Success(null);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<void>> markUnpaid({
    required String roomId,
    required String userId,
  }) async {
    final me = SupabaseMappers.requireUserId(_client);
    if (me == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('host_id')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (room['host_id'] != me) {
        return const Failed(PermissionFailure());
      }

      final existing = await _client
          .from('payments')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null) return const Failed(NotFoundFailure());

      await _client.from('payments').update({
        'paid': false,
        'payment_requested': false,
      }).eq('room_id', roomId).eq('user_id', userId);

      return const Success(null);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<List<PaymentRecord>> watchPayments(String roomId) {
    return _client
        .from('payments')
        .stream(primaryKey: ['room_id', 'user_id'])
        .eq('room_id', roomId)
        .asyncMap((rows) => _mapPayments(rows));
  }

  Future<List<PaymentRecord>> _mapPayments(
    List<Map<String, dynamic>> rows,
  ) async {
    final userIds = <String>{for (final r in rows) r['user_id'] as String};
    final names = <String, String>{};
    if (userIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', userIds.toList());
      for (final p in profiles as List) {
        names[p['id'] as String] = p['display_name'] as String? ?? 'User';
      }
    }

    return List.unmodifiable([
      for (final r in rows)
        PaymentRecord(
          userId: r['user_id'] as String,
          displayName: names[r['user_id'] as String] ?? 'User',
          amount: SupabaseMappers.asDouble(r['amount']),
          paid: r['paid'] as bool? ?? false,
          requested: r['payment_requested'] as bool? ?? false,
        ),
    ]);
  }
}
