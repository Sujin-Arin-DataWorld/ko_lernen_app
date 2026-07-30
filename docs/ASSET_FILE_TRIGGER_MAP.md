# 에셋 파일명 ↔ 트리거 1:1 매핑 (2026-07-30 최신)

> 현재 `assets/`에 실제 존재하는 **미디어 파일 193개**를 **파일명 ↔ 코드가 렌더하는 실제 위치**로 1:1 매핑.
> 배선·이동·삭제(커밋 `8866ca8` + 영상 배선분) 반영. 미사용분은 `assets_unused/`로 빠져 여기 없음.
>
> **범례**: ✅ 상시 도달 · ⚠️ 조건부(이벤트/상태) · 🎬 영상(videoReady && !reduce-motion 게이트, 실패 시 정적 폴백) · 📁 폴백 경로 전용
> **서사·정정 이력은** `docs/ASSET_TRIGGER_AUDIT_2026-07-30.md` 참조. 이 파일은 순수 조회용.

---

## assets/illustrations/mascot/ (14) — `Mascot` 위젯 (emotion→png)

| 파일 | 트리거 |
|---|---|
| `tiger_smile.png` | ✅ Mascot(tiger, smile) 기본 — 앱 전반 |
| `tiger_idle.png` | ✅ tiger smile/neutral animate 시 교차 프레임 |
| `tiger_blink.png` | ✅ tiger smile/neutral animate 깜빡임 |
| `tiger_neutral.png` | ✅ Mascot(tiger, neutral) |
| `tiger_celebrate.png` | ✅ Mascot(tiger, celebrate) — 결과·축하 카드 |
| `tiger_sad.png` | ✅ Mascot(tiger, worry) — 오답·잠금 |
| `tiger_sleepy.png` | ✅ Mascot(tiger, sleepy) |
| `tiger_thinking.png` | ✅ Mascot(tiger, thinking) — 정적(끝말잇기 폴백·book_result·hard_words) |
| `tiger_surprised.png` | ✅ Mascot(tiger, surprised) — 초성/워들 결과 |
| `magpie_perched.png` | ✅ Mascot(magpie) 기본/sleepy (정지 아이들) |
| `magpie_wingup.png` | ✅ magpie animate 날갯짓(상승) + hanok_cinematic 까치 |
| `magpie_wingdown.png` | ✅ magpie animate 날갯짓(하강) |
| `magpie_celebrate.png` | ✅ Mascot(magpie, celebrate) |
| `magpie_worry.png` | ✅ Mascot(magpie, worry) |

## assets/illustrations/tiger_anim/ (44) — `TigerStage` 프레임 📁

> **📁 홈 히어로 영상 폴백 경로 전용**: 평소엔 `tiger_rest/rise.mp4` 영상 재생. reduce-motion / 영상 로드 실패 / videoReady=false(테스트)일 때만 이 프레임 시퀀스가 등장. 정지 폴백은 `stand_greet` 1장.

| 그룹 | 파일 | 역할 |
|---|---|---|
| 인트로(launch당 1회) | `rest_idle` `notice_turn` `notice_front` `smile_front` `rise_prep` `rise_half` `stand_greet` `bob_a` `bob_b` | 엎드림→인지→미소→기상→인사 |
| 아이들 루프 | `stand_idle_a` `stand_idle_b` `sit_idle_a` `sit_idle_b` | 서서/앉아 호흡 (+ bob_a/b·stand_greet 재사용) |
| 좌 왕복 | `turn_left_3q` `step_out_left` `walk_left_01`~`08` `turn_left_front` | 좌향→걷기 8프레임→복귀 |
| 우 왕복 | `turn_right_3q` `step_out_right` `walk_right_01`~`08` `turn_right_front` | 우향→걷기 8프레임→복귀 |
| ambient 기지개 | `stretch_prep` `stretch_full` `stretch_release` | 우향 후 기지개 |
| ambient 포효 | `roar_prep` `roar_open` `roar_open2` `roar_full` `roar_close` `roar_recover` | 우향 후 으르렁 |

## assets/illustrations/hanok/ (13) — 헤더 포스터 + 대문 아트

