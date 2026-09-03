import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_policy.dart';
import 'analytics_service.dart';
import 'storage_service.dart';
import 'tts_bundled_manifest.dart';
import 'tts_installation_id.dart';
import 'tts_cache_key.dart';

export 'tts_cache_key.dart';

/// 해결된 프리미엄 오디오 한 건.
///
/// io 호스트는 mp3 를 디스크에 캐시하고 경로로 재생하고, 웹은 파일시스템이
/// 없어 같은 바이트를 메모리에서 재생한다. **둘 다 `tts/v3/...` 의 같은
/// Chirp3-HD 객체다** — 플랫폼이 바꾸는 건 플레이어에 건네는 방법뿐이고,
/// 들리는 소리는 같다.
class TtsAudio {
  const TtsAudio.path(String this.path) : bytes = null;
  const TtsAudio.bytes(Uint8List this.bytes) : path = null;

  /// 캐시된 mp3 의 절대 경로. 웹에서는 null.
  final String? path;

  /// 메모리 상의 mp3. [path] 가 있으면 null.
  final Uint8List? bytes;
}

typedef TtsAudioResolver =
    Future<TtsAudio?> Function(String text, String voice);
typedef TtsErrorReporter = void Function(String message);

/// 프리미엄 오디오를 못 들려주는 이유. UI 가 사람 말로 옮겨 보여준다.
///
/// 예전에는 실패가 전부 `lastError` 문자열 하나로 뭉개졌고 **그걸 읽는
/// 위젯이 0개**였다 — 사용자에게는 그냥 "아무 소리도 안 남"이었다
/// (Jin 2026-08-19: "letter of the day 소리 안나와").
enum TtsUnavailableReason {
  /// 설정 → Ton 에서 발음 채널이 꺼져 있다.
  channelOff,

  /// 오늘치 동적 합성 한도를 다 썼다.
  quota,

  /// 서버가 같은 문장을 합성하는 중이다 — 잠시 뒤 다시 되는 상태.
  pendingSynthesis,

  /// Storage/CF 에 닿지 못했다 (오프라인 포함).
  offline,

  /// 응답이 시한 안에 오지 않았다.
  timeout,

  /// 모든 해석 경로가 끝났지만 재생 가능한 프리미엄 오디오가 없었다.
  audioUnavailable,
}

/// Cloud TTS refused this request.
///
/// 던져진 뒤에는 [reason] 이 그대로 [TtsService.unavailable] 로 흘러가
/// 화면에 뜬다. 조용히 삼키지 않는다.
class TtsSynthesisBlocked implements Exception {
  const TtsSynthesisBlocked(
    this.message, {
    this.reason = TtsUnavailableReason.pendingSynthesis,
  });

  final String message;
  final TtsUnavailableReason reason;

  @override
  String toString() => message;
}

/// How the client should treat one Cloud Function TTS error.
enum TtsCallableKind { retryInflight, blockQuota, blockUnavailable, fallback }

class TtsCallableProbe implements Exception {
  const TtsCallableProbe({required this.code, this.message});

  final String code;
  final String? message;
}

class TtsCallableFailure {
  static const alreadyInProgressMessage =
      'TTS synthesis is already in progress.';
  static const audioUnavailableMessage = 'TTS audio is not available.';
  static const quotaMessage = 'Daily synthesis limit reached.';

  static TtsCallableKind fromError(Object error) {
    if (error is FirebaseFunctionsException) {
      return classify(code: error.code, message: error.message);
    }
    if (error is TtsCallableProbe) {
      return classify(code: error.code, message: error.message);
    }
    return TtsCallableKind.fallback;
  }

  static TtsCallableKind classify({required String code, String? message}) {
    if (_codeMatches(code, 'resource-exhausted')) {
      return TtsCallableKind.blockQuota;
    }
    if (_codeMatches(code, 'unavailable')) {
      final text = message ?? '';
      if (text.contains('already in progress')) {
        return TtsCallableKind.retryInflight;
      }
      if (text.contains('not available')) {
        return TtsCallableKind.blockUnavailable;
      }
    }
    return TtsCallableKind.fallback;
  }

  static bool _codeMatches(String raw, String code) {
    return raw == code || raw == 'functions/$code' || raw.endsWith('/$code');
  }
}

/// Stable default voice assignment shared with `tool/generate_tts.py`.
///
/// Explicit scenario roles still pass `female` or `male`. Every other learning
/// utterance uses `auto`, which hashes the trimmed text so the same Korean text
/// always resolves to the same cache namespace while the corpus stays close to
/// a 50:50 voice split.
class TtsVoicePolicy {
  const TtsVoicePolicy._();

  static const String autoVoice = 'auto';
  static const String _salt = 'hangul-sori-auto-voice-v1';

  static String resolve({required String text, String voice = autoVoice}) {
    if (voice == 'female' || voice == 'male') {
      return voice;
    }
    final normalizedText = text.trim();
    final digest = sha1.convert(utf8.encode('$_salt|$normalizedText'));
    return digest.bytes.first.isOdd ? 'male' : 'female';
  }
}

class TtsPlaybackRates {
  const TtsPlaybackRates({required this.speechRate, required this.fileRate});

  static const double defaultSpeechRate = 0.42;
  final double speechRate;
  final double fileRate;

