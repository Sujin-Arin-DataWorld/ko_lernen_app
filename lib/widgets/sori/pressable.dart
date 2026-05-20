import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// **SoriPressable** — "통통튀는" 핵심 컴포넌트.
///
/// 모든 tap-able 요소(카드/버튼/칩)를 감싸면 자동으로:
/// - tap-down → scale 0.96 (200ms ease-out)
/// - tap-up   → scale 1.0 (300ms elasticOut spring)
/// - haptic feedback (default: selectionClick)
///
/// onTap이 null이면 애니메이션 비활성 (display-only 상태).
///
/// 사용:
/// ```dart
/// SoriPressable(
///   onTap: () => Navigator.push(...),
///   child: SoriCard(child: ...),
/// )
/// ```
class SoriPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 0.0 — 1.0. Default 0.96.
  final double pressScale;

  /// 햅틱 타입. null이면 햅틱 없음.
  final SoriHaptic? haptic;

  /// hit test 동작.
  final HitTestBehavior behavior;

  /// scale animation을 child의 어느 alignment 기준으로 할지.
  final Alignment alignment;

  const SoriPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = SoriMotion.pressScale,
    this.haptic = SoriHaptic.selection,
    this.behavior = HitTestBehavior.opaque,
    this.alignment = Alignment.center,
  });

  @override
  State<SoriPressable> createState() => _SoriPressableState();
}

class _SoriPressableState extends State<SoriPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: SoriMotion.fast,
      lowerBound: widget.pressScale,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down() {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _ctrl.animateTo(widget.pressScale,
        duration: SoriMotion.fast, curve: SoriMotion.press);
  }

  void _release() {
    _ctrl.animateTo(1.0,
        duration: SoriMotion.medium, curve: SoriMotion.release);
  }

  void _doHaptic() {
    switch (widget.haptic) {
      case SoriHaptic.light:     HapticFeedback.lightImpact(); break;
      case SoriHaptic.medium:    HapticFeedback.mediumImpact(); break;
      case SoriHaptic.heavy:     HapticFeedback.heavyImpact(); break;
      case SoriHaptic.selection: HapticFeedback.selectionClick(); break;
      case null: break;
    }
  }

  void _onTap() {
    if (widget.onTap == null) return;
    _doHaptic();
    widget.onTap!();
  }

  void _onLongPress() {
    if (widget.onLongPress == null) return;
    HapticFeedback.mediumImpact();
    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown:   (_) => _down(),
      onTapUp:     (_) => _release(),
      onTapCancel: _release,
      onTap:       _onTap,
      onLongPress: widget.onLongPress != null ? _onLongPress : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _ctrl.value,
          alignment: widget.alignment,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 햅틱 강도 선택.
enum SoriHaptic { light, medium, heavy, selection }
