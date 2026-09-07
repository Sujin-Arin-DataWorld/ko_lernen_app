import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

/// 2026-08-19 — 서버 오디오 전용 재생 경로 계약.
///
/// Jin: "기계음 안나오고 해당 텍스트에 맞는 정확한 서버 음성 나오도록."
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

  test(
    '로컬 캐시 읽기 실패는 TimeoutException 외의 예외도 잡아 Storage 로 넘어간다 (finding 1a)',
    () {
      final source = File('lib/services/tts_service.dart').readAsStringSync();
      // 클래스 독스트링에도 "/// 2. 로컬 캐시 mp3 → ..." 요약이 있고
      // '///' 는 '//' 를 부분 문자열로 포함하므로, 마침표까지 포함한 좁은
      // 앵커로 실제 코드 섹션만 골라낸다 — 독스트링 쪽은
      // "로컬 캐시 mp3" 로 이어져 마침표가 없어 매치되지 않는다.
      final localCacheStart = source.indexOf('// 2. 로컬 캐시. ');
      final storageStart = source.indexOf(
        '// 3. Firebase Storage (',
        localCacheStart,
      );
      expect(localCacheStart, greaterThanOrEqualTo(0));
      expect(storageStart, greaterThan(localCacheStart));
      final localCacheBlock = source.substring(localCacheStart, storageStart);

      expect(
        localCacheBlock,
        contains('on TimeoutException'),
        reason: '느린 디스크는 여전히 시한으로 잡아야 한다',
      );
      // localCacheBlock 안에는 file.delete() 실패를 삼키는 무관한 내부
      // catch(_) 가 이미 있다(정상 — junk 파일을 지우다 실패해도 무시). 그건
      // `on TimeoutException` **앞**에 나오므로, 검사 대상을
      // `on TimeoutException` **뒤** 구간으로 좁혀 그 내부 catch 를
      // 오탐하지 않게 한다 — 우리가 확인해야 하는 건 TimeoutException 절
      // 바로 뒤에 일반 catch(_) 가 이어지는지다.
      final afterTimeout = localCacheBlock.substring(
        localCacheBlock.indexOf('on TimeoutException'),
      );
      expect(
        RegExp(r'\}\s*catch\s*\(_\)\s*\{').hasMatch(afterTimeout),
        isTrue,
        reason:
            'TimeoutException 전용 catch 뒤에 일반 catch(_) 가 없으면 '
            'FileSystemException 등이 _resolveAudio 전체를 throw 해 '
            'Storage/CF 폴백을 건너뛴다 (finding 1a)',
      );
    },
  );

  group('오디오를 해결할 수 없으면 — 무음이되 조용하지 않다', () {
    test('해결 실패는 재생을 시작하지 않고 사유를 남긴다', () async {
      final platform = _RecordingPlatform();
      final errors = <String>[];
      final resolutionErrors = <String>[];
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async => null,
        platform: platform,
        errorReporter: errors.add,
        onResolutionFailed: resolutionErrors.add,
      );

      expect(
        await engine.speak(text: '없는 소리', voice: 'female', baseRate: 0.42),
        isFalse,
      );
      expect(_RecordingPlatform.started, isEmpty);
      expect(errors, hasLength(1));
      expect(resolutionErrors, hasLength(1));
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

    test('TtsSynthesisBlocked 가 아닌 해석 실패도 사유가 보고된다 (finding 1b)', () async {
      final errors = <String>[];
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async =>
            throw const FormatException('해석 중 예기치 못한 오류'),
        platform: const _RecordingPlatform(),
        errorReporter: errors.add,
      );

      expect(
        await engine.speak(text: 'x', voice: 'female', baseRate: 0.42),
        isFalse,
      );
      expect(
        errors,
        isNotEmpty,
        reason:
            '지금은 error is TtsSynthesisBlocked 일 때만 errorReporter 가 '
            '불려서, 그 외 예외는 lastError/unavailable 을 갱신하지 않고 '
            '사라진다 (finding 1b) — 사용자는 이유 없는 무음만 본다',
      );
    });

    test(
      '재생 단계 실패(해석은 성공)는 errorReporter 만 타고 onResolutionFailed 는 안 탄다 (post-review)',
      () async {
        final generalErrors = <String>[];
        final resolutionErrors = <String>[];
        final engine = TtsPlaybackEngine(
          resolveAudio: (text, voice) async =>
              const TtsAudio.path('/tmp/ok.mp3'),
          platform: const _ThrowingStartPlatform(),
          errorReporter: generalErrors.add,
          onResolutionFailed: resolutionErrors.add,
        );

        expect(
          await engine.speak(text: 'x', voice: 'female', baseRate: 0.42),
          isFalse,
        );
        expect(
          generalErrors,
          isNotEmpty,
          reason: '재생 기전 실패도 진단용 lastError 로그는 여전히 남아야 한다',
        );
        expect(
          resolutionErrors,
          isEmpty,
          reason:
              '해석(_resolveAudio)은 성공했다 — 여기서 onResolutionFailed 가 '
              '불리면 TtsService.unavailable 이 offline 으로 채워져, '
              'Android 오디오 라우팅류 재생 실패를 "오프라인이세요?" 로 '
              '오표시한다(리뷰에서 지적된 회귀)',
        );
      },
    );

    test(
      '해석 실패는 errorReporter 와 onResolutionFailed 를 둘 다 태운다 (post-review)',
      () async {
        final generalErrors = <String>[];
        final resolutionErrors = <String>[];
        final engine = TtsPlaybackEngine(
          resolveAudio: (text, voice) async =>
              throw const FormatException('해석 중 예기치 못한 오류'),
          platform: const _RecordingPlatform(),
          errorReporter: generalErrors.add,
          onResolutionFailed: resolutionErrors.add,
        );

        expect(
          await engine.speak(text: 'x', voice: 'female', baseRate: 0.42),
          isFalse,
        );
        expect(generalErrors, isNotEmpty);
        expect(
          resolutionErrors,
          isNotEmpty,
          reason:
              '해석 실패(재생할 오디오를 아예 못 구함)는 unavailable 배너를 '
              '채워야 하는 유일한 계열이다 — onResolutionFailed 가 안 불리면 '
              'finding 1b 가 고치려던 "이유 없는 무음"이 되돌아온다',
        );
      },
    );
  });

  group('재생 시작 콜백(onPlaybackStarted) — post-review T1.1', () {
    test('해석 성공 + startAudio 성공에서만 정확히 1회, 텍스트와 함께 불린다', () async {
      final throwingCalls = <String>[];
      final throwingEngine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async => const TtsAudio.path('/tmp/ok.mp3'),
        platform: const _ThrowingStartPlatform(),
        onPlaybackStarted: (text, voice) => throwingCalls.add(text),
      );
      expect(
        await throwingEngine.speak(text: 'x', voice: 'female', baseRate: 0.42),
        isFalse,
      );
      expect(throwingCalls, isEmpty, reason: '재생-기전 실패에서는 콜백이 불리면 안 된다');
      final startedCalls = <String>[];
      final startingEngine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async => const TtsAudio.path('/tmp/ok.mp3'),
        platform: const _StartingPlatform(),
        onPlaybackStarted: (text, voice) => startedCalls.add(text),
      );
      expect(
        await startingEngine.speak(text: 'x', voice: 'female', baseRate: 0.42),
        isTrue,
      );
      expect(
        startedCalls,
        ['x'],
        reason:
            'SoriSpeech가 이 텍스트로 자기 요청과 대조해 승격 여부를 판단한다'
            '(Fix round 1, finding 1) — trim된 원문 그대로 와야 한다',
      );
      final missingCalls = <String>[];
      final missingEngine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async => null,
        platform: const _StartingPlatform(),
        onPlaybackStarted: (text, voice) => missingCalls.add(text),
      );
      expect(
        await missingEngine.speak(text: 'x', voice: 'female', baseRate: 0.42),
        isFalse,
      );
      expect(missingCalls, isEmpty);
    });

    test(
      'stop() 은 phase 를 idle 로 되돌린다 (카드 전환 정지 시 speaking 고착 방지, fix round 1)',
      () async {
        // TtsService._player(audioplayers AudioPlayer)는 최초 접근 시
        // ServicesBinding.instance 를 요구한다 — 순수 유닛 테스트에는 바인딩이
        // 없어 그냥 부르면 하위 스트림/채널 호출이 걸린다. TestWidgetsFlutterBinding
        // 을 초기화하면(이 테스트에만 영향, 나머지 9개는 플랫폼 채널을 안 써서
        // 무관) 표준 테스트용 바인딩이 생겨 채널 호출이 MissingPluginException
        // 으로 정상 실패하고, TtsService.stop() 내부의 기존 best-effort
        // try/catch(_stopPlatforms/TtsPlaybackEngine.stop)가 그걸 삼킨다.
        TestWidgetsFlutterBinding.ensureInitialized();
        TtsService.phase.value = TtsSpeechPhase.speaking;
        TtsService.activeSpeechText = '학교';
        final pending = TtsService.stop();
        // phase/activeSpeechText 리셋은 stop() 안에서 async 없이 즉시(동기)
        // 실행되므로 반환 Future 를 기다리기 전에도 이미 반영돼 있다.
        expect(TtsService.phase.value, TtsSpeechPhase.idle);
        expect(
          TtsService.activeSpeechText,
          isNull,
          reason:
              'stop() 뒤에 남은 activeSpeechText는 다음 무관한 재생이 '
              '엉뚱하게 speaking으로 오인 승격되는 통로가 된다(Fix round 1, finding 1)',
        );
        await pending;
        expect(TtsService.phase.value, TtsSpeechPhase.idle);
        expect(TtsService.activeSpeechText, isNull);
      },
    );
  });

  test('markSpeechStarting() 은 phase를 resolving으로 되돌리고 '
      'activeSpeechText를 지운다 (F1)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    TtsService.phase.value = TtsSpeechPhase.speaking;
    TtsService.activeSpeechText = '학교';

    TtsService.markSpeechStarting();

    expect(TtsService.phase.value, TtsSpeechPhase.resolving);
    expect(
      TtsService.activeSpeechText,
      isNull,
      reason:
          '직전 발화의 activeSpeechText를 남겨두면, 새 발화가 아직 자기 '
          'activeSpeechText를 쓰기 전 우연히 같은 텍스트로 대조돼 잘못 '
          '승격될 수 있다',
    );

    TtsService.phase.value = TtsSpeechPhase.idle;
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

/// post-review 헬퍼 — 해석(resolveAudio)은 성공했는데 재생 기전(플랫폼)이
/// 실패하는 경우를 재현한다. `TtsPlaybackEngine.speak()` 안 `startAudio`
/// 호출을 감싸는 catch(~:362-366, "TTS audio playback start failed")를
/// 태워, errorReporter 는 불리지만 onResolutionFailed 는 불리지 않아야
/// 한다는 것을 확인하는 데 쓴다.
class _ThrowingStartPlatform implements TtsPlaybackPlatform {
  const _ThrowingStartPlatform();

  @override
  Future<TtsPlaybackSession?> startAudio(TtsAudio audio, double rate) async {
    throw StateError('platform start failed');
  }

  @override
  Future<void> stop() async {}
}

class _StartingPlatform implements TtsPlaybackPlatform {
  const _StartingPlatform();
  @override
  Future<TtsPlaybackSession?> startAudio(TtsAudio audio, double rate) async {
    return TtsPlaybackSession(Future<bool>.value(true));
  }

  @override
  Future<void> stop() async {}
}
