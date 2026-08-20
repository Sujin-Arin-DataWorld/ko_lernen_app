import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  testWidgets('new tiger poses are reachable through the public emotion API', (
    tester,
  ) async {
    const expected = <MascotEmotion, String>{
      MascotEmotion.neutral: 'assets/illustrations/mascot/tiger_front.png',
      MascotEmotion.smile: 'assets/illustrations/mascot/taego_joy.png',
      MascotEmotion.worry: 'assets/illustrations/mascot/tiger_right.png',
      MascotEmotion.celebrate: 'assets/illustrations/mascot/tiger_joy_hi.png',
      MascotEmotion.sleepy: 'assets/illustrations/mascot/tiger_sit.png',
      MascotEmotion.thinking: 'assets/illustrations/mascot/tiger_sit.png',
    };

    for (final entry in expected.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Mascot.tiger(emotion: entry.key, size: 96)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, entry.value);
    }
  });
}
