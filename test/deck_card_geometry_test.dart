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
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

import 'helpers/deck_actions.dart';

/// **P1 카드 고정 지오메트리 센서** (UI 개편 2, 2026-08-14).
///
/// 4개 덱 화면 전부에서 카드 슬롯(`ValueKey('deck-card-slot')`)의 rect 가
/// ① 서로 다른 단어(짧은/매우 긴)에서 완전 동일하고
/// ② 같은 카드의 플립 전/후에 동일하며
/// ③ 슬롯 폭 == 가용폭(화면 폭 − 좌우 padding)임을 단언한다.
///
/// 파괴-복원 프로토콜: vocab_pack 슬롯 SizedBox 의 `width: double.infinity`
/// 한 줄을 주석 처리하면 ③(과 긴 단어에서 ①)이 빨개져야 한다. 높이 라인은
/// `FlipCard._fitFace` 가 이미 높이를 잡고 있어 파괴해도 red 가 안 뜬다 —
/// 폭 라인만 증명 대상 (핸드오프 §P1-3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shortKo = '물';
  const longKo = '지속가능성발전소에서만나요';
  const slot = ValueKey('deck-card-slot');

  Vocab word(int n, String korean, {bool boss = false}) => Vocab(
    id: 'geo_v$n',
    korean: korean,
    romanization: 'r$n',
    german: n == 2 ? 'Internationaler Führerschein' : 'Wasser',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '$korean 예문입니다.',
    exampleGerman: 'Beispielsatz $n.',
    topic: 'test',
    packId: 'a1_geo_1',
    packOrder: n,
    isReviewBoss: boss,
  );

  Widget app(Widget home) => MaterialApp(
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

  void fixViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
      // 코치마크/투어가 드래그·탭을 가로채지 않게 전부 표시됨 처리.
      'kl_tut_cpPlay': true,
      'kl_tut_review': true,
      'kl_tut_legacyVocab': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    await Storage.setTutWordbookSeen();
  });

  Rect slotRect(WidgetTester tester) => tester.getRect(find.byKey(slot));

  void expectSameRect(Rect a, Rect b, String reason) {
    expect(b.left, closeTo(a.left, 0.1), reason: '$reason (left)');
    expect(b.top, closeTo(a.top, 0.1), reason: '$reason (top)');
    expect(b.width, closeTo(a.width, 0.1), reason: '$reason (width)');
    expect(b.height, closeTo(a.height, 0.1), reason: '$reason (height)');
  }

  group('vocab_pack Learn', () {
    testWidgets('slot rect is word- and flip-invariant, full width', (
      tester,
    ) async {
      fixViewport(tester);
      final pack = VocabPack(
        id: 'a1_geo_1',
        level: 'A1',
        words: [word(1, shortKo), word(2, longKo), word(3, '셋째', boss: true)],
      );
      await tester.pumpWidget(
        app(
          VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final t = await AppL10n.delegate.load(const Locale('de'));
      final front1 = slotRect(tester);
      // ③ 슬롯 폭 == 가용폭 (400 − 좌우 padding 16×2).
      expect(front1.width, closeTo(368, 0.5), reason: '슬롯 폭 = 가용폭 가득');

      // ② 플립 전/후 rect 동일.
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expectSameRect(front1, slotRect(tester), '플립 전/후 슬롯 rect 동일');

      // 긴 단어 카드로 전진.
      tapDeckAction(tester, t.vocabPackGotIt);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text(longKo), findsOneWidget);
      // ① 서로 다른 단어에서 rect 완전 동일.
      expectSameRect(front1, slotRect(tester), '짧은/긴 단어 슬롯 rect 동일');
      expect(tester.takeException(), isNull);
    });
  });

  group('custom_pack_play', () {
    const packId = 'cp_geo';
    Map<String, Object?> wordJson(String korean, String de) => {
      'korean': korean,
      'romanization': 'r',
      'pos_de': 'N.',
      'translation_de': de,
      'translation_en': '',
      'example_korean': '$korean 예문',
      'example_de': 'Beispiel',
      'definition_ko': '',
      'image_path': '',
      'saved_to_pack_id': null,
    };

    testWidgets('slot rect is word- and flip-invariant, full width', (
      tester,
    ) async {
      fixViewport(tester);
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_tut_cpPlay': true,
        'kl_tut_soriDeck': true,
        'kl_tut_wordbook': true,
        'kl_custom_packs_v1': jsonEncode({
          packId: {
            'name': 'Geo Pack',
            'sourcePageId': 'p',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'words': [
              wordJson(shortKo, 'Wasser'),
              wordJson(longKo, 'Internationaler Führerschein'),
            ],
          },
        }),
      });
      await Storage.init();

      await tester.pumpWidget(app(const CustomPackPlayScreen(packId: packId)));
      await tester.pump(const Duration(milliseconds: 300));

      final t = await AppL10n.delegate.load(const Locale('de'));
      final front1 = slotRect(tester);
      expect(front1.width, closeTo(368, 0.5), reason: '슬롯 폭 = 가용폭 가득');

      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expectSameRect(front1, slotRect(tester), '플립 전/후 슬롯 rect 동일');

      tapDeckAction(tester, t.btnGewusst);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text(longKo), findsOneWidget);
      expectSameRect(front1, slotRect(tester), '짧은/긴 단어 슬롯 rect 동일');
      expect(tester.takeException(), isNull);
    });
  });

  group('review_session', () {
    testWidgets('slot rect is word- and flip-invariant, full width', (
      tester,
    ) async {
      fixViewport(tester);
      await tester.pumpWidget(
        app(ReviewSessionScreen(deck: [word(1, shortKo), word(2, longKo)])),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final t = await AppL10n.delegate.load(const Locale('de'));
      final front1 = slotRect(tester);
      expect(front1.width, closeTo(368, 0.5), reason: '슬롯 폭 = 가용폭 가득');

      // 플립 (카드 탭).
      await tester.tap(find.text(shortKo), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expectSameRect(front1, slotRect(tester), '플립 전/후 슬롯 rect 동일');

      // 판정으로 다음(긴 단어) 카드.
      tapDeckAction(tester, t.btnGewusst);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text(longKo), findsOneWidget);
      expectSameRect(front1, slotRect(tester), '짧은/긴 단어 슬롯 rect 동일');
      expect(tester.takeException(), isNull);
    });
  });

  group('legacy_vocab', () {
    testWidgets('slot rect is word- and flip-invariant, full width', (
      tester,
    ) async {
      fixViewport(tester);
      await tester.pumpWidget(
        app(
          LegacyVocabScreen(
            vocabLoader: () async => [word(1, shortKo), word(2, longKo)],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final front1 = slotRect(tester);
      // 400 − 좌우 padding 12×2.
      expect(front1.width, closeTo(376, 0.5), reason: '슬롯 폭 = 가용폭 가득');

      // 플립 — §P2-3 상시 액션 바가 옛 조건부 판정 행을 흡수해 카드 슬롯이
      // 플립 상태와 완전히 무관해졌다 (풀 rect 단언).
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expectSameRect(front1, slotRect(tester), '플립 전/후 슬롯 rect 동일');

      // 판정 없는 전진(스킵) → 긴 단어 카드.
      final t = await AppL10n.delegate.load(const Locale('de'));
      tapDeckAction(tester, t.btnSkip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text(longKo), findsOneWidget);
      expectSameRect(front1, slotRect(tester), '짧은/긴 단어 슬롯 rect 동일');
      expect(tester.takeException(), isNull);
    });
  });
}
