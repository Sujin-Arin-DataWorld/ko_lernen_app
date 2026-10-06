import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:ko_lernen_app/models/companion_art.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  test('October 4 canon preserves approved source bytes and alpha', () {
    final manifest =
        jsonDecode(
              File(
                'docs/assets/CANONICAL_COMPANIONS_20261004.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    for (final entry in manifest['files'] as List) {
      final bytes = File(entry['asset'] as String).readAsBytesSync();
      expect(
        sha256.convert(bytes).toString(),
        entry['sha256'],
        reason: entry['asset'] as String,
      );
      if (entry['asset'].endsWith('.png') && entry['role'] != 'poster') {
        final decoded = image.decodePng(bytes)!;
        expect(decoded.numChannels, 4);
        expect(decoded.any((pixel) => pixel.a == 0), isTrue);
      }
    }
    expect(Mascot.kTigerAsset, CompanionArt.taego);
  });
  test('retired PNG family is never called by runtime code', () {
    final offenders = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final code = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      if (code.contains('assets/illustrations/mascot/tiger_') ||
          code.contains('assets/illustrations/mascot/magpie_') ||
          code.contains('assets/illustrations/error/lost_magpie.png') ||
          code.contains('assets/illustrations/onboarding/tiger_crystal.png') ||
          code.contains('assets/illustrations/onboarding/companions/') ||
          code.contains('assets/illustrations/hanok/taego-joy-duo.png')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
