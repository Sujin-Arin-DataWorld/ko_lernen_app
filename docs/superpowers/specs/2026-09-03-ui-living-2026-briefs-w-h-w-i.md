# UI "살아 있는 앱" 2026 — 후속 패키지 브리프 W-H·W-I (PR-1 머지 후 실행)

> 작성: Fable 5.1, 2026-09-03. PR-1(`claude/ui-living-2026-0903`: W-A~W-G+W-J)의 후속. **W-H = PR-2, W-I = PR-3**, 각각 머지된 origin/main에서 새 브랜치(스택 PR 금지). 실행자 Sonnet, 심사 Fable(코드 정독·증거 PNG 열람). 공통 규칙: 워크트리만·커밋은 Jin 요청 시·ARB de/en·중괄호·단언 약화 금지·새 hex/서체/배지 금지·Living Hanok V1 불가침. 레이아웃 예산 테스트는 `test/support/real_fonts.dart` `loadSoriRealFonts()` 필수(기본 테스트 폰트는 1em 폭 사각형). 테스트 파일은 하나씩 실행(리포터가 둘째 파일을 표시하지 않는 현상).
> W-J 통합 브리프 §3(MOTION-4 파사드 매핑표·MOTION-3 선택지 E)·§2(W-I 이관 목록)의 원문은 PR-1 본문과 플랜 §6 로그에 요약돼 있다.

---

# 브리프 W-H

# W-H 브리프 — 모션·햅틱·사운드 시스템 + 코치 투어 + 마스코트 3순간 (Living layer)

## 공통 규칙 — 워크트리 안에서만 · 커밋 금지 · ARB de/en · 중괄호 · 브리프 밖 파일 보고만 · 테스트 단언 약화 금지 · 행 번호 재확인. reduce-motion(`SoriMotion.reduceMotion(context)` / `MediaQuery.disableAnimations`)에서 모든 새 모션은 정적.

## 확정 사실
- `lib/widgets/sori/motion.dart`: `SoriEntrance`(:13), `SoriAnimation`(:90-118: tap 100·quick 200·normal 400·slow 800·verySlow 1200, curves tapOut/release(elasticOut)/gentle, entrance 540, press, card, idle). W-E가 `SoriPulse`를 추가했을 수 있음(있으면 재사용).
- `lib/widgets/sori/pressable.dart` `SoriPressable`(scale 0.96, `SoriHaptic{light,medium,heavy,selection}` → `HapticFeedback.*`).
- `HapticFeedback.*` 직접 호출 152곳/44파일(`grep -rn "HapticFeedback\." lib`). `lib/services/sound_service.dart` `SoundService.correct/wrong/combo/levelUp/complete`(`assets/sfx/*.wav`, `levelUp` 호출 0곳, `SoundService.enabled` 대입 0곳 → 사운드 끌 수 없음).
- 축하 위젯: `celebration.dart` `SoriCelebration`(20 참조), `dancheong_burst.dart` `DancheongBurst`, `score_pop.dart` `ScorePop`, `milestone_celebration.dart` `showMilestoneCelebration`, `game_reward.dart` `GameOverCard`. `mascot_pop.dart` `MascotPartner`(호출 0 — 세션 시작 인사용으로 부활).
- 코치: `spotlight_coach.dart` `SpotlightCoach`/`SpotlightStep`(라이브), 고아 ARB `coachHomeTab0Title/Body … coachHomeTab3*`(4탭 시절: Start/Üben/Gye/Profil), `coachHomePath*`, `coachHomeBook*`, `coachWordleStep1-3*`. `AppShell.replayHomeTour`(`app_shell.dart:24` ValueNotifier) 이미 존재.
- 설정 화면 `settings_screen.dart`에 햅틱/사운드 토글 ARB가 있는지 확인(`settingsSound*`·`settingsHaptic*` grep), 없으면 신규 키.

## 작업 순서
### H1. `SoriAnimation` 스프링·스태거
`motion.dart`에 `SpringDescription` 3종(`springSoft`(mass1, stiffness 180, damping 20) · `springSnappy`(1, 400, 28) · `springBouncy`(1, 300, 14))과 `SoriStagger.delay(index, {step = 40ms, max = 6})` 헬퍼 추가. `SoriEntrance`에 `delay` 파라미터가 없으면 추가.

