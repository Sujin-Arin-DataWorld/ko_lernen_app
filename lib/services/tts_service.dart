import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool   _initialized = false;
  static String? lastError;

  static Future<void> _init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(Storage.ttsRate);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _initialized = true;
    } catch (e) {
      lastError = 'TTS-Initialisierung fehlgeschlagen: $e';
    }
  }

  /// Spricht den Text. Gibt `true` zurück bei Erfolg, sonst `false`.
  static Future<bool> speak(String text) async {
    try {
      await _init();
      await _tts.stop();
      final result = await _tts.speak(text);
      return result == 1;
    } catch (e) {
      lastError = 'TTS-Wiedergabe fehlgeschlagen: $e';
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
