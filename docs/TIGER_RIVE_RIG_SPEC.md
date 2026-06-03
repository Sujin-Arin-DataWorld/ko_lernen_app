# 호랑이 Rive 리그 제작 명세 (tiger.riv)

> **목표:** 호랑이가 **앉아있다 → 유저가 들어오면 쳐다보고 → 웃고 → 일어서서 → 왼쪽·오른쪽 왔다갔다**를, 프레임 끊김 없이 **부드럽게(보간)** 재현하는 Rive 리그.
> **이 문서는 핸드오프용** — Rive 에디터에서 이대로 만들거나, 외주에 그대로 전달.
> **앱 통합은 이미 완료** — `assets/rive/tiger.riv`를 넣고 `flutter pub get`만 하면 코드 변경 0으로 가동. 없으면 기존 프레임 호랑이로 자동 폴백.

---

## 1. 앱이 요구하는 "계약" (리그가 맞춰야 할 것)

통합 코드: `lib/widgets/sori/tiger_stage_rive.dart`. 다음을 가정한다 —

| 항목 | 값 | 의미 |
|---|---|---|
| 파일 경로 | `assets/rive/tiger.riv` | 이 경로/이름 고정 |
| 렌더러 | **Flutter(Skia) renderer** (`Factory.flutter`) | 이 렌더러가 지원하는 기능만 사용(대부분 OK; 특수 셰이더·블러 등 일부 미지원 가능) |
| 아트보드 | **default 1개** | RiveWidgetBuilder가 default artboard 사용 |
| 상태머신 | **default 1개, 자동 재생** | 입력(input) 없이 전체 시퀀스가 돌게 만들면 Flutter는 임베드만 함 |
| fit | `contain` | 아트보드가 밴드 높이(≈150–168px)에 contain |
| reduce-motion | 신경 X | 접근성 reduce-motion이면 Flutter가 Rive 대신 정지 프레임 표시 |

→ **핵심: "default 상태머신 하나가 입력 없이 전체 동작을 자동 재생"** 하게 만들면 가장 간단하다. (입력 노출도 가능 — §5 참고.)

---

## 2. 아트보드

- **비율: 가로로 약간 넓게(예 5:4 ~ 16:10).** 호랑이가 그 안에서 좌우로 걸을 여백 확보. (정사각이면 pacing 공간이 좁음.)
- 호랑이는 아트보드 하단 중앙 바닥에 서 있는 기준.
- 배경 없음(투명). 홈 밴드의 마당 그라데이션 위에 얹힌다.

## 3. 베이스 아트 & 리깅

- **기존 투명 PNG 재사용** — `assets/illustrations/tiger_anim/`의 호랑이를 import. 새로 안 그려도 됨.
  - 정면 idle/인사 = `stand_greet.png`(정면 서있음), `rest_idle.png`(앉음/누움)
  - 측면 걷기 참고 = `walk_left_a..f.png`, `walk_right_a..f.png`
- **리깅 방식: 본(bone) + 메시(mesh) 변형.**
  - 본: 척추(spine 2–3관절), 머리(head)+턱/입, 앞다리×2, 뒷다리×2, 꼬리(tail 2–3관절). (선택: 눈/귀)
  - 몸통·다리·머리에 메시를 씌워 관절에서 부드럽게 휘게.
- **시점 한계(중요):** 메시 변형은 정면→완전 측면 같은 **시점 회전은 못 함**. 두 가지 선택:
  - **(권장·단순)** 걷기를 **약한 3/4 정면 유지 + 다리 사이클 + 좌우 슬라이드**로. 완전 측면이 아니어도 "왔다갔다"는 자연스럽게 읽힘.
  - **(고급)** 정면 리그 + 측면 walk를 **별도 아트(기존 walk PNG)로 스왑/blend**. 더 사실적이나 작업량↑.

## 4. 타임라인 (애니메이션 클립)

| 클립 | 내용 | 비고 |
|---|---|---|
| `Sit` | 앉은 채 미세 호흡(가슴·머리 살짝) | 진입 시작 포즈 |
| `Notice` | 고개 들어 정면(유저) 응시 | 0.3–0.5s |
| `Smile` | 눈매·입 부드럽게(살짝 눈 가늘게/입꼬리) | blend로 겹쳐도 됨 |
| `Rise` | 앉→섬 (척추·다리 펴짐) | 0.4–0.7s, ease |
| `IdleStand` | 선 채 호흡 루프(loop) | 기본 대기 |
| `WalkRight` | 다리 사이클 + 아트보드 내 **오른쪽 이동** | loop 가능, ease in/out |
| `WalkLeft` | 좌측 버전 | |
| (선택)`Sit↔Stand` 전이 | 다시 앉기 등 | ambient 다양성 |

- 모든 전이는 **blend/이징**으로 부드럽게(끊김 방지가 핵심 목적).
- 걷기는 12–24fps 키프레임 권장(보간되므로 키 몇 개면 매끄럽다).

## 5. 상태머신 (default, 자동 재생)

```
Entry → Sit
  └─(0.6–1.0s 후 자동)→ Notice → Smile → Rise → IdleStand
IdleStand ─(타이머 3–7s, 랜덤/순차)→ WalkRight → IdleStand
          ─(타이머)──────────────→ WalkLeft  → IdleStand   (무한 ambient)
```
- **입력 없이** 타이머/자동 전이로 위 루프가 돌게. → Flutter는 임베드만(가장 단순·견고).
- **(선택) 입력 노출 시:** `greet`(Trigger), `walk`(Bool), `dir`(Number −1/+1). 노출하면 Flutter에서 제어 가능하나, 현재 통합은 **자동 재생**을 가정하므로 노출 안 해도 됨. (노출하면 추후 코드에서 hook 가능.)

## 6. 익스포트 & 적용

1. Rive 에디터에서 **Export → Runtime (`.riv`)** (에디터 `.rev` 아님).
2. 파일명 `tiger.riv` → `assets/rive/tiger.riv`에 저장.
3. `flutter pub get` → `flutter run`. 끝. **코드 변경 0.**
4. 안 보이면: 콘솔에서 폴백 사유 확인(파일 경로/렌더러 호환). reduce-motion이면 정지 프레임이 정상.

## 7. 제작 경로

- **DIY:** [rive.app](https://rive.app) 무료 에디터(웹/데스크탑). 메시·본 리깅 + 상태머신 학습 곡선 있음(수 시간~). 공식 튜토리얼 충실. 원하면 단계별 워크스루 따로 써줄 수 있음.
- **외주:** 이 문서 + `assets/illustrations/tiger_anim/` PNG 세트 전달. "캐릭터 메시 리깅 + 상태머신" 견적 대략 $100–300. 산출물 = `tiger.riv` 1개.

## 8. 왜 Rive인가 (요약)

프레임 PNG는 장수에 묶여 끊기고, AI 사이프레임은 호랑이가 떨린다(boiling). Rive는 **그림 1장을 보간 변형** → 60fps 매끄러움 + 일관성 + 수십 KB. 듀오링고 캐릭터 방식. (배경: `docs/TIGER_ANIMATION_SPEC.md`.)
