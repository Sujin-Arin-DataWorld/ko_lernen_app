import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Decode only the pixels needed by BoxFit, preserving the original aspect
/// ratio. A contain-sized decode would blur a wide photo cropped into a square.
class DisplaySizedFileImage extends FileImage {
  const DisplaySizedFileImage(super.file, this.physicalSize, this.fit);

  final Size physicalSize;
  final BoxFit fit;

  @override
  ImageStreamCompleter loadImage(FileImage key, ImageDecoderCallback decode) {
    return super.loadImage(
      key,
      (
        ui.ImmutableBuffer buffer, {
        ui.TargetImageSizeCallback? getTargetSize,
      }) => decode(
        buffer,
        getTargetSize: (width, height) {
          if (!physicalSize.isFinite || physicalSize.isEmpty) {
            return ui.TargetImageSize(width: width, height: height);
          }
          final fitted = applyBoxFit(
            fit,
            Size(width.toDouble(), height.toDouble()),
            physicalSize,
          );
          final scale = math.min(
            1.0,
            math.max(
              fitted.destination.width / fitted.source.width,
              fitted.destination.height / fitted.source.height,
            ),
          );
          return ui.TargetImageSize(
            width: math.max(1, (width * scale).ceil()),
            height: math.max(1, (height * scale).ceil()),
          );
        },
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DisplaySizedFileImage &&
      super == other &&
      physicalSize == other.physicalSize &&
      fit == other.fit;

  @override
  int get hashCode => Object.hash(super.hashCode, physicalSize, fit);
}
