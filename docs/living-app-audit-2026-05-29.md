# Living App Audit — Hangul Sori (2026-05-29)

> 진단·개선안·필요 자산·이미지 프롬프트. screens/ + assets/ 전수 cross-check 결과.

---

## 1. 한 줄 진단

**"분위기는 살아있는데, 사용자가 한 번 들어와서 다시 오게 만드는 retention 후크가 약하다."**

- 화면 자체의 톤·모션은 이미 Duolingo급 (Ken Burns 배경, ambient 입자, 비행 까치, 마스코트 11종, SoriCelebration burst, MascotPop).
- 부족한 건 **(a) "다음 한 발"의 시각화** (lesson path 부재), **(b) 마스코트의 상시 페르소나** (홈에서 호랑이가 안 보임), **(c) 보상 시퀀스의 단계** (정답→burst 1초 → 끝), **(d) 앱 밖 retention** (로컬 푸시·사운드 없음).

---

## 2. 현재 "이미 살아있는" 부분 (보존 대상)

| 항목 | 위치 | 강점 |
|---|---|---|
| 솟을대문 인트로 | `intro_gate_screen.dart` | 3s 시네마틱 + gate_final 풍경 + parallax push-in |
| 홈 배경 호흡 | `home_screen.dart` + `SoriKenBurns` | madang(light/dark) 느린 줌 |
| Ambient 입자 | `ambient_particles.dart` | 매화/불씨 13입자 무한 루프 |
| 비행 까치 | `flying_magpie.dart` | 상단 가로지름 |
| 마스코트 11종 | `assets/illustrations/mascot/` | 7 emotion × 2 종, idle blink/breathing |
| Celebration burst | `celebration.dart` | 단청 4색 별/다이아 30입자 |
| MascotPop | `mascot_pop.dart` | elasticOut 정답 마스코트 |
| 햅틱 | `SoriPressable` + `SoriHaptic` | 모든 카드/칩에 적용 |
| Streak + freeze | `storage_service.dart` + `_StreakHero` | shield 개수 stats에 표시 |
| SRS due-aware vocab | `vocab_screen.dart` | due 완료 시 `celebrate_complete.png` |
| Stagger entrance | `SoriEntrance` | 카드 60ms/160ms/260ms 지연 |
| Reduce-motion 대응 | `SoriMotion.reduceMotion` | 4개 모션 위젯 fallback |

→ **이건 절대 건드리지 말 것.** 듀오링고도 이 수준의 ambient는 없다.

---

## 3. Duolingo 대비 "비어 있는 곳" (Gap Analysis)

### 🔴 P0 — 출시 직후 코드만으로 가능

#### G1. 홈에 마스코트가 안 보인다
**현재**: `_Header`는 로고+텍스트 + 통계+CTA. 호랑이는 시나리오 hero 카드의 작은 sidekick으로만 등장.
**문제**: Duo의 핵심은 "캐릭터가 항상 사용자에게 말 거는 것". 우리 호랑이는 홈에서 사실상 부재.
**개선**: `_StatsPeek` 옆 또는 상단에 **호랑이 idle (96px)** + **말풍선 (오늘의 한국어 한 마디 / streak 격려 / "5분만 해볼까?")**. 시간대·streak·last seen 기준으로 말풍선 텍스트 rotate.
**이미지 필요**: ❌ (기존 tiger_idle/smile + 새 말풍선 위젯)

#### G2. "오늘 할 일"의 시각적 한 줄 (lesson path) 부재
**현재**: Heute 카드 1장 + 모듈 2×2 grid. 진척이 시각적으로 "선"으로 안 보인다.
**문제**: Duo의 skill tree는 "다음 노드"의 욕구를 만든다. 우리는 다음에 뭘 해야 하는지 직관적이지 않다.
**개선**: 홈 중간에 **수평 스크롤 lesson path** — 한옥 길 위에 5개 노드(완료=초록 깃발 / 현재=호랑이 발자국 / 잠금=먹색 자물쇠). 각 노드 = 시나리오 1개. CEFR 레벨별 chapter 구분.
**이미지 필요**: ✅ `lesson_path_road.png` (수평 길 배경 with 단청 디테일) + 노드 상태 아이콘 3종.

