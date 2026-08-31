# Content UI Bible — Hangul Sori

> **역할**: 콘텐츠를 연 뒤의 화면(단어·듣기·쓰기·문법·클로즈·문장·스몰톡·시나리오·복습)에 대한 **유일한 상호작용·타이포·CTA 정본**.
> **범위**: 플레이어/피드만. 한옥 자산은 `docs/assets/STYLE_LOCK.json`, 일러스트 생성은 `docs/ASSET_GENERATION_BIBLE.md`, 홈/Today 매트는 `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`를 유지한다.
> **상태**: 2026-08-19 Jin이 전역 개편·틴더 제거를 지시. 공유 이미지 **안 A 두루마리** 확정. P0–P7 구현. Play 자동배포는 내부테스트(`internal`)만.
> **선행 문서 정정**: `HANDOFF_UI_OVERHAUL_2` §1-1·§1-2(좌=모름·우=앎·위=저장·아래=스킵, 하단 원형 4버튼)는 **이 문서가 대체한다**. 4방향 틴더 덱은 폐기 대상이다.

---

## §0. Jin이 잠글 결정 (구현 전 확인)

이 여덟 줄이 맞으면 구현 세션은 더 묻지 않는다.

1. **콘텐츠 CTA는 녹청 하나.** 채움/강조 = `SoriColors.primary` `#1F7A6B`. 레벨 칩만 `info` `#57799E`. 주황·황은 버튼에서 뺀다. 호랑이 주황은 마스코트만, 황은 XP/스트릭만. (2026-08-19 Jin: 듣기 블루 CTA 철회)
2. **세로 피드가 전역 이동이다.** 위·아래로만, 매우 빠르게. 왼쪽·오른쪽 스와이프 없음. `Weiter`·모름·앎 버튼은 콘텐츠 열람에서 제거.
3. **하트와 보관은 다른 기능이다.** 더블탭/`♡` = 좋아요(감정, 나중에 놀이). 책갈피 = 단어장 보관(공부용 아카이브). 둘을 한 동작으로 합치지 않는다. 상세 §12.
4. **한 장 = 한 화면.** 기기 높이 안에서 본문이 잘리지 않게 담고, 다음 장은 아래로 넘긴다. 플레이어와 책장/규칙 패널을 같은 화면에 겹치지 않는다.
5. **콘텐츠 플레이어에서 네모 카드(hero `SoriCard`)를 뺀다.** 한지 배경 위에 글과 소리가 바로 앉는다. 카드는 허브·목록·선택지처럼 *고르는* 자리에만 남긴다.
6. **폰트는 2개뿐: Wanted Sans + Maru Buri.** `SoriFonts.sans`(기본 UI, DE/EN 전체)와 `SoriFonts.culture`(짧은 한국 문화 타이틀·완성 순간 전용, 번들 400/600만). 새 웹폰트·키즈 폰트 추가 금지, `fontFamily` 하드코딩 금지 — 항상 `SoriTextTheme` 토큰 경유. 위계는 기본적으로 크기·굵기만.
7. **`i` 대신 `?`가 뒤집기다.** 한 번 탭하면 뜻/뒷면이 한지 위에서 뒤집힌다. 정보 시트가 아니다.
8. **공유는 1등 동작이다.** 시스템 공유 + 생성된 이야기 이미지. 화면 스크린샷이나 검정 테두리 디지털 카드가 아니다. 이미지 3안은 §13. **잠금: A 두루마리.** B는 장면이 단어를 잡아먹을 위험, C는 너무 조용해서 기각.

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
│  닫기          1/5  소리    │  ← 얇은 크롬. 진행은 단청 잉크 획
│                             │
│         한국말              │  ← koDisplay, 상자 없음
│     (앞면: 뜻 숨김 가능)     │
│                             │
│    ?    공유    ♡    보관   │  ← 인장형 아이콘, iOS 라인 아이콘 아님
└─────────────────────────────┘
        ↑ 빠른 세로 플링
