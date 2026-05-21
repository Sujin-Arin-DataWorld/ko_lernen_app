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
- `lib/main.dart` — 라우트 테이블, Firebase/Ad 초기화, 팔레트 서비스

### 라우트
| 경로 | 화면 |
|---|---|
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
| `/listening` | PlaceholderScreen |

### 서비스
- `lib/services/auth_service.dart` — Hybrid Auth. 항상 익명 로그인, Google 링크 선택. **주의**: web에서 Firebase 미설정 시 crash 방지를 위해 `_auth`가 nullable getter임.
- `lib/services/palette_service.dart` — Remote Config `palette_variant` 키로 단청/teal 토글. `paletteVariantNotifier` (ValueNotifier) → main.dart ListenableBuilder에서 ThemeData 재빌드.
- `lib/services/storage_service.dart` — SharedPreferences 래퍼 (레벨, streak, XP 등)
- `lib/services/data_loader.dart` — CSV/JSON 에셋 로드
- `lib/services/theme_service.dart` — 다크모드 toggle
- `lib/services/locale_service.dart` — 언어 선택 (DE/EN)

### Sori 디자인 시스템 (`lib/widgets/sori/`)
- `tokens.dart` — **단일 색상 소스** (v6.0 단청 팔레트). `SoriColors`, `Spacing`, `SoriRadius`, `SoriElevation`, `SoriSurfaces`
- `hanok_tokens.dart` — 한옥 전용 색상 (단청 4색)
- `card.dart`, `button.dart`, `chip.dart`, `progress.dart`, `badge.dart`, `pressable.dart` — UI 컴포넌트
- `mascot.dart` — `Mascot.tiger` / `Mascot.magpie` → `welcome-hero.png` 일러스트 사용 (v5). v4는 미존재 `tiger_magpie.png`를 참조해 앱 전역에서 마스코트가 깨졌었음 — v5에서 수정. `animate:true` 시 호흡 애니메이션 + errorBuilder fallback
- `mascot_pop.dart` — 퀘스트 피드백용 팝업 마스코트
- `hanok/` — 한옥 장식 위젯 (단청 divider, 기와 패턴, 처마, 창살, 마당 배경)

### 데이터
- `assets/data/korean_vocab.csv` — 단어장 (level 필드: A1/A2/B1/B2)
- `assets/data/grammar.csv` — 문법
- `assets/data/scenarios.json` — 회화 시나리오
- `assets/data/kkeunmari_pool.json` — 끝말잇기 단어 풀

### 에셋
- `assets/icons/HanLogo.png` — **현재 앱 아이콘 소스** (Gemini 생성, 1024×1024, 갓+한)
- `assets/icons/icon-512.png` — HanLogo 복사본 (launcher_icons 참조)
- `assets/illustrations/hanok/welcome-hero.png` — 호랑이+까치 일러스트 (1024², Faceted Minhwa). stats 화면 hero + **마스코트 위젯 소스**
- `assets/illustrations/hanok/gate.png` — 한옥 대문 일러스트 (온보딩)
- `assets/illustrations/hanok/madang(light).png` / `madang(dark).png` — 홈 배경 (낮/밤)
- ⚠️ `tiger_magpie.png`는 **존재하지 않음** — 과거 마스코트가 이걸 참조해 깨졌음 (v5에서 해결)

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

### 마스코트 (v5)
- `Mascot.tiger` / `Mascot.magpie` 둘 다 `welcome-hero.png` 일러스트 표시.
- `emotion` 파라미터: celebrate/worry/sleepy/surprised → 우측 하단 이모지 오버레이.
- `animate: true` → hero 컨텍스트(결과/홈)용 부드러운 호흡 스케일 애니메이션.
- 에셋 로드 실패 시 errorBuilder가 색상 원+이모지 fallback (깨진 아이콘 방지).

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

- [x] 초성 퀴즈 A1-B2 레벨 분리 + 독일어 UI
- [x] 워들 독일어 힌트 카드 상시 표시
- [x] Sori v6.0 단청 팔레트 마이그레이션
- [x] HanLogo (갓+한) 런처 아이콘 적용
- [x] Firebase Remote Config `palette_variant` 키 설정
- [x] **마스코트 깨짐 수정 (v5)** — v4가 미존재 `tiger_magpie.png` 참조 → `welcome-hero.png` 일러스트 + 호흡 애니메이션 (mascot.dart)
- [x] **퀘스트 엔진 5종 라이트/다크 대응** — 레거시 `AppColors`(다크 전용) → `SoriSurfaces` (hoerverstehen/luecken/uebersetzen/particle_pop/batchim_drop)
- [x] **홈에 시나리오 노출** — listening placeholder 카드 → Szenarien 카드(`/scenarios`). 기존엔 시나리오 리스트 진입로 없었음
- [x] **홈 라이트모드 배경** — `madang(light).png` 추가 (다크는 기존)
- [x] analyzer 정리 (23→8, 잔여 8건은 settings의 deprecated Radio API + build_context — 기존)
- [x] APK 디버그 빌드 검증 통과
- [ ] 앱 on-device 시각 검증 (`flutter run`)
- [ ] **B2 시나리오 0개** → 콘텐츠 양산 (docs/content Track A, 13→30)
- [ ] 동기 기반 온보딩 + 5분 코스 (docs/content Track C) — 미실행
- [ ] 끝말잇기 게임 화면 (docs/content Track D) — 풀 JSON만 있고 화면 없음
- [ ] 모듈 통합 "Sori Brain" (docs/content Track B) — 미실행

---

## 금지 사항

- `dist/`, `build/` 내부 직접 편집 금지
- `--no-verify` git hook 우회 금지 (Jin 명시 요청 없이)
- 커밋/푸시는 Jin이 명시적으로 요청할 때만
- `palette_variant` 외 Remote Config 키 임의 추가 금지
