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
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

import 'helpers/deck_actions.dart';

/// **§P2 화면 센서 — ↑/↓ 스와이프의 학습 데이터 무결성** (2026-08-14).
///
/// 철칙(§P2-2): ↑/↓ 는 SRS·wrongCount·ledger 를 절대 건드리지 않는다.
/// ↓ 스킵은 4화면 모두 재서빙 리셋 포함 — 다음 카드는 **앞면 + 판정 비활성**.
/// ↑ 저장은 전진하지 않는다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Vocab word(int n, String korean, {bool boss = false, String? packId}) =>
      Vocab(
        id: 'vg_v$n',
        korean: korean,
        romanization: 'r$n',
        german: 'GER-$n',
        level: 'A1',
        posDe: 'Nomen',
        exampleKorean: '$korean 예문',
        exampleGerman: 'Beispiel $n',
        topic: 'test',
        packId: packId ?? '',
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

  Map<String, Object> basePrefs() => {
    'kl_user_level': 'a1',
    'kl_streak_days': 0,
    'kl_xp': 0,
    // 코치 오버레이(AbsorbPointer)가 제스처를 삼켜 단언이 공허해지는 것 방지.
    'kl_tut_review': true,
    'kl_tut_legacyVocab': true,
    'kl_tut_cpPlay': true,
    'kl_tut_soriDeck': true,
    'kl_tut_wordbook': true,
  };

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(basePrefs());
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    // Wordbook snackbar force-hides after 500ms; leave no pending timer.
    await tester.pump(const Duration(milliseconds: 550));
  }

  group('vocab_pack Learn', () {
    VocabPack pack() => VocabPack(
      id: 'a1_vg_1',
      level: 'A1',
      words: [
        word(1, '하나', packId: 'a1_vg_1'),
        word(2, '둘째', packId: 'a1_vg_1'),
        word(3, '셋째', packId: 'a1_vg_1', boss: true),
      ],
    );

    Future<void> pump(WidgetTester tester, {VocabPack? sourcePack}) async {
      final selectedPack = sourcePack ?? pack();
      await tester.pumpWidget(
        app(
          VocabPackScreen(
            packId: selectedPack.id,
            packLoader: (_) async => selectedPack,
            siblingPacksLoader: (_) async => [selectedPack],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('↓ 스킵: SRS 0 · wrongCount 0 · 재삽입 전진 · 다음 카드 앞면+판정 비활성', (
      tester,
    ) async {
      fixViewport(tester);
      await pump(tester);
      expect(find.text('하나'), findsOneWidget);

      // 플립 전에도 ↓ 허용 ("모르는 티 안 내고 넘기기").
      await tester.drag(find.text('하나'), const Offset(0, 350));
      await settle(tester);

      expect(find.text('둘째'), findsOneWidget, reason: '↓ 는 전진(재삽입)');
      expect(Storage.wrongCountOf('하나'), 0);
      expect(Storage.srsCard('하나')?.reviewCount ?? 0, 0);
      // 다음 고유 카드를 처음 보여 줬으므로 화면 카운터도 전진한다.
      expect(find.text('2 / 3'), findsOneWidget);

      // 다음 카드 = 앞면(뜻 미노출) + 판정 비활성: 우측 드래그 → 기록 0.
      expect(find.text('GER-2'), findsNothing);
      await tester.drag(find.text('둘째'), const Offset(220, 0));
      await settle(tester);
      expect(find.text('둘째'), findsOneWidget);
      expect(Storage.srsCard('둘째')?.reviewCount ?? 0, 0);
      expect(Storage.wrongCountOf('둘째'), 0);
    });

    testWidgets('↓ 연속 스킵: 8개 고유 카드를 모두 본 뒤 재출제 없이 평가로 전환', (
      tester,
    ) async {
      fixViewport(tester);
      final eightWordPack = VocabPack(
        id: 'a1_vg_2',
        level: 'A1',
        words: [
          for (var i = 1; i <= 8; i++) word(i, '단어$i', packId: 'a1_vg_2'),
        ],
      );
      await pump(tester, sourcePack: eightWordPack);

      for (var i = 1; i <= 8; i++) {
        expect(find.text('단어$i'), findsOneWidget);
        expect(find.textContaining('$i / 8'), findsOneWidget);
        await tester.drag(find.text('단어$i'), const Offset(0, 350));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await settle(tester);

      // 위 루프가 "모든 고유 카드를 보기 전에는 재출제하지 않는다"를 이미 확인한다.
      // 8개를 모두 본 순간 Learn 은 끝나고 평가로 넘어간다. 예전에는 첫 카드를
      // 다시 서빙해서 8 / 8 인데도 연습문제가 열리지 않는 것처럼 보였다.
      expect(
        find.text('단어1'),
        findsNothing,
        reason: '첫 패스를 마치면 재출제 대신 평가로 넘어간다',
      );
      expect(find.byType(QuizChoice), findsWidgets);
      expect(Storage.vokSeenIds, isEmpty, reason: '스킵은 학습 완료로 저장하지 않는다');
    });

    testWidgets('책갈피 저장: quickAdd 1회 · 전진 없음 · SRS 0 · 앞면에서도 동작', (
      tester,
    ) async {
      fixViewport(tester);
      await pump(tester);
      expect(find.text('하나'), findsOneWidget);

      tapDeckAction(tester, 'Merken');
      await settle(tester);

      expect(find.text('하나'), findsOneWidget, reason: '책갈피는 전진하지 않는다');
      expect(Storage.srsCard('하나')?.reviewCount ?? 0, 0);
      final quick = CustomPackService.getAll().where(
        (p) => p.words.any((w) => w.korean == '하나'),
      );
      expect(quick, isNotEmpty, reason: 'quickAdd 로 단어장에 저장됐다');
    });
  });

  group('review_session', () {
    List<Vocab> deck() => [word(1, '학교'), word(2, '병원')];

    testWidgets('↓ 스킵: 맨 뒤 이동 · SRS 0 · 다음 카드 앞면+판정 비활성', (tester) async {
      fixViewport(tester);
      await tester.pumpWidget(app(ReviewSessionScreen(deck: deck())));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('학교'), findsOneWidget);

      await tester.drag(find.text('학교'), const Offset(0, 350));
      await settle(tester);

      expect(find.text('병원'), findsOneWidget, reason: '↓ 는 현재 카드를 맨 뒤로');
      expect(Storage.srsCard('학교')?.reviewCount ?? 0, 0);
      expect(Storage.wrongCountOf('학교'), 0);

      // 다음 카드 = 앞면 + 판정 비활성.
      await tester.drag(find.text('병원'), const Offset(220, 0));
      await settle(tester);
      expect(find.text('병원'), findsOneWidget);
      expect(Storage.srsCard('병원')?.reviewCount ?? 0, 0);
    });

    testWidgets('책갈피 저장: quickAdd · 전진 없음 · SRS 0 · 앞면에서도 동작', (tester) async {
      fixViewport(tester);
      await tester.pumpWidget(app(ReviewSessionScreen(deck: deck())));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('학교'), findsOneWidget);

      tapDeckAction(tester, 'Merken');
      await settle(tester);

      expect(find.text('학교'), findsOneWidget);
      expect(Storage.srsCard('학교')?.reviewCount ?? 0, 0);
      final quick = CustomPackService.getAll().where(
        (p) => p.words.any((w) => w.korean == '학교'),
      );
      expect(quick, isNotEmpty);
    });
  });

  group('custom_pack_play', () {
    const packId = 'cp_vg';
    Map<String, Object?> wordJson(String korean) => {
      'korean': korean,
      'romanization': 'r',
      'pos_de': 'N.',
      'translation_de': 'DE-$korean',
      'translation_en': '',
      'example_korean': '',
      'example_de': '',
      'definition_ko': '',
      'image_path': '',
      'saved_to_pack_id': null,
    };

    testWidgets('↓ 스킵: 기록 없는 전진 · 다음 카드 앞면+판정 비활성', (tester) async {
      fixViewport(tester);
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        ...basePrefs(),
        'kl_custom_packs_v1': jsonEncode({
          packId: {
            'name': 'VG Pack',
            'sourcePageId': 'p',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'words': [wordJson('도서관'), wordJson('의자')],
          },
        }),
      });
      await Storage.init();

      await tester.pumpWidget(app(const CustomPackPlayScreen(packId: packId)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('도서관'), findsOneWidget);

      await tester.drag(find.text('도서관'), const Offset(0, 350));
      await settle(tester);

      expect(find.text('의자'), findsOneWidget, reason: '↓ 는 기록 없는 전진');
      expect(Storage.srsCard('도서관')?.reviewCount ?? 0, 0);
      expect(Storage.wrongCountOf('도서관'), 0);

      // 다음 카드 = 앞면 + 판정 비활성.
      await tester.drag(find.text('의자'), const Offset(220, 0));
      await settle(tester);
      expect(find.text('의자'), findsOneWidget);
      expect(Storage.srsCard('의자')?.reviewCount ?? 0, 0);
    });
  });

  group('legacy_vocab', () {
    List<Vocab> deck() => [word(1, '사과'), word(2, '바나나')];

    testWidgets('↓ 스킵: SRS 0 · ⏭ 카운터 경로 · 다음 카드 앞면+판정 비활성', (tester) async {
      fixViewport(tester);
      await tester.pumpWidget(
        app(LegacyVocabScreen(vocabLoader: () async => deck())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('사과'), findsOneWidget);

      await tester.drag(find.text('사과'), const Offset(0, 350));
      await settle(tester);

      expect(find.text('바나나'), findsOneWidget);
      expect(Storage.srsCard('사과')?.reviewCount ?? 0, 0);
      expect(Storage.wrongCountOf('사과'), 0);
      expect(Storage.vokSkipped, 1, reason: '기존 ⏭ 스킵 카운터 (SRS 아님)');

      // 다음 카드 = 앞면 + 판정 비활성.
      await tester.drag(find.text('바나나'), const Offset(220, 0));
      await settle(tester);
      expect(find.text('바나나'), findsOneWidget);
      expect(Storage.srsCard('바나나')?.reviewCount ?? 0, 0);
    });

    testWidgets('책갈피 즐겨찾기: 추가 전용 — 다시 눌러도 해제 안 됨', (tester) async {
      fixViewport(tester);
      await tester.pumpWidget(
        app(LegacyVocabScreen(vocabLoader: () async => deck())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('사과'), findsOneWidget);

      tapDeckAction(tester, 'Merken');
      await settle(tester);
      expect(Storage.vokFavorites, contains('사과'));
      expect(find.text('사과'), findsOneWidget, reason: '책갈피는 전진하지 않는다');

      tapDeckAction(tester, 'Merken');
      await settle(tester);
      expect(Storage.vokFavorites, contains('사과'));
      expect(Storage.srsCard('사과')?.reviewCount ?? 0, 0);
    });
  });
}
