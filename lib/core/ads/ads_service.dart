import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Loads / shows interstitial (photo or video from AdMob).
///
/// Unit: foodrush_Interstitial / foodrush_Interstitial_ios.
/// Placement: once when room phase becomes completed (natural pause).
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  InterstitialAd? _interstitial;
  var _initialized = false;
  var _loadingInterstitial = false;
  var _showingInterstitial = false;

  bool get isReady => _initialized;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await MobileAds.instance
          .initialize()
          .timeout(const Duration(seconds: 8));
      _initialized = true;
      unawaited(preloadInterstitial());
    } catch (e) {
      debugPrint('Ads init failed: $e');
    }
  }

  Future<void> preloadInterstitial() async {
    if (!_initialized || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    try {
      await InterstitialAd.load(
        adUnitId: AdIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            _loadingInterstitial = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitial = null;
                _showingInterstitial = false;
                unawaited(preloadInterstitial());
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial show failed: $error');
                ad.dispose();
                _interstitial = null;
                _showingInterstitial = false;
                unawaited(preloadInterstitial());
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial load failed: $error');
            _loadingInterstitial = false;
            _interstitial = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial load error: $e');
      _loadingInterstitial = false;
    }
  }

  /// Shows room-finished interstitial when ready. No-op if unavailable.
  Future<void> showRoomFinishedAd() async {
    if (!_initialized || _showingInterstitial) return;
    final ad = _interstitial;
    if (ad == null) {
      unawaited(preloadInterstitial());
      return;
    }
    _showingInterstitial = true;
    _interstitial = null;
    await ad.show();
  }
}
