import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/companion_art.dart';
import 'activity_illustration.dart';
import 'tokens.dart';
import 'c_gallery/c_palette.dart';

/// Sori mascot widget backed by separated tiger and magpie pose PNGs.
///
/// The public API stays compatible with the older combined welcome-hero based
/// widget. Callers keep using [Mascot.tiger], [Mascot.magpie], and
/// [Mascot.forSpeaker], while this widget selects the right pose internally.
class Mascot extends StatefulWidget {
  /// 호랑이 마스코트 정지 한 장. **잠금 자산** — 바꾸려면
  /// `test/mascot_asset_lock_test.dart` 를 먼저 고쳐야 한다(Jin 2026-08-25).
  static const String kTigerAsset = CompanionArt.taego;

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

/// Approved static poses remain steady while the learner reads or listens.
class _MascotState extends State<Mascot> {
  @override
  Widget build(BuildContext context) {
    final magpie = widget.kind == MascotKind.magpie;
    final id = magpie ? 'magpie' : 'tiger';
    final t = AppL10n.of(context);
    final asset = widget.size <= 64
        ? CompanionArt.portrait(id)
        : widget.emotion == MascotEmotion.thinking ||
              widget.emotion == MascotEmotion.worry
        ? CompanionArt.guide(id)
        : magpie && widget.emotion == MascotEmotion.celebrate
        ? CompanionArt.joyCelebrate
        : !magpie && widget.emotion == MascotEmotion.sleepy
        ? CompanionArt.taegoSeated
        : CompanionArt.fullBody(id);
    return Semantics(
      image: true,
      label: magpie ? t.characterRomanMagpie : t.characterRomanTiger,
      excludeSemantics: true,
      child: Image.asset(
        asset,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context))
            .ceil(),
        errorBuilder: (_, __, ___) =>
            _Fallback(kind: widget.kind, size: widget.size),
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
    final color = SoriSurfaces.of(context).textMuted;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        isMagpie ? Icons.flutter_dash : Icons.pets_outlined,
        size: size * .5,
        color: color,
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
  const SoriCultureComment({
    super.key,
    required this.role,
    this.conceptC = false,
  });
  final SoriCulturalRole role;
  final bool conceptC;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    TextStyle style(TextStyle value) => conceptC ? cMaterialText(value) : value;
    final (asset, name, korean, translation) = switch (role) {
      SoriCulturalRole.haechi => (
        CompanionArt.dokkaebi,
        t.cultureDokkaebiName,
        t.cultureDokkaebiLineKo,
        t.cultureDokkaebiLine,
      ),
      SoriCulturalRole.hahoeMask => (
        SoriArtwork.hahoeMask,
        t.cultureHahoeMaskName,
        t.cultureHahoeMaskHintKo,
        t.cultureHahoeMaskHint,
      ),
      SoriCulturalRole.dokkaebi => (
        SoriArtwork.dokkaebi,
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
          height: 88,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: style(type.meta)),
              Text(
                korean,
                style: style(type.body.copyWith(fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: Spacing.xs),
              Text(translation, style: style(type.bodySmall)),
            ],
          ),
        ),
      ],
    );
  }
}
