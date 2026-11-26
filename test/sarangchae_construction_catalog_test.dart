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

  test('bundled sequence retains all R16 processes and the exact final bytes', () async {
    final catalog = await SarangchaeConstruction.load();
    final r16 = jsonDecode(
      File('assets/data/ildu_r16_art_v1.json').readAsStringSync(),
    );
    final native = (r16['buildings'] as List).singleWhere(
      (b) => b['id'] == 'sarangchae',
    );
    final byId = {
      for (final stage in native['stages']) stage['processId']: stage,
    };
    final hashes = <String>{};
    expect(catalog.stages, hasLength(16));
    for (final stage in catalog.stages) {
      final bytes = File(stage.assetPath).readAsBytesSync();
      expect(sha256.convert(bytes).toString(), stage.sha256);
      expect(stage.assetPath, startsWith('assets/illustrations/ildu_r16/'));
      expect(bytes.take(4), [82, 73, 70, 70]);
      hashes.add(stage.sha256);
      expect(stage.sha256, byId['ildu.${stage.stageId}']['sha256']);
    }
    // The adopted R16 choseok and fitting lessons share the same source frame.
    expect(hashes, (native['stages'] as List).map((s) => s['sha256']).toSet());
    expect(catalog.stage(16).sha256, SarangchaeConstruction.canonicalSha256);
    expect(
      catalog.stage(16).text('title', 'fr'),
      catalog.stage(16).text('title', 'en'),
    );
  });

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
