import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'age_gate_service.dart';
import 'storage_service.dart';
import 'account/cloud_write_session.dart';

final class PrivacyAgeEligibilityException implements Exception {
  const PrivacyAgeEligibilityException();
}

enum PrivacyApplicationStatus { inactive, pending, applied, retryRequired }

/// One purpose's latest choice and actual SDK operations. Off never waits for
/// persistence before fencing application calls and attempting SDK disable.
final class _PrivacyChannel {
  _PrivacyChannel({
    required this.read,
    required this.persist,
    required this.toggle,
    required this.changed,
    this.deleteReports,
  });
  final bool Function() read;
  final Future<void> Function(bool) persist;
  final Future<void> Function(bool) toggle;
  final Future<void> Function()? deleteReports;
  final VoidCallback changed;
  int revision = 0;
  bool? desired;
  bool admitted = false;
  bool durable = false;
  PrivacyApplicationStatus status = PrivacyApplicationStatus.inactive;
  Future<void>? active;
  final _sdkOwners = <Future<void>>{};
  int _disableFailures = 0;

  void _publish() {
    changed();
  }

  bool get canCollect => admitted && desired != false && read();
  Future<void> choose(bool enabled, {bool persistChoice = true}) {
    if (active != null && desired == enabled) {
      return active!;
    }
    if (desired == enabled &&
        durable &&
        enabled &&
        status == PrivacyApplicationStatus.applied &&
        canCollect) {
      return Future<void>.value();
    }
    final token = ++revision;
    desired = enabled;
    admitted = false;
    durable = !persistChoice;
    status = PrivacyApplicationStatus.pending;
    _publish();
    // Invoke disable before entering the asynchronous native preference path.
    final disable = enabled ? null : _disable();
    final previousSdk = _sdkOwners.toList();
    final priorDisableFailures = _disableFailures;
    late final Future<void> operation;
    operation = () async {
      try {
        if (!enabled) {
          // Both obligations are started even if either one fails.
          await Future.wait<void>([
            disable!,
            if (persistChoice) persist(false),
          ]);
          if (token != revision) {
            return;
          }
          durable = true;
          await Future.wait(previousSdk);
          if (_disableFailures != priorDisableFailures) {
            throw StateError('SDK withdrawal requires retry');
          }
        } else {
          await Future.wait(previousSdk);
          if (token != revision) {
            return;
          }
          // A retry of an already stored choice preserves consented reports.
          if (persistChoice && !read()) {
            await _deleteBeforeGrant();
          }
          if (token != revision) {
            return;
          }
          if (persistChoice) {
            await persist(true);
          }
          if (token != revision) {
            return;
          }
          durable = true;
          if (!read()) {
            throw StateError('Optional collection is ineligible');
          }
          await _enable(token);
          if (token != revision || !read()) {
            return;
          }
          admitted = true;
        }
        if (token == revision) {
          status = enabled
              ? PrivacyApplicationStatus.applied
              : PrivacyApplicationStatus.inactive;
        }
      } on Object {
        if (token == revision) {
          status = PrivacyApplicationStatus.retryRequired;
          admitted = false;
        }
        rethrow;
      } finally {
        if (token == revision) {
          active = null;
          _publish();
        }
      }
    }();
    active = operation;
    return operation;
  }

  Future<void> _deleteBeforeGrant() {
    final owner = () async {
      await deleteReports?.call();
    }();
    final drain = owner.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _sdkOwners.add(drain);
    drain.then((_) => _sdkOwners.remove(drain));
    return owner;
  }

  Future<void> _disable() {
    final owner = () async {
      try {
        await toggle(false);
        await deleteReports?.call();
      } on Object {
        _disableFailures++;
        rethrow;
      }
    }();
    final drain = owner.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _sdkOwners.add(drain);
    drain.then((_) => _sdkOwners.remove(drain));
    return owner;
  }

  Future<void> _enable(int token) {
    late final Future<void> owner;
    owner = () async {
      try {
        await toggle(true);
      } finally {
        if (token != revision || desired != true || !read()) {
          await _disable();
        }
      }
    }();
    final drain = owner.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _sdkOwners.add(drain);
    drain.then((_) => _sdkOwners.remove(drain));
    return owner;
  }

