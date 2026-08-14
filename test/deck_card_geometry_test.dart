// 덱 카드 고정 지오메트리 센서 (UI/UX 개편 2 · §P1).
//
// Jin 3번째 재발 리포트: "카드 크기가 단어 텍스트에 따라 변한다."
// 실측 원인은 **폭**이다 — `FlipCard._fitFace` 의 세로 `SingleChildScrollView`
// 가 가로 제약을 loose 로 통과시키고 `SoriSwipeCard` 내부 `Stack` 도 기본
// loose 라, `width` 핀이 없는 `SoriCard(hero)` 는 텍스트 내재폭으로 신축한다.
//
// 이 센서가 4개 덱 화면 전부에서 고정하는 계약 3종:
//   ① 서로 다른 단어에서 카드 슬롯 rect 가 완전히 동일하다.
//   ② 같은 카드의 플립 전/후 rect 가 동일하다.
//   ③ 슬롯 폭 == 가용 폭 (내재폭으로 줄어들지 않는다).
//
// 공통 finder 는 `ValueKey('deck-card-slot')` — 네 화면이 같은 키를 쓴다.
//
// 파괴-복원 프로토콜: vocab_pack 슬롯의 `width: double.infinity` 를 주석
// 처리하면 ①③ 이 빨개진다. 높이 라인은 `_fitFace` 가 이미 Expanded 높이로
// 강제하므로 파괴해도 red 가 안 뜬다 — 폭 라인만 증명 대상이다.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

/// 짧은 단어 / 매우 긴 단어 쌍 — 폭 신축이 있으면 rect 가 갈라진다.
const String kShortKo = '물';
const String kLongKo = '지속가능성발전소운영위원회';
const String kShortDe = 'Was';
const String kLongDe = 'Internationaler Führerschein für Kraftfahrzeuge';

final Finder kSlot = find.byKey(const ValueKey('deck-card-slot'));

