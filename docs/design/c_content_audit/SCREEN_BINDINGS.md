# C 화면 바인딩

소스 등록/필터/typed arguments/상태/저장/보상/에셋/지원 경로를 연결한 원장입니다. 기존 atlas 기록은 경로·상태의 과거 근거로만 보존하고 C 시각 권위나 현재 QA 증거로 사용하지 않습니다.

Lernen은 입문 + 종합코스 + 자유학습입니다. 한글 읽기 준비도는 CEFR A1과 방문 이력에서 분리합니다. 3개 탐색 영역을 의무적인 순서로 진행하게 만들지 않습니다.

Small Talk 첫 경로는 209 native lesson/590 phrase/24category입니다. TalSunbi 10case는 별도 보조 연습이며 실제 저장 뒤 사랑방 기록으로 연결합니다. 일반 진입과 CoursePracticeContext 진입을 합치지 않습니다.

보상은 개봉 한 번 → 단일 itemAsset 등장/확대 → 설명·실제 저장 XP·CTA → 문화 이야기입니다. 최대3후보 선택 UI 보존 문구는 최신 사용자 지시로 대체됐습니다. claim journal/queue/중복 지급 방지는 유지합니다.

| module | 경로 | 소스 관찰 | 자동검사 | 렌더 증거 | 인간 승인 |
|---|---|---|---|---|---|
| foundation | `/foundation` | 소스/hash 연결, C refs 3 | passed_for_named_scope | observed_for_named_scope | pending |
| course | `/path` / `/course/mission` / `/course/reassessment` | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| phases | `/course/phases` / `/course/phase` / `/learning-phase/task` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| productive_draft | `/course/mission` / `/learning-phase/task` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| hangul | `/hangul` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| calligraphy | `/calligraphy` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| pronunciation | `/pronunciation` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| vocab_packs | `/vocab` / `/vocab/pack` / `/vocab/result` / `/vocab/recall` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| srs | `/review` / `/review/hub` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| my_words | `/my_words` / `/bookshelf` / `/wordbook/search` / `/hard_words` / `/bookshelf/page` / `/custom_pack/play` / `/custom_pack/edit` / `/custom_pack/quiz` / `/custom_pack/matching` / `/custom_pack/typing` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| grammar | `/grammar` / `/grammar_choice_quiz` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| book_capture | `/book` / `/book/preview` / `/book/result` / `/vocab_notebook` / `/vocab_notebook/result` / `/vocab_notebook/practice` / `/vocab_notebook/studio` / `/vocab_notebook/nuance` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| listening | `/listening` / `/listening/play` / `/content/goals` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| scenarios | `/scenarios` / `/scenario` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| smalltalk | `/smalltalk` / `/content/goals` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| talsunbi_context | `/smalltalk/context` / `/hanok/practice` | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| word_web | `/word_web` / `/vocab_notebook/nuance` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| games | `/daily` / `/chosung` / `/wordle` / `/cloze` / `/speed_match` / `/satz_arcade` / `/kkeunmari` | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| onboarding | `/onboarding` / `/quick_onboarding` / `/character_selection` / `/onboarding/start` / `/intro` | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| hanok | `/hanok` / `/hanok/construction` / `/sarangbang` / `/sarangbang/furnish` / `/quests` / `/dojangcheop` | 소스/hash 연결, C refs 1 | passed_for_named_scope | observed_for_named_scope | pending |
| dancheong | `/dojangcheop` / `/dancheong-studio` / `/dancheong-entry` / `/dancheong-studio/edit` / `/dancheong-artwork` / `/dancheong-share` | 소스/hash 연결, C refs 0 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |
| rewards | `/bojagi` | 소스/hash 연결, C refs 1 | passed_for_named_scope | observed_for_named_scope | pending |
| gye | `/gye/hub` / `/gye/create` / `/gye/join` / `/gye` / `/gye/members` | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| support | `/profile` / `/settings` / `/stats` / `/guide` / `/study-library` / `/practice` / `/hanok/practice` | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| c_roots | `/` | 소스/hash 연결, C refs 3 | passed_for_named_scope | observed_for_named_scope | pending |

자동검사·렌더·인간 승인 열은 verification-status.json의 module_validation에 명시된 결과만 표시합니다. source/hash/C component 참조는 매번 재계산하며, 명시되지 않은 module의 QA 결과를 다른 module 검사에서 추론하지 않습니다.


## 입문 범위와 게임별 유지 계약

실제 shell의 active/hidden 탭은 계정 변경 시 진행·이력·focus를 무효화하고 done&&!error 상태에서만 현재 데이터를 표시해야 합니다. A→B pending/error 회귀 검사 상태는 실행 receipt에 따로 보존합니다.

hasPendingDecorationReceipt는 미개봉 상자 수와 별개입니다. 개봉 후 마지막 CTA를 확인하지 않은 실제 item은 Today/Hanok→/bojagi에서 같은 저장 receipt로 재개하고 추가 아이템·XP·pool 변경을 만들지 않습니다. 관련 strict/native 저장 읽기·계정 lease·모델·화면 source 줄과 해시는 root_data_and_receipt_contract에 있습니다.

