import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/batchim_drop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/diktat_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/hoerverstehen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/luecken_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/particle_pop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/uebersetzen_quest.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';

import 'support/scenario_json.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    Storage.resetForTesting();
    await Storage.init();
  });

  for (final locale in const ['de', 'en']) {
    testWidgets('dialog preview cannot advance into a malformed quest $locale', (
      tester,
    ) async {
      final speech = stubSoriSpeech();
      const scenario = Scenario(
        id: 'preview-malformed-listening',
        level: LearnerLevel.a1,
        emoji: '',
        register: Register.polite,
        title: LocalizedText(ko: '인사', de: 'Begrüßung', en: 'Greeting'),
        intro: LocalizedText(ko: '', de: '', en: ''),
        vocab: [],
        grammarIds: [],
        dialog: [
          DialogLine(speaker: 'partner', ko: '안녕', de: 'Hallo', en: 'Hello'),
        ],
        quests: [
          QuestSpec(
            type: QuestType.hoerverstehen,
            data: {
              'audioKo': 42,
              'correctIndex': 0,
              'options': [
                {'de': 'Hallo', 'en': 'Hello'},
                {'de': 'Danke', 'en': 'Thanks'},
              ],
            },
          ),
        ],
      );
      await tester.pumpWidget(
        _app(
          locale,
          ScenarioPlayerScreen.preview(
            fixture: const ScenarioPlayerPreviewFixture.action(
              scenario: scenario,
              stage: ScenarioStage.dialog,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.tap(find.text(locale == 'de' ? 'Weiter' : 'Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byType(SoriEmptyState), findsOneWidget);
      expect(find.byType(SoriButton), findsNothing);
      // Only the valid dialog may speak, never the malformed quest.
      expect(speech.spoken, ['안녕']);
      expect(Storage.xp, 0);
      expect(Storage.completedScenarios, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    for (final type in QuestType.values.where(
      (t) => t != QuestType.schreiben,
    )) {
      for (final invalid in const [false, true]) {
        testWidgets('$type $locale ${invalid ? 'invalid' : 'empty'} is inert', (
          tester,
        ) async {
          final speech = stubSoriSpeech();
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final results = <QuestResult>[];
          var continued = 0;
          final data = invalid ? _invalidData(type) : <String, dynamic>{};
          await tester.pumpWidget(
            _app(
              locale,
              Scaffold(
                body: _engine(type, data, results.add, () => continued++),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          expect(find.byType(SoriEmptyState), findsOneWidget);
          expect(find.byType(SoriButton), findsNothing);
          expect(results, isEmpty);
          expect(continued, 0);
          expect(speech.spoken, isEmpty);
          expect(speech.spokenSlow, isEmpty);
          expect(Storage.xp, 0);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }

    for (final invalid in const [false, true]) {
      testWidgets(
        'quest preview $locale ${invalid ? 'invalid' : 'zero'} quests is inert',
        (tester) async {
          final speech = stubSoriSpeech();
          final raw = allScenarioJson().first;
          raw['quests'] = invalid
              ? [
                  {'type': 'satzBauen', 'data': <String, dynamic>{}},
                ]
              : [];
          var exits = 0;
          await tester.pumpWidget(
            _app(
              locale,
              ScenarioPlayerScreen.preview(
                fixture: ScenarioPlayerPreviewFixture.action(
                  scenario: Scenario.fromJson(raw),
                  stage: ScenarioStage.quest,
                ),
                onExit: () => exits++,
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull);
          expect(find.byType(SoriEmptyState), findsOneWidget);
          expect(find.byType(SoriButton), findsNothing);
          expect(speech.spoken, isEmpty);
          expect(speech.prefetched, isEmpty);
          expect(Storage.xp, 0);
          expect(Storage.completedScenarios, isEmpty);
          await tester.tap(
            find.bySemanticsLabel(locale == 'de' ? 'Schließen' : 'Close'),
          );
          await tester.pump();
          expect(exits, 1);
          expect(Storage.xp, 0);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        'scenario $locale ${invalid ? 'invalid' : 'zero'} quests cannot start',
        (tester) async {
          final speech = stubSoriSpeech();
          final raw = allScenarioJson().first;
          raw['quests'] = invalid
              ? [
                  {'type': 'satzBauen', 'data': <String, dynamic>{}},
                ]
              : [];
          final scenario = Scenario.fromJson(raw);
          var exits = 0;
          var completed = 0;
          await tester.pumpWidget(
            _app(
              locale,
              ScenarioPlayerScreen(
                scenarioId: scenario.id,
                scenarioLoader: (_) async => scenario,
                onExit: () => exits++,
                onCompleted: (_) {
                  completed++;
                },
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull);
          expect(find.byType(SoriEmptyState), findsOneWidget);
          expect(speech.spoken, isEmpty);
          expect(speech.prefetched, isEmpty);
          expect(Storage.xp, 0);
          expect(completed, 0);
          await tester.tap(
            find.bySemanticsLabel(locale == 'de' ? 'Schließen' : 'Close'),
          );
          await tester.pump();
          expect(exits, 1);
          expect(completed, 0);
          expect(Storage.xp, 0);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}

Widget _app(String locale, Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(locale),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2), disableAnimations: true),
    child: child!,
  ),
  home: child,
);

// Give each renderer otherwise usable data so the bad index/type is the
// actual reason for rejection, not an unrelated malformed field.
Map<String, dynamic> _invalidData(QuestType type) => switch (type) {
  QuestType.hoerverstehen => {
    'audioKo': '안녕',
    'correctIndex': 99,
    'options': [
      {'de': 'Hallo', 'en': 'Hello'},
      {'de': 'Danke', 'en': 'Thanks'},
    ],
  },
  QuestType.uebersetzen => {
    'promptDe': 'Hallo',
    'promptEn': 'Hello',
    'correctIndex': 99,
    'options': [
      {'ko': '안녕'},
      {'ko': '감사'},
    ],
  },
  QuestType.luecken => {
    'sentence': '저___ 학생이에요.',
    'correctIndex': 99,
    'options': ['는', '이'],
  },
  QuestType.particlePop => {
    'prefix': '저',
    'suffix': ' 학생이에요.',
    'correctIndex': 99,
    'options': ['는', '이'],
  },
  QuestType.batchimDrop => {
    'audioKo': '안녕',
    'targetWord': '안녕',
    'targetSyllableIndex': 99,
    'correctIndex': 0,
    'options': ['ㅇ', 'ㄴ'],
  },
  QuestType.satzBauen || QuestType.diktat => {'targetKo': 42},
  QuestType.schreiben => {},
};

Widget _engine(
  QuestType type,
  Map<String, dynamic> data,
  ValueChanged<QuestResult> complete,
  VoidCallback next,
) => switch (type) {
  QuestType.hoerverstehen => HoerverstehenQuest(
    data: data,
    onComplete: complete,
    onContinue: next,
    allowDontKnow: true,
  ),
  QuestType.luecken => LueckenQuest(
    data: data,
    onComplete: complete,
    onContinue: next,
    allowDontKnow: true,
  ),
  QuestType.uebersetzen => UebersetzenQuest(
    data: data,
    onComplete: complete,
    onContinue: next,
    allowDontKnow: true,
  ),
  QuestType.particlePop => ParticlePopQuest(
    data: data,
    onComplete: complete,
    onContinue: next,
    allowDontKnow: true,
  ),
  QuestType.batchimDrop => BatchimDropQuest(
    data: data,
    onComplete: complete,
    onContinue: next,
    allowDontKnow: true,
  ),
  QuestType.satzBauen => SatzBauenQuest(
    data: data,
    onComplete: complete,
    onContinue: next,
    allowDontKnow: true,
  ),
  QuestType.diktat => DiktatQuest(
    data: data,
    onComplete: complete,
    onContinue: next,
    allowDontKnow: true,
  ),
  QuestType.schreiben => throw StateError('No writing quest renderer'),
};
