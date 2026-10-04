import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_art.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_canvas.dart';

void main() {
  test('the tighter viewport preserves every approved motion foreground', () {
    for (final folder in [
      'dokkaebi-hint-20261003',
      'dokkaebi-hint-swing-20261003',
    ]) {
      final manifest =
          jsonDecode(
                File(
                  'assets_unused/approved_texture_originals/$folder/manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final runtimeBounds = manifest['runtimeForegroundBounds'] as List?;
      final bounds = runtimeBounds ?? manifest['foregroundBounds'] as List;
      for (var frame = 0; frame < bounds.length; frame++) {
        final raw = (bounds[frame] as List).cast<num>();
        final points = [
          Offset(raw[0].toDouble(), raw[1].toDouble()),
          Offset(raw[2].toDouble(), raw[3].toDouble()),
        ];
        for (final point in points) {
          // The strike manifest records its original 1440px input bounds;
          // reproduce only the documented background crop and uniform inset.
          final placed = runtimeBounds == null
              ? Offset((point.dx - 60) * .92 + 48, (point.dy - 90) * .92 + 48)
              : point;
          expect(
            PracticeDokkaebiCanvas.viewport.deflate(16).contains(placed),
            isTrue,
            reason: '$folder frame $frame must preserve horns, feet and club',
          );
        }
      }
    }
  });

  testWidgets('the resting body matches the first film frame, not its canvas', (
    tester,
  ) async {
    const width = 264.0;
    const height = width / PracticeDokkaebiCanvas.aspectRatio;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: PracticeDokkaebiRestingArt(
                pose: PracticeDokkaebiPose.ready,
              ),
            ),
          ),
        ),
      ),
    );
    final resting = tester.getRect(find.byType(PracticeDokkaebiArt));
    final firstFilmHeight = 637 / 1088 * height;
    expect(resting.height / firstFilmHeight, inInclusiveRange(.95, 1.08));
    expect(tester.takeException(), isNull);
  });
}
