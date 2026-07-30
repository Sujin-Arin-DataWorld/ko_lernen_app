import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'account/cloud_write_session.dart';
import 'notification_service.dart';

enum PushPermissionStatus { authorized, provisional, denied }

class PushNotification {
  const PushNotification({required this.title, required this.body});

  final String title;
  final String body;
}

abstract interface class PushMessagingClient {
  bool get isSupported;
  Stream<String> get tokenRefreshes;
  Stream<PushNotification> get messages;

  Future<PushPermissionStatus> requestPermission();
  Future<void> setAutoInitEnabled(bool enabled);
  Future<String?> getToken();
  Future<void> deleteToken();
}

abstract interface class PushAuthClient {
  String? get currentUid;
}

abstract interface class PushTokenRepository {
  Future<void> addToken(String uid, String token);
  Future<void> removeToken(String uid, String token);
}

abstract interface class PushTokenOwner {
  Future<void> removeTokenFrom(String uid);
  Future<void> bindCurrentUser();
}

class PushCleanupException implements Exception {
  const PushCleanupException(this.causes);

  final List<Object> causes;

  @override
  String toString() => 'Push cleanup failed in ${causes.length} step(s).';
}

/// Both the auth transition and its required push rebind failed. The original
/// errors and stack traces remain available so callers can retain both causes.
class PushOwnershipTransitionException implements Exception {
  const PushOwnershipTransitionException({
    required this.transitionError,
    required this.transitionStackTrace,
    required this.rebindError,
    required this.rebindStackTrace,
  });

  final Object transitionError;
  final StackTrace transitionStackTrace;
  final Object rebindError;
  final StackTrace rebindStackTrace;

  List<Object> get causes => <Object>[transitionError, rebindError];

  @override
  String toString() =>
      'The identity transition and push rebind both failed: '
      '$transitionError; $rebindError';
}

