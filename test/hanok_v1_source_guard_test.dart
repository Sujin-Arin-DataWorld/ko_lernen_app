import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new personal-Hanok authority has no legacy or community inputs', () {
    const paths = <String>[
      'lib/models/hanok_growth.dart',
      'lib/services/hanok_grant_catalog.dart',
      'lib/services/hanok_experience_projector.dart',
      'lib/services/hanok_state_service.dart',
    ];
    const forbidden = <String>[
      'PackProgressService',
      'VocabPackService',
      'LevelRatios',
      'HanokStage',
      'GyeService',
      "models/gye",
      "services/gye",
      'questCompletions',
      'ownedDecor',
      'earnedStamps',
      'Storage.xp',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      for (final symbol in forbidden) {
        expect(
          source,
          isNot(contains(symbol)),
          reason: '$path must not depend on $symbol',
        );
      }
    }
  });

  test('unapproved Hanok grants stay outside the Flutter asset bundle', () {
    expect(File('assets/data/hanok_grants.json').existsSync(), isFalse);
    expect(
      File('tools/content_factory/drafts/hanok_grants.json').existsSync(),
      isTrue,
    );
    final productionCatalog = File(
      'lib/services/hanok_grant_catalog.dart',
    ).readAsStringSync();
    expect(productionCatalog, isNot(contains('rootBundle')));
    expect(productionCatalog, isNot(contains('AssetBundle')));
    expect(productionCatalog, isNot(contains('assets/data/hanok_grants.json')));
  });
}
