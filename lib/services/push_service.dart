import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
  });

  factory PushService.production() {
    return PushService(
      messaging: const FirebasePushMessagingClient(),
      auth: const FirebasePushAuthClient(),
      tokens: const FirestorePushTokenRepository(),
      showNotification: ({required String title, required String body}) {
        return NotificationService.showNow(title: title, body: body);
      },
    );
  }

  final PushMessagingClient messaging;
  final PushAuthClient auth;
  final PushTokenRepository tokens;
  final ShowPushNotification showNotification;

  bool _ready = false;
  Future<bool>? _enableInFlight;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<PushNotification>? _messageSubscription;

  bool get isReady => _ready;

  /// Requests notification permission first, then enables FCM auto-init.
  /// A failed attempt leaves the service retryable.
  Future<bool> enable() async {
    if (!messaging.isSupported) {
      return false;
    }
    if (_ready) {
      return true;
    }
    final inFlight = _enableInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final attempt = _enableOnce();
    _enableInFlight = attempt;
    try {
      return await attempt;
    } finally {
      if (identical(_enableInFlight, attempt)) {
        _enableInFlight = null;
      }
    }
  }

  Future<bool> _enableOnce() async {
    try {
      final permission = await messaging.requestPermission();
      if (permission == PushPermissionStatus.denied) {
        await messaging.setAutoInitEnabled(false);
        return false;
      }

      await messaging.setAutoInitEnabled(true);
      final token = await messaging.getToken();
      if (token != null) {
        await _persistTokenForCurrentUser(token);
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
      debugPrint('PushService: enable skipped — $error');
      return false;
    }
  }

  /// Removes the current token from its user, disables auto-init, deletes the
  /// FCM token, and cancels all stream ownership.
  Future<void> disable() async {
    _ready = false;
    await _cancelSubscriptions();

    String? token;
    try {
      token = await messaging.getToken();
    } catch (error) {
      debugPrint('PushService: token lookup during disable skipped — $error');
    }

    final uid = auth.currentUid;
    if (uid != null && token != null) {
      try {
        await tokens.removeToken(uid, token);
      } catch (error) {
        debugPrint('PushService: token removal skipped — $error');
      }
    }

    try {
      await messaging.deleteToken();
    } catch (error) {
      debugPrint('PushService: token deletion skipped — $error');
    }
    try {
      await messaging.setAutoInitEnabled(false);
    } catch (error) {
      debugPrint('PushService: auto-init disable skipped — $error');
    }
  }

  @override
  Future<void> removeTokenFrom(String uid) async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await tokens.removeToken(uid, token);
      }
    } catch (error) {
      debugPrint('PushService: old-user token removal skipped — $error');
    }
  }

  @override
  Future<void> bindCurrentUser() async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _persistTokenForCurrentUser(token);
      }
    } catch (error) {
      debugPrint('PushService: current-user token binding skipped — $error');
    }
  }

  Future<void> _persistTokenForCurrentUser(String token) async {
    final uid = auth.currentUid;
    if (uid == null) {
      return;
    }
    await tokens.addToken(uid, token);
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
}

/// Wraps an auth transition so the token never remains owned by the old UID.
class PushOwnershipTransitionCoordinator {
  const PushOwnershipTransitionCoordinator({
    required this.push,
    required this.notificationsEnabled,
  });

  final PushTokenOwner push;
  final bool Function() notificationsEnabled;

  Future<T> run<T>({
    required String oldUid,
    required Future<T> Function() transition,
  }) async {
    if (!notificationsEnabled()) {
      return transition();
    }

    await push.removeTokenFrom(oldUid);
    try {
      return await transition();
    } finally {
      await push.bindCurrentUser();
    }
  }
}

final PushService pushService = PushService.production();
