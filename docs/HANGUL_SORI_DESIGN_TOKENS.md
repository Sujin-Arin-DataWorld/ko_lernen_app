# HANGUL SORI — Design Tokens

**Project:** Hangul Sori (한글소리) — Korean learning app for German-speaking learners  
**Companion to:** `HANGUL_SORI_STYLE_GUIDE.md` (Faceted Minhwa visual language)  
**Version:** 2.0 (v6.0 단청 팔레트 기준)  
**Last Updated:** 2026-05-21  
**Implementation:** Flutter / Material 3  
**Source of truth:** `lib/widgets/sori/tokens.dart` + `lib/widgets/sori/hanok_tokens.dart`

---

## TL;DR — 3원칙

1. **기능 UI** → `SoriColors` (muted 단청, AA 대비비 검증됨)
2. **한옥 장식** → `HanokColors` (vivid 단청, 채도 높은 décor용)
3. **surface/text/bg** → `SoriSurfaces.of(context).xxx` (라이트/다크 자동 분기)

```dart
// 올바른 사용 패턴
final s = SoriSurfaces.of(context);    // 라이트/다크 자동
color: SoriColors.primary              // 기능 색상 (static)
color: s.text                          // 모드에 따라 바뀌는 색상
padding: const EdgeInsets.all(Spacing.lg)  // 16dp
borderRadius: SoriRadius.brMd              // 16dp
```

---

## 1. COLOR TOKENS

### 1.1 Brand — SoriColors (`lib/widgets/sori/tokens.dart`)

#### Primary (단청 녹청 — v6.0)
| 토큰 | 값 | 용도 |
|---|---|---|
| `SoriColors.primary` | `#1F7A6B` | 버튼, CTA, 선택 indicator |
| `SoriColors.primarySoft` | `#DCEEE8` | 버튼 배경 soft, selected chip |
| `SoriColors.primaryDark` | `#0E443B` | hover/pressed 상태 |
| `SoriColors.darkPrimary` | `#4FB6A0` | 다크모드 primary (대비 확보용 lift) |

> **origin:** 창덕궁 처마 원본 `#2D9C7C` 채도 12% 낮춤. 한지 배경 위 WCAG AA 통과.

#### Cultural Accents
| 토큰 | 값 | 용도 |
|---|---|---|
| `SoriColors.tiger` | `#FF8C42` | 호랑이 마스코트 primary |
| `SoriColors.gold` | `#C99A2E` | XP, streak, 갓 띠, 성취 뱃지 |
| `SoriColors.accent` | `#A0524A` | 석간주 적 — CTA secondary, 한글 강조 |
| `SoriColors.accentSoft` | `#F0D9D5` | 석간주 soft background |
| `SoriColors.highlight` | `#5A7BA0` | 청금석 — info, 강조 highlight |
| `SoriColors.hangul` | `#A0524A` | 한국어 글자 강조 (= accent) |
| `SoriColors.darkAccent` | `#C77268` | 다크모드 석간주 (lift) |

#### Functional
| 토큰 | 값 | 용도 |
|---|---|---|
| `SoriColors.success` | `#1F7A6B` | 정답, 완료 (= primary 재사용) |
| `SoriColors.warning` | `#D4A22E` | streak, 주의 |
| `SoriColors.danger` | `#C44F40` | 오답, 삭제 (단청 적 lifted) |
| `SoriColors.info` | `#5A7BA0` | 정보 (= highlight) |

### 1.2 Surfaces — SoriSurfaces (context-aware)

**사용법:** `final s = SoriSurfaces.of(context);`

| 프로퍼티 | Light | Dark | 용도 |
|---|---|---|---|
| `s.bg` | `#FAF6EC` 한지 cream | `#0E1A18` deep ink | Scaffold 배경 |
| `s.surface` | `#F1ECDC` | `#1A2A26` | 카드, 시트 |
| `s.surfaceAlt` | `#E5DCC4` | `#233530` | 강조 카드, 드롭다운 |
| `s.text` | `#1A1F1D` 먹 | `#F1E8D0` 한지 크림 | 본문 텍스트 |
| `s.textMuted` | `#5C6660` | `#A0AFA8` | 부제, 보조 정보 |
| `s.textDim` | `#8B948E` | `#6B7570` | 캡션, metadata |
| `s.border` | `#DAD3BE` | `#2E443E` | 카드 테두리, divider |
| `s.brightness` | `Brightness.light` | `Brightness.dark` | ThemeData 빌드용 |