Foundation은 소리ㄱ·ㄴ·ㅏ·ㅣ, 조합가·나·한, 획ㄱ·ㅏ, 기존가방·나무·첫 인사까지의4단계/12과제입니다. 전체 자모·쌍자음·복합모음·받침·문장 독해를 모두 평가한 것이 아닙니다. 기존 Hangul 카드/쓰기·발음·오늘의 글자 경로를 유지합니다. 실제 행동+사용자 확인이 과제 진행이며, 전체 한글 읽기 인증으로 표시하지 않습니다.

Today의 새 일일 카드10개는 기존 학습 증거가 아닙니다. 공개 dueCount=new+review 계약을 유지하고, 입문 admission에만 private scheduledReviewCount=today.reviewCount를 사용합니다. 실제 예약 복습/명시적 A1 계속/코스 증거와 새 과제 배정을 구분합니다.

| 게임 | 유지할 기존 mechanics/state |
|---|---|
| daily_game | Select word for missing Korean sentence; first attempt determines score and SRS |
| chosung | See initials/partially masked Korean plus translation; use composed jamo pad or text input, backspace |
| syllable_cross | Choose one unused pool syllable for selected cell; intersecting cells shared between words / Replay from PracticeHistoryStore with recorded help; review mode writes practice attempt but skips fresh game XP |
| cloze | Read Korean gap sentence and DE/EN meaning; tap one candidate answer |
| speed_match | Select Korean tile on left then matching DE/EN tile on right; refill/reshuffle pairs |
| sentence_arcade | Tap word tiles to build answer; remove/reorder/reset as supported; DE/EN clue and audio; Check |
| kkeunmari | Type Korean word beginning with required syllable, submit; chain strip, last word translation/audio, user timer / Accepted user word saves learning evidence then Taego chooses next word and returns turn |
| custom_practice | Flip/listen, known/unknown/defer, saved translation edit; completed card deck has no game XP / Korean/meaning choices from saved pack; reveal and Next / Match saved Korean/meaning pairs, count misses, refill/finish / Type actual saved Korean answer, check/reveal feedback, Next |

위 동작 계약의 원문·불가/오류 상태·저장/보상 규칙은 각 catalog entry의 historical_activity_contract에 보존되어 있습니다. 현재 source 파일·route dispatch를 별도로 해시 검증하며 과거 samples를 현재 라이브 데이터로 부르지 않습니다. Silben은 실제 음절 교차격자/동일 카드/힌트3단계/직접 타일 배치를 유지하고, 게임 접촉의100+150+900ms 파란1→3dp를 소개16불꽃 효과와 구분합니다.


## 개별 module 계약

### foundation

- 필터: Four independent starter steps and twelve stable tasks. Resume validated per-account progress; opening is not practicing. Today admission uses production scheduledReviewCount=today.reviewCount; newly assigned cards do not imply prior learning. Public dueCount still includes new+review.
- 인자: FoundationStep -> direct FoundationPracticeScreen(step, service, captured FoundationLearningLease), route name /foundation/${step.id}; explicit Continue A1 uses existing course entry.
- 상태: loading, empty, step_opened, practice, audio_pending, audio_failure_retry, composition_wrong, stroke_feedback, actual_action_and_confirmation, save_pending, save_failure_retry, resume, account_stale, reset_stale, continue_A1
- 저장/보상: FoundationPracticeEvidence requires successful playback/read composition/matched strokes plus confirmation. Schema1, 16KB cap, stable merge and lease lifetime guards; no CEFR mastery, course assessment, XP or money.
- 연결된 개별 source record: 16; 에셋: 6.
- 로더: `lib/models/foundation_progress.dart`, `lib/services/foundation_progress_service.dart`, `lib/services/foundation_progress_storage.dart`, `lib/services/today_learning_snapshot.dart`, `lib/features/onboarding_v2/onboarding_learning_start.dart`
- 화면: `lib/screens/foundation_learning_screen.dart`, `lib/screens/foundation_learning_widgets.dart`, `lib/screens/foundation_practice_screen.dart`

### course

- 필터: Placement/current/completed unit and frozen graph links; no first-in-level fallback.
- 인자: String courseUnitId; CoursePracticeContext.fromLink; VocabPackRouteArguments; CourseReassessmentRouteArguments.
- 상태: placement, loading, source_failure_retry, current, locked, completed, read_only, practice, assessment, save_pending, save_failure_retry, resume
- 저장/보상: CourseProgressService; provenance revalidation and account lifetime before evidence writes.
- 연결된 개별 source record: 17,931; 에셋: 4.
- 로더: `lib/services/curriculum_catalog.dart`, `lib/services/course_progress_service.dart`, `lib/services/course_mission_navigation.dart`, `lib/services/canonical_course_segment_loader.dart`
- 화면: `lib/screens/learning_path_screen.dart`, `lib/screens/course_mission_screen.dart`, `lib/screens/course_mission_path_overview.dart`, `lib/screens/course_reassessment_screen.dart`

### phases

- 필터: Level -> phase -> published taskIds; prerequisite/mode/structured evaluator checks; related practice is not course completion.
- 인자: Level String; LearningPhase; PhaseTaskRoute (practice and assessment distinct).
- 상태: level_selection, phase, task_list, practice, assessment, draft, recording_local, unavailable, save_pending, retry, result
- 저장/보상: Phase draft/evidence hash and contentRevision/rubricVersion binding; productive work not auto-certified.
- 연결된 개별 source record: 8,496; 에셋: 32.
- 로더: `lib/services/learning_phase_catalog.dart`, `lib/services/phase_task_catalog.dart`, `lib/services/phase_task_drafts.dart`
- 화면: `lib/screens/learning_phases_screen.dart`, `lib/screens/phase_task_screen.dart`, `lib/widgets/phase_task_panel.dart`

