import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'motion/transitions.dart';
import 'services/storage_service.dart';
import 'services/locale_service.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/book_analysis_service.dart';
import 'services/palette_service.dart';
import 'services/premium_service.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/intro_gate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/book_capture_screen.dart';
import 'screens/book_preview_screen.dart';
import 'screens/book_result_screen.dart';
import 'screens/bookshelf_page_screen.dart';
import 'screens/bookshelf_screen.dart';
import 'screens/custom_pack_play_screen.dart';
import 'screens/custom_pack_edit_screen.dart';
import 'screens/custom_pack_quiz_screen.dart';
import 'screens/legacy_vocab_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/vocab_pack_result_screen.dart';
import 'screens/vocab_pack_screen.dart';
import 'screens/vocab_packs_screen.dart';
import 'screens/grammar_screen.dart';
import 'screens/kkeunmari_screen.dart';
import 'screens/listening_screen.dart';
import 'screens/chosung_quiz_screen.dart';
import 'screens/wordle_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/hangul_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/onboarding_level_screen.dart';
import 'screens/scenario_player_screen.dart';
import 'screens/scenarios_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistente Speicher initialisieren (vor runApp wichtig)
  await Storage.init();
  await Storage.touchStreak();

  // Phase 5 (stately-rising-jongga) — Cloud-Endpoint festlegen.
  // Priorität: Settings (persistent) > --dart-define > deployter Default.
  // So funktioniert "책 한 컷" für Closed-Test-Tester ohne manuelle Eingabe;
  // ohne erreichbaren Endpoint fällt der Client sauber auf Offline-Grammatik.
  const kEnvEndpoint = String.fromEnvironment('BOOK_ANALYSIS_ENDPOINT');
  const kDefaultEndpoint =
      'https://europe-west3-ko-lernen-app.cloudfunctions.net/analyze_korean_text';
  final storedEndpoint = Storage.bookAnalysisEndpoint;
  BookAnalysisService.setEndpoint(
    storedEndpoint.isNotEmpty
        ? storedEndpoint
        : (kEnvEndpoint.isNotEmpty ? kEnvEndpoint : kDefaultEndpoint),
  );

  // Firebase best-effort — schlägt fehl wenn google-services.json fehlt
  // ignore: discarded_futures, unawaited_futures
  _initFirebase();

  // AdMob best-effort initialisieren (im Hintergrund)
  // ignore: discarded_futures, unawaited_futures
  _initAds();

  // Premium / Abo (RevenueCat) best-effort — ohne Keys "kostenlos"-Modus.
  // ignore: discarded_futures, unawaited_futures
  PremiumService.init();

  // Portrait sperren
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge (Android 15+ default, ältere Versionen profitieren auch).
  // Status- und Navigationsleiste werden transparent, App zeichnet darunter.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const KoLernenApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await AuthService.ensureSignedIn();
    // v6.0 단청 kill-switch — Remote Config 'palette_variant' 읽기 (best-effort).
    await PaletteService.fetchAndApply();
  } catch (e) {
    // google-services.json fehlt → Cloud-Sync deaktiviert, lokale App funktioniert weiter
    // ignore: avoid_print
    debugPrint('Firebase init skipped: $e');
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
        theme:      AppTheme.lightFor(paletteVariantNotifier.value),
        darkTheme:  AppTheme.lightFor(paletteVariantNotifier.value),
        themeMode:  ThemeMode.light,
        locale:     localeNotifier.value,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        // Tap außerhalb von Inputs → Tastatur weg
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
        // 솟을대문 인트로가 먼저 열리고, 완료 시 온보딩 또는 홈으로 이동한다.
        // 모든 화면 전환은 SoriTransitions (fade + 깊이 scale-in) — "상자 슬라이드" 탈피.
        initialRoute: '/intro',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/intro':
              return SoriTransitions.fadeScale(
                  (_) => const IntroGateScreen(), settings: settings);
            case '/':
              return SoriTransitions.fadeScale(
                  (_) => const HomeScreen(), settings: settings);
            case '/onboarding':
              return SoriTransitions.fadeScale(
                  (_) => const OnboardingLevelScreen(), settings: settings);
            case '/vocab':
              // Phase 2 (stately-rising-jongga): default vocab entry =
              // Pack-Marktplatz (Grid).
              return SoriTransitions.fadeScale(
                  (_) => const VocabPacksScreen(), settings: settings);
            case '/vocab/pack':
              final packId = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                  (_) => VocabPackScreen(packId: packId),
                  settings: settings);
            case '/vocab/result':
              return SoriTransitions.fadeScale(
                  (_) => VocabPackResultScreen.fromArgs(settings.arguments),
                  settings: settings);
            case '/vocab/legacy':
              // Rollback / Power-User: alte single-card Ansicht (Phase 1
              // SRS-UX-Patch). Wird in Phase 3 entfernt, sobald Pack-UX
              // produktiv läuft.
              return SoriTransitions.fadeScale(
                  (_) => const LegacyVocabScreen(), settings: settings);
            case '/grammar':
              return SoriTransitions.fadeScale(
                  (_) => const GrammarScreen(), settings: settings);
            case '/listening':
              return SoriTransitions.fadeScale(
                  (_) => const ListeningScreen(), settings: settings);
            case '/kkeunmari':
              return SoriTransitions.fadeScale(
                  (_) => const KkeunmariScreen(), settings: settings);
            case '/hangul':
              return SoriTransitions.fadeScale(
                  (_) => const HangulScreen(), settings: settings);
            case '/chosung':
              return SoriTransitions.fadeScale(
                  (_) => const ChosungQuizScreen(), settings: settings);
            case '/wordle':
              return SoriTransitions.fadeScale(
                  (_) => const WordleScreen(), settings: settings);
            case '/settings':
              return SoriTransitions.fadeScale(
                  (_) => const SettingsScreen(), settings: settings);
            case '/stats':
              return SoriTransitions.fadeScale(
                  (_) => const StatsScreen(), settings: settings);
            case '/paywall':
              return SoriTransitions.fadeScale(
                  (_) => const PaywallScreen(), settings: settings);
            case '/scenarios':
              return SoriTransitions.fadeScale(
                  (_) => const ScenariosListScreen(), settings: settings);
            case '/quests':
              return SoriTransitions.fadeScale(
                  (_) => const QuestsScreen(), settings: settings);
            // Phase 5 (stately-rising-jongga) — "책 한 컷"
            case '/book':
              return SoriTransitions.fadeScale(
                  (_) => const BookCaptureScreen(), settings: settings);
            case '/book/preview':
              final args = (settings.arguments as Map?)
                      ?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
              return SoriTransitions.fadeScale(
                  (_) => BookPreviewScreen(args: args),
                  settings: settings);
            case '/book/result':
              final args = (settings.arguments as Map?)
                      ?.cast<String, dynamic>() ??
                  const <String, dynamic>{};
              return SoriTransitions.fadeScale(
                  (_) => BookResultScreen(args: args),
                  settings: settings);
            // Phase 5.1 — Bookshelf + Custom Pack
            case '/bookshelf':
              return SoriTransitions.fadeScale(
                  (_) => const BookshelfScreen(), settings: settings);
            case '/bookshelf/page':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                  (_) => BookshelfPageScreen(pageId: id),
                  settings: settings);
            case '/custom_pack/play':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                  (_) => CustomPackPlayScreen(packId: id),
                  settings: settings);
            case '/custom_pack/edit':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                  (_) => CustomPackEditScreen(packId: id),
                  settings: settings);
            case '/custom_pack/quiz':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                  (_) => CustomPackQuizScreen(packId: id),
                  settings: settings);
            case '/scenario':
              final id = settings.arguments as String? ?? '';
              return SoriTransitions.fadeScale(
                  (_) => ScenarioPlayerScreen(scenarioId: id),
                  settings: settings);
            default:
              return SoriTransitions.fadeScale(
                  (_) => const HomeScreen(), settings: settings);
          }
        },
      ),
    );
  }
}
