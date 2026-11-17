// DRAFT ONLY: copy to test/widgets/account_progress_recovery_profile_test.dart.
// Authored against 5e778d6b5b34f37947f21325170de28fe2252c77 + recovery WIP.
// Intentionally not run while the parent session's full suite is in flight.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_switch_resolution.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_nudge.dart';
import 'package:ko_lernen_app/widgets/sori/account_operation_ui.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

import '../support/real_fonts.dart';
import '../support/sori_stage_pump.dart';

const _viewport = Size(390, 844);
const _reviewKey = Key('account-recovery-review');
const _cloudKey = Key('account-recovery-cloud');
const _confirmKey = Key('account-recovery-confirm');
const _cancelKey = Key('account-recovery-cancel');
const _linkedAccount = AuthAccountSnapshot(
  providers: AuthProviderState(isGoogleLinked: true, isAppleLinked: false),
);
const _guestAccount = AuthAccountSnapshot(
  providers: AuthProviderState(isGoogleLinked: false, isAppleLinked: false),
);
final _t = lookupAppL10n(const Locale('de'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_profile': true,
      'kl_streak_days': 2,
      'kl_xp': 100,
      'kl_vok_correct': 11,
      Storage.companionVisiblePreferenceKey: false,
    });
    await Storage.init();
    MascotPreference.load();
  });

  testWidgets(
    'Profile recovery displays committed streak, XP level, and vocabulary without reopening',
    (tester) async {
      final operations = _RecoveryOperations();
      addTearDown(operations.pending.dispose);
      await _pumpProfile(tester, operations);
      final labelBefore = tester.element(find.text(_t.profileStatStreak));
      _expectStats(tester, streak: 2, level: 2, words: 11);
      final beforeReview = await _preferencesSnapshot();

      await _openReview(tester);
      await _tap(tester, _cloudKey);
      expect(operations.confirmations, 0);
      expect(operations.committedWrites, 0);
      expect(await _preferencesSnapshot(), beforeReview);

      await _tap(tester, _confirmKey);
      expect(operations.confirmations, 1);
      expect(operations.selected, AccountSwitchResolutionSide.cloud);
      expect(operations.committedWrites, 1);
      expect(operations.pending.value, AccountUiPendingState.none);
      // Prove this is a successful storage commit, rather than a fake label.
      expect(Storage.streakDays, 9);
      expect(Storage.xp, 600);
      expect(Storage.xpLevel, 7);
      expect(Storage.vokCorrect, 37);
      expect(find.byKey(_reviewKey), findsNothing);

      // Keep the original stats subtree alive. Reopening Profile or allowing
      // a lazy ListView remount here would hide the const _StatsRow regression.
      expect(labelBefore.mounted, isTrue);
      expect(
        tester.element(find.text(_t.profileStatStreak)),
        same(labelBefore),
      );
      _expectStats(tester, streak: 9, level: 7, words: 37);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profile recovery cancellation preserves storage and visible stats',
    (tester) async {
      final operations = _RecoveryOperations();
      addTearDown(operations.pending.dispose);
      await _pumpProfile(tester, operations);
      final beforeReview = await _preferencesSnapshot();

      await _openReview(tester);
      await _tap(tester, _cloudKey);
      await _tap(tester, _cancelKey);

      expect(operations.confirmations, 0);
      expect(operations.resumes, 0);
      expect(operations.committedWrites, 0);
      expect(
        operations.pending.value,
        AccountUiPendingState.switchResolutionNeeded,
      );
      expect(await _preferencesSnapshot(), beforeReview);
      _expectStats(tester, streak: 2, level: 2, words: 11);
      expect(find.byKey(_reviewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final resume in <bool>[false, true]) {
    testWidgets(
      'pending panel ${resume ? 'resume' : 'choice'} calls legacy completion once after success and zero after cancel',
      (tester) async {
        final operations = _RecoveryOperations()
          ..resumeRequired = resume
          ..commitGate = Completer<void>();
        addTearDown(operations.pending.dispose);
        var completedCalls = 0;
        await _pumpSurface(
          tester,
          Scaffold(
            body: AccountPendingOperationPanel(
              operations: operations,
              onCompleted: () async {
                completedCalls++;
              },
            ),
          ),
        );
        final beforeReview = await _preferencesSnapshot();

        await _openReview(tester);
        if (resume) {
          await tester.tap(find.text(_t.btnCancel));
          await pumpSoriStage(tester);
        } else {
          await _tap(tester, _cloudKey);
          await _tap(tester, _cancelKey);
        }
        expect(completedCalls, 0);
        expect(operations.confirmations, 0);
        expect(operations.resumes, 0);
        expect(operations.committedWrites, 0);
        expect(await _preferencesSnapshot(), beforeReview);

        await _openReview(tester);
        if (resume) {
          await tester.tap(find.text(_t.accountRecoveryResumeConfirm));
          await pumpSoriStage(tester);
        } else {
          await _tap(tester, _cloudKey);
          await _tap(tester, _confirmKey);
        }
        expect(operations.confirmations, resume ? 0 : 1);
        expect(operations.resumes, resume ? 1 : 0);
        expect(
          completedCalls,
          0,
          reason: 'The storage commit is still pending.',
        );
        expect(operations.committedWrites, 0);

        operations.commitGate!.complete();
        await pumpSoriStage(tester);
        expect(operations.committedWrites, 1);
        expect(operations.pending.value, AccountUiPendingState.none);
        expect(completedCalls, 1);
        await pumpSoriStage(tester);
        expect(
          completedCalls,
          1,
          reason: 'A state notification is not a second completion.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'specific switch callback takes precedence over legacy completion',
    (tester) async {
      final operations = _RecoveryOperations();
      addTearDown(operations.pending.dispose);
      var completedCalls = 0;
      var resolvedCalls = 0;
      await _pumpSurface(
        tester,
        Scaffold(
          body: AccountPendingOperationPanel(
            operations: operations,
            onCompleted: () async {
              completedCalls++;
            },
            onSwitchResolved: () async {
              resolvedCalls++;
            },
          ),
        ),
      );
      await _openReview(tester);
      await _tap(tester, _cloudKey);
      await _tap(tester, _confirmKey);
      expect(resolvedCalls, 1);
      expect(completedCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account nudge stays open on cancel and closes once after recovery',
    (tester) async {
      final operations = _RecoveryOperations();
      addTearDown(operations.pending.dispose);
      var nudgeClosed = 0;
      await _pumpSurface(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('open-nudge'),
              onPressed: () async {
                await showAccountNudgeSheet(
                  context,
                  account: _guestAccount,
                  accountOperations: operations,
                );
                nudgeClosed++;
              },
              child: const Text('Open account'),
            ),
          ),
        ),
      );
      await _tap(tester, const Key('open-nudge'));
      expect(find.text(_t.accountNudgeTitle), findsOneWidget);
      final beforeReview = await _preferencesSnapshot();

      await _openReview(tester);
      await _tap(tester, _cloudKey);
      await _tap(tester, _cancelKey);
      expect(nudgeClosed, 0);
      expect(operations.confirmations, 0);
      expect(await _preferencesSnapshot(), beforeReview);
      expect(find.text(_t.accountNudgeTitle), findsOneWidget);

      await _openReview(tester);
      await _tap(tester, _cloudKey);
      await _tap(tester, _confirmKey);
      expect(operations.confirmations, 1);
      expect(operations.committedWrites, 1);
      expect(nudgeClosed, 1);
      expect(find.text(_t.accountNudgeTitle), findsNothing);
      expect(find.byKey(const Key('open-nudge')).hitTestable(), findsOneWidget);
      await pumpSoriStage(tester);
      expect(nudgeClosed, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpSurface(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(1), disableAnimations: true),
        child: child!,
      ),
      home: home,
    ),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await pumpSoriStage(tester);
}

Future<void> _pumpProfile(
  WidgetTester tester,
  _RecoveryOperations operations,
) async {
  final deletion = ValueNotifier(CloudBackupDeletionJournalState.clear);
  addTearDown(deletion.dispose);
  await _pumpSurface(
    tester,
    ProfileScreen(
      account: _linkedAccount,
      accountOperations: operations,
      cloudDataDeletionJournalState: deletion,
      loadGyeMetas: () async => const [],
      enableCoach: false,
    ),
  );
  final scrollable = find
      .descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.text(_t.profileStatWords),
    220,
    scrollable: scrollable,
  );
  await tester.ensureVisible(find.byKey(_reviewKey));
  await pumpSoriStage(tester);
  expect(find.byKey(_reviewKey).hitTestable(), findsOneWidget);
  _expectStats(tester, streak: 2, level: 2, words: 11);
}

void _expectStats(
  WidgetTester tester, {
  required int streak,
  required int level,
  required int words,
}) {
  final expected = <String, int>{
    _t.profileStatStreak: streak,
    _t.profileStatLevel: level,
    _t.profileStatWords: words,
  };
  for (final entry in expected.entries) {
    final label = find.text(entry.key);
    expect(label, findsOneWidget);
    final tile = find
        .ancestor(of: label, matching: find.byType(SoriCard))
        .first;
    final value = find.descendant(
      of: tile,
      matching: find.text('${entry.value}'),
    );
    expect(
      value,
      findsOneWidget,
      reason: '${entry.key} must reflect committed storage.',
    );
    expect((Offset.zero & _viewport).contains(tester.getCenter(label)), isTrue);
    expect((Offset.zero & _viewport).contains(tester.getCenter(value)), isTrue);
  }
}

Future<Map<String, Object?>> _preferencesSnapshot() async {
  final preferences = await SharedPreferences.getInstance();
  return <String, Object?>{
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
}

Future<void> _openReview(WidgetTester tester) async {
  await _tap(tester, _reviewKey);
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await pumpSoriStage(tester);
}

// Link and replacement are deliberately unavailable: these tests exercise the
// optional recovery capability through real Profile/Panel/Nudge consumers.
class _RecoveryOperations
    implements
        AccountUiOperations,
        AccountUiPendingStateSource,
        AccountUiSwitchResolutionOperations {
  final pending = ValueNotifier(AccountUiPendingState.switchResolutionNeeded);
  final preview = AccountSwitchResolutionPreview(
    devicePlacementLevel: 'a1',
    cloudPlacementLevel: 'a2',
    deviceCompletedUnitCount: 1,
    cloudCompletedUnitCount: 3,
    canChooseDevice: true,
    canChooseCloud: true,
    binding: Object(),
  );
  int confirmations = 0;
  int resumes = 0;
  int committedWrites = 0;
  bool resumeRequired = false;
  Completer<void>? commitGate;
  AccountSwitchResolutionSide? selected;

  @override
  bool get appleSignInAvailable => false;

  @override
  ValueListenable<AccountUiPendingState> get pendingState => pending;

  @override
  Future<AccountUiPendingState> refreshPendingState() async => pending.value;

  @override
  Future<AccountSwitchResolutionPreviewResult>
  previewPendingSwitchResolution() async =>
      AccountSwitchResolutionPreviewResult(
        resumeRequired
            ? AccountSwitchResolutionPreviewStatus.resumeRequired
            : AccountSwitchResolutionPreviewStatus.ready,
        preview: resumeRequired ? null : preview,
      );

  @override
  Future<AccountSwitchResolutionOutcome> confirmPendingSwitchResolution({
    required AccountSwitchResolutionPreview preview,
    required AccountSwitchResolutionSide side,
  }) async {
    confirmations++;
    if (!identical(preview, this.preview)) {
      throw StateError('Recovery confirmation must use the reviewed preview.');
    }
    selected = side;
    return _commit();
  }

  @override
  Future<AccountSwitchResolutionOutcome> resumePendingSwitchResolution() async {
    resumes++;
    return _commit();
  }

  Future<AccountSwitchResolutionOutcome> _commit() async {
    await commitGate?.future;
    await Storage.setStreakDays(9);
    await Storage.setXp(600);
    await Storage.setVokCorrect(37);
    committedWrites++;
    pending.value = AccountUiPendingState.none;
    return AccountSwitchResolutionOutcome.completed;
  }

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
    throw StateError('Recovery must not start a new provider link.');
  }

  @override
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  ) async {
    throw StateError('Recovery must not start a new account replacement.');
  }
}
