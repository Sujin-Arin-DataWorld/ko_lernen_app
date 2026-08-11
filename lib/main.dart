import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import 'theme.dart';
import 'motion/transitions.dart';
import 'services/data_migration_service.dart';
import 'services/diagnostics_service.dart';
import 'services/storage_service.dart';
import 'services/audio_policy.dart';
import 'services/locale_service.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/cloud_auto_sync.dart';
import 'services/book_image_service.dart';
import 'services/bookshelf_service.dart';
import 'services/crop_recovery_service.dart';
import 'services/content_feedback_service.dart';
import 'services/content_feedback_lifecycle.dart';
import 'services/picker_recovery_service.dart';
import 'services/palette_service.dart';
import 'services/premium_service.dart';
import 'services/scene_asset_resolver.dart';
import 'services/notification_service.dart';
import 'services/privacy_consent_service.dart';
import 'services/push_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_options.dart';
import 'services/account/account_failure_diagnostics.dart';
import 'services/account/firebase_app_check_initializer.dart';
import 'services/account/account_operation_client.dart';
import 'services/app_startup_coordinator.dart';
import 'services/course_mission_navigation.dart';
import 'l10n/generated/app_localizations.dart';
import 'models/curriculum.dart';
import 'models/personal_room.dart';
import 'screens/splash_screen.dart';
import 'screens/quick_onboarding_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/intro_gate_screen.dart';
import 'screens/app_shell.dart';
import 'screens/paywall_screen.dart';
import 'screens/review_session_screen.dart';
import 'screens/smalltalk_screen.dart';
import 'screens/book_capture_screen.dart';
import 'screens/book_preview_screen.dart';
import 'screens/book_result_screen.dart';
import 'screens/bookshelf_page_screen.dart';
import 'screens/bookshelf_screen.dart';
import 'screens/custom_pack_play_screen.dart';
import 'screens/custom_pack_edit_screen.dart';
import 'screens/custom_pack_quiz_screen.dart';
import 'screens/custom_pack_matching_screen.dart';
import 'screens/custom_pack_typing_screen.dart';
import 'screens/wordbook_search_screen.dart';
import 'screens/hard_words_screen.dart';
import 'screens/bojagi_screen.dart';
import 'screens/dojangcheop_screen.dart';
import 'screens/gye_create_screen.dart';
import 'screens/gye_join_screen.dart';
import 'screens/gye_members_screen.dart';
import 'screens/gye_screen.dart';
import 'screens/gye_tab_screen.dart';
import 'screens/learning_path_screen.dart';
import 'screens/legacy_vocab_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/vocab_pack_result_screen.dart';
import 'screens/vocab_pack_screen.dart';
import 'screens/vocab_packs_screen.dart';
import 'screens/grammar_screen.dart';
import 'screens/kkeunmari_screen.dart';
import 'screens/listening_screen.dart';
import 'screens/chosung_quiz_screen.dart';
import 'screens/cloze_game_screen.dart';
import 'screens/daily_challenge_screen.dart';
import 'screens/satz_arcade_screen.dart';
import 'screens/speed_match_screen.dart';
import 'screens/wordle_screen.dart';
import 'screens/hanok_world_screen.dart';
import 'screens/personal_room_furnish_screen.dart';
import 'screens/practice_hub_screen.dart';
import 'screens/sarangbang_furnish_screen.dart';
import 'screens/sarangbang_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/hangul_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/onboarding_level_screen.dart';
import 'screens/onboarding_start_screen.dart';
import 'screens/course_mission_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scenario_player_screen.dart';
import 'screens/scenarios_list_screen.dart';
import 'widgets/sori/dancheong_burst.dart';
import 'widgets/sori/content_feedback_card.dart';
import 'widgets/sori/tiger_video.dart';
import 'widgets/sori/mascot_preference.dart';
import 'widgets/sori/diagnostics_route_observer.dart';
import 'widgets/sori/route_observer.dart';

