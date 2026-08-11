import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> saveLocale(String? localeCode);
  Future<void> setOnboardingSeen(bool seen);
}
