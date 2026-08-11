import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/screens/learn_hub_screen.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/intro_gate_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_level_screen.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/screens/personal_room_furnish_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_furnish_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_hub_screen.dart';
import 'package:ko_lernen_app/screens/wordle_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 3,
      'kl_xp': 40,
    });
    await Storage.init();
    DataLoader.reset();
    ScenarioLoader.reset();
    KkeunmariEngine.reset();
  });

  final screens = <String, Widget>{
    'app shell': const AppShell(),
    'intro gate': const IntroGateScreen(),
    'home': const HomeScreen(),
    'personal hanok world': const HanokWorldScreen(),
    'learn hub': const LearnHubScreen(),
    'practice hub': const PracticeHubScreen(),
    'sarangbang study': const SarangbangStudyScreen(),
    'sarangbang furnish': const SarangbangFurnishScreen(),
    'anbang furnish': const PersonalRoomFurnishScreen(
      surface: PersonalRoomSurface.anbang,
    ),
    'daecheong furnish': const PersonalRoomFurnishScreen(
      surface: PersonalRoomSurface.daecheongmaru,
    ),
    'wordbook hub': const WordbookHubScreen(),
    'learning path': const LearningPathScreen(),
    'vocab (packs grid)': const VocabPacksScreen(),
    'vocab (legacy)': const LegacyVocabScreen(),
    'grammar': const GrammarScreen(),
    'hangul': const HangulScreen(),
    'listening': const ListeningScreen(),
    'wordle': const WordleScreen(),
    'chosung': const ChosungQuizScreen(),
    'kkeunmari': const KkeunmariScreen(),
    'scenarios list': const ScenariosListScreen(),
    'scenario player': const ScenarioPlayerScreen(
      scenarioId: 'airport_arrival',
    ),
    'stats': const StatsScreen(),
    'settings': const SettingsScreen(),
    'onboarding': const OnboardingLevelScreen(),
    'companion selection': const CharacterSelectionScreen(optional: true),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders without a Flutter exception', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(entry.value));
      await tester.pump();
      // TigerStage의 ambient 스케줄러 타이머(최대 ~1.5s)가 완료될 때까지 진행.
      await tester.pump(const Duration(milliseconds: 2000));

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
    onGenerateRoute: (settings) {
      if (settings.name == '/' || settings.name == '/onboarding') {
        return MaterialPageRoute<void>(
          builder: (_) => settings.name == '/'
              ? const HomeScreen()
              : const OnboardingLevelScreen(),
        );
      }
      return null;
    },
  );
}
