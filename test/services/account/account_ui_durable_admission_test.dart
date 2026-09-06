import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

// The old server-owned "replacement" flow let a UI-injected fake race the
// direct provider link through AuthService.runDurableAccountAdmission, and
// let confirm/resume/cancel run beside other durable journals. T4b removed
// that whole confirmable/resumable/cancellable flow: switching to an
// existing account is now a single atomic operation performed entirely
// inside AuthService.switchToExistingAccount's own durable admission lane
// (see account_switch_coordinator_test.dart and auth_service_test.dart for
// that coverage). Only the still-meaningful curriculum-catalog composition
// seam remains here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('switch composition uses the injected curriculum catalog', () async {
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
  });

  group('T5: cloud-backup-deletion journal admission', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    tearDown(AuthService.resetCloudBackupDeletionForTesting);

    CloudBackupDeletionCoordinator coordinatorWithPendingJournal() {
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: CloudWriteSessionController(),
        currentUid: () => null,
        journalStore: const SharedPreferencesCloudBackupDeletionJournalStore(),
        gateway: _UnreachableGateway(),
      );
      AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
        coordinator,
      );
      return coordinator;
    }

    test(
      'link/delete lanes are admitted while the journal exists',
      () async {
        final coordinator = coordinatorWithPendingJournal();
        await coordinator.journalStore.write(
          CloudBackupDeletionJournal.pending(
            session: const CloudWriteSession(
              uid: 'durable-source',
              epoch: 3,
              mode: CloudWriteMode.cleanupPending,
            ),
            requestKey: 'Q' * 43,
          ),
        );

        var admitted = false;
        final result = await AuthService.runDurableAccountAdmission<String>(
          allowCloudBackupDeletionJournal: true,
          onAdmitted: () async {
            admitted = true;
            return 'admitted';
          },
          onBlocked: () async => 'blocked',
        );

        expect(admitted, isTrue);
        expect(result, 'admitted');
      },
    );

    test(
      'a cloud-data operation is still blocked by the same journal',
      () async {
        final coordinator = coordinatorWithPendingJournal();
        await coordinator.journalStore.write(
          CloudBackupDeletionJournal.pending(
            session: const CloudWriteSession(
              uid: 'durable-source',
              epoch: 3,
              mode: CloudWriteMode.cleanupPending,
            ),
            requestKey: 'Q' * 43,
          ),
        );

        expect(await AuthService.deleteCloudData(), CloudWriteResult.blocked);
      },
    );

    test(
      'without allowCloudBackupDeletionJournal the lane still blocks',
      () async {
        final coordinator = coordinatorWithPendingJournal();
        await coordinator.journalStore.write(
          CloudBackupDeletionJournal.pending(
            session: const CloudWriteSession(
              uid: 'durable-source',
              epoch: 3,
              mode: CloudWriteMode.cleanupPending,
            ),
            requestKey: 'Q' * 43,
          ),
        );

        final result = await AuthService.runDurableAccountAdmission<String>(
          onAdmitted: () async => 'admitted',
          onBlocked: () async => 'blocked',
        );

        expect(result, 'blocked');
      },
    );
  });
}

class _UnreachableGateway implements CloudBackupDeletionGateway {
  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) {
    throw UnimplementedError(
      'This admission test never lets the deletion callable run.',
    );
  }
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
