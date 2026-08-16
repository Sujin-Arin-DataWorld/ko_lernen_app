import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/batchim_drop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/diktat_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/hoerverstehen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/luecken_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/particle_pop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/uebersetzen_quest.dart';
import 'package:ko_lernen_app/theme.dart';

typedef _QuestBuilder =
    Widget Function(
      void Function(QuestResult) onComplete,
      VoidCallback onContinue,
    );

void main() {
  final cases = <String, _QuestBuilder>{
    'listening': (complete, next) => HoerverstehenQuest(
      audioEnabled: false,
      data: const {
        'audioKo': '안녕',
        'correctIndex': 0,
        'options': [
          {'de': 'Hallo', 'en': 'Hello'},
          {'de': 'Danke', 'en': 'Thanks'},
        ],
      },
      onComplete: complete,
      onContinue: next,
    ),
    'translation': (complete, next) => UebersetzenQuest(
      data: const {
        'promptDe': 'Hallo',
        'promptEn': 'Hello',
        'correctIndex': 0,
        'options': [
          {'ko': '안녕'},
          {'ko': '감사'},
        ],
      },
      onComplete: complete,
      onContinue: next,
    ),
    'cloze': (complete, next) => LueckenQuest(
      data: const {
        'sentence': '안___',
        'correctIndex': 0,
        'options': ['녕', '녕히'],
      },
      onComplete: complete,
      onContinue: next,
    ),
    'particle': (complete, next) => ParticlePopQuest(
      data: const {
        'prefix': '저',
        'suffix': ' 학생이에요.',
        'correctIndex': 0,
        'options': ['는', '가'],
        'explanationDe': 'Nach einem Vokal steht 는.',
        'explanationEn': 'Use 는 after a vowel.',
      },
      onComplete: complete,
      onContinue: next,
    ),
    'batchim': (complete, next) => BatchimDropQuest(
      data: const {
        'audioKo': '안녕',
        'targetWord': '안녕',
        'targetSyllableIndex': 1,
        'correctIndex': 0,
        'options': ['ㅇ', 'ㄴ'],
        'explanationDe': '녕 endet mit ㅇ.',
        'explanationEn': '녕 ends with ㅇ.',
      },
      onComplete: complete,
      onContinue: next,
    ),
    'sentence': (complete, next) => SatzBauenQuest(
      data: const {'targetKo': '안녕', 'promptDe': 'Hallo', 'promptEn': 'Hello'},
      onComplete: complete,
      onContinue: next,
    ),
    'dictation': (complete, next) => DiktatQuest(
      data: const {
        'targetKo': '안녕',
        'audioKo': '안녕',
        'promptDe': 'Hallo',
        'promptEn': 'Hello',
      },
      onComplete: complete,
      onContinue: next,
      allowWordBankFallback: true,
    ),
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key} requires submit and emits one result', (
      tester,
    ) async {
      var resultCalls = 0;
      var continueCalls = 0;
      await tester.pumpWidget(
        _host(entry.value((_) => resultCalls++, () => continueCalls++)),
      );
      await tester.pump();

      if (entry.key == 'sentence') {
        await tester.tap(find.text('안녕').last);
      } else if (entry.key == 'dictation') {
        await tester.tap(find.byKey(const ValueKey('dictation-input-mode')));
        await tester.pump();
        await tester.tap(find.text('안녕').last);
      } else {
        await tester.tap(find.byKey(const ValueKey('answer-0')));
      }
      await tester.pump();
      expect(resultCalls, 0, reason: entry.key);

      await tester.tap(find.byKey(const ValueKey('quest-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(resultCalls, 1, reason: entry.key);
      expect(continueCalls, 0, reason: entry.key);

      await tester.tap(find.byKey(const ValueKey('quest-continue')));
      await tester.pump();
      expect(resultCalls, 1, reason: entry.key);
      expect(continueCalls, 1, reason: entry.key);
    });
  }

  testWidgets('a second wrong answer reveals the solution once', (
    tester,
  ) async {
    QuestResult? result;
    await tester.pumpWidget(
      _host(
        UebersetzenQuest(
          data: const {
            'promptDe': 'Hallo',
            'promptEn': 'Hello',
            'correctIndex': 0,
            'options': [
              {'ko': '안녕'},
              {'ko': '감사'},
            ],
          },
          onComplete: (value) => result = value,
          onContinue: () {},
        ),
      ),
    );
    await tester.pump();

    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.tap(find.byKey(const ValueKey('answer-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quest-submit')));
      await tester.pump();
    }

    expect(result?.passed, isFalse);
    expect(result?.firstTry, isFalse);
    expect(find.text('The correct answer is shown.'), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(
    body: SafeArea(
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);
