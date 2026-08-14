import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/settings_cubit.dart';

/// Toggles the app between English and Arabic. `compact` renders a small pill
/// for headers; the full variant is a labelled segmented control.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final code = context.select<SettingsCubit, String>(
      (c) => c.state.settings.localeCode ?? Localizations.localeOf(context).languageCode,
    );
    final isArabic = code == 'ar';

    if (compact) {
      return TextButton.icon(
        onPressed: () => cubit.setLocale(isArabic ? 'en' : 'ar'),
        icon: const Icon(Icons.language, size: 18),
        label: Text(
          isArabic ? 'EN' : 'العربية',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: TextButton.styleFrom(foregroundColor: Colors.black),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.language,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LanguageChip(
                label: context.l10n.english,
                selected: !isArabic,
                onTap: () => cubit.setLocale('en'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LanguageChip(
                label: context.l10n.arabic,
                selected: isArabic,
                onTap: () => cubit.setLocale('ar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
