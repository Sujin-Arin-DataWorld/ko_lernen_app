import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Phase 5 (stately-rising-jongga) — On-device OCR wrapper for "책 한 컷".
///
/// **Privacy**: Bild verlässt das Gerät NICHT. Nur extrahierter Text wird
/// später für Übersetzung/Analyse zum Cloud Function gesendet.
///
/// **Use**: `TextRecognitionScript.korean` für 한국어 텍스트. Wird beim Aufruf
/// instanziiert und nach Gebrauch sofort `close()` — kein Ressourcen-Leak.
class SnapOcrService {
  /// Erkennt koreanischen Text in [imageFile]. Gibt das volle erkannte Text
  /// + Anzahl der Textblöcke zurück. Bei Fehler: `OcrResult.failure`.
  static Future<OcrResult> recognizeKorean(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final result = await recognizer.processImage(input);
      // Blöcke nach Y-Position sortieren — Lesereihenfolge oben → unten.
      final blocks = [...result.blocks];
      blocks.sort((a, b) =>
          a.boundingBox.top.compareTo(b.boundingBox.top));
      final text = blocks.map((b) => b.text).join('\n').trim();
      if (text.isEmpty) {
        return OcrResult.failure(reason: OcrFailure.noKoreanFound);
      }
      return OcrResult.success(
        text: text,
        blockCount: result.blocks.length,
      );
    } catch (e) {
      return OcrResult.failure(reason: OcrFailure.engineError, message: '$e');
    } finally {
      await recognizer.close();
    }
  }
}

enum OcrFailure {
  noKoreanFound,
  engineError,
}

class OcrResult {
  final String? text;
  final int blockCount;
  final OcrFailure? failure;
  final String? message;

  const OcrResult._({
    required this.text,
    required this.blockCount,
    required this.failure,
    required this.message,
  });

  factory OcrResult.success({required String text, required int blockCount}) =>
      OcrResult._(
        text: text,
        blockCount: blockCount,
        failure: null,
        message: null,
      );

  factory OcrResult.failure({required OcrFailure reason, String? message}) =>
      OcrResult._(
        text: null,
        blockCount: 0,
        failure: reason,
        message: message,
      );

  bool get isSuccess => failure == null;
}