```

벤치마크(thevocabulary.app)에서 **가져오는 것**은 이 뼈대다. 다크모드·세리프 영단어·동그란 회색 버튼·검정 외곽선은 가져오지 않는다. 상세 §11.

동작:

| 입력 | 결과 |
|---|---|
| 위로 플링 / 아래로 플링 | 다음 / 이전 장. `PageScrollPhysics`, 임계 낮고 감속 짧음 |
| `?` 탭 | 앞↔뒤 플립. 뒷면 = 뜻·예문·품사 (`gloss`). `i` 정보 시트 아님 |
| 단어 한 번 탭 | `?`와 동일 (큰 히트 영역) |
| 더블탭 / `♡` | `onLike` + `SoriLikeBurst`. 단어장에 넣지 않음 |
| 보관(책갈피) 탭 | `quickAdd` / 컬렉션. 하트와 분리. 스낵바 대신 책갈피가 먹으로 채워짐 |
| 공유 탭 | 이야기 이미지 생성 후 시스템 시트. 브랜드 원형 아이콘 9개 금지 |
| 좌우 드래그 | **무시.** 시스템 뒤로가기에 양보 |
| 재생 | 듣기/발음만. CTA 색은 `contentCta` |

속도: 입력 후 100ms 안에 페이지가 따라온다. reduce-motion이면 플링 애니메이션 없이 즉시 장만 바꾼다. 하트는 transform/opacity만(Vercel animation 규칙).

데이터는 두 서랍이다 (§12):

- **좋아요** → 신규 `LikedContentService`. 키 `kind + id`. 스튜디오의 “놀이 덱” 재료.
- **보관** → 기존 `CustomPackService.quickAdd` / 단어장. 공부·복습·내보내기 재료.
- 단어 좋아요가 자동으로 단어장에 들어가지 **않는다**. 둘 다 누를 수는 있다.

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

좋아요: 더블탭 → `LikedContentService`만. 보관: 책갈피 → `quickAdd`. 둘 다 스낵바 없음.

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
  likeHotspot   = 장 전체 (더블탭) + 우하단 48dp 아이콘
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
| **P2 피드 셸** | `SoriContentFeed` + `?` 플립 + 하트/보관 분리 + `SoriLikeBurst` + 테스트 | 세로만, `?`가 플립, 더블탭은 보관이 아님, 가로 0, reduce-motion |
| **P3 듣기 분리** | 책장 라우트 ≠ 플레이어 라우트 | 재생 중 책장 픽셀 0. 1400px 테스트 폐기, 390×844 단언 |
| **P4 쓰기 크롬** | 규칙 시트, 캔버스 1개, 칩 퇴거 | 360×640에서 획 캔버스가 잘리지 않음 |
| **P5 덱 6화면** | 틴더 위젯 제거 또는 dead | `swipe_card` 호출 0. 기존 flipgate/SRS 테스트는 복습만 남김 |
| **P6 나머지 콘텐츠** | Cloze/Satz/Smalltalk/Scenario를 같은 셸에 | 화면마다 다른 AppBar/카드/CTA 0 |
| **P7 좋아요 스튜디오 + 공유** | 좋아요=놀이, 보관=단어장. 공유 이미지 안 A(두루마리) | 없는 문장 생성 0. 공유 PNG에 검정 외곽선 0 |

P0–P1은 시각 승인 없이도 버그 수정으로 갈 수 있다. P2부터는 Jin의 §0 확인이 필요하다. `HANDOFF_UI_OVERHAUL_2`의 “승인 전 대규모 UI 재설계 금지”는 P2+에 적용한다.

---

## §8. 파일 지도

**신규**

- `lib/widgets/sori/content_feed.dart`
- `lib/widgets/sori/like_burst.dart`
- `lib/widgets/sori/share_slip.dart` (이야기 이미지 렌더러)
- `lib/services/liked_content_service.dart`
- `lib/services/content_share_service.dart`
- `lib/models/liked_content.dart`
- `test/content_feed_test.dart`, `test/liked_content_service_test.dart`, `test/content_share_slip_test.dart`

**핵심 교체**

- `swipe_card.dart`, `swipe_rails.dart`, `deck_action_bar.dart`, `deck_coach.dart`, `study_card_face.dart`
- `wordbook_add.dart`
- `tokens.dart`, `button.dart`

**화면**

- `listening_screen.dart` (책가도만) + `listening_play_screen.dart` (`/listening/play`)
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

§0 여덟 줄에 반대가 없으면 P0–P1을 바로 치고, P2부터 피드 구현에 들어가면 된다. 공유 이미지를 A가 아니라 B/C로 가고 싶으면 그 한 줄만 고치면 된다.

---

## §11. 벤치마크 — 가져올 뼈대 / 버릴 피부

레퍼런스: thevocabulary.app 단어 장 (`Lebemann` 화면). **IA와 속도만 훔친다. 피부는 버린다.**

| 가져온다 | 버린다 |
|---|---|
| 단어가 화면의 주인공. 크롬은 속삭인다 | 숯 다크모드, 차가운 디지털 세리프 |
| 상단 `1/5` + 짧은 진행 | iOS 얇은 프로그레스 바, 왕관 페이월 아이콘 |
| 하단 동작 4개: 정보 / 공유 / 하트 / 보관 | 회색 원 + SF 라인 아이콘, `i` 글리프 |
| 공유하면 *만든 이미지*가 나간다 | 시스템 공유 시트에 브랜드 원 9개 나열 |
| 하트와 책갈피를 한 줄에 공존 | 둘을 같은 “저장”으로 합치기 |
| 세로로 다음 단어 | 틴더 좌우, 큰 네모 카드 |

우리 피부 (수석 방향):

- 배경은 한지 `#FAF6EC`. 다크 벤치마크를 따라가지 않는다. 한옥은 낮의 마루다.
- 글은 Pretendard. 한국어가 세리프처럼 보이게 하려고 명조를 섞지 않는다(한글 명조 품질·라틴 분열 — 기존 폐기 이유).
- 아이콘은 **먹 인장 / 단청 면분할**. 검정 스트로크 라인아이콘 금지. 형태는 맞닿은 색면 (`STYLE_LOCK`·BIBLE §1.2 “NO outlines”).
- 진행은 단청 띠가 한 획으로 스며든다. 매끈한 캡슐 바가 아니다.
- 거칠고 손으로 찍은 리소 질감(오버홀 2의 인쇄 결). 벡터처럼 반듯하면 실패다.
- 힙함은 네온이 아니라 **여백 + 큰 한글 + 작은 도장**. 박물관 도슨트 톤도, 키즈 클레이도 아니다.

