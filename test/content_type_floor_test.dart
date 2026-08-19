import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Jin 2026-08-19: "전체적으로 지금 글씨체가 작은건 너무작고 큰건 너무 크고,
/// 문장 가독성이 너무 안좋고".
///
/// `SoriTextTheme.meta` 의 문서가 이미 하한을 정해 뒀다 — **12.5 아래로
/// 내려가지 말 것**. 그런데 `soriFillSize(h, frac, min, max)` 로 계산되는
/// 폰트 크기 몇 곳이 min 12 로 그 아래를 허용하고 있었다. 카드가 짧은
/// 기기에서는 항상 하한이 걸리므로, 작은 폰에서 정확히 제일 안 보이는 글자가
/// 규칙 노트·뜻풀이였다.
///
/// 간격(gap)에 쓰는 `soriFillSize` 는 대상이 아니다 — 6~8 이 정상이다.
/// 그래서 하한을 함수 안에 박지 않고 **폰트로 쓰이는 자리**만 잠근다.
void main() {
  test('폰트로 쓰이는 soriFillSize 는 12.5 아래로 내려가지 않는다', () {
    final offenders = <String>[];
    final fontFill = RegExp(
      r'fontSize:\s*soriFillSize\(\s*[^,]+,\s*[0-9.]+,\s*([0-9.]+),',
    );

    for (final file in Directory('lib/screens').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = fontFill.firstMatch(lines[i]);
        if (match == null) {
          continue;
        }
        final min = double.parse(match.group(1)!);
        if (min < 12.5) {
          offenders.add('${file.path}:${i + 1} min=$min');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'SoriTextTheme.meta 가 정한 하한은 12.5 다. 짧은 카드에서는 항상 이 '
          '하한이 걸리므로 작은 폰에서 제일 안 읽히는 글자가 된다:\n'
          '${offenders.join('\n')}',
    );
  });
}