#### Static preset instances
```dart
SoriSurfaces.light      // 단청 라이트
SoriSurfaces.dark       // 단청 다크
SoriSurfaces.lightTeal  // 레거시 teal 라이트 (kill-switch용)
SoriSurfaces.darkTeal   // 레거시 teal 다크 (kill-switch용)
```

#### Kill-switch: Teal 팔레트
Firebase Remote Config `palette_variant = "teal"` → `SoriColorsTeal` + teal surfaces.  
**직접 참조 금지** — `PaletteService`를 통해서만 사용.

### 1.3 Hanok Décor — HanokColors (`lib/widgets/sori/hanok_tokens.dart`)

**용도:** 한옥 장식 décor 전용 (divider dot, 배경 texture, hero illustration).  
`SoriColors`보다 채도가 높다 — 의도적.

#### 한지 (Paper tones)
| 토큰 | 값 | 용도 |
|---|---|---|
| `HanokColors.hanjiCream` | `#FAF6EC` | light surface (= SoriColors.lightBg) |
| `HanokColors.hanjiCreamDark` | `#E8E0CC` | 그림자, 진한 border |
| `HanokColors.hanjiNight` | `#2A2418` | dark mode 한지 |
| `HanokColors.hanjiInk` | `#2C2419` | 한지 위 글씨 |

#### 단청 오방색 (Obangsaek — vivid reference)
| 토큰 | 값 | 용도 |
|---|---|---|
| `HanokColors.cheong` | `#3D9A7F` | 청 (동방) — 단청 divider stripe |
| `HanokColors.jeok` | `#C24A45` | 적 (남방) — 단청 accent dot |
| `HanokColors.hwang` | `#DFA951` | 황 (중앙) — 갓끈, 금 장식 |
| `HanokColors.baek` | `#F5F0E6` | 백 (서방) — 한지 하이라이트 |
| `HanokColors.heuk` | `#2C2419` | 흑 (북방) — 먹 |

#### 기와 / 황토 / 마당
| 토큰 | 값 | 용도 |
|---|---|---|
| `HanokColors.giwaGray` | `#5C6470` | 기와 타일 |
| `HanokColors.hwangto` | `#A87E5E` | 한옥 기둥, 대들보 |
| `HanokColors.madangSkyLight` | `#E8EFE9` | 마당 배경 sky (낮) |
| `HanokColors.madangGroundDark` | `#15201A` | 마당 배경 ground (밤) |

---

## 2. SPACING TOKENS

**Base:** 4dp 시작, 실질적 8dp grid  
**파일:** `Spacing` class in `lib/widgets/sori/tokens.dart`

| 토큰 | 값 | 용도 |
|---|---|---|
| `Spacing.xs` | 4 | 아이콘 ↔ 레이블, 미세 간격 |
| `Spacing.sm` | 8 | 연관 요소 tight gap |
| `Spacing.md` | 12 | 중간 gap |
| `Spacing.lg` | 16 | 표준 카드 padding **(기본)** |
| `Spacing.xl` | 24 | 섹션 간격 |
| `Spacing.xxl` | 32 | 큰 섹션 |
| `Spacing.xxxl` | 48 | 화면 hero 간격 |

#### 복합 preset
```dart
Spacing.pageH       // EdgeInsets.symmetric(horizontal: 18)
Spacing.cardInner   // EdgeInsets.all(16)
Spacing.cardCompact // EdgeInsets.all(12)
```

---

## 3. BORDER RADIUS TOKENS

**파일:** `SoriRadius` class in `lib/widgets/sori/tokens.dart`

| 토큰 | 값 | 용도 |
|---|---|---|
| `SoriRadius.xs` | 8 | 작은 badge, 태그 |
| `SoriRadius.sm` | 12 | chip, 작은 카드 |
| `SoriRadius.md` | 16 | **기본 카드** |
| `SoriRadius.lg` | 20 | hero 카드, large 버튼 |
| `SoriRadius.xl` | 24 | bottom sheet top corner |
| `SoriRadius.pill` | 999 | chip/pill, avatar |

#### BorderRadius 프리셋
```dart
SoriRadius.brSm   // BorderRadius.all(Radius.circular(12))
SoriRadius.brMd   // BorderRadius.all(Radius.circular(16))
SoriRadius.brLg   // BorderRadius.all(Radius.circular(20))
SoriRadius.brPill // BorderRadius.all(Radius.circular(999))
```

---

## 4. ELEVATION / SHADOW TOKENS

**파일:** `SoriElevation` class in `lib/widgets/sori/tokens.dart`

| 토큰 | 용도 |
|---|---|
| `SoriElevation.low` | Resting card |
| `SoriElevation.medium` | Hovered/pressed card |
| `SoriElevation.high` | Hero, floating, modal |

