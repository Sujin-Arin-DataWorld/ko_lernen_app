import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **하향 전용 래칫(downward-only ratchet).**
///
/// `lib/services/**` 안에서 몸통이 비었거나 주석뿐인 `catch` 블록의 개수는
/// 이 값 밑으로만 움직여야 한다. 새 코드가 무음 catch 를 추가하면 이 숫자가
/// 올라가고, 이 테스트가 즉시 잡는다.
///
/// 2026-09-14, S1(무음 실패 래칫) PR 작업 시작 시점 기준선: 42개.
/// [DiagnosticsService.reportSwallowed] 로 전부 옮긴 뒤 0으로 낮췄다. 어떤
/// 자리를 의도적으로 비운 채 남겨야 한다면(예: 플랫폼 미지원을 조용히
/// 넘겨야 하는 자리), 그 catch 바로 옆에 이유를 남기고 이 숫자를 그만큼만
/// 올린다 — 이유 없이 올리지 않는다.
const int knownSilentCatchCap = 0;

/// `catch (...) { }` 또는 `catch (...) { // 주석만... }` — 실행 가능한 문장이
/// 하나도 없는 catch 몸통. 줄바꿈·들여쓰기·여러 줄 주석을 허용한다.
///
/// 각 주석 줄은 반드시 실제 개행(`\n`)으로 끝나야 매치된다 — `[^\n]*` 가 줄
/// 중간의 `}` 에서 조기 종료해 문서 주석 속 예시(``` `catch (_) {}` ```)를
/// 진짜 코드로 오인하는 걸 막는다.
final RegExp _emptyCatchBody = RegExp(
  r'catch\s*\([^)]*\)\s*\{(?:\s*//[^\n]*\n)*\s*\}',
);

void main() {
  test('lib/services 안 빈/주석뿐인 catch 개수는 래칫 상한을 넘지 않는다', () {
    final dir = Directory('lib/services');
    expect(dir.existsSync(), isTrue, reason: 'lib/services 디렉터리를 찾을 수 없다');

    final offenders = _findSilentCatches(dir);

    expect(
      offenders.length,
      lessThanOrEqualTo(knownSilentCatchCap),
      reason:
          '빈/주석뿐인 catch 가 ${offenders.length}개 남아 있다 (상한 '
          '$knownSilentCatchCap). 전부 DiagnosticsService.reportSwallowed 로 '
          '옮기거나, 의도적으로 남긴다면 이유를 comment 로 남기고 상한을 '
          '올린다:\n${offenders.join('\n')}',
    );
  });
}

List<String> _findSilentCatches(Directory dir) {
  final offenders = <String>[];
  final files =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final content = file.readAsStringSync();
    for (final match in _emptyCatchBody.allMatches(content)) {
      if (_matchStartsInsideLineComment(content, match.start)) {
        // 문서 주석이 예시로 `catch (_) {}` 를 인용하는 경우(오탐 방지) —
        // 실제 코드가 아니라 그 줄 자체가 `//` 로 시작하는 주석이다.
        continue;
      }
      final line = '\n'.allMatches(content.substring(0, match.start)).length + 1;
      offenders.add('${file.path}:$line');
    }
  }
  return offenders;
}

/// 매치가 시작하는 줄에서, 매치보다 앞쪽에 `//` 가 있으면 그 줄 자체가
/// 주석이다 — 실제 catch 문이 아니라 주석 속 예시 텍스트다.
bool _matchStartsInsideLineComment(String content, int matchStart) {
  final lineStart = content.lastIndexOf('\n', matchStart - 1) + 1;
  final prefix = content.substring(lineStart, matchStart);
  return prefix.contains('//');
}
