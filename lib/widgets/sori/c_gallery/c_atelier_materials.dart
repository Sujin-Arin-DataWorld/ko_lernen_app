import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import '../c_material_assets.dart';
import '../approved_chrome_assets.dart';

/// Tokens measured from the approved 2026-10-10 HTML, not the earlier crops.
abstract final class CAtelier {
  static const wideSurface = 700.0;
  static const compactSurface = 359.0;
  static const root = 'assets/illustrations/concept_c/hangul_atelier/';
  static const goldPlate = 'assets/illustrations/concept_c/craft_gold_cta.png';
  static const jade = Color(0xff174d43);
  static const deep = Color(0xff0e3931);
  static const paper = Color(0xfff6edde);
  static const ink = Color(0xff242c26);
  static const muted = Color(0xff566056);
  static const gold = Color(0xffcfa15c);
  static const edge = Color(0xffc7b18f);
  static TextStyle text(
    BuildContext context,
    double size, {
    bool bold = false,
    Color color = ink,
    bool korean = false,
    double height = 1.4,
  }) {
    final fonts = SoriLocaleFonts.of(context);
    final heading = !korean && bold && size >= 22;
    return TextStyle(
      fontFamily: korean
          ? SoriFonts.learningKorean
          : heading
          ? fonts.heading
          : fonts.body,
      fontFamilyFallback: SoriLocaleFonts.fallback,
      fontSize: size,
      fontWeight: heading
          ? fonts.headingWeight
          : bold
          ? FontWeight.w600
          : FontWeight.w400,
      height: height,
      color: color,
    );
  }

  static Widget art(String name, {double? width, double? height}) =>
      Image.asset(
        switch (name) {
          'cloud' => ApprovedChromeAssets.cloud,
          'settings-gear' => ApprovedChromeAssets.settings,
          'paper-atlas' => SoriCMaterialAssets.paperAtlas,
          _ => '$root$name.png',
        },
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
}

enum CAtelierFace { paper, jade, gold }

/// The Atelier's single public tab chrome; large text keeps the same choices.
class CAtelierTabs extends StatelessWidget {
  const CAtelierTabs({
    super.key,
    required this.children,
    this.vertical = false,
  });
  final List<Widget> children;
  final bool vertical;
  @override
  Widget build(BuildContext context) => CAtelierSurface(
    face: CAtelierFace.jade,
    radius: 14,
    depth: false,
    padding: const EdgeInsets.all(Spacing.xs),
    child: vertical
        ? Column(children: children)
        : Row(children: [for (final child in children) Expanded(child: child)]),
  );
}

/// Exact approved atelier rhythm; scoped here so other learning screens keep
/// their established typography and spacing roles.
abstract final class CAtelierSpacing {
  static const baselineGap = 2.0;
  static const relatedGap = 6.0;
  static const inlayInset = 5.0;
  static const cutoutGutter = 6.0;
}

abstract final class CAtelierType {
  static const controlLabel = 12.0;
}

/// Original material textures and the intact approved gold plate. Each plate
/// is painted once; no border fragments or extra frame are added.
class CAtelierSurface extends StatelessWidget {
  const CAtelierSurface({
    super.key,
    required this.child,
    this.face = CAtelierFace.paper,
    this.radius = 10,
    this.padding = EdgeInsets.zero,
    this.depth = true,
    this.framed = true,
    this.enabled = true,
    this.transparent = false,
  });
  final Widget child;
  final CAtelierFace face;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool depth;
  final bool framed, enabled, transparent;

  @override
  Widget build(BuildContext context) {
    if (transparent) {
      return Padding(padding: padding, child: child);
    }
    if (face == CAtelierFace.gold && enabled) {
      return Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _GoldPlate())),
          Padding(padding: padding, child: child),
        ],
      );
    }
    final colors = !enabled
        ? const [Color(0xffe1ddcf), Color(0xffe1ddcf)]
        : switch (face) {
            CAtelierFace.paper => const [
              Color(0xfffffdf4),
              Color(0xfff8efdf),
              Color(0xffe6d7bd),
            ],
            CAtelierFace.gold => const [
              Color(0xfff5d590),
              Color(0xffd8ac66),
              Color(0xffbd8740),
            ],
            CAtelierFace.jade => const [CAtelier.jade, CAtelier.deep],
          };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: !framed
            ? null
            : Border.all(
                color: face == CAtelierFace.jade
                    ? CAtelier.gold
                    : CAtelier.edge,
              ),
        color: CAtelier.jade,
        gradient: face == CAtelierFace.jade && enabled
            ? null
            : LinearGradient(
                begin: face == CAtelierFace.gold
                    ? const Alignment(-.574, -.819)
                    : const Alignment(-.423, -.906),
                end: face == CAtelierFace.gold
                    ? const Alignment(.574, .819)
                    : const Alignment(.423, .906),
                colors: colors,
                stops: colors.length == 3
                    ? [0, face == CAtelierFace.gold ? .52 : .54, 1]
                    : null,
              ),
        boxShadow: depth
            ? const [
                BoxShadow(color: Color(0xff9c7a4b), offset: Offset(0, 2)),
                BoxShadow(
                  color: Color(0x241c1710),
                  offset: Offset(0, 4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            if (face == CAtelierFace.jade && enabled)
              const Positioned.fill(
                child: IgnorePointer(child: _JadeTexture()),
              ),
            if (face == CAtelierFace.jade && enabled)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-.259, -.966),
                        end: Alignment(.259, .966),
                        colors: [
                          Color(0x10ffffff),
                          Color(0x00ffffff),
                          Color(0x40051c18),
                        ],
                        stops: [0, .48, 1],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// The supplied 2171×724 PNG stays byte-identical. This viewport excludes only
/// transparent padding/noise around the single complete object, including its
/// contact shadow: (96,184)–(2078,540). It never slices/reassembles the frame.
class _GoldPlate extends StatelessWidget {
  const _GoldPlate();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final sx = box.maxWidth / 1982, sy = box.maxHeight / 356;
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 2171 * sx,
          maxWidth: 2171 * sx,
          minHeight: 724 * sy,
          maxHeight: 724 * sy,
          child: Transform.translate(
            offset: Offset(-96 * sx, -184 * sy),
            child: Image.asset(
              CAtelier.goldPlate,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        ),
      );
    },
  );
}

