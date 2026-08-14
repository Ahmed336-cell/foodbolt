import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Initializes Supabase when credentials exist and mocks are off.
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool initialized = false;

  static Future<bool> init() async {
    if (!AppEnv.hasSupabaseCredentials) {
      debugPrint('Supabase: missing SUPABASE_URL / SUPABASE_ANON_KEY');
      return false;
    }
    if (initialized) return true;

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        anonKey: AppEnv.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      initialized = true;
      debugPrint(
        'Supabase: initialized (${AppEnv.supabaseUrl})',
      );
      return true;
    } catch (e, st) {
      debugPrint('Supabase: initialize failed: $e\n$st');
      return false;
    }
  }

  static SupabaseClient get client {
    if (!initialized) {
      throw StateError('SupabaseBootstrap.init() must run before use.');
    }
    return Supabase.instance.client;
  }
}
