import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../settings/presentation/widgets/language_switch.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final brandHeader = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, size: 34, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: context.responsiveValue(
                      phone: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    ),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    final hero = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.asset(
        AppAssets.welcomeFriends,
        fit: BoxFit.contain,
        width: double.infinity,
        height: context.isWide ? double.infinity : null,
      ),
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n.welcomeSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l10n.createRoom,
          onPressed: () => context.push('/guest', extra: 'create'),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: l10n.joinRoom,
          onPressed: () => context.push('/guest', extra: 'join'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.push('/login'),
              child: Text(l10n.loginOrSignIn),
            ),
            const Text('·', style: TextStyle(color: AppTheme.textSecondary)),
            TextButton(
              onPressed: () => context.push('/guest'),
              child: Text(l10n.continueAsGuest),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: AppPage(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding,
            8,
            context.pagePadding,
            context.isPhone ? 12 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LanguageSwitch(compact: true),
              ),
              const SizedBox(height: 8),
              brandHeader,
              const SizedBox(height: 12),
              Expanded(
                child: context.isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 6, child: hero),
                          const SizedBox(width: 28),
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: actions,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: hero),
                          const SizedBox(height: 12),
                          actions,
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
