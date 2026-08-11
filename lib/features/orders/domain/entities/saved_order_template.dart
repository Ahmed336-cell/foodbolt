import 'package:equatable/equatable.dart';

import 'user_order.dart';

/// Locally saved order template for reuse across rooms.
class SavedOrderTemplate extends Equatable {
  const SavedOrderTemplate({
    required this.id,
    required this.title,
    required this.items,
    required this.savedAt,
  });

  final String id;
  final String title;
  final List<OrderItem> items;
  final DateTime savedAt;

  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'savedAt': savedAt.toIso8601String(),
        'items': [
          for (final i in items)
            {
              'id': i.id,
              'name': i.name,
              'quantity': i.quantity,
              'price': i.price,
              'notes': i.notes,
            },
        ],
      };

  factory SavedOrderTemplate.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return SavedOrderTemplate(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Saved order',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
      items: [
        for (final raw in rawItems)
          OrderItem(
            id: (raw as Map)['id'] as String? ?? '',
            name: raw['name'] as String? ?? '',
            quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
            price: (raw['price'] as num?)?.toDouble() ?? 0,
            notes: raw['notes'] as String?,
          ),
      ],
    );
  }

  @override
  List<Object?> get props => [id, title, items, savedAt];
}
