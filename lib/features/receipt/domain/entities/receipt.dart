import 'package:equatable/equatable.dart';

enum ReceiptStatus { none, uploaded, skipped }

class Receipt extends Equatable {
  const Receipt({
    required this.roomId,
    required this.status,
    this.localPath,
    this.totalAmount,
    this.uploadedBy,
  });

  final String roomId;
  final ReceiptStatus status;
  final String? localPath;
  final double? totalAmount;
  final String? uploadedBy;

  @override
  List<Object?> get props => [roomId, status, localPath, totalAmount, uploadedBy];
}
