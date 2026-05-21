import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// **PaletteVariant** — v6.0 단청 마이그레이션 kill-switch.
///
/// Firebase Remote Config key `palette_variant` 로 원격 토글.
/// 21개 consumer 파일의 `static const SoriColors.X` 참조는 컴파일 타임에 박혀 있으므로
/// 이 스위치는 **ThemeData(AppBar/FilledButton/InputDecoration 등 글로벌 테마)** 에만 영향.
/// 진짜 50/50 A/B를 원하면 모든 SoriColors 참조를 `Theme.of(context)` 기반으로 리팩토링 필요.
enum PaletteVariant {
  /// 단청 (v6.0 기본) — 한지 cream bg, 녹청 #1F7A6B primary, 석간주 #A0524A accent.
  dancheong,

  /// 레거시 Teal (v3.1) — 흰 bg, #2AB7A9 primary. 단청 롤백 시 사용.
  teal,
}

/// 전역 알림. main.dart의 ListenableBuilder에 merge하면 ThemeData가 재빌드됨.
final ValueNotifier<PaletteVariant> paletteVariantNotifier =
    ValueNotifier<PaletteVariant>(PaletteVariant.dancheong);

class PaletteService {
  PaletteService._();

  static const _remoteKey = 'palette_variant';
  static const _defaultRaw = 'dancheong';

  /// Firebase Remote Config 부팅 fetch. 실패해도 앱은 dancheong 기본값으로 계속 작동.
  /// main.dart의 _initFirebase 다음에 best-effort로 호출.
  static Future<void> fetchAndApply() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await rc.setDefaults(const {_remoteKey: _defaultRaw});
      await rc.fetchAndActivate();
      final raw = rc.getString(_remoteKey);
      paletteVariantNotifier.value = _parse(raw);
    } catch (e) {
      // Remote Config 미설정 / 네트워크 실패 → 기본값 (dancheong) 유지.
      // ignore: avoid_print
      print('PaletteService: fetch failed, using dancheong default — $e');
    }
  }

  /// 디버그 / Settings 화면에서 수동 토글용. 영구 저장 X (다음 부팅 시 Remote Config 우선).
  static void overrideLocal(PaletteVariant v) {
    paletteVariantNotifier.value = v;
  }

  static PaletteVariant _parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'teal':
        return PaletteVariant.teal;
      case 'dancheong':
      default:
        return PaletteVariant.dancheong;
    }
  }
}
