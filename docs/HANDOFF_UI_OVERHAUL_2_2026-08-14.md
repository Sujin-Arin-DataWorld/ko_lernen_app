# HANDOFF — UI/UX 개편 2 "Sori Deck × 리소그래프 한지" (2026-08-14)

> **수신자**: 다음 AI 구현 세션 (모델 무관 — 이 문서만으로 실행 가능하도록 씀).
> **발신자**: Claude (Fable 5). Jin 의 개편 1차 리뷰 피드백 + 코드 전수 실측 기반.
> **신뢰 수준**: 이 문서의 파일:라인 인용·API 명·에셋 경로는 작성 후 **6-에이전트 적대 검증(발견 43건 반영)** 을 거쳤다. 그래도 병행 세션 커밋으로 라인은 밀릴 수 있다 — 수술 전 반드시 해당 파일을 열어 재확인하라(±수십 줄 오차는 식별자 grep 으로 복원).
> **먼저 읽을 것**: `AGENTS.md`(상시 규칙) → 이 문서 전체 → 필요할 때만 `docs/HANDOFF_UI_OVERHAUL_2026-08-14.md`(§1·§3·§5)와 `docs/UI_OVERHAUL_WORK_ORDER_2026-08-14.md`(§A 방법론·§B 원칙·§K 매트릭스).
> **선행 문서와의 관계**: 개편 1차의 §D~§H(Today 폴리시·stats·profile·온보딩·페이월)와 레거시 삭제(`79ae4a0c`)는 **완료**. 이 문서는 그 위에 얹는 **개편 2 신규 트랙**이다. 1차의 계약·래칫·에셋 런북은 전부 승계된다(§C).
> **커밋**: Jin 이 명시 요청할 때만, Phase 단위로 분리. 본인이 만진 파일만 스테이징.

---

## §0. 미션 한 문장

학습 카드를 **데이팅앱급 4방향 스와이프 덱**(좌=모름·우=앎·위=저장·아래=스킵)으로 완성하고, Today·카탈로그·Gye·Hanok 을 **"텍스트 벽 → 일러스트 언어"** 로 전환하며, 전 일러스트에 **리소그래프 인쇄 질감**(따뜻한 아날로그)을 입힌다. — 전부 기존 SoriStage 구조·계약 위에서, 구조 변경 없이.

## §1. Jin 의 구속력 있는 결정 (변경 금지)

**이번 라운드 신규 (2026-08-14 저녁, Jin 확정):**

1. **덱 4방향 의미 고정**: 좌=모름 · 우=앎 · **위=저장(super like)** · **아래=스킵(다음으로)**.
2. **덱 하단은 미니 원형 아이콘 버튼**(대형 텍스트 CTA "Gewusst/Weiß ich nicht" 제거). 모름 아이콘은 X 가 아니라 **`?`**.
3. **아이콘(모름·스킵·저장·앎)은 Material 아이콘 금지** — BBANANA/Adobe 로 한글소리 스타일(단청 도장 계열) 커스텀 제작. Material 아이콘은 errorBuilder 폴백으로만.
4. **카드 크기는 단어 텍스트와 절대 무관** — 3번째 재발이다. 이번엔 수리 + **센서 테스트**까지가 완료 조건 (§P1).
5. **아날로그 질감 = 리소그래프 인쇄 느낌** — 그레인 강화 + 잉크 미스레지스터 + 가장자리 번짐 + 얼룩. 은은한 수준이 아니라 "손으로 찍은 인쇄물"로 보여야 한다.

**승계 (1차 핸드오프 §1 — 그대로 유효):**

6. 라이트 한지 유지(다크 전환 없음). 7. SoriStage 5탭 셸이 정본. 8. **호랑이·까치 캐릭터 이미지 AI 생성 절대 금지**(기존 파일 합성만 — `docs/ASSET_GAP_R6_CONFIRMED_2026-08-03.md` ⛔). 비캐릭터 아트 신규 생성은 허용. 9. 단계적 배포 + Jin 시각 승인 게이트. 10. 버튼(이제 아이콘 버튼)이 접근성 정본, 스와이프는 가속 경로.

## §2. 실측 진단 — 왜 이 개편인가

구현 전에 이 표를 읽어라. 아래 Phase 들의 모든 수술 지점은 여기서 나온다.

| # | 증상 (Jin 리뷰) | 코드 실측 근거 |
|---|---|---|
| 1 | 덱이 데이팅앱처럼 안 됨 | `SoriSwipeCard` 는 **수평 전용** (`swipe_card.dart:203-206` — `onHorizontalDrag*`만, `_dy` 없음). up/down/덱스택/스와이프 힌트는 저장소 전체에 0건. |
| 2 | "Gewusst/Weiß ich nicht" 버튼 잔존 | `vocab_pack_screen.dart:891-911` — Learn 하단에 `SoriButton` 2개 (`vocabPackDontKnow`/`vocabPackGotIt`). |
| 3 | 스와이프 발견 불가 | `enabled:false` 면 드래그 핸들러 자체가 `null` (`swipe_card.dart:80-82, 203-206`) → 플립 전엔 카드가 1px 도 안 움직임. 코치마크·ARB 에 스와이프 언급 0건. |
| 4 | 카드 크기 회귀 | **폭 회귀다**: `_FlipFront`/`_FlipBack` 의 `SoriCard`(variant hero) 에 `width:` 없음 (`vocab_pack_screen.dart:1094,1187`; `custom_pack_play_screen.dart:388,485`). `FlipCard._fitFace` 의 세로 `SingleChildScrollView` 가 가로 제약을 loose 로 통과 (`flip_card.dart:96-108`) + `SoriSwipeCard` 내부 `Stack` 이 기본 loose (`swipe_card.dart:179`) → 카드 폭이 텍스트 내재폭으로 신축. `review_session_screen.dart:412-422` 가 "절대 지우지 말 것"이라 문서화한 바로 그 모드. **높이는 신축하지 않는다** — `_fitFace` 의 `ConstrainedBox(minHeight: constraints.maxHeight)`(`flip_card.dart:100-105`)가 이미 Expanded 높이로 강제. **카드 rect 불변을 단언하는 테스트 0개** (`vocab_pack_uniform_card_test.dart` 는 fontSize·rect.height 만). |
| 5 | Today 미션 카드 3중 반복 | `sori_stage_today_screen.dart` — eyebrow "SORI STAGE" + 제목 `soriStageMissionAction` + CTA **동일 ARB 키** = "Heutige Mission starten" ×2. `snapshot.today.destination` 은 라우팅에만 쓰고 활동명·일러스트를 표시하지 않음. |
| 6 | Today 히어로 아래 일러스트 0 | `_PendingBojagi`(`Icons.redeem_rounded` 36) · `_HanokProgress`(`Icons.home_work_outlined` 34) · `_QuestProgressRow`(맨 ListTile) — 4블록이 4가지 스타일, 이미지 0장. `structureStage.name` **enum 원문**("empty") 노출. |
| 7 | 까치가 작음 | 클립은 한지 매트가 구워진 **정사각** 프레임 → 밴드(폰 ~203dp, `home_hero.dart:92-111`)를 키우면 캐릭터가 아니라 여백이 커짐 (`home_hero.dart:100-103` 주석이 명시). `CharacterClipPlayer` 는 `SizedBox.square` 렌더 (`character_clip.dart:567-568`). |
| 8 | 카탈로그 "거대 아이콘" | 24장 전부 "중앙 단일 오브젝트" 구도(800×600, 4:3) + 카드 슬롯 16:10 `BoxFit.cover` 크롭(`sori_stage_catalog_screen.dart:246`, `illustrated_card.dart:142-154`)이 높이 16.7% 를 잘라 오브젝트를 더 확대. 잠금 0 상태라 footer 는 전 카드 동일한 "Jetzt verfügbar" ×13/10 (`:263-324`). |
| 9 | Gye 텍스트 벽 | 셸 헤더 38px(`sori_stage_gye_screen.dart:19-30`) + 임베디드 화면의 자체 헤드라인 20px(`gye_tab_screen.dart:207`) 경쟁. 문단 3개(`_Point`:264-292, **raw TextStyle Pretendard 13** — 토큰 우회). 한옥 프리뷰 8레이어 중 **3개가 0.22 유령**·1개 ~0.69 부분 실체화·4개만 1.0 (`gye_hanok.dart:73-81` + `gye_lantern_progress.dart:35-38` — permanent = `1 + lifetimeGoalsAchieved` = 4, `_previewMeta` :181-189) → 깨져 보임. 총 스크롤 ~1.3-1.5 화면. |
| 10 | Hanok 숏컷 = 고스트 텍스트 | `sori_stage_hanok_screen.dart:35-60` — Quests/Dojang-Heft/Bojagi 가 `SoriButton.ghost`(투명·무테두리·텍스트만). 정작 `stamps/` 14장·`decorations/` 24장·`reward_bojagi_closed.png` 가 번들에 있는데 이 표면에서 미사용. |

