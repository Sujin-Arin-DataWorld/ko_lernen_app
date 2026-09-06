import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/placement_diagnostic_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_restore_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/audio_policy.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/app_version_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/placement_diagnostic.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

final AppL10n _l10n = lookupAppL10n(const Locale('de'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ValueNotifier<CloudBackupDeletionJournalState> cloudJournalState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    MascotPreference.load();
    cloudJournalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.clear,
    );
  });

  tearDown(() => cloudJournalState.dispose());

  testWidgets('typed deletion entry scrolls to the protected Settings row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
          initialFocus: SettingsInitialFocus.accountDeletion,
        ),
      ),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final deletion = find.text('Konto und alle Daten löschen');
    expect(deletion, findsOneWidget);
    final rect = tester.getRect(deletion);
    expect(rect.top, greaterThan(0));
    expect(rect.bottom, lessThan(700));
  });

  testWidgets('typed guide destinations scroll and move keyboard focus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const destinations = [
      (
        focus: SettingsInitialFocus.courseStart,
        debugLabel: 'settings-course-start',
      ),
      (
        focus: SettingsInitialFocus.browseLevel,
        debugLabel: 'settings-browse-level',
      ),
      (focus: SettingsInitialFocus.companion, debugLabel: 'settings-companion'),
      (
        focus: SettingsInitialFocus.voiceSpeed,
        debugLabel: 'settings-voice-speed',
      ),
      (focus: SettingsInitialFocus.guide, debugLabel: 'settings-guide'),
    ];

    for (final destination in destinations) {
      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            key: ValueKey(destination.debugLabel),
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
            appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
            initialFocus: destination.focus,
          ),
        ),
      );
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        destination.debugLabel,
        reason: destination.focus.name,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('typed focus scroll settles immediately with reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapForLocale(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
          initialFocus: SettingsInitialFocus.guide,
        ),
        locale: const Locale('de'),
        disableAnimations: true,
      ),
    );
    // The lazy Settings list still needs frames to build the distant target,
    // but reduced motion must not need elapsed animation time to settle there.
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump();
    }

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'settings-guide');
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.isScrollingNotifier.value, isFalse);
  });

  testWidgets(
    'level recheck applies all eight answers to course start and browse level',
    (tester) async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      addTearDown(Storage.resetForTesting);
      await AudioPolicy.instance.setChannelOn(SoundChannel.speech, false);

      // CourseProgressService.shared 는 runAsync 존이 아니라 이 테스트 자신의
      // Zone 안에서 사용해야 한다 — runAsync(실제 Zone) 안에서 그 서비스의
      // 직렬화 큐를 생성한 뒤 밖(FakeAsync 존, 이 위젯의 리빌드 등)에서
      // 다시 쓰면 응답이 오지 않는다(다른 테스트 파일들에서 재현·확인됨).
      // CurriculumCatalog.load()만 runAsync로 예열해 compute() 격리 문제를
      // 피하고, 실제 배치 호출은 밖에서 한다.
      await tester.runAsync(() async {
        await CurriculumCatalog.load();
      });
      CourseProgressService.shared.resetForTesting();
      await CourseProgressService.shared.initializeForPlacement(
        'a1',
        syncBrowseLevel: false,
      );
      await Storage.setBrowseLevelCode('a2');

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
            appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
          ),
        ),
      );
      await tester.pump();

      final recheck = find.text('Mein Level neu einschätzen');
      await _ensureSettingsActionVisible(tester, recheck);
      await tester.tap(recheck);
      await tester.pumpAndSettle();

      expect(find.byType(PlacementDiagnosticScreen), findsOneWidget);
      expect(find.text('Frage 1 von 8'), findsOneWidget);

      for (
        var questionIndex = 0;
        questionIndex < placementDiagnosticQuestions.length;
        questionIndex++
      ) {
        final question = find.byKey(
          ValueKey('placement-question-$questionIndex'),
        );
        expect(question, findsOneWidget);
        final choice = find.text(
          placementDiagnosticQuestions[questionIndex].choicesDe.first,
        );
        await _centerInCurrentScrollable(tester, choice);
        await tester.tap(choice);
        await tester.pump();

        final actionLabel =
            questionIndex + 1 == placementDiagnosticQuestions.length
            ? 'Empfehlung ansehen'
            : 'Weiter';
        final action = find.widgetWithText(SoriButton, actionLabel);
        await _centerInCurrentScrollable(tester, action);
        await tester.tap(action);
        await tester.pump();
      }

      expect(find.byKey(const ValueKey('placement-result')), findsOneWidget);
      final applyRecommendation = find.widgetWithText(
        SoriButton,
        'Mit B2 starten',
      );
      await _centerInCurrentScrollable(tester, applyRecommendation);
      await tester.tap(applyRecommendation);
      for (
        var frame = 0;
        frame < 60 &&
            find.byType(PlacementDiagnosticScreen).evaluate().isNotEmpty;
        frame++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(find.byType(PlacementDiagnosticScreen), findsNothing);
      expect(Storage.placementTaken, isTrue);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'b2');
      expect(Storage.browseLevelCode, 'b2');
      final courseUnitId = Storage.courseUnitId;
      expect(courseUnitId, isNotNull);
      final catalog = await CurriculumCatalog.load();
      expect(catalog.courseUnitFor(courseUnitId!)?.level, 'b2');

      final settingsScroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      settingsScroll.position.jumpTo(settingsScroll.position.minScrollExtent);
      await tester.pump();
      final courseStart = find.text(_l10n.settingsCourseStartTitle);
      await _ensureSettingsActionVisible(tester, courseStart);
      final courseTile = tester.widget<ListTile>(
        find.ancestor(of: courseStart, matching: find.byType(ListTile)),
      );
      expect((courseTile.subtitle! as Text).data, startsWith('B2 ·'));
      final browseTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Stufe zum Stöbern'),
          matching: find.byType(ListTile),
        ),
      );
      expect((browseTile.subtitle! as Text).data, startsWith('B2 ·'));
    },
  );

  testWidgets('settings shows the injected runtime release version', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
        ),
      ),
    );
    await tester.pump();

    final version = find.text('Version 2.0.5 (11)');
    await _ensureSettingsActionVisible(tester, version);

    expect(version, findsOneWidget);
  });

  testWidgets(
    // §RELEASE-2(J13): long-pressing the About row copies the exact
    // displayed version string to the clipboard and shows a confirmation
    // notice — the injected reader string flows through unchanged.
    'long-pressing the About row copies the version string to the clipboard',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clipboardCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(
              (call.arguments as Map)['text'] as String,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
            appVersionReader: const _FixedAppVersionReader(
              '2.0.8 (2224) · e35ea785',
            ),
          ),
        ),
      );
      await tester.pump();

      final version = find.text('Version 2.0.8 (2224) · e35ea785');
      await _ensureSettingsActionVisible(tester, version);
      await tester.longPress(version);
      await tester.pump();

      expect(clipboardCalls, ['Version 2.0.8 (2224) · e35ea785']);
    },
  );

  testWidgets('founder story is available from About, not first-run setup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapForLocale(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
        ),
        locale: const Locale('de'),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    // §W-A2 재조사(실측): 이 설정 목록의 maxScrollExtent 가 11346px 로
    // 커졌다(§A3 토큰 확대분) — scrollUntilVisible 기본 delta(200)·최대
    // 시도(50)로는 10000px 까지만 닿아 이 항목(그 너머) 을 못 찾고
    // "No element" 로 죽었다. delta 를 키워 같은 예산 안에서 끝까지 닿게
    // 한다(단언은 그대로, 스크롤 메커니즘만 보정).
    final story = find.text('Warum Hangul Sori entstand');
    await _ensureSettingsActionVisible(tester, story, scrollDelta: 500);
    await tester.tap(story);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Koreanischlernen soll Klang, Schrift'),
      findsOneWidget,
    );
    expect(
      MediaQuery.textScalerOf(
        tester.element(
          find.textContaining('Koreanischlernen soll Klang, Schrift'),
        ),
      ).scale(1),
      2,
    );
    expect(find.textContaining('Sujin Park · Gründerin'), findsOneWidget);
  });

  testWidgets('settings retains a neutral version when the reader fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _ThrowingAppVersionReader(),
        ),
      ),
    );
    await tester.pump();

    // Der Platzhalter ist bewusst ein einfacher Bindestrich: sichtbare
    // deutsche und englische Texte tragen keinen Geviertstrich mehr
    // (Jin 2026-08-13), und `arb_l10n_guard_test.dart` hält das fest.
    final version = find.text('Version -');
    await _ensureSettingsActionVisible(tester, version);

    expect(version, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification permission follows the visible reminder action', (
    tester,
  ) async {
    final notifications = _FakeNotificationSettingsOperations(granted: false);
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
          notificationOperations: notifications,
        ),
      ),
    );
    await tester.pump();

    final reminder = find.text('Tägliche Erinnerung');
    await _ensureSettingsActionVisible(tester, reminder);
    expect(find.text('Taego erinnert dich ans Lernen'), findsOneWidget);
    expect(notifications.permissionRequests, 0);

    await tester.tap(
      find.ancestor(of: reminder, matching: find.byType(SwitchListTile)),
    );
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    expect(notifications.enableCalls, 0);
    expect(notifications.disableCalls, 1);
    expect(Storage.notificationsEnabled, isFalse);
    expect(
      find.textContaining('Benachrichtigungen sind deaktiviert'),
      findsOneWidget,
    );
  });

  testWidgets(
    'voice assessment can only be enabled after the separate disclosure',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final consentTitle = find.text('Einwilligung zur Sprachbewertung');
      await _ensureSettingsActionVisible(tester, consentTitle);
      final consentSwitch = find.ancestor(
        of: consentTitle,
        matching: find.byType(SwitchListTile),
      );

      await tester.tap(consentSwitch);
      await tester.pumpAndSettle();

      expect(Storage.pronunciationConsent, isFalse);
      expect(find.text('Deine Stimme bewerten lassen?'), findsOneWidget);

      await tester.tap(find.text('Ich stimme zu und möchte eine Bewertung'));
      await tester.pumpAndSettle();

      expect(Storage.pronunciationConsent, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('settings link entry confirms before safe operation starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final operations = _SettingsAccountOperations();

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: operations,
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final link = find.text('Mit Google sichern');
    await _ensureSettingsActionVisible(tester, link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(operations.linkCalls, 0);
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();
    expect(operations.linkCalls, 1);
  });

  testWidgets(
    'settings keeps a blocked account journal visible and reroutes new link to the locked dialog',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final operations = _SettingsAccountOperations()
        ..pending.value = AccountUiPendingState.blocked;

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();
      await _ensureSettingsActionVisible(
        tester,
        find.text('Dein Konto ist geschützt'),
      );

      expect(find.text('Status aktualisieren'), findsOneWidget);
      await _ensureSettingsActionVisible(
        tester,
        find.text('Mit Google sichern'),
      );
      final linkTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Mit Google sichern'),
          matching: find.byType(ListTile),
        ),
      );
      // The locked tile stays tappable but explains the block
      // instead of starting provider OAuth (no dead buttons).
      expect(linkTile.onTap, isNotNull);
      await tester.tap(find.text('Mit Google sichern'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(operations.linkCalls, 0);
    },
  );

  testWidgets(
    'pending local-cleanup deletion offers retry but keeps reset actions locked',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final operations = _SettingsAccountOperations()
        ..pending.value = AccountUiPendingState.deletionLocalCleanup;

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final retry = find.text('Erneut versuchen');
      await _ensureSettingsActionVisible(tester, retry);
      expect(retry, findsOneWidget);
      // The local reset stays available: its wipe preserves the deletion
      // journal, so a stuck remote deletion can no longer hold it hostage.
      final reset = find.text('Alle Daten zurücksetzen');
      await _ensureSettingsActionVisible(tester, reset);
      expect(
        tester
            .widget<ListTile>(
              find.ancestor(of: reset, matching: find.byType(ListTile)),
            )
            .onTap,
        isNotNull,
      );
      // Account delete responds with the deletion-pending explanation and its
      // retry — never a new-deletion confirm while the journal is unresolved.
      final delete = find.text('Konto und alle Daten löschen');
      await _ensureSettingsActionVisible(tester, delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Löschung wird fortgesetzt'),
        ),
        findsOneWidget,
      );
      expect(find.text('Löschen'), findsNothing);
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blocked account journal reroutes durable backup and restore to the locked dialog',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final operations = _SettingsAccountOperations()
        ..pending.value = AccountUiPendingState.blocked;

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
            ),
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      for (final label in ['Jetzt sichern', 'Von Cloud wiederherstellen']) {
        await _ensureSettingsActionVisible(tester, find.text(label));
        final tile = tester.widget<ListTile>(
          find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
        );
        expect(tile.onTap, isNotNull, reason: label);
      }
      // A locked tap opens the locked-account dialog; the cloud operation
      // never runs.
      // (Restore is the last tile ensured visible above, so tap that one.)
      await tester.tap(find.text('Von Cloud wiederherstellen'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Backup erfolgreich ✓'), findsNothing);
    },
  );

  testWidgets(
    'delayed persisted journal keeps every durable action locked on the first frame',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final refreshStarted = Completer<void>();
      final releasePersistedRead = Completer<AccountUiPendingState>();
      final operations = _DelayedJournalAccountOperations(
        refreshStarted: refreshStarted,
        readPersistedState: () => releasePersistedRead.future,
      );

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
            ),
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await refreshStarted.future;

      // Every account tile responds from the first frame, but while the
      // persisted journal is still being read a tap only explains the lock —
      // no durable operation may start.
      for (final label in <String>[
        'Jetzt sichern',
        'Von Cloud wiederherstellen',
        'Abmelden',
        'Cloud-Daten löschen',
        'Konto und alle Daten löschen',
      ]) {
        await _ensureSettingsActionVisible(tester, find.text(label));
        final tile = tester.widget<ListTile>(
          find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
        );
        expect(tile.onTap, isNotNull, reason: label);
      }
      await _ensureSettingsActionVisible(
        tester,
        find.text('Jetzt sichern'),
        scrollDelta: -200,
      );
      await tester.tap(find.text('Jetzt sichern'));
      await tester.pumpAndSettle();
      expect(find.text('Dein Konto ist geschützt'), findsOneWidget);
      expect(find.text('Backup erfolgreich ✓'), findsNothing);
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();

      releasePersistedRead.complete(AccountUiPendingState.blocked);
      await tester.pump();

      // Once the journal is known, the account-delete tap reroutes to the
      // locked-account dialog — still no new-deletion confirm.
      final delete = find.text('Konto und alle Daten löschen');
      await _ensureSettingsActionVisible(tester, delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Löschen'), findsNothing);
    },
  );

  testWidgets('backup shows success only for a completed cloud result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = CloudWriteSessionController()..acquire('durable');
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
      CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: _ClearCloudBackupDeletionJournalStore(),
        gateway: _UnusedCloudBackupDeletionGateway(),
      ),
    );
    CloudSync.overrideOperationsForTesting(
      backupWithResult: () async => CloudWriteResult.blocked,
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final backup = find.text('Jetzt sichern');
    await _ensureSettingsActionVisible(tester, backup);
    await tester.tap(backup);
    await tester.pumpAndSettle();

    expect(find.text('Backup erfolgreich ✓'), findsNothing);
    expect(
      find.text(
        'Die sichere Prüfung konnte nicht abgeschlossen werden. '
        'Du kannst denselben Vorgang erneut versuchen.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'restore shows retry feedback when a fresh admission finds a pending journal',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sessions = CloudWriteSessionController()..acquire('durable');
      final journal = _MutableCloudBackupDeletionJournalStore();
      AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
        CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: _UnusedCloudBackupDeletionGateway(),
        ),
      );
      addTearDown(AuthService.resetCloudBackupDeletionForTesting);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
            ),
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final restore = find.text('Von Cloud wiederherstellen');
      await _ensureSettingsActionVisible(tester, restore);
      final tile = tester.widget<ListTile>(
        find.ancestor(of: restore, matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNotNull);

      journal.current = CloudBackupDeletionJournal.pending(
        session: const CloudWriteSession(
          uid: 'durable',
          epoch: 2,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'P' * 43,
      );
      await tester.tap(restore);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Die sichere Prüfung konnte nicht abgeschlossen werden. '
          'Du kannst denselben Vorgang erneut versuchen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Keine Cloud-Daten'), findsNothing);
    },
  );

  testWidgets('restore shows retry feedback for a typed stale result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = CloudWriteSessionController()..acquire('durable');
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
      CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: _ClearCloudBackupDeletionJournalStore(),
        gateway: _UnusedCloudBackupDeletionGateway(),
      ),
    );
    CloudSync.overrideOperationsForTesting(
      restoreWithResult: () async => CloudRestoreResult.stale,
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final restore = find.text('Von Cloud wiederherstellen');
    await _ensureSettingsActionVisible(tester, restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Die sichere Prüfung konnte nicht abgeschlossen werden. '
        'Du kannst denselben Vorgang erneut versuchen.',
      ),
      findsOneWidget,
    );
    expect(find.text('Keine Cloud-Daten'), findsNothing);
  });

  testWidgets('restore shows no-backup feedback for a typed empty result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = CloudWriteSessionController()..acquire('durable');
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
      CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: _ClearCloudBackupDeletionJournalStore(),
        gateway: _UnusedCloudBackupDeletionGateway(),
      ),
    );
    CloudSync.overrideOperationsForTesting(
      restoreWithResult: () async => CloudRestoreResult.empty,
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final restore = find.text('Von Cloud wiederherstellen');
    await _ensureSettingsActionVisible(tester, restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(find.text('Keine Cloud-Daten'), findsOneWidget);
    expect(
      find.text(
        'Die sichere Prüfung konnte nicht abgeschlossen werden. '
        'Du kannst denselben Vorgang erneut versuchen.',
      ),
      findsNothing,
    );
  });

  testWidgets('deletion failure is recoverable and redacts private details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cleanup = _DeletionCleanup()
      ..failure = StateError('proof-secret-789 raw Firebase failure');

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          accountDeletionWorkflow: AccountDeletionWorkflow(cleanup),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Konto und alle Daten löschen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(cleanup.deleteCalls, 0);

    await tester.tap(find.text('Löschen').last);
    await tester.pump();

    expect(cleanup.deleteCalls, 1);
    expect(find.textContaining('proof-secret-789'), findsNothing);
    expect(find.textContaining('raw Firebase failure'), findsNothing);
    expect(find.text('Löschung wird fortgesetzt'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('cloud-data deletion redacts provider errors', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletion: () async {
            throw StateError('proof-secret-456 raw Firestore detail');
          },
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Cloud-Daten löschen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen').last);
    await tester.pump();

    expect(find.textContaining('proof-secret-456'), findsNothing);
    expect(find.textContaining('raw Firestore detail'), findsNothing);
    expect(
      find.text('Cloud-Daten konnten nicht gelöscht werden.'),
      findsOneWidget,
    );
  });

  testWidgets('cloud-data deletion reports success only when completed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletion: () async => CloudWriteResult.blocked,
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Cloud-Daten l\u00f6schen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('L\u00f6schen').last);
    await tester.pump();

    expect(find.text('Cloud-Daten wurden gel\u00f6scht.'), findsNothing);
    expect(
      find.text('Cloud-Daten konnten nicht gel\u00f6scht werden.'),
      findsOneWidget,
    );
  });

  testWidgets('loading cloud deletion locks backup restore sign-out and link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.loading,
    );
    addTearDown(journalState.dispose);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletion: () async => CloudWriteResult.blocked,
          cloudDataDeletionJournalState: journalState,
        ),
      ),
    );
    await tester.pump();

    // While the journal state is still loading, account tiles respond but a
    // tap only shows the generic protection notice — nothing may act on an
    // undisclosed journal.
    for (final label in [
      'Jetzt sichern',
      'Von Cloud wiederherstellen',
      'Abmelden',
    ]) {
      await _ensureSettingsActionVisible(tester, find.text(label));
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNotNull, reason: label);
    }

    final retryLabel = find.text('Cloud-Daten l\u00f6schen');
    await _ensureSettingsActionVisible(tester, retryLabel, scrollDelta: -200);
    await tester.tap(retryLabel);
    await tester.pumpAndSettle();
    expect(find.text('Dein Konto ist geschützt'), findsOneWidget);
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();

    journalState.value = CloudBackupDeletionJournalState.pending;
    await tester.pump();
    // A confirmed pending journal resumes the exact saved request.
    await _ensureSettingsActionVisible(tester, retryLabel, scrollDelta: -200);
    await tester.tap(retryLabel);
    await tester.pumpAndSettle();
    expect(find.text('Cloud-Löschung fortsetzen'), findsOneWidget);
    await tester.tap(find.text('Jetzt fortsetzen'));
    await tester.pumpAndSettle();
    expect(
      find.text('Cloud-Daten konnten nicht gelöscht werden.'),
      findsOneWidget,
    );

    final accountDeleteLabel = find.text('Konto und alle Daten l\u00f6schen');
    await _ensureSettingsActionVisible(tester, accountDeleteLabel);
    // Account delete responds with the cloud-resume explanation instead of a
    // dead tap while that journal is unresolved.
    await tester.tap(accountDeleteLabel);
    await tester.pumpAndSettle();
    expect(find.text('Cloud-Löschung wird fortgesetzt'), findsOneWidget);
  });

  testWidgets('retry after local cleanup failure never deletes a new account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cleanup = _DeletionCleanup()..imageFailures = 1;

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          accountDeletionWorkflow: AccountDeletionWorkflow(cleanup),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Konto und alle Daten löschen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen').last);
    await tester.pump();
    expect(cleanup.deleteCalls, 1);

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();

    expect(cleanup.deleteCalls, 1);
    expect(cleanup.imageCalls, 2);
  });

  testWidgets(
    'reset closes its dialog and shows a safe retry message when a journal appears',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
            resetAllData: () async {
              throw const CloudBackupDeletionResetBlockedException();
            },
          ),
        ),
      );
      await tester.pump();

      final reset = find.text('Alle Daten zurücksetzen');
      await _ensureSettingsActionVisible(tester, reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alle Daten zurücksetzen'), findsOneWidget);
      expect(
        find.text(
          'Die sichere Prüfung konnte nicht abgeschlossen werden. '
          'Du kannst denselben Vorgang erneut versuchen.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'reset does not pop settings when its dialog was already dismissed',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final startedReset = Completer<void>();
      final releaseReset = Completer<void>();

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
            resetAllData: () async {
              startedReset.complete();
              await releaseReset.future;
              throw const CloudBackupDeletionResetBlockedException();
            },
          ),
        ),
      );
      await tester.pump();

      final reset = find.text('Alle Daten zurücksetzen');
      await _ensureSettingsActionVisible(tester, reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await startedReset.future;
      await tester.pump();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      releaseReset.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alle Daten zurücksetzen'), findsOneWidget);
      expect(
        find.text(
          'Die sichere Prüfung konnte nicht abgeschlossen werden. '
          'Du kannst denselben Vorgang erneut versuchen.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('settings hides presentation without losing companion identity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await MascotPreference.set(MascotKind.magpie);
    await MascotPreference.setVisible(false);
    addTearDown(() => MascotPreference.set(MascotKind.tiger));

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final visibility = find.text('Lernfreund anzeigen');
    await _ensureSettingsActionVisible(tester, visibility);
    final visibilityTile = tester.widget<SwitchListTile>(
      find.ancestor(of: visibility, matching: find.byType(SwitchListTile)),
    );
    expect(visibilityTile.value, isFalse);
    expect(MascotPreference.chosenKind, MascotKind.magpie);
    expect(MascotPreference.selectedKind, isNull);

    await tester.tap(visibility);
    await tester.pumpAndSettle();

    expect(MascotPreference.chosenKind, MascotKind.magpie);
    expect(MascotPreference.selectedKind, MascotKind.magpie);
  });

  testWidgets(
    'settings and data sources reflow across the locked DE/EN matrix',
    (tester) async {
      const locales = [
        (
          locale: Locale('de'),
          title: 'Einstellungen',
          dataSources: 'Datenquellen',
          close: 'Schließen',
        ),
        (
          locale: Locale('en'),
          title: 'Settings',
          dataSources: 'Data sources',
          close: 'Close',
        ),
      ];
      const viewports = [
        (size: Size(320, 640), textScale: 2.0),
        (size: Size(360, 400), textScale: 1.0),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final locale in locales) {
        for (final viewport in viewports) {
          tester.view.physicalSize = viewport.size;
          await tester.pumpWidget(
            _wrapForLocale(
              SettingsScreen(
                key: ValueKey(
                  '${locale.locale}-${viewport.size}-${viewport.textScale}',
                ),
                account: _guest,
                accountOperations: _SettingsAccountOperations(),
                cloudDataDeletionJournalState: cloudJournalState,
                appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
              ),
              locale: locale.locale,
              textScaler: TextScaler.linear(viewport.textScale),
            ),
          );
          await tester.pump();

          expect(find.text(locale.title), findsOneWidget);
          final dataSources = find.text(locale.dataSources);
          await _scrollSettingsUntilBuilt(tester, dataSources);
          await tester.tap(dataSources);
          await tester.pumpAndSettle();

          final sheet = find.byType(DraggableScrollableSheet);
          expect(sheet, findsOneWidget);
          expect(tester.takeException(), isNull);
          final close = find.text(locale.close);
          final sheetScrollable = find
              .descendant(of: sheet, matching: find.byType(Scrollable))
              .first;
          final longLicense = find.text(
            'Translation output: factual data, attribution voluntary',
          );
          await _scrollUntilBuilt(tester, longLicense, sheetScrollable);
          expect(longLicense, findsOneWidget);
          expect(tester.takeException(), isNull);
          await _scrollUntilBuilt(tester, close, sheetScrollable);
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(sheet, findsNothing);
        }
      }
    },
  );
}