/// The app adapts its navigation and content to both tablet orientations.
/// Keeping this explicit prevents a portrait-only startup lock from silently
/// invalidating the landscape layout contract.
const List<DeviceOrientation> kAppSupportedOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistente Speicher initialisieren (vor runApp wichtig)
  await Storage.init();

  // 로컬 스키마 점검 — Storage.init() 직후, 어떤 학습 데이터에 손대기 전에.
  // 로컬 전용이라 빠르고 네트워크를 타지 않는다. 실패해도 앱은 뜨며, 그 경우
  // 학습 데이터 쓰기만 잠긴다(DataMigrationService 가 처리).
  DataMigrationResult? migration;
  try {
    migration = await DataMigrationService.run();
  } catch (error) {
    debugPrint('Data migration skipped: $error');
  }

  await Storage.touchStreak();
  // SFX 전역 오디오 세션: 타 앱 음악과 mix + 무음 스위치 존중 (ADR-002 §5-3).
  await AudioPolicy.instance.applyPlatformAudioContext();
  try {
    await BookImageService.initialize();
  } catch (error) {
    debugPrint('Managed media reconciliation skipped: $error');
  }
  try {
    await CropRecoveryService.recoverAtStartup(
      isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    );
  } catch (error) {
    debugPrint('Android crop recovery skipped: $error');
  }
  try {
    await PickerRecoveryService.recoverAtStartup(
      isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    );
  } catch (error) {
    debugPrint('Android picker recovery skipped: $error');
  }

  // Firebase, anonymous auth, RevenueCat, and optional FCM are ordered in the
  // background so cloud startup never delays runApp().
  unawaited(_startCloudServices());

  // AdMob best-effort initialisieren (im Hintergrund)
  // ignore: discarded_futures, unawaited_futures
  _initAds();

  // Lokale Benachrichtigungen (M3) best-effort initialisieren.
  // ignore: discarded_futures, unawaited_futures
  NotificationService.init();

  // 2026-08-06: Rive 런타임 초기화 제거. 프레임 시퀀스(TigerStage)와 Rive 폴백
  // (TigerStageRive)을 함께 폐지했다 — 어떤 화면도 TigerStageVideo 를 만들지
  // 않고, 캐릭터는 CharacterClipPlayer + assets/video/character/ 가 정본이며
  // 영상이 불가한 경우(reduce-motion 포함)엔 정적 Mascot PNG 로 떨어진다.

  // 캐릭터/호랑이 영상 전역 게이트. 별도 init 불필요 — 플래그만.
  // 테스트는 videoReady 기본 false 유지 → 프레임/마스코트 폴백(이 줄은 main).
  // ⚠️ Android <33 Impeller 영상 텍스처 fence 버그("ImageTextureEntry can't
  // wait on the fence on Android < 33")는 AndroidManifest 에서 Impeller 를 끄고
  // (Skia 렌더러) 근본 해소했다. Skia 는 SurfaceTexture 경로라 fence 문제가 없어
  // 모든 Android 버전에서 캐릭터 영상이 정상 렌더된다 → 영상 허용(fail-open).
  // 동시 디코더는 video_lease 가 1개로 직렬화한다(구형 기기 decoder reclaim 대응).
  // ⚠️ Impeller 를 다시 켜면(매니페스트) 여기 sdkInt>=33 게이트를 되살려야 한다.
  //   (Jin 실기기 M2101K6G/Android 12=API31: 이전 sdkInt>=33 게이트가 영상을
  //    통째로 막아 홈·프로필이 전부 정적 폴백으로 떨어졌다 — 2026-08-06.)
  // 위 사유로 캐릭터 영상은 항상 허용(fail-open). 예전 `async => true` 를 await
  // 하던 불필요한 async 홉을 제거 — runApp 전 마이크로태스크 1회 절약.
  TigerStageVideo.videoReady = true;

  // 선택된 캐릭터를 전역 notifier 로 올린다. Storage 초기화 뒤여야 한다.
  // 이걸 빼면 홈·게임·레슨완료가 전부 호랑이로 고정된다(2026-07-31 배선 수정).
  MascotPreference.load();

  // The resolver must finish before the first frame. Otherwise a dedicated
  // per-scenario illustration can be silently replaced by its category
  // fallback for the lifetime of the already-built screen.
  await SceneAssetResolver.load();

  // 정답 축하 스프라이트(복주머니·엽전) 미리 디코딩 — 첫 정답에서 폴백이 뜨는 걸 막는다.
  // 실패해도 조용히 넘어가고 절차적 burst로 폴백. runApp 무지연.
  // ignore: discarded_futures, unawaited_futures
  DancheongBurst.preload();

  // Allow phones, foldables, and tablets to use their natural orientation.
  // await 제거: 방향·시스템UI 설정은 플랫폼 채널에 호출 순서대로 큐잉되는
  // fire-and-set 이라 첫 프레임을 기다릴 필요가 없다 — runApp 전 플랫폼 왕복 2회
  // 절약(edge-to-edge/방향은 관대해 첫 프레임 직전 적용돼도 무해). 순서 보장은
  // 채널 큐가 유지하므로 아래 setSystemUIOverlayStyle 와의 순서도 그대로다.
  // ignore: discarded_futures, unawaited_futures
  SystemChrome.setPreferredOrientations(kAppSupportedOrientations);

  // 시스템바: edge-to-edge(Flutter 권장) + 화면별 SafeArea가 inset 담당.
  // MediaQuery가 상태바/네비바 inset을 정확히 보고 → SafeArea가 콘텐츠를 그 위로
  // 올려 잘림 방지. (manual 모드는 일부 기기서 inset 보고가 깨져 회귀했었음.)
  // ignore: discarded_futures, unawaited_futures
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // 밝은 한지(cream) 배경 위 → 시스템바 아이콘은 어둡게(가독성 확보).
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light, // iOS
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // 크래시 재현용 문맥. 동의가 꺼져 있으면 전부 no-op 이고, 어느 경우에도
  // runApp 을 지연시키지 않는다.
  // ignore: discarded_futures, unawaited_futures
  _recordStartupDiagnostics(migration);

  runApp(const KoLernenApp());
}

