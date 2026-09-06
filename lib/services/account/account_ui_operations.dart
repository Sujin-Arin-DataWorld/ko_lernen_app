import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../models/course_mastery.dart';
import '../auth_service.dart';
import 'account_failure_diagnostics.dart';
import '../course_mastery_service.dart';
import '../curriculum_catalog.dart';
import '../pack_progress_service.dart';
import '../vocab_pack_service.dart';
import 'account_operation_client.dart';
import 'account_switch_coordinator.dart';
import 'account_transition_coordinator.dart';
import 'cloud_backup_deletion.dart';
import 'cloud_write_session.dart';
import 'google_oauth_client.dart';
import 'apple_oauth_configuration.dart';
import 'durable_provider_link.dart';

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

class AccountUiProviderCollision extends AccountUiLinkResult {
  const AccountUiProviderCollision();
}

class AccountUiAppleConfigurationMissing extends AccountUiLinkResult {
  const AccountUiAppleConfigurationMissing();
}

/// 연동을 시도조차 할 수 없었다 — Firebase 가 없거나 초기화되지 않았다.
///
/// [AccountUiLinkCancelled] 와 반드시 구분해야 한다. 예전에는 둘 다 `null` 에서
/// 나와 취소로 뭉개졌고, 그래서 사용자는 "눌러도 아무 일이 없는 버튼"을 봤다.
class AccountUiLinkUnavailable extends AccountUiLinkResult {
  const AccountUiLinkUnavailable();
}

/// 연동이 실제로 실패했다 — 네트워크 끊김, 서버 오류, 권한 거부 등.
class AccountUiLinkFailed extends AccountUiLinkResult {
  const AccountUiLinkFailed(this.reason);

  final AccountUiLinkFailureReason reason;
}

/// 사용자에게 **다른 안내**를 해야 하는 실패 갈래.
enum AccountUiLinkFailureReason {
  /// 인터넷 없음 / 요청 중 끊김.
  offline,

  /// 서버 일시 오류, timeout, App Check 실패 등 재시도로 풀릴 수 있는 것.
  serverError,

  /// 분류할 수 없는 나머지.
  unknown,
}

enum AccountUiPendingState { loading, none, deletionLocalCleanup, blocked }

abstract interface class AccountUiPendingStateSource {
  ValueListenable<AccountUiPendingState> get pendingState;
  Future<AccountUiPendingState> refreshPendingState();
}

abstract interface class AccountUiOperations {
  bool get appleSignInAvailable;

  Future<AccountUiLinkResult> link(AccountLinkProvider provider);

  /// Signs the primary Firebase Auth instance into the existing durable
  /// account [conflict] collided with, and merges this device's local
  /// progress into that account.
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  );
}

typedef AccountUiProviderLinker =
    Future<AccountUiLinkResult> Function(AccountLinkProvider provider);

typedef AccountUiPendingStateReader = Future<AccountUiPendingState> Function();

@visibleForTesting
typedef AccountUiCurriculumCatalogLoader = Future<CurriculumCatalog> Function();

class ProductionAccountUiOperations
    implements AccountUiOperations, AccountUiPendingStateSource {
  const ProductionAccountUiOperations({
    this.providerLinker,
    @visibleForTesting this.pendingStateReader,
    @visibleForTesting this.curriculumCatalogLoader,
    @visibleForTesting this.switchFlow,
  });

  final AccountUiProviderLinker? providerLinker;
  final AccountUiPendingStateReader? pendingStateReader;
  final AccountUiCurriculumCatalogLoader? curriculumCatalogLoader;

  /// Test seam for exercising the switch route without Firebase. Production
  /// always calls through [AuthService.switchToExistingAccount].
  @visibleForTesting
  final Future<AccountSwitchResult> Function(ExistingAccountLinkConflict)?
  switchFlow;

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

  /// A legacy replacement journal (pre-T4b) is never read here — it is
  /// discarded at startup (see `AccountStartupJournalResolver`) and can no
  /// longer lock account actions. A pending cloud-backup-deletion journal is
  /// also never read here — the Settings panel already shows its own resume
  /// card (`cloudDeletionState`) and it must never lock link/delete too.
  static Future<AccountUiPendingState> _readPendingState() async {
    final deletion = await AuthService.readAccountDeletionCheckpoint();
    if (deletion?.operation?.phase == AccountOperationPhase.completed) {
      return AccountUiPendingState.deletionLocalCleanup;
    }
    return AccountUiPendingState.none;
  }

  @override
  bool get appleSignInAvailable => AuthService.appleSignInAvailable;

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
    final sourceUid = AuthService.current?.uid;
    final sourceSession = cloudWriteSessionController.current;
    if (await refreshPendingState() != AccountUiPendingState.none) {
      return const AccountUiLinkBlocked();
    }
    if (sourceUid != AuthService.current?.uid ||
        sourceSession != cloudWriteSessionController.current) {
      return const AccountUiLinkBlocked();
    }
    if (providerLinker case final linkProvider?) {
      // The injectable linker represents the same provider wait as the real
      // AuthService path, so keep it inside the durable admission lane too.
      return AuthService.runDurableAccountAdmission<AccountUiLinkResult>(
        allowCloudBackupDeletionJournal: true,
        onAdmitted: () => linkProvider(provider),
        onBlocked: () async => const AccountUiLinkBlocked(),
      );
    }
    try {
      final user = switch (provider) {
        AccountLinkProvider.google => await AuthService.linkWithGoogle(),
        AccountLinkProvider.apple => await AuthService.linkWithApple(),
      };
      // 여기 도달한 null 은 **사용자가 계정 선택 시트를 닫은 것**뿐이다.
      // 시스템 불가는 AccountLinkUnavailable 로, 나머지 실패는 아래 catch 로 온다.
      return user == null
          ? const AccountUiLinkCancelled()
          : const AccountUiLinkCompleted();
    } catch (error) {
      return mapAccountLinkException(error);
    }
  }

  @override
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  ) async {
    try {
      final flow = switchFlow;
      if (flow != null) return await flow(conflict);
      final composition = await loadAccountSwitchComposition(
        curriculumCatalogLoader: curriculumCatalogLoader,
      );
      return await AuthService.switchToExistingAccount(
        conflict,
        catalog: composition.catalog,
        courseMasteryMerger: composition.courseMasteryMerger,
      );
    } catch (error) {
      AccountFailureDiagnostics.log('switch.failed', error);
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    } finally {
      await refreshPendingState();
    }
  }

  @visibleForTesting
  Future<CourseMasteryReconciliationMerger>
  loadCourseMasteryMergerForTesting() async {
    final curriculum =
        await (curriculumCatalogLoader?.call() ?? CurriculumCatalog.load());
    return CourseMasteryService(curriculum).mergeForReconciliation;
  }
}

