# Hangul Sori — Asset Generation Bible (AI-friendly, self-contained)

> **이 파일 하나만 읽으면 됩니다.** `HANGUL_SORI_STYLE_GUIDE.md`, `HANGUL_SORI_DESIGN_TOKENS.md`,
> `stately-rising-jongga-assets.md`, `mascot_pose_sheet_v2.md`의 생성에 필요한 모든 내용을 여기에 흡수했습니다.
> 새 일러스트(마스코트 포즈 · 한옥 · 도장 · 스티커 · 장식)를 만들 때 **이 문서를 기준 + 프롬프트 소스**로 사용하세요.
>
> **대상**: Claude 및 모든 AI 에이전트 / 이미지 생성기(Nano Banana = Gemini Image, Midjourney, DALL·E, Imagen).
> **스타일명**: **Faceted Minhwa (모던 면 분할 민화)** — Joseon 민화 도상을 미드센추리 기하 면분할로, 한지 질감 위에.
> **최종 업데이트**: 2026-06-02 (v2 — 업로드된 고품질 마스코트를 마스터로 채택, 단일 통합본 작성). 변경 이력은 §9.

---

## 0. AI 에이전트 사용법 (먼저 읽기)

1. **무엇을 만들든 §1 Style DNA를 먼저 반영**한다 — 팔레트 hex, 면분할 규칙, 금지 사항.
2. 만들 자산 종류에 맞는 섹션으로 간다: 마스코트 §2 / 한옥·장식 §3 / 도장 §4 / 스티커 §5.
3. **레퍼런스 이미지를 반드시 첨부**한다. 텍스트 프롬프트만으로는 스타일이 안 잡힌다.
   - 마스코트 호랑이 → `assets/illustrations/mascot/tiger_idle.png`
   - 마스코트 까치 → `magpie_wingup.png` + `magpie_wingdown.png`
   - 한옥/장식 → 기존 `hanok/gate.png` 또는 `madang(light).png` 또는 같은 세트의 stage PNG
   - 도장/스티커 → 같은 세트에서 이미 통과한 1~2장
4. **모든 프롬프트 끝에 마감 문장**(§1.6)을 붙인다.
5. **3~5장 변주 생성 → 1장 선택.** 첫 출력이 최종인 경우는 드물다.
6. 완성 후 **§6 후처리 파이프라인**(투명화·정사각·압축)을 거쳐 지정 경로에 저장한다.

---

# §1. STYLE DNA (자급자족 — 스타일 가이드 흡수본)

## 1.1 한 문장 정의
> *"Joseon folk-painting iconography rendered in mid-century geometric facets on aged hanji paper."*
> 까치호랑이·일월오봉도·단청 도상을, Saul Bass / Charley Harper식 평면 기하로 환원하고, 한지 그레인을 덮는다.

## 1.2 핵심 원칙 (절대 불변)

1. **면분할 기하 구성** — 모든 피사체(호랑이·까치·산·기와·매화)는 깔끔한 각진 평면 색면으로 구성. 잘라낸 색종이/스테인드글라스 느낌. 매끄러운 유기곡선 아님.
2. **윤곽선 없음 (NO outlines)** — 검은 외곽선·정의선 금지. 형태는 인접 색면이 맞닿아 정의된다. (호랑이 줄무늬는 "채워진 검은 면"이지 외곽선이 아니다.)
3. **면 안에 그라데이션 없음** — 각 면은 평평한 단색 블록. 부피감은 인접 면끼리의 hard-edge 명도 차이로만. **예외 1개**: 이미지당 단 하나의 부드러운 그라데이션 허용(하늘 대기 cream→celadon, 또는 등불 halo).
4. **한지 그레인 텍스처** — 전체에 은은한 한지(닥종이) 그레인 오버레이. 없으면 너무 벡터처럼 차갑다.
5. **제한 팔레트** — 채도는 있지만 살짝 muted한 보석톤. 캔디/네온 금지. 아래 §1.3 hex만 사용.
6. **진정성 있는 도상** — 호랑이 이마 `王`, 갓 쓴 까치, 단청 띠, 처마 끝 올라간 곡선, 사군자(계절 일치), 해(주홍)+달(쪽빛). 장식이 아니라 의도로.

## 1.3 컬러 팔레트 (전 자산 공통 — 이 hex만 사용)

**한지/배경**
| 이름 | Hex | 용도 |
|---|---|---|
| Hanji Cream | `#FAF6EC` | 기본 따뜻한 크림 배경 |
| Hanji Ivory | `#F4E8D0` | 진한 크림, 종이 표면, 호랑이 크림부 |
| Hanji Light | `#FFFCF2` | 가장 옅은 크림, 하늘 상단 |

**슬레이트/기와 (건축 다크)**
| 이름 | Hex | 용도 |
|---|---|---|
| Hanok Slate | `#2A3340` | 처마 밑, 깊은 건축 그림자, 기와 |
| Deep Slate | `#1A2028` | 가장 어두운 그림자 면 |
| Neutral Charcoal | `#3E3A38` | 원경 한옥 실루엣 (light) |
| Cool Dark Slate | `#1F2A2E` | 다크모드 한옥 실루엣 |

**목재 톤**
| 이름 | Hex | 용도 |
|---|---|---|
| Warm Walnut | `#8E6646` | 기본 목재(마루·기둥·책상) |
| Cherry Wood | `#7E5A3D` | 서까래 끝, 따뜻한 강조 |
| Walnut Shadow | `#5C4028` | 목재 그림자 면 |
| Deep Walnut | `#3E3024` | 가장 어두운 목재 |

**호랑이 코트**
| 이름 | Hex | 용도 |
|---|---|---|
| Burnt Orange | `#E87830` | 호랑이 주 코트 |
| Rust Orange | `#C25420` | 호랑이 그림자 면 |
| Warm Ochre | `#A87E5E` | 코트 보조 그림자 / 항아리 |
| Tiger Cream | `#F4E8D0` | 배·턱·귀 안쪽 |
| Stripe Black | `#1A1410` | 각진 줄무늬, 먹 |

**단청 (강조)**
| 이름 | Hex (saturated) | Hex (muted) | 용도 |
|---|---|---|---|
| Dancheong Red | `#C24A45` | `#A8332E` | 주홍, 문, 도장 |
| Dancheong Gold | `#DFA951` | `#C99935` | 황·해·놋 |
| Dancheong Teal | `#3D9A7F` | `#2A6B5C` | 청자·도자·산 |