**병행 세션 경고 (착수 전 필수 확인)**: 워킹트리에 다른 세션의 미커밋 변경이 있다 — 특히 **`sori_stage_today_screen.dart` 는 +160줄 재구조화 중**: `_TodayMissionStage.build` 에 `_TodayUnavailableMissionStage` 조기 반환 분기(워킹트리 :314-320, 클래스 :417-558)가 신설됐고 그 아래 모든 위젯이 ~+160줄 밀린다(신규 언트래킹 테스트 `sori_stage_today_availability_test.dart` 가 이 동작을 고정). 그 외 `l10n/app_de.arb`·`app_en.arb`·generated, 게임 화면 다수(chosung/kkeunmari/listening/pronunciation_studio/silben_kreuz), `tool/generate_tts.py` 등. **P3·ARB 작업은 그 변경이 커밋된 뒤 시작**하고, 이 문서의 해당 파일 라인 인용은 커밋 후 재실측하라. 매 Phase 시작 시 `git status` 로 남의 파일을 파악해 본인이 만진 파일만 스테이징 (`UI_OVERHAUL_WORK_ORDER` §A-6).

## §3. Phase 지도

| Phase | 내용 | 규모 | 의존성 | 배포 단위 |
|---|---|---|---|---|
| **P1** | 카드 고정 지오메트리 수리 + 센서 | 반나절 | 없음 — **최우선** (버그 수리) | 단독 배포 가능 |
| **P2** | Sori Deck 2.0 (4방향·덱스택·아이콘 버튼·코치) | 2~3일 | P1 · §R-3 아이콘(폴백으로 선배포 가능) | 단독 |
| **P3** | Today 리디자인 (미션 카드 v2·히어로 줌·블록 통일) | 1일 | 병행 세션 커밋 | 단독 |
| **P4** | 카탈로그 폴리시 (4:3·footer·Games 히어로) | 반나절 | 없음 | 단독 |
| **P5** | Gye 압축 + Hanok 숏컷 타일 | 1일 | 없음 | 단독 |
| **§R** | 리소그래프 파이프라인 + 신규 에셋 6종 (+일괄 재처리) | 병행 | 샘플 3장 Jin 게이트 | 에셋 드롭 |

순서 원칙: P1 → P2 가 본선(Jin 1·2순위 불만). P4·P5·§R 은 병행 가능. 각 Phase 는 `UI_OVERHAUL_WORK_ORDER` §A 의 7단계 루프(계약 먼저 → 실측 → 최소침습 → 폴백 우선 → 래칫 하향 → 병행 세션 존중 → SESSION_LOG)를 그대로 돈다. **"analyze + 래칫 1종 = 검증 완료" 선언 금지** — §T 매트릭스 전부.

---

## §P1. 카드 고정 지오메트리 (회귀 수리 + 센서) — 최우선

**목표**: 4개 덱 화면 전부에서 카드 rect 가 단어·플립 상태와 완전히 무관해진다. **기능 변화 0. 시각 변화는 수리의 결과로만 발생한다** — ① 카드 폭이 항상 가용폭 가득(지금은 단어 따라 좁아짐), ② review/legacy 글자 크기의 덱-균일화. 그 외 리스타일 금지.

### P1-1. 수술 지점

계약의 정본 문장은 `review_session_screen.dart:412-422` 주석이다 — 읽고 시작하라.

**(a) `vocab_pack_screen.dart` Learn — 폭 핀 신설 (진짜 결함), 높이는 현 동작의 명시화.**
현 구조(`_buildLearn`, :827~): `Column → Expanded(:850) → SoriSwipeCard(:851, enabled: _learnCardRevealed) → SoriStudyScale(:865) → LayoutBuilder(:866) → FlipCard(:878, key: ValueKey('learn-$_learnServe') :879)`. — LayoutBuilder 가 SoriStudyScale **안**에 있다는 사실이 중요하다(아래 ⚠️).

```dart
// Expanded 안:
LayoutBuilder(builder: (context, box) {          // 신설: 슬롯 높이 소스 (box.maxHeight 만 사용)
  return SoriSwipeCard(
    enabled: _learnCardRevealed,
    // ... 기존 콜백/배지 유지
    child: SizedBox(                              // ← 카드 슬롯 고정 (P1 핵심)
      key: const ValueKey('deck-card-slot'),
      width: double.infinity,
      height: box.maxHeight,
      child: SoriStudyScale(                      // 기존 :865 이하를 그대로 이 안으로
        child: LayoutBuilder(                     // 기존 :866 내부 LayoutBuilder — 반드시 보존
          builder: (context, constraints) { /* headlineSize = soriUniformFitSize(...) 기존 그대로 */ },
        ),
      ),
    ),
  );
});
```

- ⚠️ **`soriUniformFitSize` 계산(:869-877)은 반드시 SoriStudyScale 서브트리 안에 남긴다.** `SoriStudyScale` 은 ≥600dp 에서 MediaQuery textScaler 를 최대 1.35× 부스트하고(`responsive.dart:38, 171-186`), `soriUniformFitSize` 는 `MediaQuery.textScalerOf(context)` 로 측정한다(:106). 바깥 `box` 컨텍스트에서 계산하면 태블릿에서 측정≠렌더 → FittedBox 안전망 상시 발동 → 이 Phase 완료 조건 위반. `h` 는 제약이 아니라 `soriStudyTypeScaleHeight(context)`(:868, `responsive.dart:73-74`) 출신이므로 바깥 LayoutBuilder 는 `box.maxHeight` 에만 쓰인다.
- 핀이 SoriSwipeCard 의 **child 안쪽**이어야 하는 이유: 내부 `Stack` 이 기본 loose(`swipe_card.dart:179`)라 바깥에서 죄어도 자식까지 안 내려간다.
- 높이 참고: 현 높이는 이미 `_fitFace` 가 Expanded 가득으로 강제하고 있어(§2-4) `height: box.maxHeight` 는 **현 시각 동작의 명시화**다(변화 없음). 다른 3화면은 0.82 배 — 이 1.0 vs 0.82 격차의 정합 여부는 P2 덱 통일 때 Jin 결정 항목(§J-7)으로 미룬다.
- 이중 안전벨트: `_FlipFront`(:1094)·`_FlipBack`(:1187)의 `SoriCard` 에 `width: double.infinity` 명시. (SoriCard 는 `width: null` 이면 내재폭 — `card.dart:251-255`.)

**(b) `custom_pack_play_screen.dart`** — `_Front`(:388)·`_Back`(:485)의 `SoriCard` 에 `width: double.infinity` 추가. 높이는 기존 `FractionallySizedBox(heightFactor: 0.82)`(:226-227) 유지. 슬롯 키 `deck-card-slot` 을 여기와 아래 두 화면에도 같은 방식으로 부여 — 센서의 공통 finder.

**(c) `review_session_screen.dart`** — 폭·높이 핀은 이미 정본(:426, :451-453). 슬롯 키만 부여.

**(d) `legacy_vocab_screen.dart`** — 폭(:803, :985)·높이(:459-460) 이미 핀. 슬롯 키만 부여.

### P1-2. 타이포 지터 정합 (사이징만, 리스타일 아님)

