import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/diktat_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_content.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/uebersetzen_quest.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';

import 'support/sori_speech_stubs.dart';

void main() {
  test('punctuation-only sentence targets cannot be admitted or graded', () {
    for (final target in ['', '   ', '?', '... !', '“ ”', '—', '❤']) {
      expect(
        hasPlayableQuestContent(QuestType.satzBauen, {'targetKo': target}),
        isFalse,
        reason: target,
      );
      expect(SatzBauenQuest.isCorrectOrder(['?'], target), isFalse);
      expect(SatzBauenQuest.isCorrectOrder([target], target), isFalse);
    }
  });

  test(
    'empty normalized dictation targets and variants never count as exact',
    () {
      for (final target in ['', '   ', '?', '... !', '…·', '“ ”', '—', '❤']) {
        expect(
          hasPlayableQuestContent(QuestType.diktat, {'targetKo': target}),
          isFalse,
          reason: target,
        );
      expect(DiktatQuest.isExact('...', target), isFalse);
      expect(DiktatQuest.isAccepted('...', ['안녕', target]), isFalse);
      expect(DiktatQuest.isExact(target, target), isFalse);
      expect(DiktatQuest.isAccepted(target, ['안녕', target]), isFalse);
      }
    },
  );

  for (final sentence in const [true, false]) {
    testWidgets('${sentence ? 'Satz' : 'dictation'} punctuation is inert', (
      tester,
    ) async {
      final speech = stubSoriSpeech();
      var completed = 0;
      final child = sentence
          ? SatzBauenQuest(
              data: const {'targetKo': '?'},
              onComplete: (_) => completed++,
            )
          : DiktatQuest(
              data: const {'targetKo': '...'},
              onComplete: (_) => completed++,
            );
      await tester.pumpWidget(_app('en', child));
      await tester.pump();
      expect(find.byType(SoriEmptyState), findsOneWidget);
      expect(completed, 0);
      expect(speech.spoken, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in const ['de', 'en']) {
    testWidgets('$locale translation uses nonblank fallback prompt', (
      tester,
    ) async {
      stubSoriSpeech();
      var completed = 0;
      final data = <String, dynamic>{
        'promptDe': locale == 'de' ? '  ' : 'Hallo',
        'promptEn': locale == 'en' ? '  ' : 'Hello',
        'correctIndex': 0,
        'options': [
          {'ko': '안녕'},
          {'ko': '감사'},
        ],
      };
      await tester.pumpWidget(
        _app(
          locale,
          UebersetzenQuest(
            audioEnabled: false,
            data: data,
            onComplete: (_) => completed++,
          ),
        ),
      );
      await tester.pump();
      expect(find.text(locale == 'de' ? 'Hello' : 'Hallo'), findsOneWidget);
      expect(find.byType(SoriEmptyState), findsNothing);
      expect(completed, 0);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(String locale, Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(locale),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: Scaffold(body: child),
);