### H2. `SoriFeedback` 파사드 (`lib/services/feedback_service.dart` 신규)
**⚠️ 대체(Fable 확정 2026-09-03): 이 절의 아래 4개 불릿은 폐기. `W-J.md §3 MOTION-4 대체 명세`(매핑표 9메서드·`Storage.hapticsOn` 게이트·`commit()`/`reject()`/`destructiveDone()`·이상치 6곳 `commit()` 보존·인접 `SoundService` 쌍 30곳 한 줄 통합·W-I 삭제 대상 제외·`deck_swipe_physics_test`/`content_feed_test` 무변경·설정 햅틱 토글 ARB 2키)를 그대로 따른다. 충돌 시 W-J 가 우선. 원문 매핑(medium→success, heavy→error)은 실측 관행(light=긍정·medium=부정/커밋·heavy=완료)과 반대라 폐기됐다.**
- `SoriFeedback.select()`(selection 햅틱), `.confirm()`(light), `.success({tier: small|medium|large})`(medium 햅틱 + `SoundService.correct`/`combo`/`complete` + tier large면 `SoriCelebration` 호출자에게 콜백), `.error()`(heavy + `SoundService.wrong`), `.complete()`(medium + `complete`), `.levelUp()`(heavy + `levelUp` — 호출 0곳이던 sfx 부활: 한옥 단계 상승·팩 클리어 시점에 배선).
- 설정: `Storage`에 `hapticsEnabled`(기본 true)·`soundEnabled`(기본 true) 없으면 추가, `SoundService.enabled`를 여기서 동기화. 설정 화면에 토글 2개(ARB 신규 또는 기존 키).
- 152곳 `HapticFeedback.*` 직접 호출을 `SoriFeedback.*`로 치환(기계적, 의미 매핑: selectionClick→select, lightImpact→confirm, mediumImpact→success(small) 또는 confirm(문맥), heavyImpact→error/levelUp 문맥). 문맥 판단이 애매하면 confirm.
- 가드 `test/haptic_guard_test.dart`: `lib/`에서 `HapticFeedback.` 직접 호출은 `feedback_service.dart`·`pressable.dart`에만 허용.

### H3. 마스코트 3순간 (프레임 훅, 화면별 구현 금지)
1. **세션 시작**: `SoriStudyFrame`에 `greeting: bool`(기본 true) — 세션당 1회(`Storage` 아닌 메모리 static set, 화면 타입 기준) 우상단에 `MascotPartner` 인사 팝(1.2초 후 자동 소멸, reduce-motion은 정적 0.8초).
2. **연속 정답 3**: `GameOverCard`/퀴즈 공통 정답 처리 지점을 찾아(`ScorePop` 호출부 grep) 3연속에서 `ScorePop` + 까치 `Mascot.magpie(emotion: celebrate)` 1회. 화면마다 흩어져 있으면 `SoriFeedback.success(tier: medium, streak: n)`에 streak 파라미터를 두고 파사드가 판단.
3. **완료**: `showMilestoneCelebration` 호출부를 점검해 팩 클리어/한옥 단계 상승/주간 목표 달성 세 지점에 `SoriFeedback.levelUp()` + 축하 위젯이 모두 걸려 있는지 표로 보고, 빠진 곳만 배선.

### H4. 코치 투어 부활 (I-1)
- `coachHomeTab*` 4키를 5탭에 맞게 재작성(ARB 값만: Heute/Lernen/Spiele/Hanok/Gye — `coachHomeTab4Title/Body` 신규), `SpotlightCoach` 스텝 5개를 `SoriStageShell` 첫 진입 시 1회(`Storage.homeTourSeen` 없으면 추가) 실행, `AppShell.replayHomeTour` 노티파이어로 재생, 설정에 "Tour wiederholen"(ARB 신규 `settingsReplayTour` de/en). 각 스텝은 하단 탭 아이템의 `GlobalKey`를 타깃.
- `coachWordleStep1-3*` 3키 → `SilbenKreuzScreen`(현재 `/wordle`)의 "Spielanleitung" 시트(홈 액션 옆 `?` 48dp)로 재활용. 내용이 실제 게임 규칙과 다르면 값만 갱신(de/en).

### H5. 검증
`flutter analyze` · `test/haptic_guard_test.dart` · `test/feedback_service_test.dart`(설정 off면 햅틱/사운드 미호출 — `TestDefaultBinaryMessengerBinding`로 플랫폼 채널 호출 기록) · `test/home_tour_test.dart`(첫 진입 1회, 재생 노티파이어) · 리듀스 모션 정적 렌더 테스트(`MascotPartner`·`SoriPulse`·스태거) · 전체 `flutter test | tail -40`. 보고 + 실기기 손맛 확인 포인트(Jin) 5개.

### H6. (W-D 이월) `SoriEntrance` reduce-motion 타이머 · 마스코트 celebrate 훅
**⚠️ 대체(Fable 확정 2026-09-03)**: 첫 불릿(`SoriEntrance` 타이머)은 **W-J J5 로 이관** — W-H 착수 시점엔 이미 반영돼 있으니 손대지 않는다. 둘째 불릿(`emotionOverride`)은 **D8(E) 로 대체**: 영상 경로에선 emotion 교체가 화면 변화 0 이므로, `SoriCharacterHero` 의 `bubble` 문구를 미션 CTA 탭 직후·활동 복귀(영수증 시트 앞) 시 1.2초간 축하 카피로 교체(ARB 신규 de/en 2키, 예 "Los geht's!"/"Let's go!" · "Stark gemacht!"/"Well done!"), 타이머는 dispose 취소·마일스톤 오버레이 진행 중이면 양보. 테스트 요건은 `W-J.md §3 MOTION-3`(offstage 시 `skipOffstage: false`, 복귀 경로 주입점). 아래 원문은 참고용.
- `lib/widgets/sori/motion.dart` `SoriEntrance.initState()`가 reduce-motion과 무관하게 `Future.delayed(delay)`를 예약함 → reduce-motion이면 스케줄 자체를 건너뛰고 즉시 최종 상태(`didChangeDependencies`에서 판단). `pumpAndSettle` 없이 끝나는 위젯 테스트에서 "Timer is still pending"이 나지 않도록. 관련 테스트(`sori_stage_today_matte_test` 등)의 우회용 `pumpAndSettle()`은 유지해도 됨.
- `lib/widgets/sori/home_hero.dart` `SoriCharacterHero`(StatelessWidget, `_emotion`이 `phase`에서만 파생)에 `emotionOverride: MascotEmotion?` 파라미터를 추가하고, Today 미션 CTA 탭 시 1.2초간 `celebrate`로 바꾸는 최소 state를 `sori_stage_today_screen.dart`에 둔다(H3의 "세션 시작" 인사와 별개).

