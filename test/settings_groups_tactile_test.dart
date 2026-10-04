import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/my_words_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/app_version_service.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/real_fonts.dart';

const _captureEvidence = bool.fromEnvironment(
  'CAPTURE_TACTILE_SETTINGS_EVIDENCE',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_custom_packs_v1': '{}',
      'kl_tut_bookshelf': true,
      'kl_tut_hardWords': true,
    });
    await Storage.init();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final width in const [320.0, 390.0]) {
      testWidgets(
        'five Settings groups retain reachable rows: ${locale.languageCode} $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final journal = ValueNotifier(CloudBackupDeletionJournalState.clear);
          addTearDown(journal.dispose);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            _host(
              SettingsScreen(
                account: const AuthAccountSnapshot(
                  providers: AuthProviderState(
                    isGoogleLinked: false,
                    isAppleLinked: false,
                  ),
                ),
                accountOperations: _AccountOperations(),
                cloudDataDeletionJournalState: journal,
                appVersionReader: const _VersionReader(),
              ),
              locale: locale,
              scale: width == 320 ? 2 : 1,
              boundary: boundary,
            ),
          );
          await tester.pumpAndSettle();
          final t = AppL10n.of(tester.element(find.byType(SettingsScreen)));
          final rows = <String, Finder>{
            'account': find.text(t.profileTitle),
            'learning': find.byKey(const ValueKey('settings-course-preview')),
            'controls': find.byKey(const ValueKey('settings-reduced-motion')),
            'privacy': find.byKey(const ValueKey('settings-hanok-downloads')),
            'help': find.text(t.settingsGuideTitle),
          };
          for (final group in rows.entries) {
            final heading = find.byKey(ValueKey('settings-group-${group.key}'));
            await tester.scrollUntilVisible(
              heading,
              350,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 100,
            );
            await tester.ensureVisible(heading);
            await tester.pumpAndSettle();
            expect(heading.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            if (_captureEvidence) {
              await _capture(
                tester,
                boundary,
                'settings-${group.key}-${locale.languageCode}-${width.toInt()}',
              );
            }
            await tester.scrollUntilVisible(
              group.value,
              200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 100,
            );
            await tester.ensureVisible(group.value);
            await tester.pumpAndSettle();
            expect(group.value.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('My Words evidence uses the production screen', (tester) async {
    if (!_captureEvidence) {
      return;
    }
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in const [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        _host(
          const MyWordsScreen(),
          locale: const Locale('de'),
          scale: width == 320 ? 2 : 1,
          boundary: boundary,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, boundary, 'my-words-de-${width.toInt()}');
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _host(
  Widget child, {
  required Locale locale,
  required double scale,
  required GlobalKey boundary,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: RepaintBoundary(key: boundary, child: child!),
  ),
  home: child,
);

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory('docs/screenshots/tactile-settings-words');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
  });
}

class _VersionReader implements AppVersionReader {
  const _VersionReader();
  @override
  Future<String> readVersion() async => '2.0.5 (11)';
}

class _AccountOperations implements AccountUiOperations {
  @override
  bool get appleSignInAvailable => false;
  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async =>
      const AccountUiLinkCompleted();
  @override
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountSwitchResult(AccountSwitchStatus.completed);
}
