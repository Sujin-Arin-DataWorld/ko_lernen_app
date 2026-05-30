# 3 Screens — 획기적 UX 재설계 제안 (2026-05-29)

> Jin이 보낸 스크린샷 3장 분석. 인트로는 거의 OK, 홈/온보딩에 구조적 문제.

---

## 1. 진단 (스크린샷 3장 분석)

### Screen 1 — 인트로 (✅ 거의 OK)
지금 화면은 **의도된 결과의 90%**. 게이트가 화면 가득, 닫힌 빨간 문, 마당 풍경이 doorway 뒤로 보임. 더블 게이트 사라짐.

**남은 어색함**: 게이트 frame **바깥**(투명 영역)으로 마당이 보임 → 게이트가 자연 속에 떠 있는 구도. 일부 사용자는 "왜 게이트 뒤만 풍경이고 옆에도 풍경이지?" 느낄 수 있음. (선택: 외부도 cream으로 마스킹)

### Screen 2 — 홈 (다크 모드) — 🔴 호랑이 짤림 **버그 확인**

**원인**: `madang(dark).png` 배경에 **호랑이가 그림 안에 baked-in** 되어 있음 (오른쪽 아래 구석). 또 하녹 silhouette, 단풍잎, 구름도 모두 고정 위치. `BoxFit.cover`로 화면을 채우면 폰 aspect에 따라 호랑이가 잘리거나 화면 밖으로 밀려남.

**구조적 문제 (UX 관점)**:
- 보드 같이 빽빽한 dark UI → 한옥 정체성 약함
- 상단 stats peek (1 Days · Lv 1 · 0 XP) — Duolingo 똑같음, 차별점 0
- "Letter of the day" 카드 — 좋지만 다음 hero CTA와 시각 동일 weight → hierarchy 무너짐
- "Today" hero card (Airport immigration A1 + 호랑이) — **여기만 매력적**. 나머진 generic
- 호랑이 mascot이 카드 안에 한 번만 등장 → 페르소나 약함

### Screen 3 — 온보딩 "What's your level?" — 🟡 **gate 덩그러니** 문제

작은 게이트 thumbnail이 화면 상단에 떠 있음 (HanokGateArt openAmount: 0.08, 높이 170px, 9:16). 이 작은 게이트는:
- 인트로에서 이미 본 화려한 게이트의 mini 버전
- 배경에 분리되어 외로워 보임
- 정보성 0 (장식 only)
- 전체 화면의 30% 차지 — 비효율

**시각적 문제**: 어두운 cream/black 배경에 작은 컬러풀한 게이트 → "스티커 붙인" 느낌. 한옥 컨셉의 진지함이 깎임.

---

## 2. 획기적 재설계 — 3 화면별 mockup 제안

### 🎬 Screen 1 (Intro) — Optional Polish

**현재로 충분 — 단, 두 가지 옵션:**

**Option A (보수)** — 그대로 유지. 게이트 뒤 + 게이트 옆 풍경 = "한옥은 자연 속에 있다".

**Option B (정제)** — 게이트 frame 외부에 한지 cream mask 추가. ClipPath로 게이트 silhouette만 풍경 위에 떠 있게. 전통 한국 회화의 "여백" 미학.

```dart
// 의사 코드
Stack([
  // 1. 풍경 (gate_final) — 화면 가득
  Image.asset(gate_final, BoxFit.cover),
  // 2. cream mask — 게이트 silhouette **바깥**만 cream
  CustomPaint(painter: HanokSilhouetteMask(creamFill, gateBounds)),
  // 3. 게이트 PNG — 그 위에
  HanokGateArt(...)
])
```

### 🏠 Screen 2 (Home) — 완전 재구성 ★★★

#### Bug fix
`madang(light/dark).png` 배경에 baked-in mascot/하녹 → **추상화된 ambient bg로 교체** 또는 **호랑이 mascot만 코드로 분리해서 정해진 위치에 배치**.

#### 컨셉 전환: "현대적 학습 앱" → "오늘 들어선 마당의 한 장면"
**Duo가 하는 일을 한국식으로 번역하는 것이 아니라, 한국 한옥 메타포를 끝까지 밀어붙임.**

