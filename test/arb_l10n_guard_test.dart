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
}
