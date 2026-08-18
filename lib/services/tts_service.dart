import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_policy.dart';
import 'hangul_util.dart';
import 'analytics_service.dart';
import 'storage_service.dart';
import 'tts_installation_id.dart';

typedef TtsAudioResolver = Future<File?> Function(String text, String voice);
typedef TtsErrorReporter = void Function(String message);

/// Cloud TTS refused this request. The playback engine must not fall through
/// to OS speech — quota and in-flight waits are not "use the robot voice".
class TtsSynthesisBlocked implements Exception {
  const TtsSynthesisBlocked(this.message);

  final String message;

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

/// Immutable, revisioned address for one synthesized TTS request.
///
/// The same `{voice}|{text}` SHA-1 input is deliberately shared with the
/// Cloud Function and the pre-generation script.  A revision in the object
/// path prevents an audio-setting change from reusing an immutable old object
/// from Firebase Storage or a CDN.
class TtsCacheKey {
  const TtsCacheKey._({
    required this.revision,
    required this.voice,
    required this.hash,
  });

  static const String currentRevision = 'v3';

  factory TtsCacheKey.forRequest({
    required String voice,
    required String text,
  }) {
    final normalizedVoice = voice == 'male' ? 'male' : 'female';
    final normalizedText = text.trim();
    final hash = sha1
        .convert(utf8.encode('$normalizedVoice|$normalizedText'))
        .toString();
    return TtsCacheKey._(
      revision: currentRevision,
      voice: normalizedVoice,
      hash: hash,
    );
  }

  final String revision;
  final String voice;
  final String hash;

  String get storagePath => 'tts/$revision/$voice/$hash.mp3';
  String get localFileName => 'tts_${revision}_${voice}_$hash.mp3';

  /// Same MPEG/ID3 floor the Cloud Function uses before treating bytes as audio.
  static bool isUsableAudio(List<int> data) {
    if (data.length < 32) {
      return false;
    }
    if (data[0] == 0x49 && data[1] == 0x44 && data[2] == 0x33) {
      return true;
    }
    return data[0] == 0xFF && (data[1] & 0xE0) == 0xE0;
  }
}

class TtsPlaybackRates {
  const TtsPlaybackRates({required this.speechRate, required this.fileRate});

  static const double defaultSpeechRate = 0.42;
  final double speechRate;
  final double fileRate;

  /// [userMultiplier] = 전역 사용자 속도 배수 (`Storage.ttsSpeed`, 프리셋
  /// 0.5–1.5). 요청별 [multiplier](speakSlow 0.65, 화면 오버라이드)와 곱해져
  /// mp3(fileRate)·flutter_tts(speechRate) 양쪽에 같은 clamp 로 반영된다.
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

abstract interface class TtsPlaybackPlatform {
  Future<TtsPlaybackSession?> startFile(File file, double rate);
  Future<TtsPlaybackSession?> startSpeech(String text, double rate);
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

/// Executes one TTS request with an immutable, request-local playback rate.
class TtsPlaybackEngine {
  TtsPlaybackEngine({
    required this.resolveFile,
    required this.platform,
    this.completionTimeout = const Duration(seconds: 30),
    this.errorReporter,
  });

  final TtsAudioResolver resolveFile;
  final TtsPlaybackPlatform platform;
  final Duration completionTimeout;
  final TtsErrorReporter? errorReporter;
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
        Future<File?>.sync(
          () => resolveFile(trimmed, normalizedVoice),
        ).then<_TtsResolution>(
          (file) => _TtsResolution(file: file),
          onError: (Object error, _) {
            if (error is TtsSynthesisBlocked) {
              errorReporter?.call(error.message);
              return const _TtsResolution.blocked();
            }
            return const _TtsResolution(file: null);
          },
        );
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
    final file = resolved.file;

