import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  // 2026-08-18 (Phase 2-4): 하드코딩 17개 목록 대신 kAvailableDecorations 전체를
  // 훑는다 — decoration_slot_test.dart:169-191(디스크 ↔ 화이트리스트 양방향 검사)와
  // 같은 이유다. 목록이 손으로 관리되면 새 장식을 추가한 사람이 "여기에도 추가"를
  // 잊는 순간 그 파일은 알파 검사를 영영 못 받는다 — 화이트리스트 자체를 순회하면
  // 그 실수 자체가 구조적으로 불가능해진다.
  test('free-placement decorations have genuine transparent pixels', () async {
    for (final name in kAvailableDecorations.map((slug) => '$slug.png')) {
      final file = File('assets/illustrations/decorations/$name');
      expect(file.existsSync(), isTrue, reason: name);
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(pixels, isNotNull, reason: '$name must decode as RGBA');
      final bytes = pixels!.buffer.asUint8List();
      expect(
        Iterable<int>.generate(
          frame.image.width * frame.image.height,
          (index) => bytes[(index * 4) + 3],
        ).any((alpha) => alpha < 255),
        isTrue,
        reason: '$name still has a baked-in opaque background',
      );
      frame.image.dispose();
      codec.dispose();
    }
  });
}
