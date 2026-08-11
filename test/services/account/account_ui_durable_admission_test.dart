import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(AuthService.resetCloudBackupDeletionForTesting);

  test(
    'an admitted provider link completes before confirmation writes its replacement journal',
    () async {
      final scenario = await _AdmissionScenario.create();
      final providerStarted = Completer<void>();
      final releaseProvider = Completer<void>();
      final events = <String>[];
      final flow = _RecordingReplacementFlow(
        sessions: scenario.sessions,
        journalStore: scenario.replacementJournalStore,
        events: events,
      );
      final directLink = ProductionAccountUiOperations(
        providerLinker: (_) async {
          events.add('provider-entered');
          providerStarted.complete();
          await releaseProvider.future;
          events.add('direct-auth-mutation');
          return const AccountUiLinkCompleted();
        },
      );
      final replacement = ProductionAccountUiOperations(
        replacementFlowFactory: () async => flow,
      );

      final link = directLink.link(AccountLinkProvider.google);
      await providerStarted.future;
      final confirmation = replacement.confirmReplacement(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
      );
      await Future<void>.delayed(Duration.zero);

      expect(flow.confirmCalls, 0);

      releaseProvider.complete();

      expect(await link, isA<AccountUiLinkCompleted>());
      expect(
        (await confirmation).status,
        AccountTransitionStatus.reconciliationPending,
      );
      expect(events, <String>[
        'provider-entered',
        'direct-auth-mutation',
        'replacement-journal-written',
      ]);
      final persisted = await scenario.replacementJournalStore.read();
      expect(persisted, isNotNull);
      expect(
        persisted!.replacementPhase,
        AccountReplacementPhase.targetVerified,
      );
      expect(scenario.sessions.current, persisted.session);
    },
  );

  test(
    'confirmation cannot create a replacement journal beside another durable checkpoint',
    () async {
      for (final barrier in <_DurableBarrier>[
        _DurableBarrier.replacement,
        _DurableBarrier.deletion,
        _DurableBarrier.cloudDeletion,
      ]) {
        final scenario = await _AdmissionScenario.create();
        final flow = _RecordingReplacementFlow(
          sessions: scenario.sessions,
          journalStore: scenario.replacementJournalStore,
        );
        final operations = ProductionAccountUiOperations(
          replacementFlowFactory: () async => flow,
        );
        final existing = barrier == _DurableBarrier.replacement
            ? _replacementJournal()
            : null;
        if (existing != null) {
          await scenario.replacementJournalStore.write(existing);
        }
        await scenario.addBarrier(barrier);

        final result = await operations.confirmReplacement(
          const ExistingAccountLinkConflict(AccountLinkProvider.google),
        );

        expect(
          result.status,
          AccountTransitionStatus.blocked,
          reason: '$barrier',
        );
        expect(flow.confirmCalls, 0, reason: '$barrier');
        _expectSameJournal(
          await scenario.replacementJournalStore.read(),
          existing,
          reason: '$barrier',
        );
      }
    },
  );

  test(
    'replacement resume and cancel cannot run beside deletion or cloud checkpoints',
    () async {
      for (final barrier in <_DurableBarrier>[
        _DurableBarrier.deletion,
        _DurableBarrier.cloudDeletion,
      ]) {
        final scenario = await _AdmissionScenario.create();
        final existing = _replacementJournal();
        await scenario.replacementJournalStore.write(existing);
        await scenario.addBarrier(barrier);
        final flow = _RecordingReplacementFlow(
          sessions: scenario.sessions,
          journalStore: scenario.replacementJournalStore,
        );
        final operations = ProductionAccountUiOperations(
          replacementFlowFactory: () async => flow,
        );

        final resumed = await operations.resumeReplacement();
        final cancelled = await operations.cancelReplacement();

        expect(
          resumed.status,
          AccountTransitionStatus.blocked,
          reason: '$barrier',
        );
        expect(cancelled, isFalse, reason: '$barrier');
        expect(flow.resumeCalls, 0, reason: '$barrier');
        expect(flow.cancelCalls, 0, reason: '$barrier');
        _expectSameJournal(
          await scenario.replacementJournalStore.read(),
          existing,
          reason: '$barrier',
        );
      }
    },
  );

  test(
    'replacement resume and cancel admit their own persisted journal',
    () async {
      final scenario = await _AdmissionScenario.create();
      await scenario.replacementJournalStore.write(_replacementJournal());
      final flow = _RecordingReplacementFlow(
        sessions: scenario.sessions,
        journalStore: scenario.replacementJournalStore,
      );
      final operations = ProductionAccountUiOperations(
        replacementFlowFactory: () async => flow,
      );

      final resumed = await operations.resumeReplacement();
      final cancelled = await operations.cancelReplacement();

      expect(resumed.status, AccountTransitionStatus.reconciliationPending);
      expect(cancelled, isTrue);
      expect(flow.resumeCalls, 1);
      expect(flow.cancelCalls, 1);
    },
  );

  test('replacement resume records its returned terminal status', () async {
    final scenario = await _AdmissionScenario.create();
    await scenario.replacementJournalStore.write(_replacementJournal());
    final flow = _RecordingReplacementFlow(
      sessions: scenario.sessions,
      journalStore: scenario.replacementJournalStore,
      resumeStatus: AccountTransitionStatus.completed,
    );
    final operations = ProductionAccountUiOperations(
      replacementFlowFactory: () async => flow,
    );
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) messages.add(message);
    };

    try {
      final result = await operations.resumeReplacement();

      expect(result.status, AccountTransitionStatus.completed);
      expect(
        messages,
        contains(
          contains('klAccount: link.resume.result none status=completed'),
        ),
      );
    } finally {
      debugPrint = previousDebugPrint;
    }
  });

  test(
    'replacement composition uses the injected curriculum catalog',
    () async {
      final operations = ProductionAccountUiOperations(
        curriculumCatalogLoader: () async => _minimalCourseCatalog(),
      );

      final merger = await operations.loadCourseMasteryMergerForTesting();
      final result = merger(
        local: const CourseMasterySnapshot(
          placementLevel: 'a1',
          currentCourseUnitId: 'unit-root',
        ),
        remote: null,
      );

      expect(result.conflicts, isEmpty);
      expect(result.snapshot!.currentCourseUnitId, 'unit-root');
    },
  );

  test(
    'replacement composition forwards the loaded merger to target reconciliation',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      cloudWriteSessionController.clear();
      cloudWriteSessionController.acquire('anonymous-source');
      final session = cloudWriteSessionController.transition(
        CloudWriteMode.reconciling,
      );
      AccountReconciliationSnapshot? writtenRemote;
      final operations = ProductionAccountUiOperations(
        curriculumCatalogLoader: () async => _minimalCourseCatalog(),
        replacementAccountOperations: const _UnusedReplacementOperations(),
        targetReconciliationFactory:
            ({
              required target,
              required sourceSession,
              required sessions,
              required journalStore,
              required courseMasteryMerger,
            }) => AccountReconciliationCoordinator(
              sessions: sessions,
              journalStore: journalStore,
              readRemote: () async =>
                  CloudReadResult<AccountReconciliationSnapshot>.absent(),
              loadLocal: () => AccountReconciliationSnapshot(
                fields: const {},
                srsCards: const {},
                customPacks: const {},
                packProgress: const {},
                courseMastery: const CourseMasterySnapshot(
                  placementLevel: 'a1',
                  currentCourseUnitId: 'unit-root',
                ),
              ),
              writeRemote:
                  (
                    snapshot, {
                    required expectedRevision,
                    required operationId,
                  }) async {
                    writtenRemote = snapshot;
                    return const ReconciliationWriteResult.committed(
                      revision: 1,
                    );
                  },
              writeLocal:
                  (snapshot, {required session, required sessions}) async {},
              courseMasteryMerger: courseMasteryMerger,
            ),
      );

      final composition = await operations.createReplacementComposition();
      final result = await composition.coordinator.reconcile(
        target: const _VerifiedTarget(),
        session: session,
        operationId: 'composition-operation',
        catalog: const {},
      );

      expect(result.status, AccountReconciliationStatus.completed);
      expect(writtenRemote!.courseMastery!.currentCourseUnitId, 'unit-root');
    },
  );

  test(
    'replacement composition applies an injectable non-zero bounded poll cadence',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      Duration? requestedDelay;
      final operations = ProductionAccountUiOperations(
        curriculumCatalogLoader: () async => _minimalCourseCatalog(),
        replacementAccountOperations: const _UnusedReplacementOperations(),
        replacementStatusPollDelay: (delay) async {
          requestedDelay = delay;
        },
      );

      final composition = await operations.createReplacementComposition();
      await composition.coordinator.pollDelay();

      expect(
        requestedDelay,
        ProductionAccountUiOperations.replacementStatusPollInterval,
      );
      expect(requestedDelay, isNot(Duration.zero));
      expect(
        composition.coordinator.maxStatusPolls,
        ProductionAccountUiOperations.replacementStatusPollLimit,
      );
      expect(
        requestedDelay! * composition.coordinator.maxStatusPolls,
        lessThanOrEqualTo(
          ProductionAccountUiOperations.replacementStatusPollWindow,
        ),
      );
    },
  );
}

