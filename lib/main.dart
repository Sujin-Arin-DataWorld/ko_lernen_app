import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'motion/transitions.dart';
import 'services/storage_service.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/palette_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/intro_gate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/vocab_screen.dart';
import 'screens/grammar_screen.dart';
import 'screens/placeholder_screen.dart';
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

  // Firebase best-effort — schlägt fehl wenn google-services.json fehlt
  // ignore: discarded_futures, unawaited_futures
  _initFirebase();

  // AdMob best-effort initialisieren (im Hintergrund)
  // ignore: discarded_futures, unawaited_futures
  _initAds();

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
    await AuthService.ensureSignedIn();
    // v6.0 단청 kill-switch — Remote Config 'palette_variant' 읽기 (best-effort).
    await PaletteService.fetchAndApply();
  } catch (e) {
    // google-services.json fehlt → Cloud-Sync deaktiviert, lokale App funktioniert weiter
    // ignore: avoid_print
    print('Firebase init skipped: $e');
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
      listenable: Listenable.merge([localeNotifier, themeModeNotifier, paletteVariantNotifier]),
      builder: (_, __) => MaterialApp(
        title: 'Hangul Sori',
        debugShowCheckedModeBanner: false,
        theme:      AppTheme.lightFor(paletteVariantNotifier.value),
        darkTheme:  AppTheme.darkFor(paletteVariantNotifier.value),
        themeMode:  themeModeNotifier.value,
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
              return SoriTransitions.fadeScale(
                  (_) => const VocabScreen(), settings: settings);
            case '/grammar':
              return SoriTransitions.fadeScale(
                  (_) => const GrammarScreen(), settings: settings);
            case '/listening':
              return SoriTransitions.fadeScale(
                  (ctx) => PlaceholderScreen(
                      title: AppL10n.of(ctx).moduleListenTitle, emoji: '🎧'),
                  settings: settings);
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
            case '/scenarios':
              return SoriTransitions.fadeScale(
                  (_) => const ScenariosListScreen(), settings: settings);
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
