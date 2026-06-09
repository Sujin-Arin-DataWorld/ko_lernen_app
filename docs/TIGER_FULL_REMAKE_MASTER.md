# 🐯 호랑이 애니메이션 전체 재제작 마스터 스펙 (Faceted Minhwa)

> **올인원 단일 소스.** 호랑이 애니메이션의 생성 프롬프트 + 상태머신 + 타이밍 + 프레임↔코드 매핑 + 검증을 한 문서에 통합. (구 7개 호랑이 MD를 폐기·통합, 2026-06-06.)
> **절대 원칙:** **새 호랑이를 생성하지 않는다.** `assets/illustrations/mascot/tiger_idle.png` 가 모든 프레임의 source of truth. 모든 프롬프트는 "같은 호랑이, 포즈만 변경".
> **드롭인:** 아래 파일명 그대로 `assets/illustrations/tiger_anim/` 에 저장하면 `lib/widgets/sori/tiger_stage.dart` 코드 수정 0.
> 아트 앵커 = `mascot/tiger_idle.png`(기준) + `mascot/tiger_happy.png`(3/4 모션 참조). 스타일 바이블 = `docs/ASSET_GENERATION_BIBLE.md` §2.4.

---

## §0. AI 사용 프로토콜 (이미지 생성 시 매번)

1. **레퍼런스 첨부 필수** — `tiger_idle.png`(항상) + 측면/모션이면 `tiger_happy.png` 추가. 텍스트만으로 생성 금지.
2. **캐릭터 바이블 블록(§2)을 프롬프트에 통째로 포함** — 매 프레임.
3. **포즈 종류로 방식 선택**:
   - 근접 포즈(idle·blink·bob·neutral 류) = **inpaint**(§4-b): "use tiger_idle.png as EXACT base, only edit masked area".
   - 신규 포즈(측면 보행·앉기·기지개·일어남) = **"same tiger, new pose"**(§4-c) + 바이블 블록.
4. **마무리 문장 고정**: `IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like the same tiger from the same illustrated set.`
5. **생성 후 §9 QA** 통과 못 하면 재생성.

---

## §1. Source of Truth (절대 고정)

- **`mascot/tiger_idle.png` = 기준 호랑이.** 얼굴·줄무늬·색·체형이 모든 프레임의 진실. (BIBLE §9에서 v2 마스터로 확정)
- **`mascot/tiger_happy.png`** = 3/4 액티브 모션(걷기 방향감·몸통/엉덩이/꼬리 곡선) 참조용.
- **측면 보행은 "정측면 마스터 1장"을 먼저 확정**(§4-a) 후 거기서 다리만 파생 — 이게 16장 보행 일관성의 열쇠.
- 새 호랑이·다른 화풍·사실/3D/수채화 **금지**.

---

## §2. 호랑이 Character Bible (프롬프트에 통째로 붙여넣기)

> `ASSET_GENERATION_BIBLE.md` §2.4.1 과 **동기**. 수정 시 두 곳 같이.

```
TIGER IDENTITY:
An adult Korean guardian tiger from a modern Jongga minhwa set. It feels like
a calm mountain guardian seated at a noble hanok gate: powerful, composed,
intelligent.

ANATOMY:
- Adult tiger proportions. No cub, no baby-cat head, no plush toy body.
- Broad triangular head, large cheek tufts, thick neck, heavy shoulders,
  grounded chest, big calm forepaws.
- Ears slightly lower ROUNDED tiger ears, integrated into broad head — not
  tall/sharp/kitten/fox ears.
- Four legs with correct big-cat anatomy; in side view the near and far legs
  on each end are clearly distinguishable. Never add a fifth leg, never make
  paws look like hands.

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

**팔레트 표 (HEX 고정):**

| 역할 | HEX |
|---|---|
| 주 코트 Burnt Orange | `#E87830` |
| 그림자 Rust | `#C25420` |
| 그림자 ochre | `#A87E5E` |
| 줄무늬 | `#1A1410` |
| 크림(배·얼굴·발) | `#F4E8D0` |
| 눈 amber | `#DFA951` |

