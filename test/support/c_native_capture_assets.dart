import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';

/// Decode actual production images outside the test clock before raster capture.
/// pumpAndSettle alone does not wait for codecs or cached FutureBuilder futures.
Future<void> settleCNativeCaptureAssets(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp).first);
  final images = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  final atlases = tester
      .widgetList<CAtlasArt>(find.byType(CAtlasArt))
      .map((art) => art.path)
      .toSet();
  await tester.runAsync(() async {
    await Future.wait([
      for (final provider in images)
        precacheImage(provider, context).timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw StateError('Image decode timed out: $provider'),
        ),
      for (final path in atlases)
        CImageCache.load(path).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw StateError('Atlas decode timed out: $path'),
        ),
    ]);
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  expect(
    find
        .descendant(
          of: find.byType(CAtlasArt),
          matching: find.byType(CustomPaint),
        )
        .evaluate()
        .length,
    find.byType(CAtlasArt).evaluate().length,
    reason: 'Every visible atlas illustration must paint before capture.',
  );
}