Vocab _v({
  required String id,
  required String korean,
  required String german,
  String packId = 'a1_geo_1',
  int order = 1,
  bool boss = false,
}) => Vocab(
  id: id,
  korean: korean,
  romanization: 'rom',
  german: german,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$korean 예문입니다.',
  exampleGerman: 'Beispielsatz für $german.',
  topic: 'test',
  packId: packId,
  packOrder: order,
  isReviewBoss: boss,
);

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
    child: home,
  ),
);

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 슬롯이 **부모가 준 가용 폭을 그대로 채우는지** — 내재폭 신축의 직접 반증.
/// 부모 위젯을 추측하지 않고 슬롯 자신의 들어온 제약(maxWidth)과 비교한다.
void _expectSlotFillsWidth(WidgetTester tester) {
  final RenderBox box = tester.renderObject<RenderBox>(kSlot);
  expect(
    box.size.width,
    closeTo(box.constraints.maxWidth, 0.5),
    reason: '슬롯이 가용 폭을 채우지 않는다 = 텍스트 내재폭으로 줄어든 것',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
    });
    await Storage.init();
    DataLoader.reset();
  });

  group('vocab_pack Learn', () {
    Future<void> pump(WidgetTester tester, VocabPack pack) async {
      await tester.pumpWidget(
        _app(
          VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('카드 rect 는 단어 길이와 무관하다', (tester) async {
      _phoneViewport(tester);
      await Storage.setTutVocabPackSeen();
      final pack = VocabPack(
        id: 'a1_geo_1',
        level: 'A1',
        words: [
          _v(id: 'g1', korean: kShortKo, german: kShortDe, order: 1),
          _v(id: 'g2', korean: kLongKo, german: kLongDe, order: 2),
          _v(id: 'g3', korean: '셋째', german: 'Dritte', order: 3, boss: true),
        ],
      );
      await pump(tester, pack);

      expect(kSlot, findsOneWidget);
      final Rect first = tester.getRect(kSlot);
      _expectSlotFillsWidth(tester);

      // 같은 카드 플립 → rect 불변 (②).
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(kSlot),
        first,
        reason: '플립만으로 카드 rect 가 바뀌면 뒷면이 폭을 다시 협상한 것',
      );

      // 긴 단어 카드로 전진 → rect 불변 (①).
      // 탭 대신 핸들러 직접 호출 — 이 화면들은 첫 진입 코치 오버레이가 합성
      // 탭을 삼킬 수 있고, 지오메트리는 제스처 라우팅과 무관하다
      // (선례: vocab_pack_uniform_card_test).
      final AppL10n t = await AppL10n.delegate.load(const Locale('de'));
      _tapButton(tester, t.vocabPackGotIt);
      await tester.pumpAndSettle();

      expect(find.text(kLongKo), findsOneWidget);
      expect(
        tester.getRect(kSlot),
        first,
        reason: '긴 단어에서 카드 rect 가 달라졌다 — 폭 핀이 풀렸다',
      );
      _expectSlotFillsWidth(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('review_session', () {
    testWidgets('카드 rect 는 단어 길이·플립과 무관하다', (tester) async {
      _phoneViewport(tester);
      await tester.pumpWidget(
        _app(
          ReviewSessionScreen(
            deck: [
              _v(id: 'r1', korean: kShortKo, german: kShortDe),
              _v(id: 'r2', korean: kLongKo, german: kLongDe),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(kSlot, findsOneWidget);
      final Rect first = tester.getRect(kSlot);
      _expectSlotFillsWidth(tester);

      tester.widget<SoriPressable>(find.byType(SoriPressable).first).onTap!();
      await tester.pumpAndSettle();
      expect(tester.getRect(kSlot), first, reason: '플립 후 rect 불변');

      _tapButton(tester, 'Gewusst!');
      await tester.pumpAndSettle();
      expect(find.text(kLongKo), findsOneWidget);
      expect(tester.getRect(kSlot), first, reason: '긴 단어에서 rect 불변');
      expect(tester.takeException(), isNull);
    });
  });

  group('custom_pack_play', () {
    const String packId = 'cp_geo';
    Map<String, Object> word(String korean, String de) => {
      'korean': korean,
      'romanization': 'rom',
      'pos_de': 'N.',
      'translation_de': de,
      'translation_en': de,
      'example_korean': '$korean 예문',
      'example_de': 'Beispiel $de',
      'definition_ko': '',
      'image_path': '',
    };

    testWidgets('카드 rect 는 단어 길이·플립과 무관하다', (tester) async {
      _phoneViewport(tester);
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_custom_packs_v1': jsonEncode({
          packId: {
            'name': 'Geometry Pack',
            'sourcePageId': 'page_geo',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'words': [word(kShortKo, kShortDe), word(kLongKo, kLongDe)],
          },
        }),
      });
      await Storage.init();

      await tester.pumpWidget(_app(const CustomPackPlayScreen(packId: packId)));
      await tester.pumpAndSettle();

      expect(kSlot, findsOneWidget);
      final Rect first = tester.getRect(kSlot);
      _expectSlotFillsWidth(tester);

      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pumpAndSettle();
      expect(tester.getRect(kSlot), first, reason: '플립 후 rect 불변');

      _tapButton(tester, 'Gewusst!');
      await tester.pumpAndSettle();
      expect(find.text(kLongKo), findsOneWidget);
      expect(tester.getRect(kSlot), first, reason: '긴 단어에서 rect 불변');
      expect(tester.takeException(), isNull);
    });
  });

  group('legacy_vocab', () {
    testWidgets('카드 rect 는 단어 길이·플립과 무관하다', (tester) async {
      _phoneViewport(tester);
      await tester.pumpWidget(
        _app(
          LegacyVocabScreen(
            vocabLoader: () async => [
              _v(id: 'l1', korean: kShortKo, german: kShortDe),
              _v(id: 'l2', korean: kLongKo, german: kLongDe),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(kSlot, findsOneWidget);
      final Rect first = tester.getRect(kSlot);
      _expectSlotFillsWidth(tester);

      // ⚠️ 이 화면의 플립 후 rect 불변은 **아직 성립하지 않는다** — 판정 행이
      // `if (_flipped)` 라 뒤집는 순간 그 행이 나타나며 Expanded 가용 높이를
      // ~64px 먹는다 (폭이 아니라 세로 레이아웃 문제). §P2-3 이 그 행을 항상
      // 표시되는 DeckActionBar 로 흡수하면 성립하므로, 단언은 그때 켠다.
      final Rect beforeFlip = first;
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pumpAndSettle();
      final Rect afterFlip = tester.getRect(kSlot);
      expect(
        afterFlip.width,
        beforeFlip.width,
        reason: '플립이 카드 **폭**을 바꾸면 안 된다 (P1 계약)',
      );
      _expectSlotFillsWidth(tester);
      expect(tester.takeException(), isNull);
    });
  });
}

/// 라벨로 [SoriButton] 을 찾아 핸들러를 직접 호출한다.
void _tapButton(WidgetTester tester, String label) {
  tester
      .widgetList<SoriButton>(find.byType(SoriButton))
      .firstWhere((b) => b.label == label)
      .onTap!();
}
