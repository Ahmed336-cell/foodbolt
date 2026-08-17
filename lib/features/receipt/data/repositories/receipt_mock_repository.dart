import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cost_sharing/domain/entities/cost_share.dart';
import '../../../payment_summary/domain/entities/payment_record.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';

class ReceiptMockRepository implements ReceiptRepository {
  ReceiptMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<Receipt>> uploadReceipt({
    required String roomId,
    required String localPath,
    required double totalAmount,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final memberResult =
        _store.requireMember(roomId, userResult.dataOrNull!.id);
    if (memberResult case Failed(:final failure)) return Failed(failure);
    if (totalAmount <= 0) {
      return const Failed(ValidationFailure('Enter receipt total.'));
    }
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
          receiptTotal: totalAmount,
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

    // Each person pays exactly their order — no receipt delta / extras.
    final draft = _store.recalculateCost(
      roomId: roomId,
      receiptTotal: ordersTotal,
      extras: const AdditionalCosts(),
    );
    final confirmed = CostShareDraft(
      roomId: draft.roomId,
      receiptTotal: draft.receiptTotal,
      expectedOrdersTotal: draft.expectedOrdersTotal,
      additionalCosts: draft.additionalCosts,
      shares: draft.shares,
      confirmed: true,
    );
    _store.emitCost(confirmed);
    _store.payments[roomId] = confirmed.shares
        .map(
          (s) => PaymentRecord(
            userId: s.userId,
            displayName: s.displayName,
            amount: s.finalAmount,
            paid: false,
          ),
        )
        .toList();
    _store.emitPayments(roomId);

    final room = _store.rooms[roomId];
    if (room != null) {
      _store.emitRoom(room.copyWith(phase: RoomPhase.paymentSummary));
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
