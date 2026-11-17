import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/scenario_corpus_generation.dart';
import 'package:ko_lernen_app/services/account/account_switch_resolution.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/account_switch_resolution_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final legacyKey in [false, true]) {
    test(
      'pure preview blocks retained older-generation proof without migration legacyKey=$legacyKey',
      () async {
        Storage.resetForTesting();
        Storage.resetCourseMasteryForTesting();
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        final catalog = await CurriculumCatalog.load();
        expect(
          catalog.scenarioCorpusGeneration,
          isNot(ScenarioCorpusGeneration.legacy),
        );
        final service = CourseMasteryService(catalog);
        final remoteCourse = await service.initializeForPlacement('a2');
        final rootUnit = catalog.courseUnits.firstWhere(
          (unit) => unit.level.toLowerCase() == 'a1',
        );
        final original = CourseMasterySnapshot(
          curriculumGeneration: ScenarioCorpusGeneration.legacy,
          placementLevel: 'a1',
          completedUnitIds: [rootUnit.id],
          scenarioCheckpoints: [
            ScenarioCheckpointEvidence(
              id: 'retained-before-catalog-transition',
              scenarioId: catalog.scenarioContexts.first.scenarioId,
              courseUnitId: rootUnit.id,
              score: .8,
              occurredAt: DateTime.utc(2026, 9, 20),
              courseEligible: false,
            ),
          ],
        );
        final raw = jsonEncode(original.toJson());
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(Storage.courseMasterySnapshotPreferenceKey);
        await preferences.remove(Storage.legacyCourseMasteryPreferenceKey);
        final key = legacyKey
            ? Storage.legacyCourseMasteryPreferenceKey
            : Storage.courseMasterySnapshotPreferenceKey;
        await preferences.setString(key, raw);
        Storage.resetCourseMasteryForTesting();
        final before = {
          for (final key in preferences.getKeys()) key: preferences.get(key),
        };
        final h = ResolutionHarness(
          candidateBuilder: ({required inputs, required side}) {
            final selected = side == AccountSwitchResolutionSide.device
                ? inputs.device.courseMastery!.placementLevel!
                : inputs.cloud.courseMastery!.placementLevel!;
            return AccountReconciliationMerger.merge(
              local: inputs.device,
              remote: inputs.cloud,
              catalog: {},
              courseMasteryMerger: ({required local, required remote}) =>
                  service.mergeForConfirmedPlacement(
                    local: local!,
                    remote: remote!,
                    selectedPlacementLevel: selected,
                  ),
            ).merged;
          },
        );
        h.cloud = AccountReconciliationSnapshot(
          fields: {},
          srsCards: {},
          customPacks: {},
          packProgress: {},
          courseMastery: remoteCourse,
        );
        h.beforeRead = () async {
          h.device = await LocalAccountReconciliationStore.load(
            readOnlyCourse: service,
          );
        };
        final result = await h.coordinator.previewPendingSwitchResolution();
        await preferences.reload();
        expect(preferences.getString(key), raw);
        expect({
          for (final key in preferences.getKeys()) key: preferences.get(key),
        }, before);
        expect(
          h.transitions.writes + h.switches.writes + h.reconciles + h.backfills,
          0,
        );
        expect(
          result.status,
          AccountSwitchResolutionPreviewStatus.blocked,
          reason:
              'Current-generation candidates must not be built by dropping stored completion/checkpoint proof.',
        );
        expect(result.preview, isNull);
        Storage.resetForTesting();
        Storage.resetCourseMasteryForTesting();
      },
    );
  }
  test(
    'production preview capture does not migrate scalar course input or write preferences',
    () async {
      Storage.resetForTesting();
      Storage.resetCourseMasteryForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      await Storage.setDedicatedCoursePlacementLevelCode('a1');
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final snapshot = await LocalAccountReconciliationStore.load(
        readOnlyCourse: CourseMasteryService(await CurriculumCatalog.load()),
      );
      expect(snapshot.courseMastery?.placementLevel, 'a1');
      expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      await prefs.reload();
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      Storage.resetForTesting();
      Storage.resetCourseMasteryForTesting();
    },
  );
  test(
    'preview and cancellation retain all journals and perform zero writes',
    () async {
      final h = ResolutionHarness();
      final rawBefore = h.transitions.raw;
      final sessionBefore = h.sessions.current;
      final result = await h.coordinator.previewPendingSwitchResolution();
      expect(result.status, AccountSwitchResolutionPreviewStatus.ready);
      expect(result.preview!.devicePlacementLevel, 'a1');
      expect(result.preview!.cloudPlacementLevel, 'a2');
      expect(result.preview!.deviceCompletedUnitCount, 0);
      expect(result.preview!.cloudCompletedUnitCount, 0);
      expect(result.preview!.canChooseDevice, isTrue);
      expect(result.preview!.canChooseCloud, isTrue);
      // Closing the UI simply discards the capability; no cancel mutation exists.
      expect(h.transitions.raw, rawBefore);
      expect(h.sessions.current, sessionBefore);
      expect(h.transitions.writes + h.switches.writes + h.switches.clears, 0);
      expect(h.reconciles + h.backfills + h.clears, 0);
    },
  );

  test('a choice rejected by proof validation stays disabled', () async {
    final h = ResolutionHarness()..allowDevice = false;
    final result = await h.coordinator.previewPendingSwitchResolution();
    expect(result.status, AccountSwitchResolutionPreviewStatus.ready);
    expect(result.preview!.canChooseDevice, isFalse);
    expect(result.preview!.canChooseCloud, isTrue);
    expect(
      await h.coordinator.confirmPendingSwitchResolution(
        preview: result.preview!,
        side: AccountSwitchResolutionSide.device,
      ),
      AccountSwitchResolutionOutcome.blocked,
    );
    expect(h.reconciles + h.transitions.writes + h.backfills, 0);
  });

  test('no valid proof-preserving choice returns blocked', () async {
    final h = ResolutionHarness()
      ..allowDevice = false
      ..allowCloud = false;
    final result = await h.coordinator.previewPendingSwitchResolution();
    expect(result.status, AccountSwitchResolutionPreviewStatus.blocked);
    expect(result.preview, isNull);
    expect(h.reconciles + h.transitions.writes + h.backfills, 0);
  });

  test(
    'identity changing during preview read cannot issue a capability',
    () async {
      final h = ResolutionHarness();
      h.beforeRead = () async {
        h.sessions.acquire('target-owner');
      };
      final result = await h.coordinator.previewPendingSwitchResolution();
      expect(result.status, AccountSwitchResolutionPreviewStatus.stale);
      expect(result.preview, isNull);
      expect(
        h.transitions.writes + h.switches.writes + h.reconciles + h.backfills,
        0,
      );
    },
  );

  test(
    'foreign actual identity cannot preview the pending target history',
    () async {
      final h = ResolutionHarness()..identity.currentUid = 'unrelated-owner';
      final result = await h.coordinator.previewPendingSwitchResolution();
      expect(result.status, AccountSwitchResolutionPreviewStatus.blocked);
      expect(result.preview, isNull);
      expect(h.reads + h.transitions.writes + h.reconciles + h.backfills, 0);
    },
  );

  for (final drift in [
    'uid',
    'sameUid',
    'aba',
    'reset',
    'device',
    'cloud',
    'catalog',
    'revision',
    'operation',
  ]) {
    test(
      '$drift after preview requires a new preview without any writes',
      () async {
        final h = ResolutionHarness();
        final result = await h.coordinator.previewPendingSwitchResolution();
        expect(result.status, AccountSwitchResolutionPreviewStatus.ready);
        switch (drift) {
          case 'uid':
            h.identity.currentUid = 'other-owner';
          case 'sameUid':
            h.sessions.acquire('target-owner');
          case 'aba':
            h.sessions.acquire('other-owner');
            h.sessions.acquire('target-owner');
          case 'reset':
            LocalDataLifetime.invalidate();
          case 'device':
            h.device = resolutionSnapshot('a1', xp: 1);
          case 'cloud':
            h.cloud = resolutionSnapshot('a2', xp: 18);
          case 'catalog':
            h.catalogFingerprint = 'catalog-v2';
          case 'revision':
            h.remoteRevision++;
          case 'operation':
            h.switches.value = null;
        }
        final confirmed = await h.coordinator.confirmPendingSwitchResolution(
          preview: result.preview!,
          side: AccountSwitchResolutionSide.cloud,
        );
        expect(confirmed, AccountSwitchResolutionOutcome.stale);
        expect(h.reconciles + h.transitions.writes + h.backfills + h.clears, 0);
      },
    );
  }

  test('forged preview cannot enable a disabled owned choice', () async {
    final h = ResolutionHarness()..allowDevice = false;
    final result = await h.coordinator.previewPendingSwitchResolution();
    expect(result.status, AccountSwitchResolutionPreviewStatus.ready);
    final p = result.preview!;
    final forged = AccountSwitchResolutionPreview(
      devicePlacementLevel: p.devicePlacementLevel,
      cloudPlacementLevel: p.cloudPlacementLevel,
      deviceCompletedUnitCount: 0,
      cloudCompletedUnitCount: 0,
      canChooseDevice: true,
      canChooseCloud: true,
      binding: p.binding,
    );
    expect(
      await h.coordinator.confirmPendingSwitchResolution(
        preview: forged,
        side: AccountSwitchResolutionSide.device,
      ),
      AccountSwitchResolutionOutcome.blocked,
    );
    expect(h.reconciles + h.transitions.writes + h.backfills, 0);
  });

  test(
    'explicit confirmation persists consent before reconcile and activates once',
    () async {
      final h = ResolutionHarness();
      final result = await h.coordinator.previewPendingSwitchResolution();
      expect(result.status, AccountSwitchResolutionPreviewStatus.ready);
      final outcomes = await Future.wait([
        h.coordinator.confirmPendingSwitchResolution(
          preview: result.preview!,
          side: AccountSwitchResolutionSide.cloud,
        ),
        h.coordinator.confirmPendingSwitchResolution(
          preview: result.preview!,
          side: AccountSwitchResolutionSide.cloud,
        ),
      ]);
      expect(outcomes, contains(AccountSwitchResolutionOutcome.completed));
      expect(h.consentAtReconcile?.selectedPlacementLevel, 'a2');
      expect(h.consentAtReconcile?.side, AccountSwitchResolutionSide.cloud);
      expect(h.reconciles, 1);
      expect(h.backfills, 1);
      expect(h.clears, 1);
      expect(h.sessions.current?.mode, CloudWriteMode.ready);
    },
  );
}
