# assets_unused/ — 미사용 에셋 보관소 (2026-07-30)

> **왜 여기에**: 2026-07-30 에셋 트리거 전수조사(`docs/ASSET_TRIGGER_AUDIT_2026-07-30.md`)에서
> 코드가 렌더하지 않는 것으로 확정된 파일들을 **삭제하지 않고** 한곳에 모음(Jin 지시).
> 이 폴더는 `assets/` 밖이라 **pubspec에 안 잡혀 APK에 절대 번들되지 않음**.
>
> **복원법**: 아래 표의 원경로로 `git mv` 한 줄이면 끝 (pubspec은 디렉터리 단위 등록이라 추가 수정 불필요).
> 예: `git mv assets_unused/video/tiger_greet.mp4 assets/video/`

## 0. 서체 (5) — 교체됨

| 파일 | 원경로 | 무엇 / 왜 미사용 |
|---|---|---|
| `fonts/WantedSans/*.otf` (5) + `OFL.txt` | `assets/fonts/WantedSans/` | 2026-08-19 Pretendard→Wanted Sans 교체분. 2026-09-03 Jin 지시로 본문/UI 서체를 **Paperlogy**(`assets/fonts/Paperlogy/`)로 재교체. 복원하려면 `git mv` 후 `pubspec.yaml` fonts 블록과 `lib/widgets/sori/tokens.dart`의 `SoriFonts.sans`를 `WantedSans`로 되돌릴 것 |

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
| `illustrations/tiger_anim/` (44) | `assets/illustrations/tiger_anim/` | **풀바디 호랑이 프레임 44장** (구 `TigerStage`). 2026-08-06 `TigerStage`/`TigerStageRive` 폐지와 함께 이동 — 홈이 `CharacterClipPlayer` 로 옮겨간 뒤 어떤 화면도 `TigerStageVideo` 를 만들지 않아 체인 전체가 데드코드였다. 전부 `assets/video/character/` 상위 호환 클립으로 대체(인트로 9→`tiger_rise`, idle 4→`tiger_rest`·`tiger_sitting2`, 보행 22→`tiger_walking_front`, stretch 3→`tiger_stretch`, roar 6→`tiger_roar`, `stand_greet`→`mascot/tiger_*.png`) | 📦 잔존 |

---

### 이번에 이동 **안 한** 것들 (조사에선 고아였지만 2026-07-30 배선으로 부활)

- `hanok/welcome-hero.png` → 캐릭터 선택 화면 헤더 포스터 (+ `loops/welcome_hero.mp4` 루프)
- `video/character/` 7클립(choose×2·flight·roar·bob·stretch·perched) → 선택 카드/확정 체인·밀스톤·끝말잇기·복습 완료 등에 배선
- `video/loops/` 7편(scene_*×5·welcome_hero·hanok_construction) → 시나리오 인트로·선택 헤더·온보딩 page1에 배선
- `hanok_stages/` 12장 → 원래부터 학습경로 헤더가 렌더 중이었음 (조사 §5 오판정 — 문서 정정됨)

---

## 5. 재생되지 않는 루프 영상 7종 — 2026-09-04 (PR3-T1)

8월 말 두 차례 리팩터(선택 카드/헤더 배선 변경)가 위 "이번에 이동 **안 한** 것들"
목록의 `video/loops/` 7편 배선을 지웠는데 파일만 남았다. 2026-09-04 전수 grep으로
`lib/` 어디에도 재생 호출부가 없음을 재확인(Jin 승인, 지시서 3.7). **삭제가
아니라 격리** — `HanokHeader.kLoopAssets`(`lib/widgets/sori/hanok_header.dart`)와
`AudioPolicy._ambienceGain`(`lib/services/audio_policy.dart`)에서도 짝 항목을
제거해 상수와 파일이 함께 움직이게 했다. `tool/audit_scene_assets.py`에 도달성
검사(`find_hanok_loop_reachability_issues`)를 추가해 앞으로 이런 드리프트가
나면 `--check`가 issue로 잡는다.

