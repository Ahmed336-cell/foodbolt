import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.localeCode,
    this.onboardingSeen = false,
  });

  /// `null` means "follow the device locale".
  final String? localeCode;
  final bool onboardingSeen;

  AppSettings copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? onboardingSeen,
  }) {
    return AppSettings(
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  @override
  List<Object?> get props => [localeCode, onboardingSeen];
}
