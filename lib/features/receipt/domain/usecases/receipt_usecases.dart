import '../../../../core/usecase/usecase.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';

class UploadReceipt extends UseCase<Receipt, UploadReceiptParams> {
  UploadReceipt(this._repo);
  final ReceiptRepository _repo;

  @override
  Future<Result<Receipt>> call(UploadReceiptParams params) =>
      _repo.uploadReceipt(
        roomId: params.roomId,
        localPath: params.localPath,
        totalAmount: params.totalAmount,
      );
}

class UploadReceiptParams {
  const UploadReceiptParams({
    required this.roomId,
    required this.localPath,
    required this.totalAmount,
  });
  final String roomId;
  final String localPath;
  final double totalAmount;
}

class SkipReceipt extends UseCase<Receipt, String> {
  SkipReceipt(this._repo);
  final ReceiptRepository _repo;

  @override
  Future<Result<Receipt>> call(String roomId) => _repo.skipReceipt(roomId);
}
