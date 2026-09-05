import 'package:flutter/material.dart';

import 'app_bar.dart';
import 'home_action.dart';
import 'page_header.dart';
import 'responsive.dart';
import 'screen_background.dart';
import 'tokens.dart';
import 'window_class.dart';

typedef SoriStandardBodyBuilder =
    Widget Function(BuildContext context, EdgeInsets resolvedPadding);

/// 표준 페이지가 공유하는 가장 낮은 레이아웃 프레임.
///
/// 검색 화면처럼 고정 도구막대와 내부 목록을 함께 써야 하는 화면이 배경·앱바·
/// SafeArea·의미 기반 폭을 다시 구현하지 않도록 한다. 단일 스크롤 목록은 더 높은
/// 수준의 [SoriStandardPage]를 사용한다.
class SoriStandardFrame extends StatelessWidget {
  const SoriStandardFrame({
    super.key,
    required this.appBarTitle,
    required this.builder,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.maxWidth = SoriMaxWidth.prose,
    this.padding = EdgeInsets.zero,
    this.particles = false,
    this.bottomNavigationBar,
    this.showHome = true,
  });

  final String appBarTitle;
  final SoriStandardBodyBuilder builder;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// 명시적 의미 폭. `null`이면 기존 폰→태블릿 적응형 콘텐츠 폭을 쓴다.
  final double? maxWidth;
  final EdgeInsets padding;
  final bool particles;
  final Widget? bottomNavigationBar;

  /// §B3(2026-09-03): 이 페이지가 뒤로 갈 곳이 있으면(`Navigator.canPop()`)
  /// 우상단에 확인 없는 [SoriHomeAction]을 더한다. 루트 탭 화면(뒤로 갈 곳이
  /// 없다)은 자연히 영향받지 않는다. `false`로 끄면 이 페이지는 절대 홈
  /// 액션을 받지 않는다.
  final bool showHome;

  @override
  Widget build(BuildContext context) {
    final suppliedActions = actions ?? const <Widget>[];
    final hasHomeAction = suppliedActions.any((a) => a is SoriHomeAction);
    final effectiveActions = <Widget>[
      ...suppliedActions,
      if (showHome && !hasHomeAction && Navigator.of(context).canPop())
        const SoriHomeAction(),
    ];
    return Scaffold(
      appBar: SoriAppBar(
        title: appBarTitle,
        actions: effectiveActions.isEmpty ? null : effectiveActions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
      ),
      body: SoriScreenBackground(
        particles: particles,
        child: SafeArea(
          top: false,
          child: SoriContentClamp(
            maxWidth: maxWidth,
            base: padding,
            builder: builder,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// 고정 하단 행동을 SafeArea와 콘텐츠 폭 안에 두는 표준 영역.
///
/// 학습·목록 화면의 CTA가 태블릿 전체 폭으로 늘어나거나 시스템 제스처 영역과
/// 겹치지 않도록 한다. 버튼 문구는 [SoriButton]의 자연 높이 규칙을 그대로
/// 따르므로 큰 글자에서 잘리지 않는다.
class SoriBottomActionArea extends StatelessWidget {
  const SoriBottomActionArea({
    super.key,
    required this.child,
    this.maxWidth = SoriMaxWidth.prose,
    this.padding = const EdgeInsets.all(Spacing.lg),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SoriContentClamp(
        maxWidth: maxWidth,
        base: padding,
        builder: (context, resolvedPadding) =>
            Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

/// 목록·허브·설정 계열 화면의 표준 페이지 템플릿.
///
/// 화면은 제목과 콘텐츠만 공급하고, 아래 결정은 이 컴포넌트가 소유한다.
///
/// - 투명 [SoriAppBar]와 한지 [SoriScreenBackground]
/// - SafeArea 내부의 도달 가능한 단일 스크롤
/// - 의미 기반 최대 너비와 반응형 좌우 여백
/// - eyebrow → headline → description의 [SoriPageHeader] 위계
/// - 콘텐츠 끝의 충분한 하단 여백
///
/// 집중 학습·게임·공간 탐색 화면은 각각의 전용 템플릿을 사용한다. 이 템플릿에
/// 화면별 예외를 계속 추가하지 않는다.
class SoriStandardPage extends StatelessWidget {
  const SoriStandardPage({
    super.key,
    required this.appBarTitle,
    required this.children,
    this.eyebrow,
    this.headline,
    this.description,
    this.headerTrailing,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.maxWidth = SoriMaxWidth.prose,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.lg,
      Spacing.md,
      Spacing.lg,
      Spacing.xxxl,
    ),
    this.particles = false,
    this.controller,
    this.physics,
    this.showHome = true,
    this.fill = false,
  }) : assert(
         headline != null || (eyebrow == null && description == null),
         'eyebrow와 description은 headline이 있을 때만 사용할 수 있다.',
       );

  final String appBarTitle;
  final String? eyebrow;
  final String? headline;
  final String? description;
  final Widget? headerTrailing;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double maxWidth;
  final EdgeInsets padding;
  final bool particles;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  /// §B3(2026-09-03) — [SoriStandardFrame.showHome] 참고.
  final bool showHome;

  /// W10 T-V2(2026-09-05, Jin D-4): 짧고 고정된 콘텐츠(예: 오늘의 글자,
  /// 단어장 실습 허브)가 긴 뷰포트에서 위쪽에 뭉치지 않도록 세로 중앙
  /// 배치한다. `true`면 `ListView` 대신 [SoriMinHeightScroll] 로 감싼
  /// `Column(center)` 을 쓴다 — 콘텐츠가 뷰포트보다 길면 그대로 스크롤한다.
  /// 목록형 화면(항목 수가 늘어날 수 있는 화면)은 `false`(기본값)로 둔다.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final header = headline == null
        ? null
        : SoriPageHeader(
            eyebrow: eyebrow,
            title: headline!,
            body: description,
            trailing: headerTrailing,
          );

    return SoriStandardFrame(
      appBarTitle: appBarTitle,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      maxWidth: maxWidth,
      padding: padding,
      particles: particles,
      showHome: showHome,
      builder: (context, resolvedPadding) {
        final content = [
          if (header != null) ...[
            header,
            if (children.isNotEmpty) const SizedBox(height: Spacing.xl),
          ],
          ...children,
        ];
        if (fill) {
          return SoriMinHeightScroll(
            minHeight: 0,
            fillViewport: true,
            child: Padding(
              padding: resolvedPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            ),
          );
        }
        return ListView(
          controller: controller,
          physics: physics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: resolvedPadding,
          children: content,
        );
      },
    );
  }
}
