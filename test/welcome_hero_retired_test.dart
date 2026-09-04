import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// welcome-hero 온보딩 체인 격리 **회귀 가드** (2026-09-04 PR3-T2).
///
/// `OnboardingLevelScreen`·`OnboardingStartScreen`·`QuickOnboardingScreen`
/// 3화면과 그 히어로 영상 `welcome-hero.mp4`는 서로만 참조하는 죽은 사슬이었다
/// — `lib/main.dart` 라우팅은 세 이름을 한 번도 부르지 않고, 옛 경로 이름들은
/// 전부 새 온보딩(`OnboardingV2JourneyScreen`)을 만든다. Jin 지시로 **삭제가
/// 아니라 격리**해 `assets_unused/retired_code/` · `assets_unused/video/loops/`
/// 로 옮겼다(복원법은 `assets_unused/README.md` 참조).
///
/// 이 가드는 **하향 전용**이다 — 누군가 격리된 코드·에셋을 실수로 되살려
/// `lib/`(번들 대상)에 다시 끌어들이면 여기서 잡는다. 반대 방향(격리분을
/// 정말로 복원하고 싶을 때)은 이 테스트를 먼저 지우고 시작할 것.
void main() {
  test('welcome-hero string never appears in lib/ (comments excluded)', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // 주석은 이력 설명용으로 옛 이름을 언급해도 된다 — 코드만 본다.
      final code = entity
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      if (code.contains('welcome-hero')) offenders.add(entity.path);
    }
    expect(
      offenders,
      isEmpty,
      reason: '격리된 welcome-hero 자산을 코드가 다시 부릅니다:\n${offenders.join('\n')}',
    );
  });

  test('welcome-hero.mp4 is gone from the bundled assets tree', () {
    expect(
      File('assets/video/loops/welcome-hero.mp4').existsSync(),
      isFalse,
      reason: 'welcome-hero.mp4 는 assets_unused/video/loops/ 로 격리됐다 — '
          'assets/ 에 다시 넣지 말 것',
    );
  });

  test('retired onboarding class names never appear in lib/', () {
    const retiredClassNames = <String>[
      'OnboardingLevelScreen',
      'OnboardingStartScreen',
      'QuickOnboardingScreen',
    ];

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final code = entity
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      for (final name in retiredClassNames) {
        if (code.contains(name)) offenders.add('${entity.path} → $name');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '격리된 온보딩 화면을 코드가 다시 부릅니다:\n${offenders.join('\n')}',
    );
  });
}
