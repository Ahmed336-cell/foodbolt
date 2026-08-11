import 'package:flutter/services.dart';

/// Shared input formatters for numeric fields.
class NumericInput {
  NumericInput._();

  /// Integers only (quantity, counts).
  static final intOnly = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];

  /// Money / totals: digits + one decimal point.
  static final decimal = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      if (text.isEmpty) return newValue;
      if ('.'.allMatches(text).length > 1) return oldValue;
      if (text.startsWith('.')) {
        return newValue.copyWith(
          text: '0$text',
          selection: TextSelection.collapsed(offset: text.length + 1),
        );
      }
      return newValue;
    }),
  ];

  static const intKeyboard = TextInputType.number;
  static const decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
}
