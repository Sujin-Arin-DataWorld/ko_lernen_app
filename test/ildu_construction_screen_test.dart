import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';
import 'package:ko_lernen_app/screens/hanok_preview_screen.dart';
import 'package:ko_lernen_app/screens/ildu_construction_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:shared_preferences/shared_preferences.dart';

final catalog = IlDuConstructionArtCatalog.fromJson(
  jsonDecode(File(IlDuConstructionArtCatalog.assetPath).readAsStringSync()),
);

Widget app(Widget child, {String language = 'en', double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      routes: {
        '/hanok/construction': (_) =>
            IlDuConstructionScreen(loader: () async => catalog),
      },
      home: child,
    );

Finder key(String value) => find.byKey(ValueKey(value));

Future<void> tapVisible(WidgetTester tester, String name) async {
  if (key(name).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      key(name),
      name == 'ildu-construction-changgo' ||
              name == 'ildu-construction-hyeopmun'
          ? -250
          : 250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(key(name));
  await tester.pumpAndSettle();
  await tester.tap(key(name));
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({'construction-sentinel': 7}),
  );

  for (final language in ['en', 'de']) {
    testWidgets(
      '$language: browse both series to their final with no saved progress',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          app(
            IlDuConstructionScreen(loader: () async => catalog),
            language: language,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<SoriButton>(key('ildu-construction-previous')).onTap,
          isNull,
        );

        for (final series in catalog.series) {
          await tapVisible(tester, 'ildu-construction-${series.id}');
          for (var i = 0; i < series.stages.length; i++) {
            final stage = series.stages[i];
            expect(find.text(stage.title['ko']!), findsOneWidget);
            expect(
              find.text(ilduArtText(stage.title, language)),
              findsOneWidget,
            );
            if (i < series.stages.length - 1) {
              await tapVisible(tester, 'ildu-construction-next');
            }
          }
          expect(
            tester.widget<SoriButton>(key('ildu-construction-next')).onTap,
            isNull,
          );
        }
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), {'construction-sentinel'});
        expect(prefs.getInt('construction-sentinel'), 7);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('choice feedback resets when changing stages and buildings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(IlDuConstructionScreen(loader: () async => catalog)),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, 'ildu-construction-next');
    final stage = catalog.series.first.stages[1];
    await tapVisible(
      tester,
      'ildu-construction-option-${stage.correctOptionId}',
    );
    expect(key('ildu-construction-feedback'), findsOneWidget);
    await tapVisible(tester, 'ildu-construction-next');
    expect(key('ildu-construction-feedback'), findsNothing);
    await tapVisible(tester, 'ildu-construction-changgo');
    expect(find.text('기초 놓기'), findsOneWidget);
    expect(key('ildu-construction-feedback'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog failure has a working retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      app(
        IlDuConstructionScreen(
          loader: () async {
            if (++attempts == 1) {
              throw const FormatException('Unavailable catalog');
            }
            return catalog;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppError), findsOneWidget);
    tester.widget<AppError>(find.byType(AppError)).onRetry!();
    await tester.pumpAndSettle();
    expect(find.text('발 디딜 곳 만들기'), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('German large text stays usable at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        IlDuConstructionScreen(loader: () async => catalog),
        language: 'de',
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, 'ildu-construction-next');
    await tapVisible(tester, 'ildu-construction-changgo');
    await tapVisible(tester, 'ildu-construction-next');
    expect(find.text('기둥 세우기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hanok tab and preview expose the construction page', (
    tester,
  ) async {
    for (final source in [
      const HanokPreviewScreen(),
      const SoriStageHanokScreen(active: false),
    ]) {
      await tester.pumpWidget(app(source));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'hanok-construction-entry');
      expect(find.byType(IlDuConstructionScreen), findsOneWidget);
      expect(find.text('발 디딜 곳 만들기'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    expect(tester.takeException(), isNull);
  });
}