```
┌──────────────────────────────────────────┐
│ ╭─ 처마 그림자 (단청 띠) ────────────────╮│
│ │                                       ││
│ │   안녕하세요, S님!                    ││ ← 시간대별 인사
│ │   오늘은 좋은 날이에요 ☀              ││
│ │                                       ││
│ │     🐯 (큰 호랑이 idle)               ││ ← 96-128px tiger
│ │      ↑ 말풍선 "다섯 분만 해볼까요?" ⌐ ││
│ │                                       ││
│ ╰─────────────────────────────────────╯ │
│                                          │
│  ┌─ 오늘의 한 글자 ────────────────────┐ │
│  │   한  (han)              ✓ done    │ │ ← compact daily char
│  └────────────────────────────────────┘ │
│                                          │
│   🔥 7일     ⚡ 350 XP    🛡 1 shield   │ ← inline stats (chip row, 작게)
│                                          │
│  ╭─ 가는 길 ───────────────────────────╮│ ← Skill path replacement
│  │   ●━━●━━●━━○━━○                    ││
│  │   완료  완료  완료  현재  잠금       ││
│  │   ↑ 단청 점, 한옥 길 배경           ││
│  ╰──────────────────────────────────────╯
│                                          │
│  [공항 입국] [재미·신선·5분]   ──→     │ ← 다음 한 발 (CTA)
│                                          │
│  ── 더 둘러보기 ──                       │ ← 작게
│  📚 단어 · 🌸 문법 · 🎭 시나리오 · 🎮 게임│ ← horizontal scroll
└──────────────────────────────────────────┘
```

**핵심 변화**:
1. **시간대별 인사 + 큰 호랑이 + 말풍선** — Duo의 "Duo가 항상 말 거는" 패턴을 호랑이 + 한국어 한 마디로
2. **Stats를 inline chip row** — 더 이상 큰 카드가 stats를 차지하지 않음. 호랑이가 hero
3. **Skill path** — 5개 노드(현재 chapter), 단청 점 + 한옥 길. 다음 노드의 욕구 시각화
4. **"다음 한 발" CTA** — 1개 hero scenario를 추천. 작은 chip 형식이지만 색상으로 강조
5. **모듈은 하단 secondary** — horizontal scroll로 부담 없이

**시각 톤**:
- 다크모드: night hanok madang **silhouette** (현재 baked-in 호랑이 X) + 매화/불씨 입자만
- 라이트모드: 한지 cream + 단청 acent
- 호랑이 = `Mascot.tiger(animate=true, size=120, emotion=context-aware)`

### 🚪 Screen 3 (Onboarding) — Gate 덩그러니 해결 ★★

#### 핵심 변화: **gate를 "장식"이 아니라 "맥락"으로 사용**

**3가지 reset 옵션, 갈수록 과감:**

#### Option 1 — 안정 (gate를 헤더 fullbleed로)
gate_final.png을 상단 30% 높이 hero header로 깐다 (full bleed). 위에서 cream-fade gradient. 그 위에 title overlay. Gate가 "마당으로 들어가는 입구" 메타포를 유지하면서도 작은 thumbnail 어색함 사라짐.

```
┌─────────────────────────────────────┐
│███████ gate_final (full-bleed) █████│ ← 30% 높이
│███████ fade to bg gradient █████████│
│                                     │
│ What's your level?                  │ ← title overlaps fade
│ We start at your level...           │
│                                     │
│ ┌── A1 Beginner ─────────────────┐ │
│ │ 안녕하세요. ▶                  │ │
│ └────────────────────────────────┘ │
│ ┌── A2 Basic ────────────────────┐ │
│ │ 아이스 아메리카노...           │ │
│ └────────────────────────────────┘ │
│  ...                                │
└─────────────────────────────────────┘
```

**구현**: HanokGateArt 제거 → `Image.asset(gate_final.png, BoxFit.cover, height: screenH*0.3)` + 하단 fade. **30분 작업.**

#### Option 2 — 캐릭터 중심 (★ 추천)
호랑이가 두루마리(한지 scroll)를 펴서 사용자에게 레벨 선택지를 보여주는 풍경. 호랑이 = 안내자 페르소나 확립의 시작점.

```
┌─────────────────────────────────────┐
│                                     │
│              🐯                     │ ← 큰 호랑이 (animate)
│         ╱╲  ╱╲                      │ ← "How fluent are you?"
│       ╱ 안녕 ╲   (말풍선)            │
│      ╲      ╱                       │
│                                     │
│  ─── 한지 scroll 펼쳐짐 ──────────  │ ← scroll 위에 levels
│  │ A1 Beginner    안녕하세요  ▶  │ │
│  │ A2 Basic       아이스...    ▶  │ │
│  │ B1 Intermediate 어제 친구... ▶  │ │
│  │ B2 Upper        회의가...   ▶  │ │
│  ─── scroll 끝 ─────────────────── │
│                                     │
│  Tap your level or [Decide later]  │
└─────────────────────────────────────┘
```

**구현**: 
- 위쪽: `Mascot.tiger(size: 160, animate: true)` + 말풍선 위젯
- 가운데: 한지 scroll 일러스트 배경 (신규 PNG 1장 필요 — 또는 단순 paper texture + dancheong 가장자리)
- Level cards는 scroll 위에 떠 있음 (반투명 카드)

**필요 PNG**: `scroll_unfurl.png` (선택사항 — 한지 두루마리 펼쳐진 모습, 가장자리 단청 trim).

