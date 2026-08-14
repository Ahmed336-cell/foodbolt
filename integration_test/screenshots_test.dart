import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbolt/core/di/injection.dart';
import 'package:foodbolt/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:foodbolt/features/deep_link/presentation/cubit/deep_link_cubit.dart';
import 'package:foodbolt/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:foodbolt/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store / marketing screenshots. Driven by Fastlane:
///   cd android && bundle exec fastlane screenshots
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await dotenv.load(fileName: 'assets/env/.env');
    } catch (_) {}
    dotenv.env['USE_MOCKS'] = 'true';
    if (sl.isRegistered<AuthCubit>()) {
      await sl.reset(dispose: true);
    }
    await configureDependencies();
    await sl<SettingsCubit>().load();
    await sl<DeepLinkCubit>().startListening();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> capture(
    WidgetTester tester,
    String name, {
    required String route,
    Future<void> Function()? prepare,
  }) async {
    await prepare?.call();
    await tester.pumpWidget(FoodRushApp(initialLocation: route));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot(name);
  }

  testWidgets('01_onboarding', (tester) async {
    await capture(
      tester,
      '01_onboarding',
      route: '/onboarding',
      prepare: () async {
        final auth = sl<AuthCubit>();
        if (auth.state.isAuthenticated) await auth.logout();
        await auth.checkSession();
      },
    );
  });

  testWidgets('02_welcome', (tester) async {
    await capture(
      tester,
      '02_welcome',
      route: '/welcome',
      prepare: () async {
        await sl<SettingsCubit>().finishOnboarding();
        final auth = sl<AuthCubit>();
        if (auth.state.isAuthenticated) await auth.logout();
        await auth.checkSession();
      },
    );
  });

  testWidgets('03_login', (tester) async {
    await capture(
      tester,
      '03_login',
      route: '/login',
      prepare: () async {
        await sl<SettingsCubit>().finishOnboarding();
        final auth = sl<AuthCubit>();
        if (auth.state.isAuthenticated) await auth.logout();
      },
    );
  });

  testWidgets('04_home', (tester) async {
    await capture(
      tester,
      '04_home',
      route: '/home',
      prepare: () async {
        await sl<SettingsCubit>().finishOnboarding();
        final auth = sl<AuthCubit>();
        if (!auth.state.isAuthenticated) {
          await auth.continueAsGuest('Screenshot Guest');
        }
      },
    );
  });

  testWidgets('05_create_room', (tester) async {
    await capture(
      tester,
      '05_create_room',
      route: '/create-room',
      prepare: () async {
        await sl<SettingsCubit>().finishOnboarding();
        final auth = sl<AuthCubit>();
        if (!auth.state.isAuthenticated) {
          await auth.continueAsGuest('Screenshot Guest');
        }
      },
    );
  });
}
