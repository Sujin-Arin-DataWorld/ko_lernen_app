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
    SharedPreferences.setMockInitialValues({'kl_tut_scenario': true});
    Storage.resetForTesting();
    await Storage.init();
  });

  for (final locale in const ['de', 'en']) {
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
