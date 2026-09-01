import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 주석(`//` 이후)을 지운다 — 주석 처리된 호출이 시작작업 가드를 통과시키면
/// 안 된다(정규식은 죽은 코드와 산 코드를 구분하지 못한다).
String stripLineComments(String source) => source
    .split('\n')
    .map((line) {
      final at = line.indexOf('//');
      return at < 0 ? line : line.substring(0, at);
    })
    .join('\n');

// 계약: 축하 버스트 시트는 **첫 프레임 전에** 디코딩이 끝나야 한다. 새 설치
// 직후 첫 정답도 Satz 전용 6배 시트를 쓰게 하려는 것이고, 안 그러면 첫 번째
// 축하만 절차적 폴백으로 떨어진다.
//
// 2026-08-12 통합 시 갱신: origin/main 이 UX 프리뷰 갤러리를 위해 runApp 을
// 주입 가능한 `runner` 로 바꾸면서 옛 리터럴 `runApp(const KoLernenApp());`
// 가 사라졌다. 호출 **형태**를 문자열로 고정하면 이렇게 리팩터마다 깨지므로,
// 실앱을 띄우는 지점을 형태와 무관하게 찾아 순서만 검증한다.
void main() {
  test(
    'burst sheets finish preloading before the first app frame '
    '(runner 이전 await 존재 계약 — 병렬화 리팩터에 안전)',
    () {
      final source = File('lib/main.dart').readAsStringSync();

      final launch = RegExp(
        r'(runApp|runner)\(\s*const\s+KoLernenApp\(\)\s*\)',
      ).firstMatch(source);
      expect(
        launch,
        isNotNull,
        reason: 'lib/main.dart 에서 KoLernenApp 을 띄우는 지점을 찾지 못했다.',
      );
      // 주석 처리된 호출이 "있다/await 된다"로 잡히면 가드가 죽은 코드를
      // 통과시킨다 — 검사 전에 `//` 이후를 지운 사본을 본다.
      final beforeLaunch = stripLineComments(
        source.substring(0, launch!.start),
      );

      const call = 'DancheongBurst.preload()';
      expect(
        beforeLaunch.contains(call),
        isTrue,
        reason:
            '$call 호출이 실앱 실행(runApp/runner) 이전에 있어야 한다. '
            '없으면 첫 축하가 절차적 폴백으로 떨어진다.',
      );

      final awaited = RegExp(
        r'await\s+(?:Future\.wait(?:<[\s\S]*?>)?\(\s*\[[\s\S]*?' +
            RegExp.escape(call) +
            r'|' +
            RegExp.escape(call) +
            r')',
      ).hasMatch(beforeLaunch);
      expect(
        awaited,
        isTrue,
        reason: '$call 는 await 되어야 한다(직접 또는 Future.wait 안에서).',
      );

      // UxPreviewApp 조기 반환 경로는 프리로드 앞에 있어도 된다(디버그
      // 갤러리). 그 경로까지 순서를 강제하면 갤러리 기동이 불필요하게
      // 느려진다.
    },
  );
}