  /// [userMultiplier] = 전역 사용자 속도 배수 (`Storage.ttsSpeed`, 프리셋
  /// 0.5–1.5). 요청별 [multiplier](speakSlow 0.65, 화면 오버라이드)와 곱해져
  /// mp3 재생 속도([fileRate])에 clamp 와 함께 반영된다.
  ///
  /// [speechRate] 는 OS 음성 티어가 있던 시절의 값이고 지금은 저장된 기준
  /// 속도로만 남아 있다 — 재생에 쓰이는 건 [fileRate] 다.
  static TtsPlaybackRates compose({
    required double baseRate,
    required double multiplier,
    double userMultiplier = 1.0,
  }) {
    final safeBase = baseRate.isFinite ? baseRate : defaultSpeechRate;
    final safeUser = userMultiplier.isFinite ? userMultiplier : 1.0;
    final safeMultiplier = (multiplier.isFinite ? multiplier : 1.0) * safeUser;
    return TtsPlaybackRates(
      speechRate: (safeBase * safeMultiplier).clamp(0.1, 1.0).toDouble(),
      fileRate: ((safeBase / defaultSpeechRate) * safeMultiplier)
          .clamp(0.5, 2.0)
          .toDouble(),
    );
  }
}

class TtsPlaybackSession {
  const TtsPlaybackSession(this.completion);
  final Future<bool> completion;
}

typedef TtsAudioContextSetter = Future<void> Function(AudioContext context);

/// Reasserts the speech audio session immediately before each TTS playback.
///
/// On iOS audioplayers contexts are process-global even when they are set on
/// one player. The SFX policy, another plugin, or an audio-session interruption
/// can therefore replace this context after an earlier utterance. Keeping a
/// one-time "already applied" flag makes every later utterance depend on that
/// stale global state and can leave TTS silent while the mute switch is on.
class TtsSpeechAudioContext {
  @visibleForTesting
  static AudioContext build() => AudioContext(
    android: AudioContextConfig(
      focus: AudioContextConfigFocus.duckOthers,
    ).buildAndroid(),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.duckOthers},
    ),
  );

  static Future<void> reapply(
    TtsAudioContextSetter setContext, {
    bool? isWeb,
  }) async {
    if (isWeb ?? kIsWeb) {
      return;
    }
    try {
      await setContext(build());
    } catch (_) {
      // Best effort. Do not block playback; the next utterance retries.
    }
  }
}

abstract interface class TtsPlaybackPlatform {
  Future<TtsPlaybackSession?> startAudio(TtsAudio audio, double rate);
  Future<void> stop();
}

/// Starts file playback in the order required by audioplayers on Apple hosts.
class TtsFilePlayback {
  static Future<TtsPlaybackSession?> start({
    required Future<bool> completion,
    required Future<void> Function() play,
    required Future<void> Function(double rate) setRate,
    required Future<void> Function() stop,
    void Function(Object error)? onError,
    required double rate,
  }) async {
    try {
      await play();
      await setRate(rate);
    } catch (error) {
      onError?.call(error);
      try {
        await stop();
      } catch (stopError) {
        onError?.call(stopError);
        return TtsPlaybackSession(Future<bool>.value(false));
      }
      return null;
    }
    return TtsPlaybackSession(completion);
  }
}

/// SoriSpeech(파사드)와 TtsService(엔진 배선)가 공유하는 재생 3단계.
enum TtsSpeechPhase { idle, resolving, speaking }

/// Executes one TTS request with an immutable, request-local playback rate.
class TtsPlaybackEngine {
  TtsPlaybackEngine({
    required this.resolveAudio,
    required this.platform,
    this.completionTimeout = const Duration(seconds: 30),
    this.errorReporter,
    this.onResolutionFailed,
    this.onPlaybackStarted,
  });

  final TtsAudioResolver resolveAudio;
  final TtsPlaybackPlatform platform;
  final Duration completionTimeout;
  final TtsErrorReporter? errorReporter;
  // post-review (2026-08-27): errorReporter 는 speak() 전 과정(정지·해석·
  // 재생 시작·완료)의 모든 실패에서 불린다 — 진단용 lastError 로그로는
  // 맞지만, "재생할 오디오 자체가 없다"(해석 실패)와 "오디오는 있는데
  // 재생 기전이 실패했다"(플랫폼 stop/start/completion 실패)는 서로 다른
  // 결함 계열이다. onResolutionFailed 는 오직 _resolveAudio 실패에서만
  // 불려, TtsService 가 unavailable(오프라인 추정) 배너를 그 계열에만
  // 한정할 수 있게 한다.
  final TtsErrorReporter? onResolutionFailed;
  /// 해석 성공 + startAudio 성공(세션 획득)이 둘 다 확정된 직후 정확히
  /// 1회 불린다. 해석 실패·재생-기전 실패에서는 절대 불리지 않는다.
  final VoidCallback? onPlaybackStarted;
  Future<void> _platformTail = Future<void>.value();
  Completer<void>? _cancellation;
  int _generation = 0;
  bool _disposed = false;

