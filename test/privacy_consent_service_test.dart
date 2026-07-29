import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';

void main() {
  group('crash consent', () {
    test(
      'startup with stored consent preserves consented queued reports',
      () async {
        final crash = _FakeCrashConsentClient();
        final harness = _ConsentHarness(crashConsent: true, crash: crash);

        await harness.controller.applyStored();

        expect(crash.events, <String>['collection:true']);
      },
    );

    test(
      'startup without consent disables collection and deletes reports',
      () async {
        final crash = _FakeCrashConsentClient();
        final harness = _ConsentHarness(crashConsent: false, crash: crash);

        await harness.controller.applyStored();

        expect(crash.events, <String>['collection:false', 'delete']);
      },
    );

    test(
      'explicit off to on transition deletes reports before enabling',
      () async {
        final crash = _FakeCrashConsentClient();
        final harness = _ConsentHarness(crashConsent: false, crash: crash);

        await harness.controller.setCrash(true);

        expect(harness.crashConsent, isTrue);
        expect(crash.events, <String>['delete', 'collection:true']);
      },
    );

    test(
      'disabling collection deletes unsent reports after disabling',
      () async {
        final crash = _FakeCrashConsentClient();
        final harness = _ConsentHarness(crashConsent: true, crash: crash);

        await harness.controller.setCrash(false);

        expect(harness.crashConsent, isFalse);
        expect(crash.events, <String>['collection:false', 'delete']);
      },
    );

    test('without consent framework errors use only local presentation', () {
      final crash = _FakeCrashConsentClient();
      final harness = _ConsentHarness(crashConsent: false, crash: crash);
      final details = FlutterErrorDetails(exception: StateError('boom'));

      harness.controller.handleFlutterError(details, isDebug: false);

      expect(harness.presentedErrors, <FlutterErrorDetails>[details]);
      expect(crash.recordedFlutterErrors, isEmpty);
    });

    test('with consent framework errors are sent to Crashlytics', () {
      final crash = _FakeCrashConsentClient();
      final harness = _ConsentHarness(crashConsent: true, crash: crash);
      final details = FlutterErrorDetails(exception: StateError('boom'));

      harness.controller.handleFlutterError(details, isDebug: false);

      expect(harness.presentedErrors, isEmpty);
      expect(crash.recordedFlutterErrors, <FlutterErrorDetails>[details]);
    });
  });
}

class _ConsentHarness {
  _ConsentHarness({
    required this.crashConsent,
    required _FakeCrashConsentClient crash,
  }) {
    controller = PrivacyConsentController(
      analyticsConsent: () => false,
      crashConsent: () => crashConsent,
      persistAnalyticsConsent: (_) async {},
      persistCrashConsent: (value) async {
        crashConsent = value;
      },
      analyticsClient: _FakeAnalyticsConsentClient(),
      crashClient: crash,
      presentFlutterError: presentedErrors.add,
    );
  }

  bool crashConsent;
  final List<FlutterErrorDetails> presentedErrors = <FlutterErrorDetails>[];
  late final PrivacyConsentController controller;
}

class _FakeAnalyticsConsentClient implements AnalyticsConsentClient {
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

class _FakeCrashConsentClient implements CrashConsentClient {
  final List<String> events = <String>[];
  final List<FlutterErrorDetails> recordedFlutterErrors =
      <FlutterErrorDetails>[];

  @override
  Future<void> deleteUnsentReports() async {
    events.add('delete');
  }

  @override
  void recordError(Object error, StackTrace stack, {required bool fatal}) {}

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    recordedFlutterErrors.add(details);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    events.add('collection:$enabled');
  }
}
