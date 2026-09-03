import 'package:firebase_auth/firebase_auth.dart';

import 'account_transition_coordinator.dart';
import 'cloud_write_session.dart';

enum DurableProviderLinkOutcome { linked, alreadyLinked, collision }

class DurableProviderLinkCollision implements Exception {
  const DurableProviderLinkCollision();
}

/// Adds a provider in-place. No sign-in, replacement, journal, or first-link
/// backfill is reachable from this lane. Credentials remain in this stack only.
Future<DurableProviderLinkOutcome> linkAdditionalDurableProvider<C>({
  required AccountLinkProvider provider,
  required String sourceUid,
  required CloudWriteSessionController sessions,
  required String? Function() currentUid,
  required Iterable<String> Function() currentProviderIds,
  required Future<C> Function(AccountLinkProvider, void Function())
  acquireCredential,
  required Future<void> Function(C) reauthenticate,
  required Future<String?> Function(C) linkCredential,
  required Future<void> Function() reload,
}) async {
  final session = sessions.current;
  void assertCurrent() {
    if (sourceUid.isEmpty ||
        currentUid() != sourceUid ||
        session == null ||
        session.uid != sourceUid ||
        session.mode != CloudWriteMode.ready ||
        sessions.current != session) {
      throw const AccountLinkSafetyFailure();
    }
  }

  assertCurrent();
  final providerId = '${provider.name}.com';
  final ids = currentProviderIds().toSet();
  if (!ids.contains('google.com') && !ids.contains('apple.com')) {
    throw const AccountLinkSafetyFailure();
  }
  if (ids.contains(providerId)) {
    return DurableProviderLinkOutcome.alreadyLinked;
  }
  final existing = ids.contains('google.com')
      ? AccountLinkProvider.google
      : AccountLinkProvider.apple;
  try {
    final proof = await acquireCredential(existing, assertCurrent);
    assertCurrent();
    await reauthenticate(proof);
    assertCurrent();
    final target = await acquireCredential(provider, assertCurrent);
    assertCurrent();
    String? linkedUid;
    try {
      linkedUid = await linkCredential(target);
    } on FirebaseAuthException catch (error) {
      assertCurrent();
      if (const {
        'credential-already-in-use',
        'email-already-in-use',
        'account-exists-with-different-credential',
      }.contains(error.code)) {
        return DurableProviderLinkOutcome.collision;
      }
      // Another completed attempt may have linked it. Never treat a bare
      // exception as success without reloading the original user's providers.
      if (error.code != 'provider-already-linked') {
        rethrow;
      }
      linkedUid = sourceUid;
    }
    assertCurrent();
    if (linkedUid != sourceUid) {
      throw const AccountLinkSafetyFailure();
    }
    await reload();
    assertCurrent();
    if (!currentProviderIds().contains(providerId)) {
      throw const AccountLinkSafetyFailure();
    }
    return DurableProviderLinkOutcome.linked;
  } catch (_) {
    assertCurrent();
    rethrow;
  }
}
