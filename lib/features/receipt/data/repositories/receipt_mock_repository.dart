import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cost_sharing/domain/entities/cost_share.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';

class ReceiptMockRepository implements ReceiptRepository {
  ReceiptMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<Receipt>> uploadReceipt({
    required String roomId,
    required String localPath,
    double? totalAmount,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final memberResult =
        _store.requireMember(roomId, userResult.dataOrNull!.id);
    if (memberResult case Failed(:final failure)) return Failed(failure);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final receipt = Receipt(
      roomId: roomId,
      status: ReceiptStatus.uploaded,
      localPath: localPath,
      imageUrl: localPath,
      totalAmount: totalAmount,
      uploadedBy: userResult.dataOrNull!.id,
    );
    _store.emitReceipt(receipt);

    final room = _store.rooms[roomId];
    if (room != null) {
      _store.emitRoom(room.copyWith(phase: RoomPhase.costReview));
      _store.emitCost(
        _store.recalculateCost(
          roomId: roomId,
          receiptTotal: totalAmount ?? 0,
          extras: const AdditionalCosts(),
        ),
      );
    }
    return Success(receipt);
  }

  @override
  Future<Result<Receipt>> skipReceipt(String roomId) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final memberResult =
        _store.requireMember(roomId, userResult.dataOrNull!.id);
    if (memberResult case Failed(:final failure)) return Failed(failure);

    final orderList =
        (_store.orders[roomId] ?? []).where((o) => o.submitted).toList();
    if (orderList.isEmpty) {
      return const Failed(
        ValidationFailure('No submitted orders to split.'),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final ordersTotal =
        orderList.fold<double>(0, (s, o) => s + o.subtotal);

    final receipt = Receipt(
      roomId: roomId,
      status: ReceiptStatus.skipped,
      totalAmount: ordersTotal,
      uploadedBy: userResult.dataOrNull!.id,
    );
    _store.emitReceipt(receipt);

    final room = _store.rooms[roomId];
    if (room != null) {
      _store.emitRoom(room.copyWith(phase: RoomPhase.costReview));
      _store.emitCost(
        _store.recalculateCost(
          roomId: roomId,
          receiptTotal: ordersTotal,
          extras: const AdditionalCosts(),
        ),
      );
    }
    return Success(receipt);
  }

  @override
  Stream<Receipt> watchReceipt(String roomId) => _store.watchReceipt(roomId);

  @override
  Future<Result<Receipt>> getReceipt(String roomId) async {
    return Success(
      _store.receipts[roomId] ??
          Receipt(roomId: roomId, status: ReceiptStatus.none),
    );
  }
}
