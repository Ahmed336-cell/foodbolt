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
  double get payableTotal =>
      (receiptTotal > 0 ? receiptTotal : expectedOrdersTotal) +
      additionalCosts.netExtras;

  /// Each person pays their own order. Extra fees + receipt gap split
  /// equally across everyone (20 with 2 people → 10 each).
  factory CostShareDraft.fromOrders({
    required String roomId,
    required double receiptTotal,
    required AdditionalCosts additionalCosts,
    required List<({String userId, String displayName, double subtotal})>
        orders,
    Map<String, double>? adjustments,
    bool confirmed = false,
  }) {
    final expected = orders.fold<double>(0, (s, o) => s + o.subtotal);
    final n = orders.isEmpty ? 1 : orders.length;
    final receiptGap = receiptTotal > 0 ? receiptTotal - expected : 0.0;
    final extrasPool = additionalCosts.netExtras + receiptGap;
    final extrasEach = extrasPool / n;
    final shares = <ParticipantShare>[];

    for (final o in orders) {
      final adj = adjustments?[o.userId] ?? 0;
      final extrasShare = extrasEach;
      final pay = o.subtotal + extrasShare + adj;
      shares.add(
        ParticipantShare(
          userId: o.userId,
          displayName: o.displayName,
          orderSubtotal: o.subtotal,
          extrasShare: double.parse(extrasShare.toStringAsFixed(2)),
          adjustment: adj,
          finalAmount: double.parse(pay.toStringAsFixed(2)),
        ),
      );
    }

    if (shares.isNotEmpty) {
      final base = receiptTotal > 0 ? receiptTotal : expected;
      final target = base + additionalCosts.netExtras;
      final sum = shares.fold<double>(0, (s, p) => s + p.finalAmount);
      final delta = double.parse((target - sum).toStringAsFixed(2));
      if (delta != 0) {
        final idx = shares.length - 1;
        final last = shares[idx];
        shares[idx] = ParticipantShare(
          userId: last.userId,
          displayName: last.displayName,
          orderSubtotal: last.orderSubtotal,
          extrasShare: double.parse(
            (last.extrasShare + delta).toStringAsFixed(2),
          ),
          adjustment: last.adjustment,
          finalAmount:
              double.parse((last.finalAmount + delta).toStringAsFixed(2)),
        );
      }
    }

    return CostShareDraft(
      roomId: roomId,
      receiptTotal: receiptTotal,
      expectedOrdersTotal: expected,
      additionalCosts: additionalCosts,
      shares: List.unmodifiable(shares),
      confirmed: confirmed,
    );
  }

  @override
  List<Object?> get props =>
      [roomId, receiptTotal, expectedOrdersTotal, additionalCosts, shares, confirmed];
}
