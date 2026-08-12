import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/scenario_can_do_result.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/course_mission_screen.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

const _unit = CourseUnit(
  id: 'preview_unit',
  level: 'a1',
  order: 1,
  title: CurriculumText(ko: '인사', de: 'Gruß', en: 'Greeting'),
  canDo: CurriculumText(
    ko: '공손하게 인사할 수 있어요.',
    de: 'Ich kann höflich grüßen.',
    en: 'I can greet someone politely.',
  ),
);

const _scenario = Scenario(
  id: 'preview_scene',
  level: LearnerLevel.a1,
  emoji: '👋',
  register: Register.polite,
  title: LocalizedText(ko: '첫 인사', de: 'Erste Begrüßung', en: 'First greeting'),
  intro: LocalizedText(
    ko: '',
    de: 'Begrüße die Person.',
    en: 'Greet the person.',
  ),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(speaker: 'User', ko: '안녕하세요.', de: 'Guten Tag.', en: 'Hello.'),
  ],
  quests: [],
);

const _result = ScenarioCanDoResult(
  status: ScenarioCanDoStatus.verified,
  score: 1,
  courseUnit: _unit,
  structureStageBefore: HanokStage.foundation,
  structureStageAfter: HanokStage.pillars,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(480, 900);
    view.devicePixelRatio = 1;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'gallery_sentinel': 'unchanged',
      'kl_user_level': 'a1',
      'kl_preferred_mascot': 'tiger',
      'kl_consent_accepted': false,
      'kl_tut_home': true,
    });
    await Storage.init();
    MascotPreference.load();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('01A preview accepts without granting consent', (tester) async {
    final before = await _preferencesSnapshot();
    var accepted = 0;
    await tester.pumpWidget(
      _host(ConsentScreen.preview(onPreviewAccepted: () => accepted++)),
    );

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(accepted, 1);
    expect(Storage.consentAccepted, isFalse);
    expect(await _preferencesSnapshot(), equals(before));
  });

  testWidgets('01D preview reports select and skip without mascot writes', (
    tester,
  ) async {
    final before = await _preferencesSnapshot();
    MascotKind? completedKind;
    await tester.pumpWidget(
      _host(
        CharacterSelectionScreen.preview(
          onPreviewComplete: (kind) => completedKind = kind,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('companion-option-magpie')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('companion-selection-continue')),
    );
    await tester.pump();

    expect(completedKind, MascotKind.magpie);
    expect(MascotPreference.preference.value, CompanionPreference.tiger);
    expect(await _preferencesSnapshot(), equals(before));

    completedKind = MascotKind.tiger;
    await tester.pumpWidget(
      _host(
        CharacterSelectionScreen.preview(
          key: const ValueKey('skip-preview'),
          onPreviewComplete: (kind) => completedKind = kind,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('companion-selection-skip')));
    await tester.pump();

    expect(completedKind, isNull);
    expect(MascotPreference.preference.value, CompanionPreference.tiger);
    expect(await _preferencesSnapshot(), equals(before));
  });

  testWidgets('02A preview opens Today through callback without Home writes', (
    tester,
  ) async {
    final before = await _preferencesSnapshot();
    final projection = PersonalHanokProjection.from(
      const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
    );
    TodayLearningDestination? opened;
    await tester.pumpWidget(
      _host(
        HomeScreen.preview(
          now: () => DateTime(2026, 8, 11),
          previewFixture: HomePreviewFixture(
            today: const TodayLearningSnapshot(
              pick: ReviewPick(dueCount: 4),
              destination: TodayLearningDestination(route: '/review'),
              dueCount: 4,
            ),
            hanok: projection,
            narrative: HanokBuildNarrative.empty(projection),
            onOpenToday: (destination) => opened = destination,
          ),
        ),
      ),
    );
    await tester.pump();

    final todayAction = find.descendant(
      of: find.byKey(const ValueKey('home-primary-today')),
      matching: find.byType(SoriButton),
    );
    expect(todayAction, findsOneWidget);
    await tester.ensureVisible(todayAction);
    await tester.tap(todayAction);
    await tester.pump();

    expect(opened?.route, '/review');
    expect(await _preferencesSnapshot(), equals(before));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('02B preview opens its displayed first link without writes', (
    tester,
  ) async {
    final before = await _preferencesSnapshot();
    final firstLink = ContentLink(
      id: 'preview-first-link',
      contentKind: CurriculumContentKind.scenario,
      contentId: _scenario.id,
      courseUnitId: _unit.id,
      conceptIds: const ['greeting'],
      role: ContentLinkRole.assess,
    );
    final brief = CourseMissionBrief.from(
      unit: _unit,
      links: [firstLink],
      scenarios: const [_scenario],
      isCurrent: true,
    );
    ContentLink? opened;
    await tester.pumpWidget(
      _host(
        CourseMissionScreen.preview(
          brief: brief,
          openLink: (link) async => opened = link,
        ),
      ),
    );

    final firstStepAction = find.byKey(
      const ValueKey('course-mission-primary-cta'),
    );
    expect(firstStepAction, findsOneWidget);
    await tester.ensureVisible(firstStepAction);
    await tester.tap(firstStepAction);
    await tester.pump();

    expect(opened?.id, firstLink.id);
    expect(await _preferencesSnapshot(), equals(before));
  });

  testWidgets(
    '02C preview can advance the real player without progress writes',
    (tester) async {
      final before = await _preferencesSnapshot();
      await tester.pumpWidget(
        _host(
          ScenarioPlayerScreen.preview(
            fixture: const ScenarioPlayerPreviewFixture.action(
              scenario: _scenario,
            ),
          ),
        ),
      );

      expect(find.byType(ScenarioPlayerScreen), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('You can return to your Hanok now.'), findsOneWidget);
      expect(await _preferencesSnapshot(), equals(before));
    },
  );

  testWidgets(
    '02D preview result callbacks do not persist rewards or progress',
    (tester) async {
      final before = await _preferencesSnapshot();
      var returns = 0;
      var repeats = 0;
      await tester.pumpWidget(
        _host(
          ScenarioPlayerScreen.preview(
            fixture: ScenarioPlayerPreviewFixture.result(
              scenario: _scenario,
              result: _result,
              onReturn: () => returns++,
              onRepeat: () => repeats++,
            ),
          ),
        ),
      );

      expect(find.text('Your Hanok has changed.'), findsOneWidget);
      await tester.ensureVisible(find.text('Back to my Hanok'));
      await tester.tap(find.text('Back to my Hanok'));
      await tester.pump();
      await tester.tap(find.text('Practise this scene again'));
      await tester.pump();

      expect(returns, 1);
      expect(repeats, 1);
      expect(await _preferencesSnapshot(), equals(before));
    },
  );
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);

Future<Map<String, Object?>> _preferencesSnapshot() async {
  final preferences = await SharedPreferences.getInstance();
  return {for (final key in preferences.getKeys()) key: preferences.get(key)};
}
