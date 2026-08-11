import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? notes;

  double get lineTotal => quantity * price;

  @override
  List<Object?> get props => [id, name, quantity, price, notes];
}

class UserOrder extends Equatable {
  const UserOrder({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.displayName,
    required this.items,
    required this.submitted,
  });

  final String id;
  final String roomId;
  final String userId;
  final String displayName;
  final List<OrderItem> items;
  final bool submitted;

  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);

  UserOrder copyWith({
    List<OrderItem>? items,
    bool? submitted,
    String? displayName,
  }) {
    return UserOrder(
      id: id,
      roomId: roomId,
      userId: userId,
      displayName: displayName ?? this.displayName,
      items: items ?? this.items,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props => [id, roomId, userId, displayName, items, submitted];
}
