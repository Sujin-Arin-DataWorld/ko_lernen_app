# CLAUDE.md — ko_lernen_app (Hangul Sori)

> 세션 시작 시 이 파일 먼저 읽기. 그 다음 필요한 파일만 grep/Read.
> 전역 운영 원칙은 `~/.claude/CLAUDE.md` 참조.
> **작업 완료 시마다** "현재 진행 중인 작업" 체크리스트를 업데이트할 것 (완료 항목 체크, 새 항목 추가).
> **비주얼 에셋 작업 전** `docs/ASSET_GENERATION_BIBLE.md` **하나만** 읽으면 됨 — 스타일 가이드·디자인 토큰·한옥/장식/도장/스티커/마스코트 프롬프트를 모두 흡수한 자급자족 AI 생성 바이블 (스타일명 **"Faceted Minhwa (모던 면 분할 민화)"**). 일러스트/아이콘/마케팅 자산 신규 제작·이터레이션 시 이 파일을 프롬프트 소스로 사용. (구 `HANGUL_SORI_STYLE_GUIDE.md`·`HANGUL_SORI_DESIGN_TOKENS.md`·`stately-rising-jongga-assets.md`는 상세 레퍼런스로만.)
> **마스코트(2026-06-02 v2)**: 업로드된 앉은 호랑이=`tiger_idle.png`, 갓 까치 비행 2프레임=`magpie_wingup/wingdown.png`가 캐릭터 source of truth. `tiger_sleepy`·`tiger_thinking`은 화풍 이질 → 교체 1순위. 상세는 BIBLE §2.

---

## 앱 개요

**Hangul Sori (한글소리)** — 독일어권 사용자를 위한 한국어 학습 Flutter 앱.  
대상: 독일어 모국어 사용자 (UI 언어 독일어/영어, 학습 내용 한국어).  
플랫폼: Android (주), iOS, Web (Chrome 개발 테스트).  
Firebase 프로젝트: `ko-lernen-app`

---

## 기술 스택

- **Flutter** 3.x / Dart 3.x (null-safety)
- **Firebase**: Auth (익명 + Google 링크), Firestore (cloud sync), Remote Config (palette kill-switch)
- **로컬 저장**: `shared_preferences` (`StorageService`)
- **TTS**: `flutter_tts`
- **로컬라이제이션**: ARB (`l10n/`) — DE/EN 지원, `AppL10n.of(ctx)` 사용

---

## 파일 맵 (SSoT)

### 진입점
- `lib/main.dart` — 라우트 테이블, Firebase/Ad 초기화, 팔레트 서비스. **`initialRoute: '/intro'`** — 솟을대문 인트로 후 온보딩/홈으로 분기
- `lib/screens/intro_gate_screen.dart` — 솟을대문 시네마틱 인트로 (Phase 1)
- `lib/motion/transitions.dart` — 공유 화면 전환 (`SoriTransitions.fadeScale`)

### 라우트
| 경로 | 화면 |
|---|---|
| `/intro` | IntroGateScreen (솟을대문 시네마틱 인트로 — **앱 진입점**) |
| `/` | HomeScreen |
| `/onboarding` | OnboardingLevelScreen (첫 실행 레벨 선택) |
| `/vocab` | **VocabPacksScreen** (단어팩 그리드 — v2.0) |
| `/vocab/pack` (args: packId) | VocabPackScreen (Learn→Quiz→Boss 단계) |
| `/vocab/result` (args) | VocabPackResultScreen |
| `/vocab/legacy` | LegacyVocabScreen (구 플래시카드) |
| `/grammar` | GrammarScreen |
| `/hangul` | HangulScreen |
| `/chosung` | ChosungQuizScreen (초성 퀴즈 A1-B2) |
| `/wordle` | WordleScreen (한글 워들) |
| `/settings` | SettingsScreen |
| `/stats` | StatsScreen |
| `/scenarios` | ScenariosListScreen |
| `/scenario` (args: scenarioId) | ScenarioPlayerScreen |
| `/listening` | ListeningScreen (v1 — 시나리오 TTS 재생 + 자막 토글) |
| `/kkeunmari` | KkeunmariScreen (끝말잇기 호랑이↔사용자 턴제, 30s 타이머) |
| `/quests` | QuestsScreen (특별 퀘스트 — 마당 장식 언락) |
| `/book` | BookCaptureScreen (★ 책 한 컷: 사진→OCR) |
| `/book/preview` (args) | BookPreviewScreen (OCR 텍스트 수정) |
| `/book/result` (args) | BookResultScreen (단어·문법·문장 분석 결과) |
| `/bookshelf` | BookshelfScreen (내 책장 + 커스텀팩) |
| `/bookshelf/page` (args: pageId) | BookshelfPageScreen |
| `/custom_pack/play` (args: packId) | CustomPackPlayScreen (플립카드 학습) |

### 서비스
- `lib/services/auth_service.dart` — Hybrid Auth. 항상 익명 로그인, Google 링크 선택. **주의**: web에서 Firebase 미설정 시 crash 방지를 위해 `_auth`가 nullable getter임.
- `lib/services/palette_service.dart` — Remote Config `palette_variant` 키로 단청/teal 토글. `paletteVariantNotifier` (ValueNotifier) → main.dart ListenableBuilder에서 ThemeData 재빌드.
- `lib/services/storage_service.dart` — SharedPreferences 래퍼 (레벨, streak, XP 등)
- `lib/services/data_loader.dart` — CSV/JSON 에셋 로드
- `lib/services/theme_service.dart` — 다크모드 toggle
- `lib/services/locale_service.dart` — 언어 선택 (DE/EN)
- `lib/services/kkeunmari_engine.dart` — 끝말잇기 풀 로더 + chain 검증 + 호랑이 다음 단어 선택 (`is_dead_end` 회피 우선)
- `lib/services/tts_service.dart` — flutter_tts 래퍼, ko-KR 기본, `speakSlow`/`setRate` 지원
- **책 한 컷 (Phase 5)**:
  - `lib/services/snap_ocr_service.dart` — ML Kit **on-device 한국어 OCR** (`OcrResult`). 이미지 기기 밖 전송 X.
  - `lib/services/book_analysis_service.dart` — Cloud Function 클라이언트 + 오프라인 stub. `setEndpoint(url)` / `analyze(text, targetLang)`. endpoint 빈 값/장애 시 문법패턴만 폴백.
  - `lib/services/bookshelf_service.dart` — BookPage 로컬(`kl_bookshelf_v1`) + best-effort Firestore `users/{uid}/bookshelf/{id}`.
  - `lib/services/custom_pack_service.dart` — 커스텀팩 **로컬 only**(`kl_custom_packs_v1`). createFromPage/getAll/save/delete.
- **단어팩 (Phase 1·2)**: `lib/services/vocab_pack_service.dart` (CSV `pack_id`로 61팩 로드) + `pack_progress_service.dart` (진행도 로컬+Firestore `users/{uid}/packs`).
- **한옥/퀘스트 (Phase 3·4)**: `lib/services/hanok_stage_service.dart` (진행도→한옥 12단계), `quest_tracker.dart` (특별 퀘스트), `daily_char_service.dart` (오늘의 글자).
- **동기화**: `lib/services/cloud_sync.dart` + `firestore_progress_service.dart`, `scenario_loader.dart` (시나리오 JSON).

