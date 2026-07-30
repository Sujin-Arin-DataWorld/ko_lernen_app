# 이미지·영상 에셋 트리거 전수조사 (2026-07-30)

> **목적**: `assets/` 안의 모든 이미지/영상(223개)이 **실제로 코드에서 트리거(렌더)되는지** 여부와 **트리거 위치·조건**을 전수 파악.
> **방법**: 디스크 인벤토리 → 각 매퍼 위젯(`mascot.dart`, `tiger_stage.dart`, `character_clip.dart`, `hanok_header.dart`, `madang_background.dart`, `sticker_catalog.dart`, `dancheong_stamp.dart`, `decoration_layer.dart`, `gate_art.dart`, `gye_hanok.dart`, `hanok_cinematic.dart`, `quest_catalog.dart` 등) 정독 → 소비처(instantiation) grep. 간접 참조(emotion→png, 프레임 시퀀스, 카탈로그, 파일명 유도)까지 추적.
>
> **⚠️ 정정 이력 (2026-07-30 당일 2차)**:
> 1. **§5 hanok_stages 판정 오류 정정** — 초판이 "11장 렌더 경로 없음"이라 했으나 `learning_path_screen.dart`의 `_HanokHeader`가 `stage_${slug}_light.png`를 **보간 문자열로 렌더**하고 있었음(리터럴 grep이 못 잡은 것). 12장 전부 학습경로에서 도달 가능. 단 `sideBuilding` slug 오타(`side_building`≠파일명 `sidebuilding`)로 1장만 404였음 → **수정 완료**.
> 2. **미배선 클립 7 + 루프 7 전량 배선 완료** + `welcome-hero.png` 부활 (아래 표들에 반영).
> 3. **잔여 고아 8 + 데드 22 → `assets_unused/`로 이동**(삭제 아님, `assets_unused/README.md` 참조).

---

## 0. 요약 (2026-07-30 조치 후)

| 구분 | 조사 시점 | 조치 후 |
|---|---:|---:|
| **총 미디어 파일** | 223 | 223 (30은 `assets_unused/`) |
| ✅ 트리거됨 (조건부 포함) | 167 | **193** (+클립7 +루프7 +welcome-hero +stages11 정정) |
| ❌ 번들되지만 미트리거 (고아) | 34 | **0** (14+1 배선 부활 · 11 오판정 정정 · 8 이동) |
| 💀 데드 (pubspec 미등록) | 22 | **0** (전부 `assets_unused/`로 이동) |

**2026-07-30 배선 내역 (전부 `videoReady && !reduce-motion` 게이트 + 정적 폴백):**

| 자산 | 새 트리거 위치 |
|---|---|
| `tiger_bob` · `magpie_perched` (mp4) | 캐릭터 선택 후보 카드 살아있는 루프 (`character_selection`) |
| `tiger_choose` · `magpie_choose` | 선택 확정 목례/착지 → greet 체인 1단계 (`character_selection`) |
| `tiger_roar` / `magpie_flight` | 밀스톤 축하 시트 — 선택 캐릭터별 (`milestone_celebration`) |
| `tiger_thinking` | 끝말잇기 호랑이 턴 "생각 중" 루프 (`kkeunmari_screen`) |
| `tiger_stretch` | 복습 세션 완료 카드 (`review_session_screen`) |
| `loops/scene_*` 5종 | 시나리오 인트로 아트 앰비언트 루프 (`scenario_player` `_ScenarioIntroArt` + 신규 공용 `SoriPosterLoop`) |
| `loops/welcome_hero` + `hanok/welcome-hero.png` | 캐릭터 선택 화면 헤더 배너 (`HanokHeader` 명시 loopAsset) |
| `loops/hanok_construction` | 온보딩 프리뷰 page1 한옥 건축 루프 (`onboarding_preview`) |
| `decorations/` 18종 (기존 퀘스트 썸네일 유지) | **추가**: 학습경로 한옥 헤더 위 `DecorationLayer` 합성 (완료 퀘스트 장식, Jin 승인) |

