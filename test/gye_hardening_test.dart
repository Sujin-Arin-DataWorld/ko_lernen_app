import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/services/age_gate_service.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/gye_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('report document ID is deterministic per target and reporter', () {
    expect(
      GyeReport.documentIdFor(targetUid: 'target', reporterUid: 'reporter'),
      'target_reporter',
    );
  });

  group('Gye leave hardening', () {
    test('owner leave is rejected before any write', () async {
      var commits = 0;
      final coordinator = GyeLeaveCoordinator(
        currentUid: 'owner',
        loadMembership: (_) async =>
            const GyeLeaveMembership(uid: 'owner', role: 'owner'),
        commitLeave: (_, _) async => commits += 1,
      );

      await expectLater(
        coordinator.leave('ABC234'),
        throwsA(
          isA<GyeException>().having(
            (error) => error.error,
            'error',
            GyeError.ownerCannotLeave,
          ),
        ),
      );
      expect(commits, 0);
    });

    test('member write failure is surfaced', () async {
      final failure = StateError('write failed');
      final coordinator = GyeLeaveCoordinator(
        currentUid: 'member',
        loadMembership: (_) async =>
            const GyeLeaveMembership(uid: 'member', role: 'member'),
        commitLeave: (_, _) async => throw failure,
      );

      await expectLater(coordinator.leave('ABC234'), throwsA(same(failure)));
    });

    testWidgets('failed leave keeps route open and shows localized error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _leaveHarness(
          leave: (_) async => throw const GyeException(GyeError.network),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave gye'));
      await tester.pumpAndSettle();

      expect(find.text('Inside'), findsOneWidget);
      expect(find.text('Network error. Please try again.'), findsOneWidget);
    });

    testWidgets('owner explanation is localized and route stays open', (
      tester,
    ) async {
      await tester.pumpWidget(
        _leaveHarness(
          leave: (_) async =>
              throw const GyeException(GyeError.ownerCannotLeave),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave gye'));
      await tester.pumpAndSettle();

      expect(find.text('Inside'), findsOneWidget);
      expect(find.textContaining('owner cannot leave'), findsOneWidget);
    });

    testWidgets('successful leave is the only path that pops the route', (
      tester,
    ) async {
      await tester.pumpWidget(_leaveHarness(leave: (_) async {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave gye'));
      await tester.pumpAndSettle();

      expect(find.text('Inside'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('self-attested age backstop', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      await Storage.init();
    });

    test('missing birth year is blocked by the service backstop', () {
      expect(
        GyeService.validateAgeEligibility,
        throwsA(
          isA<GyeException>().having(
            (error) => error.error,
            'error',
            GyeError.ageRestricted,
          ),
        ),
      );
    });

    test('unplausible and under-16 self-attestations are blocked', () async {
      SharedPreferences.setMockInitialValues({
        'kl_birth_year': DateTime.now().year + 1,
      });
      Storage.resetForTesting();
      await Storage.init();
      expect(AgeGateService.needsBirthYear, isTrue);
      expect(GyeService.validateAgeEligibility, throwsA(isA<GyeException>()));

      SharedPreferences.setMockInitialValues({
        'kl_birth_year': DateTime.now().year - 15,
      });
      Storage.resetForTesting();
      await Storage.init();
      expect(GyeService.validateAgeEligibility, throwsA(isA<GyeException>()));
    });

    test('plausible 16+ self-attestation passes', () async {
      SharedPreferences.setMockInitialValues({
        'kl_birth_year': DateTime.now().year - 20,
      });
      Storage.resetForTesting();
      await Storage.init();

      expect(GyeService.validateAgeEligibility, returnsNormally);
      expect(AgeGateService.isSelfAttestedOnly, isTrue);
    });

    testWidgets('copy says age is self-declared and not identity-verified', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Builder(
            builder: (context) => Text(AppL10n.of(context).gyeAgeYearBody),
          ),
        ),
      );

      expect(find.textContaining('self-declared'), findsOneWidget);
      expect(find.textContaining('not identity verification'), findsOneWidget);
    });

    testWidgets('German copy also labels the check as self-attestation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Builder(
            builder: (context) => Text(AppL10n.of(context).gyeAgeYearBody),
          ),
        ),
      );

      expect(find.textContaining('Selbstauskunft'), findsOneWidget);
      expect(find.textContaining('keine Identitätsprüfung'), findsOneWidget);
    });
  });

  group('cloud backup deletion versus account deletion', () {
    test('account document deletion planning is idempotent', () {
      expect(
        accountDocumentDeletionPlan(userExists: false, markerExists: true),
        AccountDocumentDeletionPlan.noOp,
      );
      expect(
        accountDocumentDeletionPlan(userExists: false, markerExists: false),
        AccountDocumentDeletionPlan.noOp,
      );
      expect(
        accountDocumentDeletionPlan(userExists: true, markerExists: false),
        AccountDocumentDeletionPlan.createMarkerAndDelete,
      );
      expect(
        accountDocumentDeletionPlan(userExists: true, markerExists: true),
        AccountDocumentDeletionPlan.deleteWithExistingMarker,
      );
    });

    test(
      'cloud backup deletion preserves operational user fields and document',
      () async {
        final store = _FakeUserDataDeletionStore();

        await UserDataDeletionCoordinator(store).deleteCloudBackup();

        expect(store.userDocumentDeleted, isFalse);
        expect(
          UserDataDeletionCoordinator.operationalFields,
          containsAll(<String>['gyeIds', 'blockedUids', 'fcmTokens']),
        );
        expect(
          store.removedFields,
          isNot(contains(anyOf('gyeIds', 'blockedUids', 'fcmTokens'))),
        );
        expect(
          store.deletedSubcollections,
          containsAll(<String>[
            'packs',
            'quests',
            'bookshelf',
            'custom_packs',
            'custom_words',
          ]),
        );
        expect(store.events.last, startsWith('remove-fields:'));
      },
    );

    test(
      'account deletion removes the user document for durable trigger cleanup',
      () async {
        final store = _FakeUserDataDeletionStore();

        await UserDataDeletionCoordinator(store).deleteAccountData();

        expect(store.userDocumentDeleted, isTrue);
        expect(store.removedFields, isEmpty);
        expect(store.events.first, 'begin-account-deletion');
        expect(store.events.last, 'delete-user-document');
      },
    );

    test(
      'account deletion stops before user document when backup cleanup fails',
      () async {
        final store = _FakeUserDataDeletionStore()
          ..failingSubcollection = 'bookshelf';

        await expectLater(
          UserDataDeletionCoordinator(store).deleteAccountData(),
          throwsA(isA<StateError>()),
        );

        expect(store.userDocumentDeleted, isFalse);
        expect(store.events.first, 'begin-account-deletion');
        expect(store.deletedSubcollections, <String>[
          'packs',
          'quests',
          'bookshelf',
        ]);
        expect(store.events, isNot(contains('delete-user-document')));
      },
    );
  });
}

