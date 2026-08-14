// UI/UX 개편 2 §P2-6 — ↓ 스킵 / ↑ 저장 화면 센서.
// ↓ 후 다음 카드는 앞면 + 판정 비활성, SRS/wrongCount 0.

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
import 'package:ko_lernen_app/widgets/sori/swipe_card.dart';

Vocab _word(int n, String korean) => Vocab(
  id: 'vg_v$n',
  korean: korean,
  romanization: 'r$n',
  german: 'Ger-$n',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$korean 예문.',
  exampleGerman: 'Beispiel $n.',
  topic: 'test',
  packId: 'a1_vg_1',
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
    await Storage.setTutSeen('soriDeck');
  });

  testWidgets('review ↓ skip: SRS 0, next card front + judgment off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final deck = [_word(1, '사과'), _word(2, '바나나'), _word(3, '포도')];

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
    await _settle(tester);

    expect(find.text('사과'), findsOneWidget);
    final srsBefore = Storage.srsCard('사과');
    final wrongBefore = Storage.wrongCountOf('사과');

    await tester.drag(find.text('사과'), const Offset(0, 180), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(Storage.srsCard('사과')?.reviewCount, srsBefore?.reviewCount);
    expect(Storage.wrongCountOf('사과'), wrongBefore);

    // Defer moves current to back → next is 바나나, front face.
    expect(find.text('바나나'), findsOneWidget);
    expect(find.byType(SoriSwipeCard), findsOneWidget);
    final swipe = tester.widget<SoriSwipeCard>(find.byType(SoriSwipeCard));
    expect(swipe.enabled, isFalse);

    // Front judgment still blocked.
    await tester.drag(find.text('바나나'), const Offset(220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(Storage.srsCard('바나나')?.reviewCount, isNull);
    expect(find.text('바나나'), findsOneWidget);
  });

  testWidgets('custom ↓ skip: SRS 0, next card front', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const packId = 'cp_vg';
    final packJson = jsonEncode({
      packId: {
        'name': 'VG',
        'sourcePageId': 'p',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'words': [
          {
            'korean': '연필',
            'romanization': 'yeonpil',
            'pos_de': 'N.',
            'translation_de': 'Bleistift',
            'translation_en': 'Pencil',
            'example_korean': '연필로 쓰다',
            'example_de': 'Mit dem Bleistift schreiben',
            'definition_ko': '',
            'image_path': '',
            'saved_to_pack_id': null,
          },
          {
            'korean': '지우개',
            'romanization': 'jiugae',
            'pos_de': 'N.',
            'translation_de': 'Radierer',
            'translation_en': 'Eraser',
            'example_korean': '지우개로 지우다',
            'example_de': 'Mit dem Radierer löschen',
            'definition_ko': '',
            'image_path': '',
            'saved_to_pack_id': null,
          },
        ],
      },
    });
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_custom_packs_v1': packJson});
    await Storage.init();
    await Storage.setTutSeen('cpPlay');
    await Storage.setTutSeen('soriDeck');

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
    await _settle(tester);

    expect(find.text('연필'), findsOneWidget);
    final srsBefore = Storage.srsCard('연필');

    await tester.drag(find.text('연필'), const Offset(0, 180), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(Storage.srsCard('연필')?.reviewCount, srsBefore?.reviewCount);
    expect(find.text('지우개'), findsOneWidget);
    final swipe = tester.widget<SoriSwipeCard>(find.byType(SoriSwipeCard));
    expect(swipe.enabled, isFalse);
  });

  testWidgets('vocab_pack ↓ defer: queue keeps word, next front, SRS 0', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pack = VocabPack(
      id: 'a1_vg_1',
      level: 'A1',
      words: [
        _word(1, '하늘'),
        _word(2, '바다'),
        _word(3, '산'),
        _word(4, '강'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('하늘'), findsOneWidget);
    final srsBefore = Storage.srsCard('하늘');

    await tester.drag(find.text('하늘'), const Offset(0, 220), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(Storage.srsCard('하늘')?.reviewCount, srsBefore?.reviewCount);
    // Next serve is 바다 (defer reinserts 하늘 after gap).
    expect(find.text('바다'), findsOneWidget);
    expect(find.byType(FlipCard), findsOneWidget);
    final swipe = tester.widget<SoriSwipeCard>(find.byType(SoriSwipeCard));
    expect(swipe.enabled, isFalse);
  });
}
