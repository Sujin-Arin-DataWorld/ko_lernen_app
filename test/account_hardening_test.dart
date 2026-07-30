import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_nudge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('durable account providers', () {
    test('Apple alone is a durable linked account', () {
      final providers = AuthProviderState.fromProviderIds(const ['apple.com']);

      expect(providers.isDurable, isTrue);
      expect(providers.isAppleLinked, isTrue);
      expect(providers.isGoogleLinked, isFalse);
    });

    test('Google alone is a durable linked account', () {
      final providers = AuthProviderState.fromProviderIds(const ['google.com']);

      expect(providers.isDurable, isTrue);
      expect(providers.isAppleLinked, isFalse);
      expect(providers.isGoogleLinked, isTrue);
    });

    testWidgets('profile presents an Apple-only account as connected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileScreen(
            account: AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: false,
                isAppleLinked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Mit Apple verbunden'), findsOneWidget);
      expect(find.text('Angemeldet: Apple'), findsOneWidget);
      expect(find.text('Mit Google sichern'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('profile presents both linked providers deterministically', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileScreen(
            account: AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Mit Google und Apple verbunden'), findsOneWidget);
      expect(find.text('Angemeldet: Google und Apple'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('account nudge is suppressed for an Apple-only account', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      await showAccountNudgeSheet(
        context,
        account: const AuthAccountSnapshot(
          providers: AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Speichere deinen Fortschritt'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets(
      'settings uses the Apple provider label for Apple-only account',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            const SettingsScreen(
              account: AuthAccountSnapshot(
                providers: AuthProviderState(
                  isGoogleLinked: false,
                  isAppleLinked: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Angemeldet: Apple'), findsOneWidget);
        expect(find.text('Mit Google sichern'), findsNothing);
      },
    );
  });

  group('local account deletion cleanup', () {
    test(
      'required local cleanup attempts every independent step before failing',
      () async {
        final events = <String>[];
        final operations = _FakeAccountCleanupOperations(events)
          ..imageCleanupFailure = StateError('image cleanup failed');
        final workflow = AccountDeletionWorkflow(operations);

        await expectLater(
          workflow.run(),
          throwsA(
            isA<AccountDeletionFailure>().having(
              (error) => error.causes.length,
              'cause count',
              1,
            ),
          ),
        );

        expect(events, <String>[
          'remote-delete',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
        ]);
      },
    );

    test(
      'production cleanup adapter invokes every injected strict operation',
      () async {
        final events = <String>[];
        final adapter = AccountDeletionCleanupAdapter(
          deleteRemote: () async => events.add('remote-delete'),
          resetStorage: () async => events.add('local-reset'),
          disablePush: () async => events.add('push-disable'),
          deleteImages: () async => events.add('image-delete'),
          clearTts: () async => events.add('tts-clear'),
          resetMemory: () => events.add('memory-reset'),
        );

        await AccountDeletionWorkflow(adapter).run();

        expect(events, <String>[
          'remote-delete',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
        ]);
      },
    );
  });

  group('subscription management', () {
    test('uses the App Store subscriptions route on Apple platforms', () {
      expect(
        subscriptionManagementUri(TargetPlatform.iOS),
        Uri.parse('https://apps.apple.com/account/subscriptions'),
      );
    });

    test('uses the Play Store subscriptions route on Android', () {
      expect(
        subscriptionManagementUri(TargetPlatform.android),
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      );
    });

    test('unsupported and web platforms do not receive a store route', () {
      expect(subscriptionManagementUri(TargetPlatform.windows), isNull);
      expect(subscriptionManagementUri(TargetPlatform.linux), isNull);
      expect(subscriptionManagementUri(TargetPlatform.fuchsia), isNull);
      expect(
        subscriptionManagementUri(TargetPlatform.iOS, isWeb: true),
        isNull,
      );
    });

    test('launcher false result is surfaced as a failure', () async {
      final attempted = <Uri>[];
      final manager = SubscriptionManagementLauncher(
        platform: TargetPlatform.android,
        isWeb: false,
        launchExternal: (uri) async {
          attempted.add(uri);
          return false;
        },
      );

      await expectLater(
        manager.open(),
        throwsA(isA<SubscriptionManagementException>()),
      );

      expect(attempted, <Uri>[
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      ]);
    });

    testWidgets(
      'account deletion warns about subscriptions and exposes management',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        final workflow = AccountDeletionWorkflow(
          _FakeAccountCleanupOperations(<String>[]),
        );

        await tester.pumpWidget(
          _wrap(SettingsScreen(accountDeletionWorkflow: workflow)),
        );
        await tester.pump();

        final deleteTile = find.text('Konto und alle Daten löschen');
        await tester.scrollUntilVisible(
          deleteTile,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(deleteTile);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Ein App-Store- oder Play-Store-Abo wird dadurch nicht gekündigt.',
          ),
          findsOneWidget,
        );
        expect(find.text('Store-Abo verwalten'), findsOneWidget);
      },
    );

    testWidgets('local cleanup failure never shows account deletion success', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      final operations = _FakeAccountCleanupOperations(<String>[])
        ..imageCleanupFailure = StateError('image cleanup failed');

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            accountDeletionWorkflow: AccountDeletionWorkflow(operations),
          ),
        ),
      );
      await tester.pump();

      final deleteTile = find.text('Konto und alle Daten löschen');
      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen').last);
      await tester.pump();

      expect(find.text('Löschung wird fortgesetzt'), findsOneWidget);
      expect(find.textContaining('image cleanup failed'), findsNothing);
      expect(find.text('Konto und Daten gelöscht'), findsNothing);
    });

    testWidgets('launcher false result shows localized management failure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      final manager = SubscriptionManagementLauncher(
        platform: TargetPlatform.android,
        isWeb: false,
        launchExternal: (_) async => false,
      );

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            accountDeletionWorkflow: AccountDeletionWorkflow(
              _FakeAccountCleanupOperations(<String>[]),
            ),
            subscriptionManager: manager,
          ),
        ),
      );
      await tester.pump();

      final deleteTile = find.text('Konto und alle Daten löschen');
      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Store-Abo verwalten'));
      await tester.pump();

      expect(
        find.text('Die Aboverwaltung konnte nicht geöffnet werden.'),
        findsOneWidget,
      );
    });
  });
}

class _FakeAccountCleanupOperations
    implements AccountDeletionCleanupOperations {
  _FakeAccountCleanupOperations(this.events);

  final List<String> events;
  Object? imageCleanupFailure;

  @override
  Future<void> clearTtsCache() async {
    events.add('tts-clear');
  }

  @override
  Future<void> deleteLocalImages() async {
    events.add('image-delete');
    if (imageCleanupFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> deleteRemoteAccount() async {
    events.add('remote-delete');
  }

  @override
  Future<void> disablePush() async {
    events.add('push-disable');
  }

  @override
  void resetInMemoryData() {
    events.add('memory-reset');
  }

  @override
  Future<void> resetLocalStorage() async {
    events.add('local-reset');
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