#### G3. 결과 화면의 보상 시퀀스가 단발적
**현재**: 시나리오 완료 → `SoriCelebration.burst` 1회 + XP/streak 카드.
**문제**: Duo는 chest open → gem rain → XP bar fill → league bump 4단 시퀀스.
**개선**: 결과 화면을 **3단 sequence**로 재구성:
  1. **호랑이 + 까치 함께 박수** (animate=true, 1.5s)
  2. **XP bar fill 애니메이션** (현재 → 다음 레벨, 카운트업)
  3. **편지를 무는 까치** 한 컷 — "오늘 +X XP · streak +1일"
**이미지 필요**: ✅ `magpie_letter.png` (편지 봉투를 부리에 문 까치, 정면) — 결과 화면의 "전령" 모먼트.

#### G4. Streak shield가 stats에만 있다
**현재**: `_StreakHero`에 shield 개수가 표시되지만 **stats 화면에만**. 홈에서는 안 보임.
**문제**: 사용자가 freeze 보유를 모르면 깨졌을 때 "다행" 모먼트가 사라진다.
**개선**: 홈 `_StatsPeek`의 streak 옆에 **shield mini chip** (방패 아이콘 + 개수). 0개면 hide, 1개 이상이면 표시. 깨졌다가 freeze로 살았으면 호랑이 wink + "방패가 막아줬어요!" 토스트.
**이미지 필요**: ❌ (Material 방패 아이콘 + 단청색)

#### G5. 모듈 카드가 정적
**현재**: `_MiniModuleCard`는 press 시만 SoriPressable 반응.
**문제**: 가만히 있을 때 카드가 "죽어있어 보임".
**개선**: 각 카드 우상단에 미니 idle 상태 ribbon:
  - 새 콘텐츠: "NEU" 단청 깃발 (1주 이내 추가된 시나리오 모듈)
  - 진척 중: 작은 progress arc (얼마나 완료했는지)
  - 오늘 due: 호랑이 작은 발자국 + "3개"
**이미지 필요**: ❌ (Flutter painter)

#### G6. 로딩 화면이 단순 spinner
**현재**: `AppLoading`은 일반 Material spinner.
**개선**: `tiger_thinking.png` + 작은 한지 도트 점멸 → "호랑이가 책을 찾고 있어요" 느낌.
**이미지 필요**: ❌ (기존 tiger_thinking 활용)

#### G7. 0 streak에 대한 회복 메시지 없음
**현재**: streak 0 = 그냥 0 표시.
**개선**: streak == 0 && lastActive >= 어제 → 호랑이 sad PNG + 말풍선 "다시 시작해볼까요?" → 1분 챌린지 CTA.
**이미지 필요**: ❌ (기존 tiger_sad 활용)

### 🟡 P1 — 1-2주 (이미지 의존)

#### G8. Onboarding 직후 "환영" 모먼트 부재
**현재**: 인트로 → 레벨 선택 → 바로 홈.
**개선**: 레벨 선택 직후 1회만 등장하는 **"한옥 마당에서 호랑이가 인사"** full-screen 한 컷 (3s). 까치가 위에서 날아와 함께 인사 → "환영합니다, 1단계부터 시작해요!".
**이미지 필요**: ✅ `welcome_first_day.png` (마당에 호랑이가 손 흔드는 단일 풍경 — welcome-hero.png와 다른 구도, full bleed).

#### G9. 일일 streak 캘린더 (heatmap)
**현재**: Stats에 streak 숫자만 (best · current · shields). 7일 grid 없음.
**개선**: `_StreakHero` 아래에 **7일 dots row** (월~일, 오늘은 호랑이 발자국, 완료는 초록 점, 미완료는 회색, freeze로 살린 날은 방패).
**이미지 필요**: ❌ (Material 아이콘)

