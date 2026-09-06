import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';

/// [pathVisibleLevel] is the single source of truth for which CEFR level the
/// Lernpfad renders. It must never return an empty/invalid level (the path
/// would be blank) and must map onboarding codes to the upper-case pack code.
final AppL10n _l10n = lookupAppL10n(const Locale('de'));

void main() {
  test('falls back to A1 before onboarding or on invalid input', () {
    expect(pathVisibleLevel(null), 'A1');
    expect(pathVisibleLevel(''), 'A1');
    expect(pathVisibleLevel('   '), 'A1');
    expect(pathVisibleLevel('nonsense'), 'A1');
  });

  test('returns the chosen level upper-cased', () {
    expect(pathVisibleLevel('a1'), 'A1');
    expect(pathVisibleLevel('a2'), 'A2');
    expect(pathVisibleLevel('b1'), 'B1');
    expect(pathVisibleLevel('b2'), 'B2');
    expect(pathVisibleLevel('c1'), 'C1');
    expect(pathVisibleLevel('c2'), 'C2');
  });

  test('tolerates surrounding whitespace and upper-case input', () {
    expect(pathVisibleLevel(' a2 '), 'A2');
    expect(pathVisibleLevel('B2'), 'B2');
    expect(pathVisibleLevel(' C2 '), 'C2');
  });

  test('legacy pack path keeps its dedicated browse level', () {
    expect(
      pathLegacyBrowseVisibleLevel(
        browseLevelCode: 'b1',
        placementLevelCode: 'a2',
        legacyUserLevelCode: 'a1',
      ),
      'B1',
    );
    expect(
      pathLegacyBrowseVisibleLevel(
        browseLevelCode: null,
        placementLevelCode: 'a2',
        legacyUserLevelCode: 'a1',
      ),
      'A2',
    );
  });

  test('canonical current course level wins over the legacy browse level', () {
    const snapshot = CourseMasterySnapshot(
      placementLevel: 'a2',
      currentCourseUnitId: 'a2_02',
    );

    expect(
      pathCourseVisibleLevel(
        snapshot: snapshot,
        courseUnits: _units,
        fallbackBrowseLevel: 'A1',
      ),
      'A2',
    );
    expect(pathVisibleLevel('a1'), 'A1');
  });

  testWidgets(
    '04C keeps the canonical A2 mission visible when legacy browse is A1',
    (tester) async {
      String? openedRoute;
      Object? openedArguments;
      await tester.pumpWidget(
        _host(
          LearningPathScreen.preview(
            courseUnits: _units,
            snapshot: const CourseMasterySnapshot(
              placementLevel: 'a2',
              currentCourseUnitId: 'a2_02',
            ),
            selectedLevel: 'A1',
          ),
          onRoute: (settings) {
            openedRoute = settings.name;
            openedArguments = settings.arguments;
          },
        ),
      );

      expect(find.byKey(const ValueKey('path-course-row-a2_02')), findsOne);
      expect(find.byKey(const ValueKey('path-course-row-a1_03')), findsNothing);
      final currentMission = find.byKey(const ValueKey('path-current-mission'));
      await tester.scrollUntilVisible(currentMission, 240);
      await tester.tap(currentMission);
      await tester.pumpAndSettle();
      expect(openedRoute, '/course/mission');
      expect(openedArguments, 'a2_02');
    },
  );

  testWidgets('04C preview shows completed, current, and next concise rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? openedRoute;
    Object? openedArguments;
    await tester.pumpWidget(
      _host(
        LearningPathScreen.preview(
          courseUnits: _units,
          snapshot: const CourseMasterySnapshot(
            completedUnitIds: ['a1_01', 'a1_02'],
            currentCourseUnitId: 'a1_03',
          ),
        ),
        onRoute: (settings) {
          openedRoute = settings.name;
          openedArguments = settings.arguments;
        },
        textScale: 1.3,
      ),
    );

    expect(find.text(_l10n.pathTitle), findsWidgets);
    expect(find.byKey(const ValueKey('path-course-row-a1_01')), findsNothing);
    expect(find.byKey(const ValueKey('path-course-row-a1_02')), findsOneWidget);
    expect(find.byKey(const ValueKey('path-course-row-a1_03')), findsOneWidget);
    expect(find.byKey(const ValueKey('path-course-row-a1_04')), findsOneWidget);
    expect(find.byKey(const ValueKey('path-course-row-a1_05')), findsNothing);
    expect(find.text(_l10n.pathCourseMissionsTitle), findsNothing);
    expect(find.text('fertig'), findsOneWidget);
    expect(find.text('weiter'), findsOneWidget);
    expect(find.text('später'), findsOneWidget);
    expect(find.text('Kann ich: freundlich beginnen'), findsOneWidget);
    expect(find.text('Jetzt: Name, Herkunft, Thema'), findsOneWidget);
    expect(find.text('Als Nächstes nach deinem Beweis'), findsOneWidget);
    final evidenceTitle = find.text('Woran du Fortschritt erkennst');
    expect(evidenceTitle, findsOneWidget);
    expect(find.textContaining('70'), findsOneWidget);
    expect(
      tester.getTopLeft(evidenceTitle).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('path-course-row-a1_04')))
            .dy,
      ),
    );
    expect(
      find.byKey(const ValueKey('path-legacy-practice-content')),
      findsNothing,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    final currentMission = find.byKey(const ValueKey('path-current-mission'));
    await tester.scrollUntilVisible(
      currentMission,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(currentMission);
    await tester.pump();
    await tester.tap(currentMission);
    await tester.pumpAndSettle();
    expect(openedRoute, '/course/mission');
    expect(openedArguments, 'a1_03');
  });

  testWidgets('04C keeps the legacy pack trail behind one explicit control', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        LearningPathScreen.preview(
          courseUnits: _units,
          snapshot: const CourseMasterySnapshot(currentCourseUnitId: 'a1_03'),
        ),
      ),
    );

    final toggle = find.byKey(const ValueKey('path-legacy-practice-toggle'));
    await tester.scrollUntilVisible(toggle, 300);
    // scrollUntilVisible stops as soon as any part of the widget intersects
    // the viewport — its center can still land outside it (2026-08-19: the
    // SoriTypeScale migration made comfort-scaled text a touch shorter here,
    // which was enough to move the tap point off-screen). ensureVisible
    // scrolls it fully into view before we tap.
    await tester.ensureVisible(toggle);
    await tester.pump();
    expect(toggle, findsOneWidget);
    expect(find.text('Weitere Übungen anzeigen'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('path-legacy-practice-content')),
      findsNothing,
    );

    await tester.tap(toggle);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('path-legacy-practice-content')),
      findsOneWidget,
    );
  });

  testWidgets('04C stays reachable at 320dp and 200% with safe areas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(
        LearningPathScreen.preview(
          courseUnits: _units,
          snapshot: const CourseMasterySnapshot(
            completedUnitIds: ['a1_01', 'a1_02'],
            currentCourseUnitId: 'a1_03',
          ),
        ),
        textScale: 2,
        safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
      ),
    );

    expect(find.byType(SoriStandardFrame), findsOneWidget);
    final toggle = find.byKey(const ValueKey('path-legacy-practice-toggle'));
    await tester.scrollUntilVisible(toggle, 200);
    await tester.ensureVisible(toggle);
    await tester.pump();

    expect(find.text('Weitere Übungen anzeigen'), findsOneWidget);
    expect(tester.getRect(toggle).bottom, lessThanOrEqualTo(640 - 34));
    expect(tester.takeException(), isNull);
  });
}

