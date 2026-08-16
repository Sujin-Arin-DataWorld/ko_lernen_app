import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/theme.dart';

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
  dialog: [],
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
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('quest-submit')), findsOneWidget);
    });
  }

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
}

Widget _host({
  required double textScale,
  required bool dark,
  required int questIndex,
  double keyboardInset = 0,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: child!,
    );
  },
  home: ScenarioPlayerScreen.preview(
    fixture: ScenarioPlayerPreviewFixture.action(
      scenario: _responsiveScene,
      stage: ScenarioStage.quest,
      questIndex: questIndex,
    ),
  ),
);
