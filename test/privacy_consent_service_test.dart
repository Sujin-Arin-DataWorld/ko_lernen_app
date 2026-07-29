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
      'explicit off to on keeps consent off when report deletion fails',
      () async {
        final crash = _FakeCrashConsentClient()
          ..deleteFailure = StateError('delete failed');
        final harness = _ConsentHarness(crashConsent: false, crash: crash);

        await expectLater(
          harness.controller.setCrash(true),
          throwsA(isA<StateError>()),
        );

        expect(harness.crashConsent, isFalse);
        expect(crash.events, <String>['delete']);
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

    test(
      'asynchronous framework report failures use local presentation',
      () async {
        final crash = _FakeCrashConsentClient()
          ..flutterRecordFailure = StateError('async report failed');
        final harness = _ConsentHarness(crashConsent: true, crash: crash);
        final details = FlutterErrorDetails(exception: StateError('boom'));

        harness.controller.handleFlutterError(details, isDebug: false);
        await Future<void>.delayed(Duration.zero);

        expect(harness.presentedErrors, <FlutterErrorDetails>[details]);
      },
    );

    test(
      'asynchronous platform report failures use local presentation',
      () async {
        final crash = _FakeCrashConsentClient()
          ..platformRecordFailure = StateError('async report failed');
        final harness = _ConsentHarness(crashConsent: true, crash: crash);
        final error = StateError('boom');
        final stack = StackTrace.current;

        expect(harness.controller.handlePlatformError(error, stack), isTrue);
        await Future<void>.delayed(Duration.zero);

        expect(harness.presentedErrors, hasLength(1));
        expect(harness.presentedErrors.single.exception, same(error));
      },
    );
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
  Object? deleteFailure;
  Object? flutterRecordFailure;
  Object? platformRecordFailure;

  @override
  Future<void> deleteUnsentReports() async {
    events.add('delete');
    if (deleteFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    required bool fatal,
  }) async {
    if (platformRecordFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    recordedFlutterErrors.add(details);
    if (flutterRecordFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    events.add('collection:$enabled');
  }
}
