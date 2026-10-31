import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_r16_art.dart';

Map<String, dynamic> source() =>
    jsonDecode(File(IlDuR16ArtCatalog.assetPath).readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test(
    'R16 keeps all eleven buildings and 128 original process identities',
    () {
      final catalog = IlDuR16ArtCatalog.fromJson(source());
      final canonical =
          jsonDecode(
                File(
                  'docs/hanok_r16/APP_ASSET_CONTRACT.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final processIds = <String>{
        for (final building in canonical['buildings'] as List)
          for (final stage in building['stages'] as List)
            stage['processId'] as String,
      };
      expect(catalog.buildings, hasLength(11));
      expect(catalog.stagesByProcessId.keys.toSet(), processIds);
      expect(catalog.stagesByProcessId, hasLength(128));
      expect(
        catalog.buildings.map((b) => b.id),
        IlDuR16ArtCatalog.stageCounts.keys,
      );
      expect(catalog.stagesByProcessId['unknown-process'], isNull);
    },
  );

  test('every referenced image is bundled and has its actual content hash', () {
    final catalog = IlDuR16ArtCatalog.fromJson(source());
    final images = [
      catalog.estate,
      for (final building in catalog.buildings) ...[
        building.full,
        ...building.stages.map((s) => s.image),
      ],
    ];
    for (final image in images) {
      final file = File(image.asset);
      expect(file.existsSync(), isTrue, reason: image.asset);
      expect(sha256.convert(file.readAsBytesSync()).toString(), image.sha256);
    }
    final bundledFiles = Directory('assets/illustrations/ildu_r16')
        .listSync()
        .whereType<File>()
        .map((file) => file.path.replaceAll('\\', '/'))
        .toSet();
    expect(bundledFiles, images.map((image) => image.asset).toSet());
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/illustrations/ildu_r16/'),
    );
  });

  test(
    'construction uses complete standalone roofs for Sarangchae and Jung',
    () {
      final data = source();
      for (final building in data['buildings'] as List) {
        final standalone = const {
          'sarangchae',
          'jungmunganchae',
        }.contains(building['id']);
        for (final stage in building['stages'] as List) {
          expect(stage['roofVariant'], standalone ? 'standalone' : 'original');
        }
      }
      final malformed = source();
      (malformed['buildings'] as List).first['stages'][10]['roofVariant'] =
          'connected';
      expect(
        () => IlDuR16ArtCatalog.fromJson(malformed),
        throwsFormatException,
      );
    },
  );

  test(
    'rejects duplicate identities, missing stages and changed story order',
    () {
      final duplicate = source();
      final stages = (duplicate['buildings'] as List).first['stages'] as List;
      stages[1]['processId'] = stages[0]['processId'];
      expect(
        () => IlDuR16ArtCatalog.fromJson(duplicate),
        throwsFormatException,
      );
      final missing = source();
      ((missing['buildings'] as List).first['stages'] as List).removeLast();
      expect(() => IlDuR16ArtCatalog.fromJson(missing), throwsFormatException);
      final reordered = source();
      final buildings = reordered['buildings'] as List;
      final first = buildings[0];
      buildings[0] = buildings[1];
      buildings[1] = first;
      expect(
        () => IlDuR16ArtCatalog.fromJson(reordered),
        throwsFormatException,
      );
    },
  );

  test(
    'rejects path escape and any attempt to turn artwork into ownership',
    () {
      final escaped = source();
      (escaped['estate'] as Map)['asset'] = '../private.png';
      expect(() => IlDuR16ArtCatalog.fromJson(escaped), throwsFormatException);
      final migration = source();
      migration['progressOrOwnershipMigrationIncluded'] = true;
      expect(
        () => IlDuR16ArtCatalog.fromJson(migration),
        throwsFormatException,
      );
    },
  );
}
