# assets_unused/ — 미사용 에셋 보관소 (2026-07-30)

> **왜 여기에**: 2026-07-30 에셋 트리거 전수조사(`docs/ASSET_TRIGGER_AUDIT_2026-07-30.md`)에서
> 코드가 렌더하지 않는 것으로 확정된 파일들을 **삭제하지 않고** 한곳에 모음(Jin 지시).
> 이 폴더는 `assets/` 밖이라 **pubspec에 안 잡혀 APK에 절대 번들되지 않음**.
>
> **복원법**: 아래 표의 원경로로 `git mv` 한 줄이면 끝 (pubspec은 디렉터리 단위 등록이라 추가 수정 불필요).
> 예: `git mv assets_unused/video/tiger_greet.mp4 assets/video/`

## 1. 구버전 영상 (2) — 대체됨

| 파일 | 원경로 | 무엇 / 왜 미사용 |
|---|---|---|
| `video/tiger_greet.mp4` | `assets/video/` | 구 3D풍 호랑이 인사(640², 2026-06-12 세대). 2026-07-29 캐논 호랑이 `character/tiger_rise.mp4`로 교체. 롤백하려면 복원 후 `tiger_video.dart`의 `greetAsset` 상수만 되돌리면 됨 |
| `video/tiger_pace.mp4` | `assets/video/` | 구 왔다갔다 루프. `character/tiger_rest.mp4`로 교체 (동일 롤백 절차, `paceAsset`) |

## 2. hanok 일러스트 (4)

| 파일 | 원경로 | 무엇 / 왜 미사용 |
|---|---|---|
| `illustrations/hanok/dancheong_frame.png` | `assets/illustrations/hanok/` | 워들 게임판 단청 프레임 오버레이 — 2026-05-29 입력칸 겹침으로 **의도적 제거**(wordle_screen 주석 잔존) |
| `illustrations/hanok/gate.png` | `assets/illustrations/hanok/` | 솟을대문 단일 일러스트 — **홈페이지(hangul-sori.com) final-cta용**. 홈페이지는 `docs/assets/` 사본을 쓰므로 앱 레포에선 미참조 |
| `illustrations/hanok/gate_entrance.png` | `assets/illustrations/hanok/` | 인트로 영상(`intro_gate_to_madang.mp4`)의 **소스 키프레임**. 영상 완성 후 코드 참조 0 (재렌더 시 소스로 유용 → 보관) |
| `illustrations/hanok/madang(dark).png` | `assets/illustrations/hanok/` | 홈 배경 다크 변형 — 앱이 **라이트 전용**(`themeMode.light` 고정)이라 도달 불가. 다크모드 부활 시 복원 |

## 3. 마스코트 (2)

| 파일 | 원경로 | 무엇 / 왜 미사용 |
|---|---|---|
| `illustrations/mascot/tiger_happy.png` | `assets/illustrations/mascot/` | 과거 surprised 감정의 대역 — 전용 `tiger_surprised.png` 투입 후 매핑에서 빠짐 |
| `illustrations/mascot/magpie_perched_alt.png` | `assets/illustrations/mascot/` | 앉은 까치 대체 포즈(v2 복원분) — emotion 매핑에 슬롯 없음. ⚠️ `tool/integrate_jongga_assets.py` 재실행 시 이 파일을 다시 만들어 넣으니 주의 |

## 4. 데드 아카이브 (22) — 원래부터 번들 안 되던 것들

**"데드"의 뜻**: pubspec은 디렉터리를 **비재귀**로 등록하는데, 아래 두 폴더는 등록된 적이 없어
APK에 들어간 적조차 없음. 코드 참조도 0. 순수 레포 보관물.

> **✅ 2026-07-30 Jin 검토 후 영구 삭제**: 아래 데드 아카이브 21장(walk 프레임 15 + gate 원본 백업 6)은
> Jin이 직접 확인 후 삭제함(git에서 완전 제거). `tiger_anim_archive/thinking.png` 1장만 잔존.
> 표는 기록 목적으로 유지 — 무엇이었는지 추적용.

| 폴더 | 원경로 | 무엇 | 상태 |
|---|---|---|---|
| `illustrations/tiger_anim_archive/` walk 15 | `assets/illustrations/tiger_anim_archive/` | **구세대 호랑이 보행 프레임** — `walk_left_a~f`·`walk_right_a~f`(6프레임 보행)·`walk_start_right`·`walk_stop_left/right`. 신형 8프레임(`tiger_anim/walk_*_01~08`)으로 대체된 아카이브 | ❌ 삭제됨 |
| `illustrations/tiger_anim_archive/thinking.png` | 〃 | 구 호랑이 "생각 중" 정지 프레임 | 📦 잔존 |
| `illustrations/hanok/backup/` (6) | `assets/illustrations/hanok/backup/` | **인트로 대문 아트 원본 백업** — `gate_door_left.orig2`·`gate_door_right.orig`/`orig2`·`gate_final.orig`·`gate_final.with_gate`·`gate_frame.orig2`. 2026-06-01 대문 knockout(문/프레임 분리 투명화) 작업 전 원본들 | ❌ 삭제됨 |

---

### 이번에 이동 **안 한** 것들 (조사에선 고아였지만 2026-07-30 배선으로 부활)

- `hanok/welcome-hero.png` → 캐릭터 선택 화면 헤더 포스터 (+ `loops/welcome_hero.mp4` 루프)
- `video/character/` 7클립(choose×2·flight·roar·bob·stretch·perched) → 선택 카드/확정 체인·밀스톤·끝말잇기·복습 완료 등에 배선
- `video/loops/` 7편(scene_*×5·welcome_hero·hanok_construction) → 시나리오 인트로·선택 헤더·온보딩 page1에 배선
- `hanok_stages/` 12장 → 원래부터 학습경로 헤더가 렌더 중이었음 (조사 §5 오판정 — 문서 정정됨)
