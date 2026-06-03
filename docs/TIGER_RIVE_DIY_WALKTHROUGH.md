# 호랑이 Rive 직접 제작 워크스루 (DIY)

> Jin이 [rive.app](https://rive.app) 무료 에디터에서 `tiger.riv`를 직접 만드는 단계별 가이드.
> 짝꿍 문서: [TIGER_RIVE_RIG_SPEC.md](TIGER_RIVE_RIG_SPEC.md)(코드가 기대하는 계약).
> **에디터 UI는 수시로 바뀜** — 버튼 위치 등 정확한 조작은 Rive 공식 튜토리얼(rive.app → Learn, help.rive.app, Rive 유튜브의 *Meshes / Bones / State Machine* 영상)을 옆에 켜고 따라가. 이 문서는 **"무엇을·어떤 순서로·이 호랑이에 맞는 값"**을 알려줌.

---

## 마음가짐 (먼저 읽기)
- 이건 코드가 아니라 **그림 도구 작업**. 첫 리그는 **2~6시간** 잡아. 한 번에 완성하려 하지 마.
- **핵심 전략: v0 → 확인 → v1.** 메시·본 없이 되는 v0를 **먼저 export해서 앱에 꽂아** "부드럽게 움직이네" 확인하고, 그 다음 리깅을 얹어. (앱은 v0든 v1이든 그대로 재생함.)
- 준비물: 무료 rive.app 계정 1개. 소스 그림 = `assets/illustrations/tiger_anim/`의 PNG들(특히 `stand_greet.png` 정면 선 호랑이, `rest_idle.png` 앉은 호랑이).

## 코드가 기대하는 "계약" (이것만 지키면 자동 작동)
| 항목 | 값 |
|---|---|
| 파일명 | `tiger.riv` |
| 저장 위치 | 프로젝트 `assets/rive/tiger.riv` |
| 아트보드 | **1개**(기본) |
| 상태머신 | **딱 1개**(그게 기본이 됨) · **입력 없이 자동 재생** |
| 익스포트 | **Export → Runtime (`.riv`)** (에디터 `.rev` 아님) |

→ 넣고 `flutter pub get` → `flutter run`. 코드 0줄 변경.

---

# v0 — 메시·본 없이 "부드럽게 살아있는" (가장 먼저, 30~60분)

목표: 호랑이가 **숨 쉬고(미세 스케일) + 좌우로 천천히 글라이드** 하는 것만. 시점 변화·다리 사이클 없음. 그래도 지금 프레임 끊김과는 차원이 다르게 매끄럽다.

1. **New File → Artboard 생성.** 크기 예 `1000 × 800`(가로로 약간 넓게 = 걸을 공간). 배경 투명.
2. **`stand_greet.png` 드래그해서 import.** 아트보드 하단 중앙, 바닥에 서게 배치.
3. **Animate 모드로 전환**(에디터 상단 Design ↔ Animate 토글).
4. **Animation "IdleBreathe" 만들기 (loop):**
   - 0초: 이미지 Scale 100%.
   - 1.2초: Scale 101.5%(살짝 커짐 = 숨 들이쉼), Y 살짝 위로.
   - 2.4초: 다시 100%.
   - 키프레임에 **Ease(Cubic)** 적용. Loop 켜기.
5. **Animation "Stroll" 만들기:**
   - 이미지 전체를 X로 0 → −120 → 0 → +120 → 0 (좌우 왕복), 6~8초, Ease.
   - (선택) 동시에 Y를 미세하게 위아래(±4px)로 흔들어 bob 느낌.
6. **State Machine 1개 생성**("Tiger"):
   - 상태에 IdleBreathe와 Stroll을 **둘 다 동시에** 깔거나(레이어), 또는 IdleBreathe(기본) ↔ Stroll을 타이머로 번갈아. 가장 쉬운 건 **두 애니를 각각 다른 레이어에 두고 둘 다 loop** → 호흡하면서 천천히 좌우 이동.
   - 입력(input) 만들지 말 것(자동 재생).
7. **Export → Runtime → `tiger.riv`** → `assets/rive/tiger.riv`에 저장 → `flutter pub get` → `flutter run`.
   - ✅ 홈 밴드에서 호랑이가 숨 쉬며 좌우로 미끄러지면 v0 성공. (안 보이면 §막히면.)

> sit→stand 같은 큰 포즈 변화를 v0에서 흉내내려면: `rest_idle`(앉음)·`stand_greet`(섬) 두 이미지를 겹쳐 두고 **Opacity를 서로 크로스페이드**(타임라인 보간)하면 프레임 스왑보다 매끄럽다. 하지만 진짜 부드러운 "일어서는 변형"은 v1(본)에서.

---

# v1 — 본 + 메시로 진짜 변형 (sit→인사→일어섬→걷기)

v0가 떴으면 이제 변형을 얹는다. **정면 시점은 메시가 잘 먹는다**(인사·호흡·일어섬). 측면 걷기(시점 변화)는 제일 어려우니 마지막에.

1. **메시(Mesh)** — `stand_greet` 이미지 선택 → Mesh 생성 → 정점(vertices)을 몸통·다리·머리·꼬리에 찍어 덮기. **관절(목·어깨·엉덩이·꼬리 뿌리)에 정점을 촘촘히** 둬야 자연스럽게 휜다. (공식 *Meshes* 튜토리얼.)
2. **본(Bones)** — Bone 툴로 골격: 척추(2~3관절) → 머리, 앞다리×2, 뒷다리×2, 꼬리(2~3). (공식 *Bones* 튜토리얼.)
3. **바인딩(Bind)** — 메시를 본에 바인드 → 본을 움직였을 때 그림이 따라 휘는지 확인. 안 휘는 부위는 정점의 본 가중치 조정.
4. **타임라인 추가**(Animate 모드, 각각 새 Animation):
   | 클립 | 만드는 법 | 길이 |
   |---|---|---|
   | `Notice` | 머리 본을 살짝 들어 정면 응시 | 0.4s |
   | `Smile` | 눈/입(작은 이미지나 메시 정점)으로 표정 — 어려우면 생략 | 0.3s |
   | `Rise` | 앉은 자세(본을 웅크림)에서 선 자세로 펴기. 첫 버전은 "살짝 낮췄다 펴는" 정도로 단순화 OK | 0.5~0.7s |
   | `IdleBreathe` | (v0 것 재사용) 척추·가슴 미세 | 2~3s loop |
   | `WalkCycle` | 다리 본을 교대로 들었다 놓기 + 척추 상하 미세 + 전체 X 이동 | 8~12키, loop |
   - 모든 키프레임 **Ease(Cubic)**.
   - **측면 걷기 팁:** 정면 호랑이를 완전 측면으로 "회전"은 본/메시로 불가. → 걷기는 **약한 3/4 유지 + 다리 사이클 + 좌우 슬라이드**로. 충분히 "걷는다"고 읽힌다. (완전 측면이 꼭 필요하면 기존 `walk_left/right` PNG를 측면 전용으로 import해 스왑 — 고급.)
5. **상태머신** ("Tiger", 기본 1개):
   ```
   Entry → Sit/Idle
     └(0.6~1s 자동)→ Notice → Smile → Rise → IdleBreathe
   IdleBreathe ─(타이머 3~7s)→ WalkRight → IdleBreathe → WalkLeft → …  (무한)
   ```
   - 상태 사이 transition에 **Duration(blend 0.2~0.4s)** 줘서 부드럽게.
   - 자동 진행 = 각 상태에 "exit time" 또는 타이머 조건. **입력 만들지 말 것.**
6. **Export → Runtime → `tiger.riv`** 덮어쓰기 → `flutter run`.

---

## 막히면
- **앱에서 호랑이가 안 보이거나 옛날(프레임) 그대로?** → ① 파일이 정확히 `assets/rive/tiger.riv`인지 ② `flutter pub get` 했는지 ③ Export가 **Runtime(.riv)** 였는지(에디터 .rev 아님) ④ OS reduce-motion(접근성)이 켜져 있으면 일부러 정지 프레임이 뜸 — 끄고 확인.
- **렌더 깨짐/일부 안 보임** → 앱은 Flutter(Skia) 렌더러를 씀. 특수 효과(고급 블러 등)는 피하고 기본 셰이프/메시/본만 쓰면 안전.
- **에디터 조작 자체가 막힘** → Rive 공식 *Meshes / Bones / State Machine* 튜토리얼이 정답. 특정 단계에서 막히면 나한테 "이 단계 막힘"이라고 하면 그 부분 더 풀어줄게.

## 한 줄 요약
**v0(이미지 + 호흡·글라이드)부터 export해서 앱에 꽂아 확인 → 본·메시로 인사·일어섬·걷기 얹기.** 한 방에 완성하려다 지치지 말고 단계로.