- vocab_pack 의 `soriUniformFitSize` 인자 `maxWidth: constraints.maxWidth - Spacing.xl * 2`(:872)는 **이미 정확하다** — `_FlipFront/_Back` 은 `SoriCard(variant: hero)` 이고 hero 패딩이 `EdgeInsets.all(Spacing.xl)`=24 (`card.dart:127-128`)이므로 내폭 = 슬롯폭 − 48. 슬롯 핀 이후 이 식은 그대로 두라. (`Spacing.cardInner` 16 으로 바꾸지 말 것 — 16px 과측정으로 FittedBox 안전망이 상시 발동한다.)
- `review_session_screen.dart:547-559` 와 `legacy_vocab_screen.dart:818, 998` 는 per-word `FittedBox` 단독이라 단어마다 글자 크기가 튄다 → 두 화면도 덱 전체 texts 를 `soriUniformFitSize`(`responsive.dart:93-139`) 로 넘기는 방식 채택 (custom_pack :421-440 이 선례 — 그대로 복제). **이는 의도된 시각 변화다** — SESSION_LOG 에 기록.
- 정상 상태에서 FittedBox 발동 0 이 완료 기준.

### P1-3. 센서 테스트 — 이 Phase 의 진짜 산출물

vocab_pack 은 기존 `test/vocab_pack_uniform_card_test.dart` 하니스 확장이 최소침습(CSV 프리로드·1170×2532 뷰포트가 이미 풀려 있음), 나머지는 신규 `test/deck_card_geometry_test.dart`:

- 각 화면: 짧은 단어("물")와 매우 긴 단어(한국어 장어 + "Internationaler Führerschein" 급 번역) 주입.
- finder: `find.byKey(const ValueKey('deck-card-slot'))`.
- 단언 3종: ① 서로 다른 단어에서 `tester.getRect(slot)` 완전 동일 ② 같은 카드의 플립 전/후 rect 동일 ③ 슬롯 폭 == 가용폭.
- **파괴-복원 프로토콜**: (a)의 `width: double.infinity` 한 줄(슬롯 SizedBox 쪽)을 주석 처리 → 센서 red → 복원 → green. **높이 라인은 파괴해도 red 가 안 뜬다** (`_fitFace` 가 이미 높이를 잡고 있으므로 — §2-4) — 폭 라인만 증명 대상. 결과를 SESSION_LOG 에 기록.

**완료 조건**: 위 단언 green + 기존 `vocab_pack_uniform_card_test`·`study_scale_test`·**swipe/flipgate 배터리 13건**(swipe_card 5 · review 3 · custom 3 · legacy 2 — SESSION_LOG 의 "11건"은 리셋 센서 추가 전의 낡은 수치다) 불변 + `flutter analyze` 0.

---

## §P2. Sori Deck 2.0 — 4방향 덱

**목표**: 카드가 데이팅앱처럼 "들고 넘기는 물건"이 된다. 판정 무결성(SRS)은 1비트도 안 흔들린다.

### P2-1. `SoriSwipeCard` 확장 (`lib/widgets/sori/swipe_card.dart`)

**API (기존 필드는 의미 불변 — 호출부 4곳 무수정 컴파일이 목표):**

```dart
class SoriSwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;    // 판정: 모름 — enabled 게이트 대상 (기존)
  final VoidCallback? onSwipeRight;   // 판정: 앎  — enabled 게이트 대상 (기존)
  final VoidCallback? onSwipeUp;      // 저장 — 게이트 무관, 커밋 후 카드 복귀(퇴장 없음). null 이면 위 방향 꺼짐
  final VoidCallback? onSwipeDown;    // 스킵 — 게이트 무관, 하단 퇴장. null 이면 아래 방향 꺼짐
  final SoriSwipeBadge? leftBadge, rightBadge; // 기존
  final SoriSwipeBadge? upBadge, downBadge;    // 신규
  final bool enabled;                 // ⚠️ 의미 유지 = "좌/우 판정 허용" (flipgate 센서들이 이 의미를 물고 있다)
  final VoidCallback? onBlockedHorizontalDrag; // 플립 전 수평 시도 → 힌트 훅 (드래그당 1회)
  final Widget? underlay;             // 덱 스택 미리보기 (다음 카드 앞면). null 이면 스택 없음
}
```

**제스처 알고리즘 (수평 전용 → pan):**

1. `onHorizontalDrag*`(:203-206) → `onPanStart/Update/End` 로 교체. `_dx += delta.dx; _dy += delta.dy;`
2. **지배축 잠금**: `_axis == null` 이고 `max(|_dx|,|_dy|) >= 12` 가 되는 순간 큰 쪽으로 `_axis` 확정. 확정 후 반대축 delta 무시. 드래그 종료 시 리셋. — 대각 드래그의 이중 트리거 구조적 차단.
3. **수평축 + `!enabled`**: 콜백을 죽이지 말고 **저항 드래그** — 카드 표시 오프셋은 `_dx += delta.dx * 0.15`, 커밋 절대 금지. 힌트 임계는 **원시 손가락 이동량 기준**: 별도 누적치 `_blockedRawDx += delta.dx` 를 두고 `|_blockedRawDx| > 24` 최초 1회 `onBlockedHorizontalDrag` 호출 (표시 오프셋 기준으로 걸면 0.15 저항 탓에 ~160px 을 끌어야 발화 — 발견성 목적 상실). 현재의 "핸들러 자체 null" 방식은 폐기하되, **`enabled:false` 에서 좌/우 콜백 0회 계약은 불변**(테스트 고정).
4. **커밋 임계**: 수평 = 기존 유지(폭 35% 또는 |v| > 700px/s, :59-60, 91-105). 수직 = `|_dy| > min(120.0, 카드높이 × 0.25)` 또는 `|vy| > 700`.
5. **커밋 연출**: 좌/우 = 기존(방향 × 폭 × 1.3 퇴장, `SoriMotion.fast`(150ms)/`SoriMotion.emphasis` — tokens.dart:400-411). 아래 = `높이 × 1.1` 하단 퇴장, 동일 토큰. **위 = 퇴장 없음** — 커밋 순간 `onSwipeUp` 1회 후 `SoriMotion.medium`(250ms)/`SoriMotion.release` 로 제자리 스프링백 (저장은 전진이 아니다 — §P2-3 버스트가 피드백). `_committing` 래치(:66)는 4방향 공유.
6. **reduce-motion**: 기존 패턴(:110-114, 129-133) 그대로 — 애니메이션 생략, 상태 즉시 확정, 콜백 즉시.
7. 틸트는 수평축에서만(기존 `progress × 0.16`). 수직축은 틸트 없이 순수 이동 + 미세 스케일(1.0 → 0.97).

**배지 4방향**: 기존 좌/우 배지(상단 우/좌, 램프 8%→33%, :185-192) 유지. `upBadge` 는 카드 **하단 중앙**, `downBadge` 는 **상단 중앙**. 비주얼은 §R 스탬프 에셋 + 텍스트 (에셋 없으면 기존 `_Stamp`(:215-274) 아이콘 폴백).

**덱 스택(underlay)**: `Stack` 최하단에 `IgnorePointer(child: Transform.translate(Offset(0,10), child: Transform.scale(0.95, child: underlay)))`. 진행도는 **커밋 거리로 정규화**: `p = max(|_dx| / (0.35 × 폭), |_dy| / 수직임계).clamp(0,1)` — 카드가 퇴장하는 순간 p=1 이 되도록 (|_dx|/폭 으로 나누면 커밋 시점 p=0.35 에서 underlay 가 65% 덜 올라온 채 점프한다). **위(-dy) 드래그는 p 계산에서 제외** (저장은 전진이 아니므로 다음 카드가 올라오면 거짓 어포던스). 퇴장 애니메이션 동안 p=1.0 유지. scale 0.95→1.0·y 10→0 선형. reduce-motion 시 정적(0.95/10). **underlay 는 반드시 다음 카드의 앞면(한국어 면)만** — 뒷면은 정답 유출 (`flip_card.dart:6-9` re-key 계약과 같은 원칙).

### P2-2. 화면 배선 — 방향→의미 매핑 (이 표가 정본)

