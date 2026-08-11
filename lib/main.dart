import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Missing .env is fine in mock mode.
  }
  // USE_MOCKS=false + valid SUPABASE_* → live backend; else mocks.
  await configureDependencies();
  await sl<SettingsCubit>().load();
  await sl<DeepLinkCubit>().startListening();
  runApp(const FoodRushApp());
}

class FoodRushApp extends StatefulWidget {
  const FoodRushApp({super.key});

  @override
  State<FoodRushApp> createState() => _FoodRushAppState();
}

class _FoodRushAppState extends State<FoodRushApp> {
  late final _router = createRouter();

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
