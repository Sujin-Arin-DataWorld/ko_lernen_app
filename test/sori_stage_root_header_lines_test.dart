import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/widgets/sori/collapsing_header.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

import 'support/real_fonts.dart';

/// §LAYOUT-3(J11) — `SoriCollapsingHeader.collapsedTitle` is now `required`;
/// this locks the two budgets that decision depends on:
///
/// 1. The **expanded hero title** (`SoriPageHeader`'s big headline) must fit
///    in ≤3 wrapped lines at 320-390dp (≤4 at the tightest 320dp) — beyond
///    that, `_measureExpandedHeight`'s cell-height budget balloons.
/// 2. The **collapsed 56dp bar title** — always a short `soriStageNav*`
///    label now, never the long hero copy — must stay on its single line
///    (`maxLines: 1`) at 90% of its measured width budget (a hinting-slack
///    margin against sub-pixel/font-loading drift between environments).
///
/// Uses real fonts (`loadSoriRealFonts`) — this is a layout-budget
/// (line-count) assertion, and the default test font's uniform 1em-square
/// glyphs would silently invent wrap points the real Paperlogy/MaruBuri
/// faces don't have.
// §LAYOUT-3(J11): equivalent to `SoriTextTheme.hero`/`.chromeTitle`
// (lib/widgets/sori/tokens.dart) minus the `color:` — layout/line-wrapping
// never depends on color, only on family/size/weight/letterSpacing/height,
// so this avoids needing a BuildContext/SoriSurfaces just to measure.
const _heroStyle = TextStyle(
  fontFamily: SoriFonts.culture,
  fontSize: 36,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.2,
  height: 1.08,
);
final _chromeTitleStyle = TextStyle(
  fontFamily: SoriFonts.sans,
  fontSize: SoriTypeSpecs.chromeTitle.size,
  fontWeight: SoriTypeSpecs.chromeTitle.weight,
  letterSpacing: SoriTypeSpecs.chromeTitle.letterSpacing,
  height: SoriTypeSpecs.chromeTitle.height,
);

void main() {
  setUpAll(loadSoriRealFonts);

  const widths = [320.0, 360.0, 390.0];

  final rows =
      <
        ({
          String root,
          String Function(AppL10nDe) deTitle,
          String Function(AppL10nEn) enTitle,
          String Function(AppL10nDe) deNav,
          String Function(AppL10nEn) enNav,
          int trailingSlots,
        })
      >[
        (
          root: 'Learn',
          deTitle: (t) => t.soriStageLearnTitle,
          enTitle: (t) => t.soriStageLearnTitle,
          deNav: (t) => t.soriStageNavLearn,
          enNav: (t) => t.soriStageNavLearn,
          trailingSlots: 1,
        ),
        (
          root: 'Games',
          deTitle: (t) => t.soriStageGamesTitle,
          enTitle: (t) => t.soriStageGamesTitle,
          deNav: (t) => t.soriStageNavGames,
          enNav: (t) => t.soriStageNavGames,
          trailingSlots: 1,
        ),
        (
          root: 'Hanok',
          deTitle: (t) => t.soriStageHanokTitle,
          enTitle: (t) => t.soriStageHanokTitle,
          deNav: (t) => t.soriStageNavHanok,
          enNav: (t) => t.soriStageNavHanok,
          trailingSlots: 1,
        ),
        (
          root: 'Gye',
          deTitle: (t) => t.soriStageGyePromise,
          enTitle: (t) => t.soriStageGyePromise,
          deNav: (t) => t.soriStageNavGye,
          enNav: (t) => t.soriStageNavGye,
          // §W-G G5.2 (D4 확정): trailing = CulturalHelpButton + SoriAvatar,
          // both 48dp — sori_stage_gye_screen.dart:69.
          trailingSlots: 2,
        ),
      ];

  test('root hero titles wrap within budget and nav labels fit one line', () {
    final de = AppL10nDe();
    final en = AppL10nEn();
    final table = StringBuffer(
      'root  locale  width  titleLines  navFits\n',
    );
    final failures = <String>[];

    for (final row in rows) {
      for (final width in widths) {
        for (final locale in const ['de', 'en']) {
          final title = locale == 'de' ? row.deTitle(de) : row.enTitle(en);
          final navLabel = locale == 'de' ? row.deNav(de) : row.enNav(en);

          final heroTextWidth = SoriCollapsingHeader.expandedTextWidth(
            crossAxisExtent: width - 2 * 20, // Spacing.page.left/right
            hasTrailing: true,
            trailingSlots: row.trailingSlots,
          );
          final heroPainter = TextPainter(
            text: TextSpan(text: title, style: _heroStyle),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: heroTextWidth);
          final titleLines = heroPainter.computeLineMetrics().length;
          heroPainter.dispose();

          final lineBudget = width <= 320 ? 4 : 3;
          if (titleLines > lineBudget) {
            failures.add(
              '${row.root} $locale @ ${width.toInt()}dp: hero title wraps '
              'to $titleLines lines (budget $lineBudget) — "$title"',
            );
          }

          final navTextWidth =
              SoriCollapsingHeader.expandedTextWidth(
                crossAxisExtent: width - 2 * 20,
                hasTrailing: true,
                trailingSlots: row.trailingSlots,
              ) *
              0.9;
          final navPainter = TextPainter(
            text: TextSpan(
              text: navLabel,
              style: _chromeTitleStyle,
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: navTextWidth);
          final navFits = !navPainter.didExceedMaxLines;
          navPainter.dispose();
          if (!navFits) {
            failures.add(
              '${row.root} $locale @ ${width.toInt()}dp: collapsed nav '
              'label "$navLabel" overflows its single line at 90% of '
              '${navTextWidth.toStringAsFixed(1)}px',
            );
          }

          table.writeln(
            '${row.root.padRight(6)}$locale     ${width.toInt()}    '
            '$titleLines           $navFits',
          );
        }
      }
    }

    printOnFailure(table.toString());
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