---

## 1. video/ (30개 = character 16 + loops 13 + intro 1)

### 1-1. `assets/video/character/` (16 mp4) — 흰배경 H.264, multiply 블렌드

| 파일 | 트리거 | 위치 / 조건 |
|---|:---:|---|
| `tiger_rise.mp4` | ✅ | 홈 히어로 인사(`TigerStageVideo.greetAsset`, launch당 1회) + 온보딩 첫만남(`TigerGreetClip`) |
| `tiger_rest.mp4` | ✅ | 홈 히어로 아이들 루프(`TigerStageVideo.paceAsset`) |
| `tiger_greet_pawflash.mp4` | ✅ | 캐릭터 선택 첫 인사 체인 2단계 (`CharacterClips.greetFor(tiger)`) |
| `magpie_greet_chirp.mp4` | ✅ | 캐릭터 선택 첫 인사 체인 2단계 (`greetFor(magpie)`) |
| `tiger_choose.mp4` | ✅ | **선택 확정 목례** — 체인 1단계 (`chooseFor`, 2026-07-30 배선) |
| `magpie_choose.mp4` | ✅ | **선택 확정 착지** — 체인 1단계 (〃) |
| `tiger_bob.mp4` | ✅ | **후보 카드 루프** — 선택 화면 호랑이 카드 (2026-07-30) |
| `magpie_perched.mp4` | ✅ | **후보 카드 루프** — 선택 화면 까치 카드 (2026-07-30) |
| `tiger_roar.mp4` | ⚠️ | **밀스톤 축하** — 호랑이 선택 사용자 (2026-07-30) |
| `magpie_flight.mp4` | ⚠️ | **밀스톤 축하** — 까치 선택 사용자 (2026-07-30) |
| `tiger_thinking.mp4` | ⚠️ | **끝말잇기 호랑이 턴** 생각 루프 (2026-07-30) + `feedbackFor(tiger, thinking)` |
| `tiger_stretch.mp4` | ⚠️ | **복습 세션 완료** (2026-07-30) |
| `tiger_celebrate_hifive.mp4` | ⚠️ | 게임 정답/축하 (`feedbackFor(tiger, celebrate)` → `game_reward`) |
| `magpie_celebrate.mp4` | ⚠️ | 게임 정답(`feedbackFor`) + 듣기 완료 카드 |
| `magpie_worry.mp4` | ⚠️ | 게임 오답 위로 (`feedbackFor(magpie, worry)`) |
| `tiger_roar_seated_bonus.mp4` | ⚠️ | 신기록(`newBest`) 앉은 포효 (`feedbackFor`) |

> **16/16 전부 배선 완료.** ⚠️=이벤트/상태 조건부. 모두 `videoReady && !reduce-motion` 게이트, 실패 시 정적 `Mascot` 폴백.

### 1-2. `assets/video/loops/` (13 mp4) — 무음 앰비언트 루프

| 파일 | 트리거 | 위치 / 조건 |
|---|:---:|---|
| `hanok_jongga.mp4` | ✅ | 시나리오 목록 헤더 (명시 `loopAsset`) |
| `listening_hero.mp4` | ⚠️ | 듣기 헤더 — png에서 자동 유도 |
| `kkeunmari_hero.mp4` | ⚠️ | 끝말잇기 헤더 — 자동 유도 |
| `porch.mp4` | ⚠️ | 연습 허브·워들 헤더 — 자동 유도 |
| `study_classroom.mp4` | ⚠️ | 단어팩·단어장허브·레거시단어 헤더 — 자동 유도 |
| `study_scholar.mp4` | ⚠️ | 문법·배우기허브·설정 헤더 — 자동 유도 |
| `welcome_hero.mp4` | ✅ | **캐릭터 선택 헤더** (명시 loopAsset — 포스터 하이픈이라 유도 불가, 2026-07-30) |
| `hanok_construction.mp4` | ✅ | **온보딩 프리뷰 page1** (2026-07-30) |
| `scene_cafe.mp4` | ✅ | **시나리오 인트로 아트** — cafe 백드롭 시나리오 (2026-07-30) |
| `scene_directions.mp4` | ✅ | 〃 directions |
| `scene_hotel.mp4` | ✅ | 〃 hotel |
| `scene_market.mp4` | ✅ | 〃 market |
| `scene_restaurant.mp4` | ✅ | 〃 restaurant |

