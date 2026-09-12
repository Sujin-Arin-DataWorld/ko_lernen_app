import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retired personal Hanok V1 presentation cannot return', () {
    const roots = ['lib', 'test', 'tool', '.github'];
    const forbiddenEverywhere = [
      'assets/illustrations/personal_hanok_'
          'v2/',
      'assets/illustrations/hanok_'
          'stages/',
      'Hanok'
          'WorldScreen',
      'PersonalHanok'
          'Map',
      'HanokStage'
          'Service',
    ];
    const legacyImportAllowlist = {
      'lib/services/legacy_hanok_v1_importer.dart',
      'lib/services/data_migration_service.dart',
      'lib/services/cloud_sync.dart',
      'lib/services/account/account_reconciliation.dart',
      'test/legacy_hanok_v1_importer_test.dart',
      'test/data_migration_test.dart',
      'test/hanok_cloud_sync_test.dart',
      'test/hanok_account_reconciliation_test.dart',
    };
    const legacyImportTokens = [
      'kl_hanok_'
          'state_v1',
      'kl_hanok_'
          'cutover_v2',
      'kl_hanok_'
          'stages_seen_v1',
      'kl_personal_hanok_'
          'milestones_seen_v1',
      'hanok_'
          'state_json',
    ];

    final failures = <String>[];
    for (final root in roots) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File ||
            !RegExp(r'\.(dart|py|ya?ml)$').hasMatch(entity.path)) {
          continue;
        }
        final path = entity.path.replaceAll('\\', '/');
        if (path == 'test/hanok_v1_retirement_guard_test.dart') {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final token in forbiddenEverywhere) {
          if (source.contains(token)) failures.add('$path: $token');
        }
        if (!legacyImportAllowlist.contains(path)) {
          for (final token in legacyImportTokens) {
            if (source.contains(token)) {
              failures.add('$path: legacy state outside importer boundary');
            }
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