    TtsPlaybackSession? session;
    try {
      session = await _serialize<TtsPlaybackSession?>(() async {
        if (_disposed || generation != _generation) return null;
        if (file != null) {
          try {
            final fileSession = await platform.startFile(file, rates.fileRate);
            if (fileSession != null) return fileSession;
          } catch (error) {
            // A thrown start may mean playback began but cleanup failed.
            errorReporter?.call('TTS file playback start failed: $error');
            return null;
          }
          if (_disposed || generation != _generation) return null;
        }
        if (resolved.blockSpeechFallback) {
          return null;
        }
        return platform.startSpeech(trimmed, rates.speechRate);
      });
    } catch (error) {
      errorReporter?.call('TTS platform playback start failed: $error');
      return false;
    }
    if (session == null || _disposed || generation != _generation) {
      return false;
    }
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
  const _TtsResolution({required this.file})
    : wasCancelled = false,
      blockSpeechFallback = false;
  const _TtsResolution.cancelled()
    : file = null,
      wasCancelled = true,
      blockSpeechFallback = false;
  const _TtsResolution.blocked()
    : file = null,
      wasCancelled = false,
      blockSpeechFallback = true;

  final File? file;
  final bool wasCancelled;
  final bool blockSpeechFallback;
}

class _ServicePlaybackPlatform implements TtsPlaybackPlatform {
  const _ServicePlaybackPlatform();

  @override
  Future<TtsPlaybackSession?> startFile(File file, double rate) =>
      TtsService._startFile(file, rate);

  @override
  Future<TtsPlaybackSession?> startSpeech(String text, double rate) =>
      TtsService._startFallback(text, rate);

  @override
  Future<void> stop() => TtsService._stopPlatforms();
}

/// 고품질 한국어 발음 TTS — **캐시 우선 3단**.
///
/// 1. 로컬 캐시 mp3 → 즉시 재생 (오프라인·무료)
/// 2. Firebase Storage `tts/v3/{voice}/{sha1}.mp3` → 다운로드·캐시·재생
///    (사전생성된 고정 콘텐츠: 558 단어 + 558 예문 + 204 대화 — dedup 후 1,314)
/// 3. Cloud Function 합성 → base64 수신·캐시·재생
///    (동적 콘텐츠: 책 한 컷 OCR·내 단어장의 사용자 입력 단어)
/// 4. flutter_tts 폴백 (오프라인 + 미캐시 → 기존 OS 음성)
///
/// 공개 인터페이스(`speak`/`speakSlow`/`stop`/`setRate`/`rate`)는 기존과
/// 호환되므로 23개 호출 화면을 수정할 필요가 없다.
/// `voice`: 'female'(Chirp3-HD-Zephyr, 기본) / 'male'(Chirp3-HD-Enceladus).
///
/// 웹에서는 path_provider 캐시 디렉토리가 없어 1~3단계가 자동 실패 →
/// 기존 flutter_tts 폴백으로 동작 (웹은 개발 테스트용).
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
  static const int _maxBytes = 5 * 1024 * 1024; // 5MB/파일 상한

  // ── 내부 상태 ──────────────────────────────────────────────────────
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();
  static bool _ttsInit = false;
  static Directory? _cacheDir;
  static String? lastError;
  static final TtsInstallationIdProvider _installationIdProvider =
      TtsInstallationIdProvider();
  static final TtsPlaybackEngine _playbackEngine = TtsPlaybackEngine(
    resolveFile: _resolveFile,
    platform: const _ServicePlaybackPlatform(),
    completionTimeout: _playTimeout,
    errorReporter: (message) => lastError = message,
  );

  /// 폴백(flutter_tts)에서 ko 음성 존재 여부. 화면 안내용.
  static bool koVoiceAvailable = false;

  /// 발화 중 여부 — [AudioPolicy] 더킹·UI 표시용 (ADR-002 §5-2).
  static final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);
  static int _speakToken = 0;
  static bool _speechContextApplied = false;

  static FirebaseStorage get _storage =>
      FirebaseStorage.instanceFor(bucket: _bucket);
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: _functionRegion);

  // ── 공개 API ───────────────────────────────────────────────────────

