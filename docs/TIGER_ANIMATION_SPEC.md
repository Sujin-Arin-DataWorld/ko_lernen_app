# 호랑이 애니메이션 스펙 (Tiger Animation Spec)

> **목적:** 살아있는 호랑이 마스코트의 프레임 애니메이션 구조 핸드오프 문서. 다른 AI/개발자가 이 문서만으로 이해·확장할 수 있도록 작성.
> **구현:** `lib/widgets/sori/tiger_stage.dart` (`TigerStage` 위젯). 홈 상단 밴드에서 사용 (`lib/screens/home_screen.dart` `_TigerHero`).
> **자산:** `assets/illustrations/tiger_anim/` — 35장 PNG (1254×1254 정사각, 투명 배경, Faceted Minhwa 풀바디). pubspec 폴더 단위 등록.
> 최종 갱신: 2026-06-03.

---

## 1. 컨셉

호랑이는 단순 정적 아바타가 아니라 **앱 진입 시 사용자를 알아보고 일어나 반긴 뒤, 평소엔 조용히 좌우로 왔다갔다하는 살아있는 수호자**. 성체 호랑이의 품위 + 친근함. 무섭거나 공격적이면 안 됨.

```
쉬고 있음 → 알아차림 → 부드럽게 반김 → 일어남 → 정면 환영 → 이후 idle / 서성임 / 앉기
```

## 2. 상태머신

```
REST ──(앱 진입)──▶ INTRO_GREETING ──▶ FRONT_IDLE ◀──┐
                     (launch당 1회)      (호흡 루프)    │
                                          │             │
                            ambient 5–10s │             │ 완료 시 복귀
                                          ▼             │
                              ┌──────────────────────┐  │
                              │ PACING_L / PACING_R   │──┤  (there-and-back, 중앙 복귀)
                              │ SIT                   │──┘
                              └──────────────────────┘
```

- **INTRO_GREETING** = launch당 1회 (`static bool _introPlayedThisLaunch`, 영속 X). 재시작하면 다시 인사.
- **FRONT_IDLE** = 기본. `stand_greet ↔ bob_a ↔ bob_b` 미세 호흡 루프.
- **ambient 스케줄러** = `frontIdle`에서만, 5–10s마다: 55% 유지 / 30% pacing(좌·우 랜덤) / 15% 앉기. 항상 재무장.
- **PACING** = 정면→측면 전환→walk out→반대로 돌아 walk back→정면. **항상 중앙(dx=0)·정면으로 복귀** → 누적 드리프트·화면 밖 이탈 0.

## 3. Canonical 프레임 인벤토리 (35장)

| 역할 | 정식명(.png) | 비고 |
|---|---|---|
| 휴식 | `rest_idle` | 누운 3/4, 경계 |
| 인지(회전) | `notice_turn` | 정면으로 회전 시작 |
| 인지(정면) | `notice_front` | 눈맞춤 |
| 미소 | `smile_front` | 부드러운 반응 |
| 일어설 준비 | `rise_prep` | 정면, 가슴 듦 |
| 반쯤 일어남 | `rise_half` | 3/4 상승 |
| **정면 환영** | `stand_greet` | **idle 베이스 + reduce-motion 정지 프레임** |
| 호흡 A/B | `bob_a` `bob_b` | 미세 호흡 |
| 정면 idle | `stand_idle_a` `stand_idle_b` | (idle 다양성, 현재 미사용·예비) |
| 앉기 | `sit_idle_a` `sit_idle_b` | ambient SIT |
| 좌 전환 | `turn_left_3q` | 정면→3/4 좌 |
| 좌 발 내딛기 | `step_out_left` | 3/4, 앞발 듦 |
| 좌 걷기 | `walk_left_a`…`walk_left_f` | 측면 6프레임 |
| 좌 정지 | `walk_stop_left` | |
| 좌→정면 | `turn_left_front` | 복귀 |
| 우 전환 | `turn_right_3q` | 정면→3/4 우 |
| 우 발 내딛기 | `step_out_right` | 3/4, 앞발 듦 |
| 우 걷기 시작 | `walk_start_right` | 측면 진입(우측 전용 추가 lead-in) |
| 우 걷기 | `walk_right_a`…`walk_right_f` | 측면 6프레임 |
| 우 정지 | `walk_stop_right` | |
| 우→정면 | `turn_right_front` | 복귀 |
| (단독) 생각 | `thinking` | 현재 미사용·예비 |