### H7. (W-D 미이행 이월, D18) 스트릭 다이얼로그 — 고아 ARB `streak*` 7키 배선
**추가(Fable 시각 심사 2026-09-03, `docs/screenshots/sori-stage-today-390.png`)**: Today 상단 우측의 "🔥 0"·"Lv 1" 두 개는 iOS 풍 필(Jin 금지 규칙 위반). 필 제거 → 인사 헤드라인 아래 한 줄 메타(`tt.meta` tabular, 예 "3 Tage in Folge · Level 1", ARB de/en)로 통합하고 그 줄 전체를 스트릭 시트의 탭 타깃으로. 프로필·설정 원형 아이콘 버튼 2개는 유지(프로필은 `SoriAvatar`로 교체 검토).
Today 상단 통계 행의 스트릭 숫자(`sori_stage_today_screen.dart` grep `streak`)를 탭하면 `streak*` 키로 다이얼로그/시트(기존 위젯 grep `Streak.*Dialog|streakDialog` 재사용, 없으면 표준 `SoriSheet` 바텀시트: 현재 연속일·최장 기록·다음 마일스톤). `SoriPressable`+`SoriFeedback.select()`. reduce-motion 정적. 테스트: 탭→시트에 `streakTitle` 표시. `arb_orphan_key_guard` ceiling 은 J15 절차로 재실측 하향.

### H8. 실행 전제 (Fable 확정)
W-H 는 **PR-1(W-A~W-G+W-J) 머지 후 origin/main 에서 새 브랜치**로 실행(스택 PR 금지). 설정 화면 행 추가(햅틱 토글·Tour wiederholen)로 settings 골든 3장이 바뀌므로 PR-2 에서 `regenerate-goldens` 1회(D12 a). W-I 삭제 대상 파일(onboarding_start/level/preview·discover_screen)은 치환표에서 제외하고 실측 재산정.


---

# 브리프 W-I

# W-I 브리프 — 라이브 아닌 코드·에셋 정리/부활 마무리 + 이월 항목

## 공통 규칙 — 워크트리 안에서만 · 커밋 금지 · ARB de/en · 중괄호 · 테스트 단언 약화 금지. 삭제는 import 폐포가 넓으므로 **전체 `flutter test`가 유일한 게이트**. Living Hanok V1·`ProductiveAssessmentCatalog`·`ENABLE_TESTER_FEEDBACK`·다크모드·`ENABLE_UX_GALLERY`는 **건드리지 않는다**(Jin 게이트).

## I-A. 이월 항목(W-B) — **→ W-J J2·J4 로 흡수(Fable 확정 2026-09-03). 아래 1·2 는 W-I 에서 실행하지 않는다.** W-I 에 남는 것: J4 의 `route_transition_test` fadeScale 허용목록 7파일을 삭제 후 실측 집합(`transitions.dart`·`first_voice_success_screen.dart`·`character_selection_screen.dart` 잔존 시)으로 축소 + `:75-100` MaterialPageRoute 허용목록에서 `onboarding_level_screen.dart` 제거.
1. `SoriStudyFrame`에 `bottom: PreferredSizeWidget?` 슬롯 추가(`SoriAppBar`가 `bottom`을 받도록) → `lib/screens/hangul_screen.dart`를 프레임으로 편입(X+홈+PopScope 규칙 동일). `study_home_escape_guard_test` 인벤토리 26→27.
2. `SoriTransitions.fadeScale` 직접 호출 중 비온보딩 3곳(`grammar_screen.dart:≈534`, `settings_screen.dart:≈1712`, `lib/features/guide/guide_runtime.dart:≈531`)을 `SoriTransitions.page`로. 온보딩 계열(`character_selection`·`first_voice_success`·`onboarding_*`·`onboarding_journey`)은 첫 실행 전환 계약이므로 유지. `route_transition_test`의 정적 가드를 "lib/ 전체에서 fadeScale 호출은 온보딩 파일 목록 + transitions.dart에만"으로 확장.

