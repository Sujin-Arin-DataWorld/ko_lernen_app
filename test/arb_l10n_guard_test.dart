import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ARB 문구 부채 **래칫** (디자인 계획 §7.1·§7.4, R5 신설).
///
/// ⓐ 카운트 복수형 미처리: `{n} Tage|Wörter|Pakete|…` 원형은 n=1에서
///    "1 Tage" 병을 만든다 — ICU plural(`{n, plural, one{…} other{…}}`)이 정본.
///    x/y 분수 표기(`{cleared}/{total} Pakete`)는 예외.
/// ⓑ DE/EN 키 대칭: 한쪽에만 있는 키는 곧 미번역 화면이다.
///
/// 2026-08-04 기준선: 미처리 0 / 비대칭 0 — 이 상한은 올리지 않는다.
void main() {
  late Map<String, dynamic> de;
  late Map<String, dynamic> en;

  setUpAll(() {
    de =
        json.decode(File('lib/l10n/app_de.arb').readAsStringSync())
            as Map<String, dynamic>;
    en =
        json.decode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
  });

  List<String> unpluralized(Map<String, dynamic> arb) {
    final pattern = RegExp(
      r'\{[a-zA-Z]+\}\s*'
      r'(Tage\b|Tag\b|Wörter\b|Wort\b|Pakete\b|Paket\b|Packs\b'
      r'|days\b|words\b|packs\b)',
    );
    final hits = <String>[];
    for (final entry in arb.entries) {
      final value = entry.value;
      if (entry.key.startsWith('@') || value is! String) continue;
      // plural 을 이미 쓰는 값과 x/y 분수 표기는 준수로 본다.
      if (value.contains(', plural,') || value.contains('}/{')) continue;
      if (pattern.hasMatch(value)) hits.add(entry.key);
    }
    return hits..sort();
  }

  test('카운트 복수형 미처리 키는 0을 유지한다 (DE)', () {
    final hits = unpluralized(de);
    expect(hits, isEmpty, reason: 'ICU plural 로 바꿀 것: $hits (§7.1 처방 참조)');
  });

  test('카운트 복수형 미처리 키는 0을 유지한다 (EN)', () {
    final hits = unpluralized(en);
    expect(hits, isEmpty, reason: 'ICU plural 로 바꿀 것: $hits (§7.1 처방 참조)');
  });

  test('DE/EN 키는 완전 대칭이다', () {
    final deKeys = de.keys.where((k) => !k.startsWith('@')).toSet();
    final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
    expect(deKeys.difference(enKeys), isEmpty, reason: 'DE 에만 있는 키 — EN 번역 누락');
    expect(enKeys.difference(deKeys), isEmpty, reason: 'EN 에만 있는 키 — DE 번역 누락');
  });

  test('금지 상표·구 명칭이 값에 남아 있지 않다 (Q5·Q6)', () {
    final offenders = <String>[];
    for (final arb in [de, en]) {
      for (final entry in arb.entries) {
        final value = entry.value;
        if (entry.key.startsWith('@') || value is! String) continue;
        if (value.contains('Starbucks') || value.contains('Wordle')) {
          offenders.add(entry.key);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Q5(Silben-Rätsel)·Q6(Café) 결정 위반: $offenders',
    );
  });

  test('사용자 노출 문구는 편집용 em/en dash를 쓰지 않는다', () {
    final dash = RegExp('[\u2013\u2014]');
    final offenders = <String>[];
    for (final arb in [de, en]) {
      for (final entry in arb.entries) {
        final value = entry.value;
        if (entry.key.startsWith('@') || value is! String) continue;
        if (dash.hasMatch(value)) offenders.add(entry.key);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '문장을 마침표·쉼표 등으로 자연스럽게 다시 써야 함: $offenders',
    );
  });

  // ── 학습 데이터 에셋 (Jin 2026-08-13) ──────────────────────────────────
  //
  // ARB 만 막아서는 부족했다. 화면에 실제로 보이던 em dash 292 개 중 274 개가
  // `scenarios.json` 에 있었고 ARB 가드는 거길 보지 않는다. 사용자에게 보이는
  // DE/EN 값은 여기서 함께 막는다. 한국어(`ko`) 값과 `_comment`·`meta.*` 같은
  // 내부 메모는 대상이 아니다.

  const userFacingKeys = {
    'de',
    'en',
    'promptDe',
    'promptEn',
    'explanationDe',
    'explanationEn',
    'explanation_de',
    'explanation_en',
  };

  void collectDashes(
    Object? node,
    String path,
    List<String> into,
    RegExp dash,
  ) {
    if (node is Map) {
      node.forEach((key, value) {
        final name = key.toString();
        if (userFacingKeys.contains(name) &&
            value is String &&
            dash.hasMatch(value)) {
          into.add('$path.$name');
        } else {
          collectDashes(value, '$path.$name', into, dash);
        }
      });
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        collectDashes(node[i], '$path[$i]', into, dash);
      }
    }
  }

  test('학습 데이터의 DE/EN 값에도 em/en dash 가 없다', () {
    final dash = RegExp('[–—]');
    final offenders = <String>[];

    for (final file in Directory('assets/data').listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final decoded = json.decode(file.readAsStringSync());
      collectDashes(decoded, file.uri.pathSegments.last, offenders, dash);
    }

    expect(
      offenders,
      isEmpty,
      reason: '사용자에게 보이는 독일어·영어 문장이다. 마침표·쉼표·콜론으로 다시 쓸 것: $offenders',
    );
  });

  test('grammar.csv 의 독일어·영어 열에도 em/en dash 가 없다', () {
    final dash = RegExp('[–—]');
    final lines = File('assets/data/grammar.csv').readAsLinesSync();
    final offenders = <String>[];

    for (var i = 1; i < lines.length; i++) {
      if (dash.hasMatch(lines[i])) {
        offenders.add('grammar.csv:${i + 1}');
      }
    }

    expect(offenders, isEmpty, reason: '학습 예문에 편집용 대시가 남아 있다: $offenders');
  });

  // 2026-08-13 실제 사고: `— ` 를 `, ` 로 바꾸다가 **따옴표 없는 셀에 쉼표**를
  // 넣었다. 열이 하나 밀리면서 마지막 `id` 컬럼이 깨졌고, 커리큘럼 카탈로그의
  // grammar ID 검증이 실패해 클라우드 백업에서 `course_mastery_json` 이 통째로
  // 빠졌다. 대시를 지운 흔적은 어디에도 없어서 눈으로는 안 보였다.
  test('grammar.csv 의 모든 행은 헤더와 같은 열 수를 가진다', () {
    final raw = File('assets/data/grammar.csv').readAsStringSync();
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;

    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < raw.length && raw[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (ch == '\n') {
        row.add(field.toString());
        field = StringBuffer();
        rows.add(row);
        row = <String>[];
      } else if (ch != '\r') {
        field.write(ch);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }

    final expected = rows.first.length;
    final ragged = <String>[];
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].length != expected) {
        ragged.add('line ${i + 1}: ${rows[i].length} != $expected');
      }
    }

    expect(
      ragged,
      isEmpty,
      reason:
          '열이 밀렸다. 셀 안에 쉼표를 넣으려면 셀 전체를 따옴표로 감싸야 한다: $ragged',
    );
  });
}
