# 에셋 생산 계획 (R6 실행판)

**작성** 2026-08-03 · **대상** `ko_lernen_app`
**선행** `ASSET_GAP_R6_CONFIRMED_2026-08-03.md`(무엇이 빈지) · `ASSET_GENERATION_BIBLE.md`(어떻게 그리는지) · `DESIGN_OVERHAUL_PLAN_2026-08-02.md` §5·§8
**이 문서의 역할** 앞 두 문서는 *목록*과 *화풍 규칙*이다. 여기서는 **누가 · 무엇을 · 어떤 순서로 · 어떤 검수를 통과해야 끝인지**를 정한다.

---

## 0. 상속되는 절대 규칙 (재확인, 변경 없음)

> ⛔ **호랑이(태고)·까치(조이) 캐릭터의 AI 재생성 금지.** 캐릭터가 등장하는 신규/합성 이미지는 기존 PNG를 **배치·합성**한다.
> **캐논 앵커** 호랑이 `mascot/tiger_front.png` + `mascot/tiger_right_stand.png` · 까치 `mascot/magpie_wave.png` · `magpie_sing.png` · `magpie_encourage.png`
> ✅ **만들지 않음** 다크 한옥 12단계(`themeMode.light` 고정).

**영상 규격 계약 (§0)** — 순백 `#FFFFFF` · 960×960 · 24fps · CRF19 · yuv420p · `+faststart` · **무음** · 전 프레임 픽셀 검수.
배경이 정확히 `#FFFFFF`가 아니면 `ColorFiltered(BlendMode.multiply)`에서 화면에 회색 판으로 찍힌다. **근사 흰색은 불합격이다.**

**마스코트 PNG 규격 (BIBLE §2.2)** — 1254² 또는 1536² · 진짜 RGBA · 4~8% 투명 패딩 · 한지 그레인은 색면 위에만 · `pngquant --quality=65-85` → ~300KB.

---

## 1. 지금 닫힌 것 — §3-2 빈/오류 배선 (신규 이미지 0)

2026-08-03 세션에서 **코드 배선만으로 완료**. 새로 그린 이미지 0장.

| 위젯 | 이전 | 현재 |
|---|---|---|
| `AppError` | 8곳 전부 빨간 `error_outline` 아이콘 | **위젯 기본값** `kTaegoErrorAsset = mascot/tiger_front.png` — 호출부 수정 0건으로 8화면 동시 적용 |
| `SoriEmptyState` | 32 호출부 중 6곳만 일러스트 | **32/32 배선** |
| `AppEmpty` | 일러스트 슬롯 없음, `grammar_screen` 1곳 사용 | `SoriEmptyState`로 교체 후 `@Deprecated` — 빈 상태 표준이 하나로 수렴 |

**배선 규칙 (§5.3 역할 맵 준수)**

| 의미 | 마스코트 | 적용처 |
|---|---|---|
| 오류·찾을 수 없음 | `tiger_front` (태고 = 신뢰·복구) | `AppError` 전체 + `*NotFoundTitle` 6곳 |
| 완료·성취 | `magpie_celebrate` | Knifflige Wörter 없음 · 복습 완료 · 세션 완료 |
| 초대·시작 | `magpie_wave` | Meine Wörter · 즐겨찾기 · 단어장 검색 · 팩 목록 · 문법 |
| 격려 (데이터가 없어 기능을 못 엶) | `magpie_encourage` | custom_pack 5종 · cloze · 듣기 · 문장 아케이드 · 스몰토크 · 스피드매치 · 끝말잇기 · 퀘스트 · 도장첩 |
| 대기 | `magpie_perched` | 빈 Lerngruppe(`gye_screen`) |

> **판단 근거 하나만 남긴다.** `*NotFound*`는 "아직 없다"가 아니라 "있어야 하는데 못 찾았다"라 오류로 분류해 태고를 붙였다. 조이는 "네가 채우면 된다"는 초대·격려 쪽만 맡는다. 이 경계가 틀렸다고 보시면 `*NotFound*` 6곳만 `magpie_perched`로 옮기면 된다.

---

## 2. 남은 생산 대상 — 담당별 3계층

