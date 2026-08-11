import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static bool get useMocks {
    final value = dotenv.env['USE_MOCKS']?.toLowerCase();
    if (value == null || value.isEmpty) return true;
    return value != 'false';
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get branchKey => dotenv.env['BRANCH_KEY'] ?? '';

  /// Optional override, e.g. `https://foodrush.app/join` or `foodrush://join`.
  static String get inviteBaseUrl => dotenv.env['INVITE_BASE_URL'] ?? '';

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