| 방향 | pack Learn (`vocab_pack_screen.dart`) | review (`review_session_screen.dart`) | custom (`custom_pack_play_screen.dart`) | legacy (`legacy_vocab_screen.dart`) |
|---|---|---|---|---|
| → 앎 | `_learnGotIt`(:325) — 기존 | `_answer(true)`(:153) — 기존 | `_gotIt`(:86) — 기존 | `_gewusst`(:235) — 기존 |
| ← 모름 | `_learnDontKnow`(:342) — 기존 | `_answer(false)` — 기존 | 기존 `_skip`(:100-110)은 이름과 달리 **완전한 음성 판정**이다(`srsReview(gotIt:false)` :105 + `incrementWrongCount` :107) → **`_dontKnow` 로 개명**하고 배지·버튼 라벨을 `btnNichtGewusst` 로 정정(:221 현 `btnSkip` 오표기) | `_nichtGewusst`(:255) — 기존 |
| ↑ 저장 | 신규 `_saveCurrent()` → `addToWordbook(context, korean:, translationDe:, romanization:, posDe:, exampleKorean:, exampleDe:, source: 'deck_swipe')` (`wordbook_add.dart:15-68`) | 동일 (`_card` 데이터; AppBar 의 기존 `AddToWordbookButton`(:203-211)은 접근성 정본으로 **유지** — ↑ 는 같은 동작의 가속 경로) | **비노출** — 이 화면의 단어는 정의상 이미 사용자 팩 소속. `quickAdd` 는 quick pack 내부만 dedupe 하므로(`custom_pack_service.dart:247-263`) ↑ 는 무의미하거나 중복 복사가 된다. `onSwipeUp: null` + 버튼 바 `showSave: false`. "빠른 모음집으로 복사" 의미를 원하면 Jin 컨펌 후 후속(§J-8) | **추가 전용**: `if (!_favorites.contains(v.korean)) _toggleFavorite(v.korean)` (핸들러 :160-176; 별 오버레이 호출부 :496-521). 이미 즐겨찾기면 no-op + 스프링백 — 토글 그대로 쓰면 재스와이프가 **해제**되고 favorites 모드에선 리스트가 즉석 축소된다(:169-172). 해제는 기존 별 탭 경로만 |
| ↓ 스킵 | 신규 `_learnDefer()` → `LearnSessionQueue.defer()`(§P2-4) 후 **`_advanceLearn()`(:362-377) 를 그대로 호출** — defer 는 큐를 비우지 않으므로 `isDone→_enterQuiz` 분기 발동 불가. 금지는 SRS/오답 기록이지 재서빙 리셋이 아니다 | 신규 `_deferCurrent()` — 현재 카드를 `_deck` 맨 뒤로 이동 + **`_flipped = false` 리셋** + setState. 현재 카드가 이미 마지막 위치면(덱 길이 무관) 맨뒤-이동이 no-op 이므로 스프링백 처리 | 신규 `_defer()` — **기록 없는 전진**: `_advance()`(:112-129) 의 무기록 경로 재사용 또는 `_idx++; _flipped = false; _serve++` (re-key 계약) | `_skip()`(:300-305) — 화면의 기존 스킵 의미(⏭ `Storage.setVokSkipped` 카운터 :303, 칩 표시 :449)와 일치. 이 카운터는 SRS 가 아니므로 무기록 원칙에 저촉 없음 |

**철칙 (전 화면 공통):**
- ↑/↓ 는 **SRS·wrongCount·ledger·학습 Analytics 를 절대 건드리지 않는다**. `Storage.srsReview`/`incrementWrongCount`/`_recordSessionSrs`(:389-408)/`_learnSrsRated` 접근 금지. (근거: `PackSessionSrsLedger` 는 negative 가 세션 내 **터미널** — `pack_session_srs_ledger.dart:55-62`.)
- ↓ 스킵 핸들러는 4화면 모두 **재서빙 리셋을 포함한다** — `_flipped`(및 vocab_pack 은 `_learnCardRevealed`) false 복귀 + FlipCard serve 카운터 전진. 이게 빠지면 다음 카드가 **뒷면(정답)으로 서빙**되고 판정 게이트가 열린 채가 된다 — flipgate 계약 위반. 센서: "↓ 후 다음 카드 = 앞면 + 판정 비활성" 단언(§P2-6).
- 판정(←/→)은 반드시 **기존 화면 핸들러 경유** — `Storage.srsReview` 직접 호출 신설 금지.
- ↑ 저장은 전진하지 않는다. 중복 저장은 `WordbookAddResult.alreadyExists` 기존 스낵바로 해소(레거시는 위 가드).
- ↓ 는 플립 전에도 허용 (판정이 아니다 — "모르는 티 안 내고 넘기기"가 존재 이유).
- 마지막 카드 가드: `LearnSessionQueue` 는 빈 큐에서 `StateError`(:87-91) — 커밋 애니메이션 완료 콜백 시점에 큐/덱 상태 재확인 후 no-op.

**underlay 데이터 소스 (화면별):**

| 화면 | next 카드 | 비고 |
|---|---|---|
| pack Learn | **신규 API** `LearnSessionQueue.peekNext` (`T? get peekNext => _queue.length > 1 ? _queue[1] : null;`) — 현재는 `current` 만 노출되어 있어 필수 | §P2-4 단위 테스트 포함 |
| review | `_idx + 1 < _deck.length ? _deck[_idx + 1] : null` | |
| custom | `_idx + 1 < pack.words.length ? pack.words[_idx + 1] : null` | |
| legacy | `_filtered.length > 1 ? _filtered[(_idx + 1) % _filtered.length] : null` | 랩어라운드(:200-201) 대칭 |

각 화면은 자기 앞면 위젯(`_FlipFront`/`_Front`/등)을 재사용해 underlay 구성, null 이면 생략.

### P2-3. 하단 아이콘 버튼 바 (텍스트 CTA 교체)

신규 공용 `lib/widgets/sori/deck_action_bar.dart` — 4화면 공용:

```
Row(mainAxisAlignment: center, gap Spacing.lg=16):
  [?  모름]  64dp 원형 · lightSurfaceRaised 바탕 + accent(#A0524A) 1.5px 테두리 · 판정 게이트
  [↓ 스킵]  48dp 원형 · lightSurfaceAlt 바탕                                  · 항상 활성
  [복주머니 저장] 48dp 원형 · gold@0.18 바탕 + gold 1.5px 테두리 (showSave: false 로 숨김 가능 — custom) · 항상 활성
  [✓ 앎]   64dp 원형 · primary(#1F7A6B) 채움 (아이콘은 라이트)                 · 판정 게이트
```

- 아이콘: `assets/illustrations/deck/action_{dontknow,skip,save,know}.webp` (§R-3), 판정 32dp/보조 24dp, `Image.asset` + `errorBuilder` → Material 폴백(`Icons.question_mark_rounded`/`arrow_downward_rounded`/`Icons.redeem_rounded`/`Icons.check_rounded`). **폴백 우선 배포**.
- 판정 2개는 플립 전 `opacity 0.38` + 탭 시 §P2-5 힌트 칩. ⚠️ **이건 review·custom 에선 의도적 행동 변경이다**: 두 화면의 현 판정 버튼은 플립 게이트가 없다(review :506-519 — 앞면에서도 `_answer` 가 SRS 기록; custom :259-273 동일). 공용 바 적용 = flipgate 계약을 버튼까지 확장. 기존 테스트가 앞면 버튼 판정을 단언하고 있으면 의도 변경으로 갱신 + SESSION_LOG 기록, 그리고 "버튼 프리플립 탭 → SRS 0" 센서를 신설한다(§P2-6). vocab_pack(:898,:907 `onTap: gate ? handler : null`)과 legacy(`if (_flipped)` :533)는 이미 게이트됨.
- 프레스 피드백: scale 0.94, `SoriAnimation.tap`(100ms)/`SoriAnimation.tapOut` (`motion.dart:92, :99` — ⚠️ `SoriMotion` 이 아니라 `SoriAnimation` 클래스다).
- Semantics: 라벨은 기존 ARB 재사용 — vocab_pack 은 `vocabPackDontKnow`/`vocabPackGotIt`, 나머지는 `btnNichtGewusst`/`btnGewusst`, 스킵 `btnSkip`, 저장 신규 `deckActionSave`. `button: true`, 탭타깃 48dp+ 충족.
- **화면별 교체 스펙**:
  - vocab_pack: :891-911 버튼 2개 → 바 (진행 표시 등 다른 요소 불변).
  - review: :502-522 판정 행 → 바. ⚠️ 현재 행의 `key: _answerRowKey`(:503)가 코치 2단계 타깃(:98-103)이다 — **새 바에 `_answerRowKey` 를 재부착**하지 않으면 SpotlightCoach 가 조용히 스텝을 스킵한다.
  - custom: :259-273 판정 행 → 바 (`showSave: false`).
  - legacy: `if (_flipped)` 판정 행(:533-558)과 하단 유틸 행의 Skip 버튼(:629-636)을 바로 **흡수·제거**. prev(§C-1-2 로 복원된 계약 버튼, :561-588)·Hören TTS(:590-627)·Random(:638-645)은 **별도 보조 행으로 유지** — 4버튼 바 스코프 밖이며 삭제 금지.

