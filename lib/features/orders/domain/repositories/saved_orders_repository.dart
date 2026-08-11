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
