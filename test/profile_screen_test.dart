import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/responsive.dart';

/// Smoke-Test für den Profil-Hub (Tier 1 — 2026-06-03).
///
/// Ohne Firebase liefert [AuthService] sichere Defaults
/// (`isGoogleLinked == false`), also muss die Gast-Karte mit dem Sichern-CTA
/// rendern — ohne Build-Exception. (Mascot `animate: true` ist eine
/// Endlos-Animation → `pumpAndSettle` würde hängen; daher endliche `pump`.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    MascotPreference.load();
  });

  testWidgets('ProfileScreen baut im Gast-Modus ohne Firebase fehlerfrei', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ProfileScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Gast-Karte → Sichern-CTA (settingsCloudSignInPrompt, de).
    expect(find.text('Mit Google sichern'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Profile puts editable learning choices ahead of account stats', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ProfileScreen()));
    await tester.pump();

    expect(find.text('Mein Lernen'), findsOneWidget);
    expect(find.text('Mein Ziel'), findsOneWidget);
    expect(find.text('Mein Startpunkt'), findsOneWidget);
    expect(find.text('Lernbegleitung'), findsOneWidget);
    expect(find.text('Datenschutz & Konto'), findsOneWidget);
    expect(find.text('Gruppe (Gye)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Datenschutz & Konto')).dy,
      lessThan(tester.getTopLeft(find.text('Gruppe (Gye)')).dy),
      reason: 'privacy/account is shown before the optional group entry',
    );

    await tester.tap(find.text('Mein Startpunkt'));
    await tester.pump();
    expect(find.text('A2 — Grundkenntnisse'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('A1 — Anfänger'),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Mein Fortschritt'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mein Fortschritt'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Profile learning controls stay scrollable on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(1.3),
          ),
          child: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mein Lernen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mein Fortschritt'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Mein Fortschritt'));
    await tester.pump();
    expect(find.text('Mein Fortschritt'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'ProfileScreen uses the remaining tablet content width beside a rail',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
        CloudBackupDeletionJournalState.clear,
      );
      addTearDown(journalState.dispose);

      await tester.pumpWidget(
        _wrap(
          Row(
            children: [
              const SizedBox(width: 96),
              Expanded(
                child: ProfileScreen(
                  account: const AuthAccountSnapshot(
                    providers: AuthProviderState(
                      isGoogleLinked: false,
                      isAppleLinked: false,
                    ),
                  ),
                  cloudDataDeletionJournalState: journalState,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final list = tester.widget<ListView>(find.byType(ListView).first);
      expect(
        list.padding,
        soriClampPadding(704, base: const EdgeInsets.fromLTRB(16, 16, 16, 32)),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('selected magpie portrait overrides a linked account photo', (
    tester,
  ) async {
    await Storage.setPreferredMascot('magpie');
    MascotPreference.load();
    // Magpie-Avatar alterniert bob2/bob3 (loop:false) — statischen Standard
    // (Tiger, loop:true) für Folgetests wiederherstellen, damit kein Timer leckt.
    addTearDown(() => MascotPreference.kind.value = MascotKind.tiger);

    await tester.pumpWidget(
      _wrap(
        const ProfileScreen(
          account: AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
            displayName: 'Magpie learner',
            photoUrl: 'https://example.test/profile.png',
          ),
        ),
      ),
    );
    await tester.pump();

    final networkImages = tester
        .widgetList<Image>(find.byType(Image))
        .where((image) => image.image is NetworkImage);
    expect(networkImages, isEmpty);
    // Der gewählte Charakter (Elster/조이) ersetzt das Konto-Foto. Direkt am
    // Widget geprüft statt am Semantik-Label: das Kopf-Layout (Video links /
    // Name rechts) ist ein Flex, in dem die animierte Fallback-Semantik im
    // Testharnisch nicht zuverlässig als a11y-Label erscheint — der Charakter
    // selbst (das gerenderte Mascot) schon.
    final mascot = tester.widget<Mascot>(find.byType(Mascot));
    expect(mascot.kind, MascotKind.magpie);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('no-companion profile stays empty and can choose a buddy later', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await MascotPreference.setNone();
    addTearDown(() => MascotPreference.set(MascotKind.tiger));

    await tester.pumpWidget(_wrap(const ProfileScreen()));
    await tester.pump();

    expect(find.byKey(const ValueKey('profile_avatar_none')), findsOneWidget);
    expect(find.text('Keine Lernbegleitung'), findsOneWidget);
    expect(find.byType(CharacterClipPlayer), findsNothing);

    final noCompanion = find.text('Keine Lernbegleitung');
    final companionTile = tester.widget<ListTile>(
      find.ancestor(of: noCompanion, matching: find.byType(ListTile)),
    );
    companionTile.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('태고'), findsOneWidget);
    expect(find.text('Joy'), findsOneWidget);
    final joyOption = tester.widget<SimpleDialogOption>(
      find.ancestor(
        of: find.text('Joy'),
        matching: find.byType(SimpleDialogOption),
      ),
    );
    joyOption.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(MascotPreference.selectedKind, MascotKind.magpie);
    expect(find.text('Joy'), findsOneWidget);
    expect(find.byType(CharacterClipPlayer), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('pending cloud deletion disables connected-account sign out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.pending,
    );
    addTearDown(journalState.dispose);

    await tester.pumpWidget(
      _wrap(
        ProfileScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
            displayName: 'Durable learner',
          ),
          cloudDataDeletionJournalState: journalState,
        ),
      ),
    );
    await tester.pump();

    // The locked button stays tappable and explains the pending cloud
    // deletion — never a silent dead tap, and never an actual sign-out.
    final signOutFinder = find.widgetWithText(SoriButton, 'Abmelden');
    await tester.ensureVisible(signOutFinder);
    await tester.pump();
    final signOut = tester.widget<SoriButton>(signOutFinder);
    expect(signOut.onTap, isNotNull);
    await tester.tap(signOutFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cloud-Löschung wird fortgesetzt'), findsOneWidget);
    await tester.tap(find.text('Schließen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
    'linked profile sign out stays locked until the durable account journal is clear',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final refreshStarted = Completer<void>();
      final releasePersistedRead = Completer<AccountUiPendingState>();
      final operations = _DelayedLinkedAccountOperations(
        refreshStarted: refreshStarted,
        readPersistedState: () => releasePersistedRead.future,
      );
      addTearDown(operations.dispose);

      await tester.pumpWidget(
        _wrap(
          ProfileScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
              displayName: 'Durable learner',
            ),
            accountOperations: operations,
          ),
        ),
      );
      await refreshStarted.future;

      await tester.scrollUntilVisible(
        find.widgetWithText(SoriButton, 'Abmelden'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.widgetWithText(SoriButton, 'Abmelden'));
      await tester.pump();
      var signOut = tester.widget<SoriButton>(
        find.widgetWithText(SoriButton, 'Abmelden'),
      );
      expect(signOut.onTap, isNotNull);

      releasePersistedRead.complete(
        AccountUiPendingState.replacementCancellable,
      );
      await tester.pump();

      // Still locked — but the tap now reroutes to the replacement resume
      // dialog instead of silently doing nothing (and never signs out).
      signOut = tester.widget<SoriButton>(
        find.widgetWithText(SoriButton, 'Abmelden'),
      );
      expect(signOut.onTap, isNotNull);
      await tester.ensureVisible(find.widgetWithText(SoriButton, 'Abmelden'));
      await tester.pump();
      await tester.tap(find.widgetWithText(SoriButton, 'Abmelden'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );

  testWidgets('loading cloud deletion disables a guest connection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.loading,
    );
    addTearDown(journalState.dispose);

    await tester.pumpWidget(
      _wrap(
        ProfileScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: false,
              isAppleLinked: false,
            ),
          ),
          cloudDataDeletionJournalState: journalState,
        ),
      ),
    );
    await tester.pump();

    // Loading state: the button responds with the generic protection notice
    // and never starts provider OAuth.
    await tester.scrollUntilVisible(
      find.widgetWithText(SoriButton, 'Mit Google sichern'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.widgetWithText(SoriButton, 'Mit Google sichern'),
    );
    await tester.pump();
    final connect = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Mit Google sichern'),
    );
    expect(connect.onTap, isNotNull);
    await tester.tap(find.widgetWithText(SoriButton, 'Mit Google sichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dein Konto ist geschützt'), findsOneWidget);
    expect(find.text('Konto sicher verbinden?'), findsNothing);
    await tester.tap(find.text('Schließen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('ConsentScreen (Tier 0) baut fehlerfrei', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 01A is legal consent only: one clear continuation after the legal links.
    expect(find.text('Weiter'), findsOneWidget);
    expect(find.text('Datenschutz & Lernkonto'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ConsentScreen keeps optional collection off by default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Preview gesehen + Level offen → _accept navigiert zur Level-Auswahl
    // (AppShell würde TigerStage-Timer hinterlassen → Test-Invariante).
    await Storage.setIntroPreviewSeen();

    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();

    // 01A has no optional collection checkboxes. Consent is legal only and
    // optional collection stays off until it is explicitly changed elsewhere.
    expect(Storage.analyticsConsent, isFalse);
    expect(Storage.crashConsent, isFalse);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(Storage.consentAccepted, isTrue);
    expect(Storage.analyticsConsent, isFalse);
    expect(Storage.crashConsent, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    // SoriEntrance-Stagger-Timer der Zielseite ausklingen lassen
    // (one-shot Future.delayed, nach dispose no-op).
    await tester.pump(const Duration(seconds: 2));
  });
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

class _DelayedLinkedAccountOperations
    implements AccountUiOperations, AccountUiPendingStateSource {
  _DelayedLinkedAccountOperations({
    required this.refreshStarted,
    required this.readPersistedState,
  });

  final Completer<void> refreshStarted;
  final Future<AccountUiPendingState> Function() readPersistedState;
  final ValueNotifier<AccountUiPendingState> pending =
      ValueNotifier<AccountUiPendingState>(AccountUiPendingState.none);

  @override
  bool get appleSignInAvailable => false;

  @override
  ValueListenable<AccountUiPendingState> get pendingState => pending;

  @override
  Future<bool> cancelReplacement() async => false;

  @override
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountTransitionResult(AccountTransitionStatus.blocked);

  void dispose() => pending.dispose();

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async =>
      const AccountUiLinkBlocked();

  @override
  Future<AccountUiPendingState> refreshPendingState() async {
    if (!refreshStarted.isCompleted) {
      refreshStarted.complete();
    }
    final state = await readPersistedState();
    pending.value = state;
    return state;
  }

  @override
  Future<AccountTransitionResult> resumeReplacement() async =>
      const AccountTransitionResult(AccountTransitionStatus.blocked);
}
