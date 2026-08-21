import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/spotlight_coach.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _seed({'kl_tut_learningPath': true});
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets(
        'Path keeps one complete hierarchy in ${locale.languageCode} @ '
        '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
        '×${viewport.textScale}',
        (tester) async {
          _configureView(tester, viewport.size);
          await tester.pumpWidget(
            _host(
              locale: locale,
              textScale: viewport.textScale,
              child: _preview(),
            ),
          );
          await tester.pump();

          final context = tester.element(find.byType(LearningPathScreen));
          final t = AppL10n.of(context);
          final type = SoriTextTheme.of(context);
          final frame = tester.widget<SoriStandardFrame>(
            find.byType(SoriStandardFrame),
          );
          expect(frame.appBarTitle, t.pathTitle);

          final jump = find.widgetWithIcon(
            IconButton,
            Icons.my_location_rounded,
          );
          expect(jump, findsOneWidget);
          expect(tester.widget<IconButton>(jump).tooltip, t.pathJumpToNow);
          expect(tester.widget<IconButton>(jump).onPressed, isNull);
          expect(tester.getSize(jump).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(jump).height, greaterThanOrEqualTo(48));

          _expectTextRole(tester, t.pathStoryEyebrow('A1'), type.label);
          _expectTextRole(tester, t.pathStoryTitle, type.h1);
          _expectTextRole(tester, t.pathStoryBody, type.bodySmall);

          for (final id in const ['a1_01', 'a1_02', 'a1_03']) {
            final row = find.byKey(ValueKey('path-course-row-$id'));
            expect(row, findsOneWidget);
            expect(
              find.descendant(of: row, matching: find.byType(SoriCard)),
              findsOneWidget,
            );
          }

          final current = find.byKey(const ValueKey('path-current-mission'));
          await tester.scrollUntilVisible(
            current,
            240,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(current);
          await tester.pump();
          final currentButton = tester.widget<SoriButton>(current);
          expect(currentButton.label, t.pathOpenCurrentMission);
          expect(currentButton.maxLines, isNull);
          expect(tester.getSize(current).height, greaterThanOrEqualTo(48));

          final legacy = find.byKey(
            const ValueKey('path-legacy-practice-toggle'),
          );
          await tester.scrollUntilVisible(
            legacy,
            240,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(legacy);
          await tester.pump();
          final legacyButton = tester.widget<SoriButton>(legacy);
          expect(legacyButton.label, t.pathShowMorePractice);
          expect(legacyButton.maxLines, isNull);
          expect(tester.getSize(legacy).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Path legacy card uses shared type roles in ${locale.languageCode}',
      (tester) async {
        _configureView(tester, const Size(390, 844));
        await tester.pumpWidget(
          _host(locale: locale, textScale: 1.3, child: _preview()),
        );
        await tester.pump();

        final context = tester.element(find.byType(LearningPathScreen));
        final t = AppL10n.of(context);
        final type = SoriTextTheme.of(context);
        final toggle = find.byKey(
          const ValueKey('path-legacy-practice-toggle'),
        );
        await tester.scrollUntilVisible(toggle, 300);
        await tester.ensureVisible(toggle);
        await tester.pump();
        await tester.tap(toggle);
        await tester.pump();

        _expectTextRole(tester, t.pathHanokStage(1), type.h3);
        _expectTextRole(tester, t.pathHanokSub, type.bodySmall);
        _expectTextRole(tester, t.pathLevelPacks(0, 0), type.meta);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Path jump reveals the current legacy target before scrolling', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    final loaded = await _prewarm(tester);

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        textScale: 1,
        child: LearningPathScreen(
          courseSnapshotLoader: () async =>
              CourseMasteryService(loaded.catalog).readForDisplay(),
        ),
      ),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-legacy-practice-toggle')),
    );
    expect(
      find.byKey(const ValueKey('path-legacy-practice-content')),
      findsNothing,
    );

    final jump = find.widgetWithIcon(IconButton, Icons.my_location_rounded);
    expect(tester.widget<IconButton>(jump).onPressed, isNotNull);
    await tester.tap(jump);
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('path-legacy-practice-content')),
      findsOneWidget,
    );

    final context = tester.element(find.byType(LearningPathScreen));
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final a1Count = loaded.packs.where((pack) => pack.level == 'A1').length;
    _expectTextRole(tester, t.pathLevelPacks(0, a1Count), type.meta);
    expect(tester.takeException(), isNull);
    await _disposeScreen(tester);
  });

  testWidgets('Path route focus reveals and scrolls to the requested pack', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    final loaded = await _prewarm(tester);
    final a1Packs = loaded.packs.where((pack) => pack.level == 'A1').toList();
    final focused = a1Packs.last;

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        textScale: 1,
        routeArguments: focused.id,
        child: LearningPathScreen(
          courseSnapshotLoader: () async =>
              CourseMasteryService(loaded.catalog).readForDisplay(),
        ),
      ),
    );
    final route = ModalRoute.of(
      tester.element(find.byType(LearningPathScreen)),
    );
    expect(route?.settings.arguments, focused.id);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-legacy-practice-content')),
    );
    await tester.pump();

    final label = VocabPackService.displayLabel(focused.id, lang: 'en');
    expect(find.text(label), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
    await _disposeScreen(tester);
  });

  testWidgets('Path coach points to the canonical current course step', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    final initial = await _prewarm(tester);
    final a1Units =
        initial.catalog.courseUnits.where((unit) => unit.level == 'a1').toList()
          ..sort((left, right) => left.order.compareTo(right.order));
    final completed = a1Units.first;
    final current = a1Units[1];
    await _seed({
      Storage.courseMasterySnapshotPreferenceKey: jsonEncode(
        CourseMasterySnapshot(
          placementLevel: 'a1',
          completedUnitIds: [completed.id],
          currentCourseUnitId: current.id,
        ).toJson(),
      ),
      Storage.placementLevelPreferenceKey: 'a1',
      Storage.browseLevelPreferenceKey: 'a1',
    });
    await Storage.resetTutorials();
    await _prewarm(tester);

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        textScale: 1,
        child: LearningPathScreen(
          courseSnapshotLoader: () async =>
              CourseMasteryService(initial.catalog).readForDisplay(),
        ),
      ),
    );
    await _pumpUntilVisible(tester, find.byKey(kSpotlightTooltipKey));

    final context = tester.element(find.byType(LearningPathScreen));
    final t = AppL10n.of(context);
    expect(
      find.byKey(ValueKey('path-course-row-${current.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('path-legacy-practice-content')),
      findsNothing,
    );
    expect(
      t.coachLearningPathBody,
      'Starte beim hervorgehobenen aktuellen Schritt und arbeite dich von dort aus weiter.',
    );
    expect(find.text(t.coachLearningPathBody), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeScreen(tester);
  });
}

