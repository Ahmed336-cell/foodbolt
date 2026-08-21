import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.localeCode,
    this.onboardingSeen = false,
    this.guideSeen = false,
  });

  /// `null` means "follow the device locale".
  final String? localeCode;
  final bool onboardingSeen;
  final bool guideSeen;

  AppSettings copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? onboardingSeen,
    bool? guideSeen,
  }) {
    return AppSettings(
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      guideSeen: guideSeen ?? this.guideSeen,
    );
  }

  @override
  List<Object?> get props => [localeCode, onboardingSeen, guideSeen];
}
