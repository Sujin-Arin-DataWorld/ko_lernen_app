# Android Closed Testing readiness checklist

> **Phase 5 학습 루프 안정화의 운영 정본이다.** 일반적인 수동 기기 QA는
> docs/store/RELEASE_QA_CHECKLIST.md를 함께 사용한다. 이전 v2.0 alpha의
> 5–10명, 1주, 61팩 수치는 역사 기록일 뿐 이번 후보의 기준이 아니다.
>
> 이번 대상은 Android 비공개 베타다. 2023-11-13 이후 생성된 개인 개발자 계정에는
> Google의 현재 최소 조건인 **12명 이상 연속 opt-in, 14일**을 적용한다. 계정 유형이나
> Play Console Dashboard가 더 강한 조건을 표시하면 그 값을 따른다. iOS 출시, 새 학습
> 기능, SRS 스케줄 재설계, 새 telemetry는 이 절차에 포함하지 않는다. 기준 출처는
> [Google Play Console Help](https://support.google.com/googleplay/android-developer/answer/14151465)다.

## 0. 후보 기록과 중단 조건

이 표는 실제 clean release commit을 정한 뒤에만 채운다. Play Console의 최고
versionCode를 확인하기 전에는 버전이나 출시일을 추측해 쓰지 않는다.

| 항목 | 확인값 |
|---|---|
| release commit SHA | [ ] |
| git commit 수 기반 Android versionCode | [ ] |
| pubspec versionName | [ ] |
| Play Console 최고 기존 versionCode | [ ] |
| AAB SHA-256 | [ ] |
| Internal testing 설치 확인 시각 | [ ] |
| Closed Testing 시작일 / 종료 예정일 | [ ] / [ ] |
| 초대 / opt-in / 핵심 흐름 완료 | [ ] / [ ] / [ ] |
| 업데이트 보존 완료 / 기기 매트릭스 완료 | [ ] / [ ] |
| 외부 flip-gate handoff commit SHA | [ ] |

### 지금 후보를 만들 수 있는가?

- [ ] 외부 소유의 vocab_pack_screen.dart, review_session_screen.dart,
  custom_pack_play_screen.dart와 관련 flip-gate 테스트가 **별도 commit SHA와 함께**
  인계되었다.
- [ ] 그 인계에는 flutter analyze 0 issues와 아래 정확한 검증 명령의 통과가 포함된다.
  `flutter test test/swipe_card_test.dart test/custom_pack_flipgate_test.dart
  test/review_session_flipgate_test.dart`
- [ ] flip-gate 회귀는 텍스트가 아니라 SoriContentFeed wrapper의 key/finder를 잡는다.
  각 화면에서 뒤집기 전 가로 드래그와 게이트된 판정이 SRS 0이고, 뒤집은 뒤 세로
  다음/텍스트 판정은 해당 화면의 기존 positive/negative 흐름을 기록함을 보인다.
  VocabPackScreen 수준의 증거도 포함한다.
- [ ] 정확한 release commit에서 만든 **clean worktree**만 사용한다. 현재 작업 루트의
  미인계 변경, untracked test, 또는 빌드 산출물을 섞지 않는다.
- [ ] 아래의 자동 게이트와 Internal Play 설치를 통과했다.

위 항목 하나라도 비어 있으면 AAB를 업로드하거나 Closed Testing을 시작하지 않는다.
특히 외부 변경이 진행 중인 더러운 worktree에서 빌드하지 않는다.

> **현재 인계 판정 (2026-08-14).** `ae024af6`은 별도 커밋으로 도착했지만 아직 이
> 게이트를 통과하지 못했다. `custom_pack_flipgate_test.dart`와
> `review_session_flipgate_test.dart`의 첫 드래그는 `SoriSwipeCard`가 아닌 텍스트를
> 대상으로 하며, 첫 실행 coach의 `RenderAbsorbPointer`에서 missed-hit-test 경고가 난다.
> 따라서 11개 테스트의 green 결과만으로는 실제 스와이프/SRS 경계를 증명하지 못한다.
> coach 상태를 명시적으로 고정하고 wrapper를 직접 드래그해, 앞면 좌·우 무기록과
> 뒤집은 뒤 positive/negative·wrong-count 기록을 검증하는 보강 인계가 필요하다.

> **후속 판정 (2026-09-01, 1:1 검수).** 위 지적의 실질은 이후 해소됐다:
> `08a77fd6`(2026-08-15)가 coach 상태 고정(`kl_tut_review`/`soriDeck`/`wordbook`)과
> `ValueKey('deck-card-slot')` wrapper 직접 드래그로 두 지적을 수정했고, `abf9e3ff`
> (08-18)가 덱 물리 계약 테스트를 신설, `c917d777`+`01bd8849`(08-19)가 틴더 덱 제거·
> 세로 피드 전환으로 플립 전 가로 스와이프 SRS 오염 경로를 구조적으로 제거했다
> (`deck_direction_contract_test.dart` 가드). 이 테스트들은 main push CI 전체 스위트로
> 상시 강제된다. 단 §0 후보 표는 여전히 공란 — 표 기입은 릴리스 오너가 업로드 시점
> 값으로 채우는 수동 절차로 남는다. 근거 상세:
> `docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md` H-51.

## 1. Phase 5에서 지키는 학습 계약

- PackSessionSrsLedger와 PackRecallSession은 임시 세션 한정이다. 새 persisted attempt
  모델이나 migration을 추가하지 않는다.
- Boss는 모든 Boss 단어를 Learn에서 본 뒤의 4지선다 **인식 평가**다. recall gate나
  장기 mastery 증거라고 부르지 않는다.
- 선택형 타이핑 회상은 연습이다. 팩 clear, 다음 팩 unlock, XP, stamp, 코스 진행을
  막거나 바꾸지 않는다.
- 70% Boss clear, 영구 clear, 다음 팩 unlock, XP, stamp의 기존 동작을 유지한다.
- BETA_UNLOCK_ALL=true는 **내부 테스트 전용** premium entitlement override다.
  Closed Testing 후보에는 주입하지 않는다. 저장된 pack progress, 70% clear,
  다음 팩 잠금 해제는 어느 빌드에서도 우회하지 않는다.
- ENABLE_TESTER_FEEDBACK=true는 Android의 구조화된 tester feedback만 켠다. 학습
  흐름의 조건이나 새 telemetry가 아니다.

## 2. clean release candidate 만들기

§2.1부터 §2.4까지는 같은 terminal session에서 순서대로 실행한다. 그래야 exact
release commit 변수와 clean-tree 검사가 AAB 생성 직전까지 이어진다.

### 2.1 인계 확인 후 exact commit 고정

1. 외부 소유 변경의 담당자가 독립 커밋과 handoff 근거를 제공한다.
2. 그 커밋을 포함할지 결정한 exact SHA를 기록한다. 미완성 변경은 다음 후보로 미룬다.
3. 깨끗한 분리 worktree를 만들고, 그 안에서만 후보를 검증한다.

```bash
git worktree add --detach /tmp/hangul-sori-phase5-candidate <release-sha>
cd /tmp/hangul-sori-phase5-candidate
release_commit=$(git rev-parse HEAD)
release_sha=$(git rev-parse --short HEAD)
test -z "$(git status --porcelain)"
```

기대값은 마지막 명령이 성공하는 것이다. ignored local signing credentials는
release machine에만 두고, 값이나 경로를 문서·로그·피드백에 쓰지 않는다.

### 2.2 versionCode와 commit 주입

Android versionCode는 gradle이 release commit의 git commit 수로 계산한다. 후보 SHA에서
다음을 확인하고 Play Console의 최고 existing versionCode보다 큰 값만 사용한다.

```bash
git rev-parse --short HEAD
git rev-list --count HEAD
grep '^version:' pubspec.yaml
```

versionName은 pubspec.yaml에서, versionCode는 위 commit count에서 읽는다. 둘 중 어느
값도 과거 release notes의 숫자로 대체하지 않는다.

내부테스트와 비공개테스트는 서로 다른 커밋에서 자른다. versionCode가 commit count라서
같은 SHA로 두 트랙을 올리면 두 번째 업로드가 `Version code N has already been used.`로
거부된다. `PLAY_INTERNAL_RELEASE_ENABLED=true`인 동안에는 main push마다 내부 업로드가
그 커밋의 versionCode를 먼저 소비하므로, 비공개 후보를 자르기 전에 변수를 끈다
(2026-09-01 vC2215 실사고 — 빌드·서명·게이트는 통과하고 업로드 호출만 거부됐다).

### 2.3 자동 사전 게이트

```bash
flutter pub get
flutter gen-l10n
git diff --exit-code
test -z "$(git status --porcelain)"
test "$(git rev-parse HEAD)" = "$release_commit"
flutter test --concurrency=1 \
  test/pack_session_srs_ledger_test.dart \
  test/vocab_pack_srs_ledger_integration_test.dart \
  test/vocab_pack_recall_test.dart \
  test/vocab_pack_assessment_order_test.dart \
  test/pack_progress_service_test.dart \
  test/game_srs_evidence_test.dart \
  test/scenario_srs_persistence_flow_test.dart \
  test/grammar_choice_quiz_test.dart \
  test/grammar_choice_quiz_screen_test.dart \
  test/course_graph_test.dart \
  test/content_id_contract_test.dart \
  test/data_integrity_test.dart \
  test/learning_data_recovery_test.dart \
  test/data_migration_test.dart \
  test/arb_l10n_guard_test.dart
flutter test --dart-define=BETA_UNLOCK_ALL=true test/pack_progress_service_test.dart
flutter analyze
flutter test
git diff --exit-code
test -z "$(git status --porcelain)"
test "$(git rev-parse HEAD)" = "$release_commit"
git diff --check
```

Visual source를 승인해 바꾼 경우가 아니면 goldens를 갱신하지 않는다. golden의 정본은
Linux CI다. visual_layout_regression_test.dart가 실패하면 clean be4492ea 기준과
비교해 이번 후보의 회귀인지 먼저 분류한다.

### 2.4 Closed-testing AAB

```bash
git diff --exit-code
test -z "$(git status --porcelain)"
test "$(git rev-parse HEAD)" = "$release_commit"
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --dart-define=ENABLE_TESTER_FEEDBACK=true \
  --dart-define=GIT_COMMIT="$release_sha"
shasum -a 256 build/app/outputs/bundle/release/app-release.aab
```

기대 산출물은 build/app/outputs/bundle/release/app-release.aab와
build/app/outputs/symbols/다. AAB SHA-256를 §0 표에 기록한다. 이 AAB는 exact clean
commit과 1:1이어야 하며, 루트 worktree에서 만든 다른 AAB로 바꿔치기하지 않는다.

## 3. Play Internal testing 먼저

일상적인 AAB 생성·업로드는
[`docs/GITHUB_ACTIONS_PLAY_INTERNAL_SETUP.md`](../GITHUB_ACTIONS_PLAY_INTERNAL_SETUP.md)의
GitHub Actions 경로를 사용한다. 그 경로는 **내부 테스트(`internal`)만** 갱신하고
비공개 테스트 트랙은 건드리지 않는다. 아래 실기기 검증은 자동 업로드 뒤에도
생략하지 않는다.

Closed Testing에 올리기 전 Internal testing에서 아래를 release build로 확인한다.

- [ ] 올바른 versionCode와 SHA의 AAB가 업로드되었다.
- [ ] Play Store에서 설치한 release build가 시작한다.
- [ ] App Check / Play Integrity가 실제 Play 설치 경로에서 유효하다.
- [ ] 기존 설치 위 업데이트 후 pack progress와 학습 데이터가 남는다.
- [ ] release-only crash, signing, minify, asset 누락이 없다.
- [ ] 동의한 성인 tester 한 명 이상에서 opt-in Analytics/Crashlytics 수신을 확인했다.
- [ ] 개인정보와 학습 답안이 없는 Tiger Pulse 1건을 실제 결과 화면에서 제출했고,
  App Check 보호 경로를 거쳐 accepted/delivered 상태가 확인되었다.

Analytics와 Crashlytics는 opt-in이며 self-attested age의 보수적 gate가 수집을 차단할 수
있다. 따라서
Crashlytics의 “새 크래시 없음”은 동의한 tester 범위에서만 해석한다. 기존
pack_completed, quiz_completed, Crashlytics, Tiger Pulse만 사용하고 새 이벤트나
debug SRS 화면을 추가하지 않는다.

Internal 항목이 통과하면 exact main SHA로 Closed 전용 workflow를 명시 실행하고,
Play Console에서 처리·게시된 alpha release를 확인한 뒤 opt-in 링크와 release notes를
공유한다. 테스터용 설치 및 개인정보 안내는 BETA_INSTALL_GUIDE.md를 보낸다.

### 3.1 빌드 정보·문화 용어 표면 실기기 체크리스트 (§RELEASE-2 J13)

이 브랜치가 머지된 Internal 빌드에서만 전부 확인 가능하다 — 그 전에는 main의
기존 5개 표면(`CulturalHelpButton` 직접 호출)만 확인할 수 있다.

**사전**: 업로드한 SHA로 기대 vC를 구한다 —
`git rev-list --count <업로드 SHA>`. 앱 설정 → Über(About) 행이
"Version 2.0.8 (vC) · sha"(짧은 SHA)로 그 vC·SHA와 일치하는지 확인한다 —
불일치하면 구버전이 설치된 것이니 재설치 후 다시 확인한다. About 행을 길게
눌러 정보가 클립보드에 복사되고 확인 알림이 뜨는지도 함께 본다.

**Kulturhinweise zurücksetzen**: 설정 → "Kulturhinweise zurücksetzen"을 탭한다.

**표면 8+3** (각 화면·위젯·termId로 고정 — 행 번호가 아니라 이 목록으로
추적한다):

| # | 화면 | 위젯 | termId |
|---|---|---|---|
| ① | Gye 탭 헤더 | `CulturalHelpButton` | `gye` |
| ② | Hanok 탭 헤더 | `CulturalHelpButton` | `hanok` |
| ③ | Heute "Deine Hanok" 단계 | `SoriTerm` + 퀘스트 행 보조줄 | 단계별(`hanokStageGlossaryTermId`) |
| ④ | 도장첩 | `CulturalHelpButton` + 본문 `SoriTerm.span` | `dojangcheop` + `dancheong` |
| ⑤ | Wortpakete AppBar 도장 아이콘(길게 누름) | `showCulturalTermSheetForId` | `dojangcheop` |
| ⑥ | 보자기 | `?` + 용어줄 | `bojagi` |
| ⑦ | 마당 | `?` · 완료 퀘스트 장식 탭(퀘스트 0이면 "해당 없음") | 장식별 |
| ⑧ | 한옥 지도 | `?` + 장소 목록 용어 | `hanok` |
| 추가 | 사랑방 | `?` | `sarangbang` |
| 추가 | 가구 배치 | `?` | `sarangbang` |
| 추가 | 퀘스트 목록 | 용어줄 | 퀘스트별 |

**기대**: `?` 버튼은 48dp 탭 영역. 탭하면 즉시 바텀시트(한글·한자·발음·뜻·문화
노트)가 뜬다. DE↔EN 전환 시 시트 내용이 갱신된다. 리셋 후 실내 첫 방문에서
`CulturalObjectHint`가 1회만 다시 뜬다.

**실패 시 기록**: 화면 · vC · SHA · 글자 크기(%) · 기기 모델.

## 4. 14일 Closed Testing 배정

### 4.1 최소 인원과 분담

| 그룹 | 최소 인원 | 맡은 확인 |
|---|---:|---|
| 새 계정 또는 새 앱 데이터 | 4 | 첫 팩의 전체 Learn, Quiz/Boss, 70% clear, 다음 팩 unlock |
| 기존 설치 위 업데이트 | 2 | 업데이트 전 데이터를 보존한 뒤 재실행과 pack progress 유지 |
| 기기·접근성 매트릭스 | 나머지 | Android 버전·화면 크기·130–150% 글자·회전·분할 화면 |

한 tester가 둘 이상의 조건을 맡을 수 있지만, 적용 대상 계정은 12명 이상이 14일
연속 opt-in하고 실제 핵심 흐름을 완료해야 한다. roster에는 계정 종류, 기기,
Android 버전, 담당 조건과 함께
**invited / opted-in / core-flow-complete / update-preservation-complete /
device-matrix-complete** 상태만 최소한으로 기록한다. 이름, 이메일, 학습 답안은 roster에
넣지 않는다.

### 4.2 모두가 하는 핵심 팩 흐름

1. 첫 사용 가능한 pack에서 모든 Learn 카드의 앞·뒷면을 본다.
2. Boss 단어도 assessment 전에 Learn에서 의도적으로 노출됐는지 확인한다.
3. Quiz와 Boss가 Learn 순서를 그대로 반복하지 않는지 확인한다.
4. Boss 70% clear, 결과 문구, 다음 pack unlock을 확인한다.
5. 앱 재실행 후 완료와 unlock이 유지되는지 확인한다.

### 4.3 오답과 선택형 회상

- 오답 뒤 재시도, XP, 완료 흐름은 정상이어야 한다.
- 단발 오답은 Hard Words CTA를 만들지 않는다. 기존 hard/frequent 기준에 닿은 반복
  오답에서만 어려운 단어 연습 CTA가 자연스럽게 보일 수 있다.
- raw SRS 전이는 공개 beta에서 보지 않는다. ledger regression tests가 정본이다.
- 선택형 타이핑 회상은 사용 여부, 힌트/정답 보기의 이해도, 진도 압박이 없는지를
  확인한다. 건너뛰어도 pack 결과와 unlock은 변하지 않아야 한다.

## 5. 관측, 피드백, 매일 트리아지

### 5.1 수집 범위

기존 opt-in Analytics의 pack_completed/quiz_completed, Crashlytics, 결과 화면의
구조화된 Tiger Pulse feedback만 본다. 새 행동 분석 이벤트를 추가하지 않는다.

테스터에게 자유 텍스트에 개인정보, 연락처, 계정 식별자, 한국어 학습 답안을 넣지
말라고 안내한다. 스크린샷은 필요한 경우 개인정보와 답안을 가린다.

### 5.2 우선순위

| 등급 | 정의 | 조치 |
|---|---|---|
| P0 | 크래시, 데이터 손실/손상, 잘못된 SRS positive credit, clear/unlock 회귀, 진행 불가 | 즉시 rollout 중단, hotfix |
| P1 | 정상 학습 흐름 차단, 오도하는 결과 문구, 핵심 음성·입력·피드백 실패 | 수정 후 관련 학습 회귀와 전체 게이트 재실행 |
| P2 | 비차단 UI, 카피, 선호도 문제 | 다음 Phase 후보로만 기록 |

매일 feedback과 Crashlytics를 분류하고, 같은 문제의 재현 단계, 영향 기기, release
commit을 한 줄로 남긴다. P0 또는 P1을 수정한 후보는 §2부터 다시 검증한다. 14일
동안 기능 범위를 넓히지 않는다.

## 6. 종료 판단

Closed Testing 종료일에 아래가 모두 참일 때만 Phase 5를 닫는다.

- [ ] P0 미해결 0
- [ ] P1 미해결 0
- [ ] 적용 대상이면 12명 이상이 14일 연속 opt-in했고, 핵심 pack 흐름을 완료함
- [ ] 새 계정 또는 새 앱 데이터 핵심 흐름 완료 4명 이상
- [ ] 기존 설치 업데이트 보존 완료 2명 이상
- [ ] 나머지 배정의 Android 버전·화면 크기·130–150% 글자·회전·분할 화면 매트릭스가 완료됨
- [ ] 동의 범위의 Crashlytics에 새 학습 흐름 크래시가 없음
- [ ] tester feedback이 P0/P1/P2로 분류됨
- [ ] release commit, versionCode, AAB SHA, 기간, 결과가 PR/릴리스 증거와
  AGENTS.md의 진행 체크리스트에 반영됨(`docs/SESSION_LOG.md`에는 신규 기록 금지)

14일 결과를 본 뒤에만 Learning Phase 6을 계획한다. 회상 CTA의 사용성, 오답 패턴,
tester 피드백이 충분할 때만 active recall의 빈도나 스케줄을 논의한다. Boss를
독립 recall 증거로 승격하지 않는다.

## 7. 범위 밖

- active recall 의무화 또는 required typing gate
- SRS scheduling redesign
- global LearningAttempt 모델 또는 migration
- 새 행동 분석 이벤트
- UI-overhaul Phase 4, texture work, iOS release

**작성:** 2026-08-14 · **커밋/푸시:** Jin의 별도 명시 요청이 있을 때만
