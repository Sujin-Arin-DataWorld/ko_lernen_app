import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';

void main() {
  const anchor = IlDuWorldGate(
    id: 'main-gate',
    ko: '솟을대문',
    asset: 'main-gate.png',
    x: 20,
    y: 30,
    width: 12,
    rotation: 0,
    unlockEra: IlDuWorldEra.b1,
  );

  test(
    'legacy placements retain their coordinates without presentation data',
    () {
      final presentation = IlDuMapPresentation.fromJson(null);
      expect(presentation.anchorX(anchor, 24, 35), 24);
      expect(presentation.anchorY(anchor, 24, 35), 35);
      expect(presentation.anchorWidth(anchor), 12);
      expect(presentation.logicalDeltaX(3, -2), 3);
      expect(presentation.logicalDeltaY(3, -2), -2);
    },
  );

  test(
    'R16 camera projection preserves saved drag distances through inversion',
    () {
      final presentation = IlDuMapPresentation.fromJson({
        'matrix': [.8, .1, 2, -.2, .6, 10],
        'anchors': {
          'main-gate': {'x': 50, 'y': 60, 'width': 9},
        },
      });
      final beforeX = presentation.anchorX(anchor, 20, 30);
      final beforeY = presentation.anchorY(anchor, 20, 30);
      final afterX = presentation.anchorX(anchor, 25, 28);
      final afterY = presentation.anchorY(anchor, 25, 28);
      expect(beforeX, 50);
      expect(beforeY, 60);
      expect(
        presentation.logicalDeltaX(afterX - beforeX, afterY - beforeY),
        closeTo(5, 1e-9),
      );
      expect(
        presentation.logicalDeltaY(afterX - beforeX, afterY - beforeY),
        closeTo(-2, 1e-9),
      );
      expect(presentation.anchorWidth(anchor), 9);
    },
  );

  test('decorations keep their yard-relative saved positions', () {
    final presentation = IlDuMapPresentation.fromJson({
      'matrix': [.8, .1, 2, -.2, .6, 10],
      'anchors': <String, dynamic>{},
      'yardOffsets': {
        'sarang-yard': {'dx': 3, 'dy': -5},
      },
    });
    expect(presentation.decorationX('sarang-yard', 20, 30), closeTo(24, 1e-9));
    expect(presentation.decorationY('sarang-yard', 20, 30), closeTo(19, 1e-9));
    expect(presentation.decorationX('other-yard', 20, 30), closeTo(21, 1e-9));
  });

  test('rejects a camera transform that cannot invert user gestures', () {
    expect(
      () => IlDuMapPresentation.fromJson({
        'matrix': [1, 2, 0, 2, 4, 0],
        'anchors': <String, dynamic>{},
      }),
      throwsFormatException,
    );
  });
}
