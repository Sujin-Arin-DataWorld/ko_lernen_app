import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';

/// W10 T-G1 — 뒤집기 전 슬라이딩(onSkip)이 플랜 모드의 하루치 안에서
/// 무한 순환하던 버그의 회귀 방지(지시서 1.11/1.12).
///
/// content_feed.dart:230-232 계약: 카드를 뒤집기 전에는 어떤 방향의
/// 세로 플링도 [onSkip]으로 해석된다. `_next()`(레거시 둘러보기)는
/// `% _filtered.length` 로 항상 순환하므로, 플립 없이 계속 아래로만
/// 슬라이드하면 마지막 카드에서 "Tag geschafft!" 완료 시트를 영영 볼 수
/// 없었다. `_skipCurrent()`가 마지막 카드에서 플랜 완료로 갈아타는지,
/// 그리고 레거시 둘러보기의 순환은 그대로인지를 검증한다.
final AppL10n _l10n = lookupAppL10n(const Locale('en'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_grammar': true,
      'kl_tut_soriDeck': true,
    });
    await Storage.init();
    DataLoader.reset();
    CurriculumCatalog.reset();
    await DataLoader.loadGrammar();
  });

  testWidgets(
    'skipping past the last card in a plan day completes the day exactly '
    'once instead of wrapping',
    (tester) async {
      await _storePlans({
        'a1': const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 3,
          servedIdsByDate: {},
        ),
      });
      await _pumpGrammar(tester);

      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsNothing,
      );
      expect(find.text('1 / 3'), findsOneWidget);

      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));

      // 1번째 스킵: 하루치 안의 다음 카드로 넘어간다(마지막 카드가 아님).
      feed.onSkip!();
      await tester.pump();
      expect(find.text('2 / 3'), findsOneWidget);

      // 2번째 스킵: 이제 마지막 카드(인덱스 2, 3장 중 3번째)에 있다.
      feed.onSkip!();
      await tester.pump();
      expect(find.text('3 / 3'), findsOneWidget, reason: '(b) 2번 스킵 후 마지막 카드');
      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsNothing,
        reason: '아직 마지막 카드에서 스킵하지 않았다',
      );

      // 3번째 스킵: 마지막 카드에서 스킵 → 순환하지 않고 하루 완료로 간다.
      feed.onSkip!();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsOneWidget,
        reason: '(a) 완료 시트가 정확히 한 번 뜬다',
      );

      final plan = GrammarPlanService.decodePlans(
        Storage.grammarPlanRawJson,
      )['a1'];
      final servedToday = plan?.servedIdsByDate[Storage.todayIso()];
      expect(plan?.servedIdsByDate.length, 1, reason: '(a) 오늘치 하루만 기록된다');
      expect(servedToday?.length, 3, reason: '(a) 카드 3장 id 가 모두 기록된다');

      _tapSheetButton(tester, _l10n.grammarPlanCompletionSkip);
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('grammar-plan-day-complete')),
        findsOneWidget,
        reason: '(a) 완료 시트를 닫으면 하루 완료 화면이 남는다',
      );
    },
  );

  testWidgets(
    'legacy browse (no active plan) still wraps back to the first card '
    'after skipping past the last one',
    (tester) async {
      await _pumpGrammar(tester);

      // 온보딩 시트를 닫아 레거시 둘러보기로 전환한다(플랜 시작 안 함).
      await tester.tapAt(const Offset(8, 8));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('grammar-filter-row')), findsOneWidget);
      expect(find.byKey(const Key('grammar-plan-day-header')), findsNothing);

      final initial = _cardCounterText(tester);
      expect(initial, startsWith('1 / '));
      final total = int.parse(initial.split(' / ')[1]);
      expect(total, greaterThan(1), reason: '순환을 검증하려면 카드가 2장 이상이어야 한다');

      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
      for (var i = 0; i < total; i++) {
        feed.onSkip!();
        await tester.pump();
      }

      expect(
        _cardCounterText(tester),
        '1 / $total',
        reason: '(c) 레거시 둘러보기는 마지막 카드에서 스킵하면 그대로 처음으로 순환한다',
      );
    },
  );
}

String _cardCounterText(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data != null &&
        RegExp(r'^\d+ / \d+$').hasMatch(widget.data!),
  );
  return tester.widget<Text>(finder).data!;
}

Future<void> _storePlans(Map<String, GrammarStudyPlan> plans) =>
    Storage.setGrammarPlanRawJson(GrammarPlanService.encodePlans(plans));

void _tapSheetButton(WidgetTester tester, String label) =>
    tester.widget<SoriButton>(find.widgetWithText(SoriButton, label)).onTap!();

Future<void> _pumpGrammar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const GrammarScreen(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
