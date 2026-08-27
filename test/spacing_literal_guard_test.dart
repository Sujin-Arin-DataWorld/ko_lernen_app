import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §16 간격 리듬 문법 래칫. [Spacing]/[SoriGaps] 그리드 값
/// {0,4,8,12,16,24,32,48} 밖의 숫자 리터럴이 EdgeInsets/SizedBox 간격
/// 호출에 새로 늘지 않는다.
///
/// 기준선: UIUX 바이블 2.0 진단(지시서 대응 마스터플랜) 인용치는 간격
/// 리터럴 134곳 중 그리드 밖 72곳이었다. 이 가드 자체(9개 패턴 × `lib/` 전체
/// 라인 스캔)로 2026-08-27 처음 돌려 실측한 값은 **181** — 산출 방식이 달라
/// 인용치와 어긋난다. typography_guard_test.dart와 동일한 "실측 기준선 →
/// 하향만" 관례에 따라 아래 ceiling은 이 181을 시작점으로 고정한다.
void main() {
  final grid = {0.0, 4.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0};
  final patterns = <RegExp>[
    RegExp(r'EdgeInsets\.all\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)'),
    RegExp(r'EdgeInsets\.symmetric\([^)]*horizontal:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.symmetric\([^)]*vertical:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*left:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*top:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*right:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*bottom:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'SizedBox\([^)]*width:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'SizedBox\([^)]*height:\s*([0-9]+(?:\.[0-9]+)?)'),
  ];

  test('그리드 밖(0/4/8/12/16/24/32/48 제외) 간격 리터럴은 더 늘지 않는다', () {
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//')) continue;
        for (final p in patterns) {
          for (final m in p.allMatches(line)) {
            final value = double.tryParse(m.group(1)!);
            if (value != null && !grid.contains(value)) {
              offenders.add('${f.path}:${i + 1}  ${line.trim()}');
            }
          }
        }
      }
    }
    // 2026-08-27 첫 실행 실측값 181로 고정(스펙 진단 인용치 72는 이 가드의
    // 실제 스캔 범위와 산출 방식이 달라 어긋났다 — 위 기준선 설명 참조).
    // 여기서부터는 하향만.
    const ceiling = 181;
    expect(
      offenders.length,
      lessThanOrEqualTo(ceiling),
      reason:
          '그리드 밖 간격 리터럴이 $ceiling 을 넘었다 (실제 ${offenders.length}). '
          '새 코드는 Spacing.*/SoriGaps.* 를 쓸 것.\n'
          '${offenders.take(20).join('\n')}',
    );
  });
}
