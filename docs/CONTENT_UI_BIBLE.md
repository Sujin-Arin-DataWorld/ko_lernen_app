# Content UI Bible — Hangul Sori

> **역할**: 콘텐츠를 연 뒤의 화면(단어·듣기·쓰기·문법·클로즈·문장·스몰톡·시나리오·복습)에 대한 **유일한 상호작용·타이포·CTA 정본**.
> **범위**: 플레이어/피드만. 한옥 자산은 `docs/assets/STYLE_LOCK.json`, 일러스트 생성은 `docs/ASSET_GENERATION_BIBLE.md`, 홈/Today 매트는 `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`를 유지한다.
> **상태**: 2026-08-18 실측 + Jin 요청 기반 **계획**. 구현은 Jin이 이 문서의 §0 결정을 승인한 뒤에만 시작한다.
> **선행 문서 정정**: `HANDOFF_UI_OVERHAUL_2` §1-1·§1-2(좌=모름·우=앎·위=저장·아래=스킵, 하단 원형 4버튼)는 **이 문서가 대체한다**. 4방향 틴더 덱은 폐기 대상이다.

---

## §0. Jin이 잠글 결정 (구현 전 확인)

이 여섯 줄이 맞으면 구현 세션은 더 묻지 않는다.

1. **콘텐츠 CTA는 듣기 블루 하나.** 채움/강조 = `SoriColors.info` `#57799E`(청금석). 주황(`tiger` `#FF8C42`)·황(`gold` `#C99A2E`)·경고황(`warning` `#D4A22E`)은 버튼에서 뺀다. 호랑이 주황은 마스코트만, 황은 XP/스트릭만.
2. **세로 피드가 전역 이동이다.** 위·아래로만, 매우 빠르게. 왼쪽·오른쪽 스와이프 없음. `Weiter`·모름·앎 버튼은 콘텐츠 열람에서 제거.
3. **더블탭 = 하트 = 좋아요 = 저장.** 인스타처럼 큰 하트가 한 번 터지고 끝. 스낵바가 바닥에 붙지 않는다. 나중에 좋아요만으로 연습/게임을 만든다.
4. **한 장 = 한 화면.** 기기 높이 안에서 본문이 잘리지 않게 담고, 다음 장은 아래로 넘긴다. 플레이어와 책장/규칙 패널을 같은 화면에 겹치지 않는다.
5. **콘텐츠 플레이어에서 네모 카드(hero `SoriCard`)를 뺀다.** 한지 배경 위에 글과 소리가 바로 앉는다. 카드는 허브·목록·선택지처럼 *고르는* 자리에만 남긴다.
6. **폰트는 Pretendard 하나.** 새 웹폰트·키즈 폰트·세리프 혼용 금지. 위계는 크기·굵기만.

---

## §1. 왜 이 바이블이 따로 필요한가

이미 있는 문서는 역할이 갈린다.

| 문서 | 실제로 다루는 것 | 콘텐츠 플레이어에 못 하는 것 |
|---|---|---|
| `tokens.dart` | 색·간격·텍스트 프리셋 | 누가 CTA인지, 제스처가 뭔지, 한 화면에 뭐가 살아도 되는지 |
| `ASSET_GENERATION_BIBLE.md` / `STYLE_LOCK.json` | 한옥·장식·민화 그림 | 버튼·타이포·스와이프 |
| `HANDOFF_UI_OVERHAUL_2` | 틴더 4방향 덱 + Today 일러스트 | Jin이 철회한 제스처 |
| `typography_guard_test.dart` | 부채 상한(w800≤155, raw TextStyle≤409) | 콘텐츠 역할(한국어/뜻/메타) 스케일 |
| 제네릭 UI 스킬 출력 | Claymorphism + Baloo 2 / Comic Neue | Hangul Sori 정체성. **쓰지 않는다.** |

콘텐츠 화면은 8월 18일 하루 동안 듣기 책가도·덱 3.0·쓰기 세로 배치·배치 11–16이 겹쳐 **화면마다 다른 크롬**이 생겼다. 그림 바이블이 아니라 **열람 바이블**이 필요하다.

