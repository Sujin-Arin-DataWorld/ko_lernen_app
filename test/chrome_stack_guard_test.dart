import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §17/§18 — 본문 전 Wrap+칩 중복 적층 금지 + InkWell 리플 금지 래칫.
///
/// [Wrap]이 [Chip]/[SoriChip]을 직접 감싸는 "칩 줄" 패턴이 화면 하나에
/// 여러 겹 쌓이면(2.3 Anlaut-Quiz: 레벨Wrap+모드Wrap+통계Wrap) 크롬이 본문을
/// 밀어낸다. 새 화면은 `SoriChromeRow`/`SoriLevelFilterBar` 단일 행으로
/// 대체한다.
void main() {
  // 2026-08-27 실측: chosung_quiz_screen.dart 는 Wrap+칩 블록이 이미
  // 여럿(레벨/모드/통계 등 4개) — §19 이행 전까지 그랜드파더. 같은 실측에서
  // hangul_screen(디테일 칩 2)·legacy_vocab_screen(SRS 배지+통계 2)·
  // scenario_player_screen(단어 유의어/변형 칩 2)도 기존부터 2블록씩이라
  // 함께 고정한다. **새 다중 위반 화면을 이 목록에 추가하지 않는다** — 이
  // 넷은 이 가드가 생기기 전부터 있던 부채이지 새로 늘린 게 아니다.
  //
  // 2026-08-27 W3↔main 병합 그랜드파더: study_library_screen.dart(실측
  // 3개 — 뷰 선택 Wrap, 저장 유형 필터 Wrap, 항목별 상태 배지 Wrap)는
  // main의 온보딩-미디어 웨이브가 이 가드가 생기기 전에(이 가드는 W3에서만
  // 존재) 작성한 화면이라, 그 브랜치 관점에서는 위 넷과 동일하게 규칙이
  // 없던 시점의 부채다. 컨트롤러 재정(§19 W5 이행 목록 항목 6 참고):
  // 병합 중 리팩터하지 않고 W5 §19 이행 목록에 편입(백로그 4→5).
  const chipWrapAllowlist = <String, int>{
    'lib/screens/chosung_quiz_screen.dart': 4,
    'lib/screens/hangul_screen.dart': 2,
    'lib/screens/legacy_vocab_screen.dart': 2,
    'lib/screens/scenario_player_screen.dart': 2,
    'lib/screens/study_library_screen.dart': 3,
  };

  List<_Span> chipWrapSpans(String clean) {
    final spans = <_Span>[];
    for (final m in RegExp(r'(^|[^A-Za-z0-9_$])Wrap\(').allMatches(clean)) {
      final start = m.end - 5; // 'Wrap(' 시작
      var depth = 0;
      for (var q = start; q < clean.length; q++) {
        if (clean[q] == '(') {
          depth++;
        } else if (clean[q] == ')') {
          depth--;
          if (depth == 0) {
            final body = clean.substring(start, q + 1);
            if (body.contains('Chip(')) {
              spans.add(_Span(start, q + 1));
            }
            break;
          }
        }
      }
    }
    return spans;
  }

  test('화면당 Wrap(...Chip...) 블록은 1개를 넘지 않는다(그랜드파더 제외)', () {
    final offenders = <String>[];
    for (final f
        in Directory('lib/screens')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final path = f.path.replaceAll('\\', '/');
      final rel = 'lib/screens/${path.split('lib/screens/').last}';
      final clean = _blankStringsAndComments(f.readAsStringSync());
      final count = chipWrapSpans(clean).length;
      final allowed = chipWrapAllowlist[rel] ?? 1;
      if (count > allowed) {
        offenders.add('$rel: $count 개 (허용 $allowed)');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          '화면에 Wrap+칩 블록이 중복 적층됐다 — SoriChromeRow/'
          'SoriLevelFilterBar 단일 행으로 대체할 것.\n${offenders.join('\n')}',
    );
  });

  test('raw InkWell( 은 더 늘지 않는다 (SoriPressable 사용)', () {
    var total = 0;
    final perFile = <String, int>{};
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final n = RegExp(
        r'(^|[^A-Za-z0-9_$])InkWell\(',
      ).allMatches(_blankStringsAndComments(f.readAsStringSync())).length;
      if (n > 0) {
        total += n;
        perFile[f.path] = n;
      }
    }
    // 기준선 2026-08-27: 19곳. 하향만.
    expect(
      total,
      lessThanOrEqualTo(19),
      reason: 'raw InkWell( 이 19를 넘었다 (실제 $total).',
    );
  });
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;
}

String _blankStringsAndComments(String src) {
  final out = src.split('');
  final n = src.length;
  var i = 0;
  while (i < n) {
    final c = src[i];
    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      var j = src.indexOf('\n', i);
      if (j < 0) j = n;
      for (var k = i; k < j; k++) {
        out[k] = ' ';
      }
      i = j;
    } else if (c == "'" || c == '"') {
      final quote = c;
      var j = i + 1;
      while (j < n) {
        if (src[j] == r'\') {
          j += 2;
          continue;
        }
        if (src[j] == quote) {
          j++;
          break;
        }
        if (src[j] == '\n') break;
        j++;
      }
      final end = j < n ? j : n;
      for (var k = i; k < end; k++) {
        out[k] = ' ';
      }
      i = j;
    } else {
      i++;
    }
  }
  return out.join();
}
