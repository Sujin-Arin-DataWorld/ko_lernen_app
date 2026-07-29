import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'account/cloud_write_session.dart';
import 'push_service.dart';
import 'storage_service.dart';

@immutable
class AuthProviderState {
  const AuthProviderState({
    required this.isGoogleLinked,
    required this.isAppleLinked,
  });

  factory AuthProviderState.fromProviderIds(Iterable<String> providerIds) {
    final ids = providerIds.toSet();
    return AuthProviderState(
      isGoogleLinked: ids.contains('google.com'),
      isAppleLinked: ids.contains('apple.com'),
    );
  }

  final bool isGoogleLinked;
  final bool isAppleLinked;

  bool get isDurable => isGoogleLinked || isAppleLinked;
}

/// Selects the Firebase UID that may own learning-data cloud backups.
///
/// Anonymous Firebase Auth remains available to optional authenticated
/// features, but it does not by itself authorize progress or bookshelf sync.
@immutable
class CloudBackupAccessPolicy {
  const CloudBackupAccessPolicy._();

  static String? uidFor({
    required String? uid,
    required Iterable<String> providerIds,
  }) {
    final normalizedUid = uid?.trim();
    if (normalizedUid == null || normalizedUid.isEmpty) {
      return null;
    }
    final providers = AuthProviderState.fromProviderIds(providerIds);
    return providers.isDurable ? normalizedUid : null;
  }
}

@immutable
class AuthAccountSnapshot {
  const AuthAccountSnapshot({
    required this.providers,
    this.displayName,
    this.photoUrl,
  });

  final AuthProviderState providers;
  final String? displayName;
  final String? photoUrl;
}

abstract interface class AccountDeletionOperations {
  String get userId;
  AuthProviderState get providerState;

  Future<void> reauthenticateWithGoogle();
  Future<String?> reauthenticateWithApple();
  Future<void> revokeAppleAuthorizationCode(String authorizationCode);
  Future<void> deleteCloudData();
  Future<void> deleteFirebaseUser();
  Future<void> signOutGoogle();
  Future<void> ensureAnonymousUser();
}

/// The Firebase user is already deleted, but one or more post-delete identity
/// recovery steps failed. Callers must continue local privacy cleanup and must
/// not retry deletion of the removed user.
class AccountDeletionRecoveryException implements Exception {
  const AccountDeletionRecoveryException(this.causes);

  final List<Object> causes;

  @override
  String toString() =>
      'The account was deleted, but identity recovery failed '
      '(${causes.length} failure(s)).';
}

/// Orders sensitive remote account deletion operations around Task 2's strict
/// push-ownership transition.
class AccountDeletionCoordinator {
  const AccountDeletionCoordinator({
    required this.operations,
    required this.ownershipTransitions,
  });

  final AccountDeletionOperations operations;
  final PushOwnershipTransitionCoordinator ownershipTransitions;

  Future<void> deleteAccount() async {
    final providers = operations.providerState;
    String? appleAuthorizationCode;

    // Apple revocation is mandatory whenever Apple is linked, including
    // dual-linked Google + Apple accounts.
    if (providers.isAppleLinked) {
      appleAuthorizationCode = _requireAppleAuthorizationCode(
        await operations.reauthenticateWithApple(),
      );
    } else if (providers.isGoogleLinked) {
      await operations.reauthenticateWithGoogle();
    }

    var accountDeleted = false;
    try {
      await ownershipTransitions.run(
        oldUid: operations.userId,
        transition: () async {
          if (appleAuthorizationCode != null) {
            await operations.revokeAppleAuthorizationCode(
              appleAuthorizationCode,
            );
          }

          await operations.deleteCloudData();
          try {
            await operations.deleteFirebaseUser();
          } on FirebaseAuthException catch (error) {
            if (error.code != 'requires-recent-login') {
              rethrow;
            }
            await _reauthenticateAndRevoke(providers);
            await operations.deleteFirebaseUser();
          }
          accountDeleted = true;

          await _recoverIdentity(providers);
        },
      );
    } catch (error, stackTrace) {
      if (accountDeleted && error is! AccountDeletionRecoveryException) {
        Error.throwWithStackTrace(
          AccountDeletionRecoveryException(
            List<Object>.unmodifiable(_postDeleteRecoveryCauses(error)),
          ),
          stackTrace,
        );
      }
      rethrow;
    }
  }

  List<Object> _postDeleteRecoveryCauses(Object error) {
    if (error is PushOwnershipTransitionException) {
      final transitionError = error.transitionError;
      return <Object>[
        if (transitionError is AccountDeletionRecoveryException)
          ...transitionError.causes
        else
          transitionError,
        error.rebindError,
      ];
    }
    return <Object>[error];
  }

