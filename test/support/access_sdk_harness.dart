// Test-only SDK implementations; production initialization, cache and UI run unchanged.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/premium_service.dart';

class AccessSdkHarness {
  static const uid = 'verified-access-test';
  final functions = AccessFunctionsTransport();
  final List<Timer> _timers = [];

  Future<void> initialize() async {
    FirebasePlatform.instance = _Core();
    FirebaseAuthPlatform.instance = _Auth();
    FirebaseFunctionsPlatform.instance = functions;
    cloudWriteSessionController.acquire(uid);
    await runZoned(
      PremiumService.init,
      zoneSpecification: ZoneSpecification(
        createPeriodicTimer: (self, parent, zone, period, callback) {
          final timer = parent.createPeriodicTimer(zone, period, callback);
          _timers.add(timer);
          return timer;
        },
      ),
    );
  }

  Future<void> setPremium(bool premium) async {
    functions.premium = premium;
    await PremiumService.refreshAccess();
  }

  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    cloudWriteSessionController.clear();
  }
}

class _Core extends FirebasePlatform {
  final _app = FirebaseAppPlatform(
    defaultFirebaseAppName,
    const FirebaseOptions(
      apiKey: 'test-key',
      appId: 'test-app',
      messagingSenderId: 'test-sender',
      projectId: 'test-project',
    ),
  );
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) => _app;
}

class _Auth extends FirebaseAuthPlatform {
  late final _user = _User(this);
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;
  @override
  UserPlatform get currentUser => _user;
  @override
  Stream<UserPlatform?> userChanges() => const Stream.empty();
}

class _MultiFactor extends MultiFactorPlatform {
  _MultiFactor(super.auth);
}

class _User extends UserPlatform {
  _User(FirebaseAuthPlatform auth)
    : super(
        auth,
        _MultiFactor(auth),
        InternalUserDetails(
          userInfo: InternalUserInfo(
            uid: AccessSdkHarness.uid,
            isAnonymous: false,
            isEmailVerified: true,
          ),
          providerData: [
            {'providerId': 'google.com'},
          ],
        ),
      );
}

class AccessFunctionsTransport extends FirebaseFunctionsPlatform {
  AccessFunctionsTransport() : super(null, 'europe-west3');
  final List<({String name, String region, bool limitedUse, Object? data})>
  calls = [];
  bool premium = false;
  String? requestedRegion;
  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) {
    requestedRegion = region;
    return this;
  }

  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) => _Callable(this, origin, name, options);
}

class _Callable extends HttpsCallablePlatform {
  _Callable(
    AccessFunctionsTransport functions,
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) : super(functions, origin, name, options, null);
  @override
  Future<dynamic> call([dynamic parameters]) async {
    final transport = functions as AccessFunctionsTransport;
    transport.calls.add((
      name: name!,
      region: transport.requestedRegion!,
      limitedUse: options.limitedUseAppCheckToken,
      data: parameters,
    ));
    final now = DateTime.now().millisecondsSinceEpoch;
    final premium = transport.premium;
    return {
      'schemaVersion': 1,
      'ownerUid': AccessSdkHarness.uid,
      'environment': 'PRODUCTION',
      'revision': (premium ? 'b' : 'a') * 64,
      'source': premium ? 'subscription' : 'free',
      'contentAccess': premium ? 'all' : 'a1',
      'aiPolicyId': premium ? 'premium_v1' : 'free_v1',
      'bookDailyLimit': premium ? 20 : 3,
      'pronunciationDailyLimit': premium ? 50 : 5,
      'serverNow': now,
      'accessUntil': premium ? now + 86400000 : null,
      'offlineUntil': premium ? now + 86400000 : now,
      'nextResetAt': (now ~/ 86400000 + 1) * 86400000,
    };
  }
}
