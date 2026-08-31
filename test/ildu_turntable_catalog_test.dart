import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';

void main() {
  test(
    'turntable catalog keeps eight authored and bounded frames per anchor',
    () {
      expect(
        kIlDuTurntables.keys,
        containsAll(<String>[
          'sarangchae',
          'ansarang',
          'changgo',
          'anchae',
          'anchae-store',
          'gokgan',
          'toilet-north',
          'toilet-south',
          'main-gate',
          'araechae',
          'jungmunganchae',
          'sadang',
          'sadang-gate',
          'hyeopmun-west',
          'hyeopmun-east',
        ]),
      );

      for (final entry in kIlDuTurntables.entries) {
        final spec = entry.value;
        expect(spec.anchorId, entry.key);
        expect(spec.frames, hasLength(8));
        expect(
          spec.frames.map((frame) => frame.assetPath).toSet(),
          hasLength(8),
        );
        for (final frame in spec.frames) {
          expect(
            File(frame.assetPath).existsSync(),
            isTrue,
            reason: frame.assetPath,
          );
          expect(frame.contentBounds.left, greaterThanOrEqualTo(0));
          expect(frame.contentBounds.top, greaterThanOrEqualTo(0));
          expect(
            frame.contentBounds.right,
            lessThanOrEqualTo(frame.sourceSize.width),
          );
          expect(
            frame.contentBounds.bottom,
            lessThanOrEqualTo(frame.sourceSize.height),
          );
          expect(frame.contentBounds.width, greaterThan(0));
          expect(frame.contentBounds.height, greaterThan(0));
          expect(frame.displayBounds.left, greaterThanOrEqualTo(0));
          expect(frame.displayBounds.top, greaterThanOrEqualTo(0));
          expect(
            frame.displayBounds.right,
            lessThanOrEqualTo(frame.sourceSize.width),
          );
          expect(
            frame.displayBounds.bottom,
            lessThanOrEqualTo(frame.sourceSize.height),
          );
          expect(
            frame.displayBounds.left,
            lessThanOrEqualTo(frame.contentBounds.left),
          );
          expect(
            frame.displayBounds.top,
            lessThanOrEqualTo(frame.contentBounds.top),
          );
          expect(
            frame.displayBounds.right,
            greaterThanOrEqualTo(frame.contentBounds.right),
          );
          expect(
            frame.displayBounds.bottom,
            greaterThanOrEqualTo(frame.contentBounds.bottom),
          );

          final image = img.decodePng(File(frame.assetPath).readAsBytesSync());
          expect(image, isNotNull, reason: frame.assetPath);
          expect(image!.width, frame.sourceSize.width);
          expect(image.height, frame.sourceSize.height);
          expect(
            _alphaBounds(image),
            frame.contentBounds,
            reason: '${frame.assetPath} alpha bounds drifted',
          );
          expect(frame.contentBounds.left, greaterThan(0));
          expect(frame.contentBounds.top, greaterThan(0));
          expect(frame.contentBounds.right, lessThan(frame.sourceSize.width));
          expect(frame.contentBounds.bottom, lessThan(frame.sourceSize.height));
        }
      }
    },
  );

  test('manifest degrees select the matching 45 degree frame', () {
    final spec = kIlDuSarangchaeTurntable;
    for (var direction = 0; direction < 8; direction++) {
      expect(spec.directionForDegrees(direction * 45), direction);
    }
    expect(spec.directionForDegrees(360), 0);
    expect(spec.directionForDegrees(-45), 7);
    expect(kIlDuChanggoTurntable.directionForDegrees(90), 2);
    expect(kIlDuSotdaeulmunTurntable.directionForDegrees(3), 0);
    expect(kIlDuAnchaeTurntable.directionForDegrees(90), 2);
    expect(kIlDuAraechaeTurntable.directionForDegrees(315), 7);
    expect(kIlDuSadangTurntable.directionForDegrees(90), 2);
    expect(kIlDuSadangmunTurntable.directionForDegrees(315), 7);
    expect(kIlDuAnchaeStoreTurntable.directionForDegrees(90), 2);
    expect(kIlDuGokganTurntable.directionForDegrees(315), 7);
    expect(kIlDuToiletNorthTurntable.directionForDegrees(180), 4);
  });

  test('Araechae preserves one authored canvas, viewport, and ground line', () {
    const expectedViewport = Rect.fromLTRB(448, 274, 2111, 1259);
    expect(
      kIlDuAraechaeTurntable.frames.map((frame) => frame.sourceSize).toSet(),
      <Size>{const Size(2560, 1440)},
    );
    expect(
      kIlDuAraechaeTurntable.frames.map((frame) => frame.displayBounds).toSet(),
      <Rect>{expectedViewport},
    );
    expect(
      kIlDuAraechaeTurntable.frames
          .map((frame) => frame.contentBounds.bottom)
          .toSet(),
      <double>{1259},
    );
  });

  test('Araechae runtime frames are exact copies of the review masters', () {
    const reviewRoot =
        'assets_unused/pending_review/personal_hanok_v3/'
        'changgo_turnaround_v1/';
    for (final frame in kIlDuAraechaeTurntable.frames) {
      final runtime = File(frame.assetPath);
      final reviewName = runtime.uri.pathSegments.last.replaceFirst(
        'ildu_',
        '',
      );
      final review = File('$reviewRoot$reviewName');
      expect(review.existsSync(), isTrue, reason: review.path);
      expect(
        sha256.convert(runtime.readAsBytesSync()),
        sha256.convert(review.readAsBytesSync()),
        reason: '${runtime.path} must remain byte-identical to ${review.path}',
      );
    }
  });

  test('the two manifest hyeopmun anchors reuse the approved shared kit', () {
    expect(
      kIlDuHyeopmunWestTurntable.frames.map((frame) => frame.assetPath),
      orderedEquals(
        kIlDuHyeopmunEastTurntable.frames.map((frame) => frame.assetPath),
      ),
    );
  });

  test('the two toilet placements reuse one source-faithful shared kit', () {
    expect(
      kIlDuToiletNorthTurntable.frames.map((frame) => frame.assetPath),
      orderedEquals(
        kIlDuToiletSouthTurntable.frames.map((frame) => frame.assetPath),
      ),
    );
  });

  test('Jin-approved Jungmunganchae V05 keeps transparent RGBA canvases', () {
    for (final frame in kIlDuJungmunganchaeTurntable.frames) {
      final image = img.decodePng(File(frame.assetPath).readAsBytesSync());
      expect(image, isNotNull, reason: frame.assetPath);
      expect(image!.numChannels, 4, reason: '${frame.assetPath} is not RGBA');

      for (final point in <(int, int)>[
        (0, 0),
        (image.width - 1, 0),
        (0, image.height - 1),
        (image.width - 1, image.height - 1),
      ]) {
        expect(
          image.getPixel(point.$1, point.$2).a,
          0,
          reason: '${frame.assetPath} has an opaque canvas corner',
        );
      }

      var transparentPixels = 0;
      var opaquePixels = 0;
      var partialAlphaPixels = 0;
      for (final pixel in image) {
        if (pixel.a == 0) {
          transparentPixels++;
        } else if (pixel.a == 255) {
          opaquePixels++;
        } else {
          partialAlphaPixels++;
        }
      }
      expect(transparentPixels, greaterThan(0), reason: frame.assetPath);
      expect(opaquePixels, greaterThan(0), reason: frame.assetPath);
      expect(
        partialAlphaPixels,
        0,
        reason: '${frame.assetPath} alpha contract drifted',
      );
    }
  });

  test('Jin-approved Jungmunganchae V05 runtime bytes stay locked', () async {
    const expectedHashes = <String>[
      'BC7021EF7BA05F5C21746626E1B3DDEC2E82609DB40D55171C65860256D17909',
      '386B0D951D5264F83F7A304F58ED7382F42C952DEFFAEB9199979D5470EFE1A8',
      '14C5704C581487D7A4230922065964A1742FE909A0BC28455BFB1CD42FBBC51F',
      '81156FADE5C8905CA2978B16C71E1C98D99FE9775B6B0EACCF0C243677E75DF9',
      '025E66CB5A7139CF7C5E26F09DAB845A6AFB546999677A2AD75F3A790EDD48E7',
      '3821497538DCC8FDB13C54121FEB09F952ACE8EBAE34C073DFBCEF812FB29611',
      'B19BF5169FA449AF885938938EC6FC113CEEAC81559095190FE8905EF55DD0AE',
      '174C41FC54D5D40C4D094FF2006AC7A8F6B5F9EB128612317CAE61E723D710BC',
    ];

    for (var index = 0; index < expectedHashes.length; index++) {
      final frame = kIlDuJungmunganchaeTurntable.frames[index];
      final digest = sha256.convert(await File(frame.assetPath).readAsBytes());
      expect(
        digest.toString().toUpperCase(),
        expectedHashes[index],
        reason: 'approved V05 direction $index changed',
      );
    }
  });

  test('Jin-approved Sotdaeulmun V08 runtime bytes stay locked', () async {
    const expectedHashes = <String>[
      '6E295FBE18502FFD38521C7DD0DC7688EB46B79A8E5B28B7C06C19482B254B2A',
      '44A3F480A203547A002818D395A36D5385A93E42D1A816E231A3CB7240A8D346',
      '30A62E2903B4F994267B5B997A1459E5083501676E8A0AE382C027B97A193BF3',
      '38A1D06D5869E9F7EA25C5DF6891184B1FFC382D4222C646E10A4A626CB33B16',
      'CDCDD6ADB00C22115128EDB10F78066E1B37CE5DF75BF4994B6F92875DACD71E',
      'AA64DA5B940F27E932CFE336A2A5755D744B3B540457A03198993DF5D882075E',
      '842D2D6BE0BBE1F525E6F5CDB6CFBB49539394A57BBE9D68BF16AF31B137F8B1',
      '5AB57C104B54A4F70B06048B4A61DBF7E7C7E65631B057211ADD7761C6697C30',
    ];
    const revisionRoot =
        'assets_unused/pending_review/personal_hanok_v3/turnaround_2d/'
        'ildu_sotdaeulmun_v02/revisions/'
        'ildu_sotdaeulmun_v08_depth_150_runtime/transparent_views';

    for (var index = 0; index < expectedHashes.length; index++) {
      final frame = kIlDuSotdaeulmunTurntable.frames[index];
      final runtime = File(frame.assetPath);
      final digest = sha256.convert(await runtime.readAsBytes());
      expect(
        digest.toString().toUpperCase(),
        expectedHashes[index],
        reason: 'approved Sotdaeulmun V08 direction $index changed',
      );

      final revision = File('$revisionRoot/${runtime.uri.pathSegments.last}');
      expect(revision.existsSync(), isTrue, reason: revision.path);
      expect(
        sha256.convert(await revision.readAsBytes()),
        digest,
        reason: '${runtime.path} must match the approved V08 revision',
      );
    }
  });
}

Rect _alphaBounds(img.Image image) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a == 0) {
        continue;
      }
      if (x < left) {
        left = x;
      }
      if (y < top) {
        top = y;
      }
      if (x > right) {
        right = x;
      }
      if (y > bottom) {
        bottom = y;
      }
    }
  }
  if (right < left || bottom < top) {
    return Rect.zero;
  }
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    (right + 1).toDouble(),
    (bottom + 1).toDouble(),
  );
}