**풍경 그린 / 쪽빛 / 장식**
| 이름 | Hex | 용도 |
|---|---|---|
| Mountain Teal | `#3D9A7F` | 가장 가까운 산봉우리 |
| Mountain Sage | `#5C7060` | 중경 산 |
| Pale Sage | `#9BB0A0` | 원경 산 |
| Cool Neutral Gray | `#9A938C` | 대기 원경 산 (light) |
| Muted Indigo | `#1F2E5C` | 달, 깊은 강조 |
| Cobalt Indigo | `#2C3E94` | 채도 높은 쪽빛 |
| Sky Celadon | `#D8E5DC` | 여름 하늘 상단 |
| Plum Pink | `#E8B5BC` | 매화, 부드러운 분홍 |
| Dusty Pink | `#D8B5B5` | 바랜 매화 잎 |
| Stone Gray | `#8B8478` | 주춧돌·기단·담 |
| Persimmon Orange | `#D8742E` | 곶감, 잉어, 겨울 강조 |

**다크모드 대지/하늘**
| 이름 | Hex | 용도 |
|---|---|---|
| Dark Earth | `#15201A` | 다크모드 지면 |
| Deep Navy | `#0A2E3A` | 다크모드 하늘 |
| Deeper Navy | `#061F28` | 다크모드 하늘 상단 |

> **앱 UI 토큰(참고)**: Primary 녹청 `#1F7A6B`, Accent 석간주 `#A0524A`, Tiger `#FF8C42`, Gold `#C99A2E`,
> Light BG `#FAF6EC`, Dark BG `#0E1A18`. UI 색은 일러스트 팔레트와 의도적으로 살짝 다르다 — **일러스트는 위 §1.3을 쓴다.**

## 1.4 구도 원칙

1. **겹침 평면으로 깊이** — 전경→중경(건축)→배경(풍경)→하늘/대기. 원근 트릭 금지. 깊이는 겹침 + 대기 명도(가까울수록 따뜻·어둡, 멀수록 차갑·옅음)로만.
2. **여백 넉넉히** — 전경 피사체는 보통 캔버스 <30%. 열린 느낌, 꽉 차지 않게.
3. **따뜻/차가움 양극 앵커** — 따뜻(목재·해·코트·단청) + 차가움(기와·산·청자·옅은 하늘). 순따뜻=세피아死, 순차가움=무균.
4. **명도 레인지** — 크림 하이라이트 → 중간 풍경 → 깊은 차콜 앵커. 균일 중간회색 금지.
5. **강조는 군집, 흩뿌리기 금지** — 단청 점·작은 모티프는 **2개 느슨한 군집**으로. 무작위 산포는 AI티 난다.
6. **그라데이션 1개 max.**
7. **실루엣 가독성** — 100px 썸네일에서도 호랑이가 호랑이로 읽혀야. 안 읽히면 명도 대비 ↑.

## 1.5 표준 프롬프트 템플릿 (모든 자산 베이스)

```
A [wide horizontal / square / vertical] editorial illustration of [SUBJECT/SCENE].
[ONE-SENTENCE MOOD/CONTEXT].

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial quality.

Composition layered front to back:
LAYER 1 — [Top zone / sky / framing]: [element + hex]
LAYER 2 — [Mid zone]: [element + hex]
LAYER 3 — [Foreground / focal point]: [element + hex]

ATMOSPHERIC DETAILS:
- Dancheong dots in 2 loose groupings (red #C24A45, gold #DFA951, teal #3D9A7F)
- [Asset-specific exclusions]

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT [the one allowed gradient]
- Subtle hanji paper grain texture overlay across the entire image
- Restricted palette (hex): [list key hex codes used]
- Clear silhouette readability at thumbnail size (100px)

Aspect ratio: [W:H] ([WIDTHxHEIGHT] pixels)

ABSOLUTELY AVOID: [asset-specific]

This is editorial illustration for a premium Korean learning app —
[mood summary], magazine-cover quality.
```

## 1.6 마감 문장 (레퍼런스 첨부 시 필수, 항상 마지막)

```
IMPORTANT: match the geometric faceted style, color palette, paper grain
texture, and overall mood of the attached reference images exactly. This
must look like part of the same illustrated set.
```

## 1.7 DO / DON'T 한눈에

**DO** ✓ 정통 민화 도상 · 각진 면분할 · 한지 그레인 · 강조 2군집 · 따뜻/차가움 균형 · 여백 · 제한 팔레트 · 호랑이 `王` · 까치 갓 · 자산당 단일 계절.

**DON'T** ✗ 윤곽선 · 면내 그라데이션(하늘 1개 제외) · 귀여운/치비 호랑이 · 계절 혼합 · 무작위 동물 배치 · 서양 계절 이미지 · 세피아/단색 갈색 wash · 균일 다크 wash · 빽빽한 구도 · 사실/3D/애니/수채화 · 순벡터 평면(그레인 누락) · 캔디/네온 · 한옥 실루엣에 차가운 회청색 · 이유 없는 학(鶴).

## 1.8 흔한 실패 & 교정 (프롬프트에 직접 명시)

- **너무 세피아(누리끼리)**: Neutral Charcoal `#3E3A38` 한옥 앵커 + Cool Neutral Gray `#9A938C` 원경산 추가. *"WARM-DOMINANT with NEUTRAL DARK ANCHORS, avoid sepia wash."*
- **너무 차가움**: 따뜻한 호두목·등불 glow·단청 적/금 재투입.
- **답답함**: 벽·문·병풍 제거 또는 주변화. 여백 ↑, 전경 2~4개로 제한.
- **AI 평면**: *"subtle hanji paper grain texture overlay"* 강조.
- **계절 혼합**: *"Commit to ONE season only: [season]."*
- **건물 안 보임**: *"hanok roof + columns + porch MUST be clearly visible."*
- **뜬금없는 학**: 프롬프트에 *"NO crane"* 명시 (병풍 산수 패널 등 명확한 이유 있을 때만 허용).

---

# §2. 마스코트 시스템 (확장 v2 — Jongga Guardian)

> 목표: 256px 채팅 스티커가 아니라, 한옥/장식 자산과 같은 결의 **웅장한 수호 마스코트**.
> **마스터 채택(2026-06-02)**: 업로드된 고품질 **앉은(upper-body) 호랑이 = `tiger_idle.png`**,
> 갓 까치 비행 2프레임 = `magpie_wingup.png` / `magpie_wingdown.png`.
> 이 3장이 캐릭터 디자인의 **source of truth**다. 나머지는 여기서 파생.

## 2.0 현재 파일 상태 (2026-06-02)

