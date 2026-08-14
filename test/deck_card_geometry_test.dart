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
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

Vocab _v(int n, String ko, String de) => Vocab(
  id: 'geom_v$n',
  korean: ko,
  romanization: 'r$n',
  german: de,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$ko 예문.',
  exampleGerman: 'Beispiel $de.',
  topic: 'geom',
  packId: 'a1_geom_1',
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

  group('P1: Deck Card Geometry Sensor', () {
    testWidgets('vocab_pack_screen: short vs long card rect and flip rect invariant', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const shortKo = '물';
      const longKo = '지속가능성에너지발전소에서일하는사람';
      final pack = VocabPack(
        id: 'a1_geom_1',
        level: 'A1',
        words: [
          _v(1, shortKo, 'Wasser'),
          _v(2, longKo, 'Internationaler Führerschein und Reisepass'),
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

      final slotFinder = find.byKey(const ValueKey('deck-card-slot'));
      expect(slotFinder, findsOneWidget);

      final rect1Front = tester.getRect(slotFinder);
      // Flip to back
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final rect1Back = tester.getRect(slotFinder);

      expect(rect1Front, equals(rect1Back), reason: 'Flip 전/후 카드 rect 불변');

      // Proceed to card 2 (long word) via GotIt
      final t = await AppL10n.delegate.load(const Locale('de'));
      final gotItFinder = find.text(t.vocabPackGotIt);
      await tester.tap(gotItFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final rect2Front = tester.getRect(slotFinder);
      expect(rect1Front.width, equals(rect2Front.width), reason: '단어 길이에 무관하게 폭 불변');
      expect(rect1Front.height, equals(rect2Front.height), reason: '단어 길이에 무관하게 높이 불변');
    });

    testWidgets('custom_pack_play_screen: short vs long card rect invariant', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final customPack = CustomPack(
        id: 'cp_geom_1',
        title: 'Geom Test',
        createdAt: DateTime.now(),
        words: [
          ExtractedWord(
            korean: '물',
            translationDe: 'Wasser',
            posDe: 'Nomen',
            confidence: 1.0,
            sourcePageId: 'p1',
          ),
          ExtractedWord(
            korean: '지속가능성에너지발전소',
            translationDe: 'Internationaler Führerschein',
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

      final slotFinder = find.byKey(const ValueKey('deck-card-slot'));
      expect(slotFinder, findsOneWidget);

      final rect1Front = tester.getRect(slotFinder);

      // Flip card
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final rect1Back = tester.getRect(slotFinder);
      expect(rect1Front, equals(rect1Back));

      // Advance
      final t = await AppL10n.delegate.load(const Locale('de'));
      await tester.tap(find.text(t.btnGewusst));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final rect2Front = tester.getRect(slotFinder);
      expect(rect1Front.width, equals(rect2Front.width));
      expect(rect1Front.height, equals(rect2Front.height));
    });

    testWidgets('review_session_screen: short vs long card rect invariant', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final words = [
        _v(1, '물', 'Wasser'),
        _v(2, '지속가능성에너지발전소', 'Internationaler Führerschein'),
      ];

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

      final slotFinder = find.byKey(const ValueKey('deck-card-slot'));
      expect(slotFinder, findsOneWidget);

      final rect1Front = tester.getRect(slotFinder);

      // Advance
      final t = await AppL10n.delegate.load(const Locale('de'));
      await tester.tap(find.text(t.btnGewusst));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final rect2Front = tester.getRect(slotFinder);
      expect(rect1Front.width, equals(rect2Front.width));
      expect(rect1Front.height, equals(rect2Front.height));
    });

    testWidgets('legacy_vocab_screen: short vs long card rect invariant', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final words = [
        _v(1, '물', 'Wasser'),
        _v(2, '지속가능성에너지발전소', 'Internationaler Führerschein'),
      ];

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

      final slotFinder = find.byKey(const ValueKey('deck-card-slot'));
      expect(slotFinder, findsOneWidget);

      final rect1Front = tester.getRect(slotFinder);

      // Advance
      final t = await AppL10n.delegate.load(const Locale('de'));
      await tester.tap(find.text(t.btnGewusst));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final rect2Front = tester.getRect(slotFinder);
      expect(rect1Front.width, equals(rect2Front.width));
      expect(rect1Front.height, equals(rect2Front.height));
    });
  });
}