### productive_draft

- 필터: 118 assessment definitions / eight projects / 32 source snippets / 16 bundles exist in authoring draft only. runtimeContentApproved=false; canonical segment loader requires an approved injected catalog.
- 인자: ProductiveAssessmentCatalog.fromJson and approved injection; draft fixtures are injected by tests, never automatically packaged for the learner.
- 상태: draft, per_ID_review_pending, runtime_closed, unavailable, practice_only, source_missing, history_preserved
- 저장/보상: Draft/source consistency is not human copy approval, assessed mastery or XP. Content owner must complete the per-ID review ledger and deliberate promotion before enabling executable assessment.
- 연결된 개별 source record: 541; 에셋: 3.
- 로더: `lib/services/productive_assessment_service.dart`, `lib/services/canonical_course_segment_loader.dart`
- 화면: `lib/screens/course_mission_screen.dart`, `lib/screens/phase_task_screen.dart`

### hangul

- 필터: HangulTarget overview/cards/writing; consonant/vowel/compound letter source.
- 인자: HangulTarget overview/cards/writing or retained direct entry as dispatched in main.
- 상태: overview, cards, sound_loading, sound_failure, writing, stroke_feedback, completion
- 저장/보상: FeedbackCompletion and LearningJourneyObserver; visiting is not alphabet mastery.
- 연결된 개별 source record: 34; 에셋: 3.
- 로더: `lib/services/tts_recorded_jamo.dart`, `lib/services/hangul_util.dart`
- 화면: `lib/screens/hangul_screen.dart`

### calligraphy

- 필터: Today's character and existing letter/stroke contract.
- 인자: Existing daily-character route.
- 상태: letter, audio, trace, completion, failure_retry
- 저장/보상: Existing stored daily state; no fabricated course completion.
- 연결된 개별 source record: 34; 에셋: 0.
- 로더: `lib/services/daily_char_service.dart`, `lib/services/storage_service.dart`
- 화면: `lib/screens/daily_char_sheet.dart`

### pronunciation

- 필터: Level/focus phrase selection; recording consent and assessment availability.
- 인자: Existing phrase/level route.
- 상태: phrase, listen, permission, recording, assessment_pending, result, failure_retry
- 저장/보상: PronunciationProgressService; actual assessment result only.
- 연결된 개별 source record: 84; 에셋: 1.
- 로더: `lib/services/pronunciation_phrase_loader.dart`, `lib/services/pronunciation_progress_service.dart`, `lib/services/pronunciation_assessment_client.dart`
- 화면: `lib/screens/pronunciation_studio_screen.dart`

### vocab_packs

- 필터: CSV pack_id/level/order; matching mission content ID only; direct library remains browse.
- 인자: String packId or VocabPackRouteArguments(packId, courseContext).
- 상태: pack_grid, learn, quiz, boss, recall, locked, resume, result, save_failure_retry
- 저장/보상: PackProgressService and checkpoint evidence; confirmed rewards only.
- 연결된 개별 source record: 3,342; 에셋: 216.
- 로더: `lib/services/data_loader.dart`, `lib/services/vocab_pack_service.dart`, `lib/services/pack_progress_service.dart`
- 화면: `lib/screens/vocab_packs_screen.dart`, `lib/screens/vocab_pack_screen.dart`, `lib/screens/vocab_pack_recall_screen.dart`

### srs

- 필터: Due/hard words and saved review queues.
- 인자: Existing review session request.
- 상태: due, empty, loading, review, result, save_failure_retry
- 저장/보상: Stored review scheduling and account lifetime.
- 연결된 개별 source record: 0; 에셋: 0.
- 로더: `lib/services/storage_service.dart`
- 화면: `lib/screens/review_hub_screen.dart`, `lib/screens/review_session_screen.dart`

### my_words

- 필터: Real saved pack/page IDs, search/type and usable translated word count; aliases share current hub.
- 인자: Existing String packId/pageId and custom practice requests.
- 상태: empty, list, search, edit, save_pending, save_failed, conflict, play, restore
- 저장/보상: Bookshelf/custom-pack stores and LocalDataLifetime; user records are not enumerated by this static audit.
- 연결된 개별 source record: 2,968; 에셋: 0.
- 로더: `lib/services/bookshelf_service.dart`, `lib/services/storage_service.dart`
- 화면: `lib/screens/my_words_screen.dart`, `lib/screens/custom_pack_play_screen.dart`, `lib/screens/custom_pack_edit_screen.dart`

### grammar

- 필터: Level/plan and optional mission-linked grammar ID; CSV quiz_enabled and distractor IDs.
- 인자: CoursePracticeContext for grammar or direct library request.
- 상태: plan, list, explanation, examples, quiz, result, save_pending, conflict, retry
- 저장/보상: GrammarPlanService; valid course question/evidence only, legacy viewing not assessment.
- 연결된 개별 source record: 308; 에셋: 4.
- 로더: `lib/services/data_loader.dart`, `lib/services/grammar_plan_service.dart`
- 화면: `lib/screens/grammar_screen.dart`, `lib/screens/grammar_choice_quiz_screen.dart`