| 파일 | 트리거 |
|---|---|
| `study_scholar.png` | ✅ 헤더: 문법·배우기허브·설정 (HanokHeader, 위에 study_scholar.mp4 루프) |
| `study_classroom.png` | ✅ 헤더: 단어팩·단어장허브·레거시단어 (+study_classroom.mp4) |
| `calligraphy.png` | ✅ 헤더: 한글·초성·책장 |
| `porch.png` | ✅ 헤더: 연습허브·워들 (+porch.mp4) |
| `achievements.png` | ✅ 헤더: 퀘스트·통계 |
| `listening_hero.png` | ✅ 헤더: 듣기 (+listening_hero.mp4) |
| `kkeunmari_hero.png` | ✅ 헤더: 끝말잇기 (+kkeunmari_hero.mp4) |
| `welcome-hero.png` | ✅ 헤더: **캐릭터 선택** (+welcome_hero.mp4 루프, 2026-07-30 부활) |
| `madang(light).png` | ✅ 시나리오 목록 헤더 포스터 (위에 hanok_jongga.mp4 루프) |
| `gate_frame.png` | ✅ 인트로 대문 프레임 레이어 (HanokGateArt) |
| `gate_door_left.png` | ✅ 인트로 대문 좌측 문짝 |
| `gate_door_right.png` | ✅ 인트로 대문 우측 문짝 |
| `gate_final.png` | ✅ 인트로 안마당 + 온보딩 레벨 선택 배경 |

## assets/illustrations/hanok_stages/ (12) — 학습경로 헤더 (진행도별 1장)

> `learning_path_screen`의 `_HanokHeader`가 `HanokStageService.currentStage()`에 따라 해당 단계 1장 렌더. **완료 퀘스트 장식(DecorationLayer)이 이 위에 합성됨**(2026-07-30).

| 파일 | 단계 (진행도) |
|---|---|
| `stage_empty_light.png` | 터 (시작) |
| `stage_foundation_light.png` | 주춧돌 |
| `stage_pillars_light.png` | 기둥 |
| `stage_beams_light.png` | 대들보 |
| `stage_thatch_light.png` | 초가지붕 |
| `stage_tile_partial_light.png` | 기와(부분) |
| `stage_tile_complete_light.png` | 기와 완성 |
| `stage_dancheong_light.png` | 단청 |
| `stage_gate_light.png` | 솟을대문 |
| `stage_windows_light.png` | 창호 |
| `stage_sidebuilding_light.png` | 사랑채 (⚠️ slug 오타 수정으로 2026-07-30부터 정상 렌더) |
| `stage_jongga_light.png` | 종갓집 (+ 계 공동한옥 `GyeHanok` 배경) |

## assets/illustrations/decorations/ (18) — 퀘스트 보상 + 학습경로 마당 합성

> `quests_screen` 보상 썸네일(달성=풀컬러/미달성=흐림) + 완료 시 `learning_path` 한옥 위 `DecorationLayer` 합성.

| 파일 | 퀘스트 / 조건 |
|---|---|
| `decoration_jangdokdae.png` | q_jangdokdae — 음식 50단어 마스터 |
| `decoration_maehwa.png` | q_maehwa — 형용사·감정 30 |
| `decoration_sonamu.png` | q_sonamu — 시나리오 10 완료 |
| `decoration_pond.png` | q_pond — 자연·날씨 20 |
| `decoration_seokdeung.png` | q_seokdeung — 발음 100회 |
| `decoration_punggyeong.png` | q_punggyeong — 끝말잇기 10승 |
| `decoration_pyeonaek.png` | q_pyeonaek — 한글 자모 100% |
| `decoration_doldam.png` | q_doldam — 친구/계원 5 |
| `decoration_kkachi_nest.png` | q_kkachi_nest — 30일 스트릭 |
| `decoration_sagunja_maehwa.png` | q_sagunja_maehwa — 한자단어 20 |
| `decoration_sagunja_nan.png` | q_sagunja_nan — 한자단어 40 |
| `decoration_sagunja_guk.png` | q_sagunja_guk — 한자단어 60 |
| `decoration_sagunja_juk.png` | q_sagunja_juk — 한자단어 80 |
| `decoration_seollal_flag.png` | q_seollal — 설날 시즌 초성퀴즈 5 |
| `decoration_chuseok_moon.png` | q_chuseok — 추석 음식단어 12 |
| `decoration_hangeulday_plaque.png` | q_hangeulday — 한글날 서예 7일 |
| `decoration_kite.png` | q_kite — 어린이날 서예 5연속 |
| `dokkaebi_fire.png` | ⚠️ 온보딩 프리뷰 page2 (도깨비불) |

## assets/illustrations/stamps/ (8) — `DancheongStamp` (도장첩·팩카드·클리어 결과)

> 팩 클리어/조회 시 pack_id→motif로 도장. PNG 실패 시 절차적 CustomPainter 폴백.

