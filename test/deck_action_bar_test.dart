// DeckActionBar 계약 (Sori Deck 2.0 · §P2-3).
//
// 대형 텍스트 CTA 두 개를 대체한 미니 아이콘 바다. 여기서 고정하는 것:
//   ① 4개 동작(모름·스킵·저장·앎)이 각각 정확히 한 번 불린다.
//   ② 판정 두 개는 플립 게이트를 받는다 — 잠긴 동안 판정 대신 힌트가 뜬다.
//      (review·custom 에서는 **의도된 행동 변경**이다: 두 화면의 옛 판정
//       버튼은 앞면에서도 SRS 를 기록할 수 있었다.)
//   ③ 잠겨도 버튼은 **사라지지 않는다** — 자리를 지켜야 위 카드의 지오메트리가
//      플립할 때마다 튀지 않는다.
//   ④ 저장은 숨길 수 있다 (custom pack).
//   ⑤ 접근성: 탭 타깃 48dp 이상 + Semantics 라벨.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host({
    required VoidCallback onDontKnow,
    required VoidCallback onKnow,
    required VoidCallback onSkip,
    VoidCallback? onSave,
    bool judgmentEnabled = true,
    VoidCallback? onBlockedJudgment,
  }) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(
      body: Center(
        child: DeckActionBar(
          onDontKnow: onDontKnow,
          onKnow: onKnow,
          onSkip: onSkip,
          onSave: onSave,
          judgmentEnabled: judgmentEnabled,
          onBlockedJudgment: onBlockedJudgment,
        ),
      ),
    ),
  );

  void tap(WidgetTester tester, String name) {
    tester
        .widget<SoriPressable>(
          find.descendant(
            of: find.byKey(deckActionKey(name)),
            matching: find.byType(SoriPressable),
          ),
        )
        .onTap
        ?.call();
  }

  testWidgets('네 동작이 각각 한 번씩 불린다', (tester) async {
    var dontKnow = 0, know = 0, skip = 0, save = 0;
    await tester.pumpWidget(
      host(
        onDontKnow: () => dontKnow++,
        onKnow: () => know++,
        onSkip: () => skip++,
        onSave: () => save++,
      ),
    );

    for (final name in ['dontknow', 'skip', 'save', 'know']) {
      tap(tester, name);
    }
    await tester.pump();

    expect([dontKnow, skip, save, know], [1, 1, 1, 1]);
  });

  testWidgets('판정 잠금: 좌/우는 0회, 힌트 1회, 보조 동작은 정상', (tester) async {
    var judged = 0, skip = 0, save = 0, blocked = 0;
    await tester.pumpWidget(
      host(
        onDontKnow: () => judged++,
        onKnow: () => judged++,
        onSkip: () => skip++,
        onSave: () => save++,
        judgmentEnabled: false,
        onBlockedJudgment: () => blocked++,
      ),
    );

    tap(tester, 'dontknow');
    tap(tester, 'know');
    await tester.pump();
    expect(judged, 0, reason: '플립 전에는 버튼으로도 판정할 수 없다');
    expect(blocked, 2, reason: '대신 힌트를 부른다 — 죽은 버튼이 아니다');

    tap(tester, 'skip');
    tap(tester, 'save');
    await tester.pump();
    expect([skip, save], [1, 1], reason: '스킵·저장은 판정이 아니라 게이트와 무관');
  });

  testWidgets('잠겨도 버튼은 자리를 지킨다 (카드 지오메트리 안정)', (tester) async {
    await tester.pumpWidget(
      host(
        onDontKnow: () {},
        onKnow: () {},
        onSkip: () {},
        onSave: () {},
        judgmentEnabled: true,
      ),
    );
    final Size enabled = tester.getSize(find.byType(DeckActionBar));

    await tester.pumpWidget(
      host(
        onDontKnow: () {},
        onKnow: () {},
        onSkip: () {},
        onSave: () {},
        judgmentEnabled: false,
        onBlockedJudgment: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(DeckActionBar)),
      enabled,
      reason: '잠금이 크기를 바꾸면 플립할 때마다 카드가 튄다',
    );
    expect(find.byKey(deckActionKey('know')), findsOneWidget);
  });

  testWidgets('저장은 숨길 수 있다 (custom pack)', (tester) async {
    await tester.pumpWidget(
      host(onDontKnow: () {}, onKnow: () {}, onSkip: () {}),
    );
    expect(find.byKey(deckActionKey('save')), findsNothing);
    // 나머지 셋은 그대로.
    for (final name in ['dontknow', 'skip', 'know']) {
      expect(find.byKey(deckActionKey(name)), findsOneWidget);
    }
  });

  testWidgets('탭 타깃 48dp 이상 + Semantics 라벨', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(onDontKnow: () {}, onKnow: () {}, onSkip: () {}, onSave: () {}),
    );

    for (final name in ['dontknow', 'skip', 'save', 'know']) {
      final size = tester.getSize(find.byKey(deckActionKey(name)));
      expect(
        size.shortestSide,
        greaterThanOrEqualTo(48),
        reason: '$name 탭 타깃이 48dp 미만',
      );
      final data = tester
          .getSemantics(find.byKey(deckActionKey(name)))
          .getSemanticsData();
      expect(data.label, isNotEmpty, reason: '$name 에 Semantics 라벨이 없다');
    }
    handle.dispose();
  });
}
