# 인수인계서(2026-08-27) 1:1 검수 매트릭스 — 2026-09-01

> 방법: origin/main(0dc760fe) 콘텐츠 대상, 주장별 read-only 검증 에이전트 52 + `미반영`/`불일치` 1차 판정 전건 적대적 재검증 + 완전성 비평자. 함정 3종(인계서 stale 서술·W5 간접 구현·Storage 접근자) 브리프 적용. 판정값: 반영 / 의도적 보류 / 미반영 / 불일치 / 검증불가.
>
> 집계: **반영 47** · **불일치 3** · **의도적 보류 2** (총 52) + 비평자 후속 H-53~H-56(반영 3·불일치 1) → **최종: 반영 50 · 의도적 보류 2 · 불일치 4 (총 56)**. `미반영 0` — 인계서의 실행 항목 중 main에 누락된 것은 없다. 불일치 4건은 전부 "인계서 서술이 현재 main보다 낡음/부정확" 방향이다(하단 부록).

| id | 판정 | 주장 요약 |
|---|---|---|
| H-01 | 반영 | W1 웨이브가 main에 병합됨 — merge 5e98e493 "Merge W1 데이터·즉효 버그 웨이브" + 632e7786 플랜 문서 보존 커밋이 main… |
| H-02 | 반영 | Jin 확정 13건이 main에 병합됨 — merge 10571b95, parents 5e98e493/2faef696 |
| H-03 | 반영 | W2 성능 웨이브가 main에 병합됨 — merge 2ac96dfb; 10태스크 커밋들(002661a8,01d9202a,1e4c8ad5,96557654,c74… |
| H-04 | 반영 | W3 전역 시스템 웨이브가 main에 병합됨 — merge 51c8fffb; SoriLayout/SoriGaps/SoriChromeRow/speakable.d… |
| H-05 | 반영 | W3.5 하드닝이 main에 병합됨 — merge 9b92973d; TTS 로컬캐시 catch 확대 + 전역 에러 훅(runZonedGuarded/Flutte… |
| H-06 | 반영 | 인계서 시점 main HEAD는 8faae14f였고 origin과 동기였다 (ci 리모트 상태는 이 컨테이너에서 검증 불가) |
| H-07 | 반영 | W4 T1: 7f259706 — LearnSessionQueue에 _servedIds/currentIsRepeat 게터 추가, servedPosition 수식… |
| H-08 | 반영 | W4 T2: 6e20f021 — 재출제 카운터 단일 칩 병기("+N Wdh.") + dispose 진행 영속화 |
| H-09 | 반영 | W4 T3: 721505c0+270adfce — 결과화면 AppBar 뒤로가기 복구, CTA 무조건 pop() 단순화 |
| H-10 | 반영 | W4 오버플로 묶음: 02e1bf5c — 카운터·퀴즈 헤더 Flexible 래핑(ellipsis 아님) + 320/360dp 회귀 테스트 |
| H-11 | 반영 | W4 T4: 55d6e815+dc95f2d0 — 표준팩 소급 복구(팩 목록 열람 재동기화), != → > 클램프, 5청크 동시성 제한 |
| H-12 | 반영 | W4 T5: dc1fc1f0 — 커스텀팩 quiz/matching/typing에 addVokSeen+learnedWordCount, 책장 "n von m" |
| H-13 | 반영 | W4 T6: a62c6556 — course_mission_navigation.dart에 activeScenarioCheckpointContext 헬퍼, co… |
| H-14 | 반영 | W4 T7: 4e9dea5f — setScenarioStars 첫 기록 0성 허용, 재시도 단조 |
| H-15 | 반영 | W4 T8: aa5914bf+a07b1d5f — scenario_player courseContext 자동 유도 + activeScenarioCheckpoin… |
| H-16 | 반영 | W4 T9: scenarios_list_screen.dart onClosed 즉시 갱신(0/2→1/2)이 main에 존재 |
| H-17 | 반영 | W4 T10: 일별 학습 원장 — storage_service.dart에 kl_study_log_v1_ 프리픽스(일자별 키), test/study_log_te… |
| H-18 | 반영 | W4 T11: review_deck_service.dart에 deckForIds 존재 |
| H-19 | 반영 | W4 T12: review_hub_screen.dart 존재 + main.dart에 /review/hub 라우트, /review는 여전히 플레이어 |
| H-20 | 반영 | W4 T13: buildGrammarChoiceRound에 allowedTargetIds 파라미터, main.dart 라우트 인자 파싱 |
| H-21 | 반영 | W4 T14: lib/models/grammar_study_plan.dart + lib/services/grammar_plan_service.dart 존재 |
| H-22 | 반영 | W4 T15: kl_gram_plan_v1 저장 — Storage.grammarPlanRawJson 접근자가 cloud_sync.dart와 learning_d… |
| H-23 | 반영 | W4 T16: grammar_screen.dart 플랜 모드(GrammarStudyPlan/_applyPlanSlice/planDayLabel, 첫 진입 시트) |
| H-24 | 반영 | W4 T17: grammar_choice_quiz_screen.dart 존재 + /grammar_choice_quiz 라우트 등록(T16이 호출하는 라우트) |
| H-25 | 반영 | W4 T18: 백업 화이트리스트 — cloud_sync.dart payload/restore에 study_log_json·gram_plan_json, lear… |
| H-26 | 반영 | W4 queued 2건 처리 — ① T2 카운터 +2 누적 테스트 보강 ② bookshelf_screen.dart 같은 build 내 learnedWordCo… |
| H-27 | 반영 | W5 계약1: 레벨 필터 이관 완료 — test/level_filter_guard_test.dart allowlist 공란, 7개 플레이 표면은 sheet 방… |
| H-28 | 반영 | W5 계약2: 오디오 롤아웃 완료 — test/content_audio_policy_guard_test.dart가 9표면(vocab_pack,legacy_vo… |
| H-29 | 반영 | W5 계약3: /review onPrevious 배선 — review_session_screen.dart :661 부근, SRS 재출제 안전은 lib/serv… |
| H-30 | 의도적 보류 | W5 계약4: FeedPhysics.snap 기본 전환은 의도적 보류 — content_feed.dart 기본값 legacy 유지, lib/data/feed_… |
| H-31 | 반영 | W5 계약5: 홈 이스케이프 해치 — study_frame.dart :54-62가 SoriHomeAction 주입, test/study_home_escape_… |
| H-32 | 반영 | W5 계약6: hero_placement_guard 4→0 — knownViolators 공란, HanokHeader가 chosung_quiz/hangul/l… |
| H-33 | 반영 | chipWrapAllowlist 5→0 — chrome_stack_guard_test.dart 공란, study_library_screen은 migrated … |
| H-34 | 반영 | W3.5 이월 5건 전부 처리(PR #210) — ① vocab_pack _finish()→vocab_pack_finish_coordinator.dart(재진… |
| H-35 | 반영 | 마스터플랜 W5 잔여 스코프 반영 — 퀘스트 피드백(quest_flow), Diktat 재설계, Anlaut 크롬 압축, Silben 셀 UX(silben_p… |
| H-36 | 반영 | W6 오디오 게인 스윕 완료 — tool/measure_audio_gain.py, tool/audio_gain_report.json(46파일/위반 0), te… |
| H-37 | 반영 | W6 cloze 8그룹 완료 + 게이트 준수 — lib/data/cloze_topic_groups.dart(8그룹), arb DE/EN 동시, level_fi… |
| H-38 | 반영 | W6 시나리오 아트 — 공장(매니페스트·프롬프트·감사)은 완성됐으나 전용 아트 0/126 생성(전부 not_generated, 카테고리 포스터 13종 폴백),… |
| H-39 | 반영 | tool/audit_scene_assets.py 존재 + 형제 테스트 |
| H-40 | 반영 | §7 계약 4건 유지 — ① servedPosition 동결(고정 테스트) ② recordScenarioCheckpoint 자가유도 금지(course_mast… |
| H-41 | 반영 | 살아있는 계약 유지 — audio_policy_guard(볼륨 리터럴), game_surface_contract(7게임 SoriStudyFrame), arb_… |
| H-42 | 반영 | 래칫 하향 전용 유지 — §7 표의 값들(spacing 181, fontSize 115/15파일, ellipsis 0, fontFamily 0, raw App… |
| H-43 | 반영 | by-design 침묵 실패 보존 — receipt fail-open 2곳, TTS best-effort 지점들이 "고쳐지지" 않고 유지됨 |
| H-44 | 반영 | §8 SDD 원장 — W2/W3/W4 원장 전문은 인계서에 보존됐으나 W3.5 loose 3파일(w35-execution-report.md 등)은 main에 … |
| H-45 | 불일치 ⚠ | §9-1: partner_rewrite_diff.md+batches는 tracked, diff2.md는 여전히 untracked(이 컨테이너에 부재), 97건… |
| H-46 | 반영 | §9-7/8: 지시서 파일(docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md) 여전히 미추적, new_인보딩/ 미추적 — 단 completio… |
| H-47 | 의도적 보류 | §9-4: tiger_choose 그림자 24.1%는 수리되지 않고 tool/clip_matte_report.json에서 per-clip 예산 0.25(기본 … |
| H-48 | 반영 | §9-9: w3 워크트리 잔여(test/vocab_pack_narrow_viewport_header_test.dart 146줄)는 main에 랜딩되지 않음 —… |
| H-49 | 불일치 ⚠ | 릴리스: versionCode 28(내부)·29(비공개) 업로드 실재 — 릴리스 커밋 54dae1f0/1e3d8bc6은 pubspec bump이고 실제 Pla… |
| H-50 | 불일치 ⚠ | AGENTS.md #100 태블릿 골든 게이트 — "medium/expanded 6장 깨짐"이 여전히 유효한가(이미 수리됐으면 게이트 stale) |
| H-51 | 반영 | closed-testing-checklist §0 플립게이트(ae024af6) 해소 여부 딥 트레이스 |
| H-52 | 반영 | docs/딥리서치-한옥과한글소리.md 선행 대조 기록과의 교차 검증 |

---

## 항목별 판정·근거

### H-01 — 반영

**주장:** W1 웨이브가 main에 병합됨 — merge 5e98e493 "Merge W1 데이터·즉효 버그 웨이브" + 632e7786 플랜 문서 보존 커밋이 main 이력에 존재

**근거:** git -C /home/user/ko_lernen_app_worktrees/handoff-verify merge-base --is-ancestor 5e98e493 origin/main → true; same for 632e7786 → true. Commit 5e98e493 is confirmed merge commit "Merge W1 데이터·즉효 버그 웨이브 (feat/w1-content-quickfixes)" (parents 360d61c8, d7be658a, Codex, 2026-08-26 22:06:51 +0200). Commit 632e778619ce5a52e3ba6caefbd4b715a0bc12be is "docs(plan): W1 플랜 문서 기록 보존" (2026-08-26 22:47:11 +0200), adding docs/superpowers/plans/2026-08-26-w1-content-quickfixes.md (492 lines) — the W1 plan preservation doc.

**비고:** Both SHAs exist verbatim in origin/main history with commit messages matching the claim exactly; no discrepancy found.

### H-02 — 반영

**주장:** Jin 확정 13건이 main에 병합됨 — merge 10571b95, parents 5e98e493/2faef696

**근거:** In worktree /home/user/ko_lernen_app_worktrees/handoff-verify: `git show 10571b95 --format=%P -s` → parents `5e98e49300e640994caa098d55ec5cd2e6655967` and `2faef696c24e5b3cb6fa99e382d0b268707f27af`, matching claim's 5e98e493/2faef696 exactly. Commit subject: "Merge Jin 확정 13건 — 파트너 토픽 문장 7·표제어 현대화 6" (7+6=13, matches "13건"). `git merge-base --is-ancestor 10571b95 origin/main` → is ancestor (confirmed on origin/main). `git branch --contains 10571b95` lists local `main`.

**비고:** All three claim elements (merge SHA, both parent SHAs, and the "13건" count via the commit's own 7+6 breakdown) independently verified against actual git history, not against handoff prose.

### H-03 — 반영

**주장:** W2 성능 웨이브가 main에 병합됨 — merge 2ac96dfb; 10태스크 커밋들(002661a8,01d9202a,1e4c8ad5,96557654,c74bf968,81ba384c,ee5e0b2c,4524d099,e9795377,3797431e) 존재

**근거:** Merge commit 2ac96dfb6958165afd1d0a76f0bc26be6c10a1a9 ("Merge W2 성능 웨이브 (feat/w2-performance)", parents ca27367d + 9f55341d) is an ancestor of origin/main (`git merge-base --is-ancestor 2ac96dfb origin/main` succeeds; origin/main tip is 0dc760fe "Merge pull request #245 ..."). All 10 cited task commits are also ancestors of origin/main, verified individually via `git merge-base --is-ancestor <sha> origin/main` and `git show --no-patch`: 002661a8 (docs: W2 콜드스타트 계측 절차), 01d9202a (perf(sori-stage) P4-1, 검수#7), 1e4c8ad5 (perf(sori-stage) 카탈로그 lazy load P4-2), 96557654 (perf(storage) 메모이즈 P4-3), c74bf968 (perf(sori-stage) _cellAspectRatio 메모이즈 P4-4), 81ba384c (perf(splash) 게이트 P4-5, 검수#10), ee5e0b2c (perf(scenario) P5-1), 4524d099 (test(main) 가드 재작성, 검수#11), e9795377 (perf(startup) 병렬화 P5-2), 3797431e (perf(android) 스플래시 아이콘 P5-3, 검수#26).

**비고:** All 11 SHAs (1 merge + 10 task commits) confirmed present and reachable from origin/main HEAD; no discrepancy found with the claim.

### H-04 — 반영

**주장:** W3 전역 시스템 웨이브가 main에 병합됨 — merge 51c8fffb; SoriLayout/SoriGaps/SoriChromeRow/speakable.dart/FeedPhysics 산출물이 main에 존재

**근거:** Merge commit 51c8fffb1cf957234b1a7f55429102906bc6ddbd ("Merge W3 전역 시스템 웨이브 (feat/w3-global-systems)") is a verified ancestor of origin/main (`git merge-base --is-ancestor 51c8fffb origin/main` → true; also appears directly in `git log origin/main --oneline`). The claimed artifacts all exist in origin/main today: `lib/widgets/sori/chrome_row.dart` defines `class SoriChromeRow` (line 19); `lib/widgets/sori/speakable.dart` defines `class SoriSpeech` (29), `class SoriSpeakable` (313), `class SoriSpeechIndicator` (356), `class ContentSpeechController` (438); `lib/widgets/sori/content_feed.dart` defines `enum FeedPhysics { legacy, snap }` (line 16) and consumes it (`widget.physics == FeedPhysics.snap` etc.). SoriLayout and SoriGaps are not separate files but classes inside `lib/widgets/sori/tokens.dart` — `class SoriLayout` (tokens.dart:99, includes `chromeRowTouchHeight`, `heroFit`) and `class SoriGaps` (tokens.dart:151) — both added by the same 51c8fffb merge diff (tokens.dart +83 lines) and both actively referenced across main (e.g. grammar_screen.dart:576, hanok_header.dart:133, level_filter_bar.dart:53/168/197, speakable.dart:392-393). The merge diff itself (`git show --stat 51c8fffb`) shows 53 files changed / 5734 insertions including chrome_row.dart (+98), speakable.dart (+307), tokens.dart (+83), level_filter_bar.dart (+156), plus new guard tests (chrome_stack_guard_test.dart, spacing_literal_guard_test.dart, typography_guard_test.dart, sori_layout_hero_fit_test.dart, speakable_semantics_test.dart, etc.).

**비고:** Only mismatch vs. the suggested verification path is that SoriLayout/SoriGaps are classes inside tokens.dart rather than standalone layout.dart/gaps.dart files — a file-location variance, not a missing-work issue; the classes and their guard tests are real and in active use.

### H-05 — 반영

**주장:** W3.5 하드닝이 main에 병합됨 — merge 9b92973d; TTS 로컬캐시 catch 확대 + 전역 에러 훅(runZonedGuarded/FlutterError.onError/PlatformDispatcher.onError) main.dart 설치 + SoriPressable 키보드 활성화 + chrome_row 48dp

**근거:** origin/main ancestry: `git merge-base --is-ancestor 9b92973d origin/main` → IS ANCESTOR. Merge commit 9b92973dfd0ed4ac4b2f7177a450a367af98db98 ("Merge W3.5 하드닝 웨이브") has parents 51c8fffb (main) + 45b170aa (fix/w35-hardening), touching lib/main.dart, lib/services/tts_service.dart, lib/widgets/sori/{chrome_row,pressable,speakable}.dart plus 4 new guard tests, all present at origin/main.
(1) TTS local-cache catch widened: commit 795ea1d1 in lib/services/tts_service.dart adds a bare `catch (_) { … Storage 로 넘어간다 }` after the existing `on TimeoutException` around the local FS read (finding 1a), plus errorReporter/onResolutionFailed split (commit 45b170aa) so unavailable-banner only fires on resolution failure. Guard test: test/tts_premium_only_test.dart (exists on origin/main).
(2) Global error hooks in main.dart: `PrivacyConsentService.installErrorHandlers()` is called unconditionally as the very first line of `launchKoLernenApp()` in lib/main.dart:139 (commit e47f8e19, finding 7), moved out of `_initFirebase()` so it no longer depends on Firebase success. That method (lib/services/privacy_consent_service.dart:285-290) sets `FlutterError.onError = ...` (line 286) and `PlatformDispatcher.instance.onError = _controller.handlePlatformError` (line 289) — both confirmed via `git grep` on origin/main. Guard test test/main_error_hook_test.dart asserts both hooks change identity even when the Firebase/production startup path is skipped entirely. CAVEAT: `runZonedGuarded` does NOT appear anywhere in lib/ on origin/main (`git grep runZonedGuarded origin/main -- lib/` → no hits; it only appears in docs/HANDOFF-2026-08-27-waves.md describing the pre-fix gap, and once, unrelated, in test/tts_request_rate_test.dart). So only 2 of the 3 named hook types were actually wired; runZonedGuarded was never added.
(3) SoriPressable keyboard activation: commit 5ac08d20 (finding 8) changes the Enter/Space handler in lib/widgets/sori/pressable.dart so onLongPress-only widgets (which still receive Tab focus since canRequestFocus uses `enabled`) now activate via `_onLongPress()` instead of being ignored; commit 45b170aa follow-up removes the now-dead `else` branch. Guard test: test/sori_pressable_keyboard_test.dart.
(4) chrome_row 48dp: commit 2ae4f5a7 (finding 10) changes SoriChromeRow's outer SizedBox from `SoriLayout.chromeRowHeight` (44dp) to `SoriLayout.chromeRowTouchHeight` (48dp) and removes the OverflowBox hit-test-clipping trick in _ChromeSlot, wrapping SoriPressable directly in a 48dp SizedBox. Guard test: test/chrome_row_test.dart.

**비고:** Substantively true and merged, but the claim's enumeration overstates the error-hook fix: only FlutterError.onError and PlatformDispatcher.instance.onError are actually installed (via PrivacyConsentService.installErrorHandlers() called first-line in main.dart) — runZonedGuarded is absent from the codebase entirely, so it appears the claim lifted the "3종" phrasing from the stale handoff's description of the original gap rather than from what was actually shipped.

### H-06 — 반영

**주장:** 인계서 시점 main HEAD는 8faae14f였고 origin과 동기였다 (ci 리모트 상태는 이 컨테이너에서 검증 불가)

**근거:** git -C /home/user/ko_lernen_app_worktrees/handoff-verify merge-base --is-ancestor 8faae14f origin/main → true (8faae14f is an ancestor of origin/main; current origin/main HEAD is 0dc760fe, 288 commits ahead). git show -s 8faae14f → "chore(graphify): refresh graph after onboarding CI fixes", 2026-08-27 22:34:17. docs/HANDOFF-2026-08-27-waves.md lines 10/20/26 explicitly state main HEAD was 8faae14f and 'origin/main = 로컬 main과 완전히 동일(8faae14f)' at write time, with ci remote noted separately as 10 commits behind (온보딩/골든 커밋만, not wave work). This container has only the 'origin' remote configured (git remote -v shows only origin); no 'ci' remote is reachable here.

**비고:** The claim's first half (HEAD=8faae14f, synced with origin) is directly verifiable and true as of handoff time. The second half (ci remote status unverifiable) is also correctly self-flagged in the claim — this container has no ci remote at all, confirming that sub-claim as 검증불가-appropriate, not a defect in the claim itself.

### H-07 — 반영

**주장:** W4 T1: 7f259706 — LearnSessionQueue에 _servedIds/currentIsRepeat 게터 추가, servedPosition 수식 무변경

**근거:** Commit 7f2597061 (`git merge-base --is-ancestor 7f259706 origin/main` → IS ANCESTOR) — "feat(learn-queue): _servedIds + currentIsRepeat 게터 추가". Diff on lib/services/learn_session_queue.dart adds `final Set<String> _servedIds = {}` and `bool get currentIsRepeat => ...` (checks `_servedIds.contains(idOf(current))`), and adds `_servedIds.add(idOf(_queue.first))` calls inside markKnown/markUnknown/defer. The `servedPosition` getter (file line 68 in origin/main) is not part of the diff hunks at all — formula unchanged. Confirmed present in origin/main HEAD via `git show origin/main:lib/services/learn_session_queue.dart` (currentIsRepeat at lines 81-84, _servedIds at line 77, servedPosition at line 68). Companion test file test/learn_session_queue_test.dart also touched in same commit (+30 lines).

**비고:** Commit message itself documents intent ("진행 계약 불변" / progress contract unchanged), and the code confirms it — currentIsRepeat is purely additive/observational, no existing method signatures or the servedPosition formula were altered.

### H-08 — 반영

**주장:** W4 T2: 6e20f021 — 재출제 카운터 단일 칩 병기("+N Wdh.") + dispose 진행 영속화

**근거:** Commit 6e20f021 (ancestor of origin/main, verified via `git merge-base --is-ancestor 6e20f021 origin/main`) diff confirms both claimed pieces: (1) single-chip 병기 — in `lib/screens/vocab_pack_screen.dart` the existing `SoriChip` label for Learn progress is extended to `'${servedPosition}/${uniqueTotal}${_learnRepeatCount>0 ? t.vocabPackLearnRepeatSuffix(_learnRepeatCount) : ''}'` (no separate second chip added), backed by new arb key `vocabPackLearnRepeatSuffix` in app_de.arb ("· +{n} Wdh.") and app_en.arb ("· +{n} repeats"); (2) dispose 진행 영속화 — `dispose()` now calls `_persistLearnProgress()` before `_abandonTracker.dispose()`, which calls `PackProgressService.recordWordLearned(pack)` to flush learned-word count even on mid-session exit. Re-confirmed at origin/main HEAD via `git show origin/main:lib/screens/vocab_pack_screen.dart` — lines 184-186 (_learnRepeatCount field), 233 (_persistLearnProgress in dispose), 429 (_learnRepeatCount++ on repeat serve), 446 (_persistLearnProgress fn), 1047-1050 (chip label with suffix) all present unchanged. Guard test `test/vocab_pack_screen_repeat_counter_test.dart` exists at origin/main with header comment explicitly stating "별도 칩이 아니라 숫자에 병기" (single-chip, not separate chip), matching the claim.

**비고:** No contradiction or gating found; this is a small, self-contained, fully-landed change with its own regression test.

### H-09 — 반영

**주장:** W4 T3: 721505c0+270adfce — 결과화면 AppBar 뒤로가기 복구, CTA 무조건 pop() 단순화

**근거:** Commits 721505c0 and 270adfce are both ancestors of origin/main (`git merge-base --is-ancestor` confirmed). 721505c0 (lib/screens/vocab_pack_result_screen.dart diff) removed the `automaticallyImplyLeading: false` override on the SoriStudyFrame passed to VocabPackResultScreen's AppBar, restoring the default back-leading (SoriStudyFrame defaults `automaticallyImplyLeading = true`, lib/widgets/sori/study_frame.dart:24,38,74); it also replaced the "Zurück zum Grid" CTA's `popUntil((r) => r.settings.name == '/vocab' || r.isFirst)` with a courseContext-gated pop(). 270adfce then simplified further, removing the courseContext branch entirely so the CTA is unconditionally `onTap: () => Navigator.of(context).pop()`. Verified this exact state is live on origin/main: `git show origin/main:lib/screens/vocab_pack_result_screen.dart` has no `automaticallyImplyLeading` line and no `leading:` override anywhere in the file (so the AppBar shows the default back arrow), and the grid CTA at line 326 reads `onTap: () => Navigator.of(context).pop()`. Regression tests exist on origin/main at test/vocab_pack_result_phase1_test.dart (present per `git ls-tree origin/main`), including two guard tests explicitly targeting this fix: "\"Zurück zum Grid\" 는 코스 미션 진입에서도 pop 1회만 한다 (courseContext 유무 무관)" (lines 292-352) and "\"Zurück zum Grid\" 는 /path(학습 경로) 진입에서도 pop 1회만 한다" (lines 354+), both asserting the old popUntil('/vocab'||isFirst) logic would incorrectly land on Home while the new unconditional pop() correctly returns to the immediate caller route. (flutter/dart binaries unavailable in this container, so tests were verified by reading, not executed.)

**비고:** Commit 270adfce is a follow-up simplification beyond what 721505c0 alone did (it deletes the courseContext branch 721505c0 introduced) — the claim's two-SHA pairing correctly reflects this as a single evolving fix, not two independent changes.

### H-10 — 반영

**주장:** W4 오버플로 묶음: 02e1bf5c — 카운터·퀴즈 헤더 Flexible 래핑(ellipsis 아님) + 320/360dp 회귀 테스트

**근거:** Commit 02e1bf5ccd9d76b9bdd36a21a43f2cc8ade28014 (Thu Aug 27 2026) is an ancestor of origin/main (`git merge-base --is-ancestor 02e1bf5c origin/main` succeeds). Diff of lib/screens/vocab_pack_screen.dart wraps the hint Text in Flexible (no `overflow: TextOverflow.ellipsis` added) in two places: Learn counter row (~line 1061 on origin/main, SoriChip counter left unconstrained, only the hint Text made Flexible) and Quiz/Boss header row (~line 1184, same pattern). Confirmed on origin/main via `git show origin/main:lib/screens/vocab_pack_screen.dart` — grep for Flexible/ellipsis/overflow shows only the Flexible wrap, no ellipsis/overflow param in actual code (a comment even states "ellipsis 는 쓰지 않는다"). Regression tests exist on origin/main: test/vocab_pack_screen_overflow_guard_test.dart defines `_narrowSizes = [Size(320, 640), Size(360, 640)]` and runs both a Learn-counter-row test and a Quiz-header-row test at each size, asserting `tester.takeException()` isNull (RenderFlex overflow guard); test/vocab_pack_screen_repeat_counter_test.dart covers the "+k Wdh." counter-label growth that triggered the overflow. Both files verified present via `git show origin/main:<path>`.

**비고:** One inline comment inside vocab_pack_screen_overflow_guard_test.dart loosely says "Flexible+ellipsis" describing the fix, but the actual production code and test assertions confirm only Flexible wrapping was applied, no ellipsis/overflow param — matching the claim's "(ellipsis 아님)" precisely; this is a minor wording slip in a code comment, not a discrepancy in behavior.

### H-11 — 반영

**주장:** W4 T4: 55d6e815+dc95f2d0 — 표준팩 소급 복구(팩 목록 열람 재동기화), != → > 클램프, 5청크 동시성 제한

**근거:** Both commits are ancestors of origin/main (git merge-base --is-ancestor confirmed for both 55d6e815 and dc95f2d0). 55d6e815 "fix(vocab-packs): 팩 목록 열람 시 wordsLearned 소급 재동기화 (지시서 검수#21)" adds in lib/screens/vocab_packs_screen.dart _load(): after loadLevelView, loops packs comparing PackProgressService.wordsLearnedIn(entry.pack) vs entry.progress.wordsLearned and calls PackProgressService.recordWordLearned(entry.pack) on mismatch — this is the "팩 목록 열람 재동기화" (standard-pack retroactive recovery on list view). dc95f2d0 "fix(vocab-packs): 소급 재동기화 단조 클램프 + 쓰기 폭주 완화" changes the comparison from `!=` to `>` (monotonic clamp, code comment explicitly states "단조 증가 클램프 — ... `>`, 이전엔 `!=`") and introduces `const int _backfillChunkSize = 5;` plus a chunked `Future.wait` loop over `staleDelta` (5 items per chunk) calling `_backfillPackProgress`, matching the "5청크 동시성 제한" claim. Verified current origin/main content directly (git show origin/main:lib/screens/vocab_packs_screen.dart lines 114-128, 458, 464) still contains staleDelta, `> `comparison, `_backfillChunkSize`, and `_backfillPackProgress` — confirming the changes are present and not reverted in the final state, not merely in the historical commit diffs.

**비고:** Test file test/vocab_packs_screen_backfill_test.dart was also touched in both commits (74 then 69 lines changed) per git show --stat, consistent with guard-test coverage for this behavior, though full test content was not read in detail.

### H-12 — 반영

**주장:** W4 T5: dc1fc1f0 — 커스텀팩 quiz/matching/typing에 addVokSeen+learnedWordCount, 책장 "n von m"

**근거:** Commit dc1fc1f0 ("feat(custom-pack): learnedWordCount + addVokSeen 누락 보완(quiz/matching/typing) + 책장 진행 표시") is an ancestor of origin/main (git merge-base --is-ancestor confirms). Verified actual content at origin/main: Storage.addVokSeen() is called in lib/screens/custom_pack_quiz_screen.dart:154, lib/screens/custom_pack_matching_screen.dart:178, and lib/screens/custom_pack_typing_screen.dart:147. CustomPackService.learnedWordCount() is defined at lib/services/custom_pack_service.dart:250 and consumed in lib/screens/bookshelf_screen.dart:505 to build the identity/semantics label via t.bookshelfPackLearnedMeta(learnedCount, pack.totalWords). lib/l10n/app_de.arb:207 defines bookshelfPackLearnedMeta as "{learned} von {total} gelernt" (matches "n von m" claim); app_en.arb:207 has the English equivalent "{learned} of {total} learned". Guard tests present at origin/main: test/custom_pack_service_test.dart has test 'learnedWordCount 는 vokSeenIds 교집합으로 유도된다' (line 23) asserting learnedWordCount behavior, and test/bookshelf_custom_pack_uiux_test.dart references the new "learned" line on the custom-pack tile (comment at line 426, tied to Task 5).

**비고:** All three sub-claims (addVokSeen in quiz/matching/typing, learnedWordCount, bookshelf "n von m" display) independently verified against origin/main content, not just the handoff doc text.

### H-13 — 반영

**주장:** W4 T6: a62c6556 — course_mission_navigation.dart에 activeScenarioCheckpointContext 헬퍼, course_mastery_service.dart는 계약 유지(자가유도 없음)

**근거:** Commit a62c655686de664f156f1f5c678bfe279a94d139 is an ancestor of origin/main (verified via `git merge-base --is-ancestor`). Its diff touches only lib/services/course_mission_navigation.dart (+50) and test/course_mission_navigation_test.dart (+137); course_mastery_service.dart has a fully empty diff in this commit. The new function `activeScenarioCheckpointContext(String scenarioId, {catalog, snapshot})` exists at lib/services/course_mission_navigation.dart:221-267 on origin/main, doc-commented "course_mastery_service.dart 의 courseEligible 판정 로직은 여기서 절대 복제하지 않는다... 실제 courseEligible 부여는 여전히 그 서비스 내부에서만 일어난다". It returns `CoursePracticeContext.fromLink(match)` (lib/models/course_practice_context.dart:16-22), whose factory only sets courseUnitId/contentKind/initialContentId/contentLinkId — it carries no courseEligible field at all. On origin/main, `courseEligible` is assigned only inside course_mastery_service.dart, e.g. line 800 `courseEligible: activeCheckpoint != null` inside `recordScenarioCheckpoint`, computed from the service's own `activeCheckpoint` lookup — confirming no self-derivation was introduced by the new helper. Guard tests added in the same commit (test/course_mission_navigation_test.dart, group 'activeScenarioCheckpointContext': '활성 유닛의 체크포인트 시나리오면 컨텍스트를 유도한다', '활성 유닛이 없으면 null', '시나리오가 활성 유닛의 체크포인트가 아니면 null') exist on origin/main.

**비고:** The commit message's cited line range test/course_mastery_test.dart:398-425 has since shifted (later commits added more tests to that file), but the underlying guard test content covering the courseEligible contract is present in that file; this does not affect the claim about course_mission_navigation.dart or the mastery-service contract.

### H-14 — 반영

**주장:** W4 T7: 4e9dea5f — setScenarioStars 첫 기록 0성 허용, 재시도 단조

**근거:** Commit 4e9dea5fb7f7c46855fdcf49d87b27f35389e420 ("fix(storage): setScenarioStars 0성 최초 기록 허용 — 완료 여부는 stars 값과 무관 (지시서 4.15)") is an ancestor of origin/main (git merge-base --is-ancestor confirms). Its logic is present verbatim in origin/main HEAD at lib/services/storage_service.dart:3761-3772: `setScenarioStars` computes `alreadyRecorded = current.containsKey(id)` and writes when `!alreadyRecorded || (current[id] ?? 0) < stars` — i.e. first record is always written (even 0 stars), but subsequent writes remain monotonic (only overwrite when the new value is strictly greater). Guard tests on origin/main: test/storage_scenario_cache_test.dart:75-80 "setScenarioStars 는 0성도 최초 1회는 기록한다" and :82-88 "setScenarioStars 는 여전히 단조 증가만 허용한다" (2→ignore 1→then 3 accepted). Also test/scenario_onboarding_completion_test.dart updated (git show 4e9dea5f) to assert `Storage.scenarioStars['airport_arrival']` equals 0 (not null) after a dont-know completion.

**비고:** Claim text matches implementation and tests exactly; no discrepancy found.

### H-15 — 반영

**주장:** W4 T8: aa5914bf+a07b1d5f — scenario_player courseContext 자동 유도 + activeScenarioCheckpointContext try/catch fail-soft + scenario_can_do_result_flow_test 첫 테스트 runAsync 프리웜

**근거:** Both aa5914bf and a07b1d5f confirmed ancestors of origin/main (git merge-base --is-ancestor). (1) aa5914bf diff on lib/screens/scenario_player_screen.dart: in _load(), `final courseContext = widget.courseContext ?? await activeScenarioCheckpointContext(widget.scenarioId);` — new field `_effectiveCourseContext` stores the derived context and is used in place of `widget.courseContext` at the completion-reporting call site, wiring auto-derivation for list/recommendation/repeat entry (widget.courseContext null cases). (2) a07b1d5f diff on lib/services/course_mission_navigation.dart: activeScenarioCheckpointContext's body wrapped in try/catch, catch block does `debugPrint(...); return null;`, with doc comment explaining corrupted/legacy snapshot FormatException must not block scenario playback ("순수 배경 강화... 실패하면 그냥 courseContext 없이... 진행한다"). (3) a07b1d5f diff on test/scenario_can_do_result_flow_test.dart: `await tester.runAsync(() async { await CurriculumCatalog.load(); });` inserted into the 'system back delegates to the explicit scenario exit' testWidgets at line 109 — confirmed via grep this is the FIRST testWidgets in the file (line 109), preceding 'saves once...' at line 156, matching claim's '첫 테스트'; inline comment explains the orphaned cold compute() race this prevents.

**비고:** Commit messages themselves independently corroborate the mechanism (courseEligible/course_mastery_service.dart explicitly untouched, contract frozen per course_mastery_test.dart:400-440), consistent with fail-soft-only scope.

### H-16 — 반영

**주장:** W4 T9: scenarios_list_screen.dart onClosed 즉시 갱신(0/2→1/2)이 main에 존재

**근거:** Commit 229cf4b27d6d1fe19d670aafcd3e2ea8fd7d6179 (2026-08-28, "fix(scenarios-list): 플레이어에서 복귀 시 목록 setState 갱신 배선 (지시서 4.15)") is the latest commit on lib/screens/scenarios_list_screen.dart and is HEAD's ancestor on origin/main. Verified in worktree (== origin/main for this path): onScenarioClosed wiring at exactly the suggested lines — :245 (_LessonPathHeader), :262 (_LevelSection), :374 (_OpenScenarioCard), :424 `onClosed: (_) => onScenarioClosed()` inside OpenContainer. onScenarioClosed resolves to ScenariosListScreen._refreshScenarioProgress (line 157-162: `if (!mounted) return; setState(() {});`). build() re-reads `Storage.scenarioStars` fresh at line 212 on every rebuild, and _LevelProgressChip's label (lines 659-666, via t.scenariosPathLevelProgress) computes completed-count as `scenarios.where((sc) => (stars[sc.id] ?? 0) > 0).length` out of total — the "0/2→1/2" per-level counter. So closing the OpenContainer scenario player triggers an immediate setState that recomputes this counter from fresh storage, with no separate navigation/reload required.

**비고:** This is a direct-symbol match (not one of the W5 indirection traps), so grep-based verification is reliable here; confirmed by reading full call chain and _refreshScenarioProgress/_LevelProgressChip implementations, not just presence of the identifier.

### H-17 — 반영

**주장:** W4 T10: 일별 학습 원장 — storage_service.dart에 kl_study_log_v1_ 프리픽스(일자별 키), test/study_log_test.dart 존재, srsReview 핫패스는 오늘 키만

**근거:** git show origin/main:lib/services/storage_service.dart line 2545: `static const String _studyLogPrefix = 'kl_study_log_v1_';` (line 2548 `_studyLogKey`). test/study_log_test.dart exists on origin/main (592 lines) with test 'srsReview writes a judged id to today's dedicated ledger key' asserting `prefs.getStringList('kl_study_log_v1_$today')`. Hot path: `srsReview` -> `_srsReviewTransaction` (line ~2874) computes `judgmentDate = _today(now)` and calls `_appendStudyLogEntry(id, dateIso: judgmentDate, generation: generation)` which only reads/writes `_studyLogKey(judgmentDate)` (line ~2606) — no iteration over other dates in the review path; `studyLogDates()`/full-ledger scans are separate read-only helpers used elsewhere (e.g. calendar), not in srsReview.

**비고:** HEAD at commit 6b649f80 on origin/main for this container's worktree; all three sub-claims (prefix location, test file, today-only hot path) directly verified from file content, not from the stale handoff doc.

### H-18 — 반영

**주장:** W4 T11: review_deck_service.dart에 deckForIds 존재

**근거:** git show origin/main:lib/services/review_deck_service.dart 라인 149-159에 `static List<Vocab> deckForIds(List<Vocab> all, Iterable<String> ids)` 존재 (worktree 로컬 파일과 origin/main 내용 동일 확인). git log -- lib/services/review_deck_service.dart 상 commit 170094f0 "feat(review): ReviewDeckService.deckForIds — 학습 원장 id → Vocab 해석 (달력 진입용)"에서 도입됨. `Storage.studyLogIdsFor`로 얻은 id를 순서 보존하며 Vocab으로 해석하는 헬퍼로, 문서 주석에도 명시됨.

**비고:** 클레임 위치(:150 부근)와 정확히 일치 — 실제로 150번째 줄에서 시작.

### H-19 — 반영

**주장:** W4 T12: review_hub_screen.dart 존재 + main.dart에 /review/hub 라우트, /review는 여전히 플레이어

**근거:** origin/main HEAD (0dc760fe, merge PR #245). File exists: `lib/screens/review_hub_screen.dart` (confirmed via `git ls-tree -r origin/main --name-only`, also `test/review_hub_screen_test.dart` present). `lib/main.dart:54` imports `screens/review_hub_screen.dart`. Two separate route cases in main.dart's switch: line 936 `case '/review':` → `ReviewSessionScreen(feedbackContentId: 'today_review')` (the player, unchanged), and line 943 `case '/review/hub':` → `ReviewHubScreen()` (new hub route). Both routes coexist; `/review` was not repurposed.

**비고:** Straightforward file+route check, no indirection traps applicable to this claim.

### H-20 — 반영

**주장:** W4 T13: buildGrammarChoiceRound에 allowedTargetIds 파라미터, main.dart 라우트 인자 파싱

**근거:** origin/main HEAD 0dc760fe8abae266affc9b6dcc6048137dee9f23. `git diff origin/main -- lib/main.dart lib/services/grammar_choice_quiz.dart` is empty, confirming the worktree content for these two files equals origin/main verbatim. lib/services/grammar_choice_quiz.dart:110-138 — buildGrammarChoiceRound(...) has `Set<String>? allowedTargetIds` param (line 116) used to filter targets to that set while leaving the distractor pool (`all`) unrestricted (lines 128-138: `allowedTargetIds == null || allowedTargetIds.contains(grammar.id)`). lib/main.dart:769-800 — the '/grammar_choice_quiz' route case parses `settings.arguments` as Map, reads args['allowedTargetIds'] as an Iterable and filters to Strings into `Set<String>? allowedTargetIds` (lines 773-791), then passes it to `GrammarChoiceQuizScreen(allowedTargetIds: allowedTargetIds, ...)` (line 796). Introducing commits: 5de478f3 "feat(grammar-quiz): buildGrammarChoiceRound allowedTargetIds — 타깃만 슬라이스 제한, 오답 풀은 레벨 전체 (Grammatik 마스터플랜)" and 77f102f7 "feat(grammar-quiz): allowedTargetIds/planDayLabel 배선 + 피드백 카드에 활용(note) 추가". Guard test: test/grammar_choice_quiz_route_test.dart, testWidgets 'actual grammar-choice route normalizes plan maps safely' — pushes '/grammar_choice_quiz' with arguments containing 'allowedTargetIds': ['grammar_a1_one', 42, 'grammar_a1_two'] and asserts screen.allowedTargetIds == {'grammar_a1_one','grammar_a1_two'} (non-String entries dropped).

**비고:** Working tree had zero uncommitted changes to either file relative to origin/main, so this is directly origin/main state, not a docs/superpowers overlay artifact.

### H-21 — 반영

**주장:** W4 T14: lib/models/grammar_study_plan.dart + lib/services/grammar_plan_service.dart 존재

**근거:** origin/main commit 26edb3b1 "feat(grammar-plan): GrammarStudyPlan 모델 + GrammarPlanService 순수 슬라이스 로직 (Grammatik 마스터플랜, 검수#24)". `git show origin/main:lib/models/grammar_study_plan.dart` returns 57-line immutable model (level/itemsPerDay/servedIdsByDate, fromJson/toJson/copyWith, completedDays getter). `git show origin/main:lib/services/grammar_plan_service.dart` returns 79-line abstract-final service (curatedRowsForLevel, todaysSlice, totalDays, recordServedDay, encodePlans/decodePlans) that documents Storage.grammarPlanRawJson as its IO boundary. Corresponding tests exist and are tracked in origin/main: test/grammar_study_plan_test.dart (54 lines) and test/grammar_plan_service_test.dart (168 lines), confirmed via `git ls-tree -r origin/main --name-only`.

**비고:** Both files plus their tests are present, non-stub, and substantively implement the described "Grammatik 마스터플랜" pure-slice logic; single commit covers model+service+tests together.

### H-22 — 반영

**주장:** W4 T15: kl_gram_plan_v1 저장 — Storage.grammarPlanRawJson 접근자가 cloud_sync.dart와 learning_data_export_service.dart에서 소비됨

**근거:** On origin/main (0dc760fe8abae266affc9b6dcc6048137dee9f23) via worktree, verified by accessor-name grep (not raw key grep): lib/services/storage_service.dart:1381 defines `static String get grammarPlanRawJson => _s('kl_gram_plan_v1');`. Consumed at lib/services/cloud_sync.dart:125 (`final grammarPlanJson = _rawJsonObject(Storage.grammarPlanRawJson);`) and lib/services/learning_data_export_service.dart:138 (`final raw = Storage.grammarPlanRawJson.trim();`). Also consumed in lib/screens/grammar_screen.dart:259 and lib/services/grammar_plan_service.dart docs. Guard test test/backup_new_storage_keys_guard_test.dart:30 asserts cloud_sync source literally contains 'Storage.grammarPlanRawJson'. Round-trip coverage in test/cloud_sync_test.dart:847,891,916,1011,1076 and test/grammar_plan_storage_test.dart:12-38.

**비고:** Claim exactly matches current main; no gating or partial implementation found.

### H-23 — 반영

**주장:** W4 T16: grammar_screen.dart 플랜 모드(GrammarStudyPlan/_applyPlanSlice/planDayLabel, 첫 진입 시트)

**근거:** lib/screens/grammar_screen.dart on origin/main (HEAD 60910881, file identical in worktree — `git diff origin/main -- lib/screens/grammar_screen.dart` empty) contains: `GrammarStudyPlan` model usage (lines 128, 140, 619 etc.), `_applyPlanSlice(GrammarStudyPlan plan)` method (line 658, called at 639), and `planDayLabel` (line 926, via `t.grammarPlanDayHeader`). First-entry sheet: `showSoriSheet` with `Key('grammar-plan-onboarding-sheet')` inside `_showPlanOnboardingSheet` (line 550-656), triggered on first load at line 290-291 (`if (!mounted || _isCoursePractice || activePlan != null) return; unawaited(_showPlanOnboardingSheet(...))`) — i.e. shown only when no active plan exists yet. Test coverage: test/grammar_plan_screen_test.dart, test/grammar_study_plan_test.dart, test/grammar_plan_service_test.dart all present in worktree/origin-main.

**비고:** All three named symbols and the first-entry onboarding sheet are present, wired, and gated correctly (plan-mode sheet fires only when no GrammarStudyPlan exists for the current level).

### H-24 — 반영

**주장:** W4 T17: grammar_choice_quiz_screen.dart 존재 + /grammar_choice_quiz 라우트 등록(T16이 호출하는 라우트)

**근거:** origin/main (commit 7940abc6, worktree lib/ identical to origin/main — git diff origin/main -- . ':!docs/superpowers' shows zero lib/ changes): lib/screens/grammar_choice_quiz_screen.dart exists, 560 lines, full StatefulWidget implementation (GrammarChoiceQuizScreen with initialLevel/grammarLoader/markGrammarHard/randomSeed/allowedTargetIds/planDayLabel params), not a stub. lib/main.dart:87 `import 'screens/grammar_choice_quiz_screen.dart';` and lib/main.dart:769 `case '/grammar_choice_quiz':` register the route, handling args (level, planDayLabel, allowedTargetIds) before returning the screen — confirmed identical in git show origin/main:lib/main.dart. Caller wiring confirmed: lib/screens/grammar_screen.dart (T16) also references 'grammar_choice_quiz', matching the claim that T16 calls this route.

**비고:** All three verification points (file existence, import line 87, case line 769) match exactly as suggested in the verification method.

### H-25 — 반영

**주장:** W4 T18: 백업 화이트리스트 — cloud_sync.dart payload/restore에 study_log_json·gram_plan_json, learning_data_export_service.dart 등록, test/backup_new_storage_keys_guard_test.dart 존재

**근거:** origin/main (tip 0dc760fe, work landed in 9695a6ba "feat(backup): kl_study_log_v1_*·kl_gram_plan_v1 백업/복원/내보내기 등록 + 신규 학습 키 가드 테스트 (검수#3)"). lib/services/cloud_sync.dart: `_restorableAccountFields` allowlist (lines 36-49) includes 'study_log_json' and 'gram_plan_json'; backup payload assembly at lines 123 (`payload['study_log_json'] = jsonEncode(studyLog)` built from Storage.studyLogDates()/studyLogIdsFor) and 127 (`payload['gram_plan_json'] = grammarPlanJson` from Storage.grammarPlanRawJson); restore path at lines 571 (`data['study_log_json']` → per-date atomic restore via Storage.restoreStudyLogDateForRestore) and 619 (`data['gram_plan_json']` → Storage.setGrammarPlanRawJsonForRestore). lib/services/learning_data_export_service.dart lines 96 and 100 register 'studyLog' and 'grammarPlan' sections in the export JSON. test/backup_new_storage_keys_guard_test.dart (42 lines, exists) asserts exactly this: cloud_sync.dart contains 'study_log_json', 'gram_plan_json', Storage.studyLogDates, Storage.grammarPlanRawJson; and learning_data_export_service.dart contains studyLog and grammarPlan.

**비고:** flutter binary unavailable in this container so the guard test could not be executed; verification is by direct source inspection, which line-for-line satisfies the test's own assertions, so functional confidence is high.

### H-26 — 반영

**주장:** W4 queued 2건 처리 — ① T2 카운터 +2 누적 테스트 보강 ② bookshelf_screen.dart 같은 build 내 learnedWordCount 2회 호출 호이스트(w4-integration 플랜이 명시)

**근거:** origin/main HEAD (0dc760fe) 기준 직접 확인. ① `+2` 누적 테스트: test/vocab_pack_screen_repeat_counter_test.dart:113 `testWidgets('같은 세션에서 재출제가 두 번 겹치면 카운터가 "+2" 까지 누적된다 (Task 2 리뷰 Minor)', ...)`, 단언은 :146 `expect(find.textContaining('· +2'), findsOneWidget)` — 이 테스트는 커밋 02e1bf5c(2026-08-27, "fix(vocab-pack): 좁은 화면 카운터·퀴즈 헤더 오버플로 방지 + 회귀 테스트")에서 이미 도입되어 병합 시 그대로 유지됨(w4-integration 플랜 Task3 Step1의 "기존 test가 있으면 재사용" 조건을 충족). ② 호이스트: lib/screens/bookshelf_screen.dart:505 `final learnedCount = CustomPackService.learnedWordCount(pack);` 이후 508행·531행에서 learnedCount를 재사용 — 파일 전체에서 CustomPackService.learnedWordCount 호출은 이 1건뿐(grep 확인). git blame 505/508행 → 병합 커밋 5743c3270("merge(w4): integrate progress review wave", 2026-08-29 12:42). 병합 전 W4 브랜치 원본(b6b3150b)에서는 동일 build 안에서 학습 카운트를 351행·374행 두 번 인라인 호출했음(git show b6b3150b:lib/screens/bookshelf_screen.dart 확인) — 병합 시 정확히 계획된 방식(w4-integration 플랜 Task3 Step3 "한 번 계산해 재사용")대로 중복 호출이 제거됨. 5743c3270은 `git merge-base --is-ancestor 5743c3270 origin/main` = true로 origin/main에 포함 확인됨.

**비고:** flutter/dart 바이너리가 이 컨테이너에 없어 실제 테스트 실행(green)까지는 재현하지 못했고 정적 코드·git 이력 대조로만 검증함; 로직상 실행 결과를 뒤집을 근거는 없음.

### H-27 — 반영

**주장:** W5 계약1: 레벨 필터 이관 완료 — test/level_filter_guard_test.dart allowlist 공란, 7개 플레이 표면은 sheet 방식(showSoriLevelFilterSheet+SoriChromeRow), vocab_packs만 inline bar, 파일별 legacy selector 금지 맵

**근거:** test/level_filter_guard_test.dart (byte-identical to origin/main, `git diff origin/main -- test/level_filter_guard_test.dart` empty; last touched by commits 0026d112 "refactor(filters): unify remaining level selectors" and 7a092953 "fix(w5): close common-contract integration regressions") defines `sheetScreens` = {chosung_quiz_screen.dart, cloze_game_screen.dart, grammar_screen.dart, legacy_vocab_screen.dart, satz_arcade_screen.dart, silben_kreuz_screen.dart, speed_match_screen.dart} each asserted to contain both `SoriChromeRow(` and `showSoriLevelFilterSheet(`, `inlineScreens` = {vocab_packs_screen.dart} asserted to contain `SoriLevelFilterBar(`, and a `forbidden` map of legacy selector strings (PopupMenuButton<String>, `_levelBar`/`_levelChip` widgets, `_dropdown(...filterLevel`, `_levelPicker`, chosung ValueKey) per file that must NOT appear — i.e. the exemption/allowlist is empty, no screen is grandfathered into legacy behavior. Verified directly via grep on the actual worktree files (= origin/main content): all 7 sheet screens contain both `showSoriLevelFilterSheet(` and `SoriChromeRow(` at concrete line numbers (e.g. chosung_quiz_screen.dart:280/615, cloze_game_screen.dart:192/263, grammar_screen.dart:1012/1028, legacy_vocab_screen.dart:423/436, satz_arcade_screen.dart:154/173, silben_kreuz_screen.dart:194/207, speed_match_screen.dart:256/272); vocab_packs_screen.dart:344 contains `SoriLevelFilterBar(`. Grepping all 6 forbidden legacy patterns across their respective files returned zero matches anywhere in the tree.

**비고:** Sampled the two suggested surfaces (chosung_quiz, cloze) plus checked all remaining sheet/inline surfaces and every forbidden-pattern entry for completeness; no discrepancy found. No flutter/dart runtime available in this container to execute the test itself, but static verification of every assertion the test makes is fully consistent with a passing/green state.

### H-28 — 반영

**주장:** W5 계약2: 오디오 롤아웃 완료 — test/content_audio_policy_guard_test.dart가 9표면(vocab_pack,legacy_vocab,custom_pack_play,hangul,grammar,smalltalk,quest_flow,cloze,scenario_player) 고정, 플립 표면은 SoriSpeech.* 정적 API

**근거:** origin/main @ 0dc760fe8abae266affc9b6dcc6048137dee9f2. test/content_audio_policy_guard_test.dart lines 12-22 (targetScreens) list exactly the 9 claimed surfaces: vocab_pack_screen.dart, legacy_vocab_screen.dart, custom_pack_play_screen.dart, hangul_screen.dart, grammar_screen.dart, smalltalk_screen.dart, quest_engines/quest_flow.dart, cloze_game_screen.dart, scenario_player_screen.dart. Guard test '학습 화면은 저수준 TtsService를 직접 참조하지 않는다' (line ~75) asserts none of these 9 files contain 'TtsService'; verified directly via git show + grep -c TtsService on all 9 files at origin/main → 0 matches each (all files exist). Sample-verified 2 surfaces use SoriSpeech.* static API as claimed: vocab_pack_screen.dart:692,1246,1389,1490,1494 call SoriSpeech.speak/speakSlow; hangul_screen.dart:123,143,219,978 call SoriSpeech.prefetch/prefetchAll/speak. grammar_screen.dart:1782 also confirms SoriSpeech.speak. Separate guard test (~line 91) additionally confirms quest_flow.dart, cloze_game_screen.dart, scenario_player_screen.dart each use SoriSpeakable( wrapper for non-flip tap playback, consistent with the W5 indirect-implementation pattern noted in the trap list.

**비고:** Test asserts absence of TtsService, not presence of SoriSpeech, on all 9 screens as a group; direct SoriSpeech.* usage was spot-checked on 3 of the 9 (vocab_pack, hangul, grammar) rather than exhaustively on all 9, per the suggested 2-sample method.

### H-29 — 반영

**주장:** W5 계약3: /review onPrevious 배선 — review_session_screen.dart :661 부근, SRS 재출제 안전은 lib/services/review_session_queue.dart 추출로 해결, test/review_session_queue_test.dart 존재

**근거:** origin/main commit bc6308a3 "feat(review): model previous navigation from served history" (confirmed via `git log --format=%H origin/main -- lib/services/review_session_queue.dart` → bc6308a34bc5e5b5e3a274394e6dde4bea903326). lib/screens/review_session_screen.dart:661-663 wires `onPrevious: browsingHistory || queue.canGoPrevious ? _showPrevious : null` into SoriContentFeed (matches claim's "661 부근"); _showPrevious (line 311) calls queue.previous() and setState. SRS re-issue safety is extracted into lib/services/review_session_queue.dart (150 lines): ReviewSessionQueue<T> tracks _requeuedOriginalIds (each original requeued at most once on wrong judgment, review_session_queue.dart:100-103) and _firstJudgmentIds/currentNeedsEvidence (SRS/course evidence written only on first judgment, not on requeue or history browsing). test/review_session_queue_test.dart (137 lines) exists with 5 tests covering exactly this: 'each original is requeued at most once and evidence is first-only', 'history browsing cannot judge or requeue an earlier card', dedup of originals, and defer-without-evidence.

**비고:** canGoPrevious is defined as `_historyCursor > 0`, i.e. Previous is disabled on the very first served card and enabled once at least one card has been served — consistent with "previous navigation from served history" as the commit message states.

### H-30 — 의도적 보류

**주장:** W5 계약4: FeedPhysics.snap 기본 전환은 의도적 보류 — content_feed.dart 기본값 legacy 유지, lib/data/feed_physics_candidates.dart 7후보 전부 approvedForSnap:false, 플랜에 "Jin 실기기 승인 전 금지" 명문

**근거:** origin/main@0dc760fe. (1) lib/widgets/sori/content_feed.dart:57 `this.physics = FeedPhysics.legacy` — 기본값 legacy 유지 (git show origin/main:lib/widgets/sori/content_feed.dart로 직접 확인). (2) lib/data/feed_physics_candidates.dart — 정확히 7개 후보(custom_pack_play_screen, grammar_screen, hangul_screen, legacy_vocab_screen, review_session_screen, smalltalk_screen, vocab_pack_screen) 전부 `final bool approvedForSnap = false;`로 하드코딩되어 런타임에서 변경 불가 (git show origin/main:lib/data/feed_physics_candidates.dart로 확인, "runtime consumer by design" 아니라는 dartdoc도 포함). 가드 테스트 test/feed_physics_candidates_test.dart가 7개 ID·approvedForSnap==false·불변성을 검증(main에도 존재, git show로 확인). (3) docs/superpowers/plans/2026-08-29-w5-common-contracts.md:20 (origin/main에 이미 존재, 2026-09-01 신규 문서 아님) — "`FeedPhysics.snap` 기본값·legacy 삭제는 Jin 실기기 승인 전 금지한다." 명문 확인. 동일 게이트가 docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md:22,82,161,300과 docs/superpowers/plans/2026-08-27-w3-global-systems.md:2291에도 중복 명시됨.

**비고:** claim의 세 요소(기본값 legacy, 7후보 전부 approvedForSnap:false, 플랜 명문 금지 문구)가 origin/main 실제 파일 내용과 정확히 일치. 함정 없이 코드·테스트·문서 삼자가 정합.

### H-31 — 반영

**주장:** W5 계약5: 홈 이스케이프 해치 — study_frame.dart :54-62가 SoriHomeAction 주입, test/study_home_escape_guard_test.dart 26화면 고정 duplicateAllowlist 공란

**근거:** lib/widgets/sori/study_frame.dart (origin/main, commit 316828af "feat(navigation): guarantee one home escape on study screens") lines 54-62 exactly as claimed: `final homeAction = SoriHomeAction(escape: homeEscape);` at line 54, then remainingActions/hasCustomLeading/effectiveLeading/effectiveActions logic through line 64, injecting the single home action into either `leading` or `actions` of SoriAppBar — no per-screen SoriHomeAction construction needed. test/study_home_escape_guard_test.dart (same commit) defines `expectedStudyFrameScreens` with exactly 26 entries, asserted via `expect(expectedStudyFrameScreens, hasLength(26))` in the first test, and `const duplicateAllowlist = <String>{};` (empty set, line ~35) used in the second test 'all StudyFrame screens rely on the frame-owned home action', which also asserts `expect(duplicateAllowlist, isEmpty)`.

**비고:** Confirmed via git show origin/main:<path> for both files; no worktree-only content involved (this claim predates the 2026-09-01 docs additions).

### H-32 — 반영

**주장:** W5 계약6: hero_placement_guard 4→0 — knownViolators 공란, HanokHeader가 chosung_quiz/hangul/legacy_vocab/kkeunmari/scenario_player에서 제거됨

**근거:** origin/main test/hero_placement_guard_test.dart (identical to worktree, verified via `git show origin/main:... | diff`): line 11 `const knownViolators = <String>{};` (empty), line 50 `expect(knownViolators, isEmpty);`. chooserScreens allowlist (lines 13-21) contains only bookshelf/character_selection/learning_path/quests/scenarios_list/settings/vocab_packs_screen.dart — none of chosung_quiz, hangul, legacy_vocab, kkeunmari, scenario_player. Confirmed via `grep -n "HanokHeader" lib/screens/{chosung_quiz_screen,hangul_screen,legacy_vocab_screen,kkeunmari_screen,scenario_player_screen}.dart` → zero matches in all 5 files (exit code 1). Commit history: c042eed2 "feat(sori): ... hero_placement_guard (UIUX 바이블 §15)" introduced the guard with violators, then 866481a3 "refactor(chrome): close hero and stacked-control allowlists" (2026-08-29) removed `HanokHeader(` from exactly these 5 files (`git show 866481a3 --stat` and per-file diff confirms `-HanokHeader(` / `-const HanokHeader(` removed in chosung_quiz_screen.dart, hangul_screen.dart, kkeunmari_screen.dart, legacy_vocab_screen.dart, scenario_player_screen.dart) and shrank knownViolators to empty in test/hero_placement_guard_test.dart.

**비고:** flutter binary unavailable in this container so the guard test could not be executed directly, but static inspection of the test logic (Directory('lib/screens') scan for 'HanokHeader(' string, checked against chooserScreens ∪ knownViolators) combined with the grep confirmation that none of the 5 named files contain the string makes the test's pass outcome unambiguous from source alone.

### H-33 — 반영

**주장:** chipWrapAllowlist 5→0 — chrome_stack_guard_test.dart 공란, study_library_screen은 migrated 셋(SoriChromeRow 1개 소유)

**근거:** origin/main HEAD 0dc760fe (worktree /home/user/ko_lernen_app_worktrees/handoff-verify). test/chrome_stack_guard_test.dart:13 `const chipWrapAllowlist = <String, int>{};` (empty — comment at :12 states "§19 W5 이행으로 모든 기존 다중 칩 행의 유예가 종료됐다", i.e. allowlist went 5→0). test/chrome_stack_guard_test.dart:93-119 test '§19 migrated surfaces own one public chrome row, not a private rail' — the `migrated` set at :94-99 includes 'lib/screens/study_library_screen.dart' alongside chosung_quiz_screen.dart, hangul_screen.dart, legacy_vocab_screen.dart, and asserts each has exactly one SoriChromeRow( match and no private chip rail. Verified lib/screens/study_library_screen.dart contains exactly one `SoriChromeRow(` occurrence (line 478: `return SoriChromeRow(`), matching the guard's expectation. git log on the test file shows commit 866481a3 "refactor(chrome): close hero and stacked-control allowlists" (ancestor of 74b8ef4f, 6d5c16ba) which is the commit that emptied the allowlist, all present in origin/main history.

**비고:** flutter binary unavailable in this container so the guard test could not be executed to confirm a green run; verification is by static/structural inspection of the test file and target source plus git history, which is fully consistent with the claim.

### H-34 — 반영

**주장:** W3.5 이월 5건 전부 처리(PR #210) — ① vocab_pack _finish()→vocab_pack_finish_coordinator.dart(재진입 가드,AppError 재시도) ② review_session ReviewLoadState 4상태 분리 ③ culture_notes 양 호출부 격리+culture_note_loader_lifecycle_test ④ grammar 시트 isSaving/mounted 가드 ⑤ 850ms→취소 가능 _advanceTimer

**근거:** PR #210 merged into main (commit e9ab5ce4 "Merge pull request #210 from Sujin-Arin-DataWorld/feat/w35-hardening-20260829"). Verified all 5 items in the worktree (== origin/main):
① lib/services/vocab_pack_finish_coordinator.dart:150-208 — `VocabPackFinishCoordinator.finish()` uses `_inFlight` future + `_completed` step set (enum `_VocabPackFinishStep{boss,course,xp,stamp,pending}`) as reentrancy guard, resuming only incomplete steps on retry. Consumed in lib/screens/vocab_pack_screen.dart:224-248 (`_finishCoordinator`), with AppError retry wired at vocab_pack_screen.dart:1017-1022 (`AppError(message: _finishError!, onRetry: _retryFinish, ...)`).
② lib/screens/review_session_screen.dart:51 — `enum ReviewLoadState { loading, ready, empty, error }`, used via switch at lines 423-430 to render AppLoading/AppError/_buildEmpty/_buildCard.
③ Both culture-note call sites wrap the loader in try/catch and swallow failure silently (UI-non-blocking): legacy_vocab_screen.dart:127-130 and review_session_screen.dart:159-162 (`try { await (widget.cultureNotesLoader ?? CultureNotesService.load)(); } catch (_) { ... }`). test/culture_note_loader_lifecycle_test.dart exists and parametrically tests both screens (`_screenCases`) against a throwing loader (lines 27-37).
④ lib/screens/grammar_screen.dart:687-725 — checkpoint-answer bottom sheet: local `isSaving` flag guards re-submission (`if (isComplete || isSaving || !sheetContext.mounted) return;`), and both `sheetContext.mounted`/`mounted` are re-checked after the async `checkpointRecorder` await before calling `setLocal`/`setState`.
⑤ lib/screens/vocab_pack_screen.dart:228 (`Timer? _advanceTimer;`), :757-771 — `_scheduleAdvance()` creates the 850ms timer via an injectable `createTimer` factory, and `_cancelAdvanceTimer()` (`_advanceTimer?.cancel(); _advanceTimer = null;`) is called both at the start of `_scheduleAdvance` and at the start of `_advanceQuiz`, making the delayed advance cancelable instead of the previous bare `Future.delayed`.

**비고:** All 5 carryover items from PR #210 (feat/w35-hardening-20260829) are present in main exactly as claimed; no gaps found for H-34.

### H-35 — 반영

**주장:** 마스터플랜 W5 잔여 스코프 반영 — 퀘스트 피드백(quest_flow), Diktat 재설계, Anlaut 크롬 압축, Silben 셀 UX(silben_puzzle 모델), Aussprache 재구축(pronunciation studio+trace_canvas), 시나리오 인트로 아트 해시 크롭, /my_words 허브(bookshelf/word_search/hard_words 흡수하되 기존 라우트 유지=검수 HIGH#4)

**근거:** origin/main = 0dc760fe (worktree HEAD 7940abc6 is +1 docs-only commit ahead, confirmed via git rev-parse). PR #217 "feat/w5b-learning-surfaces" merged at 98c513ff and PR #218 "feat/w5c-hubs-scenario-intro" merged at 90833e1c are both in origin/main's ancestry (git log --oneline --all shows both merge commits). Concrete files verified present at origin/main via `git show origin/main:<path>`: lib/widgets/trace_canvas.dart (TraceCanvasController/TraceCanvasSnapshot — Aussprache trace canvas), lib/models/silben_puzzle.dart (SilbenWord model, Silben-Kreuz), lib/screens/my_words_screen.dart (MyWordsScreen with MyWordsTab enum unifying search/shelf/difficult). lib/main.dart (origin/main) lines ~1038-1049 show routes '/my_words', '/wordbook/search', '/bookshelf', '/hard_words' ALL still registered and ALL dispatching to MyWordsScreen(initialTab: myWordsTabForRoute(settings.name)) — confirming the hub absorbed bookshelf/word_search/hard_words while preserving the existing route names verbatim, exactly matching 검수 HIGH#4's requirement. Also confirmed present: lib/screens/quest_engines/quest_flow.dart (quest feedback), lib/screens/quest_engines/diktat_quest.dart + test/diktat_quest_test.dart (Diktat redesign). Related commits in history: c790ddca "feat(silben): synchronize grid lanes clues and semantics", 3ecaf0cf "feat(pronunciation): expose actionable five-state diagnosis", c4b4e393 "refactor(scenarios): make intro art static and deterministic" (scenario intro art hash-crop), e1b04ed0 "perf(scenarios): prefetch first dialog audio during intro".

**비고:** Did not locate a distinct "Anlaut chrome compression" file (no anlaut-named file under lib/), but Anlaut-Quiz UI is folded into the quest_engines/SoriChromeRow pattern per known trap #2 in the task (indirect implementation) — consistent with commit 6dee4f13's renaming work; not independently confirmed by symbol grep, so treat only that sub-claim as weakly evidenced within an otherwise fully confirmed W5 scope.

### H-36 — 반영

**주장:** W6 오디오 게인 스윕 완료 — tool/measure_audio_gain.py, tool/audio_gain_report.json(46파일/위반 0), test/audio_gain_contract_test.dart, ADR-002 §9-2가 잔여 목록에서 제거되고 "2026-08-30 자동화 완료" 기재

**근거:** commit e4a739eb820a22049dba731945f90be3bd40ff32 "feat(audio): audit runtime loudness with strict report coverage" (2026-08-30 10:37:33 +0200) on origin/main adds tool/measure_audio_gain.py, tool/audio_gain_report.json, test/audio_gain_contract_test.dart, tool/test_measure_audio_gain.py. `git show origin/main:tool/audio_gain_report.json` → assetCount=46, decoderErrorCount=0, targetIssueCount=0 (schemaVersion 1). `git show origin/main:docs/ADR-002-audio-policy.md` line 275: "**2026-08-30 자동화 완료:** ... 현재 기준은 **46파일 / 오디오 스트림 24개 / 디코더 오류 0개 / 목표 위반 0개**다." (§4-1 section, after the §9 step table at line 503-522 which lists step #2 as `tool/measure_audio_gain.py` + report + contract test). The ADR's top-of-doc live "잔여" list (lines 6-10) enumerates only §9-6, §7-1, §5-2, §6-5, §3-6 — no §9-2/gain-sweep item remains listed as pending. test/audio_gain_contract_test.dart (verified content) asserts report path-set equality with disk assets under assets/sfx and assets/video, issues empty, decoderErrorCount 0, targetIssueCount 0, and per-row schema (sha256, codec, channels, sampleRate, duration).

**비고:** The claim's "§9-2가 잔여 목록에서 제거" is confirmed by omission (§9-2 is absent from the current 잔여 list) rather than by an explicit strikeout/removal diff visible in a single line — this is the correct reading of the doc's structure, not an assumption.

### H-37 — 반영

**주장:** W6 cloze 8그룹 완료 + 게이트 준수 — lib/data/cloze_topic_groups.dart(8그룹), arb DE/EN 동시, level_filter_guard가 cloze를 sheetScreens에 포함(레벨바 선완료 증거: W5-A 머지가 cloze PR보다 선행)

**근거:** (1) 8그룹: origin/main:lib/data/cloze_topic_groups.dart의 ClozeTopicGroupId enum이 정확히 8개(everydayHome, peopleRelationships, travelServices, workEducation, languageMedia, societyInstitutions, technologyScience, healthNatureLeisure), `_ordered`/`partition()`/`countsForLevel()`도 이 8개 기준으로 동작 (커밋 47ea8e89 "feat(cloze): classify canonical topics into eight exact groups", 432d9b28 "feat(cloze): filter play queue by eight localized domains"). (2) arb DE/EN 동시: 커밋 b4c82d14 "feat(l10n): name eight cloze learning domains"가 lib/l10n/app_de.arb(+68줄, clozeGroupAll 등 8개 그룹×label+description)와 lib/l10n/app_en.arb(+17줄, 동일 키셋 영문)를 한 커밋에서 함께 수정, test/l10n_parity_test.dart(+93줄)도 같이 추가됨. (3) 게이트 준수: test/level_filter_guard_test.dart의 sheetScreens 집합(7행)에 'lib/screens/cloze_game_screen.dart' 포함, forbidden 맵에서도 cloze_game_screen.dart의 레거시 `Widget _levelBar(`/`Widget _levelChip(` 금지 확인 — SoriChromeRow+showSoriLevelFilterSheet 계약 강제. 머지 시각 비교: W5-A 머지 c2199ad4 = 2026-08-30 02:59:57 +0200 (PR #211), cloze PR 머지 f604a42d = 2026-08-30 13:42:38 +0200 (PR #222) — W5-A가 약 10.7시간 먼저 머지되어 레벨바 공용계약이 cloze보다 선행함을 확인.

**비고:** claim의 세 요소(8그룹 데이터, arb 동시 갱신, 게이트 sheetScreens 포함+선행 순서) 모두 origin/main에서 직접 확인됨; 추가 조작 없음.

### H-38 — 반영

**주장:** W6 시나리오 아트 — 공장(매니페스트·프롬프트·감사)은 완성됐으나 전용 아트 0/126 생성(전부 not_generated, 카테고리 포스터 13종 폴백), 코퍼스 413→126 축소로 파일럿 3장 폐기

**근거:** worktree HEAD (descendant of commit 890306d3, confirmed via `git merge-base --is-ancestor 890306d3 HEAD`). Factory tooling present and complete: tool/build_scene_art_manifest.py, tool/audit_scene_assets.py (+ their test_*.py), lib/services/scene_asset_resolver.dart, test/scene_asset_resolver_test.dart. docs/data/scene_art_generation_manifest.json: scenarioCount=126, all 126 entries[*].generation.status == "not_generated" (verified via python parse — 0/126 dedicated art, confirms claim exactly). docs/data/scene_asset_inventory.json: scenarioCount=126, dedicatedCount=0, fallbackCount=126, missingCount=0. categoryCounts across 15 backdrop keys: 13 have count>0 (office 38, home 44, cafe 9, station 9, market 4, convenience 1, restaurant 5, pharmacy 1, directions 5, hotel 1, taxi 2, airport 1, theme_park 6) and 2 are 0 (bank, salon) — confirms "카테고리 포스터 13종 폴백". docs/data/scene_asset_report.md corroborates: 전용 포스터 0개, 카테고리 폴백 126개. Corpus history via `git log` on docs/data/scene_asset_inventory.json across all commits: df7a53e3/9a93fb68 scenarioCount=413 → 504b6d99..0995e39d scenarioCount=419 (theme-park pack added) → ca00acad "promote canonical 120 scenario corpus" scenarioCount=120 → 890306d3 "restore theme park supplement" scenarioCount=126 (current). Pilot-3 discard: commit 9a93fb68 "feat(assets): validate first scenario art review batch" generated 3 pilot posters (a1_cancel_walk.png, a1_class_pencil.png, a1_office_print.png) into assets_unused/pending_review/scenes/; commit ca00acad moved them to assets_unused/pending_review/scenes/legacy_419/ with README.md stating "These three unapproved posters belong to scenario IDs removed by the canonical_120_v1 runtime promotion... not candidates for runtime promotion" (still present at that path in current worktree).

**비고:** Minor imprecision only: the claim's "413→126" states bookend totals correctly (initial inventory was exactly 413, current is 126) but the actual path passed through 419 (theme-park pack added, matching the legacy_419 archive-folder name) and dipped to 120 before the final +6 theme-park restore to 126 — a simplification, not a contradiction.

### H-39 — 반영

**주장:** tool/audit_scene_assets.py 존재 + 형제 테스트

**근거:** origin/main (HEAD 0dc760fe) contains tool/audit_scene_assets.py (1338 lines, `git show origin/main:tool/audit_scene_assets.py`) and its sibling test tool/test_audit_scene_assets.py (561 lines, unittest-based, imports audit_scene_assets + style_lock and exercises the canonical scene inventory contract). Introduced in commit e959e25d ("feat(tool): 시나리오 퀘스트 중복·씬 에셋 감사 스크립트 + 1차 리포트"), most recently touched by ca00acad2ff0d1470dc241bfdfb8d15685a7d1a0 ("feat(content): promote canonical 120 scenario corpus", 2026-09-01), with intermediate commits df7a53e3, 9a93fb68, 504b6d99, ddd06153 also modifying the file.

**비고:** Both files verified present with real, non-trivial content directly via git show against origin/main; no reliance on the stale handoff doc.

### H-40 — 반영

**주장:** §7 계약 4건 유지 — ① servedPosition 동결(고정 테스트) ② recordScenarioCheckpoint 자가유도 금지(course_mastery_test 고정) ③ /review 라우트+고정 테스트 유지(허브는 /review/hub 분리) ④ 신규 저장 키 백업 화이트리스트 가드 테스트

**근거:** worktree HEAD(7940abc6) == origin/main(0dc760fe) + docs/superpowers 2건만 추가(diff --stat 확인, 코드 변경 없음). §7 계약 4건 모두 실코드에서 확인:
① servedPosition 동결 — test/learn_session_queue_test.dart:62 `test('servedPosition holds during re-asks (denominator never changes)')`; test/review_session_queue_test.dart(다수 assert)도 동일 계약 검증. lib/services/learn_session_queue.dart:68 getter 및 doc-comment "진행 표시 계약: 분모는 uniqueTotal(고정), 분자는 servedPosition" 존재.
② recordScenarioCheckpoint 자가유도 금지 — test/course_mastery_test.dart:421-462 `test('a current scenario without exact mission provenance stays browse history')`(courseContext 없이 호출 시 courseEligible=false 확인, courseContext 있을 때만 true) 및 test/course_mastery_test.dart:465-493 `test('tagged scenario answers require the same exact mission provenance')`. 핸드오프가 지목한 course_mastery_test.dart:416-425 위치와 동일 테스트(줄번호만 소폭 이동).
③ /review 라우트+고정 테스트, 허브 분리 — lib/main.dart:936 `case '/review':` → ReviewSessionScreen(feedbackContentId:'today_review') 유지; lib/main.dart:943 `case '/review/hub':` → ReviewHubScreen 별도 라우트. test/review_hub_screen_test.dart 존재(허브 전용), grep 결과 test/ 내 `'/review'`(허브 제외) 16개 파일·23개 호출 지점에서 여전히 라우트 참조/검증 중.
④ 신규 저장 키 백업 화이트리스트 가드 테스트 — test/backup_new_storage_keys_guard_test.dart 전체 파일 확인: study_log_json/gram_plan_json이 cloud_sync.dart에 있는지, Storage.studyLogDates/Storage.grammarPlanRawJson을 cloud_sync.dart가 읽는지, learning_data_export_service.dart가 studyLog/grammarPlan을 포함하는지 소스 파일을 직접 읽어 assert. 실제 lib/services/cloud_sync.dart:49-50(allowlist 배열)·119-127·571·619, lib/services/learning_data_export_service.dart:96-100·138에 해당 키/접근자 실존 확인.

**비고:** Flutter 툴체인이 이 컨테이너에 없어(`which flutter` 실패) 4개 테스트를 실제로 실행해 green을 확인하지는 못했으나, 테스트 파일과 대상 소스 파일의 정적 내용이 서로 정확히 대응해 통과할 것으로 판단됨. /review 관련 "고정 테스트 15곳"은 정확한 카운트 대신 근사치(16파일/23호출)로만 확인함 — 계약 위반은 아니며 테스트가 늘어난 것으로 보임.

### H-41 — 반영

**주장:** 살아있는 계약 유지 — audio_policy_guard(볼륨 리터럴), game_surface_contract(7게임 SoriStudyFrame), arb_l10n_guard(DE/EN 동시)

**근거:** origin/main HEAD 7940abc6 (2026-09-01). All 3 guard test files exist on origin/main and their invariants independently hold when checked directly against source (not just "tests exist"):
(1) test/audio_policy_guard_test.dart — scans lib/*.dart for setVolume(<num>)/volume:<num> literals outside services/audio_policy.dart. Manual re-check: 0 unexempted offenders, exactly 3 `// audio-policy: exempt` sites (lib/widgets/sori/tiger_video.dart:195,467; lib/widgets/sori/character_clip.dart:406) — matches the test's `lessThanOrEqualTo(3)` cap and its stated reason text verbatim. (Also present: test/content_audio_policy_guard_test.dart, an extra guard not named in the claim.)
(2) test/game_surface_contract_test.dart — asserts each of 7 screens (chosung_quiz_screen.dart, silben_kreuz_screen.dart, kkeunmari_screen.dart, cloze_game_screen.dart, daily_challenge_screen.dart, speed_match_screen.dart, satz_arcade_screen.dart) contains `SoriStudyFrame(` and no raw `Scaffold(`. Manual grep on origin/main confirms all 7 files under lib/screens/ contain SoriStudyFrame( (counts 3-5 each) and zero raw Scaffold( matches.
(3) test/arb_l10n_guard_test.dart — includes a 'DE/EN 키는 완전 대칭이다' test comparing lib/l10n/app_de.arb vs app_en.arb key sets (plus plural-form and em/en-dash ratchets over ARB and assets/data). Manual parse of both ARB files on origin/main: 2865 keys each side, DE-only and EN-only diffs both empty set — exact symmetry.
git log --oneline -1 for these 4 files: 890306d3 "feat(content): restore theme park supplement with verified TTS".

**비고:** flutter/dart toolchain not installed in this container, so `flutter test` itself could not be executed; verification instead re-derived each guard's pass/fail condition directly from source (ARB parsing, regex scans) and confirmed all three currently pass, which is stronger than merely confirming file existence.

### H-42 — 반영

**주장:** 래칫 하향 전용 유지 — §7 표의 값들(spacing 181, fontSize 115/15파일, ellipsis 0, fontFamily 0, raw AppBar 0, InkWell ≤19, Sori 위젯 =133, 라우트 =72, 표면 클래스 =108)이 현재 main에서 같거나 정당하게 갱신됨(인벤토리 =는 신규 화면 랜딩 시 상향 가능 — uiux_bible_closeout_inventory와 LOCK 문서 §표 동기 여부로 판정)

**근거:** 디버트(하향 전용) 6종 — 현재 worktree(main과 동일) 상수 및 git 히스토리 단일 도입 확인:
- test/spacing_literal_guard_test.dart:51 `const ceiling = 181;` (git log -p 전체 히스토리에 이 상수 도입 커밋 1건만 존재, 이후 변경 없음). 독립 재현 스캔 결과 offenders=176 ≤ 181.
- test/typography_guard_test.dart:243 `const ceiling = 115;` (fontSize-in-TextStyle, lib/screens/) — 도입 커밋 1건만 존재. 독립 재현 스캔: 114곳/15파일 ≤ 115(파일 수도 클레임 "115/15파일"과 일치).
- test/typography_guard_test.dart:69-75 `fontFamily: '` 리터럴 ceiling 0 — 독립 스캔 결과 0.
- test/typography_guard_test.dart:134-148 `lib/screens/` raw `AppBar(` ceiling 0 — 독립 스캔 결과 0.
- test/typography_guard_test.dart:151-165 `TextOverflow.ellipsis` (screens+app_bar.dart+adaptive_navigation.dart) ceiling 0 — 독립 스캔 결과 0.
- test/chrome_stack_guard_test.dart:121-143 raw `InkWell(` ceiling 19 (git log -p 전체 히스토리에 `lessThanOrEqualTo(19)` 도입 1건만 존재) — 독립 재현 스캔 결과 정확히 19(상한과 동일, 초과 아님).

인벤토리(=, 상향 허용) 3종 — 2026-08-27 handoff 스냅샷(docs/HANDOFF-2026-08-27-waves.md:295-297: Sori 위젯=133, 라우트=72, 표면 클래스=108) 대비 현재 main은 75/135/112로 상향되어 있음. test/uiux_bible_closeout_inventory_test.dart(routes hasLength(75) L39/55, surface classes hasLength(112) L110-111, Sori widgets hasLength(135) L147-149)와 독립 Python 재구현으로 세 값 모두 실제 파일시스템(lib/main.dart 스위치, lib/screens+lib/features/guide 클래스, lib/widgets/sori 파일)과 docs/UIUX_BIBLE_APPLICATION_EXECUTION_LOCK.md §6/§7/§8 표가 완전히 동기(문서화-실제 집합 차집합 0)됨을 확인 — "신규 화면 랜딩 시 상향 가능 + §표 동기" 조건 충족.

**비고:** docs/UIUX_BIBLE_APPLICATION_EXECUTION_LOCK.md §5 "Measured baseline" 표의 `lib/widgets/sori Dart files: 128`(line 200)은 §8/closeout 테스트가 강제하는 실제값 135와 어긋나는 구식 산문 수치이지만, 이 §5 서술은 어떤 가드 테스트로도 강제되지 않아(§6/§7/§8만 강제됨) H-42가 대상으로 하는 "래칫 값" 자체에는 영향 없음 — 별도 문서 정리 항목으로만 유의.

### H-43 — 반영

**주장:** by-design 침묵 실패 보존 — receipt fail-open 2곳, TTS best-effort 지점들이 "고쳐지지" 않고 유지됨

**근거:** worktree files are identical to origin/main (0dc760fe) for both — `git diff origin/main -- lib/services/sori_stage_reward_receipt_service.dart lib/services/tts_service.dart` returns empty.

Receipt fail-open (2곳), lib/services/sori_stage_reward_receipt_service.dart:
- L14-18 doc comment explicitly names this "fail-open boundary keeps a diagnostic/reward surface from becoming an entitlement gate."
- Fail-open #1 at L47-50: `catch (_) { await openActivity(); return null; }` when local/network before-capture throws.
- Fail-open #2 at L74-76: `catch (_) { return null; }` when the post-activity snapshot compare throws.
- Guard test test/sori_stage_reward_receipt_service_test.dart:142-157, named literally `'capture never blocks learning when local field capture fails (검수#7 fail-open)'`, asserts `opened==true` and `receipt==null` — proves the design is exercised, not just commented.
- git log for the file: 9f55341d, 01d9202a (검수#7), d2c5f946, 06de77df — all pre-existing, nothing since alters the two catches.

TTS best-effort points, lib/services/tts_service.dart (unchanged vs origin/main):
- L371-380 `stop()`: `catch (_) { // Public stop is best effort and must not leak platform errors. }`
- L586 doc comment on `prefetch()`: "실패는 전부 삼킨다... (`DancheongBurst.preload()` 와 같은 best-effort 철학)" backed by L608-616 `catch (_) { _prefetchAttempted.remove(key); }`.
- L977-985 `clearCache()`: `catch (_) { // best effort }` (contrasted deliberately with the strict `clearCacheStrict` variant at L988).
- L1034-1047 `_ensureSpeechAudioContext()`: `catch (_) { // best-effort — 다음 발화에서 다시 시도한다. }`
- git log for the file: 4582c486, 45b170aa, 795ea1d1, 746b9f33 — most recent commits harden error *reporting* (lastError/unavailable banner routing) without removing the best-effort silent catches themselves.

**비고:** 두 지점 모두 주석·doc-comment로 "왜 조용히 실패해도 되는지"를 명시적으로 정당화하는 by-design 패턴이며, 최근 커밋들(9f55341d, 45b170aa, 795ea1d1)은 이 실패들의 진단성(lastError/unavailable 배너 라우팅)을 개선했을 뿐 fail-open/best-effort 자체를 제거하지 않았다 — 클레임이 말하는 "고쳐지지 않고 유지됨"과 정확히 일치.

### H-44 — 반영

**주장:** §8 SDD 원장 — W2/W3/W4 원장 전문은 인계서에 보존됐으나 W3.5 loose 3파일(w35-execution-report.md 등)은 main에 커밋되지 않았고 W3.5/W5/W6 신규 원장도 main에 없음(소실 우려 재현)

**근거:** origin/main HEAD 0dc760fe. (1) docs/HANDOFF-2026-08-27-waves.md §8 "SDD 원장 보존" (헤더는 `git show origin/main:docs/HANDOFF-2026-08-27-waves.md | grep -n '^## \|^### '`로 확인)이 W2 progress.md 전문(330행, 43줄 언급), W3 progress.md 전문(378행, 67줄), W4 progress.md 전문(450행, 47줄)을 실제로 인용·보존하고 있음을 확인 — 클레임의 "W2/W3/W4 원장 전문은 인계서에 보존됐으나" 부분 일치. (2) 같은 문서 128행과 328행에서 W3.5 loose 3파일(`w35-execution-report.md` 18,081B / `w35-fix-review.diff` 10,960B / `w35-review.diff` 34,682B)이 원래 `C:\dev\hangulsori\ko_lernen_app_w35\.superpowers\sdd\` (Jin 로컬 워크트리, 이 컨테이너에는 없음)에만 존재했고 "이번 수집 작업은 이 3개 파일의 내용을 읽지 않았다"고 명시 — 이후 main에 커밋된 적이 없음을 `git ls-tree -r origin/main -- .superpowers`로 확인(해당 파일명이 트리에 전혀 없음, `git grep -n "w35-fix-review\|w35-review.diff" origin/main`도 위 두 언급 줄 외에는 아무 결과 없음). (3) `git ls-tree -r origin/main -- .superpowers`로 `.superpowers/sdd/` 전체를 나열한 결과 워크스페이스는 `2026-07-29-account-transition-and-deletion/`, `2026-07-29-release-hardening/`, `2026-07-31-content-feedback-implementation/` 세 개뿐이며 W3.5/W4/W5/W6에 해당하는 신규 SDD 원장(progress.md 등) 디렉터리는 하나도 없음 — 클레임의 "W3.5 loose 3파일은 main에 커밋되지 않았고 W3.5/W5/W6 신규 원장도 main에 없음" 부분과 정확히 일치. (4) 이번 검증 세션이 새로 작성 중인 docs/superpowers/plans/2026-09-01-handoff-verification-and-release.md의 Task 8 "SDD 원장 요약 반영"이 바로 이 공백을 메우려는 계획으로, main 자체에는 아직 해당 조치가 없음을 재확인.

**비고:** 클레임 자체가 "main 소실 우려가 여전히 재현된다"는 부정적 사실(gap)을 정확히 기술한 것이므로, 그 기술 내용이 실제 main 상태와 일치한다는 의미에서 verdict를 반영으로 표기함(즉 claim이 주장하는 미보존 상태가 실제로 확인됨). H-44는 SDD 원장 문서가 최종 반영되었는지를 묻는 것이 아니라 "인계서의 보존 상태에 대한 진술"이 맞는지를 검증하는 항목이며, 그 진술은 사실과 부합한다.

### H-45 — 불일치

**주장:** §9-1: partner_rewrite_diff.md+batches는 tracked, diff2.md는 여전히 untracked(이 컨테이너에 부재), 97건 적용 여부는 Jin 대기 유지

**근거:** origin/main (HEAD 0dc760fe) ls-tree confirms docs/data/partner_rewrite_diff.md + docs/data/partner_rewrite_batches/{flagged,rewrite-1..4}.md are tracked (claim part 1 TRUE). No docs/data/partner_rewrite_diff2.md exists anywhere in git history (`git rev-list --all | git ls-tree` scan: zero hits) and it is absent from this worktree's filesystem — consistent with the claim's "untracked, absent in this container" (claim part 2 TRUE, though note: an untracked file can never travel via git checkout regardless of whether it truly exists on Jin's machine — unverifiable either way). BUT claim part 3 ("97건 적용 여부는 Jin 대기 유지", i.e. all 97 still fully pending) is contradicted by main itself: commit 2faef696 "fix(content): Jin 확정 13건 적용 — 파트너 토픽 문장 7·표제어 현대화 6" (merged via 10571b95, both already in main history) edited partner_rewrite_diff.md to mark 13 of the 97 items ✅ "Jin 확정 적용 (2026-08-26)" (items #1 cloze_a1_0169, #11 cloze_b1_0138, #12 cloze_b1_0140, #20 cloze_b2_0173, #25 cloze_b2_0180, #26 cloze_b2_0184, #27 cloze_b2_0186, #28 cloze_b2_0194, #29 cloze_b2_0198, #30 cloze_b2_0202, #31 cloze_b2_0213, #33 cloze_b2_0216, #65 cloze_a1_0180), and applied the corresponding rewrites into assets/data/cloze.json, satz_sentences.json, korean_vocab.csv, can_do_content_authorities.json. Verified live: `git show origin/main:assets/data/cloze.json` for id cloze_a1_0169 shows sentenceKo "이건 ＿＿＿ 떼고 먹어요." / answer "잎을" — exactly the "최종 적용" text recorded in the diff, still present at HEAD, i.e. durably applied, not reverted.

**비고:** 13/97 items were already Jin-confirmed and applied (dated 2026-08-26, before the HANDOFF doc's own 2026-08-27 date), leaving only 84/97 genuinely pending — the claim's "97건 적용 여부는 Jin 대기 유지" overstates the pending scope by presenting the full 97 as undecided. Parts 1 and 2 of the claim (tracked status of diff.md/batches; diff2.md untracked/absent) are accurate.

### H-46 — 반영

**주장:** §9-7/8: 지시서 파일(docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md) 여전히 미추적, new_인보딩/ 미추적 — 단 completion-design 스펙이 지시서를 권위 #5로 인용 중(유실 위험 지속)

**근거:** git -C .../handoff-verify ls-tree -r origin/main --name-only 에서 "docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md"와 "new_인보딩/" 둘 다 0건(현재 main HEAD 0dc760fe, 2026-09-01 17:43 +0200). git log --all --full-history -- <두 경로> 도 전 브랜치 통틀어 0 커밋 — 두 경로 모두 git에 커밋된 적이 전무하며, 현재 워크트리 디스크에도 파일/디렉터리 자체가 존재하지 않음(find -iname 매치 0건, git status에 untracked로도 안 뜸 — Jin 로컬 전용 파일이라 fresh clone엔 애초에 없음). completion-design 스펙 docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md(origin/main에 정상 추적됨, git ls-tree 확인)의 "## 2. 근거와 권위 순서" 목록에서 실제로 5번 항목이 `docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md`의 원 요구사항"으로, git show 기준 실제 라인은 32(제안된 :36과 약간 오프셋이나 동일 인용문 단일 매치, grep -n "지시서" 결과 32줄 1건뿐). HANDOFF-2026-08-27-waves.md §9 7/8(517-518줄)이 이 claim의 출처 문구이나, 위 검증은 그 문서 텍스트가 아니라 origin/main의 실제 ls-tree/log/spec 내용으로 독립 확인함.

**비고:** 지시서 파일·new_인보딩/ 모두 현재 컨테이너(클론)에는 애초에 존재하지 않아 "Jin 로컬에 지금도 untracked 상태로 남아있는지" 자체는 검증 범위 밖(파일이 없으면 git이 추적 여부를 판단할 대상도 없음); 다만 "main에 커밋된 적 없음 + 스펙이 계속 이 미추적 문서를 권위 #5로 참조 중이라 유실 위험이 산다"는 claim의 핵심 취지는 origin/main 현재 상태로 그대로 확인됨.

### H-47 — 의도적 보류

**주장:** §9-4: tiger_choose 그림자 24.1%는 수리되지 않고 tool/clip_matte_report.json에서 per-clip 예산 0.25(기본 0.06)로 그랜드파더 통과, magpie_celebrate(0.113/0.12)·magpie_flight(0.172/0.18) 동일 — 1920×1080 규격 건은 커밋 없음

**근거:** tool/clip_matte_report.json (HEAD, byte-identical to commit ca27367d "chore(assets): 신규 무배경 클립 매트 리포트 재생성", 2026-08-27 00:05 +0200): tiger_choose.mp4 → floor_grey=0.241, floor_grey_budget=0.25; magpie_celebrate.mp4 → floor_grey=0.113, budget=0.12; magpie_flight.mp4 → floor_grey=0.172, budget=0.18; top-level default_floor_grey_budget=0.06 — all four numbers match the claim exactly. tool/check_clip_matte.py FLOOR_GREY_BUDGET dict carries the same per-clip values (tiger_choose.mp4: 0.25, magpie_celebrate.mp4: 0.12, magpie_flight.mp4: 0.18) with a 2026-08-25-dated comment explicitly framing them as "기록이지 승인이 아니다" (a record, not approval) and stating automated separation of shadow-vs-feather was tried and rejected (see tool/whiten_clip_matte.py) — real fix requires asset re-render. Commit f6949325 (Codex, 2026-08-26 23:54, msg "그림자 없는 동영상으로 내가 작업한거임.절대 회귀하지말도록.") replaced tiger_choose.mp4 + 4 magpie clips claiming shadow removal, and is an ancestor of ca27367d — yet the report regenerated after that replacement still shows tiger_choose at 24.1%, i.e. the shadow persisted post-"fix" and only clears the gate via the grandfathered per-clip budget, not an actual repair. For the 1920×1080 item: `git log --oneline --all -i --grep="1920\|960x960\|규격"` returns no matching commit (only an unrelated listening-art handoff doc), and `grep -rn "1920"` across lib/,test/,tool/ finds only lib/widgets/sori/share_slip.dart's unrelated `storySize = Size(1080,1920)` (Instagram-story export size) — no code or commit addresses the 5-clip aspect-ratio distortion risk. docs/HANDOFF-2026-08-27-waves.md lines 75/229/345/375/511 track both items consistently as an open, non-merge-blocking "Jin 게이트" through the file's latest entries. docs/superpowers/specs/2026-09-01-handoff-verification-and-release-design.md:25 (this verification pass's own new doc) already logs the same finding as a discovered 불일치.

**비고:** Numbers and no-commit finding both check out exactly as claimed; classified 의도적 보류 rather than 미반영 because the budget relaxation is a deliberately documented, git-tracked gate (rationale + non-regression intent spelled out in check_clip_matte.py) explicitly tracked as a pending pre-release Jin gate in the handoff, not a silent omission.

### H-48 — 반영

**주장:** §9-9: w3 워크트리 잔여(test/vocab_pack_narrow_viewport_header_test.dart 146줄)는 main에 랜딩되지 않음 — 유사 커버리지(95eeabc4/009588db/32502073)가 대체했는지 판정

**근거:** 1) 파일 부재 확인: `git show origin/main:test/vocab_pack_narrow_viewport_header_test.dart` → "fatal: path ... does not exist in 'origin/main'". `git log --all --diff-filter=A -- "*narrow_viewport*"` 및 전체 커밋의 트리 검색 결과 이 경로는 저장소 전체 히스토리(origin/main 포함 모든 브랜치)에 단 한 번도 존재한 적 없음 — w3 워크트리 로컬 산출물로만 남았던 파일.
2) 세 커밋 모두 origin/main의 조상(`git merge-base --is-ancestor <sha> origin/main` → 전부 YES): 95eeabc4 "fix(vocab): prevent compact progress overflow" (lib/screens/vocab_packs_screen.dart 수정 + test/vocab_packs_level_progress_responsive_test.dart 72줄 신설), 009588db "test(vocab): assert selected responsive level" (동 파일에 +13줄, 선택된 레벨 칩 검증 추가), 32502073 "test(goldens): capture compact vocab progress fix" (screen_vocab_packs_compact.png 골든 갱신).
3) 대체 파일 origin/main:test/vocab_packs_level_progress_responsive_test.dart (현재 85줄) 실제 내용 확인: viewports {compact 360×800, medium 800×1280, expanded 1280×800} × levels {a1, c2} 전 조합에서 VocabPacksScreen을 pump하고 PackCard 렌더 및 SoriLevelFilterBar 내 선택된 SoriChip 라벨이 레벨과 일치하는지, `tester.takeException()`이 null인지(오버플로우 없음) 검증 — 원래 narrow_viewport_header 테스트가 노리던 "좁은 뷰포트에서 vocab pack 헤더가 깨지지 않는다"는 목적과 동일한 회귀 방지 커버리지.

**비고:** 파일명·경로는 다르지만 검증 대상(좁은/다양한 뷰포트에서 vocab_packs 헤더·진행률 표시 오버플로우 방지)과 골든 이미지 갱신까지 세 커밋이 함께 제공하므로 "유사 커버리지가 대체했다"는 판정은 사실과 일치함.

### H-49 — 불일치

**주장:** 릴리스: versionCode 28(내부)·29(비공개) 업로드 실재 — 릴리스 커밋 54dae1f0/1e3d8bc6은 pubspec bump이고 실제 Play versionCode는 커밋 카운트(188/200)

**근거:** 확인 사실:
(1) 54dae1f0 (PR #241 "release: versionCode 28 — Play 내부테스트")·1e3d8bc6 (PR #242 "release: versionCode 29 — Play 비공개테스트")은 `git show <sha> -- pubspec.yaml` 기준 정말 pubspec.yaml `version:` 필드만 바꾸는 커밋(54dae1f0은 부수적으로 content_id_contract_test.dart 1줄도 포함). 클레임의 이 부분은 참.
(2) android/app/build.gradle.kts:58-70 `autoVersionCode`가 `ProcessBuilder("git","rev-list","--count","HEAD")`로 실제 Play versionCode를 결정하며 pubspec의 `+N`은 Android 빌드에 전혀 쓰이지 않음(주석 55-57에 명시) — "실제 Play versionCode는 커밋 카운트" 부분도 메커니즘 자체는 참.
(3) 그러나 클레임이 제시한 구체 수치 "188/200"은 실측과 불일치. `git -C handoff-verify rev-list --count 54dae1f0` = **2174**, `git rev-list --count 1e3d8bc6` = **2186**. 실제 Play 업로드 빌드로 GitHub Actions에서 확인되는 값도 이와 정합: CI 실행 33470000263(push on 54dae1f0, job "Signed AAB to Play Internal Testing"→"Upload to Google Play Internal Testing" step conclusion=success)의 아티팩트 이름은 "android-internal-1003-54dae1f0…"(run_number 기반이라 versionCode 미노출)이나, 동일 메커니즘을 쓰는 play_closed.yml의 성공 실행(run id 33475453597, head_sha=aac8aa34, PR #243 — 1e3d8bc6보다 2커밋 뒤)의 아티팩트명이 "android-closed-**v2188**-aac8aa34…"로 versionCode를 직접 노출하며, 이는 `git rev-list --count aac8aa34`=2188과 정확히 일치. 즉 실제 소비된 versionCode는 2174/2186(또는 비공개 트랙은 실제 빌드 커밋 기준 2188)이며, 188/200이 아님.
(4) 부가 사실: "비공개테스트" 업로드는 1e3d8bc6 자체가 아니라 그 2커밋 뒤인 aac8aa34에서 수동 workflow_dispatch(play_closed.yml)로 이뤄졌고, 첫 시도(run 33474410380)는 실패, 재시도(33475453597)에서 성공했다.

**비고:** 클레임의 정성적 골자(릴리스 커밋=pubspec bump일 뿐이고 실제 Android versionCode는 pubspec의 +N이 아니라 git rev-list --count HEAD 기반 자동값)는 코드(build.gradle.kts)·CI 로그로 확실히 반영되어 있다. 다만 클레임이 명시한 예시 수치 "188/200"은 재현 불가 — 실측치는 2174(54dae1f0)/2186(1e3d8bc6), 실제 업로드 빌드 기준으로는 2188(aac8aa34)이다. Play Console 내 실제 버전 목록 자체(외부 콘솔)는 이 컨테이너에서 열람 불가하나, CI의 업로드 스텝 성공(conclusion=success)과 아티팩트명이 강한 대체 증거가 된다.

### H-50 — 불일치

**주장:** AGENTS.md #100 태블릿 골든 게이트 — "medium/expanded 6장 깨짐"이 여전히 유효한가(이미 수리됐으면 게이트 stale)

**근거:** Fix commit 92ffd22e "test(goldens): #96 태블릿 화면 골든 6장을 SoriTypeScale에 맞춘다" (2026-08-19 15:06:45Z) is an ancestor of current HEAD (`git merge-base --is-ancestor 92ffd22e HEAD` → yes) and touches exactly the 6 files the gate names: test/goldens/baselines/{screen_settings,screen_sori_today,screen_vocab_packs}_{medium,expanded}.png, plus test/goldens/screen_layout_golden_test.dart (+4 lines wrapping the harness in SoriTypeScale, matching production `lib/main.dart:601`'s `MaterialApp.builder => SoriTypeScale(child: ...)`). The harness now carries an explicit comment at screen_layout_golden_test.dart:218-220: "Production installs this in MaterialApp.builder (`lib/main.dart`). Without it, tablet goldens lock in 'no comfort scaler' after #96." The AGENTS.md #100 gate entry itself (AGENTS.md:394-395, "- [ ] #100 태블릿 골든 (CI): ... cursor/fix-tablet-goldens-4772가 하니스에 SoriTypeScale을 넣고 Linux 기준선을 갱신 중") was added by commit f44e2978a at 2026-08-19 15:14:22Z — 8 minutes AFTER the fix commit, but on a divergent line (`git merge-base --is-ancestor 92ffd22e f44e2978a` → no) that was unaware of it; `git blame -L 394,395 AGENTS.md` shows those two lines still attributed to f44e2978a with no later edit. All 6 baseline PNGs continued to be refreshed normally in subsequent unrelated commits (c47d4379, 4c831eaa, 156ebe9b, 09af5b2b, 28d32907, f82942d1, 11c93aa8, e13c6c71) with no skip/xfail/TODO markers on tablet viewports in the test file.

**비고:** 핸드오프/AGENTS.md의 게이트 텍스트는 "진행 중"(- [ ] ... 갱신 중)이라고 하지만, 실제로는 같은 날 8분 전에 이미 다른 브랜치 라인에서 완료되어 현재 HEAD에 병합되어 있다 — 두 커밋이 병렬로 작성되며 게이트 문서가 갱신되지 않은 stale 케이스. 실기기/CI 실행 결과 자체는 이 컨테이너에서 재실행하지 않았다(정적 파일·이력 검증만 수행).

### H-51 — 반영

**주장:** closed-testing-checklist §0 플립게이트(ae024af6) 해소 여부 딥 트레이스

**근거:** RESOLVED. (1) 08-14 판정 원문 확인: docs/store/closed-testing-checklist-v2.md:50-56 (e723ddc7, 2026-08-14) — ae024af6 테스트가 텍스트 드래그 + coach RenderAbsorbPointer 문제로 불통과. (2) 다음날 08a77fd6 (2026-08-15, "finalize Sori Deck 2.0")가 두 지적을 직접 수정: git log -S "코치 오버레이"/-S "deck-card-slot" 모두 08a77fd6를 가리킴; 현재 test/review_session_flipgate_test.dart:53-57에 coach 고정(kl_tut_review/soriDeck/wordbook=true, "AbsorbPointer가 드래그를 삼켜 단언이 공허해지는 것 방지" 주석), :149/:247에 ValueKey('deck-card-slot') wrapper finder. (3) abf9e3ff (08-18, Sori Deck 3.0 물리 재작성) → test/deck_swipe_physics_test.dart·deck_direction_contract_test.dart 신설. (4) c917d777+01bd8849 (08-19) 틴더 덱 제거·세로 피드 전환으로 플립 전 가로 스와이프 SRS 오염 경로 자체를 구조적으로 제거 — deck_direction_contract_test.dart가 "live screens do not construct SoriSwipeCard"·"screens do not bind left/right swipe handlers"를 가드; c917d777이 체크리스트 게이트 문구도 SoriSwipeCard→SoriContentFeed로 갱신. (5) versionCode 29 업로드(1e3d8bc6, PR #242, 2026-09-01)는 play_closed.yml alpha 트랙 경유이며, 해당 워크플로는 exact main SHA의 push CI 성공(Require successful exact-SHA main CI 스텝)을 강제하고 ci.yml:267-269가 flutter test 전체(플립게이트·덱 계약 테스트 포함)를 실행 — 게이트 실질은 08-15~08-19에 해소된 뒤 CI로 상시 강제됨.

**비고:** 게이트의 실질(coach AbsorbPointer, wrapper 타겟팅, SRS 오염)은 2026-08-15~19에 해소·구조 제거되어 09-01 업로드와 모순 없음. 다만 체크리스트 문서 자체는 §0 표가 전부 "[ ]"이고 08-14 부정 판정 블록이 통과 판정으로 교체된 적이 없어 문서 갱신 지연이 남아 있으며, review_session 플립게이트의 앞면 드래그 2건은 여전히 find.text(warnIfMissed:false)를 쓰지만 같은 파일의 양성 흐름 테스트(카드 전진+SRS 1 기록)가 동일 드래그 경로의 유효성을 증명해 공허 단언은 아니다.

### H-52 — 반영

**주장:** docs/딥리서치-한옥과한글소리.md 선행 대조 기록과의 교차 검증

**근거:** Section "## 저장소와 HANDOFF를 전부 대조한 현재 상태" exists at docs/딥리서치-한옥과한글소리.md:51 on origin/main; file committed 2026-08-25 in 9a4454a0 (#204), i.e. two days BEFORE HANDOFF-2026-08-27-waves.md. Full-text grep of the 1,026-line doc finds zero occurrences of wave/W3.5/W4/W5/W6/Sori/cloud_sync/ratchet — the section reconciles only the Hanok-track HANDOFFs of 2026-08-16..19 (PR3 86-grant design, HANDOFF_LIVING_HANOK_V1_2026-08-17, PR4 RGBA-layer contract, canonical 2026-08-18-235200-hanok-asset-skill-audit.md, MAIN_3DAY_AUDIT_2026-08-19). It therefore cannot and does not contradict the finding that the waves handoff is closed out (W4 18/18, W3.5 5/5, W5 5/6, W6 non-video); it corroborates the verification's core method by stating explicitly that mid-state HANDOFFs "그 문서들을 현재 정본으로 읽으면 안 된다" (older handoffs are snapshots, never current canon) — the exact principle behind treating HANDOFF-2026-08-27-waves.md as stale claim-source. Open items it records are all on the hanok-asset track (see notes); verified still-open today: assets/illustrations/personal_hanok_v2/map/structures/ contains exactly the same six PNGs the doc lists (anchae, daecheongmaru, haengrangchae, sadang, sarangchae, sotdaeulmun — no byeoldang/seogo promoted), and assets_unused/pending_review/ still holds a1_states/a2_furnishing etc.

**비고:** The doc is orthogonal to, and predates, the waves handoff — "corroborates" applies to its stale-handoff-reading principle, not to wave completion itself. It does surface open items outside the H-01..H-50 scope, all on the separate hanok-asset workstream (per its Aug-19-audit snapshot): the 86-grant CanDo hanok system not called from any live screen (legacy hanok live), A1 16-state/estate PNGs bundled but unused by the production renderer, 별당·서고 PNGs and 9 sarangbang props unpromoted in assets_unused/pending_review, A2 exterior overlay unwired, ~43 credits unledgered — this track remains active post-Aug-25 (e.g. 9267dc6c, f197893c) and was never part of the waves handoff's W3.5–W6 scope.

## 완전성 비평자

**매트릭스가 놓친 주장:**

- §8 premise: "`.superpowers/sdd/`는 gitignore 대상이라 워크트리를 지우면 원장이 통째로 사라진다" AND the §8 header claim that the W2 ledger `.superpowers/sdd/2026-08-26-w2-performance/progress.md` is "(main에 보존됨, 43줄)". Both are concrete and both FAIL against main: `git check-ignore` returns non-match (exit 1) for that path, origin/main actually TRACKS 12 files under `.superpowers/sdd/` (2026-07-29/07-31 ledgers plus 2026-09-01-handoff-verification-and-release), and the W2 progress.md is NOT tracked on origin/main. The matrix's H-44 only adjudicates the general '소실 우려 재현' narrative, not the false gitignore mechanism or the '43줄 main에 보존됨' assertion — this looks like an unflagged 불일치. — 위치: Section 8, first paragraph (line 326) and the W2 progress.md heading (line 330); 확인 방법: git -C worktree check-ignore -v .superpowers/sdd/2026-08-26-w2-performance/progress.md; git ls-tree -r origin/main --name-only | grep '^\.superpowers/sdd/'; git cat-file -e origin/main:.superpowers/sdd/2026-08-26-w2-performance/progress.md
- §3 W2 Codex collision incident and Jin asset commits: T3 commit mislanded on main as `dcb36a03`, recovered via cherry-pick `1e4c8ad5` + revert `f7e86bf8`; Jin's direct asset commit `f6949325` ("그림자 없는 동영상...절대 회귀하지말도록"), divergence merge `196a88e7`, matte-report regen `ca27367d`. H-03 only verified the 11 W2 task/merge SHAs; these 6 incident SHAs are never adjudicated. (I confirmed all 6 exist and dcb36a03 is reachable from origin/main — verdict would be 반영, but the matrix has no row for it.) — 위치: Section 3, W2 table rows 'Codex 충돌 사건' and 'Jin 직접 에셋 커밋' (lines 73-74); repeated in §6 워크트리 규칙 (line 239); 확인 방법: git log -1 --format='%h %s' dcb36a03 1e4c8ad5 f7e86bf8 f6949325 196a88e7 ca27367d; git merge-base --is-ancestor dcb36a03 origin/main
- §3 content-naturalness pipeline tooling exists: `tool/audit_content_naturalness.py` (heuristic prefilter) and `tool/apply_naturalness_patch.py` (id-keyed patch apply + TTS corpus regen). No matrix note mentions either file. (Both exist on origin/main — I verified via git cat-file.) — 위치: Section 3, '콘텐츠 품질 배경' paragraph (line 40); 확인 방법: git cat-file -e origin/main:tool/audit_content_naturalness.py && git cat-file -e origin/main:tool/apply_naturalness_patch.py; sanity-read both for the claimed roles
- §4 'queued(미반영) 소소 수정 2건': (a) bookshelf_screen.dart:351,374 calls learnedWordCount twice in the same build (hoist needed, '15개 commit 어디에도 반영 안 됨'), (b) T2 counter-label test only verifies +1, not +2 accumulation. Checkable whether these were later fixed on main: current lib/screens/bookshelf_screen.dart has only ONE learnedWordCount call site (line 505), so the double-call state described no longer matches main — the matrix should record whether this queued item was since resolved (반영 of the gap-claim vs superseded). — 위치: Section 4, final paragraph before section 5 (line 186); echoed in W4 progress.md Task 5 fix-queue (line 493); 확인 방법: grep -n learnedWordCount lib/screens/bookshelf_screen.dart on origin/main; git log -S 'learnedWordCount' --oneline -- lib/screens/bookshelf_screen.dart; grep the T2 counter test for a +2 accumulation assertion
- §7 '그 외 살아있는 계약' three named guards: `audio_policy_guard` (AudioPolicy single decision point, volume-literal ratchet), `game_surface_contract` (7 game screens keep SoriStudyFrame), `arb_l10n_guard` (DE/EN same-commit rule). No matrix note covers these three contracts. (All three test files exist in test/ on main — audio_policy_guard_test.dart, game_surface_contract_test.dart, arb_l10n_guard_test.dart.) — 위치: Section 7, '그 외 살아있는 계약' (lines 274-278); 확인 방법: ls test/{audio_policy_guard,game_surface_contract,arb_l10n_guard}_test.dart; verify game_surface_contract enumerates 7 screens and arb guard enforces paired keys
- §7 ratchet table — 15 concrete numeric caps (spacing 181, fontSize 115/15 files, ellipsis 0, w900≤28/w800≤80, fontFamily 0, raw TextStyle ≤217, BorderRadius ≤24, raw AppBar 0, raw TextField ≤22, icon SoriButton ≤71 with guide_runtime pin, raw InkWell ≤19, Sori widget files =133, routes =72, screen classes =108) plus the 5-entry chipWrapAllowlist. Only the =133 row is touched (via H-42's lock-doc cross-check). The rest are unverified against current guard tests. Notably the '=133/=72/=108' pins no longer appear verbatim in test/uiux_bible_closeout_inventory_test.dart (values moved after W4 T9-18 landed), so 'downward/bookkept-only movement' should be explicitly confirmed rather than assumed. — 위치: Section 7, '래칫 현재값' table and chipWrapAllowlist block (lines 280-307); 확인 방법: grep each ceiling constant in test/spacing_literal_guard_test.dart (found: ceiling = 181 still pinned), test/typography_guard_test.dart, test/chrome_stack_guard_test.dart, test/uiux_bible_closeout_inventory_test.dart; diff chipWrapAllowlist entries (study_library_screen.dart is still listed) against the handoff's 5 entries
- §7 contract 3 numeric sub-claim: '/review 라우트 + 고정 테스트 15곳' — the specific count of 15 test locations pinning /review as the player route. The matrix verifies /review/hub separation (H-19/H-24 area) but no note re-counts the 15 pinned tests. (A naive `grep -rln "'/review'" test/` gives 16 files today, so the counting method itself needs to be pinned down.) — 위치: Section 7, 계약 3 (line 271); also §4 T12 row (line 176); 확인 방법: Reproduce the 15-location count: grep -rn "'/review'" test/ excluding '/review/hub' matches, and compare against the W4 plan's enumeration
- §5 W6 item: audit script `tool/audit_scene_assets.py` (asset filename typo detection) listed as still-to-do W6 work. It now EXISTS on origin/main (added by commit e959e25d 'feat(tool): 시나리오 퀘스트 중복·씬 에셋 감사 스크립트 + 1차 리포트'), i.e. this W6 item has since landed — the matrix (H-37 covers only cloze curation) records nothing about it, and per the known-trap rule the stale handoff's 'not started' framing needs an explicit current-state verdict. — 위치: Section 5, 4순위 W6 paragraph (line 231); 확인 방법: git log --oneline --diff-filter=A -- tool/audit_scene_assets.py; confirm e959e25d is reachable from origin/main and the script does filename-typo auditing
- §5 W5 나머지 스코프 — the Meine Wörter hub sub-claim is concrete and route-testable: `/my_words` hub absorbing bookshelf/word_search/hard_words while those named routes MUST NOT be deleted (검수 HIGH#4: 8곳이 settings.name 의존). Matrix notes cover Anlaut (H-35) but none mention /my_words, Diktat 재설계, Silben 셀 UX, Aussprache 재구축(호랑이 제거+5범주), or 시나리오 인트로 해시 크롭. Given the trap note that W5 was implemented indirectly, each of these needs a current-main verdict (반영/의도적 보류/미반영). — 위치: Section 5, '마스터 플랜이 정의한 W5의 나머지 스코프' (line 225); 확인 방법: grep "'/my_words'" and the three legacy route names in lib/main.dart on origin/main; count settings.name dependents; grep for Diktat/Silben/Aussprache screen rework commits in git log since 2026-08-27
- §6 commit-discipline claim: the full commit message of dc1fc1f0 is exactly the quoted text — subject `feat(custom-pack): ... (지시서 1.21, 검수#23)` with no body, ending in the `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` trailer. Minor, but concrete and re-checkable; no matrix row cites it. (I verified: `git log -1 --format=%B dc1fc1f0` matches the handoff verbatim.) — 위치: Section 6, '커밋 규율' block (lines 255-261); 확인 방법: git log -1 --format=%B dc1fc1f0 and byte-compare with the handoff's quoted block

**내부 불일치 지적:**

- H-02 (반영, 'no discrepancy found') vs H-45 (불일치, '97건 중 13건은 Jin이 이미 확정·적용(2faef696)'): both verdicts adjudicate the same commit 2faef696 — H-02 confirms it as a parent of the Jin-13건 merge 10571b95, while H-45 identifies those same 13 items as a subset of the 97 rewrite items. But the handoff's §3 explicitly claims the 13건 are '웨이브 파이프라인 산출물이 아님' (i.e., separate from the 97) and §9 claims the 97 are '전부 미적용'. If H-45's finding stands, H-02's 'no discrepancy' is too generous — the 13건-vs-97건 relationship claim in §3/§9 is contradicted by the same evidence H-45 relies on, and at minimum H-02's note should acknowledge it.
- H-44 (반영, 'main 소실 우려가 여전히 재현된다') is undermined by directly checkable facts the matrix never surfaces: `.superpowers/sdd/` is NOT gitignored on origin/main (git check-ignore non-match) and 12 sdd ledger files ARE tracked there (including a 2026-09-01 handoff-verification workspace), so the handoff's stated loss mechanism ('gitignore 대상이라 워크트리를 지우면 사라진다') is false as written. A 반영 verdict on the loss-risk claim without testing its false premise is internally inconsistent — the claim is at best partially true (worktree-local untracked ledgers can be lost, but not because of gitignore) and arguably 불일치.
- H-46 verdict is 반영 but its own note argues the opposite epistemic state: '지시서 파일·new_인보딩/ 모두 현재 컨테이너(클론)에는 애초에 존재하지 않아 ... 검증 범위 밖'. Per the verdict rubric, a claim about untracked state on Jin's local machine that cannot be checked from this container is the textbook case for 검증불가, not 반영. Either the verdict or the note is wrong.
- H-49 (불일치) cites refutation attempts involving '--build-number 오버라이드' and 'docs·워크플로 전수 grep', but nothing in the 521-line handoff mentions build numbers or release versioning — the evidence trail does not anchor to any identifiable claim in this document. It is unclear which handoff assertion H-49 adjudicates; if it maps to the ci-mirror/commit-count claims of §1-2, note that I independently verified `git rev-list --count 9b92973d..8faae14f` = exactly 10 with all 10 being onboarding/golden commits (matching the handoff), which would contradict a 불일치 verdict on that particular claim — so H-49 needs its claim text re-stated to be auditable.
- H-30 is verdicted 의도적 보류 (correct for the snap gate) but its note reads as a pure 반영-style match confirmation ('세 요소...정확히 일치...삼자가 정합') without naming the documented gate (실기기 QA: 콜드스타트·10분 ANR 0·4방향 손맛) that the 의도적 보류 verdict definitionally requires; conversely H-47 uses 의도적 보류 with a note that starts from 'Numbers and no-commit finding both check out' — the two rows apply the same verdict under visibly different standards, which weakens the 반영/의도적 보류 boundary across the matrix.

---

## 부록 — 비평자 후속 판정 (H-53~H-56) 및 보완 노트

### H-53 — 불일치

**주장(인계서 §8 전제):** "`.superpowers/sdd/`는 gitignore 대상이라 워크트리를 지우면 원장이 통째로 사라진다" + W2 원장이 "main에 보존됨(43줄)".

**근거:** `git check-ignore -v .superpowers/sdd/.../progress.md` → 비매치(exit 1) — **gitignore 대상이 아니다**. `git ls-tree -r origin/main | grep '^.superpowers/sdd/'` → 2026-07-29/07-31 원장 12파일이 main에 추적 중. 반면 `.superpowers/sdd/2026-08-26-w2-performance/progress.md`는 main에 **없다** — W2 원장 전문은 인계서 §8 본문 안에만 보존돼 있다. 즉 원장 소실의 실제 원인은 gitignore가 아니라 "커밋하지 않고 워크트리를 지운 것"이며, 원장은 커밋으로 보존 가능하다(이 세션 원장이 그렇게 커밋됨).

### H-54 — 반영 (비평자 검증)

**주장(§3 W2 사건 SHA):** Codex 충돌 사건(dcb36a03 오착륙, 1e4c8ad5 체리픽, f7e86bf8 리버트)과 Jin 에셋 커밋(f6949325, 196a88e7 머지, ca27367d 매트 리포트).

**근거:** 6개 SHA 전부 존재, dcb36a03은 origin/main 도달 가능 — 비평자가 `git log -1`로 각각 확인.

### H-55 — 반영 (비평자 검증)

**주장(§3 콘텐츠 파이프라인 도구):** `tool/audit_content_naturalness.py`(휴리스틱 프리필터) + `tool/apply_naturalness_patch.py`(id-키 패치 적용) 존재.

**근거:** 두 파일 모두 origin/main에 존재(`git cat-file -e`).

### H-56 — 반영 (비평자 검증)

**주장(§6 커밋 규율):** dc1fc1f0의 커밋 메시지 전문이 인계서 인용 블록과 일치.

**근거:** `git log -1 --format=%B dc1fc1f0` 바이트 대조 일치.

### 보완 노트

- 비평자가 "누락"으로 지목한 3건은 실제로는 기존 행이 다룬다(압축 뷰 오탐): 살아있는 계약 3종 = H-41, `audit_scene_assets.py` = H-39(존재, e959e25d로 랜딩 — §5의 "진행 대상" 서술은 stale), W5 잔여 스코프(/my_words·Diktat·Silben·Aussprache·인트로 해시 크롭) = H-35.
- §7 계약3의 "/review 고정 테스트 **15곳**" 카운트는 현재 16파일로 자연 증가(테스트 신설) — 라우트 계약 자체는 H-19/H-40대로 유지.
- §4 "queued 소소 2건"(bookshelf `learnedWordCount` 2회 호출)은 이후 해소됨 — 현재 `lib/screens/bookshelf_screen.dart`의 호출 지점은 1곳(:505), w4-integration 플랜이 명시한 수정이 랜딩된 결과(H-26 정합).
- H-02와 H-45는 모순이 아니라 상보: 2faef696은 Jin 확정 13건의 실체이며 동시에 97건 재작성 목록 중 13건을 ✅ 처리한 커밋이다 — 그래서 §9-1의 "97건 대기"는 84건 대기로 정정된다(H-45).
- 래칫 인벤토리 `=`핀(위젯 파일 수 등)은 W4/W5 화면 랜딩과 함께 부기 갱신됨(예: 133→135) — 하향 전용 래칫(ellipsis 0 등)은 전부 유지(H-42).
