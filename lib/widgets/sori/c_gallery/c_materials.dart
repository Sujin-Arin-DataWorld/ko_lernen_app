import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pressable.dart';
import '../tokens.dart';
import 'c_objects.dart';
import 'c_palette.dart';
import 'c5_scene_assets.dart';

export 'c_palette.dart';
export 'c5_scene_assets.dart';

/// Concept C material vocabulary. No legacy card, eaves, accent rail or nav skin.

enum CMaterial { jade, paper, oak, brass }

enum CScene { coffee, book, syllables, studyTogether }

/// Decorative objects from independent originals. Labels and actions are native.
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
  const CReferenceArt(
    this.part, {
    super.key,
    this.fit = BoxFit.contain,
    this.opticalFit = false,
  });
  final CReferencePart part;
  final BoxFit fit;
  final bool opticalFit;
  @override
  Widget build(BuildContext context) {
    if (opticalFit &&
        const {
          CReferencePart.listening,
          CReferencePart.hangul,
          CReferencePart.review,
        }.contains(part)) {
      return CAtlasArt(
        path: switch (part) {
          CReferencePart.listening => C5SceneAssets.speaker,
          CReferencePart.hangul => C5SceneAssets.hangul,
          _ => C5SceneAssets.review,
        },
        region: switch (part) {
          CReferencePart.listening => C5SceneAssets.speakerRegion,
          CReferencePart.hangul => C5SceneAssets.hangulRegion,
          _ => C5SceneAssets.reviewRegion,
        },
        fit: fit,
      );
    }
    final object = switch (part) {
      CReferencePart.cloudLogo2 => CObject.cloud,
      CReferencePart.coin => CObject.coin,
      CReferencePart.settings => CObject.settings,
      CReferencePart.words => CObject.book,
      CReferencePart.goldArrow ||
      CReferencePart.greenArrow ||
      CReferencePart.secondaryArrow => CObject.arrow,
      CReferencePart.lanterns => CObject.lantern,
      _ => null,
    };
    if (object != null) {
      return CObjectArt(object, fit: fit);
    }
    final scene = switch (part) {
      CReferencePart.coffee => CScene.coffee,
      CReferencePart.studyTogether => CScene.studyTogether,
      _ => null,
    };
    if (scene != null) {
      return _CSceneImage(scene, fit: fit);
    }
    final path = switch (part) {
      CReferencePart.headerLeaves =>
        'assets/illustrations/concept_c/games/silben_plant.png',
      CReferencePart.book => C5SceneAssets.book,
      CReferencePart.listening => C5SceneAssets.speaker,
      CReferencePart.hangul => C5SceneAssets.hangul,
      CReferencePart.review => C5SceneAssets.review,
      CReferencePart.hanokHero =>
        'assets/illustrations/personal_hanok_v3/world/sarangchae.png',
      _ => throw StateError('No independent artwork for $part'),
    };
    return Image.asset(
      path,
      fit: fit,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.high,
    );
  }
}

/// The canonical building artwork is independent of presentation mockups.
class CHanokScene extends StatelessWidget {
  const CHanokScene({super.key});
  static const aspectRatio = 278 / 229;
  @override
  Widget build(BuildContext context) => const AspectRatio(
    aspectRatio: aspectRatio,
    child: CReferenceArt(CReferencePart.hanokHero),
  );
}

// Dedicated original scene sheet (four complete illustrations, no UI).
class _CSceneImage extends StatelessWidget {
  const _CSceneImage(this.scene, {this.fit = BoxFit.contain});
  final CScene scene;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => CAtlasArt(
    path: 'assets/illustrations/concept_c/hero_atlas.png',
    region: Rect.fromLTWH(scene.index % 2 * .5, scene.index ~/ 2 * .5, .5, .5),
    fit: fit,
  );
}

abstract final class CImageCache {
  static final _images = <String, Future<ui.Image>>{};
  static final _decoded = <String, ui.Image>{};

  static ui.Image? peek(String path) => _decoded[path];