| 파일 | motif → 팩군 |
|---|---|
| `stamp_lotus.png` | lotus — 인사·자기소개·가족 |
| `stamp_chrysanthemum.png` | chrysanthemum — 시간·숫자 |
| `stamp_plum.png` | plum — 감정·형용사 |
| `stamp_bamboo.png` | bamboo — 학교·직장 |
| `stamp_cloud.png` | cloud — 날씨·자연 |
| `stamp_geometric_octagon.png` | octagon — 음식·쇼핑 |
| `stamp_mountain.png` | mountain — 교통·여행 |
| `stamp_swastika.png` | swastika(卍) — 신체·건강 |

## assets/illustrations/gye/ (8) — `GyeHanok` 공동한옥 ⚠️(계 가입 시)

> 계(契) 마당 배경 위 합성. 누적 주간목표 달성수에 따라 ghost(0.22)→실체(1.0).

| 파일 | 요소 |
|---|---|
| `gye_gate_grand.png` | 솟을대문 (+ 온보딩 프리뷰 page1 포스터) |
| `gye_haenglangchae.png` | 행랑채 |
| `gye_byeoldang.png` | 별당 |
| `gye_jeongja.png` | 정자 |
| `gye_garden.png` | 정원 |
| `gye_jangmyeongdeung_pair.png` | 장명등 한 쌍 |
| `gye_pond_large.png` | 연못 |
| `gye_bridge.png` | 다리 |

## assets/illustrations/scenes/ (5) — 시나리오 백드롭 ⚠️

> ① 시나리오 목록 per-row 썸네일 ② 플레이어 인트로 아트 포스터(위에 scene_*.mp4 루프) ③ 플레이어 전체배경 wash(0.08). 시나리오 id→key 매핑.

| 파일 | 커버 시나리오 |
|---|---|
| `cafe.png` | 카페·자기소개·연인·약속 등 |
| `restaurant.png` | 식당·분식·회식·저녁 |
| `market.png` | 시장·쇼핑·편의점·약국 |
| `hotel.png` | 호텔 |
| `directions.png` | 공항·택시·지하철·길찾기·지각 |

## assets/illustrations/book/ (5) — 책 한 컷 플로우 ⚠️

| 파일 | 트리거 |
|---|---|
| `book_empty_shelf.png` | 책장 빈 상태 |
| `book_camera_guide.png` | 책 촬영 idle |
| `book_analyzing.png` | 책 분석 로딩 |
| `book_error.png` | 책 분석 실패 |
| `book_success.png` | 책 분석 성공 (+ 온보딩 프리뷰 page0) |

## assets/illustrations/empty/ · error/ (4)

| 파일 | 트리거 |
|---|---|
| `empty/celebrate_complete.png` | ⚠️ 레거시 단어장 due 완료 |
| `empty/studyroom_waiting.png` | ⚠️ 통계 첫 진입 |
| `error/lost_magpie.png` | ⚠️ 시나리오 로드 실패 |
| `error/offline_lantern.png` | ⚠️ 설정 오프라인 |

## assets/icons/ (2)

| 파일 | 트리거 |
|---|---|
| `HanLogo.png` | ✅ 스플래시 화면 (+ 런처 아이콘 소스) |
| `icon-192.png` | ✅ 로딩 로고 + 홈 상단바 로고 |

## assets/stickers/ (30) — `StickerPicker` ⚠️(계 스티커 전송/피드)

| 카테고리 | 파일 (코드 1~30) |
|---|---|
| 호랑이 | `tiger_cheer` `tiger_clap` `tiger_surprised` `tiger_sad` `tiger_love` |
| 까치 | `magpie_dance` `magpie_wave` `magpie_sleep` `magpie_sing` `magpie_encourage` |
| 단청 | `dancheong_flower` `dancheong_star` `dancheong_cloud` `dancheong_lantern` `dancheong_hanji` |
| 한글 | `hangul_kk` `hangul_hh` `hangul_fighting` `hangul_best` `hangul_good` |
| 음식 | `food_tteok` `food_tea` `food_kimbap` `food_hotteok` `food_sikhye` |
| 도장 | `stamp_sticker_well_done` `stamp_sticker_fighting` `stamp_sticker_love` `stamp_sticker_cheer` `stamp_sticker_happy` |

---

## assets/video/ (30) 🎬 (전부 videoReady && !reduce-motion 게이트, 실패 시 정적 폴백)