### Sori 디자인 시스템 (`lib/widgets/sori/`)
- `tokens.dart` — **단일 색상 소스** (v6.0 단청 팔레트). `SoriColors`, `Spacing`, `SoriRadius`, `SoriElevation`, `SoriSurfaces`
- `hanok_tokens.dart` — 한옥 전용 색상 (단청 4색)
- `card.dart`, `button.dart`, `chip.dart`, `progress.dart`, `badge.dart`, `pressable.dart` — UI 컴포넌트
- `mascot.dart` — `Mascot.tiger` / `Mascot.magpie` (v6). **자산은 `assets/illustrations/mascot/`에 분리된 포즈 PNG**: 호랑이 5(idle/blink/happy/celebrate/sad) + 까치 4(perched/wingup/wingdown/celebrate). emotion → 포즈 매핑 (celebrate/worry/sleepy/surprised/thinking/neutral/smile). `tiger_thinking`/`tiger_sleepy`/`tiger_neutral`/`magpie_worry`는 Jin이 추후 추가하면 자동 사용, 미존재 시 errorBuilder fallback.
- `mascot_pop.dart` — 퀘스트 피드백용 팝업 마스코트
- `hanok/` — 한옥 장식 위젯 (단청 divider, 기와 패턴, 처마, 창살, 마당 배경)
- `motion.dart` — `SoriEntrance` (진입 fade+slide+scale), `SoriKenBurns` (배경 느린 줌). **`SoriMotion.reduceMotion(context)` 헬퍼** — `MediaQuery.disableAnimations` 시 정적 fallback.
- `ambient_particles.dart` — 매화 꽃잎(light) / 불씨(dark) 입자. reduce-motion 시 SizedBox.
- `flying_magpie.dart` — 홈 상단을 가로지르는 비행 까치. reduce-motion 시 SizedBox.
- `empty_state.dart` — **표준 빈/오류 상태**. `SoriEmptyState(asset, title, body, ctaLabel, onCta, secondaryLabel)`. 일러스트 errorBuilder가 아이콘 fallback.
- `hanok_header.dart` — 10:3 wide 한옥 헤더 배너. 자산 미존재 시 단청 그라데이션 + 아이콘 fallback.
- `madang_background.dart` — 한옥 12단계 배경. 3단계 fallback: `hanok_stages/stage_{slug}_{light|dark}.png` → `hanok/madang(…).png` → 그라데이션. **dark stage PNG 0/12 → 다크모드는 그라데이션.**
- `hanok_cinematic.dart` — 단계 전환 시 1회 시네마틱 (Storage gating).
- `decoration_layer.dart` — 퀘스트 보상 장식 합성. 미존재 PNG는 초록 원형 placeholder.
- `dancheong_stamp.dart` — 단청 도장 (CustomPainter, PNG 미참조).
- `pack_card.dart` / `celebration.dart` — 단어팩 카드 / 축하 burst.
- ✅ 모션 시스템 일원화 완료 — `flutter_animate` 패키지 제거. `motion.dart` + `lib/motion/transitions.dart` 둘만 공존 (역할 분리: entrance vs route transition).

### 데이터
- `assets/data/korean_vocab.csv` — 단어장 (level 필드: A1/A2/B1/B2)
- `assets/data/grammar.csv` — 문법
- `assets/data/scenarios.json` — 회화 시나리오
- `assets/data/kkeunmari_pool.json` — 끝말잇기 단어 풀
- `assets/data/grammar_patterns.json` — 문법 패턴 정규식 (책 한 컷 오프라인 stub용). **Cloud Function 쪽 `functions/analyze_korean_text/grammar_patterns.json`과 schema 동기 필요.**
- 단어팩(61)은 별도 파일이 아니라 `korean_vocab.csv`의 `pack_id`/`pack_order`/`is_review_boss` 컬럼에서 파생.
- ⚠️ **콘텐츠 언어**: `korean_vocab.csv`(`german`)·`grammar.csv`(`explanation_de`/`example_german`)는 **독일어 전용**. 영어 UI 사용자도 학습 콘텐츠는 독일어로 표시됨 (영어권 출시 시 컬럼 추가 필요).

### 에셋 (2026-05-26 복원 후 최종)
- `assets/icons/HanLogo.png` — **현재 앱 아이콘 소스** (Gemini 생성, 1024×1024, 갓+한)
- `assets/icons/icon-192.png` — pubspec 등록된 192 buffer
- `assets/illustrations/hanok/` — 한옥 공간 자산 (모두 사용 중):
  - `madang(light).png` / `madang(dark).png` — 홈 배경 (낮/밤)
  - `gate_door_left.png` / `gate_door_right.png` / `gate_frame.png` — IntroGateScreen GateArt 합성
  - `gate.png` — 한옥 솟을대문 단일 일러스트 (홈페이지 final-cta 배경, 앱은 미래 사용)
  - `welcome-hero.png` — 호랑이+어깨 까치+단청 점 통합 일러스트 (앱 미래 사용, 홈페이지 mascot-strip는 docs/assets/ 사본 사용)
  - `porch.png` — Chosung/Wordle 80px banner
  - `study.png` — Vocab/Grammar 80px banner (신규 `study_classroom.png`/`study_scholar.png`가 들어오면 자동 교체)
  - `calligraphy.png` — Hangul 화면 헤더
- `assets/illustrations/mascot/` — 분리 포즈 PNG (Mascot 위젯 소스, 11종):
  - 호랑이 7: `idle`, `blink`, `happy`, `celebrate`, `sad`, `neutral` (← tigerbasic1 복원), `smile` (← tiger_smile 복원)
  - 까치 5: `perched`, `wingup`, `wingdown`, `celebrate`, `perched_alt` (← v2 복원, fallback 다양성용)
- `assets/illustrations/scenes/` — 시나리오 backdrop 5종 (Jin 작업)
- `assets/illustrations/empty/` — 빈 상태 일러스트 3종 (Jin 작업)
- `assets/illustrations/error/` — 오류 상태 일러스트 2종 (Jin 작업)
- `docs/store/feature_graphic_v1_draft.png` — Play Store feature graphic 임시본
- `docs/assets/` — 홈페이지(hangul-sori.com) 자산: `logo.png`, `tiger.png`, `magpie.png`, `tiger_celebrate.png`, `favicon.png`, `welcome-hero.png` (mascot-strip), `gate.png` (final-cta 배경)
- ⚠️ **2026-05-25 → 26 변경 흐름**: 중복 마스코트 7장 + icon-512는 영구 삭제. 미참조 5장은 시각 검수 후 모두 복원 — tigerbasic1/tiger_smile/welcome-hero/gate는 적재적소 매핑(neutral/smile emotion + 홈페이지 hero/CTA), magpie_perched.v2는 fallback 다양성용 보존.

---

## 브랜드 팔레트 (v6.0 단청)

| 역할 | 이름 | 값 |
|---|---|---|
| Primary | 녹청 | `#1F7A6B` |
| Accent | 석간주 적 | `#A0524A` |
| Tiger | 호랑이 주황 | `#FF8C42` |
| Gold | 황 | `#C99A2E` |
| Light BG | 한지 cream | `#FAF6EC` |
| Dark BG | 먹 ink | `#0E1A18` |

**Kill-switch**: Firebase Remote Config `palette_variant` = `"teal"` → `#2AB7A9` 레거시로 롤백.

---

## 주요 패턴 & Gotchas

### Dart 문법
- `if/else` 반드시 중괄호 사용. 한 줄 생략 금지 (실제 오류 발생 이력 있음).
- 세미콜론 누락 주의.

### Web에서 Firebase
- `FirebaseAuth.instance`는 web에서 Firebase 미초기화 시 crash → `auth_service.dart`의 `_auth` getter가 try-catch로 nullable 반환하도록 수정되어 있음. 이 패턴 유지.

### 로컬라이제이션
- UI 텍스트는 `AppL10n.of(ctx).XXX` 사용. 하드코딩 금지.
- 독일어 = 주 언어. 새 문자열은 `l10n/app_de.arb` + `l10n/app_en.arb` 양쪽에 추가.

