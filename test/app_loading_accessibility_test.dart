import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);

  testWidgets('uses one localized live status when no message is supplied', (
    tester,
  ) async {
    final de = await AppL10n.delegate.load(const Locale('de'));
    await tester.pumpWidget(
      _localizedHost(const AppLoading(), locale: de.localeName),
    );

    _expectOneLiveStatus(tester, de.speechIndicatorResolving);
  });

  testWidgets(
    'uses one English localized live status when no message is supplied',
    (tester) async {
      final en = await AppL10n.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        _localizedHost(const AppLoading(), locale: en.localeName),
      );

      _expectOneLiveStatus(tester, en.speechIndicatorResolving);
    },
  );

  testWidgets('uses the explicit message as its only live status', (
    tester,
  ) async {
    const message = 'Ausspracheübungen werden geladen …';
    await tester.pumpWidget(_localizedHost(const AppLoading(message: message)));

    _expectOneLiveStatus(tester, message);
  });

  testWidgets(
    'keeps a long German asset loader safe in a short scaled viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final de = await AppL10n.delegate.load(const Locale('de'));

      await tester.pumpWidget(
        _localizedHost(
          AppLoading(
            message: de.pronunciationPhrasesLoading,
            asset: 'assets/icons/icon-192.png',
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      _expectOneLiveStatus(tester, de.pronunciationPhrasesLoading);
    },
  );

  testWidgets('is safe when an outer scroll view gives it unbounded height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedHost(
        const SingleChildScrollView(child: AppLoading(message: 'Wird geladen')),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not require MediaQuery or localization delegates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppLoading(),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

Widget _localizedHost(
  Widget child, {
  String locale = 'de',
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: textScaler, disableAnimations: true),
    child: app!,
  ),
  home: Scaffold(body: child),
);

void _expectOneLiveStatus(WidgetTester tester, String label) {
  final liveRegions = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.liveRegion == true,
  );
  expect(liveRegions, findsOneWidget);
  expect(tester.getSemantics(liveRegions).getSemanticsData().label, label);
}
