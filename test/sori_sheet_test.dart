import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/sheet.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// SoriSheet — "박스창이 화면보다 커서 잘림" 구조적 방어 회귀 테스트.
///
/// 1. 내용이 화면보다 훨씬 커도(2000px) 시트는 화면높이×0.88 이하로 클램프
///    + 오버플로 예외 0 (내부 스크롤로 흡수).
/// 2. 텍스트 스케일 1.3 클램프가 시트 내부에 적용된다.
void main() {
  Widget host({
    double textScale = 1.0,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 640),
        textScaler: TextScaler.linear(textScale),
        viewInsets: viewInsets,
      ),
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSoriSheet<void>(
                  context: context,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 40; i++)
                        const SizedBox(
                          height: 50,
                          child: Text('Zeile mit Inhalt'),
                        ),
                    ],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('내용 2000px → 시트는 화면의 88% 이하 + 오버플로 0', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 오버플로/레이아웃 예외 없음.
    expect(tester.takeException(), isNull);

    // 시트 셸 높이가 640 × 0.88 이하.
    final shell = find.byType(SoriSheetShell);
    expect(shell, findsOneWidget);
    final size = tester.getSize(shell);
    expect(size.height, lessThanOrEqualTo(640 * 0.88 + 0.5));

    // 내용은 스크롤 가능 (40줄 중 일부만 보임).
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('텍스트 스케일 1.6에서도 잘림/오버플로 0 (1.3 클램프)', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(textScale: 1.6));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // 시트 내부 텍스트는 1.3으로 클램프된다.
    final innerCtx = tester.element(find.text('Zeile mit Inhalt').first);
    final scaled = MediaQuery.textScalerOf(innerCtx).scale(10);
    expect(scaled, lessThanOrEqualTo(13.0 + 0.01));
  });

  testWidgets('sheet reserves the keyboard inset inside its safe shell', (
    tester,
  ) async {
    const keyboardInset = 220.0;
    await tester.pumpWidget(
      host(viewInsets: const EdgeInsets.only(bottom: keyboardInset)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final paddedShell = find.byWidgetPredicate((widget) {
      if (widget is! Container || widget.padding == null) return false;
      final padding = widget.padding!.resolve(TextDirection.ltr);
      return padding.bottom == Spacing.lg + keyboardInset;
    });
    expect(paddedShell, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