  static Future<ui.Image> load(String path) => _images.putIfAbsent(
    path,
    () async {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      _decoded[path] = frame.image;
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
  Widget build(BuildContext context) {
    final ready = CImageCache.peek(path);
    Widget paint(ui.Image image) => CustomPaint(
      painter: _AtlasPainter(image, region, fit, opacity),
      size: Size.infinite,
    );
    return ExcludeSemantics(
      child: ready != null
          ? paint(ready)
          : FutureBuilder<ui.Image>(
              future: CImageCache.load(path),
              builder: (_, snapshot) => snapshot.hasData
                  ? paint(snapshot.data!)
                  : const SizedBox.expand(),
            ),
    );
  }
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
          child: _CSceneImage(scene),
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
  daily,
  firstSounds,
  cloze,
  pairs,
  sentence,
  wordChain,
  yourWords,
}

/// Game illustrations from independently generated scene and object sheets.
class CGameReferenceArt extends StatelessWidget {
  const CGameReferenceArt(this.part, {super.key});
  final CGameReferencePart part;
  static const heroAspectRatio = 332 / 220;

  @override
  Widget build(BuildContext context) {
    if (part == CGameReferencePart.hero) {
      return Image.asset(
        C5SceneAssets.syllables,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        filterQuality: FilterQuality.high,
      );
    }
    if (part == CGameReferencePart.yourWords) {
      return Image.asset(
        'assets/illustrations/concept_c/games-own-words-brush.png',
        fit: BoxFit.contain,
      );
    }
    final index = switch (part) {
      CGameReferencePart.daily => 0,
      CGameReferencePart.firstSounds => 1,
      CGameReferencePart.cloze => 2,
      CGameReferencePart.pairs => 3,
      CGameReferencePart.sentence => 4,
      CGameReferencePart.wordChain => 5,
      CGameReferencePart.yourWords => 2,
      CGameReferencePart.hero => 0,
    };
    return CAtlasArt(
      path: 'assets/illustrations/concept_c/game_object_atlas.png',
      region: Rect.fromLTWH(index % 3 / 3, index ~/ 3 / 2, 1 / 3, 1 / 2),
      fit: BoxFit.contain,
    );
  }
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
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
  });
  final String label;
  final VoidCallback? onTap;
  final bool gold;
  final bool compact;
  final bool selected;
  final Widget? child;
  final Widget? surfaceTexture;
  final EdgeInsets contentPadding;

  @override
  State<CMaterialAction> createState() => _CMaterialActionState();
}

class _CMaterialActionState extends State<CMaterialAction>
    with WidgetsBindingObserver {
  bool pressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) pressed = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(() => pressed = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Duration get _feedbackDuration =>
      TickerMode.valuesOf(context).enabled &&
          (WidgetsBinding.instance.lifecycleState == null ||
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed)
      ? SoriMotion.respect(context, SoriMotion.fast)
      : Duration.zero;

  @override
  void didUpdateWidget(covariant CMaterialAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A keyboard action can disable itself before key-up reaches the control.
    // Release the material face along with the underlying press animation.
    if (widget.onTap == null) {
      pressed = false;
    }
  }

  Widget actionText() => Text(
    widget.label,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: SoriLocaleFonts.of(context).body,
      fontFamilyFallback: SoriLocaleFonts.fallback,
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
          duration: _feedbackDuration,
          curve: SoriMotion.gentle,
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
                      (widget.gold
                          ? const CAtlasArt(
                              path: C5SceneAssets.goldAction,
                              region: C5SceneAssets.goldRegion,
                              fit: BoxFit.fill,
                            )
                          : const CTexture(CMaterial.jade, opacity: .82)),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: _feedbackDuration,
                    curve: SoriMotion.gentle,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: pressed ? .14 : .30),
                          Colors.transparent,
                          Colors.black.withValues(alpha: pressed ? .24 : .18),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: widget.contentPadding,
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
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: 0,
                                        end:
                                            pressed &&
                                                !SoriMotion.reduceMotion(
                                                  context,
                                                )
                                            ? 2
                                            : 0,
                                      ),
                                      duration: _feedbackDuration,
                                      curve: SoriMotion.gentle,
                                      builder: (_, value, child) =>
                                          Transform.translate(
                                            key: const ValueKey(
                                              'c-material-cta-direction',
                                            ),
                                            offset: Offset(value, 0),
                                            child: child,
                                          ),
                                      child: SizedBox(
                                        width: 18,
                                        height: 24,
                                        child: CArrow(dark: widget.gold),
                                      ),
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
