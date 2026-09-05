// 브리프 A3 — 듣기 아이콘 좌상단 통일 (지시서 2.9). 6표면 각각에서
// SoriSpeechIndicator 가 그 표면의 카드(SoriCard/SoriContentFeed 조상)
// 좌상단 8dp 부근에 있는지 — 하단 중앙/우측 정렬로 회귀하지 않는지 — 를
// rect 비교로 고정한다. 360x640 1개 뷰포트.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

import 'support/sori_speech_stubs.dart';

const _viewport = Size(360, 640);

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// [korean] 을 그리는 카드(SoriCard 조상)와 그 안의 [SoriSpeechIndicator]가
/// 좌상단 24dp 이내로 붙어 있는지 검증한다 — 덱 스택이 다음 카드의 underlay
/// 앞면도 같이 그려 인디케이터가 2개 이상 잡힐 수 있으므로, 실제로 보이는
/// 카드([korean] 텍스트를 담은 SoriCard)를 앵커로 스코프를 좁힌다.
void expectIndicatorAtCardTopLeft(
  WidgetTester tester, {
  required String korean,
}) {
  final cardFinder = find.ancestor(
    of: find.text(korean),
    matching: find.byType(SoriCard),
  );
  expect(cardFinder, findsOneWidget, reason: '"$korean" 을 담은 SoriCard 를 못 찾음');
  // 인디케이터는 이제 카드 렌더 rect 기준 Positioned 로 그 카드의 형제다
  // (content_feed.dart topAccessory 와 같은 좌표계) — 카드를 감싸는 가장
  // 가까운 Stack(그 표면의 build()가 반환하는 로컬 Stack, 덱 언더레이의
  // 상위 Stack이 아니다) 안에서 인디케이터를 찾는다.
  final localStack = find
      .ancestor(of: cardFinder, matching: find.byType(Stack))
      .first;
  final indicatorFinder = find.descendant(
    of: localStack,
    matching: find.byType(SoriSpeechIndicator),
  );
  expect(indicatorFinder, findsOneWidget);

  final cardRect = tester.getRect(cardFinder);
  final indicatorRect = tester.getRect(indicatorFinder);
  expect(
    indicatorRect.left - cardRect.left,
    inInclusiveRange(-1.0, 24.0),
    reason: '듣기 아이콘이 카드 좌측 모서리에서 24dp 넘게 떨어져 있다',
  );
  expect(
    indicatorRect.top - cardRect.top,
    inInclusiveRange(-1.0, 24.0),
    reason: '듣기 아이콘이 카드 상단 모서리에서 24dp 넘게 떨어져 있다',
  );
}