---

## §3. 기술 규격 (전 프레임 동일 — 점프/드리프트 방지)

| 항목 | 값 |
|---|---|
| 캔버스 | **1254 × 1254 px** 정사각 |
| 배경 | **완전 투명** PNG. 그림자·바닥·체커보드·흰박스 **없음** |
| **발바닥 baseline** | 모든 프레임 **하단에서 ~100px 위 동일선**, ±10px. (현재 walk가 330px 떠서 stand(42px)와 세로 ~288px 점프하던 버그 해결) |
| body scale | 전 프레임 동일. 측면 전신 = 코끝~꼬리뿌리 가로 **~1150px**. 3/4 정면(인트로·인사) = tiger_happy 프레이밍 |
| 정렬 | 좌우 중심 + 발 baseline 기준. (코드가 bottomCenter contain → 캔버스 내 발 위치 = 화면 발 위치. **baseline 통일이 자연스러움의 80%.**) |

---

## §4. 일관성 워크플로 (드리프트 방지)

**(a) 마스터 2장 먼저 락:** ① `stand_greet`(3/4 정면 서기) ② **깨끗한 정측면 서기**(보행 기준). 이 둘 색·체형 확정 후 나머지 파생.

**(b) 근접 포즈 inpaint 템플릿(영문):**
```
Use the attached tiger_idle.png as the EXACT base image. This is an image-editing /
inpainting task, NOT new character generation. Do not redraw the character. Preserve
canvas size, transparent alpha, silhouette, ears, head angle, body position, stripe
placement, 王 forehead stripes, whiskers, nose, cream belly V, colors, scale, framing.
Only edit the masked area: [eyes / mouth / chest]. Target: [VARIANT].
Export true RGBA transparent PNG — no checkerboard, no white box, no paper background.
```

**(c) 신규 포즈 "same tiger" 템플릿(영문):**
```
[§2 캐릭터 바이블 블록 통째]
Same tiger as the attached reference images (tiger_idle.png / tiger_happy.png) — same
face, stripes, palette, proportions. NEW POSE: [프레임 motion anchor].
[§3 규격: 1254², transparent, foot baseline ~100px from bottom, identical scale]
IMPORTANT: match the faceted style, palette, grain, mood of the references exactly.
```

**(d) 추가 팁:** seed 고정(툴 지원 시) · 그룹 단위 생성 후 마스터와 대조 · 보행은 정측면 마스터에서 **다리만 교체**가 가장 일관적 · walk_left는 walk_right **수평 플립** 활용.

---

## §5. 전체 프레임 인벤토리 (44장, 코드 파일명 1:1)

스토리보드: **인트로 → 좌 서성 → 우 서성 → 중앙 복귀 → 앉기 → 일어나기 → 기지개** (+ambient 포효).

### A. 인트로 (9) — 눕기→알아챔→미소→일어남→인사
| 파일 | 뷰 | 자세 |
|---|---|---|
| `rest_idle` | 3/4 | 편히 누움, 고개 살짝 경계 |
| `notice_turn` | 3/4 | 고개 들어 정면 돌리기 시작 |
| `notice_front` | 정면 | 눈맞춤 |
| `smile_front` | 정면 | 부드러운 미소 |
| `rise_prep` | 정면 | 가슴 들며 일어설 준비 |
| `rise_half` | 3/4 | 반쯤 일어섬 |
| `stand_greet` | 정면 | **선 채 환영 (idle 베이스)** |
| `bob_a` | 정면 | stand_greet 호흡(가슴 ↑) |
| `bob_b` | 정면 | 호흡(가슴 ↓) |

### B. Idle / 앉기 (4)
| 파일 | 뷰 | 자세 |
|---|---|---|
| `stand_idle_a` | 정면 | 무게중심 살짝 이동1 |
| `stand_idle_b` | 정면 | 변형2(꼬리/귀 다른 위치) |
| `sit_idle_a` | 3/4 | 앉은 자세 |
| `sit_idle_b` | 3/4 | 앉아서 고개/꼬리 살짝 |

