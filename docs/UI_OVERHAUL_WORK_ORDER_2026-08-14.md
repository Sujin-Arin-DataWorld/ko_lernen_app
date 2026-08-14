# UI 개편 작업지시서 v2 — Phase 3-2 → 4 (2026-08-14)

> **위치**: `docs/HANDOFF_UI_OVERHAUL_2026-08-14.md` §4 의 **구체화판**. 계약·gotcha·에셋 런북은
> 핸드오프가 정본이고, 이 문서는 "다음에 무엇을 어떤 순서로 정확히 어떻게"를 담는다.
> Phase 3-1(카탈로그 그리드)·4-A(스와이프 확산) 리뷰 피드백(§C)을 **먼저 반영한 뒤** §D 로 진행.

---

## A. 작업 방법론 — 이 개편이 굴러가는 7단계 루프 (사고방식의 코드화)

모든 화면 작업은 이 루프를 돈다. 지금까지의 Phase 0~2 가 전부 이 순서였다.

1. **계약 먼저** — 화면을 열기 전에 그 화면을 물고 있는 테스트부터 찾는다:
   `grep -rln "<ScreenName>" test/`. hex 단언·골든·스모크·접근성·스모크 등재를 확인하고,
   "이 변경이 어떤 테스트를 *의도적으로* 깨는가"를 시작 전에 선언한다. 의도하지 않은
   실패가 나오면 코드가 아니라 이해가 틀린 것이다.
2. **실측 기반** — 레이아웃 결정에 "아마" 금지. 오버플로 의심 = 390/600/720/1280 ×
   배율 1.0/1.3/2.0 매트릭스에서 실제로 돌려본다. 임계값(브레이크포인트성 상수)은 구성
   요소 폭의 **실측 합**에서 도출하고 산식을 주석으로 남긴다
   (선례: `stats_top_bar.dart` 의 `_kWordmarkTextMinWidth` 주석).
3. **최소침습 · 본문 그대로** — 이동/추출은 verbatim 복사가 원칙이고, **기존 테스트
   무변경 통과가 추출의 증명**이다 (선례: Phase 2a 홈 히어로 62테스트 무변경).
   리스타일과 로직 변경을 한 덩어리에 섞지 않는다 — 섞이면 회귀의 출처를 못 찾는다.
4. **폴백 우선 배포** — 에셋 의존 UI 는 errorBuilder/아이콘 폴백과 함께 먼저 배포하고,
   아트는 규약 파일명으로 나중에 드롭한다. 아트는 절대 배포 블로커가 아니다.
5. **래칫 동반 하향** — 화면 하나 끝날 때마다 실측을 다시 재고
   `test/typography_guard_test.dart` 상한을 내려 고정한다. 상한을 올리는 커밋 금지.
6. **병행 세션 존중** — `git status` 로 남의 미커밋 파일을 먼저 파악한다. 그 파일에서
   난 실패는 고치지 말고 SESSION_LOG 에 "병행 세션 영역"으로 기록만 한다.
   본인이 만진 파일만 스테이징.
7. **기록** — SESSION_LOG 최상단에 무엇을·왜·검증을. "다음 세션이 이 항목만 읽고
   맥락을 복원할 수 있는가"가 기준.

**검증 선언 규칙**: `flutter analyze` + 래칫 1종 통과만으로 "검증 완료"라 말하지 않는다.
해당 화면의 **전체 테스트 매트릭스(§K)** 를 돌린 뒤에만 완료 선언. (Phase 3-1 워크스루가
이 규칙을 어겼고, §C 의 검증 갭이 그 결과다.)

## B. 디자인 원칙 — "200%"의 기준

### Vocabulary급 4기둥 (구조)
1. **위계**: 화면당 **대형 텍스트는 1개** (`SoriTextTheme.hero` 또는 히어로 인사말).
   그 위에 eyebrow(자간 넓은 소형 라벨), 아래에 body. 두 개의 큰 텍스트가 경쟁하면
   둘 다 진다.
2. **카드 규율**: 모든 그리드 카드 = `SoriIllustratedCard` 규격 **하나**. 같은 앱 안에서
   카드 비율이 두 개면 규율이 아니다 — 팩 그리드(0.82)와 활동 그리드는 **같은 비율**을
   쓴다(§C-후속 참조). 라운드 `SoriRadius.lg`, hairline+`SoriElevation.low` 고정.