에셋을 "누가 만들 수 있는가"로 먼저 가른다. 이게 우선순위보다 앞선다.

| 계층 | 대상 | 담당 | 근거 |
|---|---|---|---|
| **A. 세션/AI 생성 가능** | 시나리오 배경 7종 (`home`·`airport`·`taxi`·`convenience`·`clinic`·`office`·`station`) | 세션 | **인물 0** — 캐릭터가 안 나오므로 §0 재생성 금지에 걸리지 않음 |
| **B. Jin 캐논 제작 전용** | Joy 클립 P0~P4 · 온보딩 3장 · 호랑이 클립 재제작 | Jin | 캐릭터가 등장 → AI 생성 금지 |
| **C. 코드만** | 빈/오류 배선 · Joy 임시 폴백(§2-1) | 세션 | 이미지 0장 |

**계층 A가 유일하게 "지금 세션이 밀어붙일 수 있는" 신규 생성이다.** B는 목록을 아무리 정교하게 써도 Jin이 그리기 전엔 0으로 남는다. 그래서 이 계획의 실행 무게는 A와 C에 둔다.

---

## 3. 계층 A — 시나리오 배경 7종 (신규 생성)

### 3.1 왜 여기가 1순위인가

현재 배경 5장으로 시나리오 33개를 돌려막고 있다. `home` 1장이 캐주얼 7개를 한 번에 해소하므로 **투자 대비 1위**. 커버리지 5 → 11~12.

### 3.2 생산 스펙

| 항목 | 값 |
|---|---|
| 경로 | `assets/illustrations/scenes/scene_{key}.png` |
| 치수 | 시나리오 포스터 규격 확인 후 확정 — `scene_asset_resolver.dart` 소비처 기준 |
| 팔레트 | BIBLE §1.3 hex만 |
| 구도 | §1.4 — 전경 피사체 캔버스 <30%, 겹침 평면 깊이, 그라데이션 1개 max |
| 인물 | **0명** (캐릭터 금지 규칙 회피의 핵심 조건) |
| 텍스트 | 무문자 — 간판·화이트보드·노선도 전부 글자 없이 |

### 3.3 프롬프트 골격 (BIBLE §1.5 템플릿 + 자산별 델타)

```
A wide horizontal editorial illustration of {SCENE}.
{ONE-SENTENCE MOOD}.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial quality.

Composition layered front to back:
LAYER 1 — {상단/하늘}: {요소 + hex}
LAYER 2 — {중경}: {요소 + hex}
LAYER 3 — {전경 초점}: {요소 + hex}

ATMOSPHERIC DETAILS:
- Dancheong dots in 2 loose groupings (red #C24A45, gold #DFA951, teal #3D9A7F)
- NO people, NO figures, NO text, NO signage lettering

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT {허용 1개}
- Subtle hanji paper grain texture overlay across the entire image
- Restricted palette (hex): {§1.3에서 실제 쓴 hex 나열}
- Clear silhouette readability at thumbnail size (100px)

ABSOLUTELY AVOID: people, human figures, readable text, sepia wash,
uniform mid-gray, crane birds, mixed seasons, 3D render, watercolor.
```

레퍼런스를 붙일 때는 **§1.6 마감 문장을 항상 마지막에** 넣는다.

### 3.4 7종 델타

| key | 소비 시나리오 | LAYER 3 (전경 초점) | 주의 |
|---|---|---|---|
| `home` | 캐주얼 7개 | 좌식 상·방석·창호문, 따뜻한 목재 | 계절 1개로 고정 |
| `airport` | 출입국 계열 | 체크인 카운터 실루엣·수하물 벨트 | 항공사 로고·문자 금지 |
| `taxi` | 이동 계열 | 택시 뒷좌석 시점·미터기(무문자) | 번호판 문자 금지 |
| `convenience` | 편의점 | 진열 선반·냉장 도어 | 상품 라벨 문자 금지 |
| `clinic` | 병원/약국 | 약국 카운터 or 진료 의자, 십자 심볼(무문자) | 의료 텍스트 금지 |
| `office` | 회사/면접 | 회의 테이블·화이트보드(무문자) | 문자 금지 |
| `station` | 지하철/KTX | 승강장·환승 통로, 노선 스트립(무문자) | 역명 문자 금지 |

