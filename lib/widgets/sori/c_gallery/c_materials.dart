import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pressable.dart';
import 'c_objects.dart';
import 'c_palette.dart';

export 'c_palette.dart';

/// Concept C material vocabulary. No legacy card, eaves, accent rail or nav skin.

enum CMaterial { jade, paper, oak, brass }

enum CScene { coffee, book, syllables, studyTogether }

/// Decorative objects from the approved C board. Labels and actions are native.
/// The entire original is retained unchanged; only object regions are painted.
enum CReferencePart {
  cloudLogo2,
  headerLeaves,
  coin,
  settings,
  coffee,
  book,
  words,
  listening,
  hangul,
  review,
  goldArrow,
  greenArrow,
  secondaryArrow,
  lanterns,
  studyTogether,
  hanokHero,
}

class CReferenceArt extends StatelessWidget {
  const CReferenceArt(this.part, {super.key, this.fit = BoxFit.contain});
  final CReferencePart part;
  final BoxFit fit;
  static const path = 'assets/illustrations/concept_c/reference_objects.png';
  static final _pixels = <CReferencePart, Rect>{
    CReferencePart.cloudLogo2: const Rect.fromLTWH(58, 137, 29, 26),
    CReferencePart.headerLeaves: const Rect.fromLTWH(58, 218, 116, 51),
    CReferencePart.coin: const Rect.fromLTWH(219, 141, 27, 27),
    CReferencePart.settings: const Rect.fromLTWH(301, 139, 28, 30),
    CReferencePart.coffee: const Rect.fromLTWH(62, 370, 268, 130),
    CReferencePart.book: const Rect.fromLTWH(382, 311, 272, 130),
    CReferencePart.words: const Rect.fromLTWH(394, 452, 116, 85),
    CReferencePart.listening: const Rect.fromLTWH(527, 452, 114, 85),
    CReferencePart.hangul: const Rect.fromLTWH(391, 578, 115, 76),
    CReferencePart.review: const Rect.fromLTWH(532, 575, 110, 79),
    CReferencePart.goldArrow: const Rect.fromLTWH(295, 513, 16, 22),
    CReferencePart.greenArrow: const Rect.fromLTWH(294, 637, 18, 22),
    CReferencePart.secondaryArrow: const Rect.fromLTWH(625, 742, 14, 18),
    CReferencePart.lanterns: const Rect.fromLTWH(1367, 541, 221, 76),
    CReferencePart.studyTogether: const Rect.fromLTWH(1338, 239, 279, 215),
    CReferencePart.hanokHero: const Rect.fromLTWH(1018, 218, 278, 229),
  };

  @override
  Widget build(BuildContext context) {
    final r = _pixels[part]!;
    return CAtlasArt(
      path: path,
      region: Rect.fromLTWH(
        r.left / 1672,
        r.top / 941,
        r.width / 1672,
        r.height / 941,
      ),
      fit: fit,
    );
  }
}

/// The complete decorative Hanok scene from the user-approved C mockup.
/// Its source bytes and authored roof/trees/stairs stay together. All surrounding
/// titles, progress, balance and actions are native Flutter elements.
class CHanokScene extends StatelessWidget {
  const CHanokScene({super.key});

  static const aspectRatio = 278 / 229;

  @override
  Widget build(BuildContext context) => const AspectRatio(
    aspectRatio: aspectRatio,
    child: CReferenceArt(CReferencePart.hanokHero),
  );
}

abstract final class CImageCache {
  static final _images = <String, Future<ui.Image>>{};

  static Future<ui.Image> load(String path) => _images.putIfAbsent(
    path,
    () async {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    },
  );
}

/// Render atlas regions as art only. Text, focus and touch remain native widgets.
class CAtlasArt extends StatelessWidget {
  const CAtlasArt({
    super.key,
    required this.path,
    required this.region,
    this.fit = BoxFit.cover,
    this.opacity = 1,
  });

  final String path;
  final Rect region;
  final BoxFit fit;
  final double opacity;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FutureBuilder<ui.Image>(
      future: CImageCache.load(path),
      builder: (_, snapshot) => snapshot.hasData
          ? CustomPaint(
              painter: _AtlasPainter(snapshot.data!, region, fit, opacity),
              size: Size.infinite,
            )
          : const SizedBox.expand(),
    ),
  );
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter(this.image, this.region, this.fit, this.opacity);
  final ui.Image image;
  final Rect region;
  final BoxFit fit;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      region.left * image.width,
      region.top * image.height,
      region.width * image.width,
      region.height * image.height,
    );
    final fitted = applyBoxFit(fit, source.size, size);
    final crop = Alignment.center.inscribe(fitted.source, source);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      crop,
      destination,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_AtlasPainter old) =>
      old.image != image ||
      old.region != region ||
      old.fit != fit ||
      old.opacity != opacity;
}

