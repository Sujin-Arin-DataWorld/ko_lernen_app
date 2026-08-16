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
      bool allowDontKnow,
    );

void main() {
  final cases = <String, _QuestBuilder>{
    'listening': (complete, next, allowDontKnow) => HoerverstehenQuest(
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
      allowDontKnow: allowDontKnow,
    ),
    'translation': (complete, next, allowDontKnow) => UebersetzenQuest(
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
      allowDontKnow: allowDontKnow,
    ),
    'cloze': (complete, next, allowDontKnow) => LueckenQuest(
      data: const {
        'sentence': '안___',
        'correctIndex': 0,
        'options': ['녕', '녕히'],
      },
      onComplete: complete,
      onContinue: next,
      allowDontKnow: allowDontKnow,
    ),
    'particle': (complete, next, allowDontKnow) => ParticlePopQuest(
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
      allowDontKnow: allowDontKnow,
    ),
    'batchim': (complete, next, allowDontKnow) => BatchimDropQuest(
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
      allowDontKnow: allowDontKnow,
    ),
    'sentence': (complete, next, allowDontKnow) => SatzBauenQuest(
      data: const {'targetKo': '안녕', 'promptDe': 'Hallo', 'promptEn': 'Hello'},
      onComplete: complete,
      onContinue: next,
      allowDontKnow: allowDontKnow,
    ),
    'dictation': (complete, next, allowDontKnow) => DiktatQuest(
      data: const {
        'targetKo': '안녕',
        'audioKo': '안녕',
        'promptDe': 'Hallo',
        'promptEn': 'Hello',
      },
      onComplete: complete,
      onContinue: next,
      allowWordBankFallback: true,
      allowDontKnow: allowDontKnow,
    ),
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key} requires submit and emits one result', (
      tester,
    ) async {
      var resultCalls = 0;
      var continueCalls = 0;
      await tester.pumpWidget(
        _host(entry.value((_) => resultCalls++, () => continueCalls++, false)),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('quest-dont-know')), findsNothing);

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

  for (final entry in cases.entries) {
    testWidgets('${entry.key} can reveal an onboarding answer without credit', (
      tester,
    ) async {
      final results = <QuestResult>[];
      var continueCalls = 0;
      await tester.pumpWidget(
        _host(entry.value(results.add, () => continueCalls++, true)),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('quest-dont-know')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(results, hasLength(1), reason: entry.key);
      expect(results.single.passed, isFalse, reason: entry.key);
      expect(results.single.firstTry, isFalse, reason: entry.key);
      if (entry.key == 'particle') {
        expect(find.text('Use 는 after a vowel.'), findsOneWidget);
      } else if (entry.key == 'batchim') {
        expect(find.text('녕 ends with ㅇ.'), findsOneWidget);
      } else {
        expect(find.text('The correct answer is shown.'), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quest-continue')));
      await tester.pump();
      expect(results, hasLength(1), reason: entry.key);
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

  testWidgets('short cloze centers its answer group above the pinned action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        LueckenQuest(
          data: const {
            'sentence': '한국 처음___?',
            'correctIndex': 0,
            'options': ['이세요', '이에요', '예요', '이요'],
          },
          onComplete: (_) {},
          onContinue: () {},
        ),
      ),
    );
    await tester.pump();

    final firstTop = tester
        .getTopLeft(find.byKey(const ValueKey('answer-0')))
        .dy;
    final lastBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('answer-3')))
        .dy;
    final actionTop = tester
        .getTopLeft(find.byKey(const ValueKey('quest-submit')))
        .dy;
    expect(firstTop, greaterThan(120));
    expect(lastBottom, lessThan(actionTop));
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
