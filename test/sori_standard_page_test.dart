import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/page_header.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:ko_lernen_app/widgets/sori/window_class.dart';

void main() {
  testWidgets(
    'standard page keeps DE and EN content reachable across the responsive matrix',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      for (final size in const [
        Size(320, 640),
        Size(360, 400),
        Size(390, 844),
        Size(720, 1024),
        Size(1280, 900),
      ]) {
        for (final locale in const [Locale('de'), Locale('en')]) {
          for (final textScale in const [1.0, 1.3, 1.6, 2.0]) {
            tester.view.physicalSize = size;
            var taps = 0;
            final copy = _copyFor(locale);

            await tester.pumpWidget(
              _host(
                locale: locale,
                textScale: textScale,
                child: SoriStandardPage(
                  key: ValueKey(
                    '${size.width}-${size.height}-${locale.languageCode}-$textScale',
                  ),
                  appBarTitle: copy.appBar,
                  eyebrow: copy.eyebrow,
                  headline: copy.headline,
                  description: copy.description,
                  maxWidth: SoriMaxWidth.hub,
                  children: [
                    const SizedBox(
                      key: Key('standard-page-column-width'),
                      width: double.infinity,
                      height: 420,
                    ),
                    SoriButton.filled(
                      key: const Key('standard-page-last-action'),
                      label: copy.action,
                      onTap: () => taps += 1,
                    ),
                  ],
                ),
              ),
            );
            await tester.pump();

            expect(find.byType(SoriAppBar), findsOneWidget);
            expect(find.byType(SoriScreenBackground), findsOneWidget);
            expect(find.byType(SoriPageHeader), findsOneWidget);
            expect(find.text(copy.headline), findsOneWidget);
            expect(find.text(copy.description), findsOneWidget);
            expect(tester.takeException(), isNull);

            final headingData = tester
                .getSemantics(find.text(copy.headline))
                .getSemanticsData();
            expect(headingData.flagsCollection.isHeader, isTrue);

            final columnMarker = find.byKey(
              const Key('standard-page-column-width'),
            );
            await tester.scrollUntilVisible(
              columnMarker,
              240,
              scrollable: find.byType(Scrollable).first,
            );
            final contentWidth = tester.getSize(columnMarker).width;
            expect(contentWidth, lessThanOrEqualTo(SoriMaxWidth.hub));
            expect(contentWidth, greaterThan(0));

            final action = find.byKey(const Key('standard-page-last-action'));
            await tester.scrollUntilVisible(
              action,
              240,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.drag(
              find.byType(ListView),
              Offset(0, -size.height * 3),
            );
            await tester.pumpAndSettle();

            final actionRect = tester.getRect(action);
            final viewportRect = tester.getRect(find.byType(ListView));
            final matrixLabel =
                '${size.width}x${size.height} ${locale.languageCode} ${textScale}x '
                'rect=$actionRect';
            expect(
              actionRect.center.dy,
              greaterThanOrEqualTo(viewportRect.top),
              reason: matrixLabel,
            );
            expect(
              actionRect.bottom,
              lessThanOrEqualTo(viewportRect.bottom),
              reason: matrixLabel,
            );
            await tester.tap(action);
            await tester.pump();
            expect(taps, 1);
            expect(tester.takeException(), isNull);
          }
        }
      }
      semantics.dispose();
    },
  );
}

Widget _host({
  required Locale locale,
  required double textScale,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
      return MediaQuery(
        data: media.copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: child,
  );
}

({
  String appBar,
  String eyebrow,
  String headline,
  String description,
  String action,
})
_copyFor(Locale locale) {
  if (locale.languageCode == 'de') {
    return (
      appBar: 'Entdecken',
      eyebrow: 'Dein Lernweg',
      headline: 'Finde genau, was du heute brauchst.',
      description:
          'Scannen, nachschlagen, hören oder eine kleine Pause machen.',
      action: 'Mit meinem nächsten Lernschritt weitermachen',
    );
  }
  return (
    appBar: 'Discover',
    eyebrow: 'Your learning path',
    headline: 'Find exactly what you need today.',
    description: 'Scan, look up, listen, or take a short learning break.',
    action: 'Continue with my next learning step',
  );
}