## I-B. 삭제(안전 목록 — 각 항목 삭제 후 참조 0 확인)
- 화면: `lib/screens/quick_onboarding_screen.dart`, `onboarding_preview_screen.dart`, `onboarding_start_screen.dart`, `onboarding_level_screen.dart`(V1 온보딩 체인; `main.dart` 라우트 별칭 `/quick_onboarding`·`/character_selection`·`/intro`·`/onboarding/legacy-level`·`/onboarding/start`는 삭제, `/onboarding`만 딥링크 호환으로 유지), `course_mission_path_overview.dart`, `BookshelfScreen`/`HardWordsScreen`/`WordbookSearchScreen` 래퍼(각 `*Body` 클래스만 남김), `discover_screen.dart`+`lib/models/discover_catalog.dart`(`ux_preview_app.dart`의 패널에서 제거).
- 위젯/데이터: `lib/widgets/sori/mission_hero_card.dart`(W-D가 채택하지 않았으면), `study_action_bar.dart`, `hub_progress_header.dart`, `hanok_cinematic.dart`, `study_card_face.dart`, `SoriShortScrollCard`(`chaekgado/scroll_sheet.dart`), `SoriGaps`(`tokens.dart`), `AppContentFrame`(`window_class.dart`), `SlotPickerSheet`(`room_slot_picker.dart`), ~~`SarangchaeConstructionPilot`~~(→ **W-J J1 이 먼저 삭제** — W-I 착수 시점엔 이미 없음), `lib/data/feed_physics_candidates.dart`, `lib/main_shelf_preview.dart`, `TigerStageVideo`/`TigerGreetClip` 위젯 본체(`tiger_video.dart` — 정적 `videoReady` 플래그는 `character_clip.dart` 등 24곳이 읽으므로 작은 `TigerStageVideo` 네임스페이스 클래스로 남김).
- 각 삭제 대상의 테스트 파일도 함께 삭제(테스트-온리 참조 목록: `a1_hanok_construction_map`은 **제외**, Living Hanok 게이트).
- **(W-J §2 이관, Fable 확정 D1(a))** 온보딩 V1 첫 장면 임베딩 삭제: `lib/services/onboarding_journey.dart`, `ScenarioPlayerMode.onboardingFirstScene` 분기(`scenario_player_screen.dart` :266·:632·:766·:1477 근처), `onExit`/`onCompleted` 파라미터, `_withExitScope` 의 `widget.onExit != null` 분기, `_onExitCleanup`·`_exit` 의 onExit 분기, `test/scenario_onboarding_completion_test.dart` onExit 케이스. 근거: 유일 도달 경로가 `onboarding_level_screen.dart:167`(이 목록의 삭제 대상) → 프로덕션 도달 불가.
- **(W-F/W-G 결과, Fable 추가 2026-09-03)** `lib/screens/sori_stage/sori_stage_common.dart`의 `SoriStageRootHeader`·`SoriStageSafeViewport`·`kSoriStageMinimumUsableHeight`·`soriStageChromeMinHeight`(Hanok·Gye 슬리버 전환으로 실호출 0 — 삭제 전 `grep -rn` 재확인, `sori_stage_today_screen`/카탈로그가 아직 쓰면 그 심볼만 남김) · ARB `soriStageGyeFlow`(`SoriStepper`로 대체, 고아) · `test/sori_stage_adaptive_chrome_test.dart`의 옛 `SoriMinHeightScroll` 계약 잔여 케이스.
- **(W-J §2 이관)** `discover_screen.dart` 삭제 후 `test/semantics_tap_guard_test.dart` 허용목록 → `isEmpty` · 고아 골든 기준선 `test/goldens/baselines/home_compact_360x800.png`·`home_expanded_1280x800.png`(참조 0) 삭제 · `mission_hero_card.dart` 삭제 시 `test/goldens/design_components_golden_test.dart` 의 MissionHeroCard 골든 그룹 + `baselines/mission_hero_states.png` 동반 삭제(→ PR-3 에서 `regenerate-goldens` 1회).
- 에셋 고아: `assets/illustrations/activities/hard_words.webp`·`word_search.webp`·`book_capture.webp` → `assets_unused/illustrations/activities/`로 `git mv` + README 1줄(`bookshelf.webp`는 W-E에서 `my_words.webp`로 복사했으므로 원본도 이동). `assets/illustrations/deck/`·`assets/rive/` 빈 디렉터리의 pubspec 선언 제거(+`.gitkeep` 삭제).

## I-C. 미사용 ARB 정리
**(Fable 확정)** `streak*` 7키는 W-H H7 이 배선하므로 **삭제 금지**. 삭제 후 `test/arb_orphan_key_guard_test.dart` ceiling 을 실행 시점 실측값으로 하향(W-J J15 절차 반복, 올리는 변경 금지).
- `lib/l10n/app_de.arb`·`app_en.arb`에서 getter 참조 0인 키(에이전트 인벤토리 319키 기준, 이 시점에 W-C~W-H가 되살린 `coach*`·`wordle*`(재활용분)·`streak*`·`gyeEmptyPreviewCaption`·`hanokWorldMapHint`·`missionHero*`(채택 시)는 제외)를 스크립트로 재계산해 삭제. `l10n_parity`·`arb_l10n_guard` 초록. 삭제 키 수와 목록을 보고.

## I-D. `SoriDeckActionBar` 배선(Sori Deck 2.0 §P2-3)
`lib/widgets/sori/deck_action_bar.dart`(0 호출)를 4개 덱 화면(vocab_pack Learn 덱·custom_pack_play·review_session·legacy_vocab — 정확한 대상은 `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md:190-211` 확인)의 텍스트 CTA 대신 하단에 배치. 아이콘은 Material 폴백(`_deckCustomAssetsReady=false` 유지). 지시서 Lernen #24(하트/저장 이중)는 이 바의 "저장" 한 버튼으로 통합.

