import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/module_card.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_practice_hub': true,
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  testWidgets(
    'review is the single primary route and zero due stays actionable',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPractice(
        tester,
        locale: const Locale('de'),
        size: const Size(390, 844),
        textScale: 1.3,
        dueCount: 12,
      );

      final review = find.byKey(const ValueKey('practice-purpose-review'));
      expect(review, findsOneWidget);
      expect(
        find.descendant(of: review, matching: find.byType(FeaturedModuleCard)),
        findsOneWidget,
      );
      expect(find.byType(FeaturedModuleCard), findsOneWidget);
      expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
      final reviewSemantics = tester.getSemantics(review).getSemanticsData();
      expect(reviewSemantics.flagsCollection.isButton, isTrue);
      expect(reviewSemantics.hasAction(ui.SemanticsAction.tap), isTrue);

      await _pumpPractice(
        tester,
        locale: const Locale('en'),
        size: const Size(390, 844),
        textScale: 1.3,
        dueCount: 0,
      );
      await _scrollPageTo(
        tester,
        find.byKey(const ValueKey('practice-purpose-review')),
      );
      expect(find.text('Open a review whenever you want'), findsOneWidget);
      expect(find.text('No words are waiting for context'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'DE and EN keep the complete purpose hierarchy at every viewport',
    (tester) async {
      const viewports = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];

      for (final locale in const [Locale('de'), Locale('en')]) {
        for (final viewport in viewports) {
          await _pumpPractice(
            tester,
            locale: locale,
            size: viewport.size,
            textScale: viewport.textScale,
            dueCount: 12,
          );
          final t = AppL10n.of(tester.element(find.byType(PracticeHubScreen)));

          expect(find.text(t.practiceTitle), findsOneWidget);
          expect(find.text(t.practiceSubtitle), findsOneWidget);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('practice-purpose-review')),
            260,
            scrollable: _pageScrollable,
          );
          expect(find.text(t.practiceDueTitle), findsOneWidget);
          expect(find.text(t.practiceSecLearn), findsOneWidget);
          expect(find.text(t.practiceSecGames), findsOneWidget);
          expect(find.text(t.practiceWordsPurposeTitle), findsOneWidget);

          final allActivities = find.byKey(
            const ValueKey('practice-all-activities'),
          );
          await tester.scrollUntilVisible(
            allActivities,
            260,
            scrollable: _pageScrollable,
          );
          expect(allActivities, findsOneWidget);
          expect(
            tester.getSize(allActivities).height,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'purpose sheets and expanded word tools keep destinations reachable',
    (tester) async {
      for (final locale in const [Locale('de'), Locale('en')]) {
        await _pumpPractice(
          tester,
          locale: locale,
          size: const Size(320, 640),
          textScale: 2,
          dueCount: 12,
        );
        final t = AppL10n.of(tester.element(find.byType(PracticeHubScreen)));

        await _openPurpose(tester, const ValueKey('practice-purpose-focused'));
        expect(find.text(t.moduleHangulTitle), findsOneWidget);
        await _scrollSheetTo(tester, find.text(t.homeBookCardTitle));
        expect(find.text(t.homeBookCardTitle), findsOneWidget);
        await _closeSheet(tester);

        await _openPurpose(tester, const ValueKey('practice-purpose-free'));
        expect(find.text(t.dailyTitle), findsOneWidget);
        await _scrollSheetTo(tester, find.text(t.homeSmalltalkCardTitle));
        expect(find.text(t.homeSmalltalkCardTitle), findsOneWidget);
        await _closeSheet(tester);

        await _showAllActivities(tester);
        await _scrollPageTo(tester, find.text(t.vocabNotebookTitle));
        expect(find.text(t.vocabNotebookTitle), findsOneWidget);
        await _scrollPageTo(tester, find.text(t.wordWebTitle));
        expect(find.text(t.wordWebTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'all-activity cards reflow at narrow large text and pair when wide',
    (tester) async {
      await _pumpPractice(
        tester,
        locale: const Locale('de'),
        size: const Size(320, 640),
        textScale: 2,
        dueCount: 12,
      );
      var t = AppL10n.of(tester.element(find.byType(PracticeHubScreen)));
      await _showAllActivities(tester);
      expect(find.byType(FeaturedModuleCard), findsOneWidget);

      final narrowGrammar = _moduleCardWithTitle(t.moduleGrammarTitle);
      await tester.scrollUntilVisible(
        narrowGrammar,
        300,
        scrollable: _pageScrollable,
      );
      expect(tester.getSize(narrowGrammar).width, greaterThan(240));
      final narrowScenarios = _moduleCardWithTitle(t.moduleScenariosTitle);
      await tester.scrollUntilVisible(
        narrowScenarios,
        300,
        scrollable: _pageScrollable,
      );
      expect(tester.getSize(narrowScenarios).width, greaterThan(240));
      expect(tester.takeException(), isNull);

      await _pumpPractice(
        tester,
        locale: const Locale('en'),
        size: const Size(1280, 900),
        textScale: 1.3,
        dueCount: 12,
      );
      t = AppL10n.of(tester.element(find.byType(PracticeHubScreen)));
      await _showAllActivities(tester);
      expect(find.byType(FeaturedModuleCard), findsOneWidget);
      final wideGrammar = _moduleCardWithTitle(t.moduleGrammarTitle);
      await tester.scrollUntilVisible(
        wideGrammar,
        300,
        scrollable: _pageScrollable,
      );
      final wideScenarios = _moduleCardWithTitle(t.moduleScenariosTitle);
      expect(
        tester.getTopLeft(wideGrammar).dx,
        isNot(tester.getTopLeft(wideScenarios).dx),
      );
      expect(
        tester.getTopLeft(wideGrammar).dy,
        tester.getTopLeft(wideScenarios).dy,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _moduleCardWithTitle(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ModuleCard));

// W10 PR-D(2026-09-06): 페이지가 `SoriStandardPage(fill: true)` 로 바뀌며
// 본문 스크롤이 `ListView` 가 아니라 `SoriMinHeightScroll` 이 만드는
// `SingleChildScrollView` 다(연습 허브 접힌 상태 세로 중앙 정렬 수정). 시트는
// `SoriStandardFrame` 바깥(별도 라우트)이라 이 파인더는 시트의 `ListView`
// 를 절대 집지 않는다.
Finder get _pageScrollable => find.descendant(
  of: find.byType(SoriStandardFrame),
  matching: find.byType(Scrollable),
);

Finder get _sheetScrollable => find.descendant(
  of: find.byType(ListView).last,
  matching: find.byType(Scrollable),
);

Future<void> _showAllActivities(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('practice-all-activities'));
  await tester.scrollUntilVisible(button, 260, scrollable: _pageScrollable);
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
}

Future<void> _openPurpose(WidgetTester tester, ValueKey<String> key) async {
  final target = find.byKey(key);
  final viewHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (var i = 0; i < 12; i++) {
    if (target.evaluate().isNotEmpty) {
      final center = tester.getCenter(target);
      if (center.dy >= 0 && center.dy <= viewHeight) {
        break;
      }
    }
    await tester.drag(_pageScrollable, const Offset(0, -260));
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _scrollSheetTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 260, scrollable: _sheetScrollable);
  await tester.pump();
}

Future<void> _closeSheet(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(ListTile).first)).pop();
  await tester.pumpAndSettle();
}

Future<void> _scrollPageTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 260, scrollable: _pageScrollable);
  await tester.pump();
}

Future<void> _pumpPractice(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required double textScale,
  required int dueCount,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: child!),
        );
      },
      home: PracticeHubScreen.preview(
        key: ValueKey(
          'practice-${locale.languageCode}-${size.width}-${size.height}'
          '-$textScale-$dueCount',
        ),
        previewDueCount: dueCount,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