3. **일러스트 언어 단일**: 신규 아트는 전부 앵커 참조 생성(핸드오프 §5) — 크림 다이아
   배경 + 단청 점 2군집 + 무윤곽 면분할. 한 화면에 두 화풍 금지.
4. **화면당 1메시지**: 질문/행동 하나 + 옵션 카드 + 고정 하단 CTA. 부가 정보(설명·보상
   상세)는 **바텀시트로 강등**하지, 카드에 쑤셔넣지 않는다.

### Faceted Minhwa 5앵커 (정체성 — 이게 빠지면 "그냥 깔끔한 앱")
1. **한지 크림 바탕** — 배경은 항상 `SoriSurfaces` 크림 계열. (Today/홈만 매트 단색 계약.)
2. **단청 점 군집** — 장식 점은 흩뿌리지 말고 2군집. 일러스트 안에서 해결하고 UI 크롬에는 넣지 않는다.
3. **한옥 도상 = 진행/보상** — 도장(클리어)·보자기(보상)·한옥 단계(장기 진행)의 의미 배정을 섞지 않는다.
4. **마스코트 순간** — 캐릭터는 하루의 첫 진입(Today 히어로)과 완료 축하에만.
   목록·설정·통계에 마스코트를 뿌리면 희소성이 죽는다.
5. **절제된 모션** — `SoriMotion` 토큰만, reduce-motion 존중, 화면당 entrance 1~2개.

### 셀프리뷰 체크리스트 (화면 완료 선언 전에 전부 예/아니오)
- [ ] 대형 텍스트가 1개인가? eyebrow→title→body 위계가 서 있는가?
- [ ] 신규 raw `TextStyle(`/`AppBar(`/`BorderRadius.circular(숫자)` 0개인가? (마이크로 라벨도 `SoriTextTheme` — "작아서 예외"는 없다. 기존 프리셋에 없으면 프리셋을 추가하는 게 맞는지 먼저 검토)
- [ ] 새 문자열은 전부 ARB DE/EN 쌍인가?
- [ ] 잠금/프리미엄/클리어 상태가 `SoriIllustratedCardState` 로 표현되는가?
- [ ] 카드 비율·간격이 기존 그리드와 동일한가?
- [ ] 접근성: 탭타깃 48dp, 대비, Semantics 라벨, 배율 2.0 오버플로 없음?
- [ ] 래칫 하향했는가? SESSION_LOG 썼는가?

## C. Phase 3-1 · 4-A 리뷰 피드백 (Antigravity 세션 산출물)

> 결론 요약과 후속 수정 지시는 §C-3. 상세 근거는 §C-1(코드 리뷰)·§C-2(검증 실행 결과).

### C-0. 총평

방향은 정확히 맞다 — 카탈로그가 그리드 규격으로 왔고, 리워드 리시트 플로우·헤더(Profile 툴팁)·l10n·
vocab_pack Learn 스와이프 극성·재키(re-key) 계약은 전부 정확히 보존됐다(리뷰에서 praise 2건).
그러나 **"analyze + 래칫 1종 = 검증"이라는 선언이 이번 회차의 근본 문제**다. 실행하지 않은
스위트가 잡았을 결함(1280dp 오버플로)과, 코드 리뷰가 잡은 계약 위반(브라우즈 덱→판정 덱 임의 변경,
플립 전 오판정)이 그대로 남았다. §A-검증 선언 규칙과 §K 매트릭스를 이후 회차의 완료 조건으로 삼을 것.

### C-1. 필수 수정 (P0 — 다음 작업 시작 전에)

**스와이프 (legacy_vocab_screen.dart)**
1. **[major] 플립 전 스와이프가 답을 안 본 카드에 SRS 오답을 기록** — 이 화면의 판정 버튼은
   `if (_flipped)` 게이트가 계약인데 스와이프는 앞면에서도 커밋된다. 특히 좌 스와이프가
   `incrementWrongCount`(임계 3 → Extra-Lernset 편입)까지 조용히 오염시킨다.
   → `SoriSwipeCard(enabled: _flipped, …)` 한 줄로 수리 (위젯에 이미 `enabled` 파라미터 있음).
