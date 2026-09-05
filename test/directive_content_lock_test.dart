// 지시서 문구 잠금 가드 — 2.1 · 2.7 · 2.10 · 1.5 · 1.9.
//
// 이전 세션들에서 이미 확정된 콘텐츠 교정·명명 결정이 이후 배치 작업이나
// 재생성 스크립트로 조용히 되돌아가지 않도록, 정확한 문자열을 코드에 못
// 박아 둔다. 실패하면 "고의로 되돌린 것"인지 "회귀"인지부터 확인할 것 —
// 의도된 재교정이라면 이 테스트의 리터럴을 새 값으로 갱신해야 한다.
//
// CSV 로딩은 test/cloze_content_guard_test.dart 의 parseCsv 를 그대로
// 복제했다(따옴표 내 콤마/줄바꿈 처리).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';

List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var field = StringBuffer(), row = <String>[], inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n') {
      row.add(field.toString().replaceAll('\r', ''));
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

void main() {
  final clozeText = File('assets/data/cloze.json').readAsStringSync();
  final clozeRaw = jsonDecode(clozeText) as Map<String, dynamic>;
  final clozeItems = (clozeRaw['items'] as List).cast<Map<String, dynamic>>();
  final clozeById = {for (final it in clozeItems) it['id'] as String: it};

  final satzText = File('assets/data/satz_sentences.json').readAsStringSync();
  final satzRaw = jsonDecode(satzText) as Map<String, dynamic>;
  final satzItems = (satzRaw['items'] as List).cast<Map<String, dynamic>>();
  final satzById = {for (final it in satzItems) it['id'] as String: it};

  final vocabCsvText = File(
    'assets/data/korean_vocab.csv',
  ).readAsStringSync();
  final vocabRows = parseCsv(vocabCsvText);
  final vocabHeader = vocabRows.first;
  final iId = vocabHeader.indexOf('id');
  final iKorean = vocabHeader.indexOf('korean');
  final iExampleKorean = vocabHeader.indexOf('example_korean');
  final vocabById = {
    for (final r in vocabRows.skip(1))
      if (r.length > iId && r[iId].isNotEmpty) r[iId]: r,
  };

  group('층간소음 — "조심해야 돼요" 결말 고정 (2.7)', () {
    test('cloze_a1_0239 fullKo', () {
      expect(
        clozeById['cloze_a1_0239']!['fullKo'],
        '밤에는 층간소음이 나지 않게 조심해야 돼요.',
      );
    });

    test('vocab_a1_0351 example_korean', () {
      expect(
        vocabById['vocab_a1_0351']![iExampleKorean],
        '밤에는 층간소음이 나지 않게 조심해야 돼요.',
      );
    });

    test('satz_a1_0203 targetKo', () {
      expect(
        satzById['satz_a1_0203']!['targetKo'],
        '밤에는 층간소음이 나지 않게 조심해야 돼요.',
      );
    });
  });

  test('cloze_a1_0104 fullKo — 시아버지 인사 문장 (2.1)', () {
    expect(
      clozeById['cloze_a1_0104']!['fullKo'],
      '남편 집에 가니까 시아버지께서 환하게 반겨주셨어요.',
    );
  });

  group('"일정 충돌" → "의견 충돌" 교체 고정 (2.10)', () {
    test('cloze_b1_0172 answer', () {
      expect(clozeById['cloze_b1_0172']!['answer'], '의견 충돌');
    });

    test('vocab_b1_0360 korean', () {
      expect(vocabById['vocab_b1_0360']![iKorean], '의견 충돌');
    });

    test('satz_b1_0168 vocabKo', () {
      expect(satzById['satz_b1_0168']!['vocabKo'], '의견 충돌');
    });

    test('"일정 충돌"은 세 파일 어디에도 남아있지 않다', () {
      expect(clozeText, isNot(contains('일정 충돌')));
      expect(vocabCsvText, isNot(contains('일정 충돌')));
      expect(satzText, isNot(contains('일정 충돌')));
    });
  });

  group('cloze_a1_0154 — 절하는 타이밍 문장 정정 고정 (2.8, T1)', () {
    const fixed = '절하는 타이밍이 한 박자 늦었어요.';

    test('cloze_a1_0154 fullKo', () {
      expect(clozeById['cloze_a1_0154']!['fullKo'], fixed);
    });

    test('vocab_a1_0266 example_korean', () {
      expect(vocabById['vocab_a1_0266']![iExampleKorean], fixed);
    });

    test('satz_a1_0118 targetKo', () {
      expect(satzById['satz_a1_0118']!['targetKo'], fixed);
    });
  });

  group('학습 허브 타이틀 명명 고정 (1.5, 1.9)', () {
    test('복습 허브(srs) de 제목 == "Wiederholen"', () {
      final srs = soriActivityCatalog.firstWhere((e) => e.id == 'srs');
      expect(srs.title.de, 'Wiederholen');
    });

    test('어휘망(word_web) de 제목 == 현재 값', () {
      final wordWeb = soriActivityCatalog.firstWhere(
        (e) => e.id == 'word_web',
      );
      expect(wordWeb.title.de, 'Nuancen & Gegenteile');
    });

    test('어느 학습 활동 de/en 제목에도 "SRS"·"Wortnetz"가 없다', () {
      for (final entry in soriActivityCatalog) {
        expect(
          entry.title.de,
          isNot(contains('SRS')),
          reason: '${entry.id}.title.de',
        );
        expect(
          entry.title.de,
          isNot(contains('Wortnetz')),
          reason: '${entry.id}.title.de',
        );
        expect(
          entry.title.en,
          isNot(contains('SRS')),
          reason: '${entry.id}.title.en',
        );
        expect(
          entry.title.en,
          isNot(contains('Wortnetz')),
          reason: '${entry.id}.title.en',
        );
      }
    });
  });
}
