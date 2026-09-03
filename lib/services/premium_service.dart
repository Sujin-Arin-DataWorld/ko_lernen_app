import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/access_snapshot.dart';
import 'access_snapshot_controller.dart';
import 'account/cloud_write_session.dart';
import 'storage_service.dart';

/// Legacy-named content notifier for lock badges. Membership and AI policy use
/// [accessSnapshotNotifier], never this build-aware content flag.
final ValueNotifier<bool> premiumNotifier = ValueNotifier<bool>(
  PremiumService.fullAccessBuild,
);

final ValueNotifier<AccessSnapshot?> accessSnapshotNotifier = ValueNotifier(
  null,
);

enum PremiumPurchaseOutcome {
  purchased,
  cancelled,
  pending,
  signInRequired,
  stale,
  failed,
}

enum PremiumRestoreOutcome {
  restored,
  none,
  pending,
  cancelled,
  signInRequired,
  stale,
  failed,
}

PremiumPurchaseOutcome premiumPurchaseOutcomeForError(Object error) {
  if (error is PlatformException &&
      PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
    return PremiumPurchaseOutcome.cancelled;
  }
  if (error is PlatformException &&
      PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.paymentPendingError) {
    return PremiumPurchaseOutcome.pending;
  }
  return PremiumPurchaseOutcome.failed;
}

abstract interface class RevenueCatIdentityClient {
  Future<void> logIn(String uid);
  Future<void> logOut();
}

class PurchasesIdentityClient implements RevenueCatIdentityClient {
  const PurchasesIdentityClient();

  @override
  Future<void> logIn(String uid) async {
    await Purchases.logIn(uid);
  }

  @override
  Future<void> logOut() async {
    await Purchases.logOut();
  }
}

/// Serializes Firebase identity changes into RevenueCat identity changes.
/// Binding state advances only after RevenueCat confirms the transition.
class PremiumIdentityBinder {
  PremiumIdentityBinder(
    this.client, {
    required this.sessions,
    String? initialUid,
    this.identityMatches,
  }) : _boundUid = initialUid;

  final RevenueCatIdentityClient client;
  final CloudWriteSessionController sessions;
  final Future<bool> Function(String uid)? identityMatches;
  Future<void> _queue = Future<void>.value();
  bool _bindingUncertain = false;
  String? _boundUid;
  StreamSubscription<void>? _subscription;
  String? _pendingUid;
  bool _hasPendingUid = false;
  VoidCallback? _sessionListener;

  String? get boundUid => _boundUid;

  void start(Stream<String?> userIds, {void Function(Object error)? onError}) {
    if (_subscription != null) {
      return;
    }
    _subscription = userIds
        .asyncMap((uid) async {
          _pendingUid = uid;
          _hasPendingUid = true;
          try {
            final result = await bind(uid);
            if (result == CloudWriteResult.completed && uid == _pendingUid) {
              _hasPendingUid = false;
            }
          } catch (error) {
            onError?.call(error);
            debugPrint('PremiumService: identity binding failed.');
          }
        })
        .listen((_) {});
    _sessionListener = () {
      if (_hasPendingUid) {
        unawaited(_retryPending(onError));
      }
    };
    sessions.changes.addListener(_sessionListener!);
  }