  /// 표준 속도 재생. voice: 'female'(기본) / 'male'.
  /// speech 채널이 꺼져 있으면(설정) 재생하지 않고 false 를 반환한다.
  static Future<bool> speak(
    String text, {
    String voice = 'female',
    double rateMultiplier = 1.0,
  }) {
    if (AudioPolicy.instance.volumeFor(SoundChannel.speech) <= 0) {
      lastError = 'speech 채널이 꺼져 있음 (설정 → Ton)';
      return Future<bool>.value(false);
    }
    final token = ++_speakToken;
    speaking.value = true;
    AudioPolicy.instance.noteSpeechStarted();
    Analytics.ttsPlayed(
      contentType: text.trim().contains(RegExp(r'[\s.!?]'))
          ? 'sentence'
          : 'word',
    );
    final result = _playbackEngine.speak(
      text: text,
      voice: voice,
      baseRate: Storage.ttsRate,
      rateMultiplier: rateMultiplier,
      userMultiplier: Storage.ttsSpeed,
    );
    result.whenComplete(() {
      // 새 발화가 이미 시작됐으면(토큰 불일치) 종료 처리를 그쪽에 맡긴다.
      if (token == _speakToken) {
        speaking.value = false;
        AudioPolicy.instance.noteSpeechEnded();
      }
    });
    return result;
  }

