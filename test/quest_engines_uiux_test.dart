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
        hasSpeed: true,
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
            _expectButton(tester, submit, enabled: false, minHeight: 48);
            _expectVisibleInView(tester, submit, viewport.size);

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
            _expectButton(tester, submit, enabled: true, minHeight: 48);
            await _tapPointerOwned(tester, submit);
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

        final wrong = find.bySemanticsLabel('Thanks');
        await _tapPointerOwned(tester, wrong);
        final submit = find.bySemanticsLabel(t.questCheckAnswer);
        await _tapPointerOwned(tester, submit);
        await _tapPointerOwned(tester, submit);

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
            _engines.first.build(results.add, () => continueCalls++, false),
            locale: locale,
            viewport: _viewports[2],
          );

          final correctLabel = locale.languageCode == 'de' ? 'Hallo' : 'Hello';
          final wrongLabel = locale.languageCode == 'de' ? 'Danke' : 'Thanks';
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
          _expectTextContrast(tester, t.questCorrect);
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
    'dictation uses localized fields and answer-safe 48dp audio and word block '
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
        _expectButton(tester, listen, enabled: true, minHeight: 84);
        _expectSemanticsHides(tester, listen, const ['안녕', '하세요']);
        final slow = find.bySemanticsLabel(t.diktatListenSlow);
        _expectButton(tester, slow, enabled: true, minHeight: 56);
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
