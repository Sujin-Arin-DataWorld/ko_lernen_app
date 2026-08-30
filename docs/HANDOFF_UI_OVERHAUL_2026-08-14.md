# HANDOFF — UI 개편 "Vocabulary급 깔끔함 × Faceted Minhwa" (2026-08-14)

> **⚠️ 최신 정본 (2026-08-14 저녁)**: 진행 상태·작업 프로세스·남은 일은
> **`HANDOFF_UI_OVERHAUL_2026-08-14_V2.md`** 를 먼저 읽어라 (§D~§H 완료됨).
> 이 문서의 §1(구속 결정)·§3(계약 8종)·§5(에셋 런북·앵커 URL)는 여전히 유효.

> **⚠️ 업데이트 (2026-08-14 오후)**: Phase 3-1(카탈로그 그리드)·4-A(스와이프 확산)가 별도
> 세션에서 진행됐고, 그 리뷰 피드백과 **남은 Phase 의 상세 실행 스펙**은
> **`docs/UI_OVERHAUL_WORK_ORDER_2026-08-14.md`** 가 정본이다 — §4 를 대체한다.
> 이 문서의 계약(§1~§3)·에셋 런북(§5)·검증(§6)·Jin 대기(§7)는 그대로 유효.

> **수신자**: 다음 AI 세션 (Antigravity / Opus 4.6 등 — 누구든).
> **발신자**: Claude (Fable 5) 세션, Jin 승인 플랜 기반으로 Phase 0·1·2 + 에셋 + 스와이프 완료.
> **먼저 읽을 것**: `AGENTS.md`(상시 규칙) → 이 문서 → `docs/SESSION_LOG.md` 상단 3개 항목.
> **전부 미커밋 상태다.** 커밋은 Jin 이 명시 요청할 때만, 단계별로 나눠서.

---

## 0. 미션 한 문장

Vocabulary 앱(thevocabulary.app)의 **깔끔함의 실체 4가지** — ①타이포 위계(대형 헤드라인+eyebrow), ②균일 일러스트 카드 규율, ③단일 화풍 일러스트, ④화면당 1메시지(여백+헤드라인+옵션+고정 CTA) — 를 한글소리의 **한지·Faceted Minhwa·호랑이/까치·한옥 성장** 정체성 위에 얹는다. 다크 전환 아님, 모방 아님 — 구조 이식.

## 1. Jin 의 구속력 있는 결정 (변경 금지)

1. **라이트 한지 유지** — 다크 우선 전환 없음. 배경은 크림 계열.
2. **SoriStage 5탭 셸이 정본** (Today·Learn·Games·Hanok·Gye) — 2c 에서 기본 ON 완료.
3. **호랑이·까치 캐릭터 이미지 AI 생성 절대 금지** (`docs/ASSET_GAP_R6_CONFIRMED_2026-08-03.md` ⛔ — 기존 파일 합성만). 비캐릭터 아트(카테고리/온보딩/페이월)는 신규 생성 허용.
4. **단계적 배포** — 각 단계 독립 배포 가능 + Jin 시각 승인 게이트.
5. **(2026-08-14 신규) 스와이프 판정** — 학습 카드의 Gewusst/Nicht-gewusst 를 데이팅앱식 좌/우 스와이프로도. 버튼은 접근성 정본으로 유지.

설계 결정: **D1** 한국어 세리프 번들 안 함(과거 실패 이력) — 위계는 `SoriTextTheme.hero`(38/w800)+`eyebrow` 로. 미래 세리프 도입 지점은 `SoriFonts.display` 상수 하나. **D2** `SoriColors` 값 불변(hex 단언 테스트 2종 + teal kill-switch 보호) — 추가만 허용. **D3** Hanok 탭 유지(=영혼 있는 통계), Stats 는 Today 톱바 칩 딥링크. **D4** 레거시 셸은 `--dart-define=ENABLE_SORI_STAGE=false` 롤백 경로로 1릴리스 보존.

## 2. 완료된 것 (이 세션, 전부 미커밋)

### Phase 0 — 정리
- `home_screen.dart` 데드 대시보드 등 1,000+줄 제거 (2,665→최종 1,162줄), 데드 화면 2개 삭제(learn_hub·wordbook_hub + 골든 3장). **wordle_screen.dart 는 데드지만 병행 세션이 수정 중이라 삭제 보류** — Phase 4 때.
- **래칫 3종 추가** → `test/typography_guard_test.dart` (기존 가드에 통합): 화면 raw `TextStyle(` ≤449 · 숫자 `BorderRadius.circular(` ≤64 · 화면 raw `AppBar(` ≤105. **상한은 내려가기만 한다. 새 코드는 토큰/공용 위젯만.**

