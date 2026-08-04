import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 타이포·아이콘 부채 **래칫**.
///
/// 2026-07-31 디자인 개편의 안전망. 각 상한은 그 시점의 실측값에서 출발해
/// **내려가기만 한다**. Phase가 끝날 때마다 새 실측값으로 낮춘다.
///
/// 왜 필요한가:
/// - Pretendard는 400~800만 번들돼 있어 `FontWeight.w900` 은 조용히 800으로
///   렌더된다. 강조가 안 먹히면서 요소만 같은 굵기 버킷에 쌓인다.
/// - 화면의 거의 모든 글자가 w700+ 이면 위계가 크기 하나에만 의존하게 된다.
/// - 라벨이 이미 뜻을 다 말하는 버튼의 아이콘은 장식이고, 화면을 시끄럽게 한다.
void main() {
  late List<_Source> sources;

  setUpAll(() {
    sources =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .map(
              (f) =>
                  _Source(f.path.replaceAll(r'\', '/'), f.readAsStringSync()),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(sources, isNotEmpty, reason: 'lib/ 에서 Dart 파일을 못 찾았다');
  });

  test('FontWeight.w900 은 더 늘지 않는다 (번들에 900 페이스가 없다)', () {
    // 기준선 2026-07-31: 46곳 / 28파일. 목표 0.
    // 2026-08-03 R1-e: 온보딩 레벨 배지 w900 1곳 제거 → 45 로 래칫 하향.
    _expectAtMost(sources, RegExp(r'FontWeight\.w900'), 40, 'FontWeight.w900');
  });

  test('FontWeight.w800 은 더 늘지 않는다', () {
    // 기준선 2026-07-31: 189곳 / 65파일. 목표 ~20.
    //
    // 2026-08-03 R1-e(디자인 계획 §4.3·§12): `onboarding_level_screen.dart` 의
    // raw TextStyle 17개를 `SoriTextTheme` 프리셋으로 교체(실측 188) —
    // 08-01 임시 상향(193)을 **189 로 복원**. §4.3 "카드 제목 w800 금지"에 따라
    // 카드·행 제목 2곳은 h3(w700) 로 강등했다.
    _expectAtMost(sources, RegExp(r'FontWeight\.w800'), 180, 'FontWeight.w800');
  });

  test("하드코딩 'Pretendard' 리터럴은 더 늘지 않는다 (SoriFonts.sans 사용)", () {
    // 기준선 2026-07-31: 119곳 / 30파일. 목표 0.
    // ⚠️ 이 패턴은 **문자열 리터럴 안에** 산다. clean 소스에서는 리터럴이
    // 공백으로 지워져 있어 절대 매치되지 않는다(= 조용히 통과하는 가짜 가드).
    // 반드시 raw 를 봐야 한다.
    _expectAtMost(
      sources,
      RegExp("fontFamily: 'Pretendard'"),
      119,
      "fontFamily: 'Pretendard'",
      useRaw: true,
    );
  });

  test('아이콘 달린 SoriButton 은 더 늘지 않는다', () {
    // 기준선 2026-07-31: 114 span 중 74곳.
    // (114 = 실제 콜사이트 110 + button.dart 안의 생성자 선언 4)
    // 목표 ~14 — 미디어 컨트롤·플랫폼 마크·아이콘 단독 버튼만 남긴다.
    var total = 0;
    final perFile = <String, int>{};
    for (final s in sources) {
      for (final span in _callSpans(s.clean, 'SoriButton')) {
        final body = s.clean.substring(span.start, span.end);
        if (RegExp(r'\bicon\s*:').hasMatch(body)) {
          total++;
          perFile[s.path] = (perFile[s.path] ?? 0) + 1;
        }
      }
    }
    expect(
      total,
      lessThanOrEqualTo(74),
      reason: '아이콘 달린 SoriButton 이 74개를 넘었다 (실제 $total).\n${_report(perFile)}',
    );
  });
}

/// 원본과 인덱스가 1:1 대응하는, 문자열·주석이 공백으로 지워진 사본을 함께 든다.
class _Source {
  _Source(this.path, this.raw) : clean = _blankStringsAndComments(raw);

  final String path;

  /// 파일 원본. 문자열 리터럴 **안에** 사는 패턴은 반드시 이걸 봐야 한다.
  final String raw;

  /// 문자열·주석이 공백으로 지워진 사본. 코드 토큰 검색과 괄호 짝맞춤용.
  final String clean;
}

/// 괄호 짝이 맞는 호출 범위.
class _Span {
  const _Span(this.start, this.end);

  final int start;
  final int end;
}

void _expectAtMost(
  List<_Source> sources,
  RegExp pattern,
  int ceiling,
  String label, {
  bool useRaw = false,
}) {
  var total = 0;
  final perFile = <String, int>{};
  for (final s in sources) {
    final n = pattern.allMatches(useRaw ? s.raw : s.clean).length;
    if (n > 0) {
      total += n;
      perFile[s.path] = n;
    }
  }
  expect(
    total,
    lessThanOrEqualTo(ceiling),
    reason: '$label 이 상한 $ceiling 을 넘었다 (실제 $total).\n${_report(perFile)}',
  );
}

String _report(Map<String, int> perFile) {
  final entries = perFile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(15).map((e) => '  ${e.value}  ${e.key}').join('\n');
}

/// 문자열 리터럴과 주석을 같은 길이의 공백으로 치환한다.
///
/// 인덱스가 보존되므로 원본 위치와 1:1 대응한다. 이게 없으면 문자열 안의
/// 괄호나 주석에 적힌 예제 코드가 괄호 짝맞춤과 카운트를 망친다.
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
    } else if (c == '/' && i + 1 < n && src[i + 1] == '*') {
      var j = src.indexOf('*/', i + 2);
      j = j < 0 ? n : j + 2;
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

/// `ident(...)` / `ident.named(...)` 의 괄호 짝이 맞는 범위들.
///
/// [clean] 은 반드시 [_blankStringsAndComments] 를 통과한 소스여야 한다.
List<_Span> _callSpans(String clean, String ident) {
  final spans = <_Span>[];
  for (final m in RegExp('\\b${RegExp.escape(ident)}\\b').allMatches(clean)) {
    var p = m.end;
    while (p < clean.length && ' \n\t'.contains(clean[p])) {
      p++;
    }
    // `.filled` / `.outlined` 같은 named constructor 를 건너뛴다.
    while (p < clean.length &&
        (clean[p] == '.' || clean[p] == '_' || _isAlnum(clean[p]))) {
      p++;
      while (p < clean.length && ' \n\t'.contains(clean[p])) {
        p++;
      }
    }
    if (p >= clean.length || clean[p] != '(') continue;
    var depth = 0;
    for (var q = p; q < clean.length; q++) {
      if (clean[q] == '(') {
        depth++;
      } else if (clean[q] == ')') {
        depth--;
        if (depth == 0) {
          spans.add(_Span(m.start, q + 1));
          break;
        }
      }
    }
  }
  return spans;
}

bool _isAlnum(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
}
