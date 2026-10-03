import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'dancheong_renderer.dart';

enum DancheongShareOutcome { handedOff, dismissed, unavailable, failed }

DancheongShareOutcome mapDancheongShareStatus(ShareResultStatus status) =>
    switch (status) {
      ShareResultStatus.success => DancheongShareOutcome.handedOff,
      ShareResultStatus.dismissed => DancheongShareOutcome.dismissed,
      ShareResultStatus.unavailable => DancheongShareOutcome.unavailable,
    };

final class DancheongShareService {
  Future<DancheongShareOutcome> shareImage(
    DancheongExportPackage package, {
    required Rect sharePositionOrigin,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              package.png,
              mimeType: 'image/png',
              name:
                  'hangul-sori-dancheong-${package.artworkId}-${package.revision}-${package.format.name}.png',
            ),
          ],
          sharePositionOrigin: sharePositionOrigin,
          downloadFallbackEnabled: true,
        ),
      );
      return mapDancheongShareStatus(result.status);
    } catch (_) {
      return DancheongShareOutcome.failed;
    }
  }

  Future<void> saveImage(DancheongExportPackage package) async {
    if (!kIsWeb) {
      throw UnsupportedError(
        'Use the native share sheet to save the original image.',
      );
    }
    await XFile.fromData(
      package.png,
      mimeType: 'image/png',
      name:
          'hangul-sori-dancheong-${package.artworkId}-${package.revision}-${package.format.name}.png',
    ).saveTo(
      'hangul-sori-dancheong-${package.artworkId}-${package.revision}-${package.format.name}.png',
    );
  }
}
