import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/batchim_drop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/diktat_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/hoerverstehen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/luecken_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/particle_pop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_flow.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/uebersetzen_quest.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_pop.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

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
      data: const {
        'targetKo': '안녕',
        'promptDe': 'Hallo',
        'promptEn': 'Hello',
        'distractors': ['감사'],
      },
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

  // 지시서 4.11 — 옵션 탭 1회로 바로 판정되는(별도 확인 버튼이 없는) 엔진.
  // listening(hoerverstehen)은 원래부터 즉시 판정이었고, translation
  // (uebersetzen)·cloze(luecken)·particle(particlePop)이 이번에 합류했다.
  const instantByTap = {'listening', 'translation', 'cloze', 'particle'};

  for (final key in instantByTap) {
    testWidgets('$key judges immediately without a confirmation action', (
      tester,
    ) async {
      var resultCalls = 0;
      var continueCalls = 0;
      await tester.pumpWidget(
        _host(cases[key]!((_) => resultCalls++, () => continueCalls++, false)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('answer-0')));
      await tester.pump();

      expect(resultCalls, 1, reason: key);
      expect(continueCalls, 0, reason: key);
      expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
    });
  }

  for (final entry in cases.entries.where(
    (entry) => !instantByTap.contains(entry.key),
  )) {
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
      expect(find.byType(MascotPartner), findsNothing);
      expect(
        tester
            .widget<SoriButton>(find.byKey(const ValueKey('quest-submit')))
            .onTap,
        isNull,
        reason: '${entry.key} submit stays disabled before a choice',
      );

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
      final revealText = switch (entry.key) {
        'particle' => 'Use 는 after a vowel.',
        'batchim' => '녕 ends with ㅇ.',
        _ => 'The correct answer is shown.',
      };
      expect(find.text(revealText), findsOneWidget, reason: entry.key);
      // 공개된 정답은 오답 빨강으로 칠하지 않는다 — 학습자가 방금 알려준 정답을
      // 틀린 답으로 읽는다(2026-08-17 Jin: "틀렸다는거야 뭐야").
      expect(
        tester.widget<Text>(find.text(revealText)).style?.color,
        SoriColors.goldOnLight,
        reason: '${entry.key}: 정답 공개 해설이 danger 로 칠해졌다',
      );
      expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quest-continue')));
      await tester.pump();
      expect(results, hasLength(1), reason: entry.key);
      expect(continueCalls, 1, reason: entry.key);
    });
  }

  for (final entry in cases.entries) {
    testWidgets('${entry.key} shows a hint on the first miss', (tester) async {
      await tester.pumpWidget(_host(entry.value((_) {}, () {}, false)));
      await tester.pump();
      await _chooseWrong(tester, entry.key);
      if (!instantByTap.contains(entry.key)) {
        await tester.tap(find.byKey(const ValueKey('quest-submit')));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      if (entry.key == 'sentence') {
        expect(
          find.text('One word does not fit. Check the highlighted word.'),
          findsWidgets,
        );
      } else {
        expect(
          find.text('Almost. Try once more.'),
          findsWidgets,
          reason: entry.key,
        );
      }
      expect(find.byKey(const ValueKey('quest-continue')), findsNothing);
    });
  }

  for (final entry in cases.entries) {
    testWidgets('${entry.key} reveals the answer after a second miss', (
      tester,
    ) async {
      final results = <QuestResult>[];
      await tester.pumpWidget(_host(entry.value(results.add, () {}, false)));
      await tester.pump();

      for (var attempt = 0; attempt < 2; attempt++) {
        await _chooseWrong(tester, entry.key);
        if (!instantByTap.contains(entry.key)) {
          await tester.tap(find.byKey(const ValueKey('quest-submit')));
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
      }

      expect(results, hasLength(1), reason: entry.key);
      expect(results.single.passed, isFalse, reason: entry.key);
      expect(results.single.firstTry, isFalse, reason: entry.key);
      expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
    });
  }

  testWidgets('dictation accepts a declared surface variant from quest data', (
    tester,
  ) async {
    final results = <QuestResult>[];
    await tester.pumpWidget(
      _host(
        DiktatQuest(
          data: const {
            'targetKo': '다시 말씀드릴게요.',
            'audioKo': '다시 말씀드릴게요.',
            'promptDe': 'Ich melde mich noch einmal.',
            'promptEn': "I'll get back to you.",
            'acceptedVariants': ['다시 말씀 드릴게요'],
          },
          onComplete: results.add,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('diktat-korean-review')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('diktat-answer-field')),
      '다시 말씀 드릴게요',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('quest-submit')));
    await tester.pump();

    expect(results, hasLength(1));
    expect(results.single.passed, isTrue);
    expect(results.single.firstTry, isTrue);
    expect(find.byKey(const ValueKey('diktat-korean-review')), findsOneWidget);
  });

  testWidgets('listening keeps immediate judgment when motion is on', (
    tester,
  ) async {
    var resultCalls = 0;
    await tester.pumpWidget(
      _host(
        cases['listening']!((_) => resultCalls++, () {}, false),
        disableAnimations: false,
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('answer-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(resultCalls, 1);
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
    // 지시서 4.11 — cloze는 더 이상 별도 확인 버튼(quest-submit)이 없다
    // (즉시 판정). QuestLayout이 여전히 ScenarioQuestAction을 하단에
    // 고정하므로(내용이 비어 있어도 그 자리에 존재), 그 위젯의 위치를
    // "고정 액션 영역의 시작"으로 삼는다.
    final actionTop = tester
        .getTopLeft(find.byType(ScenarioQuestAction))
        .dy;
    expect(firstTop, greaterThan(120));
    expect(lastBottom, lessThan(actionTop));
  });
}

Future<void> _chooseWrong(WidgetTester tester, String key) async {
  if (key == 'sentence') {
    final submit = tester.widget<SoriButton>(
      find.byKey(const ValueKey('quest-submit')),
    );
    if (submit.onTap == null) {
      await tester.tap(find.text('감사').last);
      await tester.pump();
    }
    return;
  }
  if (key == 'dictation') {
    await tester.enterText(find.byType(TextField), '잘못');
    await tester.pump();
    return;
  }
  await tester.tap(find.byKey(const ValueKey('answer-1')));
  await tester.pump();
}

Widget _host(Widget child, {bool disableAnimations = true}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, app) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: disableAnimations),
      child: app!,
    );
  },
  home: Scaffold(
    body: SafeArea(
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);