### 3.5 후속 (선택)

각 배경에 앰비언트 루프 `loops/scene_{key}.mp4`(무음·미세 모션)를 나중에 붙일 수 있다. **포스터 PNG가 먼저, 루프는 후속.**

---

## 4. 계층 B — Joy 클립 (Jin 제작 · 세션은 검수만)

목록·우선순위는 GAP §2에 확정돼 있으므로 여기서 반복하지 않는다. **이 계획이 추가하는 것은 "도착했을 때 무엇을 통과해야 하는가"다.**

| 우선 | 파일 | 참조 포즈 (재생성 아님) |
|---|---|---|
| P0 | `magpie_bob.mp4` | `magpie_encourage` |
| P1 | `magpie_thinking.mp4` | `magpie_sing` + `magpie_encourage` |
| P2 | `magpie_flourish.mp4` | `magpie_wave` |
| P3 | `magpie_soar.mp4` | `magpie_wave` + `wingup/wingdown` |
| P4 | 프로필 포즈 +2 | 위 세 포즈 |

### 4.1 Jin 영상 도착 전 임시 완화 (신규 에셋 0 — 지금 가능)

GAP §2-1: `path_trail`(J1)·`kkeunmari`(J2)의 까치 분기를 정지 `magpie_perched` 클립 대신 **`Mascot(kind: magpie, animate: true)`**(wingup↔wingdown 날갯짓)로 폴백. 새 영상 없이 "얼어붙은" 인상만 걷어낸다. **실기기 확인 후 Jin 채택 판단.**

### 4.2 P0 `magpie_bob`이 P1보다 먼저인 이유

`path_trail`의 "지금" 노드는 앱에서 가장 자주 보이는 캐릭터 자리다. 여기가 정지면 경로 전체가 죽어 보인다. 나머지는 특정 화면에 들어가야 보인다.

---

## 5. 검수 계약 — 자동화 (`tool/clip_normalize.py`)

> **"에셋 납품 전 전 프레임 픽셀 스캔"** 규칙을 사람 눈이 아니라 스크립트로 강제한다. 첫 프레임만 보면 결함을 놓친다.

**역할 분담 — 도구를 새로 늘리지 않는다.**
`tool/check_clip_matte.py` 가 **게이트**(배경 순백 판정 → `tool/clip_matte_report.json` → `test/character_clip_matte_test.dart`)이고, `tool/clip_normalize.py` 는 **변환 + 매트가 보지 않는 모션 항목**을 맡는다. 변환 후 반드시 게이트를 다시 돌린다.
2026-08-03 기준 18개 클립 전부 `#FFFFFF` 100% 통과(0 실패).

`tool/clip_normalize.py` 로 동봉. 캐릭터 클립이 도착하면 **무조건 이걸 통과해야 배선한다.**

```bash
python3 tool/clip_normalize.py <입력.mp4> <출력.mp4> <입력폭> <입력높이> [--pingpong]
```

측정 항목과 합격선:

| 지표 | 의미 | 합격선 |
|---|---|---|
| 배경 순백도 `frac<255` | `multiply` 합성 잔상 | **0.00%** (기존 `tiger_rest` 1.69%가 하한선) |
| 피사체 면적 변동 | 카메라 고정 / 줌 없음 | < 5% (걸어오는 클립은 예외) |
| 발 접지 하단 y 변동 | 발이 미끄러지거나 프레임에 잘리는지 | < 20px, **하단 여백 0px 프레임 0개** |
| 인접프레임 평균차 최대 | 컷·모핑·플리커 | < 6 |
| 루프 이음새 / 인접 평균 | `loop: true` 자리에 쓸 수 있는지 | **≤ 2배** |
| 오디오 스트림 | §0 무음 계약 | 0개 |

`clean_background()`는 **테두리에서 flood-fill**로 배경과 옅은 바닥 그림자만 순백으로 올린다. 까치의 흰 가슴·회색 날개는 검은 깃털에 둘러싸여 배경과 끊겨 있으므로 건드려지지 않는다 — 채도·밝기 단순 임계로 지우면 까치가 뚫린다.

