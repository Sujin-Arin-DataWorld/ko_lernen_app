import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/sori_deck_coach.dart';

/// §C-3c flipgate 센서: custom_pack_play 화면 — "앞면(flipped=false) 드래그 시
/// SRS 기록 0 + 카드 인덱스 불변".
///
/// `enabled: _flipped` 배선 한 줄이 지워지면 이 테스트가 빨개진다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const packId = 'cp_test_flipgate';

  /// SharedPreferences 에 직접 심을 JSON — CustomPackService._readRaw() 경유.
  final packJson = jsonEncode({
    packId: {
      'name': 'Flipgate Test Pack',
      'sourcePageId': 'page_test',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'words': [
        {
          'korean': '도서관',
          'romanization': 'doseogwan',
          'pos_de': 'N.',
          'translation_de': 'Bibliothek',
          'translation_en': 'Library',
          'example_korean': '도서관에 가다',
          'example_de': 'In die Bibliothek gehen',
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
          'example_korean': '의자에 앉다',
          'example_de': 'Auf dem Stuhl sitzen',
          'definition_ko': '',
          'image_path': '',
          'saved_to_pack_id': null,
        },
      ],
    },
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
      'kl_custom_packs_v1': packJson,
    });
    await Storage.init();
    await Storage.setTutSeen('soriDeck');
    await Storage.setTutSeen('cpPlay');
    resetSoriDeckCoachSessionForTest();
  });

  Widget buildScreen() => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
      child: const CustomPackPlayScreen(packId: packId),
    ),
  );

  testWidgets('앞면(flipped=false) 우측 드래그 → SRS 미기록 (§C-1-1 regression)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // 앞면(한국어)이 보여야 함
    expect(find.text('도서관'), findsOneWidget);

    final srsBefore = Storage.srsCard('도서관');

    // 앞면 상태에서 우측 임계 초과 드래그
    await tester.drag(
      find.text('도서관'),
      const Offset(220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter = Storage.srsCard('도서관');

    expect(
      srsAfter?.reviewCount,
      srsBefore?.reviewCount,
      reason: 'srsReview 미호출 (앞면 스와이프 = enabled:false)',
    );

    // 같은 카드 유지
    expect(find.text('도서관'), findsOneWidget);
  });

  testWidgets('앞면 좌측 드래그 → SRS 미기록 (§C-1-1 regression, left)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('도서관'), findsOneWidget);

    final srsBefore = Storage.srsCard('도서관');

    await tester.drag(
      find.text('도서관'),
      const Offset(-220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter = Storage.srsCard('도서관');

    expect(
      srsAfter?.reviewCount,
      srsBefore?.reviewCount,
      reason: 'srsReview 미호출 (앞면 좌측 스와이프)',
    );

    expect(find.text('도서관'), findsOneWidget);
  });

  testWidgets('버튼 판정→다음 카드 플립 없이 스와이프 → SRS 불변 (리셋 경로 센서)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // 카드 1: 도서관
    expect(find.text('도서관'), findsOneWidget);

    // P2: 판정 버튼도 flipgate. 앞면 탭으로는 SRS 0, 뒤집힌 뒤에만 기록.
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();
    expect(Storage.srsCard('도서관')?.reviewCount, isNull);
    await tester.tap(find.text('도서관'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // 카드 2: 의자 — 리셋으로 앞면이어야 함
    expect(find.text('의자'), findsOneWidget);

    final srsBefore2 = Storage.srsCard('의자');

    // 카드 2: 플립 없이 우측 스와이프 → 무시되어야 함
    await tester.drag(
      find.text('의자'),
      const Offset(220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter2 = Storage.srsCard('의자');

    expect(
      srsAfter2?.reviewCount,
      srsBefore2?.reviewCount,
      reason: '다음 카드는 _flipped=false 리셋 → 스와이프 무시',
    );

    // 여전히 두 번째 카드 유지
    expect(find.text('의자'), findsOneWidget);
  });
}