### C. 좌향 서성 (11)
`turn_left_3q` · `step_out_left` · `walk_left_01`~`08` · `turn_left_front`

### D. 우향 서성 (11)
`turn_right_3q` · `step_out_right` · `walk_right_01`~`08` · `turn_right_front`

### E. 기지개 (3)
`stretch_prep` · `stretch_full` · `stretch_release`

### F. 포효 (6, ambient)
`roar_prep` · `roar_open` · `roar_open2` · `roar_full` · `roar_close` · `roar_recover`

---

## §6. 상태머신 + 타이밍 (코드 `tiger_stage.dart` 와 동기)

```
REST → INTRO(launch당 1회) → FRONT_IDLE(루프) ↔ ambient{PACING_L/R · SIT · STRETCH · ROAR}
                                              (5–10s 간격, 항상 중앙·정면 복귀)
```

**ambient 확률** (frontIdle에서만): idle 유지 32% / pacing 25% / sit 15% / stretch 14% / roar 14%.

**타이밍 (ms, dwell=체류 / fade=크로스디졸브, 0=하드컷):**

- **INTRO:** rest_idle(650/0) → notice_turn(300/200) → notice_front(300/180) → smile_front(460/200) → rise_prep(300/160) → rise_half(360/170) → stand_greet(650/220)
- **FRONT_IDLE 루프(~6.5s):** stand_greet(1200/260) → bob_a(720/240) → bob_b(720/240) → stand_idle_a(800/240) → bob_a(720/240) → stand_idle_b(800/240) → bob_b(720/240)
- **PACING:** turn_*_3q(240/200) → step_out_*(160/180) → walk_*_01..08 **×3루프, 100ms 하드컷** + dx 0→±span(linear) → 반대로 turn_*_3q(220/150) → walk back ×3 + dx →0 → turn_*_front(300/150)
  - span = `(밴드폭×0.17).clamp(28,80)` px. moonwalk 방지: 나갈 땐 진행방향, 돌아올 땐 반대방향 프레임.
- **SIT:** sit_idle_a(가변 0.45×/220) → sit_idle_b(가변 0.55×/320) → stand_greet(/260). sit 총 1.5~3s 가변.
- **STRETCH:** turn_right_3q(240/150)→stretch_prep(260/200)→stretch_full(720/260)→stretch_release(240/200)→turn_right_front(200/160)
- **ROAR:** turn_right_3q(140/150)→roar_prep(220/160)→roar_open(130/110)→roar_open2(120/90)→roar_full(440/110)→roar_close(160/120)→roar_recover(220/160)→turn_right_front(200/160)

---

## §7. 🦵 진짜 교대 보행 — 4다리 정확 메커니즘 (핵심)

### 보행 방식 = Lateral Sequence Walk (측면순서 4박자)
호랑이 걸음의 발 착지 순서: **원후족 → 원전족 → 근후족 → 근전족**, 각 **1/4 사이클** 간격 (Williams 4박자 LH→LF→RH→RF).

### 규칙 3가지 (어기면 어색)
1. **같은 쪽 앞·뒷다리는 1/4 사이클 어긋남** — 정확히 정반대로 그리면 **trot(속보)**이 되어 틀림. walk은 어긋나야 함.
2. **항상 발 3개 이상 접지** — walk은 공중에 뜨는 순간이 없음. **절대 뛰는(run/leap) 포즈 금지.**
3. **근전족·근후족이 배 아래에서 교차** (사이클당 2회) — 이게 "왼발 오른발 자연 교차"의 시각적 핵심.

### walk_right 8프레임 4다리 위치표 (facing RIGHT / 근족=오른쪽·원족=왼쪽)
> 용어: **앞뻗음**=forward extended reach, **앞/디딤**=forward planting, **몸아래**=under body passing, **뒤**=back stance, **뒤들림**=lifted behind (toe-off).

