import '../../../../core/usecase/usecase.dart';
import '../entities/payment_record.dart';

abstract class PaymentRepository {
  /// Member (or self): ask host to confirm payment.
  Future<Result<void>> requestPaid({
    required String roomId,
    required String userId,
  });

  /// Host only: confirm someone paid.
  Future<Result<void>> markPaid({
    required String roomId,
    required String userId,
  });

  /// Host only: reject request / mark unpaid again.
  Future<Result<void>> markUnpaid({
    required String roomId,
    required String userId,
  });

  Stream<List<PaymentRecord>> watchPayments(String roomId);
}