/// [SoriContentFeed] 의 topAccessory 슬롯을 쓰는 표면(그래머·스몰토크)용 —
/// 슬롯 자체가 이미 Positioned(top: Spacing.sm, left: Spacing.sm) 이므로
/// SoriContentFeed 자신을 카드 앵커로 쓴다.
void expectIndicatorAtContentFeedTopLeft(WidgetTester tester) {
  final feedFinder = find.byType(SoriContentFeed);
  expect(feedFinder, findsOneWidget);
  final indicatorFinder = find.descendant(
    of: feedFinder,
    matching: find.byType(SoriSpeechIndicator),
  );
  expect(indicatorFinder, findsOneWidget);

  final feedRect = tester.getRect(feedFinder);
  final indicatorRect = tester.getRect(indicatorFinder);
  expect(
    indicatorRect.left - feedRect.left,
    inInclusiveRange(-1.0, 24.0),
    reason: '듣기 아이콘이 카드 좌측 모서리에서 24dp 넘게 떨어져 있다',
  );
  expect(
    indicatorRect.top - feedRect.top,
    inInclusiveRange(-1.0, 24.0),
    reason: '듣기 아이콘이 카드 상단 모서리에서 24dp 넘게 떨어져 있다',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('vocab_pack_screen 플립 앞면', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      await Storage.setTutVocabPackSeen();
      await Storage.setTutPackQuizSeen();
      await Storage.setTutPackBossSeen();
    });

    testWidgets('SoriSpeechIndicator 가 카드 좌상단에 있다', (tester) async {
      stubSoriSpeech();
      _setViewport(tester);
      const korean = '하나';
      final pack = VocabPack(
        id: 'a1_placement_1',
        level: 'A1',
        words: [
          Vocab(
            id: 'placement_v1',
            korean: korean,
            romanization: 'hana',
            german: 'eins',
            level: 'A1',
            posDe: 'Zahl',
            exampleKorean: '$korean 예문',
            exampleGerman: 'Beispiel',
            topic: 'test',
            packId: 'a1_placement_1',
            packOrder: 1,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expectIndicatorAtCardTopLeft(tester, korean: korean);
      expect(tester.takeException(), isNull);
    });
  });

  group('custom_pack_play_screen 앞면', () {
    const customPackId = 'cp_placement_test';
    const korean = '도서관';
    final customPackJson = jsonEncode({
      customPackId: {
        'name': 'Placement Test Pack',
        'sourcePageId': 'page_test',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'words': [
          {
            'korean': korean,
            'romanization': 'doseogwan',
            'pos_de': 'N.',
            'translation_de': 'Bibliothek',
            'translation_en': 'Library',
            'example_korean': '$korean 예문',
            'example_de': 'Beispiel',
            'definition_ko': '',
            'image_path': '',
            'saved_to_pack_id': null,
          },
        ],
      },
    });

    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_tut_cpPlay': true,
        'kl_tut_soriDeck': true,
        'kl_tut_wordbook': true,
        'kl_custom_packs_v1': customPackJson,
      });
      await Storage.init();
    });

    testWidgets('SoriSpeechIndicator 가 카드 좌상단에 있다', (tester) async {
      stubSoriSpeech();
      _setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const CustomPackPlayScreen(packId: customPackId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expectIndicatorAtCardTopLeft(tester, korean: korean);
      expect(tester.takeException(), isNull);
    });
  });

  group('cloze_prompt 카드', () {
    const item = ClozeItem(
      level: 'a1',
      sentenceKo: '오늘은 ＿＿＿ 합니다.',
      answer: '공부를',
      fullKo: '오늘은 공부를 합니다.',
      de: 'Heute lerne ich.',
      en: 'Today I study.',
      distractors: ['운동을', '요리를', '독서를'],
    );

    testWidgets('SoriSpeechIndicator 가 카드 좌상단에 있다', (tester) async {
      stubSoriSpeech();
      _setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ClozePromptCard(item: item, lang: 'de', gloss: 'lerne'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final cardFinder = find.byType(SoriCard);
      expect(cardFinder, findsOneWidget);
      final indicatorFinder = find.byType(SoriSpeechIndicator);
      expect(indicatorFinder, findsOneWidget);

      final cardRect = tester.getRect(cardFinder);
      final indicatorRect = tester.getRect(indicatorFinder);
      expect(
        indicatorRect.left - cardRect.left,
        inInclusiveRange(-1.0, 24.0),
      );
      expect(indicatorRect.top - cardRect.top, inInclusiveRange(-1.0, 24.0));
      expect(tester.takeException(), isNull);
    });
  });

  group('grammar_screen 카드', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      await Storage.setTutSeen('grammar');
      await Storage.setTutSeen('soriDeck');
      DataLoader.reset();
      await DataLoader.loadGrammar();
    });

    testWidgets('SoriSpeechIndicator 가 SoriContentFeed 좌상단에 있다', (
      tester,
    ) async {
      stubSoriSpeech();
      _setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: const GrammarScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (find
          .byKey(const Key('grammar-plan-onboarding-sheet'))
          .evaluate()
          .isNotEmpty) {
        await tester.tapAt(const Offset(8, 8));
        await tester.pump(const Duration(milliseconds: 300));
      }

      expectIndicatorAtContentFeedTopLeft(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
