import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/spotlight_coach.dart';

/// 2026-08-06 Jin 태블릿 실기기: 코치마크가 **가로모드에서 짜부라지고**,
/// 태블릿에서는 화면 폭을 다 먹는 흰 판이 되어 "지금 뭘 가리키는 거지?"가 됐다.
/// 예외가 안 나는 결함이라 responsive smoke 로는 못 잡는다 — 말풍선이 실제로
/// 어디에, 얼마나 크게 그려졌는지를 사각형으로 고정한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 왼쪽 세로 레일의 아이콘(= Üben 탭) 을 흉내낸 타겟.
  const railTarget = Rect.fromLTWH(24, 240, 48, 48);
  // 화면 가운데 카드(= 오늘의 미션) 를 흉내낸 타겟.
  const cardTarget = Rect.fromLTWH(120, 180, 400, 120);

  for (final size in <Size>[
    Size(360, 800), // 폰 세로
    Size(740, 360), // 폰 가로 (짧은 뷰포트)
    Size(800, 600), // CI 기본 서피스
    Size(1280, 800), // 태블릿 가로
    Size(800, 1280), // 태블릿 세로
  ]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    for (final target in <({String name, Rect rect})>[
      (name: 'rail', rect: railTarget),
      (name: 'card', rect: cardTarget),
    ]) {
      testWidgets('$label ${target.name}: 말풍선이 화면 안에 들어온다', (tester) async {
        await _showCoach(tester, size: size, target: target.rect);

        final card = tester.getRect(find.byKey(kSpotlightTooltipKey));
        expect(card.left, greaterThanOrEqualTo(-0.01), reason: label);
        expect(card.top, greaterThanOrEqualTo(-0.01), reason: label);
        expect(card.right, lessThanOrEqualTo(size.width + 0.01), reason: label);
        expect(
          card.bottom,
          lessThanOrEqualTo(size.height + 0.01),
          reason: label,
        );
        expect(tester.takeException(), isNull, reason: label);
      });

      testWidgets('$label ${target.name}: 말풍선 폭이 상한을 안 넘는다', (tester) async {
        await _showCoach(tester, size: size, target: target.rect);

        final card = tester.getRect(find.byKey(kSpotlightTooltipKey));
        expect(
          card.width,
          lessThanOrEqualTo(kSpotlightTooltipMaxWidth + 0.01),
          reason: '$label ${target.name}',
        );
      });
    }

    testWidgets('$label: 말풍선이 타겟 가까이 붙는다', (tester) async {
      await _showCoach(tester, size: size, target: railTarget);

      final card = tester.getRect(find.byKey(kSpotlightTooltipKey));
      // 예전 구현은 `left: 16, right: 16` 이라 왼쪽 끝 레일을 설명하면서
      // 카드가 화면 오른쪽 끝까지 뻗었다. 이제는 타겟에서 한 화면 폭만큼
      // 멀어질 수 없다 — 가장 가까운 모서리 사이 거리로 고정한다.
      final gapX = card.left > railTarget.right
          ? card.left - railTarget.right
          : (railTarget.left > card.right ? railTarget.left - card.right : 0.0);
      final gapY = card.top > railTarget.bottom
          ? card.top - railTarget.bottom
          : (railTarget.top > card.bottom ? railTarget.top - card.bottom : 0.0);
      expect(gapX, lessThanOrEqualTo(32), reason: '$label horizontal gap');
      expect(gapY, lessThanOrEqualTo(32), reason: '$label vertical gap');
    });
  }

  testWidgets('세로 레일 타겟은 오른쪽 옆에 붙는다 (설명과 대상이 나란히)', (tester) async {
    await _showCoach(
      tester,
      size: const Size(1280, 800),
      target: railTarget,
    );

    final card = tester.getRect(find.byKey(kSpotlightTooltipKey));
    expect(card.left, greaterThanOrEqualTo(railTarget.right));
    // 세로로는 타겟 중심 근처 — 화면 반대쪽 끝이 아니다.
    expect((card.center.dy - railTarget.center.dy).abs(), lessThan(24));
  });

  testWidgets('짧은 가로모드에서도 다음/완료 버튼이 실제로 눌린다', (tester) async {
    var completed = false;
    await _showCoach(
      tester,
      size: const Size(740, 360),
      target: railTarget,
      steps: 2,
      onComplete: () => completed = true,
    );

    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pump();
    await tester.pump();

    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });

  testWidgets('단계 카운터가 현재 위치를 문자로도 알려준다', (tester) async {
    await _showCoach(
      tester,
      size: const Size(800, 600),
      target: cardTarget,
      steps: 3,
    );

    expect(find.text('1 / 3'), findsOneWidget);
  });
}

Future<void> _showCoach(
  WidgetTester tester, {
  required Size size,
  required Rect target,
  int steps = 1,
  VoidCallback? onComplete,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final keys = List.generate(steps, (_) => GlobalKey());

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(
        body: Stack(
          children: [
            for (var i = 0; i < steps; i++)
              Positioned.fromRect(
                rect: target,
                child: SizedBox(key: keys[i]),
              ),
            Builder(
              builder: (context) => TextButton(
                key: const Key('start-coach'),
                onPressed: () => SpotlightCoach.show(
                  context,
                  steps: [
                    for (var i = 0; i < steps; i++)
                      SpotlightStep(
                        targetKey: keys[i],
                        title: 'Üben',
                        body:
                            'Spiele, Wörter & Grammatik zum Wiederholen — '
                            'hier vertiefst du, was du schon kennst.',
                        icon: Icons.sports_esports_outlined,
                      ),
                  ],
                  onComplete: onComplete ?? () {},
                ),
                child: const Text('start'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('start-coach')));
  await tester.pump();
  await tester.pump();
}
