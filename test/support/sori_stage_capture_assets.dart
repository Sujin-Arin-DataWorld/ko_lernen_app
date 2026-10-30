import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/approved_figma_scene.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';

Future<void>? _prepared;

/// Resolve native C5 scene JSON and decoded atlas pixels before a capture.
/// CAtlasArt paints ui.Image directly, so Image-only precaching misses it.
Future<void> prepareSoriStageCaptureAssets() => _prepared ??= () async {
  await Future.wait([
    for (final scene in const [
      'today-65.json',
      'lernen-65.json',
      'spiele-65.json',
      'hanok-18-962.json',
      'gye-18-1033.json',
    ])
      ApprovedFigmaScene.load(scene),
  ]);
  final assets = await ApprovedFigmaScene.load('figma-assets.json');
  await Future.wait(
    {
      ...assets.values.cast<String>(),
      'assets/illustrations/concept_c/material_atlas.png',
      'assets/illustrations/concept_c/hero_atlas.png',
      'assets/illustrations/concept_c/game_object_atlas.png',
    }.map(CImageCache.load),
  );
}();

/// Await both direct Image widgets and material DecorationImage providers.
/// A second layout pass includes images introduced by completed futures.
Future<void> settleSoriStageCaptureAssets(WidgetTester tester) async {
  await tester.runAsync(prepareSoriStageCaptureAssets);
  await tester.pump();
  for (var pass = 0; pass < 3; pass++) {
    final context = tester.element(find.byType(MaterialApp));
    final providers = <ImageProvider<Object>>{
      ...tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image),
      for (final box in tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      ))
        if (box.decoration case BoxDecoration(image: final image?)) image.image,
    };
    await tester.runAsync(() async {
      await Future.wait([
        for (final provider in providers)
          precacheImage(provider, context).timeout(const Duration(seconds: 15)),
      ]);
    });
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}
