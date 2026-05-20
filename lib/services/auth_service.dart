import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Hybrid-Auth — **immer** anonym eingeloggt. Optional kann der
/// User mit Google verlinken, um Cloud-Backup zu aktivieren.
class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get current => _auth.currentUser;

  static bool get isSignedIn      => current != null;
  static bool get isAnonymous     => current?.isAnonymous ?? true;
  static bool get isGoogleLinked  =>
      current?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  static String? get displayName  => current?.displayName ?? current?.email;
  static String? get photoUrl     => current?.photoURL;

  /// In `main()` aufrufen — sorgt dafür, dass IMMER ein User existiert.
  static Future<void> ensureSignedIn() async {
    if (current == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Anonymen User mit Google-Account verlinken.
  /// Wenn das Google-Konto bereits existiert (z.B. nach App-Reinstall) —
  /// einfach mit dem bestehenden Account einloggen.
  static Future<User?> linkWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    final user = current;
    if (user != null && user.isAnonymous) {
      try {
        final result = await user.linkWithCredential(credential);
        return result.user;
      } on FirebaseAuthException catch (e) {
        // Wenn Account bereits existiert → einfach einloggen
        if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
          final result = await _auth.signInWithCredential(credential);
          return result.user;
        }
        rethrow;
      }
    } else {
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    }
  }

  /// Aus Google-Account ausloggen → wieder anonym.
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    await ensureSignedIn();  // wieder anonym
  }
}
