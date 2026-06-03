import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool   _initialized = false;
  static String? lastError;

  static Future<void> _init() async {
    if (_initialized) return;
    try {
      // Web (Chrome): ohne awaitSpeakCompletion werden längere Äußerungen
      // abgeschnitten ("da…"). Mit true wartet speak() bis zum Ende.
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('ko-KR');
      // Falls eine koreanische Stimme installiert ist, sie explizit wählen —
      // sonst liest die Standardstimme (z.B. DE im Browser) Hangul falsch vor.
      await _trySelectKoreanVoice();
      await _tts.setSpeechRate(Storage.ttsRate);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _initialized = true;
    } catch (e) {
      lastError = 'TTS-Initialisierung fehlgeschlagen: $e';
    }
  }

  /// Sucht in den verfügbaren Stimmen eine koreanische (locale beginnt mit
  /// "ko") und wählt sie. Best-effort: nicht jede Plattform liefert getVoices,
  /// und ohne installierte ko-Stimme bleibt es bei setLanguage('ko-KR').
  /// true = 이 플랫폼/브라우저에 한국어 음성이 실제로 존재. false면 (특히 웹에서)
  /// 한국어가 무음일 수 있다 — 브라우저에 ko 보이스 미설치. 화면 안내용으로 사용 가능.
  static bool koVoiceAvailable = false;

  static Future<void> _trySelectKoreanVoice() async {
    try {
      // 웹: getVoices가 첫 호출에 빈 목록을 주는 경우가 많다(보이스 지연 로드).
      // 비어 있으면 짧게 대기 후 한 번 재시도.
      var voices = await _tts.getVoices;
      if (voices is List && voices.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        voices = await _tts.getVoices;
      }
      if (voices is! List) return;
      for (final v in voices) {
        if (v is! Map) continue;
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        final name = (v['name'] ?? '').toString();
        if (locale.startsWith('ko') || locale.contains('ko-') ||
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
      // getVoices/setVoice nicht überall unterstützt — ignorieren.
    }
  }

  /// Spricht den Text. Gibt `true` zurück bei Erfolg, sonst `false`.
  static Future<bool> speak(String text) async {
    try {
      await _init();
      // stop()은 이전 발화를 끊기 위함. 웹에서 cancel()이 SpeechSynthesisErrorEvent를
      // 던질 수 있으므로 guard — 던져도 새 speak는 계속 진행.
      try {
        await _tts.stop();
      } catch (_) {}
      // Re-apply user rate in case slow mode altered it last time.
      await _tts.setSpeechRate(Storage.ttsRate);
      final result = await _tts.speak(text);
      return result == 1;
    } catch (e) {
      lastError = 'TTS-Wiedergabe fehlgeschlagen: $e';
      return false;
    }
  }

  /// Spricht langsamer (rate 0.30) — Lerner-Hilfe. Beendet danach
  /// die nächste `speak()` mit normalem rate (siehe oben).
  static Future<bool> speakSlow(String text) async {
    try {
      await _init();
      try {
        await _tts.stop();
      } catch (_) {}
      await _tts.setSpeechRate(0.30);
      final result = await _tts.speak(text);
      return result == 1;
    } catch (e) {
      lastError = 'TTS slow fehlgeschlagen: $e';
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// 0.1 (langsam) ... 1.0 (schnell). Default 0.42 (Lerntempo).
  static Future<void> setRate(double rate) async {
    final clamped = rate.clamp(0.1, 1.0);
    await Storage.setTtsRate(clamped);
    try {
      await _init();
      await _tts.setSpeechRate(clamped);
    } catch (e) {
      lastError = 'TTS-Geschwindigkeit konnte nicht gesetzt werden: $e';
    }
  }

  static double get rate => Storage.ttsRate;
}