---

## 5. MOTION TOKENS

**파일:** `SoriMotion` class in `lib/widgets/sori/tokens.dart`

#### Duration
| 토큰 | 값 | 용도 |
|---|---|---|
| `SoriMotion.fast` | 150ms | 탭 피드백, 색상 전환 |
| `SoriMotion.medium` | 250ms | 표준 화면 전환, dialog |
| `SoriMotion.slow` | 400ms | 강조 전환, 성취 reveal |
| `SoriMotion.verySlow` | 600ms | onboarding, 환영 애니 |

#### Curves
| 토큰 | 용도 |
|---|---|
| `SoriMotion.press` | `Curves.easeOut` — 탭 scale down |
| `SoriMotion.release` | `Curves.elasticOut` — 탭 bounce back |
| `SoriMotion.emphasis` | `Curves.easeOutCubic` — 페이지/hero |
| `SoriMotion.gentle` | `Curves.easeOutQuart` — 부드러운 등장 |
| `SoriMotion.celebrate` | `Curves.elasticOut` — 정답 celebrate |
| `SoriMotion.pressScale` | `0.96` — 눌렸을 때 scale |

---

## 6. TYPOGRAPHY TOKENS

**파일:** `SoriFonts` / `SoriTextTheme` class in `lib/widgets/sori/tokens.dart`

앱 번들 폰트는 2개 — 역할로만 선택한다. 크기·색은 `SoriTextTheme.of(context)` 프리셋을 통해 얻고, `TextStyle(fontFamily: '...')` 문자열 하드코딩은 금지한다. 2026-09-28 Jin 선택에 따라 한국어와 DE/EN UI를 분리했다.

| 토큰 | 폰트 | 번들 웨이트 | 용도 |
|---|---|---|---|
| `SoriFonts.sans` | Noto Sans KR | variable | KO/DE/EN UI, 제목·본문·숫자 |
| `SoriFonts.korean` / `learningKorean` | Noto Sans KR | variable | 자모·어휘·문장 등 한국어 학습 글자 |
| `SoriFonts.fallback` | 없음 | — | 공용 번들에 세 언어 글리프가 있어 별도 폴백이 필요 없음 |
| `SoriFonts.culture` | Noto Sans KR | variable | 짧은 한국어 문화 제목 |

> Noto Sans KR 한 파일에 한글 완성형·영어·독일어 글리프가 모두 들어 있다. 전체 앱에서 서체를 통일하고 역할별 굵기는 구분한다.

#### SoriTextTheme 프리셋 (발췌, 2026-09-03 §A3 재정의)
| 토큰 | 크기 | 굵기 | 폰트 | 용도 |
|---|---|---|---|---|
| `tt.hero` | 36 | w600 | sans | 페이지 대형 헤드라인 (2026-09-03 §E7: 40→36) |
| `tt.display` | 32 | w500 | sans | Display heading |
| `tt.h1` | 26 | w500 | sans | 화면 제목 |
| `tt.h2` | 22 | w500 | sans | 섹션 제목 |
| `tt.h3` | 18 | w500 | sans | 소제목 |
| `tt.cultureTitle` | 21 | w500 | culture | 문화 카드 안의 짧은 한국어 표제 |
| `tt.cardTitle` | 17 | w500 | sans | 카드 제목 (§4.3: 카드 제목 w800 금지) |
| `tt.body` | 16 | w400 | sans | 본문 |
| `tt.koDisplay` | 30 | w500 | learningKorean | 한국어 학습 본문 |
| `tt.label` | 14 | w500 | sans | 라벨 |
| `tt.caption` / `tt.meta` / `tt.cardSubtitle` | 13.5 | w400 | sans | 보조 텍스트 하한(13 아래 금지) |
| `tt.chromeTitle` | 20 | w600 | sans | 앱바 크롬 전용(`SoriAppBar`, §A4) |
| `tt.numeral` | 30 | w500 | sans (tabular) | 스트릭·XP 큰 숫자 |

> 2026-09-30: KO/DE/EN 헤드라인과 학습 글자를 Noto Sans KR로 그린다.

**가드 테스트** — 위반 재발 방지:
- `test/typography_guard_test.dart` — `FontWeight.w800`/`w900` 래칫(내려가기만 한다), `fontFamily: '...'` 문자열 리터럴 0.
- `test/font_bundle_guard_test.dart` — DE/EN의 ä/ß/€, 한국어 폰트의 한글 11172음절을 실제 `cmap`으로 검사.