| 파일 | 원경로 | 무엇 / 왜 미사용 |
|---|---|---|
| `video/loops/kkeunmari_hero.mp4` + `illustrations/hanok/kkeunmari_hero.png` | `assets/video/loops/`, `assets/illustrations/hanok/` | 끈마리 히어로 앰비언트 루프+포스터 짝. `HanokHeader` 콜사이트가 없다 |
| `video/loops/porch.mp4` + `illustrations/hanok/porch.png` | 〃 | 툇마루 앰비언트 루프+포스터 짝. 콜사이트 없음 |
| `video/loops/scene_cafe.mp4` | `assets/video/loops/` | 카페 시나리오 앰비언트 루프. `SceneAssetResolver.loopAsset`가 만들 수는 있는 경로지만 그 메서드 자체를 부르는 화면이 없다(포스터만 `posterAsset`로 씀) |
| `video/loops/scene_directions.mp4` | 〃 | 길찾기 시나리오 앰비언트 루프. 위와 동일 사유 |
| `video/loops/scene_hotel.mp4` | 〃 | 호텔 시나리오 앰비언트 루프. 위와 동일 사유 |
| `video/loops/scene_market.mp4` | 〃 | 시장 시나리오 앰비언트 루프. 위와 동일 사유 |
| `video/loops/scene_restaurant.mp4` | 〃 | 식당 시나리오 앰비언트 루프. 위와 동일 사유 |

**복원법**: `git mv`로 원경로 되돌리고, `kLoopAssets`에 이름 추가 + 해당
`HanokHeader`(또는 `SceneAssetResolver.loopAsset` 호출부) 배선을 실제로 만들면
된다. `scene_*` 5편은 `assets/illustrations/scenes/*.png`(cafe·directions·
hotel·market·restaurant) 포스터와는 무관 — 그 포스터들은 지금도 정적 배경으로
살아 있으니 건드리지 않았다.

## 6. 검토 대기 `pending_review/` (3) — 2026-08-07

번들(pubspec 등록 폴더)에 들어가면서 코드 참조가 0 이던 것들. **삭제가 아니라
격리**다 — 되살릴 근거가 나오면 원경로로 `git mv` 하면 그대로 복구된다.
`assets_unused/` 는 pubspec 에 없으므로 여기 있는 동안은 AAB 에 안 들어간다.

| 파일 | 원경로 | 용량 | 무엇 / 왜 격리 | 복원 조건 |
|---|---|---:|---|---|
| `pending_review/reference_full_estate.png` | `assets/illustrations/personal_hanok_v2/map/` | 3.1MB | 개인 한옥 **완성형 QA 대조용 참조 이미지**. 런타임 렌더 경로가 아니라 사람이 눈으로 비교하는 용도인데 번들 폴더에 있어 기기에 실려 나갔다 | 앱 안에서 "완성 예시 보기" 같은 화면을 실제로 만들 때 |
| `pending_review/tiger_magpie_play.mp4` | `assets/video/character/` | 1.1MB | 호랑이·까치가 함께 노는 클립. `CharacterClips` 상수(전부 리터럴 문자열)에 없어 어떤 화면도 재생하지 않는다 | 이 클립을 쓸 자리를 정하고 `CharacterClips` 에 상수를 추가할 때 |
| `pending_review/magpie_right_walking_flying.mp4` | `assets/video/character/` | 2.0MB | **새 양방향 가드가 첫 실행에서 찾아냈다.** 인벤토리는 "홈 인사가 이걸 쓴다"고 적었지만 `5927ae6`(클립 재배선·통합) 이후 `lib/` 참조가 0 이다 — 문서가 낡았던 것 | 홈 인사 연출을 되살릴 때. 같은 역할의 현행 클립을 먼저 확인할 것 |

> **2026-08-23 추가 (2)**: `listening_hero.png` · `listening_hero.mp4` (Hören 히어로 제거).
> 사유·복원조건은 `pending_review/README.md` 참조.

합계 **6.2MB** 가 AAB 에서 빠진다. AAB 기기별 다운로드가 190MB/200MB 라
여유가 10MB 뿐이었으므로 무시할 크기가 아니다.