바이블 구조(이 파일이 그 본체다):

```
Primitive  (SoriColors / Spacing / SoriTextTheme)     — tokens.dart
    ↓
Semantic   (contentCta, like, chrome, koDisplay…)     — 이 문서 §3
    ↓
Component  (SoriContentFeed, SoriLikeBurst, SoriAppBar)
    ↓
Page       (hören player ≠ shelf, schreiben canvas, cloze options)
```

컴포넌트에 raw hex·raw `TextStyle(`·원시 `AppBar(`를 쓰지 않는다. `design-system` 스킬의 3층과 같다.

---

## §2. 네 번 훑은 실측

감사 범위: `origin/main` (`a00fc1d1` 시점). 8월 18일 main 커밋 46개 중 콘텐츠 UI에 직접 닿은 것은 `abf9e3ff`(Sori Deck 3.0), `f109d0e5`/`e4ac3464`/`b25a81b2`(듣기 책가도), `hangul_screen.dart` 세로 쓰기, 배치 11–16이다. 스킬은 `frontend-design`, `web-design-guidelines`, `ui-ux-pro-max`(프로 룰·퀵레퍼런스·검색), `ui-styling`, `design-system`, `brand`, 프로젝트 `frontend-design`을 읽었다.

### 1차 — 무엇이 몇 개인가

**덱/틴더 경로 6개** (`SoriSwipeCard` + 대개 `SoriDeckActionBar`):

| 화면 | 파일 | 지금 제스처 |
|---|---|---|
| 단어팩 Learn | `vocab_pack_screen.dart` | 좌 모름 · 우 앎 · 위 저장 · 아래 스킵 |
| SRS 복습 | `review_session_screen.dart` | 동일 |
| 레거시 단어 | `legacy_vocab_screen.dart` | 동일 |
| 커스텀팩 | `custom_pack_play_screen.dart` | 위 저장 없음 |
| 한글 카드 탭 | `hangul_screen.dart` | 위 저장 없음 |
| 문법 덱 | `grammar_screen.dart` | 하단 바 없음, 스와이프만 |

계약 원문: `swipe_card.dart` — left=hard, right=know, up=save, down=skip.

**덱이 아닌 플레이어**: Cloze, Daily, Satz, Smalltalk, Listening, Scenario, Chosung, Quiz/Boss, Recall, Word web, Hard words, Pronunciation. 각자 AppBar·칩·카드·CTA를 따로 짠다.

공유 크롬이 화면마다 반복된다: raw `AppBar` + `FontWeight.w800` 제목, info 칩 진행도, hero `SoriCard`, 스와이프 레일, 원형 4버튼.

### 2차 — Jin이 집은 네 증상

**A. CTA가 주황으로 둔탁하다 / 듣기는 블루가 좋다**

토큰 실측 (`tokens.dart`):

| 토큰 | Hex | 콘텐츠에서 하는 일 |
|---|---|---|
| `info` | `#57799E` | 듣기 Next/완료, 레벨 칩, 스킵 레일. **Jin이 좋아하는 블루.** |
| `highlight` | `#5A7BA0` | 듣기 히어로 폴백, 한글 카드 뒷면 |
| `primary` | `#1F7A6B` | 기본 `SoriButton.filled`, 덱 ✓ 채움 |
| `tiger` | `#FF8C42` | Speed match CTA, Stage `speaking` 타일. 덱 본버튼은 아님 |
| `gold` | `#C99A2E` | 덱 저장 원형 버튼 채움 18% + 테두리 |
| `warning` | `#D4A22E` | 쓰기 규칙 카드, 문법 진행 |
| `accent` | `#A0524A` | 덱 `?` 테두리, 한글 끝내기, 단어망 |

주황이 “콘텐츠 CTA”로 느껴지는 이유: 허브 말하기 타일(`SoriActivityColors.speaking = tiger`) + 덱 저장 황금 단추 + 쓰기 노란 규칙 카드가 한 흐름에 섞인다. 듣기는 `accent: SoriColors.info`로 이미 청금석이다 (`listening_screen.dart` 494–501).

