import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'new learning-data keys are registered in the cloud backup allowlist',
    () {
      const requiredPayloadKeys = <String>['study_log_json', 'gram_plan_json'];
      final cloudSyncSource = File(
        'lib/services/cloud_sync.dart',
      ).readAsStringSync();
      final exportSource = File(
        'lib/services/learning_data_export_service.dart',
      ).readAsStringSync();

      for (final key in requiredPayloadKeys) {
        expect(
          cloudSyncSource.contains("'$key'"),
          isTrue,
          reason: '$key is missing from the cloud-sync payload/allowlist',
        );
      }
      expect(
        cloudSyncSource.contains('Storage.studyLogDates'),
        isTrue,
        reason: 'the daily SRS ledger is not read by the cloud-backup path',
      );
      expect(
        cloudSyncSource.contains('Storage.grammarPlanRawJson'),
        isTrue,
        reason: 'the grammar plan is not read by the cloud-backup path',
      );
      expect(
        exportSource.contains('studyLog') &&
            exportSource.contains('grammarPlan'),
        isTrue,
        reason: 'the learning ledger/plan is absent from the data exporter',
      );
    },
  );
}
