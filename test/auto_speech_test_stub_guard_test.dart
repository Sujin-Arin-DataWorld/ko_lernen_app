import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PR1 T3 교훈 — 자동 발화 화면(진입/전환 시 SoriSpeech.speak을 자동 호출)의
/// 위젯 테스트가 SoriSpeech를 스텁하지 않으면, speak 요청이 실제
/// TtsService(Firebase Storage/Functions)로 흘러 테스트 환경엔 mock이 없어
/// 영원히 안 풀리는 Future를 만든다 — 그 결과 in-flight 키가 잠겨 이후
/// 같은 키의 다른 요청까지 조용히 dedupe join만 하고 끝난다(디버깅 난이도가
/// 높은 함정). 이 가드는 content_audio_policy_guard_test.dart의
/// targetScreens 목록(자동 발화 화면)에 있는 화면을 pumpWidget()하는 테스트
/// 파일이 test/support/sori_speech_stubs.dart의 stubSoriSpeech() 호출
/// 또는 SoriSpeech.speakImpl에 대한 직접 대입(`speakImpl =`)을 실제로
/// 하는지 문자열 계약으로 검사한다. 두 마커는 증거의 폭이 다르다 —
/// `stubSoriSpeech(`은 speakImpl/speakSlowImpl/prefetchImpl/stopImpl 네
/// 훅을 전부 스텁하지만, 단독 `speakImpl =` 대입은 speak 하나만 스텁됐음을
/// 증명할 뿐이다(prefetch/stop은 여전히 실제 TtsService를 칠 수 있다). 그래도
/// 증거로 인정하는 이유는 이 가드가 막으려는 T3 함정 자체가 "speak가
/// 실제 서비스로 흘러 in-flight 키를 영원히 잠그는" 경로이기 때문이다 —
/// prefetch/stop이 별도 경로로 실제 서비스를 치는 문제는 이 마커로는 못
/// 잡는다(하드닝 최종 리뷰 M3, 관찰된 미스텁 사례:
/// review_session_screen_speakable_test.dart 등). `SoriSpeech.resetForTesting()`
/// 단독 호출은 증거로 인정하지 않는다 — 그건 speakImpl/speakSlowImpl/
/// prefetchImpl/stopImpl 훅을 오히려 **진짜** TtsService 델리게이트로
/// 되돌리므로(speakable.dart:135-138), 그것만 부른 테스트는 이 가드가
/// 막으려는 T3 함정 그 자체다(하드닝 리뷰 라운드1 Important #1).
void main() {
  test('자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다', () {
    final guardFile = File('test/content_audio_policy_guard_test.dart');
    expect(
      guardFile.existsSync(),
      isTrue,
      reason: 'test/content_audio_policy_guard_test.dart 가 없다',
    );
    final guardSource = guardFile.readAsStringSync();

    final listMatch = RegExp(
      r'const targetScreens = <String>\[([\s\S]*?)\];',
    ).firstMatch(guardSource);
    expect(
      listMatch,
      isNotNull,
      reason:
          'content_audio_policy_guard_test.dart 에서 targetScreens 목록을 못 찾음 — '
          '그 파일의 리스트 선언 형태가 바뀌었으면 이 정규식도 함께 고칠 것',
    );
    final targetScreens = RegExp(
      r"'([^']+)'",
    ).allMatches(listMatch!.group(1)!).map((m) => m.group(1)!).toList();
    expect(targetScreens, isNotEmpty);

    // targetScreens의 각 화면 파일에서 공개 위젯 클래스명(...Screen)을
    // 정적으로 뽑는다 — quest_flow.dart처럼 클래스명이 'Screen'으로 끝나지
    // 않는 파일은 기여하는 클래스명이 없을 수 있다(의도된 동작).
    final screenClassNames = <String>{};
    for (final path in targetScreens) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path 가 없다');
      final classMatches = RegExp(
        r'class (\w+Screen) extends',
      ).allMatches(file.readAsStringSync());
      for (final m in classMatches) {
        screenClassNames.add(m.group(1)!);
      }
    }
    expect(
      screenClassNames,
      isNotEmpty,
      reason: 'targetScreens에서 파생된 공개 Screen 클래스명이 하나도 없다',
    );

    // test/**/*.dart 를 스캔해 위 화면 중 하나를 pumpWidget()하면서도
    // 스텁 계약(stubSoriSpeech( 호출 또는 speakImpl = 직접 대입)의 실제
    // 증거가 없는 파일을 찾는다. SoriSpeech.resetForTesting()만 부르는 건
    // 증거로 치지 않는다 — tear-off 전달(`setUp(SoriSpeech.resetForTesting)`)
    // 이든 직접 호출이든, 그건 매 테스트 전 초기화만 할 뿐 speak/prefetch/
    // stop 훅은 여전히 진짜 TtsService를 가리키기 때문이다(T3 함정).
    final unstubbed = <String>[];
    for (final entity in Directory(
      'test',
    ).listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relativePath = entity.path
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^.*?test/'), 'test/');
      final content = entity.readAsStringSync();
      if (!content.contains('pumpWidget(')) {
        continue;
      }
      final mentionsTargetScreen = screenClassNames.any(content.contains);
      if (!mentionsTargetScreen) {
        continue;
      }
      final isStubbed =
          content.contains('stubSoriSpeech(') ||
          content.contains('speakImpl =');
      if (!isStubbed) {
        unstubbed.add(relativePath);
      }
    }
    unstubbed.sort();

    // 신규 미스텁 화면 테스트만 실패시킨다 — 허용 목록에 이미 있는 기존
    // 항목은 여기서 다시 걸리지 않는다(고치면 목록에서 지우고 캡을 낮출 것).
    final newOffenders = unstubbed
        .where((f) => !knownUnstubbedTestFiles.contains(f))
        .toList();
    // 허용 목록이 진짜로 아래로만 움직이도록 강제한다 — 항목이 고쳐지거나
    // (stubSoriSpeech(/speakImpl = 을 갖추거나) 파일 자체가 사라지면 더 이상
    // unstubbed에 없으므로 여기서 즉시 걸린다(M2, 하드닝 최종 리뷰).
    final stale = knownUnstubbedTestFiles
        .where((f) => !unstubbed.contains(f))
        .toList();
    expect(
      newOffenders,
      isEmpty,
      reason:
          'SoriSpeech를 스텁하지 않고 자동 발화 화면을 pumpWidget하는 신규 테스트 파일: '
          '${newOffenders.join(', ')} — stubSoriSpeech()(test/support/sori_speech_stubs.dart)'
          '를 setUp에 추가하거나(권장) SoriSpeech.speakImpl에 직접 스텁을 '
          '대입할 것. SoriSpeech.resetForTesting()만 부르는 건 증거로 '
          '인정되지 않는다 — 실제 TtsService로 흘러가는 T3 함정을 그대로 둔다',
    );
    expect(
      stale,
      isEmpty,
      reason:
          '고쳐졌거나 사라진 파일은 허용 목록에서 지우고 knownUnstubbedCap을 낮출 것: '
          '${stale.join(', ')}',
    );
    expect(
      knownUnstubbedCap,
      knownUnstubbedTestFiles.length,
      reason: 'knownUnstubbedCap은 knownUnstubbedTestFiles 길이와 정확히 같아야 한다',
    );
  });
}

