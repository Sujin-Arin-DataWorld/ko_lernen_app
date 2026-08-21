import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
import 'package:ko_lernen_app/screens/word_web_screen.dart';
import 'package:ko_lernen_app/screens/word_web_study_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_wordWeb': true});
    await Storage.init();
    await Storage.setTutSeen('wordWeb');
  });

  testWidgets('filters and pronunciation actions expose the shared contract', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      child: _hub(),
      size: const Size(390, 844),
      textScale: 1.3,
      locale: const Locale('en'),
    );
    await _finishLoad(tester);

    final filters = <Finder>[
      find.byKey(const ValueKey('word-web-filter-learned')),
      find.byKey(const ValueKey('word-web-filter-level')),
    ];
    for (final filter in filters) {
      expect(filter, findsOneWidget);
      final chip = tester.widget<SoriChip>(filter);
      expect(chip.maxLines, isNull);
      expect(chip.minInteractiveHeight, greaterThanOrEqualTo(48));
      expect(tester.getSize(filter).height, greaterThanOrEqualTo(48));
    }
    final selected = tester.widget<SoriChip>(filters.first);
    expect(selected.selected, isTrue);
    expect(selected.icon, Icons.check_rounded);

    final hubAudio = find.byTooltip('Pronunciation: 크다');
    expect(hubAudio, findsOneWidget);
    expect(tester.getSize(hubAudio).shortestSide, greaterThanOrEqualTo(48));
    final audioData = tester.getSemantics(hubAudio).getSemanticsData();
    expect(audioData.flagsCollection.isButton, isTrue);
    expect(audioData.hasAction(ui.SemanticsAction.tap), isTrue);

    await tester.tap(find.byKey(const ValueKey('big')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (final label in const [
      'Pronunciation: 크다',
      'Pronunciation: 커다랗다',
      'Pronunciation: 큰일 나다',
      'Pronunciation: 큰일 나다 예문',
    ]) {
      final action = find.descendant(
        of: find.byType(WordWebStudyScreen),
        matching: find.byTooltip(label),
      );
      if (action.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          action,
          220,
          scrollable: find.byType(Scrollable).last,
        );
      }
      expect(action, findsOneWidget);
      expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'DE and EN hub and study content reflow across the locked matrix',
    (tester) async {
      const cases = <({Size size, double scale})>[
        (size: Size(320, 640), scale: 2),
        (size: Size(360, 400), scale: 1),
        (size: Size(390, 844), scale: 1.3),
        (size: Size(720, 1024), scale: 1.3),
        (size: Size(1280, 900), scale: 1.3),
      ];

      for (final locale in const [Locale('de'), Locale('en')]) {
        for (final testCase in cases) {
          await _pump(
            tester,
            child: _hub(
              key: ValueKey(
                'hub-${locale.languageCode}-${testCase.size.width}',
              ),
            ),
            size: testCase.size,
            textScale: testCase.scale,
            locale: locale,
          );
          await _finishLoad(tester);

          expect(find.text('크다'), findsOneWidget);
          expect(find.byKey(const ValueKey('word-web-quiz')), findsOneWidget);
          expect(tester.takeException(), isNull);

          await _pump(
            tester,
            child: const WordWebStudyScreen(cluster: _cluster),
            size: testCase.size,
            textScale: testCase.scale,
            locale: locale,
          );
          final expression = find.text('큰일 나다');
          await tester.scrollUntilVisible(
            expression,
            240,
            scrollable: find.byType(Scrollable).last,
          );
          expect(expression, findsOneWidget);
          expect(find.text('큰일 나다 예문'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}

WordWebScreen _hub({Key? key}) => WordWebScreen(
  key: key,
  clusterLoader: () async => const [_cluster],
  seenLoader: () => const {'크다'},
  levelLoader: () => LearnerLevel.a1,
);

const _cluster = WordRelationCluster(
  id: 'big',
  sourceKo: '크다',
  sourceVocabId: 'vocab_big',
  sourceDe: 'groß',
  sourceEn: 'big',
  level: 'A1',
  synonyms: [WordNeighbor(ko: '커다랗다', de: 'sehr groß', en: 'very big')],
  expressions: [
    WordExpression(
      ko: '큰일 나다',
      de: 'in Schwierigkeiten geraten',
      en: 'get into trouble',
      exampleKo: '큰일 나다 예문',
      exampleDe: 'Ein Beispielsatz.',
      exampleEn: 'An example sentence.',
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required double textScale,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: child,
    ),
  );
  await tester.pump();
}

Future<void> _finishLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
