import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/batchim_drop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/diktat_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/hoerverstehen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/luecken_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/particle_pop_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_flow.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_layout.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/uebersetzen_quest.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/tts_speed_control.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/sori_speech_stubs.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

const _viewports = <({Size size, double textScale})>[
  (size: Size(320, 640), textScale: 2),
  (size: Size(360, 400), textScale: 1),
  (size: Size(390, 844), textScale: 1.3),
  (size: Size(720, 1024), textScale: 1.3),
  (size: Size(1280, 900), textScale: 1.3),
];

typedef _QuestBuilder =
    Widget Function(
      ValueChanged<QuestResult> onComplete,
      VoidCallback onContinue,
      bool allowDontKnow,
    );

final _engines =
    <({String name, bool hasSpeed, _QuestBuilder build, String? revealHintEn})>[
      (
        name: 'listening',
        hasSpeed: true,
        revealHintEn: null,
        build: (complete, next, allowDontKnow) => HoerverstehenQuest(
          data: const {
            'audioKo': '안녕',
            'question': {
              'de': 'Was bedeutet dieser Satz?',
              'en': 'What does this sentence mean?',
            },
            'instruction': {
              'de': 'Wähle die passende Bedeutung.',
              'en': 'Choose the matching meaning.',
            },
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
      ),
      (
        name: 'translation',
        hasSpeed: false,
        revealHintEn: null,
        build: (complete, next, allowDontKnow) => UebersetzenQuest(
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
      ),
      (
        name: 'cloze',
        hasSpeed: false,
        revealHintEn: null,
        build: (complete, next, allowDontKnow) => LueckenQuest(
          data: const {
            'sentence': '안___',
            'correctIndex': 0,
            'options': ['녕', '녕히'],
          },
          onComplete: complete,
          onContinue: next,
          allowDontKnow: allowDontKnow,
        ),
      ),
      (
        name: 'particle',
        hasSpeed: true,
        revealHintEn: 'Use 는 after a vowel.',
        build: (complete, next, allowDontKnow) => ParticlePopQuest(
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
      ),
      (
        name: 'batchim',
        hasSpeed: true,
        revealHintEn: '녕 ends with ㅇ.',
        build: (complete, next, allowDontKnow) => BatchimDropQuest(
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
      ),
      (
        name: 'sentence',
        hasSpeed: true,
        revealHintEn: null,
        build: (complete, next, allowDontKnow) => SatzBauenQuest(
          data: const {
            'targetKo': '안녕 하세요',
            'promptDe': 'Sage höflich Hallo.',
            'promptEn': 'Say hello politely.',
            'audioKo': '안녕 하세요',
            'distractors': ['감사'],
          },
          onComplete: complete,
          onContinue: next,
          allowDontKnow: allowDontKnow,
        ),
      ),
      (
        name: 'dictation',
        hasSpeed: false,
        revealHintEn: null,
        build: (complete, next, allowDontKnow) => DiktatQuest(
          data: const {
            'targetKo': '안녕 하세요',
            'audioKo': '안녕 하세요',
            'promptDe': 'Sage höflich Hallo.',
            'promptEn': 'Say hello politely.',
          },
          onComplete: complete,
          onContinue: next,
          allowWordBankFallback: true,
          allowDontKnow: allowDontKnow,
        ),
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in _viewports) {
      testWidgets('${locale.languageCode} ${viewport.size.width.toInt()}x'
          '${viewport.size.height.toInt()} ${viewport.textScale}x completes '
          'all quest engines in the locked matrix', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final t = lookupAppL10n(locale);
          for (final engine in _engines) {
            final results = <QuestResult>[];
            var continueCalls = 0;
            await _pumpQuest(
              tester,
              engine.build(results.add, () => continueCalls++, true),
              locale: locale,
              viewport: viewport,
            );

            expect(find.byType(QuestLayout), findsOneWidget);
            final submit = find.bySemanticsLabel(t.questCheckAnswer);
            if (engine.name == 'listening') {
              expect(submit, findsNothing);
            } else {
              _expectButton(tester, submit, enabled: false, minHeight: 48);
              _expectVisibleInView(tester, submit, viewport.size);
            }

            final speed = find.byType(TtsSpeedControl);
            expect(
              speed,
              engine.hasSpeed ? findsOneWidget : findsNothing,
              reason: engine.name,
            );
            if (engine.hasSpeed) {
              final chip = find.descendant(
                of: speed,
                matching: find.byType(SoriChip),
              );
              expect(chip, findsOneWidget, reason: engine.name);
              expect(
                tester.widget<SoriChip>(chip).minInteractiveHeight,
                greaterThanOrEqualTo(48),
                reason: engine.name,
              );
              expect(
                tester.getSize(chip).height,
                greaterThanOrEqualTo(48),
                reason: engine.name,
              );
            }

            if (engine.name == 'dictation') {
              final field = tester.widget<SoriTextField>(
                find.byType(SoriTextField),
              );
              expect(field.labelText, t.diktatAnswerLabel);
            }

            await _enterCorrectResponse(tester, engine.name);
            if (engine.name != 'listening') {
              _expectButton(tester, submit, enabled: true, minHeight: 48);
              await _tapPointerOwned(tester, submit);
            }
            expect(results, hasLength(1), reason: engine.name);
            expect(results.single.passed, isTrue, reason: engine.name);
            _expectLiveRegion(
              tester,
              _correctResultLabel(engine.name, locale, t),
            );

            final next = find.bySemanticsLabel(t.questNext);
            _expectButton(tester, next, enabled: true, minHeight: 48);
            await _tapPointerOwned(tester, next);
            expect(continueCalls, 1, reason: engine.name);
            _expectNoException(tester, reason: engine.name);
          }
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets(
    'revealed correct answer keeps exactly one selected choice semantic',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final t = lookupAppL10n(const Locale('en'));
        await _pumpQuest(
          tester,
          _engines.first.build((_) {}, () {}, false),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );

        final wrong = find.byKey(const ValueKey('answer-1'));
        await _tapPointerOwned(tester, wrong);
        await _tapPointerOwned(tester, wrong);

        final revealedWrong = find.bySemanticsLabel('Thanks, ${t.questWrong}');
        final revealedCorrect = find.bySemanticsLabel(
          'Hello, ${t.questCorrect}',
        );
        _expectButton(
          tester,
          revealedWrong,
          enabled: false,
          selected: ui.Tristate.isFalse,
          minHeight: 48,
        );
        _expectButton(
          tester,
          revealedCorrect,
          enabled: false,
          selected: ui.Tristate.isTrue,
          minHeight: 48,
        );
        final selectedCount = [revealedWrong, revealedCorrect]
            .map((finder) => tester.getSemantics(finder).getSemanticsData())
            .where(
              (data) => data.flagsCollection.isSelected == ui.Tristate.isTrue,
            )
            .length;
        expect(selectedCount, 1);
        _expectNoException(tester);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'wrong word tiles and particle slot text meet composited 4.5 contrast',
    (tester) async {
      await _pumpQuest(
        tester,
        SoriWordTile(label: '감사', state: SoriWordTileState.wrong, onTap: () {}),
        locale: const Locale('en'),
        viewport: _viewports[2],
      );
      final wordTile = find.byType(SoriWordTile);
      final wordText = tester.widget<Text>(
        find.descendant(of: wordTile, matching: find.text('감사')),
      );
      final wordMaterial = tester.widget<Material>(
        find.descendant(of: wordTile, matching: find.byType(Material)),
      );
      final wordBackground = Color.alphaBlend(
        wordMaterial.color!,
        SoriColors.lightBg,
      );
      expect(
        SoriColors.contrastRatio(wordText.style!.color!, wordBackground),
        greaterThanOrEqualTo(4.5),
      );

      final answerStates = [
        SoriAnswerState.selected,
        SoriAnswerState.correct,
        SoriAnswerState.wrong,
      ];
      await _pumpQuest(
        tester,
        Column(
          children: [
            for (final entry in answerStates.asMap().entries)
              SoriAnswerTile(
                key: ValueKey('contrast-answer-${entry.key}'),
                label: 'choice-${entry.key}',
                index: entry.key,
                state: entry.value,
                selected: true,
                onTap: () {},
              ),
          ],
        ),
        locale: const Locale('en'),
        viewport: _viewports[2],
      );
      for (final entry in answerStates.asMap().entries) {
        _expectAnswerIndexContrast(tester, entry.key);
      }

      final particle = _engines.singleWhere(
        (engine) => engine.name == 'particle',
      );
      await _pumpQuest(
        tester,
        particle.build((_) {}, () {}, false),
        locale: const Locale('en'),
        viewport: _viewports[2],
      );
      await _tapPointerOwned(tester, find.byKey(const ValueKey('answer-1')));
      _expectParticleSlotTextContrast(tester, '가');
      await _tapPointerOwned(tester, find.byKey(const ValueKey('answer-0')));
      _expectParticleSlotTextContrast(tester, '는');
      _expectNoException(tester);
    },
  );

  testWidgets(
    'word tiles are icon-free 17.5px controls with explicit state semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final t = lookupAppL10n(const Locale('en'));
        const states = <(String, SoriWordTileState)>[
          ('selected', SoriWordTileState.selected),
          ('correct', SoriWordTileState.correct),
          ('wrong', SoriWordTileState.wrong),
        ];
        await _pumpQuest(
          tester,
          Column(
            children: [
              for (final entry in states)
                SoriWordTile(label: entry.$1, state: entry.$2, onTap: () {}),
            ],
          ),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );

        final tiles = find.byType(SoriWordTile);
        expect(tiles, findsNWidgets(states.length));
        expect(
          find.descendant(of: tiles, matching: find.byType(Icon)),
          findsNothing,
        );
        for (final entry in states) {
          final text = tester.widget<Text>(find.text(entry.$1));
          expect(text.style?.fontSize, 17.5);
          final status = switch (entry.$2) {
            SoriWordTileState.selected => t.questAnswerSelected,
            SoriWordTileState.correct => t.questCorrect,
            SoriWordTileState.wrong => t.questWrong,
            _ => throw StateError('Unexpected test state'),
          };
          expect(find.bySemanticsLabel('${entry.$1}, $status'), findsOneWidget);
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('7종 엔진 모두 정답 제출 시 burst·sound·haptic을 각 1회씩만 내보낸다 (지시서 4.7)', (
    tester,
  ) async {
    // diktat(진입 자동재생)·particle(답 공개 후 읽기)이 실제 TtsService로
    // 새는 걸 막는다 — auto_speech_test_stub_guard_test.dart의 T3 함정.
    stubSoriSpeech();
    for (final engine in const [
      'listening',
      'translation',
      'cloze',
      'particle',
      'batchim',
      'sentence',
      'dictation',
    ]) {
      var burstCalls = 0;
      var soundCalls = 0;
      var hapticCalls = 0;
      final feedback = SoriQuestCorrectFeedback(
        burst: (_) => burstCalls++,
        sound: () => soundCalls++,
        haptic: () => hapticCalls++,
      );
      // 데이터 픽스처는 위 `_engines` 목록과 동일 — 재사용.
      final Widget quest = switch (engine) {
        'listening' => HoerverstehenQuest(
          data: const {
            'audioKo': '안녕',
            'question': {
              'de': 'Was bedeutet dieser Satz?',
              'en': 'What does this sentence mean?',
            },
            'instruction': {
              'de': 'Wähle die passende Bedeutung.',
              'en': 'Choose the matching meaning.',
            },
            'correctIndex': 0,
            'options': [
              {'de': 'Hallo', 'en': 'Hello'},
              {'de': 'Danke', 'en': 'Thanks'},
            ],
          },
          onComplete: (_) {},
          correctFeedback: feedback,
        ),
        'translation' => UebersetzenQuest(
          data: const {
            'promptDe': 'Hallo',
            'promptEn': 'Hello',
            'correctIndex': 0,
            'options': [
              {'ko': '안녕'},
              {'ko': '감사'},
            ],
          },
          onComplete: (_) {},
          correctFeedback: feedback,
        ),
        'cloze' => LueckenQuest(
          data: const {
            'sentence': '안___',
            'correctIndex': 0,
            'options': ['녕', '녕히'],
          },
          onComplete: (_) {},
          correctFeedback: feedback,
        ),
        'particle' => ParticlePopQuest(
          data: const {
            'prefix': '저',
            'suffix': ' 학생이에요.',
            'correctIndex': 0,
            'options': ['는', '가'],
            'explanationDe': 'Nach einem Vokal steht 는.',
            'explanationEn': 'Use 는 after a vowel.',
          },
          onComplete: (_) {},
          correctFeedback: feedback,
        ),
        'batchim' => BatchimDropQuest(
          data: const {
            'audioKo': '안녕',
            'targetWord': '안녕',
            'targetSyllableIndex': 1,
            'correctIndex': 0,
            'options': ['ㅇ', 'ㄴ'],
          },
          onComplete: (_) {},
          correctFeedback: feedback,
        ),
        'sentence' => SatzBauenQuest(
          data: const {
            'targetKo': '안녕 하세요',
            'promptDe': 'Sage höflich Hallo.',
            'promptEn': 'Say hello politely.',
            'audioKo': '안녕 하세요',
            'distractors': ['감사'],
          },
          onComplete: (_) {},
          correctFeedback: feedback,
        ),
        'dictation' => DiktatQuest(
          data: const {
            'targetKo': '안녕 하세요',
            'audioKo': '안녕 하세요',
            'promptDe': 'Sage höflich Hallo.',
            'promptEn': 'Say hello politely.',
          },
          onComplete: (_) {},
          correctFeedback: feedback,
        ),
        _ => throw StateError('Unknown quest engine: $engine'),
      };
      await _pumpQuest(
        tester,
        quest,
        locale: const Locale('en'),
        viewport: _viewports[2],
      );

      await _enterCorrectResponse(tester, engine);
      if (engine != 'listening') {
        await _tapPointerOwned(
          tester,
          find.byKey(const ValueKey('quest-submit')),
        );
      }
      await tester.pump();

      expect(burstCalls, 1, reason: engine);
      expect(soundCalls, 1, reason: engine);
      expect(hapticCalls, 1, reason: engine);
    }
  });

  testWidgets(
    'success keeps a live announcement without a duplicate lower label',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final t = lookupAppL10n(const Locale('en'));
        await _pumpQuest(
          tester,
          ScenarioQuestAction(
            canSubmit: true,
            onSubmit: () {},
            resolved: true,
            onContinue: () {},
          ),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );

        expect(find.text(t.questCorrect), findsNothing);
        _expectLiveRegion(tester, t.questCorrect);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets(
      '${locale.languageCode} choice flow exposes executable selected and live '
      'result semantics',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final t = lookupAppL10n(locale);
          final results = <QuestResult>[];
          var continueCalls = 0;
          await _pumpQuest(
            tester,
            _engines
                .singleWhere((engine) => engine.name == 'translation')
                .build(results.add, () => continueCalls++, false),
            locale: locale,
            viewport: _viewports[2],
          );

          const correctLabel = '안녕';
          const wrongLabel = '감사';
          final wrong = find.bySemanticsLabel(wrongLabel);
          _expectButton(tester, wrong, enabled: true, minHeight: 48);
          _expectBoundaryContrast(tester, wrong);
          await _tapPointerOwned(tester, wrong);

          final selectedWrong = find.bySemanticsLabel(
            '$wrongLabel, ${t.questAnswerSelected}',
          );
          _expectButton(
            tester,
            selectedWrong,
            enabled: true,
            selected: ui.Tristate.isTrue,
            minHeight: 48,
          );
          final submit = find.bySemanticsLabel(t.questCheckAnswer);
          _expectButton(tester, submit, enabled: true, minHeight: 48);
          await _tapPointerOwned(tester, submit);
          _expectLiveRegion(tester, t.questTryAgainHint);
          _expectTextContrast(tester, t.questTryAgainHint);

          final correct = find.bySemanticsLabel(correctLabel);
          await _tapPointerOwned(tester, correct);
          await _tapPointerOwned(tester, submit);

          expect(results, hasLength(1));
          expect(results.single.passed, isTrue);
          _expectLiveRegion(tester, t.questCorrect);
          final resolved = find.bySemanticsLabel(
            '$correctLabel, ${t.questCorrect}',
          );
          _expectButton(
            tester,
            resolved,
            enabled: false,
            selected: ui.Tristate.isTrue,
            minHeight: 48,
          );

          final next = find.bySemanticsLabel(t.questNext);
          _expectButton(tester, next, enabled: true, minHeight: 48);
          await _tapPointerOwned(tester, next);
          expect(continueCalls, 1);
          _expectNoException(tester);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'dictation uses localized fields and paired 56dp audio and word block '
    'semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final t = lookupAppL10n(const Locale('en'));
        await _pumpQuest(
          tester,
          _engines.last.build((_) {}, () {}, false),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );

        final listen = find.bySemanticsLabel(t.questListenAudio);
        _expectButton(tester, listen, enabled: true, minHeight: 56);
        expect(tester.getSize(listen).height, 56);
        expect(
          find.descendant(of: listen, matching: find.text(t.questListenAudio)),
          findsOneWidget,
        );
        _expectSemanticsHides(tester, listen, const ['안녕', '하세요']);
        final slow = find.bySemanticsLabel(t.diktatListenSlow);
        _expectButton(tester, slow, enabled: true, minHeight: 56);
        expect(tester.getSize(slow).height, 56);
        expect(
          find.descendant(of: slow, matching: find.text(t.diktatListenSlow)),
          findsOneWidget,
        );
        _expectSemanticsHides(tester, slow, const ['안녕', '하세요']);
        final field = tester.widget<SoriTextField>(find.byType(SoriTextField));
        expect(field.fieldKey, const ValueKey('diktat-answer-field'));
        expect(field.labelText, t.diktatAnswerLabel);

        final mode = find.bySemanticsLabel(t.diktatUseWordBlocks);
        _expectButton(tester, mode, enabled: true, minHeight: 48);
        await _tapPointerOwned(tester, mode);

        final available = find.bySemanticsLabel('안녕');
        _expectButton(tester, available, enabled: true, minHeight: 48);
        await _tapPointerOwned(tester, available);
        final selected = find.bySemanticsLabel('안녕, ${t.questAnswerSelected}');
        _expectButton(
          tester,
          selected,
          enabled: true,
          selected: ui.Tristate.isTrue,
          minHeight: 48,
        );
        expect(
          find.descendant(
            of: selected,
            matching: find.byIcon(Icons.remove_circle_outline_rounded),
          ),
          findsOneWidget,
        );
        _expectButton(
          tester,
          find.bySemanticsLabel(t.questCheckAnswer),
          enabled: true,
          minHeight: 48,
        );
        _expectNoException(tester);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'batchim particle and sentence audio controls keep non-color and reduced '
    'motion contracts',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final t = lookupAppL10n(const Locale('en'));
        final listening = _engines.singleWhere(
          (engine) => engine.name == 'listening',
        );
        await _pumpQuest(
          tester,
          listening.build((_) {}, () {}, false),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );
        final listeningReplay = find.bySemanticsLabel(
          'What does this sentence mean? ${t.questReplayAudio}',
        );
        _expectButton(tester, listeningReplay, enabled: true, minHeight: 48);
        _expectSemanticsHides(tester, listeningReplay, const ['안녕']);

        final batchim = _engines.singleWhere(
          (engine) => engine.name == 'batchim',
        );
        await _pumpQuest(
          tester,
          batchim.build((_) {}, () {}, false),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );
        final batchimListen = find.bySemanticsLabel(t.questListenAudio);
        _expectButton(tester, batchimListen, enabled: true, minHeight: 84);
        _expectSemanticsHides(tester, batchimListen, const ['안녕']);
        expect(_batchimSlot(tester).duration, Duration.zero);
        _expectAnimatedBoundaryContrast(_batchimSlot(tester));

        final particle = _engines.singleWhere(
          (engine) => engine.name == 'particle',
        );
        await _pumpQuest(
          tester,
          particle.build((_) {}, () {}, false),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );
        final replay = find.bySemanticsLabel(t.questReplayAudio);
        _expectButton(tester, replay, enabled: true, minHeight: 48);
        _expectSemanticsHides(tester, replay, const ['저는 학생이에요']);
        expect(
          tester
              .widget<SoriButton>(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is SoriButton &&
                      widget.label == t.questReplayAudio,
                ),
              )
              .variant,
          SoriButtonVariant.outlined,
        );
        expect(_particleSlot(tester).duration, Duration.zero);
        _expectAnimatedBoundaryContrast(_particleSlot(tester));
        await _tapPointerOwned(tester, find.bySemanticsLabel('는'));
        _expectLiveRegion(tester, '저는 학생이에요.');

        final sentence = _engines.singleWhere(
          (engine) => engine.name == 'sentence',
        );
        await _pumpQuest(
          tester,
          sentence.build((_) {}, () {}, false),
          locale: const Locale('en'),
          viewport: _viewports[2],
        );
        final sentencePrompt = find.bySemanticsLabel(
          'Say hello politely. ${t.questReplayAudio}',
        );
        _expectButton(tester, sentencePrompt, enabled: true, minHeight: 48);
        _expectSemanticsHides(tester, sentencePrompt, const ['안녕', '하세요']);
        expect(find.byType(QuestLayout), findsOneWidget);
        _expectNoException(tester);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('normal motion retains exact batchim and particle durations', (
    tester,
  ) async {
    final batchim = _engines.singleWhere((engine) => engine.name == 'batchim');
    await _pumpQuest(
      tester,
      batchim.build((_) {}, () {}, false),
      locale: const Locale('de'),
      viewport: _viewports[2],
      disableAnimations: false,
    );
    expect(_batchimSlot(tester).duration, const Duration(milliseconds: 150));

    final particle = _engines.singleWhere(
      (engine) => engine.name == 'particle',
    );
    await _pumpQuest(
      tester,
      particle.build((_) {}, () {}, false),
      locale: const Locale('de'),
      viewport: _viewports[2],
      disableAnimations: false,
    );
    expect(_particleSlot(tester).duration, const Duration(milliseconds: 200));
    _expectNoException(tester);
  });

  testWidgets(
    'all seven reveal paths announce the result and keep an executable '
    'continue action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final t = lookupAppL10n(const Locale('en'));
        for (final engine in _engines) {
          final results = <QuestResult>[];
          await _pumpQuest(
            tester,
            engine.build(results.add, () {}, true),
            locale: const Locale('en'),
            viewport: _viewports[2],
          );
          await _tapPointerOwned(
            tester,
            find.bySemanticsLabel(t.questDontKnowYet),
          );
          expect(results, hasLength(1), reason: engine.name);
          expect(results.single.passed, isFalse, reason: engine.name);
          _expectLiveRegion(
            tester,
            engine.revealHintEn ?? t.questAnswerRevealed,
          );
          _expectButton(
            tester,
            find.bySemanticsLabel(t.questNext),
            enabled: true,
            minHeight: 48,
          );
          _expectNoException(tester, reason: engine.name);
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  // Fix round 1 (Fable 룰링, 2026-09-04): STEP 0에서 tool/generate_tts.py의
  // collect()를 직접 읽고 실제 콘텐츠(assets/data/scenarios_*.json)로
  // 재확인한 결과 -- particlePop만 _fullSentence
  // (prefix+options[correctIndex]+suffix)를 모든 퀘스트에 대해 무조건
  // 수집하는 전용 분기가 있어 canonical corpus 소속이 보장된다. luecken
  // (빈칸 채운 완성문)과 uebersetzen(options[correctIndex].ko)은 전용
  // 수집 분기가 없다 -- 다른 소스(예: 시나리오 대화문)와 텍스트가 우연히
  // 같을 때만 canonical이었고, 실측 예시 각 3건 중 1건만 canonical이었다
  // (2/3 miss, task-1-report.md STEP 0 표 참고). 그래서:
  //  - 세 엔진 모두 진입 시 무음이다(entry autoplay 제거, Fix round 1 (a)).
  //  - particlePop만 답 공개 직후(정답이든 2회 오답 소진 뒤 공개든) 정답
  //    문장을 1회 읽는다(Fix round 1 (b)).
  //  - luecken·uebersetzen은 답 공개 후에도 계속 무음이다 -- "정답을
  //    canonical corpus에서 못 찾음" 배너가 뜨는 걸 알면서 배선하지
  //    않는다(blocked on canonical corpus -> W9-C 콘텐츠 파이프라인行).
  group('선택형 퀘스트는 진입 시 무음이고, particlePop만 답 공개 후 정답 문장을 1회 읽는다', () {
    testWidgets('luecken은 정답 공개 후에도 무음이다(canonical 아님)', (tester) async {
      final stub = stubSoriSpeech();
      await _pumpQuest(
        tester,
        LueckenQuest(
          data: const {
            'sentence': '안___',
            'correctIndex': 0,
            'options': ['녕', '녕히'],
          },
          onComplete: (_) {},
          onContinue: () {},
        ),
        locale: const Locale('de'),
        viewport: _viewports[2],
      );
      expect(stub.spoken, isEmpty, reason: '진입 시 무음');

      await _tapPointerOwned(tester, find.byKey(const ValueKey('answer-0')));
      await _tapPointerOwned(
        tester,
        find.byKey(const ValueKey('quest-submit')),
      );

      expect(stub.spoken, isEmpty, reason: '답 공개 후에도 무음');
    });

    testWidgets('luecken은 2회 오답 공개 후에도 무음이다', (tester) async {
      final stub = stubSoriSpeech();
      await _pumpQuest(
        tester,
        LueckenQuest(
          data: const {
            'sentence': '안___',
            'correctIndex': 0,
            'options': ['녕', '녕히'],
          },
          onComplete: (_) {},
          onContinue: () {},
        ),
        locale: const Locale('de'),
        viewport: _viewports[2],
      );

      final wrong = find.byKey(const ValueKey('answer-1'));
      final submit = find.byKey(const ValueKey('quest-submit'));
      await _tapPointerOwned(tester, wrong);
      await _tapPointerOwned(tester, submit);
      await _tapPointerOwned(tester, wrong);
      await _tapPointerOwned(tester, submit);

      expect(stub.spoken, isEmpty);
    });

    testWidgets('uebersetzen은 정답 공개 후에도 무음이다(canonical 아님)', (tester) async {
      final stub = stubSoriSpeech();
      await _pumpQuest(
        tester,
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
          onComplete: (_) {},
          onContinue: () {},
        ),
        locale: const Locale('de'),
        viewport: _viewports[2],
      );
      expect(stub.spoken, isEmpty, reason: '진입 시 무음');

      await _tapPointerOwned(tester, find.byKey(const ValueKey('answer-0')));
      await _tapPointerOwned(
        tester,
        find.byKey(const ValueKey('quest-submit')),
      );

      expect(stub.spoken, isEmpty, reason: '답 공개 후에도 무음');
    });

    testWidgets('uebersetzen은 2회 오답 공개 후에도 무음이다', (tester) async {
      final stub = stubSoriSpeech();
      await _pumpQuest(
        tester,
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
          onComplete: (_) {},
          onContinue: () {},
        ),
        locale: const Locale('de'),
        viewport: _viewports[2],
      );

      final wrong = find.byKey(const ValueKey('answer-1'));
      final submit = find.byKey(const ValueKey('quest-submit'));
      await _tapPointerOwned(tester, wrong);
      await _tapPointerOwned(tester, submit);
      await _tapPointerOwned(tester, wrong);
      await _tapPointerOwned(tester, submit);

      expect(stub.spoken, isEmpty);
    });

    testWidgets('particlePop은 진입 시 무음이고 정답 공개 직후 완성 문장을 1회 읽는다', (
      tester,
    ) async {
      final stub = stubSoriSpeech();
      await _pumpQuest(
        tester,
        ParticlePopQuest(
          data: const {
            'prefix': '저',
            'suffix': ' 학생이에요.',
            'correctIndex': 0,
            'options': ['는', '가'],
            'explanationDe': 'Nach einem Vokal steht 는.',
            'explanationEn': 'Use 는 after a vowel.',
          },
          onComplete: (_) {},
          onContinue: () {},
        ),
        locale: const Locale('de'),
        viewport: _viewports[2],
      );
      expect(stub.spoken, isEmpty, reason: '진입 시 무음');

      await _tapPointerOwned(tester, find.byKey(const ValueKey('answer-0')));
      await _tapPointerOwned(
        tester,
        find.byKey(const ValueKey('quest-submit')),
      );

      expect(stub.spoken, ['저는 학생이에요.']);
    });

    testWidgets('particlePop은 2회 오답 공개 직후 완성 문장을 1회 읽는다', (tester) async {
      final stub = stubSoriSpeech();
      await _pumpQuest(
        tester,
        ParticlePopQuest(
          data: const {
            'prefix': '저',
            'suffix': ' 학생이에요.',
            'correctIndex': 0,
            'options': ['는', '가'],
            'explanationDe': 'Nach einem Vokal steht 는.',
            'explanationEn': 'Use 는 after a vowel.',
          },
          onComplete: (_) {},
          onContinue: () {},
        ),
        locale: const Locale('de'),
        viewport: _viewports[2],
      );
      expect(stub.spoken, isEmpty, reason: '진입 시 무음');

      final wrong = find.byKey(const ValueKey('answer-1'));
      final submit = find.byKey(const ValueKey('quest-submit'));
      await _tapPointerOwned(tester, wrong);
      await _tapPointerOwned(tester, submit);
      expect(stub.spoken, isEmpty, reason: '1회 오답만으로는 아직 결과가 공개되지 않는다');
      await _tapPointerOwned(tester, wrong);
      await _tapPointerOwned(tester, submit);

      expect(stub.spoken, ['저는 학생이에요.']);
    });

    testWidgets('particlePop은 audioEnabled=false면 답 공개 후에도 읽지 않는다', (
      tester,
    ) async {
      final stub = stubSoriSpeech();
      await _pumpQuest(
        tester,
        ParticlePopQuest(
          data: const {
            'prefix': '저',
            'suffix': ' 학생이에요.',
            'correctIndex': 0,
            'options': ['는', '가'],
            'explanationDe': 'Nach einem Vokal steht 는.',
            'explanationEn': 'Use 는 after a vowel.',
          },
          audioEnabled: false,
          onComplete: (_) {},
          onContinue: () {},
        ),
        locale: const Locale('de'),
        viewport: _viewports[2],
      );

      await _tapPointerOwned(tester, find.byKey(const ValueKey('answer-0')));
      await _tapPointerOwned(
        tester,
        find.byKey(const ValueKey('quest-submit')),
      );

      expect(stub.spoken, isEmpty);
    });

    testWidgets(
      'particlePop: 2회 오답 공개 딜레이 중 위젯이 사라지면 mounted 가드가 발화를 막는다 (PR2 리뷰 Important 1)',
      (tester) async {
        final stub = stubSoriSpeech();
        // disableAnimations: false — _checkSelection의 200ms 지연을 실제로
        // 흐르게 해야 그 도중에 dispose할 수 있다(instant 경로는 지연 없이
        // 동기로 끝나 버려 이 회귀를 재현하지 못한다).
        await _pumpQuest(
          tester,
          ParticlePopQuest(
            data: const {
              'prefix': '저',
              'suffix': ' 학생이에요.',
              'correctIndex': 0,
              'options': ['는', '가'],
              'explanationDe': 'Nach einem Vokal steht 는.',
              'explanationEn': 'Use 는 after a vowel.',
            },
            onComplete: (_) {},
            onContinue: () {},
          ),
          locale: const Locale('de'),
          viewport: _viewports[2],
          disableAnimations: false,
        );

        final wrong = find.byKey(const ValueKey('answer-1'));
        final submit = find.byKey(const ValueKey('quest-submit'));

        // 1회차 오답 — 그 200ms 플래시 지연을 먼저 흘려보낸다.
        await _tapPointerOwned(tester, wrong);
        await _tapPointerOwned(tester, submit);
        await tester.pump(const Duration(milliseconds: 250));

        // 2회차 오답(소진) — 첫 200ms 플래시 지연은 흘려보낸다(그 안의
        // `setState`는 mounted 가드가 없는 별개의 기존 결함이라 disposed
        // 상태로 통과시키면 이 테스트가 다른 이유로 실패한다 — PR2 리뷰
        // Minor 참고, 범위 밖). 그 다음 이어지는 "정답 공개" 200ms 지연
        // (`await Future<void>.delayed(200ms)`, particle_pop_quest.dart:164)
        // 도중에 위젯을 화면에서 치운다. mounted 가드가 없으면 다음 화면에서
        // SoriSpeech.speak(_fullSentence)가 새로 시작해 버린다
        // (particle_pop_quest.dart:167-169).
        await _tapPointerOwned(tester, wrong);
        await _tapPointerOwned(tester, submit);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 400));

        expect(stub.spoken, isEmpty, reason: 'dispose 후에는 발화하지 않아야 한다');
        expect(tester.takeException(), isNull);
      },
    );
  });

  group(
    'SoriGaps.optionGap — 선택형 퀘스트 4종의 옵션 타일 사이 간격은 12dp (지시서 4.8/4.10)',
    () {
      for (final engineName in const [
        'listening',
        'translation',
        'cloze',
        'particle',
      ]) {
        testWidgets('$engineName: 첫 두 옵션 타일 사이 SizedBox 높이는 12', (tester) async {
          final engine = _engines.singleWhere((e) => e.name == engineName);
          await _pumpQuest(
            tester,
            engine.build((_) {}, () {}, false),
            locale: const Locale('de'),
            viewport: _viewports[2],
          );

          final tile0 = find.byKey(const ValueKey('answer-0'));
          final tile1 = find.byKey(const ValueKey('answer-1'));
          expect(tile0, findsOneWidget);
          expect(tile1, findsOneWidget);

          final gap =
              tester.getTopLeft(tile1).dy - tester.getBottomLeft(tile0).dy;
          expect(
            gap,
            moreOrLessEquals(SoriGaps.optionGap, epsilon: 0.5),
            reason:
                '$engineName 옵션 타일 사이 간격이 SoriGaps.optionGap(12)이 아니다 '
                '(실측 $gap)',
          );
        });
      }
    },
  );

  group(
    'SoriGaps.questionToOptions — 선택형 퀘스트 4종의 질문 영역과 첫 옵션 타일 사이 간격은 '
    '24dp (지시서 4.8/4.10)',
    () {
      for (final engineName in const [
        'listening',
        'translation',
        'cloze',
        'particle',
      ]) {
        testWidgets('$engineName: 질문 영역과 첫 옵션 타일 사이 간격은 24', (tester) async {
          final engine = _engines.singleWhere((e) => e.name == engineName);
          await _pumpQuest(
            tester,
            engine.build((_) {}, () {}, false),
            locale: const Locale('de'),
            viewport: _viewports[2],
          );

          final tile0 = find.byKey(const ValueKey('answer-0'));
          expect(tile0, findsOneWidget);

          // 4개 엔진 모두 `content` Column에서 옵션 목록 바로 앞에
          // `const SizedBox(height: SoriGaps.questionToOptions)`를 정확히
          // 1개만 둔다 — 그 SizedBox의 위쪽 끝이 곧 질문 영역의 아래쪽
          // 끝이다(둘 사이엔 다른 위젯이 없다).
          final questionGap = find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox &&
                widget.height == SoriGaps.questionToOptions,
          );
          expect(
            questionGap,
            findsOneWidget,
            reason:
                '$engineName: SoriGaps.questionToOptions SizedBox이 정확히 '
                '1개여야 한다',
          );

          final gap =
              tester.getTopLeft(tile0).dy - tester.getTopLeft(questionGap).dy;
          expect(
            gap,
            moreOrLessEquals(24, epsilon: 0.5),
            reason:
                '$engineName 질문 영역과 첫 옵션 타일 사이 간격이 24dp가 아니다 '
                '(실측 $gap)',
          );
        });
      }
    },
  );
}

Future<void> _pumpQuest(
  WidgetTester tester,
  Widget child, {
  required Locale locale,
  required ({Size size, double textScale}) viewport,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: _safeInsets,
            viewPadding: _safeInsets,
            textScaler: TextScaler.linear(viewport.textScale),
            disableAnimations: disableAnimations,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: Scaffold(
        body: SafeArea(
          child: SizedBox.expand(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _enterCorrectResponse(
  WidgetTester tester,
  String engineName,
) async {
  switch (engineName) {
    case 'listening':
    case 'translation':
    case 'cloze':
    case 'particle':
    case 'batchim':
      await _tapPointerOwned(tester, find.byKey(const ValueKey('answer-0')));
      break;
    case 'sentence':
      await _tapPointerOwned(tester, find.bySemanticsLabel('안녕'));
      await _tapPointerOwned(tester, find.bySemanticsLabel('하세요'));
      break;
    case 'dictation':
      final input = find.byKey(const ValueKey('diktat-answer-field'));
      final editable = find.descendant(
        of: input,
        matching: find.byType(EditableText),
      );
      _expectEditableField(tester, input, editable);
      await _tapPointerOwned(tester, input);
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(input, '안녕 하세요');
      await tester.pump();
      break;
    default:
      fail('Unknown quest engine: $engineName');
  }
}

String _correctResultLabel(String engineName, Locale locale, AppL10n t) =>
    switch (engineName) {
      'batchim' =>
        locale.languageCode == 'de' ? '녕 endet mit ㅇ.' : '녕 ends with ㅇ.',
      'particle' =>
        locale.languageCode == 'de'
            ? 'Nach einem Vokal steht 는.'
            : 'Use 는 after a vowel.',
      _ => t.questCorrect,
    };

void _expectButton(
  WidgetTester tester,
  Finder finder, {
  required bool enabled,
  required double minHeight,
  ui.Tristate? selected,
}) {
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(
    data.flagsCollection.isEnabled,
    enabled ? ui.Tristate.isTrue : ui.Tristate.isFalse,
  );
  expect(data.hasAction(ui.SemanticsAction.tap), enabled);
  if (selected != null) {
    expect(data.flagsCollection.isSelected, selected);
  }
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(minHeight));
}

void _expectEditableField(
  WidgetTester tester,
  Finder hitTarget,
  Finder editable,
) {
  expect(hitTarget, findsOneWidget);
  expect(editable, findsOneWidget);
  final data = tester.getSemantics(editable).getSemanticsData();
  expect(data.flagsCollection.isTextField, isTrue);
  expect(data.flagsCollection.isReadOnly, isFalse);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  expect(tester.getSize(hitTarget).height, greaterThanOrEqualTo(48));
}

void _expectSemanticsHides(
  WidgetTester tester,
  Finder finder,
  Iterable<String> hiddenFragments,
) {
  final label = tester.getSemantics(finder).getSemanticsData().label;
  for (final fragment in hiddenFragments) {
    expect(label, isNot(contains(fragment)));
  }
}

void _expectLiveRegion(WidgetTester tester, String label) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.liveRegion == true &&
        widget.properties.label == label,
  );
  expect(finder, findsOneWidget, reason: 'Expected live label: $label');
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

void _expectBoundaryContrast(WidgetTester tester, Finder control) {
  final animated = find.descendant(
    of: control,
    matching: find.byType(AnimatedContainer),
  );
  expect(animated, findsOneWidget);
  _expectAnimatedBoundaryContrast(tester.widget<AnimatedContainer>(animated));
}

void _expectAnimatedBoundaryContrast(AnimatedContainer container) {
  final decoration = container.decoration! as BoxDecoration;
  final border = decoration.border! as Border;
  expect(
    SoriColors.contrastRatio(border.top.color, SoriColors.lightBg),
    greaterThanOrEqualTo(3),
  );
}

void _expectTextContrast(WidgetTester tester, String label) {
  final text = tester.widget<Text>(find.text(label));
  expect(
    SoriColors.contrastRatio(text.style!.color!, SoriColors.lightBg),
    greaterThanOrEqualTo(4.5),
  );
}

void _expectAnswerIndexContrast(WidgetTester tester, int index) {
  final tile = find.byKey(ValueKey('contrast-answer-$index'));
  final outer = find.descendant(
    of: tile,
    matching: find.byType(AnimatedContainer),
  );
  expect(outer, findsOneWidget);
  final outerDecoration =
      tester.widget<AnimatedContainer>(outer).decoration! as BoxDecoration;
  final outerBackground = Color.alphaBlend(
    outerDecoration.color!,
    SoriColors.lightBg,
  );
  final circle = find.descendant(
    of: tile,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    ),
  );
  expect(circle, findsOneWidget);
  final circleDecoration =
      tester.widget<DecoratedBox>(circle).decoration as BoxDecoration;
  final circleBackground = Color.alphaBlend(
    circleDecoration.color!,
    outerBackground,
  );
  final letter = tester.widget<Text>(
    find.descendant(
      of: circle,
      matching: find.text(String.fromCharCode(65 + index)),
    ),
  );
  expect(
    SoriColors.contrastRatio(letter.style!.color!, circleBackground),
    greaterThanOrEqualTo(4.5),
  );
}

void _expectParticleSlotTextContrast(WidgetTester tester, String label) {
  final slot = _particleSlotFinder();
  final container = tester.widget<AnimatedContainer>(slot);
  final decoration = container.decoration! as BoxDecoration;
  final background = Color.alphaBlend(
    decoration.color!,
    SoriColors.lightSurface,
  );
  final text = tester.widget<Text>(
    find.descendant(of: slot, matching: find.text(label)),
  );
  expect(
    SoriColors.contrastRatio(text.style!.color!, background),
    greaterThanOrEqualTo(4.5),
  );
}

void _expectVisibleInView(WidgetTester tester, Finder finder, Size viewport) {
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThan(0));
  expect(rect.height, greaterThan(0));
  expect((Offset.zero & viewport).overlaps(rect), isTrue);
}

Future<void> _tapPointerOwned(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(
    finder.evaluate().single,
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pump();
  final gesture = find.descendant(
    of: finder,
    matching: find.byType(GestureDetector),
  );
  final target = gesture.evaluate().length == 1 ? gesture : finder;
  final box = tester.renderObject<RenderBox>(target);
  final point = _ownedHitPoint(tester, box);
  expect(point, isNotNull, reason: 'Control has no pointer-owned hit point.');
  final previous = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  try {
    await tester.tapAt(point!);
    await tester.pump();
  } finally {
    WidgetController.hitTestWarningShouldBeFatal = previous;
  }
}

Offset? _ownedHitPoint(WidgetTester tester, RenderBox targetBox) {
  const candidates = <Offset>[
    Offset(0.5, 0.5),
    Offset(0.25, 0.5),
    Offset(0.75, 0.5),
    Offset(0.5, 0.25),
    Offset(0.5, 0.75),
  ];
  for (final fraction in candidates) {
    final point = targetBox.localToGlobal(
      Offset(
        targetBox.size.width * fraction.dx,
        targetBox.size.height * fraction.dy,
      ),
    );
    final result = HitTestResult();
    tester.binding.hitTestInView(result, point, tester.view.viewId);
    if (result.path.any((entry) => identical(entry.target, targetBox))) {
      return point;
    }
  }
  return null;
}

AnimatedContainer _batchimSlot(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
    .singleWhere(
      (widget) =>
          widget.constraints?.maxWidth == 60 &&
          widget.constraints?.maxHeight == 40,
    );

Finder _particleSlotFinder() => find.byWidgetPredicate(
  (widget) =>
      widget is AnimatedContainer &&
      widget.constraints?.maxWidth == 64 &&
      widget.constraints?.maxHeight == 40,
);

AnimatedContainer _particleSlot(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_particleSlotFinder());

void _expectNoException(WidgetTester tester, {String? reason}) {
  expect(tester.takeException(), isNull, reason: reason);
}