2. **[major] '이전 카드' 기능 소실 + 핸드오프 §4-A 계약 임의 변경** — legacy_vocab 은 핸드오프에
   "배지 없는 넘김 덱(좌=다음/우=이전)"으로 규정돼 있었고, 기존 우측 플링이 유일한 prev 경로였는데
   판정 덱으로 배선하며 `_prev()` 를 삭제했다. 판정 덱 유지가 더 낫다고 판단했다면 그 자체는
   가능한 결정이지만(실제로 SRS 학습 화면이라 판정 덱이 더 어울린다), **결정 변경은 기록+승인
   게이트**를 거쳐야 한다. → 권장안: 판정 덱 유지 + `enabled: _flipped` + 하단 행에 prev 버튼
   추가(또는 prev 포기를 Jin 에게 명시 확인) + SESSION_LOG 에 계약 변경 기록.
3. **[minor] 즐겨찾기 별 오버레이가 SoriSwipeCard 밖** — 퇴장 애니메이션에서 별만 제자리에 남는다.
   → Positioned 별을 SoriSwipeCard child 내부 Stack 으로 이동.

**카탈로그 (sori_stage_catalog_screen.dart)**
4. **[major·실측] 1280dp 에서 카드마다 RenderFlex 18px 오버플로** — `soriGridColumns` 를 클램프
   **전** 전체 폭으로 계산해 880 클램프 안에 6컬럼(카드 130px)이 들어간다.
   → `discover_screen.dart:349` 패턴: `soriGridColumns(constraints.maxWidth - padding.horizontal,
   target: 160, min: 2, outerPadding: 0, spacing: Spacing.md)`. 접근성 테스트에 1280dp 카탈로그
   케이스 추가로 회귀 고정.
5. **[major] 활동 설명(entry.description) 렌더 표면 0곳** — 카탈로그가 유일한 표면이었다.
   ARB 25종 select 문구가 고아가 됐다. → §C-2 의 "카드 상세 시트"로 복원 (아래).
6. **[major] 보상 계약(condition+items) 표면 소멸** — "학습 전의 약속"이 사라져 리시트가
   약속 없는 사후 통보가 됐다. → 동일하게 상세 시트로 복원.
7. **[minor] dart format 미준수 2파일** → `dart format` 실행. (이 저장소는 format-clean 이 baseline.)
8. **[minor] 잠긴 카드 시맨틱**: `button:true`+무동작 탭으로 노출, 잠금 설명 1줄 말줄임.
   현재 잠긴 엔트리 0개라 잠재 결함 → `SoriIllustratedCard` 에 locked 시 `button:false` 시맨틱
   옵션 추가 + locked footer maxLines 완화.
9. **[minor] `_StateLabel` raw TextStyle 11px** — "새 코드는 토큰만" 위반. "작아서 예외"는 없다.
   → `tt.cardSubtitle.copyWith(fontWeight: FontWeight.w600)`.
10. **[minor] 레이어 역전**: `widgets/sori/activity_illustration.dart` → `screens/…/sori_stage_common.dart`
    import. → `soriActivityIcon`/`soriActivityColor` 를 `widgets/sori/` 로 이동(공용 헬퍼의 정위치),
    common 은 re-export. doc-comment "AspectRatio 바깥" 도 사실과 다름 — "슬롯 안 Center" 로 정정.
11. **[minor] Learn 탭 상단 단어팩 대형 진입 카드 미구현** (핸드오프 산출물 누락) → §C-2 와 함께.
12. **[minor] `assets/illustrations/activities/.gitkeep` 미추적** — pubspec 등록과 **같은 커밋**에
    묶지 않으면 fresh checkout 빌드가 깨진다. 커밋 분할 시 주의.

### C-2. 정보 유실의 구조적 해법 — "카드 상세 시트" (P0 후속, 반나절)

카드 규율(4기둥 ④)의 대가로 설명·보상 계약을 **버리는 게 아니라 강등**하는 것이 원칙이다:
- 신설 `showSoriActivitySheet(context, entry, progress)` — `showSoriSheet` 기반 바텀시트:
  일러스트 배너(같은 규약 에셋) → 제목+분 → **설명(entry.description)** → 보상 카드
  (`reward.condition` 칩 + 아이템 목록) → `SoriButton.filled('시작')` = 기존 리시트 캡처 플로우.
- 카드 탭 = 즉시 시작(현행 유지), 카드 **롱프레스 또는 ⓘ** = 상세 시트. 잠긴 카드는 탭 = 상세
  시트(잠금 설명 전문 표시) — §C-1-8 의 시맨틱 문제도 함께 풀린다.
- 이 시트가 생기면 ARB 고아 문구 25종이 되살아나고, 리시트는 다시 "약속 이행"이 된다.

