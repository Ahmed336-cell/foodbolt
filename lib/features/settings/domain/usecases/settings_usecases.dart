import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class LoadSettings {
  LoadSettings(this._repository);
  final SettingsRepository _repository;

  Future<AppSettings> call() => _repository.load();
}

class SaveLocale {
  SaveLocale(this._repository);
  final SettingsRepository _repository;

  Future<void> call(String? localeCode) => _repository.saveLocale(localeCode);
}

class CompleteOnboarding {
  CompleteOnboarding(this._repository);
  final SettingsRepository _repository;

  Future<void> call() => _repository.setOnboardingSeen(true);
}

class ResetOnboarding {
  ResetOnboarding(this._repository);
  final SettingsRepository _repository;

  Future<void> call() => _repository.setOnboardingSeen(false);
}