#### G10. 모듈별 hero PNG가 일부 비어있음
**현재**: Vocab=`study_classroom.png` (있음), Grammar=`study_scholar.png` (있음), Hangul/Chosung/Wordle은 madang/porch 재사용.
**개선**: Hangul 전용 hero `hangul_calligraphy_table.png` + Chosung 전용 `chosung_drum.png`.
**이미지 필요**: ✅ 2장.

#### G11. 마스코트 신규 포즈 — "응원" / "책 읽음" / "박수"
**현재**: 7 emotion (neutral/smile/celebrate/sad/sleepy/thinking/surprised + happy/blink).
**부족**:
- `tiger_cheering.png` — 응원 깃발 들고 신난 호랑이 (lesson path 진행 노드용)
- `tiger_reading.png` — 책을 펴고 읽는 호랑이 (로딩·empty용)
- `magpie_flag.png` — 단청 깃발을 발에 잡은 까치 (new content marker용)
- `magpie_letter.png` — 편지를 문 까치 (G3 결과 화면용, 위와 동일)

**이미지 필요**: ✅ 4장 (magpie_letter 포함).

### 🟢 P2 — 생태계 확장 (앱 밖 retention)

#### G12. 로컬 푸시 (streak warning, daily 챌린지)
- pubspec에 `flutter_local_notifications` 추가.
- 매일 20:00 streak 미완료 시 "호랑이가 기다려요! 5분이면 충분해요" — `tiger_sleepy` 아이콘.
- 푸시 아이콘용 단색 PNG 1장 (`notif_tiger_glyph.png`, 96×96 흰색 silhouette).

#### G13. SFX (정답 ding, level up 가야금)
- pubspec에 `just_audio` 추가.
- 5종 짧은 효과음 (정답·오답·level up·streak·page swoosh). 한국 전통 악기 톤 (가야금·해금 short pluck).
- 사운드는 외주/freesound. 이미지 불필요.

#### G14. 시즌별 마당 변화
- madang(light/dark) → 봄(매화)/여름(연잎)/가을(단풍)/겨울(눈) 4 variant.
- 시스템 날짜 기준 자동 전환 → "앱이 계절을 안다" → 다시 오게 만드는 깊은 후크.
- **이미지 필요**: ✅ `madang(light)_spring/summer/autumn/winter.png` × 4 + dark 4 = 8장 (큰 작업, 1.5단계 후보).

---

## 4. 우선순위별 실행 roadmap

| 우선 | 작업 | 이미지 필요 | 추정 |
|---|---|---|---|
| **P0-1** | G1 홈 상단 호랑이 + 말풍선 | ❌ | 0.5d 코드 |
| **P0-2** | G4 홈에 streak shield chip | ❌ | 0.5d 코드 |
| **P0-3** | G3 결과 화면 3단 시퀀스 (G3-1, G3-2만) | ❌ | 1d 코드 |
| **P0-4** | G5 모듈 카드 mini ribbon | ❌ | 0.5d 코드 |
| **P0-5** | G6 로딩 → tiger_thinking + dots | ❌ | 0.2d 코드 |
| **P0-6** | G7 streak 0 회복 카드 | ❌ | 0.3d 코드 |
| **P1-1** | G2 lesson path (수평 스크롤 길) | ✅ 1장 + painter | 2-3d 코드 + Jin |
| **P1-2** | G8 첫날 환영 모달 | ✅ 1장 | 0.5d 코드 + Jin |
| **P1-3** | G3-3 까치 편지 한 컷 | ✅ 1장 | 0.5d 코드 + Jin |
| **P1-4** | G9 streak 7일 heatmap | ❌ | 0.5d 코드 |
| **P1-5** | G10 모듈 hero 보강 | ✅ 2장 | 0.5d 코드 + Jin |
| **P1-6** | G11 마스코트 신규 포즈 | ✅ 4장 | 0.5d 코드 + Jin |
| **P2-1** | G12 로컬 푸시 | ✅ 1장 (notif glyph) | 1d 코드 |
| **P2-2** | G13 SFX | ❌ (오디오 5종) | 1d 코드 + 사운드 |
| **P2-3** | G14 시즌별 마당 | ✅ 8장 | 2d 코드 + Jin (대작업) |