### book_capture

- 필터: Book/notebook capture mode and actual OCR/page/pack result; permissions on requested capture only.
- 인자: Existing capture preview/result and pageId/packId request types in main.
- 상태: permission, capture, OCR_pending, OCR_failure, preview_edit, empty, analysis, save_pending, save_retry, saved
- 저장/보상: Real saved page/custom pack; no onboarding camera permission or example pack creation.
- 연결된 개별 source record: 216; 에셋: 4.
- 로더: `lib/services/book_image_service.dart`, `lib/services/bookshelf_service.dart`, `lib/services/vocab_notebook_parser.dart`
- 화면: `lib/screens/book_capture_screen.dart`, `lib/screens/book_preview_screen.dart`, `lib/screens/book_result_screen.dart`, `lib/screens/vocab_notebook_result_screen.dart`, `lib/screens/vocab_notebook_practice_screen.dart`

### listening

- 필터: Authored 186 lessons, level/topic/goal/day/current/review; lesson.contentIds -> actual scenario IDs.
- 인자: ContentLessonScreen(lesson, scope, reviewQueue); existing deep-link scenario/content ID adaptation in main.
- 상태: goal_setup, level, topic, continue, listen, transcript, question, review, result, save_pending, retry
- 저장/보상: ContentLearningService goal/progress/answer/review stores and source IDs; old ListeningScreen is retained legacy, not the route target.
- 연결된 개별 source record: 15,085; 에셋: 202.
- 로더: `lib/features/content_learning/content_learning_catalog.dart`, `lib/services/scenario_loader.dart`, `lib/features/content_learning/content_learning_service.dart`
- 화면: `lib/features/content_learning/content_learning_hub.dart`, `lib/features/content_learning/content_lesson_screen.dart`

### scenarios

- 필터: Six level shards, shelf/scene/current mission; dialogs, quests and checkpoints retain identity.
- 인자: String scenarioId or scoped CoursePracticeContext validated by scenario route adapter.
- 상태: shelf, intro, audio_loading, audio_failure, dialog, quest, checkpoint, result, save_pending, retry
- 저장/보상: Scenario completion/checkpoint and reward claim services; direct practice is not fabricated mission evidence.
- 연결된 개별 source record: 14,164; 에셋: 275.
- 로더: `lib/services/scenario_loader.dart`, `lib/services/course_mastery_service.dart`
- 화면: `lib/screens/scenarios_list_screen.dart`, `lib/screens/scenario_player_screen.dart`

### smalltalk

- 필터: 209 authored lessons -> all 590 phrases/24 categories; level/topic/goal/continue/review. Scoped courseContext uses SmalltalkScreen.
- 인자: No course context -> native ContentLearningHub; CoursePracticeContext -> SmalltalkScreen; ContentLessonScreen(lesson, scope, reviewQueue) internally.
- 상태: goal, level, category, continue, phrase, audio, relationship_check, review, like, save_pending, retry, result
- 저장/보상: ContentLearningService plus liked content and course relationship evidence; never replace catalog with the ten supplemental cases.
- 연결된 개별 source record: 14,794; 에셋: 3.
- 로더: `lib/features/content_learning/content_learning_catalog.dart`, `lib/services/smalltalk_loader.dart`, `lib/features/content_learning/content_learning_service.dart`
- 화면: `lib/features/content_learning/content_learning_hub.dart`, `lib/features/content_learning/content_lesson_screen.dart`, `lib/screens/smalltalk_screen.dart`

### talsunbi_context

- 필터: Supplemental ten cases by level/caseId, base or transfer; case revision preserved in history.
- 인자: SmalltalkContextRequest(caseId, transfer, level); PracticeSourceReference includes revision.
- 상태: case, relation, intent, expression, effect, follow_up_partial, wrong, saved, save_failure_retry, history, transfer
- 저장/보상: PracticeHistoryStore real save; silent fan response only; revision1 history not rewritten as invite_friend revision2.
- 연결된 개별 source record: 71; 에셋: 8.
- 로더: `lib/services/smalltalk_context_catalog.dart`, `lib/services/practice_history_store.dart`
- 화면: `lib/screens/smalltalk_context_screen.dart`, `lib/widgets/smalltalk_practice_entry.dart`, `lib/screens/hanok_practice_screen.dart`

### word_web

- 필터: Learned sourceVocabId/level with explicit browse fallback; synonyms/antonyms/related expressions.
- 인자: Existing word relation/custom-pack nuance selection.
- 상태: source, empty, relation, examples, quiz, save_pending, retry
- 저장/보상: Existing seen IDs and nuance/custom-pack stores.
- 연결된 개별 source record: 3,202; 에셋: 1.
- 로더: `lib/services/word_relation_service.dart`, `lib/services/vocab_nuance_service.dart`
- 화면: `lib/screens/word_web_screen.dart`, `lib/screens/word_web_quiz_screen.dart`, `lib/screens/vocab_nuance_screen.dart`

### games