### Phase 1 — 디자인 언어 (파일럿: 단어팩 그리드)
- `tokens.dart` 추가: `SoriTextTheme.hero`(38/w800/−0.8)·`eyebrow`(12/w700/자간1.4/석간주)·`Spacing.page`(20,20,20,48)·`SoriFonts.display`.
- 신규 공용 위젯: `widgets/sori/app_bar.dart` **SoriAppBar**(투명·좌측 h2·eyebrow 옵션) / `page_header.dart` **SoriPageHeader**(eyebrow→hero→body→trailing; `SoriStageRootHeader` 가 위임) / `illustrated_card.dart` **SoriIllustratedCard**(16:10 일러스트 슬롯+errorBuilder 폴백 계약, 상태 normal/locked/premium/cleared).
- `pack_card.dart` → SoriIllustratedCard 기반 재구성 (공개 API 불변). 일러스트 규약 `assets/illustrations/packs/{DancheongMotif.name}.webp`, 폴백 = 단청 도장 → **아트 없이 화면 먼저 배포 가능** 계약.
- `vocab_packs_screen.dart` 파일럿: SoriAppBar ×3, 그리드 childAspectRatio 0.92→0.82. `pubspec.yaml` 에 `assets/illustrations/packs/` 등록.

### 에셋 — 팩 일러스트 14종 (§5 런북 참조)
`assets/illustrations/packs/{lotus,chrysanthemum,plum,bamboo,cloud,octagon,mountain,manja,vine,chilbo,gwigap,wave,taegeuk,peony}.webp` — 800px q88, 세트 404KB. Jin 시각 승인 완료.