**총 신규 이미지: 18장** (lesson path 1 + welcome 1 + magpie letter 1 + hero 2 + 마스코트 4 + notif 1 + 시즌 8)

---

## 5. 이미지 프롬프트 (Faceted Minhwa, ready-to-paste)

> **공통**: 모든 프롬프트에 reference로 첨부 → `assets/illustrations/mascot/tiger_idle.png` (1번) + `assets/illustrations/hanok/madang(light).png` (2번).
> 스타일가이드: `~/Downloads/HANGUL_SORI_STYLE_GUIDE.md` ("Faceted Minhwa / 모던 면 분할 민화").
> 모든 출력: PNG-24, 알파 채널, 배경 투명(명시된 경우 외).

### Prompt #1 — `lesson_path_road.png` (P1-1, lesson path 배경)
- **경로**: `assets/illustrations/hanok/lesson_path_road.png`
- **크기**: 2048 × 640 (수평 스크롤 배경)
- **배경**: 투명 (한지 cream `#FAF6EC` 영역 + 길만)

```
A wide horizontal Faceted Minhwa illustration of a winding stone path through a Korean hanok village. Style: flat faceted color planes, no outlines, subtle hanji paper grain texture. Restricted palette: hanji cream #FAF6EC, celadon #1F7A6B, dancheong red #C24A45, dancheong gold #DFA951, walnut #8E6646, ink #2C2419.

Composition: a meandering paved stone path snakes from left to right across the canvas with five evenly spaced flat circular paving stones at roughly equal intervals — these will become lesson node anchors (do not draw the nodes themselves, only the path). Along the path: small flat hanok rooftop silhouettes in celadon and walnut on either side, two flat pine trees with simple triangular foliage, three flat lotus pond stones, and one small dancheong-colored stone lantern. Distant mountain silhouette layer in muted celadon at the top edge.

Style notes: editorial geometric minhwa, mid-century reduction, no people, no text, no gradients inside shapes, no outlines around shapes. Background fully transparent so the path floats on app's hanji cream. Strong silhouettes for clarity at small sizes. Match attached references exactly for color and brush feel.
```

### Prompt #2 — `welcome_first_day.png` (P1-2, 첫 환영)
- **경로**: `assets/illustrations/hanok/welcome_first_day.png`
- **크기**: 1080 × 1920 (모달 full bleed, 9:16)
- **배경**: 한지 cream `#FAF6EC` 채움

```
A full-bleed portrait Faceted Minhwa illustration for an onboarding welcome screen. A friendly Korean tiger character stands in the center-bottom of a hanok madang courtyard, waving one paw in greeting. A magpie wearing a small black gat scholar hat flies in from the upper right, wings spread, looking toward the tiger. Above them, a banner of dancheong-painted ribbon arches across the upper third with five floating flat dancheong dots (red, green, gold, white, black).

Setting details: clean hanji cream background #FAF6EC, two simple flat hanok rooftop silhouettes in celadon at the very bottom edges (left and right), three small abstract pink plum blossoms floating in the upper-left negative space, one large pale celadon mountain silhouette in the far background.

Style: flat faceted planes, no outlines, restricted palette (hanji cream #FAF6EC, tiger orange #FF8C42, celadon #1F7A6B, dancheong red #C24A45, dancheong gold #DFA951, ink #2C2419), subtle hanji paper grain overlay. Mid-century geometric reduction meets Korean minhwa. No text, no photorealism. Tiger and magpie must match the visual style of the attached reference exactly.
```

### Prompt #3 — `magpie_letter.png` (P1-3, 까치 편지)
- **경로**: `assets/illustrations/mascot/magpie_letter.png`
- **크기**: 768 × 768 투명

