import 'package:flutter/material.dart';

import 'app_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SoriAppBar(
        title: appBarTitle,
        actions: actions,
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
      builder: (context, resolvedPadding) => ListView(
        controller: controller,
        physics: physics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: resolvedPadding,
        children: [
          if (header != null) ...[
            header,
            if (children.isNotEmpty) const SizedBox(height: Spacing.xl),
          ],
          ...children,
        ],
      ),
    );
  }
}
