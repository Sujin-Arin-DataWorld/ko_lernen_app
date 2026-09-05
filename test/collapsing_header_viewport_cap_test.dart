import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/collapsing_header.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

import 'support/real_fonts.dart';

/// Regression test for the viewport-cap fix in
/// `lib/widgets/sori/collapsing_header.dart` (W10 T-H4, 2026-09-05,
/// `listening_screen.dart` bug repro): a pinned [SoriCollapsingHeader] whose
/// *natural* (uncapped) expanded height reaches the scroll viewport's own
/// height starves every sliver painted after it — the pinned header eats the
/// whole frame and the rest of the `CustomScrollView` never lays out.
/// `expandedHeight` is now clamped to 60% of `viewportMainAxisExtent` (floor
/// `kToolbarHeight`) to guard against exactly that.
///
/// This locks both directions:
/// 1. At the reproduction size (320dp width, 200% text, a moderately long
///    body) the cap actually engages, and the sliver after the header still
///    gets laid out.
/// 2. At an ordinary size (390x844, 100% text) the cap leaves the header's
///    real measured height untouched — zero visual change for the common
///    case.
///
/// Uses real fonts (`loadSoriRealFonts`) — this is a layout-budget (height)
/// assertion, and the default test font's uniform 1em-square glyphs would
/// invent wrap points the real Paperlogy/MaruBuri faces don't have, which
/// would make the "control" case unreliable (§W-F3, `test/support/real_fonts.dart`).
void main() {
  setUpAll(loadSoriRealFonts);

  const eyebrow = 'TEST';
  const title = 'Cap Test';
  const collapsedTitle = 'Cap';
  const longBody =
      'Diese lange Beschreibung testet, ob die Kopfzeile beim Aufklappen so '
      'hoch werden kann, dass sie ohne die Sechzig-Prozent-Deckelung den '
      'gesamten sichtbaren Bereich einnehmen und die nachfolgenden Inhalte '
      'am Layout hindern würde.';

  Widget harness({required double textScale}) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          const SoriCollapsingHeader(
            eyebrow: eyebrow,
            title: title,
            body: longBody,
            collapsedTitle: collapsedTitle,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(key: Key('after'), height: 40),
          ),
        ],
      ),
    ),
  );

  /// Replays `SoriCollapsingHeader._measureExpandedHeight`'s (private)
  /// TextPainter recipe to get the *uncapped* natural height for comparison
  /// — using the widget's own exposed `expandedTextWidth` for the
  /// text-width budget so the two can't silently drift apart.
  double measureNaturalHeight(BuildContext context, double crossAxisExtent) {
    final tt = SoriTextTheme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final locale = Localizations.localeOf(context);
    final textWidth = SoriCollapsingHeader.expandedTextWidth(
      crossAxisExtent: crossAxisExtent,
      hasTrailing: false,
    );

    double lineHeight(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        locale: locale,
      )..layout(maxWidth: textWidth);
      final measured = painter.height;
      painter.dispose();
      return measured;
    }

    return lineHeight(eyebrow, tt.eyebrow) +
        Spacing.xs +
        lineHeight(title, tt.hero) +
        Spacing.sm +
        lineHeight(longBody, tt.body);
  }

  testWidgets(
    '320dp + 200% 글자: 헤더가 뷰포트 60%로 눌리고 뒤 슬리버가 레이아웃을 받는다',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(textScale: 2.0));
      await tester.pumpAndSettle();

      // Sanity: confirm this scenario actually needs the cap — its natural
      // (uncapped) height really does exceed the 60% budget. Otherwise the
      // assertions below would pass trivially without exercising the clamp.
      final headerContext = tester.element(find.byType(SoriCollapsingHeader));
      final natural = measureNaturalHeight(headerContext, 320);
      expect(natural, greaterThan(480 * 0.6));

      // The bug this guards against: without a cap, the pinned header's
      // maxExtent reaches/exceeds the viewport height and the sliver after
      // it never gets laid out at all (findsNothing).
      final afterFinder = find.byKey(const Key('after'));
      expect(afterFinder, findsOneWidget);
      final afterRect = tester.getRect(afterFinder);
      expect(afterRect.width.isFinite, isTrue);
      expect(afterRect.height.isFinite, isTrue);

      final renderHeader = tester.renderObject<RenderSliver>(
        find.byType(SliverPersistentHeader),
      );
      final headerHeight = renderHeader.geometry!.paintExtent;
      expect(headerHeight, lessThanOrEqualTo(480 * 0.6));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '390x844, 100% 글자: 평범한 크기에서는 상한이 실측 높이를 건드리지 않는다',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(textScale: 1.0));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('after')), findsOneWidget);

      final headerContext = tester.element(find.byType(SoriCollapsingHeader));
      final natural = measureNaturalHeight(headerContext, 390);
      // Confirms this size genuinely sits below the cap, so the equality
      // check below is proof of "cap didn't touch it" and not a coincidence.
      expect(natural, lessThan(844 * 0.6));

      final renderHeader = tester.renderObject<RenderSliver>(
        find.byType(SliverPersistentHeader),
      );
      final headerHeight = renderHeader.geometry!.paintExtent;
      expect(headerHeight, closeTo(natural, 0.5));

      expect(tester.takeException(), isNull);
    },
  );
}
