import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/extracted_word.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

Vocab _v(int n, String ko, String de) => Vocab(
  id: 'vert_v$n',
  korean: ko,
  romanization: 'r$n',
  german: de,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$ko 예문.',
  exampleGerman: 'Beispiel $de.',
  topic: 'vert',
  packId: 'a1_vert_1',
  packOrder: n,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  group('P2: Deck Vertical Gesture & Button Gate Sensor', () {
    testWidgets('vocab_pack_screen: down swipe skips without SRS/wrongCount, up saves without advance', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pack = VocabPack(
        id: 'a1_vert_1',
        level: 'A1',
        words: [_v(1, '단어1', 'Wort1'), _v(2, '단어2', 'Wort2'), _v(3, '단어3', 'Wort3')],
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

      // 1. Up swipe on front face -> Save current word to wordbook, no advance
      await tester.drag(find.text('단어1'), const Offset(0, -150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final quickPack = CustomPackService.getById('cp_quick_v1');
      expect(quickPack?.words.any((w) => w.korean == '단어1'), isTrue, reason: '단어1이 빠른 저장 팩에 담김');
      expect(find.text('단어1'), findsOneWidget, reason: '저장은 카드를 넘기지 않음');
      expect(Storage.srsReviews['단어1'], isNull, reason: '저장은 SRS 기록 없음');

      // 2. Down swipe -> Defer (skip), advances to next card without SRS / wrong count
      await tester.drag(find.text('단어1'), const Offset(0, 150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(Storage.srsReviews['단어1'], isNull, reason: '스킵은 SRS 기록 없음');
      expect(Storage.wrongCount('단어1'), 0, reason: '스킵은 wrongCount 기록 없음');
      expect(find.text('단어2'), findsOneWidget, reason: '다음 카드로 전진');
    });

    testWidgets('review_session_screen: front button tap does not write SRS', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final words = [_v(1, '단어1', 'Wort1'), _v(2, '단어2', 'Wort2')];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: ReviewSessionScreen(initialDeck: words),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final t = await AppL10n.delegate.load(const Locale('de'));

      // Tap know button while front is visible
      await tester.tap(find.text(t.btnGewusst));
      await tester.pump();

      expect(Storage.srsReviews['단어1'], isNull, reason: '앞면 버튼 탭은 SRS 기록 없음');
      expect(find.text(t.deckFlipFirstHint), findsOneWidget, reason: '힌트 스낵바 노출');
    });

    testWidgets('custom_pack_play_screen: front button tap does not write SRS', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final customPack = CustomPack(
        id: 'cp_vert_1',
        title: 'Vert Test',
        createdAt: DateTime.now(),
        words: [
          ExtractedWord(
            korean: '단어1',
            translationDe: 'Wort1',
            posDe: 'Nomen',
            confidence: 1.0,
            sourcePageId: 'p1',
          ),
          ExtractedWord(
            korean: '단어2',
            translationDe: 'Wort2',
            posDe: 'Nomen',
            confidence: 1.0,
            sourcePageId: 'p1',
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
          home: CustomPackPlayScreen(pack: customPack),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final t = await AppL10n.delegate.load(const Locale('de'));

      // Tap know button while front is visible
      await tester.tap(find.text(t.btnGewusst));
      await tester.pump();

      expect(Storage.srsReviews['단어1'], isNull, reason: '앞면 버튼 탭은 SRS 기록 없음');
      expect(find.text(t.deckFlipFirstHint), findsOneWidget, reason: '힌트 스낵바 노출');
    });

    testWidgets('legacy_vocab_screen: up swipe toggles favorite once without unfavoriting on reswipe', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final words = [_v(1, '단어1', 'Wort1'), _v(2, '단어2', 'Wort2')];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: LegacyVocabScreen(initialVocabList: words),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Up swipe to favorite
      await tester.drag(find.text('단어1'), const Offset(0, -150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(Storage.vokFavorites.contains('단어1'), isTrue, reason: '즐겨찾기 추가됨');

      // Reswipe up -> should remain favorited
      await tester.drag(find.text('단어1'), const Offset(0, -150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(Storage.vokFavorites.contains('단어1'), isTrue, reason: '재스와이프해도 즐겨찾기 유지');
    });
  });
}
