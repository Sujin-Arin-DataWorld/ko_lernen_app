import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';

import 'theme.dart';
import 'config/ux_preview_feature.dart';
import 'features/guide/guide_runtime.dart';
import 'features/onboarding_v2/first_run_coordinator.dart';
import 'features/onboarding_v2/onboarding_rollout_service.dart';
import 'motion/transitions.dart';
import 'services/analytics_service.dart';
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
import 'services/pack_session_srs_ledger.dart';
import 'services/premium_service.dart';
import 'services/scene_asset_resolver.dart';
import 'services/splash_gate.dart';
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
import 'models/guide_contract.dart';
import 'models/personal_room.dart';
import 'models/scenario.dart';
import 'screens/splash_screen.dart';
import 'screens/daily_char_sheet.dart';
import 'screens/paywall_screen.dart';
import 'screens/review_session_screen.dart';
import 'screens/review_hub_screen.dart';
import 'screens/smalltalk_screen.dart';
import 'screens/media_phrase_screen.dart';
import 'screens/book_capture_screen.dart';
import 'screens/book_preview_screen.dart';
import 'screens/book_result_screen.dart';
import 'screens/vocab_notebook_practice_screen.dart';
import 'screens/vocab_notebook_result_screen.dart';
import 'screens/vocab_notebook_studio_screen.dart';
import 'screens/vocab_nuance_screen.dart';
import 'screens/bookshelf_page_screen.dart';
import 'screens/bookshelf_screen.dart';
import 'screens/custom_pack_play_screen.dart';
import 'screens/custom_pack_edit_screen.dart';
import 'screens/custom_pack_quiz_screen.dart';
import 'screens/custom_pack_matching_screen.dart';
import 'screens/custom_pack_typing_screen.dart';
import 'screens/wordbook_search_screen.dart';
import 'screens/hard_words_screen.dart';
import 'screens/word_web_screen.dart';
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
import 'screens/vocab_pack_recall_screen.dart';
import 'screens/vocab_pack_screen.dart';
import 'screens/vocab_packs_screen.dart';
import 'screens/grammar_screen.dart';
import 'screens/grammar_choice_quiz_screen.dart';
import 'screens/kkeunmari_screen.dart';
import 'screens/listening_screen.dart';
import 'screens/chosung_quiz_screen.dart';
import 'screens/cloze_game_screen.dart';
import 'screens/daily_challenge_screen.dart';
import 'screens/satz_arcade_screen.dart';
import 'screens/speed_match_screen.dart';
import 'screens/silben_kreuz_screen.dart';
import 'screens/ildu_world_screen.dart';
import 'screens/personal_room_furnish_screen.dart';
import 'screens/practice_hub_screen.dart';
import 'screens/pronunciation_studio_screen.dart';
import 'screens/sarangbang_furnish_screen.dart';
import 'screens/sarangbang_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/hangul_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/study_library_screen.dart';
import 'screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'screens/course_mission_screen.dart';
import 'screens/course_reassessment_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scenario_player_screen.dart';
import 'screens/scenarios_list_screen.dart';
import 'screens/ux_preview_app.dart';
import 'widgets/sori/dancheong_burst.dart';
import 'widgets/sori/content_feedback_card.dart';
import 'widgets/sori/tiger_video.dart';
import 'widgets/sori/tts_unavailable_banner.dart';
import 'widgets/sori/mascot_preference.dart';
import 'widgets/sori/diagnostics_route_observer.dart';
import 'widgets/sori/route_observer.dart';
import 'widgets/sori/type_scale.dart';

Future<void> main() => launchKoLernenApp();

