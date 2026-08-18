import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/settings_usecases.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const AppSettings(),
    this.loaded = false,
  });

  final AppSettings settings;
  final bool loaded;

  Locale? get locale =>
      settings.localeCode == null ? null : Locale(settings.localeCode!);

  bool get onboardingSeen => settings.onboardingSeen;

  SettingsState copyWith({AppSettings? settings, bool? loaded}) => SettingsState(
        settings: settings ?? this.settings,
        loaded: loaded ?? this.loaded,
      );

  @override
  List<Object?> get props => [settings, loaded];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required LoadSettings loadSettings,
    required SaveLocale saveLocale,
    required CompleteOnboarding completeOnboarding,
    required ResetOnboarding resetOnboarding,
  })  : _loadSettings = loadSettings,
        _saveLocale = saveLocale,
        _completeOnboarding = completeOnboarding,
        _resetOnboarding = resetOnboarding,
        super(const SettingsState());

  final LoadSettings _loadSettings;
  final SaveLocale _saveLocale;
  final CompleteOnboarding _completeOnboarding;
  final ResetOnboarding _resetOnboarding;

  Future<void> load() async {
    final settings = await _loadSettings();
    emit(SettingsState(settings: settings, loaded: true));
  }

  Future<void> setLocale(String? localeCode) async {
    // Optimistic UI update first — prefs can fail after hot restart.
    emit(
      state.copyWith(
        settings: localeCode == null
            ? state.settings.copyWith(clearLocale: true)
            : state.settings.copyWith(localeCode: localeCode),
      ),
    );
    try {
      await _saveLocale(localeCode);
    } catch (_) {
      // Memory fallback in repository already applied; ignore channel errors.
    }
  }

  Future<void> finishOnboarding() async {
    if (state.settings.onboardingSeen) return;
    emit(state.copyWith(settings: state.settings.copyWith(onboardingSeen: true)));
    try {
      await _completeOnboarding();
    } catch (_) {
      // Still leave onboarding marked done in memory so navigation proceeds.
    }
  }

  Future<void> resetOnboarding() async {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(onboardingSeen: false),
      ),
    );
    try {
      await _resetOnboarding();
    } catch (_) {}
  }
}
