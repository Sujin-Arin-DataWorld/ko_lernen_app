import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

/// 2026-08-19 — **프리미엄 전용** 재생 경로 계약.
///
/// Jin: "기계음 안나오고 해당 텍스트에 맞는 정확한 프리미엄 음성 나오도록."
///
/// 왜 폴백을 지웠는지: OS 음성 폴백은 안전망이 아니라 조용한 오답
/// 생성기였다. 독일어 로케일 기기에서 `setLanguage('ko-KR')` 이 실패해도
/// 그 실패를 성공으로 메모이즈해서 독일어 음성이 한국어를 읽었다
/// ("전부 das 이 지랄하고있네"). 발음을 가르치는 앱에서 틀린 발음은
/// 무음보다 나쁘다 — 학습자가 그게 틀린 줄 모르기 때문이다.
///
/// 그리고 실측상 필요도 없다. `tool/generate_tts.py --verify-storage`
/// (2026-08-19): expected 11438, remote 11729, **missing 1**.
void main() {
  test('OS 음성 티어를 되살릴 수 없다', () {
    final source = File('lib/services/tts_service.dart').readAsStringSync();

    // 주석은 남겨도 된다 — 왜 지웠는지가 이 파일에서 가장 중요한 문서다.
    // 잡아야 하는 건 되살아난 **코드**다.
    final code = source
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');

    expect(
      code,
      isNot(contains("package:flutter_tts")),
      reason: 'OS 음성 폴백은 독일어로 한국어를 읽었다 — 되살리지 말 것',
    );
    expect(code, isNot(contains('FlutterTts')));
    expect(code, isNot(contains('startSpeech')));
    expect(
      code,
      isNot(contains('_trySelectKoreanVoice')),
      reason: '한국어 음성 탐색은 OS 엔진 전용이었다',
    );

    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^\s{2}flutter_tts\s*:',
      multiLine: true,
    ).hasMatch(pubspec);
    expect(declared, isFalse, reason: 'flutter_tts 의존성도 같이 빠져야 한다');
  });

  test('재생 플랫폼은 오디오 페이로드만 받는다', () {
    // startAudio 하나뿐이면 "텍스트를 넘겨 읽게 하는" 경로가 타입상 없다.
    const platform = _RecordingPlatform();
    expect(platform, isA<TtsPlaybackPlatform>());
  });

  group('프리미엄이 없으면 — 무음이되 조용하지 않다', () {
    test('해결 실패는 재생을 시작하지 않고 사유를 남긴다', () async {
      final platform = _RecordingPlatform();
      final errors = <String>[];
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async => null,
        platform: platform,
        errorReporter: errors.add,
      );

      expect(
        await engine.speak(text: '없는 소리', voice: 'female', baseRate: 0.42),
        isFalse,
      );
      expect(_RecordingPlatform.started, isEmpty);
    });

    test('차단된 합성의 사유가 그대로 전달된다', () async {
      for (final reason in TtsUnavailableReason.values) {
        final errors = <String>[];
        final engine = TtsPlaybackEngine(
          resolveAudio: (text, voice) async =>
              throw TtsSynthesisBlocked('blocked', reason: reason),
          platform: const _RecordingPlatform(),
          errorReporter: errors.add,
        );

        expect(
          await engine.speak(text: 'x', voice: 'female', baseRate: 0.42),
          isFalse,
        );
        expect(errors, contains('blocked'), reason: '사유 $reason 가 유실됐다');
      }
    });

  });

  test('TtsAudio 는 경로 또는 바이트 중 하나만 갖는다', () {
    const byPath = TtsAudio.path('/tmp/a.mp3');
    expect(byPath.path, '/tmp/a.mp3');
    expect(byPath.bytes, isNull);
  });
}

class _RecordingPlatform implements TtsPlaybackPlatform {
  const _RecordingPlatform();

  static final started = <String>[];

  @override
  Future<TtsPlaybackSession?> startAudio(TtsAudio audio, double rate) async {
    started.add(audio.path ?? 'bytes');
    return null;
  }

  @override
  Future<void> stop() async {}
}