```
A square Faceted Minhwa character illustration of a magpie wearing a small black gat (Korean scholar hat). The magpie is in flight pose, wings spread, carrying in its beak a small folded paper letter with a red dancheong wax seal. Body facing 3/4 toward viewer, looking warmly at the camera. White belly, black wings and head, small dancheong-red beak, orange feet tucked.

Style: flat faceted color planes, no outlines, hanji paper grain overlay subtle, restricted palette (ink #2C2419, hanji cream #FAF6EC for paper, dancheong red #C24A45 for seal, dancheong gold #DFA951 for highlights, gat charcoal #4B3621). Mid-century Korean minhwa reduction. Background fully transparent. Match the visual identity of attached magpie references exactly — same proportions, same gat, same beak shape.
```

### Prompt #4 — `hangul_calligraphy_table.png` (P1-5, Hangul hero)
- **경로**: `assets/illustrations/hanok/hangul_calligraphy_table.png`
- **크기**: 1536 × 512 (10:3 banner)
- **배경**: 투명 (8% opacity backdrop용)

```
A wide horizontal Faceted Minhwa banner showing a Korean calligraphy desk inside a hanok. Composition: left third — a flat black inkstone (벼루) with a single brush resting across it; center — three folded hanji paper sheets stacked diagonally with one large faceted Hangul character "한" rendered in bold ink as if hand-painted; right third — a celadon water dropper bottle and a small folded seal box in dancheong red.

Style: flat faceted color planes, no outlines, hanji paper grain overlay, restricted palette (hanji cream #FAF6EC, ink #2C2419, celadon #1F7A6B, dancheong red #C24A45, dancheong gold #DFA951, walnut #8E6646). Strong silhouettes for legibility at 8% opacity. Mid-century minhwa reduction. No people, no text other than the single "한" character. Match attached references exactly.
```

### Prompt #5 — `chosung_drum.png` (P1-5, Chosung hero)
- **경로**: `assets/illustrations/hanok/chosung_drum.png`
- **크기**: 1536 × 512 투명

```
A wide horizontal Faceted Minhwa banner featuring a traditional Korean janggu drum and small bamboo strike. Composition: center-left — a flat janggu drum (hourglass shape) in walnut wood with celadon and dancheong-red rope tension lines, two flat bamboo drumsticks crossed beside it; right third — three faceted Hangul consonants "ㄱ ㄴ ㄷ" floating like notes, each in a different dancheong color (red, gold, celadon).

Style: flat faceted color planes, no outlines, hanji grain overlay, restricted palette (hanji cream #FAF6EC, walnut #8E6646, celadon #1F7A6B, dancheong red #C24A45, dancheong gold #DFA951, ink #2C2419). Strong silhouettes for 8% opacity backdrop. No people, no text, no photorealism. Match attached references exactly.
```

### Prompt #6 — `mascot/tiger_cheering.png` (P1-6, 응원 호랑이)
- **경로**: `assets/illustrations/mascot/tiger_cheering.png`
- **크기**: 768 × 768 투명

```
A square Faceted Minhwa illustration of the Hangul Sori tiger character holding a small dancheong-colored celebratory flag in one paw, raised high. Body in same proportions and pose family as the attached tiger references (tiger_celebrate.png), but slightly more dynamic — one foot lifted as if stepping forward in a victory pose. Mouth open in a wide friendly cheer, two small starbursts in dancheong gold near the head.

Style: flat faceted color planes, no outlines, hanji grain overlay subtle, palette identical to existing mascot set (tiger orange #FF8C42, cream belly #FAF6EC, ink stripes #2C2419, dancheong red flag #C24A45 with gold #DFA951 trim). Transparent background. Critical: tiger anatomy, face proportions, eye style, and stripe pattern must match the attached tiger_idle / tiger_celebrate references exactly so the character reads as the same individual.
```

### Prompt #7 — `mascot/tiger_reading.png` (P1-6, 책 읽는 호랑이)
- **경로**: `assets/illustrations/mascot/tiger_reading.png`
- **크기**: 768 × 768 투명