const _guest = AuthAccountSnapshot(
  providers: AuthProviderState(isGoogleLinked: false, isAppleLinked: false),
);

class _FakeNotificationSettingsOperations
    implements NotificationSettingsOperations {
  _FakeNotificationSettingsOperations({required this.granted});

  final bool granted;
  int permissionRequests = 0;
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<void> enable({
    required int hour,
    required String title,
    required String body,
    required String streakTitle,
    required String streakBody,
  }) async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

class _FixedAppVersionReader implements AppVersionReader {
  const _FixedAppVersionReader(this.version);

  final String version;

  @override
  Future<String> readVersion() async => version;
}

class _ThrowingAppVersionReader implements AppVersionReader {
  const _ThrowingAppVersionReader();

  @override
  Future<String> readVersion() async {
    throw StateError('native package metadata unavailable');
  }
}

class _SettingsAccountOperations
    implements AccountUiOperations, AccountUiPendingStateSource {
  int linkCalls = 0;
  final ValueNotifier<AccountUiPendingState> pending =
      ValueNotifier<AccountUiPendingState>(AccountUiPendingState.none);

  @override
  ValueListenable<AccountUiPendingState> get pendingState => pending;

  @override
  Future<AccountUiPendingState> refreshPendingState() async => pending.value;

  @override
  bool get appleSignInAvailable => false;

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
    linkCalls += 1;
    return const AccountUiLinkCompleted();
  }

  @override
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountSwitchResult(AccountSwitchStatus.completed);
}

