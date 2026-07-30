import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'account/account_operation_client.dart';
import 'account/account_transition_journal.dart';
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
  String createRequestKey();
  Future<AccountDeletionJournal?> readDeletionJournal();
  Future<void> writeDeletionJournal(AccountDeletionJournal journal);
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  );
  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  );
  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  );
}

abstract interface class AccountDeletionJournalStore {
  Future<AccountDeletionJournal?> read();
  Future<void> write(AccountDeletionJournal journal);
}

@immutable
class AccountDeletionJournal {
  const AccountDeletionJournal({
    required this.version,
    required this.session,
    required this.requestKey,
    this.operation,
  });

  factory AccountDeletionJournal.pending({
    required CloudWriteSession session,
    required String requestKey,
  }) {
    return AccountDeletionJournal(
      version: currentVersion,
      session: session,
      requestKey: requestKey,
    );
  }

  factory AccountDeletionJournal.fromJson(Map<String, Object?> json) {
    try {
      final version = json['version'];
      final requestKey = json['requestKey'];
      final rawSession = json['session'];
      final rawOperation = json['operation'];
      if (version is! int ||
          version != currentVersion ||
          requestKey is! String ||
          requestKey.trim().isEmpty ||
          rawSession is! Map) {
        throw const FormatException();
      }
      final session = AccountTransitionJournal.fromJson(
        rawSession.map((key, value) => MapEntry(key.toString(), value)),
      ).session;
      final operation = rawOperation == null
          ? null
          : AccountOperationResult.fromJson(
              (rawOperation as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            );
      if (operation != null &&
          operation.kind != AccountOperationKind.deletion) {
        throw const FormatException();
      }
      return AccountDeletionJournal(
        version: version,
        session: session,
        requestKey: requestKey,
        operation: operation,
      );
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  static const currentVersion = 1;

  final int version;
  final CloudWriteSession session;
  final String requestKey;
  final AccountOperationResult? operation;

  String? get operationId => operation?.operationId;

  AccountDeletionJournal copyWith({
    CloudWriteSession? session,
    AccountOperationResult? operation,
  }) {
    return AccountDeletionJournal(
      version: version,
      session: session ?? this.session,
      requestKey: requestKey,
      operation: operation ?? this.operation,
    );
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'session': AccountTransitionJournal.fromSession(session).toJson(),
    'requestKey': requestKey,
    'operation': operation?.toJson(),
  };
}

/// Retained for the local cleanup workflow's existing recovery contract.
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
    required this.sessions,
    this.pollDelay = _defaultAccountOperationPollDelay,
    this.maxPolls = 30,
  }) : assert(maxPolls > 0);

  final AccountDeletionOperations operations;
  final PushOwnershipTransitionCoordinator ownershipTransitions;
  final CloudWriteSessionController sessions;
  final Future<void> Function(Duration duration) pollDelay;
  final int maxPolls;

  Future<void> deleteAccount() async {
    final existing = await operations.readDeletionJournal();
    if (existing != null) {
      await resumePendingDeletion(journal: existing);
      return;
    }

    final providers = operations.providerState;
    String? appleAuthorizationCode;
    if (providers.isAppleLinked) {
      appleAuthorizationCode = _requireAppleAuthorizationCode(
        await operations.reauthenticateWithApple(),
      );
    } else if (providers.isGoogleLinked) {
      await operations.reauthenticateWithGoogle();
    }

    AccountDeletionJournal? journal;
    try {
      await ownershipTransitions.run(
        oldUid: operations.userId,
        transition: () async {
          final quiesced = sessions.current;
          if (quiesced == null ||
              quiesced.uid != operations.userId ||
              quiesced.mode != CloudWriteMode.quiesced) {
            throw const AccountOperationFailure(
              AccountOperationFailureCode.blocked,
              retryable: false,
            );
          }
          journal = AccountDeletionJournal.pending(
            session: quiesced,
            requestKey: operations.createRequestKey(),
          );
          await operations.writeDeletionJournal(journal!);
          final requested = await operations.requestAccountDeletion(
            AccountDeletionRequest(requestKey: journal!.requestKey),
          );
          _requireDeletionOperation(requested);
          journal = journal!.copyWith(operation: requested);
          await operations.writeDeletionJournal(journal!);
          journal = await _pollToTerminal(
            journal!,
            appleAuthorizationCode: appleAuthorizationCode,
          );
        },
      );
    } catch (_) {
      if (journal != null && sessions.current != null) {
        await operations.writeDeletionJournal(
          journal!.copyWith(session: sessions.current),
        );
      }
      rethrow;
    }
    if (journal != null && sessions.current != null) {
      await operations.writeDeletionJournal(
        journal!.copyWith(session: sessions.current),
      );
    }
  }