| 분류 | 파일 | 상태 |
|---|---|---|
| ✅ 통일 마스터 | `tiger_idle`, `tiger_blink`, `tiger_happy`, `magpie_wingup`, `magpie_wingdown` | 그대로 유지 |
| ♻️ 재생성 필요 (옛 화풍) | `tiger_smile`, `tiger_neutral`, `tiger_celebrate`, `tiger_sad`, `tiger_thinking`, `tiger_sleepy` | idle 기준 |
| ♻️ 재생성 필요 (옛 화풍) | `magpie_perched`, `magpie_perched_alt`, `magpie_celebrate`, `magpie_worry` | wingup/down 기준 |

> ⚠️ `tiger_sleepy` / `tiger_thinking` 는 현재 **다른 화풍의 호랑이**다(회화풍, 얼굴 비율 다름). idle 옆에서 이질감 최대 → 교체 1순위.
> ⚠️ `tiger_sleepy.png`를 호랑이 set 전체의 기준으로 쓰지 말 것 — 특수 휴식 포즈라 set을 눕고 부드러운 쪽으로 끈다.

## 2.1 앱 emotion enum ↔ 파일 매핑 (코드 기준, 변경 금지)

`lib/widgets/sori/mascot.dart`의 `MascotEmotion`이 참조하는 파일. **파일명을 그대로 덮어쓰면 코드 수정 불필요**(errorBuilder fallback 있음).

| emotion | 호랑이 파일 | 까치 파일 |
|---|---|---|
| `smile` (기본) | `tiger_smile` (+animate 시 `tiger_blink`/`tiger_idle` 교차) | `magpie_perched` (animate 시 wingup/down) |
| `neutral` | `tiger_neutral` (+animate 시 blink/idle 교차) | `magpie_perched` |
| `surprised` | `tiger_happy` | `magpie_perched` |
| `celebrate` | `tiger_celebrate` | `magpie_celebrate` |
| `worry` | `tiger_sad` | `magpie_worry` |
| `thinking` | `tiger_thinking` | (perched) |
| `sleepy` | `tiger_sleepy` | `magpie_perched` |

## 2.2 출력 사양 (모든 마스코트 공통)

- **Master size**: 1254×1254 또는 1536×1536 정사각 PNG.
- **App path**: `assets/illustrations/mascot/{filename}.png`
- **Alpha**: 진짜 PNG-32 / RGBA 투명. 체크무늬 찌꺼기·흰 사각·베이지 종이 사각·드롭섀도 사각 금지.
- **Framing**: 피사체 중앙, 4~8% 투명 패딩. 48~64px에서 읽히고 512px에서 프리미엄.
- **Texture**: 한지 그레인은 캐릭터 색면 위에만, 배경 레이어로 깔지 말 것.

## 2.3 cute 출력을 부르는 금지 단어/포즈 (마스코트엔 절대 사용 금지)

- **금지 단어**: cute, playful, adorable, puppy eye, apologetic, vulnerable, shrinking, small, shy, pout, baby, cub, kawaii, chibi, sticker border, toy-like, emoji-like.
- **금지 포즈**: waving paw, raised paw near face/chest, paw-to-chin, forepaw toes spread for emotion, paws together to look smaller, head tilt for vulnerability, sweat drop, tear drop, confetti-heavy joy.

## 2.4 호랑이 — Design DNA 고정 + Body Language 허용

`tiger_idle.png`는 **픽셀 감옥이 아니라 캐릭터 디자인 source of truth**. 모든 variant가 "같은 호랑이"로 보이면서, 실제 호랑이처럼 자연스럽게 움직인다.

**Design DNA (모든 variant 고정)**
- 같은 성체 한국 수호 호랑이 정체성 · 같은 얼굴 구조/muzzle/볼/넓은 두상 실루엣.
- 같은 **낮고 둥근 호랑이 귀**(고양이식 뾰족 귀 금지).
- 같은 `王` 이마 줄무늬 구조와 stripe language.
- 같은 팔레트: Burnt Orange `#E87830` / Rust `#C25420` / Cream `#F4E8D0` / Stripe `#1A1410`, 그림자 ochre `#A87E5E`.
- 같은 faceted minhwa 평면 + 한지 그레인 + 무윤곽 · 같은 dignified guardian 성격 · 같은 정사각 투명 PNG.

**Body Language (감정 따라 허용)**: body axis/line of action, 카메라 각·이동 방향, 무게중심, 어깨 비대칭, 앞발 무게 이동, 고개 높이/회전, 코 방향, 귀 각(좌우 비대칭 포함), 시선/눈꺼풀 긴장, 수염 방향, 입(soft chuff / proud call / 닫힘 / scent-analysis 미세 벌림 — 사람 grin 아님), 보일 때 꼬리 곡선.

**금지**: 완전히 다른 얼굴로 재생성 · cat ears/cub 비율/봉제인형 몸 · 사람식 손흔들기/만세/턱괴기 · 눈물/땀/부유 기호/물음표/말풍선 · 48~64px에서 안 읽히는 과소형 실루엣.

### 2.4.1 호랑이 Character Bible (프롬프트에 통째로 붙여넣기)

```
TIGER IDENTITY:
An adult Korean guardian tiger from a modern Jongga minhwa set. It feels like
a calm mountain guardian seated at a noble hanok gate: powerful, composed,
intelligent.

FRAMING:
- idle, blink, neutral, smile → upper-body guardian portrait.
- happy, celebrate, thinking, sad → front-half or near-full-body 3/4 motion
  sprite (show torso/hip + tail curve to explain the motion).
- sleepy → resting sphinx / side-rest crop.
- Near-idle face ≈ 38-45% of character height; active-motion face ≈ 24-34%
  of canvas height. Always readable at 48-64px.
- Near-idle head forward with subtle 3/4 turn (~8-12°). Active motion uses a
  stronger 25-45° 3/4 camera angle.
- Chest and shoulders large and architectural, like a gate guardian.

ANATOMY:
- Adult tiger proportions. No cub, no baby-cat head, no plush toy body.
- Broad triangular head, large cheek tufts, thick neck, heavy shoulders,
  grounded chest, big calm forepaws.
- Ears slightly lower ROUNDED tiger ears, integrated into broad head — not
  tall/sharp/kitten/fox ears.
- Exactly TWO forepaws visible. Expressive variants may shift weight or step
  one forepaw slightly forward/back, but never add a third paw and never make
  paws look like hands. Hind legs/tail may appear in active motion.

COLOR & FACETS:
- Coat burnt orange #E87830 with rust-orange #C25420 and warm ochre #A87E5E
  shadow facets.
- Stripes deep ink-black #1A1410 as bold angular FILLED shapes (not outlines).
- Cream #F4E8D0 on muzzle, cheeks, chin, chest V, belly, inner ears.
- Eyes amber-gold #DFA951, almond-shaped, focused, intelligent.
- Forehead 王 suggested through discrete angular black stripe shapes (NOT a
  typographic Chinese character).
- 45-80 large readable facets. No hundreds of tiny shards, no airbrushed fur.

STYLE:
- No outlines around body or planes. Soft upper-left light, deeper lower-right
  facets. Same quiet premium finish as the jongga gate/stage/decoration set.
- Majestic, subtle. No puppy eyes, tears, sweat, exaggerated smile, raised arms.
```