## I-E. 검증
`flutter analyze` 0 · 전체 `flutter test`(골든 포함 **0 실패** 목표) · 앱 실행 스모크(웹 릴리스 빌드 성공). 보고: 삭제 파일 목록·줄 수 감소·ARB 삭제 키 수·`git diff --cached --stat`.

## I-F. (W-D 이월) 글로서리 `sarangchae` 항목 — **→ W-J J8 로 흡수. W-I 에서 실행하지 않는다.**
`docs/data/cultural_glossary.json`에 `sarangchae`(사랑채·舍廊채: 바깥주인의 생활·접객 공간인 별채; `sarangbang`은 그 안의 방) 항목 추가(de/en/ko, https 출처 200 확인, 룬 한도) → `sori_stage_today_screen.dart` `_hanokStageTermIds`의 `HanokStage.sideBuilding` 매핑을 `'sarangbang'`→`'sarangchae'`로. `cultural_glossary_catalog_test` 18항목으로 갱신.

## I-G. (W-D/W-E 이월) 보상 카피 리터럴 정합 · 카탈로그 간격 — **→ W-J J7·J10 로 흡수. W-I 에서 실행하지 않는다.** (참고: 아래 2 의 `Spacing.lg` 는 오기, 정답은 `Spacing.xl`=24.)

## I-H. 실행 전제 (Fable 확정)
W-I 는 **PR-2(W-H) 머지 후 origin/main 에서 새 브랜치**로 실행(스택 PR 금지). 삭제는 import 폐포가 넓으므로 전체 `flutter test` 가 유일한 게이트, 골든 그룹 삭제로 `regenerate-goldens` 1회.
1. `lib/data/sori_activity_catalog.dart` `RewardContractItem.label`의 `SoriLocalizedCopy` 리터럴(de/en: 'Lern-XP'/'Learning XP', 'Passende Quest'/'Related quest', 'Verifizierter Hanok-Baufortschritt'/'Verified Hanok construction progress' 등)을 ARB `soriStageCatalogCopy` 값과 동일하게(Lern-XP/XP, Quest/Quest, Hanok-Bauteil/Hanok piece). 그리고 Today 미션 카드(`sori_stage_today_screen.dart` `_TodayMissionStage` 보상 행)가 `label.resolve()`가 아니라 `localCopy(context, label)`을 쓰는지 확인, 아니면 교체(증거 PNG `docs/screenshots/sori-stage-today-390.png`에 "Related quest"가 찍힌 원인 규명 — 픽스처 경로면 `test/sori_stage_visual_evidence_test.dart` `_snapshot()`의 리터럴을 ARB 경로로).
2. `lib/screens/sori_stage/sori_stage_catalog_screen.dart:≈174-178` 헤더→히어로 간격 72dp(`Spacing.xl`+`padding.bottom 48` 중첩) → `Spacing.lg`(24) 하나로. 골든/증거 PNG 재생성.


---

# 부록 — W-J 통합 브리프 §2(W-I 이관)·§3(W-H 이관: MOTION-4 파사드 매핑표·MOTION-3) 원문

## 2. W-I 로 이관하는 항목 (PR-3)

- **NAV-3 재분류(Jin 결정 §6)** — 온보딩 첫 장면 임베딩은 프로덕션 도달 불가: `onExit` 유일 생산자 `onboarding_journey.dart:35`(`openOnboardingFirstScene`) ← 유일 호출자 `character_selection_screen.dart:154`(`_proceed`, 비optional 모드 전용) ← 비optional `CharacterSelectionScreen()` 생성은 `onboarding_level_screen.dart:167` 한 곳 = 죽은 화면(route_transition_test.dart:78-80, W-I I-B 삭제 대상). 승인 시 W-I I-B 에 추가 삭제: `lib/services/onboarding_journey.dart`, `ScenarioPlayerMode.onboardingFirstScene`(scenario_player_screen.dart:266·:632·:766·:1477 분기), `onExit`/`onCompleted` 파라미터, `_withExitScope`(:2121)의 `widget.onExit != null` 분기, `_onExitCleanup`(:2167-2172)의 onExit 호출, `_exit`(:2145-2162)의 onExit 분기, `test/scenario_onboarding_completion_test.dart:83-103` onExit 케이스. 그러면 `exitOverride` API·신규 테스트 5·가드·AGENTS 규칙이 전부 불필요. **거부 시**(V1 임베딩 유지) 아래 §2-보류 설계를 W-I 후속으로 실행.
- NAV-2 허용목록 축소: J4 의 7파일 → 삭제 후 실측 집합(`transitions.dart`, `first_voice_success_screen.dart`, `character_selection_screen.dart`(:144 잔존 시), `onboarding_journey.dart`(NAV-3 거부 시)); `route_transition_test.dart:75-100` MaterialPageRoute 허용목록에서 `onboarding_level_screen.dart` 제거.
- NAV-4 `discover_screen.dart` 삭제 → `semantics_tap_guard_test` 허용목록 `isEmpty`.
- GOLDEN-2 고아 기준선 `test/goldens/baselines/home_compact_360x800.png`·`home_expanded_1280x800.png`(참조 테스트 0, b43bc827) 삭제.
- `mission_hero_card.dart` 삭제 시 유일 참조 `test/goldens/design_components_golden_test.dart:136-160`('MissionHeroCard 스켈레톤·allDone' 골든 그룹)과 `baselines/mission_hero_states.png` 동반 삭제 → design_components 기준선 2장만 남으므로 PR-3 에서 `regenerate-goldens` 1회.
- `onboarding_start_screen_test.dart` 등 삭제 파일의 J5 우회 주석은 손대지 않았으므로 삭제로 소멸.
- W-I I-A·I-F·I-G 절은 W-J 로 흡수됐으므로 **W-I.md 에서 삭제**하고 "W-J J2/J4/J7/J8/J10 참조" 한 줄만 남긴다.

