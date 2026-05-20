import 'package:flutter/material.dart';

import 'mascot.dart';
import 'tokens.dart';

/// 정답 시 코너에 뽕 나타나는 작은 마스코트.
///
/// 사용 예 (quest engine 안):
/// ```dart
/// Stack(children: [
///   /* quest UI */,
///   Positioned(top: 8, right: 8, child: MascotPop(visible: _isCorrect)),
/// ])
/// ```
///
/// visible=true → scale 0 → 1.0 (elasticOut, 500ms)
/// visible=false → reverse out
class MascotPop extends StatefulWidget {
  final bool visible;
  final MascotKind kind;
  final double size;
  final MascotEmotion emotion;

  const MascotPop({
    super.key,
    required this.visible,
    this.kind = MascotKind.tiger,
    this.size = 56,
    this.emotion = MascotEmotion.celebrate,
  });

  @override
  State<MascotPop> createState() => _MascotPopState();
}

class _MascotPopState extends State<MascotPop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: SoriMotion.slow);
    if (widget.visible) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant MascotPop old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctrl.forward(from: 0);
    } else if (!widget.visible && old.visible) {
      _ctrl.animateTo(0, duration: SoriMotion.fast);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        if (_ctrl.value == 0) return const SizedBox.shrink();
        final scale = SoriMotion.celebrate.transform(_ctrl.value);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: _ctrl.value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: SoriColors.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: SoriColors.success, width: 2),
        ),
        padding: const EdgeInsets.all(4),
        child: Mascot(
          kind: widget.kind,
          emotion: widget.emotion,
          size: widget.size,
        ),
      ),
    );
  }
}
