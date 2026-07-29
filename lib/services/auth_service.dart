import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
            List<Object>.unmodifiable(<Object>[error]),
          ),
          stackTrace,
        );
      }
      rethrow;
    }
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
    return AuthService._deleteUserFirestoreTree(db, user.uid);
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
      );

  static const List<String> _userSubcollections = [
    'packs',
    'quests',
    'bookshelf',
    'custom_packs',
    'custom_words',
  ];

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
        return result.user;
      } on FirebaseAuthException catch (e) {
        // Wenn Account bereits existiert → einfach einloggen
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          final result = await auth.signInWithCredential(credential);
          return result.user;
        }
        rethrow;
      }
    } else {
      final result = await auth.signInWithCredential(credential);
      return result.user;
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
    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final user = auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        final result = await user.linkWithCredential(credential);
        await _maybeSetAppleName(result.user, appleCredential);
        return result.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          final result = await auth.signInWithCredential(credential);
          return result.user;
        }
        rethrow;
      }
    } else {
      final result = await auth.signInWithCredential(credential);
      return result.user;
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
    final name = [c.givenName, c.familyName]
        .where((e) => e != null && e.isNotEmpty)
        .join(' ')
        .trim();
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
    await _deleteUserFirestoreTree(db, uid);
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

  static Future<void> _deleteUserFirestoreTree(
    FirebaseFirestore db,
    String uid,
  ) async {
    final userRef = db.collection('users').doc(uid);

    // gye 멤버십 정리 (GDPR: 사용자가 속한 모든 계에서 제거)
    await _deleteUserFromGyeMembers(db, uid);

    for (final collectionName in _userSubcollections) {
      await _deleteCollection(userRef.collection(collectionName));
    }
    await userRef.delete();
  }

  /// 사용자가 속한 모든 gye에서 멤버 문서 삭제 + 멤버수 감소.
  /// users/{uid}.gyeIds 배열 → 각 gye/{gyeId}/members/{uid} 삭제.
  static Future<void> _deleteUserFromGyeMembers(
    FirebaseFirestore db,
    String uid,
  ) async {
    try {
      // users/{uid} 문서에서 gyeIds 배열 읽기
      final userDoc = await db.collection('users').doc(uid).get();
      final gyeIds = List<String>.from(userDoc.get('gyeIds') ?? []);

      if (gyeIds.isEmpty) return;

      // 각 gye에서 멤버 문서 삭제 + 멤버수 감소
      final batch = db.batch();
      for (final gyeId in gyeIds) {
        final memberRef = db.collection('gye').doc(gyeId).collection('members').doc(uid);
        batch.delete(memberRef);

        // memberCount 감소 (rules는 쓰기 막지만, 삭제 트리거는 문제 아님)
        final metaRef = db.collection('gye').doc(gyeId);
        batch.update(metaRef, {
          'memberCount': FieldValue.increment(-1),
        });
      }

      await batch.commit();
    } catch (e) {
      // 계 정리 실패는 무시 (사용자 삭제를 막지 않음 — GDPR)
      debugPrint('[auth] gye cleanup error: $e');
    }
  }

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
