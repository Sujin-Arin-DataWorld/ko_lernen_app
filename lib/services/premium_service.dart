import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/access_snapshot.dart';
import 'access_snapshot_controller.dart';
import 'account/cloud_write_session.dart';

/// Server policy and quota information remains observable for diagnostics.
final ValueNotifier<AccessSnapshot?> accessSnapshotNotifier = ValueNotifier(
  null,
);

/// Initializes the server-owned access snapshot used by AI quota enforcement.
///
/// The class name is retained for source compatibility. Store billing and
/// subscription purchases are intentionally absent; all learning content is
/// available regardless of account or build flags.
class PremiumService {
  PremiumService._();

  static const bool freeLaunch = true;
  static const bool fullAccessBuild = true;
  static const bool purchasesEnabled = false;
  static const bool isConfigured = false;
  static const String accessEnvironment = String.fromEnvironment(
    'ACCESS_ENVIRONMENT',
    defaultValue: 'PRODUCTION',
  );

  static bool _started = false;
  static AccessSnapshotController? _access;
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

  /// Historical server authority state is diagnostic only and never gates access.
  static bool get isPremium => accessSnapshot?.hasPremium ?? false;

  static bool get hasContentAccess => true;

  static bool get requiresSignIn =>
      _identity().uid == null || _identity().isAnonymous;

  static Future<void> init() async {
    if (_started) {
      return;
    }
    _started = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      _access = AccessSnapshotController(
        sessions: cloudWriteSessionController,
        store: PreferencesAccessSnapshotStore(preferences),
        environment: accessEnvironment,
        fetch: () async {
          final before = _identity().uid;
          final response =
              await FirebaseFunctions.instanceFor(region: 'europe-west3')
                  .httpsCallable(
                    'getAccessSnapshot',
                    options: HttpsCallableOptions(
                      limitedUseAppCheckToken: true,
                    ),
                  )
                  .call();
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
      });
      _publish();
      await refreshAccess();
    } on Object {
      // Offline/Firebase failures never block bundled learning content.
      _publish();
    }
  }

  static void _sessionChanged() {
    _publish();
    unawaited(refreshAccess());
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
    accessSnapshotNotifier.value = accessSnapshot;
  }

  /// Kept as a compatibility boundary for existing navigation helpers.
  static Future<bool> gate(BuildContext context) async => true;
}
