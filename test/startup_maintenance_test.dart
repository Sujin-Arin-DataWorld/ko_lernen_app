import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/main.dart'
    show finishPostMigrationStartup, runPostMigrationStudyLogMaintenance;
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/splash_gate.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/srs_commit_journal.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/srs_recovery_banner.dart';

import 'support/reward_preferences_platform.dart';
import 'srs_process_recovery_test.dart' show journal;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });
  const writable = DataMigrationResult(
    status: DataMigrationStatus.upToDate,
    fromVersion: 1,
    toVersion: 1,
  );
  const readOnly = DataMigrationResult(
    status: DataMigrationStatus.futureVersion,
    fromVersion: 2,
    toVersion: 1,
  );

  test(
    'post-migration maintenance skips pruning without writable migration',
    () async {
      var pruneCalls = 0;
      Future<void> prune() async => pruneCalls++;

      await runPostMigrationStudyLogMaintenance(null, pruneStudyLog: prune);
      await runPostMigrationStudyLogMaintenance(readOnly, pruneStudyLog: prune);

      expect(pruneCalls, 0);
    },
  );

  test(
    'post-migration maintenance runs pruning after a writable migration',
    () async {
      var pruneCalls = 0;

      await runPostMigrationStudyLogMaintenance(
        writable,
        pruneStudyLog: () async => pruneCalls++,
      );

      expect(pruneCalls, 1);
    },
  );

  test(
    'post-migration maintenance reports a prune failure and completes',
    () async {
      final reported = <Object>[];

      await runPostMigrationStudyLogMaintenance(
        writable,
        pruneStudyLog: () async => throw StateError('prune failed'),
        onPruneFailure: reported.add,
      );

      expect(reported, hasLength(1));
      expect(reported.single, isA<StateError>());
    },
  );

  testWidgets(
    'unacknowledged native recovery does not strand independent startup',
    (tester) async {
      final record = journal();
      final release = Completer<void>();
      final native = RewardPreferencesPlatform()
        ..rejectKey = 'kl_srs_v1'
        ..releaseWrite = release
        ..commitBeforeFailure = true;
      native.values.addAll({
        SrsCommitJournal.key: record.encode(),
        record.historyKey: record.beforeHistory!,
      });
      SharedPreferencesStorePlatform.instance = native;
      await Storage.init();
      addTearDown(() {
        if (!release.isCompleted) {
          release.complete();
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => SrsRecoveryBanner(child: child!),
          home: const Scaffold(body: Text('Independent navigation')),
        ),
      );
      final effects = <String>[];
      var ready = false;
      var startupCompleted = false;
      unawaited(SplashGate.ready.then((_) => ready = true));
      unawaited(
        finishPostMigrationStartup(
          writable,
          applyAudioContext: () async => effects.add('audio'),
          initializeManagedMedia: () async => effects.add('media'),
          recoverCrop: () async => effects.add('crop'),
          recoverPicker: () async => effects.add('picker'),
        ).then((_) => startupCompleted = true),
      );

      await tester.pump();
      expect(native.writes['kl_srs_v1'], 1);
      await tester.pump(const Duration(seconds: 6));
      expect(startupCompleted, isTrue);
      expect(effects, ['audio', 'media', 'crop', 'picker']);
      expect(
        ready,
        isTrue,
        reason: 'production audio finally opens SplashGate',
      );
      expect(Storage.srsRecoveryPending, isTrue);
      expect(Storage.srsRecoveryStatus.value, SrsRecoveryStatus.retryRequired);
      final t = AppL10n.of(tester.element(find.byType(SrsRecoveryBanner)));
      await tester.ensureVisible(find.text(t.srsRecoveryRetry));
      await tester.tap(find.text(t.srsRecoveryRetry));
      await tester.pump();
      expect(native.writes['kl_srs_v1'], 1);
      expect(Storage.srsRecoveryPending, isTrue);
      expect(find.text('Independent navigation'), findsOneWidget);

      // Release only for test cleanup, after proving liveness beyond the UI
      // timeout while the production native setter was still unacknowledged.
      release.complete();
      await tester.pump();
      expect(Storage.srsRecoveryPending, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
