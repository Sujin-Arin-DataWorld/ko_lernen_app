/// 실제 어려운 글자 기록을 Atelier의 모드별 필터가 읽는지 검증한다.
/// 빈 필터는 전체 덱으로 돌아가며 선택판의 표시도 실제 덱과 일치해야 한다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_tut_hangul': true,
      'kl_tut_hangulWriteRules': true,
    });
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
        home: HangulScreen(
          initialTarget: HangulTarget.cards,
          speechPlayer: (_) async => true,
          textPrefetcher: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const chip = Key('hangul-cards-hard-only');

  Future<void> openModeSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('hangul-cards-selection')));
    await tester.pumpAndSettle();
  }

  testWidgets('모은 글자가 없으면 C 선택판에 실제 0개와 비활성 필터를 보여준다', (tester) async {
    await pumpCards(tester);
    expect(
      tester
          .widget<CAtelierButton>(find.byKey(const Key('hangul-cards-filter')))
          .selected,
      isFalse,
    );
    await openModeSheet(tester);
    expect(find.byKey(chip), findsOneWidget);
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).onTap, isNull);
    expect(
      tester.widget<CAtelierButton>(find.byKey(chip)).label,
      endsWith('(0)'),
    );
  });

  testWidgets('모름 판정으로 모은 글자를 필터가 실제로 읽는다', (tester) async {
    // 판정이 저장소에 남는 경로를 그대로 쓴다.
    await tester.runAsync(() => Storage.markHangulHard('ㄷ'));
    await pumpCards(tester);
    await openModeSheet(tester);

    expect(find.byKey(chip), findsOneWidget, reason: '모은 게 있으면 칩이 뜬다');
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).selected, isFalse);

    // 자음 덱은 19장 — 필터를 켜면 ㄷ 한 장만 남는다.
    expect(find.text('1 / 19'), findsOneWidget);
    await tester.tap(find.byKey(chip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openModeSheet(tester);
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).selected, isTrue);
    expect(
      find.text('1 / 1'),
      findsOneWidget,
      reason: '필터가 hangulHard 를 읽지 않으면 19장 그대로다 (write-only 회귀)',
    );
  });

  testWidgets('앎으로 지우면 필터가 빈 덱을 만들지 않는다', (tester) async {
    // 마지막 한 글자를 지웠을 때 `_pool[_idx % 0]` 으로 터지면 안 된다.
    await tester.runAsync(() => Storage.markHangulHard('ㄷ'));
    await pumpCards(tester);
    await openModeSheet(tester);
    await tester.tap(find.byKey(chip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 / 1'), findsOneWidget);

    await tester.runAsync(() => Storage.markHangulEasy('ㄷ'));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: HangulScreen(
          initialTarget: HangulTarget.cards,
          speechPlayer: (_) async => true,
          textPrefetcher: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('1 / 19'), findsOneWidget, reason: '빈 필터는 전체로 되돌린다');
    expect(
      tester
          .widget<CAtelierButton>(find.byKey(const Key('hangul-cards-filter')))
          .selected,
      isFalse,
    );
    await openModeSheet(tester);
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).selected, isFalse);
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).onTap, isNull);
    expect(
      tester.widget<CAtelierButton>(find.byKey(chip)).label,
      endsWith('(0)'),
    );
  });

  testWidgets('모드에 어려운 글자가 없으면 전체 덱과 비활성 0개 표시가 일치한다', (tester) async {
    await tester.runAsync(() => Storage.markHangulHard('ㄱ'));
    await pumpCards(tester);
    await openModeSheet(tester);
    await tester.tap(find.byKey(chip));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);

    await openModeSheet(tester);
    await tester.tap(find.byKey(const Key('hangul-cards-mode-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 15'), findsOneWidget);
    expect(
      tester
          .widget<CAtelierButton>(find.byKey(const Key('hangul-cards-filter')))
          .selected,
      isFalse,
    );
    await openModeSheet(tester);
    final noVowels = tester.widget<CAtelierButton>(find.byKey(chip));
    expect(noVowels.selected, isFalse);
    expect(noVowels.onTap, isNull);
    expect(noVowels.label, endsWith('(0)'));
    expect(Storage.hangulHard, ['ㄱ']);

    await tester.tap(find.byKey(const Key('hangul-cards-mode-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    await openModeSheet(tester);
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).selected, isTrue);
    expect(
      tester.widget<CAtelierButton>(find.byKey(chip)).label,
      endsWith('(1)'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('어려운 글자 수와 필터는 선택한 자음 모음 범위만 사용한다', (tester) async {
    await tester.runAsync(() => Storage.markHangulHard('ㄱ'));
    await tester.runAsync(() => Storage.markHangulHard('ㅏ'));
    await pumpCards(tester);
    await openModeSheet(tester);
    expect(
      tester.widget<CAtelierButton>(find.byKey(chip)).label,
      endsWith('(1)'),
    );
    await tester.tap(find.byKey(chip));
    await tester.pumpAndSettle();
    await openModeSheet(tester);
    await tester.tap(find.byKey(const Key('hangul-cards-mode-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('hangul-card-ㅏ')), findsOneWidget);
    await tester.tap(find.byType(FlipCard));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    final t = AppL10n.of(tester.element(find.byType(HangulScreen)));
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CAtelierButton && w.label == t.atelierKnown,
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(Storage.hangulHard, ['ㄱ']);
    expect(find.text('2 / 15'), findsOneWidget);
    expect(find.byKey(const ValueKey('hangul-card-ㅑ')), findsOneWidget);
    expect(
      tester
          .widget<CAtelierButton>(find.byKey(const Key('hangul-cards-filter')))
          .selected,
      isFalse,
    );
    await openModeSheet(tester);
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).selected, isFalse);
    expect(tester.widget<CAtelierButton>(find.byKey(chip)).onTap, isNull);
    expect(
      tester.widget<CAtelierButton>(find.byKey(chip)).label,
      endsWith('(0)'),
    );
    expect(tester.takeException(), isNull);
  });
}
