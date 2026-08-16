import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/book_ocr_document.dart';
import 'package:ko_lernen_app/services/snap_ocr_service.dart';

void main() {
  BookOcrDocument documentFor(List<String> lines) =>
      BookOcrDocumentBuilder.build(
        lines.indexed.map(
          (entry) => BookOcrLine(
            text: entry.$2,
            bounds: Rect.fromLTWH(0, entry.$1 * 30, 300, 24),
            sourceLineId: 'line:${entry.$1}',
            blockIndex: entry.$1,
            lineIndex: 0,
            confidence: 0.9,
            recognizedLanguages: const <String>['ko', 'de', 'en'],
          ),
        ),
      );

  test('private challenge shapes use original synthetic fixture only', () {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/book_ocr_layout_contract.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final pages = fixture['pages'] as List<dynamic>;
    var truePositive = 0;
    var falsePositive = 0;
    var falseNegative = 0;
    var readingOrderMatches = 0;
    var readingOrderItems = 0;

    for (final rawPage in pages.cast<Map<String, dynamic>>()) {
      final lines = (rawPage['lines'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final ordered = SnapOcrService.arrangeBlocksForReading(
        lines.map((line) {
          final bounds = (line['bounds'] as List<dynamic>).cast<num>();
          final text = line['text']! as String;
          return OcrTextBlock(
            text: text,
            bounds: Rect.fromLTRB(
              bounds[0].toDouble(),
              bounds[1].toDouble(),
              bounds[2].toDouble(),
              bounds[3].toDouble(),
            ),
            script: RegExp(r'[가-힣]').hasMatch(text)
                ? OcrScript.korean
                : OcrScript.latin,
            confidence: 0.9,
            angle: 0,
            blockIndex: line['blockIndex']! as int,
            lineIndex: line['lineIndex']! as int,
          );
        }),
      );
      final expectedReadingOrder = (rawPage['expectedReadingOrder'] as List)
          .cast<String>();
      final actualReadingOrder = ordered.map((line) => line.text).toList();
      readingOrderItems += expectedReadingOrder.length;
      for (var index = 0; index < expectedReadingOrder.length; index++) {
        if (index < actualReadingOrder.length &&
            actualReadingOrder[index] == expectedReadingOrder[index]) {
          readingOrderMatches++;
        }
      }
      final document = BookOcrDocumentBuilder.build(
        ordered.map(
          (line) => BookOcrLine(
            text: line.text,
            bounds: line.bounds,
            sourceLineId: 'block:${line.blockIndex}:line:${line.lineIndex}',
            blockIndex: line.blockIndex,
            lineIndex: line.lineIndex,
            confidence: line.confidence,
          ),
        ),
      );
      final predicted = document.analysisUnits
          .map((unit) => unit.korean)
          .toSet();
      final expected = lines
          .expand((line) => (line['expected']! as List<dynamic>).cast<String>())
          .toSet();
      truePositive += predicted.intersection(expected).length;
      falsePositive += predicted.difference(expected).length;
      falseNegative += expected.difference(predicted).length;
    }

    final precision = truePositive / (truePositive + falsePositive);
    final recall = truePositive / (truePositive + falseNegative);
    expect(pages, hasLength(8));
    expect(precision, greaterThanOrEqualTo(0.98));
    expect(recall, greaterThanOrEqualTo(0.95));
    expect(readingOrderMatches / readingOrderItems, greaterThanOrEqualTo(0.95));
  });

  test('foreign gloss stays metadata and never enters analysis text', () {
    final document = documentFor(<String>[
      '학생 student',
      '대청소를 해요 do a big clean',
      '내일 morgen',
    ]);

    expect(document.analysisText, '학생\n대청소를 해요\n내일');
    expect(
      document.units
          .expand((unit) => unit.foreignHints)
          .map((hint) => hint.text),
      containsAll(<String>['student', 'do a big clean', 'morgen']),
    );
  });

  test('preserves Latin tokens that belong to a Korean clause', () {
    final document = documentFor(<String>[
      '저는 Berlin에 살아요.',
      'K-pop 음악을 들어요.',
      '서울에서 K-pop 공연을 봤어요.',
      'AI를 공부해요.',
    ]);

    expect(document.analysisText, contains('Berlin에'));
    expect(document.analysisText, contains('K-pop 음악을'));
    expect(document.analysisText, contains('서울에서 K-pop'));
    expect(document.analysisText, contains('AI를'));
  });

  test('foreign hyphenated compounds never masquerade as Korean loanwords', () {
    final document = documentFor(<String>[
      '한국어 Deutsch-Kurs',
      '12-Stunden-Systems -제 설명',
      '교통 U-Bahn',
      '연락 E-Mail',
      'K-pop 음악을 들어요.',
    ]);

    expect(document.analysisText, isNot(contains('Deutsch-Kurs')));
    expect(document.analysisText, isNot(contains('12-Stunden-Systems')));
    expect(document.analysisText, isNot(contains('U-Bahn')));
    expect(document.analysisText, isNot(contains('E-Mail')));
    expect(document.analysisText, contains('K-pop 음악을 들어요.'));
  });

  test('grammar labels and speaker labels are not analysis sentences', () {
    final document = documentFor(<String>[
      'Fragen mit -지 않아요? ist es nicht so?',
      'Die Struktur -아/어 보다 wird benutzt',
      '제니: 내일 뭐 할 거예요?',
    ]);

    expect(document.analysisText, '내일 뭐 할 거예요?');
    expect(
      document.units.where((unit) => unit.role == BookOcrUnitRole.grammarMeta),
      hasLength(2),
    );
    expect(
      document.units.where((unit) => unit.role == BookOcrUnitRole.speakerLabel),
      hasLength(1),
    );
  });

  test('lesson furniture and common textbook instructions stay out', () {
    final document = documentFor(<String>[
      '제8과',
      '제8과 시간과 약속',
      '어휘를 배웁시다.',
      '문장을 완성하세요.',
      '괄호 안의 말을 사용해서 문장을 완성하세요.',
      '오늘은 친구를 만나요.',
    ]);

    expect(document.analysisText, '오늘은 친구를 만나요.');
    expect(
      document.units.where((unit) => unit.role == BookOcrUnitRole.instruction),
      hasLength(3),
    );
    expect(
      document.units.where(
        (unit) => unit.role == BookOcrUnitRole.pageFurniture,
      ),
      hasLength(2),
    );
  });

  test('multiple Korean islands remain separate units', () {
    final document = documentFor(<String>[
      '잘됐어요 wird verwendet, 안됐어요 ist das Gegenteil',
    ]);

    expect(document.analysisUnits.map((unit) => unit.korean), <String>[
      '잘됐어요',
      '안됐어요',
    ]);
    expect(
      document.analysisUnits.map((unit) => unit.sourceLineIds.single).toSet(),
      <String>{'line:0'},
    );
  });

  test('same-region soft wraps restore one sentence and its provenance', () {
    final document = BookOcrDocumentBuilder.build(<BookOcrLine>[
      const BookOcrLine(
        text: '저는 내일 친구와',
        bounds: Rect.fromLTWH(20, 20, 260, 24),
        sourceLineId: 'block:7:line:0',
        blockIndex: 7,
        lineIndex: 0,
        confidence: 0.8,
      ),
      const BookOcrLine(
        text: '학교에 갈 거예요.',
        bounds: Rect.fromLTWH(20, 50, 260, 24),
        sourceLineId: 'block:7:line:1',
        blockIndex: 7,
        lineIndex: 1,
        confidence: 1,
      ),
    ]);

    expect(document.analysisUnits, hasLength(1));
    expect(document.analysisUnits.single.korean, '저는 내일 친구와 학교에 갈 거예요.');
    expect(document.analysisUnits.single.role, BookOcrUnitRole.sentence);
    expect(document.analysisUnits.single.sourceLineIds, <String>[
      'block:7:line:0',
      'block:7:line:1',
    ]);
    expect(document.analysisUnits.single.confidence, closeTo(0.9, 0.0001));
  });

  test('soft-wrap reflow never crosses a card or column gutter', () {
    final document = BookOcrDocumentBuilder.build(<BookOcrLine>[
      const BookOcrLine(
        text: '오늘은 친구를',
        bounds: Rect.fromLTWH(20, 20, 220, 24),
        sourceLineId: 'block:4:line:0',
        blockIndex: 4,
        lineIndex: 0,
      ),
      const BookOcrLine(
        text: '내일 만나요.',
        bounds: Rect.fromLTWH(340, 50, 220, 24),
        sourceLineId: 'block:4:line:1',
        blockIndex: 4,
        lineIndex: 1,
      ),
    ]);

    expect(document.analysisUnits, hasLength(2));
    expect(document.analysisText, isNot(contains('친구를 내일')));
  });

  test('OCR punctuation spacing never inserts a literal replacement token', () {
    final document = documentFor(<String>['안녕하세요 , 반가워요.']);

    expect(document.analysisText, '안녕하세요, 반가워요.');
    expect(document.analysisText, isNot(contains(r'$1')));
  });
}
