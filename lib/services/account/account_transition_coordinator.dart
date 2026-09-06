import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AccountLinkProvider { google, apple }

sealed class AnonymousCredentialLinkResult {
  const AnonymousCredentialLinkResult();
}

@immutable
class AnonymousCredentialLinked<T> extends AnonymousCredentialLinkResult {
  const AnonymousCredentialLinked(this.value);

  final T value;
}

@immutable
class ExistingAccountLinkConflict extends AnonymousCredentialLinkResult
    implements Exception {
  const ExistingAccountLinkConflict(this.provider, {this.credential});

  final AccountLinkProvider provider;

  /// The credential that collided with an existing account, when the caller
  /// supplied one. `T4a` forwards this so a client-side account switch can
  /// reuse the exact credential instead of asking the user to authenticate
  /// twice.
  final AuthCredential? credential;

  @override
  String toString() =>
      'The ${provider.name} credential belongs to an existing account.';
}

class DurableAccountTransitionNotSupported implements Exception {
  const DurableAccountTransitionNotSupported();

  @override
  String toString() => 'Switching between connected accounts is not supported.';
}

class AccountLinkSafetyFailure implements Exception {
  const AccountLinkSafetyFailure();

  @override
  String toString() => 'The authenticated account changed unexpectedly.';
}

/// 계정 연동을 시도조차 할 수 없는 상태 — Firebase 가 초기화되지 않았다.
///
/// ⚠️ 이 타입이 존재하는 이유: 예전에는 이 경우와 **사용자가 직접 취소한 경우**가
/// 둘 다 `null` 로 반환돼, UI 가 "취소"로 오인하고 **아무 메시지도 띄우지
/// 않았다**. 사용자에게는 그냥 "아무 일도 일어나지 않는 버튼"이었고, 실제 원인
/// (google-services 설정 누락, Firebase init 실패)은 어디에도 드러나지 않았다.
///
/// 사용자 취소는 계속 `null` 이고, 시스템 불가는 이 예외다.
class AccountLinkUnavailable implements Exception {
  const AccountLinkUnavailable();

  @override
  String toString() =>
      'Account linking is unavailable because Firebase is not initialised.';
}

/// Attempts only a Firebase credential link. A collision is data, not a
/// request to sign the primary FirebaseAuth instance into another account.
Future<AnonymousCredentialLinkResult> attemptAnonymousCredentialLink<T>({
  required AccountLinkProvider provider,
  required String sourceUid,
  bool sourceIsAnonymous = true,
  required String? Function() currentUid,
  required Future<T> Function() linkCredential,
  AuthCredential? credential,
}) {
  if (!sourceIsAnonymous) {
    throw const DurableAccountTransitionNotSupported();
  }
  if (sourceUid.trim().isEmpty || currentUid() != sourceUid) {
    throw const AccountLinkSafetyFailure();
  }
  return _attemptAnonymousCredentialLink(
    provider: provider,
    sourceUid: sourceUid,
    currentUid: currentUid,
    linkCredential: linkCredential,
    credential: credential,
  );
}

Future<AnonymousCredentialLinkResult> _attemptAnonymousCredentialLink<T>({
  required AccountLinkProvider provider,
  required String sourceUid,
  required String? Function() currentUid,
  required Future<T> Function() linkCredential,
  AuthCredential? credential,
}) async {
  try {
    final value = await linkCredential();
    if (currentUid() != sourceUid) {
      throw const AccountLinkSafetyFailure();
    }
    return AnonymousCredentialLinked<T>(value);
  } on FirebaseAuthException catch (error) {
    if (error.code != 'credential-already-in-use' &&
        error.code != 'email-already-in-use' &&
        error.code != 'account-exists-with-different-credential') {
      rethrow;
    }
    if (currentUid() != sourceUid) {
      throw const AccountLinkSafetyFailure();
    }
    return ExistingAccountLinkConflict(provider, credential: credential);
  }
}