| f | 근전(앞다리) | 근후(뒷다리) | 원전 | 원후 |
|---|---|---|---|---|
| 01 | 몸아래 | 뒤 | 몸아래 | **앞뻗음** |
| 02 | 뒤 | 뒤들림 | 앞/디딤 | 앞/디딤 |
| 03 | 뒤 | 몸아래 | **앞뻗음** | 몸아래 |
| 04 | **뒤들림** | 앞/디딤 | 앞/디딤 | 뒤 |
| 05 | 몸아래 | **앞뻗음** | 몸아래 | 뒤 |
| 06 | 앞/디딤 | 앞/디딤 | 뒤 | 뒤들림 |
| 07 | **앞뻗음** | 몸아래 | 뒤 | 몸아래 |
| 08 | 앞/디딤 | 뒤 | 뒤들림 | 앞/디딤 |

- **근전족**: 07에서 최대 전진, 03~04에서 뒤. **근후족**: 05에서 최대 전진, 01~02에서 뒤. → 둘이 **03·06 부근 배 아래서 교차**.
- **walk_left** = 위 표의 **수평 플립**(근/원 동일, 방향만 반대).

### 자가검증 (8장 빠르게 넘겨)
- [ ] (a) 근전족 발끝이 **앞↔뒤 왕복**
- [ ] (b) 근전족이 앞일 때 근후족은 **반대 위상**(05 fore-under/hind-reach, 07 fore-reach/hind-under)
- [ ] (c) 매 프레임 **발 3개 이상 땅에 닿음**

---

## §8. 프레임별 상세 프롬프트

> 매 프롬프트 = [§2 캐릭터 바이블 블록] + 아래 motion anchor + [§3 규격: 1254² transparent, foot baseline ~100px, identical scale] + [§0 IMPORTANT 마무리]. 영문 그대로 사용.

### 인트로
- `rest_idle` — `Three-quarter view, lying down relaxed, head slightly raised and alert.`
- `notice_turn` — `Three-quarter view, lifting head, beginning to turn toward the viewer.`
- `notice_front` — `Front view, head facing forward, calm eye contact.`
- `smile_front` — `Front view, soft friendly smile, warm expression.`
- `rise_prep` — `Front view, chest lifting, gathering weight to rise from lying.`
- `rise_half` — `Three-quarter view, half-risen, mid-way standing up.`
- `stand_greet` — `Front view, standing tall, welcoming dignified pose, facing viewer.`
- `bob_a` — `Front view standing, chest raised slightly (inhale); otherwise identical to stand_greet.`
- `bob_b` — `Front view standing, chest lowered slightly (exhale); otherwise identical to stand_greet.`

### Idle / 앉기
- `stand_idle_a` — `Front view standing, weight shifted slightly, tail in a different relaxed position.`
- `stand_idle_b` — `Front view standing, ears/tail in another relaxed variation.`
- `sit_idle_a` — `Three-quarter view, sitting on haunches, calm, two forepaws planted.`
- `sit_idle_b` — `Three-quarter view sitting, head turned slightly, tail shifted.`

### 전환 (좌/우)
- `turn_left_3q` — `Three-quarter LEFT view, turning from front toward the left.`
- `step_out_left` — `Three-quarter LEFT view, lifting the near front paw to take the first step left.`
- `turn_left_front` — `Three-quarter LEFT view, turning back from left to front.`
- `turn_right_3q` / `step_out_right` / `turn_right_front` — 위와 동일, RIGHT 방향.

