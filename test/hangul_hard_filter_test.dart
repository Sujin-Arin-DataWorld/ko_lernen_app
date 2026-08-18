/// 좌(모름) 판정이 **실제로 쓰이는지** 고정하는 센서 — 2026-08-18.
///
/// 인계 지적: `Storage.hangulHard` 가 write-only 였다. `_dontKnow` 가 기록만
/// 하고 읽는 화면이 없어 좌/우 판정에 아무 효과가 없었다(문법은
/// `grammar_screen.dart:215` 에서 Schwer 필터로 읽는다). 기록만 하고 아무도 안
/// 읽는 상태는 "판정이 있다"는 거짓말이라, 읽는 경로를 만들고 여기서 고정한다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_hangul': true});
    Storage.resetForTesting();
    await Storage.init();
  });

  Future<void> pumpCards(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const HangulScreen(),
      ),
    );
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  const chip = Key('hangul-cards-hard-only');

  testWidgets('모은 글자가 없으면 필터 칩을 띄우지 않는다', (tester) async {
    await pumpCards(tester);
    expect(find.byKey(chip), findsNothing);
  });

  testWidgets('좌(모름)로 모은 글자를 필터가 실제로 읽는다', (tester) async {
    // 판정이 저장소에 남는 경로를 그대로 쓴다.
    await Storage.markHangulHard('ㄷ');
    await pumpCards(tester);

    expect(find.byKey(chip), findsOneWidget, reason: '모은 게 있으면 칩이 뜬다');
    expect(tester.widget<SoriChip>(find.byKey(chip)).selected, isFalse);

    // 자음 덱은 19장 — 필터를 켜면 ㄷ 한 장만 남는다.
    expect(find.text('1 / 19'), findsOneWidget);
    await tester.tap(find.byKey(chip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.widget<SoriChip>(find.byKey(chip)).selected, isTrue);
    expect(
      find.text('1 / 1'),
      findsOneWidget,
      reason: '필터가 hangulHard 를 읽지 않으면 19장 그대로다 (write-only 회귀)',
    );
  });

  testWidgets('앎으로 지우면 필터가 빈 덱을 만들지 않는다', (tester) async {
    // 마지막 한 글자를 지웠을 때 `_pool[_idx % 0]` 으로 터지면 안 된다.
    await Storage.markHangulHard('ㄷ');
    await pumpCards(tester);
    await tester.tap(find.byKey(chip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 / 1'), findsOneWidget);

    await Storage.markHangulEasy('ㄷ');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const HangulScreen(),
      ),
    );
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('1 / 19'), findsOneWidget, reason: '빈 필터는 전체로 되돌린다');
  });
}