/// 시작 시점에 확정되는 진단 키를 기록한다.
///
/// 값은 전부 짧은 식별자·enum 이름이라 PII 가 없다(DiagnosticsService 가 키를
/// 봉인하고 값 길이도 자른다).
Future<void> _recordStartupDiagnostics(DataMigrationResult? migration) async {
  try {
    final info = await PackageInfo.fromPlatform();
    await DiagnosticsService.setKeys({
      DiagnosticKey.appVersion: info.version,
      DiagnosticKey.buildNumber: info.buildNumber,
      DiagnosticKey.gitCommit: const String.fromEnvironment(
        'GIT_COMMIT',
        defaultValue: 'unknown',
      ),
      if (migration != null)
        DiagnosticKey.schemaVersion: migration.diagnosticValue,
    });
  } catch (error) {
    debugPrint('Startup diagnostics skipped: $error');
  }
}

Future<void> _startCloudServices() async {
  final coordinator = AppStartupCoordinator(
    initializeFirebase: _initFirebase,
    initializeAppCheck: FirebaseAppCheckInitializer.production().initialize,
    ensureSignedIn: AuthService.ensureSignedIn,
    currentUserId: () => AuthService.current?.uid,
    restorePendingAccountState: AuthService.restorePendingAccountState,
    synchronizeReadySession: AuthService.synchronizeReadyCloudWriteSession,
    resumeFeedbackOutbox: () async {
      await _contentFeedbackLifecycle.resumePending();
    },
    resumeFirstDurableLinkBackfill:
        AuthService.resumePendingFirstDurableLinkBackfill,
    resumeMediaCleanup: BookImageService.initialize,
    resumeBookshelfSync: BookshelfService.resumePendingSync,
    resumeAccountOperation: () => AuthService.resumePendingAccountDeletion(
      closeFeedback: _contentFeedbackLifecycle.closeAndDiscard,
    ),
    resumeAccountDeletionByReceipt: () =>
        AuthService.resumePendingAccountDeletionByReceipt(
          closeFeedback: _contentFeedbackLifecycle.closeAndDiscard,
        ),
    resumeCloudBackupDeletion: () async {
      await AuthService.resumePendingCloudBackupDeletion();
    },
    resumeCloudAutoSync: () async {
      await CloudAutoSync.runStartupSync();
    },
    resumeCompletedFeedbackActivation: () async {
      final finalized =
          await AuthService.finalizePendingAccountDeletionFeedback(
            closeFeedback: _contentFeedbackLifecycle.closeAndDiscard,
            activateFeedback:
                _contentFeedbackLifecycle.activateAfterCompletedDeletion,
          );
      if (!finalized) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        );
      }
    },
    initializePremium: () async {
      await PaletteService.fetchAndApply();
      await PremiumService.init();
    },
    enablePush: () async {
      await pushService.enable();
    },
    notificationsEnabled: () => Storage.notificationsEnabled,
  );
  try {
    await coordinator.start();
  } catch (error) {
    AccountFailureDiagnostics.log('startup.cloudSkipped', error);
    debugPrint('Cloud startup skipped.');
  }
}