  /// Retire a callback without changing the user's stored selection.
  void fence() {
    revision++;
    desired = null;
    admitted = false;
    active = null;
    status = PrivacyApplicationStatus.pending;
    _publish();
    final token = revision;
    final priorDisableFailures = _disableFailures;
    final previousSdk = _sdkOwners.toList();
    unawaited(() async {
      try {
        await _disable();
        // Earlier native enables own their compensating disable until it settles.
        await Future.wait(previousSdk);
        if (_disableFailures != priorDisableFailures) {
          throw StateError('SDK withdrawal requires retry');
        }
        if (token == revision) {
          status = PrivacyApplicationStatus.inactive;
          _publish();
        }
      } on Object {
        if (token == revision) {
          status = PrivacyApplicationStatus.retryRequired;
          _publish();
        }
        debugPrint('Privacy: SDK disable requires retry');
      }
    }());
  }
}

class PrivacyConsentController {
  PrivacyConsentController({
    required this.analyticsConsent,
    required this.crashConsent,
    required this.persistAnalyticsConsent,
    required this.persistCrashConsent,
    required this.analyticsClient,
    required this.crashClient,
    required this.presentFlutterError,
    VoidCallback? onChanged,
  }) {
    _analytics = _PrivacyChannel(
      read: analyticsConsent,
      persist: persistAnalyticsConsent,
      toggle: analyticsClient.setCollectionEnabled,
      changed: onChanged ?? () {},
    );
    _crash = _PrivacyChannel(
      read: crashConsent,
      persist: persistCrashConsent,
      toggle: crashClient.setCollectionEnabled,
      deleteReports: crashClient.deleteUnsentReports,
      changed: onChanged ?? () {},
    );
  }
  final bool Function() analyticsConsent;
  final bool Function() crashConsent;
  final Future<void> Function(bool) persistAnalyticsConsent;
  final Future<void> Function(bool) persistCrashConsent;
  final AnalyticsConsentClient analyticsClient;
  final CrashConsentClient crashClient;
  final void Function(FlutterErrorDetails) presentFlutterError;
  late final _PrivacyChannel _analytics;
  late final _PrivacyChannel _crash;
  bool get analyticsAdmitted => _analytics.canCollect;
  bool get crashAdmitted => _crash.canCollect;

  Future<void> applyStored() => Future.wait<void>([
    if (_analytics.active != null)
      _analytics.active!
    else if (_analytics.desired == null)
      _analytics.choose(analyticsConsent(), persistChoice: false),
    if (_crash.active != null)
      _crash.active!
    else if (_crash.desired == null)
      _crash.choose(crashConsent(), persistChoice: false),
  ]);
  Future<void> setAnalytics(bool enabled, {bool persist = true}) =>
      _analytics.choose(enabled, persistChoice: persist);
  Future<void> setCrash(bool enabled, {bool persist = true}) =>
      _crash.choose(enabled, persistChoice: persist);
  void retire() {
    _analytics.fence();
    _crash.fence();
  }

  void handleFlutterError(
    FlutterErrorDetails details, {
    required bool isDebug,
  }) {
    if (!crashAdmitted) {
      presentFlutterError(details);
      return;
    }
    if (isDebug) {
      presentFlutterError(details);
    }
    unawaited(
      _record(
        () => crashClient.recordFlutterFatalError(details),
        details,
        presentOnFailure: !isDebug,
      ),
    );
  }

  Future<void> _record(
    Future<void> Function() send,
    FlutterErrorDetails details, {
    bool presentOnFailure = true,
  }) async {
    try {
      await send();
    } on Object {
      if (presentOnFailure) {
        presentFlutterError(details);
      }
      debugPrint('Privacy: crash reporting unavailable');
    }
  }

  bool handlePlatformError(Object error, StackTrace stack) {
    final details = FlutterErrorDetails(
      exception: error,
      stack: stack,
      context: ErrorDescription('uncaught asynchronous error'),
    );
    if (!crashAdmitted) {
      presentFlutterError(details);
      return true;
    }
    unawaited(
      _record(
        () => crashClient.recordError(error, stack, fatal: true),
        details,
      ),
    );
    return true;
  }
}