**B. 듣기에서 예전 화면과 책장이 같이 보인다**

버그가 아니라 **한 스크롤에 두 UI를 고의로 남긴 상태**다.

```426:580:lib/screens/listening_screen.dart
if (_selected != null) ...[ 컨트롤 + 문장 카드 + prev/next ],
Text(t.listeningSelectScenario),
ChaekgadoShelfCase(...),  // 레벨 탭 + 12칸 책장
```

주석도 “검증하다가 순서를 바꿨다”고 적혀 있다. 390×844에서 책장이 위에 있으면 재생 버튼이 화면 밖으로 밀려, 플레이어를 위로 올렸을 뿐 책장을 분리하지 않았다. 그래서 문장을 듣는 중에 아래 책장이 같이 보인다.

**C. 단어 저장 알림이 안 사라진다**

`wordbook_add.dart` 57–69: floating `SnackBar`, **3초**, `hideCurrentSnackBar()` **없음**. 다른 화면(`gye_dedication_action.dart` 등)은 새 토스트 전에 현재 것을 지운다. 덱에서 저장을 연타하면 3초짜리 토스트가 줄 서서 바닥에 붙어 있는 것처럼 보인다. 지속 `MaterialBanner`는 없다. 첫 사용 `SpotlightCoach`는 별개 오버레이다.

ui-ux-pro-max Feedback 규칙: 토스트는 3–5초 자동 소멸, 줄을 세우지 말 것. Vercel 가이드: 비동기 알림은 `aria-live="polite"`, 포커스를 가리지 말 것.

**D. 틴더 4버튼을 인스타/틱톡으로**

지금 멘탈 모델은 데이팅앱이다. Jin이 원하는 모델은 숏폼이다.

| 지금 (Deck 3.0) | 바꿀 것 |
|---|---|
| 좌/우 = 모름/앎 | **없음.** 가로 제스처 삭제 |
| 위 = 저장, 아래 = 스킵 | **위/아래 = 이전/다음 장만.** 매우 빠른 `PageView` |
| 원형 4버튼 + Weiter | **없음.** 더블탭 하트만 저장 |
| 저장 = 단어장 스낵바 | 하트 버스트. 스낵바 없음 |
| SRS가 매 스와이프에 묶임 | 열람 피드와 SRS를 분리. 앎/모름은 전용 복습에만 |

ui-ux-pro-max Touch: `gesture-conflicts` — 본문에서 가로 스와이프를 피하고 세로 스크롤을 표준으로. `gesture-alternative` — 제스처만으로 중요 동작을 닫지 말 것 → 보이는 하트 버튼은 남긴다(WCAG 2.2 §2.5.1). `tap-delay` / 입력 지연 <100ms → 피드 물리와 하트는 즉각.

### 3차 — 타이포·카드·크롬 낭비·한 화면

**타이포가 뒤죽박죽인 이유**

정본 `SoriTextTheme`은 이미 있다: hero 38 / display 32 / h1 24 / h2 20 / h3 17 / body 15 / caption 12.5. 전부 Pretendard. 카드 제목은 w700이지 w800이 아니다.

그런데 콘텐츠 화면이 이걸 우회한다. 가드 실측 상한: w900 ≤ **31**, w800 ≤ **155**, 화면 raw `TextStyle(` ≤ **409**, raw `AppBar(` ≤ **98**. Pretendard는 400–800만 번들이라 **w900은 가짜 볼드**다.

실측 최악:

| 위치 | 문제 |
|---|---|
| 거의 모든 콘텐츠 AppBar | raw `TextStyle` + w800, `SoriAppBar` 미사용 |
| `listening_screen.dart` | 완료 제목 w900, 한국어 줄 22px w800 |
| `hangul_screen.dart` | raw `fontSize` 23곳. 규칙 13/11.5, 힌트 11 — 본문 하한 미달 |
| `smalltalk_screen.dart` | 문장 카드 w900 |
| `chosung_quiz_screen.dart` | 22px w900 |
| `custom_pack_quiz_screen.dart` | 32px w800 |
| `scenario_player_screen.dart` | 26px w800 |
| `vocab_pack_recall_screen.dart` | 디스플레이 28px |

