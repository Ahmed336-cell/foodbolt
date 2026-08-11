import '../../../../core/usecase/usecase.dart';
import '../entities/receipt.dart';

abstract class ReceiptRepository {
  Future<Result<Receipt>> uploadReceipt({
    required String roomId,
    required String localPath,
    required double totalAmount,
  });

  /// Skip receipt upload — each participant pays their own order total.
  Future<Result<Receipt>> skipReceipt(String roomId);

  Stream<Receipt> watchReceipt(String roomId);
}