#### Option 3 — 마당 풍경 fullbleed (★★ 가장 과감)
온보딩 = **인트로의 연속** 컨셉. 인트로에서 게이트 통과 → 온보딩은 "마당에 도착해서 호랑이가 환영" 화면. gate_final 풍경을 배경으로 full bleed, 호랑이가 등장.

```
┌─────────────────────────────────────┐
│ 🌄 산 풍경 (gate_final 배경) ⌐     │
│ ⌐ 한옥 silhouette ──────────────── │
│                                     │
│           🐯                        │ ← 큰 호랑이 (마당에 서 있음)
│       ╱──────╲                      │
│      │ 환영해요!│ ← 말풍선          │
│       ╲──────╱                      │
│                                     │
│ ┌─── floating 단청 chip ─────────┐ │
│ │ Where shall we start?          │ │
│ │                                │ │
│ │ ╔═ A1 ═╗ ╔═ A2 ═╗               │ │
│ │ ║  안  ║ ║ 아메 ║   ← 4 chip   │ │
│ │ ╚══════╝ ╚══════╝               │ │
│ │ ╔═ B1 ═╗ ╔═ B2 ═╗               │ │
│ │ ║어제..║ ║회의..║               │ │
│ │ ╚══════╝ ╚══════╝               │ │
│ └────────────────────────────────┘ │
│                                     │
│  [나중에 결정 (A1로 시작)]         │
└─────────────────────────────────────┘
```

**시각 임팩트 최강**. 인트로→온보딩이 **하나의 시네마틱 시퀀스**로 이어짐. 사용자가 "정말 한옥에 들어왔구나" 느낌.

**구현**: 
- `Image.asset(gate_final.png, BoxFit.cover)` 풀스크린
- 어두운 gradient overlay (가독성 위해 alpha 0.35)
- `Mascot.tiger(size: 180, animate: true)` 중앙 상단
- 4 chip을 grid 2×2로 (현재 list 대신) — 작은 정보량
- bottom CTA

**필요 자산**: 기존 자산만 사용. **추가 PNG 0장**.

---

## 3. 추천 우선순위

| 순위 | 작업 | 즉각 효과 | 시간 |
|---|---|---|---|
| **🔥 P0** | madang(dark/light).png에서 baked-in 호랑이 제거 또는 단순 silhouette만 | 다크모드 호랑이 짤림 버그 해결 | 1d (PNG 재수정 또는 코드로 분리) |
| **🔥 P0** | 온보딩: HanokGateArt 작은 thumbnail 제거 → **Option 1 (gate_final full-bleed header)** 최소 적용 | 덩그러니 해결 | 0.5d |
| **🌟 P1** | 홈: 시간대별 인사 + 큰 호랑이 + 말풍선 hero | 페르소나 확립 | 1d |
| **🌟 P1** | 홈: skill path (수평 5노드) | 진척 욕구 시각화 | 2d |
| **★ P2** | 온보딩: Option 3 (마당 풍경 + 호랑이 환영) | 시네마틱 임팩트 | 1.5d |
| **★ P2** | 홈: stats inline chip + 모듈 horizontal scroll로 redesign | hierarchy 정리 | 1d |

---

## 4. 즉시 적용 가능한 fix (이번 세션에 할 수 있는 것)

**Want me to do these now?**
- [ ] 온보딩에서 HanokGateArt thumbnail 제거하고 **Option 1 (gate_final hero header)** 적용
- [ ] 홈에서 madang(dark) 배경의 baked-in tiger 영역 추출/투명 처리
- [ ] 또는 더 간단히: madang(dark) BoxFit을 cover → fitWidth로 변경 (호랑이가 잘리는 대신 화면 밖으로 나가지 않음)

만약 OK 하면 이번 세션에 둘 다 해결 가능. 그 다음 P1 / P2는 별도 세션.

---

## 5. 핵심 미학 원칙 (앞으로 모든 화면에 적용)

1. **호랑이 = 안내자, 까치 = 알림** — 호랑이는 "사용자에게 말 거는" 캐릭터, 까치는 "좋은 소식 전령"
2. **한옥 = "공간", 단청 = "강조"** — 한옥 일러스트는 항상 배경/맥락, 단청은 CTA·badge·divider만
3. **여백 > 채움** — 한지 cream에 핵심 1개 element만. Duo처럼 정보 폭격 ❌
4. **시간대 = ambient 변화** — 아침/낮/저녁 시간대에 따라 배경 색조·인사·호랑이 표정 변화
5. **인트로 시퀀스 일관성** — 인트로 → 온보딩 → 홈 첫 진입은 하나의 시네마틱 이야기. 끊김 없이.

---

위 제안 중 어떤 옵션이 가장 마음에 들어? 알려주면 그 방향으로 구현 시작.
