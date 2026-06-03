import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sori mascot widget backed by separated tiger and magpie pose PNGs.
///
/// The public API stays compatible with the older combined welcome-hero based
/// widget. Callers keep using [Mascot.tiger], [Mascot.magpie], and
/// [Mascot.forSpeaker], while this widget selects the right pose internally.
class Mascot extends StatefulWidget {
  final MascotKind kind;
  final MascotEmotion emotion;
  final double size;

  /// Gentle idle motion. Tiger breathes and blinks; magpie can flap while
  /// flying contexts use it.
  final bool animate;

  const Mascot({
    super.key,
    required this.kind,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  });

  const Mascot.tiger({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.tiger;

  const Mascot.magpie({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.magpie;

  @Deprecated(
    'Use Mascot.tiger — Jieun/Minsu painters retired in v3 design refresh',
  )
  const Mascot.jieun({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.tiger;

  @Deprecated(
    'Use Mascot.tiger — Jieun/Minsu painters retired in v3 design refresh',
  )
  const Mascot.minsu({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.tiger;

  /// Speaker-code -> Mascot. minsu/jieun (legacy) -> tiger,
  /// kkachi/magpie -> magpie. Unknown speaker -> null.
  static Widget? forSpeaker(
    String speaker, {
    MascotEmotion emotion = MascotEmotion.smile,
    double size = 56,
    bool animate = false,
  }) {
    switch (speaker) {
      case 'tiger':
      case 'horangi':
      case '호랑이':
      case 'jieun':
      case 'minsu':
        return Mascot.tiger(emotion: emotion, size: size, animate: animate);
      case 'kkachi':
      case 'magpie':
      case '까치':
        return Mascot.magpie(emotion: emotion, size: size, animate: animate);
      default:
        return null;
    }
  }

  @override
  State<Mascot> createState() => _MascotState();
}

// TickerProviderStateMixin (nicht Single): _motion kann beim Umschalten von
// widget.animate (true→false→true) mehrfach neu erstellt werden.
class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  static const _tigerIdle = 'assets/illustrations/mascot/tiger_idle.png';
  static const _tigerBlink = 'assets/illustrations/mascot/tiger_blink.png';
  static const _tigerHappy = 'assets/illustrations/mascot/tiger_happy.png';
  static const _tigerCelebrate =
      'assets/illustrations/mascot/tiger_celebrate.png';
  static const _tigerSad = 'assets/illustrations/mascot/tiger_sad.png';
  static const _tigerThinking =
      'assets/illustrations/mascot/tiger_thinking.png';
  static const _tigerSleepy = 'assets/illustrations/mascot/tiger_sleepy.png';
  static const _tigerSmile = 'assets/illustrations/mascot/tiger_smile.png';
  static const _tigerNeutral = 'assets/illustrations/mascot/tiger_neutral.png';

  static const _magpiePerched =
      'assets/illustrations/mascot/magpie_perched.png';
  static const _magpieWingUp = 'assets/illustrations/mascot/magpie_wingup.png';
  static const _magpieWingDown =
      'assets/illustrations/mascot/magpie_wingdown.png';
  static const _magpieCelebrate =
      'assets/illustrations/mascot/magpie_celebrate.png';
  static const _magpieWorry = 'assets/illustrations/mascot/magpie_worry.png';

  AnimationController? _motion;

  bool get _isMagpie => widget.kind == MascotKind.magpie;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _startMotion();
  }

  void _startMotion() {
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant Mascot old) {
    super.didUpdateWidget(old);
    if (widget.animate && _motion == null) {
      _startMotion();
    } else if (!widget.animate && _motion != null) {
      _motion!.dispose();
      _motion = null;
    }
  }

  @override
  void dispose() {
    _motion?.dispose();
    super.dispose();
  }

  String _assetFor(double t) {
    if (_isMagpie) {
      switch (widget.emotion) {
        case MascotEmotion.celebrate:
          return _magpieCelebrate;
        case MascotEmotion.worry:
          return _magpieWorry;
        case MascotEmotion.sleepy:
          return _magpiePerched;
        case MascotEmotion.thinking:
        case MascotEmotion.surprised:
        case MascotEmotion.neutral:
        case MascotEmotion.smile:
          if (widget.animate) {
            final flap = math.sin(t * math.pi * 10);
            return flap >= 0 ? _magpieWingUp : _magpieWingDown;
          }
          return _magpiePerched;
      }
    }

    switch (widget.emotion) {
      case MascotEmotion.celebrate:
        return _tigerCelebrate;
      case MascotEmotion.worry:
        return _tigerSad;
      case MascotEmotion.sleepy:
        return _tigerSleepy;
      case MascotEmotion.thinking:
        return _tigerThinking;
      case MascotEmotion.surprised:
        return _tigerHappy;
      case MascotEmotion.smile:
        // 부드러운 미소 — animate 시 깜빡임 + 가끔 idle 프레임으로 다양성.
        if (widget.animate) {
          if (t > 0.82 && t < 0.90) return _tigerBlink;
          if (t > 0.40 && t < 0.46) return _tigerIdle;
        }
        return _tigerSmile;
      case MascotEmotion.neutral:
        // 중립 정면 — animate 시 가끔 깜빡임 + idle 프레임 교차.
        if (widget.animate) {
          if (t > 0.82 && t < 0.90) return _tigerBlink;
          if (t > 0.40 && t < 0.46) return _tigerIdle;
        }
        return _tigerNeutral;
    }
  }

  String get _semanticsLabel {
    final kindLabel = _isMagpie ? '까치' : '호랑이';
    final emotionLabel = switch (widget.emotion) {
      MascotEmotion.celebrate => ', 축하',
      MascotEmotion.worry => ', 걱정',
      MascotEmotion.sleepy => ', 졸림',
      MascotEmotion.surprised => ', 놀람',
      MascotEmotion.thinking => ', 생각 중',
      MascotEmotion.smile => ', 미소',
      MascotEmotion.neutral => '',
    };
    return '마스코트 $kindLabel$emotionLabel';
  }

  @override
  Widget build(BuildContext context) {
    final motion = _motion;
    final pose = motion == null
        ? _buildPose(0)
        : AnimatedBuilder(
            animation: motion,
            builder: (_, __) => _buildPose(motion.value),
          );

    return Semantics(
      label: _semanticsLabel,
      image: true,
      excludeSemantics: true,
      child: pose,
    );
  }

  Widget _buildPose(double t) {
    final wave = math.sin(t * math.pi * 2);
    final bob = _isMagpie && widget.animate ? wave * widget.size * 0.035 : 0.0;
    final scale = widget.animate && !_isMagpie ? 1.0 + (wave + 1) * 0.018 : 1.0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: Transform.scale(
          scale: scale,
          child: Image.asset(
            _assetFor(t),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _Fallback(kind: widget.kind, size: widget.size),
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final MascotKind kind;
  final double size;

  const _Fallback({required this.kind, required this.size});

  @override
  Widget build(BuildContext context) {
    final isMagpie = kind == MascotKind.magpie;
    final color = isMagpie ? const Color(0xFF5A7BA0) : const Color(0xFFFF8C42);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isMagpie ? '🐦' : '🐯',
        style: TextStyle(fontSize: size * 0.5, height: 1),
      ),
    );
  }
}

enum MascotKind {
  tiger,
  magpie,
  @Deprecated('Use MascotKind.tiger')
  jieun,
  @Deprecated('Use MascotKind.tiger')
  minsu,
}

enum MascotEmotion {
  neutral,
  smile,
  worry,
  celebrate,
  sleepy,
  surprised,
  thinking,
}
