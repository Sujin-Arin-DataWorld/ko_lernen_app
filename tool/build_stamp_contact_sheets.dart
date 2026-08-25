import 'dart:io';

import 'package:image/image.dart' as img;

const stampContactSheetSlugs = <String>[
  'lotus',
  'chrysanthemum',
  'plum',
  'bamboo',
  'cloud',
  'octagon',
  'mountain',
  'manja',
  'vine',
  'chilbo',
  'gwigap',
  'wave',
  'taegeuk',
  'peony',
  'changsal',
  'suryeon',
  'noemun',
  'mugunghwa',
  'moran',
  'munbangsau',
  'bok',
  'crane',
  'wadang',
  'yeopjeon',
  'soban',
];

void main() {
  final sources = loadStampContactSheetSources();
  if (sources == null) {
    exitCode = 65;
    return;
  }

  final outputDir = Directory('docs/review/stamps')
    ..createSync(recursive: true);
  _writeImage(
    buildStampContactSheet(sources),
    '${outputDir.path}/stamp_contact_sheet_62_96.png',
  );
  _writeImage(
    buildStampSilhouetteSheet(sources),
    '${outputDir.path}/stamp_silhouette_25.png',
  );
}

Map<String, img.Image>? loadStampContactSheetSources() {
  final sources = <String, img.Image>{};
  for (final slug in stampContactSheetSlugs) {
    final path = 'assets/illustrations/stamps/stamp_$slug.png';
    final decoded = img.decodePng(File(path).readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('Could not decode $path');
      return null;
    }
    sources[slug] = decoded;
  }
  return sources;
}

img.Image buildStampContactSheet(Map<String, img.Image> sources) {
  const columns = 5;
  const cellWidth = 240;
  const cellHeight = 160;
  final sheet = img.Image(
    width: columns * cellWidth,
    height: (stampContactSheetSlugs.length / columns).ceil() * cellHeight,
    numChannels: 4,
  );
  img.fill(sheet, color: img.ColorRgba8(250, 246, 236, 255));
  for (var index = 0; index < stampContactSheetSlugs.length; index++) {
    final slug = stampContactSheetSlugs[index];
    final left = (index % columns) * cellWidth;
    final top = (index ~/ columns) * cellHeight;
    final large = img.copyResize(sources[slug]!, width: 96, height: 96);
    final small = img.copyResize(sources[slug]!, width: 62, height: 62);
    img.compositeImage(sheet, large, dstX: left + 22, dstY: top + 12);
    img.compositeImage(sheet, small, dstX: left + 148, dstY: top + 29);
    img.drawString(
      sheet,
      slug,
      font: img.arial14,
      x: left + 12,
      y: top + 126,
      color: img.ColorRgba8(45, 38, 28, 255),
    );
  }
  return sheet;
}

img.Image buildStampSilhouetteSheet(Map<String, img.Image> sources) {
  const columns = 5;
  const cell = 148;
  final sheet = img.Image(
    width: columns * cell,
    height: (stampContactSheetSlugs.length / columns).ceil() * cell,
    numChannels: 4,
  );
  img.fill(sheet, color: img.ColorRgba8(255, 255, 255, 255));
  for (var index = 0; index < stampContactSheetSlugs.length; index++) {
    final motif = _motifSilhouette(sources[stampContactSheetSlugs[index]]!);
    final preview = img.copyResize(motif, width: 112, height: 112);
    final left = (index % columns) * cell + 18;
    final top = (index ~/ columns) * cell + 18;
    img.compositeImage(sheet, preview, dstX: left, dstY: top);
  }
  return sheet;
}

void _writeImage(img.Image image, String path) {
  File(path).writeAsBytesSync(img.encodePng(image, level: 9));
  stdout.writeln('$path (${image.width}x${image.height})');
}

img.Image _motifSilhouette(img.Image source) {
  final output = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  final center = (source.width - 1) / 2;
  for (final pixel in source) {
    final dx = pixel.x - center;
    final dy = pixel.y - center;
    final distanceSquared = dx * dx + dy * dy;
    if (pixel.a < 200 || distanceSquared > 419 * 419) {
      continue;
    }
    final maxChannel = [
      pixel.r,
      pixel.g,
      pixel.b,
    ].reduce((a, b) => a > b ? a : b);
    final minChannel = [
      pixel.r,
      pixel.g,
      pixel.b,
    ].reduce((a, b) => a < b ? a : b);
    final saturation = maxChannel - minChannel;
    final looksLikeCream = pixel.r > 185 && pixel.g > 170 && pixel.b > 140;
    if (!looksLikeCream && saturation > 18) {
      output.setPixelRgba(pixel.x, pixel.y, 28, 28, 28, 255);
    }
  }
  return output;
}
