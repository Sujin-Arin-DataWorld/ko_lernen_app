import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _canvasSize = 1024;
const _stampDiameter = 952;
const _outerRadius = _stampDiameter / 2;
const _ringThickness = 57.0;
const _ringRed = (r: 0xC9, g: 0x22, b: 0x17);

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/normalize_stamp_asset.dart <source.png> <output.png>',
    );
    exitCode = 64;
    return;
  }

  final source = img.decodePng(File(arguments[0]).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode ${arguments[0]}');
    exitCode = 65;
    return;
  }

  final bounds = _opaqueBounds(source);
  if (bounds == null) {
    stderr.writeln('Source has no non-transparent pixels: ${arguments[0]}');
    exitCode = 65;
    return;
  }

  final squareSize = math.max(bounds.width, bounds.height);
  final cropX = (bounds.centerX - squareSize / 2).round().clamp(
    0,
    source.width - squareSize,
  );
  final cropY = (bounds.centerY - squareSize / 2).round().clamp(
    0,
    source.height - squareSize,
  );
  final cropped = img.copyCrop(
    source,
    x: cropX,
    y: cropY,
    width: squareSize,
    height: squareSize,
  );
  final resized = img.copyResize(
    cropped,
    width: _stampDiameter,
    height: _stampDiameter,
    interpolation: img.Interpolation.cubic,
  );
  final output = img.Image(
    width: _canvasSize,
    height: _canvasSize,
    numChannels: 4,
  );
  img.compositeImage(
    output,
    resized,
    dstX: (_canvasSize - _stampDiameter) ~/ 2,
    dstY: (_canvasSize - _stampDiameter) ~/ 2,
  );

  _enforceCircleAndRing(output);
  final outputFile = File(arguments[1]);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsBytesSync(img.encodePng(output, level: 9));
  stdout.writeln(
    '${outputFile.path}: ${output.width}x${output.height}, '
    'diameter=$_stampDiameter, ring=${_ringThickness.toInt()}px',
  );
}

void _enforceCircleAndRing(img.Image image) {
  final center = (_canvasSize - 1) / 2;
  final innerRadius = _outerRadius - _ringThickness;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final distance = math.sqrt(
        math.pow(x - center, 2) + math.pow(y - center, 2),
      );
      if (distance >= _outerRadius + 0.5) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      } else if (distance >= innerRadius) {
        final alpha = ((_outerRadius + 0.5 - distance) * 255).round().clamp(
          0,
          255,
        );
        image.setPixelRgba(x, y, _ringRed.r, _ringRed.g, _ringRed.b, alpha);
      } else {
        final pixel = image.getPixel(x, y);
        image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 255);
      }
    }
  }
}

_Bounds? _opaqueBounds(img.Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (final pixel in image) {
    if (pixel.a <= 0) {
      continue;
    }
    minX = math.min(minX, pixel.x);
    minY = math.min(minY, pixel.y);
    maxX = math.max(maxX, pixel.x);
    maxY = math.max(maxY, pixel.y);
  }
  if (maxX < minX || maxY < minY) {
    return null;
  }
  return _Bounds(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
}

class _Bounds {
  const _Bounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
  double get centerX => (minX + maxX) / 2;
  double get centerY => (minY + maxY) / 2;
}
