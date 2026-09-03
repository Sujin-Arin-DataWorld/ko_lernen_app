import 'package:flutter/material.dart';

/// **SoriTransitions** — "살아있는 한옥"의 공유 화면 전환 레이어.
///
/// §B1(2026-09-03): 일반 라우트는 [page] — 플랫폼 네이티브 전환
/// ([SoriPageRoute], `theme.dart`의 `pageTransitionsTheme`가 실제 애니메이션을
/// 고른다: Android predictive-back, iOS/macOS Cupertino 슬라이드, 그 외
/// fade-upwards). `main.dart` `onGenerateRoute` 전부가 이걸 쓴다. [fadeScale]은
/// 첫 실행(온보딩) 전용으로 남는다 — [firstRun]이 그 계약을 감싼다.
class SoriTransitions {
  SoriTransitions._();

  /// 첫 실행(온보딩) 전용 fade + 깊이 scale-in. 0.94→1.0 으로 화면이
  /// "다가온다". 일반 라우트는 [page]를 쓴다 — 이 전환은 온보딩 시퀀스([firstRun])
  /// 밖에서 새로 쓰지 않는다 — `test/route_transition_test.dart`가 파일
  /// 집합을 고정한다.
  static Route<T> fadeScale<T>(
    WidgetBuilder builder, {
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 420),
    Duration reverseDuration = const Duration(milliseconds: 280),
    bool? reduceMotion,
  }) {
    final shouldReduceMotion =
        reduceMotion ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: shouldReduceMotion ? Duration.zero : duration,
      reverseTransitionDuration: shouldReduceMotion
          ? Duration.zero
          : reverseDuration,
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: AnimatedBuilder(
            animation: curved,
            builder: (_, c) =>
                Transform.scale(scale: 0.94 + curved.value * 0.06, child: c),
            child: child,
          ),
        );
      },
    );
  }

  /// First-run surfaces use the product's short transition contract and
  /// become instantaneous when the platform requests reduced motion.
  static Route<T> firstRun<T>(
    BuildContext context,
    WidgetBuilder builder, {
    RouteSettings? settings,
  }) {
    return fadeScale<T>(
      builder,
      settings: settings,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 200),
      // Keep the route-local MediaQuery decision explicit. The general route
      // helper falls back to the platform accessibility feature when callers
      // do not already have a BuildContext.
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
  }

  /// 일반 라우트의 플랫폼 네이티브 전환. `theme.dart`의
  /// `pageTransitionsTheme`가 실제 애니메이션(플랫폼별 predictive-back/
  /// Cupertino/fade-upwards)을 고르고, 이 헬퍼는 축약-동작 대응만 얹는다 —
  /// [SoriPageRoute] 참고.
  static Route<T> page<T>(WidgetBuilder builder, {RouteSettings? settings}) {
    return SoriPageRoute<T>(builder: builder, settings: settings);
  }
}

/// [SoriTransitions.page]가 만드는 [MaterialPageRoute] — 플랫폼별 실제
/// 전환은 `theme.dart`의 `pageTransitionsTheme`가 고른다(Android
/// predictive-back, iOS/macOS Cupertino 슬라이드, 그 외 fade-upwards). 이
/// 라우트는 그 위에 축약된 동작(reduce-motion) 시 duration을 0으로 낮추는
/// 책임만 더한다.
class SoriPageRoute<T> extends MaterialPageRoute<T> {
  SoriPageRoute({required super.builder, super.settings, this.reduceMotion});

  /// 테스트 전용 오버라이드 — 운영 코드는 항상 null을 넘겨
  /// [WidgetsBinding.instance.platformDispatcher.accessibilityFeatures]에서
  /// 실시간으로 읽는다.
  final bool? reduceMotion;

  bool get _shouldReduceMotion =>
      reduceMotion ??
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations;

  @override
  Duration get transitionDuration =>
      _shouldReduceMotion ? Duration.zero : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _shouldReduceMotion ? Duration.zero : super.reverseTransitionDuration;
}