CurriculumCatalog _minimalCourseCatalog() =>
    CurriculumCatalog.fromDataForTesting(
      manifestJson: const {
        'version': 2,
        'courseUnits': [
          {
            'id': 'unit-root',
            'level': 'a1',
            'order': 1,
            'title': {'ko': 'root', 'de': 'root', 'en': 'root'},
            'canDo': {'ko': 'root', 'de': 'root', 'en': 'root'},
          },
        ],
        'concepts': <Map<String, dynamic>>[],
        'surfaceForms': <Map<String, dynamic>>[],
        'formFamilies': <Map<String, dynamic>>[],
        'contentLinks': <Map<String, dynamic>>[],
        'vocabPackUnitMap': <String, String>{},
        'smalltalkCategoryUnitMap': <String, String>{},
        'clozeTopicUnitMap': <String, String>{},
        'grammarRuleMap': <String, Map<String, dynamic>>{},
      },
      vocab: const [],
      grammar: const [],
      smalltalk: const [],
      cloze: const [],
      satz: const [],
      scenarios: const [],
    );

enum _DurableBarrier { replacement, deletion, cloudDeletion }

class _AdmissionScenario {
  _AdmissionScenario._({
    required this.preferences,
    required this.sessions,
    required this.replacementJournalStore,
    required this.cloudJournalStore,
  });

