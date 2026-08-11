import 'package:equatable/equatable.dart';

enum PaymentStatus {
  unpaid,
  requested,
  paid,
}

class PaymentRecord extends Equatable {
  const PaymentRecord({
    required this.userId,
    required this.displayName,
    required this.amount,
    required this.paid,
    this.requested = false,
  });

  final String userId;
  final String displayName;
  final double amount;
  final bool paid;
  final bool requested;

  PaymentStatus get status {
    if (paid) return PaymentStatus.paid;
    if (requested) return PaymentStatus.requested;
    return PaymentStatus.unpaid;
  }

  PaymentRecord copyWith({bool? paid, bool? requested}) {
    return PaymentRecord(
      userId: userId,
      displayName: displayName,
      amount: amount,
      paid: paid ?? this.paid,
      requested: requested ?? this.requested,
    );
  }

  @override
  List<Object?> get props => [userId, displayName, amount, paid, requested];
}
