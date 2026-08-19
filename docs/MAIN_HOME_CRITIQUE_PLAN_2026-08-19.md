# Hangul Sori — 메인 홈 수석 비판 + 개선 계획

| 항목 | 값 |
|---|---|
| 기준 HEAD | `d7488bcd` (`origin/main`, 2026-08-19, #95+#96+#97 흡수 후) |
| 범위 | 학습자가 매일 여는 **앱 메인** = Sori Stage 5탭 셸 + Today. 웹 랜딩은 같은 약속의 바깥 면. 홈을 먹이는 백엔드만. |
| 이 문서가 하는 일 | 수석 UI/UX + 수석 백엔드 관점의 비판, 개선점, **실행 순서**. 코드는 고치지 않는다. |
| 이 문서가 안 하는 일 | TTS/책 live 배포, 한옥 V1 화면 연결, 에셋 승격, 4방향 틴더 부활, 콘텐츠 화면(듣기·문법·클로즈) 재작업 |
| 이미 있는 문서 | 3일 감사 `docs/MAIN_3DAY_AUDIT_2026-08-19.md` · 콘텐츠 마감 `docs/CONTENT_UIUX_FINISH_PLAN_2026-08-19.md` · 개편2 `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`. **홈 구조 비판은 여기가 정본.** 감사의 P0 운영은 반복하지 않고 가리킨다. |

사용한 스킬: `find-skills`(리더보드 + CLI), `frontend-design`(주제·토큰·시그니처·자기비판), 저장소 `explore-codebase`/`review-changes` 절차. `code-review-graph` MCP는 이 세션에 안 붙어 파일 실독으로 대체했다.

> **취소 (2026-08-19 Jin):** 시각 재설계·목업은 버린다. 홈은 **지금 있는 레이아웃을
> 기기·글자배율·정렬만** 맞춘다. 마당/현판/책가도/문 시안 HTML은 삭제했다.

---

## 0. 한 줄 결론

메인은 **한옥 마당이 아니라 언어앱 대시보드**다. 호랑이·까치는 위에 붙고, 그 아래는 미션 카드·보자기·진행바·퀘스트 리스트가 쌓인다. 백엔드는 **클라 SharedPreferences가 진실**이고 서버는 백업·합성·계 집계만 한다. 지금 학습자를 막는 구멍은 홈 카피보다 **(1) live TTS/책분석이 레포보다 낡은 것, (2) Today가 소스 하나라도 실패하면 오늘을 통째로 숨기는 것, (3) 코스가 있으면 복습·시나리오가 밀리는 것**이다.

#93이 소리·배너·책갈피·색을 고쳤고, #96이 Wanted Sans로 한글 글리프를 복구했다. **홈 IA와 보상 권한은 그대로다.**

---

## 1. 디자인 방향 (frontend-design)

### 주제·청중·한 가지 일

- **주제**: 독일어권 학습자가 매일 여는 Hangul Sori 마당.
- **청중**: DE/EN UI, 한국어를 소리로 배우는 사람. 배지·필·iOS 크롬을 싫어한다 (지속 메모리 `jin-no-ios-style-badges`).
- **화면의 일**: **오늘 할 한국어 한 가지를 시작하고, 집이 자랐다는 감각을 남긴다.** 카탈로그를 보여 주는 일이 아니다.

### 토큰 (이미 있는 것을 지킨다 — 팔레트를 갈아엎지 않는다)

한지·단청은 이 제품의 재료다. 제네릭 “크림+세리프+테라코타”를 **새로 발명하지 않는다.**

| 역할 | 이름 | 값 |
|---|---|---|
| 마당 | 한지 cream / 히어로 매트 | `#FAF6EC` / `#FBF5EB` |
| 행동 | 녹청 | `#1F7A6B` |
| 강조 | 석간주 | `#A0524A` |
| 보상만 | 황 | `#C99A2E` (XP·스트릭 전용, #93 확정) |
| 호랑이 | 주황 | `#FF8C42` |
| 먹 | 다크 배경 | `#0E1A18` (홈 라이트 정본. 다크 전환 없음) |

### 타입

`#96`이 **Wanted Sans**로 한글 11,172자를 번들에 넣었다. 디스플레이 서체를 하나 더 들이지 않는다. 위계는 크기·굵기만 (`SoriTextTheme`). `tokens.dart` 주석의 “Pretendard ExtraBold”는 stale — 다음 문서 정리에서 한 줄 고친다. 배율은 `SoriTypeScale` 하나(#96). 홈에서 `soriStudyScale`을 다시 곱하지 말 것.

### 레이아웃 — 고른 것 / 버린 것

```
고름: 한 마당, 한 CTA
┌─────────────────────┐
│ 칩(스트릭·XP)  프로필 │
│                     │
│   말풍선            │
│        [호랑이/까치] │
│  ░░ 오늘 일 = 마당 ░░│  ← 카드가 아니라 바닥
│  [시작]             │
│  장식 3점이 주변    │  ← 보자기·기둥·등, 리스트 아님
└─────────────────────┘

버림: 지금 스택
히어로 → 21:9 다크 카드 → 보자기 배너 → 한옥 바 → 퀘스트 행
```

Learn/Games는 **고르는 방**, Today는 **오늘의 방**이다. 두 방이 같은 RootHeader+그리드 문법을 쓰면 Today가 죽는다.

### 시그니처 (한 곳에만 힘을 쓴다)

**마당이 곧 오늘의 일이다.** 미션 일러스트는 캐릭터 발밑 바닥(또는 처마 아래 포스터)이고, CTA는 녹청 하나다. 한옥·보자기·퀘스트는 스크롤 섹션이 아니라 마당 소품이다. 큰 숫자+그라데이션 히어로는 쓰지 않는다.

웹 랜딩의 시그니처도 같다: Lucide 아이콘 그리드와 가짜 `62% complete`를 버리고, 앱과 같은 마당 한 컷을 연다.

### 자기비판 — 제네릭이 되지 않게 버린 것

| 유혹 | 왜 버렸나 |
|---|---|
| 크림 배경 + 세리프 디스플레이 + 테라코타 | AI 기본값 1. 한지는 이미 재료. 명조 혼용은 라틴/한글 분열로 폐기된 이력 |
| 다크 + 네온 그린 | AI 기본값 2. 단청이 아님 |
| 01 / 02 / 03 레슨 스텝 | 웹 `site.tsx`가 이미 이 템플릿. 순서가 정보가 아님 |
| 새 디스플레이 폰트 | Wanted Sans가 오늘 막 한글을 복구함. 홈에서 다시 가르면 한·독이 또 갈라짐 |
| 4방향 틴더 덱 | `CONTENT_UI_BIBLE`이 Overhaul 2를 대체. `01bd8849`가 런타임에서 뺌 |

힘을 쓸 곳: **구성(마당 vs 대시보드)**. 팔레트·서체·제스처는 건드리지 않는다.

---

## 2. 수석 UI/UX 비판

심각도: **P0** = 매일 길을 잃음. **P1** = 정체성이 언어앱으로 보임. **P2** = 손맛·일관성.

### P0-U1. Today의 일이 두 개다

학습자는 “오늘 무엇을 하지?”와 “내 집이랑 퀘스트는?”을 한 스크롤에서 동시에 받는다. Hanok·퀘스트는 이미 4·5번째 탭이다. Today `_TodayContent`는 미션 다음에 보자기·한옥 바·퀘스트 행을 붙인다 (`sori_stage_today_screen.dart`).

**증상.** 첫 화면이 카탈로그처럼 길고, CTA가 카드 안에 묻힌다. 탭 4와 정보가 중복된다.

**고침.** Today는 미션 한 덩어리 + 보자기(열 것이 있을 때만). 한옥/퀘스트는 탭으로만. 마당 소품으로 남기려면 진행바·ListTile가 아니라 장식 1점.

### P0-U2. 추천이 코스에 갇힌다

`recommendMission` 우선순위는 코스 > 진행 팩 > due≥10 복습 > 시나리오 (`mission_recommender.dart`). `courseUnits`가 비어 있지 않으면 미완 유닛이 있는 한 **항상 CoursePick**. 카탈로그에 유닛이 있으면 복습 10장이 밀려도 Today는 코스만 가리킨다.

**증상.** SRS가 쌓여도 홈은 “Kurs”만 연다. C레벨은 시나리오 fallback이 있어도 코스가 있으면 안 보인다.

**고침.** 코스가 “오늘의 유일한 길”이 아니라 “기본값”이게 한다. due가 임계를 넘으면 복습을 미션으로 올리거나, 말풍선이 복습을 한 줄로 권한다. 빈 코스 스냅샷을 “첫 미션”으로 채우지 말 것(지금 `currentCourseUnitId == null`이면 첫 미완을 집어 넣는다).

### P0-U3. 소스 하나 실패 = 오늘 없음

`TodayLearningSnapshotLoader`는 course/pack/scenario/review 중 **하나라도** 실패하면 `unavailable`이다. 네트워크가 offline이면 로컬이 살아 있어도 같은 카드다. UI는 미션·보상·한옥 블록을 전부 접는다.

**증상.** 시나리오 JSON 파싱 한 건이 오늘의 코스까지 숨긴다. 오프라인인데 저장된 복습이 있으면 보조 CTA만 남고 “오늘의 일”은 사라진다.

**고침.** 실패한 가족만 빼고, 남은 입력으로 추천을 만든다. `unavailable`은 **원격이 필수인 추천을 고를 수 없을 때**만. 로컬 코스/팩/복습은 오프라인에서도 미션이 된다.

### P1-U4. 크롬이 Material이다

Jin은 배지/필/시스템 아이콘을 거부한다. 메인은 아직 시스템 아이콘 집합이다.

| 위치 | 지금 |
|---|---|
| 하단 5탭 | `Icons.today` / `school` / `sports_esports` / `home_work` / `groups_2` |
| 보자기 | `Icons.redeem_rounded` 36 |
| Learn/Games/Hanok/Gye 헤더 | `Icons.person_outline_rounded` |
| 카탈로그 분(分) | 검정 55% **필** (`_MinutesPill`, `SoriRadius.brPill`) |
| Gye 띠 | `Icons.local_fire_department_outlined` |

히어로·한옥 배너는 Faceted Minhwa인데 내비게이션은 Generic Material App이다.

**고침.** 탭 아이콘 5개만 단청 모티프 PNG로 교체(Material은 errorBuilder). 분 표기는 필이 아니라 카드 제목 옆 작은 글자. 보자기는 이미 있는 `reward_bojagi_closed.png`. 신규 필/칩 금지.

### P1-U5. Learn/Games가 Today와 다른 집

Today는 캐릭터 히어로. 나머지 탭은 `SoriStageRootHeader`(eyebrow + 제목 + 본문 + 사람 아이콘). Learn/Games는 그 아래 히어로 카드 + 그리드. 프로필 입구가 Today 톱바와 헤더에 **두 개**다.

**고침.** 프로필은 Today 톱바 하나. 다른 탭 헤더는 방 이름만. Learn/Games 본문 문단은 잘라 그리드에 공간을 준다.

### P1-U6. 미션 카드가 “다크 히어로 템플릿”이다

`_TodayMissionStage`는 21:9 크롭 + 한옥 스테이지 다크 + 골드 eyebrow + 흰 h1 + 보상 칩 + `Starten`. 활동 제목이 이미 있는데 eyebrow `soriStageTodayMissionEyebrow`가 한 줄 더 있다. 보상은 Material `soriRewardIcon`.

같은 저장소에 `MissionHeroCard`가 있다. **생산 Today는 안 쓴다.** 골든 `design_components_golden_test`만 쓴다. 홈 미션 UI가 두 개다.

**고침.** 생산 경로 하나만 남긴다. 새 카드 위젯을 만들지 말고, 고른 쪽을 마당 바닥에 붙인다. eyebrow는 활동명과 겹치면 삭제.

### P1-U7. 히어로는 줌으로만 산다

클립이 정사각 한지 매트 mp4라 밴드를 키우면 여백만 커진다 (`home_hero.dart` `_kHeroZoom = 1.2`, 상한 1.3). 라이트 배경은 매트 평면 단색 계약 — 그레인·그라데이션 금지(영상 액자). Android는 `verticalDirection: up`으로 텍스처가 형제를 지우는 것을 막는다.

**고침.** 매트 계약은 유지(깨면 홈이 액자가 된다). 까치가 작으면 **새 클립**이지 밴드 확대가 아니다. 캐릭터 AI 생성 금지 — 기존 파일 재합성만.

### P1-U8. 웹 랜딩이 다른 제품이다

`hangul-sori-site-local/app/site.tsx`는 Lucide(`Brain`, `Gamepad2`, `Sparkles`…) + “HOW A LESSON WORKS” 3스텝 + 가짜 **`62% complete`**. 앱 메인의 호랑이 마당과 시각 계약이 없다. 공개 CTA는 TestFlight URL이 아니라 `#tester-access` 폼이다.

**고침.** 히어로를 앱 Today와 같은 마당 한 컷으로. 가짜 퍼센트 삭제. 아이콘은 한 글자(한/소/기) 이미 있는 패턴을 유지하되 Lucide를 줄인다. 스텝 번호는 “듣기 → 말하기 → 복습”이 **실제로 그 순서일 때만** 남긴다.

### P2-U9. 셸이 탭 다섯을 산 채로 둔다

`IndexedStack` + 탭마다 스냅샷 재로드. Today는 히어로 영상, Hanok은 월드, Gye는 피드. 가시 탭만 `TickerMode`라 애니는 멈추지만 **메모리·첫 로드 5배**는 남는다.

**고침.** 구조 변경은 나중. 지금은 비가시 탭의 Future를 취소하고, 영상 lease는 기존 `VideoLeaseCoordinator`만 믿는다. 탭을 4개로 줄이는 것은 Jin 게이트.

### P2-U10. Gye 탭이 헤더를 두 번 쓴다

셸 `soriStageGyePromise` + 불 아이콘 띠 + 임베디드 `GyeTabScreen` 자체 헤드라인. 빈 계는 텍스트가 먼저다.

**고침.** 셸 헤더 또는 임베디드 헤드라인 중 하나. 빈 마당은 `gye_showcase_courtyard.webp` + CTA. 설명 문단은 도움말로.

---

## 3. 수석 백엔드 비판

홈이 호출하는 경로만. Functions 모듈 분할(tts / gye / pronunciation / auth_cleanup / analyze)은 맞다. 문제는 **권한과 배포 시차**.

### P0-B1. live 서버가 레포보다 낡다 — 운영 (코드 없음)

레포 `functions/tts`는 빈 MPEG 거절·환급·12s/7s·선점이 있다. OS 폴백은 #93이 지웠다. **live CF는 구버전.** 새 클라 + 구 서버 = 프리미엄 miss 뒤 **무음**. 배너는 `#93`이 셸에 붙였다 (`TtsUnavailableBanner` in `main.dart`). 책 한 컷 live Gen2는 모듈 빠진 구버전, cache에 원문.

**고침.** `MAIN_3DAY_AUDIT` §C3 순서 그대로. 이 계획에서 배포 명령을 다시 적지 않는다. Jin 운영.

### P0-B2. 진행·XP·도장이 클라 write다

`users/{uid}`는 owner가 `update` 할 수 있다 (`firestore.rules`). 페이로드는 `CloudSync.buildBackupPayload`가 로컬 XP·스트릭·스탬프·퀘스트·SRS JSON을 넣는다. 서버가 합을 검증하지 않는다. `SoriStageRewardReceiptService`는 활동 전후 스냅샷 **델타**다. 영수증은 보여 주기만 하고 권한을 주지 않는다 — 그 반대도 맞다: **권한도 서버가 안 준다.**

**증상.** 재설치 병합은 additiv라 안전하다. 변조·더블 카운트·계 등불 부풀리기는 클라에 열려 있다. Gye 주간 목표는 CF가 집계하지만, 홈 영수증의 `gyeLanternCount`는 `GyeService.myGyeMetas()` 실패 시 **0으로 삼킨다**.

**고침 (단계).**

1. 지금: 영수증은 표시 전용 유지. 홈에서 “보상 획득”을 서버 권한처럼 말하지 말 것.
2. 다음: XP/스탬프/한옥 해금은 **append-only 이벤트**로만 올리고, rules가 감소·점프를 거절. 기존 CAS revision을 그 이벤트에 붙인다.
3. 계 등불은 클라 합산이 아니라 `gye/{id}` 필드 하나만 읽는다. 실패는 0이 아니라 `null`(표시 생략).

한옥 V1 grant catalog를 홈에 몰래 연결하지 말 것 — 분모가 달라 집이 낮아진다.

### P0-B3. Today 로더가 fail-closed다 (U3의 서버 면)

네 소스를 병렬로 읽는 것은 맞다. 실패를 한 비트로 접는 것이 틀렸다. `CourseProgressService.readForDisplay()`가 던지면 코스만 비워야 하는데 Today 전체가 내려간다. `connectivity_plus`는 **전송 계층**이지 서버 생존이 아니다. `unknown`은 오프라인으로 안 치는 것은 맞다. `offline`을 미션 차단으로 쓰는 것은 틀리다.

**고침.** U3와 같은 PR. 소스 실패는 `unavailableSources`에만 남기고, `recommendMission`은 성공한 입력만 받는다. 원격이 필요한 pick(동적 시나리오 등)만 reason을 붙인다.

### P1-B4. 탭마다 전체 스냅샷을 다시 만든다

`SoriStageProgressionService.load`는 Today + 한옥 투영 + 퀘스트 전원 + 계 등불 + 활동 진행 + 게임 베스트를 한 덩어리로 만든다. Today·Learn·Games·Hanok이 활성화될 때마다 다시 부른다. 보상 캡처는 활동 **앞뒤로 두 번** 더 부른다.

**증상.** 홈 탭 전환이 로컬이어도 버벅인다. 캡처가 실패하면 학습은 열리지만(fail-open) 디스크를 두 번 읽는다.

**고침.** 스냅샷을 셸 수명으로 한 번 들고, 탭은 구독만. 캡처는 `before`를 캐시에서 쓰고 `after`만 읽는다. 계 등불은 계 탭/영수증이 필요할 때만.

### P1-B5. 한옥이 두 진실이다

| 체계 | 누가 쓰나 | 분모 |
|---|---|---|
| 레거시 `HanokStageService` | 홈 바, `HanokWorldScreen` | 팩 비율, 표시 7조각 (`_HanokProgress` `total = 7`) |
| V1 `HanokStateService` + projector | `cloud_sync`, `account_reconciliation`, cutover **테스트** | 검증된 can-do 86 |

홈 `built / 7`은 V1 16/16/18…과 다른 이야기이다. 클라우드에는 `hanok_state_json`이 이미 올라간다. UI는 레거시만 읽는다.

**고침.** Jin 노출 게이트 전 **코드 0**. 연결은 cutover + projector + 골든을 한 커밋에. 중간만 열면 집이 내려간다. 홈 바의 `7`을 86으로 바꾸지 말 것.

### P1-B6. 계정 문서가 JSON 덩어리다

루트 문서에 `srs_json`, `custom_packs_json`, `course_mastery_json`, `hanok_state_json`. 한도 1MB (`CloudSyncService`). Bookshelf는 generation으로 뺐다(맞음). SRS 격리 시 업로드를 건너뛰는 것도 맞음.

**위험.** 단어장·코스가 늘면 루트가 1MB에 닿고 백업이 통째로 실패한다. 홈 스트릭이 그날부터 클라우드에 안 남는다.

**고침.** 진행 맵(XP/스트릭/스탬프)과 무거운 JSON을 컬렉션으로 더 쪼갠다. 홈이 읽는 필드는 작게 유지. 지금 당장은 크기 가드 + 텔레메트리(문서 바이트)만.

### P1-B7. 시작 레이스

`58379721` 이후 UI가 클라우드·Auth보다 먼저 뜬다. 동적 TTS는 uid+App Check. 홈 미션 자체는 로컬이라 열리지만, 첫 발화가 배너로 죽는다.

**고침.** 프리미엄 `speak` 직전 `ensureSignedIn`을 짧게 한 번. 스플래시 앞으로 클라우드를 되돌리지 말 것.

### P2-B8. 죽은 홈 위젯

`MissionHeroCard`는 골든만. `SoriSwipeCard`는 호출자 0(`01bd8849`). 다음 세션이 골든/핸드오프를 보고 틴더나 두 번째 미션 카드를 되살릴 수 있다.

**고침.** 호출자 0 확인 뒤 삭제. 핸드오프 §1-1·§1-2 상단에 “바이블이 대체” 한 줄 (`MAIN_3DAY_AUDIT` G).

---

## 4. 하지 말 것

- 레거시 한옥 분모를 V1 86에 갈아끼우기
- 4방향 틴더 부활
- 히어로 밴드 확대 / 매트 위에 그레인
- 캐릭터 PNG 신규 AI 생성
- pending_review를 pubspec만 넣고 올리기
- TTS 4단 폴백 되돌리기
- `MissionHeroCard`와 `_TodayMissionStage`를 둘 다 살린 채 세 번째 카드 추가
- 이 계획과 콘텐츠 화면(#93 잔여)과 한옥 승격을 **한 PR에 섞기**
- `chore/hanok-pr-e-prep` 재개

---

## 5. 실행 순서

운영과 코드 PR을 섞지 않는다. 날짜가 아니라 **의존성**이다.

### Jin — 운영 (이 브랜치 밖)

1. TTS·Rules·책 Gen2 배포 (`MAIN_3DAY_AUDIT` §C3). 홈 배너가 거짓 양성이 아닌지 실기기에서 확인.
2. 한옥: 레거시 유지 vs V1 연결. 연결 전 홈 바를 만지지 말 것.
3. 탭 아이콘·보자기 PNG 시각 승인. 승인 전 대규모 홈 재배치 금지.

### PR H1 — Today가 정직해진다 (로직, 시각 최소)

> **정정 (코드 재독):** 아래 두 줄은 테스트 계약과 충돌한다. **구현하지 말 것.**
> - 소스 실패 → Today unavailable: `today_learning_snapshot_test` + `sori_stage_today_availability_test`가 잠근다.
> - 코스 > 팩 > 복습≥10 > 시나리오: `mission_recommender_test`가 잠근다.
>
> **먼저 고칠 것:** Today 복귀/`SoriStageProgressionService.load`에서 `QuestTracker.syncEarnedRewards()` (보자기 persist). 캡처 CTA는 catalog와 같은 `loadSnapshot` seam. `currentCourseUnitId`가 끝난 유닛이면 fallback.

- ~~로더: 소스 실패를 fail-closed로 접지 않음. 오프라인+로컬 미션 유지.~~ 계약. C 목업은 제품 선택지일 뿐.
- ~~`recommendMission`: due가 임계면 복습이 코스를 이길 수 있음.~~ 계약. 바꾸지 않음.
- 테스트: 기존 Today availability + recommender는 **유지**. 추가할 것은 Today 복귀 뒤 보자기 persist.

완료 조건: 로컬 데이터만으로 Today가 미션을 보여 준다. 원격 실패는 배너/unavailable 카드가 **그 가족만** 설명한다.

### PR H2 — ~~Today가 마당이 된다~~ **취소 (Jin, 2026-08-19)**

시각 재설계·목업 HTML은 하지 않는다. 홈 크롬·IA·색은 그대로 두고
**기기 폭·글자배율·정렬·오버플로만** 맞춘다. 시안 파일은 삭제됨.

### PR H3 — 크롬 (H2와 병행 가능, 에셋 게이트)

- 탭 아이콘 5 · 보자기 썸네일 · 분 필 제거 · 프로필 입구 하나 · Gye 이중 헤더 제거.
- ARB 대칭. 래칫/타이포 가드.

### PR H4 — 홈 읽기 비용 (H1과 병행 가능)

- 셸 스냅샷 1회. 캡처는 after만. 계 등불은 필요할 때. 실패는 0이 아니라 생략.

### PR H5 — 웹 랜딩 (사이트 전용 CI)

- 가짜 62% 삭제. Lucide 축소. 마당 히어로 1컷. DE/EN/KO 카피만. 앱 코드 0.

### 나중 (게이트)

- 계정 루트 쪼개기, XP append-only rules, 한옥 V1 연결, 죽은 `SoriSwipeCard` 삭제, `tokens.dart` Pretendard 주석.

---

## 6. Jin이 고를 것

1. Today에서 한옥/퀘스트 블록을 **빼도 되는가?** (이 계획의 권고: 뺀다)
2. due 복습이 코스보다 앞설 수 있는가? (**계약: 아니오.** `mission_recommender_test`. 바꾸려면 테스트부터)
3. 탭 아이콘을 커스텀 PNG로 바꿀 것인가, 일단 시스템 아이콘을 줄이기만 할 것인가?
4. 웹 랜딩을 이번 라운드에 넣을 것인가?

1이 아니요면 H2는 보자기 정리+미션 중복 카피만 하고 마당 재배치는 하지 않는다.

---

## 7. 검증

이 문서는 코드 변경이 없다. 근거는 다음 실독이다.

- `lib/screens/sori_stage/sori_stage_{shell,today,catalog,hanok,gye}_screen.dart`
- `lib/services/{sori_stage_progression_service,sori_stage_reward_receipt_service,today_learning_snapshot,mission_recommender,cloud_sync,hanok_state_service,hanok_structure_projection_service}.dart`
- `lib/widgets/sori/{home_hero,mission_hero_card}.dart` — 후자는 생산 호출 0
- `firestore.rules` `users/{uid}` owner update
- `hangul-sori-site-local/app/site.tsx` 가짜 62%
- HEAD `d7488bcd` — #93 소리/배너, #96 Wanted Sans, 한옥 V1 UI 0, TTS live 미배포