  Future<void> resumePendingDeletion({AccountDeletionJournal? journal}) async {
    final pending = journal ?? await operations.readDeletionJournal();
    if (pending == null) {
      return;
    }
    if (pending.session.uid != operations.userId) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.permissionDenied,
        retryable: false,
      );
    }
    if (pending.operation == null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.unknown,
        retryable: false,
      );
    }
    final completed = await _pollToTerminal(pending);
    final current = sessions.current;
    if (completed.operation?.phase == AccountOperationPhase.completed &&
        current != null &&
        current.mode != CloudWriteMode.cleanupPending) {
      sessions.transition(CloudWriteMode.cleanupPending);
    }
    await operations.writeDeletionJournal(
      completed.copyWith(session: sessions.current ?? completed.session),
    );
  }

  Future<AccountDeletionJournal> _pollToTerminal(
    AccountDeletionJournal initial, {
    String? appleAuthorizationCode,
  }) async {
    var journal = initial;
    var result = journal.operation!;
    for (var poll = 0; poll < maxPolls; poll += 1) {
      _requireDeletionOperation(result);
      if (result.phase == AccountOperationPhase.completed) {
        return journal;
      }
      if (result.phase == AccountOperationPhase.blocked) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        );
      }
      if (result.phase == AccountOperationPhase.appleRevocationPending) {
        final code =
            appleAuthorizationCode ??
            _requireAppleAuthorizationCode(
              await operations.reauthenticateWithApple(),
            );
        appleAuthorizationCode = null;
        result = await operations.completeAppleRevocation(
          AppleRevocationCompletionRequest(
            operationId: result.operationId,
            expectedVersion: result.version,
            authorizationCode: code,
          ),
        );
      } else {
        await pollDelay(const Duration(seconds: 2));
        result = await operations.getAccountOperation(
          AccountOperationStatusRequest(operationId: result.operationId),
        );
      }
      journal = journal.copyWith(operation: result);
      await operations.writeDeletionJournal(journal);
    }
    throw const AccountOperationFailure(
      AccountOperationFailureCode.unavailable,
      retryable: true,
    );
  }

  void _requireDeletionOperation(AccountOperationResult result) {
    if (result.kind != AccountOperationKind.deletion) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
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

Future<void> _defaultAccountOperationPollDelay(Duration duration) {
  return Future<void>.delayed(duration);
}

class _FirebaseAccountDeletionOperations implements AccountDeletionOperations {
  const _FirebaseAccountDeletionOperations({
    required this.user,
    required this.client,
    required this.journalStore,
  });

  final User user;
  final AccountOperationGateway client;
  final AccountDeletionJournalStore journalStore;

  @override
  String get userId => user.uid;

  @override
  AuthProviderState get providerState => AuthProviderState.fromProviderIds(
    user.providerData.map((provider) => provider.providerId),
  );

  @override
  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  ) {
    return client.completeAppleRevocation(request);
  }

  @override
  String createRequestKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  @override
  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  ) {
    return client.getAccountOperation(request);
  }

  @override
  Future<AccountDeletionJournal?> readDeletionJournal() {
    return journalStore.read();
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
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  ) {
    return client.requestAccountDeletion(request);
  }

  @override
  Future<void> writeDeletionJournal(AccountDeletionJournal journal) {
    return journalStore.write(journal);
  }
}

