import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

/// §C-3c flipgate 센서: review_session 화면 — "앞면(flipped=false) 드래그 시
/// SRS 기록 0 + 카드 인덱스 불변".
///
/// `enabled: _flipped` 배선 한 줄이 지워지면 이 테스트가 빨개진다.
/// (위젯 테스트 swipe_card_test.dart 의 enabled:false 케이스와 상보.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDeck = [
    const Vocab(
      id: 'rv_1',
      korean: '학교',
      romanization: 'hakgyo',
      german: 'Schule',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '학교에 가다',
      exampleGerman: 'Zur Schule gehen',
      topic: 'Bildung',
    ),
    const Vocab(
      id: 'rv_2',
      korean: '선생님',
      romanization: 'seonsaengnim',
      german: 'Lehrer',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '선생님이 오다',
      exampleGerman: 'Der Lehrer kommt',
      topic: 'Bildung',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
    });
    await Storage.init();
  });

  Widget buildScreen() => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
      child: ReviewSessionScreen(deck: testDeck),
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
    expect(find.text('학교'), findsOneWidget);

    final srsBefore = Storage.srsCard('학교');

    // 앞면 상태에서 우측 임계 초과 드래그
    await tester.drag(
      find.text('학교'),
      const Offset(220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter = Storage.srsCard('학교');

    expect(
      srsAfter?.reviewCount,
      srsBefore?.reviewCount,
      reason: 'srsReview 미호출 (앞면 스와이프 = enabled:false)',
    );

    // 같은 카드 유지
    expect(find.text('학교'), findsOneWidget);
  });

  testWidgets('앞면 좌측 드래그 → SRS 미기록 (§C-1-1 regression, left)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('학교'), findsOneWidget);

    final srsBefore = Storage.srsCard('학교');

    await tester.drag(
      find.text('학교'),
      const Offset(-220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter = Storage.srsCard('학교');

    expect(
      srsAfter?.reviewCount,
      srsBefore?.reviewCount,
      reason: 'srsReview 미호출 (앞면 좌측 스와이프)',
    );

    expect(find.text('학교'), findsOneWidget);
  });

  testWidgets('버튼 판정→다음 카드 플립 없이 스와이프 → SRS 불변 (리셋 경로 센서)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // 카드 1: 학교
    expect(find.text('학교'), findsOneWidget);

    // 플립 전 판정 버튼은 힌트만 보여 주고 SRS를 기록하지 않는다.
    await tester.tap(find.bySemanticsLabel('Gewusst!'));
    await tester.pump();
    expect(find.text('학교'), findsOneWidget);
    expect(Storage.srsCard('학교')?.reviewCount, isNull);

    // 뒤집은 뒤 같은 접근성 버튼으로 판정한다.
    await tester.tap(find.text('학교'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.bySemanticsLabel('Gewusst!'));
    await tester.pumpAndSettle();

    // 카드 2: 선생님 — 리셋으로 앞면이어야 함
    expect(find.text('선생님'), findsOneWidget);

    final srsBefore2 = Storage.srsCard('선생님');

    // 카드 2: 플립 없이 우측 스와이프 → 무시되어야 함
    await tester.drag(
      find.text('선생님'),
      const Offset(220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter2 = Storage.srsCard('선생님');

    expect(
      srsAfter2?.reviewCount,
      srsBefore2?.reviewCount,
      reason: '다음 카드는 _flipped=false 리셋 → 스와이프 무시',
    );

    // 여전히 두 번째 카드 유지
    expect(find.text('선생님'), findsOneWidget);
  });
}
