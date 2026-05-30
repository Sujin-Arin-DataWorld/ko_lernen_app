# 살아있는 한옥 — 에셋 제작 명세 (Jin 제작용)

> "살아있는 한옥" UI/UX 대개편에 필요한 **이미지 파일 명세**.
> Claude가 코드(CustomPainter)로 그린 도형 대문은 폐기한다 — 모든 비주얼은
> Jin이 일러스트로 제작하고, Claude는 그 PNG를 코드로 **통합·애니메이션**만 한다.
> 스타일 기준: **Faceted Minhwa** (`~/Downloads/HANGUL_SORI_STYLE_GUIDE.md`).

---

## 공통 규칙

- **포맷**: PNG-24, 알파 채널 O (배경 투명). 명시된 경우만 배경 채움.
- **색 팔레트** (단청): 한지크림 `#FAF6EC` · 녹청 `#1F7A6B` · 석간주 `#C24A45` ·
  황 `#DFA951` · 먹 `#2C2419` · 황토 `#A87E5E` · 호랑이주황 `#FF8C42`
- **압축 불필요** — 원본 그대로 두면 Claude가 후처리 압축.
- 파일을 지정 경로에 넣고 **"넣었어"** 라고만 알려주면 Claude가 통합.
- 치수는 px 기준. 더 선명하게 2배 크기도 OK — **비율만 정확히** 유지.

---

## 1. 앱 로고 — 완료

**현재 상태**: `assets/icons/`의 `HanLogo.png` · `icon-512.png` · `icon-192.png`
3개가 Jin이 제작한 현재 로고 원본/파생본이다. 별도 `logo.png`/`logo_mark.png`로
이름을 바꾸지 않고 이 파일들을 정식 로고로 유지한다.

**코드 연결**:
| 파일 | 용도 |
|---|---|
| `assets/icons/HanLogo.png` | 런처 아이콘 생성 원본 + 네이티브 스플래시 |
| `assets/icons/icon-512.png` | 고해상도 파생 아이콘 |
| `assets/icons/icon-192.png` | 앱 내부 헤더·로딩 위젯 |

---

## 2. 솟을대문 — 인트로 (★1순위 · 레이어 분리 **필수**)

**현재 상태**: `gate_frame.png` · `gate_door_left.png` · `gate_door_right.png`
3개가 추가되어 인트로 코드에 통합됨. 현재 파일은 즉시 빌드 가능한 임시 SVG 기반
PNG이며, Jin 최종 일러스트이 오면 같은 경로/좌표계로 덮어쓰면 된다.

**업데이트 (2026-05-28)**: 빌드 사이즈 최적화를 위해 다음 파일을 lossily 압축했습니다. 원본 원본 파일은 `assets/illustrations/hanok/backup/`에 보관되어 있습니다.

- `assets/illustrations/hanok/gate_door_right.png` — compressed (242 KB). backup: `backup/gate_door_right.orig.png` (527 KB)
- `assets/illustrations/hanok/gate_final.png` — compressed (311 KB). backup: `backup/gate_final.orig.png` (337 KB)

압축은 `pngquant --quality=60-80 --speed 1`로 수행했습니다. 문제가 있을 경우 백업에서 원본을 복원하세요.

인트로에서 문이 **실제로 열려야** 하므로 한 장의 평면 PNG로는 불가능.
**3개 파일로 분리** 제작 — 모두 같은 좌표계에 등록(registration)되어야 함.

### 2-1. `assets/illustrations/hanok/gate_frame.png` — **1080 × 1920**
- 대문 **구조만**: 기와지붕 · 처마(끝이 위로 솟은 곡선) · 단청 띠 · 좌우 기둥 ·
  기단(주춧돌).
- **중앙 문간(doorway)은 완전 투명** — 정확한 직사각형 구멍:
  - 좌상단 `(195, 615)` → 우하단 `(885, 1615)` (즉 폭 690 × 높이 1000)
- 지붕 위 하늘·대문 바깥 영역도 **투명**.
- 정면(front elevation) 시점, 좌우 대칭.

