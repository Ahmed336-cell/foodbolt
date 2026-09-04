import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AdMob IDs for FoodRush (Android + iOS apps).
///
/// Android app: `ca-app-pub-1532909562450408~3136911130`
/// iOS app:     `ca-app-pub-1532909562450408~2945339448`
///
/// Debug builds use Google sample units to avoid invalid traffic.
/// Override any ID via `.env` if needed.
class AdIds {
  AdIds._();

  static const appIdAndroid = 'ca-app-pub-1532909562450408~3136911130';
  static const appIdIos = 'ca-app-pub-1532909562450408~2945339448';

  /// Android: foodrush_banner_ads
  static const productionBannerAndroid =
      'ca-app-pub-1532909562450408/8135910771';

  /// iOS: foodrush_banner_ios
  static const productionBannerIos = 'ca-app-pub-1532909562450408/4778130010';

  /// Android: foodrush_Interstitial
  static const productionInterstitialAndroid =
      'ca-app-pub-1532909562450408/8489415368';

  /// iOS: foodrush_Interstitial_ios
  static const productionInterstitialIos =
      'ca-app-pub-1532909562450408/9846623860';

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  static String get banner {
    if (kIsWeb) return _testBannerAndroid;
    final envKey = Platform.isIOS ? 'ADMOB_BANNER_IOS' : 'ADMOB_BANNER_ANDROID';
    final fromEnv = dotenv.env[envKey]?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (kDebugMode) {
      return Platform.isIOS ? _testBannerIos : _testBannerAndroid;
    }
    return Platform.isIOS ? productionBannerIos : productionBannerAndroid;
  }

  static String get interstitial {
    if (kIsWeb) return _testInterstitialAndroid;
    final envKey =
        Platform.isIOS ? 'ADMOB_INTERSTITIAL_IOS' : 'ADMOB_INTERSTITIAL_ANDROID';
    final fromEnv = dotenv.env[envKey]?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (kDebugMode) {
      return Platform.isIOS ? _testInterstitialIos : _testInterstitialAndroid;
    }
    return Platform.isIOS
        ? productionInterstitialIos
        : productionInterstitialAndroid;
  }
}