/// Starts the read-only Gallery before any production service when its
/// debug-only compile-time gate is enabled. The injected callbacks exist only
/// so tests can prove this return boundary without initializing plugins.
@visibleForTesting
Future<void> launchKoLernenApp({
  UxPreviewFeatureGate featureGate = const UxPreviewFeatureGate(),
  void Function(Widget app)? runApplication,
  Future<void> Function()? startProduction,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // finding 7: Firebase 초기화 성공 여부·스플래시 진행과 완전히 독립적으로
  // 가장 먼저 설치한다. PrivacyConsentController.handleFlutterError/
  // handlePlatformError 는 이미 crashClient 호출 실패를 자체 try/catch 로
  // 감싸므로(Firebase 가 아직 없어도) 여기서 거는 게 안전하다 — 최악의
  // 경우 리포팅만 스킵되고 조용히 삼켜지진 않는다(debugPrint 남음).
  PrivacyConsentService.installErrorHandlers();
  final runner = runApplication ?? runApp;
  if (featureGate.isEnabled) {
    runner(const UxPreviewApp());
    return;
  }
  final injectedProductionStart = startProduction;
  if (injectedProductionStart != null) {
    await injectedProductionStart();
    return;
  }
  await _startProductionApplication(runner);
}

Future<void> _startProductionApplication(
  void Function(Widget app) runner,
) async {
  // Persistente Speicher initialisieren (vor runApp wichtig) — Storage's
  // synchronous getters (including the splash screen's 2s-later navigation
  // check, and MascotPreference.load() below) need this done first.
  await Storage.init();

  // 시스템바: edge-to-edge(Flutter 권장) + 화면별 SafeArea가 inset 담당.
  // MediaQuery가 상태바/네비바 inset을 정확히 보고 → SafeArea가 콘텐츠를 그 위로
  // 올려 잘림 방지. (manual 모드는 일부 기기서 inset 보고가 깨져 회귀했었음.)
  // 첫 프레임보다 늦게 적용하면 잘못된 상태바 스타일이 잠깐 노출된다 —
  // runApp 직전 최대한 앞에서 건다.
  // ignore: discarded_futures, unawaited_futures
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // 시스템바 색은 edge-to-edge 배경이 제공한다. Android 15에서 지원 중단된
      // setStatusBarColor/setNavigationBarColor 요청 없이 아이콘 대비만 제어한다.
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light, // iOS
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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

  // 두 준비 작업 모두 첫 프레임 전에 끝나야 하지만 서로 의존하지 않는다
  // (하나는 에셋 매니페스트 조회, 하나는 스프라이트 시트 디코딩) — 순차
  // await 대신 병렬로 실행해 콜드스타트를 단축한다.
  // 리졸버가 안 끝나면 전용 시나리오 일러스트가 카테고리 폴백으로 조용히
  // 대체된 채 이미 빌드된 화면 생애주기 내내 유지될 수 있고, 프리로드가
  // 안 끝나면 첫 축하가 절차적 폴백으로 떨어진다 — 그래서 runner() 전에
  // **둘 다** await 된다.
  // (계약: test/scene_asset_resolver_test.dart · test/dancheong_burst_preload_contract_test.dart
  // 가 "runner 이전 await 존재"로 이 순서를 고정한다 — Task 8 참조.)
  await Future.wait<void>([
    SceneAssetResolver.load(),
    DancheongBurst.preload(),
  ]);

  // 2026-08-19(원 결정) + 2026-08-26(W2 갱신): 에셋 매니페스트(§SceneAssetResolver)
  // + 축하 스프라이트 디코딩(§DancheongBurst)만 첫 프레임 전에 끝내면 된다.
  // 마이그레이션·오디오 컨텍스트는 첫 프레임 뒤로 미루되, splash_screen.dart
  // 가 SplashGate.ready 로 그 완료를 기다린다(최소 600ms~상한 1500ms) — 예전
  // "스플래시가 고정 2초 떠 있으니 그 안에 끝난다"는 가정과 달리, 이제
  // 스플래시 표시 시간 자체가 이 작업의 완료 여부에 (상한 내에서) 반응한다.
  // BookImageService.initialize()/크롭·피커 복구는 SplashGate 와 무관하게
  // 계속 게이트 밖에서 지연 실행된다 — 스플래시 로고와 관계가 없다.
  runner(const KoLernenApp());

  unawaited(_finishStartupInBackground());
}

/// `runApp()` 뒤에 이어지는 나머지 시작 초기화. 전부 best-effort이며, 스플래시
/// 로고가 이미 화면에 떠 있는 동안 진행된다. 순서는 기존 의존성(마이그레이션
/// → 스트릭, Storage.init() 이후)만 유지하면 되고 실패해도 앱은 이미 떠 있다.
Future<void> _finishStartupInBackground() async {
  // Start cloud and the onboarding kill switch immediately behind the first
  // frame; local reconciliation below must not delay the remote release gate.
  unawaited(_startCloudServices());

  // 로컬 스키마 점검 — Storage.init() 직후, 어떤 학습 데이터에 손대기 전에.
  // 로컬 전용이라 빠르고 네트워크를 타지 않는다. 실패해도 앱은 뜨며, 그 경우
  // 학습 데이터 쓰기만 잠긴다(DataMigrationService 가 처리).
  DataMigrationResult? migration;
  try {
    migration = await DataMigrationService.run();
  } catch (error) {
    debugPrint('Data migration skipped: $error');
  }

  await runPostMigrationStudyLogMaintenance(migration);

  final streakBefore = Storage.streakDays;
  await Storage.touchStreak();
  final streakAfter = Storage.streakDays;
  if (streakAfter > streakBefore) {
    Analytics.streakExtended(streakAfter);
    if (const {3, 7, 14, 30, 50, 100}.contains(streakAfter)) {
      Analytics.streakMilestone(streakAfter);
    }
  }
  // SFX 전역 오디오 세션: 타 앱 음악과 mix + 무음 스위치 존중 (ADR-002 §5-3).
  // §정리#2: applyPlatformAudioContext() 는 (기존과 동일하게) 가드되지 않는다
  // — 여기서 던지면 finally 가 markReady() 를 보장해, 스플래시가 예외로
  // 상한 1500ms 를 다 채우고 나서야 넘어가는 일이 없다.
  try {
    await AudioPolicy.instance.applyPlatformAudioContext();
  } finally {
    // §W2-Task6: 스플래시가 기다리는 두 단계(마이그레이션+오디오 컨텍스트)가
    // 여기서 끝난다 — BookImageService 이후 단계들은 게이트와 무관.
    SplashGate.markReady();
  }
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

  // AdMob best-effort initialisieren (im Hintergrund)
  // ignore: discarded_futures, unawaited_futures
  _initAds();

  // Lokale Benachrichtigungen (M3) best-effort initialisieren.
  // ignore: discarded_futures, unawaited_futures
  NotificationService.init();

  // 크래시 재현용 문맥. 동의가 꺼져 있으면 전부 no-op 이다.
  // ignore: discarded_futures, unawaited_futures
  _recordStartupDiagnostics(migration);
}

/// Führt nichtkritische Pflege erst nach einer erfolgreichen Migration aus.
///
/// Der Tages-Log ist getrennt vom SRS-Schema und seine Bereinigung darf weder
/// vor dem Migrations-Write-Gate noch als Startfehler wirken.
@visibleForTesting
Future<void> runPostMigrationStudyLogMaintenance(
  DataMigrationResult? migration, {
  Future<void> Function()? pruneStudyLog,
  void Function(Object error)? onPruneFailure,
}) async {
  if (migration?.writesAllowed != true) {
    return;
  }
  try {
    await (pruneStudyLog ?? Storage.pruneStudyLog)();
  } on Object catch (error) {
    (onPruneFailure ??
        (error) => debugPrint('Study-log pruning skipped: $error'))(error);
  }
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
    initializeFirebase: () async {
      final available = await _initFirebase();
      if (available) {
        await OnboardingRolloutService.fetchAndApply();
      }
      return available;
    },
    // App Check activate 실패는 여기서 삼킨다: 이게 던지면 coordinator.start()
    // 전체가 중단돼 익명 로그인·아웃박스·프리미엄·푸시까지 다 죽는다.
    // 활성화 실패 시 보호된 callable 만 개별적으로 거부되는 편이
    // (서버 enforceAppCheck) 클라우드 스택 전멸보다 낫다.
    initializeAppCheck: () async {
      try {
        await FirebaseAppCheckInitializer.production().initialize();
      } catch (error) {
        AccountFailureDiagnostics.log('startup.appCheckSkipped', error);
        debugPrint('App Check activation failed; continuing without it.');
      }
    },
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
    // installErrorHandlers() 는 이제 launchKoLernenApp() 맨 앞에서 조기·
    // 무조건 설치된다(finding 7) — 여기 있던 호출은 Firebase 성공에
    // 종속된 중복이라 제거.
    // Non-PII Segmentierungs-Properties setzen (no-op ohne Einwilligung).
    unawaited(Analytics.syncUserProperties());
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
  const KoLernenApp({
    super.key,
    this.splashDisplayDuration,
    this.firstRunCoordinator,
  });

  /// Test seam for deterministic whole-app startup tests. Production uses the
  /// bounded SplashGate timing when this is null.
  final Duration? splashDisplayDuration;
  final FirstRunCoordinator? firstRunCoordinator;

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
        // analyticsRouteObserver: 명명 라우트를 screen_view 로 기록(동의 시에만).
        navigatorObservers: [
          soriRouteObserver,
          DiagnosticsRouteObserver(),
          analyticsRouteObserver,
        ],
        locale: localeNotifier.value,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        // Tap außerhalb von Inputs → Tastatur weg
        builder: (context, child) => SoriTypeScale(
          child: ContentFeedbackControllerScope(
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
                // 발음이 안 나올 때 이유를 한 줄로 띄운다. OS 음성 폴백을
                // 지운 뒤로 프리미엄을 못 받으면 무음인데, 이유 없는 무음은
                // 고장과 구분이 안 된다.
                child: TtsUnavailableBanner(child: child ?? const SizedBox()),
              ),
            ),
          ),
        ),
        // 로고 스플래시(최소 600ms~상한 1500ms, SplashGate 완료에 반응) →
        // 동의/V2 설명·설정·동행 → 솟을대문 1회 → Today.
        // 기존 완료 사용자는 V2를 건너뛰고 바로 셸로 들어간다.
        // 모든 화면 전환은 SoriTransitions (fade + 깊이 scale-in) — "상자 슬라이드" 탈피.
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/splash':
              return SoriTransitions.fadeScale(
                (_) => SplashScreen(
                  displayDuration: widget.splashDisplayDuration,
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
            case '/quick_onboarding':
              return SoriTransitions.fadeScale(
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
            case '/character_selection':
              return SoriTransitions.fadeScale(
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
            case '/intro':
              return SoriTransitions.fadeScale(
                // A direct/deep-linked intro must still pass through the V2
                // coordinator. It renders the gate only for a journal that is
                // actually at the gate phase, so this compatibility route can
                // never bypass consent, story, setup, or companion selection.
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
            case '/':
              return SoriTransitions.fadeScale(
                // Root deep links must not bypass first-run consent or an
                // interrupted V2 journey. Completed users resolve straight to
                // AppShell through the same coordinator.
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
            case '/onboarding':
              return SoriTransitions.fadeScale(
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
            case '/onboarding/legacy-level':
              return SoriTransitions.fadeScale(
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
            case '/onboarding/start':
              return SoriTransitions.fadeScale(
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
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
            case '/vocab/recall':
              final rawRecallArguments = settings.arguments;
              final routeMapCandidate = settings.arguments;
              final recallArgs = routeMapCandidate is Map
                  ? routeMapCandidate.cast<String, dynamic>()
                  : const <String, dynamic>{};
              final String id;
              if (rawRecallArguments is String) {
                id = rawRecallArguments;
              } else {
                id = recallArgs['packId'] as String? ?? '';
              }
              final recallSession = PackRecallSession.fromRouteArgument(
                recallArgs['recallSession'],
                expectedPackId: id,
              );
              return SoriTransitions.fadeScale(
                (_) => VocabPackRecallScreen(
                  packId: id,
                  recallSession: recallSession,
                ),
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
            case '/grammar_choice_quiz':
              final args = settings.arguments;
              String? planLevel;
              String? planDayLabel;
              Set<String>? allowedTargetIds;
              if (args is Map) {
                final rawLevel = args['level'];
                if (rawLevel is String) {
                  planLevel = rawLevel;
                }
                final rawPlanDayLabel = args['planDayLabel'];
                if (rawPlanDayLabel is String) {
                  planDayLabel = rawPlanDayLabel;
                }
                if (args.containsKey('allowedTargetIds')) {
                  final rawTargetIds = args['allowedTargetIds'];
                  if (rawTargetIds is Iterable) {
                    allowedTargetIds = <String>{
                      for (final id in rawTargetIds)
                        if (id is String) id,
                    };
                  }
                }
              }
              return SoriTransitions.fadeScale(
                (_) => GrammarChoiceQuizScreen(
                  initialLevel: planLevel,
                  allowedTargetIds: allowedTargetIds,
                  planDayLabel: planDayLabel,
                ),
                settings: settings,
              );
            case '/listening':
              return SoriTransitions.fadeScale(
                (_) => const ListeningScreen(),
                settings: settings,
              );
            case '/listening/play':
              final listeningScenario = settings.arguments;
              return SoriTransitions.fadeScale(
                (_) =>
                    listeningScenario is Scenario &&
                        listeningScenario.dialog.isNotEmpty
                    ? ListeningPlayScreen(scenario: listeningScenario)
                    : const ListeningScreen(),
                settings: settings,
              );
            case '/kkeunmari':
              return SoriTransitions.fadeScale(
                (_) => const KkeunmariScreen(),
                settings: settings,
              );
            case '/hangul':
              final destination = settings.arguments;
              return SoriTransitions.fadeScale(
                (_) => HangulScreen(
                  initialTarget: destination is HangulTargetDestination
                      ? destination.target
                      : HangulTarget.overview,
                ),
                settings: settings,
              );
            case '/chosung':
              return SoriTransitions.fadeScale(
                (_) => const ChosungQuizScreen(),
                settings: settings,
              );
            case '/wordle':
              // Silben-Kreuz(음절 크로스워드)가 Wordle 보드를 대체 (2026-08-11).
              // 라우트명·메뉴 라벨("Silben-Rätsel")은 유지.
              return SoriTransitions.fadeScale(
                (_) => const SilbenKreuzScreen(),
                settings: settings,
              );
            case '/cloze':
              final clozeCourseContext =
                  coursePracticeContextFromRouteArguments(
                    settings.arguments,
                    CurriculumContentKind.cloze,
                  );
              final clozeCourseUnitId = courseUnitIdFromActivityRouteArguments(
                settings.arguments,
                CurriculumContentKind.cloze,
              );
              return SoriTransitions.fadeScale(
                (_) => ClozeGameScreen(
                  courseUnitId: clozeCourseUnitId,
                  courseContext: clozeCourseContext,
                ),
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
            case '/calligraphy':
              return SoriTransitions.fadeScale(
                (_) => const DailyCalligraphyRouteScreen(),
                settings: settings,
              );
            case '/practice':
              return SoriTransitions.fadeScale(
                (_) => const PracticeHubScreen(),
                settings: settings,
              );
            case '/pronunciation':
              return SoriTransitions.fadeScale(
                (_) => const PronunciationStudioScreen(),
                settings: settings,
              );
            case '/satz_arcade':
              final satzCourseContext = coursePracticeContextFromRouteArguments(
                settings.arguments,
                CurriculumContentKind.satz,
              );
              final satzCourseUnitId = courseUnitIdFromActivityRouteArguments(
                settings.arguments,
                CurriculumContentKind.satz,
              );
              return SoriTransitions.fadeScale(
                (_) => SatzArcadeScreen(
                  courseUnitId: satzCourseUnitId,
                  courseContext: satzCourseContext,
                ),
                settings: settings,
              );
            case '/settings':
              return SoriTransitions.fadeScale(
                (_) => SettingsScreen(
                  accountDeletionWorkflow: _createAccountDeletionWorkflow(),
                  initialFocus: settings.arguments is SettingsInitialFocus
                      ? settings.arguments! as SettingsInitialFocus
                      : null,
                ),
                settings: settings,
              );
            case '/guide':
              return SoriTransitions.fadeScale(
                (_) => const GuideHubRouteScreen(),
                settings: settings,
              );
            case '/study-library':
              return SoriTransitions.fadeScale(
                (_) => const StudyLibraryScreen(),
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
            case '/review/hub':
              return SoriTransitions.fadeScale(
                (_) => const ReviewHubScreen(),
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
            case '/media_phrases':
              return SoriTransitions.fadeScale(
                (_) => const MediaPhraseScreen(),
                settings: settings,
              );
            case '/scenarios':
              return SoriTransitions.fadeScale(
                (_) =>
                    ScenariosListScreen.fromRouteArguments(settings.arguments),
                settings: settings,
              );
            case '/quests':
              return SoriTransitions.fadeScale(
                (_) => const QuestsScreen(),
                settings: settings,
              );
            // Phase 5 (stately-rising-jongga) — "책 한 컷"
            case '/book':
              final bookArgs =
                  (settings.arguments as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
              return SoriTransitions.fadeScale(
                (_) => BookCaptureScreen(
                  captureMode: bookArgs['captureMode'] as String?,
                  existingPackId: bookArgs['existingPackId'] as String?,
                ),
                settings: settings,
              );
            case '/vocab_notebook':
              final notebookArgs =
                  (settings.arguments as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
              return SoriTransitions.fadeScale(
                (_) => BookCaptureScreen(
                  captureMode: 'notebook',
                  existingPackId: notebookArgs['existingPackId'] as String?,
                ),
                settings: settings,
              );
            case '/vocab_notebook/result':
              final notebookResultArgs =
                  (settings.arguments as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
              return SoriTransitions.fadeScale(
                (_) => VocabNotebookResultScreen(args: notebookResultArgs),
                settings: settings,
              );
            case '/vocab_notebook/practice':
              final practiceId = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => VocabNotebookPracticeScreen(packId: practiceId),
                settings: settings,
              );
            case '/vocab_notebook/nuance':
              final nuanceId = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => VocabNuanceScreen(packId: nuanceId),
                settings: settings,
              );
            case '/vocab_notebook/studio':
              final studioId = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                (_) => VocabNotebookStudioScreen(packId: studioId),
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
            case '/word_web':
              return SoriTransitions.fadeScale(
                (_) => const WordWebScreen(),
                settings: settings,
              );
            case '/dojangcheop':
              return SoriTransitions.fadeScale(
                (_) => const DojangcheopScreen(),
                settings: settings,
              );
            case '/hanok':
              return SoriTransitions.fadeScale(
                (_) => const IlDuWorldScreen(),
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
            case courseReassessmentRoute:
              final arguments = reassessmentArgumentsFromRoute(
                settings.arguments,
              );
              return SoriTransitions.fadeScale(
                (_) => arguments == null
                    ? const CourseReassessmentScreen.invalid()
                    : CourseReassessmentScreen(arguments: arguments),
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
                // Fail closed for malformed/old deep links during first run.
                // The journey resolver remains the single entry authority.
                (_) => OnboardingV2JourneyScreen(
                  firstRunCoordinator: widget.firstRunCoordinator,
                ),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}