### 2-2. `assets/illustrations/hanok/gate_door_left.png` — **345 × 1000**
- **왼쪽 문짝 하나만**. 캔버스를 문짝이 꽉 채움.
- 석간주 적(`#C24A45`) 바탕 + 황금 못(brass studs) 격자 + 문고리.
- 닫힌 상태 기준 — 경첩은 **왼쪽 가장자리**, 오른쪽 가장자리가 중앙선.

### 2-3. `assets/illustrations/hanok/gate_door_right.png` — **345 × 1000**
- 오른쪽 문짝. `gate_door_left`의 좌우 대칭. 경첩은 **오른쪽 가장자리**.

→ 셋을 쌓으면 **닫힌 솟을대문** 완성. Claude가 문짝 2개를 경첩 기준
perspective 회전 → 문이 열림 → 카메라가 통과 → 마당(아래 배경)으로 진입.
→ **문 너머 배경**: 기존 `madang(light).png` 재사용 (별도 제작 불필요).

> 💡 비율 유지하면 2160×3840(2배)로 더 선명하게 만들어도 됨. 문간 구멍은
> 캔버스의 가로 18%~82%, 세로 32%~84% 위치 — 어떤 크기든 이 비율 지키면 됨.

---

## 3. 마스코트 — 호랑이 / 까치 포즈 세트 (★2순위 · Phase 3)

**현재 상태**: 기존 `assets/illustrations/hanok/` 아래에 있던 포즈 PNG를
`assets/illustrations/mascot/`로 정리했고, `Mascot`/`FlyingMagpie` 위젯이 이
분리 파일을 사용한다. 현재 파일은 1024×1024 원본이며 앱에서는 크기에 맞춰 표시된다.

`welcome-hero.png`(호랑이+까치 합본 1장)는 눈 깜빡임·날갯짓 같은 부분 동작이
불가능. **캐릭터별·포즈별로 분리** 제작.

### 호랑이 — `assets/illustrations/mascot/tiger_*.png` · 각 **768 × 768** 투명
모든 포즈에서 **몸의 위치·크기를 동일하게** (바뀌는 부분만 다르게 그리면 →
제자리에서 자연스럽게 표정이 바뀜):
| 파일 | 표정 | 용도 |
|---|---|---|
| `tiger_idle.png` | 기본, 정면 잔잔한 미소 | 평상시 (홈·대화) |
| `tiger_blink.png` | idle와 똑같되 **눈만 감음** | 깜빡임 |
| `tiger_happy.png` | 활짝 웃음 | 진척·칭찬 |
| `tiger_celebrate.png` | 만세/신남, 별눈 | 정답·완료·레벨업 |
| `tiger_sad.png` | 시무룩, 눈썹 처짐 | 오답·streak 0 |

### 까치 — `assets/illustrations/mascot/magpie_*.png` · 각 **512 × 512** 투명
갓 쓴 까치. 비행은 날개 2장 교대로:
| 파일 | 포즈 |
|---|---|
| `magpie_perched.png` | 앉음, 날개 접음 |
| `magpie_wingup.png` | 날개 위로 (비행 프레임 1) |
| `magpie_wingdown.png` | 날개 아래 (비행 프레임 2) |
| `magpie_celebrate.png` | 좋은 소식 전하는 신난 모습 |

---

## 4. (선택) 인트로 전용 마당

기본은 `madang(light).png` 재사용. 더 화사한 "환영" 장면을 원하면:
- `assets/illustrations/hanok/madang_intro.png` — 1080×1920, 문 너머로 보일
  밝은 낮의 한옥 마당 (호랑이가 마당에서 기다리는 모습 등).

---

## 우선순위 요약

1. **로고 3종** (`HanLogo.png` · `icon-512.png` · `icon-192.png`) — 완료/통합
2. **솟을대문 3종** (`gate_frame` · `gate_door_left` · `gate_door_right`) — 완료/인트로 통합
3. **마스코트 포즈** (호랑이 5 · 까치 4) — 완료/위젯 통합
4. (선택) `madang_intro.png`

추후 최종 일러스트를 교체할 때는 같은 파일명과 투명 배경/좌표계를 유지하면 코드 수정 없이 반영된다.
