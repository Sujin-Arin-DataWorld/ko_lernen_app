import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_layout.dart';

/// `QuestLayout` 계약 (Jin 2026-08-13: "모든 페이지 한 화면 + CTA 하단 고정").
///
/// 핵심은 **CTA 가 스크롤과 함께 떠내려가지 않는다**는 것이다. 예전에는 퀘스트가
/// 호스트의 `SingleChildScrollView` 안에서 통째로 스크롤돼, 긴 문제에서는
/// `Überprüfen` 이 화면 밖에 있었다.
void main() {
  const ctaKey = Key('quest-cta');
  const tallKey = Key('quest-tall-content');

  Widget harness({required Widget child}) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Widget tallContent() =>
      Container(key: tallKey, height: 2000, color: const Color(0xFF112233));

  Widget cta() => const SizedBox(
    key: ctaKey,
    height: 56,
    child: ColoredBox(color: Color(0xFF1F7A6B)),
  );

  testWidgets('높이가 정해지면 CTA 는 내용이 아무리 길어도 하단에 붙는다', (tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(
        child: QuestLayout(content: tallContent(), action: cta()),
      ),
    );
    await tester.pumpAndSettle();

    final viewportBottom = tester.getRect(find.byType(Scaffold)).bottom;
    final ctaRect = tester.getRect(find.byKey(ctaKey));

    expect(
      ctaRect.bottom,
      closeTo(viewportBottom, 1.0),
      reason: 'CTA 가 화면 하단에 닿아 있어야 한다',
    );
    expect(ctaRect.top, greaterThan(0), reason: 'CTA 가 화면 위로 잘리면 안 된다');
  });

  testWidgets('내용은 CTA 를 밀어내지 않고 남은 공간 안에서 스크롤된다', (tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(
        child: QuestLayout(content: tallContent(), action: cta()),
      ),
    );
    await tester.pumpAndSettle();

    final ctaTop = tester.getRect(find.byKey(ctaKey)).top;
    final contentTopBefore = tester.getRect(find.byKey(tallKey)).top;

    // 화면 안쪽 좌표에서 끈다 — 내용 위젯의 중심은 뷰포트 밖이라 못 쓴다.
    await tester.dragFrom(const Offset(195, 200), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(tallKey)).top,
      lessThan(contentTopBefore - 100),
      reason: '내용은 실제로 스크롤돼야 한다 (아니면 이 테스트는 공허하다)',
    );
    expect(
      tester.getRect(find.byKey(ctaKey)).top,
      closeTo(ctaTop, 1.0),
      reason: '내용을 스크롤해도 CTA 는 제자리에 있어야 한다',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('세로가 무한한 부모 안에서는 예전처럼 쌓아서 그린다', (tester) async {
    await tester.pumpWidget(
      harness(
        child: SingleChildScrollView(
          child: QuestLayout(content: tallContent(), action: cta()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ctaKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CTA 가 없는 엔진(Lücken·Übersetzen)은 내용만 그린다', (tester) async {
    await tester.pumpWidget(
      harness(child: QuestLayout(content: tallContent())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(tallKey), findsOneWidget);
    expect(find.byKey(ctaKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('아주 긴 해설 카드도 화면을 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(
        child: QuestLayout(
          content: tallContent(),
          action: Container(key: ctaKey, height: 3000, color: Colors.white),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: '해설이 길어도 오버플로가 나면 안 된다');
  });
}