  final SharedPreferences preferences;
  final CloudWriteSessionController sessions;
  final SharedPreferencesReplacementTransitionJournalStore
  replacementJournalStore;
  final _MutableCloudBackupDeletionJournalStore cloudJournalStore;

  static Future<_AdmissionScenario> create() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final sessions = CloudWriteSessionController()..acquire('anonymous-source');
    final cloudJournalStore = _MutableCloudBackupDeletionJournalStore();
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
      CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'anonymous-source',
        journalStore: cloudJournalStore,
        gateway: _UnusedCloudBackupDeletionGateway(),
      ),
    );
    return _AdmissionScenario._(
      preferences: preferences,
      sessions: sessions,
      replacementJournalStore:
          SharedPreferencesReplacementTransitionJournalStore(preferences),
      cloudJournalStore: cloudJournalStore,
    );
  }

  Future<void> addBarrier(_DurableBarrier barrier) async {
    switch (barrier) {
      case _DurableBarrier.replacement:
        return;
      case _DurableBarrier.deletion:
        await preferences.setString(
          AuthService.accountDeletionCheckpointPreferenceKey,
          'pending-account-deletion',
        );
      case _DurableBarrier.cloudDeletion:
        cloudJournalStore.current = CloudBackupDeletionJournal.pending(
          session: const CloudWriteSession(
            uid: 'anonymous-source',
            epoch: 2,
            mode: CloudWriteMode.cleanupPending,
          ),
          requestKey: 'C' * 43,
        );
    }
  }
}

