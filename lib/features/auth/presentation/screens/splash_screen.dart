import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/ads_service.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/network/connectivity_guard.dart';
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

  StreamSubscription? _connectivitySub;
  var _offlineDialogOpen = false;
  var _navigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthCubit>();
    final settings = context.read<SettingsCubit>();

    // Ads must not block splash — MobileAds.init can hang on emulators.
    unawaited(AdsService.instance.initialize());

    await Future.wait([
      auth.checkSession(),
      Future<void>.delayed(const Duration(milliseconds: 2100)),
    ]);
    if (!mounted) return;

    final online = await _ensureOnline();
    if (!online || !mounted || _navigated) return;

    _goNext(auth, settings);
  }

  Future<bool> _ensureOnline() async {
    while (mounted) {
      final online = await ConnectivityGuard.hasInternet();
      if (online) {
        await _connectivitySub?.cancel();
        _connectivitySub = null;
        return true;
      }
      await _showOfflineDialog();
      // After dismiss via Retry, loop checks again.
    }
    return false;
  }

  Future<void> _showOfflineDialog() async {
    if (!mounted || _offlineDialogOpen) return;
    _offlineDialogOpen = true;

    _connectivitySub ??= ConnectivityGuard.onConnectivityChanged.listen((_) async {
      if (!_offlineDialogOpen || !mounted) return;
      if (await ConnectivityGuard.hasInternet() && mounted) {
        Navigator.of(context, rootNavigator: true).pop(true);
      }
    });

    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: const Icon(Icons.wifi_off_rounded, size: 36),
            title: Text(
              l10n.noInternetTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            content: Text(
              l10n.noInternetBody,
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.retryConnection),
                ),
              ),
            ],
          ),
        );
      },
    );

    _offlineDialogOpen = false;
  }

  void _goNext(AuthCubit auth, SettingsCubit settings) {
    if (_navigated || !mounted) return;
    _navigated = true;

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
    unawaited(_connectivitySub?.cancel());
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