abstract final class PrivacyConsentService {
  static final analyticsEnabled = ValueNotifier<bool>(false);
  static final changes = ValueNotifier<int>(0);
  static Duration waitLimit = const Duration(seconds: 5);
  static bool _listening = false;
  static bool _ready = false;
  static bool _accountBlocked = false;
  static int _epoch = -1;
  static bool _ageEligible = false;
  static CloudWriteSessionController? _sessions;
  static VoidCallback? _sessionListener;
  static PrivacyConsentController _controller = _create();
  static PrivacyConsentController _create({
    AnalyticsConsentClient? analytics,
    CrashConsentClient? crash,
  }) => PrivacyConsentController(
    analyticsConsent: () =>
        !_accountBlocked &&
        Storage.analyticsConsent &&
        AgeGateService.isGyeAllowed,
    crashConsent: () =>
        !_accountBlocked && Storage.crashConsent && AgeGateService.isGyeAllowed,
    persistAnalyticsConsent: Storage.setAnalyticsConsent,
    persistCrashConsent: Storage.setCrashConsent,
    analyticsClient: analytics ?? const FirebaseAnalyticsConsentClient(),
    crashClient: crash ?? const FirebaseCrashConsentClient(),
    presentFlutterError: FlutterError.presentError,
    onChanged: _publish,
  );
  static void _publish() {
    analyticsEnabled.value = canCollectAnalytics;
    changes.value++;
  }

  static bool get canCollectAnalytics => _controller.analyticsAdmitted;
  static bool get canCollectCrash => _controller.crashAdmitted;
  static bool get canSubmitPronunciation =>
      !_accountBlocked && Storage.pronunciationConsent;
  static PrivacyApplicationStatus status(PrivacyPurpose purpose) =>
      switch (purpose) {
        PrivacyPurpose.analytics => _controller._analytics.status,
        PrivacyPurpose.crash => _controller._crash.status,
        PrivacyPurpose.pronunciation =>
          PrivacyChoiceStorage.choice(purpose).pending
              ? PrivacyApplicationStatus.pending
              : PrivacyChoiceStorage.choice(purpose).failed
              ? PrivacyApplicationStatus.retryRequired
              : PrivacyApplicationStatus.inactive,
      };

  /// Native selection and its current application obligations have settled.
  /// Used for truthful local feedback; it never initiates a choice or navigation.
  static bool isChoiceSettled(PrivacyPurpose purpose, bool selected) {
    final state = PrivacyChoiceStorage.choice(purpose);
    if (state.pending ||
        state.failed ||
        state.denied ||
        state.confirmed != selected) {
      return false;
    }
    if (purpose == PrivacyPurpose.pronunciation) {
      return !selected || canSubmitPronunciation;
    }
    return selected
        ? (purpose == PrivacyPurpose.analytics
              ? canCollectAnalytics
              : canCollectCrash)
        : status(purpose) == PrivacyApplicationStatus.inactive;
  }

  static void _listen() {
    if (_listening) {
      return;
    }
    _listening = true;
    _epoch = PrivacyChoiceStorage.epoch;
    _ageEligible = AgeGateService.isGyeAllowed;
    PrivacyChoiceStorage.changes.addListener(_storageChanged);
  }

  static void _storageChanged() {
    final eligible = AgeGateService.isGyeAllowed;
    if (_epoch != PrivacyChoiceStorage.epoch || (_ageEligible && !eligible)) {
      _epoch = PrivacyChoiceStorage.epoch;
      _controller.retire();
    }
    final becameEligible = !_ageEligible && eligible;
    _ageEligible = eligible;
    _publish();
    if (_ready && !_accountBlocked && becameEligible) {
      unawaited(_applyQuietly());
    }
  }

  static Future<void> _applyQuietly() async {
    try {
      await _controller.applyStored();
    } on Object {
      debugPrint('Privacy: optional application requires retry');
    }
  }

  static Future<void> applyStored() {
    _listen();
    _ready = true;
    return _controller.applyStored().timeout(waitLimit);
  }