class _DelayedJournalAccountOperations extends _SettingsAccountOperations {
  _DelayedJournalAccountOperations({
    required this.refreshStarted,
    required this.readPersistedState,
  });

  final Completer<void> refreshStarted;
  final Future<AccountUiPendingState> Function() readPersistedState;

  @override
  Future<AccountUiPendingState> refreshPendingState() async {
    if (!refreshStarted.isCompleted) {
      refreshStarted.complete();
    }
    final state = await readPersistedState();
    pending.value = state;
    return state;
  }
}

class _ClearCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async =>
      true;

  @override
  Future<CloudBackupDeletionJournal?> read() async => null;

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    throw UnimplementedError();
  }
}

class _MutableCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  CloudBackupDeletionJournal? current;

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async {
    if (current != expected) return false;
    current = null;
    return true;
  }

  @override
  Future<CloudBackupDeletionJournal?> read() async => current;

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    current = journal;
  }
}

class _UnusedCloudBackupDeletionGateway implements CloudBackupDeletionGateway {
  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    throw UnimplementedError();
  }
}

class _DeletionCleanup implements AccountDeletionCleanupOperations {
  Object? failure;
  int deleteCalls = 0;
  int imageFailures = 0;
  int imageCalls = 0;

  @override
  Future<void> clearTtsCache() async {}

