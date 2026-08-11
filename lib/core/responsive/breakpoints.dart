import 'package:flutter/material.dart';

/// Layout breakpoints for FoodRush.
class Breakpoints {
  Breakpoints._();

  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

enum AppSizeClass { phone, tablet, desktop }

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  AppSizeClass get sizeClass {
    final w = screenWidth;
    if (w >= Breakpoints.desktop) return AppSizeClass.desktop;
    if (w >= Breakpoints.phone) return AppSizeClass.tablet;
    return AppSizeClass.phone;
  }

  bool get isPhone => sizeClass == AppSizeClass.phone;

  bool get isTablet => sizeClass == AppSizeClass.tablet;

  bool get isDesktop => sizeClass == AppSizeClass.desktop;

  bool get isWide => screenWidth >= Breakpoints.phone;

  /// Horizontal page gutter.
  double get pagePadding => switch (sizeClass) {
        AppSizeClass.phone => 20,
        AppSizeClass.tablet => 32,
        AppSizeClass.desktop => 48,
      };

  /// Max readable content width (forms / lists).
  double get contentMaxWidth => switch (sizeClass) {
        AppSizeClass.phone => double.infinity,
        AppSizeClass.tablet => 720,
        AppSizeClass.desktop => 880,
      };

  /// Slightly larger type on wide screens for display titles.
  double get displayScale => isPhone ? 1 : isTablet ? 1.08 : 1.15;

  T responsiveValue<T>({
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    return switch (sizeClass) {
      AppSizeClass.phone => phone,
      AppSizeClass.tablet => tablet ?? phone,
      AppSizeClass.desktop => desktop ?? tablet ?? phone,
    };
  }
}
