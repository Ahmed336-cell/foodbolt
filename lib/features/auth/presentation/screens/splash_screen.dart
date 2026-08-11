import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
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
  late final Animation<double> _titleSlide = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.secondary, AppTheme.primary, AppTheme.accent],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, _) => CustomPaint(
                  painter: _FloatingFoodPainter(_float.value),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: const _BoltLogo(),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _titleSlide,
                    builder: (context, child) => Opacity(
                      opacity: _titleSlide.value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - _titleSlide.value)),
                        child: child,
                      ),
                    ),
                    child: Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      l10n.tagline,
                      style: const TextStyle(
                        color: Colors.white70,
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

class _BoltLogo extends StatelessWidget {
  const _BoltLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Text('🍔', style: TextStyle(fontSize: 52)),
          Positioned(
            right: 14,
            bottom: 14,
            child: Icon(Icons.bolt_rounded, size: 34, color: AppTheme.accent),
          ),
        ],
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
                    color: Colors.white,
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

class _FloatingFoodPainter extends CustomPainter {
  _FloatingFoodPainter(this.progress);

  final double progress;

  static const _emojis = ['🍕', '🍔', '🌮', '🍜', '🍣', '🥤', '🍟', '🍰'];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _emojis.length; i++) {
      final seed = (i + 1) * 0.137;
      final x = size.width * ((seed * 7) % 1);
      final travel = (progress + seed) % 1;
      final y = size.height * (1.1 - travel * 1.25);
      final drift = math.sin((travel + seed) * math.pi * 2) * 18;
      final opacity = (math.sin(travel * math.pi)).clamp(0.0, 1.0) * 0.35;

      final painter = TextPainter(
        text: TextSpan(
          text: _emojis[i],
          style: TextStyle(
            fontSize: 26 + (i % 3) * 8,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.saveLayer(
        Rect.fromLTWH(x + drift, y, painter.width, painter.height),
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
      painter.paint(canvas, Offset(x + drift, y));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingFoodPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