### P2-4. `LearnSessionQueue.defer()` + `peekNext` (`lib/services/learn_session_queue.dart`)

- `defer()`: `markUnknown`(:74-85)과 동일한 재삽입 기하(`reinsertGap = 3` 뒤), 단 `misses` **증가 없음**(졸업 경로 차단), 반환 신규 `LearnAnswerOutcome.deferred`, `servedPosition`(:60-61) 규칙은 markUnknown 과 동일(진행바 후퇴 금지). 큐 1장이면 재삽입 = 같은 카드 재서빙(유효 — 무한 defer 는 사용자 선택).
- `peekNext`: 위 표 참조 — underlay 전용 읽기 API.
- 순수 Dart 단위 테스트: defer ×10 에도 `graduated` 미발생·`uniqueTotal` 불변·gap 위치 정확·빈 큐 가드·peekNext (2장/1장/0장).

### P2-5. 플립 게이트 힌트 + 코치마크

- **힌트 칩**: 플립 전 수평 저항 드래그(원시 24px+, §P2-1-3) 또는 판정 버튼 탭 시, 카드 상단에 칩 1개 페이드인(150ms) — 신규 ARB `deckFlipFirstHint` DE "Erst antippen und umdrehen" / EN "Tap the card to flip it first". 3초 자동 소멸, 드래그당 1회.
- **코치마크 — 공용 헬퍼 방식** (⚠️ `ScreenCoachMixin` 은 State 당 coachId 1개 구조라(`screen_coach.dart:24`) 이미 'review'/'legacyVocab'/'cpPlay' 를 점유한 3화면과 공유 불가): 신규 헬퍼 `maybeShowSoriDeckCoach(context, targetKey)` — `Storage.tutSeen('soriDeck')` + 프로세스 세션 1회 가드를 직접 걸고 `SpotlightCoach.show` 호출(1스텝: 카드 타깃 + `CustomPaint` 4방향 화살표 + 신규 ARB `coachSoriDeckBody` DE "Wische die Karte: rechts = gewusst, links = nicht gewusst, hoch = merken, runter = überspringen."). 각 화면의 기존 코치 완료 후(또는 기존 코치 미발화 시) 발화. `'soriDeck'` 을 `kScreenCoachIds`(`storage_service.dart:1279-1306`)에 등록 — `resetTutorials`(:1322-1333)의 리셋 커버리지가 공짜로 따라온다.
- vocab_pack 은 `FeatureCoach.vocabPack` 시트(:205-214) 경로 유지 — 문구를 스와이프 서술 포함으로 갱신(`feature_coach.dart:115-133` switch 2곳 + ARB :2056-2059 계열). `soriDeck` 스포트라이트 대상에서는 제외.
- 기존 coach 문구 갱신: `coachReviewStep2Body`(ARB :2199-2202)에 스와이프 언급 추가 — DE/EN 쌍.

### P2-6. P2 테스트 매트릭스

| 파일 | 케이스 |
|---|---|
| `test/swipe_card_test.dart` 확장 | up/down 커밋 각 1회·중복 0 / 수직 sub-threshold 스프링백 / 대각 드래그 → 지배축만 / `enabled:false`: 좌우 0회 + `onBlockedHorizontalDrag` 1회 + up/down 은 동작 / reduce-motion 즉시 / underlay 히트테스트 불가 |
| 신규 `test/deck_vertical_gesture_test.dart` (화면 센서) | 4화면 × ↓: `srsReview` 0·`incrementWrongCount` 0·전진(재삽입) + **다음 카드 = 앞면 + 판정 비활성**. ↑(vocab_pack·review): quickAdd 1회·전진 없음·SRS 0·앞면에서도 동작. legacy ↑: 즐겨찾기 추가·재스와이프 no-op(해제 안 됨) |
| 신규 `test/vocab_pack_flipgate_test.dart` | 기존 3화면과 동형 2케이스(앞면 좌/우 드래그 → SRS·wrongCount 0 + 진행 불변). **개편 1차부터 뚫려 있던 구멍** |
| review/custom 버튼 게이트 센서 | 앞면 버튼 탭 → SRS 0 (P2-3 의도 변경의 고정). 기존 테스트 중 앞면 버튼 판정을 단언하던 케이스는 의도 변경으로 갱신 + SESSION_LOG |
| `test/learn_session_queue_test.dart` 확장 | §P2-4 단위 케이스 전부 |
| 기존 배터리 | swipe/flipgate 13건·`flip_card_advance_regression`(2건)·`vocab_pack_requeue`·`vocab_pack_flip_spoiler`(1건) **전부 green** (flipgate 센서의 계약 강화는 허용, 완화는 금지) |

**완료 조건**: 위 전부 + `flutter analyze` 0 + 래칫 하향 + ARB DE/EN 쌍(`flutter gen-l10n`) + SESSION_LOG. **실기기(Jin)**: 4방향 손맛, 좌우 엣지 vs 시스템 back 제스처, 위 스와이프 vs 알림 셰이드.

---

## §P3. Today 리디자인 — "무대에 오늘의 주인공을 올려라"

**목표**: 미션 카드가 "오늘 뭘 하는지" 보여주는 한 장의 포스터가 되고, 히어로 아래 블록들이 하나의 일러스트 언어로 통일된다. 구조(ListView 순서)·매트 계약·`verticalDirection: up` 불변.

**⚠️ 선행 조건**: 병행 세션의 `sori_stage_today_screen.dart` 재구조화(+160줄, `_TodayUnavailableMissionStage` 신설 — §2 경고 참조)가 커밋된 뒤 시작하고, 아래 라인 인용은 **재실측**하라(±160). `_TodayMissionStage` 의 unavailable 조기 반환 분기는 **그대로 보존** — 미션 불가 상태가 새 미션처럼 보이면 안 된다.

### P3-1. `_TodayMissionStage` v2

3중 반복(§2-5)을 해체한다:

```
Container(hanokStage #173D36, SoriRadius.xl=24, padding 0):   ← 다크 그린 유지 (브랜드 최강 순간)
├ (entry != null 일 때만) ClipRRect(top 24만): AspectRatio(21/9)
│   Image.asset(activityIllustrationAsset(entry.id), fit: BoxFit.cover,
│     errorBuilder → SizedBox.shrink())   ← 2차 가드일 뿐: AspectRatio 는 자식이 아니라 제약으로 크기가 잡히므로
│                                            errorBuilder 만으론 빈 다크 밴드가 남는다. 1차 강등은 entry null 게이트다
├ Padding(Spacing.xl=24):
│  ├ eyebrow: 신규 ARB soriStageTodayMissionEyebrow "HEUTIGE MISSION" — tt.eyebrow + SoriColors.gold
│  ├ 제목: entry 로컬라이즈드 타이틀 — tt.h1 white  ← "Heutige Mission starten" 반복 제거
│  ├ 보상: contract.items 를 ' · ' 조인 문자열 대신 **아이템별 칩**으로 — 각 칩 = soriRewardIcon(item.kind)
│  │   (lib/widgets/sori/reward_icon.dart:10) 16px + 라벨 tt.label onHanokStage. items 는 List<RewardContractItem>
│  │   (sori_stage_progression.dart:95,:106) 라 kind 가 아이템마다 다르다 — 단일 아이콘(현 Icons.roofing_rounded) 금지
│  └ CTA: SoriButton lg — 라벨 신규 ARB soriStageMissionStart "Starten" (제목이 이미 무엇인지 말한다)
```

