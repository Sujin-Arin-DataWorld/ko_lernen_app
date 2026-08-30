import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart'
    show AssetBundle, AssetManifest, rootBundle;

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
/// ([ScenarioBackdrop.backdropKey], one of the 12 category keys listed on that
/// getter) is used instead, so every scenario always has *something*.
///
/// The manifest must be preloaded once via [load] (done in `main.dart`). If it
/// never loaded (or failed), the resolver silently degrades to category paths.
class SceneAssetResolver {
  SceneAssetResolver._();

  static const _posterFallbackAliases = <String, String>{
    // User-authored theme_park.png replaces this automatically when bundled.
    'theme_park': 'market',
  };

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
      final category = 'assets/illustrations/scenes/$key.png';
      if (!_loaded || _assets.isEmpty || _assets.contains(category)) {
        return category;
      }
      final alias = _posterFallbackAliases[key];
      if (alias != null) {
        return 'assets/illustrations/scenes/$alias.png';
      }
    }
    return null;
  }

  /// Best ambient loop for [s]: dedicated `loops/scene_{id}.mp4` when bundled,
  /// else the category `loops/scene_{key}.mp4` **if that is bundled too**, else
  /// null (call site shows the static poster only). `SoriPosterLoop` still falls
  /// back to its poster if a returned file fails to initialise — this check just
  /// avoids paying for a doomed decoder open on the 6 categories that have a
  /// poster but no loop yet.
  static String? loopAsset(Scenario s) {
    final dedicated = 'assets/video/loops/scene_${s.id}.mp4';
    if (_assets.contains(dedicated)) {
      return dedicated;
    }
    final key = s.backdropKey;
    if (key != null) {
      final category = 'assets/video/loops/scene_$key.mp4';
      // The Theme Park Date pack intentionally ships without a loop. A later
      // user-supplied loop is picked up, but an absent one is never guessed.
      if (key == 'theme_park' && !_assets.contains(category)) {
        return null;
      }
      // 매니페스트를 실제로 읽은 상태에서 번들에 없다고 확인되면 null 을 준다.
      // 없는 파일 경로를 돌려주면 `SoriPosterLoop` 가 매번 디코더를 열었다
      // 실패하고 포스터로 되돌아온다 — 헛수고 + 첫 프레임 깜빡임.
      // 포스터와 달리 루프는 카테고리 7종(home·office·station·taxi·airport·
      // convenience·pharmacy)에 아직 파일이 없어서 이 경로가 실제로 밟힌다.
      // 매니페스트가 없거나(초기화 전·테스트) 비면 기존처럼 낙관적으로 반환.
      if (!_loaded || _assets.isEmpty || _assets.contains(category)) {
        return category;
      }
      return null;
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