### 2.4.2 호랑이 포즈별 지시 + emotion 매핑

| 파일 / emotion | 타입 | 추가 지시 |
|---|---|---|
| `tiger_idle` (smile/neutral anchor) | Near-idle portrait | 차분한 상반신 수호 초상. 눈 뜸·시선 집중, 입 닫힘, 턱 수평, 넓은 어깨, 낮고 둥근 귀, 두 앞발 planted. **업로드된 웅장한 호랑이 = 기준** (앞발 든 귀여운 호랑이 아님). |
| `tiger_blink` | Near-idle 편집 | idle 복제 후 **눈만** 편안히 감김. 그 외 전부 동일. |
| `tiger_neutral` (neutral) | Near-idle 편집 | idle 복제. 거의 동일, 눈/입/눈썹만 1~3% 더 무표정. 앱 크기에서 차이 흐려지면 exact copy 허용. |
| `tiger_smile` (smile) | Near-idle 편집 | idle 복제 후 입꼬리 + 미세한 눈 온기만. 절제된 수호자 미소. 초승달 만화눈/grin/앞발 동작 금지. |
| `tiger_happy` (surprised) | Active motion | 3/4 forward walking step + soft chuff + 따뜻한 눈. torso/hip + 느슨히 든 꼬리. 한 앞발 전방, 반대 앞발 후방 weight-bearing, 가슴 전방, 귀 neutral-forward. |
| `tiger_celebrate` (celebrate) | Active motion | proud chest lift / 절제된 tiger call / 힘찬 전진. 3/4, torso 보임, 높은 confident S-curve 꼬리, 고개 들림, 가슴 확장, 귀 alert. **만세/사람 환호/얼굴근처 앞발 금지.** |
| `tiger_sad` (worry) | Active motion | low grounded pause. 낮은 3/4 front-half/side-front, 낮아진 body line, 꼬리 낮게 trailing. 고개 숙임, 턱 당김, 시선 아래/회피, 귀 outward/back(공격적 pin 아님), 어깨 가라앉음. **puppy eye/눈물/땀/작아지는 baby pose 금지.** |
| `tiger_thinking` (thinking) | Active motion | investigative / scent-analysis pause. 3/4, 멈춘 걸음. 한 앞발 지면 위 정지/살짝 닿음, 코 살짝 들림, 고개 한쪽으로, 한 귀 forward·다른 귀 outward, 시선 옆/위, 수염 살짝 forward. 미세 flehmen 힌트만 허용. **턱괴기/물음표/사람 thinking 제스처 금지.** |
| `tiger_sleepy` (sleepy) | Rest sprite | resting sphinx / side-rest. 앞몸 낮춤, 앞발 전방 stretch, 고개 무겁지만 dignified, 꼬리 몸 따라 relaxed/살짝 curl, 눈꺼풀 거의 감김. **만화 수면기호/무너진 몸/아픈 표정 금지. 앉은 idle 프레이밍이 아니라 휴식 자세.** |

### 2.4.3 Near-idle 편집 템플릿 (blink/neutral/smile — 생성 말고 편집)

```
Use the attached tiger_idle.png as the EXACT base image. This is a near-idle
image-editing / inpainting task, NOT new character generation.

Do not redraw the character. Preserve the exact canvas size, transparent alpha,
silhouette, ears, head angle, body position, forepaw position, stripe placement,
王-like forehead stripes, whiskers, nose, cream belly V, colors, scale, framing.

Only edit the masked expression area: [eyes / eyelids / brow / mouth].
Target expression: [VARIANT EXPRESSION].

Everything outside the masked area must remain identical to tiger_idle.png.
Export as true RGBA transparent PNG — no baked checkerboard, no white box, no
paper background, no sticker outline, no text.
```

### 2.4.4 Expressive 생성 템플릿 (happy/celebrate/sad/thinking/sleepy)

```
A true-transparent PNG app mascot sprite of the SAME adult Korean guardian
tiger as tiger_idle.png, in Jongga Faceted Minhwa style.

SOURCE-OF-TRUTH RULE: use tiger_idle.png as the character-design anchor, NOT a
pixel-locked copy. This must unmistakably be the same tiger. Preserve the Design
DNA (broad head & muzzle, slightly lower rounded tiger ears, 王-like forehead
stripes, stripe language, burnt-orange/rust/cream/ink-black palette, faceted
minhwa rendering + subtle hanji grain, dignified non-cute personality, square
transparent PNG). Near-idle stays upper-body; active variants may show torso,
hip, hind legs, and tail when motion readability needs it.

EXPRESSIVE BODY LANGUAGE: allow subtle changes in head angle, chin height, ear
position, chest energy, shoulder tension, forepaw weight, slight body rotation.
Emotion from authentic tiger anatomy, not human gestures. The pose must look
like one captured animation frame of a living tiger. Use a 25-45° 3/4 camera
angle for active motion.

[PASTE the variant delta from §2.4.5]

MOTION ANCHOR: [relaxed walk / investigative pause / scent-analysis pause /
proud call / low grounded pause / resting sphinx]
BODY AXIS: [line of action, spine angle, chest height, shoulder asymmetry, weight]
FOREPAW LOGIC: [which forepaw forward, which bears weight, paused/touching/tapping]
FACE / EARS / TAIL: [eye focus, eyelid tension, nose direction, mouth as
chuff/call/closed/scent-parting, whiskers, ear angle, tail curve if visible]
CAMERA / FRAMING: [portrait / front-half / 3/4 diagonal / resting crop; tail
visibility; how much torso/hip]

CONSTRAINTS: exactly two forepaws (no third); no waving/face-paw/paw-to-chin;
hind legs must not read as extra forepaws; show full tail curve if it's part of
the emotion (don't crop the tip); no chibi/cub/plush/costume acting; no tears,
sweat, hearts, question marks, speech bubbles, text, symbols, heavy confetti;
square canvas, transparent alpha, 48-64px readability, 4-8% padding.

Export as true RGBA transparent PNG — no baked checkerboard, no white box, no
paper background, no sticker outline.
```

