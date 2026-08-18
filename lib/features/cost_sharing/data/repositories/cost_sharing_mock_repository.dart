import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../payment_summary/domain/entities/payment_record.dart';
import '../../domain/entities/cost_share.dart';
import '../../domain/repositories/cost_sharing_repository.dart';

class CostSharingMockRepository implements CostSharingRepository {
  CostSharingMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<CostShareDraft>> calculate({
    required String roomId,
    required double receiptTotal,
    required AdditionalCosts additionalCosts,
    Map<String, double>? adjustments,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);

    final draft = _store.recalculateCost(
      roomId: roomId,
      receiptTotal: receiptTotal,
      extras: additionalCosts,
      adjustments: adjustments,
    );
    _store.emitCost(draft);
    return Success(draft);
  }

  @override
  Future<Result<CostShareDraft>> confirm(String roomId) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);
    final draft = _store.costShares[roomId];
    if (draft == null) {
      return const Failed(ValidationFailure('Calculate the split first.'));
    }
    final sum = draft.sharesTotal;
    if ((sum - draft.payableTotal).abs() > 0.05) {
      return Failed(
        ValidationFailure(
          'Shares ($sum) must equal receipt (${draft.payableTotal}).',
        ),
      );
    }
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
    return Success(confirmed);
  }

  @override
  Future<Result<CostShareDraft?>> getCostShare(String roomId) async {
    return Success(_store.costShares[roomId]);
  }

  @override
  Stream<CostShareDraft> watchCostShare(String roomId) =>
      _store.watchCost(roomId);
}