  Future<void> _recoverIdentity(AuthProviderState providers) async {
    final failures = <Object>[];
    if (providers.isGoogleLinked) {
      try {
        await operations.signOutGoogle();
      } catch (error) {
        failures.add(error);
      }
    }

    try {
      await operations.ensureAnonymousUser();
    } catch (error) {
      try {
        await operations.ensureAnonymousUser();
      } catch (retryError) {
        failures
          ..add(error)
          ..add(retryError);
      }
    }

    if (failures.isNotEmpty) {
      throw AccountDeletionRecoveryException(
        List<Object>.unmodifiable(failures),
      );
    }
  }

  Future<void> _reauthenticateAndRevoke(AuthProviderState providers) async {
    if (providers.isAppleLinked) {
      final authorizationCode = _requireAppleAuthorizationCode(
        await operations.reauthenticateWithApple(),
      );
      await operations.revokeAppleAuthorizationCode(authorizationCode);
    } else if (providers.isGoogleLinked) {
      await operations.reauthenticateWithGoogle();
    }
  }

  String _requireAppleAuthorizationCode(String? authorizationCode) {
    final code = authorizationCode?.trim();
    if (code == null || code.isEmpty) {
      throw StateError(
        'Apple reauthentication did not return an authorization code.',
      );
    }
    return code;
  }
}

class _FirebaseAccountDeletionOperations implements AccountDeletionOperations {
  const _FirebaseAccountDeletionOperations({
    required this.auth,
    required this.user,
    required this.db,
  });

  final FirebaseAuth auth;
  final User user;
  final FirebaseFirestore db;

  @override
  String get userId => user.uid;

  @override
  AuthProviderState get providerState => AuthProviderState.fromProviderIds(
    user.providerData.map((provider) => provider.providerId),
  );

  @override
  Future<void> deleteCloudData() {
    return UserDataDeletionCoordinator(
      _FirestoreUserDataDeletionStore(db, user.uid),
    ).deleteAccountData();
  }

  @override
  Future<void> deleteFirebaseUser() {
    return user.delete();
  }

  @override
  Future<void> ensureAnonymousUser() {
    return AuthService.ensureSignedIn();
  }

  @override
  Future<String?> reauthenticateWithApple() {
    return AuthService._reauthenticateWithApple(user);
  }

  @override
  Future<void> reauthenticateWithGoogle() {
    return AuthService._reauthenticateWithGoogle(user);
  }

  @override
  Future<void> revokeAppleAuthorizationCode(String authorizationCode) {
    return auth.revokeTokenWithAuthorizationCode(authorizationCode);
  }

  @override
  Future<void> signOutGoogle() {
    return GoogleSignIn().signOut();
  }
}

abstract interface class UserDataDeletionStore {
  Future<void> beginAccountDeletion();
  Future<void> deleteSubcollection(String name);
  Future<void> removeUserFields(Set<String> fields);
  Future<void> deleteUserDocument();
}

enum AccountDocumentDeletionPlan {
  noOp,
  createMarkerAndDelete,
  deleteWithExistingMarker,
}

AccountDocumentDeletionPlan accountDocumentDeletionPlan({
  required bool userExists,
  required bool markerExists,
}) {
  if (!userExists) {
    return AccountDocumentDeletionPlan.noOp;
  }
  return markerExists
      ? AccountDocumentDeletionPlan.deleteWithExistingMarker
      : AccountDocumentDeletionPlan.createMarkerAndDelete;
}

class UserDataDeletionCoordinator {
  const UserDataDeletionCoordinator(this.store);

  final UserDataDeletionStore store;

  static const Set<String> operationalFields = {
    'gyeIds',
    'blockedUids',
    'fcmTokens',
  };

  static const Set<String> backupFields = {
    'vok',
    'chosung',
    'wordle',
    'grammar',
    'app',
    'progress',
    'srs_json',
    'custom_packs_json',
    'bookshelf_json',
    'updated_at',
  };

  static const List<String> backupSubcollections = [
    'packs',
    'quests',
    'bookshelf',
    'custom_packs',
    'custom_words',
  ];

  Future<void> deleteCloudBackup() async {
    for (final collectionName in backupSubcollections) {
      await store.deleteSubcollection(collectionName);
    }
    await store.removeUserFields(backupFields);
  }

  Future<void> deleteAccountData() async {
    await store.beginAccountDeletion();
    for (final collectionName in backupSubcollections) {
      await store.deleteSubcollection(collectionName);
    }
    // Deleting this document is intentional: the retryable server trigger owns
    // Gye membership/ownership and community-identity cleanup.
    await store.deleteUserDocument();
  }
}

class _FirestoreUserDataDeletionStore implements UserDataDeletionStore {
  const _FirestoreUserDataDeletionStore(this.db, this.uid);

