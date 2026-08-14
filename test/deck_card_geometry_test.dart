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
import 'package:ko_lernen_app/widgets/sori/sori_deck_coach.dart';
import 'package:ko_lernen_app/widgets/sori/swipe_card.dart';

const _slot = ValueKey('deck-card-slot');
const _shortKo = '물';
const _longKo = '지속가능성발전소';
const _longDe = 'Internationaler Führerschein';

Vocab _v(String id, String korean, String german) => Vocab(
  id: id,
  korean: korean,
  romanization: 'r',
  german: german,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$korean 예문',
  exampleGerman: 'Beispiel',
  topic: 'test',
  packId: 'a1_geo_1',
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
  resetSoriDeckCoachSessionForTest();
}

void _assertSlotPinned(WidgetTester tester) {
  final slot = tester.getRect(find.byKey(_slot));
  final swipe = tester.getRect(find.byType(SoriSwipeCard));
  expect(slot.width, swipe.width, reason: '슬롯 폭 == 스와이프 가용폭');
  expect(slot.width, greaterThan(200));
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

  testWidgets('vocab_pack slot rect is identical for short and long words', (
    tester,
  ) async {
    _viewport(tester);
    Future<void> pumpWord(String korean, String german) async {
      final pack = VocabPack(
        id: 'a1_geo_1',
        level: 'A1',
        words: [_v('g1', korean, german), _v('g2', '다음', 'nächste')],
      );
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
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pumpWord(_shortKo, 'Wasser');
    final shortRect = tester.getRect(find.byKey(_slot));
    _assertSlotPinned(tester);

    await pumpWord(_longKo, _longDe);
    final longRect = tester.getRect(find.byKey(_slot));
    expect(longRect, shortRect);
    _assertSlotPinned(tester);

    await tester.tap(find.text(_longKo), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_slot)), longRect);
  });

  testWidgets('review slot rect is identical for short and long words', (
    tester,
  ) async {
    _viewport(tester);
    Future<void> pump(Vocab word) async {
      await tester.pumpWidget(
        _app(ReviewSessionScreen(deck: [word, _v('n', '다음', 'nächste')])),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    await pump(_v('s', _shortKo, 'Wasser'));
    final shortRect = tester.getRect(find.byKey(_slot));
    _assertSlotPinned(tester);

    await pump(_v('l', _longKo, _longDe));
    final longRect = tester.getRect(find.byKey(_slot));
    expect(longRect, shortRect);

    await tester.tap(find.text(_longKo), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_slot)), longRect);
  });

  testWidgets('custom_pack slot rect is identical for short and long words', (
    tester,
  ) async {
    _viewport(tester);
    Future<void> pump(String korean, String german) async {
      SharedPreferences.setMockInitialValues({
        'kl_custom_packs_v1': jsonEncode({
          'cp_geo': {
            'name': 'Geo',
            'sourcePageId': 'page',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'words': [
              {
                'korean': korean,
                'romanization': 'r',
                'pos_de': 'N.',
                'translation_de': german,
                'translation_en': german,
                'example_korean': '',
                'example_de': '',
                'definition_ko': '',
                'image_path': '',
                'saved_to_pack_id': null,
              },
              {
                'korean': '다음',
                'romanization': 'r',
                'pos_de': 'N.',
                'translation_de': 'nächste',
                'translation_en': 'next',
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
        _app(const CustomPackPlayScreen(packId: 'cp_geo')),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    await pump(_shortKo, 'Wasser');
    final shortRect = tester.getRect(find.byKey(_slot));
    _assertSlotPinned(tester);

    await pump(_longKo, _longDe);
    final longRect = tester.getRect(find.byKey(_slot));
    expect(longRect, shortRect);

    await tester.tap(find.text(_longKo), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_slot)), longRect);
  });

  testWidgets('legacy slot rect is identical for short and long words', (
    tester,
  ) async {
    _viewport(tester);
    Future<void> pump(Vocab word) async {
      await tester.pumpWidget(
        _app(
          LegacyVocabScreen(
            vocabLoader: () async => [word, _v('n', '다음', 'nächste')],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await pump(_v('s', _shortKo, 'Wasser'));
    final shortRect = tester.getRect(find.byKey(_slot));
    _assertSlotPinned(tester);

    await pump(_v('l', _longKo, _longDe));
    final longRect = tester.getRect(find.byKey(_slot));
    expect(longRect, shortRect);

    await tester.tap(find.text(_longKo), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_slot)), longRect);
  });
}
