import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

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
  // Jin 2026-08-06: 호랑이는 감정·프레임 구분 없이 tiger_sitting2 정지 한 장으로
  // 통일(옛 tiger_* 포즈 PNG 전량 폐지). 까치는 기존 포즈 시스템 유지.
  static const _tigerSitting2 =
      'assets/illustrations/mascot/tiger_sitting2.png';

  static const _magpieWingUp = 'assets/illustrations/mascot/magpie_wingup.png';
  static const _magpieWingDown =
      'assets/illustrations/mascot/magpie_wingdown.png';
  static const _magpieCelebrate =
      'assets/illustrations/mascot/magpie_celebrate.png';
  static const _magpieWorry = 'assets/illustrations/mascot/magpie_worry.png';
  static const _magpieDance = 'assets/illustrations/mascot/magpie_dance.png';
  static const _magpieEncourage =
      'assets/illustrations/mascot/magpie_encourage.png';
  static const _magpieSing = 'assets/illustrations/mascot/magpie_sing.png';
  static const _magpieSleep = 'assets/illustrations/mascot/magpie_sleep.png';
  static const _magpieWave = 'assets/illustrations/mascot/magpie_wave.png';

  /// 조이 정면 — 태고의 `tiger_neutral`(정면)과 짝을 맞추는 중립 자세.
  /// 기존 중립 정지는 `magpie_perched`(측면)이라 태고는 사용자를 보고
  /// 조이는 옆을 보는 비대칭이 있었다.
  static const _magpieFront = 'assets/illustrations/mascot/magpie_front.png';

  AnimationController? _motion;

  bool get _isMagpie => widget.kind == MascotKind.magpie;

  @override
  void initState() {
    super.initState();
    // Motion is started in didChangeDependencies once MediaQuery is available —
    // starting the ticker here would ignore the OS "reduce motion" setting.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _startMotion() {
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  /// Runs the idle ticker only when the caller asked for motion AND the OS
  /// "reduce motion" accessibility setting is off (WCAG 2.3.3). Reduce-motion →
  /// no ticker → static pose. Called from didChangeDependencies + didUpdateWidget
  /// so both widget.animate flips and MediaQuery changes are honoured.
  void _syncMotion() {
    // 호랑이는 정지(tiger_sitting2 한 장) → 티커 불필요. 까치만 애니메이션.
    final wantMotion =
        widget.animate && _isMagpie && !SoriMotion.reduceMotion(context);
    if (wantMotion && _motion == null) {
      _startMotion();
    } else if (!wantMotion && _motion != null) {
      _motion!.dispose();
      _motion = null;
    }
  }

  @override
  void didUpdateWidget(covariant Mascot old) {
    super.didUpdateWidget(old);
    _syncMotion();
  }

  @override
  void dispose() {
    _motion?.dispose();
    super.dispose();
  }

  String _assetFor(double t, {required bool animating}) {
    if (_isMagpie) {
      switch (widget.emotion) {
        case MascotEmotion.celebrate:
          // animate 시 축하↔춤 교대로 신나는 분위기, 정지 시 축하 포즈.
          if (animating) {
            return math.sin(t * math.pi * 4) >= 0
                ? _magpieCelebrate
                : _magpieDance;
          }
          return _magpieCelebrate;
        case MascotEmotion.worry:
          return _magpieWorry;
        case MascotEmotion.sleepy:
          return _magpieSleep;
        case MascotEmotion.thinking:
          return _magpieEncourage;
        case MascotEmotion.surprised:
          return _magpieSing;
        case MascotEmotion.neutral:
          if (animating) {
            final flap = math.sin(t * math.pi * 10);
            return flap >= 0 ? _magpieWingUp : _magpieWingDown;
          }
          return _magpieFront;
        case MascotEmotion.smile:
          if (animating) {
            final flap = math.sin(t * math.pi * 10);
            return flap >= 0 ? _magpieWingUp : _magpieWingDown;
          }
          return _magpieWave;
      }
    }

    // 호랑이는 감정·애니메이션 무관 정지 한 장(Jin 2026-08-06).
    return _tigerSitting2;
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
        ? _buildPose(0, animating: false)
        : AnimatedBuilder(
            animation: motion,
            builder: (_, __) => _buildPose(motion.value, animating: true),
          );

    return Semantics(
      label: _semanticsLabel,
      image: true,
      excludeSemantics: true,
      child: pose,
    );
  }

  Widget _img(String asset, {Key? key}) {
    return Image.asset(
      asset,
      key: key,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) =>
          _Fallback(kind: widget.kind, size: widget.size),
    );
  }

  Widget _buildPose(double t, {required bool animating}) {
    final wave = math.sin(t * math.pi * 2);
    final bob = _isMagpie && animating ? wave * widget.size * 0.035 : 0.0;
    final scale = animating && !_isMagpie ? 1.0 + (wave + 1) * 0.018 : 1.0;
    final asset = _assetFor(t, animating: animating);

    // 호랑이: 프레임 전환(smile↔blink↔idle)을 150ms 크로스페이드로 부드럽게 →
    // 정면↔눈감기 하드컷 끊김 해소. ValueKey(asset)이 바뀔 때만 전환 발동.
    // 까치: 날갯짓이 빠른 교대(~5Hz)라 페이드하면 뭉개짐 → 즉시 교대 유지.
    final framed = (_isMagpie || !animating)
        ? _img(asset)
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _img(asset, key: ValueKey<String>(asset)),
          );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: Transform.scale(scale: scale, child: framed),
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
