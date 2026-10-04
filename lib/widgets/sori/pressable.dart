import '../../services/haptic_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// **SoriPressable** — "통통튀는" 핵심 컴포넌트.
///
/// 모든 tap-able 요소(카드/버튼/칩)를 감싸면 자동으로:
/// - tap-down → scale 0.96 (150ms SoriMotion.fast)
/// - tap-up   → scale 1.0 (250ms SoriMotion.medium elasticOut spring)
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

  /// 눌림 상태 통지 — 표면 v2 카드의 그림자 low→medium 전환용 (§10.3).
  /// tap-down 직후 true, tap-up/cancel 시 false. 비활성이면 down 은 오지 않는다.
  final ValueChanged<bool>? onPressedChanged;

  /// A raised action collapses toward its lower edge on contact.
  final double surfaceDepth;
  final Color? surfaceEdgeColor;
  final double surfaceRadius;

  const SoriPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = SoriMotion.pressScale,
    this.haptic = SoriHaptic.selection,
    this.behavior = HitTestBehavior.opaque,
    this.alignment = Alignment.center,
    this.onPressedChanged,
    this.surfaceDepth = 0,
    this.surfaceEdgeColor,
    this.surfaceRadius = SoriRadius.lg,
  });

  @override
  State<SoriPressable> createState() => _SoriPressableState();
}

class _SoriPressableState extends State<SoriPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hovered = false;
  bool _pressed = false;
  bool _reducedMotion = false;

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
    if (_pressed || widget.onTap == null && widget.onLongPress == null) {
      return;
    }
    _pressed = true;
    widget.onPressedChanged?.call(true);
    if (_reducedMotion) {
      return;
    }
    _ctrl.animateTo(
      widget.pressScale,
      duration: SoriMotion.fast,
      curve: SoriMotion.press,
    );
  }

  void _release() {
    if (!mounted || !_pressed) {
      return;
    }
    _pressed = false;
    widget.onPressedChanged?.call(false);
    if (_reducedMotion) {
      _ctrl.value = 1;
      return;
    }
    _ctrl.animateTo(
      1.0,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = SoriMotion.reduceMotion(context);
    if (_reducedMotion) {
      _ctrl.stop();
      _ctrl.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant SoriPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTap == null && widget.onLongPress == null) {
      _ctrl.stop();
      _ctrl.value = 1;
      _hovered = false;
      _pressed = false;
    }
  }

  void _doHaptic() {
    switch (widget.haptic) {
      case SoriHaptic.light:
        HapticService.lightImpact();
        break;
      case SoriHaptic.medium:
        HapticService.mediumImpact();
        break;
      case SoriHaptic.heavy:
        HapticService.heavyImpact();
        break;
      case SoriHaptic.selection:
        HapticService.selectionClick();
        break;
      case null:
        break;
    }
  }

  void _onTap() {
    if (widget.onTap == null) return;
    _doHaptic();
    widget.onTap!();
  }

  void _onLongPress() {
    if (widget.onLongPress == null) return;
    HapticService.mediumImpact();
    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final surfaces = SoriSurfaces.of(context);
    final focusRingColor = surfaces.brightness == Brightness.light
        ? SoriColors.primaryDark
        : SoriColors.darkPrimary;

    return Focus(
      canRequestFocus: enabled,
      onFocusChange: (focused) {
        if (!focused) {
          _release();
        }
      },
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          _release();
          return enabled ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        if (!enabled || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          _down();
          // finding 8: onTap 이 없으면(= onLongPress 만 있는 위젯) 예전엔
          // 여기서 그냥 무시했다 — 그런데 canRequestFocus 는 enabled(둘 중
          // 하나만 있어도 true) 라서 그런 위젯도 Tab 포커스는 받는다.
          // 키보드엔 "누르고 있기"에 대응하는 제스처가 없으므로, 유일한
          // 액션인 onLongPress 를 Enter/Space 의 활성화 대상으로 쓴다.
          // (post-review) 위에서 이미 `!enabled` 면 리턴했으므로 여기 온
          // 시점엔 onTap/onLongPress 중 하나는 반드시 non-null 이다 —
          // 셋 다 null 인 else 가지는 죽은 코드였다.
          if (widget.onTap != null) {
            _onTap();
          } else {
            _onLongPress();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return MouseRegion(
            onEnter: (_) {
              if (enabled) {
                setState(() => _hovered = true);
              }
            },
            onExit: (_) => setState(() => _hovered = false),
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Listener(
              behavior: widget.behavior,
              onPointerDown: (_) => _down(),
              onPointerUp: (_) => _release(),
              onPointerCancel: (_) => _release(),
              child: GestureDetector(
                behavior: widget.behavior,
                onTapCancel: _release,
                onTap: _onTap,
                onLongPress: widget.onLongPress != null ? _onLongPress : null,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) {
                    final reduced = SoriMotion.reduceMotion(context);
                    final pressure = widget.pressScale == 1
                        ? 0.0
                        : ((1 - _ctrl.value) / (1 - widget.pressScale)).clamp(
                            0.0,
                            1.0,
                          );
                    final depth = widget.surfaceDepth;
                    final surface = depth > 0
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                widget.surfaceRadius,
                              ),
                              boxShadow: depth > 0
                                  ? [
                                      BoxShadow(
                                        color:
                                            widget.surfaceEdgeColor ??
                                            SoriColors.primaryDark,
                                        offset: Offset(
                                          0,
                                          depth * (1 - pressure * .75),
                                        ),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: child,
                          )
                        : child;
                    final scaled = depth > 0
                        ? AnimatedContainer(
                            duration: SoriMotion.respect(
                              context,
                              SoriMotion.fast,
                            ),
                            curve: SoriMotion.gentle,
                            transform: Matrix4.translationValues(
                              0,
                              !reduced && enabled && (_hovered || focused)
                                  ? -2
                                  : 0,
                              0,
                            ),
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                reduced ? 0 : depth * .75 * pressure,
                              ),
                              child: Transform.scale(
                                scale: _ctrl.value,
                                alignment: widget.alignment,
                                child: surface,
                              ),
                            ),
                          )
                        : Transform.scale(
                            scale: _ctrl.value,
                            alignment: widget.alignment,
                            child: surface,
                          );
                    if (!focused) return scaled;
                    // Keyboard focus indicator (web/desktop) — 살짝 띈 ring.
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        scaled,
                        Positioned(
                          left: -3,
                          top: -3,
                          right: -3,
                          bottom: -3,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  SoriRadius.md,
                                ),
                                border: Border.all(
                                  // Opaque surface-aware tokens keep the
                                  // keyboard indicator above WCAG's 3:1
                                  // non-text contrast floor.
                                  color: focusRingColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 햅틱 강도 선택.
enum SoriHaptic { light, medium, heavy, selection }