LearningPathScreen _preview() => LearningPathScreen.preview(
  courseUnits: _units,
  snapshot: const CourseMasterySnapshot(
    completedUnitIds: ['a1_01'],
    currentCourseUnitId: 'a1_02',
  ),
);

const _units = <CourseUnit>[
  CourseUnit(
    id: 'a1_01',
    level: 'a1',
    order: 1,
    title: CurriculumText(ko: '첫째', de: 'Erste Mission', en: 'First mission'),
    canDo: CurriculumText(
      ko: '첫째',
      de: 'freundlich beginnen',
      en: 'start warmly',
    ),
  ),
  CourseUnit(
    id: 'a1_02',
    level: 'a1',
    order: 2,
    title: CurriculumText(ko: '둘째', de: 'Aktuell', en: 'Current'),
    canDo: CurriculumText(
      ko: '둘째',
      de: 'Name und Herkunft nennen',
      en: 'share my name and origin',
    ),
  ),
  CourseUnit(
    id: 'a1_03',
    level: 'a1',
    order: 3,
    title: CurriculumText(ko: '셋째', de: 'Als Nächstes', en: 'Next'),
    canDo: CurriculumText(ko: '셋째', de: 'nachfragen', en: 'ask again'),
  ),
];

void _expectTextRole(WidgetTester tester, String value, TextStyle expected) {
  final text = tester.widget<Text>(find.text(value));
  expect(text.maxLines, isNull);
  expect(text.overflow, isNull);
  expect(text.style?.fontFamily, expected.fontFamily);
  expect(text.style?.fontSize, expected.fontSize);
  expect(text.style?.fontWeight, expected.fontWeight);
}

Future<({CurriculumCatalog catalog, List<VocabPack> packs})> _prewarm(
  WidgetTester tester,
) async {
  final result = await tester.runAsync(() async {
    final catalog = await CurriculumCatalog.load();
    final packs = await VocabPackService.loadAll();
    return (catalog: catalog, packs: packs);
  });
  return result!;
}

Future<void> _seed(Map<String, Object> values) async {
  rootBundle.clear();
  Storage.resetForTesting();
  Storage.resetCourseMasteryForTesting();
  SharedPreferences.setMockInitialValues(values);
  await Storage.init();
  DataLoader.reset();
  VocabPackService.reset();
  CurriculumCatalog.reset();
}

void _configureView(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 80,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text, skipOffstage: false))
      .map((widget) => widget.data)
      .whereType<String>()
      .toList();
  throw TestFailure(
    'Expected $finder after ${attempts * 100}ms. Visible text: $texts. '
    'Exception: ${tester.takeException()}',
  );
}

Future<void> _disposeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Widget _host({
  required Locale locale,
  required double textScale,
  required Widget child,
  Object? routeArguments,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => const Scaffold(body: SizedBox.shrink()),
  ),
  onGenerateInitialRoutes: (_) => [
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/path', arguments: routeArguments),
      builder: (_) => child,
    ),
  ],
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
    return MediaQuery(
      data: media.copyWith(
        padding: safeInsets,
        viewPadding: safeInsets,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: SoriTypeScale(child: appChild!),
    );
  },
);
