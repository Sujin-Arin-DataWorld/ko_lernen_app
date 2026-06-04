import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/wordle_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/dojangcheop_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/paywall_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/responsive.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. 순수 함수: 클램프 padding 수학 ──────────────────────────────────
  group('soriClampPadding', () {
    test('폭 ≤ maxWidth → base 그대로 (extra 0, 폰 무변화)', () {
      final p = soriClampPadding(
        360,
        maxWidth: 480,
        base: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      );
      expect(p.left, 16);
      expect(p.right, 16);
      expect(p.top, 4); // 상하 보존
      expect(p.bottom, 24);
    });

    test('정확히 maxWidth → extra 0', () {
      final p = soriClampPadding(
        480,
        maxWidth: 480,
        base: const EdgeInsets.symmetric(horizontal: 16),
      );
      expect(p.left, 16);
      expect(p.right, 16);
    });

    test('넓은 폭 → 잉여폭을 좌우로 균등 분배', () {
      final p = soriClampPadding(
        1200,
        maxWidth: 480,
        base: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      );
      expect(p.left, 16 + 360); // (1200 - 480) / 2 = 360
      expect(p.right, 16 + 360);
      expect(p.top, 8);
      expect(p.bottom, 24);
    });

    test('기본값: content breakpoint(480) + Spacing.lg base', () {
      final p = soriClampPadding(SoriBreakpoints.content);
      expect(p.left, Spacing.lg);
      expect(p.right, Spacing.lg);
    });

    test('grid breakpoint(600) override', () {
      final p = soriClampPadding(
        SoriBreakpoints.grid + 200,
        maxWidth: SoriBreakpoints.grid,
        base: const EdgeInsets.symmetric(horizontal: 12),
      );
      expect(p.left, 12 + 100); // 200 / 2
      expect(p.right, 12 + 100);
    });
  });

  // ── 2. SoriContentClamp 위젯: LayoutBuilder 폭 와이어링 ────────────────
  group('SoriContentClamp', () {
    testWidgets('가용 폭에 따라 padding 클램프', (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late EdgeInsets captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriContentClamp(
              base: const EdgeInsets.symmetric(horizontal: 16),
              builder: (_, p) {
                captured = p;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(captured.left, 16 + 260); // (1000 - 480) / 2 = 260
      expect(captured.right, 16 + 260);
    });
  });

  // ── 2b. soriGridColumns: 반응형 grid 컬럼 수 ──────────────────────────
  group('soriGridColumns', () {
    test('폰 360px → min 보존 (회귀 0)', () {
      expect(soriGridColumns(360, target: 110, min: 3, max: 6), 3);
    });
    test('태블릿 768px → 확장', () {
      expect(soriGridColumns(768, target: 110, min: 3, max: 6),
          greaterThan(3));
    });
    test('아주 넓은 폭 → max 상한 클램프', () {
      expect(soriGridColumns(3000, target: 110, min: 3, max: 6), 6);
    });
    test('좁은 폭도 min 밑으로 안 내려감', () {
      expect(soriGridColumns(200, target: 150, min: 2, max: 6), 2);
    });
  });

  // ── 2c. SoriCenterClamp: 비스크롤 중앙 클램프 위젯 ────────────────────
  group('SoriCenterClamp', () {
    testWidgets('넓은 폭 → maxWidth(480)로 제한', (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriCenterClamp(
              child: const SizedBox.expand(
                child: ColoredBox(key: Key('c'), color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 480);
    });

    testWidgets('폰 폭(360) → 그대로 통과 (회귀 0)', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriCenterClamp(
              child: const SizedBox.expand(
                child: ColoredBox(key: Key('c'), color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 360);
    });
  });

  // ── 3. 화면 렌더: 다중 폭에서 오버플로 0 ───────────────────────────────
  group('반응형 화면 다중 폭 렌더', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 3,
        'kl_xp': 40,
      });
      await Storage.init();
      DataLoader.reset();
      ScenarioLoader.reset();
    });

    final screens = <String, Widget>{
      'home': const HomeScreen(),
      'scenarios list': const ScenariosListScreen(),
      'settings': const SettingsScreen(),
      'stats': const StatsScreen(),
      'vocab packs': const VocabPacksScreen(),
      // 반응형 전파 + 핫스팟 동적화 화면 (무인자만)
      'grammar': const GrammarScreen(),
      'hangul': const HangulScreen(),
      'wordle': const WordleScreen(),
      'kkeunmari': const KkeunmariScreen(),
      'dojangcheop': const DojangcheopScreen(),
      'listening': const ListeningScreen(),
      'hard words': const HardWordsScreen(),
      'legacy vocab': const LegacyVocabScreen(),
      'consent': const ConsentScreen(),
      'paywall': const PaywallScreen(),
    };

    for (final width in <double>[308, 360, 800, 1280]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} @ ${width.toInt()}px 오버플로 없음',
            (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(_wrap(entry.value));
          await tester.pump(); // 첫 프레임 (로딩 상태)
          // 비동기 로드(시나리오·due 카운트) 해소 → Today 카드 등 실데이터 상태 렌더.
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 1200));

          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
    onGenerateRoute: (settings) => null,
  );
}