Jin이 싫어하는 알약/칩 강조(`jin-no-ios-style-badges`)도 쓰기·듣기·클로즈에 그대로 있다.

**네모 카드가 둔탁한 이유**

`SoriCard` hero = 패딩 24 + 반지름 20 + `lightSurfaceRaised` `#FFFDF8` + 낮은 그림자. 배경이 이미 한지 `#FAF6EC`라 크림 위에 흰 상자를 또 올리는 셈이다. 토큰 주석 자체가 “크림온크림이 답답함의 원인”이라고 적혀 있다. 플레이어는 그 상자를 *콘텐츠 자체*로 쓴다. 허브 목록용이던 문법이 학습 문장을 가둔다.

`frontend-design`: 장식을 하나 빼고 나가라. 시그니처는 하나. 여기 시그니처는 **한지 위의 한글**이지, 둥근 상자 안의 한글이 아니다.

**쓰기 화면이 30%를 버리는 이유** (`hangul_screen.dart` `_WriteTab` 1453–1551)

| 블록 | 대략 높이 | 학습에 필요한가 |
|---|---|---|
| Hangul-Schreibregeln 카드 | 70–90pt | 첫 1회면 충분 |
| 자음/모음 칩 | ~40pt | 가끔 |
| 엄격/연습 칩 + 힌트 | ~70pt | 가끔 |
| 시범 240 + 연습 240 | ~480pt | 예. 둘을 동시에 둘 필요는 없음 |
| 진행 칩 + 아이콘 줄 | ~90pt | 일부 |

8월 18일에 가로 2칸을 세로로 쌓아 캔버스는 커졌지만, 규칙 카드와 알약을 내리지 않아 폰에서 항상 스크롤이 강제된다. 같은 패턴이 듣기(플레이어+책장), 클로즈(지시문+레벨칩+카드), 문법(예전 필터)에도 있다.

**한 화면에 안 담기는 곳**

- 듣기: 테스트 뷰포트가 **1400px** (`listening_shelf_route_test.dart`). 실기기 844pt에서는 책장이 다음 페이지처럼 붙어 있다.
- 쓰기: 크롬 180pt + 캔버스 480pt > 844pt.
- 덱: 카드 슬롯 `heightFactor: 0.82` + 하단 바 = 본문이 작은 상자 안에 또 잘린다.
- 시나리오: 포스터 고정 140px + 하단 Weiter.

### 4차 — 스킬로 자기 검열

제네릭 `--design-system`은 교육앱에 Claymorphism과 Baloo 2 / Comic Neue를 추천했다. `frontend-design`이 경고하는 **키즈/템플릿 기본값**이다. Hangul Sori는 독일 성인 학습자 + Faceted Minhwa + 단청이다. **그 추천은 버린다.**

쓸 스킬 규칙만 남긴다.

- 한 곳에만 힘을 준다: 청금석 CTA + 하트. 나머지 크롬은 조용히.
- 토스트는 줄을 세우지 않고, 좋아요는 토스트가 아니라 모션.
- 제스처는 세로 하나. 가로 스와이프는 시스템 뒤로가기와 싸운다.
- 더블탭 저장의 보이는 대체 수단(하트 아이콘)은 필수.
- 본문 16px 근처, 11px 금지, 대비 4.5:1, 터치 44/48, safe area, reduced-motion.
- 이모지를 아이콘으로 쓰지 않는다. 하트는 벡터.
- 컴포넌트에 raw hex 금지.

---

## §3. 콘텐츠 시맨틱 토큰 (추가분)

`tokens.dart`에 *이름만* 얹는다. 새 hex를 만들지 않는다.

