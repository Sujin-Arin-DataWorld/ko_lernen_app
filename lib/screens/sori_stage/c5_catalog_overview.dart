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
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(16) > 20;
    final compact = !large && maxHeight != null && maxHeight! < 440;
    final gap = compact ? 2.0 : 4.0;
    final tileHeight = compact ? 68.0 : 104.0;
    final fonts = SoriLocaleFonts.of(context);
    final labelStyle = SoriTextTheme.of(context).body.copyWith(
      fontSize: 16,
      height: 1.1,
      color: CPalette.ink,
      fontWeight: fonts.bodyWeight(FontWeight.w500),
    );
    Widget label(String value) => Text(
      value.replaceAll('Tageschallenge', 'Tages\u00adchallenge'),
      textAlign: TextAlign.center,
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
        padding: EdgeInsets.symmetric(horizontal: 3, vertical: large ? 8 : 1),
        child: horizontal || large
            ? Row(
                children: [
                  SizedBox.square(dimension: large ? 64 : 32, child: item.art),
                  const SizedBox(width: 4),
                  Expanded(child: label(item.label)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: compact ? 24 : 56, child: item.art),
                  const SizedBox(height: 2),
                  label(item.label),
                ],
              ),
      ),
    );
    final children = <Widget>[
      if (!games)
        large
            ? Column(
                children: [
                  for (final (i, text) in steps.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          _StepNumber(i + 1),
                          const SizedBox(width: 8),
                          Expanded(child: label(text)),
                        ],
                      ),
                    ),
                ],
              )
            : SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, text) in steps.indexed)
                      Expanded(
                        child: Column(
                          children: [
                            _StepNumber(i + 1),
                            const SizedBox(height: 3),
                            label(text),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      if (!games) SizedBox(height: gap),
      if (!large && maxHeight != null)
        Expanded(child: _hero())
      else
        SizedBox(height: games ? 180 : 150, child: _hero()),
      if (games) ...[
        SizedBox(height: gap),
        Text(
          heroLabel,
          textAlign: TextAlign.center,
          style: SoriTextTheme.of(context).h2.copyWith(
            fontSize: 24,
            height: compact ? 1.0 : 1.2,
            color: CPalette.ink,
          ),
        ),
        SizedBox(height: gap),
        _primary(),
      ] else ...[
        SizedBox(height: gap),
        label(heroLabel),
      ],
      SizedBox(height: gap),
      if (large)
        for (final item in tiles) ...[tile(item), SizedBox(height: gap)]
      else
        for (var i = 0; i < tiles.length; i += games ? 3 : 2) ...[
          SizedBox(
            height: tileHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + (games ? 3 : 2); j++) ...[
                  if (j > i) const SizedBox(width: 4),
                  Expanded(child: tile(tiles[j])),
                ],
              ],
            ),
          ),
          SizedBox(height: gap),
        ],
      if (!games) _primary(),
      if (footer case final item?) tile(item, horizontal: true),
    ];
    final board = CPaperPanel(
      padding: EdgeInsets.all(compact ? 2 : 8),
      child: Column(
        mainAxisSize: maxHeight == null ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: maxHeight == null
          ? board
          : SizedBox(height: maxHeight, child: board),
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
