# 기술 인계서 — Hangul Sori 앱 전면 개선 웨이브 (2026-08-27)

> 근거자료: (1) 5개 체크아웃 read-only 수집 원자료 494줄(`handoff-raw.md`, 2026-08-27 수집 — 이하 "원자료") (2) 마스터 플랜 `C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-fizzy-marshmallow.md`(59개 지시서 항목 1:1 매핑, 6웨이브 로드맵). 모든 SHA·카운트·경로는 원자료 또는 실제 파일 확인에서 나온 값이며, 추정/서술적 내용은 그때그때 "추정"·"확인 필요"로 명시했다.
> 원본 지시서: `docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md` (59개 항목, 현재 main에 untracked 상태로 존재 — 아래 9절 참고)

---

## 1. 한 줄 요약 + 지금 당장 할 일

**main은 W1·Jin13건·W2·W3·W3.5가 전부 병합된 상태**(HEAD `8faae14f`, origin과 동기, ci 리모트는 10커밋 뒤처짐 — 전부 온보딩 리디자인/골든 커밋이고 웨이브 작업 아님). **W4(진행·복습 시스템)는 별도 워크트리 `C:\dev\hangulsori\ko_lernen_app_w4`(branch `feat/w4-progress-review`)에서 18태스크 중 8개 완료**(T1-T8, HEAD `a07b1d5f`) — Task 8은 컨트롤러가 발견한 회귀 테스트 실패를 근본원인까지 규명해 수정하고 전체 스위트로 재검증까지 마쳤다(회귀 수정 커밋 `a07b1d5f`, 상세는 4절). **지금 당장 할 일: `ko_lernen_app_w4`에서 Task 9부터 이어서 진행할 것** — 파일 교집합 순차 규칙(`storage_service.dart` T7→10→15→18, `scenario_player_screen.dart` T8→10, arb 파일 T2→5→12→16→17, `main.dart` T12→17)은 계속 적용된다. 브랜치는 아직 **main에 미병합**이니 이 상태를 병합 가능으로 착각하지 말 것(4절 참고). W5 플랜 문서는 아직 존재하지 않는다 — W4 잔여분을 끝낸 뒤 반드시 새로 작성해야 하며, W3 플랜 말미의 "W5 필수 이행 목록(계약)" 6항목을 그대로 흡수해야 한다(5절).

---

## 2. 현재 상태 표

5개 경로는 전부 하나의 `.git`을 공유하는 워크트리(원격 2개: `origin`=GitHub 공개, `ci`=CI 전용 미러).

| 경로 | 브랜치 | HEAD | 머지 여부 | Working tree |
|---|---|---|---|---|
| `C:\dev\hangulsori\ko_lernen_app` (메인) | `main` | `8faae14f` "chore(graphify): refresh graph after onboarding CI fixes" | — (기준 브랜치) | **dirty** — 웨이브 무관 자산/문서 다수(하단 참고), graphify-out 제외 |
| `C:\dev\hangulsori\ko_lernen_app_w2` | `feat/w2-performance` | `9f55341d` "fix(perf): W2 정리 — 미청취 future 가드·markReady finally·종횡비 메모 2엔트리·문서 정정" | ✅ main에 병합(`2ac96dfb`) | dirty는 `graphify-out/**`뿐(7 modified + ~127 untracked AST 캐시) — 실작업 파일 0 |
| `C:\dev\hangulsori\ko_lernen_app_w3` | `feat/w3-global-systems` | `4a2ac0a4` "fix(a11y): 칩 시맨틱 정규화·하트 상태 안내·이전 카드 대체수단·인디케이터 정지 동작" | ✅ main에 병합(`51c8fffb`) | **dirty** — `lib/screens/vocab_pack_screen.dart` 수정(18+/8-) + `test/vocab_pack_narrow_viewport_header_test.dart` 신규(146줄). **목적/작성자 불명 — 머지 후 잔여 WIP으로 추정, 다음 세션이 diff 확인 후 커밋할지 폐기할지 판단 필요**(9절) |
| `C:\dev\hangulsori\ko_lernen_app_w35` | `fix/w35-hardening` | `45b170aa` "fix(tts): unavailable 배너를 해석 실패로 한정 — 재생 단계 실패 오표시 제거" | ✅ main에 병합(`9b92973d`) | **dirty** — `.superpowers/sdd/` 아래 미추적 원장류 3개(8절에서 취급, graphify 잡음 전혀 없음) |
| `C:\dev\hangulsori\ko_lernen_app_w4` | `feat/w4-progress-review` | `a07b1d5f` "fix(course-mission-navigation): activeScenarioCheckpointContext 예외 안전망 + 콜드 카탈로그 로드 고아 테스트 수정 (T8 후속)" | ❌ **미병합** | dirty는 `graphify-out/**`뿐(11 modified + ~59 untracked) — 실작업 파일 0 |

**리모트 동기 상태**(로컬 캐시 기준, `git fetch` 미실행): `origin/main` = 로컬 `main`과 완전히 동일(`8faae14f`). `ci/main`은 `9b92973d`(W3.5 머지)에 멈춰 10커밋 뒤처짐 — 전부 온보딩 리디자인(`ea3160e1`/`87dacea8`/`d0318897`)과 골든 재기준(`f82942d1` 등) 커밋이며 **웨이브 산출물이 아니다**. `ci`를 갱신하려면 `git push ci main`.

**main의 dirty 상세**(전부 웨이브 범위 밖, 9절에서 다시 취급):
- `assets_unused/pending_review/personal_hanok_v3/` 아래 한옥 참고자산 정리 중(10개 삭제 + 21개 blueprint 신규 untracked + 3개 PNG 신규 untracked) — PR #208(`ildu-v3-canon-cleanup`, W1 병합 직전 커밋)과 연속선상의 자산 큐레이션으로 추정.
- `docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md`(원본 지시서 59개 항목, 12,713 bytes) — **아직 untracked**. 전 웨이브의 출발점인 이 문서 자체가 git에 커밋된 적이 없다.
- `docs/data/partner_rewrite_diff2.md`(48,872 bytes, untracked) — 9절 참고, 기존 `partner_rewrite_diff.md`(이미 tracked)와 별개 파일.
- `new_인보딩/` 전체 디렉터리(untracked) — 온보딩 리디자인 감사/프로토타입 번들(아트 18종, 폰트 4종, `.dc.html` 목업 3개, 오늘 날짜 폰 스크린샷 11장). **6웨이브 계획과 무관한 별도 트랙**으로 보인다(아래 3절 서두 참고).

---

## 3. 완료된 웨이브

### 콘텐츠 품질 배경 (W1을 이해하기 위한 맥락)

지시서의 어색한 문장 5건(층간소음·시아버지·절하·이모티콘·일정충돌, 지시서 2.1/2.6-2.8/2.10)은 마스터 플랜에서 "점 수정"이 아니라 **전 코퍼스 자연성 검사·교정 파이프라인**으로 격상됐다: ①`tool/audit_content_naturalness.py` 휴리스틱 프리필터 ②LLM 자연성 심사·재작성(beyond-humanizer 계약 — 한국어 정본 판정 후 DE/EN을 각각 독립 재구성, 영어를 중간 정본으로 쓰지 않음) ③Jin 배치 단위 승인 게이트 ④`tool/apply_naturalness_patch.py`로 id-키 패치 적용 + TTS 코퍼스 재생성. W1이 이 파이프라인과 시드 5건 검증 + 1차 전 코퍼스 실행을 담당했다.

이 파이프라인과 별도로(원자료에는 없는, 이 세션 발주자의 배경 설명): Jin은 한 차례 LLM이 작성한 "검수 11건" 파일을 반려한 적이 있다 — 실제 원인은 생성기 배치가 만들어낸 가짜 표제어("기억을 재배치하다" 등)와 템플릿형 문장이었다. 이후 432개 항목 토픽 전체를 원어민이 스크리닝해 **97개 결함 항목을 발견, 전부 재작성했지만 아직 적용하지 않고 Jin 자신의 LLM 파이프라인에 넘기기 위해 보존**했다. 이 산출물로 보이는 파일이 실제로 존재한다: `docs/data/partner_rewrite_diff.md`(이미 tracked) + `docs/data/partner_rewrite_batches/`(`flagged.md`, `rewrite-1~4.md` 등, 이미 tracked) — 그런데 main에는 **추가로** `docs/data/partner_rewrite_diff2.md`(untracked, 48,872 bytes)가 있다. `diff`와 `diff2`의 관계(후속 배치인지, 재작업인지)는 원자료에 없다 — **다음 세션이 두 파일을 직접 열어 확인할 것**(9절).

### W1 — 데이터·즉효 버그

| 항목 | 값 |
|---|---|
| 브랜치/워크트리 | `feat/w1-content-quickfixes` — **이미 삭제됨**(원자료 5경로에 없음) |
| main 병합 SHA | `5e98e493` "Merge W1 데이터·즉효 버그 웨이브" (+ `632e7786` "docs(plan): W1 플랜 문서 기록 보존") |
| 대응 지시서 항목(플랜 문서 자체 선언, 태스크별 검증 불가) | 2.1, 2.5-2.8, 2.10(시드), 1.5/1.9(네이밍), 1.13/1.17(테스터 아이콘 전역 스윕), 4.17(X버튼) |
| 테스트 카운트 | **미기록** |
| SDD 원장 | **소실** — `.superpowers/sdd/2026-08-26-w1-content-quickfixes/`가 원자료 5경로 어디에도 없다(워크트리 삭제 시 함께 사라진 것으로 추정). 태스크별 완료 근거가 커밋 로그 수준으로만 남아있고, 본 인계서는 그 이상을 검증할 수 없다. |

**이것이 8절 "SDD 원장 보존"이 강조하는 위험이 이미 한 번 현실화된 사례다** — W3.5·W3·W4의 원장을 이번에 놓치면 똑같은 일이 반복된다.

### Jin 확정 13건

| 항목 | 값 |
|---|---|
| main 병합 SHA | `10571b95` "Merge Jin 확정 13건 — 파트너 토픽 문장 7·표제어 현대화 6" (parents `5e98e493`, `2faef696`) |
| 내용 | Jin이 직접 승인한 수기 교정 13건(웨이브 파이프라인 산출물이 아님) — W1 직후, W2 브랜치 분기 전에 병합됨(`feat/w2-performance` 브랜치 베이스가 "60578409 = main+Jin13건 동기"로 명시) |
| 테스트 카운트 / SDD 원장 | 둘 다 미기록 |

### W2 — 성능

| 항목 | 값 |
|---|---|
| 브랜치/워크트리 | `feat/w2-performance` — `C:\dev\hangulsori\ko_lernen_app_w2`(clean, graphify 제외) |
| main 병합 SHA | `2ac96dfb` "Merge W2 성능 웨이브" |
| 스펙 | 마스터 플랜 P4(즉효 5건)/P5(구조 3건, 스플래시 아이콘 제작 포함) + 검수 보강 #7·#10·#11·#26 |
| 테스트 카운트 | 원장 마지막 명시값 **4,701 GREEN**(Task 9 시점) — Task 10(스플래시)과 정리 커밋(`9f55341d`) 이후의 최종 카운트는 원장에 없음. 병합 직전 전체 리뷰(fable)는 "Ready to merge YES, Critical/Important 0, Minor 5" → 정리 픽스 4건(`9f55341d`) 적용 후 재리뷰 clean. |
| 10태스크 요약 | T1 문서(002661a8) · T2 fail-open 양경로 검증(01d9202a) · T3 hanok 정본 재활성화 패턴 채택 + 재발 리스크(1e4c8ad5+0b2a35bc, 아래 사건 참고) · T4 scenarioStars/completedScenarios 메모이즈(96557654+5c85a91c) · T5 `_cellAspectRatio` 메모이즈(c74bf968) · T6 receipt `capture()` 재설계 — before 스냅샷 병행+openActivity 우선 await, min600/cap1500 게이트(81ba384c, **P4 5건 완주**) · T7 `_parseShard` 순수함수 분리+compute() 격리안전(ee5e0b2c) · T8 시작작업 화이트리스트 가드(4524d099) · T9 pre-runApp 병렬화(e9795377) · T10 Android12+ 스플래시 아이콘 제작+flutter_native_splash 재생성(3797431e, **10태스크 완주**) |
| Codex 충돌 사건 | 2026-08-26, Jin의 Codex 세션이 같은 체크아웃을 동시 사용 — T3 커밋이 main에 오착륙(`dcb36a03`), 체리픽(`1e4c8ad5`)+리버트(`f7e86bf8`)로 복구. **이후 전용 워크트리 규칙이 여기서 시작됨**(6절). |
| Jin 직접 에셋 커밋 | `f6949325` "그림자 없는 동영상으로 내가 작업한거임.절대 회귀하지말도록." — 배경 없는 비디오 5종 직접 커밋. origin/main 발산(Codex UIUX 2커밋)과 머지(`196a88e7`)로 정리, 매트 리포트 재생성(`ca27367d`)으로 GREEN 복구. |
| 잔여 Jin 게이트(릴리스 전, 머지 비차단) | ① Android12+ 실기기 스플래시 육안 확인 ② 콜드스타트 Before(`632e7786` 시점)/After 실측(체크리스트 `C:\dev\hangulsori\ko_lernen_app\docs\data\coldstart_benchmark.md` — 파일 존재 확인됨) ③ 비디오 에셋 2건: **tiger_choose 그림자 잔존 24.1%**, **신규 5종 규격 1920×1080**(960×960 아님, 왜곡 위험) |
| 후속 후보(별도 티켓) | reward-flow 테스트 3초 고정 딜레이→폴링 전환, pad 스크립트 mkdir 누락, 가드 정규식 느슨함, main.dart 낡은 주석 |

