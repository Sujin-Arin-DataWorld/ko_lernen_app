# 디자인 전면 세련화 계획 — "촌스럽다"를 끝내는 로드맵

**작성** 2026-08-02 (Cowork 세션) · **대상** `ko_lernen_app` v2.0.2+8
**입력** Jin 실기기 스크린샷 16장(2026-08-02 17:44~17:52 + 2026-08-03 00:59~01:00, 1080×2400 독일어 로케일) + 레포 소스 전수 정찰(`tokens.dart`·`theme.dart`·`home_screen.dart`·`practice_hub_screen.dart`·`app_de.arb`·온보딩 3화면·AGENTS.md)
**선행 문서** `HOME_REDESIGN_PLAN_2026-07-31_v2.md` · `SESSION_2026-07-31_lernpfad-zigzag-assets.md` · `DESIGN_CRITIQUE_ONBOARDING_2026-07-31.md` · `ASSET_GENERATION_BIBLE.md`
**요청 범위** ① 튜토리얼~앱 전 화면 세련화 ② 홈/Üben 정보구조 ③ 현재 미션 중심 홈 ④ 번역 누수 ⑤ 로딩·오류·접근성 통일 ⑥ **조이(까치)·태고(호랑이) 캐릭터 일관성**

> ⚠️ 이 문서는 **계획서다** — 코드·에셋 변경 0. 마스코트 이미지는 절대 규칙대로 **Jin이 직접 제작**하며, 이 문서는 대상 목록과 브리프 조건만 확정한다.

---

## 0. 여섯 줄 요약

