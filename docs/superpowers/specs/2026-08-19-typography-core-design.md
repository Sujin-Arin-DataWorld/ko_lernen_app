# 타이포 코어 설계 — 한글 폰트 복구 · 단일 램프 · 배율 하나 · 간격 · 잘림 가드 (2026-08-19)

> 대상: `docs/CONTENT_UIUX_FINISH_PLAN_2026-08-19.md` Phase 3(디자인 시스템 코어) 중 PR #93(`94bbf68a`)이
> **남겨 둔** 부분 — "배율 권한 4개를 ambient TextScaler 하나로 통합 + `SoriKoreanText` 도입" — 에
> 폰트 결함(아래 §0-1, 계획서가 몰랐던 사실)·간격 토큰·잘림 가드를 더해 이 세션(Windows,
> `claude/typography-core-20260819`)이 맡는다. Phase 4(콘텐츠 13화면 이관)는 이 코어 위에서 맥이 이어간다.
> Jin 결정(2026-08-19): 폰트 = **Wanted Sans**, 범위 = A+B+C+D 전부 여기서.
> 이미 끝난 것(#93, 건드리지 않음): `ko_wrap.dart` U+2060 재작성, `content_type_floor_test`(soriFillSize 하한 12.5),
> `content_palette_guard_test`, 래칫 하향(w900 28·w800 141·Pretendard 79·raw TextStyle 371·radius 38·AppBar 84).

## 0. 실측한 원인 (추정 아님)

| # | 사실 | 근거 |
|---|---|---|
| 1 | 번들 `PretendardStd-*.otf` 5개와 `GowunBatang-*.ttf` 2개 모두 **한글 글리프 0개** (cmap 실측: Hangul Syllables 0/11,172). 한국어는 전부 OS 폴백(Windows Chrome=맑은 고딕, Android=제조사 기본, iOS=Apple SD Gothic)으로 그려진다. `pubspec.yaml:185` 주석과 `tokens.dart:509-511` "단일 폰트" 전제가 한글에서 성립하지 않았다. | fontTools 실측 2026-08-19 |
| 2 | `fontSize:` 리터럴 31종(11/11.5/12/12.5/13/13.5/14/14.5 8단계 공존), raw `TextStyle(` 476곳 중 307곳이 크기 직접 지정. `SoriTextTheme`(337 사용)과 `ThemeData.textTheme`(3 사용)이 **값이 다른 병렬 램프**, `displayLarge`는 번들에 없는 w900. `caption`==`meta` 완전 중복. | 코드 감사 |
| 3 | 배율 3겹 곱: `soriComfortScale`(×1.10, letterSpacing까지) × `SoriStudyScale`(×1.35) × OS(×2.0). 폰(≤600dp)에선 앞 둘이 1.0이라 체감 0, 태블릿에서 폭주. | `tokens.dart:673-675`, `responsive.dart:175-216` |
| 4 | `maxLines:1 + ellipsis` ≈50곳(설계 규칙 금지), 문장급 잘림 ≥10곳. 고정 높이 안 텍스트 6곳이 1.3×부터 클리핑. 기존 배율 매트릭스 테스트는 `takeException()`만 봐서 **ellipsis 잘림을 못 잡는다**. (`SoriPhraseWrap` fade는 #93이 해결.) | 코드 감사 |
| 5 | 8px 그리드 이탈 `SizedBox(height:)` 리터럴 120곳, 페이지 좌우 여백 12/16/18/20/24 공존, `Spacing.pageH/cardInner/cardCompact` 사용 0. `SoriChip` 기본 ≈30dp, `SoriButton.sm` 40dp. | 코드 감사 |

## 1. 폰트 (A)

- **Wanted Sans v1.0.3** (OFL 1.1, github.com/wanteddev/wanted-sans) 정적 OTF
  Regular 400 / Medium 500 / SemiBold 600 / Bold 700 / ExtraBold 800 — 각 ≈1.35MB, 합 6.7MB.
  실측: 한글 11,172/11,172 · 호환자모 52 · ä ö ü Ä Ö Ü ß € „ “ ” – — … · → 전부 포함
  (빠진 것: 대문자 ẞ U+1E9E, 아래아 ㆍ — 앱 콘텐츠 미사용).
  `WantedSansStd`(라틴 전용 1.6MB)는 **쓰지 않는다** — Pretendard에서 밟은 함정과 동일.
- `assets/fonts/WantedSans/{WantedSans-Regular,Medium,SemiBold,Bold,ExtraBold}.otf` + `OFL.txt`.
  `assets/fonts/Pretendard/`·`assets/fonts/GowunBatang/` 삭제. `pubspec.yaml` `fonts:`는
  family **`WantedSans`** 하나. `google_fonts` 의존성 제거(참조 0).
- `SoriFonts.sans = 'WantedSans'`. 하드코딩 `fontFamily: 'Pretendard'` 79곳 → `SoriFonts.sans`
  (가족명이 바뀌므로 **남기면 시스템 폴백으로 떨어진다** — 0으로 만들고 래칫 0 고정).
  `SoriFonts.serif/serifFallback/display`·`_base(serif:)` 분기 삭제(참조 0).
- 테스트 `FontLoader('Pretendard')` 2곳(`game_layout_test`, `sori_stage_visual_evidence_test`) →
  `WantedSans` 경로. 골든 테스트는 실폰트를 안 싣는다(테스트 폰트) → 폰트 교체로는 안 변함.
- 새 가드 `test/font_bundle_guard_test.dart`: pubspec에 선언된 폰트 파일 전부에 대해
  `가`·`힣`·`ㄱ`·`ä`·`ß` 글리프 존재를 cmap(포맷 4/12)으로 확인 — 의존성 없는 ~80줄 파서.
  라틴 전용 서브셋이 다시 들어오는 사고를 CI가 막는다.

## 2. 단일 램프 + 배율 권한 하나 (B)

### 2.1 램프 (`SoriTextTheme`, Wanted Sans 기준)

| 역할 | 크기 | 굵기 | letterSpacing | height | 비고 |
|---|---|---|---|---|---|
| `koHero` | 56 | w700 | 0 | 1.10 | 신설. 자모/글자 한 개 |
| `hero` | 36 | w700 | −0.4 | 1.12 | 38/w800/−0.8 → 완화 |
| `display` | 30 | w700 | −0.3 | 1.18 | 32/w800 → |
| `koDisplay` | 30 | w700 | −0.2 | 1.28 | 28 → 30 (계획서 §3.2) |
| `numeral` | 30 | w700 | −0.2 | 1.1 | tabular 유지 |
| `h1` | 24 | w700 | −0.3 | 1.25 | w800 → w700 |
| `koDisplaySm` | 24 | w700 | −0.1 | 1.32 | 신설. 긴 한국어의 유일한 축소 단계 |
| `h2` | 20 | w700 | −0.2 | 1.3 | w800 → w700 |
| `h3` | 17 | w600 | −0.1 | 1.35 | w700 → w600 |
| `gloss` | 17 | w500 | 0 | 1.45 | textMuted |
| `body` | 15 | w500 | 0 | 1.5 | 1.45 → 1.5 (한국어 본문 하한) |
| `glossSm` | 15 | w500 | 0 | 1.45 | 신설. textMuted |
| `cardTitle` | 15 | w700 | −0.1 | 1.35 | 유지(BIBLE: 카드 제목 w700) |
| `bodySmall` | 14 | w500 | 0 | 1.45 | textMuted |
| `label` | 13 | w600 | 0.1 | 1.25 | w700 → w600 (최빈 166곳, 위계는 크기·색) |
| `caption` | 12.5 | w500 | 0 | 1.4 | textMuted |
| `meta` | 12.5 | w600 | 0 | 1.35 | textMuted. caption과 굵기로 구분(중복 해소) |
| `cardSubtitle` | 12.5 | w500 | 0 | 1.4 | 12 → 12.5 하한 |
| `eyebrow` | 12 | w700 | 1.2 | 1.2 | accent. 유지(대문자 라벨) |
| `serifDisplay` | = `hero` | | | | alias(@Deprecated) — 호출 유지, 신규 금지 |

원칙: 토큰 램프에 **w800/w900 없음**(ExtraBold는 raw 잔존 141곳 때문에 번들만 유지, 래칫으로 하향).
한국어 줄간격 하한 1.25, 본문 1.5. 자간은 대형만 음수, 본문 이하 0. 하한 12.5 예외 없음.

### 2.2 Material `TextTheme`은 램프에서 파생

`SoriTypeRamp`(신규, `tokens.dart` 안 정적 const: 역할별 size/weight/spacing/height, 색 없음)가 유일한 램프.
`SoriTextTheme.of(ctx)`는 surface 색만 입히고, `lib/theme.dart::_buildTextTheme`은 같은 램프를 Material 슬롯에
매핑한다: displayLarge←hero · displayMedium←display · displaySmall←koDisplaySm · headlineLarge←h1 ·
headlineMedium←h2 · headlineSmall←h3 · titleLarge←cardTitle · titleMedium←bodySmall(w600) · titleSmall←label ·
bodyLarge←body · bodyMedium←bodySmall · bodySmall←caption · labelLarge←label · labelMedium←meta ·
labelSmall←caption(+0.3 자간). w900 소멸. 컴포넌트 테마: AppBar 19/w800 → `h2`(20/w700), Chip 12 → 12.5,
ListTile subtitle 12 → 12.5, NavigationBar label 11 → 12, 나머지 유지. 모든 `fontFamily` 리터럴 → `SoriFonts.sans`.

### 2.3 배율 권한 하나

- `SoriTextTheme._base`에서 `* _deviceScale` 제거(fontSize·letterSpacing 둘 다).
- `lib/main.dart` `MaterialApp.builder`에 `SoriTypeScale`(신규, `lib/widgets/sori/type_scale.dart`):
  `MediaQuery(textScaler: SoriComfortTextScaler(os, soriComfortScale(width)))` — OS 배율 × 컴포트(≤1.10).
  Material 텍스트도 같이 스케일되고 letterSpacing은 배율을 안 탄다. `soriComfortScale` 커브는 유지
  (`sori_tablet_responsive_contract_test` 고정).
- `soriComfortScale`을 **글자 크기**에 직접 곱하던 호출부(`button.dart` fontSize 등 — 구현 시 `grep soriComfortScale(` 전수)는
  곱을 뺀다(TextScaler가 이미 한다 — 이중 적용 방지). 높이·패딩·아이콘 크기 곱은 유지.
- `SoriStudyScale`·`_StudyTextScaler`·`soriStudyScale` **삭제**(호출 17+3). `SoriStudyClamp`(폭) 유지.
  `study_scale_test.dart`에서 해당 그룹 삭제.
- `soriFillSize`·`soriStudyTypeScaleHeight`·`soriUniformFitSize`는 **이 PR에서 건드리지 않는다**
  (계획서 Phase 4가 호출부 정리). 주석으로 "TextScaler가 한 번 더 곱한다"를 명시.
- 폰(≤600dp)에선 comfort·study가 1.0이라 **Jin이 보는 390dp 화면은 크기 변화 0**(램프 변경분만 보임).

### 2.4 한국어 줄바꿈 — 완료(#93)
`ko_wrap.dart`는 U+2060 단일 문단으로 이미 재작성됨. 스파이크(2026-08-19)로 재확인: `포기하지` 한 줄 유지,
박스보다 넓은 토큰(독일어 27자·한글 18자)은 엔진이 비상 줄바꿈(오버플로 0) → 추가 측정 로직 불필요. 손대지 않는다.

### 2.5 단일 진입 위젯 — `lib/widgets/sori/content_type.dart` (신규)

- `SoriKoreanText(text, {role, maxLines, textAlign, key})` — `role` 기본 `koDisplay`; `text` 길이(공백 제외)로
  `koHero(1자) / koDisplay(≤14자) / koDisplaySm(그 이상)` 중 스냅(이산 3단계, 연속 배율 아님), `SoriPhraseWrap`으로 렌더,
  `FittedBox` 사용 금지. 덱 균일 크기(`uniformOver`)는 Phase 4에서 `soriUniformFitSize` 정리와 함께 — 이 PR은
  `double? fontSize` 오버라이드만 열어 둔다.
- `SoriGlossText(text, {maxLines, textAlign})` — 공백 제외 40자 초과 시 `glossSm`, 아니면 `gloss`.
- 이 PR은 위젯을 **만들고 테스트만** 한다. 화면 적용은 Phase 4(맥).

## 3. 간격·카드·터치 타깃 (C)

- `Spacing`: 사용 0인 `pageH`·`cardInner`·`cardCompact` 삭제. 신설
  `cardGap = 12`(카드 사이), `sectionGap = 24`, `gutter = 16`(폰), `gutterWide = 24`(≥600dp),
  `double soriPageGutter(BuildContext)`(폭으로 16/24), `double soriScrollBottomInset(BuildContext)` =
  `max(32, MediaQuery.paddingOf(ctx).bottom + 24)` — 리스트 끝이 홈 인디케이터·제스처 바에 가리지 않게.
  (리터럴 120곳 전수 교체는 범위 밖 — 토큰만 신설, 화면 작업 때 교체.)
- `SoriChip`: `minInteractiveHeight` 기본 `null` → **`onTap != null`이면 44**. 라벨 12 → 12.5.
- `SoriButton.sm`: 40 → 44 (`md` 48, `lg` 56 유지). 라벨 `fontFamily` 리터럴 → 토큰, fontSize의 comfort 곱 제거(§2.3).
- `docs/HANGUL_SORI_DESIGN_TOKENS.md`: TYPOGRAPHY 섹션 추가(폰트·램프·배율 규칙·신설 간격 토큰),
  존재하지 않는 `HANGUL_SORI_STYLE_GUIDE.md` 참조 제거, `Last Updated` 갱신.

## 4. 잘림 제거 + 가드 (D)

### 4.1 문장급 잘림 제거(이 PR) — 구현 시 현재 main 라인으로 재확인
| 위치 | 변경 |
|---|---|
| `hard_words_screen.dart` 독일어 뜻 | `maxLines:1+ellipsis` 제거(무제한) |
| `wordbook_search_screen.dart` 한국어 정의 | maxLines 2 → 4, 12 → caption |
| `content_feed.dart` 판정 CTA 3개 | maxLines 1 → 2, 중앙 정렬 |
| `deck_coach.dart` 힌트 | maxLines 1 → 2 |
| `empty_state.dart` · `scenarios_list_screen.dart` 빈 상태 · `speed_match_screen.dart` 규칙 · `sarangbang_screen.dart` 저장 표현 | ellipsis 제거(무제한) |
| `discover_screen.dart` · `learning_path_screen.dart` 본문 | maxLines 2 → 3 |
| `learning_path_screen.dart` statusText | `maxWidth:72` 제거 → Flexible |
| `module_card.dart` 제목 · `mission_context_bar.dart` · `illustrated_card.dart` subtitle · `scenarios_list_screen.dart` 제목 · `pack_card.dart` | maxLines 1 → 2 |
| `settings_screen.dart` URL | 유지(문장 아님) — 허용목록 |

### 4.2 고정 높이 → 최소 높이/배율 반영(이 PR)
`diktat_quest.dart`(22) · `kkeunmari_screen.dart`(38) · `legacy_vocab_screen.dart`(44)는 `SizedBox(height)` →
`ConstrainedBox(minHeight)`; `vocab_packs_screen.dart` `childAspectRatio 0.82`와 `personal_room_furnish_screen.dart`
`mainAxisExtent 126`은 `MediaQuery.textScalerOf` 반영(`sori_stage_catalog_screen.dart` `_cellAspectRatio` 패턴 재사용).

### 4.3 가드
- `test/support/text_clipping.dart`: `expectNoClippedText(tester, {allow})` — 렌더 트리의 모든 `RenderParagraph`에
  대해 `didExceedMaxLines == false` 단언(허용 Key 목록 예외) + `takeException()` null.
- 기존 배율 매트릭스 테스트(`sori_stage_responsive_accessibility_test.dart` 390/720/1280 × 1.0/1.3/2.0,
  `visual_layout_regression_test.dart`)에 위 헬퍼를 연결. 신규 `test/text_clipping_matrix_test.dart`: Firebase 없이
  펌프되는 화면(문법·단어팩·듣기 플레이·스몰톡·설정 — 기존 위젯 테스트가 이미 펌프하는 것들)을
  **360×640 / 390×844 / 430×932 / 800×1280 × 1.0/1.3/2.0**에서 펌프해 잘림·오버플로 0 단언. 실패하면 허용목록이
  아니라 화면을 고친다.
- `typography_guard_test.dart` 래칫 추가: `maxLines: 1`·`TextOverflow.ellipsis` 상한(실측−수정분), `fontFamily: 'Pretendard'`
  **0**, w900·w800 재실측 하향.

## 5. 범위 밖 (명시)
콘텐츠 13화면의 `soriFillSize`/`FittedBox`/raw AppBar 이관(Phase 4) · 문법 허브(Phase 5) · `SizedBox(height:)` 리터럴
120곳 전수 교체 · 다크 테마 부활 · 피드 제스처.

## 6. 검증·전달
- `flutter analyze` 클린. 테스트: 신규 3종 + `typography_guard`·`sori_phrase_wrap`·`study_scale`·
  `sori_tablet_responsive_contract`·`visual_layout_regression`·`circular_feedback_widget`·`grammar_type_filter`·
  `game_layout`·`sori_stage_visual_evidence`·`content_type_floor`·골든(램프 변경으로 **골든 재생성 필요**, 변경분 시각 확인)
  → 마지막에 `flutter test` 전체.
- 웹 프리뷰(Chrome)로 360/390/430/800 폭에서 문법·단어팩·듣기 화면 스크린샷 — Wanted Sans 렌더 증빙.
- 브랜치 `claude/typography-core-20260819`(worktree `.claude/worktrees/typography-core`, base `94bbf68a`),
  블록별 커밋(A → B-배율 → B-램프 → B-위젯 → C → D → 문서), PR 1개. 머지는 Jin 승인 후.
- `docs/SESSION_LOG.md` 최상단 기록. `CONTENT_UIUX_FINISH_PLAN` Phase 3 머리에 "§3.1·3.2·3.4는 이 문서로 실행" 한 줄.