### 마스코트 (v6, 2026-05-25)
- `Mascot.tiger` / `Mascot.magpie` — 분리 포즈 PNG (`assets/illustrations/mascot/`).
- `emotion` 파라미터: celebrate/worry/sleepy/surprised/thinking/neutral/smile.
- 호랑이 매핑: celebrate=tiger_celebrate, worry=tiger_sad, sleepy=tiger_sleepy*, thinking=tiger_thinking*, surprised=tiger_happy, smile/neutral=tiger_idle (animate=true 시 blink 프레임).
- 까치 매핑: celebrate=magpie_celebrate, worry=magpie_worry*, animate 시 wingup/wingdown 교대, idle=magpie_perched.
- `*` 표시는 Jin이 PNG 추가 시 자동 사용. 미존재 시 _Fallback (색상 원+이모지).
- `animate: true` → hero 컨텍스트(결과/홈)용 부드러운 호흡 스케일 애니메이션.

### 아이콘 재생성
```bash
flutter pub run flutter_launcher_icons     # Android/iOS
npx sharp-cli --input assets/icons/HanLogo.png --output web/icons/Icon-192.png resize 192
npx sharp-cli --input assets/icons/HanLogo.png --output web/icons/Icon-512.png resize 512
```

### 개발 실행
```bash
flutter run -d chrome          # 웹 (개발)
flutter run -d <android-id>   # 안드로이드
```

---

## 현재 진행 중인 작업 (2026-06-02 기준)

> **최신 현황 → `docs/release-readiness-2026-06-02.md`.** 앱은 **v2.0 (stately-rising-jongga)**, 버전 `2.0.0+3`, 안드로이드 내부 테스트 직전.
> - ✅ 사진→단어장("책 한 컷") 클라이언트 완성 · Cloud Function(`functions/analyze_korean_text` — kiwipiepy+DeepL+우리말샘) **배포 대기**
> - ✅ 단어팩 61(Learn→Quiz→Boss) · 특별 퀘스트→마당 장식 · 한옥 12단계 성장 · 홈 v4(호랑이 hero)
> - 🔨 2026-06-02 세션: 공유 기능(친구코드+OS공유) · Cloud Function 클라 보정 · 홈 skill-path 레일
> - ⏳ Jin 운영: 함수 배포(gcloud gen2) · AAB 빌드 · Play Console 업로드 · 실기기 검증
> - 🟡 후속: hanok_stages dark 12장 · 영어 학습 콘텐츠 · 수익화

### (이하 2026-05 히스토리 — 대부분 완료/대체됨)

### ★ "살아있는 한옥" UI/UX 대개편 (승인된 계획)
> 정적 "상자 더미" → 모션·깊이·캐릭터가 살아 움직이는 한옥. 컨셉(단청+한옥+호랑이/까치)은 유지.
> 전체 plan: `~/.claude/plans/claude-code-ko-leren-app-glimmering-storm.md`

- [x] **Phase 0** — 토대 안정화 (`flutter analyze` 0) + `flutter_animate` 모션 패키지
- [~] **Phase 1** — 솟을대문 시네마틱 인트로 (코드 완료 · 시각 검증 미완)
- [ ] **Phase 2** — 살아있는 한옥 환경 (홈=마당, ambient 모션) — *동시 세션 진행 중*
- [ ] **Phase 3** — 호랑이·까치 마스코트 생명력 (포즈 기반 2D 애니메이션)
- [ ] **Phase 4** — de-box + 모든 상호작용 생명력 (스프링·축하·물리 전환)
- [ ] **Phase 5** — 60fps 보증 + GitHub Actions CI

### 출시 폴리시 (2026-05-22 Week 1–4 완료)
> plan: `~/.claude/plans/hangul-sori-temporal-wombat.md`

**Week 1 — 접근성 + 모션 일원화 + 토큰**
- [x] 모든 Sori 위젯에 `Semantics` 적용 (button, chip, card, pressable, badge, mascot)
- [x] `SoriColors.primaryOnLight = primaryDark` 토큰 (≥7:1 대비, AA 통과)
- [x] `intro_gate_screen.dart`의 하드코딩 `_black`/`_white` → `SoriColors.darkBg`/`lightBg`
- [x] `flutter_animate` 패키지 완전 제거 + `app_error.dart`의 `.animate()` 호출을 `SoriEntrance` + 인라인 `_BreathingTransform`으로 재작성
- [x] `SoriMotion.reduceMotion(context)` 헬퍼 추가 — 4개 모션 위젯 reduce-motion 대응
- [x] `SoriTextTheme` 신규 (display/h1/h2/h3/body/bodySmall/caption/label, Pretendard 통일)
- [x] `HanokColors.cheongMuted/jeokMuted/hwangMuted` muted 변형 추가
- [x] `Mascot` 위젯 Semantics (`label: '호랑이 마스코트, 상태: $emotion'`)

**Week 2 — 빈/오류 상태 + 헤더 슬롯**
- [x] `SoriEmptyState` 위젯 신규 (asset + title + body + CTA + secondary)
- [x] `HanokHeader` 위젯 신규 (10:3 wide, gradient fallback)
- [x] 5개 빈/오류 상태 통일: 시나리오 B2 잠금 (`sleeping_tiger_b2.png`) · 단어장 due 완료 (`celebrate_complete.png`) · 통계 첫 진입 (`study_room_waiting.png`) · 설정 오프라인 (`offline_lantern.png`) · 시나리오 로드 실패 (`lost_magpie.png`)
- [x] Settings 헤더 (`scholar_room.png`) + Stats 헤더 (`achievements.png`) 통합
- [x] DE/EN ARB에 10개 빈/오류 키 추가

**Week 3 — 모듈 폴리시**
- [x] **Chosung 라운드 요약** — 10문제 단위 round 추적, 라운드 종료 시 정확도% + 평균 시간 + 레벨 추천 카드 (`_RoundSummaryCard` private 위젯)
- [x] **Wordle 키보드 폴리시** — 결과 카드에 `Focus(autofocus: true, onKeyEvent: ...)` → Enter/Space로 새 단어. 입력 자동 재포커스 (브라우저 IME가 한글 합성 처리)
- [x] **시나리오 백드롭** — `_backdropKey` getter (scenario ID → scene 키 매핑) + `assets/illustrations/scenes/{key}.png` opacity 0.08 백그라운드 + errorBuilder fallback (Jin이 PNG 만들기 전에도 정상 동작)
- [ ] **Hangul IoU 정확도 측정** — 캔버스 stroke vs ghost letter mask 비교, 80%+ 시 celebrate 팝업. 캔버스 구조 복잡도 때문에 출시 후 1차 업데이트로 이월

**Week 4 — 출시 자료 (모두 `docs/store/`)**
- [x] `docs/store/README.md` — Pre-submission 체크리스트 (Play Console + App Store Connect)
- [x] `docs/store/listing-de.md` — DE 짧은 설명(78자) + Promo(168자) + 전체 설명(~2950자) + Release Notes
- [x] `docs/store/listing-en.md` — EN 동일 + Apple Keywords(94자, 100자 한도 내)
- [x] `docs/store/data-safety.md` — Play Data Safety + Apple App Privacy 답변 (Firebase Anonymous + 옵션 Google Sign-In, 광고 없음 가정)
- [x] `docs/store/screenshot-shotlist.md` — 8슬롯 캡쳐 가이드 (어떤 state로 어떻게)
- [x] `docs/store/release-notes-v1.md` — v1.0.0 DE/EN

**Privacy URL**: `https://hangul-sori.com/privacy.html` (기존 `docs/privacy.html` + `docs/CNAME` 활용)

