import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob-Wrapper — Banner + Interstitial.
///
/// **Test-IDs**: Google's offizielle Test-AdUnit-IDs. Beim Production-Release
/// durch echte AdUnit-IDs ersetzen (siehe `_AdIds`).
class AdService {
  static bool _initialized = false;

  /// Vor jeder Anzeige aufrufen (idempotent).
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdMob init fehlgeschlagen: $e');
    }
  }

  // ── Banner ────────────────────────────────────────────
  /// Erstellt eine BannerAd. Caller verantwortlich für `load()` + `dispose()`.
  static BannerAd buildBanner({AdSize size = AdSize.banner, void Function(Ad)? onLoaded}) {
    return BannerAd(
      adUnitId: _AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded:   (ad) => onLoaded?.call(ad),
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: $err');
          ad.dispose();
        },
      ),
    );
  }

  // ── Interstitial ──────────────────────────────────────
  static InterstitialAd? _interstitial;

  /// Vorladen — z.B. beim Spielstart, dann später anzeigen.
  static Future<void> preloadInterstitial() async {
    await init();
    try {
      await InterstitialAd.load(
        adUnitId: _AdIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitial = ad,
          onAdFailedToLoad: (err) {
            debugPrint('Interstitial failed: $err');
            _interstitial = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial preload error: $e');
    }
  }

  /// Anzeigen falls geladen. Nach Anzeige automatisch nachladen.
  static Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial(); // für nächstes Mal
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitial = null;
      },
    );
    await ad.show();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdUnit-IDs
// ─────────────────────────────────────────────────────────────────────────────
class _AdIds {
  // ⚠️ Test-IDs (immer Test-Ads anzeigen, nie echtes Geld). Vor Production
  // im AdMob-Dashboard echte AdUnit-IDs erstellen und hier einsetzen.

  static const _useTestIds = true;  // im Production-Release auf false

  static const _testBannerAndroid       = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testBannerIos           = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialIos     = 'ca-app-pub-3940256099942544/4411468910';

  // TODO: durch echte IDs ersetzen
  static const _prodBannerAndroid       = '';
  static const _prodInterstitialAndroid = '';
  static const _prodBannerIos           = '';
  static const _prodInterstitialIos     = '';

  static String get banner {
    if (_useTestIds || (Platform.isAndroid ? _prodBannerAndroid : _prodBannerIos).isEmpty) {
      return Platform.isAndroid ? _testBannerAndroid : _testBannerIos;
    }
    return Platform.isAndroid ? _prodBannerAndroid : _prodBannerIos;
  }

  static String get interstitial {
    if (_useTestIds || (Platform.isAndroid ? _prodInterstitialAndroid : _prodInterstitialIos).isEmpty) {
      return Platform.isAndroid ? _testInterstitialAndroid : _testInterstitialIos;
    }
    return Platform.isAndroid ? _prodInterstitialAndroid : _prodInterstitialIos;
  }
}