- **활동 entry 는 기존 `activityForRoute(snapshot.today.destination?.route)` 로 얻는다** (`sori_stage_progression_service.dart:34` 사용례, 정의 `sori_activity_catalog.dart:432-441`) — **신규 조회 함수 발명 금지**. destination 은 route 기반 모델(`today_learning_snapshot.dart:21-30`)이고 가능한 라우트는 4종뿐('/course/mission'→course, '/vocab/pack'→vocab_packs, '/review'→srs, '/scenario'→scenarios) — **전부 `activities/{id}.webp` 보유**. 제목 = `entry.title` 로컬라이즈드 픽, 일러스트 경로 = 기존 `activityIllustrationAsset(entry.id)`(`activity_illustration.dart:18`). `entry == null` 강등 분기는 현재 도달 불가지만 가드로 필수.
- `destination == null`(미션 없음) 경로와 unavailable 분기는 기존 문구 그대로.
- ⚠️ 함정: 다크 카드 위 텍스트는 white/`onHanokStage #FFF7E4` — 대비 테스트. `sori_stage_today_matte_test.dart` 3종 불변. 배율 2.0 오버플로 매트릭스.

### P3-2. 히어로 크롭-줌 — 까치를 키운다 (에셋 재생성 없이, ⛔규칙 준수)

