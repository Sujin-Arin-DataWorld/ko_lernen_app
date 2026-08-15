import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/snap_ocr_service.dart';

void main() {
  OcrTextBlock block(
    String text,
    double left,
    double top, {
    OcrScript script = OcrScript.korean,
    double? confidence,
    double? angle,
    double width = 80,
  }) => OcrTextBlock(
    text: text,
    bounds: Rect.fromLTWH(left, top, width, 24),
    script: script,
    confidence: confidence,
    angle: angle,
  );

  test('reads a bilingual two-column page down each column', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('German top', 260, 12, script: OcrScript.latin),
      block('\uD55C\uAE00 top', 20, 10),
      block('German bottom', 260, 80, script: OcrScript.latin),
      block('\uD55C\uAE00 bottom', 20, 76),
    ]);

    expect(ordered.map((item) => item.text), [
      '\uD55C\uAE00 top',
      '\uD55C\uAE00 bottom',
      'German top',
      'German bottom',
    ]);
  });

  test('removes an overlapping duplicate OCR line', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('\uD55C\uAD6D', 20, 10),
      block('\uD55C\uAD6D', 20, 10, script: OcrScript.latin),
      block('lesson', 20, 50, script: OcrScript.latin),
    ]);

    expect(ordered.map((item) => item.text), ['\uD55C\uAD6D', 'lesson']);
  });

  test('drops unsupported-script OCR noise from a bilingual page', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('한국어 문법', 20, 10),
      block('مرحبا', 20, 45, script: OcrScript.korean),
      block('Deutsche Erklärung', 20, 80, script: OcrScript.latin),
    ]);

    expect(ordered.map((item) => item.text), ['한국어 문법', 'Deutsche Erklärung']);
  });

  test('reads a three-column textbook down each column', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('C top', 420, 10, script: OcrScript.latin),
      block('A bottom', 20, 70),
      block('B top', 220, 12, script: OcrScript.latin),
      block('A top', 20, 10),
      block('C bottom', 420, 72, script: OcrScript.latin),
      block('B bottom', 220, 68, script: OcrScript.latin),
    ]);

    expect(ordered.map((item) => item.text), [
      'A top',
      'A bottom',
      'B top',
      'B bottom',
      'C top',
      'C bottom',
    ]);
  });

  test('keeps a full-width heading before the columns it introduces', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('B bottom', 280, 100, script: OcrScript.latin),
      block('단원 제목', 10, 5, width: 510),
      block('A bottom', 20, 98),
      block('B top', 280, 52, script: OcrScript.latin),
      block('A top', 20, 50),
    ]);

    expect(ordered.map((item) => item.text), [
      '단원 제목',
      'A top',
      'A bottom',
      'B top',
      'B bottom',
    ]);
  });

  test('keeps a full-width section separator between column bands', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('right after 2', 280, 180, script: OcrScript.latin),
      block('left before 1', 20, 20),
      block('구분 제목', 10, 100, width: 510),
      block('right before 2', 280, 62, script: OcrScript.latin),
      block('left after 1', 20, 140),
      block('right before 1', 280, 22, script: OcrScript.latin),
      block('left before 2', 20, 60),
      block('right after 1', 280, 142, script: OcrScript.latin),
      block('left after 2', 20, 178),
    ]);

    expect(ordered.map((item) => item.text), [
      'left before 1',
      'left before 2',
      'right before 1',
      'right before 2',
      '구분 제목',
      'left after 1',
      'left after 2',
      'right after 1',
      'right after 2',
    ]);
  });

  test('unsupported script ratio at 20 percent is severe', () {
    final quality = SnapOcrService.evaluateOcrQuality([
      block('가나다라م', 20, 10, confidence: 0.9),
    ]);

    expect(quality.unsupportedScriptRatio, closeTo(0.20, 0.000001));
    expect(quality.severeWarnings, contains('ocr_unsupported_script_severe'));
  });

  test('half of available Korean confidences below threshold is severe', () {
    final quality = SnapOcrService.evaluateOcrQuality([
      block('안녕하세요', 20, 10, confidence: 0.44),
      block('감사합니다', 20, 40, confidence: 0.90),
    ]);

    expect(quality.lowConfidenceRatio, 0.5);
    expect(quality.severeWarnings, contains('ocr_low_confidence_severe'));
  });

  test('all-null iOS confidence emits unavailable warning only', () {
    final quality = SnapOcrService.evaluateOcrQuality([
      block('안녕하세요', 20, 10),
      block('감사합니다', 20, 40),
    ]);

    expect(quality.confidenceUnavailable, isTrue);
    expect(quality.warnings, contains('ocr_confidence_unavailable'));
    expect(quality.severeWarnings, isEmpty);
  });

  test('median line rotation over 12 degrees with three lines is severe', () {
    final quality = SnapOcrService.evaluateOcrQuality([
      block('하나', 20, 10, confidence: 0.9, angle: 14),
      block('둘', 20, 40, confidence: 0.9, angle: 16),
      block('셋', 20, 70, confidence: 0.9, angle: 10),
    ]);

    expect(quality.medianRotationDegrees, 14);
    expect(quality.severeWarnings, contains('ocr_rotation_severe'));
  });
}