| 시맨틱 | 원시 | 쓰는 곳 |
|---|---|---|
| `contentCta` | `info` `#57799E` | 남은 텍스트 버튼(듣기 재생 등) |
| `contentCtaOn` | white | 그 위 글자 (대비 4.53:1 기존 검증) |
| `like` | `accent` `#A0524A` | 하트 채움. 석간주 — 단청이고 인스타 핑크가 아님 |
| `contentChrome` | transparent / 한지 | 플레이어 배경. 상자 없음 |
| `successMark` | `primary` `#1F7A6B` | 복습 전용 “앎”이 남을 때만 |
| `mascot` | `tiger` | 캐릭터만. 버튼 금지 |
| `reward` | `gold` | XP/스트릭만. 버튼 금지 |

활동 타일 `SoriActivityColors.speaking = tiger`는 허브 포스터용으로 남기되, **그 타일을 눌러 들어간 플레이어 CTA는 `contentCta`로 갈아탄다.**

### 콘텐츠 타이포 역할

기존 `SoriTextTheme`에 세 역할만 더한다. 화면이 숫자를 고르지 않는다.

| 역할 | 크기 | 굵기 | 줄간격 | 용도 |
|---|---|---|---|---|
| `koDisplay` | 28 (폰) / 32 (큰 폰, comfort scale) | w700 | 1.25 | 화면의 한국어 한 덩어리 |
| `gloss` | 17 | w500 | 1.4 | DE/EN 뜻, 자막 |
| `meta` | 12.5 | w500 | 1.35 | 진행 `3 / 12`, 힌트. **11px 금지** |

규칙:

- 한국어가 히어로, 번역이 보조, 크롬이 속삭인다.
- 카드 제목·AppBar는 기존 `h2`/`cardTitle`. 플레이어 AppBar는 `SoriAppBar`.
- w900 신규 0. 콘텐츠 화면의 w800은 AppBar 마이그레이션으로만 줄어든다.
- 긴 한국어는 `koDisplay`를 한 단계 내려 맞춘다(`soriUniformFitSize`와 같은 계약). 상자를 키우지 않는다.

---

## §4. 전역 상호작용: Sori Content Feed

신규 `lib/widgets/sori/content_feed.dart`가 정본이다. 화면은 아이템과 콜백만 넘긴다.

```
┌─────────────────────────────┐
│  닫기 · 소리  ·  ♡(접근성)  │  ← 얇은 크롬, 한지와 같은 색
│                             │
│         한국말              │  ← koDisplay, 카드 없음
│      deutsche Glosse        │  ← gloss
│                             │
│     (더블탭 시 하트)         │
└─────────────────────────────┘
        ↑ 빠른 세로 플링
```

동작:

| 입력 | 결과 |
|---|---|
| 위로 플링 / 아래로 플링 | 다음 / 이전 장. `PageScrollPhysics`, 임계 낮고 감속 짧음 |
| 더블탭 | `onLike` + `SoriLikeBurst` + 라이트 햅틱. 이미 좋아요면 하트만 채움(토글은 아이콘 탭) |
| 하트 아이콘 탭 | 같은 `onLike` (보이스오버·모터 대체) |
| 길게 누르기 | 뒤집기/뜻 공개가 있는 활동만 |
| 좌우 드래그 | **무시.** 시스템 뒤로가기에 양보 |
| 재생 버튼 | 듣기/발음만. CTA 색은 `contentCta` |

속도: 입력 후 100ms 안에 페이지가 따라온다. reduce-motion이면 플링 애니메이션 없이 즉시 장만 바꾼다. 하트는 transform/opacity만(Vercel animation 규칙).

좋아요 데이터:

- 신규 `LikedContentService` (로컬 + 기존 cloud sync best-effort).
- 아이템 키: `kind + id` (`vocab` / `cloze` / `satz` / `smalltalk` / `listeningLine` / `grammar` / `scenarioBeat`).
- 단어는 기존 `quickAdd`도 같이 호출해 단어장과 호환.
- 이후 스튜디오(`vocab_notebook/studio` 확장)는 **좋아요만** 넣어서 카드·퀴즈·클로즈·문장·스몰톡·시나리오 게임을 고른다. 없는 문장은 만들지 않는다(현행 스튜디오 계약).

