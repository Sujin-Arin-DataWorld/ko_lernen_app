import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/sori/button.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/tokens.dart';

class C5OverviewTile {
  const C5OverviewTile({
    required this.key,
    required this.label,
    required this.art,
    required this.onTap,
  });
  final Key key;
  final String label;
  final Widget art;
  final VoidCallback? onTap;
}

/// Native reflow of the approved C5 book/steps or hero/six-object composition.
/// The account/catalog screen supplies every label and action.
class C5CatalogOverview extends StatelessWidget {
  const C5CatalogOverview({
    super.key,
    required this.games,
    required this.primaryLabel,
    required this.heroLabel,
    required this.hero,
    required this.onPrimary,
    required this.tiles,
    this.detailsLabel,
    this.onDetails,
    this.steps = const [],
    this.footer,
    this.maxHeight,
  });
  final bool games;
  final String primaryLabel, heroLabel;
  final Widget hero;
  final VoidCallback? onPrimary, onDetails;
  final String? detailsLabel;
  final List<String> steps;
  final List<C5OverviewTile> tiles;
  final C5OverviewTile? footer;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => _content(context, bounds.maxWidth),
  );

  Widget _content(BuildContext context, double width) {
    final large = MediaQuery.textScalerOf(context).scale(16) > 20;
    final compact = !large && maxHeight != null && maxHeight! < 440;
    final compactGame = compact && games;
    final panelInset = compact ? Spacing.xs / 2 : Spacing.xs;
    final rowGap = compact ? Spacing.xs : Spacing.sm;
    final sectionGap = compactGame
        ? Spacing.xs
        : compact
        ? Spacing.sm
        : Spacing.md;
    final actionGap = compactGame ? Spacing.xs : Spacing.sm;
    final heroHeight = math.min(
      large ? 150.0 : 180.0,
      math.max(0, width - Spacing.sm * 2 - panelInset * 2) / 1.5,
    );
    final fonts = SoriLocaleFonts.of(context);
    final labelStyle = SoriTextTheme.of(context).body.copyWith(
      fontSize: 16,
      height: 1.1,
      color: CPalette.ink,
      fontWeight: fonts.bodyWeight(FontWeight.w500),
    );
    Widget label(String value, {TextAlign align = TextAlign.center}) => Text(
      value.replaceAll('Tageschallenge', 'Tages\u00adchallenge'),
      textAlign: align,
      style: labelStyle,
    );
    Widget tile(C5OverviewTile item, {bool horizontal = false}) => CImageTap(
      key: item.key,
      label: item.label,
      onTap: item.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: CPalette.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CPalette.fineEdge),
          boxShadow: const [
            BoxShadow(color: Color(0xffbfa27d), offset: Offset(0, 2)),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: large
              ? Spacing.sm
              : compactGame
              ? 0
              : Spacing.xs,
        ),
        child: horizontal || large
            ? Row(
                children: [
                  SizedBox.square(dimension: large ? 64 : 32, child: item.art),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: label(item.label, align: TextAlign.start)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: compact ? 24 : 48, child: item.art),
                  const SizedBox(height: Spacing.xs),
                  label(item.label),
                ],
              ),
      ),
    );
    final art = SizedBox(height: heroHeight, child: _hero());
    final columns = games ? 3 : 2;
    final children = <Widget>[
      if (!games)
        large
            ? Column(
                children: [
                  for (final (i, text) in steps.indexed) ...[
                    if (i > 0) const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        _StepNumber(i + 1),
                        const SizedBox(width: Spacing.sm),
                        Expanded(child: label(text, align: TextAlign.start)),
                      ],
                    ),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, text) in steps.indexed)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepNumber(i + 1),
                          const SizedBox(height: Spacing.xs),
                          label(text),
                        ],
                      ),
                    ),
                ],
              ),
      if (!games) const SizedBox(height: Spacing.xs),
      if (!large && maxHeight != null)
        Flexible(fit: FlexFit.loose, child: art)
      else
        art,
      const SizedBox(height: Spacing.xs),
      if (games) ...[
        Text(
          heroLabel,
          textAlign: TextAlign.center,
          style: SoriTextTheme.of(context).h2.copyWith(
            fontSize: 24,
            height: compact ? 1.0 : 1.2,
            color: CPalette.ink,
          ),
        ),
        SizedBox(height: compactGame ? Spacing.xs / 2 : Spacing.sm),
        _primary(),
      ] else
        label(heroLabel),
      SizedBox(height: sectionGap),
      if (large)
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          tile(tiles[i]),
        ]
      else
        for (var i = 0; i < tiles.length; i += columns) ...[
          if (i > 0) SizedBox(height: rowGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = i; j < i + columns && j < tiles.length; j++) ...[
                if (j > i) const SizedBox(width: Spacing.sm),
                Expanded(child: tile(tiles[j])),
              ],
            ],
          ),
        ],
      SizedBox(height: actionGap),
      if (!games) _primary(),
      if (footer case final item?) tile(item, horizontal: true),
    ];
    final board = CPaperPanel(
      padding: EdgeInsets.all(panelInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: maxHeight == null
          ? board
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight!),
              child: board,
            ),
    );
  }

  Widget _hero() => Stack(
    key: const ValueKey('c5-overview-hero'),
    fit: StackFit.expand,
    children: [
      hero,
      if (games && onDetails != null)
        Positioned(
          top: 0,
          right: 0,
          child: SoriButton.outlined(
            key: const ValueKey('c5-overview-details'),
            cMaterial: true,
            label: detailsLabel!,
            onTap: onDetails,
          ),
        ),
    ],
  );

  Widget _primary() => SoriButton.filled(
    key: ValueKey(games ? 'c5-game-start' : 'c5-course-start'),
    cMaterial: true,
    fullWidth: true,
    label: primaryLabel,
    onTap: onPrimary,
  );
}

class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number);
  final int number;
  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.textScalerOf(context).scale(16) + 8,
    height: MediaQuery.textScalerOf(context).scale(16) + 8,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: number == 1 ? CPalette.deepJade : CPalette.paper,
      shape: BoxShape.circle,
      border: Border.all(
        color: number == 1 ? CPalette.brass : CPalette.fineEdge,
      ),
    ),
    child: Text(
      '$number',
      style: SoriTextTheme.of(context).body.copyWith(
        fontSize: 16,
        height: 1,
        color: number == 1 ? CPalette.paper : CPalette.ink,
        fontWeight: SoriLocaleFonts.of(context).bodyWeight(FontWeight.w700),
      ),
    ),
  );
}