const _units = <CourseUnit>[
  CourseUnit(
    id: 'a1_01',
    level: 'a1',
    order: 1,
    title: CurriculumText(ko: '첫째', de: 'Erste Mission', en: 'First mission'),
    canDo: CurriculumText(ko: '첫째', de: 'Erstes Ziel', en: 'First goal'),
  ),
  CourseUnit(
    id: 'a1_02',
    level: 'a1',
    order: 2,
    title: CurriculumText(
      ko: '둘째',
      de: 'Begrüßen & Hangul',
      en: 'Greeting & Hangul',
    ),
    canDo: CurriculumText(
      ko: '둘째',
      de: 'freundlich beginnen',
      en: 'start warmly',
    ),
  ),
  CourseUnit(
    id: 'a1_03',
    level: 'a1',
    order: 3,
    title: CurriculumText(
      ko: '셋째',
      de: 'Mich vorstellen',
      en: 'Introduce myself',
    ),
    canDo: CurriculumText(
      ko: '셋째',
      de: 'Name, Herkunft, Thema',
      en: 'name, origin, topic',
    ),
  ),
  CourseUnit(
    id: 'a1_04',
    level: 'a1',
    order: 4,
    title: CurriculumText(
      ko: '넷째',
      de: 'Bestellen & bitten',
      en: 'Order & ask',
    ),
    canDo: CurriculumText(
      ko: '넷째',
      de: 'Ich kann nachfragen.',
      en: 'I can ask again.',
    ),
  ),
  CourseUnit(
    id: 'a1_05',
    level: 'a1',
    order: 5,
    title: CurriculumText(ko: '다섯째', de: 'Weiter', en: 'Continue'),
    canDo: CurriculumText(
      ko: '다섯째',
      de: 'Ich kann weitermachen.',
      en: 'I can continue.',
    ),
  ),
  CourseUnit(
    id: 'a2_01',
    level: 'a2',
    order: 1,
    title: CurriculumText(ko: '일상', de: 'Alltag', en: 'Daily life'),
    canDo: CurriculumText(
      ko: '일상',
      de: 'Im Alltag beginnen',
      en: 'start daily life',
    ),
  ),
  CourseUnit(
    id: 'a2_02',
    level: 'a2',
    order: 2,
    title: CurriculumText(ko: '약속', de: 'Verabreden', en: 'Make plans'),
    canDo: CurriculumText(
      ko: '약속',
      de: 'Einen Termin absprechen',
      en: 'arrange a meeting',
    ),
  ),
];

Widget _host(
  Widget child, {
  ValueChanged<RouteSettings>? onRoute,
  double textScale = 1,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  onGenerateRoute: onRoute == null
      ? null
      : (settings) {
          onRoute(settings);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: SizedBox()),
          );
        },
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: safeInsets,
        viewPadding: safeInsets,
        textScaler: TextScaler.linear(textScale),
      ),
      child: appChild!,
    );
  },
  home: child,
);