SRS(앎/모름)는 `/review` 전용으로 남긴다. 숏폼 열람에 채점 버튼을 다시 심지 않는다.

---

## §5. 화면별 수술

### 5.1 듣기 — 플레이어와 책장을 쪼갠다

지금: 한 `SingleChildScrollView`에 히어로 + 컨트롤 + 문장 카드 + prev/next + 책가도.

바꿀 것:

1. `/listening` = 책가도만 (고르는 화면, 카드 허용).
2. `/listening/play` = 피드. 한 줄이 한 장. 더블탭 저장. 배속은 아이콘 하나.
3. 10:3 `HanokHeader`는 고르는 화면에만. 플레이어에서 30%를 먹지 않는다.
4. 자막은 장 안의 `gloss`이지 칩 줄이 아니다.

### 5.2 쓰기 — 규칙과 알약을 내린다

지금: 규칙 카드 + 칩 2줄 + 시범 240 + 연습 240.

바꿀 것:

1. Hangul-Schreibregeln는 **첫 실행 시트 1회**. 이후 `?`로만.
2. 자음/모음·엄격/연습은 AppBar overflow 또는 길게 누르기.
3. 시범은 연습 캔버스의 고스트 획. 캔버스는 **하나**.
4. 글자 이동은 세로 피드(다음 글자가 아래). 획 인식과 충돌하지 않게 캔버스 밖 가장자리만 스크롤. `‹ ›`는 접근성 정본으로 유지(이미 WCAG 주석이 맞다).

### 5.3 단어·문법·복습 덱 6화면

`SoriSwipeCard` / `swipe_rails` / `SoriDeckActionBar`를 피드로 교체. 플립 게이트(뒷면 보기 전 채점 금지)는 **복습 화면에만** 남긴다. 열람 피드에서는 길게 눌러 뜻을 연다.

저장 경로: 더블탭 → `LikedContentService` + (단어면) `quickAdd`. 스낵바 호출 없음.

### 5.4 Cloze / Satz / Smalltalk / Scenario

같은 피드 셸. Cloze 선택지는 장 하단 절반을 균등 분할(기존 `ClozeOptionsList` 유지). 짧은 문항은 중앙. Scenario `Weiter`는 정답을 확인한 뒤에만, 그것도 `contentCta` 하나. 평소 이동은 세로 플링.

### 5.5 네모 카드

| 남긴다 | 뺀다 |
|---|---|
| 카탈로그, 책장 칸, 레벨 고르기, Cloze 선택지 | 단어 앞/뒤면 히어로 상자 |
| 설정, 통계, 계 피드 | 듣기 `_LineCard` 히어로 |
| | 스몰톡 문장을 감싼 base 카드 |
| | 쓰기 규칙 카드 |

`StudyCardFace`에 `cardless: true` — 한지 + 여백만. 처마 장식은 허브에만.

---

## §6. 한 화면 계약 (기기)

모든 피드 장은 이 박스를 통과한다.

```
safeTop
  chromeRow     ≤ 48dp
  body          = 나머지. FittedBox가 아니라 역할 스케일(koDisplay→한 단계 다운)
  likeHotspot   = 장 전체 (더블탭) + 우하단 44dp 아이콘
safeBottom      시스템 제스처와 겹치지 않음
```

검증 뷰포트: **360×640, 390×844, 430×932, 800×1280**. 가로 모드는 본문을 스케일 다운하지, 좌우 스크롤을 열지 않는다. 접근성 글자 200%면 그 장만 세로로 살짝 스크롤 허용 — “한 화면”보다 읽기가 이긴다.

금지: 플레이어 안에 두 번째 대형 섹션(책장, 규칙, 히어로 배너, 전폭 버튼 4줄).

---

## §7. 구현 순서 (승인 후)

한 세션에 전부를 넣지 않는다. 계약이 있는 라이브 위젯이라 단계가 필요하다.