```
A square Faceted Minhwa illustration of the Hangul Sori tiger character sitting cross-legged on the floor reading a small open hanji book held in both front paws. Head tilted slightly down, eyes soft and focused on the page, gentle Mona-Lisa half-smile. The book shows a tiny faceted Hangul character "가" on the visible page.

Same anatomy, face, stripes, palette as the attached tiger_idle reference (tiger orange #FF8C42, cream belly #FAF6EC, ink stripes #2C2419, hanji book in cream #FAF6EC with ink #2C2419 character). Flat faceted color planes, no outlines, hanji grain overlay subtle, transparent background. Critical: must read as the same tiger character.
```

### Prompt #8 — `mascot/magpie_flag.png` (P1-6, 깃발 까치)
- **경로**: `assets/illustrations/mascot/magpie_flag.png`
- **크기**: 512 × 512 투명

```
A square Faceted Minhwa illustration of a magpie wearing a small black gat scholar hat, perched on a flat horizontal branch, holding in its talons a small dancheong-painted flag (red and gold stripes) that flutters to the right. Wings folded against the body, head turned 3/4 toward viewer with a proud cheerful expression.

Same proportions, beak shape, gat, body palette as attached magpie references (ink black wings/head #2C2419, cream belly #FAF6EC, dancheong red beak #C24A45, gat charcoal #4B3621, orange feet #FF8C42). Flat faceted planes, no outlines, hanji grain overlay subtle, transparent background. Critical: must read as the same magpie individual as references.
```

### Prompt #9 — `mascot/magpie_letter.png` (이미 #3에 작성)
→ Prompt #3 참조.

### Prompt #10 — `notif_tiger_glyph.png` (P2-1, 푸시 아이콘)
- **경로**: `android/app/src/main/res/drawable/notif_tiger_glyph.png` (Android 푸시 small icon)
- **크기**: 96 × 96 흰색 silhouette, 투명 배경

```
A 96x96 px single-color white silhouette of a friendly Korean tiger head, front-facing, with rounded ears and stylized stripe shapes simplified to thick white strokes. Optimized for Android notification small-icon: pure white on transparent background, no anti-aliased gray, strong negative space, readable at 24x24 px scale.

Style: extreme reduction — Faceted Minhwa silhouette translated to a single-tone glyph. No color, no gradients, only solid white shapes and transparent gaps. Reference the attached tiger_idle.png for face proportions and ear placement but reduce to silhouette + 2 inner negative-space stripes only.
```

### Prompt #11–18 — `madang(light)_spring/summer/autumn/winter.png` + `madang(dark)_*.png` (P2-3, 시즌)
- **경로**: `assets/illustrations/hanok/madang(light)_spring.png` 등 8장
- **크기**: 1080 × 1920 (현재 madang과 동일 비율, 같은 카메라 좌표계 유지)

각 시즌 differential 요소만 다르고 **마당 구도·카메라·한옥 위치는 완전 동일**해야 함 (Ken Burns 줌 적용 시 부드러운 전환):

| 시즌 | Light variant 추가 요소 | Dark variant 추가 요소 |
|---|---|---|
| **Spring** | 매화 꽃잎, 연두색 잎, 분홍 꽃봉오리 | 보름달 + 매화 실루엣 + 매화 꽃잎 입자 |
| **Summer** | 짙은 녹음, 연잎(작은 연못 추가), 매미 silhouette 1개 | 반딧불 (입자처럼) + 깊은 청록 |
| **Autumn** | 단풍나무 (빨강·황금), 낙엽 4-5장 | 단풍 silhouette + 보름달 + 따뜻한 호박색 |
| **Winter** | 눈 덮인 기와, 매화 가지 위 잔설, 회청색 톤 | 눈 + 청록 야간 + 작은 따뜻한 창문 빛 |