Widget _leaveHarness({required Future<void> Function(String) leave}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Builder(
      builder: (rootContext) => Scaffold(
        body: TextButton(
          onPressed: () {
            Navigator.of(rootContext).push(
              MaterialPageRoute<void>(
                builder: (_) => Builder(
                  builder: (context) => Scaffold(
                    body: Column(
                      children: [
                        const Text('Inside'),
                        TextButton(
                          onPressed: () =>
                              confirmLeaveGye(context, 'ABC234', leave: leave),
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

class _FakeUserDataDeletionStore implements UserDataDeletionStore {
  final Set<String> removedFields = <String>{};
  final List<String> deletedSubcollections = <String>[];
  final List<String> events = <String>[];
  String? failingSubcollection;
  bool userDocumentDeleted = false;

  @override
  Future<void> beginAccountDeletion() async {
    events.add('begin-account-deletion');
  }

  @override
  Future<void> deleteSubcollection(String name) async {
    deletedSubcollections.add(name);
    events.add('delete-subcollection:$name');
    if (name == failingSubcollection) {
      throw StateError('subcollection failed: $name');
    }
  }

  @override
  Future<void> deleteUserDocument() async {
    userDocumentDeleted = true;
    events.add('delete-user-document');
  }

  @override
  Future<void> removeUserFields(Set<String> fields) async {
    removedFields.addAll(fields);
    events.add('remove-fields:${fields.toList()..sort()}');
  }
}
