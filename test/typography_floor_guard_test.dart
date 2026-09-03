import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **타이포 하한 가드** (§A6, 2026-09-03. §W-A2 6에서 정규식 확장).
///
/// `SoriTextTheme` 최저 토큰이 13(`caption`/`meta`/`cardSubtitle`)으로
/// 올라간 뒤에도 `fontSize:` 리터럴이 그 아래로 새로 생기지 않게 막는다.
/// `typography_guard_test.dart`의 래칫(실측 상한만 관리)과 달리 이 가드는
/// **절대 하한** — 허용목록 없이 13 미만이면 무조건 실패한다.
///
/// `[:=]`로 콜론(`fontSize: 12`) 뿐 아니라 등호(named-parameter 기본값,
/// `this.fontSize = 12,`)도 잡는다 — `SoriChip.fontSize` 기본값이 원래
/// 등호 문법이라 이 가드의 사각지대였다(§W-A2 발견).
void main() {
  test('lib/ 의 fontSize 리터럴은 13 아래로 내려가지 않는다', () {
    final offenders = <String>[];
    final pattern = RegExp(r'fontSize\s*[:=]\s*(\d+(?:\.\d+)?)');

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final match in pattern.allMatches(lines[i])) {
          final value = double.tryParse(match.group(1)!);
          if (value != null && value < 13) {
            offenders.add(
              '${file.path.replaceAll(r'\', '/')}:${i + 1}  fontSize: $value',
            );
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'lib/ 의 fontSize 리터럴은 13 미만이면 안 된다 (§A6 타이포 하한):\n'
          '${offenders.join('\n')}',
    );
  });
}
