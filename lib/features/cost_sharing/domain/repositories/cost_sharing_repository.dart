import '../../../../core/usecase/usecase.dart';
import '../entities/cost_share.dart';

abstract class CostSharingRepository {
  Future<Result<CostShareDraft>> calculate({
    required String roomId,
    required double receiptTotal,
    required AdditionalCosts additionalCosts,
    Map<String, double>? adjustments,
  });
  Future<Result<CostShareDraft>> confirm(String roomId);
  Stream<CostShareDraft> watchCostShare(String roomId);
}
