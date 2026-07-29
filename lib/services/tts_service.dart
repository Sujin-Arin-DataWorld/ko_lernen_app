import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'storage_service.dart';

typedef TtsAudioResolver = Future<File?> Function(String text, String voice);
typedef TtsErrorReporter = void Function(String message);

class TtsPlaybackRates {
  const TtsPlaybackRates({required this.speechRate, required this.fileRate});

  static const double defaultSpeechRate = 0.42;
  final double speechRate;
  final double fileRate;

  static TtsPlaybackRates compose({
    required double baseRate,
    required double multiplier,
  }) {
    final safeBase = baseRate.isFinite ? baseRate : defaultSpeechRate;
    final safeMultiplier = multiplier.isFinite ? multiplier : 1.0;
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
          onError: (_, __) => const _TtsResolution(file: null),
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
  const _TtsResolution({required this.file}) : wasCancelled = false;
  const _TtsResolution.cancelled() : file = null, wasCancelled = true;

  final File? file;
  final bool wasCancelled;
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
/// 2. Firebase Storage `tts/{voice}/{sha1}.mp3` → 다운로드·캐시·재생
///    (사전생성된 고정 콘텐츠: 526 단어 + 526 예문 + 204 대화)
/// 3. Cloud Function 합성 → base64 수신·캐시·재생
///    (동적 콘텐츠: 책 한 컷 OCR·내 단어장의 사용자 입력 단어)
/// 4. flutter_tts 폴백 (오프라인 + 미캐시 → 기존 OS 음성)
///
/// 공개 인터페이스(`speak`/`speakSlow`/`stop`/`setRate`/`rate`)는 기존과
/// 호환되므로 23개 호출 화면을 수정할 필요가 없다.
/// `voice`: 'female'(Chirp3-HD-Aoede, 기본) / 'male'(Neural2-C).
///
/// 웹에서는 path_provider 캐시 디렉토리가 없어 1~3단계가 자동 실패 →
/// 기존 flutter_tts 폴백으로 동작 (웹은 개발 테스트용).
class TtsService {
  TtsService._();

  // ── 설정 ──────────────────────────────────────────────────────────
  /// Firebase Storage 버킷. Storage 활성화 후 실제 버킷명으로 교정할 것
  /// (신형 프로젝트는 `*.firebasestorage.app`, 구형은 `*.appspot.com`).
  static const String _bucket = 'gs://ko-lernen-app.firebasestorage.app';

  /// 동적 합성 Cloud Function 엔드포인트. main.dart / RemoteConfig 에서 주입.
  /// 빈 값이면 3단계(CF)를 건너뛰고 flutter_tts 폴백으로 간다.
  static String ttsFnEndpoint = '';
  static void setEndpoint(String url) => ttsFnEndpoint = url.trim();

  static const Duration _netTimeout = Duration(seconds: 12);
  static const Duration _playTimeout = Duration(seconds: 30);
  static const int _maxBytes = 5 * 1024 * 1024; // 5MB/파일 상한

  // ── 내부 상태 ──────────────────────────────────────────────────────
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();
  static bool _ttsInit = false;
  static Directory? _cacheDir;
  static String? lastError;
  static final TtsPlaybackEngine _playbackEngine = TtsPlaybackEngine(
    resolveFile: _resolveFile,
    platform: const _ServicePlaybackPlatform(),
    completionTimeout: _playTimeout,
    errorReporter: (message) => lastError = message,
  );

  /// 폴백(flutter_tts)에서 ko 음성 존재 여부. 화면 안내용.
  static bool koVoiceAvailable = false;

  static FirebaseStorage get _storage =>
      FirebaseStorage.instanceFor(bucket: _bucket);

  // ── 공개 API ───────────────────────────────────────────────────────

  /// 표준 속도 재생. voice: 'female'(기본) / 'male'.
  static Future<bool> speak(
    String text, {
    String voice = 'female',
    double rateMultiplier = 1.0,
  }) {
    return _playbackEngine.speak(
      text: text,
      voice: voice,
      baseRate: Storage.ttsRate,
      rateMultiplier: rateMultiplier,
    );
  }

  /// 느리게 재생 (학습 보조). 사용자 기본 속도에 요청 배수 0.65를 곱한다.
  static Future<bool> speakSlow(String text, {String voice = 'female'}) {
    return speak(text, voice: voice, rateMultiplier: 0.65);
  }

  static Future<void> stop() => _playbackEngine.stop();

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

  // ── 핵심 흐름 ──────────────────────────────────────────────────────

  /// 캐시 → Storage → CF 순으로 mp3 파일을 확보. 실패 시 null.
  static Future<File?> _resolveFile(String text, String voice) async {
    final dir = await _ensureCacheDir();
    if (dir == null) {
      return null;
    }
    final hash = _hash(voice, text);
    final file = File('${dir.path}/${voice}_$hash.mp3');

    // 1. 로컬 캐시
    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    // 2. Firebase Storage (사전생성된 고정 콘텐츠)
    try {
      final Uint8List? data = await _storage
          .ref('tts/$voice/$hash.mp3')
          .getData(_maxBytes);
      if (data != null && data.isNotEmpty) {
        await file.writeAsBytes(data, flush: true);
        return file;
      }
    } catch (_) {
      // object-not-found / 오프라인 → CF 시도
    }

    // 3. Cloud Function (동적 합성)
    if (ttsFnEndpoint.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse(ttsFnEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'text': text, 'voice': voice}),
            )
            .timeout(_netTimeout);
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final b64 = body['audioBase64'] as String?;
          if (b64 != null && b64.isNotEmpty) {
            final bytes = base64Decode(b64);
            await file.writeAsBytes(bytes, flush: true);
            return file;
          }
        }
      } catch (_) {
        // 폴백으로
      }
    }
    return null;
  }

  static Future<TtsPlaybackSession?> _startFile(
    File file,
    double playbackRate,
  ) async {
    try {
      // 완료 대기 future 를 play 전에 준비 (짧은 mp3 의 complete race 방지).
      final done = _player.onPlayerComplete.first.then((_) => true);
      return await TtsFilePlayback.start(
        completion: _guardCompletion(done, errorPrefix: 'mp3 재생 완료 대기 실패'),
        play: () => _player.play(DeviceFileSource(file.path)),
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
      await _tts.setSpeechRate(rate);
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

  /// 사전생성 스크립트(Python)와 **동일한** 키 규칙: sha1("$voice|$text").
  static String _hash(String voice, String text) {
    return sha1.convert(utf8.encode('$voice|$text')).toString();
  }

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
      await _tts.setVolume(1.0);
      _ttsInit = true;
    } catch (e) {
      lastError = 'TTS 초기화 실패: $e';
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