**§2-보류: NAV-3 유지 설계(거부 시에만)** — `home_action.dart` `SoriHomeAction`(:28-51)·`SoriCloseAction`(:82-109)에 `final VoidCallback? exitOverride;`, `_leave`/`_close` 에서 `onLeave?.call(); if (!context.mounted) { return; } final override = exitOverride; if (override != null) { override(); return; }` 뒤 기존 이동. `study_frame.dart` 에 `exitOverride` 전달 + PopScope(:70-88) `canPop: !homeEscape.confirmWhen && exitOverride == null`, 핸들러에서 같은 순서. `scenario_player_screen.dart:1981-1993` 은 `_withExitScope` 래퍼 제거(바깥 PopScope 가 겹치면 onExit 2회) 후 **게이트 보존**: `onLeave: widget.onExit == null ? _onExitCleanup : null, exitOverride: widget.onExit == null ? null : _exitToOnboardingHost`, `_exitToOnboardingHost() { if (!_loadLifecycle.requestExit()) { return; } widget.onExit!(); }`; `_onExitCleanup` 은 `requestExit()` 만; `_popAfterLoadExit`(:2174-2179)는 `onExit` 우선. 테스트 `test/scenario_player_onboarding_exit_test.dart` 5케이스(①실패 상태 X ②홈 ③로딩 X ④maybePop ⑤onExit null 회귀; 현행 코드에서 ①·② 실패 원문 필수 — 단 홈 경로의 실제 앱 증상은 'ROOT 재푸시' 가 아니라 `/`=`OnboardingV2JourneyScreen` 재해석(main.dart:663-672)). `study_frame_navigation_test.dart` 'exitOverride' 4케이스. 정적 가드 '`exitOverride:` 전달 파일 == {scenario_player_screen.dart}' + `return _withExitScope(` 호출 정확히 1회(선언 `Widget _withExitScope(` 제외).

(검증 반영: **blocker** — NAV-3 는 죽은 경로용 공용 API 라 삭제로 재분류 · 유지 시에도 `requestExit` 단일 출구 래치를 override 안에 · `_withExitScope(` 카운트가 선언에도 매치 · 홈 경로 서술 정정 · 중괄호 규칙)

---

## 3. W-H 로 이관하는 항목 (PR-2)

### MOTION-4 → W-H H2 **대체 명세**(W-H.md H2 는 이 절을 가리키는 한 줄로 축소)

**근본 원인** — 실측 153회/44파일(pressable 5 포함, 순수 이관 148): selectionClick 75 · mediumImpact 34 · lightImpact 33 · heavyImpact 12. 호출부 전수 문맥 분류 결과 코드 관행은 **light=긍정(정답·알았다), medium=부정(오답·몰랐다)·커밋, heavy=완료·파괴적 작업 완료** — mediumImpact 34 중 24 가 오답/거절(vocab_pack:744 주석 '오답 — 더 강한 햅틱' 이 출처), heavyImpact 12 중 error 는 2 뿐(완료 5·파괴적 3·정답 1). 브리프 H2 원문(medium→success, heavy→error)을 기계 적용하면 24개 퀴즈 오답이 'success', 완료 8곳이 'error' 로 뒤집힌다. 햅틱 설정 키 없음(`storage_service.dart` grep 0); 사운드는 `Storage.sndMaster`(:2106)→`AudioPolicy.masterOn`→`SoundService._play` 로 이미 꺼진다 — H2 의 '`SoundService.enabled` 동기화' 는 읽기 전용 getter 라 **삭제**.

**파사드 매핑표**(`lib/services/feedback_service.dart`, `abstract final class SoriFeedback`, 전부 `static void`; `Future<void>` tear-off 도 `VoidCallback` 에 대입되므로 void 강제는 근거 아님 — 관행상 void):