### C-3. 검증 실행 결과 (이번 리뷰에서 대신 돌린 스위트)

Antigravity 회차가 건너뛴 스위트를 전부 실행했다 (2026-08-14, 이 리뷰에서):
`sori_stage_catalog_reward_flow` · `sori_activity_catalog` · `sori_stage_responsive_accessibility`
· `sori_stage_shell` · `sori_stage_today_matte` · `swipe_card` · `flip_card_advance_regression`
· `vocab_pack_flip_spoiler` · `vocab_pack_requeue` · `screen_smoke` · `accessibility_guideline`
· `typography_guard` · `responsive` · `responsive_short_height`

**결과: 804 통과 / 0 실패 · `flutter analyze` 0.**

⚠️ 해석 주의 — green ≠ 무결함. §C-1-4 의 1280dp 오버플로는 기존 스위트가 카탈로그를
1280dp 에서 검사하지 않아 통과한 것이고, 리뷰 에이전트의 스크래치 위젯 테스트가 실측으로
증명했다. §C-1-1 의 플립 전 오판정도 행동 계약이라 스위트 밖이다. **커버리지 밖 결함이
남아 있으므로 §C-1 수리 + 회귀 테스트 추가(1280dp 카탈로그 케이스, legacy_vocab
플립-게이트 스와이프 테스트)까지가 이번 회차의 완료 조건이다.**

### C-3b. 수리 회차 검증 결과 (2026-08-14 오후, 독립 실측)

§C-1 수리 4건 **전부 CONFIRMED_FIXED** (주장이 아니라 실측):
- §C-1-1: `enabled: _flipped` 가 판정 SoriSwipeCard 에 정확히 배선 — `_canSwipe` 가 드래그
  자체를 차단, 하단 버튼의 `if (_flipped)` 게이트와 의미 일치.
- §C-1-3: 별 오버레이가 child Stack 내부 → Transform 과 함께 이동. (부수: 바깥 Stack 이
  단일 자식만 남음 — 무해한 흔적, 다음 손질 때 정리.)
- §C-1-4: 클램프 패딩 차감 폭(1280→840, 4열 ~201px). **스크래치 위젯 테스트 6케이스**
  (1280/1440/1280@1.3 × learn·games, 감도 검증된 하니스)에서 레이아웃 예외 0.
- §C-1-9: `tt.cardSubtitle.copyWith(w600)` — 파일 내 raw TextStyle 0. format/analyze clean.

**미충족 잔여 (완료 조건의 나머지 절반)**:
1. **1280dp 카탈로그 회귀 테스트 미추가** — `sori_stage_responsive_accessibility_test.dart` 는
   HEAD 대비 무변경(1280 은 셸만, 카탈로그는 390 뿐). 수리가 코드에만 있고 테스트에 고정되지
   않았다 — 다음 리팩터가 조용히 되돌릴 수 있다. 케이스 추가 필수.
2. **legacy_vocab 플립-게이트 스와이프 화면 테스트 미추가** — `swipe_card_test.dart` 는 위젯
   계약만 다루고 `enabled:false` 케이스도 없다. ① 위젯 테스트에 enabled:false 드래그 무시
   케이스, ② legacy_vocab 화면 테스트에 "앞면 드래그 → srsReview/wrongCount 미기록" 케이스.

### C-3c. §C 잔여 배치(시트·prev·레이어·회귀테스트) 검증 결과 (2026-08-14 저녁, 독립 실측)

**확정된 것**:
- 1280dp 카탈로그 회귀 테스트 = **진짜 민감함** (파괴-복원 프로토콜: 수리를 되돌리자 정확히
  그 케이스만 실패 8/1 → 복원 후 바이트 동일 + 9/9 green).
- `SoriStageRootHeader` 복원 충실(위임·툴팁·48dp 유지, raw TextStyle 3개가 토큰으로 수렴).
- 레이어 이동 완전 (`grep 'screens/' lib/widgets/` = 0). ARB 2키 en/de 대칭·명명 양호.
- 시트 시작 버튼이 리시트 캡처 플로우를 태움 — 약속→이행 고리 유지.
- 그들 매트릭스에서 빠진 responsive 2종을 대신 실행: **720/720 green** (prev 버튼 추가 후
  308dp 협폭 포함). → **§K 에 responsive_test·responsive_short_height 를 상시 포함할 것.**