  Future<void> _retryPending(void Function(Object error)? onError) async {
    final uid = _pendingUid;
    try {
      final result = await bind(uid);
      if (result == CloudWriteResult.completed && uid == _pendingUid) {
        _hasPendingUid = false;
      }
    } catch (error) {
      onError?.call(error);
      debugPrint('PremiumService: identity retry failed.');
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<CloudWriteResult> bind(String? uid) {
    final expected = sessions.current;
    return _serialized(() async {
      if (sessions.current != expected) {
        return CloudWriteResult.stale;
      }
      return _bind(uid);
    });
  }

  /// The SDK identity cannot change during an in-flight store operation. Any
  /// Firebase transition still invalidates its result immediately.
  Future<T?> runBound<T>({
    required String uid,
    required Future<T> Function() action,
  }) {
    final expected = sessions.current;
    return _serialized(() async {
      final fence = CloudWriteFence(sessions);
      if (expected == null ||
          fence.verify(expected, uid: uid) != CloudWriteResult.completed ||
          await _bind(uid) != CloudWriteResult.completed) {
        return null;
      }
      if (fence.verify(expected, uid: uid) != CloudWriteResult.completed) {
        return null;
      }
      final result = await action();
      if (fence.verify(expected, uid: uid) != CloudWriteResult.completed) {
        return null;
      }
      return result;
    });
  }

  Future<CloudWriteResult> _bind(String? uid) async {
    final operationUid = uid ?? _boundUid;
    if (operationUid == null) {
      return CloudWriteResult.completed;
    }
    final fence = CloudWriteFence(sessions);
    final expected = fence.readySnapshot(operationUid);
    if (expected == null) {
      return CloudWriteResult.blocked;
    }
    if (uid == _boundUid && !_bindingUncertain) {
      if (uid != null &&
          identityMatches != null &&
          !await identityMatches!(uid)) {
        _bindingUncertain = true;
      } else {
        return fence.verify(expected, uid: operationUid);
      }
    }
    if (fence.verify(expected, uid: operationUid) !=
        CloudWriteResult.completed) {
      return CloudWriteResult.stale;
    }
    if (_boundUid == null) {
      return CloudWriteResult.blocked;
    }

    if (uid != null) {
      final loginResult = await fence.runWithSnapshot(
        snapshot: expected,
        uid: uid,
        action: () => client.logIn(uid),
      );
      if (loginResult != CloudWriteResult.completed) {
        _bindingUncertain = true;
        return loginResult;
      }
      if (identityMatches != null && !await identityMatches!(uid)) {
        _bindingUncertain = true;
        return CloudWriteResult.blocked;
      }
      if (fence.verify(expected, uid: uid) != CloudWriteResult.completed) {
        _bindingUncertain = true;
        return CloudWriteResult.stale;
      }
      _boundUid = uid;
      _bindingUncertain = false;
      return CloudWriteResult.completed;
    }
    return CloudWriteResult.blocked;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    final listener = _sessionListener;
    if (listener != null) {
      sessions.changes.removeListener(listener);
      _sessionListener = null;
    }
  }
}

PurchasesConfiguration revenueCatConfiguration({
  required String apiKey,
  required String appUserId,
}) {
  final uid = appUserId.trim();
  if (uid.isEmpty) {
    throw ArgumentError.value(appUserId, 'appUserId', 'must not be empty');
  }
  return PurchasesConfiguration(apiKey)..appUserID = uid;
}

/// A store request never grants access itself: only the server snapshot does.
class PremiumPurchaseController {
  PremiumPurchaseController({
    required this.sessions,
    required this.binder,
    required this.identity,
    required this.enabled,
    required this.hasPremium,
    required this.refreshAccess,
    required this.purchasePackage,
    required this.restorePurchases,
  });
  final CloudWriteSessionController sessions;
  final PremiumIdentityBinder binder;
  final ({String? uid, bool isAnonymous}) Function() identity;
  final bool Function() enabled;
  final bool Function() hasPremium;
  final Future<void> Function() refreshAccess;
  final Future<bool> Function(Package) purchasePackage;
  final Future<bool> Function() restorePurchases;
  bool _busy = false;

  bool _matches(String uid, CloudWriteSession? session) =>
      identity().uid == uid &&
      !identity().isAnonymous &&
      session != null &&
      sessions.current == session &&
      session.mode == CloudWriteMode.ready;

  Future<PremiumPurchaseOutcome> purchase(Package package) async {
    final user = identity();
    final uid = user.uid;
    final session = sessions.current;
    if (uid == null || user.isAnonymous) {
      return PremiumPurchaseOutcome.signInRequired;
    }
    if (!enabled() || _busy || !isMonthlyPackage(package)) {
      return PremiumPurchaseOutcome.failed;
    }
    if (hasPremium()) {
      return PremiumPurchaseOutcome.purchased;
    }
    _busy = true;
    try {
      final outcome = await binder.runBound<PremiumPurchaseOutcome>(
        uid: uid,
        action: () async {
          if (!_matches(uid, session)) {
            return PremiumPurchaseOutcome.stale;
          }
          await purchasePackage(package);
          if (!_matches(uid, session)) {
            return PremiumPurchaseOutcome.stale;
          }
          await refreshAccess();
          if (!_matches(uid, session)) {
            return PremiumPurchaseOutcome.stale;
          }
          return hasPremium()
              ? PremiumPurchaseOutcome.purchased
              : PremiumPurchaseOutcome.pending;
        },
      );
      return outcome ??
          (_matches(uid, session)
              ? PremiumPurchaseOutcome.failed
              : PremiumPurchaseOutcome.stale);
    } on Object catch (error) {
      return _matches(uid, session)
          ? premiumPurchaseOutcomeForError(error)
          : PremiumPurchaseOutcome.stale;
    } finally {
      _busy = false;
    }
  }

  Future<PremiumRestoreOutcome> restore() async {
    final user = identity();
    final uid = user.uid;
    final session = sessions.current;
    if (uid == null || user.isAnonymous) {
      return PremiumRestoreOutcome.signInRequired;
    }
    if (!enabled() || _busy) {
      return PremiumRestoreOutcome.failed;
    }
    _busy = true;
    try {
      final outcome = await binder.runBound<PremiumRestoreOutcome>(
        uid: uid,
        action: () async {
          if (!_matches(uid, session)) {
            return PremiumRestoreOutcome.stale;
          }
          final sdkActive = await restorePurchases();
          if (!_matches(uid, session)) {
            return PremiumRestoreOutcome.stale;
          }
          await refreshAccess();
          if (!_matches(uid, session)) {
            return PremiumRestoreOutcome.stale;
          }
          return hasPremium()
              ? PremiumRestoreOutcome.restored
              : sdkActive
              ? PremiumRestoreOutcome.pending
              : PremiumRestoreOutcome.none;
        },
      );
      return outcome ??
          (_matches(uid, session)
              ? PremiumRestoreOutcome.failed
              : PremiumRestoreOutcome.stale);
    } on Object catch (error) {
      if (!_matches(uid, session)) {
        return PremiumRestoreOutcome.stale;
      }
      return switch (premiumPurchaseOutcomeForError(error)) {
        PremiumPurchaseOutcome.cancelled => PremiumRestoreOutcome.cancelled,
        PremiumPurchaseOutcome.pending => PremiumRestoreOutcome.pending,
        _ => PremiumRestoreOutcome.failed,
      };
    } finally {
      _busy = false;
    }
  }
}

bool isMonthlyPackage(Package package) =>
    package.packageType == PackageType.monthly &&
    package.storeProduct.subscriptionPeriod == 'P1M';

Package? monthlyOfferingPackage(Offering? offering) {
  final monthly = offering?.monthly;
  return monthly != null && isMonthlyPackage(monthly) ? monthly : null;
}

/// Server access is initialized in every build, even when native billing is off.
class PremiumService {
  PremiumService._();

  static const String entitlementId = 'premium';
  static const bool betaUnlockAll = bool.fromEnvironment(
    'BETA_UNLOCK_ALL',
    defaultValue: false,
  );
  static const bool freeLaunch = bool.fromEnvironment(
    'FREE_LAUNCH',
    defaultValue: false,
  );
  static const bool fullAccessBuild = betaUnlockAll || freeLaunch;
  static const String _androidKey = String.fromEnvironment('RC_ANDROID_KEY');
  static const String _iosKey = String.fromEnvironment('RC_IOS_KEY');
  static const String accessEnvironment = String.fromEnvironment(
    'ACCESS_ENVIRONMENT',
    defaultValue: 'PRODUCTION',
  );
  static bool _configured = false;
  static bool _started = false;
  static Future<void>? _billingInit;
  static PremiumIdentityBinder? _identityBinder;
  static AccessSnapshotController? _access;
  static PremiumPurchaseController? _purchases;
  static final Stopwatch _clock = Stopwatch()..start();
  static String? _observedUid;
  static bool? _observedAnonymous;
  static Timer? _expiryTimer;
  static AppLifecycleListener? _lifecycle;

  static ({String? uid, bool isAnonymous}) _identity() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return (uid: user?.uid, isAnonymous: user?.isAnonymous ?? true);
    } on Object {
      return (uid: null, isAnonymous: true);
    }
  }

