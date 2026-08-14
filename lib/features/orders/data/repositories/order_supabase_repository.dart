import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_order.dart';
import '../../domain/repositories/order_repository.dart';

class OrderSupabaseRepository implements OrderRepository {
  OrderSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();

  @override
  Future<Result<UserOrder>> getMyOrder(String roomId) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final existing = await _client
          .from('orders')
          .select('id, room_id, user_id, submitted')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();

      final profile = await _client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final displayName = profile?['display_name'] as String? ?? 'User';

      if (existing != null) {
        final items = await _loadItems(existing['id'] as String);
        return Success(
          UserOrder(
            id: existing['id'] as String,
            roomId: roomId,
            userId: userId,
            displayName: displayName,
            items: items,
            submitted: existing['submitted'] as bool? ?? false,
          ),
        );
      }

      final row = await _client
          .from('orders')
          .insert({
            'room_id': roomId,
            'user_id': userId,
            'submitted': false,
          })
          .select()
          .single();

      return Success(
        UserOrder(
          id: row['id'] as String,
          roomId: roomId,
          userId: userId,
          displayName: displayName,
          items: const [],
          submitted: false,
        ),
      );
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<UserOrder>> upsertMyOrder({
    required String roomId,
    required List<OrderItem> items,
    required bool submit,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('phase')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());

      final phase =
          SupabaseMappers.roomPhaseFromDb(room['phase'] as String?);
      if (phase == RoomPhase.ordersLocked ||
          phase.index > RoomPhase.ordering.index) {
        return const Failed(ValidationFailure('Orders are locked.'));
      }

      final profile = await _client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final displayName = profile?['display_name'] as String? ?? 'User';

      final orderRow = await _client
          .from('orders')
          .upsert(
            {
              'room_id': roomId,
              'user_id': userId,
              'submitted': submit,
            },
            onConflict: 'room_id,user_id',
          )
          .select()
          .single();

      final orderId = orderRow['id'] as String;
      await _client.from('order_items').delete().eq('order_id', orderId);

      if (items.isNotEmpty) {
        await _client.from('order_items').insert([
          for (final item in items)
            {
              'id': item.id.isEmpty ? _uuid.v4() : item.id,
              'order_id': orderId,
              'name': item.name,
              'quantity': item.quantity,
              'price': item.price,
              'notes': item.notes,
            },
        ]);
      }

      final savedItems = await _loadItems(orderId);
      return Success(
        UserOrder(
          id: orderId,
          roomId: roomId,
          userId: userId,
          displayName: displayName,
          items: savedItems,
          submitted: submit,
        ),
      );
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<void>> lockOrders(String roomId) async {
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

      await _client.from('rooms').update({
        'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.ordersLocked),
      }).eq('id', roomId);

      return const Success(null);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<List<UserOrder>> watchOrders(String roomId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .asyncMap((_) => _loadOrders(roomId));
  }

  Future<List<UserOrder>> _loadOrders(String roomId) async {
    final orders = await _client
        .from('orders')
        .select('id, room_id, user_id, submitted')
        .eq('room_id', roomId);

    final userIds = <String>{
      for (final o in orders as List) o['user_id'] as String,
    };
    final names = await _profileNames(userIds);

    final result = <UserOrder>[];
    for (final o in orders as List) {
      final id = o['id'] as String;
      final uid = o['user_id'] as String;
      final items = await _loadItems(id);
      result.add(
        UserOrder(
          id: id,
          roomId: roomId,
          userId: uid,
          displayName: names[uid] ?? 'User',
          items: items,
          submitted: o['submitted'] as bool? ?? false,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<List<OrderItem>> _loadItems(String orderId) async {
    final rows = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId);
    return (rows as List)
        .map(
          (r) => OrderItem(
            id: r['id'] as String,
            name: r['name'] as String,
            quantity: SupabaseMappers.asInt(r['quantity'], 1),
            price: SupabaseMappers.asDouble(r['price']),
            notes: r['notes'] as String?,
          ),
        )
        .toList();
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