**P0 — §D 진행 전 필수 (2건)**:
1. **시트가 ARB 를 우회한다**: title/description/잠금 설명/보상 condition·label 5곳이
   `resolve(lang)` 리터럴 — ARB description 25종은 **여전히 고아**이고, 향후 ARB 수정이
   시트에 반영되지 않아 카드(localCopy)와 시트(리터럴)가 어긋난다. 원인은 `localCopy` 가
   screens 층에 있는 것. → **icon/color 와 동일 수법**: `localCopy` 를 widgets 층으로 이동
   (+common re-export) 후 시트 5곳 교체.
2. **legacy_vocab 화면 레벨 플립게이트 테스트 여전히 부재** (두 번째 지적) — 위젯
   `enabled:false` 케이스만 있고, 화면 배선(`enabled: _flipped`) 자체를 고정하는 테스트가
   없다. 이 한 줄이 지워지면 SRS 오염 버그가 위젯 테스트 green 인 채 재발.
   → 앞면 드래그 → `srsReview`/`wrongCount` 미기록 + `_idx` 불변 단언.

**P1 — §D 와 병행 가능 (minor 5)**:
3. 잠금 판정이 카드(progress 우선)와 시트(정적 unlock OR)에서 다름 → `isEntryLocked(entry,
   progress)` 헬퍼 하나로 통일.
4. 리시트 캡처 시작 18줄이 onTap·시트 onStart 에 verbatim 중복 → `_start()` 추출 공유.
5. prev 버튼 44dp(<48) + Semantics/ARB 라벨 부재 → 48dp + `vocabPrevCard` 키(DE/EN).
   (wrap-around prev 는 `_next` 와 대칭이라 합리적 — SESSION_LOG 에 명시만.)
6. 잠긴 카드 semanticsLabel 이 여전히 'Open X' — 실제 동작(상세 시트)과 불일치 → locked
   분기 라벨.
7. 보상 아이콘·수량 표기가 약속 시트와 리시트 시트에서 상이(xp: star vs bolt 등) →
   `soriRewardIcon(kind)` 공용화 + 표기 통일 + 시트 스모크 테스트 1건.

잔여: §C-1-11 Learn 대형 진입 카드 (P1 과 함께).

### C-4. 이번 회차에서 잘한 것 (유지할 것)
- 리워드 리시트 캡처 플로우를 로직 그대로 이식 — 이런 "본문 그대로" 이식이 맞는 방식이다.
- vocab_pack Learn 스와이프: 극성·`_learnSrsRated` 1회 가드·서빙 re-key·ARB·버튼 유지 전부 정확.
- 래칫을 실측해 449→438 로 **하향**한 것 — 규율의 올바른 사용.
- `activityIllustrationAsset()` 규약 함수 + 폴백 위젯 분리 — 재사용 가능한 형태.

## D. Phase 3-2 — `sori_stage_today_screen.dart` 폴리시 (반나절)

**목표**: 기능 변화 0, raw TextStyle → 토큰. Today 는 이미 구조가 맞다 — 다듬기만.

| 위치 | 현재 | 지시 |
|---|---|---|
| `_TodayMissionStage` eyebrow (`soriStageBrandLabel`) | raw 13px gold w700 ls1.2 | `tt.eyebrow.copyWith(color: SoriColors.gold)` |
| `_TodayMissionStage` 헤드라인 | raw 26/w700 white | `tt.h1.copyWith(color: Colors.white)` — **hero(38) 금지**: 이 화면의 히어로는 인사말이다(위계 원칙 1) |
| `_TodayMissionStage` 보상 행 | raw w700 | `tt.label.copyWith(color: SoriActivityColors.onHanokStage)` |
| `_PendingBojagi` 제목/본문/CTA | raw 18/기본/w700 | `tt.h3` / `tt.bodySmall` / `tt.label` |
| `_HanokProgress` 제목/카운트/다음 조각 | raw 20 ×2, w700 | `tt.h3` / `tt.numeral.copyWith(fontSize: 20)`… 아니, 프리셋 발명 금지 — 카운트는 `tt.h3` + tabular 필요 시 `copyWith(fontFeatures:)` |
| `_QuestProgressRow` / 최근접 퀘스트 제목(22px) | raw | 퀘스트 섹션 제목 → `SoriSectionHeader(t.soriStageClosestQuests)` 로 교체(골드 헤어라인 — 정체성 앵커), 행 텍스트 `tt.cardTitle`/`tt.label` |
| `LinearProgressIndicator` radius 12/8 | 숫자 리터럴 | `SoriRadius.brSm` 계열 (borderRadius 파라미터는 BorderRadius 받음) |