### 2.4.5 Expressive variant delta (위 템플릿의 [PASTE] 자리)

```
tiger_happy.png — content, safe, friendly greeting.
3/4 diagonal motion sprite, not straight-on. Diagonal line of action from the
lifted tail through back and chest to the leading forepaw; body travels across
canvas while head turns warmly to the viewer. One large foreground forepaw
reaches forward; opposite forepaw back & weight-bearing. Ears neutral-forward,
warm engaged eyes, mouth slightly open as a soft chuff (not a grin). Relaxed
C-curve or soft S-curve tail. Reads as "good job, continue."

tiger_celebrate.png — confident success, energized.
3/4 diagonal with visible torso and a higher confident S-curve tail. Upward
line of action from grounded forepaws through expanded chest to raised head;
shoulders energized, body rotated slightly. One forepaw steps forward with
confident weight transfer, the other braces (both low, tiger-like). Head raised,
ears alert, mouth open in a short powerful tiger call/chuff-roar (not a cartoon
scream). Stronger than happy but dignified. No human cheering, no raised arms.

tiger_sad.png — low energy, disappointment, withdrawal.
Low 3/4 front-half or side-front crop; visible lowered body line; low trailing
tail if visible. Descending line of action; chest less open; shoulders softened
and slightly sunk; low center of gravity. Both forepaws heavy near the ground.
Head lowered, chin tucked, gaze down/away; ears relaxed outward/back (not
aggressively pinned); mouth closed with subtle downturned tension. Dignified and
composed, not helpless or babyish. No tears.

tiger_thinking.png — investigating, scenting, evaluating, listening. NOT a human
"thinking face"; the tiger paused mid-step to analyze the environment.
3/4 diagonal; torso/hip enough to show a paused step; restrained balancing tail
if it fits. Forward but suspended diagonal line of action. One forepaw paused
just above ground or lightly touching; weight on the other grounded forepaw +
rear support. Head turned slightly to one side; nose lifted as if catching
scent; eyes focused sideways and slightly upward; one ear forward, the other
outward (selective listening); whiskers slightly forward; mouth mostly closed,
optional very subtle flehmen hint only. Thoughtful, observant, quietly
intelligent. Avoid symmetrical ears, even neutral walk, smile, exaggerated
flehmen grimace, confused cartoon face, sad body language, paw-to-chin, props.

tiger_sleepy.png — rest, safety, low arousal.
Resting sphinx front-half, side-rest crop, or compact rest sprite. Horizontal
calm body axis; chest lowered, shoulders soft, neck relaxed. Forepaws stretched
forward or folded naturally under the chest (not human-like). Head heavy but
dignified; eyelids mostly closed; ears relaxed; mouth closed or a tiny elegant
yawn. Tail relaxed along the body or softly curled. No cartoon sleep symbols, no
collapsed body, no sick/sad expression.
```

## 2.5 까치 Character Bible

```
MAGPIE IDENTITY:
Use the attached magpie_wingup and magpie_wingdown images as the EXACT quality,
anatomy, color, gat, and faceted-feather reference. The result must look like
the same Korean magpie character in a new pose.

DESIGN CONSTANTS:
- Ink-black / blue-black head and back #101820, cool slate facets #26323A, deep
  teal tail facets #0E4D58.
- Cream-white belly and wing panels #F4E8D0 with pale gray shadow facets #B8B6AE.
- Long elegant tail, visible black beak, small amber-gold eye #DFA951.
- Korean gat MUST be accurate: black cylindrical crown, wide flat brim, thin
  chin strap tied under the beak/neck. No top hat, no western hat.
- Legs/feet small burnt-orange facets #C25420.
- Feathers are angular layered planes, not fuzzy realistic feather noise.
- Same body size, head size, gat size, and tail length across ALL poses.

COMPOSITION CONSTANTS:
- One magpie only, centered in a square canvas. Transparent background only.
- No round chick body, no penguin proportions, no oversized eyes.
- No speech bubble, sticker border, or extra props unless requested.
- Keep the body center anchored consistently across perched, perched_alt,
  wingup, wingdown, celebrate, worry.
```

### 2.5.1 까치 포즈별 지시

| 파일 | 지시 |
|---|---|
| `magpie_wingup` ✅ | 기준. 비행 frame 1: 양 날개 높이 든 wide V. |
| `magpie_wingdown` ✅ | 기준. 비행 frame 2: 양 날개 내려 바깥으로 펼침. |
| `magpie_perched` | 차분한 Joseon 전령 포즈. 날개 접음, 발 보임, 갓 정확, 긴 꼬리 우아. 작은 가지 옵션(스티커처럼 보이지 않을 때만). |
| `magpie_perched_alt` | 같은 캐릭터, 방향/고개 각만 다름. 몸 스케일·갓 크기 동일. |
| `magpie_celebrate` | 우아한 good-news 포즈. 날개 열되 귀엽지 않게, 부리 살짝 벌림. 단청 facet 2~3개만, 무거운 confetti 금지. |
| `magpie_worry` | 침착한 걱정. 고개 각 + 날개 tuck으로 표현. 눈물/땀/둥근 아기새 얼굴 금지. |

### 2.5.2 까치 기본 템플릿

```
A true-transparent PNG app mascot sprite of a Korean magpie wearing a gat,
[POSE / EMOTION].
Use the attached magpie_wingup and magpie_wingdown as the exact quality,
anatomy, color, gat, and faceted-feather reference — same dignified magpie in a
new pose.
[Paste MAGPIE IDENTITY / Design constants / Composition constants]
[Paste pose-specific sentence]
Aspect ratio: 1:1 square, 1254x1254 or 1536x1536 px. Export as true RGBA
transparent PNG.
```

## 2.6 공통 스타일 문장 (마스코트 프롬프트 끝에)

```
Create this as a premium Korean learning app mascot sprite in the same Jongga
Faceted Minhwa style as the attached hanok gate, hanok stage, and quest-
decoration assets. This is NOT a chat sticker and NOT a cute animal icon — it
is a dignified guardian mascot: monumental, calm, editorial, geometric, rooted
in Joseon minhwa. Large clean geometric facets, crisp silhouette, subtle hanji
grain, restrained traditional palette. No soft toy feeling, no emoji face, no
chibi proportions, no Western cartoon acting. Emotion through authentic tiger/
magpie anatomy and body language. True transparent PNG alpha — no baked
checkerboard, no background box, no shadow rectangle, no text, no speech bubble,
no sticker outline.
```

