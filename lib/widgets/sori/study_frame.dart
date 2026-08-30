import 'package:flutter/material.dart';

import 'app_bar.dart';
import 'home_action.dart';
import 'responsive.dart';
import 'screen_background.dart';
import 'tokens.dart';

export 'home_action.dart' show SoriHomeEscape;

/// 집중형 학습·퀴즈 화면의 공용 프레임.
///
/// 화면은 문제·카드·결과 상태만 공급하고, 앱바·한지 배경·SafeArea·태블릿 폭
/// 램프·기본 여백은 이 프레임이 한 번만 결정한다. 내부 콘텐츠의 스크롤과 flex
/// 구조는 활동마다 다르므로 호출부가 소유한다.
class SoriStudyFrame extends StatelessWidget {
  const SoriStudyFrame({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.particles = false,
    this.noiseAlpha = 0.11,
    this.bottomNavigationBar,
    this.hero,
    this.homeEscape = const SoriHomeEscape(),
  });

  final String title;
  final String? eyebrow;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final EdgeInsetsGeometry padding;
  final bool particles;
  final double noiseAlpha;
  final Widget? bottomNavigationBar;

  /// §15 계약: 플레이 화면은 전체 히어로 예산(200dp/22%)을 받지 않는다.
  /// 넘겨진 위젯은 항상 [SoriLayout.heroCollapsedHeight](96dp)로 고정
  /// 클램프된다 — 안의 내용이 더 크더라도 잘리거나 눌린다. null(기본값)이면
  /// 자리 자체가 없다(0dp) — `hero_placement_guard_test.dart` 가 지키는
  /// "플레이 화면 히어로 0dp"의 유일한 예외 경로가 이 슬롯이다.
  final Widget? hero;
  final SoriHomeEscape homeEscape;

  @override
  Widget build(BuildContext context) {
    final homeAction = SoriHomeAction(escape: homeEscape);
    final remainingActions = <Widget>[
      for (final action in actions ?? const <Widget>[])
        if (action is! SoriHomeAction) action,
    ];
    final hasCustomLeading = leading != null && leading is! SoriHomeAction;
    final effectiveLeading = hasCustomLeading ? leading : homeAction;
    final effectiveActions = <Widget>[
      if (hasCustomLeading) homeAction,
      ...remainingActions,
    ];

    return Scaffold(
      appBar: SoriAppBar(
        title: title,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
        eyebrow: eyebrow,
        actions: effectiveActions.isEmpty ? null : effectiveActions,
        leading: effectiveLeading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: SoriScreenBackground(
        particles: particles,
        noiseAlpha: noiseAlpha,
        child: SafeArea(
          top: false,
          child: SoriStudyClamp(
            child: hero == null
                ? Padding(padding: padding, child: child)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: SoriLayout.heroCollapsedHeight,
                        child: ClipRect(child: hero!),
                      ),
                      Expanded(
                        child: Padding(padding: padding, child: child),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// 짧은 화면과 큰 접근성 글자에서 학습 본문의 flex 구조를 보존하며 스크롤한다.
///
/// [minHeight]는 100% 글자에서 해당 활동이 필요로 하는 최소 본문 높이다. 200%
/// 까지는 줄 높이 증가를 반영해 최대 1.9배로 키운다. 정상 세로 화면은 기존
/// 레이아웃을 그대로 쓰고, 실제 가용 높이가 부족할 때만 [SoriMinHeightScroll]
/// 이 유한 높이 상자를 만들어 `Expanded`와 `Spacer`를 안전하게 유지한다.
class SoriAdaptiveStudyBody extends StatelessWidget {
  const SoriAdaptiveStudyBody({
    super.key,
    required this.minHeight,
    required this.child,
  });

  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scaleProgress = (textScale - 1).clamp(0.0, 1.0);
    final accessibleMinHeight = minHeight * (1 + scaleProgress * 0.9);
    return SoriMinHeightScroll(minHeight: accessibleMinHeight, child: child);
  }
}