### 3-1. 소스 → 정식명 변환 이력 (2026-06-03 import)
소스 = `~/Downloads/호랑이-인트로 호랑이완성/` (Jin 최적화 폴더, 각 ~300–380KB). 정리 시 수정한 문제:
- 더블 확장자 `.png.png` ×3 (`notice_turn`, `notice_front`, `walk_right_a`) → 단일 `.png`
- 파일명 한글 ×2 (`4-2_front_정면_일어설준비1`→`rise_prep`, `tiger_thinking생각하는호랑이`→`thinking`)
- 숫자/접두 불일치(`1_optimized.`, `6-2tiger_`) 제거 → snake_case 통일

**드롭한 파일(픽셀 확인 후 — 중복/예비):** `turn_right_threeq`·`step_out_threeq_right`·`turn_right_front_prep`(각 `tiger_` 접두 없는 중복본 — 접두본을 좌측 명명과 통일해 채택) + `b-1tiger_walk_side_left_a`(walk_left_a 대체 take). 원본은 Downloads에 보존 → 필요 시 교체 가능.

### 3-2. ⚠️ 투명 배경 복원 (2026-06-03, 필수 후처리)
**소스 프레임 전부 알파 없음** — 비압축 원본은 `RGB`(흰색 ~(252,252,252) 불투명 배경, 옅은 체커보드), 최적화본은 그 RGB를 팔레트화한 `P`. 그대로 앱에 넣으면 **호랑이 뒤 흰 사각형**이 보임(Jin 실기기 포착). 수정 파이프라인(PIL):
1. **소스 재선정** — 품질 위해 **비압축 `최종 호랑이 이미지/` RGB 원본**에서 재키잉(팔레트 밴딩/디더 회피). 단 `rise_prep`은 비압축에 없어 최적화 `4-2`만 사용.
2. **배경 키잉** — 4모서리+가장자리 8~10점에서 `ImageDraw.floodfill(thresh≈46)`로 **테두리 연결 근백색만** 알파0 (호랑이 안쪽 흰색/크림은 보존, faceted 하드엣지라 헤일로 거의 0).
3. **재압축** — `convert('P', ADAPTIVE, 255색, dither=NONE)` + 알파0→예약 인덱스 255 + `transparency=255`. 35장 ≈10MB(투명영역 압축으로 불투명본보다 작음).
> 검증: 크림(#FAF6EC) 합성 육안(intro/idle/좌/우 대표 6장) — 흰 사각형·구멍·헤일로 0. 키잉 코드는 git 이력 참조(일회성 스크립트, repo 미커밋). **소스를 투명 PNG로 다시 export하면 이 단계 불필요.**

## 4. 시퀀스 & 타이밍 (구현값 — `tiger_stage.dart`와 동기)

> 단위 ms. **fade** = 다음 프레임으로의 크로스디졸브 길이(0 = 하드컷). **dwell** = 해당 프레임 체류.

### INTRO_GREETING (1회)
| 프레임 | dwell | fade |
|---|---|---|
| rest_idle | 650 | 0(즉시) |
| notice_turn | 300 | 200 |
| notice_front | 300 | 180 |
| smile_front | 460 | 200 |
| rise_prep | 300 | 160 |
| rise_half | 360 | 170 |
| stand_greet | 650 | 220 |

### FRONT_IDLE (루프)
`stand_greet`(1300) → `bob_a`(640) → `bob_b`(640) → `bob_a`(640) → 반복. fade 280 (느린 호흡).

### PACING (there-and-back)
1. `turn_{side}_3q` (dwell 240, fade 150)
2. `step_out_{side}` (170, 120)
3. (우측만) `walk_start_right` (120, 60)
4. **walk out**: `walk_{side}_a..f` ×2루프, 프레임당 **120ms 하드컷**, 동시에 dx `0 → ±span`
5. `turn_{opp}_3q` (220, 150) — 반대로 돌기
6. **walk back**: `walk_{opp}_a..f` ×2루프, dx `±span → 0`
7. `turn_{opp}_front` (300, 150) → FRONT_IDLE

- **span** = `(밴드폭 × 0.17).clamp(28, 80)` px. 작은 화면서 화면 밖 이탈 방지.
- **dx 동기:** 걷기 프레임 하드컷이라 프레임당 정확히 120ms → `_paceCtrl.duration = loops×6×120`으로 발걸음과 글라이드 일치.
- **moonwalk 방지:** 나갈 땐 진행 방향 프레임, 돌아올 땐 반대 방향 프레임.

### SIT
`sit_idle_a`(900, fade 220) → `sit_idle_b`(950, 320) → `stand_greet`(fade 260) → FRONT_IDLE.

## 5. 구현 (`TigerStage`)

```dart
TigerStage({ double height = 168, MascotEmotion fallbackEmotion = MascotEmotion.smile })
```

- **시퀀서:** 토큰 가드 재귀 Future. 새 행동 = `++_seqToken`; 모든 await 후 `_disposed || token != _seqToken` 체크 → 이전 시퀀스 자가 종료(setState-after-dispose 방지).
- **크로스페이드:** `Image.asset` 2장 스택(뒤 `1-_xfade.value` / 앞 `_xfade.value`). `AnimatedSwitcher` 대신 직접 제어(정확 ms·`gaplessPlayback` 무플리커). 걷기는 fade 0 하드컷.
- **reduce-motion** (`SoriMotion.reduceMotion` = `MediaQuery.disableAnimations`): build 첫 줄에서 `_staticBand()` 반환(정지 `stand_greet` 1장, 컨트롤러/타이머 0). 런타임 토글도 `didChangeDependencies`에서 `_stopLife()`로 처리.
- **degradation 2층:** ① 프레임별 `errorBuilder` → post-frame `_assetsOk=false` → 전체 `_staticBand`. ② `_staticBand`의 `Image.asset(stand_greet)` errorBuilder → `Mascot.tiger(fallbackEmotion)`(자체 이모지 fallback 보유). → **누락 시에도 깨진 이미지 0**.
- **precache:** `didChangeDependencies`에서 35장 `precacheImage`(가드 + `.catchError`).
- **lifecycle:** `WidgetsBindingObserver` — 백그라운드 시 타이머/컨트롤러 정지(`_seqToken++`), 복귀 시 `frontIdle` 재개(intro 아님).
- **ground shadow:** 발밑 부드러운 타원 그림자가 dx와 함께 이동 → 떠 보이지 않게.

## 6. 홈 통합

- `_TigerHero`(`home_screen.dart`): greeting + subline 텍스트(상단) → `TigerStage` 밴드(콘텐츠 폭 전체, height 150/168 반응형) + `_SpeechBubble` 좌상단 오버레이.
- 밴드는 `SoriContentClamp`(480) 안의 **콘텐츠 폭** 차지 → 걷는 가로 공간 확보. (배경/입자/까치 풀블리드는 기존 유지.)
- ⚠️ **edge-to-edge 풀블리드는 미적용(후속).** clamp 구조상 진짜 화면 끝까지 늘리려면 clamp의 가로 패딩을 "밴드 제외 나머지"로 분리해야 함 → 2026-06-03 좁은폰(308px) 튜닝 회귀 위험이 있어 Jin 육안 확인 후 결정. 현재도 "와이드 밴드"로 충분히 넓음.

## 7. English handoff (for another AI/dev)

```text
We are creating a consistent animated tiger asset set for an app mascot. The tiger must feel
like the same adult tiger in every frame: same face, same stripe logic, same amber eyes, same
orange/cream/black palette, same faceted low-poly geometric rendering, same body proportions,
and the same dignified-but-friendly guardian mood.

Three animation parts: (1) Intro Greeting — lying → notices the user → turns front → soft smile
→ rises → stands front to greet (plays once per launch). (2) Front Idle — front-facing, alive via
a subtle breathing loop (tiny chest/head motion, no pose change). (3) Ambient Pacing — occasionally
turns to a side, walks a few calm steps, turns back, returns to center. Relaxed, never aggressive,
never running or stalking.

Most important requirement: consistency. Use 3/4 views for rising and transitional poses, front
view for greeting and eye contact, side / strong 3/4 views for walking so the legs read clearly.
Premium semi-dimensional low-poly look, not a flat sticker.
```

## 8. 후속 / 미제작

- `lie_idle` 포즈(누운 휴식 변형) — REST는 현재 `rest_idle`로 충분. 추가 시 ambient에 편입.
- ✅ 추가 special: 기지개(stretch 3프레임)·포효(roar 6프레임) — **구현됨**(2026-06-03 "누락이미지" 드롭). `tiger_anim/`에 `stretch_prep/full/release`, `roar_prep/open/open2/full/close/recover`. `TigerStage._doStretch`/`_doRoar`가 ambient에서 turn_right로 진입·복귀하며 재생(확률 stretch 11% / roar 9%).
- `stand_idle_a/b`·`thinking`은 자산만 있고 미사용 — idle 다양성/특수 상태로 후속 활용 가능.
- 좌향 idle_hold용 `왼쪽보는*` 변형(비압축 폴더에만 존재) — 측면 정지 hold가 필요하면 import.
- edge-to-edge 풀블리드 밴드 (§6 참조).
- 살아있는 호랑이를 결과/통계 등 다른 화면으로 확장.