| 메서드 | 햅틱 | sfx | 용도 |
|---|---|---|---|
| `select()` | selectionClick | 없음 | 선택·이동·토글(72) |
| `confirm()` | lightImpact | 없음 | 버튼 커밋·'알았다'·정답인데 사운드가 다른 경로에서 나는 곳 |
| `commit()` | mediumImpact | 없음 | **커밋 6곳 + swipe_card:453(우=앎)·:538(저장)** — 현행 강도 보존 |
| `success({tier})` | small light / medium medium / large heavy | correct / combo / complete | 정답+인접 `SoundService.correct()` 통합 |
| `error()` | mediumImpact | wrong | 오답+`wrong()` |
| `reject()` | mediumImpact | 없음 | 입력 검증 실패·'몰랐다' 자기판정(kkeunmari:388·406, vocab_pack:407, legacy_vocab:303, custom_pack_play:127) |
| `complete()` | heavyImpact | complete | 완료 5(`success(large)` 와 물리 동일 → **`success(large)` 는 두지 않는다**, tier 는 small/medium 만) |
| `levelUp()` | heavyImpact | levelUp | 메서드만, 배선은 H3-3 표 확정 후 |
| `destructiveDone()` | heavyImpact | 없음 | settings:1796·1824·2010 |

게이트: `if (!Storage.hapticsOn) { return; }` 햅틱 단에만(`storage_service.dart` `_b('kl_haptics', true)`/`_sb` 추가; `_b`(:1243)는 init 전에도 기본값이라 Storage 미초기화 테스트 무영향). `@visibleForTesting static void Function(String sfx)? debugSoundSink`.

**변경 요약** — 설정 사운드 스위치(settings_screen.dart:2352) 아래 같은 형태의 햅틱 `SwitchListTile`(`Icons.vibration`, ARB `settingsHapticsTitle` "Vibration"/"Haptics", `settingsHapticsDesc` "Kurzes Vibrieren bei Antworten und Tasten"/"Short vibration for answers and buttons"); `pressable.dart:107-124 _doHaptic`·`:134 _onLongPress` 를 파사드 경유(추천, 허용목록 1파일; `SoriHaptic` enum :235 유지); 43파일 148곳 문맥 기반 치환 — 인접 `SoundService.*` 쌍 30곳은 한 줄로 통합(이중 재생 금지); 함수 참조 5곳(swipe_card:453·460·477, quest_flow:36, mascot_pop:173) tear-off; `quest_flow.dart:36` 기본값 `haptic = SoriFeedback.confirm`, `sound = SoundService.correct` 유지; `mascot_pop.dart:150-152,172-173` 사운드 그대로·햅틱만 confirm. **이상치 6곳**(review_session:361 반대 매핑, particle_pop:117 정답 heavy, vocab_nuance:63 오답 selection, custom_pack_play:127 몰랐다 selection, hangul:1545·daily_char:193 오획 heavy, **swipe_card :453 medium(앎)/:460 light(모름) — `test/deck_swipe_physics_test.dart:754-760` 이 우측=mediumImpact 를 단언**) → §6 Jin 결정 전까지 `commit()` 으로 현행 강도 보존.

**순서 의존** — W-I I-3 삭제 대상(onboarding_start:70·onboarding_level:153·onboarding_preview:67, discover_screen)은 치환표에서 **제외**하고 148 → 실측 재산정. 실행 순서는 PR-2(W-H) → PR-3(W-I) 이므로 제외 목록을 브리프에 첨부.

**방어** — `test/haptic_guard_test.dart`(`lib/**` `\bHapticFeedback\.` 는 `feedback_service.dart` 만; `SoundService\.(correct|wrong|combo|complete|levelUp)\(` 직접 호출 래칫 실측값에서 하향; `feedback_service.dart` 안 `Storage.hapticsOn` 참조 ≥1) · `test/feedback_service_test.dart`(`setMockMethodCallHandler(SystemChannels.platform)` 로 `HapticFeedback.vibrate` arguments 기록 — **각 호출 뒤 `await tester.pump()` 필수**; 매핑표 1:1, `setHapticsOn(false)` 후 vibrate 0·sfx 유지, `setSndMaster(false)` 시 sfx 0, tear-off 컴파일) · Sonnet 148행 치환표(행·이전 API·문맥·새 호출·인접 사운드 제거 여부) 원문 보고 · AGENTS.md 서비스 항목.

**수용 기준** — 가드·파사드 테스트 초록 · analyze 0 · `l10n_parity`·`arb_l10n_guard` 초록 · **`content_feed_test`(:396-412)·`deck_swipe_physics_test`(:723-735,:754-760) 무변경 통과 — 채널·횟수뿐 아니라 `call.arguments` 의 햅틱 종류까지 동일** · 치환표에서 '정답→error'·'오답→success' 0, 인접 쌍 중복 0 · Jin 손맛 5포인트(단어팩 정답/오답, Silben-Kreuz 오답, 스피드매치 종료, 설정 데이터 삭제 완료, 햅틱 off 후 카드 프레스).

**롤백** — 파일 단위 `git checkout --`(커밋 전제 롤백 금지 — AGENTS 커밋 규칙).

**골든 영향(GOLDEN-4 보정)** — 설정 화면 행 추가(햅틱 토글 + H4 'Tour wiederholen')는 `screen_layout_golden_test.dart:95` settings 픽스처를 바꾸므로 **PR-2 도 `regenerate-goldens` 1회 필요**(settings 3장) — 또는 설정 행 추가를 PR-3 로 이관해 재생성을 1회로 합침(§6).

