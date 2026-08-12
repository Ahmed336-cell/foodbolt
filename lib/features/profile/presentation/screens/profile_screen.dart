import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../settings/presentation/widgets/language_switch.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountBody,
      confirmLabel: l10n.deleteAccountConfirm,
      variant: AppDialogVariant.destructive,
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AuthCubit>().deleteAccount();
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final l10n = context.l10n;
    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.notSignedIn)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: AdaptivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AvatarCircle(name: user.displayName, color: user.avatarColor, size: 84),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            if (user.email != null)
              Text(user.email!, textAlign: TextAlign.center),
            if (user.isGuest)
              Center(child: Chip(label: Text(l10n.guest))),
            const SizedBox(height: 28),
            const LanguageSwitch(),
            const Spacer(),
            PrimaryButton(
              label: l10n.logout,
              onPressed: () async {
                await context.read<AuthCubit>().logout();
                if (context.mounted) context.go('/welcome');
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.deleteAccount,
              onPressed: () => _confirmDeleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
