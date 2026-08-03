import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/services/course_checkpoint_questions.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // Course checks are the subject of these tests; do not let the first-run
    // full-screen coach consume their taps.
    await Storage.setTutSeen('grammar');
    await Storage.setTutSeen('smalltalk');
    DataLoader.reset();
    SmalltalkLoader.reset();
    CurriculumCatalog.reset();
  });

  testWidgets(
    'course grammar hides the target pattern until the scored check',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.grammar &&
            item.courseUnitId == 'a1_03_topic_subject_particles' &&
            item.role == ContentLinkRole.assess,
      );
      final ids = courseContentIdsForContext(
        catalog: catalog,
        courseContext: CoursePracticeContext.fromLink(link),
        kind: CurriculumContentKind.grammar,
      )!;
      final target = (await DataLoader.loadGrammar()).firstWhere(
        (grammar) => ids.contains(grammar.id),
      );

      await tester.pumpWidget(
        _wrap(
          GrammarScreen(courseContext: CoursePracticeContext.fromLink(link)),
        ),
      );
      await _settleCourseScreen(tester);

      expect(find.text('Quick check'), findsOneWidget);
      expect(find.text(target.pattern), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeCourseScreen(tester);
    },
  );

  testWidgets(
    'smalltalk assessment does not reveal the correct relationship before selection',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.smalltalk &&
            item.courseUnitId == 'a2_02_plans_proposals' &&
            item.role == ContentLinkRole.assess,
      );

      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(courseContext: CoursePracticeContext.fromLink(link)),
        ),
      );
      await _settleCourseScreen(tester);

      await tester.tap(find.text('Quick check').first);
      await tester.pump();

      final relationshipLabels = SmalltalkRelationshipContext.values
          .map((context) => context.labelFor('en'))
          .toSet();
      final optionButtons = tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .where((button) => relationshipLabels.contains(button.label))
          .toList(growable: false);
      expect(optionButtons, hasLength(3));
      expect(optionButtons.every((button) => button.accent == null), isTrue);
      expect(optionButtons.every((button) => !button.destructive), isTrue);
      expect(tester.takeException(), isNull);
      await _disposeCourseScreen(tester);
    },
  );

  testWidgets(
    'practice-only smalltalk remains guidance and exposes no checkpoint action',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.smalltalk &&
            item.courseUnitId == 'a1_04_order_request_object' &&
            item.role == ContentLinkRole.practice,
      );

      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(courseContext: CoursePracticeContext.fromLink(link)),
        ),
      );
      await _settleCourseScreen(tester);

      expect(find.text('Quick check'), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeCourseScreen(tester);
    },
  );
}

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: child,
);

Future<void> _settleCourseScreen(WidgetTester tester) async {
  // Do not use pumpAndSettle here: the app deliberately contains entrance
  // animations. Two short frames are sufficient for the asset-backed loaders
  // and keep this regression test independent of animation lifetimes.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _disposeCourseScreen(WidgetTester tester) async {
  // Grammar/smalltalk own TTS and entrance widgets. Explicit disposal keeps
  // their delayed callbacks from leaking into the next widget test.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
