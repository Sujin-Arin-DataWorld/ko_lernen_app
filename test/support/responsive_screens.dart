// 반응형 매트릭스가 공유하는 화면 목록과 앱 래퍼.
//
// `responsive_test.dart` 와 `responsive_short_height_test.dart` 가 **같은 화면
// 집합**을 각각 다른 축(폭 / 낮은 높이)으로 훑는다. 목록이 갈라지면 한쪽에만
// 커버되는 화면이 생기므로 여기 한 곳에서만 정의한다.
//
// ⚠️ 파일명이 `_test.dart` 가 아니라 `flutter test` 가 테스트로 수집하지 않는다.

import 'package:flutter/material.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/screens/dojangcheop_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/learn_hub_screen.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/paywall_screen.dart';
import 'package:ko_lernen_app/screens/personal_room_furnish_screen.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/screens/quests_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_furnish_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/screens/satz_arcade_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_hub_screen.dart';
import 'package:ko_lernen_app/screens/wordle_screen.dart';
import 'package:ko_lernen_app/theme.dart';

/// 반응형 회귀를 거는 화면들 — **무인자 생성자만**.
///
/// 인자로 렌더 구조가 달라지는 변형(코스 모드·팩 인자)은 여기 담을 수 없어
/// `responsive_short_height_test.dart` 의 상태 변형 그룹이 따로 맡는다.
Map<String, Widget> responsiveScreens() => <String, Widget>{
  'app shell': const AppShell(),
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
  'scenarios list': const ScenariosListScreen(),
  'settings': const SettingsScreen(),
  'stats': const StatsScreen(),
  'vocab packs': const VocabPacksScreen(),
  'grammar': const GrammarScreen(),
  'hangul': const HangulScreen(),
  'wordle': const WordleScreen(),
  'kkeunmari': const KkeunmariScreen(),
  'dojangcheop': const DojangcheopScreen(),
  'listening': const ListeningScreen(),
  'hard words': const HardWordsScreen(),
  'legacy vocab': const LegacyVocabScreen(),
  'consent': const ConsentScreen(),
  'paywall': const PaywallScreen(),
  'chosung': const ChosungQuizScreen(),
  'cloze': const ClozeGameScreen(),
  'speed match': const SpeedMatchScreen(),
  'daily challenge': const DailyChallengeScreen(),
  'satz arcade': const SatzArcadeScreen(),
  'learning path': const LearningPathScreen(),
  'gye tab': const GyeTabScreen(),
  'quests': const QuestsScreen(),
  'smalltalk': const SmalltalkScreen(),
  'review': const ReviewSessionScreen(),
};

/// 화면 하나를 앱 셸(테마·로케일·l10n)에 담는다. [textScale] 은 시스템 글자
/// 확대 재현용 — 1.0 이면 `MediaQuery` 를 덧씌우지 않는다.
Widget wrapResponsive(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: textScale == 1.0
        ? child
        : MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child,
          ),
    onGenerateRoute: (settings) => null,
  );
}
