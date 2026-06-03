import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  static bool get isGoogleLinked {
    try {
      return current?.providerData.any((p) => p.providerId == 'google.com') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static bool get isAppleLinked {
    try {
      return current?.providerData.any((p) => p.providerId == 'apple.com') ??
          false;
    } catch (_) {
      return false;
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
    if (auth == null) return;
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
    if (uid == null || db == null) return;
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
    if (auth == null || user == null) return;

    final wasGoogleLinked =
        user.providerData.any((p) => p.providerId == 'google.com');
    final wasAppleLinked =
        user.providerData.any((p) => p.providerId == 'apple.com');
    if (wasGoogleLinked) {
      await _reauthenticateWithGoogle(user);
    } else if (wasAppleLinked) {
      await _reauthenticateWithApple(user);
    }

    await deleteCloudData();
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (wasGoogleLinked) {
          await _reauthenticateWithGoogle(user);
        } else if (wasAppleLinked) {
          await _reauthenticateWithApple(user);
        }
        await user.delete();
      } else {
        rethrow;
      }
    }

    await GoogleSignIn().signOut();
    await ensureSignedIn();
  }

  /// Aus Google-Account ausloggen → wieder anonym.
  static Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    await GoogleSignIn().signOut();
    await auth.signOut();
    await ensureSignedIn(); // wieder anonym
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

  static Future<void> _reauthenticateWithApple(User user) async {
    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email],
      nonce: _sha256(rawNonce),
    );
    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    await user.reauthenticateWithCredential(credential);
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
