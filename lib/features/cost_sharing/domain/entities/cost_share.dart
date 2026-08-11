import 'package:equatable/equatable.dart';

class AdditionalCosts extends Equatable {
  const AdditionalCosts({
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.tax = 0,
    this.discount = 0,
    this.other = 0,
  });

  final double deliveryFee;
  final double serviceFee;
  final double tax;
  final double discount;
  final double other;

  double get netExtras => deliveryFee + serviceFee + tax + other - discount;

  AdditionalCosts copyWith({
    double? deliveryFee,
    double? serviceFee,
    double? tax,
    double? discount,
    double? other,
  }) {
    return AdditionalCosts(
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      other: other ?? this.other,
    );
  }

  @override
  List<Object?> get props => [deliveryFee, serviceFee, tax, discount, other];
}

class ParticipantShare extends Equatable {
  const ParticipantShare({
    required this.userId,
    required this.displayName,
    required this.orderSubtotal,
    required this.extrasShare,
    required this.adjustment,
    required this.finalAmount,
  });

  final String userId;
  final String displayName;
  final double orderSubtotal;
  final double extrasShare;
  final double adjustment;
  final double finalAmount;

  @override
  List<Object?> get props =>
      [userId, displayName, orderSubtotal, extrasShare, adjustment, finalAmount];
}

class CostShareDraft extends Equatable {
  const CostShareDraft({
    required this.roomId,
    required this.receiptTotal,
    required this.expectedOrdersTotal,
    required this.additionalCosts,
    required this.shares,
    this.confirmed = false,
  });

  final String roomId;
  final double receiptTotal;
  final double expectedOrdersTotal;
  final AdditionalCosts additionalCosts;
  final List<ParticipantShare> shares;
  final bool confirmed;

  double get difference => receiptTotal - expectedOrdersTotal;
  double get sharesTotal => shares.fold(0, (s, p) => s + p.finalAmount);

  @override
  List<Object?> get props =>
      [roomId, receiptTotal, expectedOrdersTotal, additionalCosts, shares, confirmed];
}