- 필터: Actual per-game rules and level pools; crossword hints 1/2/3 and direct tile placement; custom pack modes keep minimum-word requirements.
- 인자: CoursePracticeContext only for matching family; direct games and custom String packId preserve practice scope.
- 상태: level, question, selected, hint1, hint2, hint3, tile, wrong, complete, record, reward_pending, retry, replay
- 저장/보상: Per-game completion/best and YeopjeonLearningCheckpoint; actual media contact 100+150+900ms outline, no reward fabricated by animation.
- 연결된 개별 source record: 36,941; 에셋: 6.
- 로더: `lib/services/cloze_loader.dart`, `lib/services/satz_loader.dart`, `lib/services/silben_puzzle_loader.dart`, `lib/services/kkeunmari_engine.dart`, `lib/services/kkeunmari_dictionary_service.dart`, `lib/services/korean_noun_lexicon.dart`, `lib/services/storage_service.dart`
- 화면: `lib/screens/daily_challenge_screen.dart`, `lib/screens/chosung_quiz_screen.dart`, `lib/screens/silben_kreuz_screen.dart`, `lib/screens/cloze_game_screen.dart`, `lib/screens/speed_match_screen.dart`, `lib/screens/satz_arcade_screen.dart`, `lib/screens/kkeunmari_screen.dart`

### onboarding

- 필터: Existing seven steps, beginnerDraft versus A1 placement, purpose and Taego/Joy IDs; previews do not write course/rewards.
- 인자: Existing coordinator/journey request; draft and final commit journal.
- 상태: load, resume, level, purpose, story2_6, back, sound_preview, companion, committing, save_retry
- 저장/보상: Onboarding journal and account-safe final commit; one Hangul route launch is not literacy completion.
- 연결된 개별 source record: 56; 에셋: 19.
- 로더: `lib/features/onboarding_v2/onboarding_journey_repository.dart`, `lib/features/onboarding_v2/onboarding_journey_state.dart`, `lib/features/onboarding_v2/onboarding_learning_start.dart`
- 화면: `lib/screens/onboarding_v2/onboarding_setup_screen.dart`, `lib/screens/onboarding_v2/onboarding_story_screen.dart`, `lib/screens/onboarding_v2/onboarding_companion_screen.dart`

### hanok

- 필터: Real build stage/ownership/ledger and approved canonical art; dormant IlDu world separately classified.
- 인자: Existing house/stage/room requests; actual quote/purchase validation.
- 상태: loading, stage, locked, price, insufficient_funds, purchase_pending, retry, owned, furnish, opened_receipt_resume, account_invalidated, pending_data_not_previous_account
- 저장/보상: Yeopjeon construction ledger; Dancheong culture collection is a different economy.
- 연결된 개별 source record: 277; 에셋: 376.
- 로더: `lib/services/sori_stage_progression_service.dart`, `lib/services/hanok_competence_projection_service.dart`, `lib/services/yeopjeon_service.dart`
- 화면: `lib/screens/sori_stage/sori_stage_hanok_screen.dart`, `lib/screens/sarangbang_screen.dart`

### dancheong

- 필터: Real motif/stamp ownership, draft/artwork IDs; artwork does not repaint canonical architecture.
- 인자: Dancheong editor/artwork request types dispatched in main.
- 상태: collection, locked, motif, draft, editor, save_pending, retry, artwork, share
- 저장/보상: DancheongStore; collection and personal expression separate from construction currency.
- 연결된 개별 source record: 0; 에셋: 0.
- 로더: `lib/features/dancheong/dancheong_store.dart`, `lib/features/dancheong/dancheong_connections.dart`
- 화면: `lib/screens/dojangcheop_screen.dart`

### rewards

- 필터: Confirmed/pending moments, account lifetime, journal/queue/idempotent claim; source ownership before display.
- 인자: Existing claim/receipt/itemAsset adapter; approved single-item flow replaces old selection UI.
- 상태: closed, claim_pending, opening, one_item_reveal, explanation, actual_saved_XP, placement, culture_story, failure_retry, skip, return, opened_unacknowledged_resume, strict_read_failure, account_invalidated
- 저장/보상: Pending persisted receipt is separate from unopened boxes. Today/Hanok resume /bojagi with the same item and existing claim; no extra item, XP or pool change. Old maximum-three-candidate screen is not an acceptance requirement.
- 연결된 개별 source record: 116; 에셋: 42.
- 로더: `lib/services/decoration_reward_service.dart`, `lib/services/sori_stage_reward_receipt_service.dart`, `lib/services/yeopjeon_learning_checkpoint.dart`
- 화면: `lib/screens/bojagi_screen.dart`, `lib/screens/sori_stage/sori_stage_reward_receipt_sheet.dart`

### gye

- 필터: Actual membership/groupId and server weekly projection; 16+ birth-year gate and six-digit code/nickname.
- 인자: Existing String groupId/join requests.
- 상태: loading, unjoined, age_gate, create, join, invalid_code, joined, weekly_goal, members, report, leave, failure_retry
- 저장/보상: GyeService backend membership and promise records; no invented member or completion numbers.
- 연결된 개별 source record: 30; 에셋: 30.
- 로더: `lib/services/gye_service.dart`, `lib/services/sori_stage_progression_service.dart`
- 화면: `lib/screens/sori_stage/sori_stage_gye_screen.dart`, `lib/screens/gye_screen.dart`, `lib/screens/gye_members_screen.dart`

### support