## 2.7 생성 순서 (추천)

1. `tiger_idle` 확정(이미 보유) → source of truth로 고정.
2. `blink`/`neutral`/`smile` = near-idle **편집**(§2.4.3). blink는 눈만.
3. `happy`/`celebrate`/`sad`/`thinking`/`sleepy` = expressive 생성(§2.4.4+2.4.5). 한 이미지당 MOTION ANCHOR 하나만.
4. `magpie_perched` 먼저 → 나머지 까치 variation.
5. 우선순위: ① `tiger_sleepy`·`tiger_thinking`(이질감 최대) → ② `celebrate`·`sad`(노출 빈도 높음) → ③ `smile`·`neutral`(편집으로 빠르게) → ④ 까치 3종.
6. 앱 투입 전 mint/black/cream 배경 위에서 체크무늬·사각박스 잔재 확인.

---

# §3. 한옥 & 장식 (배경 단계 + 영구 장식)

> 전체 12단계 × light/dark = 24장의 **단계별 정확한 프롬프트**는 `docs/plans/stately-rising-jongga-assets.md` §2에 있음.
> 이 섹션은 그 자료 없이도 **새 한옥 요소를 같은 스타일로** 만들 수 있는 시스템(구도 로직 + 어휘 + 템플릿 + 완성 예시)을 담는다.

## 3.1 한옥 배경 공통 사양

- **치수**: 1236×2700 (9:20, madang와 동일). PNG-24, 배경 채움(알파 X).
- **경로**: `assets/illustrations/hanok_stages/stage_{name}_{light|dark}.png`
- **카메라**: 마당 정면에서 약 30° 위 3/4 view. **모든 단계 시점·구도 통일**(전환 시 cross-fade만).
- **영역 분할**: 하늘 상단 30~40% / 마당 중간 30% / 건물·지면 하단 30~40%.
- **light 하늘**: cream `#FAF6EC` → celadon `#D8E5DC` (허용된 1개 그라데이션).
- **dark 하늘**: Deep Navy `#0A2E3A` → Deeper Navy `#061F28`, 옅은 보름달 `#F4E8D0` 30%.

## 3.2 한옥 건축 어휘 (요소별 정확 사양 — 새 요소 프롬프트의 부품)

- **주춧돌(foundation)**: 화강암 블록, top `#8B8478` / 측면 그림자 `#5C4028`. 각진 직육면체, 둥글게 금지.
- **기둥(기둥)**: 수직 사각, 앞면 `#8E6646` / 안쪽 그림자 `#5C4028`. 수직성 강조.
- **대들보 + 서까래**: 가로 보 `#8E6646`(밑 그림자 `#3E3024`) + 부채꼴로 펼친 좁은 막대 10~12개, 끝 `#7E5A3D` 작은 사각(서까래 끝 = 처마 밑 "이빨").
- **초가지붕**: 둥근 dome, ochre gold `#DFA951` + walnut 그림자 `#8E6646`. 처마 끝 살짝 처짐(한국식, 중국 파고다 뾰족함 금지).
- **기와지붕**: 곡면 흑기와, Hanok Slate `#2A3340` + Deep Slate `#1A2028` 그림자. **처마 끝 위로 올라간 뿔(처마끝, upturned horn)** — 한국 곡선. 망와(처마 끝 국화 disc) cream+ochre.
- **단청 띠**: teal `#3D9A7F` base + 교대 사각(red `#C24A45` / gold `#DFA951` / cream `#FAF6EC`) 2열 + 작은 연꽃 모티프. 처마 밑·기둥 상단. 정확한 grid, 무윤곽, 절제.
- **창호지문**: walnut frame 작은 사각 grid + 한지 cream `#FAF6EC` backing + 안쪽 따뜻한 ochre `#DFA951` 저투명 glow(등불).
- **솟을대문**: 두 짝 walnut 문 `#8E6646`(그림자 `#3E3024`) + 둥근 쇠못 grid(stripe black `#1A1410`) + 작은 기와 지붕 + 편액(walnut 프레임 + cream 종이, 글자 비움). 돌계단 `#8B8478`.
- **회벽**: 흰 회벽 `#FAF6EC` + 하단 stone `#8B8478` + 위 작은 기와 trim.
- **마당 지면**: sandy earth `#9A938C` (light). 다크 `#15201A`.
- **원경 산**: 일월오봉도 3겹 — 원 `#9A938C` / 중 `#9BB0A0`/`#5C7060` / 근 `#3D9A7F`. 각진 평면 실루엣.

## 3.3 한옥 배경 프롬프트 템플릿 (새 단계/변형용)

```
A vertical 9:20 editorial illustration of [HANOK SCENE / STAGE]. [MOOD].

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting. NOT cute, NOT cartoonish — confident,
premium editorial.

LAYER 1 — Sky (top 35%): hanji cream #FAF6EC fading to sky celadon #D8E5DC
(the single allowed gradient). [moon #1F2E5C / sun #C24A45 / cloud scrolls].
LAYER 2 — Distant mountains (mid 25%): irworobongdo 3 receding peaks, cool gray
#9A938C / pale sage #9BB0A0 / mountain sage #5C7060, flat angular silhouettes.
LAYER 3 — [Foreground architecture/courtyard]: [build from §3.2 vocabulary with
exact hex per element].

ATMOSPHERIC DETAILS: 2 loose dancheong dot groupings (#C24A45, #DFA951, #3D9A7F);
[1-2 magpies on eave/branch with accurate gat]; persimmon tree silhouette at far
left when young, removed when the estate matures. NO crane.

Style discipline: NO outlines; NO gradients within shapes except the sky;
subtle hanji grain; restricted palette (list hex used); clear silhouette at
thumbnail.

Aspect ratio: 9:20 vertical (1236x2700). 

ABSOLUTELY AVOID: Chinese pagoda roof, Japanese garden, modern objects, scattered
random elements, sepia wash, packed composition.

[§1.6 closing line]
```

**Dark 변형 추가 지시**: *"Render the same scene at night: sky deep navy #0A2E3A → #061F28, pale ivory full moon #F4E8D0 at 30%, lattice doors glowing warmly from interior lamplight, dancheong jewels more muted, mountains darker silhouettes, ground dark earth #15201A, tiny scattered star dots."*

## 3.4 완성 예시 (참고 — Stage: 기와 완성)