  Future<bool> speak({
    required String text,
    required String voice,
    required double baseRate,
    double rateMultiplier = 1.0,
    double userMultiplier = 1.0,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (_disposed) return false;
    final generation = ++_generation;
    _cancellation?.complete();
    final cancellation = Completer<void>();
    _cancellation = cancellation;
    final normalizedVoice = voice == 'male' ? 'male' : 'female';
    final rates = TtsPlaybackRates.compose(
      baseRate: baseRate,
      multiplier: rateMultiplier,
      userMultiplier: userMultiplier,
    );
    final stopCurrent =
        _serialize<void>(() async {
          if (_disposed || generation != _generation) return;
          await platform.stop();
        }).then<bool>(
          (_) => true,
          onError: (Object error, StackTrace stack) {
            errorReporter?.call('TTS platform stop failed: $error');
            return false;
          },
        );
    final resolution =
        Future<TtsAudio?>.sync(
          () => resolveAudio(trimmed, normalizedVoice),
        ).then<_TtsResolution>(
          (audio) => _TtsResolution(audio: audio),
          onError: (Object error, _) {
            // TtsSynthesisBlocked 는 사유 문자열이 이미 사람이 읽을 말이다.
            // 그 외 예외(finding 1b — 예전엔 여기서 조용히 버려졌다)도
            // errorReporter 로 보내야 lastError 가 갱신된다.
            final message = error is TtsSynthesisBlocked
                ? error.message
                : 'TTS resolution failed: $error';
            errorReporter?.call(message);
            // post-review: unavailable 배너는 이 "해석 실패" 분기에서만
            // 켠다 — stop/시작/완료 같은 재생-기전 실패(아래 catch 들)는
            // errorReporter 만 타고 onResolutionFailed 는 타지 않는다.
            onResolutionFailed?.call(message);
            return const _TtsResolution(audio: null, failureReported: true);
          },
        );
    // 시한은 **각 티어 안**에 있다(디스크 2s · Storage 8s · CF 시퀀스 20s).
    // 여기에 벽시계 타이머를 하나 더 두지 않는 이유: 해결이 즉시 끝나도
    // 타이머가 먼저 만들어져 살아남고, `speak()` 를 await 하지 않는 화면·
    // 위젯 테스트에서 "A Timer is still pending" 으로 터진다. 티어 시한은
    // 실제로 그 작업을 할 때만 걸리므로 그런 부작용이 없다.
    final resolved = await Future.any<_TtsResolution>([
      resolution,
      cancellation.future.then((_) => const _TtsResolution.cancelled()),
    ]);
    if (resolved.wasCancelled || _disposed || generation != _generation) {
      return false;
    }
    if (!await stopCurrent) {
      return false;
    }
    if (_disposed || generation != _generation) return false;
    final audio = resolved.audio;
    // 프리미엄 오디오가 없으면 아무 소리도 내지 않는다. 예전에는 여기서
    // OS 음성으로 떨어졌는데, 독일어 엔진이 한국어를 읽어 "전부 das" 가
    // 됐다 (Jin 2026-08-19). 예외 해석 실패는 위에서 이미 보고됐고,
    // 정상 null(모든 티어 miss)도 여기서 반드시 사유를 남긴다.
    if (audio == null) {
      if (!resolved.failureReported) {
        const message = 'TTS resolution returned no playable audio.';
        errorReporter?.call(message);
        onResolutionFailed?.call(message);
      }
      return false;
    }

    TtsPlaybackSession? session;
    try {
      session = await _serialize<TtsPlaybackSession?>(() async {
        if (_disposed || generation != _generation) return null;
        try {
          return await platform.startAudio(audio, rates.fileRate);
        } catch (error) {
          // A thrown start may mean playback began but cleanup failed.
          errorReporter?.call('TTS audio playback start failed: $error');
          return null;
        }
      });
    } catch (error) {
      errorReporter?.call('TTS platform playback start failed: $error');
      return false;
    }
    if (session == null || _disposed || generation != _generation) {
      return false;
    }
    onPlaybackStarted?.call();
    bool completed;
    try {
      completed = await Future.any<bool>([
        session.completion.timeout(
          completionTimeout,
          onTimeout: () {
            errorReporter?.call('TTS playback completion timed out');
            return false;
          },
        ),
        cancellation.future.then((_) => false),
      ]);
    } catch (error) {
      errorReporter?.call('TTS playback completion failed: $error');
      completed = false;
    }
    if (!completed && !_disposed && generation == _generation) {
      try {
        await _serialize<void>(() async {
          if (!_disposed && generation == _generation) {
            await platform.stop();
          }
        });
      } catch (_) {
        // A failed cleanup must not escape the public bool contract.
      }
    }
    return completed;
  }

  Future<void> stop() async {
    ++_generation;
    _cancellation?.complete();
    _cancellation = null;
    try {
      await _serialize<void>(platform.stop);
    } catch (_) {
      // Public stop is best effort and must not leak platform errors.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _platformTail = _platformTail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }
}

class _TtsResolution {
  const _TtsResolution({required this.audio, this.failureReported = false})
    : wasCancelled = false;
  const _TtsResolution.cancelled()
    : audio = null,
      wasCancelled = true,
      failureReported = false;
  final TtsAudio? audio;
  final bool wasCancelled;
  final bool failureReported;
}

class _ServicePlaybackPlatform implements TtsPlaybackPlatform {
  const _ServicePlaybackPlatform();

  @override
  Future<TtsPlaybackSession?> startAudio(TtsAudio audio, double rate) =>
      TtsService._startAudio(audio, rate);

  @override
  Future<void> stop() => TtsService._stopPlatforms();
}

/// 고품질 한국어 발음 TTS — **프리미엄 전용 4단**.
///
/// 1. 검증된 first-line manifest rootBundle mp3 → 즉시 재생 (오프라인·무료).
/// 2. 로컬 캐시 mp3 → 즉시 재생. 웹은 메모리 캐시.
/// 3. Firebase Storage `tts/v3/{voice}/{sha1}.mp3` → 다운로드·캐시·재생
/// 4. Cloud Function 합성 → base64 수신·캐시·재생
///    (동적 콘텐츠: 책 한 컷 OCR·내 단어장의 사용자 입력 단어)
///
/// **OS 음성(flutter_tts) 폴백은 없다.** 2026-08-19 에 지웠다.
///
/// 왜: 폴백은 "안전망"이 아니라 조용한 오답 생성기였다. 독일어 로케일
/// 기기에서 `setLanguage('ko-KR')` 이 실패해도 그 실패를 성공으로 메모이즈해
/// 독일어 음성이 한국어를 읽었다 — Jin: "전부 das 이 지랄하고있네".
/// 발음을 배우는 앱에서 틀린 발음은 무음보다 나쁘다.
/// 그리고 실측상 그럴 필요도 없다: 2026-08-19 `--verify-storage` 기준
/// 발화 11,438개 중 Storage 에 없는 건 **1개**다. 프리미엄이 사실상 전부다.
///
/// 프리미엄을 못 받으면 **무음 + 사유**다. 사유는 [unavailable] 로 나가고
/// 화면이 사람 말로 옮긴다. 조용히 실패하지 않는다.
///
/// 공개 인터페이스(`speak`/`speakSlow`/`stop`/`setRate`/`rate`)는 그대로라
/// 호출 70곳을 고칠 필요가 없다.
/// `voice`: 'auto'(기본·결정적 균형 배정) / 'female'(Chirp3-HD-Zephyr) /
/// 'male'(Chirp3-HD-Enceladus).
class TtsService {
  TtsService._();

  // ── 설정 ──────────────────────────────────────────────────────────
  /// Firebase Storage 버킷. Storage 활성화 후 실제 버킷명으로 교정할 것
  /// (신형 프로젝트는 `*.firebasestorage.app`, 구형은 `*.appspot.com`).
  static const String _bucket = 'gs://ko-lernen-app.firebasestorage.app';

  /// Dynamic synthesis is a Firebase callable, so Auth and App Check tokens
  /// are attached by the SDK instead of exposing an unauthenticated HTTP URL.
  static const String _functionRegion = 'europe-west3';
  static const String _functionName = 'synthesize_tts';

  static const Duration _netTimeout = Duration(seconds: 12);
  static const Duration _playTimeout = Duration(seconds: 30);

  /// Storage 읽기 시한. 예전에는 없어서 멈춘 연결 하나가 `speak()` 를
  /// 영원히 붙잡았다 — 탭해도 아무 일도 안 일어나는 것처럼 보였다.
  static const Duration _storageTimeout = Duration(seconds: 8);

  /// 로컬 캐시 파일 I/O 시한.
  static const Duration _diskTimeout = Duration(seconds: 2);
  static const int _maxBytes = 5 * 1024 * 1024; // 5MB/파일 상한

  // ── 내부 상태 ──────────────────────────────────────────────────────
  static final AudioPlayer _player = AudioPlayer();
  static Directory? _cacheDir;
  static String? lastError;
  static final TtsInstallationIdProvider _installationIdProvider =
      TtsInstallationIdProvider();
  /// [speaking](레거시 bool)과 별개인 3단 재생 상태. `SoriSpeech.phase`가
  /// 이 리스너를 구독해 resolving→speaking 승격 신호로 쓴다(Task 2).
  static final ValueNotifier<TtsSpeechPhase> phase =
      ValueNotifier<TtsSpeechPhase>(TtsSpeechPhase.idle);
  static final TtsPlaybackEngine _playbackEngine = TtsPlaybackEngine(
    resolveAudio: _resolveAudio,
    platform: const _ServicePlaybackPlatform(),
    completionTimeout: _playTimeout,
    // 모든 실패(정지·해석·재생 시작·완료) 공통 — 진단용 lastError 만
    // 갱신한다. unavailable(오프라인 추정) 배너는 여기서 켜지 않는다:
    // 재생 기전 실패(예: Android 오디오 라우팅 사고 — 이게 바로
    // tts_unavailable_banner.dart 가 애초에 존재하는 이유다)까지
    // "오프라인이세요?" 로 오표시했었다(post-review, finding 1b 후속수정).
    errorReporter: (message) => lastError = message,
    // post-review: unavailable 배너는 오직 "해석 실패"(아예 재생할 오디오가
    // 없음) 계열에서만 켠다 — 예외뿐 아니라 모든 티어가 정상적으로 null 을
    // 반환한 경우도 TtsPlaybackEngine.speak() 가 이 콜백으로 보고한다.
    onResolutionFailed: (_) {
      // _resolveAudio 의 각 티어가 이미 구체적 사유(quota/offline/...)로
      // unavailable 을 채웠다면 여기서 일반 사유로 덮어쓰지 않는다 —
      // 아직 비어 있을 때만(finding 1b 가 다루는, 어떤 티어도 사유를
      // 남기지 않은 새 예외 종류) 최소한 배너가 뜨도록 채운다.
      if (unavailable.value == null) {
        _reportUnavailable(TtsUnavailableReason.audioUnavailable);
      }
    },
    onPlaybackStarted: () => phase.value = TtsSpeechPhase.speaking,
  );

  /// 웹 전용 메모리 캐시 — 파일시스템이 없어 1단을 여기에 둔다.
  /// 상한을 두는 이유: 한 세션에서 수백 줄을 들으면 탭이 무거워진다.
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};
  static const int _memoryCacheEntries = 64;

  /// 지금 왜 소리가 안 나는지. null 이면 문제 없음.
  ///
  /// [lastError] 는 9곳에서 쓰였지만 **읽는 위젯이 0개**였다 — 그래서
  /// 무음이 사용자에게 늘 원인 불명이었다. 이건 화면이 구독한다.
  static final ValueNotifier<TtsUnavailableReason?> unavailable =
      ValueNotifier<TtsUnavailableReason?>(null);

  static void _reportUnavailable(TtsUnavailableReason reason) {
    unavailable.value = reason;
  }

  /// 사용자가 배너를 닫았거나, 다음 발화가 성공했다.
  static void clearUnavailable() => unavailable.value = null;

  /// 발화 중 여부 — [AudioPolicy] 더킹·UI 표시용 (ADR-002 §5-2).
  static final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);
  static int _speakToken = 0;

  static FirebaseStorage get _storage =>
      FirebaseStorage.instanceFor(bucket: _bucket);
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: _functionRegion);