// 아래 허용 목록은 2026-09-03 실측 기준선이다 — 이 가드를 새로 도입하며
// 이미 존재하던 미스텁 테스트 파일들을 동결한 것으로, 새 화면/테스트가 이
// 목록에 추가되는 일은 없어야 한다(늘리기 금지). 항목을 고치면(stubSoriSpeech
// 도입) 여기서 지우고 knownUnstubbedCap도 함께 낮출 것.
//
// 2026-09-03 origin/main(#253-#255) 병합 재기준선: 이 가드가 만들어지기
// 전부터 main에 이미 있던 미스텁 파일 2개
// (test/features/study_library/study_library_language_test.dart,
// test/flashcard_language_preferences_test.dart)를 병합으로 처음 관측해
// 동결선에 추가했다 — 새로 작성된 위반이 아니라 병합이 드러낸 기존 부채의
// 재측정이다. 이 두 파일을 stubSoriSpeech()로 옮기는 건 이 작업 범위 밖.
const List<String> knownUnstubbedTestFiles = <String>[
  'test/accessibility_guideline_test.dart',
  'test/airport_arrival_roleplay_layout_test.dart',
  'test/c0_level_selection_test.dart',
  'test/circular_feedback_widget_test.dart',
  'test/cloze_game_screen_ui_test.dart',
  'test/course_mission_build_activity_test.dart',
  'test/course_practice_screen_test.dart',
  'test/culture_note_loader_lifecycle_test.dart',
  'test/custom_pack_flipgate_test.dart',
  'test/deck_card_geometry_test.dart',
  'test/deck_vertical_gesture_test.dart',
  'test/dedicated_feedback_route_test.dart',
  'test/features/study_library/study_bookmark_production_writer_test.dart',
  'test/features/study_library/study_library_language_test.dart',
  'test/flashcard_language_preferences_test.dart',
  'test/game_layout_test.dart',
  'test/grammar_filter_position_test.dart',
  'test/grammar_plan_screen_test.dart',
  'test/hangul_content_locale_test.dart',
  'test/hangul_hard_filter_test.dart',
  'test/hangul_interaction_regression_test.dart',
  'test/hangul_swipe_and_prefetch_test.dart',
  'test/hangul_write_gate_test.dart',
  'test/legacy_vocab_flipgate_test.dart',
  'test/onboarding_flow_test.dart',
  'test/responsive_short_height_test.dart',
  'test/scenario_can_do_result_flow_test.dart',
  'test/scenario_grammar_resolution_test.dart',
  'test/scenario_intro_art_test.dart',
  'test/scenario_mission_context_test.dart',
  'test/scenario_onboarding_completion_test.dart',
  'test/scenario_quest_fold_test.dart',
  'test/scenario_quest_responsive_test.dart',
  'test/scenario_srs_persistence_flow_test.dart',
  'test/scenarios_list_screen_ui_test.dart',
  'test/screen_smoke_test.dart',
  'test/shared_game_feedback_route_test.dart',
  'test/smalltalk_presentation_test.dart',
  'test/smalltalk_screen_ui_test.dart',
  'test/standalone_games_uiux_test.dart',
  'test/study_activity_responsive_test.dart',
  'test/ux_gallery_no_write_test.dart',
  'test/ux_preview_app_test.dart',
  'test/visual_layout_regression_test.dart',
  'test/vocab_notebook_result_screen_test.dart',
  'test/vocab_notebook_studio_screen_test.dart',
  'test/vocab_pack_advance_timer_test.dart',
  'test/vocab_pack_assessment_order_test.dart',
  'test/vocab_pack_finish_screen_test.dart',
  'test/vocab_pack_flip_spoiler_test.dart',
  'test/vocab_pack_flipgate_test.dart',
  'test/vocab_pack_mission_context_test.dart',
  'test/vocab_pack_quiz_save_test.dart',
  'test/vocab_pack_requeue_test.dart',
  'test/vocab_pack_same_pack_choices_test.dart',
  'test/vocab_pack_screen_overflow_guard_test.dart',
  'test/vocab_pack_screen_repeat_counter_test.dart',
  'test/vocab_pack_srs_ledger_integration_test.dart',
  'test/vocab_pack_typography_test.dart',
  'test/vocab_pack_uniform_card_test.dart',
  'test/wordbook_spotlight_coach_test.dart',
];
const int knownUnstubbedCap = 61; // 2026-09-05 onboarding_start_screen_test.dart 격리로 하향
