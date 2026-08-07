import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  test('tiger profile picker is fixed to tiger_sitting2 (Jin 2026-08-06)', () {
    expect(CharacterClips.profileClipCountFor(MascotKind.tiger), 1);
    expect(
      CharacterClips.profileClipFor(MascotKind.tiger, 0),
      CharacterClips.tigerSitting2,
    );
  });

  test('magpie profile picker uses every requested portrait clip', () {
    expect(CharacterClips.profileClipCountFor(MascotKind.magpie), 3);
    expect(
      [
        CharacterClips.profileClipFor(MascotKind.magpie, 0),
        CharacterClips.profileClipFor(MascotKind.magpie, 1),
        CharacterClips.profileClipFor(MascotKind.magpie, 2),
      ],
      [
        CharacterClips.magpiePerched,
        CharacterClips.magpieChoose,
        CharacterClips.magpieFlight,
      ],
    );
  });

  // Jin 2026-08-07 (샤오미 패드 6): "png가지고 움직이는것같이 만들어놓은거
  // 그게 처음에 재생되고 계속 mp4이 재생돼. 이거mp4만 재생되도록 하고".
  // 홈 히어로는 `staticFallback:false` 인데 워치독이 900ms 로 실기기 디코더
  // 콜드 스타트보다 짧아, 매번 까치 PNG 플립북(wingup↔wingdown)이 먼저 뜬 뒤
  // mp4 로 교체됐다. 정책은 이제 시간이 아니라 lease 상태로 판단한다.
  group('CharacterClipFallbackPolicy', () {
    // 홈 히어로가 쓰는 조합: 영상 가능 + `staticFallback:false`.
    bool homeHero({
      bool videoUnavailable = false,
      bool failed = false,
      bool clipRetired = false,
    }) => CharacterClipFallbackPolicy.showStaticFallback(
      videoUnavailable: videoUnavailable,
      failed: failed,
      clipRetired: clipRetired,
      staticFallbackRequested: false,
    );

    test('normal MP4 initialization waits — no animated Mascot', () {
      // 이 케이스가 회귀의 전부였다. 예전 900ms 워치독은 여기서 정적을 켰고,
      // 까치 폴백이 PNG 플립북이라 "mp4 앞에 PNG 애니메이션이 재생"됐다.
      expect(homeHero(), isFalse);
    });

    test('elapsed time is not an input at all', () {
      // 시그니처에 시간·시도횟수 인자가 없다는 것 자체가 계약이다. 같은
      // 입력이면 언제 물어도 같은 답 — 호출을 반복해도 절대 뒤집히지 않는다.
      for (var i = 0; i < 100; i++) {
        expect(homeHero(), isFalse);
      }
    });

    test('an impossible video path falls back immediately', () {
      // videoReady=false · 다크. 기다려도 절대 안 오므로 시간을 끌 이유가 없다.
      expect(homeHero(videoUnavailable: true), isTrue);
    });

    test('an explicit decoder failure falls back', () {
      // 코디네이터가 백오프 2회 재시도까지 끝낸 뒤의 onFailed.
      expect(homeHero(failed: true), isTrue);
    });

    test('a finished one-shot holds its last pose', () {
      // 텍스처 반납 후 자리가 사라지던 프로필 호랑이 회귀 방지.
      expect(homeHero(clipRetired: true), isTrue);
    });

    test('an explicit staticFallback request always wins', () {
      expect(
        CharacterClipFallbackPolicy.showStaticFallback(
          videoUnavailable: false,
          failed: false,
          clipRetired: false,
          staticFallbackRequested: true,
        ),
        isTrue,
      );
    });
  });
}
