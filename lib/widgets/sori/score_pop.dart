import 'package:flutter/material.dart';
import 'tokens.dart';

/// 정답/콤보 순간 짧은 텍스트("+10 XP", "3er-Combo!")를 화면에 띄우고
/// 위로 떠오르며 사라지게 하는 OverlayEntry 헬퍼.
/// [SoriCelebration.burst] 와 같은 패턴 — 호출 한 줄로 도파민 피드백.
/// reduce-motion 시에는 움직임 없이 잠깐 표시했다 사라진다(접근성).
class ScorePop {
  ScorePop._();

  static void show(
    BuildContext context,
    String text, {
    Color? color,
    Offset? origin,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final media = MediaQuery.of(context);
    final start =
        origin ?? Offset(media.size.width / 2, media.size.height * 0.40);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ScorePop(
        text: text,
        color: color ?? SoriColors.gold,
        topStart: start.dy,
        reduceMotion: SoriMotion.reduceMotion(context),
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ScorePop extends StatefulWidget {
  const _ScorePop({
    required this.text,
    required this.color,
    required this.topStart,
    required this.reduceMotion,
    required this.onDone,
  });

  final String text;
  final Color color;
  final double topStart;
  final bool reduceMotion;
  final VoidCallback onDone;

  @override
  State<_ScorePop> createState() => _ScorePopState();
}

class _ScorePopState extends State<_ScorePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final rise =
            widget.reduceMotion ? 0.0 : -52.0 * Curves.easeOut.transform(t);
        final scale = widget.reduceMotion
            ? 1.0
            : (t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) : 1.0);
        final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);
        return Positioned(
          left: 0,
          right: 0,
          top: widget.topStart + rise,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Center(child: _bubble()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: SoriRadius.brPill,
        boxShadow: SoriElevation.medium,
      ),
      child: Text(
        widget.text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