> **13/13 전부 배선 완료.** 유도 규칙: 헤더 `<이름>.png` → `loops/<이름>.mp4` 자동. 시나리오 목록 per-row 썸네일(21개)은 디코더 폭발 방지를 위해 **의도적으로 정지 유지** — 루프는 플레이어 인트로에서만.

### 1-3. `assets/video/` 루트

| 파일 | 트리거 | 비고 |
|---|:---:|---|
| `intro_gate_to_madang.mp4` | ✅ | 앱 실행 인트로 (`intro_gate_screen`) |
| ~~`tiger_greet.mp4`~~ · ~~`tiger_pace.mp4`~~ | 📦 | **`assets_unused/video/`로 이동** (구버전, 롤백법은 README) — APK −6.8MB |

---

## 2. illustrations/mascot/ (14 png) — `Mascot` 위젯

`mascot.dart`가 `kind`+`emotion` → PNG 매핑. **14/14 전부 사용** (고아 2는 이동됨).

✅ `tiger_idle`·`tiger_blink`·`tiger_smile`·`tiger_neutral`·`tiger_celebrate`·`tiger_sad`·`tiger_sleepy`·`tiger_thinking`·`tiger_surprised`·`magpie_perched`·`magpie_wingup`·`magpie_wingdown`·`magpie_celebrate`·`magpie_worry`
📦 ~~`tiger_happy`~~·~~`magpie_perched_alt`~~ → `assets_unused/illustrations/mascot/` (매핑 밖)

---

## 3. illustrations/tiger_anim/ (44 png) — `TigerStage` 프레임

`_allFrames`가 44프레임 전부 참조. **전부 ✅이나 영상 폴백 경로 전용** — `videoReady=true`(main)라 평소엔 영상이 재생되고, 프레임은 reduce-motion/영상 실패/테스트에서만 등장.

---

## 4. illustrations/hanok/ (13 png)

| 파일 | 트리거 | 위치 |
|---|:---:|---|
| `study_scholar`·`study_classroom`·`calligraphy`·`porch`·`achievements`·`listening_hero`·`kkeunmari_hero` | ✅ | 각 모듈 `HanokHeader` (동명 루프 mp4 자동 승격) |
| `madang(light)` | ✅ | 시나리오 목록 헤더 포스터 |
| `gate_frame`·`gate_door_left`·`gate_door_right` | ✅ | 인트로 대문 합성 (`HanokGateArt`) |
| `gate_final` | ✅ | 인트로 안마당 + 온보딩 레벨 배경 |
| `welcome-hero` | ✅ | **캐릭터 선택 헤더 포스터** (2026-07-30 부활) |
| ~~`dancheong_frame`~~·~~`gate.png`~~·~~`gate_entrance`~~·~~`madang(dark)`~~ | 📦 | `assets_unused/illustrations/hanok/`로 이동 |

---

## 5. illustrations/hanok_stages/ (12 png) — 성장 한옥 (⚠️ 초판 판정 오류 → 정정)

> **초판 오류**: "`MadangBackground`만이 렌더러이고 `GyeHanok`(jongga)만 마운트 → 11장 미도달"이라 판정했으나,
> **`learning_path_screen.dart`의 `_HanokHeader`가 `'…/stage_${stage.assetSlug}_light.png'`을 직접 렌더**
> (보간 문자열이라 리터럴 스캔에 안 잡혔음). 학습경로 상단 헤더가 `HanokStageService.currentStage()`에 따라
> **진행도별 12단계 이미지를 전부 표시**한다.

