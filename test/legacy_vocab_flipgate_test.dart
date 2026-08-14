import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

/// §C-3c P0-2: 화면 레벨 플립게이트 테스트 — "앞면(flipped=false) 드래그 시
/// SRS/wrongCount 미기록 + 카드 인덱스 불변"을 검증.
///
/// 위젯 테스트(swipe_card_test.dart)는 `enabled:false`에서 콜백이 무시되는지
/// 확인하지만, 화면의 `enabled: _flipped` 배선 한 줄이 지워져도 빨개지지 않는다.
/// 이 테스트는 **그 배선 자체를 고정한다** — 수리를 지우면 빨개진다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testVocab = [
    const Vocab(
      id: 'test_1',
      korean: '사과',
      romanization: 'sagwa',
      german: 'Apfel',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '사과를 먹다',
      exampleGerman: 'Einen Apfel essen',
      topic: 'Essen',
    ),
    const Vocab(
      id: 'test_2',
      korean: '바나나',
      romanization: 'banana',
      german: 'Banane',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '바나나를 먹다',
      exampleGerman: 'Eine Banane essen',
      topic: 'Essen',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
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
      data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
      child: LegacyVocabScreen(vocabLoader: () async => testVocab),
    ),
  );

  testWidgets(
    '앞면(flipped=false) 우측 드래그 → SRS 기록 0, 카드 인덱스 불변 (§C-1-1 regression)',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      // vocabLoader future 해소 + 화면 빌드
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 앞면(한국어) 텍스트가 보여야 함
      expect(find.text('사과'), findsOneWidget);

      // SRS 스냅샷 (before)
      final srsBefore = Storage.srsCard('사과');
      final wrongBefore = Storage.wrongCountOf('사과');

      // 앞면 상태에서 우측 임계 초과 드래그
      await tester.drag(
        find.text('사과'),
        const Offset(220, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // SRS 스냅샷 (after) — 변화 없어야 함
      final srsAfter = Storage.srsCard('사과');
      final wrongAfter = Storage.wrongCountOf('사과');

      expect(
        srsAfter?.reviewCount,
        srsBefore?.reviewCount,
        reason: 'srsReview가 호출되지 않아야 함 (앞면 스와이프 = enabled:false)',
      );
      expect(
        wrongAfter,
        wrongBefore,
        reason: 'wrongCount가 증가하지 않아야 함 (앞면 스와이프)',
      );

      // 카드 인덱스도 변하지 않아야 함 — 같은 한국어 텍스트가 여전히 보임
      expect(find.text('사과'), findsOneWidget);
    },
  );

  testWidgets('앞면(flipped=false) 좌측 드래그 → SRS 미기록 (§C-1-1 regression, left)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('사과'), findsOneWidget);

    final srsBefore = Storage.srsCard('사과');

    // 좌측 드래그 (nicht gewusst 방향)
    await tester.drag(
      find.text('사과'),
      const Offset(-220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter = Storage.srsCard('사과');

    expect(
      srsAfter?.reviewCount,
      srsBefore?.reviewCount,
      reason: 'srsReview 미호출 (앞면 좌측 스와이프)',
    );

    // 여전히 같은 카드
    expect(find.text('사과'), findsOneWidget);
  });
}
