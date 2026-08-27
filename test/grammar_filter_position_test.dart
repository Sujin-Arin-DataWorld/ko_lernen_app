import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';

/// 검수#17 회귀 가드.
///
/// `grammar_screen.dart` 의 `_applyFilters()` 는 예전엔 레벨/유형/난이도 중
/// 하나만 바꿔도 무조건 `_idx = 0` 으로 되돌렸다. 20번째 카드를 보다가
/// 난이도 필터를 건드리면 1번 카드로 튀어 "랜덤하게 딴 카드로 간다" 는
/// 체감을 냈다 — 이게 지시서 1.11 "랜덤" 신고의 유력 원인이었다.
///
/// 이 파일은 그 계약을 고정한다: 지금 보던 카드가 새 필터에도 남아 있으면
/// 그 자리를 지키고(테스트 1), 진짜 사라졌을 때만 0 으로 되돌리며(테스트 2),
/// 아래 방향 플링에 배선한 `onPrevious` 가 idx>0 에서만 열리고 부르면 카드를
/// 한 장 되돌린다(테스트 3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // 4방향 덱 코치가 전체 화면 스포트라이트로 탭/플링을 삼키지 않도록
    // (course_practice_screen_test.dart 와 같은 이유).
    await Storage.setTutSeen('grammar');
    await Storage.setTutSeen('soriDeck');
    DataLoader.reset();
    // 실제 asset(rootBundle)에서 읽는 콜드 로드라 `_settle()`의 짧은 pump
    // 예산과 경합할 수 있다 — course_practice_screen_test.dart 와 같은
    // 이유로 위젯을 펌프하기 전에 캐시를 데운다.
    await DataLoader.loadGrammar();
  });

  final positionCounter = find.textContaining(RegExp(r'^\d+ / \d+$'));

  String position(WidgetTester tester) =>
      tester.widget<Text>(positionCounter).data!;

  Future<void> skipForward(WidgetTester tester, int times) async {
    // `onSkip` 콜백을 직접 호출한다 — circular_feedback_widget_test.dart(:331)
    // 와 같은 확립된 패턴. 실제 카드(FlipCard 내부 SingleChildScrollView 포함)
    // 위에서 세로 플링 제스처를 시뮬레이션하면 안쪽 스크롤뷰와 제스처
    // 아레나를 다퉈 신뢰할 수 없다 — content_feed_test.dart 는 플링→콜백
    // 디스패치 자체를 이미 격리된 위젯으로 고정해 뒀으므로, 여기서는
    // grammar_screen 이 그 콜백을 어떻게 배선했는지만 직접 검증한다.
    for (var i = 0; i < times; i++) {
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onSkip!();
      await tester.pump();
    }
  }

  testWidgets('난이도 필터를 바꿔도 목록이 줄지 않으면 카드 위치가 유지된다 (검수#17)', (tester) async {
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _settle(tester);

    expect(positionCounter, findsOneWidget);
    expect(position(tester), startsWith('1 / '));

    await skipForward(tester, 3);
    final beforeFilter = position(tester);
    expect(
      beforeFilter,
      isNot(startsWith('1 / ')),
      reason: '카드를 세 장 넘겼는데 위치가 1번에 머물러 있다 — 테스트 전제가 깨졌다',
    );

    // 방금 초기화한 세션엔 Storage.grammarHard 가 비어 있다 — 난이도를
    // 'Alle'→'Leicht' 로 바꿔도 hardPatterns.contains() 가 전부 false 라
    // 목록이 한 장도 줄지 않는다. "지금 카드가 새 목록에 그대로 남아
    // 있어야 하는" 케이스를 결정적으로 재현한다.
    expect(Storage.grammarHard, isEmpty);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    final t = AppL10n.of(tester.element(find.byType(GrammarScreen)));
    await tester.tap(find.widgetWithText(SoriChip, t.grammarEasy));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SoriButton, t.btnApply));
    await tester.pumpAndSettle();

    final afterFilter = position(tester);
    expect(
      afterFilter,
      beforeFilter,
      reason:
          '난이도 필터를 바꾸자 카드 위치가 $beforeFilter → $afterFilter 로 튀었다 — '
          '_applyFilters() 가 _idx 를 0 으로 되돌렸다(검수#17 회귀).',
    );
  });

  testWidgets('필터를 바꿔 지금 카드가 새 목록에서 진짜 사라지면 위치가 0으로 되돌아간다', (tester) async {
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _settle(tester);

    // A1 으로 스코프(assets/data/grammar.csv 실측 2026-08-27: 41장).
    // 개수 라벨 + 앞쪽 CTA 때문에 뒤쪽 레벨 칩이 가로 ListView 클립 끝에
    // 붙을 수 있다(circular_feedback_widget_test.dart 의 #89/#91 메모와
    // 같은 사유) — ensureVisible 대신 scrollUntilVisible 로 정착시킨다.
    final filterRow = find.descendant(
      of: find.byKey(const Key('grammar-filter-row')),
      matching: find.byType(Scrollable),
    );
    final a1Chip = find.byKey(const Key('grammar-level-A1'));
    await tester.scrollUntilVisible(a1Chip, 120, scrollable: filterRow);
    await tester.pumpAndSettle();
    await tester.tap(a1Chip);
    await tester.pumpAndSettle();

    await skipForward(tester, 2);
    expect(
      position(tester),
      isNot(startsWith('1 / ')),
      reason: 'A1 안에서 두 장을 넘겼는데 위치가 1번에 머물러 있다 — 테스트 전제가 깨졌다',
    );

    // A2 는 A1 과 레벨이 겹치지 않는다(패턴마다 level 은 단일 값) — 지금
    // 카드는 새 목록에서 반드시 사라진다.
    final a2Chip = find.byKey(const Key('grammar-level-A2'));
    await tester.scrollUntilVisible(a2Chip, 120, scrollable: filterRow);
    await tester.pumpAndSettle();
    await tester.tap(a2Chip);
    await tester.pumpAndSettle();

    expect(position(tester), startsWith('1 / '));
  });

  testWidgets('onPrevious 콜백은 idx>0 에서만 열리고, 부르면 카드를 한 장 되돌린다 (검수#17 배선)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _settle(tester);

    expect(
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onPrevious,
      isNull,
      reason: '첫 카드(idx=0)에는 되돌아갈 곳이 없다',
    );

    await skipForward(tester, 1);
    final afterOneSkip = position(tester);
    expect(afterOneSkip, isNot(startsWith('1 / ')));

    final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
    expect(feed.onPrevious, isNotNull);
    feed.onPrevious!();
    await tester.pumpAndSettle();

    expect(position(tester), startsWith('1 / '));
  });

  testWidgets(
    '이전 카드 대체수단(WCAG 2.5.1 커스텀 시맨틱 액션)은 idx>0 에서만 노출된다 (접근성 후속수정 A3)',
    (tester) async {
      // onPrevious(아래 플링)는 easy/hard/save/skip 과 같은
      // customSemanticsActions 목록에 있었는데, 그 목록 자체엔 처음부터
      // 빠져 있었다 — 스와이프를 쓸 수 없는 사용자는 카드를 되돌릴 방법이
      // TalkBack/VoiceOver 메뉴에 아예 없었다.
      await tester.pumpWidget(_wrap(const GrammarScreen()));
      await _settle(tester);

      Map<CustomSemanticsAction, VoidCallback> customActions() {
        final matches = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where(
              (w) =>
                  w.properties.customSemanticsActions != null &&
                  w.properties.customSemanticsActions!.isNotEmpty,
            )
            .toList();
        expect(
          matches,
          hasLength(1),
          reason: '커스텀 시맨틱 액션 컨테이너는 카드 영역에 하나뿐이어야 한다',
        );
        return matches.single.properties.customSemanticsActions!;
      }

      final t = AppL10n.of(tester.element(find.byType(GrammarScreen)));

      expect(
        customActions().keys.map((a) => a.label),
        isNot(contains(t.grammarPreviousCard)),
        reason: '첫 카드(idx=0)에는 되돌아갈 곳이 없다 — 대체수단도 노출되면 안 된다',
      );

      await skipForward(tester, 1);

      expect(
        customActions().keys.map((a) => a.label),
        contains(t.grammarPreviousCard),
        reason: 'idx>0 이면 스와이프와 동등한 대체수단(커스텀 액션)도 열려야 한다',
      );
    },
  );
}

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: true),
      child: child!,
    );
  },
  home: child,
);

Future<void> _settle(WidgetTester tester) async {
  // course_practice_screen_test.dart 와 같은 이유로 pumpAndSettle 은 초기
  // 로드 직후엔 쓰지 않는다 — 진입 애니메이션이 있다. 짧은 두 프레임이면
  // 에셋 로드엔 충분하다.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