`frontend-design`: 시그니처는 하나. 이 장의 시그니처는 **한지 한가운데 한글**. 벤치마크의 검정 카드는 그 자리를 다시 상자로 죽인다.

---

## §12. 하트 vs 보관 — 스킬로 나눈 기능

`npx skills find`로 공유/북마크 스킬을 찾았다. like-vs-archive를 직접 다루는 1K+ 공식 스킬은 없었다. 가까운 것:

| 스킬 | 설치 | 평판 | 이 결정에 쓰는 부분 |
|---|---|---|---|
| [kostja94/marketing-skills@social-share-generator](https://skills.sh/kostja94/marketing-skills/social-share-generator) | 842, repo ★903 | 통과 | 버튼은 적게, **감정 최고점**에만 공유. OG/이미지가 버튼 수보다 중요 |
| [kostja94/marketing-skills@open-graph](https://skills.sh/kostja94/marketing-skills/open-graph) | 926 | 통과 | 미리보기 이미지가 공유의 본체 |
| [langchain-ai/deepagents@social-media](https://skills.sh/langchain-ai/deepagents/social-media) | 2.6K, ★27.9K | 공식에 가깝 | 인앱 UX가 아니라 캡션 작성. **설치하지 않는다** |
| mengto `x-bookmark-quote-posts` | 260 | 1000 미만 → 채택 안 함 | — |

ui-ux-pro-max `favorites bookmark` 검색은 칩 리플로우만 나와 매칭 실패. 폴백은 인스타 관용(2026): **더블탭/하트 = 약한 즉시 신호, 저장/북마크 = 강한 의도**.

그래서 우리 앱의 두 서랍은 이렇게 가른다.

| | 좋아요 `♡` | 보관 책갈피 |
|---|---|---|
| 마음 | “이거 좋다. 나중에 놀고 싶다.” | “이건 내 공부에 넣는다.” |
| 제스처 | 더블탭 + 아이콘 | 아이콘만 (실수 방지. 더블탭과 안 겹침) |
| 데이터 | `LikedContentService` | `quickAdd` / 단어장 / 기존 즐겨찾기 통합 |
| 어디로 가나 | 놀이 스튜디오 — 좋아요만으로 게임 | 책장·검색·복습·내보내기 |
| 피드백 | 큰 하트 한 번. 토스트 없음 | 책갈피가 먹(s.text)으로 채워짐. 토스트 없음 |
| 공개 | 비공개 감정 | 비공개 아카이브. 공유와 무관 |
| 기존 코드 | 신규 | `wordbook_add.dart` + `Storage.vokFavorites`를 이 아이콘으로 흡수 |

벤치마크가 하트와 책갈피를 한 줄에 둔 이유는 이것이다. 우리가 어제 계획에서 “더블탭 = 저장”으로 합치면 공부 아카이브와 놀이 덱이 다시 섞인다.

접근성: 하트·보관·`?`·공유는 각각 48dp + 독일어 라벨 (`Gefällt mir` / `Merken` / `Umdrehen` / `Teilen`). 제스처만으로 닫지 않는다.

---

## §13. 공유 이미지 3안

스킬 규칙: 버튼 9개보다 **한 장의 그림**. 앱은 `SharePlus`로 텍스트만 나눈다(계 코드·팩). 콘텐츠 공유는 **이미지를 만들어** 넘긴다. 검정 테두리·스크린샷·앱 UI 크롬 금지.

세 안 모두 Faceted Minhwa, 한지 그레인, **외곽선 0**.

### 안 A — 두루마리 (기본 · 추천)

9:16 이야기 + 1:1 잘라 쓰기. 세로 한지 두루마리가 살짝 말리고, 가운데 한국어 `koDisplay`, 아래 DE `gloss` 한 줄, 우측 하단 작은 한글소리 도장. 책가도 나무 칸이 위아래를 살짝 자른다. 호랑이/까치는 없거나 도장만.

- 왜: 듣기 책가도와 세계가 같고, 스토리 앱에 붙는다.
- 위험: 두루마리가 진부한 스크롤 클리셰가 되면 안 됨. 나무·한지는 STYLE_LOCK 실측 hex.

### 안 B — 사랑방 한 장면

4:5 포스터. 사랑방 마루 위에 단어가 병풍처럼 떠 있다. 가구는 면분할, 창으로 마당 한 조각. 단어가 가구보다 크다. 마스코트는 증인이면 되고 주인공이 아니다.

- 왜: 가장 센세이션. 저장하면 “한국 방”이 보인다.
- 위험: 장면이 단어를 잡아먹음. 단어 대비 4.5:1 미달 시 폐기.

### 안 C — 시조 쪽지

1:1 또는 4:5. 손으로 찢은 한지 쪽지, 먹 번짐, 석간주 도장 하나. 단어 + 품사 + 예문 한 줄. 벤치마크의 “카드 이미지로 저장”에 가장 가깝되, 둥근 디지털 카드가 아니다.

- 왜: WhatsApp/메시지에서 읽힌다. 생성 비용 최저.
- 위험: 너무 조용하면 공유가 안 된다. 도장·찢김이 필수.

**잠금: A.** vercel composition/optimize(렌더러 하나·9:16에서 1:1 크롭), react-native-skills(스토리 비율), web-design-guidelines(대비·큰 한글), writing-guidelines(짧은 캡션), frontend-design·brand(한지 두루마리가 시그니처), canvas-design(세로 장), web-artifacts-builder(만든 이미지가 공유 본체), discernment-nudge(기존 책가도 세계와 맞음). B는 장면이 단어를 잡아먹을 레이아웃 버그 위험, C는 벤치마크 복제에 가깝고 너무 조용하다. ui-ux-pro-max Claymorphism/키즈 폰트는 기각.

시트에는 `Thema`·인스타 원형 로고를 그리지 않는다. `이야기 만들기` 하나 → 생성 → 시스템 공유. 캡션은 DE/EN 한 줄 + 한국어 + `hangul-sori.com`. 감정 최고점은 **뒷면을 연 직후** 또는 좋아요 직후(스킬: 버튼은 그 순간에만 강조).

---

## §14. 수석 디자이너 — 한옥을 힙하게 다시 짜는 법

벤치마크는 *깨끗한 디지털 사전*이다. 우리는 *손으로 찍은 사랑방 피드*다.

**한 문장.** 학습자는 한지 마루에 앉아 단어를 넘긴다. 글이 가구고, 동작은 인장이다.

**공간**

- 플레이어 = 마루(한지). 허브 = 마당/책가도(고르는 곳). 두 공간을 한 화면에 겹치지 않는다.
- 여백을 가구처럼 쓴다. 패딩 24 상자로 글을 가두지 않는다.
- 하단 5탭은 지금 Sori Stage를 유지하되, 플레이어 안에서는 숨기거나 한지에 녹인다. 벤치마크의 floating pill 탭을 복제하지 않는다.

**물질**

- 면이 맞닿아 형태가 생긴다. 검정 라인으로 그림을 그리지 않는다.
- 리소 그레인, 살짝 어긋난 판. 완벽한 원·1px 헤어라인은 허브 선택지에만.
- 아이콘 4종(`?` 공유 하트 보관)은 하나의 인장 세트. 소재가 안 오면 Material 폴백을 쓰지 않고 **면분할 도형**으로 그린다(원 안에 i 금지).

**움직임**

- 세로 플링이 문짝이 아니라 마루를 쓸고 지나가는 속도.
- 플립은 카드 원근이 아니라 한지가 한 번 뒤집히는 짧은 회전. 220ms 이하.
- 하트는 석간주 면. 인스타 핑크 그라데이션 금지.

**위계**

- 한국어 28–32. 뜻 17. 크롬 12.5. 아이콘은 글보다 작다.
- 색: 마루 한지, 글 먹, 동작 청금석/석간주, 보상만 황.

**성공 기준**

1. 스크린샷만 봐도 Hangul Sori인지 3초 안에 안다 (두루마리·한지·도장).
2. thevocabulary.app과 나란히 두면 *같은 앱처럼 안 보인다*.
3. 어떤 장에도 검정 외곽선·회색 원 아이콘·주황 CTA가 없다.
4. 하트를 눌러도 단어장이 안 늘고, 보관을 눌러야 는다.
5. 공유 이미지가 앱 스크린샷이 아니다.

이 다섯이 아니면 리디자인이 아니라 스킨이다.

---

## §15. 기기 적응 레이아웃 계약 (UIUX 바이블 2.0)

`SoriLayout`(`tokens.dart`)이 정본.

- **heroMaxShare 0.22** — 히어로 배너 높이 상한, 화면 높이의 22%. **전
  뷰포트에 상시** 적용한다(구 `_askBelowHeight` 700dp 게이트 삭제 — 360×640
  세로 폰도 배너가 화면의 51%를 먹던 실측 버그의 원인이었다).
- **heroMaxHeight 200dp** — 절대 상한. 태블릿 등 22%가 200dp를 넘는 화면에서
  한 번 더 막는다.
- **heroCollapsedHeight 96dp** — `SoriStudyFrame(hero:)` 슬롯 전용 고정 높이.
- **플레이 화면(SoriStudyFrame) 히어로 0dp** — `hero` 슬롯에 아무것도 안
  넘기면 자리 자체가 없다. 히어로는 "고르는" 화면(허브·카탈로그) 전용이다.
- **크롬 행 44/48dp** — `chromeRowHeight`(시각) / `chromeRowTouchHeight`
  (터치 타깃, WCAG 2.5.5). `SoriChromeRow`(§17)·`SoriLevelFilterBar`(검수#5)가
  이 두 값을 공유한다.
- **비율 고정 히어로는 폭으로 맞춘다 — 자르지 않는다.** 비율(aspectRatio)은
  콘텐츠 계약(포스터·루프 원본 프레이밍 보존), 높이 예산은 레이아웃 계약 —
  둘은 동시에 성립해야 한다. 자연 높이가 예산을 넘을 때 높이만 줄이면 비율이
  깨져 크롭·찌그러짐이 생기거나(구현 방식에 따라) 통째로 0dp가 된다
  (`scenarios_list_screen`의 16:9 종가 히어로가 360×780에서 사라지던 회귀 —
  컨트롤러 룰링 2026-08-27). `SoriLayout.heroFit()`이 그 대신 높이를 예산까지
  줄이고 **폭도 같은 비율로** 줄여(중앙 정렬) 비율을 지킨 채 작아진다.
  `HanokHeader`가 내부적으로 쓴다 — 호출부는 `aspectRatio`만 넘기면 된다.

강제: `hero_placement_guard_test.dart` — HanokHeader는 고르는 화면 7곳만
허용, 학습 화면 4곳은 §19 이행 대기 그랜드파더(늘리기 금지).
`sori_layout_hero_fit_test.dart` — `heroFit`이 좁은 화면에서 비율을 지키며
폭을 줄이는지, 이미 예산 안에 들어오는 화면은 그대로 두는지 고정한다.

---

## §16. 간격 리듬 문법

`SoriGaps`(`tokens.dart`) — 전부 기존 `Spacing` 별칭, 신규 hex/px 없음.

| 이름 | 값 | 용도 |
|---|---|---|
| `optionGap` | 12 | 선택지 사이(4.10) |
| `cardGap` | 16 | 카드 사이 |
| `sectionGap` | 24 | 섹션 사이 |
| `questionToOptions` | 24 | 질문 → 선택지(4.8) |
| `labelToField` | 8 | 폼 라벨 → 입력 |
| `chromeToContent` | 16 | 크롬 → 본문 |
| `headingToBody` | 8 | 제목 → 본문 |
| `paragraphGap` | 12 | 문단 사이 |

그리드 밖(0/4/8/12/16/24/32/48 이외) 숫자 리터럴은 신규 0 —
`spacing_literal_guard_test.dart`가 강제한다(기준선 181, 하향만).

---

## §17. 타입·컨트롤·상태

- **역할 스케일** — `SoriTextTheme` 정본. 인터랙티브 라벨 ≥13, 선택지 타일
  ≥16(지시서 4.12).
- **`SoriChromeRow`(`widgets/sori/chrome_row.dart`)** — 앱바 아래 단 1줄:
  leading 필터 아이콘(탭 → 필터 시트, 레벨 필 전부를 시트 안으로) · center
  진행 메타 · trailing TTS 배속 1개. **Wrap 칩 줄 스택 금지** —
  `chrome_stack_guard_test.dart`가 화면당 1블록으로 강제한다.
- **상태** — `SoriPressable`(0.96 스케일, tap-down 150ms ease-out / tap-up
  250ms elasticOut)이 모든 탭 요소의 정본 눌림 상태다(추가 코드 변경 없음 —
  기존 구현이 이미 이 스펙과 일치, §17이 문서로 고정). `SoriButton(loading:)`
  신설 — 비동기 액션 중 탭 차단+회전 인디케이터, 색은 평소 활성 스타일 유지.
  `InkWell` 리플 신규 금지(`chrome_stack_guard_test.dart` 래칫).

---

## §18. 강제 장치

문서가 아니라 컴포넌트·가드가 지킨다.

- `SoriStudyFrame(hero:)` — 유일한 히어로 경로. §15 클램프(96dp)가 내장돼
  있어 콜러가 얼마나 큰 위젯을 넘기든 화면 예산을 못 넘는다.
- `SoriChromeRow` — 유일한 필터/진행 크롬 컨테이너.
- **가드 4종**(전부 `test/`, typography_guard와 같은 "실측 기준선 → 하향만"
  문법):
  1. `hero_placement_guard_test.dart` — HanokHeader는 고르는 화면 7곳 또는
     §19 이행 대기 4곳(chosung/hangul/legacy_vocab/kkeunmari)에서만.
  2. `chrome_stack_guard_test.dart` — 화면당 Wrap+칩 블록 ≤1(chosung_quiz·
     hangul·legacy_vocab·scenario_player 4곳만 §19 이행 전 그랜드파더) +
     InkWell 리플 신규 0.
  3. `spacing_literal_guard_test.dart` — 그리드 밖 간격 리터럴 신규 0(하향
     래칫).
  4. `typography_guard_test.dart` — 기존 9개 래칫 + 신규 "원시 TextStyle(
     안 fontSize 리터럴" 래칫.

---

## §20. 거버넌스 — 바이블 판정 기록

새 UI 불일치를 발견하면: **판정**(미적용/바이블 부재/바이블 결함) → 근거
절 인용 → 조치 → 가드 갱신, 순으로 이 표에 한 줄 추가한다. "바이블 결함"
판정만 §15-§19 자체를 고친다 — "미적용"은 화면을 고치고 바이블은 그대로
둔다.

| 사례 | 판정 | 근거/조치 | 가드 |
|---|---|---|---|
| 2.3 Anlaut-Quiz 크롬 4단 적층 | 바이블 부재 | §15(히어로 예산)·§17.2(크롬 행 단일화) 신설로 해소 | `hero_placement_guard`·`chrome_stack_guard` |
| 4.8 질문→선택지 간격 임의값 | 바이블 부재 | §16 `questionToOptions` 신설 | `spacing_literal_guard` |
| 4.10 선택지 사이 간격 임의값 | 바이블 부재 | §16 `optionGap` 신설 | `spacing_literal_guard` |

**웨이브 배선:** §15-§18(토큰·컴포넌트·가드)은 W3 첫 태스크로 랜딩. §19
이행표(화면별 실제 적용)는 W5. 이 §20 거버넌스 절차는 W3부터 상시.
