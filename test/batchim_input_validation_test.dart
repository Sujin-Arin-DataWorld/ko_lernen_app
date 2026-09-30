import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/batchim_drop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_content.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';

import 'support/sori_speech_stubs.dart';

const _valid = <String, dynamic>{
  'audioKo': '한글',
  'targetWord': '한글',
  'targetSyllableIndex': 0,
  'options': ['ㄱ', 'ㅁ', 'ㄴ', 'ㅇ'],
  'correctIndex': 2,
};

void main() {
  final invalid = <String, Map<String, dynamic>>{
    'answer does not restore the authored syllable': {
      ..._valid,
      'correctIndex': 0,
    },
    'target is not a Korean syllable': {..._valid, 'targetWord': 'A'},
    'target has no final consonant to remove': {..._valid, 'targetWord': '나'},
    'unknown consonant choice': {
      ..._valid,
      'options': ['ㄱ', 'foo', 'ㄴ', 'ㅇ'],
    },
    'duplicate correct choices': {
      ..._valid,
      'options': ['ㄴ', 'ㅁ', 'ㄴ', 'ㅇ'],
    },
    'UTF16 index outside rendered syllables': {
      ..._valid,
      'targetWord': '📖한',
      'targetSyllableIndex': 2,
    },
  };
  for (final entry in invalid.entries) {
    test(entry.key, () {
      expect(
        hasPlayableQuestContent(QuestType.batchimDrop, entry.value),
        isFalse,
      );
    });
    for (final locale in ['de', 'en']) {
      testWidgets('$locale ${entry.key} cannot speak, answer or complete', (
        tester,
      ) async {
        final speech = stubSoriSpeech();
        var completed = 0;
        var continued = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: Locale(locale),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Scaffold(
              body: BatchimDropQuest(
                data: entry.value,
                allowDontKnow: true,
                onComplete: (_) => completed++,
                onContinue: () => continued++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SoriEmptyState), findsOneWidget);
        expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
        expect(find.byKey(const ValueKey('quest-dont-know')), findsNothing);
        expect(find.byKey(const ValueKey('quest-continue')), findsNothing);
        expect(find.byKey(const ValueKey('answer-0')), findsNothing);
        expect(speech.spoken, isEmpty);
        expect(completed, 0);
        expect(continued, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final (word, target, options, correct) in [
    ('한글', 0, ['ㄱ', 'ㅁ', 'ㄴ', 'ㅇ'], 2),
    ('값', 0, ['ㅂ', 'ㅄ', 'ㅅ', 'ㄱ'], 1),
    ('읽다', 0, ['ㄺ', 'ㄹ', 'ㄱ', 'ㄲ'], 0),
    ('📖한', 1, ['ㄱ', 'ㅁ', 'ㄴ', 'ㅇ'], 2),
  ]) {
    test('accepts the spelling of $word at rendered index $target', () {
      expect(
        hasPlayableQuestContent(QuestType.batchimDrop, {
          ..._valid,
          'targetWord': word,
          'targetSyllableIndex': target,
          'options': options,
          'correctIndex': correct,
        }),
        isTrue,
      );
    });
  }
}
