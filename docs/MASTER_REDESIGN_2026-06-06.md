# Hangul Sori — 듀오링고급 완성형 개편안

> **2026-06-06 · deep-research(112 agents · 29 sources · 검증 12/22 findings) 기반**
> 근거 출처: Duolingo 1차(블로그·백서 DRR-24-04·Practice Hub 가이드) + peer-reviewed(ACM L@S'22, LLT 2024, ACL 2016)

---

## 0. 한 줄 결론

우리는 **이미 모든 재료를 가졌다** — `learning_path_screen`(완성된 Duolingo식 path), 단어팩 61개(`packOrder` 선형), 한옥 12단계, 계 두레판(칭호·기여·응원), 책 한 컷, SRS(`ReviewDeckService`). 문제는 **조립(IA)**이다. path를 홈 카드 하나로 묻고 기능을 평면 분산했다. **신규 구축이 아니라 재배치가 답.**

---

## 1. 정직한 진단 — Stage 1이 어긋난 지점 (§0)

- **Stage 1이 한 것**: 홈 `_BrowseSection`(둘러보기 16카드) 제거 + 4탭(홈/배우기/연습/단어장) 분산.
- **충돌**: deep-research Finding 1·2(Duolingo 1차출처, 만장일치 3-0)는 *"홈=path 압도적 중심, 기능은 path 안 또는 축소된 bottom-menu"*. "배우기/연습/단어장"으로 기능을 평면 분산한 건 **검증된 안티패턴**.
- **Jin "게임·단어공부가 사라졌다"** = 정확히 이 충돌의 증상. 익숙한 홈 카드를 탭 속에 숨겨 발견성을 끊었다.
- **단, Stage 1 전부 무용은 아니다**: 허브의 named 섹션 구조는 Finding 3과 정합. `app_shell`·허브·`feature_coach`·온보딩 캐러셀은 **재활용**하고, 탭 구성과 홈만 교정한다.

---

## 2. deep-research 검증 findings (채택분만)

| # | Finding | conf | vote |
|---|---|---|---|
| F1 | 홈 = 단일 선형 path("다음 한 걸음" 명확). 기능 탭 분산 X | **high** | 3-0×2 |
| F2 | 부가기능(스토리·복습·퀘스트·문법)은 최상위 탭 X → path 안 or 축소 bottom-menu | **high** | 3-0 |
| F3 | 복습·단어·듣기·말하기 = 각각 named 진입점(Practice 허브) | **high** | 3-0 |
| F4 | 선형 path는 완주 느리나 숙련도↑(잠정) | med | 2-1 |
| F5 | 게이미피케이션 최악 함정 = 경쟁 리그/리더보드(CA=477) | **high** | 3-0 |
| F6 | 리그 = dark nudge(동기부여된 유저도 강등 처벌). 공동한옥(채워지기만)이 구조적 회피 | **high** | 3-0 |
| F7 | streak·점수 집착 = 자신감↓·이탈. freeze+관대한 목표로 완화 | med | 3-0 |
| F8 | 과도 게이미피케이션 = 학습저해. XP/도장은 학습행동에 종속 | **high** | 3-0 |
| F9 | 협력도 '공유보상만, 공유목표 없으면' 해롭다 → 주간 공동목표+멤버 가시성 필수 | **high** | 3-0 |
| F10 | 개인 기여 인정 없는 팀 = 의욕상실 → 멤버별 기여 시각화(비경쟁) | **high** | 3-0 |
| F11 | 잘 설계된 협업 = 경쟁과 동률(dark-nudge 없이). 계 제대로 = 정답 | med | 2-1 |
| F12 | 적응형 SRS +12% 일일참여. 책한컷 단어→SRS 정합 | med | 2-1 |

**채택 안 함(검증 탈락 10건)**: 게이미피케이션 효능 일반주장(β=0.440, 0-3), 리더보드 enjoyment↑(0-3), HLR이 Leitner보다 45%정확(1-2), relatedness 메타분석 g=1.776(0-3), 게이미피케이션 옵트아웃 최다지지(1-2). → **"게이미피케이션이 성과를 올린다"는 일반 주장은 근거로 쓰지 않는다.** 채택된 증거는 주로 *해악/함정* 방향.

---

## 3. 완성형 IA

### 3.1 홈 = Lernpfad(path) 본문 승격 ★긴급
- 이미 있는 `learning_path_screen`(한옥 12단계 + 단어팩 노드 ✓/Jetzt/🔒)을 **홈 탭 본문으로** 올린다.
- 현재 홈의 `_PathCard`(카드 하나)·`_SkillPathRail`(가로 레일) → 전체 path로 대체.
- 호랑이 = 현재 위치 마커, 한옥 = path 배경(F1 명시 권고).
- 상단 얇은 바: streak · 일일목표 · XP(오늘 할 일). 책 한 컷 = FAB.

### 3.2 bottom-nav 4탭 재구성
| Stage 1 | → 개편 | 내용 | 근거 |
|---|---|---|---|
| 홈(빈약) | **길 Pfad** | learning_path 본문 + 오늘복습 띠 | F1·2·4 |
| 배우기 | *흡수* | 한글/문법/시나리오 → 길 노드 또는 연습 | F2 |
| 연습 | **연습 Üben** | named: 복습·단어·듣기·말하기 + 게임(초성/워들/끝말잇기) | F3 |
| 단어장 | *흡수* | wordbook/custom/hard → 연습 "단어(Wörter)" 섹션 | F3 |
| — | **계 Gye** | 두레판 + 공동한옥(차별점 승격) | F9·10·11 |
| (AppBar) | **나 Profil** | 통계/도장첩/설정/단어장 | — |

→ 최종 4탭: **길 · 연습 · 계 · 나**. (Duolingo의 홈·연습·리그·프로필과 평행하되, **리그→계 = 경쟁을 비경쟁 협력으로 교체** = 우리의 무기)

### 3.3 Jin "사라짐" 즉시 복구
- 홈=path 본문 → "다음 걸음" 명확(F1).
- 게임/단어 = 연습 탭 named 섹션으로 **노출**(숨김 X).
- 첫 탭 전환 시 코치마크(`feature_coach` 인프라 재활용).

---

## 4. 계(契) — 연구가 지지하는 유일한 소셜 방향 (차별점 핵심)

- **F9**: 공동 한옥(공유보상)만으론 *해롭다* → **주간 공동 목표 명시** + 멤버 가시성 필수. (두레판 이미 보유 → 강화)
- **F10**: 멤버별 기여량 시각화(비경쟁). 두레판 stacked bar가 정확히 정합.
- **F5·6**: 경쟁 리그 **절대 도입 X**. 공동 한옥(채워지기만·안 줄어듦)이 dark-nudge를 구조적으로 회피.
- **F11**: "잘 설계된 협업 = 경쟁과 동률, 단 해악 없음" → **계가 듀오링고 리그보다 우월할 수 있는 학술 근거.**

---

## 5. 리텐션 (신중 — 효능 일반주장은 근거 탈락)

- **streak**: freeze 추가 + 관대한 일일목표(F7 상실공포 완화). `streakDays` 인프라 有, freeze만 추가.
- **XP/도장**: 학습행동 종속 유지(F8). 허영지표 X.
- **경쟁순위**: 도입 X(F5·6).
- **SRS**: 책한컷→`ReviewDeckService`→SRS(F12). 사용데이터 쌓이면 간격 튜닝.
- ⚠️ 일일목표값·푸시타이밍·하트는 **정량근거 없음(openQ)** → 추가조사 후 결정.

---

## 6. openQuestions (별도 deep-research 권장)

1. **온보딩 "가입 나중" 패턴** — 1차 검증 생존 못함. 현 앱 consent/onboarding이 가입·동의를 앞단에 둬 Duolingo와 상충 가능. **온보딩 전용 조사 필요.**
2. 푸시 알림 타이밍·하트/에너지·일일목표 설정값의 리텐션 정량효과.
3. Babbel/Busuu/Memrise 1차 패턴(이번 증거는 전부 Duolingo).
4. 책 한 컷 비표준 어휘 ↔ 선형 path "제시된 순서" 통합(개인화 vs 큐레이션 — 열린 설계 질문).

---

## 7. 로드맵

| Phase | 내용 | 효과 |
|---|---|---|
| **R1 긴급·회귀복구** | 홈=learning_path 본문 + bottom-nav 4탭(길/연습/계/나). `app_shell` 재활용 | Jin "사라짐" 해소 + Duolingo IA 정합 |
| **R2** | 연습 허브 named 섹션(복습·단어·듣기·말하기·게임) 정렬 | F3 발견성 |
| **R3** | 계 주간 공동목표 + 기여 가시화 강화(두레판 위) | F9·10 차별점 |
| **R4** | streak freeze + 일일목표 + SRS 튜닝 | F7·12 리텐션 |
| **R5 조사 후** | 온보딩 재설계 | openQ#1 |

---

## 8. 검증 출처 (1차)

- Duolingo 홈 재설계 — blog.duolingo.com/new-duolingo-home-screen-design (2022)
- Duolingo 백서 DRR-24-04 — duolingo-papers.s3 (2024)
- Duolingo Practice Hub 가이드 — blog.duolingo.com/guide-to-duolingo-practice-hub
- Mogavi et al., 게이미피케이션 오용 — ACM L@S'22, arxiv 2203.16175
- Qiao/Yeung et al., 협력학습 N=156 — LLT 2024
- Settles & Meeder, HLR SRS — ACL 2016, P16-1174

---

## 9. 계 커뮤니티 — 출시 범위 vs 포스트런치 로드맵 (2026-06-12 확정)

### 출시 범위 (구현 완료 — 2026-06-12 세션)
- **멤버 차단(block)**: `users/{uid}.blockedUids` + 멤버 화면 토글 + 피드/응원 클라 필터 (Play UGC 정책)
- **멤버 프로필 카드**: GyeMember에 level/streak denormalize(`syncMyMemberStats`) → 멤버 탭 시 SoriSheet 카드
- **지난주 살림꾼(MVP) 카드**: `weekly_goal_rollover` CF가 `lastWeekMvp`/`lastWeekMvpPacks` 기록 → GyeScreen 축하 톤 1줄 카드 (⚠️ CF 재배포 필요 — Jin)
- **전원챌린지 축하**: 전원 기여 달성 순간 SoriCelebration.burst (2인+, 실행당 1회)
- 기존 dure 5종(두레판·피드·응원·MVP회고·전원챌린지)은 89f32ea에서 완성

### 포스트런치 (Tandem 방향 — 의도적 보류, 근거)
| 후보 | 보류 사유 | 선행 조건 |
|---|---|---|
| 자유 텍스트 채팅 | ML 모더레이션 비용·스팸·신고량 폭증 리스크. 현재 스티커/정형 응원이 모더레이션-안전 | 모더레이션 파이프라인(Cloud DLP or Perspective API)+운영 인력 |
| 피드 reaction(이벤트별 스티커 답글) | GyeSticker.targetEventId 스키마는 준비됨 — UI/rules 추가 필요(M) | v2.1 후보 |
| 공개 계 검색/가입 | 초대코드(bearer) 모델이 GDPR·스팸에 안전. 공개화는 발견성↑ 대신 모더레이션 부담↑ | 신고 처리 SLA + 차단 사용 데이터 확인 후 |
| 1:1 파트너 매칭(Tandem 코어) | 별도 프로덕트 규모: 매칭엔진·DM·신원/안전(미성년 보호)·차단 고도화 | 사용자 기반 + 안전 설계 별도 트랙 |
