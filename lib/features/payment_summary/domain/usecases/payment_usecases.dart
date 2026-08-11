import '../../../../core/usecase/usecase.dart';
import '../repositories/payment_repository.dart';

class RequestPayment extends UseCase<void, PaymentUserParams> {
  RequestPayment(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Result<void>> call(PaymentUserParams params) =>
      _repo.requestPaid(roomId: params.roomId, userId: params.userId);
}

class MarkPaymentAsPaid extends UseCase<void, PaymentUserParams> {
  MarkPaymentAsPaid(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Result<void>> call(PaymentUserParams params) =>
      _repo.markPaid(roomId: params.roomId, userId: params.userId);
}

class MarkPaymentAsUnpaid extends UseCase<void, PaymentUserParams> {
  MarkPaymentAsUnpaid(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Result<void>> call(PaymentUserParams params) =>
      _repo.markUnpaid(roomId: params.roomId, userId: params.userId);
}

class PaymentUserParams {
  const PaymentUserParams({required this.roomId, required this.userId});
  final String roomId;
  final String userId;
}

/// Backward-compatible alias.
typedef MarkPaidParams = PaymentUserParams;