  /// 느리게 재생 (학습 보조). 사용자 기본 속도에 요청 배수 0.65를 곱한다.
  static Future<bool> speakSlow(String text, {String voice = 'female'}) {
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
  static Future<void> prefetch(String text, {String voice = 'female'}) async {
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
    final key = '$voice|$trimmed';
    if (!_prefetchAttempted.add(key)) {
      return;
    }
    try {
      await _resolveFile(trimmed, voice, allowSynthesis: false);
    } catch (_) {
      // 조용히 무시 — 최선 노력이다.
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
    String voice = 'female',
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
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// 0.1 (langsam) … 1.0 (schnell). flutter_tts 폴백용 + 저장.
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

  /// 캐시 → Storage → CF 순으로 mp3 파일을 확보. 실패 시 null.
  ///
  /// [allowSynthesis] 가 false 면 **3단(Cloud Function 동적 합성)을 건너뛴다**.
  /// 프리페치 전용 스위치다 — 아직 누르지도 않은 낱자를 투기적으로 합성하면
  /// 합성 할당량을 쓰고 12초 타임아웃까지 잡아먹는다. 사용자가 실제로 누르면
  /// 그때 평소 경로가 3단까지 간다.
  static Future<File?> _resolveFile(
    String text,
    String voice, {
    bool allowSynthesis = true,
  }) async {
    final dir = await _ensureCacheDir();
    if (dir == null) {
      return null;
    }
    final key = TtsCacheKey.forRequest(voice: voice, text: text);
    final file = File('${dir.path}/${key.localFileName}');

    // 1. 로컬 캐시
    if (await file.exists()) {
      final localBytes = await file.readAsBytes();
      if (TtsCacheKey.isUsableAudio(localBytes)) {
        return file;
      }
      try {
        await file.delete();
      } catch (_) {
        // Never return this file. The next lookup still rejects junk bytes.
      }
    }

    // 2. Firebase Storage (사전생성된 고정 콘텐츠)
    try {
      final Uint8List? data = await _storage
          .ref(key.storagePath)
          .getData(_maxBytes);
      if (data != null && TtsCacheKey.isUsableAudio(data)) {
        await _writeAtomically(file, data);
        return file;
      }
    } catch (_) {
      // object-not-found / 오프라인 → CF 시도
    }

    // 3. Authenticated Firebase callable (dynamic synthesis).
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
        await _writeAtomically(file, bytes);
        return file;
      }
    } on TtsSynthesisBlocked {
      rethrow;
    } catch (_) {
      // Firebase/Auth/App Check unavailable → OS TTS fallback.
    }
    return null;
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
        if (kind == TtsCallableKind.blockQuota) {
          lastError = TtsCallableFailure.quotaMessage;
          throw const TtsSynthesisBlocked(TtsCallableFailure.quotaMessage);
        }
        if (kind == TtsCallableKind.blockUnavailable) {
          lastError = TtsCallableFailure.audioUnavailableMessage;
          throw const TtsSynthesisBlocked(
            TtsCallableFailure.audioUnavailableMessage,
          );
        }
        return null;
      }
    }
    return null;
  }

  static Future<TtsPlaybackSession?> _startFile(
    File file,
    double playbackRate,
  ) async {
    try {
      await _ensureSpeechAudioContext();
      // 완료 대기 future 를 play 전에 준비 (짧은 mp3 의 complete race 방지).
      final done = _player.onPlayerComplete.first.then((_) => true);
      return await TtsFilePlayback.start(
        completion: _guardCompletion(done, errorPrefix: 'mp3 재생 완료 대기 실패'),
        play: () => _player.play(
          DeviceFileSource(file.path),
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

  static Future<TtsPlaybackSession?> _startFallback(
    String text,
    double rate,
  ) async {
    try {
      await _initTts();
      await _applyFallbackLanguage(text);
      await _tts.setSpeechRate(rate);
      await _tts.setVolume(AudioPolicy.instance.volumeFor(SoundChannel.speech));
      final completion = _guardCompletion(
        _tts.speak(text).then((result) => result == 1),
        errorPrefix: 'TTS 폴백 완료 대기 실패',
      );
      return TtsPlaybackSession(completion);
    } catch (e) {
      lastError = 'TTS 폴백 실패: $e';
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
  static Future<void> _ensureSpeechAudioContext() async {
    if (_speechContextApplied) {
      return;
    }
    _speechContextApplied = true;
    try {
      await _player.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.duckOthers).build(),
      );
    } catch (_) {
      // best-effort — 실패 시 플랫폼 기본 세션으로 재생.
    }
  }

  static Future<void> _initTts() async {
    if (_ttsInit) {
      return;
    }
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('ko-KR');
      await _trySelectKoreanVoice();
      await _tts.setSpeechRate(Storage.ttsRate);
      await _tts.setPitch(1.0);
      await _tts.setVolume(AudioPolicy.instance.volumeFor(SoundChannel.speech));
      _ttsInit = true;
    } catch (e) {
      lastError = 'TTS 초기화 실패: $e';
    }
  }

  /// 마지막으로 OS 엔진에 넘긴 언어. 같은 언어면 다시 설정하지 않는다
  /// (setLanguage 는 엔진에 따라 수십 ms 걸린다).
  static String? _fallbackLanguage;

  /// OS 폴백으로 읽을 때 **텍스트에 맞는 언어**를 고른다.
  ///
  /// _initTts 가 ko-KR 을 한 번 설정하고 끝이라, 독일어 문장도 한국어 엔진이
  /// 읽어 알아들을 수 없는 소리가 났다("독일어랑 한국어랑 구분을 못해" — Jin,
  /// 2026-08-12 Buchseite einlesen). 한글이 하나라도 있으면 한국어, 아니면
  /// 학습자의 모국어(독일어/영어)로 본다 — 이 앱에서 비한글 텍스트는 뜻풀이·
  /// 예문 번역이라 사실상 그 둘뿐이다.
  ///
  /// HD mp3 가 있을 때는 여기까지 오지 않는다. 폴백 전용 처리다.
  static Future<void> _applyFallbackLanguage(String text) async {
    final hasHangul = text.runes.any(
      (r) => isHangulSyllable(r) || (r >= 0x3131 && r <= 0x318E), // 홀자모(ㄱ·ㅏ…)
    );
    // localeCode 는 'de' | 'en' | ''(시스템). 빈 값이면 이 앱의 기본인 독일어.
    final language = hasHangul
        ? 'ko-KR'
        : (Storage.localeCode == 'en' ? 'en-US' : 'de-DE');
    if (_fallbackLanguage == language) {
      return;
    }
    try {
      await _tts.setLanguage(language);
      _fallbackLanguage = language;
    } catch (e) {
      // 기기에 그 언어 데이터가 없을 수 있다 — 그대로 두는 편이 낫다.
      lastError = 'TTS 언어 설정 실패($language): $e';
    }
  }

  static Future<void> _trySelectKoreanVoice() async {
    try {
      var voices = await _tts.getVoices;
      if (voices is List && voices.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        voices = await _tts.getVoices;
      }
      if (voices is! List) {
        return;
      }
      for (final v in voices) {
        if (v is! Map) {
          continue;
        }
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        final name = (v['name'] ?? '').toString();
        if (locale.startsWith('ko') ||
            locale.contains('ko-') ||
            name.toLowerCase().contains('korean')) {
          await _tts.setVoice({
            'name': name,
            'locale': (v['locale'] ?? 'ko-KR').toString(),
          });
          koVoiceAvailable = true;
          return;
        }
      }
    } catch (_) {
      // getVoices/setVoice 미지원 플랫폼 — 무시.
    }
  }
}
