import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/google_oauth_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/google_sign_in');
  late GoogleSignIn client;
  late List<String> platformCalls;
  late String uid;
  late CloudWriteSessionController sessions;
  late CloudWriteSession originalSession;
  Future<void> Function()? onClear;
  bool cancel = false;

  void assertCurrent() {
    if (uid != 'firebase-original' || sessions.current != originalSession) {
      throw const AccountLinkSafetyFailure();
    }
  }

  setUp(() {
    client = GoogleOAuthClient.instance();
    platformCalls = [];
    uid = 'firebase-original';
    sessions = CloudWriteSessionController();
    originalSession = sessions.acquire(uid);
    onClear = null;
    cancel = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          platformCalls.add(call.method);
          switch (call.method) {
            case 'init':
              return null;
            case 'signOut':
              await onClear?.call();
              return null;
            case 'signIn':
              if (cancel) {
                throw PlatformException(
                  code: GoogleSignIn.kSignInCanceledError,
                );
              }
              return <String, Object?>{
                'id': 'google-selected',
                'email': 'selected@example.com',
                'displayName': 'Selected Account',
                'photoUrl': null,
                'serverAuthCode': null,
              };
            default:
              fail('Unexpected provider operation: ${call.method}');
          }
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<GoogleSignInAccount?> acquire() => GoogleOAuthClient.signInFresh(
    client: client,
    assertCurrent: assertCurrent,
  );

  test(
    'cached Google user still opens a fresh native account chooser',
    () async {
      await client.signIn();
      final cached = client.currentUser;
      platformCalls.clear();
      final result = await acquire();
      expect(platformCalls, ['signOut', 'signIn']);
      expect(result?.id, 'google-selected');
      expect(identical(result, cached), isFalse);
      expect(uid, 'firebase-original');
      expect(sessions.current, originalSession);
    },
  );

  for (final identityChange in ['UID', 'epoch']) {
    test(
      '$identityChange change while clearing Google blocks the chooser',
      () async {
        await client.signIn();
        platformCalls.clear();
        onClear = () async {
          if (identityChange == 'UID') {
            uid = 'different';
          }
          sessions.acquire(uid);
        };
        await expectLater(acquire(), throwsA(isA<AccountLinkSafetyFailure>()));
        expect(platformCalls, ['signOut']);
      },
    );
  }

  test('clear failure never opens chooser or revokes Google access', () async {
    await client.signIn();
    platformCalls.clear();
    onClear = () async => throw PlatformException(code: 'network_error');
    await expectLater(acquire(), throwsA(isA<PlatformException>()));
    expect(platformCalls, ['signOut']);
    expect(uid, 'firebase-original');
  });

  test('cancel after clearing preserves Firebase UID and epoch', () async {
    await client.signIn();
    platformCalls.clear();
    cancel = true;
    expect(await acquire(), isNull);
    expect(platformCalls, ['signOut', 'signIn']);
    expect(uid, 'firebase-original');
    expect(sessions.current, originalSession);
  });
}
