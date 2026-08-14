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
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/sori_deck_coach.dart';
import 'package:ko_lernen_app/widgets/sori/swipe_card.dart';

Vocab _v(String korean, String german, {String id = 'v'}) => Vocab(
  id: id,
  korean: korean,
  romanization: 'r',
  german: german,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_vert_1',
  packOrder: 1,
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

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _quietCoach() async {
  await Storage.setTutSeen('soriDeck');
  await Storage.setTutSeen('review');
  await Storage.setTutSeen('cpPlay');
  await Storage.setTutSeen('legacyVocab');
  await Storage.setTutVocabPackSeen();
  await Storage.setTutWordbookSeen();
  resetSoriDeckCoachSessionForTest();
}

Future<void> _swipeDeck(WidgetTester tester, Offset delta) async {
  await tester.drag(find.byType(SoriSwipeCard), delta, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _swipeUpWord(WidgetTester tester, String korean) async {
  await tester.drag(
    find.text(korean).first,
    const Offset(0, -180),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
}

bool _quickHas(String korean) {
  return CustomPackService.getAll().any(
    (pack) =>
        pack.id == CustomPackService.quickPackId &&
        pack.words.any((word) => word.korean == korean),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await _quietCoach();
    DataLoader.reset();
  });

  testWidgets('vocab_pack ↓ 스킵은 SRS 없이 전진하고 다음 카드는 앞면', (tester) async {
    _viewport(tester);
    final pack = VocabPack(
      id: 'a1_vert_1',
      level: 'A1',
      words: [
        _v('사과', 'Apfel', id: 'a'),
        _v('바나나', 'Banane', id: 'b'),
        _v('포도', 'Traube', id: 'c'),
      ],
    );
    await tester.pumpWidget(
      _app(
        VocabPackScreen(
          key: UniqueKey(),
          packId: pack.id,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('사과'), findsWidgets);

    await _swipeDeck(tester, const Offset(0, 180));

    expect(Storage.srsCard('사과')?.reviewCount, isNull);
    expect(Storage.wrongCountOf('사과'), 0);
    expect(find.text('바나나'), findsWidgets);
    expect(find.text('Banane'), findsNothing);
    expect(
      tester.widget<DeckActionBar>(find.byType(DeckActionBar)).judgmentEnabled,
      isFalse,
    );
  });

  testWidgets('vocab_pack ↑ 저장은 전진 없이 quickAdd 하고 SRS 0', (tester) async {
    _viewport(tester);
    final pack = VocabPack(
      id: 'a1_vert_1',
      level: 'A1',
      words: [
        _v('사과', 'Apfel', id: 'a'),
        _v('바나나', 'Banane', id: 'b'),
      ],
    );
    await tester.pumpWidget(
      _app(
        VocabPackScreen(
          key: UniqueKey(),
          packId: pack.id,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _swipeUpWord(tester, '사과');
    expect(find.text('사과'), findsWidgets);
    expect(Storage.srsCard('사과')?.reviewCount, isNull);
    expect(_quickHas('사과'), isTrue);
  });

  testWidgets('review ↓ 스킵은 SRS 없이 다음 앞면을 서빙한다', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _app(
        ReviewSessionScreen(
          key: UniqueKey(),
          deck: [
            _v('학교', 'Schule', id: 'r1'),
            _v('선생님', 'Lehrer', id: 'r2'),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await _swipeDeck(tester, const Offset(0, 180));

    expect(Storage.srsCard('학교')?.reviewCount, isNull);
    expect(Storage.wrongCountOf('학교'), 0);
    expect(find.text('선생님'), findsWidgets);
    expect(find.text('Lehrer'), findsNothing);
    expect(
      tester.widget<DeckActionBar>(find.byType(DeckActionBar)).judgmentEnabled,
      isFalse,
    );
  });

  testWidgets('review ↑ 저장은 같은 카드에 머물고 quickAdd 한다', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _app(
        ReviewSessionScreen(
          key: UniqueKey(),
          deck: [
            _v('학교', 'Schule', id: 'r1'),
            _v('선생님', 'Lehrer', id: 'r2'),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('학교'), findsWidgets);

    await _swipeUpWord(tester, '학교');
    expect(find.text('학교'), findsWidgets);
    expect(Storage.srsCard('학교')?.reviewCount, isNull);
    expect(_quickHas('학교'), isTrue);
  });

  testWidgets('custom ↓ 스킵은 기록 없이 전진한다', (tester) async {
    _viewport(tester);
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_custom_packs_v1': jsonEncode({
        'cp_vert': {
          'name': 'Vert',
          'sourcePageId': 'page',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'words': [
            {
              'korean': '도서관',
              'romanization': 'doseogwan',
              'pos_de': 'N.',
              'translation_de': 'Bibliothek',
              'translation_en': 'Library',
              'example_korean': '',
              'example_de': '',
              'definition_ko': '',
              'image_path': '',
              'saved_to_pack_id': null,
            },
            {
              'korean': '의자',
              'romanization': 'uija',
              'pos_de': 'N.',
              'translation_de': 'Stuhl',
              'translation_en': 'Chair',
              'example_korean': '',
              'example_de': '',
              'definition_ko': '',
              'image_path': '',
              'saved_to_pack_id': null,
            },
          ],
        },
      }),
    });
    await Storage.init();
    await _quietCoach();
    await tester.pumpWidget(
      _app(CustomPackPlayScreen(key: UniqueKey(), packId: 'cp_vert')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _swipeDeck(tester, const Offset(0, 180));

    expect(Storage.srsCard('도서관')?.reviewCount, isNull);
    expect(Storage.wrongCountOf('도서관'), 0);
    expect(find.text('의자'), findsWidgets);
    expect(find.text('Stuhl'), findsNothing);
  });

  testWidgets('legacy ↑ 는 즐겨찾기 추가만 하고 재스와이프는 해제하지 않는다', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _app(
        LegacyVocabScreen(
          key: UniqueKey(),
          vocabLoader: () async => [
            _v('사과', 'Apfel', id: 'l1'),
            _v('바나나', 'Banane', id: 'l2'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _swipeDeck(tester, const Offset(0, -180));
    expect(Storage.vokFavorites, contains('사과'));
    expect(find.text('사과'), findsWidgets);

    await _swipeDeck(tester, const Offset(0, -180));
    expect(Storage.vokFavorites, contains('사과'));
    expect(Storage.srsCard('사과')?.reviewCount, isNull);
  });

  testWidgets('legacy ↓ 스킵은 다음 앞면을 열고 SRS 0', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _app(
        LegacyVocabScreen(
          key: UniqueKey(),
          vocabLoader: () async => [
            _v('사과', 'Apfel', id: 'l1'),
            _v('바나나', 'Banane', id: 'l2'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _swipeDeck(tester, const Offset(0, 180));

    expect(Storage.srsCard('사과')?.reviewCount, isNull);
    expect(find.text('바나나'), findsWidgets);
    expect(find.text('Banane'), findsNothing);
  });
}
