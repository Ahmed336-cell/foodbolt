import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/env.dart';
import 'core/config/load_app_env.dart';
import 'core/di/injection.dart';
import 'core/localization/l10n_extension.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/deep_link/presentation/cubit/deep_link_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  await loadAppEnv();
  try {
    // USE_MOCKS=false + valid SUPABASE_* in assets/env/.env → live backend.
    await configureDependencies();
  } catch (e) {
    debugPrint('Backend boot failed: $e');
    runApp(_BackendConfigErrorApp(message: AppEnv.backendError ?? e.toString()));
    return;
  }
  await sl<SettingsCubit>().load();
  await sl<DeepLinkCubit>().startListening();
  runApp(const FoodRushApp());
}

class _BackendConfigErrorApp extends StatelessWidget {
  const _BackendConfigErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Backend not connected',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(message),
                const SizedBox(height: 16),
                const Text(
                  '1) Put SUPABASE_URL + SUPABASE_ANON_KEY in assets/env/.env\n'
                  '2) Set USE_MOCKS=false\n'
                  '3) flutter clean && flutter run (full restart)\n'
                  '4) Enable Anonymous sign-in in Supabase Auth',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodRushApp extends StatefulWidget {
  const FoodRushApp({super.key, this.initialLocation});

  /// Override start route (used by screenshot / integration tests).
  final String? initialLocation;

  @override
  State<FoodRushApp> createState() => _FoodRushAppState();
}

class _FoodRushAppState extends State<FoodRushApp> {
  late final _router = createRouter(
    initialLocation: widget.initialLocation ?? '/splash',
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthCubit>()..checkSession()),
        BlocProvider.value(value: sl<DeepLinkCubit>()),
        BlocProvider.value(value: sl<SettingsCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) => a.locale != b.locale,
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'FoodRush',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: settings.locale,
            supportedLocales: AppLocales.supported,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
