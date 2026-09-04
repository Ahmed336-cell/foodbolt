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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Need MediaQuery width for adaptive size — load once.
    if (_ad == null) {
      _load();
    }
  }

  Future<void> _load() async {
    if (kIsWeb) return;
    if (!AdsService.instance.isReady) {
      await AdsService.instance.initialize();
    }
    if (!mounted || !AdsService.instance.isReady) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
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
