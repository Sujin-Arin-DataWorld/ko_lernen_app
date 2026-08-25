import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../tool/build_stamp_contact_sheets.dart';

void main() {
  final sources = loadStampContactSheetSources();

  test('25종의 62dp·96dp 접촉표가 승인 골든과 일치한다', () {
    expect(sources, isNotNull);
    final actual = buildStampContactSheet(sources!);
    final golden = _decodeGolden(
      'docs/review/stamps/stamp_contact_sheet_62_96.png',
    );

    _expectExactPixels(actual, golden);
  });

  test('25종의 이름 없는 실루엣표가 승인 골든과 일치한다', () {
    expect(sources, isNotNull);
    final actual = buildStampSilhouetteSheet(sources!);
    final golden = _decodeGolden('docs/review/stamps/stamp_silhouette_25.png');

    _expectExactPixels(actual, golden);
  });
}

img.Image _decodeGolden(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '골든 기준 이미지가 없습니다: $path');
  final decoded = img.decodePng(file.readAsBytesSync());
  expect(decoded, isNotNull, reason: '골든 이미지를 디코드할 수 없습니다: $path');
  return decoded!;
}

void _expectExactPixels(img.Image actual, img.Image golden) {
  expect(actual.width, golden.width);
  expect(actual.height, golden.height);
  expect(
    actual.getBytes(order: img.ChannelOrder.rgba),
    orderedEquals(golden.getBytes(order: img.ChannelOrder.rgba)),
  );
}
