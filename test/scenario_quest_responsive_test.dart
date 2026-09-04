import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';

const _responsiveScene = Scenario(
  id: 'airport_arrival',
  level: LearnerLevel.a1,
  emoji: '✈️',
  register: Register.polite,
  title: LocalizedText(
    ko: '공항 입국',
    de: 'Einreise am Flughafen',
    en: 'Airport arrival',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '한국 처음이세요?',
        'correctIndex': 0,
        'options': [
          {
            'de': 'Sind Sie zum ersten Mal in Korea?',
            'en': 'Is this your first time in Korea?',
          },
          {
            'de': 'Wie lange bleiben Sie geschäftlich in Korea?',
            'en': 'How long are you staying in Korea for business?',
          },
        ],
      },
    ),
    QuestSpec(
      type: QuestType.diktat,
      data: {
        'targetKo': '여권 보여주세요.',
        'audioKo': '여권 보여주세요.',
        'promptDe': 'Zeigen Sie bitte Ihren Pass.',
        'promptEn': 'Please show your passport.',
      },
    ),
    QuestSpec(
      type: QuestType.uebersetzen,
      data: {
        'promptDe': 'Eine Woche.',
        'promptEn': 'A week.',
        'correctIndex': 0,
        'options': [
          {'ko': '일주일이요.'},
          {'ko': '처음이에요.'},
        ],
      },
    ),
    QuestSpec(
      type: QuestType.luecken,
      data: {
        'sentence': '한국 처음___?',
        'correctIndex': 0,
        'options': ['이세요', '이에요'],
      },
    ),
    QuestSpec(
      type: QuestType.particlePop,
      data: {
        'prefix': '저',
        'suffix': ' 학생이에요.',
        'correctIndex': 0,
        'options': ['는', '가'],
      },
    ),
    QuestSpec(
      type: QuestType.batchimDrop,
      data: {
        'audioKo': '안녕',
        'targetWord': '안녕',
        'targetSyllableIndex': 1,
        'correctIndex': 0,
        'options': ['ㅇ', 'ㄴ'],
      },
    ),
    QuestSpec(
      type: QuestType.satzBauen,
      data: {
        'targetKo': '안녕하세요.',
        'promptDe': 'Guten Tag.',
        'promptEn': 'Hello.',
        'audioKo': '안녕하세요.',
      },
    ),
  ],
  dialog: [
    DialogLine(
      speaker: 'officer',
      ko: '여권 보여주세요.',
      de: 'Bitte Ihren Pass.',
      en: 'Passport, please.',
    ),
    DialogLine(
      speaker: 'user',
      ko: '네, 여기 있어요.',
      de: 'Ja, hier bitte.',
      en: 'Yes, here you go.',
    ),
  ],
);

void main() {
  final cases = [
    (const Size(308, 620), 1.0, false),
    (const Size(390, 760), 1.3, false),
    (const Size(480, 860), 2.0, true),
    (const Size(800, 1000), 1.3, true),
  ];

  for (final entry in cases) {
    testWidgets('quest frame fits ${entry.$1.width} at ${entry.$2}x text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(entry.$1);
      await tester.pumpWidget(
        _host(textScale: entry.$2, dark: entry.$3, questIndex: 0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);
      expect(find.text('1 of 7'), findsOneWidget);
      expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
      expect(find.byKey(const ValueKey('answer-1')), findsOneWidget);
    });
  }

  for (final questIndex in const [0, 1, 2, 3, 4, 5, 6]) {
    testWidgets('engine $questIndex fits a 390dp frame', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      await tester.pumpWidget(
        _host(textScale: 1.0, dark: false, questIndex: questIndex),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('quest-submit')),
        questIndex == 0 ? findsNothing : findsOneWidget,
      );
    });
  }

  testWidgets('roleplay frame keeps its CTA on a short phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    await tester.pumpWidget(
      _host(textScale: 1.0, dark: false, questIndex: 0, roleplay: true),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('Build your answer'), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-submit')), findsOneWidget);
  });

  testWidgets('dictation remains usable above a software keyboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    await tester.pumpWidget(
      _host(textScale: 1.3, dark: false, questIndex: 1, keyboardInset: 280),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-submit')), findsOneWidget);
  });

  testWidgets(
    'long title remains complete with 200 percent text and safe area',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          textScale: 2,
          dark: false,
          questIndex: 0,
          locale: const Locale('de'),
          safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
        ),
      );
      await tester.pump();

      final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(SoriAppBar),
          matching: find.text(appBar.title),
        ),
      );
      expect(appBar.title, 'Einreise am Flughafen');
      // §B2(2026-09-03): the frame-owned close (X) is a Semantics button
      // with a label ("Schließen" in de), not an IconButton with a tooltip.
      // `Icon` itself always wraps in its own unlabeled Semantics, so this
      // finds the labeled ancestor directly instead of walking up from the
      // icon.
      expect(
        find.descendant(
          of: find.byType(SoriAppBar),
          matching: find.byIcon(Icons.close_rounded),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Schließen'), findsOneWidget);
      expect(title.maxLines, isNotNull);
      expect(title.overflow, TextOverflow.clip);
      expect(find.text('1 von 7'), findsOneWidget);
      expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
      expect(find.byKey(const ValueKey('answer-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host({
  required double textScale,
  required bool dark,
  required int questIndex,
  double keyboardInset = 0,
  bool roleplay = false,
  Locale locale = const Locale('en'),
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
        padding: safeInsets,
        viewPadding: safeInsets,
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: child!,
    );
  },
  home: ScenarioPlayerScreen.preview(
    fixture: ScenarioPlayerPreviewFixture.action(
      scenario: _responsiveScene,
      stage: roleplay ? ScenarioStage.rollenspiel : ScenarioStage.quest,
      questIndex: questIndex,
    ),
  ),
);
