import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/progress_meter.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// **SoriProgressMeter** 계약 (§W-D D1).
///
/// `MediaQuery(disableAnimations: true)` 는 실제 시스템 "동작 줄이기"를
/// 흉내내는 표준 테스트 패턴 — [SoriMotion.reduceMotion] 이 이걸 읽는다.
/// 그 아래에서는 단 1프레임(`tester.pump()`, `pumpAndSettle` 아님)만으로도
/// 최종값이 렌더돼야 한다 — 애니메이션 대기 없이 즉시.
void main() {
  Widget host(Widget child, {bool reduceMotion = true}) => MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  group('SoriProgressMeter.segments', () {
    testWidgets('칸 수는 total, 채워진 색은 filled 개수만큼', (tester) async {
      await tester.pumpWidget(
        host(
          const SoriProgressMeter.segments(filled: 3, total: 7),
        ),
      );
      await tester.pump();

      final coloredBoxes = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(SoriProgressMeter),
              matching: find.byType(ColoredBox),
            ),
          )
          .toList();
      expect(coloredBoxes.length, 7);
      final filledCount = coloredBoxes
          .where((box) => box.color == SoriColors.primary)
          .length;
      expect(filledCount, 3);
    });

    testWidgets('라벨 텍스트가 렌더된다', (tester) async {
      await tester.pumpWidget(
        host(
          const SoriProgressMeter.segments(
            filled: 2,
            total: 7,
            label: '2 / 7 Bauteile',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('2 / 7 Bauteile'), findsOneWidget);
    });

    testWidgets('disableAnimations 에서 pump 1프레임 후 최종값이 렌더된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const SoriProgressMeter.segments(filled: 4, total: 7)),
      );
      // 딱 1프레임 — pumpAndSettle 아님.
      await tester.pump();

      final coloredBoxes = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(SoriProgressMeter),
              matching: find.byType(ColoredBox),
            ),
          )
          .toList();
      final filledCount = coloredBoxes
          .where((box) => box.color == SoriColors.primary)
          .length;
      expect(filledCount, 4);
      final opacities = tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacities.every((o) => o.opacity == 1), isTrue);
    });
  });

  group('SoriProgressMeter.bar', () {
    testWidgets('disableAnimations 에서 pump 1프레임 후 최종 너비가 렌더된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const SoriProgressMeter.bar(value: 0.6, label: '3 / 5')),
      );
      await tester.pump();

      final fraction = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fraction.widthFactor, 0.6);
      expect(find.text('3 / 5'), findsOneWidget);
    });

    testWidgets('라벨이 없으면 트레일링 텍스트를 렌더하지 않는다', (tester) async {
      await tester.pumpWidget(host(const SoriProgressMeter.bar(value: 0.4)));
      await tester.pump();

      expect(find.byType(Text), findsNothing);
    });
  });

  group('SoriProgressMeter.ring', () {
    testWidgets('value 1.5 는 1.0 으로 클램프된다 (예외 없음)', (tester) async {
      await tester.pumpWidget(host(const SoriProgressMeter.ring(value: 1.5)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('value -0.2 는 0.0 으로 클램프된다 (예외 없음)', (tester) async {
      await tester.pumpWidget(host(const SoriProgressMeter.ring(value: -0.2)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('center 위젯을 중앙에 렌더한다', (tester) async {
      await tester.pumpWidget(
        host(
          const SoriProgressMeter.ring(
            value: 0.5,
            center: Text('50%'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('50%'), findsOneWidget);
    });
  });
}
