import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_art.dart';
import 'package:ko_lernen_app/widgets/practice_scholar_art.dart';

class _MissingCharacterBundle extends CachingAssetBundle {
  final attemptedImages = <String>[];

  @override
  Future<ByteData> load(String key) {
    if (!key.endsWith('.png')) {
      return rootBundle.load(key);
    }
    attemptedImages.add(key);
    return Future.error(StateError('Missing test character asset: $key'));
  }
}

void main() {
  final cases = [
    (
      name: 'scholar inviting',
      child: const PracticeScholarArt(pose: PracticeScholarPose.inviting),
      attempts: [
        PracticeScholarPose.inviting.asset,
        PracticeScholarPose.calm.asset,
      ],
    ),
    (
      name: 'scholar calm',
      child: const PracticeScholarArt(pose: PracticeScholarPose.calm),
      attempts: [PracticeScholarPose.calm.asset],
    ),
    (
      name: 'Dokkaebi inviting',
      child: const PracticeDokkaebiArt(pose: PracticeDokkaebiPose.inviting),
      attempts: [
        PracticeDokkaebiPose.inviting.asset,
        PracticeDokkaebiPose.ready.asset,
      ],
    ),
    (
      name: 'Dokkaebi ready',
      child: const PracticeDokkaebiArt(pose: PracticeDokkaebiPose.ready),
      attempts: [PracticeDokkaebiPose.ready.asset],
    ),
  ];
  for (final example in cases) {
    testWidgets('${example.name} fails once within its canonical pose set', (
      tester,
    ) async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      final bundle = _MissingCharacterBundle();
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: bundle,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox.square(dimension: 100, child: example.child),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(bundle.attemptedImages, orderedEquals(example.attempts));
      expect(tester.takeException(), isNull);
    });
  }
}
