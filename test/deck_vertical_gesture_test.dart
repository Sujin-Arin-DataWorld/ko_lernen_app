// Sori Deck 2.0 · 화면 레벨 세로 제스처 센서 (§P2-6).
//
// 위(저장)·아래(스킵)는 **판정이 아니다**. 이 파일이 고정하는 계약:
//   ↓ 스킵 : SRS 0 · 오답 카운터 0 · 전진 · 다음 카드는 **앞면 + 판정 비활성**
//            (재서빙 리셋이 빠지면 다음 카드가 뒷면=정답으로 서빙되고 판정
//             게이트가 열린 채가 된다 — flipgate 계약 위반)
//   ↑ 저장 : 단어장 추가 · **전진 없음** · SRS 0 (legacy 는 즐겨찾기 추가 전용)
//
// 제스처는 실제 드래그로 건다. 각 케이스는 먼저 **양성 대조**(플립 후 좌/우
// 드래그가 실제로 판정을 남긴다)로 드래그가 도달하는지 증명하므로, hit-test
// 가 빗나가 단언이 공허하게 통과하는 일이 없다.

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
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/swipe_card.dart';

final Finder _slot = find.byKey(const ValueKey('deck-card-slot'));

Vocab _v(String id, String ko, String de) => Vocab(
  id: id,
  korean: ko,
  romanization: 'rom',
  german: de,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$ko 예문입니다.',
  exampleGerman: 'Beispiel $de.',
  topic: 'test',
  packId: 'a1_vg_1',
  packOrder: int.parse(id.split('_').last),
  isReviewBoss: false,
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

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 카드 슬롯을 실제로 드래그한다 (합성 탭이 아니라 제스처 경로).
///
/// 드래그 뒤 **실제 비동기**를 한 번 흘려보낸다: 저장·SRS 기록은
/// SharedPreferences 플랫폼 채널을 타므로 fake-async 안에서는 절대 완료되지
/// 않는다. 이걸 빼면 "기록됐다" 단언이 조용히 공허해진다.
Future<void> _dragCard(WidgetTester tester, Offset offset) async {
  await tester.drag(_slot, offset, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}

/// 저장은 화면에서 fire-and-forget(`ignore: discarded_futures`)이라 테스트가
/// await 할 손잡이가 없다. 고정 지연으로 재면 플레이키하므로 조건이 참이 될
/// 때까지 **실제 비동기**를 흘리며 폴링한다.
Future<void> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final sw = Stopwatch()..start();
  while (!condition() && sw.elapsed < timeout) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

/// ↑ 저장이 이 화면에 **배선돼 있는가**.
///
/// 저장의 영속화까지 이 파일에서 단언하지 않는 이유: `addToWordbook` 은
/// 화면에서 fire-and-forget 이고, 그 안의 `CustomPackService.quickAdd` 는
/// SharedPreferences 목이 테스트 간에 인스턴스를 물고 있어 같은 파일에서
/// 두 번째 저장이 완료되지 않는다(핸들러 호출 자체는 실측으로 확인했다).
///
/// 그래서 증명을 둘로 나눈다:
/// - **제스처 → 콜백 1회**: `swipe_card_test.dart` 의 위젯 계약이 담당.
/// - **콜백 → 이 화면의 저장 동작 + 판정 무오염**: 여기서 배선 존재와
///   "전진 없음 · SRS 0" 을 단언한다.
/// 영속화 규칙(dedupe 등)은 `CustomPackService` 쪽 테스트 소관이다.
bool _saveWired(WidgetTester tester) =>
    tester.widget<SoriSwipeCard>(find.byType(SoriSwipeCard)).onSwipeUp != null;

Future<void> _flip(WidgetTester tester) async {
  final flip = find.byType(FlipCard);
  if (flip.evaluate().isNotEmpty) {
    tester.widget<FlipCard>(flip.first).onTap!();
  } else {
    // review 는 FlipCard 가 아니라 SoriPressable 로 뒤집는다.
    tester.widget<SoriPressable>(find.byType(SoriPressable).first).onTap!();
  }
  await tester.pumpAndSettle();
}

/// **현재(맨 앞) 카드**에 이 단어가 보이는가.
///
/// ⚠️ 화면 전체를 세면 안 된다: 덱 스택(underlay)이 다음 카드의 앞면을 뒤에
/// 그리므로 `find.text('바나나')` 는 전진하지 않아도 통과하고, 랩어라운드
/// 덱에서는 **이전 단어까지** 뒤에 그려져 "안 움직였다" 단언마저 공허해진다.
/// underlay 는 `FlipCard` 를 쓰지 않으므로 그걸 기준으로 맨 앞 카드만 본다.
Finder _onCurrentCard(String text) {
  final flip = find.byType(FlipCard);
  if (flip.evaluate().isNotEmpty) {
    return find.descendant(of: flip.first, matching: find.text(text));
  }
  // review 는 FlipCard 대신 인라인 카드 — 슬롯이 underlay 를 제외한다.
  return find.descendant(
    of: find.byKey(const ValueKey('deck-card-slot')),
    matching: find.text(text),
  );
}

/// 판정 게이트가 실제로 닫혀 있는지 — 바의 선언 상태로 읽는다.
bool _judgmentEnabled(WidgetTester tester) =>
    tester.widget<DeckActionBar>(find.byType(DeckActionBar)).judgmentEnabled;

int _srsCount(String ko) => Storage.srsCard(ko)?.reviewCount ?? 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
      // ⚠️ 첫 진입 코치 오버레이(SpotlightCoach)는 전면 스크림으로 **모든
      // 포인터를 흡수**한다. 이 플래그들이 없으면 합성 드래그가 카드에
      // 닿지 않고 "기록 0" 단언이 조용히 공허해진다.
      'kl_tut_wordbook': true,
      'kl_tut_vocab_pack': true,
      'kl_tut_pack_quiz': true,
      'kl_tut_pack_boss': true,
      'kl_tut_home_tour': true,
      'kl_tut_review': true,
      'kl_tut_legacyVocab': true,
      'kl_tut_cpPlay': true,
      'kl_tut_soriDeck': true,
    });
    await Storage.init();
    DataLoader.reset();
  });

  // ── vocab_pack Learn ────────────────────────────────────────────────
  group('vocab_pack Learn', () {
    final pack = VocabPack(
      id: 'a1_vg_1',
      level: 'A1',
      words: [
        _v('vg_1', '하나', 'Eins'),
        _v('vg_2', '둘', 'Zwei'),
        _v('vg_3', '셋', 'Drei'),
      ],
    );

    Future<void> pump(WidgetTester tester) async {
      await Storage.setTutVocabPackSeen();
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

    testWidgets('양성 대조: 플립 후 우측 드래그는 실제로 판정을 남긴다', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester);
      await _dragCard(tester, const Offset(260, 0));
      expect(
        _onCurrentCard('둘'),
        findsOneWidget,
        reason:
            '수평 드래그가 카드에 도달하지 않으면 이 대조가 실패한다 — '
            '그 경우 아래 세로 케이스의 "기록 0" 단언은 공허하다',
      );
    });

    testWidgets('↓ 스킵: SRS·오답 0 · 전진 · 다음 카드는 앞면+판정 비활성', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester); // 뒤집어 둔 상태에서 스킵해도 기록은 없어야 한다

      await _dragCard(tester, const Offset(0, 160));

      expect(_srsCount('하나'), 0, reason: '스킵은 판정이 아니다');
      expect(Storage.wrongCountOf('하나'), 0);
      expect(_onCurrentCard('둘'), findsOneWidget, reason: '전진했다');
      expect(
        _judgmentEnabled(tester),
        isFalse,
        reason: '재서빙 리셋 — 다음 카드는 앞면이고 판정은 잠겨 있다',
      );
    });

    testWidgets('↑ 저장: 단어장 추가 · 전진 없음 · SRS 0', (tester) async {
      _phone(tester);
      await pump(tester);

      expect(_saveWired(tester), isTrue, reason: '↑ 는 저장에 배선돼 있다');
      await _dragCard(tester, const Offset(0, -160));
      expect(_onCurrentCard('하나'), findsOneWidget, reason: '저장은 전진이 아니다');
      expect(_srsCount('하나'), 0, reason: '저장은 판정이 아니다');
      expect(Storage.wrongCountOf('하나'), 0);
    });

    testWidgets('↑ 저장은 플립 전에도 동작한다 (판정 게이트와 무관)', (tester) async {
      _phone(tester);
      await pump(tester);
      expect(_judgmentEnabled(tester), isFalse);

      expect(_saveWired(tester), isTrue);
      await _dragCard(tester, const Offset(0, -160));

      expect(_onCurrentCard('하나'), findsOneWidget, reason: '저장은 전진이 아니다');
      expect(_srsCount('하나'), 0);
    });
  });

  // ── review_session ──────────────────────────────────────────────────
  group('review_session', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ReviewSessionScreen(
            deck: [_v('vg_1', '학교', 'Schule'), _v('vg_2', '선생', 'Lehrer')],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('양성 대조: 플립 후 우측 드래그는 실제로 판정을 남긴다', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester);
      await _dragCard(tester, const Offset(260, 0));
      expect(_onCurrentCard('선생'), findsOneWidget, reason: '드래그 도달 대조');
    });

    testWidgets('↓ 스킵: SRS·오답 0 · 다음 카드는 앞면+판정 비활성', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester);

      await _dragCard(tester, const Offset(0, 160));

      expect(_srsCount('학교'), 0);
      expect(Storage.wrongCountOf('학교'), 0);
      expect(_onCurrentCard('선생'), findsOneWidget, reason: '다음 카드로 넘어갔다');
      expect(_judgmentEnabled(tester), isFalse, reason: '재서빙 리셋');
    });

    testWidgets('↑ 저장: 단어장 추가 · 전진 없음 · SRS 0', (tester) async {
      _phone(tester);
      await pump(tester);

      expect(_saveWired(tester), isTrue, reason: '↑ 는 저장에 배선돼 있다');
      await _dragCard(tester, const Offset(0, -160));
      expect(_onCurrentCard('학교'), findsOneWidget, reason: '저장은 전진이 아니다');
      expect(_srsCount('학교'), 0);
    });
  });

  // ── custom_pack_play ────────────────────────────────────────────────
  group('custom_pack_play', () {
    const String packId = 'cp_vg';
    Map<String, Object> w(String ko, String de) => {
      'korean': ko,
      'romanization': 'rom',
      'pos_de': 'N.',
      'translation_de': de,
      'translation_en': de,
      'example_korean': '$ko 예문',
      'example_de': 'Beispiel $de',
      'definition_ko': '',
      'image_path': '',
    };

    Future<void> pump(WidgetTester tester) async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_tut_wordbook': true,
        'kl_tut_cpPlay': true,
        'kl_tut_soriDeck': true,
        'kl_custom_packs_v1': jsonEncode({
          packId: {
            'name': 'Vertical Pack',
            'sourcePageId': 'page_vg',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'words': [w('도서관', 'Bibliothek'), w('의자', 'Stuhl')],
          },
        }),
      });
      await Storage.init();
      await tester.pumpWidget(_app(const CustomPackPlayScreen(packId: packId)));
      await tester.pumpAndSettle();
    }

    testWidgets('양성 대조: 플립 후 우측 드래그는 실제로 판정을 남긴다', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester);
      await _dragCard(tester, const Offset(260, 0));
      expect(_onCurrentCard('의자'), findsOneWidget, reason: '드래그 도달 대조');
    });

    testWidgets('↓ 스킵: SRS·오답 0 · 다음 카드는 앞면+판정 비활성', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester);

      await _dragCard(tester, const Offset(0, 160));

      expect(_srsCount('도서관'), 0);
      expect(Storage.wrongCountOf('도서관'), 0);
      expect(_onCurrentCard('의자'), findsOneWidget);
      expect(_judgmentEnabled(tester), isFalse, reason: '재서빙 리셋');
    });

    testWidgets('↑ 저장은 이 화면에서 비노출이다', (tester) async {
      _phone(tester);
      await pump(tester);

      // 이 팩의 단어는 정의상 이미 사용자 팩 소속 — 저장 버튼도 없고
      // 위 스와이프도 아무 일도 하지 않는다.
      expect(find.byKey(deckActionKey('save')), findsNothing);
      await _dragCard(tester, const Offset(0, -160));
      expect(_onCurrentCard('도서관'), findsOneWidget, reason: '전진하지 않는다');
    });
  });

  // ── legacy_vocab ────────────────────────────────────────────────────
  group('legacy_vocab', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          LegacyVocabScreen(
            vocabLoader: () async => [
              _v('vg_1', '사과', 'Apfel'),
              _v('vg_2', '바나나', 'Banane'),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('양성 대조: 플립 후 우측 드래그는 실제로 판정을 남긴다', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester);
      await _dragCard(tester, const Offset(260, 0));
      expect(_onCurrentCard('바나나'), findsOneWidget, reason: '드래그 도달 대조');
    });

    testWidgets('↓ 스킵: SRS·오답 0 · 다음 카드는 앞면+판정 비활성', (tester) async {
      _phone(tester);
      await pump(tester);
      await _flip(tester);

      await _dragCard(tester, const Offset(0, 160));

      expect(_srsCount('사과'), 0, reason: '스킵 카운터는 SRS 가 아니다');
      expect(Storage.wrongCountOf('사과'), 0);
      expect(_onCurrentCard('바나나'), findsOneWidget);
      expect(_judgmentEnabled(tester), isFalse, reason: '재서빙 리셋');
    });

    testWidgets('↑ 저장은 즐겨찾기 **추가 전용** — 다시 밀어도 해제되지 않는다', (tester) async {
      _phone(tester);
      await pump(tester);

      await _dragCard(tester, const Offset(0, -160));
      expect(Storage.vokFavorites, contains('사과'), reason: '위 스와이프 = 즐겨찾기 추가');

      // 같은 카드를 다시 위로 → 토글이면 해제된다. 추가 전용이어야 한다.
      await _dragCard(tester, const Offset(0, -160));
      expect(
        Storage.vokFavorites,
        contains('사과'),
        reason: '재스와이프는 no-op — 해제는 별 탭 경로만',
      );
      expect(_srsCount('사과'), 0);
    });
  });
}
