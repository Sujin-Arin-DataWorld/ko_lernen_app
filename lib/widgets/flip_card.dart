import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'sori/scroll_if_needed.dart';

/// Tappable card that flips horizontally between [front] and [back].
///
/// ⚠️ 계약: 표시하는 **단어(내용)가 바뀔 때는 반드시 새 [key]를 줘야 한다**
/// (예: 서빙 카운터 `ValueKey('learn-$serve')`). key 없이 같은 setState에서
/// 내용과 `flipped=false`만 바꾸면 이 State가 재사용되어 reverse 애니메이션이
/// **다음 카드의 뒷면(뜻) 위에서** 재생된다 — 답이 ~190ms 미리 노출된다.
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool flipped;
  final VoidCallback? onTap;
  final Duration duration;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.flipped,
    this.onTap,
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.flipped) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.flipped != old.flipped) {
      widget.flipped ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final v = _anim.value;
          final showFront = v < 0.5;
          final rot = v * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(rot),
            child: showFront
                ? _fitFace(widget.front)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _fitFace(widget.back),
                  ),
          );
        },
      ),
    );
  }

  /// 카드 앞/뒷면은 학습 화면에서 `Expanded` 안에 들어가 **높이가 하드 바운드**
  /// 된다. 가로로 든 폰이나 분할 화면처럼 뷰포트가 짧으면 그 상자가 면 내용
  /// (36pt 한국어 + 발음 + 재생 버튼 + 힌트)보다 작아져 그대로 넘쳤다
  /// — 800×360 단어팩에서 101px (2026-08-07).
  ///
  /// 여유가 있을 때는 지금까지와 **완전히 같은 레이아웃**이다: `minHeight` 로
  /// 상자를 꽉 채우게 강제하므로 면 안의 `Center` 도 그대로 가운데 정렬된다.
  /// 모자랄 때만 잘라내는 대신 스크롤한다 — `SoriEmptyState` 와 같은 규칙.
  ///
  /// 세로 스크롤이라 화면 쪽 좌우 스와이프(다음/이전 카드) 제스처와 축이 겹치지
  /// 않고, `FlipCard` 루트의 탭(뒤집기)도 스크롤뷰가 삼키지 않는다.
  Widget _fitFace(Widget face) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) {
          return face;
        }
        return SingleChildScrollView(
          physics: kSoriCardFacePhysics,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: face,
          ),
        );
      },
    );
  }
}
