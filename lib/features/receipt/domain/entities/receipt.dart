import 'package:equatable/equatable.dart';

enum ReceiptStatus { none, uploaded, skipped }

class Receipt extends Equatable {
  const Receipt({
    required this.roomId,
    required this.status,
    this.localPath,
    this.storagePath,
    this.imageUrl,
    this.totalAmount,
    this.uploadedBy,
  });

  final String roomId;
  final ReceiptStatus status;
  /// Local picker path (uploader device only).
  final String? localPath;
  final String? storagePath;
  /// Signed/public URL so everyone in the room can view the photo.
  final String? imageUrl;
  final double? totalAmount;
  final String? uploadedBy;

  @override
  List<Object?> get props =>
      [roomId, status, localPath, storagePath, imageUrl, totalAmount, uploadedBy];
}