(검증 반영: **blocker** — swipe_card 우측 커밋 medium 을 `confirm`(light)로 바꾸면 deck_swipe_physics_test:756-760 즉시 실패 → `commit()` 메서드 신설·6번째 이상치 등재 · `success(large)`/`complete()` 물리 중복 제거 · 채널 기록 테스트의 pump 요건 · Storage init 의존·void tear-off 근거 삭제 · W-I 순서 의존·제외 목록 · 커밋 전제 롤백 삭제 · pressable :113/:134)

### MOTION-3 → W-H H6 둘째 문단 **대체**(Jin 결정 §6 후 실행)

**근본 원인** — `home_hero.dart:46` StatelessWidget, `_emotion`(:75-84)은 phase 파생, 소비처 정적 `Mascot(emotion:)`(:164)·영상 `CharacterClipPlayer(fallbackEmotion:)`(:200). `character_clip.dart:310-316` 계약상 영상이 준비되면 항상 mp4 → **라이트 모드 실기기(영상 경로)에서 emotionOverride 는 화면 변화 0**. CTA(`sori_stage_today_screen.dart:707`)는 탭 즉시 `SoriStageRewardReceiptService.capture → openActivity → pushNamed` 로 떠나 탭 시점 celebrate 는 전환 ~300ms 만 보임; 복귀(:735-738 `onActivityReturned()` 후 영수증)가 실제로 보이는 순간. `_celebrating`(:103)은 마일스톤 오버레이 전용.

**선택지(§6)** — (A) 최소 설계: `SoriCharacterHero.emotionOverride`(기본 null) + Today state `MascotEmotion? _heroEmotionOverride; Timer? _heroEmotionTimer;` + `_celebrateHero()`(마일스톤 진행 중이면 양보, 1.2s 후 복귀, dispose 취소) + `_TodayContent`(**:475**, 생성 :438-442)에 `onMissionStart`/`onRewardReturned` 콜백 → `_TodayMissionStage`(:581-587) CTA 첫 줄·영수증 시트 앞. 정적 경로(다크·forceStatic·videoUnavailable)에서만 보임. (D) 브리프 H6 전제(탭 시 보이는 반응)가 영상 경로에서 거짓임을 보고하고 W-H 범위에서 제외. (E) 히어로 `bubble` 문구를 1.2초 축하 카피로 교체(ARB de/en 신설, 영상 lease 무손상, 라이트 실기기에서도 보임). (B) 정적 교체 / (C) celebrate 클립 자산 — 비추천. **추천: (E), 차선 (D).**

**테스트 요건(A 또는 E 채택 시)** — `test/sori_character_hero_emotion_test.dart`(forceStatic, override 우선·null 시 phase·시맨틱 라벨 mascot.dart:220-229) · `test/sori_stage_today_hero_celebrate_test.dart`: CTA 탭 후 Today 는 새 라우트 아래 offstage → **`find.byType(Mascot, skipOffstage: false)`** 또는 push 가 일어나지 않는 스냅샷 구성; 복귀 경로는 `capture` 의 `loadNetworkBefore`/`captureLocalBefore` 주입점을 CTA 에 노출해 fake-async 에서 검증(`networkFuture` 는 fake-async 에서 완료되지 않음, reward_flow_test:66-75). 'reduce-motion 에서도 포즈 전환 유지' 원칙의 출처는 `mascot_pop.dart:145`.

(검증 반영: **major** — 테스트 ① offstage 로 실패 → skipOffstage/주입점 · `_TodayBody`→`_TodayContent` :475 · mascot_pop :157→:145 · (D)(E) 선택지 추가)

---


## I-I. (Jin 결정 2026-09-03) compound map 폐기 후보

Jin: Hanok 탭의 항공 부감 합성 지도(`PersonalHanokMap` compound 분기, `assets/illustrations/personal_hanok_v*`, `WorldMapViewport`)는 "지저분하고 이미 안 쓰는 이미지". PR-1(W-K 1b)에서 Hanok 탭 프리뷰를 단계 일러스트(`hanok_stages/stage_*_light.png`)로 교체했으므로 compound map의 남은 참조는 프로덕션 라우트가 없는 `HanokWorldScreen` 비임베드 경로뿐이다. W-I에서: 참조 0 재확인 → `PersonalHanokMap` compound 분기·`WorldMapViewport`·`personal_hanok_v*` 에셋을 `assets_unused/`로 이동(pubspec 선언 제거) + `personal_hanok_map_golden_test` 3건 정리. **Jin 게이트**(에셋 이동은 보고 후).

## I-J. (Jin 결정 2026-09-03) `kHanokWorldUpdating` 플래그 해제 시점

PR-1(W-K 1c)에서 Hanok 탭 프리뷰·Gye 카드 미니 씬·Gye 빈 포스터를 `SoriUpdatingScene`(`assets/illustrations/hanok/estate_overview.webp` + 베일 + "Wird gerade erneuert")로 덮었다(`lib/widgets/sori/updating_scene.dart` `kHanokWorldUpdating = true`). 새 한옥 지도(Living Hanok V1/IlDu 맵)가 사용자 노출 게이트를 통과하면 플래그를 `false`로 내리고, `false` 분기(단계 일러스트 프리뷰·`GyeHanok` 미니 씬·`GyeShowcaseArtwork`)를 새 지도로 교체한다. 그 전까지 I-I(compound map 폐기)는 `false` 분기와 함께 정리.