### video/ 루트 (1)
| 파일 | 트리거 |
|---|---|
| `intro_gate_to_madang.mp4` | ✅ 앱 실행 인트로 (intro_gate_screen) |

### video/loops/ (13) — 무음 앰비언트 루프
| 파일 | 트리거 |
|---|---|
| `hanok_jongga.mp4` | ✅ 시나리오 목록 헤더 (명시 loopAsset) |
| `listening_hero.mp4` | ⚠️ 듣기 헤더 (listening_hero.png에서 유도) |
| `kkeunmari_hero.mp4` | ⚠️ 끝말잇기 헤더 |
| `porch.mp4` | ⚠️ 연습허브·워들 헤더 |
| `study_classroom.mp4` | ⚠️ 단어팩·단어장허브·레거시 헤더 |
| `study_scholar.mp4` | ⚠️ 문법·배우기허브·설정 헤더 |
| `welcome_hero.mp4` | ⚠️ 캐릭터 선택 헤더 (명시 loopAsset, 2026-07-30) |
| `hanok_construction.mp4` | ⚠️ 온보딩 프리뷰 page1 (2026-07-30) |
| `scene_cafe.mp4` | ⚠️ 시나리오 인트로 아트 — cafe (2026-07-30) |
| `scene_directions.mp4` | ⚠️ 〃 directions |
| `scene_hotel.mp4` | ⚠️ 〃 hotel |
| `scene_market.mp4` | ⚠️ 〃 market |
| `scene_restaurant.mp4` | ⚠️ 〃 restaurant |

### video/character/ (16) — 흰배경 캐릭터 클립 (multiply 블렌드)
| 파일 | 트리거 |
|---|---|
| `tiger_rise.mp4` | ✅ 홈 히어로 인사(launch당 1회) + 온보딩 첫만남 |
| `tiger_rest.mp4` | ✅ 홈 히어로 아이들 루프 |
| `tiger_greet_pawflash.mp4` | ✅ 캐릭터 선택 인사 — 체인 2단계(호랑이) |
| `magpie_greet_chirp.mp4` | ✅ 캐릭터 선택 인사 — 체인 2단계(까치) |
| `tiger_choose.mp4` | ✅ 캐릭터 선택 확정 목례 — 체인 1단계 (2026-07-30) |
| `magpie_choose.mp4` | ✅ 캐릭터 선택 확정 착지 — 체인 1단계 (2026-07-30) |
| `tiger_bob.mp4` | ✅ 캐릭터 선택 호랑이 카드 루프 (2026-07-30) |
| `magpie_perched.mp4` | ✅ 캐릭터 선택 까치 카드 루프 (2026-07-30) |
| `tiger_roar.mp4` | ⚠️ 밀스톤 축하 시트 — 호랑이 선택자 (2026-07-30) |
| `magpie_flight.mp4` | ⚠️ 밀스톤 축하 시트 — 까치 선택자 (2026-07-30) |
| `tiger_thinking.mp4` | ⚠️ 끝말잇기 호랑이 턴 루프 (2026-07-30) |
| `tiger_stretch.mp4` | ⚠️ 복습 세션 완료 (2026-07-30) |
| `tiger_celebrate_hifive.mp4` | ⚠️ 게임 정답 축하 (feedbackFor tiger celebrate) |
| `magpie_celebrate.mp4` | ⚠️ 게임 정답(magpie) + 듣기 완료 카드 |
| `magpie_worry.mp4` | ⚠️ 게임 오답 위로 (feedbackFor magpie worry) |
| `tiger_roar_seated_bonus.mp4` | ⚠️ 신기록(newBest) 앉은 포효 |

---

## 요약
| 카테고리 | 개수 | 상태 |
|---|---:|---|
| mascot | 14 | ✅ 전부 사용 |
| tiger_anim | 44 | 📁 영상 폴백 전용 |
| hanok | 13 | ✅ 헤더·대문 |
| hanok_stages | 12 | ✅ 학습경로 진행도별 |
| decorations | 18 | ✅ 퀘스트·마당 |
| stamps | 8 | ✅ 도장 |
| gye | 8 | ⚠️ 계 공동한옥 |
| scenes | 5 | ⚠️ 시나리오 백드롭 |
| book/empty/error/icons | 11 | 상태·아이콘 |
| stickers | 30 | ⚠️ 계 스티커 |
| video (root/loops/character) | 30 | 🎬 영상 |
| **합계** | **193** | **미트리거 0** |

*미사용 에셋은 `assets_unused/`(README 참조). 기준 커밋: `8866ca8` + 영상 배선 커밋.*
