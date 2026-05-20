import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'services/storage_service.dart';
import 'services/locale_service.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
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
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeNotifier,
      builder: (_, locale, __) => MaterialApp(
        title: 'Koreanisch lernen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: locale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        // Tap außerhalb von Inputs → Tastatur weg
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
        // Erst-Launch: Nutzer hat noch kein Level gewählt → Onboarding.
        initialRoute: Storage.userLevelCode == null ? '/onboarding' : '/',
        routes: {
          '/':           (_) => const HomeScreen(),
          '/onboarding': (_) => const OnboardingLevelScreen(),
          '/vocab':      (_) => const VocabScreen(),
          '/grammar':    (_) => const GrammarScreen(),
          '/listening':  (ctx) => PlaceholderScreen(title: AppL10n.of(ctx).moduleListenTitle, emoji: '🎧'),
          '/hangul':     (_) => const HangulScreen(),
          '/chosung':    (_) => const ChosungQuizScreen(),
          '/wordle':     (_) => const WordleScreen(),
          '/settings':   (_) => const SettingsScreen(),
          '/stats':      (_) => const StatsScreen(),
          '/scenarios':  (_) => const ScenariosListScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/scenario') {
            final id = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => ScenarioPlayerScreen(scenarioId: id),
            );
          }
          return null;
        },
      ),
    );
  }
}
