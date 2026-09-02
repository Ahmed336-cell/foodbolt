import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  /// Set by [configureDependencies] after backend choice.
  static bool usingMocks = true;

  /// Human-readable reason when live backend cannot start.
  static String? backendError;

  static bool get useMocks {
    final value = dotenv.env['USE_MOCKS']?.toLowerCase();
    if (value == null || value.isEmpty) return true;
    return value != 'false';
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  static String get branchKey => dotenv.env['BRANCH_KEY'] ?? '';

  /// Optional HTTPS override, e.g. `https://foodrush.app/join`.
  static String get inviteBaseUrl => dotenv.env['INVITE_BASE_URL'] ?? '';

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT') &&
      supabaseAnonKey != 'your_anon_key';

  /// True when live DB was requested but credentials/init failed.
  static bool liveBackendRequestedButUnavailable = false;
}