### 5.1 실측 사례 (이 계약이 왜 필요한지)

2026-08-03 도착분 3종의 변환 전/후:

| 클립 | 배경 순백도(전→후) | 루프 이음새 | 처리 |
|---|---|---|---|
| `tiger_thinking` | 93.7% 오염 → **0.00%** | 16.4배 | 크로스페이드는 꼬리·귀 잔상(캐논 위반) → **핑퐁**으로 0.1배 |
| `tiger_walking_front` | 90.7% 오염 → 상단 0.003% | 8.3배 | **원샷 전용** 판정 |
| `tiger_magpie_play` | 바닥 그림자 6.00% → **0.14%** | 4.7배 | flood-fill 제거 |

세 클립 모두 **1440×1440으로 도착**했다. 규격은 960이다. 생성기 출력을 그대로 넣으면 규격 위반이 기본값이 된다 — 그래서 변환을 사람 손에 맡기지 않는다.

---

## 6. 신규 호랑이 클립 2종 — 배선 경고 (GAP §2-2)

| 클립 | 상태 | 배선 규칙 |
|---|---|---|
| `tiger_walking_front.mp4` | 카탈로그에 상수만 추가(`CharacterClips.tigerWalkingFront`), 역할 함수 미배선 | ⛔ **kind-분기 역할에 넣지 말 것** — 짝 `magpie_*_forward`가 없어 조이가 또 정지로 떨어진다. 넣으려면 까치 대응 영상이 먼저. 또한 피사체가 38% 커지고 이음새 8.3배라 **`loop: false` 전용** |
| `tiger_magpie_play.mp4` | 미배선 | 둘 다 등장 → **중립**. 홈·마일스톤 등 **캐릭터 선택과 무관한 화면**에만 배선 가능 |

---

## 7. 실행 순서

| # | 작업 | 담당 | 신규 이미지 | 선행 |
|---|---|---|---|---|
| 1 | ~~빈/오류 배선~~ | ~~세션~~ | ~~0~~ | ✅ **완료 (2026-08-03)** |
| 2 | 시나리오 배경 `home` 1장 | 세션 | 1 | 소비처 치수 확인 |
| 3 | Joy 임시 폴백(§2-1) 실기기 확인 | 세션 → Jin 채택 | 0 | — |
| 4 | 배경 `airport`·`taxi`·`convenience` | 세션 | 3 | #2 화풍 승인 |
| 5 | Joy P0 `magpie_bob` | **Jin** | 1 클립 | — |
| 6 | 배경 `clinic`·`office`·`station` | 세션 | 3 | #4 |
| 7 | Joy P1 → P2 → P3 → P4 | **Jin** | 4+ | #5 |
| 8 | 온보딩 3장 캐논 재제작 | **Jin** | 3 | — |

**하지 않음** 다크 한옥 12단계 · 캐릭터 AI 재생성 · `tiger_walking_front`의 kind-분기 배선.

---

## 8. 결정이 필요한 항목

1. **시나리오 배경 치수** — `scene_asset_resolver.dart` 소비처 기준 실측 필요. 한옥 배경(1236×2700)과 다를 가능성이 높다.
2. **`*NotFound*` 6곳의 마스코트** — 현재 태고(오류 해석). 조이로 옮길지 §1 각주 참조.
3. **`tiger_magpie_play` 배선 위치** — 중립 클립이라 홈/마일스톤 후보. 어느 화면에 넣을지.
4. **Joy 임시 폴백(§2-1) 채택 여부** — 실기기 확인 후.

---

*근거 파일: `docs/ASSET_GAP_R6_CONFIRMED_2026-08-03.md` · `docs/ASSET_GENERATION_BIBLE.md` §1.3~1.8·§2.2~2.3·§6~§8 · `docs/DESIGN_OVERHAUL_PLAN_2026-08-02.md` §5.3·§8.1 · `lib/widgets/app_error.dart` · `lib/widgets/sori/empty_state.dart` · `lib/widgets/sori/character_clip.dart` · 클립 실측 3종(2026-08-03 세션).*
