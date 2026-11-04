import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/scenario.dart';
import '../../services/scene_asset_resolver.dart';
import 'approved_chrome_assets.dart';
import 'c_gallery/c_materials.dart';
import 'c_learning_surface.dart' show SoriCLearningFonts;
import 'learning_stage_navigation.dart';
import 'pressable.dart';
import 'study_frame.dart';
import 'tokens.dart';
import 'tts_speed_control.dart';

/// Presentation tokens for the approved Alltagsszenen folded-paper scenes.
/// The original materials remain independent art; every word/action is native.
abstract final class ScenarioC {
  // The original 2172px paper slices need half-size edges below these
  // component dimensions, so punctuation tiles retain an interior plane.
  // These are material geometry, independent of the screen breakpoint.
  static const foldCompactEdgeWidth = 40.0;
  static const foldCompactEdgeHeight = 72.0;
  static const tileCompactEdgeWidth = 60.0;
  // Approved 402dp catalog: the level label occupies 138dp beside the grid.
  // The row stacks whenever this leaves less than a 48dp target per column.
  static const levelFilterLabelWidth = 138.0;
  static const kitchenScene = 'a2_minho_weekend_cooking_plan';
  static const kitchen = 'design_assets/scenarios/kitchen-stage.png';
  static const fold = 'design_assets/scenarios/fold-paper.png';
  static const book = 'design_assets/scenarios/open-book.png';
  static const plaque = 'design_assets/scenarios/jade-plaque.png';
  static const gold = 'design_assets/scenarios/gold-button.png';
  static const wordTile = 'design_assets/scenarios/word-tile.png';
  static const answerTray = 'design_assets/scenarios/answer-tray.png';
  static const writingBoard = 'design_assets/scenarios/writing-board.png';
  static const ink = Color(0xff29251f);
  static const muted = Color(0xff665c4d);
  static const jade = Color(0xff174d43);
  static const brass = Color(0xffd5aa5f);
  static const paper = Color(0xfff6edde);
  static const heading = TextStyle(
    fontFamily: SoriCLearningFonts.heading,
    fontFamilyFallback: [SoriFonts.korean],
    fontSize: 25,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: SoriCLearningFonts.body,
    fontFamilyFallback: [SoriFonts.korean],
    fontSize: 16,
    height: 1.35,
    color: ink,
  );
  static const korean = TextStyle(
    fontFamily: SoriFonts.korean,
    fontSize: 22,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static String title(AppL10n t) => t.soriStageActivityTitle('scenarios');
}

/// Opt-in only: shared quest engines keep their existing appearance elsewhere.
class ScenarioCTheme extends InheritedWidget {
  const ScenarioCTheme({super.key, required super.child});
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScenarioCTheme>() != null;
  @override
  bool updateShouldNotify(ScenarioCTheme oldWidget) => false;
}

class ScenarioCBackground extends StatelessWidget {
  const ScenarioCBackground({
    super.key,
    required this.child,
    this.wooden = false,
  });
  final Widget child;
  final bool wooden;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: CTexture(wooden ? CMaterial.oak : CMaterial.paper),
      ),
      child,
    ],
  );
}

class ScenarioCFold extends StatelessWidget {
  const ScenarioCFold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 32),
    this.onTap,
    this.semanticLabel,
    this.semanticValue,
    this.accent,
    this.minHeight = 0,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticValue;
  final Color? accent;
  final double minHeight;
  @override
  Widget build(BuildContext context) {
    final panel = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (_, box) {
                // Small punctuation tiles need narrower original edges too.
                final scale =
                    box.maxWidth < ScenarioC.foldCompactEdgeWidth ||
                        box.maxHeight < ScenarioC.foldCompactEdgeHeight
                    ? 16.0
                    : 8.0;
                return Image.asset(
                  ScenarioC.fold,
                  scale: scale,
                  centerSlice: Rect.fromLTRB(
                    132 / scale,
                    102 / scale,
                    2076 / scale,
                    564 / scale,
                  ),
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                );
              },
            ),
          ),
          if (accent != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: accent!, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    if (onTap == null) return panel;
    return Semantics(
      button: true,
      label: semanticLabel,
      value: semanticValue,
      onTap: onTap,
      child: SoriPressable(
        onTap: onTap,
        pressScale: 1,
        pressOffsetY: 2,
        child: panel,
      ),
    );
  }
}

/// Original raised ivory/gold word material. Interaction stays in the engine.
class ScenarioCWordTile extends StatelessWidget {
  const ScenarioCWordTile({super.key, required this.child, this.accent});
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) => _ScenarioCSlicedMaterial(
    asset: ScenarioC.wordTile,
    slice: const Rect.fromLTRB(160, 120, 2010, 580),
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
    minHeight: 48,
    accent: accent,
    child: child,
  );
}