- 필터: Actual guest/account/local/cloud/consent/history states; support aliases and direct modals tracked individually.
- 인자: Existing account operation and history source requests; no static enumeration of personal data.
- 상태: guest, linked, offline, pending_sync, switch, conflict, reauth, export, delete, history_empty, history, retry
- 저장/보상: Existing account operations and local lifetime guards; cloud/device QA unverified.
- 연결된 개별 source record: 181; 에셋: 1.
- 로더: `lib/services/account/account_switch_coordinator.dart`, `lib/services/local_data_lifetime.dart`, `lib/services/auth_service.dart`
- 화면: `lib/screens/profile_screen.dart`, `lib/screens/settings_screen.dart`, `lib/screens/stats_screen.dart`, `lib/screens/practice_hub_screen.dart`, `lib/screens/hanok_practice_screen.dart`

### c_roots

- 필터: Five production tabs, shared focus, IndexedStack/scroll/controller/account/TickerMode contracts.
- 인자: Existing TodayLearningDestination route and typed arguments; preview action IDs do not certify production connections.
- 상태: today, learn, games, hanok, gye, selected, focus, reselect, loading, error, empty, return, hidden_tab_account_change, done_without_error_data, opened_receipt_resume
- 저장/보상: Existing shell _open / LearningAttempt.unshown / receipt and account lifetime guards. Active and hidden tabs invalidate on account change; previous account data must not survive pending/error snapshots.
- 연결된 개별 source record: 57; 에셋: 22.
- 로더: `lib/services/learning_focus.dart`, `lib/services/sori_stage_progression_service.dart`, `lib/models/home_navigation_art.dart`
- 화면: `lib/screens/sori_stage/sori_stage_shell.dart`, `lib/screens/sori_stage/sori_stage_today_screen.dart`, `lib/screens/sori_stage/sori_stage_catalog_screen.dart`, `lib/screens/sori_stage/sori_stage_hanok_screen.dart`, `lib/screens/sori_stage/sori_stage_gye_screen.dart`

## 실제 등록 경로와 별칭/legacy

각 경로의 current main.dart 줄·해시·dispatch 원문과 typed arguments는 screen-bindings.json에 있습니다. 이름이 같은 과거 Listening 화면을 현재 native 듣기 루트로 계산하지 않습니다.

