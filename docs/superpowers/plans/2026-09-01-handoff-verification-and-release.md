# 인수인계 1:1 검수·잔여 정리·릴리스 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 인수인계서(2026-08-27)의 main 반영을 1:1 판정하는 매트릭스를 커밋하고, 확정 격차를 수정한 뒤, main 병합과 Android 내부·비공개 재배포(2.0.8+30)까지 완료한다.

**Architecture:** 검수는 병렬 read-only 검증자 팬아웃 + 적대적 재검증으로 매트릭스를 만들고, 수정은 워크트리 한 곳에서 직렬 SDD로 랜딩한다. 병합·배포는 검수 PR → graphify PR → 릴리스 PR(마지막) 순서를 고정해 play_closed의 정확-SHA 게이트를 지킨다.

**Tech Stack:** git worktree, GitHub MCP(PR·Actions), ci.yml/play_closed.yml, graphifyy CLI(스코프 한정), Flutter 테스트는 CI 전용(컨테이너에 flutter 없음).

**Spec:** `docs/superpowers/specs/2026-09-01-handoff-verification-and-release-design.md`

## Global Constraints

- 작업 위치: `/home/user/ko_lernen_app_worktrees/handoff-verify`, 브랜치 `claude/handoff-review-verification-199gwi` (base origin/main).
- 커밋 제목 `type(scope): 설명`, 본문 없이 트레일러 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` (+세션 트레일러). 모델 ID를 제목·본문에 쓰지 않는다.
- 래칫 상향 금지, 가드 allowlist 확장 금지, `docs/assets/**`·매트 예산 코드 수정 금지, `.graphify_python`·`graphify-out/cache/**` 수정 금지.
- `test/tester_build_release_contract_test.dart`가 고정한 문자열 앵커('12명 이상 연속 opt-in, 14일', §2.4 빌드 블록, `git rev-list --count HEAD` 등) 불변.
- 구현 태스크는 직렬(한 워크트리 구현자 1명), 검수 태스크만 병렬 허용.
- 배포 보고는 CI run/잡 conclusion 실측만 근거로 한다.

---

### Task 1: 검수 매트릭스 생성·커밋

**Files:**
- Create: `docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md`

**Interfaces:**
- Produces: 매트릭스 문서(주장 id `H-01`…`H-45+`, 판정 `반영|의도적 보류|미반영|불일치|검증불가`, 근거 SHA/파일:줄/PR/가드명). Task 2 배너와 Task 9 PR 본문이 이 파일을 인용한다.

- [ ] **Step 1: 주장 분해** — 인계서 §1-§9를 원자 주장으로 분해(§2 상태표 6, §3 웨이브 SHA·카운트 8, §4 W4 T1-18, §5 W5 계약 6+교차 2+2순위 5+W6 4+마스터플랜 잔여 8, §7 계약 4+살아있는 계약 3+래칫 16, §8 원장 4, §9 항목 10). 각 주장에 검증 방법 1줄.
- [ ] **Step 2: 병렬 검증** — 주장별 검증자(sonnet) 팬아웃. 브리프에 함정 3종(인계서 stale 서술 / W5 간접 구현: `showSoriLevelFilterSheet`·`SoriSpeech.*`·`study_frame.dart` 주입 / W4 T10·T18은 `Storage.*` 접근자로 검증) + "origin/main 콘텐츠만 근거" 명시.
- [ ] **Step 3: 적대적 재검증** — `미반영`/`불일치` 1차 판정 전건을 opus 재검증(반박 시도, 근거 파일 직접 재열람). 재검증 통과만 확정.
- [ ] **Step 4: §0 플립게이트 증거 추적** — `ae024af6` 이후 vocab_pack/review_session/custom_pack_play의 드래그(외부 플립게이트) 검증이 해소됐는지: `git log --all --grep`(flip, drag, SoriSwipeCard, coach), `docs/store/closed-testing-checklist-v2.md` 이력, PR #211(review_session ±233)·관련 테스트로 추적. 결론을 매트릭스 `H-§0` 항목에 증거와 함께 기록.
- [ ] **Step 5: 매트릭스 작성·커밋** — 표(판정 집계 헤더 + 항목별 행) 작성.
  `git add docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md && git commit -m "docs(audit): 인수인계 2026-08-27 1:1 검수 매트릭스"`

### Task 2: 인계서 이력화 배너

**Files:**
- Modify: `docs/HANDOFF-2026-08-27-waves.md:1-5` (제목 바로 아래 blockquote 추가, 본문 무수정)

- [ ] **Step 1: 배너 삽입** — 제목(`# 기술 인계서 …`) 다음 줄에:
```markdown
> **⛔ 이력 문서 (2026-09-01 1:1 검수 종결):** 이 인계서의 실행 항목은 전부 종결됐다 —
> W4 18/18(PR #209) · W3.5 이월 5/5(PR #210) · W5 계약 5/6(PR #211/#217/#218, 잔여 1건
> `FeedPhysics.snap` 기본 전환은 Jin 실기기 승인 게이트) · W6 비영상(PR #219/#220/#222).
> 항목별 판정·근거는 `docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md`.
> 현행 정본은 `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md`와 이후 릴리스
> 트랙이다. 아래 본문은 2026-08-27 시점 서술이므로 현재 상태로 읽지 말 것.
```
- [ ] **Step 2: 커밋** — `git commit -m "docs(handoff): 2026-08-27 인계서 이력화 배너 — 검수 매트릭스 링크"`

### Task 3: 앱스토어 리뷰 문서 버전 핀 제거

**Files:**
- Modify: `docs/store/app-store-connect-v2.0.8-review-access.md:101`

- [ ] **Step 1: 교체** — `The repository version is currently \`2.0.8+27\`. For iOS/iPadOS, App Store` 문장을 다음으로 교체(뒤 문장 유지):
```markdown
The repository version is whatever `pubspec.yaml` line 4 says at archive time
(2026-09-01 현재 `2.0.8+30`). For iOS/iPadOS, App Store
```
- [ ] **Step 2: 커밋** — `git commit -m "docs(store): 리뷰 접근 문서의 고정 버전 표기를 pubspec 참조로 정정"`

### Task 4: 체크리스트 §0 — 증거 반영 또는 모순 명기 (Task 1 Step 4 결과로 분기)

**Files:**
- Modify: `docs/store/closed-testing-checklist-v2.md` (§0 판정 블록에 날짜별 추기만, 기존 문구 삭제 금지)

- [ ] **Step 1(분기 A — 해소 증거 발견):** 2026-08-14 판정 아래에 `- 2026-09-01: <근거 SHA/PR/테스트> 로 외부 플립게이트 인수 통과 확인 — §0 하드스톱 해제.` 추가.
- [ ] **Step 1(분기 B — 증거 미발견):** 동일 위치에 `- 2026-09-01: 위 판정이 미해소인 채 versionCode 29(2026-09-01)가 alpha에 업로드됨 — 게이트와 실운영의 모순. Jin 판정 대기(재검증 또는 판정 폐기). 업로드는 Jin 명시 지시로 진행됨.` 추가.
- [ ] **Step 2: 계약 테스트 앵커 확인** — 추가 텍스트가 `tester_build_release_contract_test.dart`의 `contains`/`isNot(contains)` 단언과 충돌하지 않는지 대조(§2.4 빌드 블록·'12명' 문구·금지어 `BETA_UNLOCK_ALL`·`/Users/` 미포함).
- [ ] **Step 3: 커밋** — `git commit -m "docs(store): closed §0 판정 추기 — 2026-09-01 검수 결과"`

### Task 5: AGENTS.md 게이트 최신화

**Files:**
- Modify: `AGENTS.md` "현재 진행 중인 작업" 절만

- [ ] **Step 1:** UI 실기기 게이트 항목에 1줄 추가: `tiger_choose 매트 그림자 24.1%는 수리가 아니라 per-clip 예산 완화(0.06→0.25 그랜드파더, tool/clip_matte_report.json)로 게이트 통과 중 — 육안 확인 대상(magpie_celebrate·magpie_flight 동일).`
- [ ] **Step 2:** Task 1 매트릭스가 증거로 닫았다고 판정한 게이트만 삭제(예: #100 태블릿 골든이 이미 green이면). 증거 없으면 무변경.
- [ ] **Step 3: 커밋** — `git commit -m "docs(agents): 게이트 최신화 — 매트 예산 그랜드파더 가시화 (검수 2026-09-01)"`

### Task 6: 검수 발견 코드 격차 수정 (조건부, Task 1 확정분만)

**Files:** Task 1 매트릭스의 `미반영`/`불일치` 중 코드 건별로 지정

- [ ] **Step 1:** 건별 RED 테스트 → 최소 구현 → 커밋(TDD, 래칫·가드 준수). 이 컨테이너에서 실행 불가한 테스트는 코드 리뷰 에이전트 2인(구현 외 fresh) 교차 검증으로 대체하고 PR CI로 실측.
- [ ] **Step 2:** 없으면 이 태스크는 "해당 없음"으로 원장 기록.

### Task 7: 이연 minor 저위험 스윕 (조건부)

**Files:** 확인 후 지정 — 후보: `test/`의 reward-flow 3초 고정 딜레이, `tool/pad_android12_splash_icon.py` mkdir, W2 가드 정규식, `lib/main.dart` 낡은 주석, W4 원장 deferred(예: speakable 3자 경합)

- [ ] **Step 1:** 후보 각각이 #209~#245에서 이미 처리됐는지 확인(처리됐으면 목록에서 제거).
- [ ] **Step 2:** 남은 것 중 "테스트/도구/주석 한정 + 프로덕션 동작 무변경" 건만 수정·개별 커밋. 그 외는 매트릭스 부록 '차기 후보'로 목록화.

### Task 8: SDD 원장 요약 반영

**Files:**
- Modify: `docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md` (부록 절 추가)

- [ ] **Step 1:** `.superpowers/sdd/2026-09-01-handoff-verification-and-release/progress.md`의 태스크별 결론·룰링을 매트릭스 부록으로 요약(원장 소실 대책). 커밋 `docs(audit): 검수 세션 원장 요약 부록`.

### Task 9: 검수 PR → CI green → main 병합

- [ ] **Step 1:** `git fetch origin && git log --oneline origin/main -1`(발산 확인) → `git push -u origin claude/handoff-review-verification-199gwi`(실패 시 2/4/8/16s 백오프).
- [ ] **Step 2:** draft PR 생성(base main). 본문: 매트릭스 요약표 + 변경 목록 + human-only 잔여 + iOS 런북. `subscribe_pr_activity`.
- [ ] **Step 3:** ready-for-review 전환 → head SHA 자동 CI run 확인(없을 때만 `task=ci` 1회 dispatch) → green까지(실패는 root-cause 후 수정 커밋, draft 병합 금지).
- [ ] **Step 4:** merge_pull_request(merge commit) → main push CI(전체 스위트) green 확인. red면 수정 PR 즉시.

### Task 10: graphify 스코프 기록 → PR → 병합

- [ ] **Step 1:** 워크트리를 병합된 origin/main으로 최신화. 이번 병합에서 변경된 파일 목록으로 graphify 스코프 재추출(#238 방식). diff 검사: `git status --porcelain -- graphify-out/ | grep -v -E "manifest.json|graph.json|GRAPH_REPORT|labels|2026-09-01|wiki/"`가 비어야 함. `.graphify_python`·`cache/**` 변경 발생 시 전부 checkout으로 되돌리고 manifest 경량 갱신(변경 파일 엔트리만)으로 폴백.
- [ ] **Step 2:** 커밋 `docs(graphify): 인수인계 검수·병합 반영 — 매트릭스·배너·게이트 갱신 기록` (본문에 검수 결론·병합 SHA 서술) → 새 브랜치 PR → CI green → 병합.

### Task 11: 릴리스 PR + 내부·비공개 배포

- [ ] **Step 1:** Jin에게 `PLAY_INTERNAL_RELEASE_ENABLED=true` 설정 요청(AskUserQuestion). 응답 전 진행 금지(거절/무응답 시 내부는 blocked 보고, 비공개만 진행).
- [ ] **Step 2:** 새 브랜치에서 `pubspec.yaml:4`를 `version: 2.0.8+30`으로 — 단일 파일 커밋 `release: versionCode 30 — Play 비공개테스트`. PR 생성(풀스위트 PR CI green 확인) → **squash 병합**, squash 제목 = 커밋 제목 그대로.
- [ ] **Step 3:** 병합 SHA의 push CI 완주 대기 → conclusion success + `Signed AAB to Play Internal Testing` 잡 `success` 확인(변수 ON 시). `skipped`면 변수 상태 재확인 후 `task=release-internal` dispatch 1회.
- [ ] **Step 4:** origin/main tip == 병합 SHA 재확인 → `play_closed.yml` dispatch `{"expected_sha":"<병합 SHA 40자 소문자>"}` → run `success` 확인. 실패 시 로그 root-cause(레이스면 새 tip으로 재수행).

### Task 12: 최종 검증·보고

- [ ] **Step 1:** verification-before-completion 점검: 전 PR 병합·CI green·업로드 잡 success·graphify 커밋 diff 범위 — 전부 실측 링크로 수집.
- [ ] **Step 2:** 검수 매트릭스 아티팩트 페이지 발행(비공개 링크).
- [ ] **Step 3:** 한국어 최종 보고: 매트릭스 요약, 병합·배포 실측, Jin 전용 잔여 목록(지시서 파일 미추적·partner_rewrite_diff2·new_인보딩/·FeedPhysics 실기기 게이트·12명×14일 캠페인·Play Console 승격·Firebase 게이트·iOS 수동 런북·시나리오 아트 126건·§0 판정).
