# W7 PR2 · 퀘스트 엔진 UI·오디오 (지시서 4.5 · 4.7 · 4.8/4.10 · 4.13 · 2.9 파생 · 1.24 파생)

> 정본: 마스터플랜 §8.2 (`C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-zany-pancake.md`). 이 문서는 Sonnet 발주용 태스크 단위 브리프이며 줄 앵커는 **origin/main `d120af87`**(2026-09-03 Sonnet 읽기 전용 조사 + Fable 대조) 기준이다. 발주 전 `python tool/check_brief_anchors.py <이 파일>`로 앵커를 검사한다.
> 워크트리 `C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr2-quest-20260903`, 브랜치 `claude/w7-pr2-quest-20260903`. 원장 `.superpowers/sdd/2026-09-03-w7-pr2-quest/progress.md`(force-add).
> 체제: Fable 설계·브리프·직독 판정 / Sonnet 구현·1차 리뷰. 커밋 `<type>(<scope>): <한국어 요약> (지시서 N.N)` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`, 아이덴티티 Codex/codex@local, 푸시 없음.

## 상시 규칙 (§4 템플릿 10–15)
- 자동 발화 화면 위젯 테스트는 `setUp`에서 `stubSoriSpeech()`(`test/support/sori_speech_stubs.dart`)를 쓴다 — `SoriSpeech.resetForTesting()`만으로는 가드(`test/auto_speech_test_stub_guard_test.dart`)가 미스텁으로 본다.
- 고정 단언은 절대 구현에 맞춰 바꾸지 않는다(R2) — 못 통과하면 멈추고 보고. 래칫·allowlist 상향 금지(R3). `if/else` 중괄호 필수(R5). 하드코딩 사용자 문자열 금지(arb de/en 동기, R6).
- 리뷰어 변이 검사(probe 파일)는 구현자 검증 실행과 동시에 돌리지 않는다.
- `content_audio_policy_guard_test.dart`는 문자열 가드: targetScreens 화면 소스에 `TtsService` 리터럴이 있으면 즉시 RED, `speakable.dart`의 `TtsService.stop()`·`didPushNext`·`int _generation` 리터럴은 유지.
- 스니펫의 상수·필드명·라인은 구현 전 실제 코드와 대조하고, 어긋나면 브리프 결함으로 보고한다(구현자가 임의로 설계를 바꾸지 않는다).

## 사실 (조사 결과, 파일:줄)
- `lib/screens/scenario_player_screen.dart`: 대사 버블은 `onTap`에서만 발화(L1403), `_next()`(L925)와 `PageController` 흐름(L597–945)에 자동재생 없음. 어휘 스테이지의 `AddToWordbookButton(compact: true)`는 L1292–1296(대사 카드에는 없음). 자체 `PopScope`는 L2139.
- `lib/screens/quest_engines/luecken_quest.dart`·`uebersetzen_quest.dart`: TTS 호출 0건. `particle_pop_quest.dart:341` `onTap: () => TtsService.speak(_fullSentence)`, `initState` L73–83 애니메이션만. `hoerverstehen_quest.dart:65-71` initState 포스트프레임 `TtsService.speak(_audioKo)`. `diktat_quest.dart:361-368` `_playTts()`.
- `lib/widgets/sori/tokens.dart:151-168` `SoriGaps` 8토큰 정의, lib 사용처 0. `Spacing.sm` 옵션 간격: diktat L228/268/287/509/552/561/583, hoerverstehen L173/180/205, luecken L167, uebersetzen L147.
- `lib/screens/quest_engines/quest_flow.dart:18-46` `SoriQuestCorrectFeedback`(burst+sound+haptic); `.play(context)` 호출은 `batchim_drop_quest.dart:191`, `satz_bauen_quest.dart:355`뿐.
- `diktat_quest.dart:319-320` `_promptDe/_promptEn`, `_meaning()` L377–381; `tools/content_factory/validate_content.py:1732` diktat 필수키 `("targetKo","promptDe","promptEn")`. arb에 `diktatMeaningKo` 없음.
- `lib/screens/silben_kreuz_screen.dart:322-333` `TtsService.speak` 직접 호출; `test/content_audio_policy_guard_test.dart:12-24` targetScreens 12개에 silben 없음.
- `ContentSpeechController`(`lib/widgets/sori/speakable.dart` 하단): `playOnEnter(text, {voice})`, 라우트 옵저버 구독으로 `didPushNext/deactivate` 시 다음 프레임 `TtsService.stop()`. 선례 `lib/screens/review_session_screen.dart`.

## T2.1 자동재생 — dialog 스테이지 + luecken/uebersetzen/particle_pop (지시서 4.5) ⚠ 최우선·최고 위험
- **Fable 룰링 정정(2026-09-04, fix round 1)**: 퀴즈 3종(luecken·uebersetzen·particle_pop)은 읽을 수 있는 한국어 문장이 곧 정답(채운 문장·완성 문장·정답 옵션)이라 **진입 자동재생 면제**. 대신 답 공개 직후 정답 문장을 `SoriSpeech.speak`로 **1회** 읽되, 그 문자열이 `assets/data/tts_canonical_manifest.json`에 있을 때만(#254 canonical 게이트 — 비-canonical은 비로그인 시 '오디오 없음' 배너). 비-canonical이면 구현하지 않고 W9-C 콘텐츠 파이프라인으로 보낸다. 아래 원문 GOAL 중 "세 퀘스트=문제 문장"은 이 룰링으로 대체된다.
- GOAL: 스테이지 진입 시 대표 문장 1개 자동재생(§9-1 룰링: 순차 전체 읽기 아님). dialog=현재 대사, 세 퀘스트=문제 문장. 뒤로/전환 시 정지.
- FILES: `lib/screens/scenario_player_screen.dart`(필드 `final _speech = ContentSpeechController();` + dispose; `_next()` L925 및 초기 스테이지 결정 지점에서 dialog 스테이지면 `_speech.playOnEnter(현재 대사.ko, voice: sc.voiceForSpeaker(...))`), `luecken_quest.dart`, `uebersetzen_quest.dart`, `particle_pop_quest.dart`(각 `initState` 포스트프레임에서 `widget.audioEnabled && mounted`일 때 **`SoriSpeech.speak(문제 문장)`** — `TtsService` 직접 호출 금지), `hoerverstehen_quest.dart:65-71`·`diktat_quest.dart:361-368`·`particle_pop_quest.dart:341`의 `TtsService.speak` → `SoriSpeech.speak`로 통일.
- INTERFACE: 기존 `SoriSpeech.speak(String, {String? voice})` / `ContentSpeechController.playOnEnter`. 새 public API 없음. `audioEnabled` 플래그가 없는 엔진은 quest_flow에서 내려오는 기존 플래그를 재사용(없으면 보고).
- DO NOT: 순차 자동 진행 추가 금지; `SoriSpeakable` 계약 변경 금지; `_buildDialog` 탭 재생(L1403) 제거 금지; 디바운스 상수 신설 금지(`playOnEnter`는 `Duration.zero`).
- FROZEN: `test/content_audio_policy_guard_test.dart` 전부(targetScreens는 T2.5에서만 확장), `test/speakable_screen_lifecycle_test.dart`, `test/sori_speech_phase_matrix_test.dart`.
- TDD: (1) `test/scenario_player_ui_test.dart`에 `stubSoriSpeech()` 기반 신규 `'스테이지 전환마다 대표 문장 1회 자동재생, 뒤로 전환 시 정지'`(기존 `speakCalls` 기대값은 [자동재생 첫 대사, 탭]으로 갱신 — 계약 변경 명시) → RED (2) `test/quest_engines_uiux_test.dart` 신규 그룹 `'선택형 퀘스트 3종은 진입 시 문제 문장을 1회 자동재생'`(audioEnabled=false면 0회) → RED (3) 구현 (4) GREEN (5) analyze 0 (6) `flutter test --no-pub test/content_audio_policy_guard_test.dart test/auto_speech_test_stub_guard_test.dart`.
- DONE: 위 테스트 GREEN, 가드 2종 GREEN, 5개 엔진 소스에 `TtsService` 리터럴 0(주석 포함 — T2.5의 가드 확장 전제).
- REPORT: diffstat · RED/GREEN 로그 · analyze · 예상 밖 가드 실패 · ≤3 의문.

## T2.2 정답 효과 5엔진 (지시서 4.7)
- FILES: `hoerverstehen_quest.dart`, `luecken_quest.dart`, `uebersetzen_quest.dart`, `particle_pop_quest.dart`, `diktat_quest.dart` — `batchim_drop_quest.dart`(필드 `final SoriQuestCorrectFeedback correctFeedback;` 기본 `const SoriQuestCorrectFeedback()`, 정답 분기 `widget.correctFeedback.play(context)`, L191)와 동일 패턴. 정답 분기의 기존 `HapticFeedback.*Impact()`는 제거(play가 haptic 포함).
- DO NOT: 오답 경로 `SoundService.wrong()` 변경 금지; hoerverstehen 2회 시도 규칙 불변; 볼륨 리터럴 금지.
- TDD: `quest_engines_uiux_test.dart`의 엔진 리스트를 7종으로 확장해 `burstCalls/soundCalls/hapticCalls == 1` 단언 → RED → 구현 → GREEN.
- DONE: 7/7 엔진 단언 GREEN, `audio_policy_guard_test` GREEN.

## T2.3 SoriGaps 배선 (지시서 4.8/4.10)
- **Fable 룰링 정정(2026-09-04, fix round 1)**: 잔여 6토큰을 quest_flow에 "각 1곳 이상 적용"하라는 원문 지시는 폐기 — 의미 불일치 치환을 유도했다. 필수 사용은 `optionGap`·`questionToOptions`뿐이며, 나머지 6토큰은 가드의 미채택 목록(하향 전용 래칫)으로 관리하고 의미가 맞는 표면(PR4 크롬·W8 폼·표준 페이지)에서만 채택한다. 검증은 테스트 파일별 개별 실행(`--concurrency=1`).
- FILES: 위 `Spacing.sm` 옵션 간격 사이트 → `SoriGaps.optionGap`(12, 의도된 시각 변경); 문제→옵션 `Spacing.lg` → `SoriGaps.questionToOptions`; 잔여 토큰(cardGap/labelToField/chromeToContent/headingToBody/paragraphGap/sectionGap)은 `quest_flow.dart`에 각 1곳 이상 적용. `satz_bauen_quest.dart`의 로컬 `sectionGap`은 값 불변·개명만.
- TDD: 신규 `test/sori_gaps_usage_guard_test.dart`(lib 스캔, 8토큰 각 참조 ≥1 — 배선 전 RED 정상) + `quest_engines_uiux_test`에 옵션 타일 간격 12 단언.
- DO NOT: `spacing_literal_guard`(ceiling 181) 새 리터럴 0; 골든 로컬 재생성 금지(Linux CI 정본 — 시각 변경이므로 PR CI `task=regenerate-goldens` 대상 목록을 보고).

## T2.4 Diktat 한국어 뜻 (지시서 4.13, §9-3 룰링)
- FILES: `diktat_quest.dart:319-320` 옆 `String get _promptKo => (widget.data['promptKo'] as String?)?.trim() ?? '';`, 리뷰 카드 '의미 보기' 토글을 `_completed` 게이트(미완료 시 버튼 미표시; 열리면 DE/EN + `_promptKo.isNotEmpty`일 때 KO 줄), `tools/content_factory/validate_content.py:1732` `promptKo` 선택 문자열(targetKo와 동일하면 오류), arb `diktatMeaningKo` de "Auf Koreanisch" / en "In Korean" + `flutter gen-l10n`.
- TDD: `quest_engines_uiux_test` 3건(미완료 토글 부재 · 완료 후 DE/EN · promptKo 있으면 KO 줄) + `tools/content_factory` 파이썬 테스트 1건.
- DO NOT: 데이터 백필 금지(W9-C).

## T2.5 Silben SoriSpeech 이관 (2.9 파생)
- FILES: `silben_kreuz_screen.dart:322-333` `TtsService.speak(` → `SoriSpeech.speak(`, import 교체, dispose에 `unawaited(SoriSpeech.stop())`; `test/content_audio_policy_guard_test.dart:12-24` targetScreens에 silben 추가(**T2.1 완료 후** — 5개 엔진과 silben 소스에 `TtsService` 리터럴 0 확인 뒤).
- DONE: 가드 GREEN(targetScreens 13→14), silben 기존 테스트 GREEN.

## T2.6 대사 카드 책갈피 (1.24 파생, §9-2 룰링: 책갈피만, 하트 제외)
- FILES: `scenario_player_screen.dart` `_buildDialog` 대사 카드 Column 끝에 `AddToWordbookButton(compact: true, korean: line.ko, translationDe: line.de, translationEn: line.en)`(어휘 행 L1292 패턴).
- TDD: `scenario_player_ui_test` `'대사 카드 책갈피 탭은 quickAdd 1회'`(CustomPackService 페이크) + 카드 onTap(재생)과 버튼 탭 비전파 단언.

## 종료 게이트
전 태스크 Fable 승인 → 전체 스위트(0 실패, skip ≤15) · analyze 0 · 리뷰어 `ecc:flutter-reviewer`+`ecc:a11y-architect`(Semantics) · opus 브랜치 리뷰 · graphify · 원장 커밋 → Jin 요청 시 푸시·PR(PR1 뒤 병합 순서: PR2 → PR4).
