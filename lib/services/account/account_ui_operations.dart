import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../auth_service.dart';
import '../pack_progress_service.dart';
import '../vocab_pack_service.dart';
import 'account_transition_coordinator.dart';
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

abstract interface class AccountUiOperations {
  bool get appleSignInAvailable;

  Future<AccountUiLinkResult> link(AccountLinkProvider provider);
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  );
  Future<AccountTransitionResult> resumeReplacement();
  Future<bool> cancelReplacement();
}

class ProductionAccountUiOperations implements AccountUiOperations {
  const ProductionAccountUiOperations();

  @override
  bool get appleSignInAvailable => AuthService.appleSignInAvailable;

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
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
    final bundle = await _createCoordinator();
    return bundle.coordinator.cancel();
  }

  @override
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  ) async {
    final bundle = await _createCoordinator();
    return bundle.coordinator.confirm(conflict, catalog: bundle.catalog);
  }

  @override
  Future<AccountTransitionResult> resumeReplacement() async {
    final bundle = await _createCoordinator();
    return bundle.coordinator.resume(catalog: bundle.catalog);
  }

  Future<_AccountTransitionBundle> _createCoordinator() async {
    final preferences = await SharedPreferences.getInstance();
    final journalStore = SharedPreferencesReplacementTransitionJournalStore(
      preferences,
    );
    final packs = await VocabPackService.loadAll();
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
      operations: AuthService.replacementAccountOperations(),
      journalStore: journalStore,
      createRequestKey: _newRequestKey,
      reconcile:
          ({
            required target,
            required session,
            required operationId,
            required catalog,
          }) {
            final reconciliation = FirebaseTargetReconciliationFactory.create(
              target: target,
              sourceSession: session,
              sessions: cloudWriteSessionController,
              journalStore: journalStore,
            );
            return reconciliation.reconcile(
              session: session,
              operationId: operationId,
              catalog: catalog,
            );
          },
    );
    return _AccountTransitionBundle(coordinator: coordinator, catalog: catalog);
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

class _AccountTransitionBundle {
  const _AccountTransitionBundle({
    required this.coordinator,
    required this.catalog,
  });

  final AccountTransitionCoordinator coordinator;
  final Map<String, PackCatalogEntry> catalog;
}
