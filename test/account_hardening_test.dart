import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_nudge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('durable account providers', () {
    test('Apple alone is a durable linked account', () {
      final providers = AuthProviderState.fromProviderIds(const ['apple.com']);

      expect(providers.isDurable, isTrue);
      expect(providers.isAppleLinked, isTrue);
      expect(providers.isGoogleLinked, isFalse);
    });

    test('Google alone is a durable linked account', () {
      final providers = AuthProviderState.fromProviderIds(const ['google.com']);

      expect(providers.isDurable, isTrue);
      expect(providers.isAppleLinked, isFalse);
      expect(providers.isGoogleLinked, isTrue);
    });

    testWidgets('profile presents an Apple-only account as connected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileScreen(
            account: AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: false,
                isAppleLinked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.scrollUntilVisible(
        find.text('Mit Apple verbunden'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mit Apple verbunden'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Angemeldet: Apple'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('Angemeldet: Apple'), findsOneWidget);
      expect(find.text('Mit Google sichern'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('profile presents both linked providers deterministically', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileScreen(
            account: AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.scrollUntilVisible(
        find.text('Mit Google und Apple verbunden'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mit Google und Apple verbunden'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Angemeldet: Google und Apple'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('Angemeldet: Google und Apple'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('account nudge is suppressed for an Apple-only account', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      await showAccountNudgeSheet(
        context,
        account: const AuthAccountSnapshot(
          providers: AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Speichere deinen Fortschritt'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets(
      'settings uses the Apple provider label for Apple-only account',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            const SettingsScreen(
              account: AuthAccountSnapshot(
                providers: AuthProviderState(
                  isGoogleLinked: false,
                  isAppleLinked: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final signedIn = find.text('Angemeldet: Apple');
        await tester.scrollUntilVisible(
          signedIn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(signedIn, findsOneWidget);
        expect(find.text('Mit Google sichern'), findsNothing);
      },
    );
  });

  group('local account deletion cleanup', () {
    test(
      'remote deletion barrier precedes local cleanup and cleanup continues',
      () async {
        final events = <String>[];
        final operations = _FakeAccountCleanupOperations(events)
          ..imageCleanupFailure = StateError('image cleanup failed');
        final workflow = AccountDeletionWorkflow(operations);

        await expectLater(
          workflow.run(),
          throwsA(
            isA<AccountDeletionFailure>().having(
              (error) => error.causes.length,
              'cause count',
              1,
            ),
          ),
        );

        expect(events, <String>[
          'remote-delete',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
        ]);
      },
    );

    test('remote request failure leaves local cleanup untouched', () async {
      final events = <String>[];
      final remoteFailure = StateError('remote request unavailable');
      final operations = _FakeAccountCleanupOperations(events)
        ..remoteDeletionFailure = remoteFailure;
      final workflow = AccountDeletionWorkflow(operations);

      await expectLater(workflow.run(), throwsA(same(remoteFailure)));

      expect(events, <String>['remote-delete']);
    });

    test(
      'production cleanup adapter invokes every injected strict operation',
      () async {
        final events = <String>[];
        final adapter = AccountDeletionCleanupAdapter(
          deleteRemote: () async => events.add('remote-delete'),
          resetStorage: () async => events.add('local-reset'),
          disablePush: () async => events.add('push-disable'),
          deleteImages: () async => events.add('image-delete'),
          clearTts: () async => events.add('tts-clear'),
          resetMemory: () => events.add('memory-reset'),
        );

        await AccountDeletionWorkflow(adapter).run();

        expect(events, <String>[
          'remote-delete',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
        ]);
      },
    );

    test(
      'completed deletion checkpoint clears only after local retry succeeds',
      () async {
        final events = <String>[];
        final operations = _FakeAccountCleanupOperations(events)
          ..imageCleanupFailure = StateError('disk busy');
        var checkpointClears = 0;
        final workflow = AccountDeletionWorkflow(
          operations,
          completeCheckpoint: () async => checkpointClears += 1,
        );

        await expectLater(
          workflow.run(),
          throwsA(isA<AccountDeletionFailure>()),
        );
        expect(checkpointClears, 0);

        operations.imageCleanupFailure = null;
        await workflow.retryLocalCleanup();
        expect(checkpointClears, 1);
        expect(events.where((event) => event == 'remote-delete').length, 1);
      },
    );

    test(
      'checkpoint removal precedes feedback activation with the deleted UID',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          AuthService.accountDeletionCheckpointPreferenceKey: jsonEncode(
            _completedDeletionCheckpoint().toJson(),
          ),
        });
        final preferences = await SharedPreferences.getInstance();
        String? activatedDeletedUid;
        var checkpointPresentDuringActivation = true;

        await AuthService.completeLocalAccountDeletionCleanup(
          activateFeedback: (deletedUid) async {
            activatedDeletedUid = deletedUid;
            checkpointPresentDuringActivation = preferences.containsKey(
              AuthService.accountDeletionCheckpointPreferenceKey,
            );
            return true;
          },
        );

        expect(activatedDeletedUid, _completedDeletionCheckpoint().session.uid);
        expect(checkpointPresentDuringActivation, isFalse);
      },
    );

    test(
      'failed feedback activation retains the handoff for a later retry',
      () async {
        final checkpoint = _completedDeletionCheckpoint();
        SharedPreferences.setMockInitialValues(<String, Object>{
          AuthService.accountDeletionCheckpointPreferenceKey: jsonEncode(
            checkpoint.toJson(),
          ),
        });
        final preferences = await SharedPreferences.getInstance();
        var activationCalls = 0;
        var allowActivation = false;

        Future<void> complete() =>
            AuthService.completeLocalAccountDeletionCleanup(
              activateFeedback: (_) async {
                activationCalls += 1;
                expect(
                  preferences.containsKey(
                    AuthService.accountDeletionCheckpointPreferenceKey,
                  ),
                  isFalse,
                );
                return allowActivation;
              },
            );

        await expectLater(
          complete(),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.retryable,
              'retryable',
              isTrue,
            ),
          ),
        );
        expect(
          preferences.containsKey(
            AuthService.accountDeletionCheckpointPreferenceKey,
          ),
          isFalse,
        );
        expect(
          preferences.getString(
            AuthService
                .accountDeletionFeedbackActivationCheckpointPreferenceKey,
          ),
          jsonEncode(checkpoint.toJson()),
        );

        allowActivation = true;
        await complete();

        expect(activationCalls, 2);
        expect(
          preferences.containsKey(
            AuthService.accountDeletionCheckpointPreferenceKey,
          ),
          isFalse,
        );
        expect(
          preferences.containsKey(
            AuthService
                .accountDeletionFeedbackActivationCheckpointPreferenceKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'handoff-only restart is activation pending and never starts remote',
      () async {
        final checkpoint = _completedDeletionCheckpoint();
        SharedPreferences.setMockInitialValues(<String, Object>{
          AuthService.accountDeletionFeedbackActivationCheckpointPreferenceKey:
              jsonEncode(checkpoint.toJson()),
        });
        final restoration = await AuthService.restorePendingAccountState(
          'new-anonymous-uid',
        );

        expect(
          restoration.kind,
          AccountStartupRestorationKind.feedbackActivationPending,
        );
      },
    );

    test(
      'real preference reset preserves completed checkpoint across restart',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'kl_learning_progress': 'private-progress',
          'foreign_key': 'keep',
        });
        await Storage.init();
        final preferences = await SharedPreferences.getInstance();
        var remoteCalls = 0;
        var failLocalCleanup = true;

        AccountDeletionJournal? readCheckpoint() {
          final encoded = preferences.getString(
            AuthService.accountDeletionCheckpointPreferenceKey,
          );
          if (encoded == null) return null;
          return AccountDeletionJournal.fromJson(
            (jsonDecode(encoded) as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
        }

        Future<void> remoteDelete() {
          return AccountDeletionRemoteGate(
            readCheckpoint: () async => readCheckpoint(),
            preflight: (_) {},
            startOrResumeRemote: () async {
              remoteCalls += 1;
              await preferences.setString(
                AuthService.accountDeletionCheckpointPreferenceKey,
                const JsonEncoder.withIndent(
                  '  ',
                ).convert(_completedDeletionCheckpoint().toJson()),
              );
            },
            recoverCompleted: (_) async {},
          ).run();
        }

        AccountDeletionWorkflow newWorkflow() => AccountDeletionWorkflow(
          AccountDeletionCleanupAdapter(
            deleteRemote: remoteDelete,
            resetStorage: () => Storage.resetAllStrict(
              canonicalizeAccountDeletionCheckpoint:
                  AuthService.canonicalizeCompletedDeletionCheckpoint,
            ),
            disablePush: () async {
              if (failLocalCleanup) throw StateError('push unavailable');
            },
            deleteImages: () async {
              if (failLocalCleanup) throw StateError('images unavailable');
            },
            clearTts: () async {
              if (failLocalCleanup) throw StateError('tts unavailable');
            },
            resetMemory: () {},
          ),
          completeCheckpoint: () async {
            await preferences.remove(
              AuthService.accountDeletionCheckpointPreferenceKey,
            );
          },
        );

        await expectLater(
          newWorkflow().run(),
          throwsA(
            isA<AccountDeletionFailure>().having(
              (failure) => failure.causes.length,
              'independent cleanup failures',
              3,
            ),
          ),
        );
        expect(remoteCalls, 1);
        expect(preferences.containsKey('kl_learning_progress'), isFalse);
        expect(preferences.getString('foreign_key'), 'keep');
        expect(
          readCheckpoint()?.operation?.phase,
          AccountOperationPhase.completed,
        );
        expect(
          preferences.getString(
            AuthService.accountDeletionCheckpointPreferenceKey,
          ),
          jsonEncode(_completedDeletionCheckpoint().toJson()),
        );

        failLocalCleanup = false;
        await newWorkflow().run();
        expect(remoteCalls, 1);
        expect(
          preferences.containsKey(
            AuthService.accountDeletionCheckpointPreferenceKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'canonical checkpoint is durable before a later key removal fails',
      () async {
        final checkpointKey =
            AuthService.accountDeletionCheckpointPreferenceKey;
        final canonical = jsonEncode(_completedDeletionCheckpoint().toJson());
        final preferences = _MemoryPreferenceRemovalStore(
          <String, Object>{
            checkpointKey: const JsonEncoder.withIndent(
              '  ',
            ).convert(_completedDeletionCheckpoint().toJson()),
            'kl_learning_progress': 'private-progress',
            'kl_other_private_data': 'private-data',
          },
          removalResults: const {'kl_learning_progress': false},
        );

        await expectLater(
          Storage.resetAllStrict(
            preferences: preferences,
            canonicalizeAccountDeletionCheckpoint:
                AuthService.canonicalizeCompletedDeletionCheckpoint,
          ),
          throwsA(isA<PreferenceResetException>()),
        );

        expect(preferences.events.first, 'set:$checkpointKey');
        expect(preferences.values[checkpointKey], canonical);
        expect(preferences.values['kl_learning_progress'], 'private-progress');
      },
    );

    test(
      'canonical checkpoint write failure aborts before private data erase',
      () async {
        final checkpointKey =
            AuthService.accountDeletionCheckpointPreferenceKey;
        final raw = const JsonEncoder.withIndent(
          '  ',
        ).convert(_completedDeletionCheckpoint().toJson());
        final preferences = _MemoryPreferenceRemovalStore(<String, Object>{
          checkpointKey: raw,
          'kl_learning_progress': 'must-remain',
        }, setStringResult: false);

        await expectLater(
          Storage.resetAllStrict(
            preferences: preferences,
            canonicalizeAccountDeletionCheckpoint:
                AuthService.canonicalizeCompletedDeletionCheckpoint,
          ),
          throwsA(isA<PreferenceWriteException>()),
        );

        expect(preferences.events, <String>['set:$checkpointKey']);
        expect(preferences.values[checkpointKey], raw);
        expect(preferences.values['kl_learning_progress'], 'must-remain');
      },
    );

    test(
      'strict reset excludes only the exact validated checkpoint key',
      () async {
        final checkpointKey =
            AuthService.accountDeletionCheckpointPreferenceKey;
        final canonical = jsonEncode(_completedDeletionCheckpoint().toJson());
        final lookalikeKey = '${checkpointKey}_shadow';
        final preferences = _MemoryPreferenceRemovalStore(<String, Object>{
          checkpointKey: const JsonEncoder.withIndent(
            '  ',
          ).convert(_completedDeletionCheckpoint().toJson()),
          'kl_learning_progress': 'private-progress',
          lookalikeKey: 'must-not-bypass-reset',
          'foreign_key': 'keep',
        });

        await Storage.resetAllStrict(
          preferences: preferences,
          canonicalizeAccountDeletionCheckpoint:
              AuthService.canonicalizeCompletedDeletionCheckpoint,
        );

        expect(preferences.events.first, 'set:$checkpointKey');
        expect(preferences.events, isNot(contains('remove:$checkpointKey')));
        expect(preferences.events, contains('remove:$lookalikeKey'));
        expect(preferences.values, <String, Object>{
          checkpointKey: canonical,
          'foreign_key': 'keep',
        });
      },
    );

    test('invalid raw checkpoint is removed before strict reset', () async {
      final unknown = _completedDeletionCheckpoint().toJson()
        ..['authorizationCode'] = 'private-secret';
      final ready = _completedDeletionCheckpoint().toJson();
      (ready['session']! as Map<String, Object?>)['mode'] = 'ready';
      final missingOperation = _completedDeletionCheckpoint().toJson()
        ..['operation'] = null;
      final mismatched = _completedDeletionCheckpoint().toJson();
      (mismatched['operation']! as Map<String, Object?>)['kind'] =
          'replacement';
      for (final invalid in <Map<String, Object?>>[
        unknown,
        ready,
        missingOperation,
        mismatched,
      ]) {
        final preferences = _MemoryPreferenceRemovalStore(<String, Object>{
          'kl_learning_progress': 'must-not-erase-on-invalid-proof',
          AuthService.accountDeletionCheckpointPreferenceKey: jsonEncode(
            invalid,
          ),
        });
        await expectLater(
          Storage.resetAllStrict(
            preferences: preferences,
            canonicalizeAccountDeletionCheckpoint:
                AuthService.canonicalizeCompletedDeletionCheckpoint,
          ),
          throwsA(isA<AccountOperationFailure>()),
        );
        expect(
          preferences.values.containsKey(
            AuthService.accountDeletionCheckpointPreferenceKey,
          ),
          isFalse,
        );
        expect(
          preferences.values['kl_learning_progress'],
          'must-not-erase-on-invalid-proof',
        );
      }
    });
  });

  group('subscription management', () {
    test('uses the App Store subscriptions route on Apple platforms', () {
      expect(
        subscriptionManagementUri(TargetPlatform.iOS),
        Uri.parse('https://apps.apple.com/account/subscriptions'),
      );
    });

    test('uses the Play Store subscriptions route on Android', () {
      expect(
        subscriptionManagementUri(TargetPlatform.android),
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      );
    });

    test('unsupported and web platforms do not receive a store route', () {
      expect(subscriptionManagementUri(TargetPlatform.windows), isNull);
      expect(subscriptionManagementUri(TargetPlatform.linux), isNull);
      expect(subscriptionManagementUri(TargetPlatform.fuchsia), isNull);
      expect(
        subscriptionManagementUri(TargetPlatform.iOS, isWeb: true),
        isNull,
      );
    });

    test('launcher false result is surfaced as a failure', () async {
      final attempted = <Uri>[];
      final manager = SubscriptionManagementLauncher(
        platform: TargetPlatform.android,
        isWeb: false,
        launchExternal: (uri) async {
          attempted.add(uri);
          return false;
        },
      );

      await expectLater(
        manager.open(),
        throwsA(isA<SubscriptionManagementException>()),
      );

      expect(attempted, <Uri>[
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      ]);
    });

    testWidgets(
      'account deletion warns about subscriptions and exposes management',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        final workflow = AccountDeletionWorkflow(
          _FakeAccountCleanupOperations(<String>[]),
        );
        final cloudJournalState = ValueNotifier(
          CloudBackupDeletionJournalState.clear,
        );
        addTearDown(cloudJournalState.dispose);

        await tester.pumpWidget(
          _wrap(
            SettingsScreen(
              accountDeletionWorkflow: workflow,
              accountOperations: const _AlwaysReadyAccountOperations(),
              cloudDataDeletionJournalState: cloudJournalState,
            ),
          ),
        );
        await tester.pump();

        final deleteTile = find.text('Konto und alle Daten löschen');
        await tester.scrollUntilVisible(
          deleteTile,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(deleteTile);
        await tester.pumpAndSettle();
        await tester.tap(deleteTile);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Ein App-Store- oder Play-Store-Abo wird dadurch nicht gekündigt.',
          ),
          findsOneWidget,
        );
        expect(find.text('Store-Abo verwalten'), findsOneWidget);
      },
    );

    testWidgets('local cleanup failure never shows account deletion success', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      final operations = _FakeAccountCleanupOperations(<String>[])
        ..imageCleanupFailure = StateError('image cleanup failed');
      final cloudJournalState = ValueNotifier(
        CloudBackupDeletionJournalState.clear,
      );
      addTearDown(cloudJournalState.dispose);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            accountDeletionWorkflow: AccountDeletionWorkflow(operations),
            accountOperations: const _AlwaysReadyAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final deleteTile = find.text('Konto und alle Daten löschen');
      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(deleteTile);
      await tester.pumpAndSettle();
      final deleteListTile = tester.widget<ListTile>(
        find.ancestor(of: deleteTile, matching: find.byType(ListTile)),
      );
      expect(deleteListTile.onTap, isNotNull);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen').last);
      await tester.pump();

      expect(find.text('Löschung wird fortgesetzt'), findsOneWidget);
      expect(find.textContaining('image cleanup failed'), findsNothing);
      expect(find.text('Konto und Daten gelöscht'), findsNothing);
    });

    testWidgets('launcher false result shows localized management failure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      final manager = SubscriptionManagementLauncher(
        platform: TargetPlatform.android,
        isWeb: false,
        launchExternal: (_) async => false,
      );
      final cloudJournalState = ValueNotifier(
        CloudBackupDeletionJournalState.clear,
      );
      addTearDown(cloudJournalState.dispose);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            accountDeletionWorkflow: AccountDeletionWorkflow(
              _FakeAccountCleanupOperations(<String>[]),
            ),
            subscriptionManager: manager,
            accountOperations: const _AlwaysReadyAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final deleteTile = find.text('Konto und alle Daten löschen');
      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(deleteTile);
      await tester.pumpAndSettle();
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Store-Abo verwalten'));
      await tester.pump();

      expect(
        find.text('Die Aboverwaltung konnte nicht geöffnet werden.'),
        findsOneWidget,
      );
    });
  });
}

AccountDeletionJournal _completedDeletionCheckpoint() {
  return AccountDeletionJournal(
    version: AccountDeletionJournal.currentVersion,
    session: const CloudWriteSession(
      uid: 'deleted-source',
      epoch: 4,
      mode: CloudWriteMode.cleanupPending,
    ),
    requestKey: 'deletion-request-1',
    operation: const AccountOperationResult(
      operationId: 'deletion-operation-1',
      kind: AccountOperationKind.deletion,
      phase: AccountOperationPhase.completed,
      version: 3,
      attemptCount: 1,
      retryable: false,
    ),
  );
}

class _MemoryPreferenceRemovalStore implements PreferenceRemovalStore {
  _MemoryPreferenceRemovalStore(
    Map<String, Object> initial, {
    this.setStringResult = true,
    this.removalResults = const <String, bool>{},
  }) : values = Map<String, Object>.from(initial),
       durableValues = Map<String, Object>.from(initial);

  final Map<String, Object> values;
  final Map<String, Object> durableValues;
  final bool setStringResult;
  final Map<String, bool> removalResults;
  final List<String> events = <String>[];

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Set<String> getKeys() => values.keys.toSet();

  @override
  Object? getValue(String key) => values[key];

  @override
  Future<void> reload() async {
    values
      ..clear()
      ..addAll(durableValues);
  }

  @override
  Future<bool> remove(String key) async {
    events.add('remove:$key');
    final result = removalResults[key] ?? true;
    if (!result) return false;
    values.remove(key);
    durableValues.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    events.add('set:$key');
    if (!setStringResult) return false;
    values[key] = value;
    durableValues[key] = value;
    return true;
  }
}

class _FakeAccountCleanupOperations
    implements AccountDeletionCleanupOperations {
  _FakeAccountCleanupOperations(this.events);

  final List<String> events;
  Object? imageCleanupFailure;
  Object? remoteDeletionFailure;

  @override
  Future<void> clearTtsCache() async {
    events.add('tts-clear');
  }

  @override
  Future<void> deleteLocalImages() async {
    events.add('image-delete');
    if (imageCleanupFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> deleteRemoteAccount() async {
    events.add('remote-delete');
    if (remoteDeletionFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> disablePush() async {
    events.add('push-disable');
  }

  @override
  void resetInMemoryData() {
    events.add('memory-reset');
  }

  @override
  Future<void> resetLocalStorage() async {
    events.add('local-reset');
  }
}

class _AlwaysReadyAccountOperations implements AccountUiOperations {
  const _AlwaysReadyAccountOperations();

  @override
  bool get appleSignInAvailable => false;

  @override
  Future<bool> cancelReplacement() async => false;

  @override
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountTransitionResult(AccountTransitionStatus.blocked);

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async =>
      const AccountUiLinkBlocked();

  @override
  Future<AccountTransitionResult> resumeReplacement() async =>
      const AccountTransitionResult(AccountTransitionStatus.blocked);
}

Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
