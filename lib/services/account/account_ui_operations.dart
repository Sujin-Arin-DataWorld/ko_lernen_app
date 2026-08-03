import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/course_mastery.dart';
import '../auth_service.dart';
import '../course_mastery_service.dart';
import '../curriculum_catalog.dart';
import '../pack_progress_service.dart';
import '../vocab_pack_service.dart';
import 'account_operation_client.dart';
import 'account_reconciliation.dart';
import 'account_transition_coordinator.dart';
import 'account_transition_journal.dart';
import 'cloud_backup_deletion.dart';
import 'cloud_write_session.dart';

sealed class AccountUiLinkResult {
  const AccountUiLinkResult();
}

class AccountUiLinkCompleted extends AccountUiLinkResult {
  const AccountUiLinkCompleted();
}

class AccountUiLinkCancelled extends AccountUiLinkResult {
  const AccountUiLinkCancelled();
}

class AccountUiLinkBlocked extends AccountUiLinkResult {
  const AccountUiLinkBlocked();
}

class AccountUiLinkConflict extends AccountUiLinkResult {
  const AccountUiLinkConflict(this.conflict);

  final ExistingAccountLinkConflict conflict;
}

enum AccountUiPendingState {
  loading,
  none,
  replacementCancellable,
  replacementResumable,
  deletionLocalCleanup,
  blocked,
}

abstract interface class AccountUiPendingStateSource {
  ValueListenable<AccountUiPendingState> get pendingState;
  Future<AccountUiPendingState> refreshPendingState();
}

abstract interface class AccountUiOperations {
  bool get appleSignInAvailable;

  Future<AccountUiLinkResult> link(AccountLinkProvider provider);
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  );
  Future<AccountTransitionResult> resumeReplacement();
  Future<bool> cancelReplacement();
}

typedef AccountUiProviderLinker =
    Future<AccountUiLinkResult> Function(AccountLinkProvider provider);

typedef AccountUiPendingStateReader = Future<AccountUiPendingState> Function();

@visibleForTesting
typedef AccountUiCurriculumCatalogLoader = Future<CurriculumCatalog> Function();

@visibleForTesting
typedef AccountUiTargetReconciliationFactory =
    AccountReconciliationCoordinator Function({
      required VerifiedTargetContext target,
      required CloudWriteSession sourceSession,
      required CloudWriteSessionController sessions,
      required AccountTransitionJournalStore journalStore,
      required CourseMasteryReconciliationMerger courseMasteryMerger,
    });

/// Test seam for exercising the UI-owned replacement route without Firebase.
///
/// Production always builds the coordinator-backed implementation below.
@visibleForTesting
abstract interface class AccountUiReplacementFlow {
  Future<bool> cancel();
  Future<AccountTransitionResult> confirm(ExistingAccountLinkConflict conflict);
  Future<AccountTransitionResult> resume();
}

@visibleForTesting
typedef AccountUiReplacementFlowFactory =
    Future<AccountUiReplacementFlow> Function();

