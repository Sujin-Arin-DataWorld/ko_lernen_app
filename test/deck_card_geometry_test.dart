// UI/UX 개편 2 §P1 — 덱 카드 슬롯 지오메트리 센서.
// 짧은/긴 단어, 플립 전/후에서 `deck-card-slot` rect 가 불변이어야 한다.
// 폭 핀(`width: double.infinity`)을 제거하면 이 테스트가 빨개진다.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

const _slotKey = ValueKey('deck-card-slot');

Vocab _word(int n, String korean, {String german = 'Wort'}) => Vocab(
  id: 'geo_v$n',
  korean: korean,
  romanization: 'r$n',
  german: german,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$korean 예문.',
  exampleGerman: 'Beispiel $n.',
  topic: 'test',
  packId: 'a1_geo_1',
  packOrder: n,
  isReviewBoss: n >= 3,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    await Storage.setTutSeen('review');
    await Storage.setTutSeen('cpPlay');
    await Storage.setTutSeen('legacyVocab');
  });

  group('vocab_pack Learn slot geometry', () {
    testWidgets('short vs long word keep identical slot rect; flip preserves it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const short = '물';
      const long = '지속가능성발전소';
      final pack = VocabPack(
        id: 'a1_geo_1',
        level: 'A1',
        words: [
          _word(1, short, german: 'Wasser'),
          _word(2, long, german: 'Internationaler Führerschein'),
          _word(3, '셋째', german: 'Dritt'),
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
      await _settle(tester);

      final slot = find.byKey(_slotKey);
      expect(slot, findsOneWidget);
      final shortRect = tester.getRect(slot);
      expect(shortRect.width, greaterThan(300));

      // Flip front → back: rect must stay identical.
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await _settle(tester);
      expect(tester.getRect(slot), shortRect);

      // Advance to long word.
      final t = await AppL10n.delegate.load(const Locale('de'));
      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .firstWhere((b) => b.label == t.vocabPackGotIt)
          .onTap!();
      await _settle(tester);

      expect(find.text(long), findsOneWidget);
      final longRect = tester.getRect(slot);
      expect(
        longRect,
        shortRect,
        reason: '카드 슬롯 rect 는 단어 길이와 무관해야 한다 (P1 폭 핀)',
      );
    });
  });

  group('custom_pack Play slot geometry', () {
    testWidgets('short vs long keep identical slot width', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const packId = 'cp_geo';
      final packJson = jsonEncode({
        packId: {
          'name': 'Geo Pack',
          'sourcePageId': 'page_geo',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'words': [
            {
              'korean': '물',
              'romanization': 'mul',
              'pos_de': 'N.',
              'translation_de': 'Wasser',
              'translation_en': 'Water',
              'example_korean': '물을 마시다',
              'example_de': 'Wasser trinken',
              'definition_ko': '',
              'image_path': '',
              'saved_to_pack_id': null,
            },
            {
              'korean': '지속가능성발전소',
              'romanization': 'jisok',
              'pos_de': 'N.',
              'translation_de': 'Internationaler Führerschein',
              'translation_en': 'License',
              'example_korean': '예문',
              'example_de': 'Beispiel',
              'definition_ko': '',
              'image_path': '',
              'saved_to_pack_id': null,
            },
          ],
        },
      });
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_custom_packs_v1': packJson,
      });
      await Storage.init();
      await Storage.setTutSeen('cpPlay');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: const CustomPackPlayScreen(packId: packId),
          ),
        ),
      );
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 500));

      final slot = find.byKey(_slotKey);
      expect(slot, findsOneWidget);
      final shortRect = tester.getRect(slot);

      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await _settle(tester);
      expect(tester.getRect(slot), shortRect);

      final t = await AppL10n.delegate.load(const Locale('de'));
      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .firstWhere((b) => b.label == t.btnGewusst)
          .onTap!();
      await _settle(tester);

      final longRect = tester.getRect(slot);
      expect(longRect.width, shortRect.width);
      expect(longRect.height, shortRect.height);
    });
  });

  group('review session slot geometry', () {
    testWidgets('deck slot width equals available; flip preserves rect', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final deck = [
        _word(1, '물', german: 'Wasser'),
        _word(2, '지속가능성발전소', german: 'Internationaler Führerschein'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: ReviewSessionScreen(deck: deck),
        ),
      );
      await _settle(tester);

      final slot = find.byKey(_slotKey);
      expect(slot, findsOneWidget);
      final before = tester.getRect(slot);
      expect(before.width, greaterThan(300));

      // Tap flip via pressable card area.
      await tester.tap(find.text('물'));
      await _settle(tester);
      expect(tester.getRect(slot), before);
    });
  });
}