  // ── 공개 API ───────────────────────────────────────────────────────

  /// 표준 속도 재생. voice: 'auto'(기본) / 'female' / 'male'.
  /// speech 채널이 꺼져 있으면(설정) 재생하지 않고 false 를 반환한다.
  static Future<bool> speak(
    String text, {
    String voice = TtsVoicePolicy.autoVoice,
    double rateMultiplier = 1.0,
  }) {
    if (AudioPolicy.instance.volumeFor(SoundChannel.speech) <= 0) {
      lastError = 'speech 채널이 꺼져 있음 (설정 → Ton)';
      _reportUnavailable(TtsUnavailableReason.channelOff);
      return Future<bool>.value(false);
    }
    unavailable.value = null;
    final token = ++_speakToken;
    speaking.value = true;
    AudioPolicy.instance.noteSpeechStarted();
    Analytics.ttsPlayed(
      contentType: text.trim().contains(RegExp(r'[\s.!?]'))
          ? 'sentence'
          : 'word',
    );
    final resolvedVoice = TtsVoicePolicy.resolve(text: text, voice: voice);
    final result = _playbackEngine.speak(
      text: text,
      voice: resolvedVoice,
      baseRate: Storage.ttsRate,
      rateMultiplier: rateMultiplier,
      userMultiplier: Storage.ttsSpeed,
    );
    result.whenComplete(() {
      // 새 발화가 이미 시작됐으면(토큰 불일치) 종료 처리를 그쪽에 맡긴다.
      if (token == _speakToken) {
        speaking.value = false;
        phase.value = TtsSpeechPhase.idle;
        AudioPolicy.instance.noteSpeechEnded();
      }
    });
    return result;
  }

