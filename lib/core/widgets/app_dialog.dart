import 'package:flutter/material.dart';

import '../localization/l10n_extension.dart';
import '../theme/app_theme.dart';

enum AppDialogVariant { normal, destructive }

/// Branded confirmation dialog — use [showAppConfirmDialog] to display.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.variant = AppDialogVariant.normal,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final AppDialogVariant variant;
  final IconData? icon;

  bool get _destructive => variant == AppDialogVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final accent = _destructive ? const Color(0xFFC62828) : AppTheme.primary;
    final accentSoft =
        _destructive ? const Color(0xFFFFEBEE) : const Color(0xFFFFE8D6);
    final defaultIcon =
        _destructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded;

    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon ?? defaultIcon, color: accent, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                child: Text(confirmLabel),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                child: Text(cancelLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  AppDialogVariant variant = AppDialogVariant.normal,
  IconData? icon,
}) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel ?? l10n.cancel,
      variant: variant,
      icon: icon,
    ),
  );
}
