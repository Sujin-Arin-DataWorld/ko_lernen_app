import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/collapsing_header.dart';

/// §E3: `SoriCollapsingHeader` — 스크롤 0에서 펼친 큰 제목, 스크롤이 그
/// 접힘 예산을 넘으면 접힌 56dp 크롬 바로 스냅한다. reduce-motion 이면
/// 중간 보간 없이 두 상태 사이를 즉시 전환한다.
///
/// 두 상태(펼침/접힘)는 완전히 안 보일 때 위젯 트리에서 통째로 빠진다
/// (`Visibility(maintainState: false)`) — trailing(예: 프로필 버튼)이 양쪽
/// 레이어에 다 있어도 정지 상태에서는 항상 정확히 1개만 트리에 남는다.
void main() {
  const eyebrow = 'LERNEN';
  const title = 'Großer Titel';
  const collapsedTitle = 'Kompakt';
  const body = 'Kurzer Text.';
  const trailingTooltip = 'Profil';

  Widget harness({bool disableAnimations = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SoriCollapsingHeader(
              eyebrow: eyebrow,
              title: title,
              body: body,
              collapsedTitle: collapsedTitle,
              trailing: const Tooltip(
                message: trailingTooltip,
                child: Icon(Icons.person_outline_rounded),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    SizedBox(height: 100, child: Text('item $index')),
                childCount: 30,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Finder expandedFinder() =>
      find.byKey(const ValueKey<String>('sori-collapsing-header-expanded'));
  Finder collapsedFinder() =>
      find.byKey(const ValueKey<String>('sori-collapsing-header-collapsed'));

  testWidgets('스크롤 0에서 펼친 큰 제목이 보이고 접힌 크롬은 트리에서 빠져 있다', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text(title), findsOneWidget);
    expect(tester.widget<Opacity>(expandedFinder()).opacity, 1.0);
    // 완전히 안 보이는 접힌 레이어는 통째로 언마운트돼 있다 — Opacity 로
    // 가려진 게 아니라 애초에 트리에 없다.
    expect(collapsedFinder(), findsNothing);
    // trailing(프로필 버튼)도 펼친 쪽에만 정확히 1개.
    expect(find.byTooltip(trailingTooltip), findsOneWidget);
  });

  testWidgets('접힘 예산을 넘겨 스크롤하면 접힌 제목이 보이고 높이가 56이다', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // 짧은 테스트 콘텐츠(eyebrow+title+body)의 펼친 높이는 300dp 보다
    // 훨씬 작다 — 300dp 스크롤이면 접힘 예산을 넉넉히 넘겨 완전히 접힌다.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text(collapsedTitle), findsOneWidget);
    expect(tester.widget<Opacity>(collapsedFinder()).opacity, 1.0);
    expect(expandedFinder(), findsNothing);
    expect(find.byTooltip(trailingTooltip), findsOneWidget);

    final renderHeader = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    expect(renderHeader.geometry!.paintExtent, kToolbarHeight);
    expect(kToolbarHeight, 56.0);
  });

  testWidgets('reduce-motion 이면 중간 보간 없이 스냅한다', (tester) async {
    await tester.pumpWidget(harness(disableAnimations: true));
    await tester.pumpAndSettle();

    // 완전히 펼친 상태에서 작게 스크롤 — 선형 보간이었다면 접힌 레이어가
    // 부분적으로라도 트리에 나타나야 하지만, reduce-motion 스냅은 여전히
    // 펼친 상태를 유지해야 한다(접힌 레이어 자체가 없어야 한다).
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -10));
    await tester.pump();
    expect(collapsedFinder(), findsNothing);
    expect(tester.widget<Opacity>(expandedFinder()).opacity, 1.0);

    // 접힘 예산을 넘기면 즉시 완전히 접힌 상태로 스냅한다.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pump();
    expect(expandedFinder(), findsNothing);
    expect(tester.widget<Opacity>(collapsedFinder()).opacity, 1.0);
  });

  // §W-G G5.2: `trailing`이 두 개의 48dp 액션(Row)을 담을 때 —
  // `trailingSlots: 2`가 헤더 텍스트 폭 예산에서 그만큼을 미리 뺀다. 접힌
  // 56dp 크롬 바에서 두 액션의 실제 렌더 사각형이 겹치지 않고, 접힌 제목도
  // (짧은 `collapsedTitle` 계약대로) 잘리지 않아야 한다.
  testWidgets('trailingSlots=2: 두 액션이 겹치지 않고 접힌 제목이 잘리지 않는다', (
    tester,
  ) async {
    const tooltipA = 'Hilfe';
    const tooltipB = 'Profil';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SoriCollapsingHeader(
                eyebrow: eyebrow,
                title: title,
                body: body,
                collapsedTitle: collapsedTitle,
                trailingSlots: 2,
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 48,
                      child: Tooltip(
                        message: tooltipA,
                        child: Icon(Icons.help_outline_rounded),
                      ),
                    ),
                    SizedBox(width: 4),
                    SizedBox.square(
                      dimension: 48,
                      child: Tooltip(
                        message: tooltipB,
                        child: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      SizedBox(height: 100, child: Text('item $index')),
                  childCount: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 접힘 예산을 넘겨 스크롤 — 위 테스트들과 같은 300dp.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text(collapsedTitle), findsOneWidget);
    final rectA = tester.getRect(find.byTooltip(tooltipA));
    final rectB = tester.getRect(find.byTooltip(tooltipB));
    expect(
      rectA.overlaps(rectB),
      isFalse,
      reason: '두 트레일링 액션의 48dp 히트영역이 겹치면 안 된다: $rectA vs $rectB',
    );

    final titleParagraph = tester.renderObject<RenderParagraph>(
      find.text(collapsedTitle),
    );
    expect(
      titleParagraph.didExceedMaxLines,
      isFalse,
      reason: '접힌 바 제목은 두 액션이 있어도 완전히 표시돼야 한다',
    );
    expect(tester.takeException(), isNull);
  });
}
