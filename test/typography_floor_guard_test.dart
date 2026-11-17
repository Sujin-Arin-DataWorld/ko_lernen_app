import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **타이포 하한 가드** (§A6, 2026-09-03. §W-A2 6에서 정규식 확장).
///
/// `SoriTextTheme` 최저 토큰이 13(`caption`/`meta`/`cardSubtitle`)으로
/// 올라간 뒤에도 `fontSize:` 리터럴이 그 아래로 새로 생기지 않게 막는다.
/// `typography_guard_test.dart`의 래칫(실측 상한만 관리)과 달리 이 가드는
/// **절대 하한** — 승인된 원본의 두 잠긴 아트 토큰을 제외하고 13 미만은 실패한다.
/// 예외는 파일 전체가 아니라 정확한 멤버/값에만 적용한다. 일반 본문이나
/// 접근성 flowing layout에는 이 크기를 재사용하지 않는다.
///
/// `[:=]`로 콜론(`fontSize: 12`) 뿐 아니라 등호(named-parameter 기본값,
/// `this.fontSize = 12,`)도 잡는다 — `SoriChip.fontSize` 기본값이 원래
/// 등호 문법이라 이 가드의 사각지대였다(§W-A2 발견).
void main() {
  test('lib/ 의 fontSize 리터럴은 13 아래로 내려가지 않는다', () {
    final offenders = <String>[];
    final reviewed = <String, int>{};
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
            final path = file.path.replaceAll(r'\', '/');
            final member = _reviewedReferenceMember(path, lines, i, value);
            if (member != null) {
              reviewed.update(member, (count) => count + 1, ifAbsent: () => 1);
              continue;
            }
            offenders.add('$path:${i + 1}  fontSize: $value');
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
    expect(reviewed, {'gyeBody': 1, 'welcomeBrand': 1});
  });

  test('reference exception cannot cover another member, file or size', () {
    const path = 'lib/widgets/sori/intro_tokens.dart';
    final lines = [
      'static TextStyle gyeBody(double s) => TextStyle(',
      'fontSize: 12.5 * s,',
    ];
    expect(_reviewedReferenceMember(path, lines, 1, 12.5), 'gyeBody');
    expect(_reviewedReferenceMember('lib/other.dart', lines, 1, 12.5), isNull);
    expect(_reviewedReferenceMember(path, lines, 1, 12), isNull);
    expect(
      _reviewedReferenceMember(
        path,
        ['static TextStyle body(double s) => TextStyle(', lines[1]],
        1,
        12.5,
      ),
      isNull,
    );
  });
}

String? _reviewedReferenceMember(
  String path,
  List<String> lines,
  int index,
  double value,
) {
  if (path != 'lib/widgets/sori/intro_tokens.dart') {
    return null;
  }
  // Figma 77:2 / 85:32 reference-only Gye caption and brand lockup, approved
  // 2026-10-18. The source guard still detects every other sub-13 literal.
  const approved = {'gyeBody': 12.5, 'welcomeBrand': 12.0};
  for (var i = index; i >= 0; i--) {
    final match = RegExp(r'^\s*static TextStyle (\w+)\(').firstMatch(lines[i]);
    if (match != null) {
      final name = match.group(1)!;
      return approved[name] == value ? name : null;
    }
    if (lines[i].trim() == ');') {
      break;
    }
  }
  return null;
}