/// Loads the catalog and course-mastery merger a durable account switch needs
/// to reconcile local progress into the target account. Shared by
/// [ProductionAccountUiOperations.switchToExisting] and the startup
/// `resumeAccountSwitch` step in `main.dart`.
Future<({Map<String, PackCatalogEntry> catalog, CourseMasteryReconciliationMerger courseMasteryMerger})>
loadAccountSwitchComposition({
  AccountUiCurriculumCatalogLoader? curriculumCatalogLoader,
}) async {
  final packsFuture = VocabPackService.loadAll();
  final curriculumFuture = curriculumCatalogLoader?.call() ?? CurriculumCatalog.load();
  final packs = await packsFuture;
  final curriculum = await curriculumFuture;
  final catalog = <String, PackCatalogEntry>{
    for (final pack in packs)
      pack.id: PackCatalogEntry(
        packId: pack.id,
        level: pack.level,
        wordsTotal: pack.total,
      ),
  };
  return (
    catalog: catalog,
    courseMasteryMerger: CourseMasteryService(curriculum).mergeForReconciliation,
  );
}

/// Maps every production link exception onto a distinct UI result.
///
/// Cancel codes must stay [AccountUiLinkCancelled]. Journal / identity
/// fences stay [AccountUiLinkBlocked]. A missing Google ID token is a
/// retryable server-side configuration failure, not a quiet cancel.
@visibleForTesting
AccountUiLinkResult mapAccountLinkException(Object error) {
  if (error is DurableProviderLinkCollision) {
    return const AccountUiProviderCollision();
  }
  if (error is AppleOAuthConfigurationMissing) {
    return const AccountUiAppleConfigurationMissing();
  }
  if (error is ExistingAccountLinkConflict) {
    return AccountUiLinkConflict(error);
  }
  if (error is DurableAccountTransitionNotSupported ||
      error is CloudBackupDeletionIdentityChangeBlockedException) {
    return const AccountUiLinkBlocked();
  }
  if (error is AccountLinkUnavailable) {
    return const AccountUiLinkUnavailable();
  }
  if (error is GoogleOAuthIdTokenMissing) {
    return const AccountUiLinkFailed(AccountUiLinkFailureReason.serverError);
  }
  if (error is AccountLinkSafetyFailure) {
    return const AccountUiLinkFailed(AccountUiLinkFailureReason.unknown);
  }
  if (error is FirebaseAuthException) {
    if (isUserCancelledAuthCode(error.code)) {
      return const AccountUiLinkCancelled();
    }
    return AccountUiLinkFailed(_classifyAuthFailure(error.code));
  }
  if (error is PlatformException) {
    if (isUserCancelledAuthCode(error.code)) {
      return const AccountUiLinkCancelled();
    }
    return AccountUiLinkFailed(_classifyAuthFailure(error.code));
  }
  return const AccountUiLinkFailed(AccountUiLinkFailureReason.unknown);
}

@visibleForTesting
bool isUserCancelledAuthCode(String? code) {
  switch (code) {
    case 'sign_in_canceled':
    case 'sign_in_cancelled':
    case 'canceled':
    case 'cancelled':
    case 'ERROR_CANCELED':
    case 'reauth-cancelled':
    case 'target-verification-cancelled':
    case 'web-context-cancelled':
      return true;
    default:
      return false;
  }
}

/// 인증 실패 코드를 사용자에게 다르게 안내해야 하는 갈래로 나눈다.
///
/// 코드 문자열은 FirebaseAuth 와 Google Sign-In 플러그인이 각각 쓰는 값이다.
/// 분류가 애매하면 [AccountUiLinkFailureReason.unknown] 으로 두고 "잠시 후 다시"
/// 안내를 한다 — 확실하지 않은 원인을 단정해 보여 주는 것보다 낫다.
AccountUiLinkFailureReason _classifyAuthFailure(String code) {
  switch (code) {
    case 'network_error':
    case 'network-request-failed':
      return AccountUiLinkFailureReason.offline;
    case 'internal-error':
    case 'too-many-requests':
    case 'unknown':
    case 'sign_in_failed':
    case 'developer_error':
    case '10':
    case 'missing-id-token':
    case 'firebaseAppCheckTokenInvalid':
    case 'app-check-token-invalid':
      return AccountUiLinkFailureReason.serverError;
    default:
      return AccountUiLinkFailureReason.unknown;
  }
}
