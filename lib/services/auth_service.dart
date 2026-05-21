import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  static String? get displayName => current?.displayName ?? current?.email;
  static String? get photoUrl => current?.photoURL;

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

  /// Aus Google-Account ausloggen → wieder anonym.
  static Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    await GoogleSignIn().signOut();
    await auth.signOut();
    await ensureSignedIn(); // wieder anonym
  }
}
