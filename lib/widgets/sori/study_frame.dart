import 'package:flutter/material.dart';

import 'app_bar.dart';
import 'home_action.dart';
import 'responsive.dart';
import 'screen_background.dart';
import 'tokens.dart';

export 'home_action.dart' show SoriHomeEscape, SoriCloseAction;

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
    this.automaticallyImplyLeading = true,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.particles = false,
    this.noiseAlpha = 0.11,
    this.bottomNavigationBar,
    this.hero,
    this.homeEscape = const SoriHomeEscape(),
    this.onLeave,
    this.bottom,
  });

  final String title;
  final String? eyebrow;
  final Widget child;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final EdgeInsetsGeometry padding;
  final bool particles;
  final double noiseAlpha;
  final Widget? bottomNavigationBar;

  /// 앱바 아래 고정 크롬(TabBar 등). SoriAppBar.bottom 으로 그대로 전달된다.
  final PreferredSizeWidget? bottom;

  /// §15 계약: 플레이 화면은 전체 히어로 예산(200dp/22%)을 받지 않는다.
  /// 넘겨진 위젯은 항상 [SoriLayout.heroCollapsedHeight](96dp)로 고정
  /// 클램프된다 — 안의 내용이 더 크더라도 잘리거나 눌린다. null(기본값)이면
  /// 자리 자체가 없다(0dp) — `hero_placement_guard_test.dart` 가 지키는
  /// "플레이 화면 히어로 0dp"의 유일한 예외 경로가 이 슬롯이다.
  final Widget? hero;
  final SoriHomeEscape homeEscape;

  /// 닫기(X)·홈 두 출구 모두에 전달 — 화면이 타이머 정지 등 정리를 할 자리.
  /// [SoriHomeEscape.confirmWhen]이면 확인 시트에서 "떠나기"를 고른 뒤,
  /// 아니면 즉시 호출된다.
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    // §B2(2026-09-03): 좌상단 닫기(X)·우상단 홈은 화면마다 다시 만들지
    // 않는다 — 프레임이 유일하게 소유한다. 시스템 뒤로가기/스와이프백/
    // 예측 뒤로가기도 X와 같은 확인 규칙을 따르도록 PopScope로 감싼다.
    final remainingActions = <Widget>[
      for (final action in actions ?? const <Widget>[])
        if (action is! SoriHomeAction && action is! SoriCloseAction) action,
    ];
    final effectiveActions = <Widget>[
      SoriHomeAction(escape: homeEscape, onLeave: onLeave),
      ...remainingActions,
    ];

    return PopScope(
      canPop: !homeEscape.confirmWhen,
      onPopInvokedWithResult: (didPop, _) async {
        // `didPop` 은 이 라우트에 등록된 *모든* PopEntry(예:
        // grammar_screen.dart의 필터-해제 전용 PopScope)를 반영한 합성값이라,
        // 이 프레임이 자기 몫이 아닌 차단까지 확인 시트로 가로채지 않도록
        // 스스로의 [homeEscape.confirmWhen]도 다시 확인한다 — 그렇지 않으면
        // 화면이 아직 열려 있는데 이 분기가 또 pop을 시도해 이중 종료로
        // 이어진다.
        if (didPop || !homeEscape.confirmWhen) {
          return;
        }
        if (!await showLeaveConfirmSheet(context, homeEscape)) {
          return;
        }
        onLeave?.call();
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: SoriAppBar(
          title: title,
          textScale: MediaQuery.textScalerOf(context).scale(1),
          viewportWidth: MediaQuery.sizeOf(context).width,
          eyebrow: eyebrow,
          actions: effectiveActions,
          leading: SoriCloseAction(escape: homeEscape, onLeave: onLeave),
          automaticallyImplyLeading: automaticallyImplyLeading,
          bottom: bottom,
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
      ),
    );
  }
}

/// 짧은 화면과 큰 접근성 글자에서 학습 본문의 flex 구조를 보존하며 스크롤한다.
///
/// [minHeight]는 100% 글자에서 해당 활동이 필요로 하는 최소 본문 높이다. 200%
/// 까지는 줄 높이 증가를 반영해 최대 (1+[maxScaleBoost])배로 키운다(기본
/// 0.9 → 1.9배). 정상 세로 화면은 기존 레이아웃을 그대로 쓰고, 실제 가용
/// 높이가 부족할 때만 [SoriMinHeightScroll] 이 유한 높이 상자를 만들어
/// `Expanded`와 `Spacer`를 안전하게 유지한다.
///
/// [maxScaleBoost] 기본값(0.9)은 대부분 화면에 맞지만, 200%에서 유독 긴
/// 본문(독일어 장문 부제 등)을 가진 화면은 실측 후 더 큰 값을 넘겨야 할 수
/// 있다(예: `book_capture_screen.dart` — §W-A2, 288dp 폭에서 부제가 900px+
/// 필요해 기본 1.9배로는 부족했다).
class SoriAdaptiveStudyBody extends StatelessWidget {
  const SoriAdaptiveStudyBody({
    super.key,
    required this.minHeight,
    required this.child,
    this.maxScaleBoost = 0.9,
  });

  final double minHeight;
  final Widget child;
  final double maxScaleBoost;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scaleProgress = (textScale - 1).clamp(0.0, 1.0);
    final accessibleMinHeight = minHeight * (1 + scaleProgress * maxScaleBoost);
    return SoriMinHeightScroll(minHeight: accessibleMinHeight, child: child);
  }
}
