import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/onboarding_level_screen.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

/// 마스코트·히어로 정지 그림 **잠금** (Jin 2026-08-25).
///
/// Jin 이 두 번 갈아엎은 자산이라 못 박는다:
/// ① 호랑이 마스코트는 `tiger_front.png` — 옛 `tiger_sitting2.png` 는 누운 자세라
///    정지 상태에서 축 처져 보였다. **영상** `tiger_sitting2.mp4` 는 그대로 쓴다
///    (움직일 땐 문제없다) — 그래서 이 잠금은 `.png` 만 막고 `.mp4` 는 건드리지
///    않는다.
/// ② 온보딩 히어로 포스터는 정본 페어 아트 `magpie_tiger_together.png` —
///    옛 `hanok/welcome-hero.png` 는 폐기했다.
///
/// 자산을 바꾸려면 이 테스트를 **먼저** 고쳐야 한다. 그게 잠금의 목적이다.
void main() {
  const tigerAsset = 'assets/illustrations/mascot/tiger_front.png';
  const heroPoster = 'assets/illustrations/mascot/magpie_tiger_together.png';

  // 코드가 되살리면 안 되는 옛 그림들. 경로 전체가 문자열 리터럴로 등장하는
  // 경우만 잡는다 — 주석에서 이력을 설명하는 건 허용해야 한다.
  const retired = <String>[
    'assets/illustrations/mascot/tiger_sitting2.png',
    'assets/illustrations/hanok/welcome-hero.png',
  ];

  test('tiger mascot pose is locked to tiger_front (Jin 2026-08-25)', () {
    expect(Mascot.kTigerAsset, tigerAsset);
    expect(File(tigerAsset).existsSync(), isTrue, reason: '$tigerAsset 없음');
  });

  test('onboarding hero poster is locked to the canonical pair art', () {
    expect(OnboardingLevelScreen.kHeroPoster, heroPoster);
    expect(File(heroPoster).existsSync(), isTrue, reason: '$heroPoster 없음');
  });

  test('retired mascot art is gone from disk and from code', () {
    for (final path in retired) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason: '$path 는 폐기됐다 — 번들에 다시 넣지 말 것',
      );
    }

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // 주석은 이력 설명용으로 옛 이름을 언급해도 된다 — 코드만 본다.
      final code = entity
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      for (final path in retired) {
        if (code.contains(path)) offenders.add('${entity.path} → $path');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '폐기된 그림을 코드가 다시 부릅니다:\n${offenders.join('\n')}',
    );
  });
}
