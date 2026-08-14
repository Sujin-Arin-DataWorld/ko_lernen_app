# 인수인계 v2 — UI 개편 Phase 0~3 완주 (2026-08-14, Claude Code)

> **커밋 상태**: Phase 0~3 + §I 에셋 39장 = **`dcef0ba3` 로 커밋·origin/main 푸시 완료**
> (104 파일, Jin 지시). 병행 세션의 vocab-pack/SRS 클러스터는 의도적으로 제외 —
> §5 파일 소유권 참조. Jin 이 에셋(그레인 처리 포함) 승인함 (2026-08-14).

> **읽는 순서**: 이 문서(현재 상태·프로세스) → `UI_OVERHAUL_WORK_ORDER_2026-08-14.md`(상세 지시서, §A~§K) → `HANDOFF_UI_OVERHAUL_2026-08-14.md`(v1: 구속 결정·계약 8종·에셋 런북 §5 — 여전히 유효).
> v1 §4 는 지시서가 대체했고, 지시서 §D~§H 는 **이 세션에서 완료**됐다. 남은 것은 §I(에셋)·§J(Phase 4)·Jin 검증뿐이다.

## 0. 절대 규칙 (v1 §1 요약 — 위반 금지)

1. ⛔ 호랑이·까치 캐릭터 이미지 AI 재생성 무조건 금지 (기존 파일 합성만).
2. 커밋/푸시는 Jin 이 명시적으로 요청할 때만. 스테이징은 **본인이 만진 파일만**.
3. UI 문자열은 ARB DE/EN 쌍 필수, 하드코딩 금지. 추가 후 `flutter gen-l10n`.
4. 래칫 상한(타이포 가드·window_class 가드)은 **내려가기만** 한다. 상향 커밋 금지.
5. 매트 계약: 홈/Today 라이트 배경 = `HomeHeroClips.matte`(#FBF5EB) 평면 단색. 그라데이션·그레인 금지. `quest_cta_pinned` hex 단언 불변.
6. 변경마다 `docs/SESSION_LOG.md` 최상단 기록.

## 1. 완료 상태 (이 세션 기준)

| 구간 | 상태 | 핵심 산출물 |
|---|---|---|
| §C 잔여 (P1-7, §C-1-11) | ✅ | `widgets/sori/reward_icon.dart`(약속=이행 공용 매핑), 카탈로그 Learn 히어로 카드(`SliverMainAxisGroup`+`SoriIllustratedCard.shrinkWrap`, 21/9) |
| §D Today 폴리시 | ✅ | `sori_stage_today_screen.dart` raw TextStyle 12곳→토큰, 퀘스트 섹션→`SoriSectionHeader`, radius→토큰, a11y 매트릭스에 'sori today' |
| §E stats | ✅ | `SoriAppBar` ×2, 섹션 3개→`SoriSectionHeader`(레벨 라벨 trailing 승격, 카드 내 제목 제거), 게임 카드 compact+아이콘 44박스+cardTitle, 수치 tabular |
| §F profile | ✅(1건 유보) | `SoriAppBar`, `_ProfileSectionLabel`→`SoriSectionHeader` 위임, 게스트/연결/StatTile 토큰화(w900·Pretendard 제거). **§F-2 아바타 정지 이미지 미적용** — 코드의 Jin 2026-08-06 결정("영상 복원"+lease 직렬화)과 충돌하여 클립 유지. Jin 재확인 필요 |
| §G 온보딩 | ✅(2건 무수술) | consent·start·character_selection 에 `SoriPageHeader` 프레임, start 옵션=텍스트+우측 라디오. **level·preview 무수술** — 살아있는 "마당의 아침"/v2 캐러셀이 실질 충족, 기계 치환은 한옥 정체성 파괴 판단. a11y 에 start/level 추가 |
| §H 페이월+티저 | ✅ | paywall 히어로 슬롯(`rewardIllustrationAsset('paywall_hero')`+보자기 폴백)·`paywallEyebrow` ARB·가격 카드, `PackCard.premium`(왕관 칩, 자물쇠 우선)+`premiumNotifier` 구독, 센서 테스트 3건 |
| 수습 | ✅ | Antigravity 컴파일 잔해 4건, EN ARB 중첩 삽입 사고, window_class 가드(sarangbang 640→`SoriBreakpoints.tabletContent`), profile 테스트 lazy 스크롤 수리 |

**래칫 궤적 (전부 하향, = 각 구간의 파괴-복원 센서):**
raw TextStyle 437→426(§D)→420(§E)→412(§F)→409(§G) · radius 64→60→57→54 · AppBar 105→99 · w900 40→35 · w800 180→168 · Pretendard 119→94.

**검증 상태:** `flutter analyze` 0 · 전체 스위트 **유일 실패 1건 = `scenario_srs_persistence_flow_test`("completion only records negative SRS for the failed direct quest target") — 병행(외부) 세션 소관, 손대지 말고 기록만.** skip 13 = Linux 전용 골든(맥에서 자동 skip).

## 2. 남은 작업 (우선순위순)

1. ~~§I 에셋 생성~~ → **완료 (2026-08-14 저녁, BBANANA 재활성화 후)**: 활동 24종 +
   paywall_hero 생성·검수(재생성 4)·번들 완료, Jin 피드백("인쇄물 질감")에 따라
   활동 24 + paywall + 팩 14 전부에 `scratchpad/grain.py` 종이 그레인 후처리.
   상세는 SESSION_LOG 해당 항목. 팩 원본 백업: `scratchpad/packs_orig/`.
2. **Jin 검증 대기 항목** (§7 of v1 + 이번 추가):
   - Today 매트 — 실기기 Android 필수 (에뮬레이터가 거짓말한 이력)
   - 스와이프 손맛/back 제스처, DE 문구 검수, Linux 골든 재생성
   - §F-2 아바타(클립 유지 vs 정지 이미지) 재확인 / §G level·preview 무수술 판단 승인
   - 커밋 지시 (지금까지 커밋 0 — 전부 워킹트리)
3. **Phase 4** (지시서 §J — 배포 1릴리스 후): 레거시 셸·home_screen·wordle 삭제, 래칫 수렴, iOS teal 아이콘 정합.

## 3. 작업 프로세스 (이 세션의 방법론 — 그대로 따라라)

지시서 §A 의 7루프가 정본이다. 이 세션에서 실제로 굴린 형태:

1. **화면 하나 = 한 사이클**: 지시서 §해당 절 재독 → 현재 파일 실측(grep으로 raw TextStyle/radius/AppBar 좌표 잡기) → 편집 → `dart format` → `flutter analyze` → 해당 화면 테스트 → 전체 스위트.
2. **래칫 실측 요령**: 상한을 일시적으로 0(또는 낮은 값)으로 바꿔 실패 메시지의 "실제 N"을 읽고, 그 값으로 상한 확정 + 주석에 "N→M (§X 사유)" 한 줄. **절대 추정으로 내리지 마라** — 편집 누락을 래칫이 잡아준다.
3. **파괴-복원 센서**: 리스타일 구간의 센서는 래칫 하향 그 자체다(토큰화를 되돌리면 상한 초과로 빨개짐). 행동 변경(티저 등)은 전용 위젯 테스트를 만든다 (`vocab_packs_premium_teaser_test.dart` 참조).
4. **지시서와 현실이 충돌하면**: 기계적으로 따르지 말고 (a) 코드에 기록된 Jin 실기기 결정이 우선, (b) 살아있는 고품질 구현의 "실질 충족" 여부를 판단, (c) 무수술 결정은 SESSION_LOG 에 근거와 함께 기록하고 Jin 확인 목록에 올린다. (§F-2, §G level/preview 가 선례.)
5. **병행 세션 규칙**: 남의 파일(현재 vocab_pack_screen·result_screen·review_deck_service 계열) 실패는 기록만. ARB 는 공유 자원 — 외부 편집 착지 후 `flutter gen-l10n` 재실행으로 정합 회복 (이번에 실제로 발생).

## 4. 테스트 함정 노트 (이번에 밟은 것들 — 재발 방지)

- **lazy sliver/ListView**: 레이아웃이 커지면 하단 위젯이 빌드 범위 밖 → `find` 0개 또는 hit-test 실패. 순서: `scrollUntilVisible`(빌드) → `ensureVisible`(정렬) → `pump` → tap. `ensureVisible` 단독은 **미빌드 요소를 못 찾는다**.
- **CSV/rootBundle in testWidgets**: fake-async 안에서 `DataLoader.loadVocab`(CSV) 가 안 풀린다 → `await tester.runAsync(() => VocabPackService.loadAll())` 로 캐시 프리웜 후 pump.
- **ARB 삽입은 python + `json.loads` 검증**으로 (정규식 앵커가 중첩 키에 물리는 사고 1회 있었음). 삽입 후 반드시 gen-l10n + `grep -c` 로 getter 생성 확인.
- **sed 로 상한 프로브 후 복원할 때** 같은 패턴이 다른 줄에 물리는지 확인 (radius 상한을 437로 덮은 사고 1회 — Edit 툴로 정밀 복원했다).
- 골든은 Linux 전용 — 맥에서는 skip 이 정상(13건). 재생성은 Jin/CI 몫.

## 5. 이 세션이 만든/크게 바꾼 파일 (스테이징 후보)

**신규**: `lib/widgets/sori/reward_icon.dart` · `test/vocab_packs_premium_teaser_test.dart` · `test/legacy_vocab_flipgate_test.dart`(Antigravity 초안, 내가 수리) · `scripts/apply_paper_grain.py`
**변경(내 소관)**: `sori_stage_today_screen` · `sori_stage_catalog_screen` · `sori_stage_reward_receipt_sheet` · `widgets/sori/{activity_sheet,illustrated_card,pack_card,activity_illustration}` · `stats_screen` · `profile_screen` · `consent_screen` · `onboarding_start_screen` · `character_selection_screen` · `onboarding_preview_screen` · `paywall_screen` · `vocab_packs_screen` · `sarangbang_screen`(640 상수화) · `app_en/de.arb`(paywallEyebrow, soriStageActivityDetails) · `test/{typography_guard,window_class_guard,accessibility_guideline,profile_screen,onboarding_start_screen,sori_stage_catalog_reward_flow}_test.dart` · `docs/SESSION_LOG.md`
**외부 세션 소관 (건드리지 마라)**: `vocab_pack_screen` · `vocab_pack_result_screen` · `custom_pack_*` · `review_deck_service` · `daily_challenge` · `legacy_vocab_screen`(스와이프 배선부) · `flip_card` 등.

## 6. 다음 세션 로드맵 (기술 상세 — 2026-08-14 저녁 확정)

### 6.1 즉시 (다음 세션 첫 30분)

1. **병행 세션 수렴 확인** — 커밋 `dcef0ba3` 이후 워킹트리에 남은 것은 전부
   vocab-pack/SRS 클러스터다. 그 세션이 끝나면 반드시:
   - `flutter analyze` 0 확인 (마지막 실측: `main.dart:604` argument_type 에러 — 그쪽 리콜 라우트)
   - `data_integrity` green (그쪽 `vocab_pack_recall_screen.dart` 가 부재 에셋
     `mascot/tiger_idle.png` 참조 중 — ⛔ 캐릭터 에셋은 생성 금지, 기존 mascot 파일로 경로 교체가 정답)
   - **래칫 원복**: 그쪽 신규 화면들이 raw TextStyle +11 · w800 +7 · AppBar +5 초과.
     상한 상향 금지 — 그쪽 화면을 SoriTextTheme/SoriAppBar 로 토큰화해서 내려야 한다.
2. **Linux 골든 재생성** — 맥에서 불가(기준선은 Linux 정본, `screen_layout_golden_test.dart` 주석):
   ```
   flutter test --update-goldens test/goldens   # Linux CI/도커에서만
   ```
   Phase 1~3 이 의도적으로 바꾼 화면(vocab_packs·catalog·today·stats·profile·온보딩·페이월)의
   기준선을 갱신하고, 나머지가 무변경인지 diff 로 확인한다.

### 6.2 스토어 배포 (Jin 실기기 검증 후)

- **전제**: ① 병행 세션 수렴(위 6.1), ② Jin 실기기 Android 매트 확인(에뮬레이터는 거짓말 이력),
  ③ Linux 골든 green.
- iOS: 메모리 노트 — CocoaPods 는 `LANG=en_US.UTF-8` 필요, `build_ipa.sh` 업로드 스텝에
  cp 버그 있음 → IPA 를 altool 로 직접 업로드. ML Kit 때문에 arm64 시뮬레이터 빌드 불가.
- Android: versionCode 는 git 커밋수 자동증가(2026-08-13 세션).
- `FREE_LAUNCH=1` 게이트 상태를 릴리스 전에 Jin 과 재확인 (프리미엄 티저가 이제 카드에 보인다).

### 6.3 에셋 파이프라인 (승인됨 — 재사용법)

- **생성**: v1 핸드오프 §5 런북 (Seedream V4.5 + 앵커 URL). **검수 탈락 4유형과 교정 패턴**
  (이번 실측): ① 텍스트 침입 → "ENTIRELY BLANK … no markings of any kind" ② 만화식 검은
  외곽선 → "NO black outlines, flat matte color planes like paper cutouts" ③ 3D/사진 질감 →
  "flat paper-cutout, no wood grain texture, no 3D shading" ④ 포토리얼 배경 → 전체 장면을
  "the ENTIRE scene drawn as flat matte paper-cutout" 로 감싼다. 1차 합격률 21/25.
- **그레인**: `scripts/apply_paper_grain.py` (venv pillow/numpy) → `cwebp -q 84`.
  전 세트(39장) 기본값(fine 5.0/coarse 4.0) 적용·승인됨. 새 아트는 반드시 같은 처리를
  거쳐야 세트가 갈라지지 않는다. 그레인 전 팩 원본은 스크래치패드와 함께 소멸 —
  필요 시 앵커로 재생성.
- **온보딩 아트 3~4장**(plan 의 에셋 표)은 미생성 — preview 화면이 기존 PNG 로 살아 있어
  우선순위 낮음. 만들 거면 같은 런북+그레인.

### 6.4 Phase 4 마감 (배포 1릴리스 후 — 지시서 §J)

- 삭제: `LegacyAppShell`·`home_screen.dart`(공용 위젯으로 이미 추출됨)·`wordle_screen.dart`
  + 라우트/테스트 항목. 각각 grep 참조 0 확인 후.
- 래칫 수렴 目標: raw TextStyle 409→~50, AppBar 99→~10 (나머지 ~60화면 SoriAppBar 스윕),
  radius 54→0, Pretendard 94→0. 스윕 순서는 진입 빈도순 (settings → practice hub → 게임들).
- iOS teal 아이콘 정합, 다크모드 재검토는 그 뒤.

### 6.5 검증 상태 스냅샷 (커밋 시점)

- 내 소관 배치(smoke 24·teaser 3·reward_flow·a11y 40·guards) green. DE 문구 검수 완료
  (paywallEyebrow/soriStageActivity*/legacyVocabPrevious/statsGamesSection — 자연 독일어 확인).
- 전체 스위트의 실패는 전부 병행 세션 소관 3건 (6.1 참조). 잔여 BBANANA 크레딧 ~1,010.