Future<bool> _contentFeedbackDeletionActive() =>
    AuthService.runDurableAccountAdmission<bool>(
      onAdmitted: () async => false,
      onBlocked: () async => true,
    );

Future<bool> _contentFeedbackActivationBlocked(String deletedUid) =>
    AuthService.runCompletedDeletionFeedbackActivationAdmission<bool>(
      deletedUid: deletedUid,
      onAdmitted: () async => false,
      onBlocked: () async => true,
    );

ContentFeedbackService _createContentFeedbackService() =>
    ContentFeedbackService.production(
      currentUid: () => AuthService.current?.uid,
      deletionActive: _contentFeedbackDeletionActive,
      platform: () =>
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      locale: () {
        final languageCode =
            localeNotifier.value?.languageCode ??
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        return languageCode == 'en' ? 'en' : 'de';
      },
    );

final ContentFeedbackLifecycle _contentFeedbackLifecycle =
    ContentFeedbackLifecycle(
      initialService: _createContentFeedbackService(),
      createService: _createContentFeedbackService,
      currentIdentity: () => (
        uid: AuthService.current?.uid,
        isAnonymous: AuthService.current?.isAnonymous ?? false,
      ),
      durableJournalActive: _contentFeedbackActivationBlocked,
    );

AccountDeletionWorkflow _createAccountDeletionWorkflow() =>
    AccountDeletionWorkflow.production(
      feedbackOutbox: _contentFeedbackLifecycle,
      activateFeedback:
          _contentFeedbackLifecycle.activateAfterCompletedDeletion,
    );

Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // DSGVO/TTDSG: Analytics + Crashlytics sind opt-in. Die Erhebung ist im
    // Manifest/Info.plist deaktiviert; hier wird die gespeicherte
    // Einwilligung (Default: aus) auf die SDKs angewendet.
    await PrivacyConsentService.applyStored();
    PrivacyConsentService.installErrorHandlers();
    return true;
  } catch (_) {
    // google-services.json fehlt → Cloud-Sync deaktiviert, lokale App funktioniert weiter
    // ignore: avoid_print
    debugPrint('Firebase init skipped.');
    return false;
  }
}

Future<void> _initAds() async {
  try {
    await AdService.init();
    await AdService.preloadInterstitial();
  } catch (_) {
    // best-effort
  }
}

class ContentFeedbackLifecycleObserver extends StatefulWidget {
  const ContentFeedbackLifecycleObserver({
    super.key,
    required this.resumePending,
    required this.onResumeResult,
    required this.child,
  });

  final Future<ContentFeedbackResumeResult> Function() resumePending;
  final ValueChanged<ContentFeedbackResumeResult> onResumeResult;
  final Widget child;

  @override
  State<ContentFeedbackLifecycleObserver> createState() =>
      _ContentFeedbackLifecycleObserverState();
}

