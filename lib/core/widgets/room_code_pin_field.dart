import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../room/room_code.dart';
import '../theme/app_theme.dart';

/// 6-box PIN-style room code entry. Always uppercase A–Z / 0–9.
class RoomCodePinField extends StatefulWidget {
  const RoomCodePinField({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = true,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool autofocus;

  @override
  State<RoomCodePinField> createState() => _RoomCodePinFieldState();
}

class _RoomCodePinFieldState extends State<RoomCodePinField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  var _emitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(RoomCode.length, (_) => TextEditingController());
    _nodes = List.generate(RoomCode.length, (_) => FocusNode());
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nodes.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _setChar(int index, String ch) {
    _controllers[index].value = TextEditingValue(
      text: ch,
      selection: TextSelection.collapsed(offset: ch.length),
    );
  }

  void _emit() {
    if (_emitting) return;
    _emitting = true;
    final code = RoomCode.extract(_value);
    widget.onChanged(code);
    if (RoomCode.isComplete(code)) {
      widget.onCompleted?.call(code);
    }
    _emitting = false;
  }

  void _fillCode(String code) {
    final chars = RoomCode.extract(code).split('');
    for (var j = 0; j < RoomCode.length; j++) {
      _setChar(j, j < chars.length ? chars[j] : '');
    }
    final focusAt = chars.length >= RoomCode.length
        ? RoomCode.length - 1
        : chars.length.clamp(0, RoomCode.length - 1);
    _nodes[focusAt].requestFocus();
    if (chars.length >= RoomCode.length) {
      _nodes[focusAt].unfocus();
    }
    _emit();
    setState(() {});
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Paste (invite text or full code) — formatter may already extract.
      _fillCode(value);
      return;
    }
    if (value.isEmpty) {
      _setChar(index, '');
      if (index > 0) _nodes[index - 1].requestFocus();
      _emit();
      setState(() {});
      return;
    }
    final ch = RoomCode.normalize(value).characters.first;
    _setChar(index, ch);
    if (index < RoomCode.length - 1) {
      _nodes[index + 1].requestFocus();
    } else {
      _nodes[index].unfocus();
    }
    _emit();
    setState(() {});
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }
    if (index == 0) return KeyEventResult.ignored;
    _setChar(index - 1, '');
    _nodes[index - 1].requestFocus();
    _emit();
    setState(() {});
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final boxW =
              ((constraints.maxWidth - gap * (RoomCode.length - 1)) /
                      RoomCode.length)
                  .clamp(40.0, 56.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(RoomCode.length, (i) {
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  end: i == RoomCode.length - 1 ? 0 : gap,
                ),
                child: SizedBox(
                  width: boxW,
                  height: 58,
                  child: Focus(
                    onKeyEvent: (_, event) => _onKey(i, event),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      enabled: widget.enabled,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      inputFormatters: const [
                        _RoomCodeBoxFormatter(),
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.black12,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _controllers[i].text.isEmpty
                                ? Colors.black12
                                : AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2.4,
                          ),
                        ),
                      ),
                      onChanged: (v) => _onChanged(i, v),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Read-only display of a room code as PIN boxes.
class RoomCodePinDisplay extends StatelessWidget {
  const RoomCodePinDisplay({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final normalized = RoomCode.normalize(code);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(RoomCode.length, (i) {
          final ch = i < normalized.length ? normalized[i] : '';
          return Container(
            width: 44,
            height: 52,
            margin: EdgeInsetsDirectional.only(
              end: i == RoomCode.length - 1 ? 0 : 8,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: Text(
              ch,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Single-box formatter: 1 uppercase char, or full extracted code on paste.
class _RoomCodeBoxFormatter extends TextInputFormatter {
  const _RoomCodeBoxFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }
    if (text.length == 1) {
      final upper = text.toUpperCase();
      if (!RegExp(r'^[A-Z0-9]$').hasMatch(upper)) {
        return oldValue;
      }
      return TextEditingValue(
        text: upper,
        selection: const TextSelection.collapsed(offset: 1),
      );
    }
    // Paste: keep extracted code so onChanged can distribute across boxes.
    final code = RoomCode.extract(text);
    return TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
  }
}