/// Jade-edged assembly plane, separate from the folded source prompt.
class ScenarioCAnswerTray extends StatelessWidget {
  const ScenarioCAnswerTray({
    super.key,
    required this.child,
    this.accent,
    this.minHeight = 88,
  });
  final Widget child;
  final Color? accent;
  final double minHeight;

  @override
  Widget build(BuildContext context) => _ScenarioCSlicedMaterial(
    asset: ScenarioC.answerTray,
    slice: const Rect.fromLTRB(132, 108, 2040, 610),
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
    minHeight: minHeight,
    accent: accent,
    child: SizedBox(width: double.infinity, child: child),
  );
}

class ScenarioCWritingBoard extends StatelessWidget {
  const ScenarioCWritingBoard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => _ScenarioCSlicedMaterial(
    asset: ScenarioC.writingBoard,
    slice: const Rect.fromLTRB(160, 140, 1614, 747),
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
    minHeight: 0,
    child: child,
  );
}

class _ScenarioCSlicedMaterial extends StatelessWidget {
  const _ScenarioCSlicedMaterial({
    required this.asset,
    required this.slice,
    required this.padding,
    required this.minHeight,
    required this.child,
    this.accent,
  });
  final String asset;
  final Rect slice;
  final EdgeInsets padding;
  final double minHeight;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minWidth: 48, minHeight: minHeight),
    child: Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (_, box) {
              final scale = box.maxWidth < ScenarioC.tileCompactEdgeWidth
                  ? 16.0
                  : 8.0;
              return Image.asset(
                asset,
                scale: scale,
                centerSlice: Rect.fromLTRB(
                  slice.left / scale,
                  slice.top / scale,
                  slice.right / scale,
                  slice.bottom / scale,
                ),
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              );
            },
          ),
        ),
        if (accent != null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 11),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: accent!, width: 2)),
                ),
              ),
            ),
          ),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

class ScenarioCSpeakerBadge extends StatelessWidget {
  const ScenarioCSpeakerBadge({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: CAtlasArt(
          path: ScenarioC.plaque,
          region: Rect.fromLTWH(0, .25, 1, .48),
          fit: BoxFit.fill,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 5, 14, 7),
        child: Text(
          name,
          style: ScenarioC.heading.copyWith(
            fontSize: 13,
            color: ScenarioC.paper,
          ),
        ),
      ),
    ],
  );
}

class ScenarioCSpeedControl extends StatelessWidget {
  const ScenarioCSpeedControl({super.key});

