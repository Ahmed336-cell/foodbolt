import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/env.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../settings/presentation/widgets/language_switch.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.55, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.05, 0.7, curve: Curves.easeOutCubic),
    ),
  );
  late final Animation<double> _actions = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final l10n = context.l10n;
    final titleSize = context.responsiveValue(
      phone: 44.0,
      tablet: 56.0,
      desktop: 64.0,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF3E6),
              Color(0xFFFFE0C2),
              Color(0xFFFFF8F0),
            ],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: AppPage(
            padding: EdgeInsets.fromLTRB(
              context.pagePadding,
              8,
              context.pagePadding,
              context.isPhone ? 16 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const LanguageSwitch(compact: true),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push('/history'),
                      icon: const Icon(Icons.history_rounded),
                      tooltip: l10n.historyTitle,
                    ),
                    IconButton(
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.person_outline_rounded),
                      tooltip: l10n.profile,
                    ),
                  ],
                ),
                if (AppEnv.usingMocks) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: const Color(0xFFFFE0A3),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        AppEnv.liveBackendRequestedButUnavailable
                            ? 'Offline mock mode — rooms are NOT saved to Supabase. Fix `.env` SUPABASE_* and full restart.'
                            : 'Mock mode — rooms stay on this device only. Set USE_MOCKS=false + SUPABASE_* in `.env` for multi-phone join.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C3B00),
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final sideBySide = context.isWide &&
                              constraints.maxHeight > 420;
                          final brand = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: context.isPhone ? 12 : 24),
                              Text(
                                l10n.appName,
                                style: GoogleFonts.sora(
                                  fontSize: titleSize,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.tagline,
                                style: GoogleFonts.sora(
                                  fontSize: context.isPhone ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(height: context.isPhone ? 28 : 36),
                              if (user != null)
                                Row(
                                  children: [
                                    AvatarCircle(
                                      name: user.displayName,
                                      color: user.avatarColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.helloUser(user.displayName),
                                            style: GoogleFonts.sora(
                                              fontSize:
                                                  context.isPhone ? 20 : 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            l10n.homePrompt,
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );

                          final actions = FadeTransition(
                            opacity: _actions,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (sideBySide)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _HomePrimaryAction(
                                          label: l10n.createRoom,
                                          hint: l10n.createRoomSubtitle,
                                          icon: Icons.bolt_rounded,
                                          filled: true,
                                          onTap: () =>
                                              context.push('/create-room'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _HomePrimaryAction(
                                          label: l10n.joinRoom,
                                          hint: l10n.joinRoomSubtitle,
                                          icon: Icons.group_add_rounded,
                                          filled: false,
                                          onTap: () =>
                                              context.push('/join-room'),
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _HomePrimaryAction(
                                    label: l10n.createRoom,
                                    hint: l10n.createRoomSubtitle,
                                    icon: Icons.bolt_rounded,
                                    filled: true,
                                    onTap: () => context.push('/create-room'),
                                  ),
                                  const SizedBox(height: 12),
                                  _HomePrimaryAction(
                                    label: l10n.joinRoom,
                                    hint: l10n.joinRoomSubtitle,
                                    icon: Icons.group_add_rounded,
                                    filled: false,
                                    onTap: () => context.push('/join-room'),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => context.push('/history'),
                                  child: Text(
                                    l10n.historyTitle,
                                    style: GoogleFonts.sora(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (sideBySide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 5, child: brand),
                                const SizedBox(width: 32),
                                Expanded(flex: 4, child: actions),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              brand,
                              const Spacer(),
                              actions,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePrimaryAction extends StatelessWidget {
  const _HomePrimaryAction({
    required this.label,
    required this.hint,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppTheme.textPrimary;
    return Material(
      color: filled ? AppTheme.primary : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.isPhone ? 20 : 22,
            vertical: context.isPhone ? 18 : 22,
          ),
          child: Row(
            children: [
              Container(
                width: context.isPhone ? 48 : 52,
                height: context.isPhone ? 48 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: filled ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: foreground,
                      ),
                    ),
                    Text(
                      hint,
                      style: TextStyle(
                        color: filled
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: filled
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
