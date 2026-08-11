import '../../../../core/usecase/usecase.dart';
import '../entities/cost_share.dart';
import '../repositories/cost_sharing_repository.dart';

class CalculateCostSharing extends UseCase<CostShareDraft, CalculateCostParams> {
  CalculateCostSharing(this._repo);
  final CostSharingRepository _repo;

  @override
  Future<Result<CostShareDraft>> call(CalculateCostParams params) =>
      _repo.calculate(
        roomId: params.roomId,
        receiptTotal: params.receiptTotal,
        additionalCosts: params.additionalCosts,
        adjustments: params.adjustments,
      );
}

class CalculateCostParams {
  const CalculateCostParams({
    required this.roomId,
    required this.receiptTotal,
    required this.additionalCosts,
    this.adjustments,
  });
  final String roomId;
  final double receiptTotal;
  final AdditionalCosts additionalCosts;
  final Map<String, double>? adjustments;
}

class ConfirmCostSharing extends UseCase<CostShareDraft, String> {
  ConfirmCostSharing(this._repo);
  final CostSharingRepository _repo;

  @override
  Future<Result<CostShareDraft>> call(String roomId) => _repo.confirm(roomId);
}