  /// 느리게 재생 (학습 보조). 사용자 기본 속도에 요청 배수 0.65를 곱한다.
  static Future<bool> speakSlow(
    String text, {
    String voice = TtsVoicePolicy.autoVoice,
  }) {
    return speak(text, voice: voice, rateMultiplier: 0.65);
  }

  /// 재생하지 않고 **로컬 캐시만 채운다**.
  ///
  /// 2026-08-17 테스터(Amor): "카드 음성이 너무 늦게 나온다." 캐시가 비면
  /// 낱자마다 Storage 다운로드 + fsync 를 기다린 **뒤에야** 소리가 난다.
  /// 화면에 들어온 순간 미리 받아두면 탭 시점엔 1단(로컬 디스크)이라 즉시 난다.
  ///
  /// **동적 합성은 하지 않는다**(`allowSynthesis: false`) — 누르지도 않은 걸
  /// 미리 합성하면 할당량만 태운다. Storage 에 없으면 조용히 포기하고, 실제로
  /// 누를 때 평소 경로가 처리한다.
  ///
  /// 실패는 전부 삼킨다. 프리페치가 안 돼도 앱 동작은 그대로다
  /// (`DancheongBurst.preload()` 와 같은 best-effort 철학).
  static Future<void> prefetch(
    String text, {
    String voice = TtsVoicePolicy.autoVoice,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    // 음성 채널을 꺼 둔 사용자에게는 받지 않는다. speak() 가 같은 게이트로
    // 재생을 막는데 미리받기만 도는 건 절대 못 들을 파일을 내려받는 것이다.
    if (AudioPolicy.instance.volumeFor(SoundChannel.speech) <= 0) {
      return;
    }
    // 세션 내 1회로 묶는다. Storage 에 없는 텍스트는 매번 네트워크 왕복을
    // 되풀이하고, 있는 텍스트도 mp3 전체를 다시 읽는다 — 카드를 넘길 때마다
    // ±1 이웃이 겹쳐 들어오므로 이게 금방 수십 번이 된다.
    final resolvedVoice = TtsVoicePolicy.resolve(text: trimmed, voice: voice);
    final key = '$resolvedVoice|$trimmed';
    if (!_prefetchAttempted.add(key)) {
      return;
    }
    try {
      await _resolveAudio(trimmed, resolvedVoice, allowSynthesis: false);
    } catch (_) {
      // 일시적 실패(시한 초과·오프라인)는 메모에서 뺀다. 예전에는 시도
      // **전에** 기록해서, 한 번 삐끗한 문자열이 그 세션 내내 봉인됐다 —
      // 한글 탭에 들어오자마자 자모 40개를 던지는 화면에서 특히 잘 터졌다.
      _prefetchAttempted.remove(key);
    }
  }

  /// 이번 실행에서 이미 시도한 프리페치 키. 재시도 억제용.
  static final Set<String> _prefetchAttempted = <String>{};

  @visibleForTesting
  static void resetPrefetchMemoForTesting() => _prefetchAttempted.clear();

  /// [texts] 를 동시 [concurrency] 개씩 미리 받는다. 중복은 알아서 제거한다.
  ///
  /// 동시 개수를 제한하는 이유: 한글 화면은 낱자 34개를 한 번에 요청하는데,
  /// 전부 동시에 던지면 첫 탭이 자기 차례를 기다리게 된다 — 프리페치가 오히려
  /// 지연을 만드는 셈이다.
  static Future<void> prefetchAll(
    Iterable<String> texts, {
    String voice = TtsVoicePolicy.autoVoice,
    int concurrency = 3,
  }) async {
    final queue = <String>{
      for (final t in texts)
        if (t.trim().isNotEmpty) t.trim(),
    }.toList();
    if (queue.isEmpty) {
      return;
    }
    final lanes = math.max(1, math.min(concurrency, queue.length));
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= queue.length) {
          return;
        }
        await prefetch(queue[index], voice: voice);
      }
    }

    await Future.wait([for (var i = 0; i < lanes; i++) worker()]);
  }

  static Future<void> stop() {
    // 진행 중이던 speak 의 완료 처리를 무효화한다.
    //
    // 예전에는 재생만 멈추고 토큰은 그대로 뒀다. 그래서 화면이 dispose 되며
    // stop() 을 불러도, 이미 떠 있던 speak 의 whenComplete 가 나중에 실행돼
    // AudioPolicy.noteSpeechEnded() 로 200ms 타이머를 새로 걸었다 — 주인 없는
    // 화면이 앱 전역 타이머를 남기는 셈이다. 위젯 트리가 사라진 뒤 타이머가
    // 남는 걸 flutter_test 가 잡아내면서 드러났다(2026-08-12).
    //
    // 토큰을 올리면 speak(366행)이 발급한 값과 달라져 그 완료 블록이 통째로
    // 건너뛰어진다 — 새 발화가 끼어들었을 때와 같은 처리다.
    _speakToken++;
    speaking.value = false;
    // 지연 복원(noteSpeechEnded)이 아니라 즉시 복원이다 — 정지했으니 이어질
    // 다음 문장이 없고, 200ms 타이머를 새로 걸면 방금 없앤 문제가 되살아난다.
    AudioPolicy.instance.restoreDuckNow();
    return _playbackEngine.stop();
  }

  static Future<void> _stopPlatforms() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// 0.1 (langsam) … 1.0 (schnell). mp3 재생 속도의 기준값 + 저장.
  static Future<void> setRate(double rate) async {
    final clamped = rate.clamp(0.1, 1.0);
    await Storage.setTtsRate(clamped);
  }

  static double get rate => Storage.ttsRate;

  // ── 전역 사용자 속도 배수 (2026-08-13, "음성 나오는 모든 곳" 속도 바) ──
  //
  // `speak`/`speakSlow` 단일 관문에 곱해지므로 화면별 배선 없이 전역 적용된다.
  // 재생 중 리튠은 하지 않는다 — 엔진은 요청-로컬 불변 rate 설계(120행)이고,
  // 발화가 짧아 다음 발화부터 반영해도 충분하다.

  /// 사용자 속도 배수 프리셋 값들 (mp3 fileRate clamp 0.5–2.0 안에서 정직).
  static const List<double> speedPresets = [0.5, 0.75, 0.8, 1.0, 1.25, 1.5];

  static ValueNotifier<double>? _speedNotifier;

  /// 현재 전역 배수 — 여러 UI 인스턴스(속도 바·설정)가 함께 구독한다.
  static ValueNotifier<double> get speedNotifier =>
      _speedNotifier ??= ValueNotifier<double>(Storage.ttsSpeed);

  static Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(speedPresets.first, speedPresets.last);
    await Storage.setTtsSpeed(clamped.toDouble());
    speedNotifier.value = clamped.toDouble();
  }

  // ── 핵심 흐름 ──────────────────────────────────────────────────────

  /// 번들 → 캐시 → Storage → CF 순으로 mp3 파일을 확보. 실패 시 null.
  ///
  /// [allowSynthesis] 가 false 면 **3단(Cloud Function 동적 합성)을 건너뛴다**.
  /// 프리페치 전용 스위치다 — 아직 누르지도 않은 낱자를 투기적으로 합성하면
  /// 합성 할당량을 쓰고 12초 타임아웃까지 잡아먹는다. 사용자가 실제로 누르면
  /// 그때 평소 경로가 3단까지 간다.
  static Future<TtsAudio?> _resolveAudio(
    String text,
    String voice, {
    bool allowSynthesis = true,
  }) async {
    final key = TtsCacheKey.forRequest(voice: voice, text: text);

    // 1. Manifest-declared rootBundle bytes. The manifest loader validates
    // schema/key/path/hash/MPEG shape before exposing a path, and this request
    // validates the selected bytes again before playback. Any bundle failure
    // preserves the pre-existing disk → Storage → callable chain.
    final bundledPath = await key.bundledAssetPath();
    if (bundledPath != null) {
      try {
        final bundledBytes = await TtsBundledManifest.readAsset(
          bundledPath,
        ).timeout(_diskTimeout);
        if (TtsCacheKey.isUsableAudio(bundledBytes)) {
          return TtsAudio.bytes(bundledBytes);
        }
      } on TimeoutException {
        // A stalled rootBundle read falls through to the existing cache tiers.
      } catch (_) {
        // Missing/corrupt declared bytes must never block disk/network fallback.
      }
    }

    // 웹은 파일시스템이 없다. 예전에는 여기서 1~3단이 통째로 죽고 OS 음성만
    // 남아 브라우저 독일어 음성이 한국어를 읽었다. 이제 같은 Storage 객체를
    // 메모리로 받아 재생한다 — 웹도 프리미엄이다.
    final Directory? dir = kIsWeb ? null : await _ensureCacheDir();
    if (!kIsWeb && dir == null) {
      _reportUnavailable(TtsUnavailableReason.offline);
      return null;
    }
    final File? file = dir == null
        ? null
        : File('${dir.path}/${key.localFileName}');

    // 2. 로컬 캐시. 멈춘 파일시스템이 speak() 를 붙잡지 못하게 시한을 건다.
    if (file != null) {
      try {
        if (await file.exists().timeout(_diskTimeout)) {
          final localBytes = await file.readAsBytes().timeout(_diskTimeout);
          if (TtsCacheKey.isUsableAudio(localBytes)) {
            return TtsAudio.path(file.path);
          }
          try {
            await file.delete();
          } catch (_) {
            // Never return this file. The next lookup still rejects junk bytes.
          }
        }
      } on TimeoutException {
        // 디스크가 막혔다 — Storage 로 넘어간다.
      } catch (_) {
        // FileSystemException 등 그 외 I/O 실패(권한·손상 매체 등) —
        // 여기서 던지면 _resolveAudio 전체가 throw 해 Storage/CF 폴백을
        // 건너뛴다(finding 1a). Storage 로 넘어간다.
      }
    } else {
      final cached = _memoryCache[key.localFileName];
      if (cached != null) {
        return TtsAudio.bytes(cached);
      }
    }

    // 3. Firebase Storage (사전생성된 고정 콘텐츠)
    try {
      final Uint8List? data = await _storage
          .ref(key.storagePath)
          .getData(_maxBytes)
          .timeout(_storageTimeout);
      if (data != null && TtsCacheKey.isUsableAudio(data)) {
        return await _cacheAndWrap(key, file, data);
      }
    } on TimeoutException {
      // 느린 회선 — 무한정 붙잡느니 CF 를 시도한다.
    } catch (_) {
      // object-not-found / 오프라인 → CF 시도
    }

    // 4. Authenticated Firebase callable (dynamic synthesis).
    if (!allowSynthesis) {
      return null;
    }
    try {
      final installationId = await _installationIdProvider.getOrCreate();
      final bytes = await takeCallableAudio(
        invoke: () async {
          final result = await _functions
              .httpsCallable(
                _functionName,
                options: HttpsCallableOptions(
                  timeout: _netTimeout,
                  limitedUseAppCheckToken: true,
                ),
              )
              .call<Map<String, dynamic>>(
                buildTtsCallableData(
                  text: text,
                  voice: key.voice,
                  installationId: installationId,
                ),
              );
          final b64 = result.data['audioBase64'] as String?;
          if (b64 == null || b64.isEmpty) {
            return null;
          }
          final decoded = base64Decode(b64);
          if (!TtsCacheKey.isUsableAudio(decoded)) {
            return null;
          }
          return decoded;
        },
      );
      if (bytes != null) {
        return await _cacheAndWrap(key, file, bytes);
      }
    } on TtsSynthesisBlocked catch (blocked) {
      _reportUnavailable(blocked.reason);
      rethrow;
    } catch (_) {
      // Firebase/Auth/App Check 에 못 닿았다. 무음이지만 이유는 남긴다.
      _reportUnavailable(TtsUnavailableReason.offline);
    }
    return null;
  }

  @visibleForTesting
  static Future<TtsAudio?> resolveAudioForTesting(
    String text,
    String voice, {
    bool allowSynthesis = false,
  }) => _resolveAudio(text, voice, allowSynthesis: allowSynthesis);

  /// 받은 바이트를 플랫폼에 맞게 캐시하고 재생 가능한 형태로 감싼다.
  static Future<TtsAudio> _cacheAndWrap(
    TtsCacheKey key,
    File? file,
    Uint8List data,
  ) async {
    if (file == null) {
      if (_memoryCache.length >= _memoryCacheEntries) {
        _memoryCache.remove(_memoryCache.keys.first);
      }
      _memoryCache[key.localFileName] = data;
      return TtsAudio.bytes(data);
    }
    await _writeAtomically(file, data);
    return TtsAudio.path(file.path);
  }

  /// 임시 파일에 쓰고 rename 으로 갈아끼운다.
  ///
  /// 같은 캐시 파일을 프리페치(쓰기)와 재생(읽기)이 동시에 만진다 — 화면에
  /// 들어오면 낱자 34개를 받는 동안 사용자는 이미 카드를 누른다.
  /// `isUsableAudio` 는 길이와 앞 몇 바이트만 보므로 **쓰다 만 파일도 통과**해
  /// 잘린 소리가 나거나, 읽는 쪽이 "망가진 파일"로 판단해 프리페치가 쓰던
  /// 파일을 지워버린다. rename 은 같은 파일시스템에서 원자적이라 읽는 쪽은
  /// 항상 완성본 아니면 없음만 본다.
  static Future<void> _writeAtomically(File file, Uint8List bytes) async {
    final tmp = File('${file.path}.part');
    try {
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    } catch (_) {
      try {
        await tmp.delete();
      } catch (_) {
        // 임시 파일 정리 실패는 무해하다.
      }
      rethrow;
    }
  }

  /// Retry / fail-closed policy for one Cloud TTS callable sequence.
  @visibleForTesting
  static Future<Uint8List?> takeCallableAudio({
    required Future<Uint8List?> Function() invoke,
    int maxAttempts = 3,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await invoke();
      } catch (error) {
        final kind = TtsCallableFailure.fromError(error);
        if (kind == TtsCallableKind.retryInflight &&
            attempt < maxAttempts - 1) {
          continue;
        }
        if (kind == TtsCallableKind.retryInflight) {
          lastError = TtsCallableFailure.alreadyInProgressMessage;
          throw const TtsSynthesisBlocked(
            TtsCallableFailure.alreadyInProgressMessage,
            reason: TtsUnavailableReason.pendingSynthesis,
          );
        }
        if (kind == TtsCallableKind.blockQuota) {
          lastError = TtsCallableFailure.quotaMessage;
          throw const TtsSynthesisBlocked(
            TtsCallableFailure.quotaMessage,
            reason: TtsUnavailableReason.quota,
          );
        }
        if (kind == TtsCallableKind.blockUnavailable) {
          lastError = TtsCallableFailure.audioUnavailableMessage;
          throw const TtsSynthesisBlocked(
            TtsCallableFailure.audioUnavailableMessage,
            reason: TtsUnavailableReason.audioUnavailable,
          );
        }
        return null;
      }
    }
    return null;
  }

  static Future<TtsPlaybackSession?> _startAudio(
    TtsAudio audio,
    double playbackRate,
  ) async {
    final path = audio.path;
    final source = path != null
        ? DeviceFileSource(path)
        : BytesSource(audio.bytes!, mimeType: 'audio/mpeg');
    try {
      await _reapplySpeechAudioContext();
      // 완료 대기 future 를 play 전에 준비 (짧은 mp3 의 complete race 방지).
      final done = _player.onPlayerComplete.first.then((_) => true);
      return await TtsFilePlayback.start(
        completion: _guardCompletion(done, errorPrefix: 'mp3 재생 완료 대기 실패'),
        play: () => _player.play(
          source,
          volume: AudioPolicy.instance.volumeFor(SoundChannel.speech),
        ),
        setRate: _player.setPlaybackRate,
        stop: _player.stop,
        onError: (error) {
          lastError = 'mp3 재생 속도 설정 실패: $error';
        },
        rate: playbackRate,
      );
    } catch (e) {
      lastError = 'mp3 재생 실패: $e';
      try {
        await _player.stop();
      } catch (stopError) {
        lastError = 'mp3 재생 실패: $e; 정지 실패: $stopError';
        return TtsPlaybackSession(Future<bool>.value(false));
      }
      return null;
    }
  }

  static Future<bool> _guardCompletion(
    Future<bool> completion, {
    required String errorPrefix,
  }) async {
    try {
      return await completion;
    } catch (error) {
      lastError = '$errorPrefix: $error';
      return false;
    }
  }

  // ── 헬퍼 ───────────────────────────────────────────────────────────

  /// 캐시된 음성 mp3 전부 삭제 — 계정 삭제/전체 초기화 시 호출.
  static Future<void> clearCache({
    Future<Directory> Function()? cacheDirectory,
  }) async {
    try {
      await clearCacheStrict(cacheDirectory: cacheDirectory);
    } catch (_) {
      // best effort
    }
  }

  /// Account-deletion variant: any lookup or filesystem failure propagates.
  static Future<void> clearCacheStrict({
    Future<Directory> Function()? cacheDirectory,
  }) async {
    try {
      final dir = await (cacheDirectory ?? _strictCacheDirectory)();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } finally {
      _cacheDir = null;
    }
  }

  static Future<Directory> _strictCacheDirectory() async {
    if (_cacheDir case final cached?) {
      return cached;
    }
    final base = await getApplicationCacheDirectory();
    return Directory('${base.path}/tts_cache');
  }

  static Future<Directory?> _ensureCacheDir() async {
    if (kIsWeb) {
      return null; // path_provider 는 웹에서 던진다 — 메모리 캐시를 쓴다.
    }
    if (_cacheDir != null) {
      return _cacheDir;
    }
    try {
      final base = await getApplicationCacheDirectory();
      final dir = Directory('${base.path}/tts_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
      return dir;
    } catch (e) {
      lastError = '캐시 디렉토리 실패: $e';
      return null;
    }
  }

  /// TTS 플레이어 오디오 세션 — 발음은 들려야 하므로 duckOthers (ADR-002 §5-3).
  /// iOS 는 duckOthers 와 respectSilence 병용이 금지(playAndRecord 강제)라
  /// 여기서는 respectSilence 를 걸지 않는다 — 무음 스위치 존중은 SFX 전역
  /// 컨텍스트([AudioPolicy.applyPlatformAudioContext]) 몫.
  static Future<void> _reapplySpeechAudioContext() =>
      TtsSpeechAudioContext.reapply(_player.setAudioContext);
}