  @override
  Future<void> deleteLocalImages() async {
    imageCalls += 1;
    if (imageFailures > 0) {
      imageFailures -= 1;
      throw StateError('private local image failure');
    }
  }

  @override
  Future<void> deleteRemoteAccount() async {
    deleteCalls += 1;
    if (failure case final value?) throw value;
  }

  @override
  Future<void> disablePush() async {}

  @override
  void resetInMemoryData() {}

  @override
  Future<void> resetLocalStorage() async {}
}

Widget _wrap(Widget child) {
  return _wrapForLocale(child, locale: const Locale('de'));
}

Widget _wrapForLocale(
  Widget child, {
  required Locale locale,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: appChild!,
    ),
    home: child,
  );
}

Future<void> _ensureSettingsActionVisible(
  WidgetTester tester,
  Finder finder, {
  double scrollDelta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    scrollDelta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _centerInCurrentScrollable(
  WidgetTester tester,
  Finder target,
) async {
  await tester.scrollUntilVisible(
    target,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(target),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pump();
}

Future<void> _scrollSettingsUntilBuilt(
  WidgetTester tester,
  Finder finder,
) async {
  await _scrollUntilBuilt(tester, finder, find.byType(Scrollable).first);
}

Future<void> _scrollUntilBuilt(
  WidgetTester tester,
  Finder finder,
  Finder scrollable,
) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pump();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
}
