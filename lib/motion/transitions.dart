import 'package:flutter/material.dart';

/// **SoriTransitions** — "살아있는 한옥"의 공유 화면 전환 레이어.
///
/// 표준 [MaterialPageRoute]의 옆으로-미는 슬라이드는 "상자 더미" 느낌을 준다.
/// 여기 전환들은 *깊이감*으로 — fade + 미세 scale-in — 화면이 다가오듯 들어온다.
class SoriTransitions {
  SoriTransitions._();

  /// 부드러운 fade + 미세 scale-in. 인트로→홈, hero 진입에 사용.
  static Route<T> fadeScale<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 540),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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