class _ContentFeedbackLifecycleObserverState
    extends State<ContentFeedbackLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumePending());
    }
  }

  Future<void> _resumePending() async {
    try {
      final result = await widget.resumePending();
      if (!mounted) return;
      widget.onResumeResult(result);
    } catch (_) {
      debugPrint('Feedback outbox resume skipped.');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class KoLernenApp extends StatefulWidget {
  const KoLernenApp({super.key});

  @override
  State<KoLernenApp> createState() => _KoLernenAppState();
}

class _KoLernenAppState extends State<KoLernenApp> {
  final _resumeDeliveryNotifier = ContentFeedbackResumeDeliveryNotifier();

  @override
  void dispose() {
    _resumeDeliveryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localeNotifier, paletteVariantNotifier]),
      builder: (_, __) => MaterialApp(
        title: 'Hangul Sori',
        debugShowCheckedModeBanner: false,
        // Dark Mode deaktiviert (v2.0): App immer im Light-Theme.
        // darkTheme spiegelt das Light-Theme, falls das System Dark erzwingt.
        theme: AppTheme.lightFor(paletteVariantNotifier.value),
        darkTheme: AppTheme.lightFor(paletteVariantNotifier.value),
        themeMode: ThemeMode.light,
        // 영상 위젯이 "내 화면 위에 다른 화면이 올라왔는지"를 알아야
        // 디코더를 놓을 수 있다 (route_observer.dart 주석 참조).
        navigatorObservers: [soriRouteObserver, DiagnosticsRouteObserver()],
        locale: localeNotifier.value,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        // Tap außerhalb von Inputs → Tastatur weg
        builder: (context, child) => ContentFeedbackControllerScope(
          featureGate: _contentFeedbackLifecycle.featureGate,
          submitFeedback: _contentFeedbackLifecycle.submit,
          resumePending: _contentFeedbackLifecycle.resumePending,
          resumeDeliveryNotifier: _resumeDeliveryNotifier,
          readPassportState: _contentFeedbackLifecycle.readPassportState,
          child: ContentFeedbackLifecycleObserver(
            resumePending: _contentFeedbackLifecycle.resumePending,
            onResumeResult: _resumeDeliveryNotifier.report,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            ),
          ),
        ),
        // 로고 스플래시(2초) → 솟을대문 인트로 → 온보딩/홈
        // 모든 화면 전환은 SoriTransitions (fade + 깊이 scale-in) — "상자 슬라이드" 탈피.
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/splash':
              return SoriTransitions.fadeScale(
                (_) => const SplashScreen(),
                settings: settings,
              );
            case '/quick_onboarding':
              return SoriTransitions.fadeScale(
                (_) => const QuickOnboardingScreen(),
                settings: settings,
              );
            case '/character_selection':
              return SoriTransitions.fadeScale(
                (_) => const CharacterSelectionScreen(),
                settings: settings,
              );
            case '/intro':
              return SoriTransitions.fadeScale(
                (_) => const IntroGateScreen(),
                settings: settings,
              );
            case '/':
              return SoriTransitions.fadeScale(
                (_) => const AppShell(),
                settings: settings,
              );
            case '/onboarding':
              return SoriTransitions.fadeScale(
                (_) => const OnboardingLevelScreen(),
                settings: settings,
              );
            case '/onboarding/start':
              return SoriTransitions.fadeScale(
                (_) => const OnboardingStartScreen(),
                settings: settings,
              );
            case '/vocab':
              // Phase 2 (stately-rising-jongga): default vocab entry =
              // Pack-Marktplatz (Grid).
              final vocabCourseContext =
                  coursePracticeContextFromRouteArguments(
                    settings.arguments,
                    CurriculumContentKind.vocab,
                  );
              final vocabCourseUnitId = courseUnitIdFromVocabRouteArguments(
                settings.arguments,
              );
              return SoriTransitions.fadeScale(
                (_) => VocabPacksScreen(
                  courseUnitId: vocabCourseUnitId,
                  courseContext: vocabCourseContext,
                ),
                settings: settings,
              );
            case '/vocab/pack':
              final packId =
                  vocabPackIdFromRouteArguments(settings.arguments) ?? '';
              final packCourseContext =
                  vocabCourseContextFromPackRouteArguments(settings.arguments);
              return SoriTransitions.fadeScale(
                (_) => VocabPackScreen(
                  packId: packId,
                  courseContext: packCourseContext,
                ),
                settings: settings,
              );
            case '/vocab/result':
              return SoriTransitions.fadeScale(
                (_) => VocabPackResultScreen.fromArgs(settings.arguments),
                settings: settings,
              );
            case '/vocab/legacy':
              // Rollback / Power-User: alte single-card Ansicht (Phase 1
              // SRS-UX-Patch). Wird in Phase 3 entfernt, sobald Pack-UX
              // produktiv läuft.
              return SoriTransitions.fadeScale(
                (_) => const LegacyVocabScreen(),
                settings: settings,
              );
            case '/grammar':
              final grammarCourseContext =
                  coursePracticeContextFromRouteArguments(
                    settings.arguments,
                    CurriculumContentKind.grammar,
                  );
              return SoriTransitions.fadeScale(
                (_) => GrammarScreen(courseContext: grammarCourseContext),
                settings: settings,
              );
            case '/listening':
              return SoriTransitions.fadeScale(
                (_) => const ListeningScreen(),
                settings: settings,
              );
            case '/kkeunmari':
              return SoriTransitions.fadeScale(
                (_) => const KkeunmariScreen(),
                settings: settings,
              );
            case '/hangul':
              return SoriTransitions.fadeScale(
                (_) => const HangulScreen(),
                settings: settings,
              );
            case '/chosung':
              return SoriTransitions.fadeScale(
                (_) => const ChosungQuizScreen(),
                settings: settings,
              );
            case '/wordle':
              return SoriTransitions.fadeScale(
                (_) => const WordleScreen(),
                settings: settings,
              );
            case '/cloze':
              final clozeCourseUnitId = settings.arguments as String?;
              return SoriTransitions.fadeScale(
                (_) => ClozeGameScreen(courseUnitId: clozeCourseUnitId),
                settings: settings,
              );
            case '/speed_match':
              return SoriTransitions.fadeScale(
                (_) => const SpeedMatchScreen(),
                settings: settings,
              );
            case '/daily':
              return SoriTransitions.fadeScale(
                (_) => const DailyChallengeScreen(),
                settings: settings,
              );
            case '/practice':
              return SoriTransitions.fadeScale(
                (_) => const PracticeHubScreen(),
                settings: settings,
              );
            case '/satz_arcade':
              final satzCourseUnitId = settings.arguments as String?;
              return SoriTransitions.fadeScale(
                (_) => SatzArcadeScreen(courseUnitId: satzCourseUnitId),
                settings: settings,
              );
            case '/settings':
              return SoriTransitions.fadeScale(
                (_) => SettingsScreen(
                  accountDeletionWorkflow: _createAccountDeletionWorkflow(),
                ),
                settings: settings,
              );
            case '/stats':
              return SoriTransitions.fadeScale(
                (_) => const StatsScreen(),
                settings: settings,
              );
            case '/profile':
              return SoriTransitions.fadeScale(
                (_) => const ProfileScreen(),
                settings: settings,
              );
            case '/paywall':
              return SoriTransitions.fadeScale(
                (_) => const PaywallScreen(),
                settings: settings,
              );
            case '/review':
              return SoriTransitions.fadeScale(
                (_) => const ReviewSessionScreen(
                  feedbackContentId: 'today_review',
                ),
                settings: settings,
              );
            case '/smalltalk':
              final smalltalkCourseContext =
                  coursePracticeContextFromRouteArguments(
                    settings.arguments,
                    CurriculumContentKind.smalltalk,
                  );
              return SoriTransitions.fadeScale(
                (_) => SmalltalkScreen(courseContext: smalltalkCourseContext),
                settings: settings,
              );
            case '/scenarios':
              return SoriTransitions.fadeScale(
                (_) => const ScenariosListScreen(),
                settings: settings,
              );
            case '/quests':
              return SoriTransitions.fadeScale(
                (_) => const QuestsScreen(),
                settings: settings,
              );
            // Phase 5 (stately-rising-jongga) — "책 한 컷"
            case '/book':
              return SoriTransitions.fadeScale(
                (_) => const BookCaptureScreen(),
                settings: settings,
              );
            case '/book/preview':
              final args =
                  (settings.arguments as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
              return SoriTransitions.fadeScale(
                (_) => BookPreviewScreen(args: args),
                settings: settings,
              );
            case '/book/result':
              final args =
                  (settings.arguments as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
              return SoriTransitions.fadeScale(
                (_) => BookResultScreen(args: args),
                settings: settings,
              );
            // Phase 5.1 — Bookshelf + Custom Pack
            case '/bookshelf':
              return SoriTransitions.fadeScale(
                (_) => const BookshelfScreen(),
                settings: settings,
              );
            case '/bookshelf/page':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => BookshelfPageScreen(pageId: id),
                settings: settings,
              );
            case '/custom_pack/play':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => CustomPackPlayScreen(packId: id),
                settings: settings,
              );
            case '/custom_pack/edit':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => CustomPackEditScreen(packId: id),
                settings: settings,
              );
            case '/custom_pack/quiz':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => CustomPackQuizScreen(packId: id),
                settings: settings,
              );
            case '/custom_pack/matching':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => CustomPackMatchingScreen(packId: id),
                settings: settings,
              );
            case '/custom_pack/typing':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => CustomPackTypingScreen(packId: id),
                settings: settings,
              );
            case '/wordbook/search':
              return SoriTransitions.fadeScale(
                (_) => const WordbookSearchScreen(),
                settings: settings,
              );
            case '/hard_words':
              return SoriTransitions.fadeScale(
                (_) => const HardWordsScreen(),
                settings: settings,
              );
            case '/dojangcheop':
              return SoriTransitions.fadeScale(
                (_) => const DojangcheopScreen(),
                settings: settings,
              );
            case '/hanok':
              return SoriTransitions.fadeScale(
                (_) => const HanokWorldScreen(),
                settings: settings,
              );
            case '/hanok/anbang':
              return SoriTransitions.fadeScale(
                (_) => const PersonalRoomFurnishScreen(
                  surface: PersonalRoomSurface.anbang,
                ),
                settings: settings,
              );
            case '/hanok/daecheong':
              return SoriTransitions.fadeScale(
                (_) => const PersonalRoomFurnishScreen(
                  surface: PersonalRoomSurface.daecheongmaru,
                ),
                settings: settings,
              );
            case '/sarangbang':
              return SoriTransitions.fadeScale(
                (_) => const SarangbangStudyScreen(),
                settings: settings,
              );
            case '/sarangbang/furnish':
              return SoriTransitions.fadeScale(
                (_) => const SarangbangFurnishScreen(),
                settings: settings,
              );
            case '/bojagi':
              return SoriTransitions.fadeScale(
                (_) => const BojagiScreen(),
                settings: settings,
              );
            case '/gye/create':
              return SoriTransitions.fadeScale(
                (_) => const GyeCreateScreen(),
                settings: settings,
              );
            case '/gye/join':
              return SoriTransitions.fadeScale(
                (_) => const GyeJoinScreen(),
                settings: settings,
              );
            case '/gye/hub':
              return SoriTransitions.fadeScale(
                (_) => const GyeTabScreen(),
                settings: settings,
              );
            case '/gye':
              final gyeId = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => GyeScreen(gyeId: gyeId),
                settings: settings,
              );
            case '/gye/members':
              final gyeId = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => GyeMembersScreen(gyeId: gyeId),
                settings: settings,
              );
            case '/path':
              return SoriTransitions.fadeScale(
                (_) => const LearningPathScreen(),
                settings: settings,
              );
            case '/course/mission':
              final missionCourseUnitId = settings.arguments as String?;
              return SoriTransitions.fadeScale(
                (_) => CourseMissionScreen(courseUnitId: missionCourseUnitId),
                settings: settings,
              );
            case '/scenario':
              final scenarioContext = coursePracticeContextFromRouteArguments(
                settings.arguments,
                CurriculumContentKind.scenario,
              );
              final id = scenarioIdFromRouteArguments(settings.arguments) ?? '';
              return SoriTransitions.fadeScale(
                (_) => ScenarioPlayerScreen(
                  scenarioId: id,
                  courseContext: scenarioContext,
                ),
                settings: settings,
              );
            default:
              return SoriTransitions.fadeScale(
                (_) => const AppShell(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}
