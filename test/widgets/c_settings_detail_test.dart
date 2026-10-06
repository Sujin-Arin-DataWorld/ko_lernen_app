import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ValueNotifier<CloudBackupDeletionJournalState> journal;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    journal = ValueNotifier(CloudBackupDeletionJournalState.clear);
  });
  tearDown(() => journal.dispose());

  for (final focus in SettingsInitialFocus.values) {
    testWidgets('C settings detail renders ${focus.name}', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(
          SettingsScreen(
            conceptC: true,
            initialFocus: focus,
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: false,
                isAppleLinked: false,
              ),
            ),
            accountOperations: _AccountOps(),
            cloudDataDeletionJournalState: journal,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sound overview opens the dedicated C sound details screen', (
    tester,
  ) async {
    final routes = <RouteSettings>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        onGenerateRoute: (settings) {
          routes.add(settings);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
        home: SettingsScreen(
          conceptC: true,
          initialFocus: SettingsInitialFocus.voiceSpeed,
          accountOperations: _AccountOps(),
          cloudDataDeletionJournalState: journal,
        ),
      ),
    );
    await tester.pump();
    final more = find.text('Weitere Klänge');
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pump();
    expect(routes.last.name, '/settings/detail');
    expect(routes.last.arguments, SettingsInitialFocus.soundDetails);
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  routes: {
    '/profile': (_) => const SizedBox.shrink(),
    '/guide': (_) => const SizedBox.shrink(),
    '/content/goals': (_) => const SizedBox.shrink(),
    '/course/phases': (_) => const SizedBox.shrink(),
  },
  home: child,
);

class _AccountOps implements AccountUiOperations, AccountUiPendingStateSource {
  final pending = ValueNotifier<AccountUiPendingState>(
    AccountUiPendingState.none,
  );

  @override
  bool get appleSignInAvailable => false;

  @override
  ValueListenable<AccountUiPendingState> get pendingState => pending;

  @override
  Future<AccountUiPendingState> refreshPendingState() async => pending.value;

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async =>
      const AccountUiLinkCompleted();

  @override
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountSwitchResult(AccountSwitchStatus.completed);
}