  @override
  Widget build(BuildContext context) => TtsSpeedControl(
    minInteractiveHeight: 48,
    compactBuilder: (context, label, openPresetSheet) => ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
      child: ScenarioCFold(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        minHeight: 48,
        semanticLabel: '${AppL10n.of(context).ttsSpeedLabel}: $label',
        onTap: openPresetSheet,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 28),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: ExcludeSemantics(
              child: Text(label, style: ScenarioC.body.copyWith(fontSize: 14)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Visual replay target; the containing prompt retains the single tap owner.
class ScenarioCAudioDisc extends StatelessWidget {
  const ScenarioCAudioDisc({super.key, this.icon = Icons.volume_up_rounded});
  final IconData icon;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ScenarioC.paper,
        border: Border.all(color: ScenarioC.brass),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22665c4d),
            offset: Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Icon(icon, color: ScenarioC.muted),
    ),
  );
}

class ScenarioCGoldButton extends StatelessWidget {
  const ScenarioCGoldButton({
    super.key,
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: SoriPressable(
        onTap: onTap,
        pressScale: 1,
        pressOffsetY: 2,
        child: Opacity(
          opacity: onTap == null ? .5 : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 56,
              minWidth: double.infinity,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: CAtlasArt(
                    path: ScenarioC.gold,
                    region: Rect.fromLTWH(.012, .235, .975, .52),
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ScenarioC.heading.copyWith(fontSize: 21),
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

class ScenarioCPlaque extends StatelessWidget {
  const ScenarioCPlaque({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: CAtlasArt(
          path: ScenarioC.plaque,
          region: Rect.fromLTWH(0, .25, 1, .48),
          fit: BoxFit.fill,
        ),
      ),
      SizedBox(width: double.infinity, child: child),
    ],
  );
}

class ScenarioCHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScenarioCHeader({
    super.key,
    required this.title,
    required this.leading,
    required this.home,
    required this.width,
    required this.textScaler,
    this.progressLabel,
  });
  final String title;
  final Widget leading;
  final Widget home;
  final double width;
  final TextScaler textScaler;
  final String? progressLabel;
  double get _plaqueHeight {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: ScenarioC.heading.copyWith(fontSize: 23),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: (width - 132).clamp(80, 800));
    return (painter.height + 22).clamp(62, double.infinity);
  }

  @override
  Size get preferredSize => Size.fromHeight(_plaqueHeight + 10 + _brandHeight);
  double get _brandHeight => progressLabel == null
      ? 24
      : (textScaler.scale(13) * 1.35 + 4).clamp(24, double.infinity);
  @override
  Widget build(BuildContext context) => ScenarioCBackground(
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: ScenarioCPlaque(
                child: SizedBox(
                  height: _plaqueHeight,
                  child: Row(
                    children: [
                      SizedBox(width: 48, height: 48, child: leading),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: ScenarioC.heading.copyWith(
                            fontSize: 23,
                            color: ScenarioC.paper,
                          ),
                        ),
                      ),
                      SizedBox(width: 48, height: 48, child: home),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _brandHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ApprovedChromeImage(
                    asset: ApprovedChromeAssets.cloud,
                    size: 20,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'HANGUL SORI',
                    textScaler: TextScaler.noScaling,
                    style: ScenarioC.body.copyWith(
                      fontSize: 13,
                      color: ScenarioC.jade,
                    ),
                  ),
                  if (progressLabel != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      progressLabel!,
                      style: ScenarioC.body.copyWith(
                        fontSize: 13,
                        color: ScenarioC.jade,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The cooking scene owns this setting. Other scenes retain their real poster.
class ScenarioCHero extends StatelessWidget {
  const ScenarioCHero({
    super.key,
    required this.scenario,
    required this.height,
    this.people = false,
  });
  final Scenario scenario;
  final double height;
  final bool people;
  @override
  Widget build(BuildContext context) {
    if (scenario.id != ScenarioC.kitchenScene) {
      final poster = SceneAssetResolver.posterAsset(scenario);
      return poster == null
          ? const SizedBox.shrink()
          : SizedBox(
              height: height,
              width: double.infinity,
              child: Image.asset(
                poster,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            );
    }
    return SizedBox(
      key: ValueKey('scenario-kitchen-hero-${height.toInt()}'),
      height: height,
      child: LayoutBuilder(
        builder: (_, box) {
          final scale = box.maxWidth / 402;
          final large = height > 220;
          final medium = height > 150;
          final personWidth = large
              ? 300.0
              : medium
              ? 230.0
              : 220.0;
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(ScenarioC.kitchen, fit: BoxFit.cover),
                ),
                if (people) ...[
                  for (var i = 0; i < 2; i++)
                    Positioned(
                      left:
                          (large
                              ? (i == 0 ? -45 : 150)
                              : medium
                              ? (i == 0 ? -10 : 170)
                              : (i == 0 ? -25 : 175)) *
                          scale,
                      top: -8,
                      width: personWidth * scale,
                      height: personWidth * 1.5 * scale,
                      child: Image.asset(
                        'assets/illustrations/personas/v3/${i == 0 ? 'minho' : 'andrea'}.png',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: large || medium ? 54 : 26,
                    child: const CAtlasArt(
                      path: ScenarioC.kitchen,
                      region: Rect.fromLTWH(0, .74, 1, .26),
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class ScenarioCDivider extends StatelessWidget {
  const ScenarioCDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(child: Divider(color: ScenarioC.brass)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.filter_vintage, size: 14, color: ScenarioC.brass),
        ),
        Expanded(child: Divider(color: ScenarioC.brass)),
      ],
    ),
  );
}

class ScenarioCWritingLines extends CustomPainter {
  const ScenarioCWritingLines();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffc7b18f)
      ..strokeWidth = .6;
    for (var y = 58.0; y < size.height - 24; y += 29) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(ScenarioCWritingLines oldDelegate) => false;
}

class ScenarioCFrame extends StatelessWidget {
  const ScenarioCFrame({
    super.key,
    required this.title,
    required this.child,
    this.onLeave,
    this.onLeaveOwnsNavigation = false,
    this.onDestinationSelected,
    this.wooden = false,
    this.padding = EdgeInsets.zero,
  });
  final String title;
  final Widget child;
  final VoidCallback? onLeave;
  final bool onLeaveOwnsNavigation;
  final ValueChanged<int>? onDestinationSelected;
  final bool wooden;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => ScenarioCTheme(
    child: SoriStudyFrame(
      title: title,
      onLeave: onLeave,
      onLeaveOwnsNavigation: onLeaveOwnsNavigation,
      padding: padding,
      leadingVisual: const SizedBox.square(
        dimension: 48,
        child: Icon(Icons.chevron_left, color: ScenarioC.paper, size: 32),
      ),
      homeContent: const ApprovedChromeImage(
        asset: 'design_assets/hoeren/home-c-v1.png',
        size: 44,
      ),
      headerBuilder: (context, leading, actions) => ScenarioCHeader(
        title: title,
        leading: leading,
        home: actions.first,
        width: MediaQuery.sizeOf(context).width,
        textScaler: MediaQuery.textScalerOf(context),
      ),
      backgroundBuilder: (_, body) =>
          ScenarioCBackground(wooden: wooden, child: body),
      bottomNavigationBar: SoriLearningStageNavigation(
        onLeave: onLeave,
        onDestinationSelected: onDestinationSelected,
      ),
      child: child,
    ),
  );
}
