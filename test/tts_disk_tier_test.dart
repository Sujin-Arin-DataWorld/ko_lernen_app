import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_bundled_manifest.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

/// Task D — 디스크 캐시 히트 경로(_resolveAudio 2단)를 실제 파일시스템으로
/// 고정한다. [TtsService.setCacheDirForTesting]로 `_cacheDir`를 미리
/// 채워 두면 `_ensureCacheDir()`가 path_provider/플랫폼 채널을 건드리지
/// 않고 즉시 그 디렉터리를 반환하므로, Firebase(Storage/Functions) 없이도
/// 디스크 히트만 결정적으로 검증할 수 있다 — `resolveAudioForTesting`의
/// 기본 `allowSynthesis: false`와 무관하게, 디스크 히트는 3/4단(Storage/CF)에
/// 닿기도 전에 반환된다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const voice = 'female';
  const text = '디스크 히트 테스트';

  late Directory dir;

  setUp(() async {
    TtsBundledManifest.resetForTesting();
    dir = await Directory.systemTemp.createTemp('tts_disk_');
    TtsService.setCacheDirForTesting(dir);
  });

  tearDown(() async {
    TtsService.setCacheDirForTesting(null);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('디스크 캐시 히트: 번들 1단은 미스하고 2단 파일 경로를 반환하며 mtime을 지금으로 갱신한다', () async {
    final key = TtsCacheKey.forRequest(voice: voice, text: text);

    // 번들 1단이 실제로 이 텍스트를 갖고 있지 않은지 먼저 확인한다 — 있으면
    // _resolveAudio가 1단에서 바로 반환해 이 테스트가 검증하려는 디스크
    // 2단에 도달하지 않으므로, 그 경우 이 테스트의 전제 자체가 깨진다.
    final bundledPath = await key.bundledAssetPath();
    expect(
      bundledPath,
      isNull,
      reason:
          '테스트 문구($text)가 실제 first-line manifest에 새로 실리면 disk-tier 테스트가 '
          '무의미해진다 — 다른 미실린 문구로 바꿀 것',
    );

    final file = File('${dir.path}/${key.localFileName}');
    await file.writeAsBytes(_validMp3());
    final staleTime = DateTime.now().subtract(const Duration(days: 3));
    await file.setLastModified(staleTime);
    expect(
      DateTime.now().difference(file.lastModifiedSync()),
      greaterThan(const Duration(days: 1)),
      reason: 'mtime 조작이 실제로 반영됐는지 사전 확인',
    );

    final resolved = await TtsService.resolveAudioForTesting(text, voice);

    expect(resolved, isNotNull);
    expect(
      resolved!.path,
      file.path,
      reason: '디스크 히트는 TtsAudio.path(그 파일 경로)를 반환해야 한다 — bytes가 아니면 '
          '번들/Storage가 아니라 정확히 이 디스크 파일에서 왔다는 뜻이다',
    );

    // _touchCacheFile은 unawaited best-effort라 resolveAudioForTesting이
    // 반환한 시점에 아직 안 끝났을 수 있다 — 최대 2초 폴링한다.
    var touched = false;
    for (var i = 0; i < 40; i++) {
      if (DateTime.now().difference(file.lastModifiedSync()) <
          const Duration(minutes: 1)) {
        touched = true;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(
      touched,
      isTrue,
      reason: '캐시 히트 시 mtime이 지금으로 갱신돼야 mtime 기반 prune(§9-4)이 방금 재생된 '
          '파일을 최신으로 본다',
    );
  });
}

/// test/tts_bundled_manifest_test.dart의 `_validMp3()`와 같은 최소
/// MPEG-frame-sync 픽스처(0xFF 0xFB + 나머지 0) — `TtsCacheKey.isUsableAudio`가
/// 요구하는 32바이트 이상 + MPEG/ID3 시그니처만 만족하면 된다.
Uint8List _validMp3() => Uint8List.fromList(
  List<int>.filled(64, 0)
    ..[0] = 0xFF
    ..[1] = 0xFB,
);