```
A vertical 9:20 editorial illustration of a dignified hanok with a full
traditional Korean curved black-clay tile roof, in a courtyard with distant
irworobongdo mountains. Calm accomplished mood.

LAYER 1 — Sky: hanji cream #FAF6EC → sky celadon #D8E5DC, muted-indigo crescent
moon #1F2E5C upper-right, 2-3 ivory cloud scrolls clustered upper-right.
LAYER 2 — Mountains: 3 receding irworobongdo peaks (#9A938C / #9BB0A0 / #5C7060).
LAYER 3 — Hanok: full curved black tile roof, hanok slate #2A3340 primary, deep
slate #1A2028 shadow facets; strong UPTURNED eave horns on both sides (Korean
curve, not Chinese pagoda); chrysanthemum-disc tile caps (망와) in cream+ochre,
2 per eave tip; rafter ends as a row of small cherry-wood #7E5A3D rectangles
under the eaves; warm walnut #8E6646 pillars; granite #8B8478 foundation stones;
sandy courtyard #9A938C. Two gat-wearing magpies, one on each eave horn, facing
slightly inward.

ATMOSPHERIC: 2 loose dancheong dot groupings (#C24A45, #DFA951, #3D9A7F). NO crane.
Style: NO outlines; only the sky gradient; subtle hanji grain; palette #FAF6EC
#D8E5DC #2A3340 #1A2028 #8E6646 #7E5A3D #8B8478 #9A938C #DFA951 #C24A45 #3D9A7F.
Aspect ratio: 9:20 (1236x2700).
[§1.6 closing line]
```

## 3.5 영구 장식 (투명 PNG 오버레이) — 공통

- **포맷**: PNG-24, 알파 O (배경 투명 필수). 자체 그림자 약간(밑 어두운 면), 떠있는 느낌 X.
- **경로**: `assets/illustrations/decorations/{quest_id}.png`. 카메라 각은 stage와 동일.
- **요소(치수 px)**: 장독대 600×400 · 매화나무 500×800 · 노송 600×900 · 연못+잉어 500×350 · 장명등 300×650 · 풍경 150×350 · 편액 400×120(글자 비움) · 돌담 1200×200 · 사군자 4폭 · 까치 둥지 · 계절 이벤트(설날 색동기·추석 보름달·한글날 세종 편액·연). **상세 개별 프롬프트는 `stately-rising-jongga-assets.md` §3.**
- **장식 템플릿**:

```
A transparent PNG of [KOREAN DECORATION], faceted minhwa style, for layered
composition over a hanok courtyard. NO outlines, pure color planes, subtle hanji
grain, restricted palette ([hex used]). Self-shadow only at the base (soft, low
opacity). Aspect ratio [W:H] ([WxH] pixels). PNG with full alpha transparency.
IMPORTANT: render with transparent background so this can be layered over
courtyard scenes; match the attached set's style exactly.
```

---

# §4. 단청 도장 (Stamps) — 8종

> 팩 클리어 시 도장첩에 찍히는 단청 무늬. 8 base, 토픽군별 무늬. 코드에서 색 변주로 확장.

## 4.1 공통 사양
- PNG-24, 알파 O(투명). **256×256.** 경로 `assets/illustrations/stamps/stamp_{motif}.png`.
- **Family resemblance 필수**: 8개가 동일 외곽 크기·동일 ring 두께·동일 cream paper inner, **motif만 차이.**

## 4.2 표준 도장 템플릿 (motif 교체식)

```
A transparent PNG of a circular Korean dancheong-style stamp featuring a [MOTIF]
motif. Faceted minhwa style.

Construction:
- Circular stamp outline: dancheong red #C24A45 outer ring (thick, ~15% of diameter)
- Inner circle background: hanji cream #FAF6EC
- Centered [MOTIF]: [MOTIF DESCRIPTION], flat dancheong gold #DFA951 facets with
  mountain teal #3D9A7F shadow facets; alternating gold/teal/cream planes
- Tiny center dot in dancheong red

Aspect ratio: 1:1 (256x256 pixels). Transparent outside the stamp circle.
Style: NO outlines on the motif (color planes only), subtle paper grain,
restricted palette #C24A45 #FAF6EC #DFA951 #3D9A7F.
[§1.6 closing line]
```

## 4.3 8종 motif (토픽군 매핑)

| 파일 | Motif | 묘사 cue | 토픽군 |
|---|---|---|---|
| `stamp_lotus` | 연꽃 | 8 angular petals radiating, gold facet + teal base shadow | 인사·자기소개·가족 |
| `stamp_chrysanthemum` | 국화 | dense layered angular petals, concentric gold/teal | 시간·숫자 |
| `stamp_plum` | 매화 | 5-petal blossom + center gold dot, angular branch hint | 감정·형용사 |
| `stamp_bamboo` | 대나무 격자 | vertical stalks + segment lines + angular leaf cluster | 학교·직장 |
| `stamp_cloud` | 구름문양 | flat geometric curl/scroll shapes interlocking | 날씨·자연 |
| `stamp_geometric_octagon` | 팔각 기하 | octagon grid of alternating gold/teal/red triangles | 음식·쇼핑 |
| `stamp_mountain` | 산봉우리 | mini irworobongdo 3 peaks + tiny sun/moon | 교통·여행 | 
| `stamp_swastika` | 만(卍)자 격자 | interlocking 卍 lattice (Buddhist/folk), gold on cream | 신체·건강 |- 완성

---

# §5. 스티커 (Stickers) — 30종

> 계(모임방) 채팅 대신 사용. 6 category × 5 = 30. 작은 사이즈에서도 읽혀야.

## 5.1 공통 사양
- PNG-24, 알파 O. **256×256.** 경로 `assets/stickers/{category}_{name}.png`.
- **스타일 예외**: 스티커는 메인 자산보다 **조금 더 둥글고 친근(거의 chibi 허용)**. 단 **§1.3 팔레트는 그대로.** 작은 사이즈 가독성 우선(동작 실루엣이 먼저 읽히게).
- ⚠️ 단, **앱 마스코트(`mascot/`)는 스티커가 아니다** — 마스코트는 §2의 dignified guardian 규칙을 따른다. 스티커의 chibi 허용은 `stickers/`에만 적용.

## 5.2 6 카테고리 × 5