> **이 폴더가 생긴 이유.** `assets/video/character/` 가 오래 단방향 가드였다 —
> "상수가 가리키는 파일이 실재하는가"만 보고 그 반대(디스크에 있는데 상수에
> 없는 것)는 안 봤다. 2026-08-07 에 양방향으로 바꾸자마자 위 2 개가 나왔다.
> 전 폴더 검사는 `test/asset_orphan_guard_test.dart` 가 맡는다.

## 7. welcome-hero 온보딩 체인 3화면 + 히어로 영상 — 2026-09-04 (PR3-T2)

옛 온보딩 화면 3개(`OnboardingLevelScreen`·`OnboardingStartScreen`·
`QuickOnboardingScreen`)가 서로만 참조하는 죽은 사슬이었다. `lib/main.dart`
라우팅에는 세 클래스 이름이 한 번도 나오지 않고, 옛 경로 이름들(`/quick_onboarding`
`/onboarding/legacy-level` `/onboarding/start`)은 전부 새 온보딩
(`OnboardingV2JourneyScreen`)을 만든다. 2026-09-04 전수 grep으로 앱 코드 중
유일한 참조가 디버그 갤러리 `lib/screens/ux_preview_app.dart`(패널 `01B`)
한 줄임을 재확인(Jin 승인, 지시서 3.2). **삭제가 아니라 격리** —
`HanokHeader.kLoopAssets`·`AudioPolicy._ambienceGain`에서도 `welcome-hero`
항목을 함께 제거해 상수와 파일이 같이 움직이게 했고, 디버그 갤러리에서도
`01B` 패널을 뺐다(`lib/models/ux_preview_catalog.dart`).

세 화면의 히어로 포스터 상수 `OnboardingLevelScreen.kHeroPoster`가 가리키던
`assets/illustrations/mascot/magpie_tiger_together.png`는 `stats_screen.dart`·
`mascot.dart`가 계속 정본으로 쓰는 **살아 있는** 마스코트 아트라 이번 이동
대상에서 뺐다.

| 파일 | 원경로 | 무엇 / 왜 미사용 |
|---|---|---|
| `retired_code/screens/onboarding_level_screen.dart` | `lib/screens/` | 옛 A1~C1 레벨 사다리 화면. `OnboardingStartScreen`만 이 화면으로 이동했다 |
| `retired_code/screens/onboarding_start_screen.dart` | `lib/screens/` | 옛 학습 동기 설문 화면. `QuickOnboardingScreen`만 이 화면으로 이동했다 |
| `retired_code/screens/quick_onboarding_screen.dart` | `lib/screens/` | 위 두 화면으로 가는 진입점. 라우팅 콜사이트가 없다 |
| `retired_code/test/onboarding_start_screen_test.dart` | `test/` | 위 화면 전용 테스트. 격리와 함께 실행 대상에서 뺐다 |
| `retired_code/test/quick_onboarding_screen_test.dart` | `test/` | 〃 |
| `video/loops/welcome-hero.mp4` | `assets/video/loops/` | `OnboardingLevelScreen`의 히어로 앰비언트 루프(585KB). 화면이 격리되며 유일한 콜사이트가 사라졌다 |

**복원법**: 세 화면과 두 테스트를 `git mv`로 원경로에 되돌리고, `analysis_options.yaml`
`exclude`에서 `assets_unused/**` 아래 이 파일들이 다시 빠지는지 확인할 필요는
없다(폴더 단위 제외라 자동 반영). `welcome-hero.mp4`를 되돌리고
`HanokHeader.kLoopAssets`·`AudioPolicy._ambienceGain`에 항목을 다시 추가하고,
`lib/screens/ux_preview_app.dart`와 `lib/models/ux_preview_catalog.dart`에
`01B` 패널을 다시 배선하면 된다. `test/welcome_hero_retired_test.dart`가
이 격리를 하향 전용으로 지키므로, 복원할 때는 그 테스트부터 지울 것.
