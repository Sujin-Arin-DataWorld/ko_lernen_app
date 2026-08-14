import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 창 크기 분기 **래칫** — "앱 전체가 같은 기준을 쓴다"를 코드로 강제한다.
///
/// 화면마다 제각각 임계값을 두면 같은 태블릿에서 어떤 화면은 레일, 어떤 화면은
/// 탭이 되고, 나중에 기준을 바꿀 때 놓치는 곳이 생긴다. 두 가지를 막는다:
///
/// 1. **플랫폼으로 레이아웃을 가르지 않는다** — Android 에도 태블릿·폴더블이,
///    iOS 에도 iPad 가 있다. `Platform.isAndroid` 는 시스템 관례(권한·공유·결제)
///    에만 쓰고 레이아웃 레이어(`lib/screens`, `lib/widgets`)에는 두지 않는다.
/// 2. **숫자 리터럴 직접 비교를 늘리지 않는다** — 폭 비교는
///    `windowClassFor` 또는 `SoriBreakpoints` 상수를 거친다.
///
/// 각 상한은 실측값에서 출발해 **내려가기만 한다**. 올리려면 그 자리가 왜
/// 예외인지 주석으로 남길 것.
void main() {
  late List<_Source> sources;
  late List<_Source> layoutSources;

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

    layoutSources = sources
        .where(
          (s) =>
              s.path.startsWith('lib/screens/') ||
              s.path.startsWith('lib/widgets/'),
        )
        .toList();
    expect(layoutSources, isNotEmpty, reason: '레이아웃 소스를 못 찾았다');
  });

  test('레이아웃 레이어는 Platform.isAndroid/isIOS 로 분기하지 않는다', () {
    // 기준선 2026-08-06: 0곳. 목표 0 유지.
    //
    // 서비스 레이어(lib/services/)는 제외한다 — 거기서는 파일 저장 경로나
    // 권한 API 처럼 **실제로 OS 마다 다른 동작**을 고르는 게 맞다.
    // 예: lib/services/word_image_service.dart 의 Android scoped-storage 분기.
    _expectAtMost(
      layoutSources,
      RegExp(r'Platform\.is(Android|IOS|MacOS|Windows|Linux|Fuchsia)\b'),
      0,
      'lib/screens·lib/widgets 의 Platform.is*',
    );
  });

  test('폭 비교에 숫자 리터럴을 직접 쓰지 않는다', () {
    // 기준선 2026-08-06: 1곳 (sarangbang `>= 640`) — 2026-08-14 §D 수습에서
    // SoriBreakpoints.tabletContent 상수로 이관 완료.
    //
    // 남은 1곳: lib/widgets/sori/responsive.dart `soriUniformFitSize` 의
    //   `maxWidth <= 0` — 브레이크포인트가 아니라 **유효성(비양수 폭) 가드**다.
    //   이 정규식이 구분 못 하는 정당한 예외라 상한 1 을 점유한다. 새 폭 비교는
    //   windowClassFor(width) 또는 SoriBreakpoints.* 를 쓴다.
    _expectAtMost(
      sources,
      RegExp(
        r'(MediaQuery\.(of\(\w+\)\.size|sizeOf\(\w+\))\.width|'
        r'\b\w*[Cc]onstraints\.maxWidth|\bmaxWidth)\s*[<>]=?\s*[0-9]',
      ),
      1,
      '숫자 리터럴 폭 비교',
    );
  });

  test('창 분류의 임계값은 window_class.dart 한 곳에만 산다', () {
    // 840(= expanded 시작점)이 다른 파일에 복제되면 기준이 갈라진다.
    final offenders = <String, int>{};
    for (final s in sources) {
      if (s.path.endsWith('lib/widgets/sori/window_class.dart')) {
        continue;
      }
      final n = RegExp(r'[<>]=?\s*840\b').allMatches(s.clean).length;
      if (n > 0) {
        offenders[s.path] = n;
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          '840dp 임계값이 window_class.dart 밖에 복제됐다.\n'
          'windowClassFor(width) 를 쓸 것.\n${_report(offenders)}',
    );
  });

  test('창 분류 API 는 실제로 쓰이고 있다 (죽은 추상화 방지)', () {
    // 분류를 만들어 두고 아무도 안 쓰면 "통일"이 아니라 파일 하나가 늘 뿐이다.
    final users = sources
        .where(
          (s) =>
              !s.path.endsWith('lib/widgets/sori/window_class.dart') &&
              RegExp(
                r'\b(windowClassFor|appWindowClassOf|AppWindowClass|AppContentFrame|SoriMaxWidth)\b',
              ).hasMatch(s.clean),
        )
        .map((s) => s.path)
        .toList();
    expect(users, isNotEmpty, reason: 'window_class.dart 를 쓰는 곳이 없다 — 배선이 빠졌다');
  });
}

/// 원본과 인덱스가 1:1 대응하는, 문자열·주석이 공백으로 지워진 사본을 함께 든다.
class _Source {
  _Source(this.path, this.raw) : clean = _blankStringsAndComments(raw);

  final String path;

  /// 파일 원본. 문자열 리터럴 **안에** 사는 패턴은 반드시 이걸 봐야 한다.
  final String raw;

  /// 문자열·주석이 공백으로 지워진 사본. 코드 토큰 검색용.
  final String clean;
}

void _expectAtMost(
  List<_Source> sources,
  RegExp pattern,
  int ceiling,
  String label,
) {
  var total = 0;
  final perFile = <String, int>{};
  for (final s in sources) {
    final n = pattern.allMatches(s.clean).length;
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
/// 인덱스가 보존되므로 원본 위치와 1:1 대응한다. 이게 없으면 주석에 적힌 예제
/// 코드(예: window_class.dart 의 `Platform.isAndroid` 설명)가 카운트를 망친다.
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
