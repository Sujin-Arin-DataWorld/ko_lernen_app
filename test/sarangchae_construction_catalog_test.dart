import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> source() =>
      jsonDecode(File(SarangchaeConstruction.assetPath).readAsStringSync())
          as Map<String, dynamic>;

  test(
    'bundled sequence retains every approved PNG and exact final bytes',
    () async {
      final catalog = await SarangchaeConstruction.load();
      final hashes = <String>{};
      expect(catalog.stages, hasLength(16));
      for (final stage in catalog.stages) {
        final bytes = File(stage.assetPath).readAsBytesSync();
        expect(sha256.convert(bytes).toString(), stage.sha256);
        expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        hashes.add(stage.sha256);
      }
      expect(hashes, hasLength(16));
      expect(catalog.stage(16).sha256, SarangchaeConstruction.canonicalSha256);
      expect(
        catalog.stage(16).text('title', 'fr'),
        catalog.stage(16).text('title', 'en'),
      );
    },
  );

  test('rejects a reordered or shortened sequence', () {
    final reordered = source();
    (reordered['stages'] as List).first['sequence'] = 2;
    expect(
      () => SarangchaeConstruction.fromJson(reordered),
      throwsFormatException,
    );
    final shortened = source();
    (shortened['stages'] as List).removeLast();
    expect(
      () => SarangchaeConstruction.fromJson(shortened),
      throwsFormatException,
    );
  });

  test('rejects replacement of the approved completed building', () {
    final changed = source();
    (changed['stages'] as List).last['sha256'] = 'unapproved';
    expect(
      () => SarangchaeConstruction.fromJson(changed),
      throwsFormatException,
    );
  });

  test(
    'each construction lesson stands alone in Korean, English and German',
    () {
      final catalog = SarangchaeConstruction.fromJson(source());
      for (final stage in catalog.stages) {
        for (final language in ['ko', 'en', 'de']) {
          for (final field in [
            'title',
            'question',
            'body',
            'caption',
            'gloss',
            'chapter',
          ]) {
            expect(stage.text(field, language).trim(), isNotEmpty);
          }
        }
      }
      final missing = source();
      (missing['stages'] as List).first['body']['de'] = '';
      expect(
        () => SarangchaeConstruction.fromJson(missing),
        throwsFormatException,
      );
    },
  );
}
