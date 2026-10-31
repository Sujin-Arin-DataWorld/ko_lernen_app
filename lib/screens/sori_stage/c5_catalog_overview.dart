import 'dart:math' as math;
import 'package:flutter/material.dart';
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

/// One physical scene and native destinations; the catalog owns every launch.
/// Reviewed C5 composition: Figma 136:304. Large text reflows instead of shrinking.
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
    this.unitMeta,
    this.footer,
    this.maxHeight,
  });
  final bool games;
  final String primaryLabel, heroLabel;
  final String? unitMeta, detailsLabel;
  final Widget hero;
  final VoidCallback? onPrimary, onDetails;
  final List<C5OverviewTile> tiles;
  final C5OverviewTile? footer;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => _content(context, bounds.maxWidth),
  );

  Widget _content(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final large = scaler.scale(16) > 20;
    final short = !large && maxHeight != null && maxHeight! < 490;
    final bounded = !large && !short && maxHeight != null;
    final fonts = SoriLocaleFonts.of(context);
    final labelStyle = SoriTextTheme.of(context).body.copyWith(
      fontSize: 16,
      height: 1.15,
      color: CPalette.ink,
      fontWeight: fonts.bodyWeight(FontWeight.w600),
    );
    String copy(String value) =>
        value.replaceAll('Tageschallenge', 'Tages\u00adchallenge');
    Widget label(String value, {TextAlign align = TextAlign.center}) =>
        Text(copy(value), textAlign: align, style: labelStyle);
    Widget tile(
      C5OverviewTile item, {
      bool horizontal = false,
      double? labelHeight,
    }) => CImageTap(
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
            BoxShadow(color: Color(0xffad8a60), offset: Offset(0, 3)),
            BoxShadow(
              color: Color(0x200d241c),
              offset: Offset(0, 4),
              blurRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: large ? 8 : 4),
        child: horizontal || large
            ? Row(
                children: [
                  SizedBox(
                    width: large ? 80 : 44,
                    height: large ? 72 : 40,
                    child: item.art,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: label(item.label, align: TextAlign.start)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: games ? 64 : 87, child: item.art),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: labelHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: label(item.label),
                    ),
                  ),
                ],
              ),
      ),
    );

    final columns = games ? 3 : 2;
    final contentWidth = math.max(1.0, width - 24);
    final tileWidth = (contentWidth - 8 * (columns - 1)) / columns;
    double rowLabelHeight(int start) {
      var height = 0.0;
      for (var i = start; i < start + columns && i < tiles.length; i++) {
        final painter = TextPainter(
          text: TextSpan(text: copy(tiles[i].label), style: labelStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          locale: Localizations.localeOf(context),
        )..layout(maxWidth: math.max(1.0, tileWidth - 8));
        height = math.max(height, painter.height);
        painter.dispose();
      }
      return height;
    }

    final art = SizedBox(
      height: math.min(
        contentWidth / (games ? 1579 / 996 : 2),
        short ? 150.0 : 225.0,
      ),
      child: _hero(context),
    );
    final title = Text(
      heroLabel,
      style: SoriTextTheme.of(context).h2.copyWith(
        fontSize: games ? 24 : 20,
        height: 1.15,
        color: CPalette.ink,
      ),
    );
    final children = <Widget>[
      if (!games) ...[
        if (unitMeta case final meta?) ...[
          Text(meta, style: labelStyle.copyWith(color: CPalette.deepJade)),
          const SizedBox(height: 4),
        ],
        title,
        const SizedBox(height: 4),
      ],
      if (bounded) Flexible(fit: FlexFit.loose, child: art) else art,
      const SizedBox(height: 4),
      if (games) ...[title, const SizedBox(height: 8)],
      if (games || short || large) ...[_primary(), const SizedBox(height: 8)],
      if (large)
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          tile(tiles[i]),
        ]
      else
        for (var i = 0; i < tiles.length; i += columns) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = i; j < i + columns && j < tiles.length; j++) ...[
                if (j > i) const SizedBox(width: 8),
                Expanded(child: tile(tiles[j], labelHeight: rowLabelHeight(i))),
              ],
            ],
          ),
        ],
      if (!games && !short && !large) ...[
        const SizedBox(height: 8),
        _primary(),
      ],
      if (footer case final item?) ...[
        const SizedBox(height: 8),
        tile(item, horizontal: true),
      ],
    ];
    final panel = CPaperPanel(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: bounded
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight!),
              child: panel,
            )
          : panel,
    );
  }

  Widget _hero(BuildContext context) => Stack(
    key: const ValueKey('c5-overview-hero'),
    fit: StackFit.expand,
    children: [
      hero,
      if (games && onDetails != null)
        Positioned(
          top: 0,
          right: 0,
          child: CImageTap(
            key: const ValueKey('c5-overview-details'),
            label: detailsLabel!,
            onTap: onDetails,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CPalette.paper,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: CPalette.fineEdge),
                boxShadow: const [
                  BoxShadow(color: Color(0xffad8a60), offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                detailsLabel!,
                style: SoriTextTheme.of(context).body.copyWith(
                  fontSize: 16,
                  height: 1.15,
                  color: CPalette.ink,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _primary() => CMaterialAction(
    key: ValueKey(games ? 'c5-game-start' : 'c5-course-start'),
    gold: games,
    label: primaryLabel,
    onTap: onPrimary,
  );
}
