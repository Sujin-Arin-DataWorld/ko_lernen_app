import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// 계약: 축하 버스트 시트는 **첫 프레임 전에** 디코딩이 끝나야 한다. 새 설치
// 직후 첫 정답도 Satz 전용 6배 시트를 쓰게 하려는 것이고, 안 그러면 첫 번째
// 축하만 절차적 폴백으로 떨어진다.
//
// 2026-08-12 통합 시 갱신: origin/main 이 UX 프리뷰 갤러리를 위해 runApp 을
// 주입 가능한 `runner` 로 바꾸면서 옛 리터럴 `runApp(const KoLernenApp());`
// 가 사라졌다. 호출 **형태**를 문자열로 고정하면 이렇게 리팩터마다 깨지므로,
// 실앱을 띄우는 지점을 형태와 무관하게 찾아 순서만 검증한다.
void main() {
  test('burst sheets finish preloading before the first app frame', () {
    final source = File('lib/main.dart').readAsStringSync();

    final preload = source.indexOf('await DancheongBurst.preload();');
    expect(
      preload,
      greaterThanOrEqualTo(0),
      reason:
          'lib/main.dart 가 DancheongBurst.preload() 를 await 해야 한다. '
          'await 를 떼면 첫 축하가 절차적 폴백으로 떨어진다.',
    );

    // 실앱(KoLernenApp)을 띄우는 지점 — runApp 직접 호출이든 runner 주입이든.
    final launch = RegExp(
      r'(runApp|runner)\(\s*const\s+KoLernenApp\(\)\s*\)',
    ).firstMatch(source);
    expect(
      launch,
      isNotNull,
      reason: 'lib/main.dart 에서 KoLernenApp 을 띄우는 지점을 찾지 못했다.',
    );

    expect(
      launch!.start,
      greaterThan(preload),
      reason: '프리로드 await 가 실앱 실행보다 뒤에 있으면 계약이 깨진다.',
    );

    // UxPreviewApp 조기 반환 경로는 프리로드 앞에 있어도 된다(디버그 갤러리).
    // 그 경로까지 순서를 강제하면 갤러리 기동이 불필요하게 느려진다.
  });
}