| 경로 | 분류 | 실제 source target |
|---|---|---|
| `/splash` | registered_source_route_not_click_QA | SplashScreen |
| `/quick_onboarding` | alias | OnboardingV2JourneyScreen |
| `/character_selection` | alias | OnboardingV2JourneyScreen |
| `/intro` | registered_source_route_not_click_QA | OnboardingV2JourneyScreen |
| `/` | registered_source_route_not_click_QA | OnboardingV2JourneyScreen |
| `/onboarding` | registered_source_route_not_click_QA | OnboardingV2JourneyScreen |
| `/onboarding/legacy-level` | registered_legacy | OnboardingV2JourneyScreen |
| `/onboarding/start` | alias | OnboardingV2JourneyScreen |
| `/vocab` | registered_source_route_not_click_QA | VocabPacksScreen |
| `/vocab/pack` | registered_source_route_not_click_QA | VocabPackScreen |
| `/vocab/result` | registered_source_route_not_click_QA | dispatch excerpt 참조 |
| `/vocab/recall` | registered_source_route_not_click_QA | VocabPackRecallScreen |
| `/vocab/legacy` | registered_legacy | LegacyVocabScreen |
| `/grammar` | registered_source_route_not_click_QA | dispatch excerpt 참조 |
| `/grammar_choice_quiz` | registered_source_route_not_click_QA | GrammarChoiceQuizScreen |
| `/listening` | registered_source_route_not_click_QA | ContentLearningHub |
| `/listening/play` | registered_source_route_not_click_QA | ContentLearningHub |
| `/kkeunmari` | registered_source_route_not_click_QA | KkeunmariScreen |
| `/foundation` | registered_source_route_not_click_QA | FoundationLearningScreen |
| `/hangul` | registered_source_route_not_click_QA | HangulScreen |
| `/chosung` | registered_source_route_not_click_QA | ChosungQuizScreen |
| `/wordle` | registered_source_route_not_click_QA | SilbenKreuzScreen |
| `/cloze` | registered_source_route_not_click_QA | ClozeGameScreen |
| `/speed_match` | registered_source_route_not_click_QA | SpeedMatchScreen |
| `/daily` | registered_source_route_not_click_QA | DailyChallengeScreen |
| `/calligraphy` | registered_source_route_not_click_QA | DailyCalligraphyRouteScreen |
| `/practice` | registered_source_route_not_click_QA | PracticeHubScreen |
| `/pronunciation` | registered_source_route_not_click_QA | PronunciationStudioScreen |
| `/satz_arcade` | registered_source_route_not_click_QA | SatzArcadeScreen |
| `/content/goals` | registered_source_route_not_click_QA | ContentGoalSettingsScreen |
| `/settings` | registered_source_route_not_click_QA | SettingsScreen |
| `/guide` | registered_source_route_not_click_QA | GuideHubRouteScreen |
| `/study-library` | registered_source_route_not_click_QA | StudyLibraryScreen |
| `/stats` | registered_source_route_not_click_QA | StatsScreen |
| `/profile` | registered_source_route_not_click_QA | ProfileScreen |
| `/review` | registered_source_route_not_click_QA | ReviewSessionScreen |
| `/review/hub` | registered_source_route_not_click_QA | ReviewHubScreen |
| `/smalltalk/context` | registered_source_route_not_click_QA | SmalltalkContextScreen |
| `/hanok/practice` | registered_source_route_not_click_QA | HanokPracticeScreen |
| `/smalltalk` | registered_source_route_not_click_QA | ContentLearningHub, SmalltalkScreen |
| `/media_phrases` | registered_source_route_not_click_QA | MediaPhraseScreen |
| `/scenarios` | registered_source_route_not_click_QA | dispatch excerpt 참조 |
| `/quests` | registered_source_route_not_click_QA | QuestsScreen |
| `/book` | registered_source_route_not_click_QA | BookCaptureScreen |
| `/vocab_notebook` | registered_source_route_not_click_QA | BookCaptureScreen |
| `/vocab_notebook/result` | registered_source_route_not_click_QA | VocabNotebookResultScreen |
| `/vocab_notebook/practice` | registered_source_route_not_click_QA | VocabNotebookPracticeScreen |
| `/vocab_notebook/nuance` | registered_source_route_not_click_QA | VocabNuanceScreen |
| `/vocab_notebook/studio` | registered_source_route_not_click_QA | VocabNotebookStudioScreen |
| `/book/preview` | registered_source_route_not_click_QA | BookPreviewScreen |
| `/book/result` | registered_source_route_not_click_QA | BookResultScreen |
| `/my_words` | registered_source_route_not_click_QA | MyWordsScreen |
| `/wordbook/search` | alias | MyWordsScreen |
| `/bookshelf` | alias | MyWordsScreen |
| `/hard_words` | alias | MyWordsScreen |
| `/bookshelf/page` | registered_source_route_not_click_QA | BookshelfPageScreen |
| `/custom_pack/play` | registered_source_route_not_click_QA | CustomPackPlayScreen |
| `/custom_pack/edit` | registered_source_route_not_click_QA | CustomPackEditScreen |
| `/custom_pack/quiz` | registered_source_route_not_click_QA | CustomPackQuizScreen |
| `/custom_pack/matching` | registered_source_route_not_click_QA | CustomPackMatchingScreen |
| `/custom_pack/typing` | registered_source_route_not_click_QA | CustomPackTypingScreen |
| `/word_web` | registered_source_route_not_click_QA | WordWebScreen |
| `/dojangcheop` | registered_source_route_not_click_QA | DojangcheopScreen |
| `/dancheong-studio` | registered_source_route_not_click_QA | DancheongStudioScreen |
| `/dancheong-entry` | registered_source_route_not_click_QA | dispatch excerpt 참조 |
| `/dancheong-studio/edit` | registered_source_route_not_click_QA | DancheongEditorScreen |
| `/dancheong-artwork` | registered_source_route_not_click_QA | DancheongArtworkScreen, DancheongShareScreen, DancheongStudioScreen |
| `/dancheong-share` | alias | DancheongArtworkScreen, DancheongShareScreen, DancheongStudioScreen |
| `/hanok/construction` | registered_source_route_not_click_QA | IlDuConstructionScreen |
| `/hanok` | registered_source_route_not_click_QA | dispatch excerpt 참조 |
| `/hanok/anbang` | registered_source_route_not_click_QA | dispatch excerpt 참조 |
| `/hanok/daecheong` | registered_source_route_not_click_QA | dispatch excerpt 참조 |
| `/sarangbang` | registered_source_route_not_click_QA | SarangbangStudyScreen |
| `/sarangbang/furnish` | registered_source_route_not_click_QA | SarangbangFurnishScreen |
| `/bojagi` | registered_source_route_not_click_QA | BojagiScreen |
| `/gye/create` | registered_source_route_not_click_QA | GyeCreateScreen |
| `/gye/join` | registered_source_route_not_click_QA | GyeJoinScreen |
| `/gye/hub` | registered_source_route_not_click_QA | GyeTabScreen |
| `/gye` | registered_source_route_not_click_QA | GyeScreen |
| `/gye/members` | registered_source_route_not_click_QA | GyeMembersScreen |
| `/path` | registered_source_route_not_click_QA | LearningPathScreen |
| `/course/phases` | registered_source_route_not_click_QA | LearningPhasesScreen |
| `/course/phase` | registered_source_route_not_click_QA | LearningPhaseDetailScreen, LearningPhasesScreen |
| `/learning-phase/task` | registered_source_route_not_click_QA | LearningPhasesScreen, PhaseTaskScreen |
| `/course/mission` | registered_source_route_not_click_QA | CourseMissionScreen |
| `/course/reassessment` | registered_source_route_not_click_QA | CourseReassessmentScreen |
| `/scenario` | registered_source_route_not_click_QA | ScenarioPlayerScreen |

## 지원/계정/이력·직접 모달

과거 97flow 목록의 개별 source 파일과 현재 등록 경로를 재확인합니다. 개별 상태·visible action·preserve contract·mockup variant는 JSON 원장에 보존하며 완료 플래그를 승계하지 않습니다.

