import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show AssetBundle, AssetManifest, rootBundle;

import '../models/scenario.dart';

/// Resolves the scene poster (PNG) and ambient loop (MP4) for a scenario, with a
/// **convention-first, category-fallback** strategy.
///
/// Convention: drop a file named after the scenario id and it is picked up
/// automatically — no code or pubspec change needed (the `scenes/` and
/// `video/loops/` folders are registered as directories in pubspec):
///   • poster: `assets/illustrations/scenes/{id}.png`
///   • loop:   `assets/video/loops/scene_{id}.mp4`
///
/// When a dedicated asset is absent, the scenario's category backdrop
/// ([ScenarioBackdrop.backdropKey], one of cafe/directions/market/restaurant/
/// hotel) is used instead, so every scenario always has *something*.
///
/// The manifest must be preloaded once via [load] (done in `main.dart`). If it
/// never loaded (or failed), the resolver silently degrades to category paths.
class SceneAssetResolver {
  SceneAssetResolver._();

  static Set<String> _assets = const {};
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  /// Loads the app's asset manifest once and caches the set of bundled asset
  /// paths. Safe to await repeatedly; failure leaves the resolver in
  /// "category fallback only" mode rather than throwing.
  static Future<void> load([AssetBundle? bundle]) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        bundle ?? rootBundle,
      );
      _assets = manifest.listAssets().toSet();
      _loaded = true;
    } catch (_) {
      // Bundle unavailable (e.g. very early startup / headless test) → keep the
      // category-fallback behaviour. Mark loaded so we don't retry-loop.
      _assets = const {};
      _loaded = true;
    }
  }

  /// Best poster for [s]: dedicated `scenes/{id}.png` when bundled, else the
  /// category `scenes/{key}.png`, else null (call site shows a mascot).
  static String? posterAsset(Scenario s) {
    final dedicated = 'assets/illustrations/scenes/${s.id}.png';
    if (_assets.contains(dedicated)) {
      return dedicated;
    }
    final key = s.backdropKey;
    if (key != null) {
      return 'assets/illustrations/scenes/$key.png';
    }
    return null;
  }

  /// Best ambient loop for [s]: dedicated `loops/scene_{id}.mp4` when bundled,
  /// else the category `loops/scene_{key}.mp4`, else null (call site shows the
  /// static poster only). `SoriPosterLoop` additionally falls back to its poster
  /// if the returned file fails to initialise.
  static String? loopAsset(Scenario s) {
    final dedicated = 'assets/video/loops/scene_${s.id}.mp4';
    if (_assets.contains(dedicated)) {
      return dedicated;
    }
    final key = s.backdropKey;
    if (key != null) {
      return 'assets/video/loops/scene_$key.mp4';
    }
    return null;
  }

  /// Test seam: inject a known asset set without touching the real bundle.
  @visibleForTesting
  static void debugSetAssets(Set<String> assets) {
    _assets = Set<String>.from(assets);
    _loaded = true;
  }

  /// Test seam: reset to the unloaded, empty state.
  @visibleForTesting
  static void debugReset() {
    _assets = const {};
    _loaded = false;
  }
}