### W3 — 전역 시스템

| 항목 | 값 |
|---|---|
| 브랜치/워크트리 | `feat/w3-global-systems` — `C:\dev\hangulsori\ko_lernen_app_w3`(**dirty**, 2절 참고) |
| main 병합 SHA | `51c8fffb` "Merge W3 전역 시스템 웨이브" |
| 대응 지시서 항목 | 1.18(레벨알약 C1/C2), 1.24(하트/보관 분리), 2.9(전역 오디오), 4.3/4.5(음성 즉시재생), 4.16(홈 이스케이프 해치 — kkeunmari만, 잔여는 W5 계약) |
| 테스트 카운트 | **4,735 passed / 0 failed**(명시), 25커밋, 15/15 태스크 승인 완료 |

**T1-T15 요약** (전부 `ecc:flutter-reviewer` 등 전문 리뷰 Approved 후 랜딩):

| # | 내용 | 커밋 | 비고 |
|---|---|---|---|
| T1 | §15 `SoriLayout` 토큰, 전뷰포트 히어로 클램프(`heroFit` — 비율고정 히어로는 높이예산 초과시 폭을 비례축소, 0dp 붕괴 금지), `SoriStudyFrame(hero:)`, `hero_placement_guard`(위반 4화면 유예) | `c042eed2` | Critical/Important 0, 4,707 GREEN |
| T2 | §16 `SoriGaps` 8종(기존 Spacing 별칭), `spacing_literal_guard`(ceiling 181, 리뷰어가 451파일 스캔 독립 재구현으로 검증) | `28f27bf5`+`94778b6a` | 4,708 GREEN |
| T3 | §17 `SoriChromeRow`(44/48dp)·`SoriButton(loading:)`·`SoriPressable` 정본·`chrome_stack_guard` | `355bd198` | 4,710 GREEN. §19 이관 부채가 **1화면이 아니라 4화면**(chosung 4·hangul 2·legacy_vocab 2·scenario_player 2)임을 이 태스크에서 확인 — W5 §19에 반드시 반영 |
| T4 | typography `fontSize` 래칫 신설(115/15파일 실측) | `613cbc51`+`64c44439` | 지적 0, 4,711 GREEN |
| T5 | §20 거버넌스 절차 신설, **바이블 §15-§20 완성** | `4998f2e0` | 문서 전용, 컨트롤러 직접검증 |
| T6 | C1 `#6B4A7E`/C2 `#4A3D63` + `rankOf` 5·6 + `rankCount` 6 원자적 랜딩(색만 넣지 않고 서열도 동시 — 검수 보강 #8 반영) | `cb3c6ef7` | 4,711 GREEN. 골든은 **CI(Linux 3.44.0) workflow_dispatch 산출물로 재기준**(9절 — Jin 인지 필요) |
| T7 | `SoriLevelFilterBar` 신설 + smalltalk·listening 이관 + listening 시작레벨 버그 수정 | `9392f471`+`30d33fb7` | 1 fix round(스크롤스윕+hasLength(7) 하한+48dp 단언) 후 clean |
| T8 | 하트=`s.text`(먹) 무조건, 하트/북마크 일방향 분리 | `7bb964ba` | 지적 0, 4,712 GREEN |
| T9 | `_Stamp` 4종 48dp 승격 + AppBar 북마크 중복 제거 | `c95910d5`+`ddc31b25` | 1 fix round(북마크 Semantics **value**로 저장상태 안내 DE/EN + chosung_quiz 앵커 스포트라이트 커버리지 신설) 후 clean, 4,716 GREEN |
| T10 | `SoriHomeAction`(확인시트 dismissible) + kkeunmari 배선 | `a30c863a` | 4,714 GREEN |
| T11+12 | `speakable.dart` 신설(`SoriSpeech`/`SoriSpeakable`/`SoriSpeechIndicator`/`ContentSpeechController`) + content_feed 인디케이터 슬롯·더블탭 재스코프 | `7d38c43a`(RED)→`1270c1c0`(GREEN) | 4,721/0. 이후 1 fix round(`a680e43c` — in-flight 맵 단일화 + deactivate/didPushNext 프레임지연 중앙화 + 인디케이터 48dp) 후 4,729/0 |
| T13 | 진입/전환 자동재생 수명주기(`deactivate`/`didPushNext`) | `0a661f7a`+`bff5fd4a` | 1 fix round(Skip 경로 자동재생 누락 수정) 후 clean, 8/8 |
| T14 | `FeedPhysics` 이중경로 신설(legacy 기본, `snap`은 W5 게이트 후) | `f1bb700d`+`a13e577a` | 1 fix round(`_snapCtrl` 리셋+재진입 가드) 후 clean, 14/14 |
| T15 | 위치보존(인덱스 아닌 **Grammar.id 동일성** 기반) + 아래 플링=이전 카드 | `45476ab4` | Approved |
| 문서정리 | 낡은 "4단계/4색" 주석 일괄 정리(hanok_tokens.dart 등 5파일) | `3ca70038` | 래칫 무이동(14/14) |

### W3 종료 시 전문 감사가 발견한 것 — 가장 중요한 교훈

W3 15태스크는 각각 태스크 단위 리뷰(`ecc:flutter-reviewer`)를 전부 통과했다. 그런데 **웨이브 전체를 대상으로 한 `ecc:silent-failure-hunter` 감사**가 태스크 단위 리뷰가 전부 놓친 문제를 찾아냈다 — 이것이 W3.5가 따로 필요했던 이유이자, 이번 세션이 다음 세션에 전달하는 가장 중요한 작업 방법론적 교훈이다: **개별 태스크 리뷰가 전부 green이어도 브랜치 전체를 다시 훑는 감사가 필요하다.**

발견 사항(W3 도입 결함이 아니라 **전부 기존 경로** — 그래서 W3 머지는 차단하지 않고 별도 하드닝 웨이브 W3.5로 분리):

- **[Critical] `tts_service.dart:744-761`** — 로컬 캐시 읽기가 `TimeoutException`만 잡고 다른 I/O 예외는 3단 폴백 전체를 우회 + `errorReporter` 미발화 → **Jin이 신고한 "소리 안 나와"의 실제 재현 경로.**
- **[Critical] `vocab_pack_screen.dart:738-835`** — `_finish()`가 try/catch·await 없이 fire-and-forget → 예외 시 XP/클리어/도장 미기록 + 결과화면 미이동 + 흔적 0. **"진행이 안 저장된다"의 재현 경로.**
- **[Critical] `review_session_screen.dart:148-178`** — `_load()`가 로그 없이 전부 삼키고 **축하 빈 상태(magpie_celebrate)를 표시** → 로드 실패와 "정말 복습할 게 없음"이 구분 불가능. 형제 화면(grammar/vocab_pack)은 이미 AppError+재시도 패턴을 갖고 있었다.
- **[Important]** culture_notes_service 미청취 비동기 에러, grammar 체크포인트 시트 dispose 미가드(중복 제출 가능), vocab_pack 850ms `Future.delayed` 미취소, 전역 fire-and-forget 저장 쓰기 다수.
- **[최대 레버리지]** `main.dart`에 전역 에러 훅(`runZonedGuarded`/`FlutterError.onError`/`PlatformDispatcher.onError`)이 없었다 — `DiagnosticsService`+Crashlytics sink는 이미 존재하는데 연결이 안 돼 있었다. 한 줄 연결로 위 다수가 최소한 **관측**은 가능해진다.
- **[By-design 확인, 고치지 말 것]** receipt fail-open 2곳, TTS best-effort 4곳은 의도된 설계.

같은 시기 `ecc:a11y-architect` 감사는 **W3 자신이 도입한 접근성 결함 5건**을 찾았다(태스크 단위 리뷰가 놓친 것들, W3.5에서 수정): ①북마크 Semantics 라벨이 저장 상태를 반영하지 않음(구 AppBar 버튼도 동일 결함이었음) ②`SoriSpeechIndicator`의 `SizedBox` 40×40이 `OverflowBox` 44를 감싸 실제 터치 타깃이 40으로 축소(a11y 최소치 미달) ③`SoriPressable`이 `onLongPress` 전용이라 키보드로 활성화 불가(포커스 트랩) ④smalltalk가 제스처 전용 내비게이션(WCAG 2.5.1 위반) ⑤`chrome_row` 히트박스가 44dp뿐(터치 타깃 최소 48dp 미달).

### W3.5 — 하드닝

| 항목 | 값 |
|---|---|
| 브랜치/워크트리 | `fix/w35-hardening` — `C:\dev\hangulsori\ko_lernen_app_w35`(**dirty**, 3개 미추적 원장 파일만 — 8절) |
| main 병합 SHA | `9b92973d` "Merge W3.5 하드닝 웨이브" |
| SDD 원장 | `.superpowers/sdd/` 아래 전용 워크스페이스 디렉터리가 **없다** — `progress.md` 자체가 존재하지 않고, 3개 loose 파일(`w35-execution-report.md`/`w35-fix-review.diff`/`w35-review.diff`)만 존재. 아래 8절 참고 — **내용은 수집되지 않았다, 지금 워크트리에서 직접 열어야 한다.** |
| 실행 6건 | TTS 로컬캐시 폴백 우회 수정 + 비-Blocked 예외 보고(단, **배너는 "해석 실패"로 한정** — 재생 단계 오류를 "온라인이신가요?"로 오표시하던 것도 같이 고침) / 전역 에러 훅 무조건 설치(Firebase 초기화 전에도 안전) / `SoriPressable` 키보드 활성화 / smalltalk `customSemanticsActions`(WCAG 2.5.1) / `chrome_row` 히트박스 44→48(토큰화) / speakable.dart의 ⚠️ 주석을 "확정 사실" 서술에서 "관측 증상" 서술로 완화(원인 규명은 별도 조사로 이월) |
| 테스트 카운트 | **5,065 GREEN** |
| W4 머지 후 이월분 | 5건, 아래 5절 참고(vocab_pack `_finish()` 등) — **아직 아무것도 처리되지 않음** |

---

## 4. 진행 중: W4 (진행·복습 시스템)

워크트리 `C:\dev\hangulsori\ko_lernen_app_w4`, 브랜치 `feat/w4-progress-review`, 베이스 `291d3005`(main after W1/W2/W3/Jin13건 + Codex 온보딩). 플랜: `C:\dev\hangulsori\ko_lernen_app_w4\docs\superpowers\plans\2026-08-27-w4-progress-review.md`(18태스크). 사전검수 4건 전부 NEEDS-CHANGE 없이 수정 확정(`c79f98c7`).

**절대 위반 금지 계약 4건**(플랜 사전검수에서 확정, 7절에서 다시 취급): LearnSessionQueue `servedPosition` 동결 / `recordScenarioCheckpoint` 자가유도 금지 / `/review` 라우트+고정 테스트 15곳 / 신규 저장 키는 백업 화이트리스트 필수.

### 완료(커밋됨) — Task 1-7

| # | 내용 | 커밋 | 실제 변경 | 리뷰/카운트 |
|---|---|---|---|---|
| T1 | `LearnSessionQueue` `_servedIds`+`currentIsRepeat` 게터 | `7f259706` | 게터 추가만 — `servedPosition` 수식·큐 조작 순서는 **diff 0 deletions로 바이트 동일 실증**됨 | Approved, 16/16 신규, 전체 5,061/0 |
| T2 | 재출제 카운터 "3/9 · +N Wdh." 병기 + dispose 진행 영속화 | `6e20f021` | 검수#21 대로 **단일 칩 병기**(별도 칩 아님), dispose 시 영속화가 멱등·단조(vokSeenIds∩pack 경로까지 리뷰어가 추적) | Approved, 5,062/0 |
| T3 | 결과화면 뒤로가기 복구 | `721505c0`+`270adfce` | AppBar leading 복구. **설계 룰링**: CTA 분기를 `courseContext?pop:popUntil`에서 **무조건 `pop()`으로 단순화**(pushReplacementNamed가 스택 위치를 1:1 보존하므로 모든 진입경로에 안전 — 리뷰어가 진입점 전부 grep 재검증) | clean after 1 fix round |
| T4 | 표준팩 소급 복구(팩 목록 열람 시 재동기화) | `55d6e815`+`dc95f2d0` | 리뷰에서 단조성 갭 발견(vokSeenIds 감소 가능 경로 존재) → `!=`→`>` 클램프 + 5청크 동시성 제한 + 개별 실패 격리로 수정 | Approved+fix, 5,073/0 |
| T5 | 커스텀팩 `learnedWordCount`+`addVokSeen` 누락 보완 + 책장 "n von m" | `dc1fc1f0` | quiz/matching/typing 3모드 보완, **P1 단어팩 워크스트림 종료**. ⚠ 제품 시맨틱 차이 발생(9절) | Approved, **P1 종료** |
| T6 | `activeScenarioCheckpointContext` 헬퍼(course_mission_navigation.dart) | `a62c6556` | 서비스 파일(`course_mastery_service.dart`) 자체는 **바이트 동일**(계약 유지) — 헬퍼가 호출 지점에서 컨텍스트를 부착 | Approved, 5,076/0 |
| T7 | `setScenarioStars` 0성 최초 기록 허용 | `4e9dea5f` | 첫 기록은 0성도 허용, 재시도는 단조(2→0 거부) — 리뷰어가 5개 전이 전수 추적 + 소비처 4곳 전부 `?? 0` 폴백이라 동작변화 0 확인 | Approved, 5,078/0 |

### Task 8 — 완료(검증 완료, 2커밋)

플랜 상 Task 8은 `scenario_player_screen.dart`의 `_load()`/`_persistResult()`에 courseContext 자동 유도를 배선하는 것이다. **컨트롤러가 직접 확인 — Task 8은 완료됐다.** 2커밋에 걸쳐 있고, 브랜치 HEAD는 `aa5914bf`가 아니라 `a07b1d5f`다(2절):
- `aa5914bf` "feat(scenario-player): 활성 체크포인트 courseContext 자동 유도 배선 — 리스트/추천/반복 진입 전부 (지시서 4.15)" — 원 구현. `lib/screens/scenario_player_screen.dart`(계획대로) + `lib/services/course_mission_navigation.dart`(+2, T6 재손질) + `lib/services/course_progress_service.dart`(+20) + 테스트 8개(`course_mission_navigation_test.dart`, `dedicated_feedback_route_test.dart`, `scenario_can_do_result_flow_test.dart`, `scenario_mission_context_test.dart`, `scenario_onboarding_completion_test.dart`, `scenario_player_ui_test.dart`, `scenario_srs_persistence_flow_test.dart`, `widgets/settings_screen_test.dart`)를 건드린다.
- `a07b1d5f` "fix(course-mission-navigation): activeScenarioCheckpointContext 예외 안전망 + 콜드 카탈로그 로드 고아 테스트 수정 (T8 후속)" — 회귀 수정. 아래 세 갈래.

이전 인계서 작성 시점엔 컨트롤러의 자체 전체 스위트 실행에서 `scenario_can_do_result_flow_test.dart`의 테스트 `"saves once, then shows the persisted can-do before returning"`가 실패한 것만 알려져 있었고, 그 수정이 디스패치는 됐지만 검증 전에 이 문서가 쓰였다. 디스패치 스코프는 ① 회귀인지 테스트 자체가 틀렸는지 정직하게 진단 ② course-context 유도 과정의 throw가 시나리오 플레이를 중단시키지 않도록 fail-soft 컨테인 ③ `test/screen_smoke_test.dart`의 `resetForTesting()` 시딩 감사 — 세 가지였다. 컨트롤러가 직접 확인한 결과, 전부 아래처럼 마무리됐다:

**① 근본원인 — 진짜 테스트 인프라 함정이었다, 단언은 하나도 안 바꿨다.** `scenario_can_do_result_flow_test.dart`의 **첫 번째** 테스트(`"system back delegates..."`)가 형제 테스트에는 이미 있던 `CurriculumCatalog.load()`의 `runAsync` 프리웜을 빠뜨리고 있었다. Task 8이 `ScenarioPlayerScreen`을 여는 모든 경로에 courseContext 유도를 무조건 배선하면서, 이 첫 테스트가 콜드 `compute()` 기반 카탈로그 로드를 고아로 남기기 시작했다(그 체인을 await하지 않으므로 테스트 자체는 계속 통과) — `CurriculumCatalog._cache`가 null인 채로 남고, **다음** 테스트가 그 고아 프로세스와 경합해 교착한다. 수정은 첫 테스트에 동일한 `runAsync` 프리웜을 추가한 것뿐. 이것이 예전에 관측됐던 "스위트가 ~5087개 근처까지 도달한 뒤 summary line 없이 멈춘다"는 증상의 실제 원인이었다(7절 함정 목록에 일반화해 등재).
**② fail-soft 컨테인 — 구현됨.** `activeScenarioCheckpointContext` 호출 지점을 try/catch로 감쌌다 — 손상된 로컬 스냅샷 JSON 등으로 `FormatException`이 던져져도 컨텍스트가 `null`로 강등될 뿐 시나리오 재생은 계속된다. 회귀 가드 테스트 추가됨.
**③ `test/screen_smoke_test.dart` 감사 — 조사 후 "수정 불요"로 종결.** 고립 실행·전체 스위트 내 실행 양쪽 다 24/24 클린으로 실측됨 — 실제로는 문제가 없었다. 근거는 Task 8 리포트에 있다.

`course_progress_service.dart`의 +20줄(원래 Task 8 Files 블록에 없어 이전 인계서가 의문으로 남겼던 부분)도 이제 설명된다: `resetForTesting()` 테스트 시드 헬퍼일 뿐이고 프로덕션 메서드는 무변경 — `storage_service.dart`를 포함해 이미 ~10개 서비스에 있는 기존 패턴과 동일하다. `lib/services/course_mastery_service.dart`는 여전히 **바이트 동일**(T6에서 고정된 계약 유지, 7절 계약 2번 참고).

**컨트롤러가 브랜치 위에서 직접 돌린 전체 스위트: `5,089 passed / 0 failed / 14 skipped`("All tests passed!"), `flutter analyze`도 clean.** `widgets/settings_screen_test.dart`가 왜 `aa5914bf`에 포함됐는지는 여전히 원자료에 명시적 언급이 없지만, 전체 스위트가 GREEN으로 재확인됐으므로 더 이상 막힌 질문은 아니다.

### 미커밋 — Task 9-18

| # | 내용 | 대상 파일 | 상태 |
|---|---|---|---|
| T9 | `scenarios_list_screen.dart` `onClosed` 갱신(0/2→1/2 즉시 반영) | `build()`, `_LessonPathHeader`, `_LevelSection`, `_OpenScenarioCard`, `_NextRecommended` | **미착수** |
| T10 | SRS 일별 학습 원장(`kl_study_log_v1_<dateIso>`) | `storage_service.dart`(`srsReview`), `scenario_player_screen.dart`(`recordScenarioFailedQuestSrs`), 신규 `test/study_log_test.dart` | **미착수** — 검수 HIGH#2 설계 구속: 일자별 키(단일 JSON맵 금지), `srsReview` 핫패스는 오늘 키(≤500)만 R/W, 60일 프루닝은 앱시작/달력열람 시, **명시적 판정만 기록**(시나리오 자동오답 제외) |
| T11 | `ReviewDeckService.deckForIds` | `review_deck_service.dart` | **미착수** |
| T12 | `ReviewHubScreen` 신설 + `/review/hub` 라우트 | 신규 `review_hub_screen.dart`, `main.dart`, `sori_activity_catalog.dart`, arb de/en | **미착수** — 검수 HIGH#14: `/review`는 플레이어로 유지(라우트 고정 테스트 15곳), 허브는 반드시 `/review/hub`로 분리 |
| T13 | `buildGrammarChoiceRound`에 `allowedTargetIds` 파라미터 | `grammar_choice_quiz.dart` | **미착수** |
| T14 | `grammar_study_plan.dart` 모델 + `grammar_plan_service.dart` | 신규 2파일 + 신규 테스트 2파일 | **미착수** |
| T15 | `storage_service.dart`에 `kl_gram_plan_v1` | grammar 섹션 | **미착수** — 검수 보강 #24: 일차 카운트 금지, **일자별 서빙된 id 목록**으로 저장(CSV 재배치 면역) |
| T16 | `grammar_screen.dart` 플랜 모드(첫 진입 시트+일 헤더+완료 시트) | `_load()`, `_showFilterSheet`, filter chrome, arb de/en | **미착수** — T17과 함께여야 함(아래) |
| T17 | `grammar_choice_quiz_screen.dart` 재구축(531줄) + `/grammar_choice_quiz` 라우트 등록 | 전체 화면 + `main.dart` | **미착수** — **T16이 호출하는 라우트를 T17이 등록한다. T17 없이 웨이브를 끝내면 런타임 예외** — 플랜에 명시된 하드 제약 |
| T18 | 클라우드 백업 화이트리스트 + 학습데이터 내보내기 + 가드 테스트 | `cloud_sync.dart`(`_restorableAccountFields`/`buildBackupPayload`/`_applyRestorePayload`), `learning_data_export_service.dart`(`buildPackage`), 신규 `test/backup_new_storage_keys_guard_test.dart` | **미착수** — 검수 HIGH#3과 직결: `kl_study_log_*`·`kl_gram_plan_v1`을 반드시 T10/T15와 **같은 PR에서** 등록해야 함(별도로 미루면 신규 키가 백업에서 누락된 채로 랜딩) |

**요약: T1-8 커밋·검증 완료, T9 및 T10-18(10개) 미착수(8/18).** 파일 교집합 순차 규칙(플랜 사전검수 확정): `storage_service.dart` T7→10→15→18, `scenario_player_screen.dart` T8→10, arb 파일 T2→5→12→16→17, `main.dart` T12→17.

**queued(미반영) 소소 수정 2건**: T2 관련 카운터 라벨 "+1만 검증, +2 누적 미검증" 테스트 보강 / T5 관련 `bookshelf_screen.dart:351,374`가 같은 build에서 `learnedWordCount`를 2회 호출(지역변수 호이스트 필요, 15개 commit 어디에도 반영 안 됨).

---

## 5. 남은 일 (우선순위 순)

### 1순위 — W4 잔여

Task 8은 완료·검증됐다(4절). **다음: T9** → T10 → T11 → T12 → T13 → T14 → T15 → T16+T17(**반드시 함께**) → T18. 리뷰 우선순위: `ecc:flutter-reviewer`가 기본, 접근성 표면(T9/T12/T16)은 `ecc:a11y-architect` 병행, 저장/비동기 경로(T10/T15/T18)는 `ecc:silent-failure-hunter` 병행(6절).

### 2순위 — W3.5에서 W4 머지 후로 이월된 5건

W4 progress.md에 "W4 머지 후 처리할 이월 5건"으로 명시. 원 감사(3절 "전문 감사")의 파일:줄 근거를 같이 적는다:

1. **`lib/screens/vocab_pack_screen.dart:738-835`** — `_finish()`가 try/catch·await 없는 fire-and-forget. 증상: XP/클리어/도장 미기록, 결과화면 미이동, 흔적 0.
2. **`lib/screens/review_session_screen.dart:148-178`** — `_load()`가 실패를 전부 삼키고 축하 빈 상태(magpie_celebrate) 표시. 증상: 로드 실패와 "복습 없음"이 구분 불가.
3. **culture_notes_service** — 미청취 비동기 에러(같은 웨이브의 receipt 서비스에 정답 패턴 존재, 그대로 복제 가능).
4. **grammar 체크포인트 시트** — dispose 미가드로 중복 제출 가능.
5. **vocab_pack 850ms `Future.delayed`** — 미취소.

이 5건은 W4 완료 후 착수해야 한다(W4와 파일이 겹칠 위험 — 특히 1번과 T2/T5, 2번은 T12 ReviewHub와 인접).

### 3순위 — W5 (플랜 문서부터 새로 써야 함)

**`docs/superpowers/plans/` 어디에도 W5 플랜이 없다** — main/w3/w4 트리를 전수 확인(`*w5*` 검색, graphify-out·.git 제외)했고 빌드 캐시 해시 안의 우연한 "w5" 문자열 외에는 아무것도 없었다. 다음 세션이 `superpowers:writing-plans`로 `docs/superpowers/plans/2026-08-27-w5-screen-surgery.md`(가칭) 같은 파일을 새로 써야 한다.

**W5 플랜은 아래를 반드시 명시 태스크로 포함해야 한다** — W3 플랜 말미 `## W5 필수 이행 목록 (계약)`의 원문 그대로(`C:\dev\hangulsori\ko_lernen_app_w3\docs\superpowers\plans\2026-08-27-w3-global-systems.md` 2284-2293줄, 이미 main에 병합됨):

> 1. **레벨 필터바 잔여 이관 + `level_filter_guard`** — 13곳 중 W3에서 이관한 2곳(smalltalk/listening)을 뺀 나머지 11곳(chosung_quiz/cloze/speed_match/grammar 등) 전부를 `SoriLevelFilterBar`로 이관. `level_filter_guard`는 이관이 대부분 끝나야 의미가 있어 W3엔 만들지 않았다 — W5에서 이관과 함께(또는 직후) 반드시 신설.
> 2. **오디오 표면 잔여 롤아웃** — speakable.dart 7단계 롤아웃 중 W3에서 배선한 1곳(review_session)을 뺀 나머지 6개 플립 표면(vocab_pack/legacy_vocab/custom_pack_play/hangul/grammar/smalltalk) + 비플립 표면(quest/cloze/scenario) 전체.
> 3. **`/review` onPrevious 배선(재출제 동적 덱 검증 포함)** — grammar_screen과 같은 "아래 플링=이전 카드"를 review_session_screen.dart에도 배선. **단 review 덱은 grammar와 달리 SRS 재출제로 세션 도중 동적 재구성**된다(오답 카드가 뒤로 재삽입돼 순서가 바뀜) — grammar_screen.dart의 "현재 id를 새 목록에서 다시 찾는" 패턴을 그대로 복붙하면 위험. W5 태스크는 이 재출제 상호작용을 먼저 재현·검증한 뒤 구현 방식을 정한다.
> 4. **`FeedPhysics.snap` 기본 전환 + legacy 삭제** — 실기기 QA 게이트(콜드스타트·10분 세션 ANR 0·4방향 손맛) 통과 후 화면 단위로 `physics: FeedPhysics.snap`을 기본값으로 승격하고, legacy 분기를 삭제하는 별도 PR.
> 5. **홈 이스케이프 해치 잔여 화면** — kkeunmari 외 전체. `scenario_player_screen.dart`처럼 이미 자체 `leading`이 있는 화면은 `SoriHomeAction`으로 대체할지 병존시킬지 화면별로 판정해 기록한다.
> 6. **`hero_placement_guard` 유예 4화면의 실제 히어로 제거(§19)** — chosung_quiz_screen/hangul_screen/legacy_vocab_screen/kkeunmari_screen에서 `HanokHeader`를 제거하고 그랜드파더 allowlist를 4→0으로 좁힌다.

**교차 참조(위 계약 밖이지만 W5 §19 태스크가 반드시 반영해야 하는 것)**: §19 이관 부채는 실제로 **4화면**(chosung 4·hangul 2·legacy_vocab 2·scenario_player 2)이다(항목 6은 kkeunmari만 언급하지만 scenario_player_screen.dart도 해당). `study_library_screen.dart`의 3-Wrap 칩블록 부채(W3↔main 머지 중 발견, `chipWrapAllowlist`에 그랜드파더로 등재)도 "W5 §19 이행 목록 항목 6"에 이미 편입하기로 룰링됨(7절 ratchet 표 참고).

**흥미로운 교차점**: 검수 보강 HIGH#9("hoerverstehen만 즉시판정")가 W5 산출물로 명시한 고정 테스트 4개 중 하나가 `scenario_can_do_result_flow_test.dart`다 — **바로 Task 8이 건드린 그 파일.** W5에서 이 테스트를 다시 만질 계획이 이미 있다 — Task 8의 회귀 수정(`a07b1d5f`, 4절)은 이 파일의 단언을 하나도 바꾸지 않고 테스트 인프라 결함(runAsync 프리웜 누락)만 고쳤으므로, 임시방편이 남지 않았고 W5 재작업과 충돌하지 않는다.

**마스터 플랜이 정의한 W5의 나머지 스코프**(W3 계약과 별개, 추가): 퀘스트 피드백 전체(SoriWordTile 아이콘 제거, hoerverstehen 즉시판정 통일, 정답 이펙트, 스페이싱), Diktat 재설계(promptKo, 재생 UI), 4.4(시나리오 Grammatik 복수카드)/4.9(작문 힌트) 보충, Anlaut-Quiz 크롬 압축, Silben 셀 UX(색상 재설계), Aussprache 재구축(호랑이 제거+5범주 진단), 시나리오 인트로 아트 해시 크롭, Meine Wörter 허브 통합(`/my_words` — bookshelf/word_search/hard_words 흡수, 단 **라우트 자체는 삭제 금지** — 검수 HIGH#4: 8곳이 `settings.name`에 의존하므로 탭 프리셀렉트 인자를 가진 named route로 유지).

### 4순위 — W6 (Jin이 제외한 비디오 생성 항목 제외)

Jin의 지시: W5까지는 전부 진행하되 **비디오 재생성만 제외**(welcome-hero 교체/삭제+회귀가드, greet/celebrate/magpie 4종, taego-joy-duo v2) — 이 항목들은 이번 스코프에 포함하지 않는다. tiger_choose는 Jin이 이미 직접 작업 완료(그림자 잔존 24.1%만 확인 대상, 3절).

W6에서 **여전히 진행 대상인 것**: 시나리오별 이미지 웨이브(office→home→… 우선순위, 1536×1024, `ASSET_GENERATION_BIBLE` 스타일, 파일명=시나리오 id 자동인식), 오디오 게인 스윕(ADR-002 파이프라인), cloze 주제 8그룹 큐레이션(**W5 레벨바 완성 후**로 명시 게이트됨), 감사 스크립트 `tool/audit_scene_assets.py`(에셋 파일명 오타 검출).

---

## 6. 작업 방식 (그대로 이어받을 것)

**파이프라인**: 브리프 → 구현자(서브에이전트) → 전문 리뷰 → fix 라운드(보통 1회, 필요시 최대 5) → SDD 원장(`progress.md`) 기록. 구현/리뷰 프롬프트는 영어, Jin에게 보고할 때는 한국어.

**워크트리 규칙**: 웨이브마다 전용 워크트리 하나. main(원 체크아웃)은 Jin/Codex 세션 전용 — 웨이브 작업이 여기서 실행되면 안 된다. 이 규칙은 W2 중 Jin의 Codex 세션이 같은 체크아웃을 동시에 써서 커밋이 main에 오착륙한 사건(3절, `dcb36a03`) 이후 확정됐다.

**직렬화 규칙**: 워크트리 하나에서 **구현자 동시 실행 금지**(순차만) — W2에서 시작, W3에서도 "동일 워크트리 동시 쓰기 경고"(T7 fix ∥ T8 구현, 파일 교집합은 없었지만 위험 확인됨) 이후 재확인, W4 사전검수에서도 명문화(리뷰만 병행 가능). **전체 스위트 실행과 파일 편집도 절대 겹치면 안 된다** — W4 Task 1에서 무인 전체 스위트 실행 중 편집이 베이스라인을 오염시킨 사례가 실제로 발생(구현자가 자체 발견, stash로 재검증).

**래칫 규칙**: 가드 상한은 내려가기만 한다. 올리는 것은 **컨트롤러 판단만 가능**, 구현자 권한 밖. 실사례: 오버플로 수정 에이전트가 `TextOverflow.ellipsis`를 썼다가 ellipsis 래칫(상한 0)을 위반 — 다른 태스크의 전체 스위트 실행이 검출, 컨트롤러가 승인된 대안(Flexible+wrap, `settings_screen` 선례)으로 정정 지시.

**전문 리뷰 로스터**: `ecc:flutter-reviewer`(기본) / `ecc:a11y-architect`(접근성 표면) / `ecc:silent-failure-hunter`(저장·비동기 경로). 웨이브 종료 시점엔 **태스크 단위를 넘어 브랜치 전체**를 이 3종으로 다시 훑는다 — W3 종료 감사가 정확히 이 순서로 Critical 3건 + a11y 5건을 찾아냈다(3절).

**브리프/원장 위치와 재생성**: 워크스페이스는 `<워크트리>\.superpowers\sdd\<플랜파일명과 동일한 날짜-이름>\`(예: `.superpowers\sdd\2026-08-27-w4-progress-review\`) 아래 `progress.md`(웨이브 전체 원장) + `task-N-report.md`(태스크별) + `review-*.diff`. 이 워크스페이스를 만들고 브리프/리뷰 패키지를 만드는 스크립트는 superpowers 플러그인 안에 있다 — 이번 세션에서 실제 경로를 확인함(캐시된 버전 6.3.0 기준, 업데이트되면 버전 디렉터리명이 바뀔 수 있음):
```
C:\Users\vjinn\.claude\plugins\cache\claude-plugins-official\superpowers\6.3.0\skills\subagent-driven-development\scripts\sdd-workspace
C:\Users\vjinn\.claude\plugins\cache\claude-plugins-official\superpowers\6.3.0\skills\subagent-driven-development\scripts\task-brief
C:\Users\vjinn\.claude\plugins\cache\claude-plugins-official\superpowers\6.3.0\skills\subagent-driven-development\scripts\review-package
```
실무적으로는 `superpowers:subagent-driven-development` 스킬을 부르면 이 스크립트들이 알아서 호출된다 — 직접 셸에서 실행할 일은 거의 없을 것이다.

**커밋 규율**: 이번 세션에서 실제 커밋 메시지 전문을 확인함(`git log -1 --format=%B`) —
```
feat(custom-pack): learnedWordCount + addVokSeen 누락 보완(quiz/matching/typing) + 책장 진행 표시 (지시서 1.21, 검수#23)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
```
제목 줄은 `type(scope): 설명 (지시서 N.NN[, 검수#NN])` 형식으로 대응 지시서/검수 보강 항목 번호를 괄호로 병기하고, 본문 없이 바로 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` 트레일러로 끝난다. TDD·빈번 커밋 원칙(태스크당 최소 1커밋, fix 라운드마다 추가 커밋)도 그대로 유지.

---

## 7. 살아있는 계약/함정

### 계약 위반 절대 금지 4건 (W4 사전검수에서 명문화, 플랜 검수로 안전 판정된 것)

1. **`LearnSessionQueue.servedPosition` 동결** — 재출제 중에는 이 값을 바꾸지 않는다(테스트로 고정된 계약). W4 T1이 `_servedIds`/`currentIsRepeat` 게터만 추가하고 수식은 손대지 않은 것이 이 계약을 지키는 정확한 방법이었다.
2. **`recordScenarioCheckpoint`(course_mastery_service.dart) 내부에서 `courseEligible` 자가 유도 금지** — `course_mastery_test.dart:416-425`가 고정. 컨텍스트 없는 실행은 영구히 `courseEligible=false`이며 이것은 버그가 아니라 계약이다. 컨텍스트는 반드시 **호출 지점**(T6의 `activeScenarioCheckpointContext` 헬퍼처럼)에서 부착해야 하며, 서비스 파일 자체를 수정하면 안 된다.
3. **`/review` 라우트 + 고정 테스트 15곳** — `/review`는 플레이어 화면으로 유지(Today 원탭 CTA, `today_review` 피드백 id). 허브(T12)는 반드시 `/review/hub`라는 별도 라우트로 분리한다.
4. **신규 저장 키는 백업 화이트리스트 필수** — `kl_study_log_*`·`kl_gram_plan_v1` 등 T10/T15에서 새로 만드는 키는 그 키를 도입하는 같은 PR에서 `cloud_sync.dart`(payload+복원)와 `learning_data_export_service.dart`에 등록해야 한다(T18). "신규 학습 키는 백업 목록 필수"를 검증하는 가드 테스트도 T18의 산출물이다.

### 그 외 살아있는 계약

- **오디오 정책 단일 결정점** — `AudioPolicy`가 볼륨/재생 정책의 유일한 결정 지점이며 래칫 테스트로 고정돼 있다. 새 코드가 볼륨 리터럴을 직접 쓰면 `audio_policy_guard`가 걸린다.
- **게임 표면 프레임** — 7개 게임 화면은 전부 `SoriStudyFrame`을 유지해야 한다(`game_surface_contract`).
- **arb DE/EN 동시 추가 규칙** — 새 사용자 노출 문자열은 `app_de.arb`와 `app_en.arb`에 **반드시 같은 커밋에서 함께** 추가한다(`arb_l10n_guard`). W4의 T2/T5/T9/T12/T16/T17 전부 이 규칙을 따른다. 영어를 중간 정본으로 쓰지 않고 한국어 원문에서 DE/EN을 각각 독립 재구성하는 것도 같은 원칙의 연장(3절 콘텐츠 자연성 배경 참고).

### 래칫 현재값(전부 `C:\dev\hangulsori\ko_lernen_app_w4\test\` 기준, 하향만 가능)

| 가드 | 파일 | 현재 상한 | 비고 |
|---|---|---|---|
| 그리드 밖 간격 리터럴 | `spacing_literal_guard_test.dart` | **181** | 2026-08-27 최초 실측 기준선 |
| fontSize 리터럴(TextStyle 안, lib/screens/) | `typography_guard_test.dart` | **115** (15파일) | 2026-08-27 최초 실측 |
| `TextOverflow.ellipsis`(화면+공통내비) | 〃 | **0** | 위반 시 대안은 Flexible+wrap(settings_screen 선례) — ellipsis로 "고치지" 말 것 |
| `FontWeight.w900` / `w800` | 〃 | ≤28 / ≤80 | |
| `fontFamily: '` 리터럴 | 〃 | **0** | |
| raw `TextStyle(`(lib/screens/) | 〃 | ≤217 | |
| `BorderRadius.circular(` 숫자 리터럴 | 〃 | ≤24 | |
| raw `AppBar(`(lib/screens/) | 〃 | **0** | |
| raw `TextField(`(lib/screens/) | 〃 | ≤22 | |
| 아이콘 있는 `SoriButton` | 〃 | ≤71 | `lib/features/guide/guide_runtime.dart`에 예외 1건 핀 |
| raw `InkWell(` | `chrome_stack_guard_test.dart` | **≤19** | 2026-08-27 최초 실측, `SoriPressable` 사용 원칙 |
| Sori 위젯 파일 수 | `uiux_bible_closeout_inventory_test.dart` | **=133** | `docs/UIUX_BIBLE_APPLICATION_EXECUTION_LOCK.md` §8 표와 1:1 대응 |
| `main.dart` 등록 라우트 수 | 〃 | **=72** | §6 표와 1:1 대응 |
| 화면형 표면 클래스 수 | 〃 | **=108** | `lib/screens/`+`lib/features/guide/` |

**`chipWrapAllowlist`**(화면별 Wrap+Chip 블록 상한, 나머지는 전부 1로 캡):
```
lib/screens/chosung_quiz_screen.dart: 4
lib/screens/hangul_screen.dart: 2
lib/screens/legacy_vocab_screen.dart: 2
lib/screens/scenario_player_screen.dart: 2
lib/screens/study_library_screen.dart: 3
```
앞 4개는 가드 신설 이전부터 있던 부채(§19 이관 대상, 5절). `study_library_screen.dart`는 W3↔main 머지 중 발견돼 별도로 그랜드파더 등재됐고 "W5 §19 이행 목록 항목 6"에 편입하기로 룰링됨 — **새로운 다중 위반 화면을 이 목록에 추가하지 않는다.**

### by-design로 확정된 침묵 실패 — "고치지" 말 것

- **receipt fail-open 2곳** — 영수증 캡처 실패 시 열림 상태로 진행(사용자 차단 방지가 의도).
- **TTS best-effort 지점**(`prefetch`/`clearCache`/`_ensureSpeechAudioContext` 등) — 실패해도 조용히 넘어가는 것이 의도된 동작. 3절 W3.5가 고친 것은 "로컬 캐시 읽기의 예외 처리 범위가 너무 좁아서 3단 폴백 전체가 스킵되는" 버그이지, best-effort 자체를 없앤 게 아니다 — 이 구분을 유지할 것.
- **`AudioPolicy.applyPlatformAudioContext` 미가드** — 예외 시 `markReady`가 발화하지 않아 항상 1500ms 대기로 강등된다. W2 Task 6에서 발견·보류(deferred) 판정, 후속 티켓 후보로만 기록.

### 알려진 테스트 인프라 함정

- **`CourseProgressService.shared`의 Zone-crossing** — 싱글턴 상태가 테스트 Zone을 넘어 누수될 수 있는 함정 범주. Task 8 감사에서 `test/screen_smoke_test.dart`가 `resetForTesting()` 시딩 누락으로 의심됐으나, 컨트롤러 실측 결과 고립 실행·전체 스위트 내 실행 양쪽 다 24/24 클린 — **이 파일은 무관한 것으로 판정 종료**(4절 Task 8 참고). 일반 원칙은 여전히 유효: 이 서비스를 만지는 테스트를 새로 쓸 때는 리셋 시딩이 있는지 먼저 확인할 것.
- **`FakeAsync`와 `compute()`의 불일치** — `compute()`는 진짜 isolate를 스폰하므로 `FakeAsync`로 타이머를 가짜로 흘려도 제어되지 않는다. `ScenarioLoader`/`_parseShard`처럼 compute()를 쓰는 경로를 테스트할 때 FakeAsync 기반 하네스를 그대로 재사용하면 안 된다.
- **미청취 콜드 `compute()`가 정적 캐시를 null로 남겨 나중 테스트를 교착시킨다** — 실사례: Task 8이 `scenario_can_do_result_flow_test.dart`에서 이렇게 걸렸다(4절). 어떤 테스트가 `compute()` 기반 로드(예: `CurriculumCatalog.load()`)를 시작만 하고 그 체인을 await하지 않으면 테스트 자체는 통과하지만, compute()는 고아로 남고 정적 캐시는 null인 채로 남는다 — **같은 파일/워커의 나중 테스트**가 그 고아 프로세스와 경합하면 교착한다. 증상 시그니처: 스위트가 끝까지 도달한 것처럼 보이는데 **summary line 없이 멈춘다**(실사례는 ~5087개 근처). 수정법: 그 compute()를 유발하는 테스트에 형제 테스트와 동일한 `runAsync` 프리웜을 추가.
- **베이스라인 오염** — 무인 전체 스위트 실행 중에는 어떤 파일도 편집하지 않는다(위 직렬화 규칙과 동일 사건).

---

## 8. SDD 원장 보존

**이 섹션이 존재하는 이유**: `.superpowers/sdd/`는 gitignore 대상이라 워크트리를 지우면 원장이 통째로 사라진다. **W1의 원장이 실제로 이렇게 소실됐다**(3절). 아래 W2/W3/W4의 `progress.md`는 원자료에서 수집된 전문을 그대로 옮긴 것이다 — 워크트리가 삭제돼도 이 인계서에는 남는다.

**아직 옮기지 못한 것**: `C:\dev\hangulsori\ko_lernen_app_w35\.superpowers\sdd\`에는 `progress.md`가 아예 없고, 대신 loose 파일 3개(`w35-execution-report.md` 18,081 bytes, `w35-fix-review.diff` 10,960 bytes, `w35-review.diff` 34,682 bytes)가 있다. **이번 수집 작업은 이 3개 파일의 내용을 읽지 않았다**(존재와 크기만 확인) — W3.5는 이미 main에 병합 완료된 상태이므로 워크트리가 정리될 위험이 W1보다 훨씬 임박해 있다. **다음 세션이 가장 먼저 할 일 중 하나로 이 3개 파일을 직접 열어 이 문서(또는 별도 보존 위치)에 옮겨 담을 것을 강력히 권고.**

### `C:\dev\hangulsori\ko_lernen_app\.superpowers\sdd\2026-08-26-w2-performance\progress.md` (main에 보존됨, 43줄)

```
# SDD ledger — plan: docs/superpowers/plans/2026-08-26-w2-performance.md

Branch: feat/w2-performance (base 60578409 = main+Jin13건 동기). Spec: 마스터 플랜 P4/P5 + 검수 7/10/11/26. 플랜은 sonnet 작성 → sonnet 검수(NEEDS-CHANGE 2건) → 수정 커밋 2fe42eee 로 확정.

## Pre-flight (플랜 검수로 대체 — 2026-08-26)
Ruling: 검수 HIGH(가드 정규식 제네릭 미허용)·MEDIUM(Task3→5 병렬 주장 오류) 는 플랜 텍스트 수정으로 해소(2fe42eee). 비용: 없음(실행 전 수정).
Ruling: Task 5 대상 파일 정정(silben→sori_stage_catalog_screen) — 컨트롤러 grep 으로 실증 승인.
Ruling: 워킹트리 단일 — W2 부터 구현자 동시 실행 금지(순차만). 근거: Jin 배치와의 브랜치 체크아웃 충돌 실경험.
실행 순서: 1→2→3→4→5→6→7→8→9→10 순차 (3→5 같은 파일, 8→9 의존).

## W2 종료 (2026-08-27)
최종 전체 리뷰(fable): Ready to merge YES — Critical/Important 0, Minor 5. 정리 픽스 4건(9f55341d) 적용 후 재리뷰 clean. **main 머지 2ac96dfb, origin·ci 푸시 완료.**
잔여 Jin 게이트(릴리스 전, 머지 차단 아님): ① Android12 실기기 스플래시 육안 ② 콜드스타트 Before(632e7786)/After 실측 ③ 비디오 에셋 2건(tiger_choose 그림자 잔존, 신규 5종 1920×1080 규격).
W2 잔여 후속(별도 티켓 후보): reward-flow 테스트 3초 고정 딜레이→폴링, pad 스크립트 mkdir, 가드 정규식 느슨함, main.dart 기타 낡은 주석.

## Task log

Task 1: complete (commit 002661a8, 문서 30줄). Ruling: 문서 전용 커밋이라 리뷰 시트 생략, 컨트롤러 직접 검증(diff 정독 — 명령·중앙값 절차·Before/After 표·Jin 게이트 명시 확인). 비용: 낮음(코드 0줄).
Task 2: complete (commit 01d9202a, review clean). fail-open 양 경로(예외·행) 추적 검증, Completer 레이스 트랩 실증, 이탈 2건(테스트 전용 runAsync 픽스 + lint 리네임) 정당 판정.
Task 2: minor (deferred): catalog_reward_flow_test 의 고정 3초 딜레이 — 느린 CI 에서 플레이크 위험, 폴링 루프로 후속 교체 후보.
Task 2: minor (deferred): GyeService 캐시 프로세스 첫 capture 는 랜턴 0 과소보고 — 브리프가 수용한 트레이드오프(문서화됨).
사건(2026-08-26): Jin 의 Codex 세션이 동일 체크아웃을 동시 사용 — Task 3 커밋이 main 에 오착륙(dcb36a03), 구현자가 체리픽(1e4c8ad5)+리버트(f7e86bf8)로 복구. Ruling: 이후 W2 전 작업은 전용 워크트리 C:\dev\hangulsori\ko_lernen_app_w2 에서 수행(원 체크아웃은 Jin/Codex 전용). 비용: 워크트리 pub get 1회.
에셋: Jin 이 배경 없는 비디오 5종을 main 에 직접 커밋(f6949325 "절대 회귀하지말도록") — origin/main 발산(Codex UIUX 2커밋)을 머지(196a88e7)로 정리, 양 원격 푸시 완료. 그림자 보정 코드 조사 에이전트 결과 대기 중; "회귀 금지" 요구는 에셋 락 가드(해시 고정) 후보로 W6 에 기록.
Task 3: 구현 완료 보고 (1e4c8ad5, 신규 테스트 2/2 + 전체 4,685 GREEN).
Task 3: Ruling: "재활성화 시 재로드 금지" 문구 폐기 — hanok 정본 패턴(활성화마다 정확 1회 새로고침)을 계약으로 채택. 비용: 재방문 시 로드 1회는 의도된 갱신.
Task 3: fix round 1/5 시작 (재활성화 정확 카운트 테스트 추가 — 프로덕션 무변경 예상). 이후 W2 전 작업 워크트리 수행.
Task 3: fix round 1/5 (1 addressed — 재활성화 정확 카운트 테스트 0b2a35bc, lib/ 무변경). Ruling: 테스트 단일 파일 fix 라 재리뷰 시트 생략, 컨트롤러 diff 직접 검증(카운트 계약 일치 확인). 비용: 낮음.
Task 3: complete (commits 1e4c8ad5+0b2a35bc, 3/3 GREEN).
Task 3: minor (deferred): didUpdateWidget 조건 `(!old.active && active)` 의 중복 단순화 — 기존 코드, hanok 과 표기 통일 후보.
Task 4: complete (commits 96557654+5c85a91c, review Approved + fix round 1). scenarioStars/completedScenarios 메모이즈, 캐시 리셋 배선(기존 패턴), 원장 클레임 양 지점 무조건 무효화 — 컨트롤러 diff 직접 검증. 신규 테스트 5/5, 전체 4,690 GREEN.
Task 4: minor (deferred): _sl 쓰기 실패 주입 불가 — 성공 경로만 직접 단언(테스트 주석에 한계 명시).
Task 5: complete (commit c74bf968). Ruling: 소형 기계적 diff 라 컨트롤러 직접 검증(메모 키 완전성 — cellWidth·textScale·locale·titles·footers 확인). 신규 테스트 3/3+회귀 GREEN. 비용: 낮음.
Task 6: complete (commit 81ba384c, review Approved). 게이트 min600·cap1500·fail-open 3경로 추적 검증, fake-clock 테스트 정당, BookImage 게이트 밖 비차단. 4,698 GREEN — **P4 즉효 5건 전부 랜딩**.
Task 6: minor (deferred): applyPlatformAudioContext 미가드(기존) — 예외 시 markReady 미발화로 항상 1500ms 대기 강등. 후속 티켓 후보.
Task 6: minor (deferred): main.dart:568 낡은 "스플래시(2초)" 주석 잔존(브리프 스코프 밖) + 리포트의 ignore 선례 표현 부정확(파일레벨 1건 혼용).
Task 7: complete (commit ee5e0b2c, review Approved — 지적 0건). _parseShard 순수성·아이솔레이트 안전성 코드 검사 통과(레코드 반환, 뮤테이션 함정 회피), skip-broken 패리티, findById 시맨틱 일치. 4,701 GREEN.
Task 8: complete (commit 4524d099). Ruling: 테스트 전용 + 구현자가 부정 케이스(await 제거·runner 이후 이동) 스크립트 검증 완료 → 컨트롤러 diff 직접 검증으로 갈음. 가드 13/13, 전체 4,701 GREEN, main.dart 무변경.
Task 9: complete (commit e9795377). Ruling: main.dart 단일 지점 변경 + Task 8 가드가 계약 고정 → 컨트롤러 직접 검증. 숨은 순서 의존 없음(정적 상태·에셋 소스 분리), 양 로더 모두 내부 삼킴이라 Future.wait fail-fast 관측 불가 = 실패 동작 동일. 가드 12/12, 전체 4,701 GREEN.
Task 10: complete (commit 3797431e, review Approved). 화이트리스트 4속성 4개 styles.xml 전부 원본 값 보존(재생성이 values/·values-night/ 를 아예 건드리지 않음 — 브리프 위험 가정보다 안전), manifest 무변경, windowSplashScreen* 신설, 아이콘 세이프존 55% PIL 실측, 신규 소스는 비번들 경로. **W2 10태스크 전부 랜딩.**
Task 10: minor (deferred): pad_android12_splash_icon.py 가 출력 디렉터리 mkdir 안 함(신선 클론 재실행 시 취약); flutter_native_splash 병합 동작이 가정보다 보수적이라는 사실을 다음 브리프에 반영 권고.
Task 10: Jin 게이트 미충족 — Android 12+ 실기기 스플래시 육안 확인 + 콜드스타트 Before/After 실측(체크리스트 docs/data/coldstart_benchmark.md).
Task 4: note: 워크트리에 .superpowers 브리프 부재 — 구현자가 플랜 문서 Task 섹션으로 대체(컨트롤러 수용). 이후 디스패치는 원 체크아웃의 브리프 경로를 직접 지정.
에셋 후속: 매트 리포트 재생성 커밋 ca27367d 푸시 완료(main GREEN 복구). Jin 확인 대기 2건 — tiger_choose 그림자 잔존(24.1%), 신규 5종 규격 1920×1080 왜곡 위험. 그림자 보정 코드는 제거 0건(범용 매트 존치)·보류 1건(profile_screen magpieBob2 워크어라운드).
```

### `C:\dev\hangulsori\ko_lernen_app_w3\.superpowers\sdd\2026-08-27-w3-global-systems\progress.md` (67줄)

```
# SDD ledger — plan: docs/superpowers/plans/2026-08-27-w3-global-systems.md

Worktree: C:\dev\hangulsori\ko_lernen_app_w3 (branch feat/w3-global-systems, base e2c90182 = main + W1/W2/Jin batches). 15 tasks.
플랜: sonnet 작성(1a2bac00) → sonnet 검수 NEEDS-CHANGE → 컨트롤러 룰링 4건 → 수정 확정(e24157e5).

## Pre-flight rulings (2026-08-27)
Ruling: Task 9 AppBar 북마크 제거는 진행하되 **피드 _Stamp 의 a11y 선검증·48dp 승격이 선행 조건**(Semantics button/label + 터치 타깃). 중복 UI 를 접근성 목발로 남기지 않는다(지시서 1.24). 비용: 스탬프 승격 1스텝.
Ruling: W3/W5 분할(레벨필터 13→2, 오디오 7→1, /review onPrevious, 피드 기본 전환, 홈해치 잔여, 히어로 유예 4화면) **승인 — 단 W5 플랜의 필수 이행 계약으로 못박음**(플랜에 `## W5 필수 이행 목록 (계약)` 섹션 존재). Jin 승인은 "계획 전체 완주·W5까지"로 이미 받음. 비용: W5 분량 증가.
Ruling(구현자 정정 수용): wordbook_add.dart import 는 review·vocab_pack **양쪽 모두 존치**(addToWordbook 함수 호출 때문) — 원 룰링의 "import 삭제"는 컴파일 오류였을 것. 근거: 구현자 grep 실증.
실행 순서: 의존 명시대로 T1→T2(tokens), content_feed T8→T12→T14, review_session T9→T13, BIBLE T1→…→T8. 워크트리 단독 사용, 구현자 동시 실행 금지(순차).

## 전문 감사 (ecc 스킬 편입, 2026-08-27)
silent-failure-hunter 결과 — **전부 W3 도입 결함 아님(기존 경로)**, 따라서 W3 머지 비차단. 단 지시서 원 불만과 직결되므로 **별도 하드닝 웨이브(W3.5)로 처리 확정**:
- [Critical] tts_service.dart:744-761 로컬 캐시 읽기가 TimeoutException 만 잡아 다른 I/O 예외 시 3단 폴백 전체 우회 + errorReporter 미발화 → "소리 안 나와" 재발 경로. 최소 수정: catch 범위 확대 + 비-Blocked 예외도 보고.
- [Critical] vocab_pack_screen.dart:738-835 `_finish()` 가 try/catch·await 없이 fire-and-forget → 예외 시 XP/클리어/도장 미기록 + 결과 화면 미이동 + 흔적 0. "진행이 안 저장된다" 재현 경로.
- [Critical] review_session_screen.dart:148-178 `_load()` 가 로그 없이 전부 삼키고 **축하 빈 상태**(magpie_celebrate)를 표시 → 로드 실패와 "복습 없음"이 구분 불가. 형제 화면(grammar/vocab_pack)은 이미 AppError+재시도 패턴 보유.
- [Important] culture_notes_service 미청취 비동기 에러(같은 웨이브의 receipt 서비스에 정답 패턴 존재), grammar 체크포인트 시트 dispose 미가드(중복 제출 가능), vocab_pack 850ms Future.delayed 미취소, 전역 fire-and-forget 저장 쓰기 다수.
- [최대 레버리지] main.dart 에 전역 에러 훅(runZonedGuarded/FlutterError.onError/PlatformDispatcher.onError) 부재 — DiagnosticsService+Crashlytics sink 는 이미 존재하는데 미연결. 한 줄 연결로 위 다수가 최소한 관측 가능해짐.
- [By-design 확인] receipt fail-open 2곳·TTS best-effort 4곳은 **유지** — 나중에 "고치지" 말 것.

## Task log

Task 1: complete (commit c042eed2, review Approved — Critical/Important 0). §15 토큰·전뷰포트 클램프·heroFit(폭 축소)·SoriStudyFrame(hero:)·hero_placement_guard(위반 4 유예, 11개 호출처 실측 정합)·회귀테스트 재타게팅+예산 단언(비-토톨로지 검증됨). 4,707 GREEN.
Task 2: complete (commits 28f27bf5+94778b6a, review Approved). §16 SoriGaps 8종 전부 Spacing 별칭 정합, spacing_literal_guard 실측 ceiling=181 을 리뷰어가 독립 재구현으로 정확히 재현(451파일 스캔), 여유 0이라 다음 위반에 즉시 실패. 이탈 2건(const→final Set, 브리프 지정 2커밋) 정당. 4,708 GREEN.
Task 3: complete (commit 355bd198, review Approved). §17 SoriChromeRow(토큰 44/48)·SoriButton(loading:)·SoriPressable 정본·chrome_stack_guard. 리뷰어가 4개 유예 화면의 Wrap+Chip 수를 직접 재계수해 정확 확인 + lib/screens 전수 스윕으로 5번째 위반 없음 확인. 인벤토리 129→130 은 실측 부기. 4,710 GREEN.
Task 4: complete (commits 613cbc51+64c44439, review Approved — 지적 0건). typography fontSize 래칫 신설(실측 115/15파일, 하향 전용), 기존 9테스트 무변경(0 deletions), §18 문서가 실제 랜딩 상태와 정합(가드 4종·유예 4화면·래칫 181/115/19). 4,711 GREEN.
Task 5: complete (commit 4998f2e0). Ruling: 문서 전용이라 리뷰 시트 생략, 컨트롤러 직접 검증(§20 판정 절차 + 첫 3레코드가 실제 랜딩 §15/§16/§17·가드와 정합). **바이블 2.0 §15-§20 완성** — W3 기반 워크스트림 종료.
Task 6: complete (commit cb3c6ef7, review Approved). C1 #6B4A7E/C2 #4A3D63 + rankOf 5·6 + rankCount 6 **원자적 랜딩**(중간 상태 없음), 온보딩 3소비처는 동적 참조라 무수정(리뷰어 직접 확인), 골든은 CI(Linux 3.44.0) workflow_dispatch 산출물로 재기준(ci.yml 잡과 절차 일치 확인), 대비 수치는 리뷰어가 WCAG 1차 원리로 재계산해 소수 2자리 일치. 4,711 GREEN.
Task 7: 구현 완료(9392f471) — SoriLevelFilterBar 신설 + smalltalk·listening 이관 + listening 시작레벨 버그 수정. 리뷰 Needs fixes 1건(smalltalk 높이 검사가 가상화로 조용히 축소, 개수 하한 없음) → fix 라운드 1 진행 중.
Task 7: fix round 1/5 (1 addressed — 스크롤 스윕 + seenLabels hasLength(7) 하한 + 48dp 단언; commit 30d33fb7). 컨트롤러 diff 직접 검증. 구현자가 자기 1차 시도의 미스코프 파인더 버그도 자체 발견·수정.
Task 7: complete (commits 9392f471+30d33fb7, review clean after 1 fix round).
Task 9: 구현 완료(c95910d5) — _Stamp 4종 48dp 승격(HitTestBehavior.opaque 로 실제 히트영역 확인됨), AppBar 중복 제거, import 양쪽 존치, 죽은 코드 정리. 리뷰 Needs fixes 2건.
Task 9: **fix 큐잉(T10 랜딩 후 즉시 디스패치)** — ① [Critical, 회귀는 아님] 북마크 Semantics 라벨이 saved 상태를 반영 안 함(구 AppBar 버튼도 동일 결함이었음) → 상태 반영 라벨/값 필요, arb de/en 동시 ② [Important] 삭제한 vocab_pack_flipgate 테스트가 wordbook 스포트라이트 코치의 유일한 커버리지였고 그 기능은 4화면(book_result·chosung_quiz·listening_play·scenario_player)에 여전히 살아 있음 → 생존 화면 1곳에 동등 커버리지 신설.
Task 10: complete (commit a30c863a, review Approved). SoriHomeAction(확인 시트 dismissible·context.mounted 재검사) + kkeunmari 배선. isRoundActive 를 `_end == _End.none` 로 치환한 이탈은 리뷰어가 상태머신 추적으로 정당성 실증(승리 결과 카드 위 오탐 제거, 브리프가 대체 허용 명시). 인벤토리 131→132 실측 확인. 4,714 GREEN.
Task 10: minor (deferred): home_action 의 44px 리터럴이 3줄 포매팅 때문에 spacing 가드를 우회(브리프 상속); KkeunmariScreen 실제 배선의 종단 테스트는 없음(단위 레벨까지만).
Task 9: fix round 1/5 (2 addressed — 북마크 Semantics value 상태 안내(DE Gemerkt/Nicht gemerkt·EN Saved/Not saved) + chosung_quiz 앵커 스포트라이트 커버리지 신설; commit ddc31b25). 재리뷰 clean: value 가 접근성 트리에 실제 도달(ExcludeSemantics 는 자식만), 테스트 비-토톨로지 구조적 확인, listening_play 의 coachEnabled:false 하드코딩 실증.
Task 9: complete (commits c95910d5+ddc31b25, review clean after 1 fix round). 4,716 GREEN.
Task 11+12: complete (commits 7d38c43a RED → 1270c1c0 GREEN, review Approved). speakable.dart 신설 + content_feed 인디케이터 슬롯/더블탭 재스코프. 검수#13 5건 중 ①②③④는 리뷰어가 Flutter Stack 히트테스트 알고리즘·TtsService 취소 시맨틱까지 추적해 실구현 확인. 4,721 passed / 0 failed.
Task 12: **fix 큐잉(T13 랜딩 후 즉시)** — ⑤ 공유 in-flight 맵이 실제로는 `_inFlightSpeak`/`_inFlightPrefetch` 두 개로 분리(브리프 코드 자체의 결함, 구현자 과실 아님): prefetch 진행 중 같은 문장을 speak 하면 중복 요청. 클래스 doc 도 과장. + [Minor] SoriSpeechIndicator 의 SizedBox 40×40 이 OverflowBox 44 를 감싸 실제 터치 타깃은 40 — a11y 최소치 미달.
Task 12: minor (deferred): 수명주기(디바운스·세대·라우트 전환·히트테스트)의 런타임 테스트 부재 — 소스 문자열 가드로만 고정(가드 테스트 주석에 트레이드오프 명시됨). W5 실기기 QA 시 수동 확인 항목.
Task 13: 구현 완료(0a661f7a, 4,723/0 failed). 리뷰: deactivate 프레임 지연 이탈은 **정당 승인**(TtsService.stop 이 speaking notifier 를 동기 변경 → 빌드 중 setState 크래시, 실서비스에도 존재하는 실버그; 지연은 같은 프레임 내 보장, stop 계약 유지). 그러나 Needs fixes 2건.
Task 13: **fix 큐잉(speakable 픽스 랜딩 후)** — ① Skip(_deferCurrent) 경로는 _idx 불변이라 playOnEnter 미호출 → 카드가 바뀌는데 무음(다른 두 전환 경로와 불일치) ② 신규 테스트 2건이 인디케이터 존재·탭 격리만 검증, playOnEnter 를 지워도 GREEN — 자동재생 미고정. 리뷰어 제안: TtsService.speaking.value 가 speak() 시작 시 동기 true 가 되므로 저비용 양성 신호로 사용 가능.
Task 14: 구현 완료(f1bb700d) — physics 이중 경로(legacy 기본), 리뷰 Approved: legacy 바이트 동등성·7 호출처 무수정·7 기존 테스트 무편집·T12 히트테스트 구조 보존을 리뷰어가 코드 추적 + 9/9 테스트 실행으로 확인. fix 라운드 1 진행 중(스냅 후 _snapCtrl 미리셋 → 언더레이 불투명도 1.0 고정, 브리프 상속 잠복 버그; W5 에서 snap 켜면 발현).
Task 14: minor (deferred): "언더레이 슬라이드"는 실제로는 불투명도 램프(브리프 문구와 구현 불일치, 기능 결함 아님).
Task 7: minor (deferred, 스펙 상속): 시각 44dp 토큰은 스크롤 컨텍스트라 미사용(브리프가 근거 명시); 레벨별 accent 색 변경이 smalltalk 에도 적용(브리프 dartdoc 에 공시됨).
Task 8: complete (commit 7bb964ba, review Approved — 지적 0건). 북마크 = 먹(s.text) 무조건, 하트는 불변(일방향 분리), 재병합 시 실패하는 테스트 추가, §12 1줄 갱신. 4,712 GREEN.
운영: 동일 워크트리 동시 쓰기 경고 발생(T7 fix ∥ T8 구현) — 파일 교집합은 없었으나 **이후 구현자는 엄격 직렬화**(리뷰만 병행).
Task 12: fix round 1/5 (3 addressed — 공유 in-flight 맵 단일화(양방향 교차 재사용 실증)·deactivate/didPushNext 프레임 지연 중앙화 + T13 화면측 우회 되돌림·인디케이터 실터치 48dp 토큰; commit a680e43c). 재리뷰 clean, 4,729/0 failed.
Task 12: minor (deferred): speak 2건이 같은 prefetch 를 동시에 물면 3자 경합으로 speakImpl 중복 가능(_startSpeak 가 _inFlight 재확인 안 함) — 2자 계약은 충족, 3자는 후속.
Task 12: **문서 정리 항목 추가** — speakable.dart:71-81 의 ⚠️ 주석이 "Dart 3.12.2 에서 arrow/block body·인라인 체인 차이로 Future 미완료" 를 확정 사실로 단언하나, 리뷰어 판정상 언어 명세와 모순(실제 원인은 초안의 로직 문제였을 가능성). 코드 자체는 정확·테스트 GREEN 이므로 유지하되 **주장을 관측 증상 서술로 완화**하고 원인 규명은 별도 조사로 남긴다.
Task 14: fix round 1/5 (2 addressed — _snapCtrl.value 리셋·재진입 가드; commit a13e577a). 두 픽스 모두 되돌려 RED 확인(언더레이 1.0, 재진입 2회) 후 GREEN. content_feed 11/11.
Task 13: fix round 1/5 (2 addressed — Skip(_deferCurrent) 자동재생 추가 + speakImpl 가짜 리졸버로 진입·전환 발화 텍스트 결정적 고정; commit bff5fd4a). 구현자가 뮤테이션 테스트(playOnEnter 제거→Skip 테스트만 RED)로 비-토톨로지 실증. 컨트롤러 diff 직접 검증. 8/8 GREEN.
Task 13: complete (commits 0a661f7a+bff5fd4a, review clean after 1 fix round).
Task 15: 구현 완료(45476ab4) — 필터 변경 시 위치 보존 + 아래 플링=이전 카드(grammar). RED 재현("4/244→1/244") 후 브리프 코드 그대로 적용, 전체 4,735/0 failed. 리뷰 진행 중.
문서 정리: complete (commit 3ca70038, 7파일 주석/문서만). 6단 레벨·150/250ms·48dp 스탬프·speakable ⚠️ 문구 완화 — 래칫 무이동 확인(14/14).
Task 14: complete (commits f1bb700d+a13e577a, fix round 재리뷰 clean). 리뷰어가 _snapTween null 선행→setState 순서의 미묘함까지 추적, legacy 불변을 분기 구조로 증명, 햅틱 카운트 전환은 실제 테스트 설계 결함 수정으로 판정. 14/14 GREEN.
Task 15: complete (commit 45476ab4, review Approved). 위치 보존이 인덱스 클램프가 아니라 **Grammar.id 동일성 기반**임을 확인, onPrevious 언더플로 차단, 테스트 하네스 적응 2건은 기존 선례 재사용으로 정당. analyze 0 독립 재실행 확인.
Task 15: minor (deferred): "앞쪽 항목만 제거되고 현재 카드가 살아남아 인덱스가 밀리는" 케이스 미커버(소스는 정확, 테스트 두께 문제); 아래 플링=이전 카드는 플립 후에만 도달 가능(content_feed 기존 라우팅, W5 /review 태스크 참고 사항).
**W3 15/15 전 태스크 승인 완료 — 25커밋, 최종 전체 스위트 4,735 passed / 0 failed.**
Task 6: **Ruling(배치)**: 낡은 "4단계/4색" 주석들(hanok_tokens.dart:97-98 자기모순 포함, onboarding_level_screen:609·732-735, mission_hero_card:8·91, level_chip:8-9, pressable.dart:9-10 의 200/300ms)은 개별 마이크로 픽스 대신 **W3 말미 문서 정리 태스크 1건으로 일괄 처리**. 근거: 전부 런타임 무영향 주석이고, 태스크마다 파일이 겹쳐 동시 수정 시 충돌 위험. 비용: 그때까지 문서가 잠시 불일치.
Task 3: **중요 인계사항**: §19 마이그레이션 부채는 1화면이 아니라 **4화면**(chosung 4·hangul 2·legacy_vocab 2·scenario_player 2) — W5 §19 이행 태스크에 반드시 반영.
Task 3: minor (deferred): chipWrapAllowlist 는 파일별 정적 상한(성장 차단은 확실, 자가 하향은 아님); pressable.dart:9-10 헤더 주석이 200/300ms 로 낡음(실제 150/250) — 1줄 수정 후보.
Task 2: minor (deferred): 래칫 하향 강제는 주석 관례뿐(리포 기존 typography_guard 와 동일); 가드가 EdgeInsets.fromLTRB 미포함(브리프 상속 결함).
Task 1: minor (deferred): 가드가 문자열 포함 스캔이라 래퍼/별칭 우회 미탐지; tokens.dart LAYOUT 배너 위치 코스메틱; SoriStudyFrame hero!=null 분기 미실행(T3/T7 에서 커버); knownViolators 길이 단언은 중복 방지용.

Task 1: NEEDS_CONTEXT 접수 — 무조건 히어로 예산(0.22/200dp)이 scenarios_list 의 의도된 16:9 히어로를 360×780 에서 0dp 로 붕괴시켜 visual_layout_regression_test 실패.
Task 1: **Ruling(설계)**: 상수·기존 테스트·유예목록 손대지 않는다. 대신 클램프에 규칙 1개 추가 — **비율 고정 히어로는 높이 예산에 맞춰 폭을 비례 축소(가운데 정렬)하며, 자르거나 0dp 로 붕괴시키지 않는다.** 구현은 공용 헬퍼(SoriLayout.heroFit)에, 화면은 aspectRatio 전달만. §15 바이블에 문단 1개로 명문화. 근거: 비율=콘텐츠 계약, 높이=레이아웃 계약 — 양립 가능하며 좁은 뷰포트에서 양보할 것은 폭뿐. 비용: 좁은 화면에서 히어로가 가로로 작아짐(수용).
```

### `C:\dev\hangulsori\ko_lernen_app_w4\.superpowers\sdd\2026-08-27-w4-progress-review\progress.md` (47줄)

```
# SDD ledger — plan: docs/superpowers/plans/2026-08-27-w4-progress-review.md

Worktree: C:\dev\hangulsori\ko_lernen_app_w4 (branch feat/w4-progress-review, base 291d3005 = main after W1/W2/W3/Jin batches + Codex onboarding). 18 tasks.
플랜: sonnet 작성(8a0f8c36) → sonnet 검수 NEEDS-CHANGE 4건 → 수정 확정(c79f98c7).

## Pre-flight rulings (2026-08-27)
Ruling: 계약 위험 a-d(LearnSessionQueue servedPosition 동결 / recordScenarioCheckpoint 자가유도 금지 / /review 라우트·고정 테스트 15곳 / 신규 키 백업 화이트리스트)는 플랜 검수에서 4건 전부 안전 판정 — 실행 중에도 이 4개는 절대 위반 금지.
Ruling: 파일 교집합 순차 — storage_service T7→10→15→18, scenario_player T8→10, arb T2→5→12→16→17, main.dart T12→17. **T16 이 부르는 /grammar_choice_quiz 라우트는 T17 이 등록** — T17 없이 웨이브 종료 금지(런타임 예외).
Ruling: 워크트리 단독 사용, 구현자 엄격 직렬화(리뷰만 병행). 리뷰는 ecc:flutter-reviewer 우선, 접근성 표면은 ecc:a11y-architect, 저장/비동기 경로는 ecc:silent-failure-hunter 병행.

## W3.5 하드닝 — main 머지 완료 (9b92973d, 2026-08-27)
실행 6건: TTS 로컬캐시 폴백 우회 수정 + 비-Blocked 예외 보고(단, **배너는 해석 실패로 한정** — 재생 단계 오류를 "온라인이신가요?"로 오표시하던 것 수정), 전역 에러 훅 무조건 설치(Firebase 초기화 전에도 안전), SoriPressable 키보드 활성화(onLongPress 전용 위젯 포커스 트랩 해소), smalltalk customSemanticsActions(WCAG 2.5.1), chrome_row 히트박스 44→48(토큰), speakable ⚠️ 주석 실제 원인으로 정정. 5,065 GREEN.
**W4 머지 후 처리할 이월 5건**: vocab_pack `_finish()` 예외 무보호 / review_session `_load()` 축하 빈상태 오인 + culture_notes 미청취 에러 / grammar 체크포인트 시트 dispose / vocab_pack 850ms Future.delayed 미취소.

## W3 에서 이월된 하드닝 (별도 브랜치 fix/w35-hardening 에서 처리 — W4 와 파일 충돌 주의)
tts 로컬 캐시 catch 확대 / vocab_pack `_finish()` 예외 무보호 / review_session `_load()` 축하 빈상태 오인 / culture_notes 미청취 에러 / grammar 체크포인트 시트 dispose / 850ms Future.delayed 미취소 / 전역 에러 훅 부재 / SoriPressable 키보드 활성화 / smalltalk 제스처 전용 내비 / chrome_row 히트박스.

## 세션 종료 시점 상태 (2026-08-28)
Task 8 complete (commits aa5914bf + a07b1d5f). 리뷰 Needs fixes 2건 + 컨트롤러가 직접 돌린 전체 스위트에서 발견한 실패 1건 전부 해소:
- 실패 근본 원인: `scenario_can_do_result_flow_test.dart` 첫 테스트가 형제 테스트에 있던 `CurriculumCatalog.load()` runAsync 프리웜을 빠뜨림 → T8 이후 모든 시나리오 오픈이 컨텍스트를 유도하면서 콜드 compute() 를 고아로 남기고, 다음 테스트가 그와 경합해 교착. 단언 무편집으로 프리웜만 추가.
- fail-soft: `activeScenarioCheckpointContext` try/catch — 손상된 스냅샷 JSON 등으로 던져도 컨텍스트만 null 이 되고 시나리오 재생은 계속(회귀 테스트 추가).
- screen_smoke_test 는 실측 결과 정상(고립·전체 양쪽 24/24) — 수정 불요로 판정.
- **컨트롤러 직접 전체 스위트 검증: 5,089 passed / 0 failed (`All tests passed!`).**
W4 진행률: **8/18 완료**(T1-T8), T9-T18 미착수. 브랜치 feat/w4-progress-review 는 main 에 **미머지**.

## Task log

Task 1: complete (commit 7f259706, review Approved — Critical/Important 0). `_servedIds`+`currentIsRepeat` 추가만, servedPosition 수식·큐 조작 순서 바이트 동일(diff 0 deletions 로 실증). 리뷰어가 재출제·defer·소진 3시나리오 전부 추적 검증, 16/16 GREEN, 전체 5,061/0.
Task 1: minor (deferred): markUnknown 이 idOf 를 2회 호출(브리프가 대칭성 위해 지정한 형태 — idOf 가 무거워지면 정리).
Task 2: complete (commit 6e20f021, review Approved). 검수#21 단일 칩 병기(별도 칩 아님) + T1 currentIsRepeat 소스 확인, dispose 영속화가 파생값 재계산이라 멱등·단조(리뷰어가 vokSeenIds∩pack 경로까지 추적). 5,062/0. 이탈 2건(요구사항 드리프트 단언 수정·교차 실행 노이즈)은 리뷰어가 큐 산술 수기 추적 + 동일 조합 재실행 64/64 로 실증 반박.
Task 2: **fix 큐잉(T3 랜딩 후, 같은 파일이라 직렬)** — [Important] 카운터 라벨이 최대 ~20자로 길어졌는데 `vocab_pack_screen.dart:957-966` 의 Row 에 Flexible/Expanded 가 없어 320-360dp 에서 오버플로 위험(SoriChip 내부 ellipsis 는 부모가 폭을 제한해야 작동). **앞서 별건으로 미룬 `_buildQuiz` 헤더 Row 오버플로(task_a40bf2a2)와 같은 파일·같은 결함 클래스이므로 한 태스크로 묶어 처리** + 좁은 뷰포트 회귀 테스트 추가.
Task 2: minor (deferred): 신규 테스트가 +1 만 검증(+2 누적 미검증).
Task 3: complete (commits 721505c0+270adfce, review clean after 1 fix round). AppBar 리딩 복구 + 다중 라우트 하네스(단일 라우트면 canPop=false 라 단언이 무의미해지는 점을 SDK 근거로 실증).
Task 3: **Ruling(설계)**: CTA 의 `courseContext ? pop : popUntil('/vocab')` 분기를 **무조건 pop() 으로 단순화** — pushReplacementNamed 가 스택 위치를 1:1 보존하므로 모든 진입(그리드·코스미션·홈 3종·/path)에서 1회 pop 이 정답. 리뷰어가 `/vocab/result` 생산 진입점 1곳(pushReplacementNamed) + `/vocab/pack` 5곳 전부 additive pushNamed 임을 독립 grep 으로 재검증. 근거: 술어 vs 진입경로 불일치 클래스를 통째로 제거. 비용: 향후 bare push 진입점이 생기면 재검토 필요(가드 없음).
Task 3: minor (deferred): CTA 더블탭 디바운스 부재(화면 전체 기존 패턴).
운영 사건: 오버플로 수정 에이전트의 미커밋 변경이 typography ellipsis 래칫(상한 0)을 위반 — 다른 에이전트의 전체 스위트 실행이 검출. 컨트롤러가 커밋 전 경고 전달(래칫 상향 금지, 승인된 대안 패턴 사용 지시).
오버플로 묶음 수정: complete (commit 02e1bf5c). 카운터·퀴즈 헤더 Flexible 래핑(ellipsis 는 래칫 위반이라 wrap 패턴 채택 — settings_screen 선례) + 320/360dp 회귀 테스트, 각 픽스 되돌려 RED 확인. 5,070/0.
Task 4: complete (commits 55d6e815+dc95f2d0, review Approved + fix round 1). 팩 목록 열람 시 소급 재동기화(기존 "3/9 갇힘" 자가 치유). 리뷰어가 단조성 갭 실증(vokSeenIds 는 현재 증가만 하지만 resetSession·팩 큐레이션 경로에선 감소 가능) → `!=`→`>` 클램프 + 5개 청크 착수 제한 + 개별 실패 격리. 컨트롤러 최종 파일 직접 확인. 5,073/0.
Task 4: minor (deferred): Firestore 쓰기는 호출부 착수율 제한일 뿐 하드 동시성 상한 아님(_persist/savePack 은 펜스 밖); wordsLearnedIn 의 vokSeenIds 셋 재구축 호이스트 미적용(시그니처에 주입 파라미터 없음).
Task 5: complete (commit dc1fc1f0, review Approved). 커스텀팩 3모드 addVokSeen 보완 + learnedWordCount 순수 유도 + 책장 "n von m" (a11y 라벨 동기). 리뷰어가 3개 호출 지점 발화 시점 추적, 중복 기록은 스토리지·유도 양쪽 dedup 으로 안전 확인. **P1 단어팩 워크스트림 종료.**
Task 5: **fix 큐잉(다음 태스크 랜딩 후)** — [Important] bookshelf_screen.dart:351,374 가 같은 build 에서 learnedWordCount 를 2회 호출(전역 vokSeenIds 를 매번 toSet). 지역변수로 호이스트. + [minor] 3모드 배선의 위젯 회귀 테스트 부재(이 태스크가 고친 버그를 막을 가드 없음).
Task 5: note(제품): 커스텀팩 3모드는 정답/오답 무관하게 addVokSeen(브리프 명시, Learn 단계 선례와 일치) — 반면 표준팩 퀴즈/보스는 정답에만 기록. 오답 단어도 "학습함"에 포함되는 차이는 상위 스펙 결정이며 Jin 인지 필요.
Task 6: complete (commit a62c6556, review Approved). `activeScenarioCheckpointContext` 신설 — 서비스 파일 바이트 동일(계약 유지), 술어 미러를 리뷰어가 조건 단위 대조(생략된 :691/:692 는 caller-supplied context 교차검증용이라 fromLink 구성상 자동 충족), 널 경로 전부 fail-closed. 5,076/0.
Task 6: minor (deferred): 랜딩된 doc 주석의 course_mastery_test 줄 인용이 낡음(:398-425 → 실제 400-441); 미러 드리프트 감지가 주석뿐(테스트 미고정) — **T8(실제 호출부 배선)에서 라운드트립 테스트 1건 추가할 것**.
Task 7: complete (commit 4e9dea5f, review Approved). setScenarioStars 첫 기록은 0성도 허용, 재시도는 단조(2→0 거부). 리뷰어가 5개 전이 전수 추적 + 소비처 4곳 감사(전부 `?? 0` 폴백이라 동작 변화 0) + 갱신된 테스트 단언이 "약화가 아니라 교정"임을 주변 의도까지 읽어 확인. 신규 키 없음(T18 무관). 5,078/0.
Task 7: minor (deferred): 새 주석의 "0/2→1/2 판정 입력" 근거는 현재 코드에 대응 소비자가 없음(CourseActivityReporter 는 passed/total 을 직접 받음) — 향후 체크포인트 소비자 구현 시 참고.
Task 1: note: 무인 전체 스위트 실행 중 편집하면 베이스라인이 오염됨(구현자가 자체 발견·stash 로 재검증). 이후 태스크에 경고 전달 중.
```

**참고(2026-08-28 갱신)**: 원장에 "## 세션 종료 시점 상태 (2026-08-28)" 블록이 위와 같이 추가되어 Task 8 완료(커밋 `aa5914bf`+`a07b1d5f`)와 회귀 근본원인·수정 내역, 전체 스위트 `5,089 passed / 0 failed`를 원장 스스로 기록하게 됐다(같은 내용을 4절 Task 8에서 더 풀어서 서술). `widgets/settings_screen_test.dart`가 왜 `aa5914bf`에 포함됐는지는 원장에도 여전히 명시적 언급이 없지만, 전체 스위트가 GREEN으로 재확인됐으므로 더 이상 막힌 질문은 아니다.

---

## 9. Jin 확인 대기 항목

1. **97개 재작성 항목** — 432개 항목 토픽 전체의 원어민 스크리닝에서 발견된 결함 97건, 전부 재작성 완료했으나 **적용하지 않고 보존만** 함. 위치: `docs/data/partner_rewrite_diff.md`(이미 tracked) + `docs/data/partner_rewrite_batches/`(`flagged.md`, `rewrite-1~4.md` 등, 이미 tracked). Jin 자신의 LLM 파이프라인에 넘기기 위한 것 — **적용 여부와 시점은 Jin 결정 대기.** ⚠ main에는 이것과 별개로 `docs/data/partner_rewrite_diff2.md`(untracked, 48,872 bytes)가 추가로 존재한다 — 기존 `diff.md`와의 관계(후속판/재작업 여부)가 원자료에 없으므로 다음 세션이 직접 diff 내용을 대조해 Jin에게 확인해야 한다.
2. **Android 12+ 실기기 스플래시 육안 확인** — W2 게이트, 아직 미충족(3절).
3. **콜드스타트 Before/After 실측** — 체크리스트 `C:\dev\hangulsori\ko_lernen_app\docs\data\coldstart_benchmark.md`(파일 존재 확인됨), 아직 미충족.
4. **비디오 에셋 2건** — tiger_choose 그림자 잔존 24.1%(Jin 본인 작업분에 남아있는 정도), 신규 무배경 클립 5종이 960×960이 아니라 **1920×1080**이라 기기 블렌드 시 왜곡 위험.
5. **커스텀팩 vs 표준팩 "오답도 학습함으로 카운트" 시맨틱 차이** — W4 T5 이후 커스텀팩 3모드(quiz/matching/typing)는 정답·오답 무관하게 `addVokSeen`을 기록하는데(Learn 단계 선례를 따른 브리프의 명시적 설계), 표준팩 퀴즈/보스 스테이지는 정답에만 기록한다. 이 비대칭은 상위 스펙 결정이며 Jin이 의도한 것인지 확인이 필요하다.
6. **CI Linux 골든 재기준** — W3 Task 6(C1/C2 팔레트)의 골든 이미지가 로컬이 아니라 **CI(Linux 3.44.0) workflow_dispatch 산출물**로 재기준됐다. 리뷰어가 ci.yml 잡과 절차 일치는 확인했지만, 골든을 로컬 macOS/Windows 렌더링과 다른 소스로 관리하기 시작했다는 정책 자체를 Jin이 인지하고 있는지 확인 필요.

### 추가로 관찰된, 아직 분류 안 된 항목 (위 5개 지정 목록 밖)

7. **원본 지시서 파일이 git에 없다** — `docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md`(59개 항목, 전 웨이브의 출발점)가 main에 여전히 untracked 상태다. 커밋해도 되는지 Jin 확인 후 커밋 권장(이 문서가 유실되면 6웨이브 전체의 근거가 사라진다).
8. **`new_인보딩/` 디렉터리** — 오늘(2026-08-27) 타임스탬프의 폰 스크린샷 11장을 포함한 온보딩 리디자인 감사/프로토타입 번들이 main에 untracked로 존재한다. 6웨이브 계획과는 무관한 별도 트랙으로 보이며(온보딩은 이미 별도로 `260dc9d6`/`ea3160e1`/`87dacea8` 커밋들을 통해 main에 랜딩되어 있다), 이것이 진행 중인 추가 작업인지 정리 대상인지 불명 — Jin에게 이 디렉터리의 용도를 확인.
9. **`ko_lernen_app_w3` 워크트리의 머지 후 잔여 수정** — `lib/screens/vocab_pack_screen.dart`(18+/8-)와 `test/vocab_pack_narrow_viewport_header_test.dart`(146줄, 신규)가 W3 머지(`51c8fffb`) 이후에도 커밋되지 않은 채 남아 있다. 이것이 못다 커밋한 유효한 작업인지, 폐기해도 되는 실험인지 다음 세션이 diff를 읽고 판단(필요하면 Jin에게 확인).
10. **`docs/data/partner_rewrite_diff2.md`** — 8절 각주 참고, 항목 1과 동일 사안.