### 보행 (walk_right — facing RIGHT, §7 표를 4다리 모두 명시)
공통: `Full side profile facing RIGHT, calm lateral-sequence walk, three paws on the ground, never airborne, never running.`
- `walk_right_01` — `near foreleg passing under the chest, near hind leg pushed BACK in stance, far foreleg passing under body, far hind leg reaching FORWARD landing.`
- `walk_right_02` — `near foreleg angled BACK, near hind leg lifted behind (toe-off), far foreleg planting forward, far hind leg planting.`
- `walk_right_03` — `near foreleg pushed BACK in stance, near hind leg swinging forward under body, far foreleg reaching FORWARD, far hind leg under body.`
- `walk_right_04` — `near foreleg LIFTED behind the body (toe-off, paw up behind), near hind leg planting forward under hip, far foreleg planting, far hind leg back. (front paw clearly BEHIND)`
- `walk_right_05` — `near foreleg swinging forward under the chest, near hind leg reaching FORWARD planting, far foreleg under body, far hind leg pushed back.`
- `walk_right_06` — `near foreleg planting forward, near hind leg planted under hip, far foreleg pushed back, far hind leg lifted behind.`
- `walk_right_07` — `near foreleg fully extended FORWARD reaching ahead, near hind leg planted under the hip, far foreleg pushing back, far hind leg under the body.`
- `walk_right_08` — `near foreleg forward planting, near hind leg pushed BACK, far foreleg lifted behind (toe-off), far hind leg planting forward. (leads back into 01)`

### 보행 (walk_left)
`walk_left_01`~`08` = walk_right 동일 자세의 **수평 플립**(facing LEFT). 각 프레임 근/원·앞/뒤 동일, 방향만 반대.

### 기지개
- `stretch_prep` — `Three-quarter RIGHT, front paws starting to reach forward, head lowering.`
- `stretch_full` — `Three-quarter RIGHT, classic cat stretch: front legs extended forward, chest low, hips raised high.`
- `stretch_release` — `Three-quarter RIGHT, relaxing out of the stretch back toward standing.`

### 포효 (선택)
- `roar_prep`→`roar_open`→`roar_open2`→`roar_full`→`roar_close`→`roar_recover` — `Three-quarter RIGHT, mouth gradually opening into a dignified roar then closing` (입 벌림 단계적, 위엄있게·공격적이지 않게).

---

## §9. QA 체크리스트 (생성 후)
- [ ] 전 프레임 **얼굴·줄무늬·색 동일** (tiger_idle.png과 일치, 드리프트 0)
- [ ] **발바닥 baseline 통일** (세로 점프 0)
- [ ] **보행: 근전족 01앞→04뒤→07앞 왕복 + 근후족 반대 위상 + 항상 3발 접지** (§7 자가검증)
- [ ] 배경 **완전 투명** (흰박스·체커보드 0)
- [ ] **faceted** 스타일 유지 (페인터리/3D로 흐려지지 않음), 팔레트 `#E87830` 계열

---

## §10. 적용 & 검증
1. `assets/illustrations/tiger_anim/` 에 **같은 파일명**으로 저장 → 코드 수정 0.
2. 투명 미처리 시 코너 floodfill 키잉 후처리.
3. **시뮬레이터** `http://localhost:8131` (`/tmp/tiger_sim/`): "우향 걷기만 0.3×"로 4다리 교대 확인 + "전체 데모"로 스토리보드 확인.
4. **앱**: `flutter run` → 홈 상단 밴드 육안. reduce-motion 시 정지 프레임 확인.

---

## §11. 프레임 ↔ 코드 매핑 (`lib/widgets/sori/tiger_stage.dart`)
- `_allFrames` (44) = §5 전체 목록 (precache 대상).
- `_walkLeft` = `walk_left_01`..`08` (순차).
- `_walkRight` = `walk_right_01`..`08` (순차).
- 새 프레임은 **순차 01~08** 그대로 드롭인 (재배열 금지 — 새 프레임이 이미 올바른 사이클).
- 프레임 수 변경(예: 12장) 시 위 3배열 + PACING 타이밍(§6) 동기 갱신 필요.

---

## 부록. Rive 경로 (보류)
프레임 방식으로 전환하며 Rive 리깅 문서는 폐기. `lib/widgets/sori/tiger_stage_rive.dart`는 `assets/rive/tiger.riv` 부재 시 **프레임 `TigerStage`로 폴백**하므로 앱 동작엔 영향 없음. Rive 리그는 미제작. 추후 부드러운 보간이 필요하면 별도 검토.
