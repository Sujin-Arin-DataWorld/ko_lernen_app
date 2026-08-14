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
import 'package:ko_lernen_app/widgets/sori/swipe_card.dart';

const _slotKey = ValueKey('deck-card-slot');

Vocab _word(int index, String korean, String german, {bool boss = false}) =>
    Vocab(
      id: 'geometry_$index',
      korean: korean,
      romanization: 'romanization-$index',
      german: german,
      english: german,
      level: 'A1',
      posDe: 'Nomen',
      posEn: 'noun',
      exampleKorean: '$korean 예문입니다.',
      exampleGerman: 'Beispielsatz $index.',
      exampleEnglish: 'Example $index.',
      topic: 'test',
      packId: 'a1_geometry_1',
      packOrder: index,
      isReviewBoss: boss,
    );

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
    child: child,
  ),
);

void _expectSlotFillsSwipe(WidgetTester tester) {
  final slot = find.byKey(_slotKey);
  final swipe = find.byType(SoriSwipeCard);
  expect(slot, findsOneWidget);
  expect(swipe, findsOneWidget);
  expect(
    tester.widget<SizedBox>(slot).width,
    double.infinity,
    reason: 'loose swipe stacks require an explicit full-width deck slot',
  );
  expect(
    tester.getRect(slot).width,
    closeTo(tester.getRect(swipe).width, 0.01),
  );
}

Future<void> _flip(WidgetTester tester) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    DataLoader.reset();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    await Storage.setTutSeen('review');
    await Storage.setTutSeen('cpPlay');
    await Storage.setTutSeen('legacyVocab');
  });

  testWidgets('pack Learn slot ignores word length and flip state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pack = VocabPack(
      id: 'a1_geometry_1',
      level: 'A1',
      words: [
        _word(1, '물', 'Wasser'),
        _word(2, '국제운전면허시험장', 'Internationaler Führerschein'),
        _word(3, '끝', 'Ende', boss: true),
      ],
    );
    await tester.pumpWidget(
      _host(
        VocabPackScreen(
          packId: pack.id,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final front = tester.getRect(find.byKey(_slotKey));
    _expectSlotFillsSwipe(tester);
    await _flip(tester);
    expect(tester.getRect(find.byKey(_slotKey)), front);

    tester.widget<DeckActionBar>(find.byType(DeckActionBar)).onKnow();
    await tester.pumpAndSettle();
    expect(find.text('국제운전면허시험장'), findsOneWidget);
    expect(tester.getRect(find.byKey(_slotKey)), front);
  });

  testWidgets('review slot ignores word length and flip state', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        ReviewSessionScreen(
          deck: [
            _word(1, '물', 'Wasser'),
            _word(2, '국제운전면허시험장', 'Internationaler Führerschein'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final front = tester.getRect(find.byKey(_slotKey));
    _expectSlotFillsSwipe(tester);
    await tester.tap(find.text('물'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getRect(find.byKey(_slotKey)), front);

    tester.widget<DeckActionBar>(find.byType(DeckActionBar)).onKnow();
    await tester.pumpAndSettle();
    expect(find.text('국제운전면허시험장'), findsOneWidget);
    expect(tester.getRect(find.byKey(_slotKey)), front);
  });

  testWidgets('custom-pack slot ignores word length and flip state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const packId = 'cp_geometry';
    SharedPreferences.setMockInitialValues({
      'kl_custom_packs_v1': jsonEncode({
        packId: {
          'name': 'Geometry',
          'sourcePageId': 'page',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'words': [
            {
              'korean': '물',
              'romanization': 'mul',
              'pos_de': 'N.',
              'translation_de': 'Wasser',
              'translation_en': 'Water',
              'example_korean': '물을 마셔요.',
              'example_de': 'Ich trinke Wasser.',
              'definition_ko': '',
              'image_path': '',
              'saved_to_pack_id': null,
            },
            {
              'korean': '국제운전면허시험장',
              'romanization': 'gukje',
              'pos_de': 'N.',
              'translation_de': 'Internationaler Führerschein',
              'translation_en': 'International driving licence',
              'example_korean': '면허를 확인해요.',
              'example_de': 'Ich prüfe den Führerschein.',
              'definition_ko': '',
              'image_path': '',
              'saved_to_pack_id': null,
            },
          ],
        },
      }),
    });
    Storage.resetForTesting();
    await Storage.init();
    await Storage.setTutSeen('cpPlay');

    await tester.pumpWidget(_host(const CustomPackPlayScreen(packId: packId)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final front = tester.getRect(find.byKey(_slotKey));
    _expectSlotFillsSwipe(tester);
    await tester.tap(find.text('물'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getRect(find.byKey(_slotKey)), front);

    tester.widget<DeckActionBar>(find.byType(DeckActionBar)).onKnow();
    await tester.pumpAndSettle();
    expect(find.text('국제운전면허시험장'), findsOneWidget);
    expect(tester.getRect(find.byKey(_slotKey)), front);
  });

  testWidgets('legacy slot ignores word length and flip state', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final deck = [
      _word(1, '물', 'Wasser'),
      _word(2, '국제운전면허시험장', 'Internationaler Führerschein'),
    ];
    await tester.pumpWidget(
      _host(LegacyVocabScreen(vocabLoader: () async => deck)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final front = tester.getRect(find.byKey(_slotKey));
    _expectSlotFillsSwipe(tester);
    await tester.tap(find.text('물'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getRect(find.byKey(_slotKey)), front);

    tester.widget<DeckActionBar>(find.byType(DeckActionBar)).onKnow();
    await tester.pumpAndSettle();
    expect(find.text('국제운전면허시험장'), findsOneWidget);
    expect(tester.getRect(find.byKey(_slotKey)), front);
  });
}
