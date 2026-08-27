import 'package:flutter/material.dart';

/// **SoriTransitions** — "살아있는 한옥"의 공유 화면 전환 레이어.
///
/// 표준 [MaterialPageRoute]의 옆으로-미는 슬라이드는 "상자 더미" 느낌을 준다.
/// 여기 전환은 *깊이감*으로 — fade + 미세 scale-in — 화면이 다가오듯 들어온다.
/// 앱의 모든 라우트가 이 전환을 쓴다 (`main.dart` `onGenerateRoute`).
class SoriTransitions {
  SoriTransitions._();

  /// 부드러운 fade + 깊이 scale-in. 0.94→1.0 으로 화면이 "다가온다".
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
}