### Phase 2 — SoriStage 셸 부활 (2026-08-13 롤백 사유 수리)
- **2a**: 홈 히어로/톱바/주간시트를 본문 그대로 공용화 → `widgets/sori/home_hero.dart`(**SoriCharacterHero** + `SoriDayPhase`/`soriDayPhaseFor`/`soriHeroGreeting`) · `stats_top_bar.dart`(**SoriStatsTopBar**) · `week_sheet.dart`(`showSoriWeekSheet`). 게이트 = 홈 테스트 62개 무변경 통과.
- **2b**: `sori_stage_today_screen.dart` 재구성 — 라이트 배경 = `HomeHeroClips.matte`(#FBF5EB) **평면 단색**(`ValueKey('sori-today-bg')`), 톱바(+프로필 아이콘 신설)+히어로가 헤더(RootHeader 이 탭에서 제거), `verticalDirection: up` 페인트 안전장치, teal kill-switch → `SoriCharacterHero.forceStatic`, `now` 주입. 로딩/오류에도 헤더 즉시 표시(ListView). 계약 테스트 `test/sori_stage_today_matte_test.dart`.
- **2c**: `lib/config/sori_stage_feature.dart` 기본 **true**. `sori_stage_shell_test.dart` 갱신.
- 파생 수리: SoriStatsTopBar 배율 1.4 클램프(200% 오버플로) + 폭 적응(프로필 있는 셸에서 워드마크 텍스트 <376dp 숨김·레벨 칩 <296dp 숨김 — 상수 `_kProfileReserve/_kWordmarkTextMinWidth/_kLevelChipMinWidth`, 홈은 불변).

### 스와이프 판정 (2026-08-14, Jin 신규 요청 — 부분 완료)
- 신규 `widgets/sori/swipe_card.dart` — **SoriSwipeCard**(+SoriSwipeBadge): 좌/우 드래그, 임계 폭35%/700px/s, 틴더식 기울임+판정 스탬프, 탭(플립)과 공존, reduce-motion 즉시판정, 버튼 유지 원칙. 테스트 `test/swipe_card_test.dart` 4종.
  - ⚠️ 컨트롤러는 initState 생성 (late-lazy 는 미사용 dispose 크래시 — 이미 수리됨, 주석 참조).
- 배선 완료 2곳: `review_session_screen.dart`(우=Gewusst `_answer(true)`/좌=Nicht gewusst) · `custom_pack_play_screen.dart`(우=`_gotIt`/좌=`_skip`).

## 3. 계약·Gotcha (어기면 회귀)

1. **매트 배경 계약**: 홈/Today 라이트 배경 = `HomeHeroClips.matte` 평면 단색. 그라데이션·`HanjiTexture` 그레인·틴트 금지 — Android 영상 텍스처가 액자화. 근거 주석: `home_hero.dart` 클래스 doc + `character_clip.dart` HomeHeroClips.
2. **`verticalDirection: VerticalDirection.up`** (홈 build·Today `_header`): 영상 텍스처가 먼저 그린 형제를 지우는 Android 컴포지터 문제의 구조적 차단. 제거 금지.
3. **hex 단언 테스트**: `home_hero_matte_test.dart`·`quest_cta_pinned_test.dart`·`sori_stage_today_matte_test.dart` — 색 바꾸면 여기서 잡힘(의도).
4. **골든**: 렌더 골든은 **Linux 전용**(맥에서 ~11 skip). `screen_vocab_packs_{medium,expanded}` 재생성 필요(Phase 1 의도 변화, Jin/CI 몫). 새 sori 화면 골든은 `loadSnapshot`/`now` 픽스처로.
5. **래칫**: `typography_guard_test.dart` 7종 — 실측이 낮아지면 숫자를 내려 고정, 절대 올리지 말 것.
6. **병행 세션 존재**: 다른 AI 세션이 학습 메커니즘(플립·퀴즈·TTS속도·`responsive.dart` `soriUniformFitSize`)을 미커밋으로 작업 중. **본인이 만진 파일만 스테이징.** 현재 전체 스위트 실패 1건 = `window_class_guard`가 그쪽 `responsive.dart` `maxWidth <= 0` 유효성 검사를 오탐 — 그쪽 정리 몫.
7. l10n: 새 문구는 반드시 `l10n/app_de.arb`+`app_en.arb` 쌍 + `flutter gen-l10n`. 하드코딩 금지. if/else 중괄호 필수. SESSION_LOG 기록 필수.
8. dev 서버: `.claude/launch.json` `flutter-web`(포트 8765). 웹에선 영상 lease 없어 히어로 밴드가 빈 것이 정상(실기기에서 클립 재생). 온보딩 우회: localStorage `flutter.kl_consent_accepted='true'`, `flutter.kl_onboarding_completed='true'`, `flutter.kl_user_level='"a1"'` 후 리로드.

## 4. 남은 작업 (우선순위순)

### 4-A. 스와이프 확산 (task #8 잔여)
- `legacy_vocab_screen.dart` — 플립 브라우즈 덱: 배지 없이 좌=다음/우=이전 (SoriSwipeCard 그대로, badge null). ⚠️ 병행 세션이 serving key(`legacy-$_serve`) 작업한 파일.
- `vocab_pack_screen.dart` Learn 단계 — 동일 패턴. ⚠️ 동일 주의.
- `hard_words_screen.dart` 는 ReviewSessionScreen 재사용이면 자동 커버 — 확인만.
- 스와이프 힌트 코치마크(첫 1회): `feature_coach.dart`/`SpotlightCoach` 패턴 재사용, `Storage` `kl_tut_*` 플래그.
- 실기기 제스처 충돌 확인: 카드 위 수평 드래그 vs (좌우 엣지) 시스템 back 제스처.

### 4-B. Phase 3 — 핵심 화면 리스타일 (task #6, 순서대로 각각 배포 가능)
1. **`sori_stage_catalog_screen.dart`** (300줄, Learn+Games 탭): `_ActivityListRow` 리스트 → `SoriIllustratedCard` 그리드(`soriGridColumns`, 갭 `Spacing.md`). 일러스트 규약 `assets/illustrations/activities/{activityId}.webp` + `soriActivityIcon` 폴백(`sori_stage_common.dart`). `SceneAssetResolver`(`lib/services/scene_asset_resolver.dart`) 패턴을 복제한 소형 `CardIllustrationResolver` 신설 권장. Learn 탭 상단에 단어팩 그리드 진입 대형 카드.
2. **`sori_stage_today_screen.dart` 폴리시**: `_TodayMissionStage`/`_PendingBojagi`/`_HanokProgress`/`_QuestProgressRow` 의 raw TextStyle → `SoriTextTheme`(+`SoriSectionHeader`), 래칫 하향.
3. **`stats_screen.dart`**(713줄): AppBar→SoriAppBar, `numeral` 토큰 정렬.
4. **`profile_screen.dart`**(1154줄): SoriAppBar + 카드 규율 (`.preview()` 픽스처 있음).
5. **온보딩 5화면** consent(193)→start(344)→level(1052)→character_selection(921)→preview(449): Vocabulary 설문 패턴 = `SoriPageHeader`(eyebrow+hero) + 상단 여백 + 옵션 카드 + **고정 하단 CTA**(`quest_cta_pinned_test` hex 불변). 캐릭터 화면의 클립·렌더는 불변(⛔규칙).
6. **`paywall_screen.dart`**(238줄): 신규 일러스트 히어로(`assets/illustrations/reward/paywall_hero.webp`) + 혜택 체크리스트 + `lightSurfaceRaised` 가격 카드. 잠긴 팩 카드에 `SoriIllustratedCardState.premium` 티저 → `/paywall`. `FREE_LAUNCH=1` iOS 모드 존중.
- 각 화면: 3 브레이크포인트 골든(픽스처) + 접근성 테스트 확장 + ARB DE/EN 쌍 + 래칫 하향 + SESSION_LOG.

### 4-C. Phase 4 (Phase 2 배포 1릴리스 후)
레거시 셸(`LegacyAppShell`·`home_screen.dart`·구 허브 탭)·wordle_screen 삭제, raw AppBar 스윕 → 래칫 0 수렴, 미사용 GowunBatang 번들 정리 검토, iOS 아이콘 배경 legacy teal(#2AB7A9) → 현행 팔레트 정합.

## 5. 에셋 생성 런북 (활동 카드 ~12장 + 페이월 1장이 남았다)

> **⛔ 정정(2026-08-30):** 이 절은 packs 14장을 낳은 원조 런북이지만 이제 stale하다.
> 후처리(cwebp -q 88, 60KB 이하)와 프롬프트 골격 모두 docs/LISTENING_CARD_RECIPE.md
> (그레인 후처리 · q84 · 85~105KB)로 대체됐다 — 정물 카드 계열 신규 생성은 RECIPE
> 만 따른다.

**플랫폼**: BBANANA MCP (`generate_image`/`get_status`), 모델 **"Seedream V4.5"**, 장당 1크레딧 (잔여 ~1,040). aspect_ratio "4:3".

**핵심 = 앵커 참조 워크플로** (세트 일관성의 비결):
1. 스타일 앵커(이 세션이 만든 bamboo 서재 정물)를 `image_urls` 로 참조:
   `https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/1786656413789.jpg`
   (URL 이 죽으면 `assets/illustrations/packs/bamboo.webp` 를 업로드해 새 참조로.)
2. 프롬프트 골격: "Create a NEW illustration in exactly the same illustrated-set style as the reference image (same geometric faceted background diamonds, same hanji cream palette, same paper grain, same dancheong dot clusters, same flat no-outline planes), but with this subject instead: [주제]. … ABSOLUTELY AVOID: outlines, cute style, animals, people, text, 3D render, photorealism. This must look like part of the same illustrated set as the reference."
3. 스타일 정본은 `docs/ASSET_GENERATION_BIBLE.md` §1.3(hex)·§1.5(템플릿)·§1.7(DO/DON'T). **캐릭터·사람 금지.**
4. **결과를 반드시 눈으로 검수** — 이 세션의 재생성 사례: 고무신이 크록스로 나옴(전통 사물은 형태를 문장으로 상세 기술), 실내 전경으로 배경 이탈(“크림 다이아 배경 유지, 풀 룸 금지” 명시).
5. 변환 파이프라인 (맥):
   `curl -s -o raw.src {URL} && sips -Z 800 -s format jpeg raw.src --out raw800.jpg && cwebp -q 88 raw800.jpg -o assets/illustrations/{dir}/{name}.webp` (장당 목표 ≤60KB).
6. 활동 카드 파일명은 `{activityId}.webp` — activityId 목록은 `sori_stage_catalog_screen.dart`/활동 카탈로그에서 추출. pubspec 에 `assets/illustrations/activities/` 등록 필요.

## 6. 검증 루틴

```bash
flutter analyze                                   # 항상 0
flutter test test/typography_guard_test.dart      # 래칫 7종
flutter test test/sori_stage_today_matte_test.dart test/home_hero_matte_test.dart test/quest_cta_pinned_test.dart
flutter test                                      # 전체 (기대: 실패 = 병행 세션 window_class_guard 1건뿐)
```
시각 검증: `flutter-web` 서버 → §3-8 localStorage 우회 → `#/`(Today)·`#/vocab`(팩 그리드). **매트/영상 판정은 실기기 Android만 신뢰.**

## 7. Jin 대기 항목 (AI가 할 수 없는 것)
1. 실기기 Android에서 Today 히어로 매트 확인 (액자 경계 여부).
2. Linux CI 골든 재생성: `screen_vocab_packs_{medium,expanded}` (+이후 신규 골든).
3. 커밋 지시 (권장 분할: Phase0 / Phase1+에셋 / Phase2 / 스와이프).
4. DE 로케일 실기기 문구 확인.
