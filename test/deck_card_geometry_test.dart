// P1 센서: 4개 덱 화면(vocab_pack Learn·review·custom_pack·legacy_vocab)
// 전부에서 카드 슬롯 rect 가 단어·플립 상태와 완전히 무관해야 한다
// (`docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md` §P1 — 3회차 재발 회귀 수리).
//
// 계약: 각 화면의 카드 슬롯에 공용 키 `deck-card-slot` 이 붙어 있다.
//   ① 서로 다른 단어(짧은/긴)에서 슬롯 rect 가 완전히 같다.
//   ② 같은 카드의 플립 전/후 슬롯 rect 가 완전히 같다.
//   ③ 슬롯 폭이 가용 폭을 채운다(짧은 단어의 내재폭으로 신축하지 않는다).
//
// 파괴-복원 프로토콜(수동, SESSION_LOG 기록): 각 화면의 슬롯 SizedBox/
// SoriCard 의 `width: double.infinity` 한 줄을 주석 처리하면 이 파일의
// ① 단언이 빨개진다 — 폭 라인이 진짜 결함 지점이었음을 증명한다. 높이
// 라인은 파괴해도 red 가 안 뜬다(§2-4 — `_fitFace`/`FractionallySizedBox`
// 가 이미 높이를 강제하므로) — 폭 라인만 증명 대상.
//
// 화면 탐색은 기존 flipgate 센서 배터리의 관례를 따른다: 플립·판정은 실제
// 탭 시뮬레이션이 아니라 위젯 콜백을 직접 호출한다(vocab_pack_uniform_card_test
// 선례) — 카드 위 GestureDetector 겹침으로 인한 히트테스트 경고 없이 신뢰
// 가능하게 동작을 트리거한다.

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
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

Finder get _slotFinder => find.byKey(const ValueKey('deck-card-slot'));

