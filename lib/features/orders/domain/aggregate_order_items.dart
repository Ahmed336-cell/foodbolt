import 'entities/user_order.dart';

/// One merged line for the restaurant ticket (same name + notes).
class AggregatedOrderLine {
  const AggregatedOrderLine({
    required this.name,
    required this.qty,
    required this.total,
    required this.notes,
    required this.byPerson,
  });

  final String name;
  final int qty;
  final double total;
  final String? notes;

  /// Who ordered this line and how many each.
  final List<({String displayName, int qty})> byPerson;

  bool get isShared => byPerson.length > 1;

  String get peopleSummary {
    if (byPerson.isEmpty) return '';
    return byPerson
        .map((p) => p.qty > 1 ? '${p.displayName} ×${p.qty}' : p.displayName)
        .join(' · ');
  }
}

/// Merge identical items (name + notes) across people. Easy restaurant view.
List<AggregatedOrderLine> aggregateOrderItems(List<UserOrder> orders) {
  final submitted =
      orders.where((o) => o.submitted && o.items.isNotEmpty).toList();

  final buckets = <String, _Bucket>{};
  for (final order in submitted) {
    for (final item in order.items) {
      final name = item.name.trim();
      if (name.isEmpty) continue;
      final notes = item.notes?.trim();
      final notesKey = (notes == null || notes.isEmpty) ? '' : notes;
      // Case-insensitive merge so "Pizza" + "pizza" become one line.
      final key = '${name.toLowerCase()}\u0000$notesKey';
      final bucket = buckets.putIfAbsent(
        key,
        () => _Bucket(displayName: name, notes: notesKey.isEmpty ? null : notesKey),
      );
      bucket.qty += item.quantity;
      bucket.total += item.lineTotal;
      bucket.byPerson.update(
        order.displayName,
        (q) => q + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
  }

  final lines = buckets.values
      .map(
        (b) => AggregatedOrderLine(
          name: b.displayName,
          qty: b.qty,
          total: b.total,
          notes: b.notes,
          byPerson: b.byPerson.entries
              .map((e) => (displayName: e.key, qty: e.value))
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName)),
        ),
      )
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return lines;
}

class _Bucket {
  _Bucket({required this.displayName, required this.notes});

  final String displayName;
  final String? notes;
  int qty = 0;
  double total = 0;
  final byPerson = <String, int>{};
}
