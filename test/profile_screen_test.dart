import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/learner_motivation.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
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
    Storage.resetForTesting();
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

    await tester.pumpWidget(_wrap(const ProfileScreen(enableCoach: false)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Gast-Karte → Sichern-CTA (settingsCloudSignInPrompt, de).
    await tester.scrollUntilVisible(
      find.text('Mit Google sichern'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
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

    await tester.pumpWidget(_wrap(const ProfileScreen(enableCoach: false)));
    await tester.pump();

    expect(find.text('Mein Lernen'), findsOneWidget);
    expect(find.text('Mein Ziel'), findsOneWidget);
    expect(find.text('Mein Startpunkt'), findsOneWidget);
    expect(find.text('Lernbegleitung'), findsOneWidget);
    expect(find.text('Datenschutz & Konto'), findsOneWidget);
    expect(find.text('Gruppe (계)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Datenschutz & Konto')).dy,
      lessThan(tester.getTopLeft(find.text('Gruppe (계)')).dy),
      reason: 'privacy/account is shown before the optional group entry',
    );

    await tester.tap(find.text('Mein Startpunkt'));
    await tester.pump();
    expect(find.text('A2 · Grundkenntnisse'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('A1 · Anfänger'),
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

  testWidgets(
    'Profile start-point selection warns before resetting populated course progress and cancel writes nothing',
    (tester) async {
      tester.view.physicalSize = const Size(308, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const existingSnapshot =
          '{"version":2,"placementLevel":"a1",'
          '"currentCourseUnitId":"a1_02_self_intro_identity",'
          '"completedUnitIds":["a1_01_greetings_hangul"],'
          '"bypassedPrerequisiteUnitIds":[],"evidence":[],'
          '"scenarioCheckpoints":[]}';
      await Storage.setCourseMasteryStateAtomically(
        canonicalSnapshotJson: existingSnapshot,
        placementLevelCode: 'a1',
        browseLevelCode: 'a1',
        currentCourseUnitId: 'a1_02_self_intro_identity',
        mirrorLegacyUserLevel: true,
      );
      final preferences = await SharedPreferences.getInstance();
      final before = <String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };
      var initializeCalls = 0;

      await tester.pumpWidget(
        _wrap(
          MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.3),
            ),
            child: ProfileScreen(
              initializePlacement: (_) async => initializeCalls++,
              enableCoach: false,
            ),
          ),
        ),
      );
      await tester.pump();

      await _selectProfileLevel(tester, 'A2 · Grundkenntnisse');

      expect(initializeCalls, 0);
      expect(
        find.text(
          'Dabei werden dein bisheriger Kursfortschritt, abgeschlossene '
          'Einheiten, Übungsnachweise und Szenen-Checks zurückgesetzt. '
          'Gespeicherte Vokabeln und Kontodaten bleiben erhalten.',
        ),
        findsOneWidget,
      );
      expect(<String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, before);

      await tester.tap(find.text('Abbrechen'));
      await tester.pump();

      expect(initializeCalls, 0);
      expect(Storage.courseMasterySnapshotRawJson, existingSnapshot);
      expect(<String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profile start point updates canonical placement, current mission, and legacy level together',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const existingSnapshot =
          '{"version":2,"placementLevel":"a1",'
          '"currentCourseUnitId":"a1_02_self_intro_identity",'
          '"completedUnitIds":["a1_01_greetings_hangul"],'
          '"bypassedPrerequisiteUnitIds":[],"evidence":[],'
          '"scenarioCheckpoints":[]}';
      await Storage.setCourseMasteryStateAtomically(
        canonicalSnapshotJson: existingSnapshot,
        placementLevelCode: 'a1',
        browseLevelCode: 'a1',
        currentCourseUnitId: 'a1_02_self_intro_identity',
        mirrorLegacyUserLevel: true,
      );

      await tester.pumpWidget(
        _wrap(
          ProfileScreen(
            initializePlacement: (levelCode) async {
              await Storage.setCourseMasteryStateAtomically(
                canonicalSnapshotJson:
                    '{"version":2,"placementLevel":"$levelCode",'
                    '"currentCourseUnitId":"a2_01_polite_daily",'
                    '"completedUnitIds":[],"bypassedPrerequisiteUnitIds":[],'
                    '"evidence":[],"scenarioCheckpoints":[]}',
                placementLevelCode: levelCode,
                browseLevelCode: levelCode,
                currentCourseUnitId: 'a2_01_polite_daily',
                mirrorLegacyUserLevel: true,
              );
            },
            enableCoach: false,
          ),
        ),
      );
      await tester.pump();

      await _chooseProfileLevel(tester, 'A2 · Grundkenntnisse');
      await tester.pump();

      expect(Storage.userLevelCode, 'a2');
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a2');
      expect(Storage.browseLevelCode, 'a2');
      expect(Storage.courseUnitId, startsWith('a2_'));
      expect(
        Storage.courseMasterySnapshotRawJson,
        contains('"placementLevel":"a2"'),
      );
      expect(
        Storage.courseMasterySnapshotRawJson,
        contains('"currentCourseUnitId":"${Storage.courseUnitId}"'),
      );
      expect(Storage.courseMasterySnapshotRawJson, isNot(existingSnapshot));
      expect(
        Storage.courseMasterySnapshotRawJson,
        contains('"completedUnitIds":[]'),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Profile displays dedicated canonical placement before a stale legacy level without writes',
    (tester) async {
      await Storage.setUserLevelCode('a1');
      await Storage.setDedicatedCoursePlacementLevelCode('a2');
      await Storage.setCourseMasterySnapshotRawJson(
        '{"version":2,"placementLevel":"a2",'
        '"currentCourseUnitId":"a2_01_polite_daily",'
        '"completedUnitIds":[],"bypassedPrerequisiteUnitIds":[],'
        '"evidence":[],"scenarioCheckpoints":[]}',
      );
      final preferences = await SharedPreferences.getInstance();
      final before = <String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };

      await tester.pumpWidget(_wrap(const ProfileScreen(enableCoach: false)));
      await tester.pump();

      expect(find.text('A2 · Grundkenntnisse'), findsWidgets);
      expect(find.text('A1 · Anfänger'), findsNothing);
      expect(<String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, before);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Profile keeps the prior start point and explains a canonical placement failure',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await Storage.setUserLevelCode('a1');
      var attemptedLevel = '';

      await tester.pumpWidget(
        _wrap(
          ProfileScreen(
            initializePlacement: (levelCode) async {
              attemptedLevel = levelCode;
              throw const PreferenceWriteException(
                Storage.courseUnitPreferenceKey,
              );
            },
            enableCoach: false,
          ),
        ),
      );
      await tester.pump();

      await _chooseProfileLevel(tester, 'A2 · Grundkenntnisse');
      await tester.pump();

      expect(attemptedLevel, 'a2');
      expect(Storage.userLevelCode, 'a1');
      expect(find.text('A1 · Anfänger'), findsOneWidget);
      expect(
        find.text(
          'Der Startpunkt konnte nicht geändert werden. Versuche es erneut.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Profile preview renders fixture learning choices and every edit stays mutation-free',
    (tester) async {
      await Storage.setMotivation(LearnerMotivation.career.id);
      await Storage.setUserLevelCode('a1');
      await Storage.setBrowseLevelCode('a1');
      await Storage.setPreferredMascot('tiger');
      MascotPreference.load();
      final preferences = await SharedPreferences.getInstance();
      final before = <String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };
      final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
        CloudBackupDeletionJournalState.clear,
      );
      addTearDown(journalState.dispose);
      var motivationTaps = 0;
      var startPointTaps = 0;
      var companionTaps = 0;

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
            loadGyeMetas: () async => const <GyeMeta>[],
            previewMode: true,
            previewMotivation: LearnerMotivation.travel,
            previewLevel: LearnerLevel.b1,
            previewCompanion: CompanionPreference.magpie,
            onChangeMotivation: () => motivationTaps++,
            onChangeStartPoint: () => startPointTaps++,
            onChangeCompanion: () => companionTaps++,
            enableCoach: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reise nach Korea'), findsWidgets);
      expect(find.text('B1 · Mittelstufe'), findsWidgets);
      expect(find.text('Joy'), findsOneWidget);
      (await _tile(tester, 'profile-learning-goal')).onTap!();
      (await _tile(tester, 'profile-learning-start-point')).onTap!();
      (await _tile(tester, 'profile-learning-companion')).onTap!();
      (await _tile(tester, 'profile-account-controls')).onTap!();
      (await _tile(tester, 'profile-gye')).onTap!();
      (await _tile(tester, 'profile-learning-data-export')).onTap!();
      (await _tile(tester, 'profile-account-delete')).onTap!();
      await tester.pump();

      expect(motivationTaps, 1);
      expect(startPointTaps, 1);
      expect(companionTaps, 1);
      expect(
        Navigator.of(tester.element(find.byType(ProfileScreen))).canPop(),
        isFalse,
      );
      expect(<String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, before);
    },
  );

  testWidgets('Profile 06A rows expose Gye name and fixture-safe actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.clear,
    );
    addTearDown(journalState.dispose);
    var accountCalls = 0;
    var gyeCalls = 0;
    var exportCalls = 0;
    var deletionCalls = 0;

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
          loadGyeMetas: () async => const [
            GyeMeta(
              id: 'MOON23',
              name: 'Mondhof',
              code: 'MOON23',
              ownerId: 'owner',
            ),
          ],
          exportLearningData: () async => exportCalls++,
          onOpenAccountControls: () => accountCalls++,
          onOpenGye: () => gyeCalls++,
          onOpenAccountDeletion: () => deletionCalls++,
          enableCoach: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mondhof'), findsOneWidget);
    expect(find.text('Meine Lerndaten'), findsOneWidget);
    expect(find.text('Konto löschen'), findsOneWidget);
    (await _tile(tester, 'profile-account-controls')).onTap!();
    (await _tile(tester, 'profile-gye')).onTap!();
    (await _tile(tester, 'profile-learning-data-export')).onTap!();
    (await _tile(tester, 'profile-account-delete')).onTap!();
    await tester.pump();
    expect(accountCalls, 1);
    expect(gyeCalls, 1);
    expect(exportCalls, 1);
    expect(deletionCalls, 1);
    expect(
      find.text('Deine Lerndaten sind zum Teilen bereit.'),
      findsOneWidget,
    );
  });

  testWidgets('Profile account rows use typed Settings destinations', (
    tester,
  ) async {
    final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.clear,
    );
    addTearDown(journalState.dispose);
    final destinations = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ProfileScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: false,
              isAppleLinked: false,
            ),
          ),
          cloudDataDeletionJournalState: journalState,
          loadGyeMetas: () async => const <GyeMeta>[],
          enableCoach: false,
        ),
        onGenerateRoute: (settings) {
          destinations.add(settings.arguments);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
    await tester.pump();

    (await _tile(tester, 'profile-account-controls')).onTap!();
    await tester.pump();
    expect(destinations.last, SettingsInitialFocus.account);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();

    (await _tile(tester, 'profile-account-delete')).onTap!();
    await tester.pump();
    expect(destinations.last, SettingsInitialFocus.accountDeletion);
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
          child: ProfileScreen(enableCoach: false),
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
    await tester.scrollUntilVisible(
      signOutFinder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
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

    // Der Screen ist mit den optionalen Opt-in-Schaltern scrollbar; auf kleinen
    // Viewports liegt „Weiter“ unter dem Fold. Erst sichtbar scrollen, dann tippen.
    await tester.ensureVisible(find.text('Weiter'));
    await tester.pump();
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

/// §F(2026-08-14) 섹션 헤더가 레이아웃을 키워 하단 타일이 lazy ListView 의
/// 빌드 범위 밖일 수 있다 — 먼저 스크롤해 빌드시킨 뒤 위젯을 돌려준다.
Future<ListTile> _tile(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  return tester.widget<ListTile>(
    find.descendant(of: finder, matching: find.byType(ListTile)),
  );
}

Future<void> _chooseProfileLevel(WidgetTester tester, String levelLabel) async {
  await _selectProfileLevel(tester, levelLabel);
  expect(find.text('Startpunkt ändern?'), findsOneWidget);
  await tester.tap(find.text('Ändern und Kursfortschritt zurücksetzen'));
  await tester.pump();
}

Future<void> _selectProfileLevel(WidgetTester tester, String levelLabel) async {
  // §F 섹션 헤더로 타일이 뷰포트 밖일 수 있다 — 빌드까지 스크롤(ensureVisible
  // 는 미빌드 lazy 자식을 못 찾는다).
  await tester.scrollUntilVisible(
    find.text('Mein Startpunkt'),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text('Mein Startpunkt'));
  await tester.pump();
  await tester.tap(find.text('Mein Startpunkt'));
  await tester.pump();
  await tester.tap(
    find.descendant(
      of: find.byType(SimpleDialog),
      matching: find.text(levelLabel),
    ),
  );
  await tester.pump();
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
