import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// de/en 번역 키 parity 래칫 — 현재 델타 0. 늘리지 말 것.
// (@ 로 시작하는 메타데이터 항목은 템플릿(DE) 전용이 정상이라 제외.)
void main() {
  test('app_de.arb ↔ app_en.arb 번역 키 델타 0', () {
    Set<String> keysOf(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>).keys
            .where((k) => !k.startsWith('@'))
            .toSet();

    final de = keysOf('lib/l10n/app_de.arb');
    final en = keysOf('lib/l10n/app_en.arb');
    final onlyDe = de.difference(en);
    final onlyEn = en.difference(de);
    expect(onlyDe, isEmpty, reason: 'DE 에만 있는 키 — EN 번역을 같이 추가할 것');
    expect(onlyEn, isEmpty, reason: 'EN 에만 있는 키 — DE 번역을 같이 추가할 것');
  });
}
