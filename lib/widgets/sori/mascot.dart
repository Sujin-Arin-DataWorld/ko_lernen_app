import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/canonical_companion_art.dart';
import '../practice_dokkaebi_art.dart';
import 'tokens.dart';
import 'activity_illustration.dart';
import '../../l10n/generated/app_localizations.dart';

/// Sori companions backed by the user's canonical Baekho and Magpie stills.
///
/// The public API stays compatible with the older combined welcome-hero based
/// widget. Callers keep using [Mascot.tiger], [Mascot.magpie], and
/// [Mascot.forSpeaker], while this widget selects the right pose internally.
class Mascot extends StatefulWidget {
  /// Stable Taego identity, presented with the user's canonical Baekho artwork.
  static const String kTigerAsset = CanonicalCompanionArt.baekhoStanding;

  final MascotKind kind;
  final MascotEmotion emotion;
  final double size;

  /// Optional gentle Magpie motion, respecting the existing motion preference.
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
  // Stored Tiger/Magpie identity remains compatible; actual state selects
  // reviewed canonical stills without creating progress or rewards.
  static const _tigerAsset = Mascot.kTigerAsset;

  /// Joy's canonical default posture.
  static const _magpieFront = CanonicalCompanionArt.magpieStanding;

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
    // 호랑이는 정지 한 장 → 티커 불필요. 까치만 애니메이션.
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
      return switch (widget.emotion) {
        MascotEmotion.celebrate ||
        MascotEmotion.surprised => CanonicalCompanionArt.magpieCelebrate,
        MascotEmotion.thinking ||
        MascotEmotion.worry => CanonicalCompanionArt.magpieGuide,
        _ => _magpieFront,
      };
    }
    return switch (widget.emotion) {
      MascotEmotion.thinking ||
      MascotEmotion.worry => CanonicalCompanionArt.baekhoGuide,
      MascotEmotion.sleepy => CanonicalCompanionArt.baekhoSeated,
      _ => _tigerAsset,
    };
  }

  String get _semanticsLabel {
    final kindLabel = _isMagpie ? '까치' : '백호';
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
    final bob = _isMagpie && animating ? wave * widget.size * 0.006 : 0.0;
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
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.pets_outlined,
        color: SoriSurfaces.of(context).textMuted,
        size: size * 0.5,
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

enum SoriCulturalRole { haechi, hahoeMask, dokkaebi }

/// One small cultural figure or object in a meaningful context, separate from
/// the human dialogue cast and their TTS identity. No selection or reward logic.
/// The Hahoe mask is an object beside a neutral activity hint, not a speaker.
class SoriCultureComment extends StatelessWidget {
  const SoriCultureComment({super.key, required this.role});
  final SoriCulturalRole role;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final (asset, name, korean, translation) = switch (role) {
      SoriCulturalRole.haechi => (
        SoriArtwork.haechi,
        t.cultureHaechiName,
        t.cultureHaechiLineKo,
        t.cultureHaechiLine,
      ),
      SoriCulturalRole.hahoeMask => (
        SoriArtwork.hahoeMask,
        t.cultureHahoeMaskName,
        t.cultureHahoeMaskHintKo,
        t.cultureHahoeMaskHint,
      ),
      SoriCulturalRole.dokkaebi => (
        PracticeDokkaebiPose.inviting.asset,
        t.cultureDokkaebiName,
        t.cultureDokkaebiLineKo,
        t.cultureDokkaebiLine,
      ),
    };
    return Row(
      key: ValueKey('culture-comment-${role.name}'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          asset,
          width: 64,
          height: role == SoriCulturalRole.hahoeMask ? 64 : 88,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: type.meta),
              Text(
                korean,
                style: type.body.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: Spacing.xs),
              Text(translation, style: type.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
