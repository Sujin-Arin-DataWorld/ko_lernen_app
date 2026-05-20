import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Wiederverwendbarer Banner-Wrapper. Lädt automatisch, disposed sauber.
/// Wenn Anzeige fehlschlägt: rendert nichts (kein Layout-Sprung).
class AppBannerAd extends StatefulWidget {
  final AdSize size;
  const AppBannerAd({super.key, this.size = AdSize.banner});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Nicht auf Web laden
    if (kIsWeb) return;
    await AdService.init();
    final ad = AdService.buildBanner(
      size: widget.size,
      onLoaded: (_) {
        if (mounted) setState(() => _loaded = true);
      },
    );
    ad.load();
    if (mounted) setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