  static Future<void> setChoice(PrivacyPurpose purpose, bool enabled) {
    _listen();
    _ready = true;
    final result = switch (purpose) {
      PrivacyPurpose.analytics => setAnalytics(enabled),
      PrivacyPurpose.crash => setCrash(enabled),
      PrivacyPurpose.pronunciation => Storage.setPronunciationConsent(enabled),
    };
    return result.timeout(waitLimit);
  }

  static Future<void> setAnalytics(bool enabled, {bool persist = true}) {
    _listen();
    _ready = true;
    final allowed = enabled && AgeGateService.isGyeAllowed;
    final operation = _controller.setAnalytics(allowed, persist: persist);
    return operation
        .then((_) {
          if (enabled && !allowed) {
            throw const PrivacyAgeEligibilityException();
          }
        })
        .timeout(waitLimit);
  }

  static Future<void> setCrash(bool enabled, {bool persist = true}) {
    _listen();
    _ready = true;
    final allowed = enabled && AgeGateService.isGyeAllowed;
    final operation = _controller.setCrash(allowed, persist: persist);
    return operation
        .then((_) {
          if (enabled && !allowed) {
            throw const PrivacyAgeEligibilityException();
          }
        })
        .timeout(waitLimit);
  }

  /// The producer publishes quiescence synchronously before identity I/O.
  static void bindAccountSessions(CloudWriteSessionController sessions) {
    _listen();
    if (_sessions != null && _sessionListener != null) {
      _sessions!.changes.removeListener(_sessionListener!);
    }
    _sessions = sessions;
    String? previousUid = sessions.current?.uid;
    void changed() {
      final current = sessions.current;
      final blocked =
          sessions.hasBeenActivated &&
          (current == null || current.mode != CloudWriteMode.ready);
      final changedOwner = previousUid != null && current?.uid != previousUid;
      if ((!_accountBlocked && blocked) || changedOwner) {
        PrivacyChoiceStorage.retire();
      }
      _accountBlocked = blocked;
      previousUid = current?.uid ?? previousUid;
      _publish();
      if (!blocked) {
        unawaited(_refreshAndApply());
      }
    }

    _sessionListener = changed;
    sessions.changes.addListener(changed);
    changed();
  }

  static Future<void> _refreshAndApply() async {
    await PrivacyChoiceStorage.refresh();
    if (_ready && !_accountBlocked) {
      await _applyQuietly();
    }
  }

  static void retireForImport() {
    PrivacyChoiceStorage.retire();
    unawaited(_refreshAndApply());
  }

  static void installErrorHandlers() {
    _listen();
    FlutterError.onError = (details) =>
        _controller.handleFlutterError(details, isDebug: kDebugMode);
    PlatformDispatcher.instance.onError = _controller.handlePlatformError;
  }

  @visibleForTesting
  static void configureForTesting({
    AnalyticsConsentClient? analytics,
    CrashConsentClient? crash,
  }) {
    if (_sessions != null && _sessionListener != null) {
      _sessions!.changes.removeListener(_sessionListener!);
    }
    _sessions = null;
    _sessionListener = null;
    _ready = false;
    _accountBlocked = false;
    _controller = _create(analytics: analytics, crash: crash);
    _listen();
    _epoch = PrivacyChoiceStorage.epoch;
    _ageEligible = AgeGateService.isGyeAllowed;
    waitLimit = const Duration(seconds: 5);
    _publish();
  }
}

abstract interface class AnalyticsConsentClient {
  Future<void> setCollectionEnabled(bool enabled);
}

abstract interface class CrashConsentClient {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> deleteUnsentReports();
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    required bool fatal,
  });
}

class FirebaseAnalyticsConsentClient implements AnalyticsConsentClient {
  const FirebaseAnalyticsConsentClient();

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }
}

class FirebaseCrashConsentClient implements CrashConsentClient {
  const FirebaseCrashConsentClient();

  @override
  Future<void> deleteUnsentReports() {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return FirebaseCrashlytics.instance.deleteUnsentReports();
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    required bool fatal,
  }) {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      enabled,
    );
  }
}
