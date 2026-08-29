import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';

void main() {
  test(
    'turntable catalog keeps eight authored and bounded frames per building',
    () {
      expect(
        kIlDuTurntables.keys,
        containsAll(<String>['sarangchae', 'ansarang', 'jungmunganchae']),
      );

      for (final spec in kIlDuTurntables.values) {
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
}