### v1.0.0 출시 준비 (2026-05-25 — 2주 plan)
> 전체 plan: `~/.claude/plans/snappy-conjuring-lemur.md` — 5 트랙 (자산정리·신규PNG·코드·콘텐츠·검증) + 부록 A에 PNG 18장 상세 스펙

**Track A — 자산 정리 (✅ 완료, 2026-05-25)**
- [x] hanok/ 중복 마스코트 7장 + 미참조 5장 + icon-512 삭제 (~17MB 절감)
- [x] `assets/illustrations/scenes/`, `empty/`, `error/` 폴더 생성 + pubspec 등록
- [x] feature-graphic.png → `docs/store/feature_graphic_v1_draft.png` 이동

**Track C — 코드 구현 (✅ 완료, 2026-05-25)**
- [x] `Mascot` 위젯 emotion enum에 `thinking` 추가, magpie worry/sleepy 매핑
- [x] `/listening` 화면 신규 — `ListeningScreen` (TTS dialog 재생 + 자막 토글 4모드 + 속도 3단계 + 진행/완료 카드)
- [x] `/kkeunmari` 화면 신규 — `KkeunmariScreen` + `KkeunmariEngine` 서비스 (chain 검증, 30s 타이머, dead_end 처리, XP 보상)
- [x] 홈 화면 카드 4종(Chosung/Wordle/Kkeunmari/Listening) 2×2 grid
- [x] Vocab/Grammar banner path → 신규 `study_classroom.png`/`study_scholar.png` (없으면 study.png fallback)
- [x] Wordle 게임판 단청 frame Container + 4코너 단청 dot + 결과 카드 mascot (까치 celebrate / 호랑이 worry)
- [x] Chosung 라운드 종료 → 정확도별 mascot (≥80% celebrate + 별 burst / 50-79% surprised / <50% worry)
- [x] DE/EN ARB에 listening 18키 + kkeunmari 19키 추가, gen-l10n 성공
- [x] `flutter analyze` 0 issues · `flutter build apk --debug` 통과

**Track B — 신규 PNG 자산 (Jin, 진행 중)**
- 전체 18장 스펙은 plan 부록 A 참조. 모두 errorBuilder fallback이 동작하므로 누락 상태에서도 빌드 정상.
- `docs/store/gate_decomposition_prompt.md` 작성 — gate.png 기반 3-layer animation prompt 생성
- 핵심 우선순위: ① 시나리오 백드롭 5장 (`scenes/`), ② 빈/오류 5장 (`empty/`+`error/`), ③ 헤더 6장 (`hanok/scholar_room`, `achievements`, `study_classroom`, `study_scholar`, `listening_hero`, `kkeunmari_hero`), ④ 마스코트 4장 (`mascot/tiger_thinking/neutral/sleepy`, `magpie_worry`), ⑤ feature graphic 1024×500.

**Track D — 콘텐츠 작성 (✅ 핵심 완료, 2026-05-27)**
- [x] B2 시나리오 3개 (`business_meeting_intro`, `complaint_delivery`, `doctor_consultation`) — 원어민 DE/EN 전면 교열 후 확정
- [x] 일상 시나리오 5개 신규 추가: `taxi_street` [A2] · `plans_with_friend` [A2] · `running_late` [A2] · `postpone_plans` [B1] · `cancel_plans` [B1]
- [x] `assets/data/scenarios.json` 13 → 21개 (A1×6, A2×7, B1×5, B2×3)
- [x] `docs/store/b2_scenarios_draft.json` 최종본 커밋
- 끝말잇기 풀은 v1 그대로 충분 (225 단어)
- 듣기는 시나리오 dialog 재사용 — 별도 콘텐츠 불필요
- [ ] optional: `apartment_viewing`, `job_interview` B2 2개 (백로그)

**Track E — 검증 & 출시 자료 (남은 작업)**
- [ ] **Data Safety 답변 확정** — `docs/store/data-safety.md` 끝의 "Open questions": Crashlytics/Analytics/AdMob이 release build에 포함되는지 확인
- [ ] **실기기 시각 검증** — Android 1대 + iPhone 1대에서 전 화면 진입, light/dark 둘 다 (특히 신규 `/listening`·`/kkeunmari`, Wordle 단청 frame, Chosung mascot, Vocab/Grammar banner fallback)
- [ ] **신규 PNG 적용 후 스크린샷 8슬롯 캡쳐** (Track B 일부 PNG 들어오면 재캡쳐)
- [ ] **Release notes 업데이트** — "신규 듣기 모드 + 끝말잇기 + B2 시나리오"

**🟡 출시 후 1차 업데이트 (v1.0.1) 후보**
- Hangul IoU 정확도 측정 (출시 전 deferred)
- Listening 받아쓰기 미니퀘스트 (현재는 step별 재생만)
- Kkeunmari 레벨 필터 (현재 단일 모드)
- 마스코트 추가 포즈 (tiger_thinking/neutral/sleepy + magpie_worry) — Jin이 만들면 자동 사용
- [ ] **madang(dark) v2** (계획 D5)

**🟢 콘텐츠 백로그 (별개 트랙)**
- [ ] 시나리오 21개 → 추가 양산 (apartment_viewing, job_interview 등)
- [ ] 동기 기반 온보딩 + 5분 코스 (Track C)
- [ ] 끝말잇기 게임 화면 (Track D, 풀 JSON만 있고 화면 없음)
- [ ] 모듈 통합 "Sori Brain" (Track B)

---

## 세션 로그 (Audit · Review · Update · Push)

### 2026-06-02 (Cowork) — 이미지 교체 + 다크모드 폐지 + API키 반영 + 출시 문서

**범위:** 내부 테스터 모집 직전. Jin 요청으로 (1) 압축 이미지 교체, (2) 다크모드 폐지, (3) DeepL·우리말샘 키 반영, (4) 출시 문서 3종.

**Update(이 Cowork 세션):**
1. **이미지 48장 교체/추가** — `~/Downloads/종가이미지 압축`의 `_optimized` PNG를 앱 에셋 경로로 매핑·복사.
   - hanok_stages 10(light) — **`stage_beams_light.png` 신규**(.en 변형, 841×1870 규격 일치 / .de는 off-size라 스킵).
   - decorations 10 · stamps 6 · stickers 11(`assets/stickers/`, `hangul_hh` 신규) · hanok gate 5 · mascot 6(`tiger_idle2` 신규=코드 미연결).
