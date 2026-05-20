# Hangul Sori — Brand Guide v1

> 이 문서는 "Hangul Sori (한글소리)" 앱의 브랜드 시각/언어 단일 소스 (v3 디자인 리프레시 기준).
> 갱신은 `lib/widgets/sori/tokens.dart` 변경과 함께 진행.

---

## 1. 브랜드 정체성

| | 값 |
|---|---|
| **공식 이름** | 한글소리 (en: Hangul Sori) |
| **의미** | "한글의 소리" — Sound of Hangul |
| **태그라인** | DE: *Learn Korean like a local* · EN: *Learn Korean the natural way.* |
| **타겟** | 한국어를 배우는 독일어/영어권 학습자 (A1–B2) |
| **톤** | 따뜻함 + 친근함 + 진지한 정확성 (한국 문화 존중) |

---

## 2. 로고 사용

### 정식 풀버전 — `assets/icons/icon.svg` (512×512)
- 익선관 (Sejong 왕관) + gold band + 보석 + "한" 글자
- 디테일이 살아있어 ≥ 128px 사이즈에서만 사용
- **용도**: 런처 아이콘, splash, marketing graphic, web og:image

### 미니버전 — `assets/icons/icon-mini.svg` (512×512 viewBox, 어디든 동작)
- 익선관 silhouette (디테일 0) + "한"
- 단색 흰색 위 brand purple bg
- **용도**: ≤ 64px 컨텍스트 (앱 헤더, 작은 알림, favicon)
- **사용 예**: `lib/screens/home_screen.dart:88`

### 사용 금지
- ❌ 익선관 따로, "한" 따로 분리 사용
- ❌ 다른 글자로 치환 ("Sori", "韓" 등)
- ❌ 단색 외 그라데이션 ${미니} / 흰색 외 색 채움 ${미니}

---

## 3. 컬러 토큰 — `lib/widgets/sori/tokens.dart`

### 브랜드
| 변수 | 값 | 용도 |
|---|---|---|
| `SoriColors.primary` | `#7B5CFF` | 주 액션, CTA, 브랜드 |
| `SoriColors.primarySoft` | `#EFEAFF` | tinted 배경 |
| `SoriColors.primaryDark` | `#6044DD` | hover/press |

### 액센트 (제한 사용)
| 변수 | 값 | 용도 |
|---|---|---|
| `SoriColors.hangul` | `#EC4899` | 한국어 강조 (Hangul 화면, 자음 셀) |
| `SoriColors.success` | `#22C55E` | 정답, 완료, streak active |
| `SoriColors.warning` | `#F59E0B` | streak, 별점, 주의 |
| `SoriColors.danger` | `#EF4444` | 오답, 삭제 |
| `SoriColors.info` | `#3B82F6` | 정보 (드물게, 모음 강조 등) |

### Surfaces (light/dark 자동 — `SoriSurfaces.of(context)`)
- **Light**: `#FFFFFF` bg, `#F7F8FA` surface, `#0F1419` text
- **Dark**: `#0B0E12` bg, `#171B22` surface, `#F4F6F8` text

---

## 4. 타이포그래피

### 폰트
- **유일 사용 폰트**: **Pretendard** (5 weights bundled)
- `lib/theme.dart:51`에 `fontFamily: 'Pretendard'` default 세팅
- Material Text 위젯은 **자동 상속** — 별도 명시 불필요
- CustomPainter / TextPainter 직접 그릴 때만 `fontFamily: 'Pretendard'` 명시

### Weight 매핑
| Weight | 용도 |
|---|---|
| 400 Regular | body, description |
| 500 Medium | 보조 라벨 |
| 600 SemiBold | 카드 타이틀 |
| 700 Bold | 강조 라벨 |
| 800 ExtraBold | screen title, AppBar |
| 900 Black | 큰 한글 문자 (hero card 한 글자, 마스코트 z 등) |

### 크기 일관성
- Body: 13-14
- Card title: 14-18
- Hero title: 18-22
- App bar: 18
- 큰 한글 글자: 60-110 (hangul cards), 26-32 (cells)

---

## 5. 모션 — `SoriMotion`

| | duration | 사용 |
|---|---|---|
| `fast` | 150ms | hover, focus |
| `medium` | 250ms | card press release |
| `slow` | 400ms | mascot pop in, sheet open |
| `verySlow` | 600ms | hero transition |

| Curve | 사용 |
|---|---|
| `press` (easeOut) | press down |
| `release` (elasticOut) | press up → spring |
| `emphasis` (easeOutCubic) | route transition |
| `celebrate` (elasticOut) | 성공 bounce |

---

## 6. 마스코트 — v3에서 변경

### 폐기 (v2)
- ~~Jieun (안경 + 긴 머리)~~ — painter 버그로 "대머리"처럼 보임
- ~~Minsu (올리브 모자)~~ — 페어로 등장 의도였으나 사용처 적음

### 신규 (v3) — `lib/widgets/sori/mascot.dart` 재작성
- **주: 호랑이 (Tiger / 호랑이)** — 한국 상징, 88 Hodori 유산 + Kakao Friends 동글동글
- **보조: 까치+갓 (Magpie + Gat / 까치호랑이 풍속)** — 좋은 소식, 조선 민화 정통
- 6 emotions 동일: smile, celebrate, worry, surprised, sleepy, neutral

### 마스코트 활용 가이드
- **Onboarding hero**: tiger size=128 smile
- **Home header sidekick**: tiger size=32, 시간대별 emotion
- **Quest 정답**: MascotPop tiger celebrate (코너)
- **Wordle 승리**: magpie celebrate ("좋은 소식이야!")
- **Streak 0/1-7/8+**: tiger sleepy / neutral / celebrate

---

## 7. 톤 가이드 (language)

### 사용자 호칭
- DE: `du` (정중 X, 친밀 톤)
- EN: 그대로 you
- KO: 학습 콘텐츠에만 한국어 (UI는 DE/EN)

### 마스코트 대사 (시나리오 안)
- 호랑이: 친구 같은 한국 친구 톤 — "안녕!", "잘했어!"
- 까치: 격려/희소식 톤 — "오! 좋은 소식이야!"
- 둘 다 어려운 표현 안 씀, 학습자가 따라 말할 수 있는 짧은 문장

---

## 8. 변경 로그

| 버전 | 날짜 | 변경 |
|---|---|---|
| v1 | 2026-05-21 | 초기 작성 — 호랑이 마스코트 도입, icon-mini.svg 추가 |