class _RecordingReplacementFlow implements AccountUiReplacementFlow {
  _RecordingReplacementFlow({
    required this.sessions,
    required this.journalStore,
    this.events,
    this.resumeStatus = AccountTransitionStatus.reconciliationPending,
  });

  final CloudWriteSessionController sessions;
  final SharedPreferencesReplacementTransitionJournalStore journalStore;
  final List<String>? events;
  final AccountTransitionStatus resumeStatus;
  int confirmCalls = 0;
  int resumeCalls = 0;
  int cancelCalls = 0;

  @override
  Future<bool> cancel() async {
    cancelCalls += 1;
    return true;
  }

  @override
  Future<AccountTransitionResult> confirm(
    ExistingAccountLinkConflict conflict,
  ) async {
    confirmCalls += 1;
    final current = sessions.current!;
    final quiesced = current.mode == CloudWriteMode.ready
        ? sessions.transition(CloudWriteMode.quiesced)
        : current;
    await journalStore.write(
      AccountTransitionJournal.fromSession(
        quiesced,
        replacementProvider: conflict.provider.name,
        replacementTargetUid: 'durable-target',
        replacementRequestKey: 'replacement-request-key',
        replacementPhase: AccountReplacementPhase.targetVerified,
      ),
    );
    events?.add('replacement-journal-written');
    return const AccountTransitionResult(
      AccountTransitionStatus.reconciliationPending,
    );
  }

  @override
  Future<AccountTransitionResult> resume() async {
    resumeCalls += 1;
    return AccountTransitionResult(resumeStatus);
  }
}

class _MutableCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  CloudBackupDeletionJournal? current;

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async {
    if (current != expected) return false;
    current = null;
    return true;
  }

  @override
  Future<CloudBackupDeletionJournal?> read() async => current;

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    current = journal;
  }
}

class _UnusedCloudBackupDeletionGateway implements CloudBackupDeletionGateway {
  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    throw UnimplementedError();
  }
}

class _VerifiedTarget implements VerifiedTargetContext {
  const _VerifiedTarget();

  @override
  bool get isAnonymous => false;

  @override
  String get uid => 'durable-target';

  @override
  Future<void> dispose() async {}
}

class _UnusedReplacementOperations implements ReplacementAccountOperations {
  const _UnusedReplacementOperations();

  Never _unused() => throw UnimplementedError();

  @override
  Future<AccountOperationResult> attachTarget({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) async => _unused();

  @override
  Future<AccountOperationResult> cancel({
    required CloudWriteSession sourceSession,
    required String operationId,
    required int expectedVersion,
  }) async => _unused();

  @override
  Future<AccountOperationResult> commitReconciliation({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) async => _unused();

  @override
  Future<AccountOperationResult> getStatus({
    required VerifiedTargetContext target,
    required String operationId,
  }) async => _unused();

  @override
  Future<AccountOperationResult> prepare({
    required CloudWriteSession sourceSession,
    required String targetUid,
    required String requestKey,
  }) async => _unused();

  @override
  Future<AccountOperationResult> startSourceCleanup({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) async => _unused();
}

AccountTransitionJournal _replacementJournal() {
  return AccountTransitionJournal.fromSession(
    const CloudWriteSession(
      uid: 'anonymous-source',
      epoch: 4,
      mode: CloudWriteMode.quiesced,
    ),
    replacementProvider: 'google',
    replacementTargetUid: 'durable-target',
    replacementRequestKey: 'replacement-request-key',
    replacementPhase: AccountReplacementPhase.targetVerified,
  );
}

void _expectSameJournal(
  AccountTransitionJournal? actual,
  AccountTransitionJournal? expected, {
  required String reason,
}) {
  expect(actual?.toJson(), expected?.toJson(), reason: reason);
}