2. **다크모드 폐지** — `main.dart` `themeMode: ThemeMode.light` 고정 + `darkTheme`를 light로 미러 + `themeModeNotifier`를 merge에서 제거. `settings_screen.dart` 테마 선택 UI 삭제. 양쪽 `theme_service.dart` import 제거(미사용 경고 0 확인). → **다크용 PNG 제작 불필요**.
3. **콘텐츠 버그 수정** — `scenarios.json` `cafe_starbucks_basic` 독일어 문법 설명 오류(햄버거=모음인데 Konsonant-Ende로 오기 + 무의미 반복) 수정 · `One iced americano, tall please.`→`One iced Americano, tall, please.` · `listing-en.md` "Anlaut Quiz"→"Initial-Consonant Quiz". (JSON 파싱 OK)
4. **버전** `1.0.1+2`→`2.0.0+3` (`pubspec.yaml`).
5. **API 키 반영(보안)** — `functions/analyze_korean_text/.env`에 `DEEPL_API_KEY`(:fx) + `URIMALSAEM_API_KEY` 저장(.gitignore `.env*` 처리 확인, git status 미노출). `.env.example` 커밋용 템플릿. `main.py`에 `.env` 로더 + **우리말샘(opendict) 뜻풀이 enrichment**(urllib stdlib, 키 없으면/실패 시 빈 문자열, 최대 20단어) 추가 → 응답에 `definitionKo`. 클라 연결: `ExtractedWord.definitionKo`(옵션 필드) + `book_analysis_service` 파싱 + `book_result_screen` 단어카드 "📖 뜻풀이" 표시. (`py_compile` OK. 우리말샘 실호출은 샌드박스 403으로 미검증 → 배포 후 확인)
6. **책 한 컷 프롬프트 완성** — `jongga-assets.md` §7: 기존엔 7.1만 완전 프롬프트, 7.2~7.5는 구도 설명만 → **7.2~7.5 완전 영문 프롬프트 작성**(템플릿+상황 layer, center-blank 지시 포함). 이제 5장 전부 복붙 가능.
7. **출시 문서 3종** — `docs/LAUNCH_READINESS_2026-06-02.md`(준비도 진단·계획), `docs/JIN_VERIFY_CHECKLIST.md`(Jin 직접 검증 항목), `docs/IMAGES_TO_CREATE.md`(제작할 이미지 light-only).
8. **웹사이트 v2.0 갱신** — `docs/index.html`: 히어로에 사진 기능 문구 + "베타 신청" CTA 메일 연결, 📷 책 한 컷 플래그십 카드 + 한옥 건축 + 퀘스트 카드(3개국어), 단어장 카드 "61팩" 메시지, 스크린샷 라벨·메타 갱신. (태그 균형 검증) — **라이브 반영은 docs/ 커밋·푸시 필요**.
9. **"나만의 단어장"(수동 커스텀 단어장) 신규** — 기존 CustomPack 인프라 확장:
   - 모델: `CustomPack.manual()`+`copyWith()`+`isManual`, `ExtractedWord.manual()`.
   - 서비스: `createEmpty/addWord/updateWord/deleteWord/rename` + `BookAnalysisService.autoFill()`(단어 1개 번역·뜻풀이 자동채우기, Cloud Function 필요).
   - 화면 신규: `custom_pack_edit_screen.dart`(단어 직접 추가·편집·삭제, 자동채우기, TTS), `custom_pack_quiz_screen.dart`(4지선다 퀴즈, ≥4단어).
   - 진입: 책장 화면 ＋버튼(생성)·편집 아이콘, 빈 상태 보조 CTA. 라우트 `/custom_pack/edit`·`/custom_pack/quiz`.
   - l10n: DE/EN +30키(`wb*`/`quiz*`/`createWordbook*`), 591키 parity OK. **`flutter gen-l10n` 재실행 필수**(생성 파일 stale).
10. **나만의 단어장 3종 확장 (홈카드·CSV·사진)** — 무오류·고품질, 새 네이티브 의존성 0:
   - **홈 카드**: 홈 모듈 그리드의 빈 셀(퀘스트 옆)에 "나만의 단어장" 카드 → `/bookshelf` (레이아웃 변경 없음). `homeWordbookCard*` l10n.
   - **CSV 가져오기**: 편집 화면 액션 → 붙여넣기 다이얼로그 → 기존 `csv` 패키지로 파싱(한국어,뜻,예문) → `CustomPackService.addWords()` 일괄. 파일선택기(file_picker) 미사용=권한0. `csvImport*` l10n.
   - **사진 첨부**: `ExtractedWord.imagePath` 필드 추가 + 신규 `WordImageService`(image_picker 촬영/갤러리 → **path_provider로 앱 문서 폴더 영구 복사**) + 편집 시트 사진 버튼/썸네일 + 단어 타일 썸네일 + 플립카드 앞면 이미지. 모두 `Image.file(errorBuilder)`로 누락 안전. `wbPhoto*` l10n.
   - **pubspec**: `path_provider: ^2.1.5` 직접 의존성 추가(이미 lockfile transitive라 resolve 안전). 카메라/사진 권한은 책 한 컷이 이미 선언(Android CAMERA/READ_MEDIA_IMAGES, iOS NSCamera/PhotoLibrary).
   - l10n 양쪽 602키 parity OK. CSV 일괄·파일import는 백로그.

**⚠️ 빌드:** 신규 l10n 키 + path_provider 때문에 **반드시 `flutter pub get` → `flutter gen-l10n` → `flutter analyze` → `flutter test`** 1회. 정적 검증(브레이스 균형·키 parity·JSON·기존 위젯 API 대조)만 했고 컴파일은 Jin 로컬에서.

**검증:** Jin 로컬 빌드 통과 확인("전부 문제없이 빌드됐어"). 이후 추가된 `definitionKo` 관련 Dart 3파일은 `flutter analyze` 1회 재확인 권장. 함수 배포·AAB·실기기·Play Console·우리말샘 실호출 = Jin.

**⚠️ API 키:** DeepL·우리말샘 키가 대화에 노출됨 → 셋업 후 **DeepL 키 재발급** 권장.

**Git push:** 미수행 (Jin 확인 후).

### 2026-06-02 — 출시 준비도 전수 진단 + 6종 작업 (plan: deepl-api…eager-puppy)

**범위:** 내부 테스터 모집 직전 전수 진단 → 진단문서 작성 + CLAUDE.md 갱신 + 공유 기능·Cloud Function 보정·홈 skill-path.

**핵심 진단(정정):**
- Cloud Function `functions/analyze_korean_text/main.py` = **kiwipiepy(순수 Python, Java 없음) + DeepL + 우리말샘(NIKL)** 이미 구현 → 배포만 남음(Jin, gcloud gen2 권장 europe-west3). 1차 audit의 "konlpy/Java"는 환각.
- 버전 `2.0.0+3`, privacy.html account-deletion 링크, 홈 v4 재설계 — 모두 이미 반영(동시 세션).
- 로컬라이제이션: 독일어 완벽 / 영어 UI 완벽이나 **학습 콘텐츠는 독일어 전용**(`korean_vocab.csv` `german` · `grammar.csv` `_de` 컬럼). 독일어권 타깃엔 OK.
- 에셋: 코드 cross-ref → missing 전부 fallback, 테스터에 깨진 이미지 0. hanok_stages **dark 0/12**가 다크모드 시각손실 최대.
- 공유 기능: 코드 0건 → 신규 개발.

**Update(이 세션):**
- A. `docs/release-readiness-2026-06-02.md` 신규 (영역별 상태·에셋 실측·P0~P3·Play Console 폼값).
- B. CLAUDE.md 파일맵·라우트·현재작업·세션로그 v2.0 갱신.
- 2. 공유(친구코드+OS공유): `share_plus` · `shared_pack_service.dart` · firestore.rules `shared_packs/{code}` · UI(공유시트·코드 가져오기) · l10n.
- 3. Cloud Function 클라 보정: `targetLang` locale화 · 기본 endpoint 주입 · EN translation. `.env`에 두 키(gitignored). 배포 런북.
- 4. 홈 skill-path 레일.

**검증:** `flutter analyze` 0 유지 + `gen-l10n` + `test`. 함수 배포·AAB·실기기·Play Console = Jin.

**⚠️ API 키:** DeepL·우리말샘 키가 대화에 노출됨 → 셋업 후 **DeepL 키 재발급** 권장.

**Git push:** 미수행 (Jin 확인 후).

### 2026-05-21 — 코드베이스 audit + 마스코트/퀘스트/홈 긴급 수정

