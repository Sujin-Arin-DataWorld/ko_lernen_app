import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/canonical_companion_art.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

/// The explicit canonical replacement on 2026-10-30 supersedes the old
/// single-pose lock. Keep the new identity active and old source bytes
/// recoverable, without rendering a superseded character as a fallback.
void main() {
  const tigerAsset = CanonicalCompanionArt.baekhoStanding;
  const heroPoster = 'assets/illustrations/mascot/magpie_tiger_together.png';

  // 코드가 되살리면 안 되는 옛 그림들. 경로 전체가 문자열 리터럴로 등장하는
  // 경우만 잡는다 — 주석에서 이력을 설명하는 건 허용해야 한다.
  const retired = <String>[
    'assets/illustrations/mascot/tiger_sitting2.png',
    'assets/illustrations/hanok/welcome-hero.png',
  ];

  test('tiger identity uses the new canonical Baekho (Jin 2026-10-30)', () {
    expect(Mascot.kTigerAsset, tigerAsset);
    expect(File(tigerAsset).existsSync(), isTrue, reason: '$tigerAsset 없음');
  });

  test('superseded pair original remains recoverable during replacement', () {
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
      for (final path in [
        ...retired,
        'assets/illustrations/mascot/tiger_front.png',
        'assets/illustrations/mascot/magpie_front.png',
        heroPoster,
      ]) {
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