**함정**: ① 미션 카드는 다크(`hanokStage`) 배경 — 텍스트 색은 반드시 `Colors.white`/`onHanokStage` 유지, 대비 테스트로 확인. ② 매트 계약 테스트(`sori_stage_today_matte_test.dart`) 불변 통과 필수. ③ `Spacing.page` 이미 적용돼 있음 — 재적용 금지.

**테스트**: matte 3종 불변 + `accessibility_guideline_test.dart` 의 화면 맵에 `sori today` 항목 추가(fixture: `loadSnapshot`+`now`) + 래칫 438→~426 하향.

## E. Phase 3-3 — `stats_screen.dart` (반나절)

Today 톱바 스트릭/레벨 칩에서 1탭 거리 — 격이 맞아야 한다.

1. `AppBar` ×1~2 → `SoriAppBar(title: t.statsTitle)` (래칫 AppBar 105→10x).
2. 본문 위계: 화면 첫 요소 = 스트릭 히어로 카드 (기존 유지, 수치는 `tt.numeral`).
   섹션 구분은 전부 `SoriSectionHeader` (XP · 주간 · 게임별 기록).
3. 주간 히트맵 셀: radius 숫자 리터럴 → 토큰, 셀 색은 기존 로직 유지.
4. 게임별 지표 행: `SoriCard(variant: compact)` 규율로 통일 (아이콘 44 박스 + cardTitle/cardSubtitle — `_ReviewCard` 패턴이 Phase 0 에서 삭제됐지만 같은 시각 규격).
5. **하지 말 것**: 차트 라이브러리 도입, 통계 로직 변경, 새 지표 발명.

**테스트**: 기존 접근성 테스트가 stats 커버 — 불변 통과. 골든 `screen_stats_*` 있으면 재생성 목록에 추가(Linux). 픽스처 생성자 없으면 `StatsScreen.preview()` 신설(Storage 읽기 주입) — home 패턴 참조.

## F. Phase 3-4 — `profile_screen.dart` (반나절~1일)

1. `SoriAppBar` 전환.
2. 상단 정체성 블록: 카드 1장 — 선택 캐릭터 **정지 이미지**(`Mascot`, 클립 아님 — 마스코트 순간 원칙: 프로필은 '순간'이 아니다… 예외로 정지 이미지는 허용, 애니메이션 금지) + 이름/레벨/가입상태.
3. 섹션: `SoriSectionHeader` (계정 · 학습 설정 · 데이터). 타일은 `SoriCard(compact)` + `ListTile` 조합 유지.
4. **GDPR/계정 영역(링크·내보내기·삭제)은 로직 한 줄도 건드리지 않는다** — 2026-08-10 수리가 얹혀 있는 민감 영역. 스타일 래핑만.
5. Today 톱바 프로필 아이콘 → 이 화면. 통계 진입 행이 없으면 추가(`/stats`).

**테스트**: `.preview()` 픽스처 존재 — 골든 3장 신설. 계정 플로우 테스트 불변 통과 필수.

## G. Phase 3-5 — 온보딩 5화면 (2~3일, 디자인 밀도 최고)

### 공통 프레임 (Vocabulary 설문 패턴의 한글소리판)
```
Scaffold (bg: SoriScreenBackground 기본)
└ SafeArea → SoriCenterClamp(480)
  └ Column
    ├ (스킵 가능 화면만) Align.topRight: TextButton('Überspringen')
    ├ SizedBox(Spacing.xxl)                    ← 상단 여백이 위계의 절반이다
    ├ SoriPageHeader(
    │   eyebrow: 단계 라벨,                     ← ARB 신규: onboardingStepLabel
    │   title: 질문형 헤드라인 (hero 38),
    │   body: 선택 설명 1줄)
    ├ SizedBox(Spacing.xl)
    ├ 옵션 카드 목록: SoriCard(selectable) + 우측 라디오/체크 
    │   — 텍스트+라디오만. 아이콘 남발 금지(Vocabulary 가 깔끔한 이유)
    ├ (스크롤 필요시 Expanded+ListView, 아니면 Spacer)
    └ 고정 하단 CTA: SoriButton.filled fullWidth
       ⚠️ quest_cta_pinned_test hex 단언 — CTA 색 변경 금지
```