class _JadeTexture extends StatelessWidget {
  const _JadeTexture();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage(SoriCMaterialAssets.jade),
        repeat: ImageRepeat.repeat,
        scale: 1254 / 420,
        alignment: Alignment.center,
      ),
    ),
  );
}

/// The HTML's right/top 200% paper texture, sampled at paint time from the full
/// original. The source file and the texture's pixels remain unmodified.
class CAtelierPaper extends StatelessWidget {
  const CAtelierPaper({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    child: ColoredBox(
      color: CAtelier.paper,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: .58, child: _PaperTexture()),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

class _PaperTexture extends StatelessWidget {
  const _PaperTexture();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => ClipRect(
      child: OverflowBox(
        alignment: Alignment.topRight,
        minWidth: box.maxWidth * 2,
        maxWidth: box.maxWidth * 2,
        minHeight: box.maxHeight * 2,
        maxHeight: box.maxHeight * 2,
        child: Image.asset(SoriCMaterialAssets.paperAtlas, fit: BoxFit.fill),
      ),
    ),
  );
}

class CAtelierButton extends StatefulWidget {
  const CAtelierButton({
    super.key,
    required this.label,
    required this.onTap,
    this.face = CAtelierFace.paper,
    this.fontSize = CAtelierType.controlLabel,
    this.child,
    this.semanticLabel,
    this.selected,
    this.depth = true,
    this.framed = true,
    this.bold,
    this.padding = const EdgeInsets.all(CAtelierSpacing.cutoutGutter),
    this.bare = false,
  });
  final String label;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final CAtelierFace face;
  final double fontSize;
  final Widget? child;
  final bool? selected;
  final bool depth;
  final bool framed;
  final bool bare;
  final bool? bold;
  final EdgeInsetsGeometry padding;
  @override
  State<CAtelierButton> createState() => _CAtelierButtonState();
}

class _CAtelierButtonState extends State<CAtelierButton> {
  bool _pressed = false;
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduced = SoriMotion.reduceMotion(context);
    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SoriRadius.sm),
          border: _focused ? Border.all(color: CAtelier.gold, width: 2) : null,
        ),
        child: Semantics(
          button: true,
          enabled: enabled,
          selected: widget.selected,
          label: widget.semanticLabel ?? widget.label,
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onTapDown: enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedContainer(
                duration: reduced
                    ? Duration.zero
                    : Duration(milliseconds: _pressed ? 110 : 190),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
                child: CAtelierSurface(
                  face: widget.face,
                  enabled: enabled,
                  framed: widget.framed,
                  transparent: widget.bare,
                  radius: 9,
                  depth: widget.depth && !_pressed,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Padding(
                      padding: widget.face == CAtelierFace.gold && enabled
                          ? widget.padding.add(
                              const EdgeInsets.only(
                                bottom: CAtelierSpacing.relatedGap,
                              ),
                            )
                          : widget.padding,
                      child: Center(
                        child:
                            widget.child ??
                            Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: CAtelier.text(
                                context,
                                widget.fontSize,
                                bold:
                                    widget.bold ??
                                    widget.face == CAtelierFace.jade,
                                color: !enabled
                                    ? const Color(0xff69685f)
                                    : widget.face == CAtelierFace.jade
                                    ? CAtelier.paper
                                    : CAtelier.ink,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bare image controls share native focus/activation without adding a frame.
class CAtelierTouch extends StatefulWidget {
  const CAtelierTouch({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<CAtelierTouch> createState() => _CAtelierTouchState();
}

class _CAtelierTouchState extends State<CAtelierTouch> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    onShowFocusHighlight: (value) => setState(() => _focused = value),
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          widget.onTap();
          return null;
        },
      ),
    },
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: _focused ? Border.all(color: CAtelier.gold, width: 2) : null,
        borderRadius: BorderRadius.circular(SoriRadius.xs),
      ),
      child: widget.child,
    ),
  );
}

class CAtelierSpeaker extends StatelessWidget {
  const CAtelierSpeaker({
    super.key,
    this.width = 64,
    this.height = 40,
    this.playing = false,
  });
  final double width, height;
  final bool playing;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: playing && !SoriMotion.reduceMotion(context) ? 1.045 : 1),
    duration: const Duration(milliseconds: 180),
    builder: (context, scale, child) => Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: playing && !SoriMotion.reduceMotion(context) ? -.025 : 0,
        child: child,
      ),
    ),
    child: CAtelier.art('speaker', width: width, height: height),
  );
}

/// Consistent single-column phone and two-column tablet content ownership.
class CAtelierColumns extends StatelessWidget {
  const CAtelierColumns({
    super.key,
    required this.visual,
    required this.controls,
    this.phoneGap = 4,
    this.tablet = false,
  });
  final Widget visual, controls;
  final double phoneGap;
  final bool tablet;
  @override
  Widget build(BuildContext context) =>
      tablet && MediaQuery.textScalerOf(context).scale(1) < 1.5
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 11, child: visual),
            const SizedBox(width: Spacing.lg),
            Expanded(flex: 10, child: controls),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            visual,
            SizedBox(height: math.max(0, phoneGap)),
            controls,
          ],
        );
}
