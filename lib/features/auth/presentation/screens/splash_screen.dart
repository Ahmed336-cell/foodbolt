import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.45, curve: Curves.elasticOut),
  );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthCubit>();
    final settings = context.read<SettingsCubit>();
    await Future.wait([
      auth.checkSession(),
      Future<void>.delayed(const Duration(milliseconds: 2100)),
    ]);
    if (!mounted) return;

    if (!settings.state.onboardingSeen) {
      context.go('/onboarding');
    } else if (auth.state.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        width: double.infinity,
        color: AppTheme.background,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Image.asset(
                        AppAssets.logo,
                        height: 260,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      l10n.tagline,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: _BouncingDots(controller: _float),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (controller.value * 3 + i * 0.22) % 1;
            final lift = math.sin(phase * math.pi * 2).clamp(-1.0, 1.0) * 5;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -lift),
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