/// 400×800 — Jin 이 회귀를 실제로 목격한 표준 폰 폭 근사치(기존 flipgate
/// 센서 배터리와 동일 관례). 800×600 같은 넓은 기본값에서는 카드가 이미
/// 넓어 보여 텍스트-내재폭 신축 회귀가 가려진다.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 화면에 있는 유일한 [FlipCard] 를 직접 뒤집는다 — 탭 시뮬레이션이
/// 겹친 GestureDetector 때문에 히트테스트 경고를 내는 문제를 피한다.
void _flipViaCallback(WidgetTester tester) {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('vocab_pack Learn', () {
    Vocab word(int n, String korean, {bool boss = false}) => Vocab(
      id: 'geo_v$n',
      korean: korean,
      romanization: 'r$n',
      german: 'GEO-GER-$n',
      level: 'A1',
      posDe: 'Nomen',
      exampleKorean: '$korean 예문',
      exampleGerman: 'Satz $n',
      topic: 'test',
      packId: 'a1_geo_1',
      packOrder: n,
      isReviewBoss: boss,
    );

    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      await Storage.setTutVocabPackSeen();
      await Storage.setTutPackQuizSeen();
      await Storage.setTutPackBossSeen();
    });

    Future<AppL10n> pump(WidgetTester tester, VocabPack pack) async {
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
      return AppL10n.delegate.load(const Locale('de'));
    }

    testWidgets('슬롯 rect 가 단어 길이·플립 상태와 무관하게 동일 + 가용 폭을 채운다', (tester) async {
      _setPhoneViewport(tester);
      const short = '물';
      const long = '국제인권보호협약기구';
      final pack = VocabPack(
        id: 'a1_geo_1',
        level: 'A1',
        words: [word(1, short), word(2, long), word(3, '셋', boss: true)],
      );
      final t = await pump(tester, pack);

      expect(_slotFinder, findsOneWidget);
      final rectShort = tester.getRect(_slotFinder);

      // ③ 슬롯이 가용 폭을 채운다 — 짧은 단어의 내재폭으로 신축하지 않는다.
      expect(
        rectShort.width,
        greaterThan(400 * 0.7),
        reason: '짧은 단어("물")에서도 슬롯 폭이 가용 폭을 채워야 한다',
      );

      // ② 같은 카드의 플립 전/후.
      _flipViaCallback(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final rectFlipped = tester.getRect(_slotFinder);
      expect(rectFlipped, rectShort, reason: '플립 전/후 슬롯 rect 는 완전히 같아야 한다');

      // ① 다른 단어(긴 단어)로 전진 — 하단 "Gewusst!" 버튼 콜백 직접 호출.
      _flipViaCallback(tester); // 다시 앞면으로.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .firstWhere((b) => b.label == t.vocabPackGotIt)
          .onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final rectLong = tester.getRect(_slotFinder);
      expect(rectLong, rectShort, reason: '짧은 단어와 긴 단어에서 슬롯 rect 는 완전히 같아야 한다');
      expect(tester.takeException(), isNull);
    });
  });

  group('review session', () {
    setUp(() async {
      // `Storage._prefs` 는 `??=` 로만 채워진다 — 앞 group 의 mock 값이
      // 남아 있으면 이 group 의 setMockInitialValues 가 무시된다.
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 0,
        'kl_xp': 0,
        // 스포트라이트 코치를 건너뛴다 — 아니면 그 backdrop 의
        // AbsorbPointer 가 카드 밖 히트테스트를 흡수해 이 센서와 무관한
        // 경고/불안정을 만든다.
        'kl_tut_review': true,
      });
      await Storage.init();
    });

    final deck = [
      const Vocab(
        id: 'geo_rv_1',
        korean: '차',
        romanization: 'cha',
        german: 'Auto',
        level: 'A1',
        posDe: 'N.',
        exampleKorean: '차를 타다',
        exampleGerman: 'Ins Auto einsteigen',
        topic: 'test',
      ),
      const Vocab(
        id: 'geo_rv_2',
        korean: '국제인권보호협약기구',
        romanization: 'gukje-ingwonbohohyeobyakgigu',
        german: 'Menschenrechtsschutzabkommen',
        level: 'A1',
        posDe: 'N.',
        exampleKorean: '기구에 가입하다',
        exampleGerman: 'Der Organisation beitreten',
        topic: 'test',
      ),
    ];

    Widget buildScreen() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          disableAnimations: true,
        ),
        child: ReviewSessionScreen(deck: deck),
      ),
    );

    testWidgets('슬롯 rect 가 단어 길이·플립 상태와 무관하게 동일 + 가용 폭을 채운다', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));

      expect(_slotFinder, findsOneWidget);
      final rectShort = tester.getRect(_slotFinder);
      expect(rectShort.width, greaterThan(400 * 0.7));

      // 카드를 감싸는 SoriPressable 을 직접 찾아 onTap 콜백을 호출한다
      // (탭 시뮬레이션은 겹친 SoriSwipeCard 제스처 감지기와 충돌 경고를 낸다).
      final pressableFinder = find.ancestor(
        of: _slotFinder,
        matching: find.byType(SoriPressable),
      );
      expect(pressableFinder, findsOneWidget);
      tester.widget<SoriPressable>(pressableFinder).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final rectFlipped = tester.getRect(_slotFinder);
      expect(rectFlipped, rectShort);

      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .firstWhere((b) => b.label == 'Gewusst!')
          .onTap!();
      await tester.pumpAndSettle();

      final rectLong = tester.getRect(_slotFinder);
      expect(rectLong, rectShort);
      expect(tester.takeException(), isNull);
    });
  });

  group('custom pack play', () {
    const packId = 'geo_cp_test';
    final packJson = jsonEncode({
      packId: {
        'name': 'Geometry Test Pack',
        'sourcePageId': 'page_test',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'words': [
          {
            'korean': '집',
            'romanization': 'jip',
            'pos_de': 'N.',
            'translation_de': 'Haus',
            'translation_en': 'House',
            'example_korean': '집에 가다',
            'example_de': 'Nach Hause gehen',
            'definition_ko': '',
            'image_path': '',
            'saved_to_pack_id': null,
          },
          {
            'korean': '국제인권보호협약기구',
            'romanization': 'gukje-ingwonbohohyeobyakgigu',
            'pos_de': 'N.',
            'translation_de': 'Menschenrechtsschutzabkommen',
            'translation_en': 'Human rights protection agreement',
            'example_korean': '기구에 가입하다',
            'example_de': 'Der Organisation beitreten',
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
        'kl_streak_days': 0,
        'kl_xp': 0,
        'kl_custom_packs_v1': packJson,
      });
      await Storage.init();
    });

    Widget buildScreen() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          disableAnimations: true,
        ),
        child: const CustomPackPlayScreen(packId: packId),
      ),
    );

    testWidgets('슬롯 rect 가 단어 길이·플립 상태와 무관하게 동일 + 가용 폭을 채운다', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));

      expect(_slotFinder, findsOneWidget);
      final rectShort = tester.getRect(_slotFinder);
      expect(rectShort.width, greaterThan(400 * 0.7));

      _flipViaCallback(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final rectFlipped = tester.getRect(_slotFinder);
      expect(rectFlipped, rectShort);

      _flipViaCallback(tester); // 다시 앞면으로.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .firstWhere((b) => b.label == 'Gewusst!')
          .onTap!();
      await tester.pumpAndSettle();

      final rectLong = tester.getRect(_slotFinder);
      expect(rectLong, rectShort);
      expect(tester.takeException(), isNull);
    });
  });

  group('legacy vocab', () {
    final testVocab = [
      const Vocab(
        id: 'geo_lg_1',
        korean: '물',
        romanization: 'mul',
        german: 'Wasser',
        level: 'A1',
        posDe: 'N.',
        exampleKorean: '물을 마시다',
        exampleGerman: 'Wasser trinken',
        topic: 'test',
      ),
      const Vocab(
        id: 'geo_lg_2',
        korean: '국제인권보호협약기구',
        romanization: 'gukje-ingwonbohohyeobyakgigu',
        german: 'Menschenrechtsschutzabkommen',
        level: 'A1',
        posDe: 'N.',
        exampleKorean: '기구에 가입하다',
        exampleGerman: 'Der Organisation beitreten',
        topic: 'test',
      ),
    ];

    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 0,
        'kl_xp': 0,
        'kl_tut_legacyVocab': true,
      });
      await Storage.init();
      DataLoader.reset();
    });

    Widget buildScreen() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          disableAnimations: true,
        ),
        child: LegacyVocabScreen(vocabLoader: () async => testVocab),
      ),
    );

    testWidgets('슬롯 rect 가 단어 길이·플립 상태와 무관하게 동일 + 가용 폭을 채운다', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 'due' 모드는 판정 직후 dueIds 에서 카드를 빼 [_filtered] 를
      // 다시 계산한다 — 이 화면 특유의 진도 관리이고 P1 슬롯 계약과는
      // 무관하다. 'Alle' 모드로 고정해 판정이 헤더 배지/필터 폭에 개입하지
      // 않는 안정된 조건에서 슬롯 rect 만 비교한다. ⚠️ 카드 안(레벨 칩)에도
      // SoriChip 이 있어 `.last` 로 고르면 잘못된 위젯을 집는다 — 라벨로
      // 정확히 지정한다.
      tester
          .widgetList<SoriChip>(find.byType(SoriChip))
          .firstWhere((c) => c.label == 'Alle')
          .onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_slotFinder, findsOneWidget);
      final rectShort = tester.getRect(_slotFinder);
      expect(rectShort.width, greaterThan(400 * 0.7));

      // ② 는 이 화면에서 폭만 비교한다: legacy_vocab 은 (P2 로 예정된
      // 아이콘 액션바 이전 구조라) 판정 행이 `if (_flipped) ...` 로
      // 뒤집은 뒤에만 나타난다(:562) — 그만큼 카드 Expanded 의 가용
      // 높이가 정당하게 줄어든다. 이건 P1 회귀가 아니라 기존 UI 설계다.
      // 폭은 플립 여부와 무관하게 항상 같아야 한다.
      _flipViaCallback(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final rectFlipped = tester.getRect(_slotFinder);
      expect(
        rectFlipped.width,
        rectShort.width,
        reason: '플립 전/후에도 슬롯 폭은 같아야 한다(판정 행 추가는 높이만 바꾼다)',
      );

      // 판정 버튼은 뒤집힌 상태에만 존재한다(:562) — 뒤집힌 채로 판정한다.
      // `_advanceAfterReview`/`_next()` 가 다음 카드를 다시 앞면으로
      // 리셋하므로(flipgate 계약), 측정 시점엔 다시 앞면·판정 행 없음
      // 상태로 돌아와 있다.
      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .firstWhere((b) => b.label == 'Gewusst!')
          .onTap!();
      await tester.pumpAndSettle();

      // ① 카드 2(긴 단어)도 같은(앞면) 플립 상태에서 비교 — 완전히 같은 rect.
      final rectLong = tester.getRect(_slotFinder);
      expect(rectLong, rectShort);
      expect(tester.takeException(), isNull);
    });
  });
}