**Audit (전수 조사):**
- 🔴 마스코트가 앱 전역에서 깨져 있었음 — `mascot.dart`가 존재하지 않는 `tiger_magpie.png` 참조. 체크리스트엔 완료(`[x]`)로 잘못 표기돼 있었음. 홈 아바타·시나리오 대화·결과 화면·퀘스트 정답 팝업 전부 깨진 이미지로 표시
- 🟡 퀘스트 엔진 5종이 레거시 `AppColors`(다크 하드코딩) 사용 → 라이트모드에서 깨짐
- 🟡 `/scenarios` 리스트 화면은 완성됐으나 홈에서 진입 동선 없음
- 🟡 `madang(light).png` 미사용 (라이트모드 홈 배경 없음)
- 🟡 analyzer 경고 23건
- 콘텐츠: 시나리오 13개(B2 0개), `docs/content` 4트랙 전부 미실행

**Review:** Sori 디자인 시스템·8개 일러스트는 성숙·고품질. 핵심 결함은 마스코트 깨짐 + 라이트모드 미완성 + 콘텐츠 진입 동선 부재.

**Update (실행·검증 완료):**
1. mascot v5 — `welcome-hero.png` 기반 재작성, 호흡 애니메이션, errorBuilder fallback
2. 퀘스트 5종 → `SoriSurfaces` 라이트/다크 대응
3. 홈 Szenarien 카드 신설 (`/scenarios` 진입로)
4. 홈 라이트모드 `madang(light).png` 배경
5. analyzer 23→8
6. 검증: `flutter analyze` 0 errors · APK 디버그 빌드 성공 · 웹에서 시나리오 전체 흐름(온보딩→홈→리스트→퀘스트 3종→결과) 시각 확인

**Git push:** `f748073` (+ 동시 세션 `0afbd66`) → `origin/main` 푸시 완료

### 2026-05-21 (2차) — 발견 이슈 수정 + 역동적 애니메이션

**발견 이슈 수정 (Review→Fix):**
- 웹 settings 진입/리로드 시 `FirebaseException` JS-interop 레드스크린 — `auth_service`의 `_auth`를 nullable getter로, 모든 읽기 getter를 예외 안전하게. 웹 전용 이슈(안드로이드 무관)
- 시나리오 완료 후 홈 복귀 시 XP·streak 미갱신 — Today 카드 네비게이션에 `.then()` refresh 추가

**역동적 애니메이션 (Update):**
- `widgets/sori/motion.dart` 신규 — `SoriEntrance`(진입 fade+slide+scale), `SoriKenBurns`(배경 느린 줌)
- `widgets/sori/ambient_particles.dart` 신규 — 라이트: 매화 꽃잎 / 다크: 불씨 입자 (CustomPainter, seamless 무한 루프)
- `widgets/sori/flying_magpie.dart` 신규 — 갓 쓴 까치가 홈 상단을 주기적으로 비행 (날갯짓·뱅킹)
- 홈: Ken Burns 배경 + 매화 입자 + 비행 까치 + 카드 stagger 진입
- 온보딩: 매화 입자 + 대문 "열리듯" 등장 + 레벨 카드 stagger

**검증:** `flutter analyze` 0 issues · APK 디버그 빌드 성공. ⚠️ **시각(픽셀) 검증 미완** — Chrome 확장 연결 끊김 + 화면 접근 권한 시간 초과로 애니메이션 실물 확인 못 함. 코드는 컴파일·빌드만 검증됨 → 첫 `flutter run` 시 까치/입자 모양 점검 권장.

**동시 세션 작업 (같은 커밋에 포함):** 다른 세션이 솟을대문 인트로(`screens/intro_gate_screen.dart`) + 라우트 전환(`lib/motion/transitions.dart`) + `flutter_animate` 패키지 + 스플래시 색(teal→cream)을 작업. 본 커밋에 함께 포함됨. ⚠️ entrance 애니메이션이 `SoriEntrance`(이 세션)와 `flutter_animate`(동시 세션) 두 방식 공존 — 추후 일원화 검토 필요.

**Git push:** 본 커밋 → `origin/main`

### 2026-05-25 — v1.0.0 출시 plan + Track A·C 완료 (plan: snappy-conjuring-lemur)

**범위:** 2주 출시 준비 종합 점검. 자산 점검 + 컨셉 일관성 진단 + plan 작성 + Track A(자산 정리) + Track C(코드 구현) 동일 세션에서 완료.

**진단 (3 Explore agent 병렬):**
- 자산: hanok/에 마스코트 7장이 mascot/와 md5 동일 중복 (~16MB), + 미참조 5장 (gate.png, welcome-hero.png 등). intro_gate_screen.dart는 CustomPainter (HanokGateArt) 사용, PNG 미사용 검증.
- 콘텐츠: 시나리오 13개 중 B2 = 0개. /listening은 PlaceholderScreen, 끝말잇기 화면 없음 (풀 JSON만 있음).
- 디자인: Intro/Home/Stats 강함 ⭐⭐⭐, Vocab/Grammar/Wordle 약함 ⭐ (순수 텍스트).

**Plan (`snappy-conjuring-lemur.md`):** 5 트랙 (A:정리·B:PNG·C:코드·D:콘텐츠·E:검증) + 부록 A에 18장 PNG 상세 스펙 (Faceted Minhwa 스타일 가이드 기반 영문 프롬프트 그대로 복붙용).

**Update (Track A·C 완료):**
1. 자산: hanok/ 14개 삭제·이동 (~17MB 절감), scenes/empty/error 폴더 + .gitkeep + pubspec 등록
2. Mascot v6: emotion enum에 thinking 추가 + magpie worry/sleepy 매핑 + 신규 PNG 미존재 시 자동 fallback
3. ListeningScreen 신규 — TTS dialog 재생, 자막 4모드, 속도 3단계, sidekick 마스코트, 완료 시 XP+8 per line
4. KkeunmariScreen + KkeunmariEngine 신규 — 호랑이↔사용자 턴제, 30s 타이머, dead_end 처리, chain length × 10 XP
5. 홈 카드: 게임 4종 (Chosung/Wordle/Kkeunmari/Listening) 2×2 grid
6. Wordle 단청 frame Container + 4코너 단청 dot + 결과 카드 mascot (까치 celebrate / 호랑이 worry)
7. Chosung 라운드 종료 → 정확도별 mascot (≥80% celebrate + SoriCelebration.burst / 50-79% surprised / <50% worry)
8. Vocab/Grammar banner path → 신규 `study_classroom.png`/`study_scholar.png` (errorBuilder로 study.png fallback)
9. DE/EN ARB +37 키 (listening 18 + kkeunmari 19) — `flutter gen-l10n` 성공

**검증:** `flutter analyze` = **0 issues** · `flutter build apk --debug` = **success** (exit 0). 시각 검증은 Jin 실기기에서.

**미수행 (Jin 영역):** Track B PNG 18장 (plan 부록 A), Track D B2 시나리오 3-5개 (plan §7.1.2), Track E 실기기 검증·Data Safety·스크린샷.

**Git push:** 미수행 (Jin이 확인 후 명시적 요청 시 push).

### 2026-05-27 — Track D 콘텐츠 완료 (시나리오 13→21)

**범위:** B2 시나리오 3개 DE/EN 원어민 교열 + scenarios.json append + 일상 시나리오 5개 신규 작성.

**Update:**
1. **B2 시나리오 DE/EN 전면 교열** — 이전 세션 초안의 번역체·문법 오류 전수 수정:
   - `business_meeting_intro` title de: "Im Geschäftsmeeting vorstellen" → "Vorstellung beim Geschäftsmeeting" (sich 누락 수정)
   - `doctor_consultation` grammarBlock de: "Ich hoffe, ich werde bald besser" → "Ich hoffe, es geht mir bald besser"
   - 이전 세션 수정 사항 포함 (Ich hätte gerne / Es tut mir wirklich leid / stressbedingter Erschöpfung 등)