### 화면별 지시
| 화면 | 지시 | 금지 |
|---|---|---|
| `consent_screen`(193) | 프레임만 교체: eyebrow 'DATENSCHUTZ', hero 타이틀, 법적 본문은 카드 안 스크롤. | **법적 문구·동의 로직 변경 금지** |
| `onboarding_start_screen`(344) | 설문 1페이지 정석 적용 (동기 선택). `learner_motivation` 데이터 불변 | 옵션에 일러스트 넣기(과함) |
| `onboarding_level_screen`(1052) | ⚠️ **전면 재작성 금지** — "마당의 아침" 기존 리디자인이 살아 있다. `SoriPageHeader` 정렬 + CEFR 카드 4장을 `SoriCard(selectable)`+`HanokLevelPalette` 액센트로 정리하는 **부분 수술**만 | 1052줄 재작성, 레벨 로직 변경 |
| `character_selection_screen`(921) | 프레임만: eyebrow 'DEIN BEGLEITER' + hero 질문. 캐릭터 패널·클립·색은 **픽셀 불변** | ⛔ 캐릭터 에셋/연출 변경 |
| `onboarding_preview_screen`(449) | 3카드 캐러셀 카드를 `SoriIllustratedCard` 규격으로(기존 onboarding/ PNG 사용), 페이지 도트 토큰화 | 새 캐러셀 라이브러리 |

**ARB**: 신규 키 최소화 — eyebrow 류만 추가(DE/EN 쌍). 기존 질문 문구 재사용 우선.
**테스트**: 각 화면 골든 3장(390/720/1280) + `accessibility_guideline_test` 에 start/level 추가 + 스모크 불변. 온보딩 플로우 테스트(`onboarding_flow_service`) 불변 통과.

## H. Phase 3-6 — `paywall_screen.dart` (반나절) + 프리미엄 티저

### 페이월 와이어
```
Column
├ SoriAppBar(leading: X 닫기, title 없음)
├ 일러스트 히어로: AspectRatio(16:9) Image.asset('assets/illustrations/reward/paywall_hero.webp')
│   errorBuilder → 기존 reward_bojagi_closed.png (폴백 우선 배포)
├ SoriPageHeader(eyebrow: 'PREMIUM', title: ARB 신규 — "모든 마당을 열어보세요" 톤)
├ 혜택 3~4행: Icon(check_rounded, success) + tt.body
├ 가격 카드: lightSurfaceRaised + primary 강조 테두리(선택 상태 규격) + 월가격 hero급 숫자(tt.numeral) + 조건 tt.caption
├ CTA: SoriButton.filled fullWidth
└ 복원 · 약관: TextButton 행 (tt.caption)
```
- `PremiumService`/RevenueCat 로직 불변. `FREE_LAUNCH=1` 게이트 불변.

### 프리미엄 티저 (중요한 미세 디자인 — 현재 시스템의 빈틈)
현재 `PackCard` 는 **선행 잠금**(이전 팩 클리어)만 표현한다. A2+ 레벨의 **프리미엄 잠금**은
카드에 보이지 않고 탭 후 인터스티셜로만 드러난다 — 전환 기회 유실. 지시:
1. `vocab_packs_screen` 에서 `_level != 'A1' && !PremiumService.isPremium` 이면 카드
   상태를 `SoriIllustratedCardState.premium`(골드 왕관 칩)으로, onTap → `PremiumService.gate`.
2. 선행 잠금(자물쇠 칩)과 시각적으로 구분됨을 골든으로 고정.
3. `premiumNotifier` 구독으로 구매 후 즉시 해제 반영.

## I. 에셋 — 활동 일러스트 24종 주제표 (생성 런북 = 핸드오프 §5, 앵커 참조 필수)

전부 **비캐릭터·비인물**. "same illustrated set" 앵커 프롬프트에 아래 subject 만 갈아끼운다.
파일명 = `assets/illustrations/activities/{id}.webp` (800px q88, ≤60KB).

