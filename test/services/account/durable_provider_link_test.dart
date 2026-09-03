import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/durable_provider_link.dart';

void main() {
  late CloudWriteSessionController sessions;
  late String? uid;
  late Set<String> providers;
  late List<String> calls;
  String? invalidateAt;
  bool epochOnly = false;
  String? failureAt;

  setUp(() {
    sessions = CloudWriteSessionController()..acquire('original');
    uid = 'original';
    providers = {'google.com'};
    calls = [];
    invalidateAt = null;
    epochOnly = false;
    failureAt = null;
  });

  Future<void> step(String stage) async {
    calls.add(stage);
    if (stage == invalidateAt) {
      if (!epochOnly) uid = 'different';
      sessions.acquire(uid!);
    }
    if (stage == failureAt) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
  }

  Future<DurableProviderLinkOutcome> run({String? linkError}) =>
      linkAdditionalDurableProvider<String>(
        provider: AccountLinkProvider.apple,
        sourceUid: 'original',
        sessions: sessions,
        currentUid: () => uid,
        currentProviderIds: () => providers,
        acquireCredential: (provider, assertCurrent) async {
          await step(
            provider == AccountLinkProvider.google
                ? 'reauthCredential'
                : 'targetCredential',
          );
          assertCurrent();
          return provider.name;
        },
        reauthenticate: (credential) async => step('reauthenticate'),
        linkCredential: (credential) async {
          await step('link');
          if (linkError != null) throw FirebaseAuthException(code: linkError);
          providers.add('apple.com');
          return uid;
        },
        reload: () async => step('reload'),
      );

  test(
    'additional provider preserves UID, epoch and skips account activation',
    () async {
      final before = sessions.current;
      expect(await run(), DurableProviderLinkOutcome.linked);
      expect(uid, 'original');
      expect(sessions.current, before);
      expect(calls, [
        'reauthCredential',
        'reauthenticate',
        'targetCredential',
        'link',
        'reload',
      ]);
    },
  );

  for (final stage in [
    'reauthCredential',
    'reauthenticate',
    'targetCredential',
    'link',
    'reload',
  ]) {
    for (final onlyEpoch in [false, true]) {
      test(
        'rejects ${onlyEpoch ? "epoch" : "UID"} change after $stage',
        () async {
          invalidateAt = stage;
          epochOnly = onlyEpoch;
          await expectLater(run(), throwsA(isA<AccountLinkSafetyFailure>()));
          expect(calls.last, stage);
        },
      );
    }
  }

  for (final code in [
    'credential-already-in-use',
    'email-already-in-use',
    'account-exists-with-different-credential',
  ]) {
    test(
      '$code is safe durable collision, never anonymous replacement',
      () async {
        expect(
          await run(linkError: code),
          DurableProviderLinkOutcome.collision,
        );
        expect(uid, 'original');
        expect(providers, {'google.com'});
        expect(calls.last, 'link');
      },
    );
  }
  test('already linked does not prompt or mutate', () async {
    providers.add('apple.com');
    expect(await run(), DurableProviderLinkOutcome.alreadyLinked);
    expect(calls, isEmpty);
  });
  test(
    'provider-already-linked response requires confirmed provider after reload',
    () async {
      await expectLater(
        run(linkError: 'provider-already-linked'),
        throwsA(isA<AccountLinkSafetyFailure>()),
      );
      expect(calls.last, 'reload');
    },
  );
  test(
    'cancellation stops before link without changing progress identity',
    () async {
      final before = sessions.current;
      await expectLater(
        linkAdditionalDurableProvider<String>(
          provider: AccountLinkProvider.apple,
          sourceUid: 'original',
          sessions: sessions,
          currentUid: () => uid,
          currentProviderIds: () => providers,
          acquireCredential: (_, fence) async =>
              throw FirebaseAuthException(code: 'reauth-cancelled'),
          reauthenticate: (_) async {
            fail('must not reauthenticate');
          },
          linkCredential: (_) async {
            fail('must not link');
          },
          reload: () async {
            fail('must not reload');
          },
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(sessions.current, before);
      expect(uid, 'original');
    },
  );
  test('network failure stops before linking and can retry', () async {
    failureAt = 'targetCredential';
    await expectLater(run(), throwsA(isA<FirebaseAuthException>()));
    expect(providers, {'google.com'});
    failureAt = null;
    expect(await run(), DurableProviderLinkOutcome.linked);
  });
  test(
    'restart clears session and cannot resume an in-flight credential',
    () async {
      sessions.clear();
      await expectLater(run(), throwsA(isA<AccountLinkSafetyFailure>()));
      expect(calls, isEmpty);
    },
  );
}