| 파일 | 트리거 | 조건 |
|---|:---:|---|
| `stage_empty~jongga_light` 12장 전부 | ✅ | 학습경로 헤더 — 진행도(팩 클리어)에 따라 해당 단계 1장 표시 |
| `stage_jongga_light` | ✅ | (추가로) 계 공동한옥 배경 (`GyeHanok` → `MadangBackground`) |

- **`sideBuilding` slug 오타 수정됨** (2026-07-30): `'side_building'` → `'sidebuilding'` — 이전엔 이 단계만 404 → 그라데이션 폴백이었음.
- 다크 변형은 0장이지만 앱이 라이트 전용이라 무영향.
- **추가 (2026-07-30)**: 학습경로 stage 이미지 위에 `DecorationLayer` 합성 — 완료한 특별 퀘스트 장식이 한옥 위에 나타남 (좌표는 실기기 튜닝 대상).

---

## 6. illustrations/decorations/ (18 png) — 퀘스트 보상 장식

**18개 전부 ✅** — ① 퀘스트 화면 보상 썸네일(기존) + ② **학습경로 한옥 헤더 `DecorationLayer` 합성**(2026-07-30 마운트, 완료 퀘스트만) + `dokkaebi_fire`는 온보딩 프리뷰 page2.
`DecorationLayer` 데드 코드 문제는 학습경로 마운트로 해소.

## 7. illustrations/stamps/ (8 png) — **8/8 ✅** (도장첩·팩 카드·클리어 결과, PNG 실패 시 CustomPainter 폴백)

## 8. stickers/ (30 png) — **30/30 ✅** (계 스티커 전송/피드 — 계 가입 시 도달)

## 9. illustrations/gye/ (8 png) — **8/8 ✅** (`GyeHanok` 공동한옥 합성)

## 10. 기타 UI (scenes 5 · book 5 · empty 2 · error 2 · icons 2) — **전부 ✅**

scenes 5(시나리오 백드롭+인트로 아트 포스터) · book 5(책 한 컷 플로우) · empty/error 4(빈/오류 상태) · icons 2(스플래시·로고).

## 11. ~~데드~~ → 📦 `assets_unused/`로 이동 완료

구 보행 프레임 16(`tiger_anim_archive/`) + gate 아트 원본 백업 6(`hanok/backup/`) — 원래 pubspec 미등록이라 APK에 없던 것들. 정체·복원법은 `assets_unused/README.md`.

---

## 12. 조치 결과 (구 권장 조치 대비)

- ~~A. 정리~~ → **완료**: 고아 8 + 데드 22 = 30파일 `assets_unused/` 이동 (삭제 없음, README 포함).
- ~~B. 배선 대기~~ → **완료**: 클립 7 + 루프 7 전량 배선 + `welcome-hero.png` 부활 + 공용 `SoriPosterLoop` 추출.
- ~~C. 설계 확인~~ → **해소**: hanok_stages = 오판정 정정(전부 도달) + slug 버그 수정 / `DecorationLayer` = 학습경로 마운트(Jin 승인) / `madang(dark)` = 이동.
- D. 참고 유지: tiger_anim 44프레임은 영상 폴백 전용(정상) · stickers/gye/stamps는 기능 내 조건부(정상).

**⚠️ 실기기 확인 항목(Jin)**: 선택 화면(카드 루프 2 → choose → greet 체인 · welcome_hero 배너 16:9 crop), 밀스톤 시트(호랑이 포효/까치 비행), 끝말잇기 호랑이 턴 클립, 복습 완료 기지개, 시나리오 인트로 루프 5종, 온보딩 page1 건축 루프, 학습경로 장식 좌표(마당 시안값 그대로라 튜닝 필요할 수 있음).

---

*조사 방법: 매퍼 위젯 12종 정독 + 소비처 grep + 보간 경로 추적(2차). 기준 커밋: 조사=`abe7bff`, 조치=본 커밋.*
