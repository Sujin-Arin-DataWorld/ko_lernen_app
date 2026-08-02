import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ADR-002 §6-2 — 볼륨 리터럴 래칫.
// lib/ 에서 `setVolume(<숫자>)` / `volume: <숫자>` 를 센다.
// audio_policy.dart(정책 자신)와 `// audio-policy: exempt — <이유>` 주석이
// 같은 줄 또는 바로 윗줄에 있는 곳만 허용. **숫자를 올리지 말 것** — 새 볼륨
// 하드코딩은 AudioPolicy.volumeFor() 로 가야 한다.
void main() {
  test('lib/ 볼륨 리터럴 — exempt 주석 없는 하드코딩 0건', () {
    final setVolumeLiteral = RegExp(r'setVolume\(\s*\d+(\.\d+)?\s*\)');
    final volumeArgLiteral = RegExp(r'\bvolume:\s*\d+(\.\d+)?\b');
    final offenders = <String>[];
    final exempt = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => !f.path
              .replaceAll('\\', '/')
              .endsWith('services/audio_policy.dart'),
        );

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!setVolumeLiteral.hasMatch(line) &&
            !volumeArgLiteral.hasMatch(line)) {
          continue;
        }
        final prev = i > 0 ? lines[i - 1] : '';
        final where = '${file.path}:${i + 1}';
        if (line.contains('audio-policy: exempt') ||
            prev.contains('audio-policy: exempt')) {
          exempt.add(where);
        } else {
          offenders.add('$where  ->  ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '볼륨 하드코딩 금지 — AudioPolicy.volumeFor() 를 쓰거나 정당한 사유와 '
          '함께 "// audio-policy: exempt — <이유>" 주석을 달 것.\n'
          '${offenders.join('\n')}',
    );
    // exempt 남용 가드 — 늘려야 하면 사유를 코드 주석과 이 상한에 함께 남길 것.
    expect(
      exempt.length,
      lessThanOrEqualTo(3),
      reason:
          '현재 exempt 3곳(캐릭터/홈/온보딩 영상 내장 트랙 상시 무음): '
          '${exempt.join(', ')}',
    );
  });
}
