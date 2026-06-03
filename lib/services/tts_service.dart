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
  static Future<void> _trySelectKoreanVoice() async {
    try {
      final voices = await _tts.getVoices;
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
      await _tts.stop();
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
      await _tts.stop();
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
