import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/account/account_switch_resolution.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_operation_ui.dart';
import 'package:ko_lernen_app/widgets/sori/account_progress_recovery_sheet.dart';

import '../support/real_fonts.dart';

class ResolutionOperations
    implements
        AccountUiOperations,
        AccountUiPendingStateSource,
        AccountUiSwitchResolutionOperations {
  final state = ValueNotifier(AccountUiPendingState.switchResolutionNeeded);
  var previews = 0;
  var confirmations = 0;
  var resumes = 0;
  Completer<void>? previewGate;
  Completer<void>? confirmGate;
  AccountSwitchResolutionSide? selected;
  AccountSwitchResolutionOutcome outcome =
      AccountSwitchResolutionOutcome.completed;
  AccountSwitchResolutionPreviewStatus status =
      AccountSwitchResolutionPreviewStatus.ready;

  @override
  bool get appleSignInAvailable => false;

  @override
  ValueListenable<AccountUiPendingState> get pendingState => state;

  @override
  Future<AccountUiPendingState> refreshPendingState() async => state.value;

  @override
  Future<AccountSwitchResolutionPreviewResult>
  previewPendingSwitchResolution() async {
    previews++;
    await previewGate?.future;
    return AccountSwitchResolutionPreviewResult(
      status,
      preview: status == AccountSwitchResolutionPreviewStatus.ready
          ? AccountSwitchResolutionPreview(
              devicePlacementLevel: 'a1',
              cloudPlacementLevel: 'a2',
              deviceCompletedUnitCount: 0,
              cloudCompletedUnitCount: 3,
              canChooseDevice: true,
              canChooseCloud: true,
              binding: Object(),
            )
          : null,
    );
  }

  @override
  Future<AccountSwitchResolutionOutcome> confirmPendingSwitchResolution({
    required AccountSwitchResolutionPreview preview,
    required AccountSwitchResolutionSide side,
  }) async {
    confirmations++;
    selected = side;
    await confirmGate?.future;
    if (outcome == AccountSwitchResolutionOutcome.completed) {
      state.value = AccountUiPendingState.none;
    }
    return outcome;
  }

  @override
  Future<AccountSwitchResolutionOutcome> resumePendingSwitchResolution() async {
    resumes++;
    if (outcome == AccountSwitchResolutionOutcome.completed) {
      state.value = AccountUiPendingState.none;
    }
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected account operation in recovery UI');
}

Future<void> pumpPanel(
  WidgetTester tester,
  ResolutionOperations operations, {
  bool includeSecondEntry = false,
  Locale locale = const Locale('de'),
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('account-review-capture'),
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: includeSecondEntry
              ? Builder(
                  builder: (context) => Column(
                    children: [
                      AccountPendingOperationPanel(operations: operations),
                      TextButton(
                        onPressed: () => reviewPendingAccountProgress(
                          context: context,
                          operations: operations,
                        ),
                        child: const Text('Second review entry'),
                      ),
                    ],
                  ),
                )
              : AccountPendingOperationPanel(operations: operations),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  for (final language in ['de', 'en']) {
    for (final size in [const Size(320, 780), const Size(390, 844)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'resume actions fit $language ${size.width}dp ${scale}x and retain explicit consent',
          (tester) async {
            final operations = ResolutionOperations()
              ..status = AccountSwitchResolutionPreviewStatus.resumeRequired;
            await pumpPanel(
              tester,
              operations,
              locale: Locale(language),
              size: size,
              textScale: scale,
            );
            final t = AppL10n.of(
              tester.element(find.byType(AccountPendingOperationPanel)),
            );
            Future<void> open() async {
              await tester.tap(find.text(t.accountRecoveryReview));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(operations.resumes, 0);
              for (final label in [
                t.btnCancel,
                t.accountRecoveryResumeConfirm,
              ]) {
                final rect = tester.getRect(find.text(label));
                expect(rect.left, greaterThanOrEqualTo(0));
                expect(rect.right, lessThanOrEqualTo(size.width));
                expect(rect.top, greaterThanOrEqualTo(0));
                expect(rect.bottom, lessThanOrEqualTo(size.height));
              }
            }

            await open();
            const captureDir = String.fromEnvironment(
              'ACCOUNT_RECOVERY_CAPTURE_DIR',
            );
            if (captureDir.isNotEmpty) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('account-review-capture')),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                try {
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await File(
                    '$captureDir/resume-${size.width.toInt()}-$language-${scale.toInt()}x.png',
                  ).writeAsBytes(bytes!.buffer.asUint8List());
                } finally {
                  image.dispose();
                }
              });
            }
            await tester.tap(find.text(t.btnCancel));
            await tester.pumpAndSettle();
            expect(operations.resumes, 0);
            await open();
            await tester.tap(find.text(t.accountRecoveryResumeConfirm));
            await tester.pumpAndSettle();
            expect(operations.resumes, 1);
            expect(operations.confirmations, 0);
          },
        );
      }
    }
  }

  testWidgets(
    'two entry points share one in-flight review and cancel allows a fresh review',
    (tester) async {
      final gate = Completer<void>();
      final operations = ResolutionOperations()..previewGate = gate;
      addTearDown(() {
        if (!gate.isCompleted) {
          gate.complete();
        }
      });
      await pumpPanel(tester, operations, includeSecondEntry: true);
      await tester.tap(find.text('Lernstand prüfen'));
      await tester.pump();
      await tester.tap(find.text('Second review entry'));
      await tester.pump();
      expect(operations.previews, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(
        find.byType(AccountProgressRecoverySheet, skipOffstage: false),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('account-recovery-cancel')));
      await tester.pumpAndSettle();
      expect(operations.confirmations, 0);
      await tester.tap(find.text('Second review entry'));
      await tester.pumpAndSettle();
      expect(operations.previews, 2);
      await tester.tap(find.byKey(const Key('account-recovery-cancel')));
      await tester.pumpAndSettle();
      expect(operations.confirmations, 0);
    },
  );

  testWidgets(
    'pending switch offers review, cancel writes nothing, explicit choice confirms once',
    (tester) async {
      final operations = ResolutionOperations();
      await pumpPanel(tester, operations);
      expect(
        find.text('Sicherung braucht deine Aufmerksamkeit'),
        findsOneWidget,
      );
      await tester.tap(find.text('Lernstand prüfen'));
      await tester.pumpAndSettle();
      expect(operations.previews, 1);
      expect(operations.confirmations, 0);
      await tester.tap(find.byKey(const Key('account-recovery-cancel')));
      await tester.pumpAndSettle();
      expect(operations.confirmations, 0);
      expect(
        operations.state.value,
        AccountUiPendingState.switchResolutionNeeded,
      );
      await tester.tap(find.text('Lernstand prüfen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-recovery-cloud')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('account-recovery-confirm')));
      await tester.pumpAndSettle();
      expect(operations.confirmations, 1);
      expect(operations.selected, AccountSwitchResolutionSide.cloud);
      expect(operations.state.value, AccountUiPendingState.none);
      expect(find.text('Sicherung braucht deine Aufmerksamkeit'), findsNothing);
    },
  );

  testWidgets(
    'stale confirmation retains pending state and a visible retry message',
    (tester) async {
      final operations = ResolutionOperations()
        ..outcome = AccountSwitchResolutionOutcome.stale;
      await pumpPanel(tester, operations);
      await tester.tap(find.text('Lernstand prüfen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-recovery-device')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('account-recovery-confirm')));
      await tester.pumpAndSettle();
      expect(
        operations.state.value,
        AccountUiPendingState.switchResolutionNeeded,
      );
      expect(
        find.text(
          'Dein Lernstand hat sich inzwischen geändert. Prüfe ihn bitte noch einmal.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lernstand prüfen'), findsOneWidget);
    },
  );

  testWidgets('unavailable preview never starts confirmation', (tester) async {
    final operations = ResolutionOperations()
      ..status = AccountSwitchResolutionPreviewStatus.unavailable;
    await pumpPanel(tester, operations);
    await tester.tap(find.text('Lernstand prüfen'));
    await tester.pumpAndSettle();
    expect(operations.confirmations, 0);
    expect(
      find.text(
        'Dein Lernstand kann gerade nicht geprüft werden. Versuche es erneut.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'back dismisses review without confirming or clearing the journal',
    (tester) async {
      final operations = ResolutionOperations();
      await pumpPanel(tester, operations);
      await tester.tap(find.text('Lernstand prüfen'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(operations.confirmations, 0);
      expect(
        operations.state.value,
        AccountUiPendingState.switchResolutionNeeded,
      );
      expect(find.text('Lernstand prüfen'), findsOneWidget);
    },
  );

  testWidgets(
    'durable choice resumes only after explicit continue and never offers a new choice',
    (tester) async {
      final operations = ResolutionOperations()
        ..status = AccountSwitchResolutionPreviewStatus.resumeRequired;
      await pumpPanel(tester, operations);
      await tester.tap(find.text('Lernstand prüfen'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-recovery-cloud')), findsNothing);
      expect(operations.resumes, 0);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(operations.resumes, 0);
      expect(operations.confirmations, 0);
      await tester.tap(find.text('Lernstand prüfen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bestätigte Auswahl fortsetzen'));
      await tester.pumpAndSettle();
      expect(operations.resumes, 1);
      expect(operations.confirmations, 0);
      expect(operations.state.value, AccountUiPendingState.none);
    },
  );

  testWidgets('repeated review taps and confirmation taps admit one request', (
    tester,
  ) async {
    final operations = ResolutionOperations()
      ..previewGate = Completer<void>()
      ..confirmGate = Completer<void>();
    await pumpPanel(tester, operations);
    await tester.tap(find.text('Lernstand prüfen'));
    await tester.pump();
    expect(operations.previews, 1);
    await tester.tap(find.byKey(const Key('account-recovery-review')));
    await tester.pump();
    expect(operations.previews, 1);
    operations.previewGate!.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-recovery-cloud')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-recovery-confirm')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(operations.confirmations, 1);
    await tester.tap(find.byKey(const Key('account-recovery-review')));
    await tester.pump();
    expect(operations.confirmations, 1);
    operations.confirmGate!.complete();
    await tester.pumpAndSettle();
    expect(operations.state.value, AccountUiPendingState.none);
  });

  testWidgets(
    'Settings backup reviews first, cancellation writes nothing, then a separate backup is required',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final operations = ResolutionOperations();
      final journal = ValueNotifier(CloudBackupDeletionJournalState.clear);
      addTearDown(journal.dispose);
      final sessions = CloudWriteSessionController()..acquire('durable');
      AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
        CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: ClearDeletionJournal(),
          gateway: UnusedDeletionGateway(),
        ),
      );
      var backupCalls = 0;
      CloudSync.overrideOperationsForTesting(
        backupWithResult: () async {
          backupCalls++;
          return CloudWriteResult.completed;
        },
      );
      addTearDown(() {
        CloudSync.resetOperationsForTesting();
        AuthService.resetCloudBackupDeletionForTesting();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SettingsScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
            ),
            accountOperations: operations,
            cloudDataDeletionJournalState: journal,
            initialFocus: SettingsInitialFocus.account,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Jetzt sichern'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Jetzt sichern'));
      await tester.pumpAndSettle();
      expect(operations.previews, 1);
      expect(backupCalls, 0);
      await tester.tap(find.byKey(const Key('account-recovery-cancel')));
      await tester.pumpAndSettle();
      expect(operations.confirmations, 0);
      expect(backupCalls, 0);
      await tester.tap(find.text('Jetzt sichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-recovery-cloud')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('account-recovery-confirm')));
      await tester.pumpAndSettle();
      expect(operations.confirmations, 1);
      expect(backupCalls, 0);
      expect(find.textContaining('Du kannst jetzt sichern.'), findsOneWidget);
      await tester.tap(find.text('Jetzt sichern'));
      await tester.pumpAndSettle();
      expect(backupCalls, 1);
    },
  );
}

class ClearDeletionJournal implements CloudBackupDeletionJournalStore {
  @override
  Future<CloudBackupDeletionJournal?> read() async => null;
  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async =>
      true;
  @override
  Future<void> write(CloudBackupDeletionJournal journal) async =>
      throw StateError('Recovery UI must not request deletion');
}

class UnusedDeletionGateway implements CloudBackupDeletionGateway {
  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async => throw StateError('Recovery UI must not delete cloud data');
}
