// 브리프 A3 — 듣기 아이콘 좌상단 통일 (지시서 2.9). 6표면 각각에서
// SoriSpeechIndicator 가 그 표면의 카드(SoriCard/SoriContentFeed 조상)
// 좌상단 8dp 부근에 있는지 — 하단 중앙/우측 정렬로 회귀하지 않는지 — 를
// rect 비교로 고정한다. 360x640 1개 뷰포트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
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
}
