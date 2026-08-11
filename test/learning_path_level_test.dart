import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/theme.dart';

/// [pathVisibleLevel] is the single source of truth for which CEFR level the
/// Lernpfad renders. It must never return an empty/invalid level (the path
/// would be blank) and must map onboarding codes to the upper-case pack code.
void main() {
  test('falls back to A1 before onboarding or on invalid input', () {
    expect(pathVisibleLevel(null), 'A1');
    expect(pathVisibleLevel(''), 'A1');
    expect(pathVisibleLevel('   '), 'A1');
    expect(pathVisibleLevel('nonsense'), 'A1');
    expect(pathVisibleLevel('c1'), 'A1');
  });

  test('returns the chosen level upper-cased', () {
    expect(pathVisibleLevel('a1'), 'A1');
    expect(pathVisibleLevel('a2'), 'A2');
    expect(pathVisibleLevel('b1'), 'B1');
    expect(pathVisibleLevel('b2'), 'B2');
  });

  test('tolerates surrounding whitespace and upper-case input', () {
    expect(pathVisibleLevel(' a2 '), 'A2');
    expect(pathVisibleLevel('B2'), 'B2');
  });

  testWidgets('04C preview shows completed, current, and next concise rows', (
    tester,
  ) async {
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
      ),
    );

    expect(find.text('Dein Weg'), findsWidgets);
    expect(find.byKey(const ValueKey('path-course-row-a1_01')), findsNothing);
    expect(find.byKey(const ValueKey('path-course-row-a1_02')), findsOneWidget);
    expect(find.byKey(const ValueKey('path-course-row-a1_03')), findsOneWidget);
    expect(find.byKey(const ValueKey('path-course-row-a1_04')), findsOneWidget);
    expect(find.byKey(const ValueKey('path-course-row-a1_05')), findsNothing);
    expect(find.textContaining('70'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('path-legacy-practice-content')),
      findsNothing,
    );

    final currentMission = find.byKey(const ValueKey('path-current-mission'));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
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
    title: CurriculumText(ko: '둘째', de: 'Begrüßen', en: 'Greet'),
    canDo: CurriculumText(
      ko: '둘째',
      de: 'Ich kann begrüßen.',
      en: 'I can greet.',
    ),
  ),
  CourseUnit(
    id: 'a1_03',
    level: 'a1',
    order: 3,
    title: CurriculumText(ko: '셋째', de: 'Bestellen', en: 'Order'),
    canDo: CurriculumText(
      ko: '셋째',
      de: 'Ich kann bestellen.',
      en: 'I can order.',
    ),
  ),
  CourseUnit(
    id: 'a1_04',
    level: 'a1',
    order: 4,
    title: CurriculumText(ko: '넷째', de: 'Nachfragen', en: 'Ask again'),
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
];

Widget _host(Widget child, {ValueChanged<RouteSettings>? onRoute}) =>
    MaterialApp(
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
      home: child,
    );