class ProductionAccountUiOperations
    implements AccountUiOperations, AccountUiPendingStateSource {
  const ProductionAccountUiOperations({
    this.providerLinker,
    @visibleForTesting this.pendingStateReader,
    @visibleForTesting this.replacementFlowFactory,
    @visibleForTesting this.curriculumCatalogLoader,
    @visibleForTesting this.targetReconciliationFactory,
    @visibleForTesting this.replacementAccountOperations,
  });

  final AccountUiProviderLinker? providerLinker;
  final AccountUiPendingStateReader? pendingStateReader;
  final AccountUiReplacementFlowFactory? replacementFlowFactory;
  final AccountUiCurriculumCatalogLoader? curriculumCatalogLoader;
  final AccountUiTargetReconciliationFactory? targetReconciliationFactory;
  final ReplacementAccountOperations? replacementAccountOperations;

  static final ValueNotifier<AccountUiPendingState> _pendingState =
      ValueNotifier<AccountUiPendingState>(AccountUiPendingState.loading);
  static int _pendingStateRefreshGeneration = 0;

  @override
  ValueListenable<AccountUiPendingState> get pendingState => _pendingState;

  @override
  Future<AccountUiPendingState> refreshPendingState() async {
    final generation = ++_pendingStateRefreshGeneration;
    // This notifier is shared by every Settings/Profile guard. Clear a prior
    // admission synchronously so a sibling guard cannot start an account
    // action while the newest durable read is still in flight.
    _pendingState.value = AccountUiPendingState.loading;
    AccountUiPendingState next;
    try {
      next = await (pendingStateReader?.call() ?? _readPendingState());
    } catch (_) {
      next = AccountUiPendingState.blocked;
    }
    // Multiple account widgets can refresh this shared durable state at once.
    // Only the newest read may update the shared notifier; otherwise a late
    // stale failure could keep fresh clear actions locked, or a late clear
    // could unlock an action while a newer checkpoint is pending. Returning a
    // stale clear result would also let its caller start provider OAuth, so a
    // superseded read is blocked rather than treated as admission.
    if (generation != _pendingStateRefreshGeneration) {
      return AccountUiPendingState.blocked;
    }
    _pendingState.value = next;
    return next;
  }

  static Future<AccountUiPendingState> _readPendingState() async {
    final preferences = await SharedPreferences.getInstance();
    final replacement =
        await SharedPreferencesReplacementTransitionJournalStore(
          preferences,
        ).read();
    final deletion = await AuthService.readAccountDeletionCheckpoint();
    final cloudBackupDeletion =
        await const SharedPreferencesCloudBackupDeletionJournalStore().read();
    if (cloudBackupDeletion != null) {
      return AccountUiPendingState.blocked;
    }
    if (replacement != null && deletion != null) {
      return AccountUiPendingState.blocked;
    }
    if (deletion != null) {
      return deletion.operation?.phase == AccountOperationPhase.completed
          ? AccountUiPendingState.deletionLocalCleanup
          : AccountUiPendingState.blocked;
    }
    if (replacement?.replacementPhase case final phase?) {
      return switch (phase) {
        AccountReplacementPhase.targetVerified ||
        AccountReplacementPhase.prepared ||
        AccountReplacementPhase.attached ||
        AccountReplacementPhase.reconciling ||
        AccountReplacementPhase.reconciled =>
          AccountUiPendingState.replacementCancellable,
        AccountReplacementPhase.cleanupStarting ||
        AccountReplacementPhase.cleanupPending ||
        AccountReplacementPhase.activationPending =>
          AccountUiPendingState.replacementResumable,
      };
    }
    return AccountUiPendingState.none;
  }

  @override
  bool get appleSignInAvailable => AuthService.appleSignInAvailable;

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
    if (await refreshPendingState() != AccountUiPendingState.none) {
      return const AccountUiLinkBlocked();
    }
    if (providerLinker case final linkProvider?) {
      // The injectable linker represents the same provider wait as the real
      // AuthService path, so keep it inside the durable admission lane too.
      return AuthService.runDurableAccountAdmission<AccountUiLinkResult>(
        onAdmitted: () => linkProvider(provider),
        onBlocked: () async => const AccountUiLinkBlocked(),
      );
    }
    try {
      final user = switch (provider) {
        AccountLinkProvider.google => await AuthService.linkWithGoogle(),
        AccountLinkProvider.apple => await AuthService.linkWithApple(),
      };
      return user == null
          ? const AccountUiLinkCancelled()
          : const AccountUiLinkCompleted();
    } on ExistingAccountLinkConflict catch (conflict) {
      return AccountUiLinkConflict(conflict);
    } on DurableAccountTransitionNotSupported {
      return const AccountUiLinkBlocked();
    }
  }

  @override
  Future<bool> cancelReplacement() async {
    try {
      return await AuthService.runDurableAccountAdmission<bool>(
        allowReplacementTransitionJournal: true,
        onAdmitted: () async {
          final flow = await _createReplacementFlow();
          return flow.cancel();
        },
        onBlocked: () async => false,
      );
    } finally {
      await refreshPendingState();
    }
  }

  @override
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  ) async {
    try {
      return await AuthService.runDurableAccountAdmission<
        AccountTransitionResult
      >(
        onAdmitted: () async {
          final flow = await _createReplacementFlow();
          return flow.confirm(conflict);
        },
        onBlocked: () async =>
            const AccountTransitionResult(AccountTransitionStatus.blocked),
      );
    } finally {
      await refreshPendingState();
    }
  }

  @override
  Future<AccountTransitionResult> resumeReplacement() async {
    try {
      return await AuthService.runDurableAccountAdmission<
        AccountTransitionResult
      >(
        allowReplacementTransitionJournal: true,
        onAdmitted: () async {
          final flow = await _createReplacementFlow();
          return flow.resume();
        },
        onBlocked: () async =>
            const AccountTransitionResult(AccountTransitionStatus.blocked),
      );
    } finally {
      await refreshPendingState();
    }
  }

  Future<AccountUiReplacementFlow> _createReplacementFlow() async {
    final factory = replacementFlowFactory;
    if (factory != null) return factory();
    final bundle = await createReplacementComposition();
    return _CoordinatorAccountUiReplacementFlow(bundle);
  }

  @visibleForTesting
  Future<AccountUiReplacementComposition> createReplacementComposition() async {
    final preferences = await SharedPreferences.getInstance();
    final journalStore = SharedPreferencesReplacementTransitionJournalStore(
      preferences,
    );
    final packsFuture = VocabPackService.loadAll();
    final courseMasteryMergerFuture = loadCourseMasteryMergerForTesting();
    final packs = await packsFuture;
    final courseMasteryMerger = await courseMasteryMergerFuture;
    final catalog = <String, PackCatalogEntry>{
      for (final pack in packs)
        pack.id: PackCatalogEntry(
          packId: pack.id,
          level: pack.level,
          wordsTotal: pack.total,
        ),
    };
    final coordinator = AccountTransitionCoordinator(
      sessions: cloudWriteSessionController,
      identity: const FirebaseAccountTransitionIdentity(),
      verifier: FirebaseIsolatedTargetVerifier(),
      // The authenticated source gateway must always come from this factory:
      // it force-refreshes and fences the anonymous source token.
      operations:
          replacementAccountOperations ??
          AuthService.replacementAccountOperations(),
      journalStore: journalStore,
      createRequestKey: _newRequestKey,
      reconcile:
          ({
            required target,
            required session,
            required operationId,
            required catalog,
          }) {
            final reconciliation = targetReconciliationFactory != null
                ? targetReconciliationFactory!(
                    target: target,
                    sourceSession: session,
                    sessions: cloudWriteSessionController,
                    journalStore: journalStore,
                    courseMasteryMerger: courseMasteryMerger,
                  )
                : FirebaseTargetReconciliationFactory.create(
                    target: target,
                    sourceSession: session,
                    sessions: cloudWriteSessionController,
                    journalStore: journalStore,
                    courseMasteryMerger: courseMasteryMerger,
                  );
            return reconciliation.reconcile(
              session: session,
              operationId: operationId,
              catalog: catalog,
            );
          },
    );
    return AccountUiReplacementComposition(
      coordinator: coordinator,
      catalog: catalog,
    );
  }

  @visibleForTesting
  Future<CourseMasteryReconciliationMerger>
  loadCourseMasteryMergerForTesting() async {
    final curriculum =
        await (curriculumCatalogLoader?.call() ?? CurriculumCatalog.load());
    return CourseMasteryService(curriculum).mergeForReconciliation;
  }

  static String _newRequestKey() {
    const alphabet =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_';
    final random = Random.secure();
    return List<String>.generate(
      32,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}

@visibleForTesting
class AccountUiReplacementComposition {
  const AccountUiReplacementComposition({
    required this.coordinator,
    required this.catalog,
  });

  final AccountTransitionCoordinator coordinator;
  final Map<String, PackCatalogEntry> catalog;
}

class _CoordinatorAccountUiReplacementFlow implements AccountUiReplacementFlow {
  const _CoordinatorAccountUiReplacementFlow(this._bundle);

  final AccountUiReplacementComposition _bundle;

  @override
  Future<bool> cancel() => _bundle.coordinator.cancel();

  @override
  Future<AccountTransitionResult> confirm(
    ExistingAccountLinkConflict conflict,
  ) => _bundle.coordinator.confirm(conflict, catalog: _bundle.catalog);

  @override
  Future<AccountTransitionResult> resume() =>
      _bundle.coordinator.resume(catalog: _bundle.catalog);
}
