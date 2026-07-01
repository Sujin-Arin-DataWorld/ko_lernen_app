import 'package:flutter/material.dart';

import 'ambient_particles.dart';
import 'hanok/hanji_texture.dart';

/// **SoriScreenBackground** — 화면 전역 한지 배경 래퍼 (D4 공유 토대).
///
/// plain Material Scaffold의 단색 크림 배경 위에 은은한 한지 결(paper grain)을
/// 깔아 모든 화면이 "종이 위"에 있게 한다. 15+ 화면이 `body`를 이걸로 감싸
/// 배경 반복 코드를 없앤다.
///
/// 설계 근거:
/// - [HanjiTexture]는 불투명 크림 워시(= Scaffold bg와 동색 `#FAF6EC`)에 미세
///   grain만 더하므로 텍스트 대비는 그대로. **최하단 레이어**로 깔고 콘텐츠는 위.
/// - 콘텐츠는 [Positioned.fill]로 감싸 원래 Scaffold body가 받던 **tight full-size
///   제약**을 그대로 받는다 → Column/Expanded/Center 레이아웃 회귀 0(드롭인 대체).
/// - [particles]는 passive(읽기) 화면에서만 true 권장 — 게임/입력/설정은 false.
///   reduce-motion 시 [AmbientParticles]가 자동으로 정적(SizedBox) 폴백.
/// - 다크 모드에선 질감을 생략(라이트 전용 앱 — 대비 안전·불필요).
///
/// ```dart
/// Scaffold(
///   body: SoriScreenBackground(
///     child: SafeArea(child: ListView(...)),
///   ),
/// )
/// ```
///
/// ⚠️ **bounded 제약(=Scaffold body)** 전용. unbounded(스크롤 내부 등)에 직접
/// 넣으면 all-Positioned Stack이 0으로 붕괴한다.
class SoriScreenBackground extends StatelessWidget {
  final Widget child;

  /// 은은한 매화 파티클 레이어(passive 화면만). 기본 false.
  final bool particles;

  /// 파티클 개수(절제 — 기본 8).
  final int particleCount;

  /// 한지 섬유 강도. 기본 0.11("은은 크림" — 가독성 우선). 카드(토큰 0.13)보다 옅게.
  final double noiseAlpha;

  const SoriScreenBackground({
    super.key,
    required this.child,
    this.particles = false,
    this.particleCount = 8,
    this.noiseAlpha = 0.11,
  });

  @override
  Widget build(BuildContext context) {
    // 라이트 전용 앱 — 다크에선 질감 생략(대비 안전·불필요).
    if (Theme.of(context).brightness == Brightness.dark) {
      return child;
    }
    return Stack(
      children: [
        // 최하단: 한지 결 (Scaffold 크림과 동색 + 미세 grain).
        Positioned.fill(
          child: HanjiTexture(
            noiseAlpha: noiseAlpha,
            child: const SizedBox.expand(),
          ),
        ),
        // 절제된 매화 (passive 화면만; reduce-motion 자동 폴백).
        if (particles)
          Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: particleCount)),
          ),
        // 콘텐츠 — tight full-size 제약(드롭인 대체).
        Positioned.fill(child: child),
      ],
    );
  }
}
