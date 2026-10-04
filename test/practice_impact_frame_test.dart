import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/practice_impact_frame.dart';

void main() {
  testWidgets('contact highlights the card border and preserves input', (
    tester,
  ) async {
    var pulse = 0, taps = 0;
    var reduce = false, visible = true;
    late StateSetter update;
    const capture = ValueKey('impact-capture');
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
              child: Scaffold(
                body: Center(
                  child: TickerMode(
                    enabled: visible,
                    child: RepaintBoundary(
                      key: capture,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: PracticeImpactFrame(
                          pulse: pulse,
                          child: SizedBox(
                            width: 240,
                            height: 160,
                            child: ColoredBox(
                              color: Colors.white,
                              child: GestureDetector(
                                onTap: () => taps++,
                                child: const Center(child: Text('A word')),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    Future<List<int>> pixels() async => (await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(capture),
      );
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List().toList();
      image.dispose();
      return bytes;
    }))!;
    final idle = await pixels();
    bool changedAt(List<int> picture, Offset point) {
      final x = point.dx.round() + 14, y = point.dy.round() + 14;
      for (var dy = -3; dy <= 3; dy++) {
        for (var dx = -3; dx <= 3; dx++) {
          final index = ((y + dy) * 268 + x + dx) * 4;
          if (picture[index] != idle[index] ||
              picture[index + 1] != idle[index + 1] ||
              picture[index + 2] != idle[index + 2]) {
            return true;
          }
        }
      }
      return false;
    }

    int difference(List<int> picture) {
      var result = 0;
      for (var i = 0; i < picture.length; i += 4) {
        result +=
            (picture[i] - idle[i]).abs() +
            (picture[i + 1] - idle[i + 1]).abs() +
            (picture[i + 2] - idle[i + 2]).abs();
      }
      return result;
    }

    final bounds = tester.getRect(find.text('A word'));
    update(() => pulse = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final peak = await pixels();
    for (final point in const [
      Offset(72, 1),
      Offset(239, 80),
      Offset(168, 159),
      Offset(1, 80),
    ]) {
      expect(
        changedAt(peak, point),
        isTrue,
        reason: 'The entire card border highlights together.',
      );
    }
    for (var y = 32; y < 156; y++) {
      final from = (y * 268 + 32) * 4, to = (y * 268 + 236) * 4;
      expect(
        peak.sublist(from, to),
        idle.sublist(from, to),
        reason: 'Learning text/input pixels must stay untouched.',
      );
    }
    expect(tester.getRect(find.text('A word')), bounds);
    await tester.tap(find.text('A word'));
    await tester.pump();
    expect(
      taps,
      1,
      reason: 'The border must not intercept a touch while it is highlighted.',
    );
    await tester.pump(const Duration(milliseconds: 700));
    final fading = await pixels();
    expect(difference(fading), greaterThan(0));
    expect(
      difference(fading),
      lessThan(difference(peak)),
      reason: 'The highlighted border gradually returns to normal.',
    );
    update(() => pulse = 0);
    await tester.pump();
    expect(await pixels(), idle);
    update(() => pulse = 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    update(() => reduce = true);
    await tester.pump();
    expect(await pixels(), idle);
    update(() => reduce = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(await pixels(), idle);
    update(() => pulse = 3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    update(() => visible = false);
    await tester.pump();
    expect(await pixels(), idle);
    update(() => visible = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      await pixels(),
      idle,
      reason: 'Hidden effects must never replay on return.',
    );
    update(() => pulse = 4);
    await tester.pump();
    await tester.pump(
      PracticeImpactTiming.total + const Duration(milliseconds: 50),
    );
    expect(
      await pixels(),
      idle,
      reason: 'One appearance must finish completely.',
    );
    expect(tester.takeException(), isNull);
  });
}
