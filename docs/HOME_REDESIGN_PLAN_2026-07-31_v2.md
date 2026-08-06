# 홈 개편 재계획 v2 — 검수 반영본

**작성** 2026-07-31 · **대상** `ko_lernen_app`
**입력** `hangeulsorihomeredesign.html`(목업) · `에셋요청서.md` · `docs/ASSET_VIDEO_PIPELINE_2026-07-30.md`
**검수** opus5(사실 검증) + sonnet(제품 판단) 독립 2건 — 지적 전량 재현 후 반영
**v1 대비** 사실 오류 8건 정정 · 신규 최우선 항목(에셋 용량) 추가 · CTA 색 결정 변경 · Phase 순서 변경

> **fable5는 사용량 한도로 검수 불가.** opus5·sonnet 2인 검수로 대체했습니다.

---

## 0. 네 줄 결론

1. **에셋요청서 7항목 중 새로 만들 것은 0개다.** 5개는 이미 레포에 있고, 1개(한지 텍스처)는 만들면 퇴보하며, 1개(까치 정지 프레임)는 소스 영상이 삭제돼 **실행 자체가 불가능**해졌다.
2. **"캐릭터 선택이 반영되는지 모르겠다"는 사실이다 — 그런데 더 나쁘다.** `Storage.preferredMascot`을 읽는 곳이 앱 전체에 3곳뿐이고 홈은 그중에 없다. 그리고 **캐릭터를 다시 고를 방법이 앱 어디에도 없다** (`/character_selection` 진입점 0개).
3. **목업은 진단이 정확하고 처방은 못 쓴다.** 8개 지적이 전부 소스로 재현된다. 단 팔레트를 새로 도입할 필요가 없다 — **기존 토큰 + 신규 1개**로 같은 목표를 달성한다.
4. **그런데 이 모든 것보다 큰 게 있다: `assets/`가 159MB다.** 1MB 초과 파일 62개가 112MB를 차지하고, 그중 7개는 두 폴더에 중복 복사돼 있다. pubspec이 폴더째 번들하므로 전부 APK에 들어간다. **홈 개편보다 먼저 처리해야 한다.**

---

## 1. v1의 오류 — 먼저 정정합니다

검수에서 걸린 제 오류를 그대로 싣습니다. v1을 이미 읽으셨다면 아래를 우선하세요.

