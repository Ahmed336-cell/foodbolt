import '../aggregate_order_items.dart';
import '../entities/saved_order_template.dart';
import '../entities/user_order.dart';

abstract class SavedOrdersRepository {
  Future<List<SavedOrderTemplate>> loadAll();
  Future<void> save(SavedOrderTemplate template);
  Future<void> delete(String id);
}

extension OrderCopyText on List<OrderItem> {
  String toCopyText({String currency = 'EGP'}) {
    if (isEmpty) return '';
    final lines = <String>[
      for (final i in this)
        '• ${i.name} ×${i.quantity} — ${i.lineTotal.toStringAsFixed(0)} $currency'
            '${i.notes == null || i.notes!.isEmpty ? '' : ' (${i.notes})'}',
    ];
    final total = fold<double>(0, (s, i) => s + i.lineTotal);
    lines.add('Total: ${total.toStringAsFixed(0)} $currency');
    return lines.join('\n');
  }
}

extension RestaurantOrderCopyText on List<UserOrder> {
  /// Text formatted to send / call in to a restaurant.
  String toRestaurantOrderText({
    required String restaurantName,
    required String currency,
  }) {
    final submitted =
        where((o) => o.submitted && o.items.isNotEmpty).toList();
    if (submitted.isEmpty) return '';

    final aggregated = aggregateOrderItems(this);
    final grandTotal =
        submitted.fold<double>(0, (s, o) => s + o.subtotal);
    final lines = <String>[
      restaurantName,
      '',
      '--- Combined ---',
      for (final line in aggregated) ...[
        '• ${line.name} ×${line.qty}'
            '${line.notes == null || line.notes!.isEmpty ? '' : ' (${line.notes})'}'
            ' — ${line.total.toStringAsFixed(0)} $currency',
        if (line.isShared) '  (${line.peopleSummary})',
      ],
      '',
      '--- Per person ---',
      for (final order in submitted) ...[
        order.displayName,
        for (final item in order.items)
          '  • ${item.name} ×${item.quantity}'
              '${item.notes == null || item.notes!.isEmpty ? '' : ' (${item.notes})'}'
              ' — ${item.lineTotal.toStringAsFixed(0)} $currency',
        '  Subtotal: ${order.subtotal.toStringAsFixed(0)} $currency',
        '',
      ],
      'Grand total: ${grandTotal.toStringAsFixed(0)} $currency',
    ];
    return lines.join('\n').trim();
  }
}