```
Use the attached existing madang(light).png as the EXACT compositional base. Reproduce the same hanok layout, same yard geometry, same horizon line, same camera angle. Only modify seasonal flora and atmospheric color temperature as follows: [insert season-specific bullet from table above].

Style: flat faceted Minhwa planes, no outlines, hanji grain overlay subtle, restricted palette (hanji cream #FAF6EC, celadon #1F7A6B, dancheong red #C24A45, dancheong gold #DFA951, walnut #8E6646, ink #2C2419) plus season accents — Spring: pale pink #F8C8D8, soft green #B6D7A8 — Summer: deep teal #14746F, lotus pink #FFB6C1 — Autumn: maple red #C0392B, amber #E0A458 — Winter: snow #F4F4F4, cold gray-blue #B0BEC5.

Critical: composition and camera must match the reference exactly so the app can swap variants without code changes.
```

→ Dark variants는 위 프롬프트의 base를 `madang(dark).png`로 바꾸고 night palette (ink bg #0E1A18, moon cream #FAF6EC, dim celadon #2D5A52) 적용.

---

## 6. 다음 액션 (Jin과 합의해 우선순위 결정)

**Option A — Lean P0 (3-4일, 이미지 0장)**
G1·G4·G5·G6·G7 → 출시 직후 patch v1.0.2로 release. "홈에서 호랑이가 인사한다" + "shield 보임" + "로딩이 살아있다" → 즉시 retention 상승 예상.

**Option B — Full P0 + P1-3 magpie letter (1주, 이미지 1장)**
A + G3 결과 시퀀스 3단 (magpie_letter.png 제작 필요). "정답 후 보상 폭포" → Duolingo의 핵심 도파민 루프 추가.

**Option C — Full P1 (2-3주, 이미지 8장 + lesson path painter 큰 작업)**
B + G2 lesson path + G8 환영 + G9 heatmap + G10 hero 보강 + G11 마스코트 4종. **앱의 정체성이 한 단계 점프.**

**Option D — P2 시즌별 마당 (1-1.5개월)**
C + G12 푸시 + G13 SFX + G14 시즌. **"앱이 살아 숨쉰다"의 최종 형태.** 한국 콘텐츠로서 차별점 최대화.

---

## 7. 진단 요약 한 표

| 카테고리 | 현재 | Duolingo 수준 | 격차 |
|---|---|---|---|
| 분위기·모션 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **우리가 우월** |
| 마스코트 일러스트 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 비슷 |
| 마스코트 페르소나 (말 걺·등장 빈도) | ⭐⭐ | ⭐⭐⭐⭐⭐ | **큰 격차** |
| 진척 시각화 (path/tree) | ⭐ | ⭐⭐⭐⭐⭐ | **큰 격차** |
| 보상 시퀀스 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 격차 |
| Streak 시스템 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 살짝 |
| 앱 밖 retention (푸시·이메일) | ⭐ | ⭐⭐⭐⭐⭐ | **큰 격차** |
| 사운드 | ⭐ (TTS만) | ⭐⭐⭐⭐ | 격차 |
| 콘텐츠 다양성 | ⭐⭐⭐ (21 시나리오) | ⭐⭐⭐⭐⭐ | 시간 |
| 접근성 (Semantics·reduce-motion) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **우리가 우월** |

---

## 8. gate_final 통합 상태 (작업 완료 확인)

이전 세션에서 이미 완료된 사항:
- ✅ `gate_door_right.png` 247KB로 압축 (원본 539KB, backup 보관)
- ✅ `gate_final.png` 318KB로 압축 (원본 345KB, backup 보관)
- ✅ `intro_gate_screen.dart`에 `gate_final.png` 레이어 통합:
  - `beyondFade = ease-out (t-0.30)/0.30` (0.30→0.60 fade-in)
  - `beyondScale = 1.0 + pushIn * 0.40` (parallax push-in)
  - `gatewayAlign = Alignment(0.0, 0.18)` (게이트와 정렬)
  - `madang(light).png` fallback 안전망 유지 (gate_final 위에 항상 base)
- ✅ `docs/REGISTRY.md` 신규 작성 (gate assets + 압축 결과 + 복원 방법)
- ✅ `docs/living-hanok-assets.md`에 gate_final 섹션 추가

→ 추가 코드/문서 변경 불필요. 이번 세션은 **audit + 개선 로드맵 문서화**가 새로 추가된 것.