2. **scenarios.json append** — B2 3개 + 신규 5개 → 총 21개
3. **신규 시나리오 5개** (원어민 DE/EN으로 초안부터 작성):
   - `taxi_street` [A2] — 일반 택시, 길 지시, 요금 정산. Grammar: -(아/어) 주세요
   - `plans_with_friend` [A2, casual] — 금요일 약속 잡기. Grammar: -(으)ㄹ래?/ㄹ까?
   - `running_late` [A2, casual] — 30분 지각 카톡, ㅋㅋ 문화. Grammar: -고 있어 + -(으)ㄹ 것 같아
   - `postpone_plans` [B1, casual] — 하루 전 미루기. Grammar: -게 됐어
   - `cancel_plans` [B1, casual] — 당일 몸 안 좋아서 취소. Grammar: -아/어서 + 못 -(으)ㄹ 것 같아

**검증:** `python3` JSON 파싱 + 전 필드 검사 통과. 오류 0건.

**파일:**
- `assets/data/scenarios.json` (+8 시나리오)
- `docs/store/b2_scenarios_draft.json` (최종본)
- `docs/store/backdrop_prompts_day1.md` (백드롭 5장 이미지 생성 프롬프트 — Jin 사용)

**Git push:** Jin 요청으로 커밋 완료 → `origin/main`

---

### 2026-05-22 — 출시 폴리시 Week 1–4 (plan: hangul-sori-temporal-wombat)

**범위:** 4주 폴리시 — 접근성·모션 일원화·빈상태·모듈 폴리시·스토어 자료. 코드만 작업 (PNG는 Jin이 별도 생성).

**Update:**
- **Week 1**: Semantics 6개 위젯 + `primaryOnLight` 토큰 + `SoriMotion.reduceMotion` + `SoriTextTheme` + `flutter_animate` 제거 + `_BreathingTransform` 인라인 위젯 (`app_error.dart` 재작성)
- **Week 2**: `SoriEmptyState`·`HanokHeader` 신규 + 5개 빈/오류 상태 통일 + Settings/Stats 헤더 슬롯 + ARB 10키
- **Week 3**: Chosung 라운드(10문제) 요약 카드 + Wordle Focus/Enter 단축키 + 시나리오 backdrop opacity 0.08
- **Week 4**: `docs/store/` 6개 문서 (README, listing-de, listing-en, data-safety, screenshot-shotlist, release-notes-v1)

**검증:** `flutter analyze` = 0 issues · debug APK 빌드 통과. 시각 검증은 Jin 실기기에서.

**미해결 (위 체크리스트 참조):** Hangul IoU 정확도(deferred), Data Safety 답변 확정(Crashlytics/Analytics/AdMob 확인 필요), PNG 자산 8종 생성.

**Git push:** 본 커밋 → `origin/main`

### 2026-05-27 — 출시 직전 더블 크로스체크 + Play Console 일관성 픽스

**범위:** 동시 세션이 푸시한 `84bad36` (Crashlytics/Analytics 연동) 직후 점검. Play Console 등록 직전 *문서 ↔ 코드 ↔ 매니페스트* 정합성을 다시 본 결과 모두 작은 불일치들이 남아 있었음. 빌드 차원의 결함 0건, 출시 정합성 결함 4건 수정.

**Audit 결과:**
- ✅ `firebase_crashlytics ^4.3.10` + Gradle plugin `3.0.1` + `main.dart::_initFirebase` Hook (`FlutterError.onError` + `PlatformDispatcher.onError`) — 정확히 권장 패턴
- ✅ `firebase_analytics ^11.6.0` pubspec 등록 — SDK 링크만으로 auto-collection 활성 (custom event 미사용)
- ✅ `google-services` 4.4.2, `firebase.crashlytics` 3.0.1 — settings.gradle.kts에 정확히 등록
- ✅ `android/app/build.gradle.kts` — `isMinifyEnabled = true`, `isShrinkResources = true`, ProGuard rules 적용. R8 난독화 ON
- ✅ `proguard-rules.pro` — Firebase + Flutter + flutter_tts + Parcelable 보존 규칙 모두 포함
- ✅ `flutter_animate` 패키지 코드/pubspec에서 완전 제거 (한 줄 주석만 잔존)
- ✅ `print()` 잔존 0건. `debugPrint` 2건 (main.dart의 Firebase init fail + palette_service의 RC fetch fail) — 모두 best-effort 로깅. 민감 정보 노출 없음
- 🔴 `AndroidManifest.xml` — AdMob `APPLICATION_ID` meta-data가 **test ID**로 남아 있음. `google_mobile_ads`는 pubspec에서 주석 처리됐고 `ad_service.dart`는 stub → manifest 잔재가 "no ads" Data-Safety 주장을 흐림
- 🔴 `assets/illustrations/error/offline_lantern.png.png` — 더블 확장자 (.png.png)
- 🔴 `assets/illustrations/empty/studyroom_wating.png` — 오타 (`wating` → `waiting`)
- 🔴 Jin이 새로 만든 5장 PNG (empty/error)이 코드에 wire-up 안 됨 — 화면들이 여전히 mascot 이미지를 사용
- 🔴 `docs/store/data-safety.md` 끝의 "Open questions" 3개 (Crashlytics/Analytics/AdMob) 미해결 → Play Console form 작성 불가
- 🟡 In-app account deletion 미구현 (Play 5월 2024 정책 위반 가능성) — v1.0.1 후보로 메모

**Update (모두 이 세션에서 수정):**
1. **AdMob 매니페스트 잔재 제거** — `AndroidManifest.xml`의 `com.google.android.gms.ads.APPLICATION_ID` meta-data 삭제 + "AdMob 재활성화 시 어떻게 되돌리는지" 주석 남김
2. **PNG 파일명 수정** — `offline_lantern.png.png` → `offline_lantern.png`, `studyroom_wating.png` → `studyroom_waiting.png`
3. **5장 PNG 코드 wire-up**:
   - 시나리오 로드 실패 (`scenarios_list_screen.dart:81`) → `error/lost_magpie.png`
   - 시나리오 B2 잠금 (`_EmptyLevelCard` Image.asset) → `locked ? empty/sleeping_tiger_b2.png : mascot/tiger_blink.png` 분기
   - 단어장 due 완료 (`vocab_screen.dart:229`) → `empty/celebrate_complete.png`
   - 설정 오프라인 (`settings_screen.dart:340`) → `error/offline_lantern.png`
   - 통계 첫 진입 (`stats_screen.dart:50`) → `empty/studyroom_waiting.png`
   - 모두 `errorBuilder` 아이콘 fallback이 있어 PNG 로드 실패 시 자동 폴백
4. **data-safety.md 전면 보강** — SDK Audit 표 추가, "Open questions" 모두 ✅로 해결, "Account Deletion (Play-Policy)" 섹션 추가. Play Console form 그대로 옮길 수 있는 상태로 정리

**Play Console 입력값 (확정):**
- Privacy URL: `https://hangul-sori.com/privacy.html`
- App Access: "All functionality is available without special access" (익명 Firebase Auth로 모든 기능 접근 가능 — 검토용 계정 불필요)
- Data Safety: `docs/store/data-safety.md` 표 그대로
  - **수집 데이터**: Email + Display Name (Google opt-in), User ID (Firebase UID, 자동), App Activity (XP/Streak/Progress + Analytics auto-events), Crash logs, Diagnostics, Device/other IDs (Firebase Installation ID + Advertising ID via Analytics)
  - **공유**: 없음. **판매**: 없음. **암호화 in transit**: Yes (TLS).
- Category: Education (Bildung)
- Content rating: IARC 13+
- Target audience: 13+ (DE+EN)
- Support email: `hello@hangul-sori.com`