클립 정사각 프레임의 매트(#FBF5EB)는 화면 배경과 **동일한 단색**이므로 크롭이 시각적으로 불가능하다 — 이걸 이용한다. `home_hero.dart:164-180` 의 `CharacterClipPlayer` 를:

```dart
static const double _kHeroZoom = 1.2;  // 주석: 클립은 정사각+매트 베이크(#FBF5EB=배경 동일)라 크롭 불가시.
                                       // 1.3 초과 금지 — 발/그림자 잘림은 실기기에서만 판정 가능.
ClipRect(
  child: Transform.scale(
    scale: _kHeroZoom,
    alignment: kind == MascotKind.magpie
        ? Alignment.bottomCenter          // 까치 발/그림자 위치 고정
        : Alignment.center,               // 호랑이 standing idle 상하 무크롭
    child: CharacterClipPlayer(size: bandHeight, ...),
  ),
)
```

- 2026-08-15 실기기 시각 검수: 원본부터 기상 중 머리가 잘리고 루프 경계가 튀는
  `tiger_rise_hanji`는 번들에서 제외했다. 호랑이는 경계 접촉 없는 10초
  `tiger_thinking_hanji` standing idle을 중앙 1.2배로 쓰고, 까치만 기존 하단 정렬을 유지한다.
- `forceStatic`/다크 경로의 `Mascot` PNG(:158-163)는 투명 배경 — **줌 적용 금지**.
- 밴드 높이 산식(:92-111)·캡·매트 계약 불변. `sori_stage_today_matte_test` green 유지.
- **Jin 실기기 게이트**: 발끝/꼬리 잘림·매트 경계 확인 후 1.15~1.3 미세조정.
- (스코프 밖) 인사말 raw TextStyle(:116-129, w900)은 의도된 예외 — 건드리지 않는다.

### P3-3. 블록 통일 — 아이콘 텍스트 → 일러스트 언어

**(a) `_HanokProgress` → 한옥 스테이지 배너 카드.**
- 상단 `ClipRRect(SoriRadius.brLg)` + `AspectRatio(16/5)` 배너: 현 단계 이미지. HanokStage→에셋 매핑은 **기존 리졸버 재사용** — `grep -rn "hanok_stages/stage_" lib/` 로 위치 확인(`assets/illustrations/hanok_stages/stage_{empty,foundation,pillars,beams,thatch,tile_partial,tile_complete,dancheong,gate,windows,sidebuilding,jongga}_light.png` 12장 실재). 신규 매핑 함수 발명 금지.
- 배너 우하단 `"$built / 7"` — `tt.h3` + tabular. 아래 진행바(minHeight 12, `SoriRadius.brSm`) 유지.
- **enum 원문 노출 수리**: `structureStage.name` → 신규 ARB 매핑 `hanokStageName_{enumName}` — `lib/models/hanok_stage.dart:8` 의 **전 값 exhaustive switch** DE/EN (empty→"Bauplatz", foundation→"Fundament", pillars→"Säulen", beams→"Balken", thatchRoof→"Strohdach", tileRoofPartial→"Erste Ziegel", tileRoofComplete→"Ziegeldach", dancheong→"Dancheong", gate→"Tor", windows→"Fenster" — 나머지 값은 파일을 열어 채운다). 위젯층 헬퍼로 두어 다른 표면도 재사용.

**(b) `_QuestProgressRow` → 카드 규율 + 보상 썸네일.**
- 맨 `ListTile` → `SoriCard(compact)` 행: leading 34×34 보상 썸네일 + 제목 `tt.cardTitle` + 진행바 + `n/m` `tt.label`.
- 썸네일: `quests_screen.dart:502-522` 의 `_RewardThumb`(decorations PNG + 폴백)를 **`lib/widgets/sori/reward_thumb.dart` 로 승격** 공유 (widgets → screens import 금지 — `UI_OVERHAUL_WORK_ORDER` §C-1-10 선례).
- 행 탭 = 기존 라우팅 유지.

**완료 조건**: matte 3종·접근성(today)·스모크·`sori_stage_today_availability_test`(병행 세션 신규) 불변 + 배율/폭 매트릭스 + 래칫 하향 + ARB 쌍 + SESSION_LOG. 골든: **`screen_sori_today` 3장은 신설이다** — `test/goldens/screen_layout_golden_test.dart` 의 screens 맵(:88-100, 현재 settings·vocab_packs 뿐)에 `sori_today` 항목을 추가(결정적 렌더를 위해 `now`/`loadSnapshot` 시임 주입 — 1차 핸드오프 §3-4 픽스처 원칙)하고 Linux 에서 생성.

---

## §P4. 카탈로그 폴리시 (Lernen·Spiele)

**목표**: "거대 아이콘 벽" → 정돈된 일러스트 카탈로그. 구조·시트·리시트 플로우 불변.

1. **이미지 슬롯 16:10 → 4:3** — `sori_stage_catalog_screen.dart:246` 을 `hero ? 21/9 : 4/3` 로. 원본(800×600)과 일치 → 크롭 0, 오브젝트 체감 ~17% 축소. `childAspectRatio: 0.78`(:140-147) 재실측 — **산식 주석 필수** (§A-2). 390/720/1280 × 1.0/1.3/2.0 매트릭스 + **기존 1280dp 카탈로그 회귀 케이스 green 유지** (`sori_stage_responsive_accessibility_test.dart` — 파괴-복원으로 감도가 증명된 케이스. 깨뜨리면 수리가 아니라 회귀).
2. **footer 조건화** — `_StateLabel`(:263-324): 상태 신호는 `SoriActivityState { ready, inProgress, completed, locked }` 4값 + `SoriActivityProgress { state, current, target }` 뿐이다(`sori_stage_progression.dart:30, :171-183` — 활동별 "보상대기/신규" 신호는 **모델에 없다**. `pendingBojagiCount` 는 스냅샷 레벨 :191). 조건: `state == ready && (current == null || current <= 0)` → footer **null** (전 카드 동일 "Jetzt verfügbar" 는 노이즈); locked/inProgress/completed 는 표시. ARB `soriStageActivityReady`(:2927) 키는 삭제하지 않는다.
3. **분(分) 표기 이동** — subtitle(:243 `soriStageMinutes`) → 이미지 우하단 미니 필: `Colors.black.withValues(alpha: 0.55)` 바탕(⚠️ `withOpacity` 는 deprecated — 저장소는 전부 `.withValues` 이관 완료, 쓰면 analyze 0 이 깨진다) + white `tt.caption` + `SoriRadius.pill` + padding(8,3). `SoriIllustratedCard` 에 선택 파라미터 `imageOverlay` 신설 — ⚠️ 배치는 **이미지 슬롯 내부**: `illustrated_card.dart:142-154` 의 `ClipRRect > AspectRatio > _Illustration` 을 새 `Stack` 으로 감싸 `Positioned(bottom, right)` (기존 카드 전체 Stack :135-173 에 넣으면 필이 footer 위에 얹힌다). 기본 null — 기존 호출부(팩 그리드 등) 영향 0 확인.
4. **Games 탭 히어로** — :56-68, 114-133 의 hero 승격이 Learn(`vocab_packs`) 전용 → Games 탭이면 `daily_game` 을 동일 `_ActivityGridCard(hero: true)` 로 승격, 그리드 제거 로직 대칭.

**완료 조건**: `sori_activity_catalog`·`sori_stage_catalog_reward_flow`·responsive 2종·접근성 스위트 green + 래칫 + SESSION_LOG. 골든 재생성 목록 갱신.

---

## §P5. Gye 압축 + Hanok 숏컷 타일

### P5-1. Gye (`gye_tab_screen.dart` — 임베디드는 `sori_stage_gye_screen.dart` 경유)

**목표**: 390×844 에서 **스크롤 없이** CTA 도달(±1줄). 화면당 1메시지.

1. **헤드라인 단일화** — `_IntroEmpty`(:191-261)에 `embedded` 플래그를 전달해, 임베디드일 때 자체 eyebrow/헤드라인/리드(:201-209) **제거**. 셸 헤더가 유일한 대형 텍스트.
2. **유령 프리뷰 → 단일 공동마당 성장 쇼케이스** — 2026-08-15 실기기 시각 검수로 기존 `showcase: true`(완성 종가 위에 서로 다른 원근의 `gye_*` 8장을 모두 1.0 합성)는 건물이 한곳에 뭉쳐 보여 **폐기**했다. `_IntroEmpty`는 393:220 슬롯에서 `assets/video/gye/gye_shared_hanok_build.mp4`의 빈 마당→공동 한옥 완성을 한 번 재생하고 마지막 프레임을 유지한다. 오디오는 제거했으며 reduce-motion·영상 불가·초기화 실패에서는 같은 영상 9.7초 프레임의 `assets/illustrations/gye/gye_showcase_courtyard.webp` 포스터를 쓴다. 기존 `gyeShowcaseCaption`과 실제 가입 계의 `GyeHanok` 진행도(완성/다음/ghost)는 별도 renderer로 보존한다. 향후 가입 계 자체를 다시 그릴 때만 동일 고정 캔버스 stage 0–8을 제작한다.
3. **문단 3개 → 1줄 칩 카드 3개** — `_Point`(:264-292, raw Pretendard TextStyle)를 `SoriCard(compact)` + `Icon 20` + **신규 단문 ARB** 로: `gyeExplainWhatShort` "Eine kleine, freiwillige Lerngruppe." / `gyeExplainWhyShort` "Ein gemeinsames Hanok, kein Wettbewerb." / `gyeExplainHowShort` "Beitritt mit 6-stelligem Code." (EN 쌍). **기존 장문 키 3종은 삭제하지 않고 ⓘ 상세 시트로 강등** — `showSoriSheet` 기반, 칩 행 우측 ⓘ 1개 (`UI_OVERHAUL_WORK_ORDER` §C-2 원칙: 정보는 버리지 않고 강등한다).
4. **프라이버시 카드 → 1줄** — :236-248 을 `gyePrivacyTitle` 1줄 + 동일 ⓘ 시트에 `gyePrivacyBody` 수록.
5. 미션 칩(`sori_stage_gye_screen.dart:32-58`)의 raw `TextStyle(fontWeight: w700)` → `tt.label` 계열.
6. raw Pretendard TextStyle 토큰 수렴 — ⚠️ 위치 정정: `_GyeList`(:296-331)는 이미 토큰만 쓴다(:313,:315). 실제 잔존은 **`_GyeCard`(:368-372, :380-384)** 와 **비임베디드 AppBar 타이틀/서브타이틀(:97-114)** — 이 둘을 이번 회차에 수렴.

**완료 조건**: 390×844 실측(스크린샷) 1화면 이내 + 접근성 테스트 gye 케이스 추가 + `showGyeChooser`(:396-459) 플로우 불변 + 래칫 하향.

### P5-2. Hanok 숏컷 (`sori_stage_hanok_screen.dart:35-60`)

고스트 텍스트 버튼 3개 → **일러스트 숏컷 타일 3개** (Row, 균등 폭, gap `Spacing.md`):

| 타일 | 썸네일 (40×40) | 라벨 | 카운트 (tt.caption) | 라우트 |
|---|---|---|---|---|
| Quests | `reward_thumb.dart`(P3-3b 공용화) + 대표 decoration PNG 1장(`ls assets/illustrations/decorations/` 후 선택) | `soriStageQuests`(:2887) | `"$done / $total"` — ⚠️ 14 는 상수가 아니다: `quests_screen.dart:409-421` `_QuestSummary` 의 계산(`done = completed 수`, `total = active∪completed 수` :416-417)을 재사용하라. 카탈로그엔 18정의(시즌 4 포함, `quest_catalog.dart`)가 있어 시즌 윈도우 안에선 total 이 커진다 | `/quests` |
| Dojang-Heft | `assets/illustrations/stamps/stamp_lotus.png` | `soriStageDojang`(:2888) | 획득 수 — 소스는 `dojangcheop_screen.dart:64-66` (`Storage.earnedStamps` ∩ `DancheongMotif.values` 14종), 표시 선례 :95 `t.dojangProgress` | `/dojangcheop` |
| Bojagi | `reward_bojagi_closed.png` (`bojagi_screen.dart:14-15` 상수 재사용) | `soriStageBojagi`(:2889) | 대기 n — Today `pendingBojagiCount` 와 동일 소스 | `/bojagi` |

- 타일 = `SoriCard(compact)` 세로 구성(썸네일→cardTitle→caption), 전체 탭타깃, Semantics `button:true` + "라벨, 카운트" 병합.
- **카운트 배선이 반나절을 넘기면 1차 배포는 카운트 없이** 타일+라벨만 — 카운트는 후속 커밋 (폴백 우선 배포).
- `HanokWorldScreen(embedded:)`(:34)·헤더(:22-33) 불변.

**완료 조건**: 스모크·접근성 green + 3 라우트 동작 + 래칫.

---

## §R. 아트 디렉션 v2 — "리소그래프 한지 인쇄" + 신규 에셋 6종

### R-1. 후처리 파이프라인 `scripts/apply_riso_v2.py`

기존 `scripts/apply_paper_grain.py`(휘도 전용, fine 5.0/coarse 4.0, seed 7, `grain()` :23)를 **확장**한 신규 스크립트 (기존 스크립트 보존 — 배포 세트의 정본 이력).

**⚠️ 전제**: 번들 39장(activities 24 + packs 14 + paywall_hero)은 **전부 이미 fine 5.0/coarse 4.0 그레인이 구워져 있고 원본은 소멸됐다** (`apply_paper_grain.py:12-14` docstring + 1차 핸드오프 V2 §6.3). 따라서 ① 그레인 단계는 **추가분(delta)만** 얹는다 — 39장 공통.

| 단계 | 파라미터 (기본값) | 구현 |
|---|---|---|
| ① 그레인 추가분 | fine **+2.0** / coarse **+1.5** (기베이크 5.0/4.0 위에 → 체감 ~7.0/5.5) | 기존 `grain()` 재사용 (휘도 전용, 색상 불변) |
| ② 잉크 미스레지스터 | offset **1.5px**, 대상 채널 R | R 채널만 (+1.5, +0.5) 시프트 사본을 60% 블렌드 — 단청 적/금에서 판 어긋남 |
| ③ 잉크 스펙클 | density **0.4%**, 휘도 L<40% 면 한정 | 다크 면에 밝은 점 노이즈 — 잉크가 안 앉은 종이 알갱이 |
| ④ 가장자리 번짐 | radius **1px**, opacity **20%** | 다크 플레인 마스크 1px 팽창 저불투명 합성 |
| ⑤ 웜 캐스트 | **4%** overlay #F4E8D0 (Hanji Ivory) | 전체 소폭 온도 상승 |
| 시드 | `crc32(파일명)` | 파일별 결정적 재현 |

- 대안(스크립트 막히면): Adobe MCP `image_add_grain`+`image_adjust_color_temperature` — 단 ②③④ 불가라 스크립트가 정본. 더 나은 대안: §5 앵커 워크플로로 원본 재생성 후 풀 파이프라인 — Jin 이 크레딧 소모를 승인할 때만.
- **적용 대상**: 39장 전부 (리인코딩 cwebp q88, 장당 ≤70KB). `gye/`·`hanok_stages/`·`stamps/`(투명 PNG·레이어 합성물)는 **스코프 제외** — Jin 별도 결정.
- **게이트**: 샘플 3장 (`packs/bamboo`, `activities/listening`, `reward/paywall_hero`) 처리 → before/after Jin 승인 → 일괄. 미승인 파라미터로 전량 처리 금지.

### R-2. 신규 생성 프롬프트 델타 (앞으로 모든 아트 공통)

1차 핸드오프 §5 앵커 워크플로 그대로 + 스타일 문단에 추가:

> "Printed like a risograph poster: visible paper tooth, subtle ink misregistration between color plates, slightly uneven ink coverage, tiny ink speckles in dark areas — warm, organic, hand-printed feel. Still NO outlines, still flat faceted color planes."

### R-3. 신규 에셋 6종 — 덱 액션 아이콘 4 + 판정 스탬프 2

**플랫폼**: BBANANA MCP (`generate_image`, 모델 "Seedream V4.5", aspect_ratio "1:1") — BBANANA 연결 세션에서 실행. Adobe Express Pro 로 Jin 수작업 제작 경로도 동급 허용.
**공통 사양**: 생성 1024×1024 → `sips -Z 512` → 투명화(흰 배경 생성 시 Adobe MCP `image_remove_background`) → `cwebp -q 90` → 512px, 장당 ≤30KB. 경로 `assets/illustrations/deck/` — **pubspec 등록과 같은 커밋에 디렉터리(.gitkeep 포함) 추가** (`UI_OVERHAUL_WORK_ORDER` §C-1-12 교훈: 분리 커밋은 fresh checkout 빌드를 깬다).
**Family resemblance**: 4개 아이콘은 `ASSET_GENERATION_BIBLE.md` §4.2 도장 템플릿의 팔레트·면분할 규율 공유 — 동일 시각 무게. 각 프롬프트 끝에 §1.6 마감 문장 + R-2 리소 델타. **캐릭터·사람·텍스트 절대 금지.**

| 파일 | subject 골자 (프롬프트에 이식) |
|---|---|
| `action_dontknow.webp` | a bold brush-stroke question mark, single confident ink stroke in seokganju red-brown #A0524A, angular faceted stroke edges, small ink dot as the question mark's point |
| `action_skip.webp` | a downward angular arrow built from three stacked faceted chevrons, ink black #1A1410 with one gold #DFA951 accent facet |
| `action_save.webp` | a Korean bokjumeoni lucky pouch with drawstring knot, gold #DFA951 and dancheong red #C24A45 facets, tiny norigae tassel |
| `action_know.webp` | a circular dancheong seal stamp: thick red #C24A45 ring, cream #FAF6EC inner, bold angular checkmark in the center in red |
| `stamp_know.webp` | same seal language as action_know but larger composition with slight stamped-ink unevenness, like freshly pressed on hanji (카드 판정 오버레이용) |
| `stamp_dontknow.webp` | a small hanji card with the brush question mark stamped slightly tilted, seokganju ink (카드 판정 오버레이용) |

검수 기준(§5 교훈 승계): 100px 축소 실루엣 가독 / 형태 정확(물음표·체크 왜곡 시 재생성) / 4종 무게 균일 / 리소 질감이 형태를 잡아먹지 않음. **3~5변주 → 1장 선택.**

### R-4. (선택) 활동 아트 구도 재생성

§P4-1(4:3 복원) 후에도 "단일 오브젝트" 구도가 과하면, Jin 지목 카드만 R-2 델타 + "subject placed slightly off-center, occupying ~40% of frame, with more negative space and a second small supporting element" 로 재생성. 전량 재생성 금지 — 24장은 Jin 승인 자산.

---

## §T. 테스트 매트릭스 & 검증 루틴

| Phase | 반드시 green | 신규 센서 | 골든(Linux) | 실기기(Jin) |
|---|---|---|---|---|
| P1 | uniform 2종·study_scale·swipe/flipgate 13건·analyze 0 | deck_card_geometry (폭 라인 파괴-복원 증명) | — | — |
| P2 | P1 전부·flip_card_advance_regression(2)·vocab_pack_requeue·vocab_pack_flip_spoiler(1) | swipe_card 확장·deck_vertical_gesture·**vocab_pack_flipgate**·review/custom 버튼 게이트·learn_queue defer/peekNext | — | 4방향 손맛·엣지 제스처 |
| P3 | matte 3종·sori_stage 4스위트·접근성(today)·availability | — | **screen_sori_today 3장 신설** (screens 맵 추가) | 히어로 줌 잘림·매트 |
| P4 | catalog 2스위트·responsive 2종·**1280dp 카탈로그 케이스** | — | 카탈로그 재생성 | — |
| P5 | 스모크·접근성(+gye)·gye chooser 플로우 | — | gye/hanok 재생성 | — |
| §R | — (에셋) | — | 영향 골든 재생성 | 샘플 3장 승인 게이트 |

공통 루틴 (매 Phase):

```bash
flutter analyze                                    # 항상 0
flutter test test/typography_guard_test.dart       # 래칫 — 하향만
flutter test test/sori_stage_today_matte_test.dart test/home_hero_matte_test.dart test/quest_cta_pinned_test.dart
flutter test                                       # 전체 (병행 세션 실패는 SESSION_LOG 에 사유 기록 후 제외 선언)
```

시각 검증: `.claude/launch.json` `flutter-web`(8765) + 온보딩 우회 localStorage 3키(1차 핸드오프 §3-8). **매트/영상/스와이프 손맛 판정은 실기기 Android 만 신뢰.**

## §C. 계약 승계 (요약 — 원문이 정본)

1. **매트 계약**: 홈/Today 배경 = `HomeHeroClips.matte` 평면 단색, 그라데이션·그레인·틴트 금지 (`home_hero.dart` doc). 2. **`verticalDirection: up`** 제거 금지. 3. **hex 단언 3종** (`home_hero_matte`·`quest_cta_pinned`·`sori_stage_today_matte`) — 색 변경은 여기서 잡히는 게 의도. 4. **래칫**(`typography_guard_test.dart`) 상한은 내려가기만 — 새 코드는 토큰/공용 위젯만, "작아서 예외" 없음. deprecated `withOpacity` 금지(`.withValues(alpha:)`). 5. **ARB DE/EN 쌍** + `flutter gen-l10n`, 하드코딩 금지, if/else 중괄호. 6. **⛔ 호랑이·까치 AI 생성 금지** — §P3-2 줌은 렌더 변형이라 허용, 픽셀 소스 불변. 7. **골든은 Linux 전용** (맥 ~13 skip 정상). 8. **본인 파일만 스테이징**, 커밋은 Jin 지시 시 Phase 단위. 9. **SESSION_LOG** 최상단 기록 (무엇을/왜/검증). 10. 플립 게이트(`enabled:` 배선)와 SRS 증거 경계(`PackSessionSrsLedger`)는 학습 데이터 무결성 계약 — P2 는 이 계약을 **강화**(버튼까지 확장)하되 절대 완화하지 않는다.

## §J. Jin 게이트 / 대기 항목

1. §R-1 리소 샘플 3장 before/after 승인 (전량 처리 전 필수).
2. §R-3 아이콘 4종 시안 승인 (변주 중 선택).
3. P2 실기기: 4방향 손맛·엣지 제스처 충돌·햅틱 강도.
4. P3 실기기: `_kHeroZoom` 1.15~1.3 미세조정 (발/꼬리 잘림).
5. Linux CI 골든 재생성 (P3~P5 이후 — `HANDOFF_REMAINING_TASKS.md` §1 절차) + `screen_sori_today` 신설분.
6. 커밋 지시 (권장 분할: P1 / P2 / P3 / P4 / P5 / §R 에셋).
7. 덱 카드 높이 정합: vocab_pack Learn(가득) vs 나머지 3화면(0.82) — 통일할지, 통일하면 어느 쪽인지.
8. custom 화면 ↑ 저장 의미: 비노출(권장, §P2-2) vs "빠른 모음집으로 복사".
