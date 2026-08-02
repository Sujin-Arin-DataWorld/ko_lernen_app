import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import 'theme.dart';
import 'motion/transitions.dart';
import 'services/storage_service.dart';
import 'services/locale_service.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
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
import 'firebase_options.dart';
import 'services/account/firebase_app_check_initializer.dart';
import 'services/app_startup_coordinator.dart';
import 'l10n/generated/app_localizations.dart';
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
import 'screens/dojangcheop_screen.dart';
import 'screens/gye_create_screen.dart';
import 'screens/gye_join_screen.dart';
import 'screens/gye_members_screen.dart';
import 'screens/gye_screen.dart';
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
import 'screens/settings_screen.dart';
import 'screens/hangul_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/onboarding_level_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scenario_player_screen.dart';
import 'screens/scenarios_list_screen.dart';
import 'package:rive/rive.dart' show RiveNative;
import 'widgets/sori/dancheong_burst.dart';
import 'widgets/sori/content_feedback_card.dart';
import 'widgets/sori/tiger_stage_rive.dart';
import 'widgets/sori/tiger_video.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistente Speicher initialisieren (vor runApp wichtig)
  await Storage.init();
  await Storage.touchStreak();
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

  // Rive(살아있는 호랑이) 런타임 best-effort. 실패해도 앱은 프레임 폴백으로 정상
  // — TigerStageRive가 riveReady=false면 기존 TigerStage(프레임)를 쓴다.
  // ⚠️ 웹은 비활성화 (.riv 파일 path resolution 이슈, 프레임으로 충분함)
  if (!kIsWeb) {
    try {
      if (await RiveNative.init()) {
        TigerStageRive.riveReady = true;
      }
    } catch (_) {
      // 네이티브 미지원/초기화 실패 → 프레임 폴백 유지
    }
  }

  // 호랑이 영상(홈 밴드·온보딩 인사) 활성화. 별도 init 불필요 — 플래그만.
  // 테스트는 false 유지 → 프레임/마스코트 폴백(플러그인 채널 미호출).
  TigerStageVideo.videoReady = true;

  // The resolver must finish before the first frame. Otherwise a dedicated
  // per-scenario illustration can be silently replaced by its category
  // fallback for the lifetime of the already-built screen.
  await SceneAssetResolver.load();

  // 정답 축하 스프라이트(복주머니·엽전) 미리 디코딩 — 첫 정답에서 폴백이 뜨는 걸 막는다.
  // 실패해도 조용히 넘어가고 절차적 burst로 폴백. runApp 무지연.
  // ignore: discarded_futures, unawaited_futures
  DancheongBurst.preload();

  // Portrait sperren
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 시스템바: edge-to-edge(Flutter 권장) + 화면별 SafeArea가 inset 담당.
  // MediaQuery가 상태바/네비바 inset을 정확히 보고 → SafeArea가 콘텐츠를 그 위로
  // 올려 잘림 방지. (manual 모드는 일부 기기서 inset 보고가 깨져 회귀했었음.)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

  runApp(const KoLernenApp());
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
    resumeCompletedAccountCleanup: () =>
        _createCompletedAccountDeletionWorkflow().run(),
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
  } catch (_) {
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

AccountDeletionWorkflow _createCompletedAccountDeletionWorkflow() =>
    AccountDeletionWorkflow.completedStartupRecovery(
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

class KoLernenApp extends StatelessWidget {
  const KoLernenApp({super.key});

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
        locale: localeNotifier.value,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        // Tap außerhalb von Inputs → Tastatur weg
        builder: (context, child) => ContentFeedbackControllerScope(
          featureGate: _contentFeedbackLifecycle.featureGate,
          submitFeedback: _contentFeedbackLifecycle.submit,
          readPassportState: _contentFeedbackLifecycle.readPassportState,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
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
            case '/vocab':
              // Phase 2 (stately-rising-jongga): default vocab entry =
              // Pack-Marktplatz (Grid).
              return SoriTransitions.fadeScale(
                (_) => const VocabPacksScreen(),
                settings: settings,
              );
            case '/vocab/pack':
              final packId = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => VocabPackScreen(packId: packId),
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
              return SoriTransitions.fadeScale(
                (_) => const GrammarScreen(),
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
              return SoriTransitions.fadeScale(
                (_) => const ClozeGameScreen(),
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
            case '/satz_arcade':
              return SoriTransitions.fadeScale(
                (_) => const SatzArcadeScreen(),
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
              return SoriTransitions.fadeScale(
                (_) => const SmalltalkScreen(),
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
            case '/scenario':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => ScenarioPlayerScreen(scenarioId: id),
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
