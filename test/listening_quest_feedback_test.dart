import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/hoerverstehen_quest.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/scenario_fixtures.dart';

void main() {
  test('default meaning question can explain a dialogue excerpt', () {
    const data = {
      'audioKo': '많이 피곤해 보여.',
      'correctIndex': 0,
      'options': [
        {'en': 'You look pretty tired.'},
      ],
    };
    expect(
      scenarioListeningTranscriptTranslation(
        scenarioAirportArrivalFixture,
        const QuestSpec(type: QuestType.hoerverstehen, data: data),
        'en',
      ),
      'You look pretty tired.',
    );
    expect(
      scenarioListeningTranscriptTranslation(
        scenarioAirportArrivalFixture,
        const QuestSpec(
          type: QuestType.hoerverstehen,
          data: {
            ...data,
            'question': {'en': 'What is the speaker trying to do?'},
          },
        ),
        'en',
      ),
      isEmpty,
    );
  });
  test(
    'transcript meaning comes from the dialogue, not an inference answer',
    () {
      const quest = QuestSpec(
        type: QuestType.hoerverstehen,
        data: {
          'audioKo': ' 여권 보여주세요. ',
          'correctIndex': 0,
          'options': [
            {'en': 'The officer asks for identification.'},
          ],
        },
      );
      expect(
        scenarioListeningTranscriptTranslation(
          scenarioAirportArrivalFixture,
          quest,
          'en',
        ),
        'Please show me your passport.',
      );
      expect(
        scenarioListeningTranscriptTranslation(
          scenarioAirportArrivalFixture,
          quest,
          'de',
        ),
        'Bitte zeigen Sie Ihren Reisepass.',
      );
      expect(
        scenarioListeningTranscriptTranslation(
          scenarioAirportArrivalFixture,
          const QuestSpec(
            type: QuestType.hoerverstehen,
            data: {'audioKo': '없는 대사'},
          ),
          'en',
        ),
        isEmpty,
      );
    },
  );
  for (final locale in ['en', 'de']) {
    for (final reveal in [false, true]) {
      testWidgets(
        '$locale listening reveals the heard sentence after ${reveal ? 'skip' : 'answer'}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(locale),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              home: Scaffold(
                body: HoerverstehenQuest(
                  audioEnabled: false,
                  allowDontKnow: true,
                  transcriptTranslation: locale == 'en'
                      ? 'Please hand over your passport.'
                      : 'Bitte geben Sie mir Ihren Reisepass.',
                  data: const {
                    'audioKo': '여권 주세요.',
                    'correctIndex': 0,
                    'options': [
                      {
                        'de': 'Ihren Reisepass, bitte.',
                        'en': 'Your passport, please.',
                      },
                      {'de': 'Danke.', 'en': 'Thank you.'},
                    ],
                    'explanation': {
                      'de': '주세요 ist eine höfliche Bitte.',
                      'en': '주세요 makes a polite request.',
                    },
                  },
                  onComplete: (_) {},
                  onContinue: () {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('여권 주세요.'), findsNothing);
          await tester.tap(
            find.byKey(ValueKey(reveal ? 'quest-dont-know' : 'answer-0')),
          );
          await tester.pumpAndSettle();
          expect(find.text('여권 주세요.'), findsOneWidget);
          expect(
            find.text(
              locale == 'en'
                  ? 'Please hand over your passport.'
                  : 'Bitte geben Sie mir Ihren Reisepass.',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              locale == 'en'
                  ? '주세요 makes a polite request.'
                  : '주세요 ist eine höfliche Bitte.',
            ),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
