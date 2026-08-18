import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_order.dart';
import '../../domain/repositories/order_repository.dart';

class OrderMockRepository implements OrderRepository {
  OrderMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<UserOrder>> getMyOrder(String roomId) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final user = userResult.dataOrNull!;
    final list = _store.orders[roomId] ?? [];
    final existing = list.where((o) => o.userId == user.id).firstOrNull;
    if (existing != null) return Success(existing);
    final order = UserOrder(
      id: _store.newId(),
      roomId: roomId,
      userId: user.id,
      displayName: user.displayName,
      items: const [],
      submitted: false,
    );
    list.add(order);
    _store.orders[roomId] = list;
    _store.emitOrders(roomId);
    return Success(order);
  }

  @override
  Future<Result<UserOrder>> upsertMyOrder({
    required String roomId,
    required List<OrderItem> items,
    required bool submit,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final room = roomResult.dataOrNull!;
    if (room.phase == RoomPhase.ordersLocked ||
        room.phase.index > RoomPhase.ordering.index) {
      return const Failed(ValidationFailure('Orders are locked.'));
    }
    final user = userResult.dataOrNull!;
    final list = List<UserOrder>.from(_store.orders[roomId] ?? []);
    final idx = list.indexWhere((o) => o.userId == user.id);
    final order = UserOrder(
      id: idx >= 0 ? list[idx].id : _store.newId(),
      roomId: roomId,
      userId: user.id,
      displayName: user.displayName,
      items: items,
      submitted: submit,
    );
    if (idx >= 0) {
      list[idx] = order;
    } else {
      list.add(order);
    }
    _store.orders[roomId] = list;
    _store.emitOrders(roomId);
    return Success(order);
  }

  @override
  Future<Result<void>> lockOrders(String roomId) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    _store.emitRoom(
      roomResult.dataOrNull!.copyWith(phase: RoomPhase.ordersLocked),
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> updateItemPrice({
    required String itemId,
    required double price,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    if (price < 0) {
      return const Failed(ValidationFailure('Enter a valid price.'));
    }

    for (final entry in _store.orders.entries) {
      final list = List<UserOrder>.from(entry.value);
      var changed = false;
      for (var i = 0; i < list.length; i++) {
        final order = list[i];
        final idx = order.items.indexWhere((it) => it.id == itemId);
        if (idx < 0) continue;
        if (_store.rooms[order.roomId]?.hostId != userResult.dataOrNull!.id) {
          return const Failed(PermissionFailure());
        }
        final items = List<OrderItem>.from(order.items);
        items[idx] = items[idx].copyWith(price: price);
        list[i] = order.copyWith(items: items);
        changed = true;
        break;
      }
      if (changed) {
        _store.orders[entry.key] = list;
        _store.emitOrders(entry.key);
        return const Success(null);
      }
    }
    return const Failed(NotFoundFailure());
  }

  @override
  Future<Result<List<UserOrder>>> getOrders(String roomId) async {
    return Success(List.unmodifiable(_store.orders[roomId] ?? const []));
  }

  @override
  Stream<List<UserOrder>> watchOrders(String roomId) =>
      _store.watchOrders(roomId);
}