  final FirebaseFirestore db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      db.collection('users').doc(uid);

  @override
  Future<void> beginAccountDeletion() async {
    final markerRef = db.collection('account_deletions').doc(uid);
    await db.runTransaction((transaction) async {
      final marker = await transaction.get(markerRef);
      final user = await transaction.get(_userRef);
      if (marker.exists || !user.exists) {
        return;
      }
      transaction.set(markerRef, {
        'state': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> deleteSubcollection(String name) {
    return AuthService._deleteCollection(_userRef.collection(name));
  }

  @override
  Future<void> deleteUserDocument() async {
    final markerRef = db.collection('account_deletions').doc(uid);
    final snapshots = await Future.wait([_userRef.get(), markerRef.get()]);
    final plan = accountDocumentDeletionPlan(
      userExists: snapshots[0].exists,
      markerExists: snapshots[1].exists,
    );
    if (plan == AccountDocumentDeletionPlan.noOp) {
      return;
    }
    final batch = db.batch();
    if (plan == AccountDocumentDeletionPlan.createMarkerAndDelete) {
      batch.set(markerRef, {
        'state': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    batch.delete(_userRef);
    await batch.commit();
  }

  @override
  Future<void> removeUserFields(Set<String> fields) async {
    final snapshot = await _userRef.get();
    if (!snapshot.exists) {
      return;
    }
    await _userRef.update({
      for (final field in fields) field: FieldValue.delete(),
    });
  }
}

/// Hybrid-Auth — **immer** anonym eingeloggt. Optional kann der
/// User mit Google verlinken, um Cloud-Backup zu aktivieren.
///
/// **Web-Sicherheit**: Firebase ist auf Web fragil (JS-Interop) — wenn keine
/// Firebase-Config vorliegt, wirft `FirebaseAuth.instance` eine
/// `FirebaseException`, die als JS-`TypeError` durchschlägt und z.B. die
/// Settings-Seite rot crashen lässt. Daher fangen **alle Lese-Getter**
/// Ausnahmen ab und liefern sichere Defaults; Aktions-Methoden brechen
/// sauber ab, wenn Firebase nicht verfügbar ist. Auf Android (mit
/// google-services.json) greifen die Guards nie — normales Verhalten.
class AuthService {
  static final PushOwnershipTransitionCoordinator _pushOwnershipTransitions =
      PushOwnershipTransitionCoordinator(
        push: pushService,
        notificationsEnabled: () => Storage.notificationsEnabled,
        sessions: cloudWriteSessionController,
      );

  /// Firebase-Auth-Instanz — `null`, wenn Firebase nicht initialisiert
  /// (z.B. Web ohne Config). Wirft nie.
  static FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Aktueller User — null-safe, wirft nie (Web-Crash-Schutz).
  static User? get current {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isSignedIn => current != null;
  static bool get isAnonymous => current?.isAnonymous ?? true;

  static AuthProviderState get providerState {
    try {
      return AuthProviderState.fromProviderIds(
        current?.providerData.map((provider) => provider.providerId) ??
            const <String>[],
      );
    } catch (_) {
      return const AuthProviderState(
        isGoogleLinked: false,
        isAppleLinked: false,
      );
    }
  }

  static bool get isGoogleLinked => providerState.isGoogleLinked;
  static bool get isAppleLinked => providerState.isAppleLinked;
  static bool get isDurableLinked => providerState.isDurable;

  /// UID eligible for learning-progress backup, or `null` for anonymous-only
  /// and unavailable identities.
  static String? get cloudBackupUid {
    try {
      final user = current;
      return CloudBackupAccessPolicy.uidFor(
        uid: user?.uid,
        providerIds:
            user?.providerData.map((provider) => provider.providerId) ??
            const <String>[],
      );
    } catch (_) {
      return null;
    }
  }

  /// Apple Sign-In ist nur auf Apple-Plattformen verfügbar (App-Store-
  /// Richtlinie 4.8 verlangt es, sobald Google-Login angeboten wird).
  static bool get appleSignInAvailable {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static String? get displayName => current?.displayName ?? current?.email;
  static String? get photoUrl => current?.photoURL;
  static AuthAccountSnapshot get accountSnapshot => AuthAccountSnapshot(
    providers: providerState,
    displayName: displayName,
    photoUrl: photoUrl,
  );

  static FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// In `main()` aufrufen — sorgt dafür, dass IMMER ein User existiert.
  /// Bricht still ab, wenn Firebase nicht verfügbar ist (Web ohne Config).
  static Future<void> ensureSignedIn() async {
    final auth = _auth;
    if (auth == null) {
      return;
    }
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    _syncReadyCloudWriteSession(auth.currentUser?.uid);
  }

  static void _syncReadyCloudWriteSession(String? uid) {
    CloudWriteSessionSynchronizer(
      cloudWriteSessionController,
    ).synchronizeReady(uid);
  }

  static User? _activateSignedInUser(User? user) {
    _syncReadyCloudWriteSession(user?.uid);
    return user;
  }

  /// Anonymen User mit Google-Account verlinken.
  /// Wenn das Google-Konto bereits existiert (z.B. nach App-Reinstall) —
  /// einfach mit dem bestehenden Account einloggen.
  static Future<User?> linkWithGoogle() async {
    final auth = _auth;
    if (auth == null) return null;

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final user = auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        final result = await user.linkWithCredential(credential);
        return _activateSignedInUser(result.user);
      } on FirebaseAuthException catch (e) {
        // Wenn Account bereits existiert → einfach einloggen
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          final result = await auth.signInWithCredential(credential);
          return _activateSignedInUser(result.user);
        }
        rethrow;
      }
    } else {
      final result = await auth.signInWithCredential(credential);
      return _activateSignedInUser(result.user);
    }
  }

  /// Anonymen User mit Apple-Account verlinken (iOS — App-Store-Pflicht 4.8).
  /// Wie [linkWithGoogle]: existiert das Apple-Konto bereits → einfach anmelden.
  static Future<User?> linkWithApple() async {
    final auth = _auth;
    if (auth == null) return null;

    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256(rawNonce),
    );
    final credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    final user = auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        final result = await user.linkWithCredential(credential);
        await _maybeSetAppleName(result.user, appleCredential);
        return _activateSignedInUser(result.user);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          final result = await auth.signInWithCredential(credential);
          return _activateSignedInUser(result.user);
        }
        rethrow;
      }
    } else {
      final result = await auth.signInWithCredential(credential);
      return _activateSignedInUser(result.user);
    }
  }

  /// Apple liefert den Namen nur beim allerersten Login — übernehmen, wenn
  /// vorhanden und noch kein displayName gesetzt ist.
  static Future<void> _maybeSetAppleName(
    User? user,
    AuthorizationCredentialAppleID c,
  ) async {
    if (user == null) return;
    if (user.displayName != null && user.displayName!.isNotEmpty) return;
    final name = [
      c.givenName,
      c.familyName,
    ].where((e) => e != null && e.isNotEmpty).join(' ').trim();
    if (name.isEmpty) return;
    try {
      await user.updateDisplayName(name);
    } catch (_) {
      // best-effort — Name ist optional.
    }
  }

  /// Delete the signed-in user's Firestore backup document and known
  /// subcollections. Local data stays untouched.
  static Future<void> deleteCloudData() async {
    final uid = current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      throw StateError('Cloud account data is unavailable.');
    }
    await UserDataDeletionCoordinator(
      _FirestoreUserDataDeletionStore(db, uid),
    ).deleteCloudBackup();
  }

  /// Delete the Firebase account plus its Firestore backup.
  ///
  /// Caller is responsible for clearing local device data after this succeeds.
  /// A fresh anonymous Firebase user is created afterwards so the anonymous-first
  /// app contract remains true.
  static Future<void> deleteAccount() async {
    final auth = _auth;
    final user = auth?.currentUser;
    final db = _db;
    if (auth == null || user == null || db == null) {
      throw StateError('The Firebase account is unavailable.');
    }

    await AccountDeletionCoordinator(
      operations: _FirebaseAccountDeletionOperations(
        auth: auth,
        user: user,
        db: db,
      ),
      ownershipTransitions: _pushOwnershipTransitions,
    ).deleteAccount();
  }

  /// Aus Google-Account ausloggen → wieder anonym.
  static Future<void> signOut() async {
    final auth = _auth;
    final oldUid = auth?.currentUser?.uid;
    if (auth == null || oldUid == null) {
      return;
    }
    await _pushOwnershipTransitions.run(
      oldUid: oldUid,
      transition: () async {
        await GoogleSignIn().signOut();
        await auth.signOut();
        await ensureSignedIn(); // wieder anonym
      },
    );
  }

  static Future<void> _reauthenticateWithGoogle(User user) async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'reauth-cancelled',
        message: 'Google reauthentication was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  static Future<String?> _reauthenticateWithApple(User user) async {
    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email],
      nonce: _sha256(rawNonce),
    );
    final credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
    await user.reauthenticateWithCredential(credential);
    final authorizationCode = appleCredential.authorizationCode.trim();
    return authorizationCode.isEmpty ? null : authorizationCode;
  }

  /// Krypto-sicherer Nonce für Apple Sign-In (Replay-Schutz). Roh-Nonce geht
  /// an Firebase (`rawNonce`), der SHA-256-Hash an Apple (`nonce`).
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snap = await collection.limit(400).get();
      if (snap.docs.isEmpty) return;

      final batch = collection.firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
