import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

void main() {
  test('preview is the exact approved source', () {
    final bytes = File(kIlDuV3PreviewAsset).readAsBytesSync();
    expect(bytes, hasLength(2127303));
    expect(
      sha256.convert(bytes).toString(),
      'c35e5b89a2f2154a61b07ed0d8e0b02b6d6e7b063825b10b132f02a95f14c0c6',
    );
  });

  testWidgets('shows the whole preview without an interactive affordance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 292.5,
            child: HanokV3Preview(message: '준비 중'),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, kIlDuV3PreviewAsset);
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.center);
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });
}
