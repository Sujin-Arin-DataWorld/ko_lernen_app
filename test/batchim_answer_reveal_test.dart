import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/batchim_drop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_flow.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/sori_speech_stubs.dart';

void main() {
  for (final locale in ['de', 'en']) {
    for (final resolution in ['correct', 'two wrong', 'dont know']) {
      testWidgets('$locale hides spelling until $resolution resolution', (
        tester,
      ) async {
        final speech = stubSoriSpeech();
        final semantics = tester.ensureSemantics();
        try {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final results = <QuestResult>[];
          var continues = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(locale),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: Scaffold(
                body: SafeArea(
                  child: BatchimDropQuest(
                    data: const {
                      'audioKo': '한글',
                      'targetWord': '한글',
                      'targetSyllableIndex': 0,
                      'options': ['ㄱ', 'ㅁ', 'ㄴ', 'ㅇ'],
                      'correctIndex': 2,
                      'explanationDe': 'Die erste Silbe endet mit ㄴ.',
                      'explanationEn': 'The first syllable ends in ㄴ.',
                    },
                    allowDontKnow: true,
                    onComplete: results.add,
                    onContinue: () => continues++,
                    correctFeedback: SoriQuestCorrectFeedback(
                      burst: (_) {},
                      sound: () {},
                      haptic: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          _expectHidden();
          expect(find.text('하'), findsOneWidget);
          expect(find.text('글'), findsOneWidget);
          expect(speech.spoken, ['한글']);
          expect(results, isEmpty);
          final listen = find.bySemanticsLabel(
            locale == 'de' ? 'Audio anhören' : 'Listen to audio',
          );
          expect(listen, findsOneWidget);
          await tester.tap(listen);
          await tester.pump();
          expect(speech.spoken, ['한글', '한글']);
          _expectHidden();

          if (resolution == 'dont know') {
            await tester.tap(find.byKey(const ValueKey('quest-dont-know')));
          } else {
            final index = resolution == 'correct' ? 2 : 0;
            await tester.tap(find.byKey(ValueKey('answer-$index')));
            await tester.pump();
            _expectHidden();
            expect(results, isEmpty);
            await tester.tap(find.byKey(const ValueKey('quest-submit')));
            if (resolution == 'two wrong') {
              await tester.pumpAndSettle();
              _expectHidden();
              expect(results, isEmpty);
              await tester.tap(find.byKey(const ValueKey('answer-0')));
              await tester.pump();
              await tester.tap(find.byKey(const ValueKey('quest-submit')));
            }
          }
          await tester.pumpAndSettle();
          expect(find.text('한글'), findsOneWidget);
          expect(find.text('한'), findsOneWidget);
          expect(find.bySemanticsLabel(RegExp('한글')), findsOneWidget);
          expect(results, hasLength(1));
          expect(results.single.passed, resolution == 'correct');
          expect(results.single.firstTry, resolution == 'correct');
          expect(continues, 0);
          await tester.tap(find.byKey(const ValueKey('quest-continue')));
          await tester.pump();
          expect(continues, 1);
          expect(results, hasLength(1));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }
}

void _expectHidden() {
  expect(find.text('한글'), findsNothing);
  expect(find.text('한'), findsNothing);
  expect(find.bySemanticsLabel(RegExp('한글|한')), findsNothing);
}
