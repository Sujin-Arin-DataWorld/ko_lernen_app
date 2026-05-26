# CLAUDE.md — ko_lernen_app (Hangul Sori)

> 세션 시작 시 이 파일 먼저 읽기. 그 다음 필요한 파일만 grep/Read.
> 전역 운영 원칙은 `~/.claude/CLAUDE.md` 참조.
> **작업 완료 시마다** "현재 진행 중인 작업" 체크리스트를 업데이트할 것 (완료 항목 체크, 새 항목 추가).
> **비주얼 에셋 작업 전** `~/Downloads/HANGUL_SORI_STYLE_GUIDE.md` 반드시 읽기 — 스타일명 **"Faceted Minhwa (모던 면 분할 민화)"**, 일러스트/아이콘/마케팅 자료 신규 제작·이터레이션 시 이 가이드를 프롬프트 기준으로 사용.

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
| `/vocab` | VocabScreen |
| `/grammar` | GrammarScreen |
| `/hangul` | HangulScreen |
| `/chosung` | ChosungQuizScreen (초성 퀴즈 A1-B2) |
| `/wordle` | WordleScreen (한글 워들) |
| `/settings` | SettingsScreen |
| `/stats` | StatsScreen |
| `/scenarios` | ScenariosListScreen |
| `/scenario` (args: scenarioId) | ScenarioPlayerScreen |
| `/listening` | ListeningScreen (v1 — 시나리오 TTS 재생 + 자막 토글) |
| `/kkeunmari` | KkeunmariScreen (v1 — 끝말잇기 호랑이↔사용자 턴제, 30s 타이머) |

### 서비스
- `lib/services/auth_service.dart` — Hybrid Auth. 항상 익명 로그인, Google 링크 선택. **주의**: web에서 Firebase 미설정 시 crash 방지를 위해 `_auth`가 nullable getter임.
- `lib/services/palette_service.dart` — Remote Config `palette_variant` 키로 단청/teal 토글. `paletteVariantNotifier` (ValueNotifier) → main.dart ListenableBuilder에서 ThemeData 재빌드.
- `lib/services/storage_service.dart` — SharedPreferences 래퍼 (레벨, streak, XP 등)
- `lib/services/data_loader.dart` — CSV/JSON 에셋 로드
- `lib/services/theme_service.dart` — 다크모드 toggle
- `lib/services/locale_service.dart` — 언어 선택 (DE/EN)
- `lib/services/kkeunmari_engine.dart` — 끝말잇기 풀 로더 + chain 검증 + 호랑이 다음 단어 선택 (`is_dead_end` 회피 우선)
- `lib/services/tts_service.dart` — flutter_tts 래퍼, ko-KR 기본, `speakSlow`/`setRate` 지원

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
- ✅ 모션 시스템 일원화 완료 — `flutter_animate` 패키지 제거. `motion.dart` + `lib/motion/transitions.dart` 둘만 공존 (역할 분리: entrance vs route transition).

### 데이터
- `assets/data/korean_vocab.csv` — 단어장 (level 필드: A1/A2/B1/B2)
- `assets/data/grammar.csv` — 문법
- `assets/data/scenarios.json` — 회화 시나리오
- `assets/data/kkeunmari_pool.json` — 끝말잇기 단어 풀

### 에셋 (2026-05-25 정리 후)
- `assets/icons/HanLogo.png` — **현재 앱 아이콘 소스** (Gemini 생성, 1024×1024, 갓+한)
- `assets/icons/icon-192.png` — pubspec 등록된 192 buffer
- `assets/illustrations/hanok/` — 한옥 공간 자산 (모두 사용 중):
  - `madang(light).png` / `madang(dark).png` — 홈 배경 (낮/밤)
  - `gate_door_left.png` / `gate_door_right.png` / `gate_frame.png` — IntroGateScreen GateArt 합성
  - `porch.png` — Chosung/Wordle 80px banner
  - `study.png` — Vocab/Grammar 80px banner (신규 `study_classroom.png`/`study_scholar.png`가 들어오면 자동 교체, 둘 다 errorBuilder fallback으로 study.png 유지)
  - `calligraphy.png` — Hangul 화면 헤더
- `assets/illustrations/mascot/` — 분리 포즈 PNG (Mascot 위젯 소스)
- `assets/illustrations/scenes/` — 시나리오 backdrop 5종 (Jin이 PNG 추가 시 자동 적용). `_backdropKey` 매핑은 `scenario_player_screen.dart`에 이미 완료
- `assets/illustrations/empty/` — 빈 상태 일러스트 3종 (sleeping_tiger_b2, celebrate_complete, study_room_waiting) — Jin 작업
- `assets/illustrations/error/` — 오류 상태 일러스트 2종 (offline_lantern, lost_magpie) — Jin 작업
- `docs/store/feature_graphic_v1_draft.png` — Play Store feature graphic 임시본 (재생성 권장)
- ⚠️ **2026-05-25 정리**: hanok/ 중복 마스코트 7장 + 미참조 5장(`tiger_smile`, `tigerbasic1`, `magpie_perched.v2`, `welcome-hero`, `gate.png`) + icons/icon-512.png 삭제 (~17MB 절감). 이전 코드가 참조하던 `welcome-hero.png`, `gate.png`는 모두 분리 자산/CustomPainter로 이전 완료.

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

## 현재 진행 중인 작업 (2026-05-21 기준)

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
- 핵심 우선순위: ① 시나리오 백드롭 5장 (`scenes/`), ② 빈/오류 5장 (`empty/`+`error/`), ③ 헤더 6장 (`hanok/scholar_room`, `achievements`, `study_classroom`, `study_scholar`, `listening_hero`, `kkeunmari_hero`), ④ 마스코트 4장 (`mascot/tiger_thinking/neutral/sleepy`, `magpie_worry`), ⑤ feature graphic 1024×500.

**Track D — 콘텐츠 작성 (Jin, 진행 중)**
- B2 시나리오 3-5개 추가 (`business_meeting_intro`, `complaint_delivery`, `doctor_consultation`, optional `apartment_viewing`, `job_interview`) — schema는 plan §7.1.1 참조
- 끝말잇기 풀은 v1 그대로 충분 (225 단어)
- 듣기는 시나리오 dialog 재사용 — 별도 콘텐츠 불필요

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
- [ ] B2 시나리오 0개 → 양산 (docs/content Track A, 13→30)
- [ ] 동기 기반 온보딩 + 5분 코스 (Track C)
- [ ] 끝말잇기 게임 화면 (Track D, 풀 JSON만 있고 화면 없음)
- [ ] 모듈 통합 "Sori Brain" (Track B)

---

## 세션 로그 (Audit · Review · Update · Push)

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

---

## 금지 사항

- `dist/`, `build/` 내부 직접 편집 금지
- `--no-verify` git hook 우회 금지 (Jin 명시 요청 없이)
- 커밋/푸시는 Jin이 명시적으로 요청할 때만
- `palette_variant` 외 Remote Config 키 임의 추가 금지
