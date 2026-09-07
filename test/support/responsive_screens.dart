// 반응형 매트릭스가 공유하는 화면 목록과 앱 래퍼.
//
// `responsive_test.dart` 와 `responsive_short_height_test.dart` 가 **같은 화면
// 집합**을 각각 다른 축(폭 / 낮은 높이)으로 훑는다. 목록이 갈라지면 한쪽에만
// 커버되는 화면이 생기므로 여기 한 곳에서만 정의한다.
//
// ⚠️ 파일명이 `_test.dart` 가 아니라 `flutter test` 가 테스트로 수집하지 않는다.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/course_mission_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_quiz_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_typing_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/screens/daily_char_sheet.dart';
import 'package:ko_lernen_app/screens/discover_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/dojangcheop_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/personal_room_furnish_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
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
import 'package:ko_lernen_app/screens/vocab_notebook_practice_screen.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_result_screen.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_studio_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

import 'scenario_fixtures.dart';

/// 반응형 회귀를 거는 화면들 — **무인자 생성자만**.
///
/// 인자로 렌더 구조가 달라지는 변형(코스 모드·팩 인자)은 여기 담을 수 없어
/// `responsive_short_height_test.dart` 의 상태 변형 그룹이 따로 맡는다.
Map<String, Widget> responsiveScreens() => <String, Widget>{
  'app shell': const AppShell(),
  'home': const SoriStageTodayScreen(),
  'personal hanok world': const HanokWorldScreen(),
  'practice hub': const PracticeHubScreen(),
  'sarangbang study': const SarangbangStudyScreen(),
  'sarangbang furnish': const SarangbangFurnishScreen(),
  'anbang furnish': const PersonalRoomFurnishScreen(
    surface: PersonalRoomSurface.anbang,
  ),
  'daecheong furnish': const PersonalRoomFurnishScreen(
    surface: PersonalRoomSurface.daecheongmaru,
  ),
  'scenarios list': const ScenariosListScreen(),
  'settings': const SettingsScreen(),
  'stats': const StatsScreen(),
  'vocab packs': const VocabPacksScreen(),
  'grammar': const GrammarScreen(),
  'hangul': const HangulScreen(),
  'wordle': const SilbenKreuzScreen(),
  'kkeunmari': const KkeunmariScreen(),
  'dojangcheop': const DojangcheopScreen(),
  'listening': const ListeningScreen(),
  'hard words': const HardWordsScreen(),
  'legacy vocab': const LegacyVocabScreen(),
  'consent': const ConsentScreen(),
  'first voice success': const FirstVoiceSuccessScreen(
    canDo: 'Ich kann jemanden begrüßen.',
  ),
  'companion selection': const CharacterSelectionScreen(optional: true),
  'course mission': const CourseMissionScreen(),
  'chosung': const ChosungQuizScreen(),
  'cloze': const ClozeGameScreen(),
  'speed match': const SpeedMatchScreen(),
  'daily challenge': const DailyChallengeScreen(),
  'satz arcade': const SatzArcadeScreen(),
  'learning path': const LearningPathScreen(),
  'discover': const DiscoverScreen(),
  'profile': const ProfileScreen(),
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

// ── W10 T-V4(2026-09-05): 세로 채움 가드 전용 추가 화면 ──────────────────────
//
// 아래 화면들은 인자·페이크(단어팩/발음 녹음기 등)가 필요해 무인자 생성자만
// 받는 [responsiveScreens] 에 넣을 수 없다. append-only — 기존 목록은 절대
// 건드리지 않는다. 호출부(test/vertical_fill_guard_test.dart)가 `setUp` 에서
// [verticalFillGuardPackId] 팩을 `CustomPackService.save` 로 등록해 둔 뒤에만
// 이 화면들을 pump 해야 한다(단어장/커스텀팩 화면이 packId 로 조회한다).

/// 가드 전용 커스텀팩/단어장 화면이 조회하는 고정 팩 id.
const verticalFillGuardPackId = 'w10-vertical-fill-guard-pack';

/// 최소 4개 — 커스텀팩 퀴즈(4지선다)가 요구하는 하한을 만족한다.
final List<ExtractedWord> verticalFillGuardWords = <ExtractedWord>[
  ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
  ExtractedWord.manual(korean: '학생', translationDe: 'Schüler'),
  ExtractedWord.manual(korean: '친구', translationDe: 'Freund'),
  ExtractedWord.manual(korean: '음식', translationDe: 'Essen'),
];

/// 녹음기 플랫폼 채널을 건드리지 않는 무동작 페이크 —
/// `test/pronunciation_studio_screen_test.dart` 의 `_FakeRecorder` 와 같은
/// 목적(권한/스트림을 실제로 요청하지 않음).
class _NoopPronunciationRecorder implements PronunciationRecorder {
  const _NoopPronunciationRecorder();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async =>
      const Stream<Uint8List>.empty();

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

const _verticalFillGuardPhrases = <PronunciationPhrase>[
  PronunciationPhrase(
    id: 'w10-guard-0001',
    level: LearnerLevel.a1,
    ko: '안녕하세요',
    de: 'Guten Tag.',
    en: 'Hello.',
    focus: 'ㅎ 발음',
  ),
];

/// W10 PR-D(2026-09-06): 순수 widget-test 하네스에서 `compute()`(isolate)로
/// 끝나는 프로덕션 로더는 절대 안 돌아온다 — `scenarios list`/`app shell`/
/// `home` 이 세로 채움 가드에서 로딩 스피너에 멈춰 RED였다. 각 화면이 이미
/// 갖고 있는(또는 이 PR에서 새로 뚫은) 로더 주입 구멍으로 실측값을 즉시
/// 반환해, 가드가 **실제 레이아웃**을 판정하게 한다 — allowlist가 아니라
/// 진짜 데이터로 통과시킨다.
SoriStageProgressionSnapshot _verticalFillGuardStageSnapshot() =>
    SoriStageProgressionSnapshot(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
      ),
      hanok: PersonalHanokProjection.from(
        const LevelRatios(a1: 1, a2: .5, b1: 0, b2: 0),
      ),
      quests: const [],
      pendingBojagiCount: 1,
      stampCount: 0,
      xp: 320,
      streakDays: 7,
      todayReward: null,
    );

/// `scenarioAirportArrivalFixture` 하나만 넘기면 헤더+레벨 섹션 하나뿐이라
/// 800×1280 처럼 긴 뷰포트에서 (진짜 결함이 아니라) **표본 데이터 부족**으로
/// top=1%/bottom=51.5% 가 나와 55% 문턱을 살짝 놓친다 — 실제 프로덕션
/// 카탈로그는 레벨마다 여러 시나리오가 있다. 리스트 화면 카드는 id/level/
/// emoji/title/register 만 읽으므로(재생은 안 함) vocab/dialog/quests 는
/// 빈 리스트로 충분하다.
List<Scenario> _verticalFillGuardScenarios() => [
  scenarioAirportArrivalFixture,
  for (final level in [LearnerLevel.a1, LearnerLevel.a2, LearnerLevel.b1])
    for (var i = 0; i < 3; i++)
      Scenario(
        id: 'w10-guard-${level.code}-$i',
        level: level,
        emoji: '📖',
        register: Register.polite,
        title: LocalizedText(
          ko: '시나리오 ${level.code}-$i',
          de: 'Szenario ${level.code}-$i',
          en: 'Scenario ${level.code}-$i',
        ),
        intro: const LocalizedText(ko: '', de: '', en: ''),
        vocab: const [],
        grammarIds: const [],
        dialog: const [],
        quests: const [],
      ),
];

/// [responsiveScreens] 에 얹는 추가 화면. `CustomPackService.save` 로
/// [verticalFillGuardPackId] 팩을 미리 등록해 둔 뒤 호출할 것.
///
/// 여기 담긴 키가 [responsiveScreens] 와 겹치면(예: `scenarios list`,
/// `app shell`, `home`) — 호출부가 두 맵을 스프레드로 합칠 때 이 맵이
/// **나중**이라 이쪽이 이긴다. `responsiveScreens` 자체는 건드리지 않으므로
/// (다른 반응형 스위트는 여전히 무인자 생성자를 그대로 쓴다) 이 교체는 세로
/// 채움 가드에만 적용된다.
Map<String, Widget> verticalFillGuardExtraScreens() => <String, Widget>{
  'pronunciation studio': const PronunciationStudioScreen(
    recorder: _NoopPronunciationRecorder(),
    cloudAssessmentEnabled: false,
    phrases: _verticalFillGuardPhrases,
  ),
  'calligraphy': const DailyCalligraphyRouteScreen(),
  'vocab notebook practice': const VocabNotebookPracticeScreen(
    packId: verticalFillGuardPackId,
  ),
  'vocab notebook studio': const VocabNotebookStudioScreen(
    packId: verticalFillGuardPackId,
  ),
  'vocab notebook result': VocabNotebookResultScreen(
    args: const <String, dynamic>{'text': '학교 - Schule\n학생 = Schüler'},
  ),
  'custom pack quiz': VocabNotebookGuardWidgets.quiz(),
  'custom pack matching': VocabNotebookGuardWidgets.matching(),
  'custom pack typing': VocabNotebookGuardWidgets.typing(),
  // `ScenariosListScreen.loadScenarios` — 다른 화면 테스트(예:
  // test/scenarios_list_screen_ui_test.dart)와 같은 시험용 구멍.
  'scenarios list': ScenariosListScreen(
    loadScenarios: () async => _verticalFillGuardScenarios(),
  ),
  // `AppShell.loadTodaySnapshot`(이 PR에서 새로 뚫음) — Today 탭까지 그대로
  // 전달돼 5탭 셸 전체가 실제 데이터로 그려진다.
  'app shell': AppShell(
    loadTodaySnapshot: () async => _verticalFillGuardStageSnapshot(),
  ),
  // `SoriStageTodayScreen.loadSnapshot` — test/sori_stage_adaptive_chrome_test
  // .dart 등 기존 Today 탭 테스트와 같은 시험용 구멍.
  'home': SoriStageTodayScreen(
    loadSnapshot: () async => _verticalFillGuardStageSnapshot(),
  ),
};

/// 커스텀팩 게임 3종 — 별도 네임스페이스로 묶어 어떤 화면들이 짝인지 드러낸다.
abstract final class VocabNotebookGuardWidgets {
  static Widget quiz() => CustomPackQuizScreen(
    packId: verticalFillGuardPackId,
    words: verticalFillGuardWords,
  );
  static Widget matching() => CustomPackMatchingScreen(
    packId: verticalFillGuardPackId,
    words: verticalFillGuardWords,
  );
  static Widget typing() => CustomPackTypingScreen(
    packId: verticalFillGuardPackId,
    words: verticalFillGuardWords,
  );
}