| id | 탭 | 주제 (subject 골자) |
|---|---|---|
| course | Learn | stepping stones crossing a stream toward a small flag on the far bank (가이드 코스) |
| hangul | Learn | ink brush drawing one bold faceted stroke on a hanji sheet, inkstone beside |
| calligraphy | Learn | brush resting on brush-rest + small daily hanji card with a single stroke started |
| pronunciation | Learn | traditional buk drum with two sticks, faceted sound arcs rising |
| vocab_packs | Learn | stack of three bojagi-wrapped bundles in dancheong colors (팩!) |
| srs | Learn | wooden waterwheel with four hanji cards on its rim (반복 주기) |
| hard_words | Learn | archery target on wooden stand with one arrow dead-center |
| grammar | Learn | interlocking hanok bracket joinery (gongpo) pieces mid-assembly (구조) |
| listening | Learn | pungggyeong wind-chime under an eaves corner, faceted sound arcs |
| scenarios | Learn | two Hahoe masks facing each other on stands (대화 — 인물 아님, 탈) |
| smalltalk | Learn | two floor cushions facing across a low tea table, teapot between |
| book_capture | Learn | open book with a faceted magnifying lens hovering, light beam |
| bookshelf | Learn | chaekgado (책가도) scholar's bookshelf still life — 민화 장르 그 자체 |
| word_search | Learn | magnifying glass over scattered small hanji cards |
| daily_game | Games | daily paper calendar pad + rising gold sun disc |
| chosung | Games | stacked wooden blocks, one lifted mid-air revealing a hidden face |
| syllable_cross | Games | lattice window (창살) grid with a few cells filled gold (크로스워드) |
| cloze | Games | patchwork bojagi with one missing patch floating above its gap |
| speed_match | Games | two hanji cards snapping together with a small spark, speed lines |
| sentence_arcade | Games | wooden blocks linked in a row like a small train (문장 조립) |
| kkeunmari | Games | chain of traditional maedeup knots, one knot being tied (끝말잇기) |
| custom_quiz | Games | four-way wooden signpost at a fork (4지선다) |
| custom_matching | Games | pair of embroidered pouches, mirror images, ribbon between |
| custom_typing | Games | brush writing on lined hanji guided by a floating sound arc (받아쓰기) |

+ `reward/paywall_hero.webp`: "completed hanok estate at golden dusk, bojagi gift bundle at the gate" (§H).
검수 기준: 크림 다이아 배경 유지 / 단청 점 2군집 / 전통 사물 형태 정확(고무신 사건 §5 교훈 — 낯선 전통 사물은 형태를 문장으로 상술) / 100px 썸네일 실루엣 가독.

## J. Phase 4 — 마감 (Phase 2 가 실기기 검증·배포되고 1릴리스 후)

1. 레거시 삭제 순서: `LegacyAppShell`(app_shell.dart 내) → `home_screen.dart` → 레거시 전용 탭 화면(`practice_hub`·`discover`·`gye_tab` — **라우트 참조 grep 으로 실사용 확인 후**) → `wordle_screen.dart`(병행 세션 커밋 후) → 관련 골든/스모크/픽스처 정리.
   ⚠️ `showGyeChooser` 등 home_screen.dart 안의 **공용 함수**는 삭제 전 위젯 층으로 이주.
2. 래칫 수렴 목표: 화면 raw TextStyle ≤50 · raw AppBar 0 · Pretendard 리터럴 0 · radius 리터럴 0.
3. 자산 정리: GowunBatang 번들 제거 검토(SoriFonts.display 계획과 함께 결정), iOS 아이콘 배경 `#2AB7A9`(legacy teal) → 현행 정합, `assets_unused/` 47MB 처분은 Jin 결정.

## K. 테스트 매트릭스 & 배포 게이트

| 단계 | 반드시 green | 골든 | 실기기(Jin) |
|---|---|---|---|
| 3-2 Today | matte 3종 · sori_stage 4스위트 · 접근성(+today) · 래칫 | screen_sori_today 3장 신설 | — |
| 3-3 stats | 접근성(stats) · 스모크 | screen_stats 재생성 | — |
| 3-4 profile | 계정 플로우 테스트 전체 · 스모크 | profile 3장 신설 | — |
| 3-5 온보딩 | onboarding_flow · quest_cta_pinned(hex) · 스모크 · 접근성(+2) | 화면당 3장 | DE 문구 확인 |
| 3-6 페이월 | premium 게이트 테스트 · FREE_LAUNCH 빌드 스모크 | paywall 3장 | 구매 플로우 |
| 4-A 스와이프 잔여 | swipe_card · flip 회귀 3종 · requeue | — | **실기기 손맛 + back 제스처** |
| 공통 | `flutter analyze` 0 · `flutter test` 전체(병행 세션 항목 제외 사유 기록) | Linux CI 재생성 목록 유지 | Today 매트 |

배포 게이트: 각 Phase 커밋 분리 → Jin 시각 승인 → Linux 골든 → 실기기 스모크.
