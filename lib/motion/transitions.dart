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
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 280),
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
            builder: (_, c) => Transform.scale(
              scale: 0.94 + curved.value * 0.06,
              child: c,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
