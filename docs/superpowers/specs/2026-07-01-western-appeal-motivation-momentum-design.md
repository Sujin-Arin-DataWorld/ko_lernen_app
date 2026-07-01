# 서양 학습자 어필 — "동기 & 모멘텀" 설계

> 2026-07-01 · Jin "독일/미국/영국인에게 얼마나 매력적일지, 더 멋지고 공부하고 싶어지는 앱으로" → 자율 구현 승인(승인 게이트 생략, phase별 검증→커밋).

## Context (왜)

한글소리는 콘텐츠(CEFR 단어 546·문법 88·시나리오 33·스몰토크 145, 원어민급 DE/EN)·게임 8종·SRS·한옥 성장·계·고품질 TTS·Faceted Minhwa 아트(D1~D5 한지 에디토리얼 방금 완료)를 갖췄다. **그러나 서양 학습자가 한국어를 배우는 감정적 이유(K-Pop·K-Drama·여행·문화·연인/가족·커리어)를 앱이 한 번도 묻거나 활용하지 않는다.** Duolingo의 검증된 리텐션 플레이북 1번 = "왜 배우는가"를 첫날 묻고, 그 이유에 맞춰 격려를 개인화하는 것. CLAUDE.md 백로그 "동기 기반 온보딩"과도 일치.

**핵심 통찰:** 서양 K-학습자의 진입은 **K-컬처에 대한 감정적 끌림**이다. 이걸 명명(capture)하고 학습 순간마다 그 이유로 되돌려주면(personalize) "공부하고 싶어짐"이 커진다. 저위험·고레버·테스트 가능.

## 제약 (§0 · 야간 자율)

- **시각 검증 불가**(Jin 취침) → 검증된 기존 컴포넌트만 재사용(SoriCard·SoriChip·SoriButton·showSoriSheet·Mascot·SoriCelebration·SoriScreenBackground). 신규 수제 UI·리스크 큰 시각 변경 금지.
- **동시세션 파일 금지**: `hangul_screen.dart`·`scenarios_list_screen.dart` 절대 무접촉. 온보딩 페이지 플로우(delicate)도 피하고 **첫 홈 진입 시트**로 동기 캡처(showSoriSheet 재사용).
- DE/EN UI 카피는 내가 작성(원어민 품질 노력, KO 학습 콘텐츠 아님). 신규 KO 콘텐츠 생성 없음.
- 매 phase: 구현 → 적대적 더블크로스체크(verify agent) → analyze/test → 커밋. 전부 끝나면 push.

## Phase 1 — Learner Motivation (캡처 + 저장)

- `lib/data/learner_motivation.dart`: `enum LearnerMotivation { kpop, kdrama, travel, culture, loved, career, curious }` + `LearnerMotivationMeta`(id·IconData·labelKey·tigerLineKey). `fromId`/`all` 헬퍼.
- `StorageService`: `String get motivation`(빈="") · `setMotivation` · `bool get motivationAsked` · `setMotivationAsked`.
- `lib/widgets/sori/motivation_sheet.dart`: `showMotivationSheet(context)` = showSoriSheet — 마스코트 + "Warum lernst du Koreanisch?" + 7 선택(SoriCard/칩 그리드) → 탭 시 setMotivation + setMotivationAsked + pop.
- 홈: `initState` 뒤 첫 프레임에 `!Storage.motivationAsked && Storage.introSeen류(온보딩 이후)` 이면 시트 1회. (튜토리얼 투어와 겹치지 않게 순서 가드.)
- l10n: `motivationSheetTitle`·`motivationSheetSubtitle` + 7 label + 7 tigerLine (DE/EN).
- **테스트**: enum 무결성(전 항목 label/tigerLine/icon 존재·id 유일), Storage 라운드트립, `LearnerMotivation.fromId` 매핑, responsive 스모크(홈 무회귀).

## Phase 2 — Personalization (학습 순간마다 그 이유로)

- 홈 tiger bubble/subline: 동기 설정 시 확률적으로 동기-맞춤 격려 라인(예: kpop→"Bald verstehst du deine Lieblingssongs!"). 기존 `_tigerBubble` 로직에 분기(순수 함수화 → 테스트).
- Profile: "Dein Grund: {label}" 1줄 + 변경 진입(시트 재오픈).
- Settings: 동기 변경 항목(기존 섹션 재사용, SoriSectionHeader 아래).
- l10n: profile/settings 라벨 소수.
- **테스트**: 동기별 tiger 라인 선택 순수 함수(각 enum→비어있지 않은 키), profile/settings 스모크.

## Phase 3 — Daily Momentum (가시적 커밋 장치) *(Phase 1·2 무리 없으면)*

- Storage: `xpToday`(날짜 리셋) — `addXp`가 함께 증가, 날짜 바뀌면 0. `dailyGoalMinutes`(이미 존재)를 XP 목표로 재해석하거나 별도 `dailyGoalXp`(기본 30) 추가.
- 홈: "Heute: {xpToday}/{goal} XP" 진행 칩/링(기존 progress 위젯 재사용). 목표 달성 시 마스코트 미소.
- **테스트**: `xpToday` 날짜-리셋 순수 로직(어제→오늘 0), 목표 달성 판정.

## 재사용 (신규 위젯 최소화)

- `showSoriSheet`(sheet.dart) · `SoriCard`/`SoriChip`/`SoriButton` · `Mascot.tiger` · `SoriSurfaces`/`SoriTextTheme`/`SoriColors` · `SoriCelebration`(Phase 3 달성) · `AppL10n`.

## Verification (각 phase)

- 적대적 verify(agent): 컴파일·괄호·레이아웃 중립·l10n parity·hangul/scenarios_list 무접촉·동기 카피 자연스러움.
- `flutter analyze lib test` 0(잔여 hangul warning 제외) · `flutter test`(신규 유닛 + responsive 무회귀) · gen-l10n parity · dart format.
- 전 phase 완료 시 `git push origin main` + 완료 보고서.

## YAGNI (의도적 제외)

- STT(말하기) = 큰 별도 베팅(나중). 동기 기반 콘텐츠 자동 큐레이션·신규 KO 콘텐츠·온보딩 페이지 재구성·리더보드(안티패턴) 제외.
