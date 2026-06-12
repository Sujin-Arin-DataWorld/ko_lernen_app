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

  /// 폴백(flutter_tts)에서 ko 음성 존재 여부. 화면 안내용.
  static bool koVoiceAvailable = false;

  static FirebaseStorage get _storage =>
      FirebaseStorage.instanceFor(bucket: _bucket);

  // ── 공개 API ───────────────────────────────────────────────────────

  /// 표준 속도 재생. voice: 'female'(기본) / 'male'.
  static Future<bool> speak(String text, {String voice = 'female'}) {
    return _speak(text, voice: voice, playbackRate: 1.0);
  }

  /// 느리게 재생 (학습 보조). 사전생성 mp3 는 0.65 배속, 폴백은 rate 0.30.
  static Future<bool> speakSlow(String text, {String voice = 'female'}) {
    return _speak(text, voice: voice, playbackRate: 0.65, fallbackRate: 0.30);
  }

  static Future<void> stop() async {
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

  static Future<bool> _speak(
    String text, {
    required String voice,
    required double playbackRate,
    double? fallbackRate,
  }) async {
    final t = text.trim();
    if (t.isEmpty) {
      return false;
    }
    final v = (voice == 'male') ? 'male' : 'female';

    final File? file = await _resolveFile(t, v);
    if (file != null) {
      return _playFile(file, playbackRate);
    }
    // 4. flutter_tts 폴백
    return _fallback(t, fallbackRate);
  }

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
      final Uint8List? data =
          await _storage.ref('tts/$voice/$hash.mp3').getData(_maxBytes);
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

  static Future<bool> _playFile(File file, double playbackRate) async {
    try {
      await stop();
      // 완료 대기 future 를 play 전에 준비 (짧은 mp3 의 complete race 방지).
      final done = _player.onPlayerComplete.first;
      try {
        await _player.setPlaybackRate(playbackRate);
      } catch (_) {
        // 일부 플랫폼은 play 전 setPlaybackRate 미지원 — 무시.
      }
      await _player.play(DeviceFileSource(file.path));
      await done.timeout(_playTimeout, onTimeout: () {});
      return true;
    } catch (e) {
      lastError = 'mp3 재생 실패: $e';
      return false;
    }
  }

  static Future<bool> _fallback(String text, double? rate) async {
    try {
      await _initTts();
      try {
        await _tts.stop();
      } catch (_) {}
      await _tts.setSpeechRate(rate ?? Storage.ttsRate);
      final result = await _tts.speak(text);
      return result == 1;
    } catch (e) {
      lastError = 'TTS 폴백 실패: $e';
      return false;
    }
  }

  // ── 헬퍼 ───────────────────────────────────────────────────────────

  /// 사전생성 스크립트(Python)와 **동일한** 키 규칙: sha1("$voice|$text").
  static String _hash(String voice, String text) {
    return sha1.convert(utf8.encode('$voice|$text')).toString();
  }

  /// 캐시된 음성 mp3 전부 삭제 — 계정 삭제/전체 초기화 시 호출.
  static Future<void> clearCache() async {
    try {
      final dir = await _ensureCacheDir();
      if (dir != null && await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // best effort
    } finally {
      _cacheDir = null;
    }
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