  static AccessSnapshot? get accessSnapshot {
    final session = cloudWriteSessionController.current;
    if (_identity().uid != session?.uid) {
      return null;
    }
    return _access?.snapshot;
  }

  /// Membership, never inferred from free content or a development override.
  static bool get isPremium => accessSnapshot?.hasPremium ?? false;
  static bool get hasContentAccess =>
      fullAccessBuild ||
      isPremium ||
      (kDebugMode && Storage.devPremiumOverride);
  static bool get isConfigured => _configured;
  static bool get requiresSignIn =>
      _identity().uid == null || _identity().isAnonymous;
  static bool get purchasesEnabled =>
      !freeLaunch && !betaUnlockAll && _configured;

  static Future<void> init() async {
    if (_started) {
      return;
    }
    _started = true;
    // No read of Storage.premiumCached: an unscoped boolean is not authority.
    try {
      final preferences = await SharedPreferences.getInstance();
      _access = AccessSnapshotController(
        sessions: cloudWriteSessionController,
        store: PreferencesAccessSnapshotStore(preferences),
        environment: accessEnvironment,
        fetch: () async {
          final before = _identity().uid;
          final response = await FirebaseFunctions.instanceFor(
            region: 'europe-west3',
          ).httpsCallable('getAccessSnapshot').call();
          if (_identity().uid != before) {
            throw StateError('Stale access response');
          }
          return Map<String, dynamic>.from(response.data as Map);
        },
        wallMillis: () => DateTime.now().millisecondsSinceEpoch,
        elapsedMillis: () => _clock.elapsedMilliseconds,
      )..addListener(_publish);
      _observedUid = _identity().uid;
      _observedAnonymous = _identity().isAnonymous;
      cloudWriteSessionController.changes.addListener(_sessionChanged);
      _lifecycle ??= AppLifecycleListener(
        onResume: () {
          unawaited(refreshAccess());
        },
        onPause: () => _access?.checkpoint(),
      );
      // A resume event and this lightweight timer enforce expiry without restart.
      _expiryTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
        _publish();
        _access?.checkpoint();
      });
      FirebaseAuth.instance.userChanges().listen((user) {
        final changed =
            user?.uid != _observedUid ||
            user?.isAnonymous != _observedAnonymous;
        _observedUid = user?.uid;
        _observedAnonymous = user?.isAnonymous;
        if (changed) {
          _access?.invalidateIdentity();
          _publish();
        }
        unawaited(refreshAccess());
        unawaited(_ensureBilling());
      });
      _publish();
      await refreshAccess();
      await _ensureBilling();
    } on Object {
      // Missing Firebase configuration or offline startup must not block learning.
      _publish();
    }
  }

  static void _sessionChanged() {
    _publish();
    unawaited(refreshAccess());
    unawaited(_ensureBilling());
  }

  static Future<void> refreshAccess() async {
    final uid = _identity().uid;
    if (uid == null || cloudWriteSessionController.current?.uid != uid) {
      _publish();
      return;
    }
    await _access?.refresh();
    _publish();
  }

  static void _publish() {
    premiumNotifier.value = hasContentAccess;
    accessSnapshotNotifier.value = accessSnapshot;
  }

  static Future<void> _ensureBilling() async {
    if (freeLaunch ||
        betaUnlockAll ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    final key = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosKey
        : _androidKey;
    if (key.isEmpty || requiresSignIn) {
      return;
    }
    final existing = _billingInit;
    if (existing != null) {
      await existing;
      // The identity may have changed while configuration was in flight.
      if (_configured) {
        try {
          await _identityBinder?.bind(requiresSignIn ? null : _identity().uid);
        } on Object {
          // Failed identity transitions stay unbound for purchase checks.
        }
      }
      return;
    }
    final work = _configureOrBind(key);
    _billingInit = work;
    try {
      await work;
    } finally {
      _billingInit = null;
    }
  }

  static Future<bool> _sdkIdentityMatches(String uid) async =>
      await Purchases.appUserID == uid && !await Purchases.isAnonymous;

  static Future<void> _configureOrBind(String key) async {
    final user = _identity();
    final uid = user.uid;
    if (uid == null || user.isAnonymous) {
      return;
    }
    final session = CloudWriteFence(
      cloudWriteSessionController,
    ).readySnapshot(uid);
    if (session == null) {
      return;
    }
    try {
      if (!_configured) {
        await Purchases.configure(
          revenueCatConfiguration(apiKey: key, appUserId: uid),
        );
        // SDK process state may have changed even if Firebase changed meanwhile.
        _configured = true;
        _identityBinder = PremiumIdentityBinder(
          const PurchasesIdentityClient(),
          sessions: cloudWriteSessionController,
          initialUid: uid,
          identityMatches: _sdkIdentityMatches,
        );
        _identityBinder!.start(
          FirebaseAuth.instance.userChanges().map(
            (user) => user == null || user.isAnonymous ? null : user.uid,
          ),
        );
        _purchases = PremiumPurchaseController(
          sessions: cloudWriteSessionController,
          binder: _identityBinder!,
          identity: _identity,
          enabled: () => purchasesEnabled,
          hasPremium: () => isPremium,
          refreshAccess: refreshAccess,
          purchasePackage: (package) async {
            final result = await Purchases.purchase(
              PurchaseParams.package(package),
            );
            return result.customerInfo.entitlements.active.containsKey(
              entitlementId,
            );
          },
          restorePurchases: () async => (await Purchases.restorePurchases())
              .entitlements
              .active
              .containsKey(entitlementId),
        );
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      }
      if (_identity().uid == uid &&
          !requiresSignIn &&
          cloudWriteSessionController.current == session) {
        await _identityBinder!.bind(uid);
      }
    } on Object {
      // Purchase retry may reattempt binding; errors never grant access.
    }
  }

  static void _onCustomerInfo(CustomerInfo _) {
    // RC events have no reliable current UID tag (originalAppUserId is an alias).
    // Never apply their entitlements directly. Ask our authenticated server.
    unawaited(refreshAccess());
  }

  static Future<Offering?> currentOffering() async {
    final expectedUid = _identity().uid;
    final expectedSession = cloudWriteSessionController.current;
    await _ensureBilling();
    final user = _identity();
    final uid = user.uid;
    if (!purchasesEnabled ||
        uid == null ||
        user.isAnonymous ||
        uid != expectedUid ||
        cloudWriteSessionController.current != expectedSession) {
      return null;
    }
    try {
      return await _identityBinder?.runBound<Offering?>(
        uid: uid,
        action: () async => (await Purchases.getOfferings()).current,
      );
    } on Object {
      return null;
    }
  }

  static Future<PremiumPurchaseOutcome> purchase(Package package) async {
    if (requiresSignIn) {
      return PremiumPurchaseOutcome.signInRequired;
    }
    final uid = _identity().uid;
    final session = cloudWriteSessionController.current;
    await _ensureBilling();
    if (_identity().uid != uid ||
        requiresSignIn ||
        cloudWriteSessionController.current != session) {
      return PremiumPurchaseOutcome.stale;
    }
    return await _purchases?.purchase(package) ?? PremiumPurchaseOutcome.failed;
  }

  static Future<PremiumRestoreOutcome> restore() async {
    if (requiresSignIn) {
      return PremiumRestoreOutcome.signInRequired;
    }
    final uid = _identity().uid;
    final session = cloudWriteSessionController.current;
    await _ensureBilling();
    if (_identity().uid != uid ||
        requiresSignIn ||
        cloudWriteSessionController.current != session) {
      return PremiumRestoreOutcome.stale;
    }
    return await _purchases?.restore() ?? PremiumRestoreOutcome.failed;
  }

  /// Use RevenueCat's verified original-store management link, not device OS.
  static Future<Uri?> managementUrl() async {
    final expectedUid = _identity().uid;
    final expectedSession = cloudWriteSessionController.current;
    await _ensureBilling();
    final uid = _identity().uid;
    if (!_configured ||
        uid == null ||
        requiresSignIn ||
        _identityBinder == null ||
        uid != expectedUid ||
        cloudWriteSessionController.current != expectedSession) {
      return null;
    }
    try {
      final raw = await _identityBinder!.runBound<String?>(
        uid: uid,
        action: () async => (await Purchases.getCustomerInfo()).managementURL,
      );
      final uri = raw == null ? null : Uri.tryParse(raw);
      if (uri?.scheme != 'https' ||
          !const {'apps.apple.com', 'play.google.com'}.contains(uri?.host)) {
        return null;
      }
      return uri;
    } on Object {
      return null;
    }
  }

  static Future<void> setDevOverride(bool value) async {
    if (!kDebugMode) {
      return;
    }
    await Storage.setDevPremiumOverride(value);
    _publish();
  }

  static Future<bool> gate(BuildContext context) async {
    if (hasContentAccess) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    await Navigator.of(context).pushNamed('/paywall');
    return hasContentAccess;
  }
}
