import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme/app_theme.dart';
import 'ad_ids.dart';
import 'ads_service.dart';

/// Anchored adaptive banner — idle / review screens only.
///
/// Placement: Home, Lobby, History, Profile, Suggestions, Selected,
/// Order details, Receipt, Cost share, Payment, Room summary.
/// Skip: race, voting, order entry, auth gates.
///
/// Ad unit: foodrush_banner_ads (Android) / foodrush_banner_ios (iOS).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  var _loaded = false;
  var _loading = false;
  var _retries = 0;
  var _useFallbackSize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null && !_loading && !_loaded) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (kIsWeb || _loading || !mounted) return;
    _loading = true;

    await AdsService.instance.initialize();
    if (!mounted || !AdsService.instance.isReady) {
      _loading = false;
      return;
    }

    final AdSize size;
    if (_useFallbackSize) {
      size = AdSize.banner;
    } else {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final adaptive =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      size = adaptive ?? AdSize.banner;
    }

    if (!mounted) {
      _loading = false;
      return;
    }

    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _loading = false;
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'Banner failed (${AdIds.banner}): $error',
          );
          ad.dispose();
          _loading = false;
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });

          // code 3 = NO_FILL — retry later; try smaller size once.
          if (_retries < 3) {
            _retries++;
            if (error.code == 3) _useFallbackSize = true;
            Future<void>.delayed(Duration(seconds: 8 * _retries), () {
              if (mounted && !_loaded) unawaited(_load());
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: ColoredBox(
        color: AppTheme.surface,
        child: SizedBox(
          width: double.infinity,
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