**검증:**
- 정적 분석 (코드 검토): ✅ 모든 변경이 기존 패턴과 일관. 추가된 PNG 경로 모두 `errorBuilder` 안전망 있음. 컴파일 이슈 없음.
- 빌드 검증: 샌드박스에 flutter 미설치 → Jin 로컬에서 `flutter analyze && flutter test && flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols` 1회 실행 필요. 동일 패키지 셋업으로 직전 커밋(`84bad36`)이 통과했으므로 회귀 가능성 낮음.

**Jin 로컬 env 액션 (이전 세션 미완 — 그대로 유효):**
1. Android Studio → SDK Manager → SDK Tools → "Android SDK Command-line Tools (latest)" 설치
2. `flutter doctor --android-licenses` 실행 → 모두 `y`
3. 프로젝트 루트에서:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
   ```
4. 결과 AAB: `build/app/outputs/bundle/release/app-release.aab` → Play Console Closed Testing 트랙 업로드
5. 동시에 `build/app/outputs/symbols/` 의 native debug symbols를 Play Console "App bundle explorer → Native debug symbols" 에 업로드 (난독화 스택 trace 복원용)

**미수행 (v1.0.1 후보 또는 Jin 영역):**
- 🟡 In-app account deletion (`AuthService.deleteAccount()` + Firestore doc 삭제) — Play 2024년 5월 정책 권장사항. 출시 후 14일 내 patch
- 🟡 Track B 남은 PNG (마스코트 추가 포즈, hero PNGs 등) — Jin 작업, errorBuilder fallback으로 빌드는 정상
- 🟡 실기기 시각 검증 (특히 새로 wire-up한 5장 PNG가 의도대로 보이는지)
- 🟡 Track D B2 시나리오 — 동시 세션 `6898646`에서 B2×3 추가됨 (확인 필요)
- 🟡 Crashlytics + Analytics console에서 실제 데이터 수신 확인 (release build 한 번 실행 후)

**Git push:** 미수행 (Jin 확인 후 명시 요청 시 commit & push).
**변경 파일:** `AndroidManifest.xml`, `data-safety.md`, `scenarios_list_screen.dart`, `vocab_screen.dart`, `settings_screen.dart`, `stats_screen.dart`, `CLAUDE.md` + PNG 2장 rename + 3장 staging (`lost_magpie.png`, `offline_lantern.png`, `studyroom_waiting.png`).

### 2026-05-27 (3차) — AAB 크기 최적화 (97MB → 예상 ~55MB)

**범위:** 1차 빌드가 97MB AAB로 나옴 → Jin이 줄이고 싶다고 함 → 자산 분석 + 무손실 PNG 압축 + Gradle 설정 정리.

**진단:**
- AAB 97MB 중 자산 PNG가 ~46MB (mascot 21 + scenes 11 + empty 6.4 + error 4 + hanok 3.4)
- 모든 일러스트 PNG가 1024-1254px, RGB/RGBA 무압축으로 저장됨 (각 ~2MB)
- Faceted Minhwa 스타일 = 단청 면 분할 = 평면 색상 → palette 양자화에 이상적

**Update (2단계 최적화):**
1. **Gradle 설정** (`android/app/build.gradle.kts`):
   - `buildTypes.release { ndk { debugSymbolLevel = "NONE" } }` 추가
   - native debug symbols를 AAB에 packing 안 함 → 5-15MB 절감
   - 심볼은 이미 `build/app/outputs/symbols/`에 있어 Play Console에 따로 업로드 가능

2. **PNG 양자화 압축** (Pillow Image.quantize, palette 256색):
   - RGBA → FASTOCTREE, RGB → MEDIANCUT
   - 백업은 `assets/illustrations/.backup_uncompressed/`에 자동 저장 (`.gitignore`에 추가)
   - 원본을 in-place로 압축 (코드 경로 변경 불필요)

**결과:**
| 폴더 | Before | After | 절감 |
|---|---|---|---|
| mascot/ | 21 MB | 1.6 MB | -93% |
| scenes/ | 11 MB | 4.5 MB | -59% |
| empty/ | 6.4 MB | 4.1 MB | -36% |
| error/ | 4.0 MB | 2.0 MB | -50% |
| hanok/ | 3.4 MB | 3.0 MB | -12% |
| **TOTAL** | **45.9 MB** | **13.9 MB** | **-70% (30.5 MB 절감)** |

- `madang(light/dark).png` 2장은 사진풍 그라데이션이라 양자화가 오히려 크게 만들어 → 원본 복구
- `calligraphy/porch/study/welcome-hero/gate.png` 5장은 이미 어느정도 최적화 상태 → 1% 정도만 줄어듦
- 시각 검증: tiger_idle / cafe / celebrate_complete / magpie_perched 4장 spot check → 육안으로 원본과 구분 불가능

**예상 AAB 크기:** 97 MB → **~55 MB** (자산 30 MB + symbols 5-15 MB 절감)
**예상 사용자 다운로드:** ABI split 후 **15-25 MB** (이전 30-40 MB → 절반)

**다음 단계 — Jin이 재빌드:**
```bash
flutter clean
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
ls -lh build/app/outputs/bundle/release/app-release.aab
```

**롤백 방법** (압축 결과가 마음에 안 들면):
```bash
cp -r assets/illustrations/.backup_uncompressed/* assets/illustrations/
```
백업 폴더는 `.gitignore` 처리됨 → repo 크기 영향 없음.

**변경 파일:** `android/app/build.gradle.kts` (ndk debugSymbolLevel), `.gitignore` (backup 폴더 제외), `assets/illustrations/{mascot,scenes,empty,error,hanok}/*.png` (압축).
**Git push:** 미수행.

### 2026-05-27 — Play Console 타겟 연령 결정 + iOS AdMob 잔재 정리

**범위:** Play Console "앱 타겟층 및 콘텐츠" 5단계 답변 확정 + 향후 광고 도입 시 정책 위반 0 로드맵 정리 + iOS AdMob 잔재 제거.

**Audit:**
- Android-Manifest, pubspec.yaml, ad_service.dart 모두 "no ads" 일관 ✅
- 🔴 iOS Info.plist에 `GADApplicationIdentifier` (test ID) + `SKAdNetworkItems` 잔존 — Android와 비대칭, Data-Safety "no ads" 답변과 불일치 우려

**Update:**
1. `ios/Runner/Info.plist` — `GADApplicationIdentifier` + `SKAdNetworkItems` 제거, Android-Manifest와 동일 패턴의 복원 안내 주석 추가
2. `docs/store/data-safety.md` SDK-Audit 표에 iOS 정리 반영
3. `docs/store/target-audience-and-ads.md` 신규 — Play Console 5단계 답변 가이드 + 광고 도입 시 정책 위반 0 체크리스트 (SDK, 코드 복원, 슬롯 설계, Disruptive Ads 9개 항목, Data Safety 업데이트, ATT, 직접 광고주 영업)

**핵심 결정 — 대상 연령대 = 13+ (13–15세 + 16–17세 + 18세 이상 3개 체크):**
- 콘텐츠는 G-rated이지만 K-pop/K-drama 영향 청소년+성인이 시장 현실
- 13세 미만 포함 시 COPPA + GDPR-K (독일 16세) + Google Families Programme 부담 폭발
- 기존 문서(IARC 13+, Apple App-Privacy) 일관성 유지

**검증:** 정적만 — 빌드는 Jin 로컬. 변경된 Dart 코드 0줄이라 회귀 가능성 0.

**Git push:** 미수행.

---

## 금지 사항

- `dist/`, `build/` 내부 직접 편집 금지
- `--no-verify` git hook 우회 금지 (Jin 명시 요청 없이)
- 커밋/푸시는 Jin이 명시적으로 요청할 때만
- `palette_variant` 외 Remote Config 키 임의 추가 금지