class CTexture extends StatelessWidget {
  const CTexture(this.material, {super.key, this.opacity = 1});
  final CMaterial material;
  final double opacity;

  @override
  Widget build(BuildContext context) => CAtlasArt(
    path: 'assets/illustrations/concept_c/material_atlas.png',
    region: Rect.fromLTWH(
      material.index % 2 * .5,
      material.index ~/ 2 * .5,
      .5,
      .5,
    ),
    opacity: opacity,
  );
}

class CSceneArt extends StatelessWidget {
  const CSceneArt(
    this.scene, {
    super.key,
    required this.height,
    this.radius = 8,
  });
  final CScene scene;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final referenceWidth = scene == CScene.studyTogether ? 370 : 346;
      final scaledHeight = height * constraints.maxWidth / referenceWidth;
      final reference = switch (scene) {
        CScene.coffee => CReferencePart.coffee,
        CScene.book => null,
        CScene.studyTogether => CReferencePart.studyTogether,
        CScene.syllables => null,
      };
      final aspect = switch (scene) {
        CScene.coffee => 268 / 130,
        CScene.book => 272 / 130,
        CScene.studyTogether => 279 / 215,
        CScene.syllables => 1.5,
      };
      return SizedBox(
        height: scaledHeight.clamp(0, constraints.maxWidth / aspect),
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: scene == CScene.book
              ? const CObjectArt(CObject.book)
              : reference != null
              ? CReferenceArt(reference)
              : CAtlasArt(
                  path: 'assets/illustrations/concept_c/hero_atlas.png',
                  fit: BoxFit.contain,
                  region: Rect.fromLTWH(
                    scene.index % 2 * .5,
                    scene.index ~/ 2 * .5,
                    .5,
                    .5,
                  ),
                ),
        ),
      );
    },
  );
}

class CGameObject extends StatelessWidget {
  const CGameObject(this.index, {super.key, this.size = 92});
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CAtlasArt(
      path: 'assets/illustrations/concept_c/game_object_atlas.png',
      region: Rect.fromLTWH(index % 3 / 3, index ~/ 3 / 2, 1 / 3, 1 / 2),
      fit: BoxFit.contain,
    ),
  );
}

enum CGameReferencePart {
  hero,
  firstSounds,
  cloze,
  pairs,
  sentence,
  wordChain,
  yourWords,
}

/// Art from the games mock explicitly selected by the user. Source bytes stay
/// intact; the gallery's status bar, labels and buttons are never painted.
class CGameReferenceArt extends StatelessWidget {
  const CGameReferenceArt(this.part, {super.key});

  final CGameReferencePart part;
  static const path = 'assets/illustrations/concept_c/games_reference.png';
  static const labelRepairPath =
      'assets/illustrations/concept_c/games_label_repair.png';
  static const heroAspectRatio = 332 / 220;
  static const _pixels = <CGameReferencePart, Rect>{
    CGameReferencePart.hero: Rect.fromLTWH(1257, 277, 332, 220),
    CGameReferencePart.firstSounds: Rect.fromLTWH(1270, 547, 86, 66),
    CGameReferencePart.cloze: Rect.fromLTWH(1372, 548, 96, 69),
    CGameReferencePart.pairs: Rect.fromLTWH(1490, 547, 86, 67),
    CGameReferencePart.sentence: Rect.fromLTWH(1267, 654, 164, 49),
    CGameReferencePart.wordChain: Rect.fromLTWH(1463, 653, 108, 51),
    CGameReferencePart.yourWords: Rect.fromLTWH(1268, 735, 101, 53),
  };

  @override
  Widget build(BuildContext context) {
    final r = _pixels[part]!;
    final art = CAtlasArt(
      path: path,
      region: Rect.fromLTWH(
        r.left / 1672,
        r.top / 941,
        r.width / 1672,
        r.height / 941,
      ),
      fit: BoxFit.contain,
    );
    if (part != CGameReferencePart.hero) return art;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(clipper: const _CGameLabelsClipper(), child: art),
          Positioned(
            left: constraints.maxWidth * 237 / 332,
            top: 0,
            width: constraints.maxWidth * 95 / 332,
            height: constraints.maxHeight * 46 / 220,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0, 6 / 46, 1 - 6 / 46, 1],
              ).createShader(bounds),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 6 / 95, 1 - 6 / 95, 1],
                ).createShader(bounds),
                child: const CAtlasArt(
                  path: labelRepairPath,
                  region: Rect.fromLTWH(
                    1494 / 1672,
                    277 / 941,
                    95 / 1672,
                    46 / 941,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Native localization replaces the baked title. Only the former preview label
/// receives a restored garden patch; all character and object pixels stay in
/// the original source.
class _CGameLabelsClipper extends CustomClipper<Path> {
  const _CGameLabelsClipper();

  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & size),
    Path()..addRect(
      Rect.fromLTWH(
        0,
        size.height * 193 / 220,
        size.width * 165 / 332,
        size.height * 27 / 220,
      ),
    ),
  );

  @override
  bool shouldReclip(_CGameLabelsClipper oldClipper) => false;
}