| 카테고리 (파일 prefix) | 5종 | 비고 |
|---|---|---|
| 호랑이 `tiger_*` | cheer(응원) · clap(박수) · surprised(놀람) · sad(슬픔) · love(사랑) | 스티커는 동작 실루엣 우선. 마스코트보다 둥글어도 OK |
| 까치 `magpie_*` | 5종 (인사·기쁨·놀람·졸림·하트 등) | 갓 정확 유지 |
| 단청 모티프 `dancheong_*` | 5종 (연꽃·구름·매듭·태극·꽃살문 등) | 순수 패턴 스티커 |
| 한글 자모 `hangul_*` | 5종 (ㄱ/ㅏ/한글 글자 표정 등) | Pretendard/Noto Sans KR Bold 일관 |
| 음식 `food_*` | 5종 (떡·차·김치·부채·매듭 등 전통 소품) | |
| 도장 `stamp_sticker_*` | 5종 (잘함·완료·합격 도장 스타일) | §4 도장 룩 재활용 |

## 5.3 스티커 템플릿

```
A transparent PNG chat sticker of [SUBJECT + ACTION], 256x256, Korean learning
app. Faceted minhwa style but slightly rounded and friendly (sticker tone). Keep
the restricted palette (§1.3 hex). Bold readable silhouette that reads first at
small size. Subtle hanji grain on color planes. NO outlines, NO speech bubble,
NO text, transparent background. [§1.6 closing line]
```

---

# §6. 후처리 파이프라인 (공통)

생성 후 항상 거친다(샌드박스 bash로 일괄 처리 가능):

1. **배경 투명화** — 흰/베이지 사각, 체크무늬, 드롭섀도 사각 제거 → 진짜 RGBA.
2. **정사각·동일 프레이밍** — 마스코트는 1254² 또는 1536², 4~8% 패딩. 합성 자산은 지정 px.
3. **앵커 정렬** — 마스코트는 발 위치/몸 중심을 idle과 맞춤(애니메이션 흔들림 방지).
4. **압축** — `pngquant --quality=65-85` → 마스코트 ~300KB, 배경/장식은 §해당 치수. (현 idle/blink/happy ≈ 300~440KB 수준에 맞춤.)
5. **가독성 체크** — mint/black/cream 배경 위 48~64px 썸네일에서 표정·실루엣 확인.
6. **저장** — 지정 경로에 **동일 파일명 덮어쓰기** → 코드 수정 불필요.

> Claude가 도와줄 수 있는 부분: 생성기 출력 PNG들을 주면 1~6을 일괄 자동화해서 해당 폴더에 떨군다.

---

# §7. 파일 경로 맵

| 자산 | 경로 | 치수 |
|---|---|---|
| 마스코트 (호랑이/까치 포즈) | `assets/illustrations/mascot/{name}.png` | 1254² / 1536² |
| 한옥 단계 배경 | `assets/illustrations/hanok_stages/stage_{name}_{light|dark}.png` | 1236×2700 |
| 영구 장식 (투명 오버레이) | `assets/illustrations/decorations/{quest_id}.png` | 가변 |
| 단청 도장 | `assets/illustrations/stamps/stamp_{motif}.png` | 256² |
| 채팅 스티커 | `assets/stickers/{category}_{name}.png` | 256² |
| 한옥 헤더/씬 | `assets/illustrations/hanok/{name}.png` | 가변 |

---

# §8. 자산 종류별 빠른 체크리스트

- [ ] §1.3 팔레트 hex만 사용했는가
- [ ] 윤곽선 없음 · 면내 그라데이션 없음(하늘 1개 제외) · 한지 그레인 있음
- [ ] 강조는 2군집(흩뿌리기 아님) · 따뜻/차가움 앵커 둘 다 · 여백 충분
- [ ] 마스코트: dignified guardian(귀엽지 않음) · 낮고 둥근 귀 · `王` · 앞발 정확히 2개 · 갓 정확
- [ ] 계절 단일 · 이유 없는 학 없음 · 서양 이미지 없음
- [ ] 48~64px(마스코트/도장/스티커) 또는 100px(배경) 썸네일 가독성
- [ ] 진짜 RGBA 투명(해당 자산) · 체크무늬/사각박스 잔재 없음
- [ ] 레퍼런스 첨부 + §1.6 마감 문장 포함

---

# §9. 변경 이력 (Changelog)

### 2026-06-02 — v2: 단일 통합 바이블 작성 + 마스코트 마스터 채택
- **마스코트 마스터 교체**: 업로드된 고품질 **앉은 호랑이 = `tiger_idle.png`**, 갓 까치 비행 2프레임 = `magpie_wingup/wingdown.png`를 캐릭터 디자인 **source of truth**로 채택. "진짜 호랑이 + 친근함 + 다양한 포즈" 목표를 §2.4 Design DNA 고정 + Body Language 허용 체계로 정식화.
- **단일 자급자족본**: `HANGUL_SORI_STYLE_GUIDE.md` + `HANGUL_SORI_DESIGN_TOKENS.md`(팔레트) + `stately-rising-jongga-assets.md`(한옥/장식/도장/스티커/마스코트 바이블)의 생성 필수 내용을 이 파일 하나로 흡수. 이제 AI는 **이 파일만 읽으면** 동일 스타일로 신규 자산 생성 가능.
- **현 상태 진단**: `tiger_sleepy`·`tiger_thinking`이 다른 화풍 → 교체 1순위로 명시. 통일된 faceted 세트(idle/blink/happy/wingup/wingdown) 보존.
- **확장**: 호랑이 expressive variant delta(happy/celebrate/sad/thinking/sleepy) 풀 프롬프트, 까치 바이블, 한옥 건축 어휘 + 템플릿 + 완성 예시, 도장 8 motif, 스티커 6 카테고리, 후처리 파이프라인 포함.
- **문서 정리(전수조사 후)**: 흩어진 이미지 생성 문서 9종을 `docs/_archive/`로 이동(삭제 X, 매핑은 `docs/_archive/README.md`). 현행 체계 = **HOW**(이 파일) + **WHAT**(`IMAGES_TO_CREATE.md`) + **WHERE**(`assets/REGISTRY.md`) + **부록**(`plans/stately-rising-jongga-assets.md` 낱장 95장). `HANGUL_SORI_STYLE_GUIDE.md`·`mascot_pose_sheet_v2.md`는 이 파일에 흡수되어 아카이브됨. `HANGUL_SORI_DESIGN_TOKENS.md`는 코드용 디자인시스템 문서라 별도 유지.

> 이 문서는 `docs/plans/mascot_pose_sheet_v2.md`(요약판)를 포함·확장한다. 신규 자산 생성 시 **이 ASSET_GENERATION_BIBLE.md를 우선** 참조.