1. **"촌스럽다"의 최대 지분은 색이 아니라 표면 처리다.** 크림 배경(#FAF6EC) 위에 크림 카드(#F1ECDC, 대비 1.09:1)를 얹고 전부 얇은 테두리로만 구분한다 — 카드가 떠오르지 않으니 화면 전체가 한 장의 골판지처럼 보인다. 처방은 이미 토큰에 있다(`lightSurfaceRaised #FFFDF8` + 그림자). **테두리를 빼고 띄우는 것**이 이 계획의 1번 수술이다.
2. **홈은 현재 "경로 2개 + CTA 4개 + 수치 카드 3개"가 경쟁하는 게시판이다.** Lernpfad 전체 임베드(`home_screen.dart:584`)와 시나리오 "Dein Pfad"(`:692`)가 같은 화면에 있다. **홈 = 오늘의 미션 1개 중심**으로 재편하고, 경로 전량은 `/path` 전용 화면으로 이관한다.
3. **캐릭터는 배선·이름(조이/태고)이 이미 정리됐는데, 온보딩 3장이 캐논 화풍 밖이다** (`book_scan.png`·`gye_gate_grand.png`·`hanok_construction.mp4` — painterly/이질 렌더 + 그림 속 영어 UI). 온보딩만 고치면 첫인상~홈까지 화풍이 하나로 잇긴다.
4. **독일어 문구 결함이 세련미를 갉아먹는다.** "1 Tage in Folge" 복수형 버그(실기기 재현), 요일 M·D·M·D·F·S·S 중복 문자, "Pack" 용어, 페르소나 4개 혼재(Der Tiger/Sori/Joy/Taego), 그림 속 영어. ARB 감사 1회로 잡는다.
5. **로딩·오류·빈 상태는 표준 위젯이 이미 있다** (`SoriEmptyState`·`app_loading`·`app_error`) — 문제는 전수 적용이 안 된 것. 규정을 정하고 화면별 체크리스트로 닫는다.
6. 총 로드맵 **R0~R7, 실작업 약 7.5일 + Jin 에셋 병행**. 선행 계획(v2)의 완료분(Phase A·0a·P1·0b) 위에서 시작하며, 남아 있던 Phase 2(홈 위계)를 이번 안으로 대체·확장한다.

---

## 1. 이번 계획의 위치 — 선행 작업과의 관계

| 선행 계획 항목 (HOME_REDESIGN v2) | 상태(스크린샷·NEXT_STEPS 기준) | 이번 계획에서 |
|---|---|---|
| Phase A — assets 159MB 다이어트 | ✅ 138MB (다운스케일 32장) | 유지, R6에서 신규 에셋도 같은 규격 준수 |
| Phase 0a — 주 CTA 대비 수정(주황 채움 + 먹 라벨 + `fillOutline` 보강 테두리) | ✅ 적용 확인(스크린샷 "Jetzt lernen" 먹색 라벨) | 유지 |
| Phase 1 — 캐릭터 배선(MascotPreference·설정 진입점) | ✅ 홈 히어로가 선택 캐릭터(까치/호랑이) 반영 확인 | §5에서 "화풍" 층위로 확장 |
| Phase 0b — 카드 대비(`lightSurfaceRaised` 3.27:1) | ✅ 토큰·카드 반영 | **§4에서 한 걸음 더: 테두리 다이어트 + 그림자 중심** |
| Phase 2 — 홈 정보 위계 | ❌ 미착수 | **§6이 대체** (Lernpfad 임베드 반전 반영) |
| 조이·태고 리네이밍 (l10n 4키) | ✅ `characterRomanTiger=Taego` 등 | 문구 페르소나 통일로 확장(§7) |

**중요 — 요구 반전 1건.** 2026-07-31 세션에서 Jin 지시는 "팩을 접거나 '+N개 더'로 숨기지 않는다 — 모든 pfad가 100% 트리거"였고, 그 결과가 지금의 홈 전체 임베드다. 이번 요청("전체가 다 보여서 너무 길고 지저분")은 이를 뒤집는다. 이 계획은 **"홈 = 미리보기 3노드 / `/path` = 전량 노출·100% 트리거 유지"**로 두 요구를 동시에 만족시키는 안을 기본값으로 한다 → 확정은 §11 Q1.

---

## 2. 화면 전수 검토 — 16장 크리틱

### 2.1 온보딩 프리뷰 3장 (`onboarding_preview_screen.dart`)

| # | 발견 | 심각도 | 처방 |
|---|---|---|---|
| O-1 | **슬라이드 화풍이 캐논(Faceted Minhwa) 밖** — "Ein Foto" 슬라이드의 호랑이·까치는 별개 렌더 스타일, "Dein Hanok wächst"는 painterly 실사풍(호랑이·까치 포함) | 🔴 | §5.2 교체 목록. 캐릭터 등장 컷은 캐논 스타일로 Jin 재제작, 정경 컷은 캐릭터 제거 버전도 가능 |
| O-2 | **그림 속 영어 UI 다수** — `book_scan.png` 내부에 "Scan Korean · Vocabulary · Grammar · Subject + Verb · Study · Review · My Page · Scanning" 등 | 🔴 | 재제작 시 **무문자 목업** 원칙(§7.4). 에셋에 UI 언어를 굽지 않는다 |
| O-3 | "Ein Foto" 슬라이드 본문 마지막 줄("…auf deinem Gerät.")이 페이지 도트·CTA와 겹쳐 잘림 | 🟡 | 본문 영역 `Flexible` + 최소 여백 토큰화. 시스템 글꼴 200%에서 재검증 |
| O-4 | 다크 배경 슬라이드(1·3)와 라이트 슬라이드(레벨 선택) 사이 **명암 점프** — 흐름의 톤이 두 번 꺾인다. 다크 배경에선 상태바 아이콘 대비도 약함 | 🟡 | **온보딩 전 슬라이드를 한지 라이트로 통일**(§6.5). 레벨 화면 v4·앱 본편과 톤 연결 + `SystemUiOverlayStyle` 문제 소멸 + 캐릭터 클립(multiply, 밝은 배경 전용) 사용 가능해짐 |
| O-5 | "12 Stufen, die du wachsen siehst" 등 본문이 4~5줄 장문 — 온보딩 독해 부담 | 🟢 | 슬라이드당 헤드라인 + 본문 2줄 이내로 압축(§7.3) |
| O-6 | `Überspringen` 톤 — 다크 위 회색 필 버튼이 유일한 상단 요소로 무거움 | 🟢 | 라이트 통일 시 텍스트 버튼으로 강등 |

### 2.2 레벨 선택 + Google 백업 시트

| # | 발견 | 심각도 | 처방 |
|---|---|---|---|
| L-1 | 레벨 화면 자체는 v4 개편이 반영돼 기준선 양호(한지 배경·카드 위계) — **이 화면이 앱의 "세련됨 기준점"** | ✅ | 이 화면의 표면·타이포 문법을 전 앱으로 확산(§4) |
| L-2 | 백업 시트가 레벨 선택 위에 겹쳐 올라옴 — 결정 2개(레벨/계정)가 한 시점에 경쟁 | 🟡 | 시트는 **레벨 확정 후** 또는 첫 팩 완료 후로 지연(기존 `accountNudge` 트리거 재사용) |
| L-3 | 시트의 호랑이 PNG는 캐논 준수 ✅ — 다만 배경 흰 사각과 시트 크림의 경계 미세 노출 | 🟢 | 캐릭터 PNG 뒤 배경색 = 시트 surface 동일 상수 (path_trail 불변식 (3)과 동일 규칙) |

### 2.3 홈 4장 (17:52 구빌드 + 00:59 신빌드)

| # | 발견 | 심각도 | 처방 |
|---|---|---|---|
| H-1 | **한 화면에 경로 2개** — Lernpfad 지그재그 전체 임베드 + "Dein Pfad 0/14"(시나리오 레일). 개념 구분("팩 경로" vs "미션 경로")이 시각적으로 전달 안 됨 | 🔴 | §6.1 — 홈에는 **경로 미리보기 1개**만. 시나리오 레일은 미션 히어로에 흡수 |
| H-2 | **Lernpfad 임베드가 잠금 노드 수십 개를 회색으로 나열** — "회색 벽" 스크롤. 길고 지저분하다는 체감의 직접 원인 | 🔴 | 홈 임베드 제거 → 미리보기 3노드(§6.2). `/path`는 전량 유지 + 챕터 헤더·현재 노드 자동 스크롤 |
| H-3 | **CTA 경쟁 4개** — "Jetzt lernen"(주황) vs "Heute empfohlen→Los geht's!"(녹청) vs "Dein Tageskurs" vs 경로의 "Jetzt" 노드. 색도 주황/녹청 혼재 | 🔴 | 화면당 filled 주 CTA 1개 규칙(§4.4). 나머지는 카드 탭/텍스트 버튼으로 강등 |
| H-4 | **인사 메시지 이중 발화** — 헤더 "Deine nächste Alltagsmission ist bereit." vs 말풍선 "Sollen wir kurz wiederholen?" — 서로 다른 행동을 동시에 지시 | 🟡 | 발화는 캐릭터 말풍선 1곳으로 단일화, 헤더는 인사만(§6.1) |
| H-5 | **수치 과밀** — 스트릭 카드에 "1 Tage / Lv 1 / 0 XP / Lv 1 / 진행바 0%" — 같은 정보 중복 + 신규 유저에게 0 세 개 | 🟡 | 컴팩트 스탯 스트립 1줄(스트릭·주간 디딤돌만). 레벨·XP는 프로필로 |
| H-6 | "Heute empfohlen: Im Starbucks bestellen **A2**"가 방금 A1 시작한 유저에게 노출 | 🟡 | 추천 레벨 정합 가드: `recommendedLevel ≤ userLevel` (§6.1 규칙 R-REC) |
| H-7 | "Willkommen zurück!" + streak 1 + 0 XP 조합 — 문구·데이터 불일치 인상 (0b-3 수정의 경계 조건) | 🟡 | QA 시나리오에 "가입 2일차·XP 0" 케이스 추가(§12) |
| H-8 | 상단 로고+워드마크와 상태바 밀착, 설정 기어만 우측 — 헤더가 장식 없이 허전한데 아래는 과밀 | 🟢 | 헤더 = 워드마크 + 스트릭 칩 + 설정(48dp) 고정(§6.1) |
| H-9 | 스크린샷의 빨간 "60"은 **MIUI/개발자옵션 FPS 카운터로 추정** — 앱 결함 아님. 단 스토어 스크린샷 촬영 시 반드시 끌 것 | ℹ️ | 릴리스 스크린샷 체크리스트(§12) |

### 2.4 Lernpfad 임베드 2장 (00:59)

| # | 발견 | 심각도 | 처방 |
|---|---|---|---|
| P-1 | 지그재그·도장 노드·마스코트 클립 등 **경로 자체의 조형은 성공적** — 문제는 위치(홈)와 노출량 | ✅ | 조형 유지, `/path`로 이관 |
| P-2 | 잠금 노드가 균일 회색조 45% — 화면의 70%가 회색 → "죽은 화면" 인상 | 🟡 | 잠금 = 회색 대신 **한지 저채도 톤**(단청 모티프 색 15% 알파) + 레벨 챕터 헤더로 리듬 부여(§6.2) |
| P-3 | 노드 라벨 "Familie & Beziehun…" 말줄임 — 독일어 복합어 잘림 | 🟡 | 라벨 2줄 허용(이미 슬롯 136dp), `maxLines` 금지 원칙 재확인 |
| P-4 | 현재 노드 마스코트 클립과 "Jetzt" 배지는 잘 작동(먹 글자 수정 반영 확인) | ✅ | 유지 |

### 2.5 Üben 3장

| # | 발견 | 심각도 | 처방 |
|---|---|---|---|
| U-1 | **"1 Tage in Folge"** — 독일어 복수형 버그 실기기 재현 (`hubPracticeStreak`) | 🔴 | ICU plural 도입(§7.1). 동류 키 6개 일괄 |
| U-2 | 카드 19장(Lernen 4·Spiele 11·Wörter 4)이 전부 동일 무게(아이콘+제목+부제) — 훑어도 위계가 없다. 3섹션 구조 자체는 정상 | 🟡 | 섹션당 featured 1 + 그리드(이미 구현됨)를 살리되, **표면 v2**(테두리→그림자)로 시각 리듬 회복(§4.2) |
| U-3 | "Heute wiederholen"이 홈(`homeReviewTitle`)과 Üben(`reviewTitle`)에 중복 — 같은 이름, 두 집 | 🟡 | 단일 소스 규칙: 홈=오늘 할 일 묶음에서만, Üben=Wörter 섹션에서만. 명칭 동일 유지(§6.3) |
| U-4 | 아이콘이 Material 심볼 + 색만 다름 — 단청 도장·한옥 모티프 자산이 있는데 미활용 | 🟢 | R6에서 `motifForPackId` 8모티프를 섹션 아이콘으로 확장 검토(발주는 IA 확정 후 — v2 §3-4 보류 판정 유지) |
| U-5 | "Wordle" — 타 상표 게임명 노출 | 🟡 | §7.2 용어 결정 Q5 (예: "Hangeul-Rätsel") |

### 2.6 Lerngruppe · Profil

| # | 발견 | 심각도 | 처방 |
|---|---|---|---|
| G-1 | Lerngruppe 탭이 설명 카드 1장 + 버튼 2개, 화면 2/3 공백 — 미완성 인상 | 🟡 | `SoriEmptyState` 문법으로 재구성: 조이 일러스트 + 혜택 3줄 + CTA 1/보조 1 + "공동 한옥" 미리보기 1장(§6.4) |
| G-2 | Profil "Kontowechsel pausiert" 시스템 알림이 최상단 상시 카드 — 평시엔 무의미한 기술 문구 | 🟡 | 이벤트 발생 시에만 노출(dismissible), 평시 숨김. 문구도 사용자 언어로(§7.3) |
| G-3 | "Mit Google sichern" 버튼이 비활성처럼 보이는 회색 채움 — 실제 활성 여부와 시각 상태 불일치 | 🟡 | 활성=filled primary / 비활성=outline+disabled 규칙 통일(§4.4) |
| G-4 | 게스트 아바타(조이)는 캐논 준수, 메달리온 평면 fill 반영 확인 | ✅ | 유지 |

### 2.7 공통 (전 화면)

- **요일 트래커 "M D M D F S S"** — M·D·S가 두 번씩. 독일어 표준 2자(Mo Di Mi Do Fr Sa So)로 (§7.1).
- **상태바 아이콘 대비** — 다크 온보딩에서 어두운 아이콘. 온보딩 라이트 통일 시 자동 해소.
- **전부-테두리 카드** — 모든 화면 공통. §4.2가 근본 처방.
- **로딩·오류·빈 상태 편차** — 표준 위젯 존재하나 화면별 적용 불균일 (§8).

---

## 3. 진단 — "촌스럽다"의 6가지 실제 원인 (기여도 순)

1. **표면(70%가 여기서 온다)** — 크림 위 크림(1.09:1) + 전부 얇은 테두리 + 그림자 부재. 0b가 카드 바탕을 올렸지만 **테두리 중심 문법**은 그대로다. 테두리 카드가 12장 쌓이면 "표"처럼 보이고, 그림자 카드가 6장 떠 있으면 "제품"처럼 보인다.
2. **밀도와 중복** — 홈 블록 12개(히어로, 스탯, 디딤돌, CTA, 경로 2, 추천, 복습, 코스, 오늘의 글자…), 두 곳의 "Heute wiederholen", 4개의 CTA. 위계가 없으면 어떤 팔레트든 촌스러워진다.
3. **캐릭터 화풍 혼재** — 캐논(Faceted Minhwa) vs painterly(온보딩 정경) vs 이질 렌더(book_scan). 첫 60초(온보딩)에 세 화풍을 다 보여준다 — 브랜드가 미성립 상태로 홈에 도착한다.
4. **타이포 위계 압착** — 전 표면 w800 편중(가드 래칫 189를 이미 초과했던 전력), 카드 제목 14px w800 vs 본문 12px — 크기 차 대신 굵기만으로 위계를 내다 보니 "전부 소리치는" 화면. 독일어 복합어 말줄임 다수.
5. **색 운용 규칙 부재** — 팔레트(v6.0 단청)는 이미 세련됐다. 문제는 운용: 화면당 filled CTA 2색 공존, 잠금 회색 벽, 카드 액센트 5색 산발(Üben 15카드가 무작위 색), gold 계열 저대비 사용처 잔존.
6. **문구 마감** — 복수형 버그, 요일 중복 문자, 페르소나 4개(Der Tiger/Sori/Joy/Taego), 그림 속 영어, 시스템 문구("Kontowechsel pausiert") 노출. 독일어 사용자는 여기서 "미완성"을 읽는다.

> 결론: **팔레트 교체·리브랜딩 불필요.** 기존 토큰 위에서 ①표면 문법 교체 ②홈 IA ③온보딩 화풍 통일 ④문구 마감 — 네 손잡이만 당기면 "세련됨"은 따라온다.

---

## 4. 디자인 원칙 & 시스템 보강 (기존 토큰 위에)

### 4.1 레이어 모델 — "한지 위 백자"

| 레이어 | 토큰 | 규칙 |
|---|---|---|
| 바닥 | `lightBg #FAF6EC` (한지) | Scaffold 전용. 질감은 `hanji_texture.dart`(코드 페인터)만 |
| **카드** | **`lightSurfaceRaised #FFFDF8`** + `SoriElevation.low` | **기본 카드 = 테두리 없음 + 그림자.** 흰 한지가 크림 위에 "떠 있는" 문법 |
| 선택형 UI | raised + `lightBorderStrong #978C73` 1.5px | 라디오·레벨 카드·선택지처럼 **경계 자체가 정보**일 때만 테두리 |
| 강조 카드 | `primarySoft`/`accentSoft` 채움 | 화면당 1장 이내 |
| 장식 | `HanokColors` (처마·단청 divider·도장) | 정보 전달 금지, 순수 장식 |

### 4.2 테두리 다이어트 (이 계획의 1번 수술)

- `card.dart`의 기본 variant: `border: lightBorder 1px` → **`border: none` + `SoriElevation.low`**. `lightBorder`는 divider 전용으로 강등.
- `accent != null` 색 코딩 분기는 유지하되 **좌측 4px 액센트 바** 또는 아이콘 배지로 표현 형식 변경 — v2 §0b-2가 경고한 "카드별 색 코딩 소실" 회피.
- 다크모드: 그림자가 안 보이므로 다크만 `darkBorderStrong` 유지 (`SoriSurfaces` 분기, 기존 토큰).
- **회귀면 경고(v2 계승): `SoriCard`는 34개 파일 사용.** 골든 테스트 선행 + 라이트/다크 실기기 확인 필수.

### 4.3 타이포 위계 복원

| 층 | 스타일 | 용처 |
|---|---|---|
| Display/H1 | 26~32 **w800** (기존 `SoriTextTheme`) | 화면당 1개 (온보딩 헤드라인·화면 타이틀) |
| 카드 제목 | 15~17 **w700** | w800 금지 — 래칫(`typography_guard_test` ≤189) 여유 확보 |
| 본문 | 14~15 w500 | 최소 12.5px (온보딩 크리틱 규칙 전 앱 확장) |
| 라벨/칩 | 12.5~13 w700 | 대문자 변환 금지(독일어) |

- **`maxLines:1 + ellipsis` 전면 금지** (홈 7곳 + 경로 라벨). 2줄 허용 + 시스템 글꼴 200% 테스트.
- 숫자는 `numeral`(tabular) 유지. 한글 학습 콘텐츠는 라틴보다 +1~2px (온보딩 크리틱 §3 규칙).

### 4.4 색 운용 3규칙

1. **화면당 filled 주 CTA 1개** — 색은 구현 반영본 유지: `tiger` 채움 + `onFill()` 자동 먹 라벨(7.22:1) + `fillOutline()` 보강 테두리. 보조 = `primary` outline/tonal, 3순위 = 텍스트 버튼.
2. **모듈 카드 액센트는 섹션당 1색** — Üben: Lernen=`primary`, Spiele=`gold(OnLight)`, Wörter=`accent` 계열로 수렴 (19카드 7색 산발 종료).
3. **잠금·비활성은 회색이 아니라 저채도 한지톤** — `surfaceAlt` 채움 + 모티프 색 15% 알파. "죽은 회색 벽" 제거.
- 자동 가드 유지: `SoriColors.onFill()`/`fillOutline()` — 신규 색 조합은 반드시 이 헬퍼 경유.

### 4.5 다크모드 범위

이번 범위는 **라이트 고정 유지**(현행 `themeMode.light`). 단 §4 변경분은 전부 `SoriSurfaces` 분기로 작성해 다크 부채를 늘리지 않는다. 캐릭터 클립(multiply·흰 배경 소스)은 **밝은 배경 전용**이라는 기술 제약이 다크 전환의 실질 블로커임을 명시해 둔다(§5.4).

---

## 5. 캐릭터 시스템 — 조이(까치)·태고(호랑이) 일관성 규정

### 5.1 캐논 재확인 (변경 없음 — 강제 수단만 추가)

- **화풍**: "Faceted Minhwa (모던 면 분할 민화)" — 고밀도 텍스처 저폴리 + 종이결, **외곽선 없음**. 프롬프트 소스는 `docs/ASSET_GENERATION_BIBLE.md` 단일.
- **정본**: 호랑이 = `mascot/tiger_idle.png` 계열 · 까치 = `magpie_perched/wingup/wingdown` 계열. 콧수염 점 금지, 불쌍한 인상 금지, 평면 벡터풍 전면 거부.
- **제작 주체**: 신규 캐릭터 이미지는 **Jin이 직접 제작**. 에이전트는 요청 없이 생성하지 않는다.
- **이름**: 태고(Taego)=호랑이·산군, 조이(Joy)=까치·길조 (l10n `characterRoman*` 키 반영 완료). "든든이"는 계(Gye) 칭호로만 잔존 — 혼용 금지.

### 5.2 화풍 위반 인벤토리 (Jin 제작 대상 — 우선순위순)

| # | 에셋 | 사용처 | 위반 내용 | 브리프 조건 |
|---|---|---|---|---|
| 1 | `assets/illustrations/onboarding/book_scan.png` | 프리뷰 슬라이드 "Ein Foto statt 30-mal tippen" | 캐릭터 렌더 이질 + **그림 속 영어 UI 7건** | 캐논 화풍 태고+조이 / 폰 목업은 **무문자**(빈 스캔 프레임+한글 낱자만) / 라이트 한지 배경 |
| 2 | `assets/illustrations/gye/gye_gate_grand.png` + `assets/video/loops/hanok_construction.mp4` | 슬라이드 "Dein Hanok wächst" | painterly 실사 호랑이·까치·정경 | 안 A: 캐릭터 없는 한옥 정경(최소 수정) / 안 B: 캐논 캐릭터 포함 재제작. **영상 재제작 시 규격 계약 준수: 960×960·24fps·CRF19·faststart·무음** + 전 프레임 픽셀 검수 |
| 3 | `assets/illustrations/onboarding/tiger_crystal.png` | 슬라이드 "5 Minuten am Tag genügen" | 화풍은 근접하나 **다크 배경 + 청색 크리스탈**이 단청 어휘 밖 | 슬라이드 라이트 통일에 맞춰 재제작 — 스트릭 실드 은유 유지 시 `gold`/단청 황 계열 오브제 권고 → §11 Q4 |
| 4 | `tiger_sleepy` · `tiger_thinking` (구 지적) | Mascot 폴백 포즈 | 화풍 이질 (AGENTS.md 기존 교체 1순위) | 캐논 포즈 세트에 맞춰 재제작 (기존 항목 승계) |

**신규 생성 0개 원칙 재확인**: 위 4건 외에는 기존 자산으로 충분하다(v2 §3 판정 유지). 온보딩 외 화면(홈·경로·프로필·결과)은 이미 캐논 준수 — 스크린샷 L-3·P-4·G-4로 확인.

### 5.3 역할·등장 맵 (운용 규정)

| 상황 | 캐릭터 | 근거/상태 |
|---|---|---|
| 홈 히어로·인사 | **선택 캐릭터** (MascotPreference) | 배선 완료 — 유지 |
| 승리·축하 (정답률 ≥50%, 팩 완료, 마일스톤) | **조이** (길조) | 코드 승패 연출 9곳 — **일괄 치환 금지** (v2 §5.3 ②분류) |
| 위로·격려 (정답률 <50%, 오답) | **태고** (묵직한 힘) | 동상 |
| 스트릭 보호·경고 | 태고 | "Streak-Schutz" 서사와 결속 |
| 빈 상태 (`SoriEmptyState`) | 조이 (가벼운 안내) | §8에서 일러스트 슬롯 표준화 |
| 오류 상태 (`app_error`) | 태고 (신뢰·복구) | 동상 |
| 온보딩 | 태고 주연 + 조이 어깨 동반 (2인조 정체성) | `welcome_hero.mp4` 기준 |

- **발화 단일화**: 화면당 캐릭터 발화(말풍선)는 1개. 헤더 서브카피와 말풍선이 서로 다른 행동을 지시하지 않는다(H-4).
- **소리 규칙**(기존 절대 규칙 유지): 첫 인사에 사람 목소리·한국어 TTS 금지 — 동물 소리+몸짓만. 까치 인사 SFX 부재는 여전히 미해결(무음 폴백 중) → §11 Q7.

### 5.4 기술 계약 (재확인 — 위반 시 화풍이 아니라 합성이 깨진다)

- 캐릭터 클립 = **순백 #FFFFFF 배경 H.264 mp4** + `ColorFiltered(multiply)` → **클립 뒤 배경은 반드시 단색이며 `blendColor`와 동일 상수** (path_trail 불변식 (3)). 그라데이션 위 배치 금지.
- multiply 특성상 **밝은 배경 전용** — 다크 배경 슬라이드/화면에는 정적 PNG만.
- 동시 H.264 디코더 ≤1 (Jin 실기기 SD678 reclaim 이슈) — 신규 화면이 클립을 추가할 땐 `video_lease` 예산 확인.
- 전 프레임 픽셀 스캔 검수 후 납품(첫 프레임만 보지 않는다).

---

## 6. IA 재설계 — 미션 중심 홈

### 6.1 홈: 12블록 → 5블록

**새 홈 (위→아래):**

| # | 블록 | 내용 | 흡수/폐기되는 현재 위젯 (`home_screen.dart`) |
|---|---|---|---|
| 1 | 헤더 | 워드마크 + 스트릭 칩(🔥n) + 설정 48dp | `_TopBar` 정리 |
| 2 | 캐릭터 인사 | 선택 캐릭터 클립(높이 축소 ~160dp) + **말풍선 1개** | `_TigerHero` + `_SpeechBubble` (발화 단일화, H-4) |
| 3 | **오늘의 미션 히어로 (단일 CTA)** | "다음 것 1개"만: 진행 중 팩 > 오늘 복습(임계 초과 시) > 추천 시나리오 순의 **단일 추천 엔진**. 카드 안에 레벨 칩·소요시간·XP·진행 링 + filled CTA 1개 | `_TodayScenarioCard` + "Jetzt lernen" + `_CourseCard`의 추천 역할 통합. **규칙 R-REC: 추천 레벨 ≤ 사용자 레벨** (H-6) |
| 4 | 이어지는 길 (미리보기) | Lernpfad **현재 노드 ±2 = 3노드 가로 스트립** + "Ganzer Pfad →" (`pathSeeAll` 키 기존재) | `SoriPathTrail` 홈 임베드(:584) 제거, `_SkillPathRail`(:692) 폐기 — 시나리오 진행은 미션 히어로가 대변 |
| 5 | 오늘 할 일 *(있을 때만)* + 마당 | 복습 n·어려운 단어·오늘의 글자 — **0건이면 블록 자체 숨김**. 이어서 모듈 그리드(축약) | `_ReviewCard`·`_HardWordsCard`·`_DailyCharCard`·`_SteppingStonesRow`(주간 디딤돌은 스트릭 칩 탭 시 시트로) |

- 프리미엄 `_CourseCard` 거취는 수익화 화면이므로 임의 폐기하지 않는다 — 블록 3의 추천 소스로 통합하되 노출 형태는 §11 Q2.
- 스탯(`_StatChipRow`·`_DailyGoalCard`)의 수치 5종은 **칩 1줄로 압축**, 상세는 `/stats`.

### 6.2 Lernpfad: `/path` 전용 화면으로 (100% 트리거 유지)

- `learning_path_screen.dart` + `SoriPathTrail` 그대로 사용 — **노드 전량·전부 탭 가능 유지** (잠금 탭 = 힌트 스낵바, 기존 동작).
- 개선 3건: ① 진입 시 **현재 노드로 자동 스크롤**(상단 점프 버튼 병행) ② 레벨(A1·A2·B1·B2) **챕터 헤더 + 사계 단청 팔레트**(`HanokLevelPalette` — 온보딩 크리틱 §4에서 신설한 4색 재사용)로 리듬 부여 ③ 잠금 노드 저채도 한지톤(§4.4-3).
- 홈 미리보기(블록 4)와 `/path`는 같은 `PackProgressService.loadLevelView` 데이터 — 별도 상태 없음.

### 6.3 Üben: 순서와 단일 소스

- 섹션 순서 변경: **이어하기(due 있을 때만) → Lernen → Wörter → Spiele** — "연습하러 왔다가 게임에 갇히는" 동선 역전 방지. (현행 Lernen→Spiele→Wörter, `practice_hub_screen.dart`)
- "Heute wiederholen" 단일 소스: 홈 블록 5와 Üben 이어하기 섹션은 **같은 `/review` 진입점** — 상태(n Wörter fällig)도 같은 서비스에서. 이름 중복은 허용하되 화면당 1회만.
- 카드 액센트 색 섹션 수렴(§4.4-2) + 표면 v2 적용.
- `HanokHeader`(porch) 유지 — 허브 정체성 장식은 남긴다.

### 6.4 Lerngruppe · Profil

- **Lerngruppe 빈 상태**: `SoriEmptyState` 문법 — 조이 일러스트(기존 자산) + "함께 지으면 오래 간다" 헤드라인 + 혜택 3줄 + `Gye erstellen`(filled) / `Mit Code beitreten`(outline) + 공동 한옥 미리보기 1장(`gye_hanok` 재사용). 참여 후에는 기존 GyeScreen.
- **Profil**: ① 시스템 알림 카드는 이벤트 시에만(G-2) ② 버튼 활성/비활성 시각 규칙(G-3) ③ 게스트 유도 카드는 혜택 중심 문구로(§7.3).

### 6.5 온보딩 흐름 (화면 순서는 유지, 톤만 통일)

인트로 게이트 → 프리뷰 3장(**전부 한지 라이트 + 캐논 에셋**, O-1~O-6) → 레벨 선택(v4, 현행 유지) → 백업 시트는 **첫 팩 완료 후**로 이동(L-2). 전 구간 상태바 다크 아이콘 고정.

---

## 7. 문구·번역 정리 (독일어)

### 7.1 버그 — 즉시 수정 (R5)

| 키 (`app_de.arb`) | 현재 | 수정 |
|---|---|---|
| `hubPracticeStreak` (:1171) · `dailyStreak` (:959) | "{n} Tage in Folge" → **"1 Tage"** 노출 | ICU plural: `{n, plural, one{1 Tag in Folge} other{{n} Tage in Folge}}` |
| `streakDialogCurrent` (:27) · `gyeProfileStreak` (:544) · `dailyCharStreak` (:795) · `notifDailyStreakBody` (:1035) · `milestoneStreakTitle` (:1126) | 동일 패턴 — **스트릭 계열 합계 7키** | 동일 처방 (EN arb 동반 수정) |
| `{n} Wörter`·`{packs} Packs`·`{cleared}/{total} Packs` 계열 (`bookshelfPackMeta`·`gyeMvpCard`·`vocabPacksProgressLabel` 등) | n=1에서 "1 Wörter/1 Packs" — 동일 병 | §7.4 감사 스크립트로 **전수 검출 후 일괄** ICU plural |
| 요일 디딤돌 | M D M D F S S | **Mo Di Mi Do Fr Sa So** (스크린리더 라벨은 전체 요일명) |

### 7.2 용어 표준화 (결정 필요 항목은 §11)

| 현재 | 문제 | 권고 |
|---|---|---|
| "Pack" (50+ 키) | 독일어 단독 명사 *das Pack*은 경멸어(천민·무리). 합성어(Vokabel-Pack)는 덜하지만 단독 사용("Neues Pack", "lern ein neues Pack")이 다수 | **"Paket"** 전환(Duolingo/Drops 관례) 또는 "Lektion". 일괄 치환 스크립트 + 수동 검수 → Q3 |
| `homeBookshelfCardDesc` "Custom-Packs" | 영어식 | 기존 키 재사용: **"Eigene Pakete/Packs"** (`bookshelfSectionCustomPacks` 이미 "Eigene Packs") |
| "Streak" (30+ 키) | 앙글리시즘 — 다만 학습앱 관례로 정착 중 | **유지 권고** (Duolingo DE도 병용). 대안 "Serie" → Q3에서 함께 확정 |
| "Quests" | 영어 | "Missionen" 검토 (홈 "Alltagsmission"과 어휘 통일) |
| "Wordle" | 타 상표 게임명 | "Hangeul-Rätsel" 등 자체명 → Q5 |
| "Im Starbucks bestellen" | 실존 상표 — 스토어 심사·상표 리스크 + 특정 브랜드 종속 | **"Im Café bestellen"** 권고 → Q6 |

### 7.3 페르소나·레지스터 통일

- 현재 화자 4명: "Der Tiger"(previewPage3Body) / "Sori"(previewPage1Body) / Joy / Taego. **규정: 기능 설명의 주어는 앱(Sori), 정서적 발화의 주어는 캐릭터 이름(Taego/Joy).** "Der Tiger meldet sich…" → "Taego meldet sich…" → Q8.
- du-형 유지(전 앱 일관 확인됨). 시스템 문구("Kontowechsel pausiert")는 사용자 언어로 재작성: 무엇이 보호됐고 다음에 뭘 하면 되는지 1문장.
- 온보딩 본문은 헤드라인 + 2줄 이내(O-5). 장식적 은유("ein Tag mal untergeht")는 유지하되 문장당 1개.

### 7.4 프로세스 (재발 방지)

1. **에셋 무문자 원칙** — 일러스트에 UI 언어를 굽지 않는다(한글 학습 소재 낱자는 예외). `IMAGES_TO_CREATE.md`·BIBLE에 규칙 명문화.
2. **ARB 감사 스크립트**(`tool/` 추가): ⓐ `{n}`·`{count}` 뒤 "Tage|Wörter|Packs…" 복수형 미처리 검출 ⓑ 라틴 앙글리시즘 후보 목록 ⓒ DE/EN 키 대칭 검사. CI(기존 가드 테스트 옆)에 래칫으로.
3. 릴리스 전 **독일어 네이티브 패스 1회** — 신규·변경 키만 diff 검수.

---

## 8. 상태·접근성 통일

### 8.1 상태 4종 표준 (기존 위젯 전수 적용)

| 상태 | 표준 | 규정 |
|---|---|---|
| 로딩 | `app_loading.dart` + **스켈레톤**(카드 자리 raised 실루엣 shimmer) | 스피너 단독 금지. 캐릭터 클립은 로딩에 사용 금지(디코더 예산) |
| 오류 | `app_error.dart` — 태고 정적 + 원인 1줄 + **Erneut versuchen** 1버튼 | 기술 문구 금지. 오프라인은 별도 카피("Kein Internet — dein Fortschritt ist lokal sicher.") |
| 빈 | `SoriEmptyState` — 조이 + 다음 행동 CTA 1개 | "없음"으로 끝내지 않는다 — 항상 출구 제공 |
| 성공 | `celebration.dart`/`dancheong_burst` | reduce-motion 시 정적 배지 (기존 gating 유지) |

적용 체크리스트(대상 화면 전수): Lerngruppe(G-1)·Bücherregal·Meine Wörter·Knifflige Wörter("Keine Sorgenkinder"는 빈 상태 카피로 이동)·Heute wiederholen("Alles erledigt!")·퀘스트·통계.

### 8.2 접근성 기준선 (측정 가능한 것만)

- 대비: 본문 ≥4.5:1, 대형/UI ≥3:1 — `contrastRatio()` 헬퍼로 테스트 고정(수기 검수 금지). 기지 수치: 먹/한지 15.47 ✅, muted 5.52 ✅, CTA 5.37/5.80 ✅, 카드 경계 3.27 ✅.
- 터치 타깃 ≥48dp: 헤더 아이콘(v2 지적)·`Später`류 텍스트 버튼·경로 노드(132×136 ✅).
- `Semantics`: 복합 카드(미션 히어로·경로 노드·스탯 칩)에 병합 라벨. 마스코트 클립은 `excludeSemantics` + 대체 텍스트.
- 시스템 글꼴 200%: `maxLines` 금지 원칙 + 스크린샷 회귀 세트에 200% 변형 포함.
- reduce-motion: 기존 `SoriMotion.respect` 체계 유지 — 신규 모션 전부 경유.

---

## 9. 실행 로드맵

> 전제: 브랜치 필수(`feat/design-refresh-2026-08`), 병렬 세션 mtime 확인, 커밋은 Jin 승인 시. Flutter 실행 검증(analyze/test/실기기)은 로컬 세션 몫.

| 단계 | 기간 | 내용 | DoD (완료 기준) |
|---|---|---|---|
| **R0 기준선** | 0.5일 | v2 완료분 실기기 대조(§1 표), 골든/스모크 확충(홈·Üben·경로), 16장 스크린샷 재촬영 세트 정의 | analyze/test 그린 + 기준 스크린샷 보관 |
| **R1 표면 수술** | 1일 | `card.dart` 표면 v2(테두리→그림자, 액센트 바), 잠금 톤, 버튼 활성/비활성 규칙 | SoriCard 34파일 시각 회귀(라이트+다크) 통과, 대비 테스트 그린 |
| **R2 홈 재편** | 2일 | §6.1 5블록 — 미션 히어로(추천 엔진 규칙 R-REC 포함), 경로 미리보기, 임베드 제거, 발화 단일화 | 홈 스크롤 길이 ≤2.5화면(현 5+), filled CTA 1개, 골든 통과 |
| **R3 경로 화면** | 1일 | `/path` 자동 스크롤·챕터 헤더·잠금 톤 | 76노드 전부 탭 가능(기존 테스트 유지) + 현재 노드 첫 화면 진입 |
| **R4 허브·기타** | 1일 | Üben 섹션 순서·색 수렴, Lerngruppe 빈 상태, Profil 정리 | 화면별 체크리스트(§8.1) 소화 |
| **R5 문구** | 1일 | plural 스트릭 7키 + 감사 스크립트로 Wörter/Packs 계열 전수, 요일, 용어 치환(Q3 확정분), 페르소나 규칙 | "1 Tag" 실기기 확인, 감사 스크립트 CI 그린 |
| **R6 에셋 (Jin 병행)** | — | §5.2 4건 재제작 + 온보딩 라이트 배경 적용, 전 프레임 검수 | BIBLE 프롬프트 준거 + 규격 계약(§5.4) + 무문자 원칙 |
| **R7 마감** | 1일 | 상태 통일 잔여분, 접근성 스윕, 릴리스 스크린샷(FPS 오버레이 OFF), `DEPLOY_CHECKLIST` 반영 | §12 전 항목 체크 |

의존성: R1 → R2·R3·R4 (표면이 먼저). R6은 R2와 독립 병행 가능, 온보딩 교체는 R6 에셋 도착 후. 합계 실작업 ≈ **7.5일 + 에셋 병행**.

---

## 10. 핸드오프 스펙 — 신규·변경 컴포넌트 3종

### 10.1 `MissionHeroCard` (신규, 홈 블록 3)

- **레이아웃**: raised 카드, `SoriRadius.lg`, 내부 `Spacing.cardInner`. 좌측 진행 링(56dp, `primary`) / 우측 콘텐츠: 레벨 칩(`HanokLevelPalette`) + 제목(h3 w700, 2줄 허용) + 메타 1줄(`caption`: "5–7 min · +140 XP") + filled CTA(`tiger` 채움·`onFill` 먹 라벨·`fillOutline` 테두리, 높이 52).
- **상태**: `notStarted`(CTA "Los geht's") / `inProgress`(링 %, CTA "Weitermachen") / `allDone`(조이 축하 + "Für heute geschafft" + 보조 텍스트 버튼 "Noch eine Runde") / `loading`(스켈레톤) / `error`(카드 자리 비움 — 홈은 오류 카드 금지, 조용히 다음 소스 폴백).
- **데이터 규칙**: 추천 소스 우선순위 = 진행 중 팩 > due 복습(≥10) > 시나리오 추천. **`recommendedLevel ≤ userLevel`** 가드. 프리미엄 코스는 Q2 확정 후 배지로 병합.
- **접근성**: 카드 = Semantics 1노드("Nächste Mission: {title}, Level {level}, etwa {min} Minuten"). CTA 48dp+.

### 10.2 `PathPreviewRow` (신규, 홈 블록 4)

- 가로 스트립 높이 ~120dp: 노드 3개(완료 도장 · **현재(클립 or 정적)** · 다음 잠금) + 우측 "Ganzer Pfad →" 텍스트 버튼(`pathSeeAll`).
- 노드 시각은 `path_trail.dart` 문법 재사용(도장·황금 링·잠금 톤) — **단, 클립은 홈 히어로와 동시 재생 금지**(디코더 ≤1): 히어로가 클립이면 미리보기는 정적.
- 탭: 현재 노드 = 팩 진입, 그 외 = `/path` (해당 노드로 스크롤 파라미터).
- 데이터: `PackProgressService.loadLevelView` — 신규 상태 없음.

### 10.3 `SoriCard` 표면 v2 (변경)

- default: `lightSurfaceRaised` + `SoriElevation.low`, 테두리 없음 / pressed: `medium` + `pressScale 0.96`(기존 `pressable`).
- `selectable` variant: + `lightBorderStrong` 1.5px (선택 상태 = `primary` 2px).
- `accent` variant: 좌측 4px 바(`accent` 색) — 기존 색 코딩 API 유지, 시각만 이전.
- 다크: `darkSurface` + `darkBorderStrong` 1.5px (그림자 무효 환경).
- 마이그레이션: 34파일 — 기본값 교체는 1커밋, variant 지정이 필요한 화면(선택지·온보딩 카드) 목록화 후 개별 커밋.

### 10.4 온보딩 슬라이드 템플릿 (변경)

- 배경 `lightBg` + `hanji_texture` + 벚꽃 입자(reduce-motion 게이트) / 일러스트 슬롯 상단 55%(정사각, 캐논 에셋) / 헤드라인 26 w800 / 본문 15 w500 ≤2줄 / 도트+CTA 고정 하단(본문과 최소 `Spacing.xl` 이격 — O-3 방지) / 상태바 다크 아이콘.

---

## 11. Jin 결정 필요 — 8건

| Q | 질문 | 기본값(권고) |
|---|---|---|
| Q1 | 홈 Lernpfad **임베드 제거 + 미리보기 3노드** 확정? (07-31 "100% 트리거" 지시의 공식 반전 — `/path`에서는 전량 유지) | 예 |
| Q2 | 프리미엄 "Dein Tageskurs"를 미션 히어로에 **배지로 통합**할지, 별도 카드 유지할지 (수익화 노출량 트레이드오프) | 히어로 통합 + 주 1회 전용 카드 |
| Q3 | 용어: **Pack→Paket** 전환? Streak 유지? (50+ 키 일괄 치환, 스토어 문구 연동) | Paket 전환 · Streak 유지 |
| Q4 | `tiger_crystal` 재제작 시 크리스탈 모티프 유지(금색 전환) vs 다른 은유(단청 방패·부적) | 부적(단청 황) — 한국 정체성 강화 |
| Q5 | "Wordle" 명칭 교체? | "Hangeul-Rätsel" |
| Q6 | "Im Starbucks bestellen" → "Im Café bestellen"? (콘텐츠 데이터 수정 포함) | 예 |
| Q7 | 까치 인사 SFX 제작 여부 (현재 조이 선택 시 무음 — v2 Q3 승계) | 제작 (Jin 녹음/생성) |
| Q8 | 문구 화자: "Der Tiger …" → "Taego …" 통일? | 예 (§7.3 규칙) |

---

## 12. 검증 체크리스트

**표면·시각 (R1)**
- [ ] SoriCard 34파일 라이트/다크 시각 회귀 — 기준 스크린샷 대조
- [ ] 대비 자동 테스트: 본문 4.5 / UI 3.0 하한 (`contrastRatio` 기반, 신규 조합 포함)
- [ ] w800 사용량 래칫 ≤189 유지 (`typography_guard_test`)

**홈·IA (R2·R3)**
- [ ] 홈 filled CTA 정확히 1개 · 스크롤 길이 ≤2.5화면 · 경로 임베드 0
- [ ] A1 신규 계정에서 A2 추천 미노출 (R-REC)
- [ ] 헤더 발화 1개 (헤더 서브카피 ↔ 말풍선 충돌 0)
- [ ] `/path`: 진입 시 현재 노드 가시 · 76노드 전부 탭 가능 · `path_trail_tap_test` 9/9 유지
- [ ] 홈 히어로 클립 + 미리보기 클립 동시 재생 0 (`adb logcat | grep reclaim` 무발생)

**문구 (R5)**
- [ ] streak=1 실기기에서 "1 Tag in Folge" (Üben 헤더·Tages-Challenge 카드·알림)
- [ ] 요일 2자 표기 + 스크린리더 전체 요일명
- [ ] ARB 감사 스크립트 CI 그린 (plural 미처리 0 · DE/EN 키 대칭)
- [ ] 그림 속 비학습 텍스트 0 (신규 에셋)

**에셋·캐릭터 (R6)**
- [ ] 신규 에셋 4건: BIBLE 프롬프트 준거 확인 + 전 프레임 픽셀 스캔 리포트
- [ ] 승패 연출 9곳 회귀: <50% 태고 / ≥50% 조이 유지
- [ ] 캐릭터 클립 뒤 배경 = blendColor 동일 상수 (이음매 0)

**상태·접근성·릴리스 (R4·R7)**
- [ ] 빈/오류/로딩 표준 위젯 적용 화면 체크리스트 100%
- [ ] 시스템 글꼴 200% 스크린샷 세트 — 잘림 0
- [ ] "가입 2일차·XP 0" 계정 시나리오 문구 정합 (H-7)
- [ ] 릴리스 스크린샷: FPS 오버레이 OFF · 상태바 정리

---

*근거 파일: `lib/widgets/sori/tokens.dart`(v6.0 토큰·대비 헬퍼) · `lib/theme.dart` · `lib/screens/home_screen.dart`(:552 E1a 임베드, :692 _SkillPathRail, 위젯 22종) · `lib/screens/practice_hub_screen.dart`(3섹션 19카드) · `lib/screens/onboarding_preview_screen.dart`(:97–117 에셋 4종) · `lib/l10n/app_de.arb`(plural 미처리 키 6+ · characterRoman* :37–43) · `lib/widgets/sori/{card,empty_state,path_trail,character_clip}.dart` · `lib/widgets/{app_loading,app_error}.dart` · docs 선행 4종. 스크린샷 16장은 Jin 제공 원본 기준.*