class _SharedPreferencesAccountDeletionJournalStore
    implements AccountDeletionJournalStore {
  const _SharedPreferencesAccountDeletionJournalStore();

  static const _key = 'kl_account_deletion_journal_v1';

  @override
  Future<AccountDeletionJournal?> read() async {
    final encoded = (await SharedPreferences.getInstance()).getString(_key);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const FormatException();
      }
      return AccountDeletionJournal.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  @override
  Future<void> write(AccountDeletionJournal journal) async {
    final preferences = await SharedPreferences.getInstance();
    final wrote = await preferences.setString(
      _key,
      jsonEncode(journal.toJson()),
    );
    if (!wrote) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.unavailable,
        retryable: true,
      );
    }
  }
}

abstract interface class UserDataDeletionStore {
  Future<void> deleteSubcollection(String name);
  Future<void> removeUserFields(Set<String> fields);
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
}

class _FirestoreUserDataDeletionStore implements UserDataDeletionStore {
  const _FirestoreUserDataDeletionStore(this.db, this.uid);

  final FirebaseFirestore db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      db.collection('users').doc(uid);

  @override
  Future<void> deleteSubcollection(String name) {
    return AuthService._deleteCollection(_userRef.collection(name));
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
  static const AccountDeletionJournalStore _accountDeletionJournalStore =
      _SharedPreferencesAccountDeletionJournalStore();

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
  }

  static void synchronizeReadyCloudWriteSession(String uid) {
    CloudWriteSessionSynchronizer(
      cloudWriteSessionController,
    ).synchronizeReady(uid);
  }

  static User? _activateSignedInUser(User? user) {
    final uid = user?.uid;
    if (uid != null) {
      synchronizeReadyCloudWriteSession(uid);
    }
    return user;
  }

  /// Restores durable fencing only after [expectedUid] has been obtained from
  /// the live Firebase Auth user. Journal metadata never supplies that value.
  static Future<CloudWriteSession?> restoreCloudWriteSession(
    String expectedUid,
  ) async {
    final liveUid = current?.uid;
    if (liveUid == null || liveUid != expectedUid) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.permissionDenied,
        retryable: false,
      );
    }
    final journal = await _accountDeletionJournalStore.read();
    if (journal == null) {
      return null;
    }
    final currentSession = cloudWriteSessionController.current;
    if (currentSession == journal.session) {
      return currentSession;
    }
    if (currentSession != null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    return cloudWriteSessionController.resume(
      journal.session,
      expectedUid: expectedUid,
    );
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

  /// Requests server-owned account deletion and polls its authoritative state.
  ///
  /// Caller clears local device data only after this completes.
  static Future<void> deleteAccount() async {
    final user = current;
    if (user == null) {
      throw StateError('The Firebase account is unavailable.');
    }

    await AccountDeletionCoordinator(
      operations: _FirebaseAccountDeletionOperations(
        user: user,
        client: AccountOperationClient.firebase(),
        journalStore: _accountDeletionJournalStore,
      ),
      ownershipTransitions: _pushOwnershipTransitions,
      sessions: cloudWriteSessionController,
    ).deleteAccount();
  }

  /// Continues the exact durable server operation restored at startup.
  static Future<void> resumePendingAccountDeletion() async {
    final user = current;
    if (user == null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.authenticationRequired,
        retryable: false,
      );
    }
    await AccountDeletionCoordinator(
      operations: _FirebaseAccountDeletionOperations(
        user: user,
        client: AccountOperationClient.firebase(),
        journalStore: _accountDeletionJournalStore,
      ),
      ownershipTransitions: _pushOwnershipTransitions,
      sessions: cloudWriteSessionController,
    ).resumePendingDeletion();
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