/// The server authoritatively rejected the operation before creating a marker.
///
/// This is the only failure that permits restoring the source push binding.
class ServerConfirmedPreMarkerRejection implements Exception {
  const ServerConfirmedPreMarkerRejection(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A server accepted the operation, so source ownership stays frozen for
/// inspection/resume even though the request call itself completed normally.
class ServerAcceptedOwnershipFreeze {
  const ServerAcceptedOwnershipFreeze();
}

typedef ShowPushNotification =
    Future<void> Function({required String title, required String body});

class FirebasePushMessagingClient implements PushMessagingClient {
  const FirebasePushMessagingClient();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  bool get isSupported => !kIsWeb;

  @override
  Stream<PushNotification> get messages {
    return FirebaseMessaging.onMessage
        .where((message) => message.notification != null)
        .map(
          (message) => PushNotification(
            title: message.notification?.title ?? 'Hangul Sori',
            body: message.notification?.body ?? '',
          ),
        );
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<void> deleteToken() {
    return _messaging.deleteToken();
  }

  @override
  Future<String?> getToken() {
    return _messaging.getToken();
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    final settings = await _messaging.requestPermission();
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return PushPermissionStatus.authorized;
      case AuthorizationStatus.provisional:
        return PushPermissionStatus.provisional;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.notDetermined:
        return PushPermissionStatus.denied;
    }
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) {
    return _messaging.setAutoInitEnabled(enabled);
  }
}

class FirebasePushAuthClient implements PushAuthClient {
  const FirebasePushAuthClient();

  @override
  String? get currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
}

class FirestorePushTokenRepository implements PushTokenRepository {
  const FirestorePushTokenRepository();

  @override
  Future<void> addToken(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeToken(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }
}

/// FCM registration lifecycle. Local reminder scheduling intentionally remains
/// in [NotificationService] and does not depend on this optional cloud path.
class PushService implements PushTokenOwner {
  PushService({
    required this.messaging,
    required this.auth,
    required this.tokens,
    required this.showNotification,
    required this.sessions,
  });

  factory PushService.production() {
    return PushService(
      messaging: const FirebasePushMessagingClient(),
      auth: const FirebasePushAuthClient(),
      tokens: const FirestorePushTokenRepository(),
      sessions: cloudWriteSessionController,
      showNotification: ({required String title, required String body}) {
        return NotificationService.showNow(title: title, body: body);
      },
    );
  }

  final PushMessagingClient messaging;
  final PushAuthClient auth;
  final PushTokenRepository tokens;
  final ShowPushNotification showNotification;
  final CloudWriteSessionController sessions;

  bool _ready = false;
  bool _desiredEnabled = false;
  Future<void> _lifecycleTail = Future<void>.value();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<PushNotification>? _messageSubscription;

  bool get isReady => _ready;

  /// Requests notification permission first, then enables FCM auto-init.
  /// A failed attempt leaves the service retryable.
  Future<bool> enable() {
    if (!messaging.isSupported) {
      return Future<bool>.value(false);
    }
    _desiredEnabled = true;
    return _enqueueLifecycle(() async {
      if (!_desiredEnabled) {
        return false;
      }
      if (_ready) {
        return true;
      }
      return _enableOnce();
    });
  }

  Future<bool> _enableOnce() async {
    try {
      final permission = await messaging.requestPermission();
      if (!_desiredEnabled) {
        return false;
      }
      if (permission == PushPermissionStatus.denied) {
        await messaging.setAutoInitEnabled(false);
        return false;
      }

      await messaging.setAutoInitEnabled(true);
      if (!_desiredEnabled) {
        await _quiesceRuntime();
        return false;
      }
      final token = await messaging.getToken();
      if (!_desiredEnabled) {
        await _quiesceRuntime();
        return false;
      }
      if (token != null) {
        await _persistTokenForCurrentUser(token);
      }
      if (!_desiredEnabled) {
        await _quiesceRuntime();
        return false;
      }

      _tokenRefreshSubscription = messaging.tokenRefreshes.listen(
        (refreshedToken) {
          unawaited(_persistRefreshedToken(refreshedToken));
        },
        onError: (Object error) {
          debugPrint('PushService: token refresh skipped — $error');
        },
      );
      _messageSubscription = messaging.messages.listen(
        (message) {
          unawaited(_showForegroundNotification(message));
        },
        onError: (Object error) {
          debugPrint('PushService: foreground message skipped — $error');
        },
      );
      _ready = true;
      return true;
    } catch (error) {
      _ready = false;
      await _quiesceRuntime();
      debugPrint('PushService: enable skipped — $error');
      return false;
    }
  }

  /// Removes the current token from its user, disables auto-init, deletes the
  /// FCM token, and cancels all stream ownership.
  Future<void> disable() {
    _desiredEnabled = false;
    return _enqueueLifecycle(() => _disable(strict: false));
  }

  /// Account-deletion variant that attempts every independent cleanup step and
  /// reports all failures after the attempts finish.
  Future<void> disableStrict() {
    _desiredEnabled = false;
    return _enqueueLifecycle(() => _disable(strict: true));
  }

  Future<void> _disable({required bool strict}) async {
    _ready = false;
    final failures = <Object>[];
    await _cancelSubscriptionsForCleanup(strict: strict, failures: failures);

    if (!messaging.isSupported) {
      _throwStrictCleanupFailures(strict, failures);
      return;
    }

    await _attemptCleanup(
      label: 'auto-init disable',
      strict: strict,
      failures: failures,
      operation: () => messaging.setAutoInitEnabled(false),
    );

    String? token;
    try {
      token = await messaging.getToken();
    } catch (error) {
      _recordCleanupFailure(
        label: 'token lookup during disable',
        error: error,
        strict: strict,
        failures: failures,
      );
    }

    final uid = auth.currentUid;
    if (token != null) {
      if (uid == null) {
        _recordCleanupFailure(
          label: 'token owner lookup',
          error: StateError('Cannot remove a push token without a user ID.'),
          strict: strict,
          failures: failures,
        );
      } else {
        await _attemptCleanup(
          label: 'token removal',
          strict: strict,
          failures: failures,
          operation: () => _removeToken(uid, token!),
        );
      }
    }

    await _attemptCleanup(
      label: 'token deletion',
      strict: strict,
      failures: failures,
      operation: messaging.deleteToken,
    );
    _throwStrictCleanupFailures(strict, failures);
  }

  @override
  Future<void> removeTokenFrom(String uid) {
    if (!messaging.isSupported) {
      return Future<void>.value();
    }
    _desiredEnabled = false;
    return _enqueueLifecycle(() => _invalidateTokenForIdentityTransition(uid));
  }

  Future<void> _invalidateTokenForIdentityTransition(String uid) async {
    _ready = false;
    await _cancelSubscriptions();

    String? token;
    try {
      token = await messaging.getToken();
    } catch (error) {
      debugPrint('PushService: old-user token lookup skipped — $error');
    }

    Object? autoInitError;
    StackTrace? autoInitStack;
    try {
      await messaging.setAutoInitEnabled(false);
    } catch (error, stack) {
      autoInitError = error;
      autoInitStack = stack;
    }

    Object? deletionError;
    StackTrace? deletionStack;
    try {
      await messaging.deleteToken();
    } catch (error, stack) {
      deletionError = error;
      deletionStack = stack;
    }

    if (autoInitError != null) {
      Error.throwWithStackTrace(autoInitError, autoInitStack!);
    }
    if (deletionError != null) {
      Error.throwWithStackTrace(deletionError, deletionStack!);
    }

    // The local token is now definitively invalid. Remote cleanup can be
    // best-effort without leaving a deliverable token attached to the old UID.
    if (token != null) {
      try {
        await _removeToken(uid, token);
      } catch (error) {
        debugPrint(
          'PushService: stale old-user token cleanup skipped — $error',
        );
      }
    }
  }

  @override
  Future<void> bindCurrentUser() async {
    if (!messaging.isSupported) {
      return;
    }
    if (auth.currentUid == null) {
      throw StateError('Cannot bind push notifications without a user ID.');
    }
    await enable();
    if (auth.currentUid == null) {
      _ready = false;
      throw StateError('Push notification identity disappeared during bind.');
    }
  }

  Future<void> _persistTokenForCurrentUser(String token) async {
    final uid = auth.currentUid;
    if (uid == null) {
      throw StateError('Cannot persist a push token without a user ID.');
    }
    final result = await CloudWriteFence(
      sessions,
    ).run(uid: uid, action: () => tokens.addToken(uid, token));
    if (result != CloudWriteResult.completed) {
      return;
    }
  }

  Future<void> _removeToken(String uid, String token) async {
    await CloudWriteFence(
      sessions,
    ).run(uid: uid, action: () => tokens.removeToken(uid, token));
  }

  Future<void> _persistRefreshedToken(String token) async {
    try {
      await _persistTokenForCurrentUser(token);
    } catch (error) {
      debugPrint('PushService: refreshed token persist skipped — $error');
    }
  }

  Future<void> _showForegroundNotification(PushNotification message) async {
    try {
      await showNotification(title: message.title, body: message.body);
    } catch (error) {
      debugPrint('PushService: local notification skipped — $error');
    }
  }

  Future<void> _cancelSubscriptions() async {
    final tokenSubscription = _tokenRefreshSubscription;
    final messageSubscription = _messageSubscription;
    _tokenRefreshSubscription = null;
    _messageSubscription = null;
    if (tokenSubscription != null) {
      await tokenSubscription.cancel();
    }
    if (messageSubscription != null) {
      await messageSubscription.cancel();
    }
  }

  Future<void> _cancelSubscriptionsForCleanup({
    required bool strict,
    required List<Object> failures,
  }) async {
    final tokenSubscription = _tokenRefreshSubscription;
    final messageSubscription = _messageSubscription;
    _tokenRefreshSubscription = null;
    _messageSubscription = null;
    if (tokenSubscription != null) {
      await _attemptCleanup(
        label: 'token refresh subscription cancellation',
        strict: strict,
        failures: failures,
        operation: tokenSubscription.cancel,
      );
    }
    if (messageSubscription != null) {
      await _attemptCleanup(
        label: 'message subscription cancellation',
        strict: strict,
        failures: failures,
        operation: messageSubscription.cancel,
      );
    }
  }

  Future<void> _attemptCleanup({
    required String label,
    required bool strict,
    required List<Object> failures,
    required Future<void> Function() operation,
  }) async {
    try {
      await operation();
    } catch (error) {
      _recordCleanupFailure(
        label: label,
        error: error,
        strict: strict,
        failures: failures,
      );
    }
  }

  void _recordCleanupFailure({
    required String label,
    required Object error,
    required bool strict,
    required List<Object> failures,
  }) {
    if (strict) {
      failures.add(error);
    } else {
      debugPrint('PushService: $label skipped — $error');
    }
  }

  void _throwStrictCleanupFailures(bool strict, List<Object> failures) {
    if (strict && failures.isNotEmpty) {
      throw PushCleanupException(List.unmodifiable(failures));
    }
  }

  Future<void> _quiesceRuntime() async {
    _ready = false;
    await _cancelSubscriptions();
    try {
      await messaging.setAutoInitEnabled(false);
    } catch (error) {
      debugPrint('PushService: stale enable cleanup skipped — $error');
    }
  }

  Future<T> _enqueueLifecycle<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _lifecycleTail = _lifecycleTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}

/// Wraps an auth transition so the token never remains owned by the old UID.
class PushOwnershipTransitionCoordinator {
  const PushOwnershipTransitionCoordinator({
    required this.push,
    required this.notificationsEnabled,
    required this.sessions,
  });

  final PushTokenOwner push;
  final bool Function() notificationsEnabled;
  final CloudWriteSessionController sessions;

  Future<CloudWriteResult> run<T>({
    required String oldUid,
    required Future<T> Function() transition,
  }) async {
    final fence = CloudWriteFence(sessions);
    final snapshot = fence.readySnapshot(oldUid);
    if (snapshot == null) {
      return CloudWriteResult.blocked;
    }
    final removal = await fence.run(
      uid: oldUid,
      action: () => push.removeTokenFrom(oldUid),
    );
    if (removal != CloudWriteResult.completed) {
      return removal;
    }
    final quiescedSession = sessions.transition(CloudWriteMode.quiesced);
    Object? transitionError;
    StackTrace? transitionStackTrace;
    try {
      await transition();
    } catch (error, stackTrace) {
      transitionError = error;
      transitionStackTrace = stackTrace;
    }

    final mayRestoreSource =
        transitionError is ServerConfirmedPreMarkerRejection;
    final acceptedAndFrozen = transitionError == null;
    final transitionStillOwned = sessions.current == quiescedSession;
    if (transitionStillOwned) {
      if (acceptedAndFrozen) {
        sessions.transition(CloudWriteMode.cleanupPending);
      } else if (mayRestoreSource) {
        sessions.transition(CloudWriteMode.ready);
      } else if (!mayRestoreSource) {
        sessions.transition(CloudWriteMode.blocked);
      }
    }
    var sessionResult = !transitionStillOwned
        ? CloudWriteResult.stale
        : acceptedAndFrozen
        ? CloudWriteResult.completed
        : CloudWriteResult.blocked;
    if (notificationsEnabled() &&
        transitionStillOwned &&
        mayRestoreSource &&
        sessions.current?.uid == oldUid &&
        sessions.current?.mode == CloudWriteMode.ready) {
      try {
        await push.bindCurrentUser();
        final current = sessions.current;
        sessionResult =
            current?.uid == oldUid && current?.mode == CloudWriteMode.ready
            ? CloudWriteResult.completed
            : CloudWriteResult.stale;
      } catch (rebindError, rebindStackTrace) {
        throw PushOwnershipTransitionException(
          transitionError: transitionError,
          transitionStackTrace: transitionStackTrace!,
          rebindError: rebindError,
          rebindStackTrace: rebindStackTrace,
        );
      }
    }

    if (transitionError != null) {
      Error.throwWithStackTrace(transitionError, transitionStackTrace!);
    }
    return sessionResult;
  }
}

final PushService pushService = PushService.production();
