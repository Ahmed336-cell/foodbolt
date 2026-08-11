import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Persists settings when the platform channel works; falls back to an
/// in-memory map when SharedPreferences fails (common after hot restart).
class SettingsPrefsRepository implements SettingsRepository {
  static const _localeKey = 'settings.locale';
  static const _onboardingKey = 'settings.onboarding_seen';

  SharedPreferences? _prefs;
  bool _prefsBroken = false;

  /// Always-available cache so locale/onboarding still change when the
  /// native channel is down.
  final Map<String, Object?> _memory = {};

  Future<SharedPreferences?> _tryPrefs() async {
    if (_prefsBroken) return null;
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (e, st) {
      _prefsBroken = true;
      debugPrint('SharedPreferences unavailable, using memory: $e\n$st');
      return null;
    }
  }

  @override
  Future<AppSettings> load() async {
    final prefs = await _tryPrefs();
    if (prefs != null) {
      try {
        final locale = prefs.getString(_localeKey);
        final seen = prefs.getBool(_onboardingKey) ?? false;
        if (locale != null) _memory[_localeKey] = locale;
        _memory[_onboardingKey] = seen;
        return AppSettings(localeCode: locale, onboardingSeen: seen);
      } catch (e) {
        _prefsBroken = true;
        debugPrint('SharedPreferences load failed: $e');
      }
    }
    return AppSettings(
      localeCode: _memory[_localeKey] as String?,
      onboardingSeen: (_memory[_onboardingKey] as bool?) ?? false,
    );
  }

  @override
  Future<void> saveLocale(String? localeCode) async {
    if (localeCode == null) {
      _memory.remove(_localeKey);
    } else {
      _memory[_localeKey] = localeCode;
    }

    final prefs = await _tryPrefs();
    if (prefs == null) return;
    try {
      if (localeCode == null) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, localeCode);
      }
    } catch (e) {
      _prefsBroken = true;
      debugPrint('SharedPreferences saveLocale failed: $e');
    }
  }

  @override
  Future<void> setOnboardingSeen(bool seen) async {
    _memory[_onboardingKey] = seen;

    final prefs = await _tryPrefs();
    if (prefs == null) return;
    try {
      await prefs.setBool(_onboardingKey, seen);
    } catch (e) {
      _prefsBroken = true;
      debugPrint('SharedPreferences setOnboardingSeen failed: $e');
    }
  }
}