| flow | 현재 source 증거 |
|---|---:|
| first_run | 5/5 |
| splash | 1/1 |
| consent | 1/1 |
| intro_gate | 1/1 |
| first_success | 2/2 |
| optional_companion | 1/1 |
| review_demo | 2/2 |
| settings | 1/1 |
| profile | 1/1 |
| account_operations | 2/2 |
| stats | 1/1 |
| content_goals | 1/1 |
| guide | 1/1 |
| guide_topic | 1/1 |
| placement_diagnostic | 1/1 |
| hanok_downloads | 1/1 |
| study_library | 1/1 |
| my_words | 4/4 |
| pack_share_redeem | 1/1 |
| bookshelf_page | 1/1 |
| custom_edit | 1/1 |
| custom_play | 1/1 |
| custom_quiz | 1/1 |
| custom_matching | 1/1 |
| custom_typing | 1/1 |
| hard_quiz | 1/1 |
| book_capture | 1/1 |
| book_preview | 1/1 |
| book_result | 1/1 |
| notebook_result | 1/1 |
| notebook_practice | 1/1 |
| notebook_studio | 1/1 |
| notebook_nuance | 1/1 |
| hanok_preview | 1/1 |
| construction_explorer | 1/1 |
| yeopjeon_wallet | 1/1 |
| room_study | 1/1 |
| room_furnish | 2/2 |
| treasure_chest | 1/1 |
| stamps | 1/1 |
| dancheong_studio | 1/1 |
| dancheong_editor | 1/1 |
| dancheong_artwork | 1/1 |
| dancheong_share | 1/1 |
| dancheong_visitor | 1/1 |
| gye_hub | 2/2 |
| gye_create | 1/1 |
| gye_join | 1/1 |
| gye_detail | 1/1 |
| gye_members | 1/1 |
| gye_social_sheets | 2/2 |
| practice_history | 1/1 |
| smalltalk_context | 1/1 |
| reward_receipt | 1/1 |
| global_recovery | 3/3 |
| gye_dedication | 2/2 |
| course_path | 1/1 |
| course_phases | 1/1 |
| phase_task | 1/1 |
| course_mission | 1/1 |
| course_reassessment | 1/1 |
| vocab_packs | 1/1 |
| vocab_pack | 1/1 |
| vocab_result | 1/1 |
| vocab_recall | 1/1 |
| review_hub | 1/1 |
| review_session | 1/1 |
| listening | 1/1 |
| content_lesson | 1/1 |
| smalltalk | 3/3 |
| scenarios | 1/1 |
| scenario_player | 1/1 |
| persona_people | 1/1 |
| persona_profile | 1/1 |
| word_web | 1/1 |
| word_web_study | 1/1 |
| word_web_quiz | 1/1 |
| grammar | 1/1 |
| grammar_choice | 1/1 |
| hangul | 1/1 |
| calligraphy | 1/1 |
| pronunciation | 1/1 |
| quests | 1/1 |
| daily_game | 1/1 |
| chosung | 1/1 |
| syllable_cross | 1/1 |
| cloze | 1/1 |
| speed_match | 1/1 |
| sentence_arcade | 1/1 |
| kkeunmari | 1/1 |
| registered_practice_hub | 1/1 |
| registered_media_phrases | 1/1 |
| legacy_vocab | 1/1 |
| weekly_activity | 1/1 |
| cultural_help | 1/1 |
| content_feedback | 1/1 |
| gye_age_gate | 3/3 |

## 재사용 컴포넌트와 검토 진입점

각 컴포넌트의 실제 파일 해시·현재 import consumer를 JSON 원장에 남깁니다. 사용된다는 소스 증거는 실제 상태 실행/시각 승인이 아닙니다.

| 컴포넌트 소스 | 현재 import consumer 수 |
|---|---:|
| `lib/widgets/sori/c_gallery/c_materials.dart` | 25 |
| `lib/widgets/sori/c_gallery/c_palette.dart` | 3 |
| `lib/widgets/sori/c_gallery/c_objects.dart` | 12 |
| `lib/screens/sori_stage/c_stage_chrome.dart` | 5 |
| `lib/widgets/sori/adaptive_navigation.dart` | 1 |
| `lib/widgets/sori/learning_entry_paths.dart` | 1 |
| `lib/widgets/practice_scholar_art.dart` | 4 |
| `lib/widgets/practice_scholar_explanation.dart` | 1 |
| `lib/widgets/practice_dokkaebi_canvas.dart` | 2 |
| `lib/widgets/practice_dokkaebi_help.dart` | 1 |
| `lib/widgets/sori/dokkaebi_flame_frame.dart` | 1 |
| `lib/widgets/sori/dokkaebi_intro.dart` | 1 |
| `lib/widgets/sori/bojagi_reveal.dart` | 0 |
| `lib/widgets/sori/reward_chest/reward_chest_screen.dart` | 1 |
| `lib/widgets/sori/reward_chest/reward_cultural_story.dart` | 1 |

tool/c_content_flow_preview.dart는 실제 KoLernenApp route switch를 별도 origin의 로컬 Storage로 검토하는 진입점입니다. concept_c_preview.dart의 하위 로컬 샘플 상태와 구분합니다. 이 원장 자체는 preview 실행·build·렌더 QA를 수행하지 않습니다.

과거 보자기 후보 UI 테스트는 소유 세션의 bojagi-screen-tests-before.dart에 정확한 바이트로 보존되어 있습니다. 그 보존은 최신 단일 아이템 UI를 3후보로 되돌릴 요구가 아닙니다.

상자 오디오는 HANDOFF.md:215의 mute preview 계약과 파일 부재를 따릅니다. SFX 경로만으로 파일·라이선스·기기 소리 QA 완료를 주장하지 않습니다.
