import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'services/storage_service.dart';
import 'services/locale_service.dart';
import 'services/ad_service.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/vocab_screen.dart';
import 'screens/grammar_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/chosung_quiz_screen.dart';
import 'screens/wordle_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/hangul_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistente Speicher initialisieren (vor runApp wichtig)
  await Storage.init();
  await Storage.touchStreak();

  // AdMob best-effort initialisieren (im Hintergrund)
  // ignore: discarded_futures, unawaited_futures
  _initAds();

  // Portrait sperren
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KoLernenApp());
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
        initialRoute: '/',
        routes: {
          '/':          (_) => const HomeScreen(),
          '/vocab':     (_) => const VocabScreen(),
          '/grammar':   (_) => const GrammarScreen(),
          '/listening': (_) => const PlaceholderScreen(title: 'Hören',  emoji: '🎧'),
          '/hangul':    (_) => const HangulScreen(),
          '/chosung':   (_) => const ChosungQuizScreen(),
          '/wordle':    (_) => const WordleScreen(),
          '/settings':  (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