| # | v1 주장 | 실제 | 재현 명령 |
|---|---|---|---|
| 1 | `EavesCorner`는 사용처 0인 죽은 코드 | **card.dart:97에서 사용 중.** SoriCard 전체가 의존 → 손대면 앱 전역 회귀 | `grep -rn EavesCorner lib/` |
| 2 | "1일차 인사 분기 없음" → ARB 키 신설 | **분기는 이미 있다** (`learner_motivation.dart:83` `streak==0 && xp==0`). 진짜 원인은 `home_screen.dart:701`의 `if (streakDays == 0)` 블록이 723행에서 `homeTigerBubbleResume`을 **무조건** 띄우는 것 | `grep -n "streakDays == 0" lib/screens/home_screen.dart` |
| 3 | 홈에서 `/path` 링크 4개 | **3개.** 688행은 `/scenario` | `grep -c "'/path'" …` |
| 4 | `MascotKind.tiger` 29곳 | **39곳** (그중 9곳은 승패 연출로 **의도된 것** — §5.3) | `grep -rn "MascotKind.tiger" lib/ \| wc -l` |
| 5 | 헤더 아이콘 4개 중 3개가 탭과 중복 | **2개.** `/stats` 탭은 없다 | `app_shell.dart` destinations |
| 6 | 헤더 로고가 `HanLogo.png` | **`icons/icon-192.png`** (44KB). HanLogo는 런처·스플래시 전용 | `home_screen.dart:852` |
| 7 | 터치 타깃 36dp → 🔴 치명 · WCAG 2.1 **AA** 2.5.5 | **2.5.5는 AAA다.** WCAG 2.1 AA에 터치 타깃 기준 없음. 2.2 AA(2.5.8, 24dp)는 36dp가 통과 → **Material 48dp 권고 미달, 🟡 주요** | WCAG 2.1 SC 목록 |
| 8 | textScaler 1곳 → 🔴 치명 | **과장.** Flutter `Text`는 자동 적용. 진짜 위험은 `maxLines:1 + ellipsis` 조합(홈 7곳) | — |
| 9 | 홈 `Semantics(` 1개 → 🔴 치명(4.1.2) | **과장.** `card.dart:151`이 탭 가능한 SoriCard 전부를 `Semantics(button:true)`로 감싼다. 진짜 문제는 `semanticLabel` **0개** → 🟡 주요 | `card.dart:151` |
| 10 | "기존 토큰만으로 전부 해결" | **테두리는 못 얻는다.** `lightBorderStrong`은 카드 채움(#F1ECDC) 기준 **2.81:1로 미달**. 카드 채움을 올려야 한다 → §4.2 | 재계산 |

---

## 2. ★ 최우선 — `assets/` 159MB (v1에 없던 항목)

검수가 지적하고 제가 재현한, **계획서의 어떤 항목보다 사용자 체감이 큰 문제**입니다.

| 지표 | 값 |
|---|---|
| `assets/` 총량 | **159 MB** |
| `illustrations/` | 86 MB |
| `video/` | 52 MB |
| `stickers/` | 18 MB |
| **1MB 초과 파일** | **62개 · 합계 112 MB** |
| 최대 단일 파일 | `stickers/stamp_sticker_fighting.png` **5.1 MB** |

### 2.1 즉시 회수 가능한 낭비

| 항목 | 절감 | 근거 |
|---|---|---|
| **`stickers/`↔`mascot/` 완전 중복 7개** | 확인 필요 | `tiger_sad.png`(각 4.92MB) · `tiger_surprised` · `magpie_dance/encourage/sing/sleep/wave` — **같은 파일명·같은 크기가 두 폴더에** |
| **`mascot/magpie.png` 1.6MB** | 1.6 MB | 확장자는 `.png`인데 **실체는 JPEG**(`JFIF, 1536×2752`). `lib/` 어디서도 참조 안 함 |
| **2508² 원본 다운스케일** | 대폭 | 마스코트 PNG가 2508px로 들어있다. 앱 최대 표시 크기는 180dp — 1254² 또는 1024²로 충분 |
| `sfx/README.md` · 기타 문서 | 소 | pubspec이 `assets/sfx/` 폴더째 번들 |

### 2.2 조치

```
Phase A (0.5~1일, 홈 개편 착수 전)
  A-1  stickers ↔ mascot 중복 7개 → 한쪽으로 통일, 참조 정리
  A-2  mascot/magpie.png 삭제 (미참조 + 포맷 거짓)
  A-3  2MB 초과 PNG 다운스케일 (2508 → 1254). 캐논 호랑이 tiger_idle 포함 여부는 확인 후
  A-4  pubspec 폴더 등록 → 비-미디어 파일 유입 감시 (테스트로 고정)
```

> ⚠️ **A-3은 사용자 확인이 필요합니다.** "캐논 호랑이"로 못 박으신 파일들이라 원본 해상도 축소를 임의로 하지 않습니다. §9 Q4 참조.

---

## 3. 에셋요청서 판정 (v1 유지 + 정정 2건)

| # | 요청 | 판정 | 근거 |
|---|---|---|---|
| 1 | `magpie_sitting.png` | ⛔ **실행 불가** | 소스 `magpie_sitting.mp4`가 **삭제됨**(스캔 중 병렬 세션이 제거). 대안: `mascot/magpie_perched.png`(91KB) 유용 — 이미 `Mascot`에 배선돼 있음 |
| 2 | `tiger_sitting.png` | 🔴 불필요 | `mascot/tiger_idle.png` + `tiger_blink.png`. **사용자가 "캐논"으로 지정한 바로 그 파일** |
| 3 | `app_mark.svg` | 🟡 보류 | 헤더가 쓰는 건 `icons/icon-192.png`(44KB). 겹침 원인은 파일이 아니라 `_TopBar` 레이아웃 — **레이아웃 먼저** |
| 4 | 마당 아이콘 6종 | 🟡 보류 | IA 확정 후(§6.3). 지금 발주하면 버림 |
| 5 | `hanji_tile.png` | 🔴 불필요 + 퇴보 | `hanok/hanji_texture.dart` CustomPainter가 닥섬유 + 다크모드 처리. PNG는 둘 다 잃는다 |
| 6 | 표정 변형 | 🔴 불필요 | PNG 20종 + mp4 16종 실재 |
| 7 | 한옥 마당 5단계 | 🟠 **판정 보류(v1 정정)** | `hanok_stages/` 12종은 **841×1870 세로 건물 진행**이고 요청서는 **1024×768 가로 마당 정경**. 용도가 다를 수 있음 → §9 Q5 |

> **정정**: v1은 요청서 1·2번을 "반박"처럼 썼지만, 요청서도 **"생성하지 마세요"**라고 같은 결론을 냈습니다. 다만 요청서가 제시한 방법(영상 프레임 추출)이 소스 삭제로 불가능해졌고, 애초에 `mascot/` PNG로 이미 해결돼 있었다는 점이 다릅니다.

**생성 대상 0개** — 단 3·4·7은 "지금 안 만든다"이지 "영원히 불필요"가 아닙니다.

---

## 4. 접근성 — 정정된 실측

### 4.1 색 대비 (라이트)

| 요소 | 현재 | 판정 | **권고 (기존 토큰)** | 결과 |
|---|---:|:--:|---|---:|
| 주 CTA 채움 vs 배경 | `tiger #FF8C42` **2.14** | ❌ | **`tigerOnLight #A8490B`** | **5.37** ✅ |
| 주 CTA 흰 라벨 | **2.31** | ❌ | 흰 on `tigerOnLight` | **5.80** ✅ |
| 카드 vs 배경 | `#F1ECDC` **1.09** | ❌ | 테두리로 해결 ↓ | — |
| 카드 테두리 | `lightBorder` **1.39** | ❌ | `lightBorderStrong` on **신규 `lightSurfaceRaised #FFFDF8`** | **3.27** ✅ |
| 보조 라벨 | `lightTextDim` **2.89** | ❌ | `lightTextMuted #5C6660` | **5.52** ✅ |
| 본문 | **15.47** | ✅ | 유지 | 15.47 ✅ |

### 4.2 CTA 색 결정 — v1에서 변경 ★

v1은 `SoriColors.accent`(석간주 적 #A0524A)를 권고했습니다. **제품 검수가 정확히 반박했습니다**: 학습 앱에서 붉은 주 버튼은 오답·경고로 학습된 색이고, 호랑이 주황을 CTA에서 빼는 건 대비 수치만으로 정당화되지 않는다.

**재계산 결과 — `SoriColors.tigerOnLight #A8490B`가 모든 면에서 낫습니다:**

| 후보 | 채움 vs 배경 | 흰 라벨 | 브랜드 | 신규 토큰 |
|---|---:|---:|---|---|
| `tiger #FF8C42` (현재) | 2.14 ❌ | 2.31 ❌ | 유지 | — |
| `accent #A0524A` (v1 권고) | 5.12 ✅ | 5.53 ✅ | **주황 상실** | 0 |
| **`tigerOnLight #A8490B`** ★ | **5.37** ✅ | **5.80** ✅ | **주황 유지** | **0** |
| 목업 `#A85210` | 5.02 ✅ | 5.41 ✅ | 주황 유지 | 1 (불필요) |

`tigerOnLight`는 **이미 존재하는 토큰**이고, 주석에 "`tiger`는 밝아서 텍스트로 못 쓴다 → 이 다크 변형을 써라"라고 적혀 있습니다. 채움으로도 쓰면 되는데 아무도 안 쓰고 있었습니다.

> **부수 효과**: 목업이 새로 만든 `#A85210`과 사실상 같은 색입니다. 목업의 색 판단이 옳았고, 앱에 이미 그 색이 있었을 뿐입니다.

### 4.3 다크모드 — v1에서 누락 (검수 지적)

| 조합 | 대비 | 판정 |
|---|---:|:--:|
| 흰 라벨 vs `darkAccent #C77268` | 3.48 | ⚠️ UI만 통과, 텍스트 미달 → **먹색 라벨(4.80)** 사용 |
| `darkAccent` vs `darkBg` | 5.12 | ✅ |
| **`darkBorder #2E443E` vs `darkSurface #1A2A26`** | **1.43** | ❌ **다크모드 카드 경계도 안 보인다** |
| `darkTextMuted` vs `darkBg` | 7.79 | ✅ |

> **신규 발견**: 라이트에서 고친 카드 경계 문제가 다크에도 그대로 있습니다. 앱이 `themeMode.light` 고정이라 지금은 안 드러나지만, 다크를 켜는 순간 같은 결함이 나옵니다.

### 4.4 조작·인지 (등급 정정)

| # | 이슈 | 기준 | 등급 | 처방 |
|---|---|---|---|---|
| 1 | 헤더 아이콘 36×36dp | Material 48 / HIG 44 / WCAG 2.2 AA 2.5.8 통과 | 🟡 주요 *(v1 치명 → 정정)* | 48dp 또는 개수 축소 |
| 2 | 헤더 2개가 하단 탭과 중복 | 3.2.3 | 🟡 주요 | 헤더 = 스트릭 + 설정 |
| 3 | `semanticLabel` 홈 0개 | 4.1.2 보조 | 🟡 주요 *(v1 치명 → 정정)* | 복합 카드에 라벨 |
| 4 | `maxLines:1 + ellipsis` 홈 7곳 | 1.4.4 | 🟡 주요 *(v1 치명 → 정정)* | 독일어 200%에서 잘림 검증 |
| 5 | 마당 타일 색으로만 구분 | 1.4.1 | 🟢 경미 | 색 + 텍스트 |
| 6 | 웰컴 영상 자막 없음 | 1.2.2 | 🟢 경미 | 텍스트 오버레이 가능 |

> `SoriMotion.reduceMotion` · `TigerStageVideo.videoReady` 폴백은 **이미 올바르다.** 추가 작업 없음.

---

## 5. 근본 원인 — 캐릭터 배선

### 5.1 데이터 흐름

```
character_selection_screen.dart:79   Storage.setPreferredMascot(...)      ← 쓰기 1
        ▼
Storage.preferredMascot                                                    ← 읽기 3 (전부)
   ├── profile_screen.dart:315          ✅
   ├── scenario_player_screen.dart:1453 ✅
   └── milestone_celebration.dart:39    ✅
       ❌ home_screen.dart · game_reward.dart · listening_screen · 게임 7종
```

### 5.2 ★ 신규 치명 발견 — 캐릭터를 다시 고를 수 없다

```
$ grep -rn "'/character_selection'" lib/ | grep -v main.dart
(출력 없음)
```

**`/character_selection`으로 가는 진입점이 앱 전체에 0개입니다.** 라우트 테이블에만 등록돼 있습니다.

의미:
- 온보딩에서 한 번 고르면 **영원히 못 바꿉니다**
- **P1의 결과를 검증할 방법이 없습니다** — 까치로 바꿔서 홈을 볼 수가 없음
- 그리고 목업/v1이 제안한 "캐릭터가 일일 목표 기본값(45/30 XP)을 정한다"는 **되돌릴 수 없는 결정을 첫 탭에 묶는 것**이 됩니다

→ **P1-0(설정에 캐릭터 변경 추가)이 P1 전체의 선행 조건입니다.**

### 5.3 `MascotKind.tiger` 39곳 — 5분류 (v1 정정)

v1은 "29곳 전부 제거"라고 썼습니다. **틀렸습니다.** 일괄 치환하면 의도된 연출이 파괴됩니다.

| 분류 | 개수 | 조치 |
|---|---:|---|
| ① **진짜 하드코딩** | ~12 | `Storage.mascotKind`로 교체 — `home_screen:712` · `book_result:278,284` · `chosung:717,733` · `custom_pack_play:245` · `vocab_pack_result:113,414` · `tiger_video:363` |
| ② **의도된 승패 연출** | **9** | **유지.** `pct >= 50 ? magpie : tiger` (cloze:279, custom_pack_quiz:308, custom_pack_typing:301, daily_challenge:256, satz_arcade:239) + `won ? magpie : tiger` (kkeunmari:717, wordle:783). **까치=길조/승리, 호랑이=위로** — 이건 기능이지 버그가 아니다 |
| ③ **선택 화면 자체** | 6 | **유지 필수** (`character_selection_screen`) |
| ④ **기본값 파라미터** | ~8 | 기본값만 `Storage.mascotKind`로 (`character_clip:109`, `game_reward:107`, `mascot:34,51,61`) |
| ⑤ `@Deprecated` 문자열 | 2 | 무관 (`mascot.dart:338,340`) |

> **§9 체크리스트를 "리터럴 0"에서 "①분류만 0"으로 수정합니다.**

---

## 6. 실행 계획 v2 — 순서 변경

검수 지적: v1은 P0(접근성)을 먼저 뒀지만 **사용자가 직접 말한 고통은 P1(캐릭터)**이고, P0-2는 앱 전역 회귀라 오히려 P1보다 위험합니다.

```
Phase A  에셋 용량 159MB          0.5~1일   ← 신규, 최우선
Phase 0a CTA 색 + 보조텍스트       15분     ← 2줄, 즉시
Phase 1  캐릭터 배선               3.5일    ← 사용자가 말한 고통
Phase 0b 카드 경계 + 1일차 인사    1.5일    ← 앱 전역 회귀면, P1 뒤로
Phase 2  홈 정보 위계              4.5일    ← 골든 테스트 선행
Phase 3  에셋 (있으면)             0.5일
────────────────────────────────────────
합계 약 10.5일 (v1의 4일은 2.5배 낙관 — 검수 지적 수용)
```

### Phase 0a — 즉시 (2줄, 15분)

| ID | 파일 | 변경 |
|---|---|---|
| **0a-1** | `home_screen.dart:528` | `accent: SoriColors.tiger` → **`SoriColors.tigerOnLight`** (5.37/5.80, 주황 유지) |
| **0a-2** | 홈 `s.textDim` 사용처 (**1곳**) | → `s.textMuted` |

> `s.textDim`은 앱 전역 **69곳**에 있습니다. 홈 1곳만 고칩니다 — 나머지 68곳은 별도 과제로 분리(검수 지적 수용).

### Phase 1 — 캐릭터 배선 (3.5일) ★

| ID | 작업 |
|---|---|
| **P1-0** ★신규 | **설정에 캐릭터 변경 진입점 추가.** 현재 진입점 0개 → P1 검증 불가. **선행 조건** |
| **P1-1** | `Storage.mascotKind` getter + **`ValueNotifier<MascotKind>`**. static getter만으로는 변경 시 리빌드가 안 된다(검수 C6). `TigerStageVideo._greetPlayedThisLaunch`도 static이라 함께 처리 |
| **P1-2** | `TigerStageVideo` → `CharacterClips.stageFor(kind)`. 호랑이 `tiger_rise`/`tiger_rest` · 까치 `magpie_choose`/`magpie_perched` (전부 실재).<br>**범위 추가**: `TigerGreetClip`(tiger_video.dart:313) + **SFX 336행** — `sfx/tiger_greet.mp3`가 하드코딩돼 있고 **까치용 SFX가 없다**(§9 Q3) |
| **P1-3** | 홈 상단바 4개 → 2개(스트릭 + 설정), 48dp. 워드마크 겹침 동시 해결 |
| **P1-4** | §5.3의 **①분류 12곳만** 교체. ②③은 유지 |
| **P1-5** | 캐릭터가 바꾸는 것 — **v1에서 축소**(§6.1) |
| **P1-6** | 검증: `CharacterClips.stageFor(kind)`를 **순수 함수로 분리해 단위 테스트**. v1의 "홈에 tiger_ 문자열 0" 위젯 테스트는 **무의미하다** — 테스트 환경에서 `videoReady=false`라 영상 경로를 아예 안 탄다(검수 D5) |

#### 6.1 캐릭터가 바꾸는 것 — 6개 → **4개로 축소**

제품 검수가 2개를 반박했고 수용합니다.

| 항목 | v1 | v2 | 사유 |
|---|:--:|:--:|---|
| 액센트 색 | ✅ | ✅ | 호랑이 `tigerOnLight` / 까치 `highlight #5A7BA0` (둘 다 기존 토큰) |
| 1일차 인사 | ✅ | ✅ | |
| 재방문 인사 | ✅ | ✅ | |
| CTA 문구 | ✅ | ✅ | |
| **다음 행동 추천(타일 순서)** | ✅ | ❌ **제거** | 목업 스스로 "레이아웃은 캐릭터가 안 바꾼다"고 못 박았는데 정면충돌. 복습이 시급해도 호랑이는 "새 레슨 먼저"를 미는 모순. → **타일 순서 고정, 같은 추천을 다른 어조로만** |
| **일일 목표 기본값 45/30 XP** | ✅ | ❌ **제거** | 학습 강도를 "어떤 동물이 좋은가"에 묶는 건 결정권이 잘못된 화면에 있다. 달성률 지표가 캐릭터 선택 비율에 오염된다. → **목표는 레벨 선택 화면이 정한다** |

### Phase 0b — 카드 경계 + 1일차 인사 (1.5일, P1 뒤)

| ID | 작업 |
|---|---|
| **0b-1** | **`SoriColors.lightSurfaceRaised = #FFFDF8` 신규 토큰 1개** 추가 → 카드 채움. `lightBorderStrong` 위에서 **3.27:1**(현재 2.81 미달) |
| **0b-2** | `card.dart:130,141` 테두리 `width: 1` → `1.5`, 색 `lightBorderStrong`.<br>⚠️ **`accent != null` 분기(1.19~1.51:1)는 별도 처방 필요** — 여기를 덮으면 카드별 색 코딩(primary/tiger/gold/danger)이 통째로 사라진다. alpha 0.25→0.55 상향 검토 |
| **0b-3** | **1일차 인사 — v1 진단 폐기.** ARB 키 신설 불필요. `home_screen.dart:701`의 `if (Storage.streakDays == 0)` → `if (streakDays == 0 && Storage.xp > 0)` 로 변경. `learner_motivation.dart:83`은 이미 정상 |
| **0b-4** | 다크모드 `darkBorder` 1.43:1 (§4.3) — 라이트와 같은 처방 |

> **회귀면 경고**: `SoriCard`는 **34개 파일**에서 쓰입니다. Phase 0b는 홈 전용 작업이 아니며 실기기 라이트/다크 확인이 필요합니다.

### Phase 2 — 홈 정보 위계 (4.5일)

**선행 조건**: `home_screen.dart`는 **2135줄**이고 이를 커버하는 테스트가 **2개**(`screen_smoke_test`, `responsive_test`)뿐입니다. 골든/스모크 테스트 확충 없이 착수하면 무보호 리팩터링입니다.

#### 6.2 5블록 — v1 매핑 정정

v1 표에서 **프리미엄 "맞춤 일일 코스"(`_CourseCard`)가 언급 없이 빠져 있었습니다**(제품 검수 지적). 1인 개발 앱에서 수익화 화면이 조용히 사라지는 건 매핑 자체의 결함입니다.

| 순 | 블록 | 흡수하는 현재 요소 |
|---|---|---|
| 1 | 인사 + 캐릭터 | `_TigerHero` (+캐릭터 분기) |
| 2 | **이어서 배우기** (단일 CTA) | 주 CTA + `_TodayScenarioCard` + Lernpfad 링크 |
| 3 | 오늘 할 일 *(있을 때만)* | `_ReviewCard` + `_DailyCharCard` + hard words |
| 4 | 나의 걸음 | `_StatChipRow` + `_DailyGoalCard` |
| 5 | **맞춤 코스** *(프리미엄)* ★ | **`_CourseCard`** — v1 누락. 거취 결정 필요(§9 Q1) |
| 6 | 배움의 마당 | 모듈 그리드 |

> **착수 전 현재 홈 위젯을 100% 커버리지로 재매핑**하고, 각 항목에 유지/이동/삭제를 명시할 것.

#### 6.3 마당 6칸 — v1 정정

| 목업안 | v1 | v2 | 사유 |
|---|---|---|---|
| Hangeul | Hangeul | **Hangeul** `/hangul` | A0는 문자가 먼저 |
| Aussprache(마이크) | Hören | **Wortschatz** `/vocab` | 마이크 기능 없음 확인(STT 패키지 0, `RECORD_AUDIO` 권한 0, CF는 문법분석) |
| Wortschatz | Wortschatz | **Wiederholen** `/review` | |
| Wiederholen | Wiederholen | **Szenarien** `/scenarios` | 콘텐츠 233KB |
| Hören | Szenarien | **Hören** `/listening` | |
| Kultur | ~~Spiele~~ | **Quests** `/quests` | **v1의 Spiele는 하단 탭 #2와 중복** — v1이 §4.4에서 "헤더-탭 중복은 SC 3.2.3 위반"이라 지적한 죄를 스스로 저질렀다(검수 C8) |

**문화(Kultur) — 제품 검수 반박 수용**: 독일어권 학습자에게 존댓말·격식은 한국어가 유럽어와 가장 다른 지점이자 일반 어휘 앱과의 차별점입니다. 완전 삭제 대신 `culture_notes.json`(9KB) 기반으로 **Wiederholen 안 라벨 또는 "곧 출시" 타일**로 흡수하는 안을 검토합니다(§9 Q6).

#### 6.4 디딤돌 ↔ 게이지 전환 — 기준 변경

v1: "1~7일차 디딤돌 / 8일차~ 게이지" → **제품 검수 반박 수용.**
가입 후 경과일 기준이면, 며칠 쉬고 8일째 돌아온 사용자가 스트릭 0·XP 낮은 채로 게이지를 보게 됩니다 — 목업 진단 #4("너는 아무것도 안 했다")의 8일차 재현입니다.

→ **전환 기준을 스트릭으로 통일.** 스트릭이 끊기면 가입일과 무관하게 디딤돌형으로 되돌립니다.

---

## 7. 핸드오프 스펙 (정정)

### 7.1 토큰

| 토큰 | 값 | 용도 | 상태 |
|---|---|---|---|
| `SoriColors.tigerOnLight` | `#A8490B` | **주 CTA 채움** + 호랑이 액센트 텍스트 | 기존 |
| `SoriColors.tiger` | `#FF8C42` | 마스코트 장식 채움 **only**. **흰 텍스트 금지(lint 고정)** | 기존 |
| `SoriColors.highlight` | `#5A7BA0` | 까치 액센트 | 기존 |
| `SoriColors.lightBorderStrong` | `#978C73` | 카드 테두리 **1.5px** | 기존 |
| `SoriColors.lightTextMuted` | `#5C6660` | 보조 텍스트 하한 | 기존 |
| **`SoriColors.lightSurfaceRaised`** | **`#FFFDF8`** | **카드 채움** (테두리 3.27:1 확보) | **신규 1개** |

**신규 토큰 1개** (v1은 "0개"라고 썼으나 테두리 대비를 못 채움 — §1 오류 10).

### 7.2 컴포넌트 — v1 정정

| 컴포넌트 | v1 스펙 | 실제 | 조치 |
|---|---|---|---|
| `SoriButton.filled` | "높이 56dp, 라벨 19sp/w800" | **`lg` = 높이 52 / 폰트 16. height·fontSize prop 자체가 없음** | 크기를 바꾸려면 `button.dart` 수정 — 앱 전역 영향 |
| `SoriCard` | "border 1.5px" | **`width: 1` 하드코딩** (`card.dart:130,141`) | 0b-2에서 처리 |
| `MadangTile` | `minHeight: 112` | 신규 | 고정 높이 금지 |
| `ContinueLessonCard` | 신규 | — | 블록 2 |
| `SteppingStonesRow` | 신규 | — | 블록 4, **스트릭 기준** |
| `CharacterStageBand` | `TigerStageVideo` 개명 | — | P1-2 |

### 7.3 엣지 케이스

| 요소 | 상태 | 동작 |
|---|---|---|
| 블록 3 | 복습 0 · 어려운 단어 0 | **블록 숨김** (빈 카드 금지) |
| 블록 4 | 스트릭 0 | 디딤돌형 (가입일 무관) |
| 캐릭터 밴드 | `!videoReady \|\| reduceMotion \|\| init 실패` | 정적 `Mascot(kind)` — **이미 구현됨** |
| **웰컴 영상** | **기존 사용자 업데이트** | **스트릭/XP > 0이면 "이미 봄"으로 마이그레이션.** 안 하면 몇 주 쓴 사용자가 "기다리고 있었어" 온보딩 영상을 본다(제품 검수 지적) |
| 모든 텍스트 | 시스템 글꼴 200% | `maxLines:1 + ellipsis` 홈 7곳 검증 |

---

## 8. 하지 말 것

1. ❌ 에셋요청서 2·5·6번 생성 — 이미 있음. 덮으면 "캐논 호랑이" 손실
2. ❌ 목업 팔레트 클래스 신설 — 단, `lightSurfaceRaised` **1개는 추가**(§7.1)
3. ❌ `{character}_{state}` 파일명 리팩터 — `CharacterClips`가 이미 그 역할
4. ❌ `MascotKind.tiger` **일괄 치환** — 승패 연출 9곳 파괴(§5.3)
5. ❌ `EavesCorner`를 죽은 코드로 알고 손대기 — **SoriCard 전체가 의존**
6. ❌ Phase 2를 Phase 1보다 먼저
7. ❌ **Phase 0b를 Phase 1보다 먼저** — 앱 전역 회귀면이 크다
8. ❌ **git 브랜치 없이 착수** — 병렬 세션이 같은 레포를 편집 중이고 `git status`에 수백 파일이 M 상태다. 롤백 지점이 없다
9. ❌ **Remote Config 킬스위치를 믿기** — `palette_variant`는 `SoriColors ↔ SoriColorsTeal` 전환만 한다. Phase 0의 하드코딩 참조 변경은 **원격 롤백 불가**, 앱 업데이트가 유일한 되돌리기

---

## 9. 사용자 결정이 필요한 항목

| Q | 질문 | 왜 물어야 하나 |
|---|---|---|
| **Q1** | **프리미엄 "맞춤 일일 코스"를 새 홈 어디에 둘 것인가, 아니면 이번에 뺄 것인가?** | v1 매핑에서 언급 없이 누락됨. 수익화 화면이라 임의 결정 불가 |
| **Q2** | **캐릭터를 설정에서 나중에 바꿀 수 있게 할 것인가?** | 현재 진입점 0개. 안 만들면 P1 검증 자체가 불가 |
| **Q3** | **까치용 인사 SFX를 만들 것인가?** | `sfx/`에 `tiger_greet.mp3` 하나뿐. P1-2 후 까치 사용자가 호랑이 소리를 듣거나 무음 |
| **Q4** | **2MB 초과 PNG를 다운스케일해도 되는가?** (2508 → 1254) | "캐논 호랑이" 파일 포함. 112MB 회수의 핵심이지만 임의로 안 함 |
| **Q5** | **한옥 마당 가로 정경(1024×768)이 따로 필요한가?** | 기존 `hanok_stages/`는 841×1870 세로 건물 진행. 용도가 다를 수 있음 |
| **Q6** | **문화(Kultur)를 마당에 넣을 것인가?** | 독일어권에 존댓말은 차별점. `culture_notes.json`은 있으나 전용 화면 없음 |
| **Q7** | **`tiger_roar_seated_bonus.mp4`를 복구할 수 있는가?** | 없으면 신기록 전용 연출을 영구 포기하고 `tigerCelebrateHifive`로 매핑 |

---

## 10. 검증 체크리스트 (정정)

**Phase A**
- [ ] `du -sh assets/` — 착수 전/후 기록
- [ ] `stickers/`↔`mascot/` 중복 7개 해소
- [ ] `assets/` 하위 비-미디어 파일 0 (테스트로 고정)

**Phase 0a**
- [ ] CTA 채움 ≥3:1, 라벨 ≥4.5:1 — 실측 기록
- [ ] `tiger` 채움 + 흰 텍스트 조합을 **lint/테스트로 금지**

**Phase 1**
- [ ] 설정 → 캐릭터 변경 진입 가능 (**선행**)
- [ ] `CharacterClips.stageFor(kind)` **단위 테스트** 통과 (위젯 테스트 아님)
- [ ] §5.3 **①분류 12곳** 리터럴 0 — ②③은 잔존이 정상
- [ ] 승패 연출 9곳이 여전히 승/패로 캐릭터를 바꾸는지 회귀 확인
- [ ] 까치 선택 → 홈/게임결과/레슨완료 스크린샷 대조

**Phase 0b**
- [ ] `SoriCard` 사용 34개 파일 시각 회귀 — 라이트 **+ 다크**
- [ ] `accent != null` 분기의 색 코딩이 살아 있는가
- [ ] 신규 사용자(streak 0, xp 0)에게 "Willkommen zurück!" 안 뜸

**Phase 2**
- [ ] 착수 **전** 홈 골든/스모크 테스트 확충 (현재 2개)
- [ ] 블록 단위 5커밋으로 분할, 커밋마다 스모크 통과 게이트
- [ ] 홈에서 인자 없는 중복 진입 0 — **`/vocab/pack` 3개는 서로 다른 팩을 연다. 무조건 1개로 줄이면 기능이 사라진다**
- [ ] 시스템 글꼴 200%에서 잘림 0
- [ ] 마당 6칸 전부 실재 라우트 + **하단 탭과 비중복**

**Phase 3**
- [ ] **`test/data_integrity_test.dart:193`의 `$` 스킵을 수정**해 `'$_base/...'` 보간 자산도 검사. `tiger_roar_seated_bonus` 누락이 여기서 안 잡혔다 — 수동 체크리스트보다 싸고 영구적

---

*근거: 2026-07-31 전량 스캔 + 독립 검수 2건(opus5 사실검증 62툴콜 / sonnet 제품판단). 병렬 세션이 같은 레포를 편집 중이므로 착수 전 §10을 재확인할 것.*
