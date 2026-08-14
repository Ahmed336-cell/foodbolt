import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads bundled env, then overlays gitignored project-root `.env` (secrets).
Future<void> loadAppEnv() async {
  try {
    await dotenv.load(fileName: 'assets/env/.env', isOptional: true);
    debugPrint(
      'Env: assets loaded (keys=${dotenv.env.length}, '
      'USE_MOCKS=${dotenv.env['USE_MOCKS']}, '
      'urlLen=${dotenv.env['SUPABASE_URL']?.length ?? 0}, '
      'keyLen=${dotenv.env['SUPABASE_ANON_KEY']?.length ?? 0})',
    );
  } catch (e) {
    debugPrint('Env: assets/env/.env not loaded ($e)');
  }

  // Local override — never commit root `.env`.
  // Works on host / desktop / when cwd is project. Android app cwd usually can't see this.
  if (kIsWeb) return;
  try {
    final file = await _findRootEnvFile();
    if (file == null) {
      debugPrint('Env: root .env not found near cwd=${Directory.current.path}');
      return;
    }
    final lines = await file.readAsLines();
    var merged = 0;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final key = line.substring(0, eq).trim();
      var value = line.substring(eq + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      if (key.isEmpty) continue;
      // Non-empty root values win (so empty assets placeholders don't block).
      if (value.isNotEmpty) {
        dotenv.env[key] = value;
        merged++;
      }
    }
    debugPrint('Env: merged root ${file.path} ($merged keys)');
  } catch (e) {
    debugPrint('Env: root .env merge skipped ($e)');
  }
}

Future<File?> _findRootEnvFile() async {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final env = File('${dir.path}/.env');
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (await env.exists() && await pubspec.exists()) return env;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  final fallback = File('.env');
  if (await fallback.exists()) return fallback;
  return null;
}