class CPaperPanel extends StatelessWidget {
  const CPaperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 14,
    this.raised = true,
    this.surfaceTexture,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool raised;
  final Widget? surfaceTexture;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: CPalette.paper,
      border: Border.all(color: CPalette.fineEdge),
      boxShadow: [
        BoxShadow(
          color: const Color(0xffbfa27d),
          offset: Offset(0, raised ? 3 : 2),
          blurRadius: 0,
        ),
        BoxShadow(
          color: const Color(0x330d241c),
          offset: Offset(0, raised ? 5 : 3),
          blurRadius: raised ? 8 : 3,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius - 1),
      child: Stack(
        children: [
          Positioned.fill(
            child:
                surfaceTexture ?? const CTexture(CMaterial.paper, opacity: .55),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x55ffffff), Color(0x0982522f)],
                ),
                border: Border(
                  top: BorderSide(color: Color(0xbbfffdf4), width: 1.2),
                  left: BorderSide(color: Color(0x88fffdf4), width: 1),
                ),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    ),
  );
}

class CMaterialAction extends StatefulWidget {
  const CMaterialAction({
    super.key,
    required this.label,
    required this.onTap,
    this.gold = true,
    this.compact = false,
    this.selected = false,
    this.child,
    this.surfaceTexture,
  });
  final String label;
  final VoidCallback? onTap;
  final bool gold;
  final bool compact;
  final bool selected;
  final Widget? child;
  final Widget? surfaceTexture;

  @override
  State<CMaterialAction> createState() => _CMaterialActionState();
}

class _CMaterialActionState extends State<CMaterialAction> {
  bool pressed = false;

  Widget actionText() => Text(
    widget.label,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'Paperlogy',
      fontSize: widget.compact ? 16 : 21,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: widget.gold ? CPalette.ink : CPalette.paper,
    ),
  );

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      child: SoriPressable(
        haptic: null,
        pressScale: .99,
        surfaceDepth: 4,
        surfaceRadius: 9,
        surfaceEdgeColor: widget.gold
            ? const Color(0xff875620)
            : const Color(0xff0a332c),
        onTap: widget.onTap,
        onPressedChanged: (value) => setState(() => pressed = value),
        child: AnimatedContainer(
          width: widget.compact ? null : double.infinity,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 120),
          constraints: BoxConstraints(
            minWidth: 48,
            minHeight: widget.compact ? 48 : 54,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: widget.gold ? CPalette.brass : CPalette.jade,
            border: Border.all(
              color: widget.gold
                  ? const Color(0xfff2d79c)
                  : const Color(0xffd4bc80),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x490e251d),
                offset: Offset(0, pressed ? 1 : 5),
                blurRadius: pressed ? 1 : 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child:
                      widget.surfaceTexture ??
                      CTexture(
                        widget.gold ? CMaterial.brass : CMaterial.jade,
                        opacity: widget.gold ? .85 : .82,
                      ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: .30),
                          Colors.transparent,
                          Colors.black.withValues(alpha: .18),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: ExcludeSemantics(
                    child:
                        widget.child ??
                        (widget.compact
                            ? actionText()
                            : Row(
                                children: [
                                  Expanded(child: actionText()),
                                  if (!widget.compact) ...[
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 18,
                                      height: 24,
                                      child: CArrow(dark: widget.gold),
                                    ),
                                  ],
                                ],
                              )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CImageTap extends StatelessWidget {
  const CImageTap({
    super.key,
    required this.label,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      container: true,
      button: true,
      label: label,
      selected: selected,
      enabled: onTap != null,
      onTap: onTap,
      onLongPress: onLongPress,
      child: SoriPressable(
        pressScale: .99,
        surfaceDepth: child is CPaperPanel ? 2 : 0,
        surfaceRadius: child is CPaperPanel
            ? (child as CPaperPanel).radius
            : 10,
        surfaceEdgeColor: const Color(0xffb79a73),
        haptic: null,
        onTap: onTap,
        onLongPress: onLongPress,
        child: ExcludeSemantics(child: child),
      ),
    ),
  );
}