| Phase | 하는 일 | 완료 조건 |
|---|---|---|
| **P0 토큰** | `contentCta` / `like` / `koDisplay` / `gloss` / `meta`. 듣기·스피드매치·덱 저장 버튼의 tiger/gold/warning을 시맨틱으로 치환 | 콘텐츠 화면에서 버튼 accent가 info 또는 like. 가드 상한 상승 0 |
| **P1 토스트** | `addToWordbook`에 `hideCurrentSnackBar()`. 피드가 오기 전 임시 수정 | 연타해도 스낵바 1개, 1.5초 후 소멸 |
| **P2 피드 셸** | `SoriContentFeed` + `SoriLikeBurst` + `LikedContentService` + 테스트 | 세로만, 더블탭 하트, 가로 0, reduce-motion, 하트 버튼 대체 |
| **P3 듣기 분리** | 책장 라우트 ≠ 플레이어 라우트 | 재생 중 책장 픽셀 0. 1400px 테스트 폐기, 390×844 단언 |
| **P4 쓰기 크롬** | 규칙 시트, 캔버스 1개, 칩 퇴거 | 360×640에서 획 캔버스가 잘리지 않음 |
| **P5 덱 6화면** | 틴더 위젯 제거 또는 dead | `swipe_card` 호출 0. 기존 flipgate/SRS 테스트는 복습만 남김 |
| **P6 나머지 콘텐츠** | Cloze/Satz/Smalltalk/Scenario를 같은 셸에 | 화면마다 다른 AppBar/카드/CTA 0 |
| **P7 좋아요 스튜디오** | 좋아요만으로 연습/게임 | 없는 문장 생성 0. 기존 스튜디오 계약 |

P0–P1은 시각 승인 없이도 버그 수정으로 갈 수 있다. P2부터는 Jin의 §0 확인이 필요하다. `HANDOFF_UI_OVERHAUL_2`의 “승인 전 대규모 UI 재설계 금지”는 P2+에 적용한다.

---

## §8. 파일 지도

**신규**

- `lib/widgets/sori/content_feed.dart`
- `lib/widgets/sori/like_burst.dart`
- `lib/services/liked_content_service.dart`
- `lib/models/liked_content.dart`
- `test/content_feed_test.dart`, `test/liked_content_service_test.dart`

**핵심 교체**

- `swipe_card.dart`, `swipe_rails.dart`, `deck_action_bar.dart`, `deck_coach.dart`, `study_card_face.dart`
- `wordbook_add.dart`
- `tokens.dart`, `button.dart`

**화면**

- `listening_screen.dart` (+ 라우트 `main.dart`)
- `hangul_screen.dart` `_WriteTab`
- `vocab_pack_screen.dart`, `review_session_screen.dart`, `legacy_vocab_screen.dart`, `custom_pack_play_screen.dart`, `grammar_screen.dart`
- `cloze_game_screen.dart`, `satz_arcade_screen.dart`, `smalltalk_screen.dart`, `scenario_player_screen.dart`

**테스트 폐기·이전**

- `swipe_card_test.dart`, `deck_swipe_physics_test.dart`, `deck_direction_contract_test.dart`, `deck_action_bar_test.dart`, `hangul_swipe_and_prefetch_test.dart` → 피드/좋아요 센서로 이전
- flipgate·SRS 원장은 복습에만 유지

---

## §9. 하지 말 것

- Claymorphism, Baloo, Comic Neue, Noto로 Pretendard를 교체.
- 인스타 그라데이션 하트, iOS 필, 새 배지.
- 콘텐츠 플레이어에 다시 네모 히어로 카드.
- 피드에 앎/모름/Weiter를 “작게라도” 부활.
- 좋아요를 한옥 보상·코스 증거에 연결 (단어망과 같은 격리).
- 호랑이/까치 픽셀 재생성.
- 이 문서를 우회하는 화면별 원샷 리디자인.

---

## §10. Jin 확인 한 줄

§0 여섯 줄에 반대가 없으면 P0–P1을 바로 치고, P2부터 피드 구현에 들어가면 된다. 카드를 허브에 남기는 것(§0-5)만 다르게 가고 싶으면 그 한 줄만 고치면 된다.
