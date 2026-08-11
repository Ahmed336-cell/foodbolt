import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentMockRepository implements PaymentRepository {
  PaymentMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<void>> requestPaid({
    required String roomId,
    required String userId,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final me = userResult.dataOrNull!;
    if (me.id != userId) {
      return const Failed(PermissionFailure());
    }
    final list = List<PaymentRecord>.from(_store.payments[roomId] ?? []);
    final idx = list.indexWhere((p) => p.userId == userId);
    if (idx < 0) return const Failed(NotFoundFailure());
    if (list[idx].paid) return const Success(null);
    list[idx] = list[idx].copyWith(requested: true);
    _store.payments[roomId] = list;
    _store.emitPayments(roomId);
    return const Success(null);
  }

  @override
  Future<Result<void>> markPaid({
    required String roomId,
    required String userId,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final me = userResult.dataOrNull!;
    final room = _store.rooms[roomId];
    if (room == null) return const Failed(NotFoundFailure());
    if (room.hostId != me.id) {
      return const Failed(PermissionFailure());
    }
    final list = List<PaymentRecord>.from(_store.payments[roomId] ?? []);
    final idx = list.indexWhere((p) => p.userId == userId);
    if (idx < 0) return const Failed(NotFoundFailure());
    list[idx] = list[idx].copyWith(paid: true, requested: false);
    _store.payments[roomId] = list;
    _store.emitPayments(roomId);

    if (list.every((p) => p.paid)) {
      _store.emitRoom(room.copyWith(phase: RoomPhase.completed));
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> markUnpaid({
    required String roomId,
    required String userId,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final me = userResult.dataOrNull!;
    final room = _store.rooms[roomId];
    if (room == null) return const Failed(NotFoundFailure());
    if (room.hostId != me.id) {
      return const Failed(PermissionFailure());
    }
    final list = List<PaymentRecord>.from(_store.payments[roomId] ?? []);
    final idx = list.indexWhere((p) => p.userId == userId);
    if (idx < 0) return const Failed(NotFoundFailure());
    list[idx] = list[idx].copyWith(paid: false, requested: false);
    _store.payments[roomId] = list;
    _store.emitPayments(roomId);
    return const Success(null);
  }

  @override
  Stream<List<PaymentRecord>> watchPayments(String roomId) =>
      _store.watchPayments(roomId);
}
