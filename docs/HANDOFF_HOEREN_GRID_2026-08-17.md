# 인수인계 — Hören 카드 그리드: 데이터 계층(main)과 UI/에셋 세션 접합

**작성** 2026-08-17 · **기준** `main` = `f071d44d` (PR #68 병합 직후)
**목적** 계획 1(데이터 기반)이 main에 들어간 상태에서, 별도 세션이 만드는
**카드 그리드 UI + 72장 아트**와 어떻게 하나로 붙는지 못 박는다.

**같이 읽을 정본**
- 설계: `docs/superpowers/specs/2026-08-17-hoeren-shelf-per-level-design.md`
- 계획 1: `docs/superpowers/plans/2026-08-17-hoeren-shelf-foundation.md`
- 아트 명세(다른 세션): `docs/LISTENING_CARD_ART_SPEC.md`

---

## 0. 한 줄 요약

책가도 선반 렌더는 폐기되고 **카드 그리드**(Spiele 탭과 같은 `SoriIllustratedCard`)로 간다.
분류축(레벨별 12칸)은 살아남는다. **단, 두 세션이 서로 다른 72칸 이름표를 각자 만들었고
그중 18칸은 내용까지 다르다.** §3이 이 충돌의 전부이고, 나머지는 그 위에서 기계적이다.

---

## 1. 지금 main에 들어가 있는 것 (내 작업, 완료)

PR #68로 병합됨. **UI를 어떻게 바꾸든 아래는 그대로 쓴다.**

### 1.1 데이터 계약

| 대상 | 계약 |
|---|---|
| 코퍼스 파일 | `assets/data/scenarios_{a1,a2,b1,b2,c1,c2}.json` **6개**. 단일 `scenarios.json`은 **없다** |
| 개수 | a1 67 · a2 66 · b1 55 · b2 54 · c1 11 · c2 11 = **264** |
| `Scenario.shelf` | `String`, `{level}_{slug}` (예 `a1_eat`). 264개 **전수** 보유. 빈 문자열이면 미배정 |
| `Scenario.backdrop` | `String`, 번들에 실재하는 **14종** 중 하나 (`airport bank cafe convenience directions home hotel market office pharmacy restaurant salon station taxi`) |
| 파이썬 접근 | `tools/content_factory/scenario_store.py` — `load_root()` / `load_scenarios()` / `write_shards()` / `target_shard()` |
| Dart 테스트 접근 | `test/support/scenario_json.dart` — `allScenarioJson()` / `allScenarioRoot()` / `scenarioShardRoot(level)` |
| 칸 정의 정본 | `tools/content_factory/shelf_assignment.py` — `SHELF_SLUGS`(레벨→12 slug) · `ALL_SHELVES`(72) · `ASSIGNMENT`(칸→id) · `SHELF_BY_ID` |

⛔ `assets/data/scenarios.json` 을 되살리지 말 것. `validate_content.py`가 샤드-레벨 일치까지 검사한다.

### 1.2 런타임 로더 (`lib/services/scenario_loader.dart`)

```dart
static const List<LearnerLevel> shardLevels = LearnerLevel.values;
static const int maxResidentShards = 2;

static String shardPath(LearnerLevel level);          // assets/data/scenarios_{code}.json
static Future<List<Scenario>> load();                 // 전 레벨 union (계약 불변)
static Future<List<Scenario>> loadLevel(LearnerLevel level);  // 그 레벨 샤드 하나만
static List<LearnerLevel> get residentLevels;         // 오래된 것부터, 테스트 seam
static Scenario? byId(String id);                     // 전 코퍼스 + 상주 샤드 모두 탐색
static List<Scenario> byLevel(LearnerLevel level);
static void reset();                                  // 전 코퍼스 + 샤드 + LRU 비움
```

**UI가 알아야 할 것 두 가지.**
1. 서재 화면은 `loadLevel(사용자레벨)`을 쓴다. `load()`를 쓰면 3,600개 시점에 22.3 MB가 통째로 올라온다.
2. `loadLevel`은 상주 2개 LRU다. 층 전환(A1↔A2)은 공짜지만 3번째 레벨을 열면 가장 오래된 것이 내려간다.
   전 코퍼스가 이미 상주 중이면(`load()`가 먼저 불렸으면) 추가 IO 없이 걸러서 준다.

### 1.3 배경(`backdrop`)은 UI와 독립이다

`ScenarioBackdrop.backdropKey`는 이제 JSON 필드를 그대로 돌려준다. `_categoryById` const map
264엔트리는 **삭제됐다**. `SceneAssetResolver.posterAsset(scenario)` / `loopAsset(scenario)`의
per-scenario 오버라이드 동작은 그대로다.

- `backdrop` = **어디서 벌어지나**(장면 포스터). 플레이어 배경용.
- `shelf` = **무엇을 배우나**(칸). 서재 그리드용.
- **둘은 독립이다.** 카드 이미지를 `backdrop`에서 파생시키면 안 된다 — 한 칸 안에 편의점·시장·약국이
  섞여 있는 것이 정상이다(설계 §5.1).

### 1.4 지켜야 할 게이트

| 게이트 | 명령 | 현재 |
|---|---|---|
| 콘텐츠 스키마 | `python tools/content_factory/validate_content.py` | OK. `shelf`(72칸 열거)·`backdrop`(14종) 필수 |
| 배경 무회귀 | `flutter test test/scenario_shelf_contract_test.dart` | 264/264 기준선 대조 |
| 샤드 무결성 | 같은 파일 | 개수·레벨 일치·id 유일성 |
| 로더 계약 | `flutter test test/scenario_loader_shard_test.dart` | `loadLevel`·LRU 2 |
| 에셋 고아 | `flutter test test/asset_orphan_guard_test.dart` | §4.3 참조 — **새 폴더는 여기 등록해야 한다** |

---

## 2. 다른 세션이 이미 만든 것

**워크트리** `.claude/worktrees/claude+chaekgado-listening` · **브랜치** `claude/chaekgado-listening`
**기준 커밋** `637e70f8` — 내 작업 이전이고 origin/main보다 한참 뒤다. **미커밋 19개.**

```
?? lib/data/scenario_shelf.dart            72칸 정의 + id→칸 하드코딩 맵 (588줄)
?? lib/screens/listening_library_view.dart 서재 화면
?? lib/screens/listening_player_view.dart  플레이어 뷰
?? lib/widgets/sori/chaekgado/             chaekgado_shelf_grid.dart · chaekgado_drawer.dart
?? test/listening_chaekgado_test.dart      · test/scenario_shelf_test.dart
 M lib/l10n/app_{de,en}.arb + generated     72칸 표시명
 M lib/services/storage_service.dart        진행도
 M lib/screens/listening_screen.dart · lib/main.dart
```

아트 명세(`docs/LISTENING_CARD_ART_SPEC.md`)는 이미 main에 있고, 다음이 확정돼 있다.

- 카드 = `SoriIllustratedCard`, **16:10 `BoxFit.cover`** → 소스 4:3의 상하 각 8.3%가 잘린다
- 경로 `assets/illustrations/listening/{Key}.webp` · 800×600 WebP q88 · **장당 70KB 이하**
- 배경 아이보리 `#F4E8D0` · 적 `#B94B32` · 청 `#5F9A93` (기존 38장 실측 교정값)
- 진행: `A1Transit`·`A1Repair` 파일럿 2장은 교정 전이라 폐기 → 재생성. **나머지 70장 미착수**

---

## 3. ⛔ 충돌: 72칸 이름표가 두 벌이다

여기가 이 문서의 핵심이다. **같은 축을 두 세션이 각자 만들었다.**

| | 내 것 (main에 배포됨) | 다른 세션 (미커밋) |
|---|---|---|
| 위치 | `tools/content_factory/shelf_assignment.py` + JSON `shelf` 필드 | `lib/data/scenario_shelf.dart` |
| 배정 방식 | **데이터 필드** — 시나리오 레코드가 자기 칸을 안다 | **Dart const map** `kScenarioShelfByScenarioId` (id→칸) |
| 키 형식 | `a1_eat` (소문자 스네이크) | `A1Cafe` (파스칼) |
| 264개 태깅 | 완료, validator 강제 | 해당 없음(맵에 직접 나열) |

### 3.1 기능 9칸은 1:1 대응한다 (54칸, 이름만 다름)

다른 세션이 설계 §4를 그대로 따랐기 때문에 **순서까지 일치**한다. 기계적 개명이면 끝난다.

| 레벨 | 내 slug → 그쪽 Key |
|---|---|
| A1 | transit→`A1Transit` · taxi_stay→`A1Arrival` · counter→`A1Counter` · eat→`A1Cafe` · home→`A1Home` · greet→`A1Greeting` · repeat→`A1Repair` · body→`A1Health` · partner→`A1Family` |
| A2 | move→`A2Travel` · money→`A2Bank` · buy→`A2Shopping` · eat→`A2Cafe` · body→`A2Body` · apt→`A2Neighbourhood` · work→`A2Work` · plan→`A2Plans` · partner→`A2Family` |
| B1 | repair→`B1Repairs` · refund→`B1Refund` · bill→`B1Receipts` · delay→`B1Delay` · form→`B1Paperwork` · team→`B1Team` · neighbor→`B1Neighbours` · feel→`B1Feelings` · partner→`B1Family` |
| B2 | meeting→`B2Meetings` · evidence→`B2Evidence` · negotiate→`B2Negotiation` · contract→`B2Contracts` · notice→`B2Notices` · travel→`B2Escalation` · health→`B2Medical` · public→`B2Public` · partner→`B2Family` |
| C1 | briefing→`C1Briefing` · uncertainty→`C1Uncertainty` · access→`C1Access` · labor→`C1InvisibleLabor` · conflict_interest→`C1Conflict` · policy→`C1Policy` · clinical→`C1Consent` · critique→`C1Critique` · mediation→`C1Mediation` |
| C2 | automation→`C2Automation` · record→`C2Records` · discourse→`C2Discourse` · mandate→`C2Authority` · impact→`C2Impact` · memory→`C2Memory` · ethics→`C2Ethics` · history→`C2History` · aesthetic→`C2Translation` |

**이 54칸이 live 264개의 100%를 담고 있다.** 즉 실제 콘텐츠는 전혀 다투지 않는다.

### 3.2 나머지 18칸은 내용이 다르다 — ✅ 결정됨(2026-08-17, Jin): **(나) 기능 확장 채택**

> 반영 완료: `shelf_assignment.py`의 관심축 3칸이 레벨별 `EXPANSION_SLUGS`로 교체됐고
> 스펙 §4.2에 개정 주석을 남겼다. Batch 11 36편은 폐기가 아니라 보류 — 서재 밖 별도
> 진입(추천 줄)을 만들 때 편입한다.

둘 다 재고 0이라 지금 깨지는 건 없지만, **신규 3,300개를 무엇으로 채울지가 갈린다.**

| 레벨 | 내 것 (관심축 3) | 다른 세션 (기능 확장 3) |
|---|---|---|
| A1 | friends · dating · fandom | `A1Numbers` · `A1Phone` · `A1Wayfinding` |
| A2 | friends · dating · fandom | `A2Delivery` · `A2Enrolment` · `A2Booking` |
| B1 | friends · dating · fandom | `B1Insurance` · `B1Incident` · `B1Cancellation` |
| B2 | friends · dating · fandom | `B2Hiring` · `B2Authorities` · `B2Privacy` |
| C1 | friends · dating · fandom | `C1Methodology` · `C1Facework` · `C1Attribution` |
| C2 | friends · dating · fandom | `C2Limitation` · `C2Jurisdiction` · `C2Representation` |

**걸려 있는 것:** Batch 11(36편, `.claude/worktrees/scenario-batch11-20260817`에 draft)이
`friends`/`dating`/`fandom`/`youtube`/`gaming`/`kpop` 카테고리로 이미 집필됐다. 관심축을 버리면
그 36편이 갈 칸이 없다.

**선택지 셋**

- **(가) 관심 3칸 유지** — Batch 11이 그대로 편입된다. 아트 명세의 18장을 관심축으로 다시 그려야 한다(18장 재작업, 72크레딧).
- **(나) 기능 확장 3칸 채택** — 아트 72장이 그대로 산다. Batch 11 36편은 갈 곳이 없어 별도 처리(보류·폐기·기능칸 재배정)가 필요하다.
- **(다) 12칸 → 15칸** — 둘 다 산다. 대신 레벨당 15칸이라 그리드가 길어지고(2열 × 8행) 총량이 3,600 → 4,500이 된다. 설계 §7이 "칸이 늘면 서재가 다시 커진다"고 기각한 방향이다.

내 권고는 **(나)** 다. 이유는 셋이다. ① 아트 72장·DE 표시명·파일럿 검수가 이미 그 축 위에 서 있어 되돌리는 비용이 가장 크다. ② 관심축(친구·연애·팬덤)은 *소재*이지 *언어 능력*이 아니라, "레벨이 오를수록 처리하는 절차가 무거워진다"는 축과 층위가 다르다 — 설계 §4.2도 "하나의 taxonomy로 합치면 둘 다 망가진다"고 적었고, 지금 그 봉합선이 실제로 터진 것이다. ③ Batch 11 36편은 레벨당 6편이라 손실이 작고, `daily` 6편은 이미 기능칸으로 가게 돼 있다.

다만 **관심축을 영구 폐기하자는 뜻은 아니다.** 서재와 별개 진입(예: "오늘 뭐 듣지" 추천 줄)로 살리는 편이 맞다고 본다. 이건 계획 2 범위 밖이다.

---

## 4. 붙이는 방법 — 확정 시 그대로 실행

§3이 정해지면 아래는 기계적이다.

### 4.1 `lib/data/scenario_shelf.dart`의 하드코딩 맵을 없앤다 (필수)

`kScenarioShelfByScenarioId`(id→칸 const map)는 내가 방금 지운 `_categoryById`와 **똑같은 구조**다.
설계 §5.2가 이걸 없앤 이유가 그대로 적용된다 — 시나리오를 추가할 때마다 Dart를 고쳐야 하고,
신규 3,300개에서 그 규칙은 무너진다.

```dart
// 지금 (다른 세션)
ScenarioShelf? shelfForScenario(Scenario scenario) =>
    kScenarioShelfByScenarioId[scenario.id];

// 바꿀 것 — 데이터가 자기 칸을 안다
ScenarioShelf? shelfForScenario(Scenario scenario) =>
    kScenarioShelfByKey[scenario.shelf];   // scenario.shelf = 'a1_eat'
```

`ScenarioShelf`(이모지·표시명·정렬순서)는 그대로 두고, **키만 데이터에서 읽는다.** 264개 맵은 삭제한다.
삭제 후 신규 시나리오의 `lib/` 수정은 0회가 된다.

### 4.2 키 형식을 하나로 정한다

권고: **데이터는 `a1_eat`(소문자), 표시·에셋은 `A1Cafe`(파스칼)** 를 유지하고 그 사이를 한 함수로 잇는다.
데이터 쪽을 파스칼로 바꾸면 264개 `shelf` 값과 `shelf_assignment.py`·validator·테스트를 다 고쳐야 한다.

```dart
/// 'a1_eat' → 'A1Cafe'. 에셋 경로와 ARB 키가 이 값을 쓴다.
String listeningCardKey(String shelf);   // scenario_shelf.dart 안에 표로 고정
```

파이썬 쪽 개명(§3.1의 54칸)은 `shelf_assignment.py`의 slug를 바꾸고 마이그레이션을 한 번 더 돌리면 된다 —
`tools/content_factory/migrate_shelf_backdrop.py`가 그대로 재사용된다(§5 참조).

### 4.3 에셋 배선 (다른 세션 담당, 내가 검증)

1. `pubspec.yaml`에 **`- assets/illustrations/listening/`** 한 줄 추가.
   Flutter는 디렉터리를 **비재귀**로 포함한다 — 하위 폴더를 만들면 각각 등록해야 한다.
2. `test/asset_orphan_guard_test.dart`의 `dynamicDirs`에 등록:
   ```dart
   'assets/illustrations/listening/': 'illustrations/listening/',
   ```
   근거 문자열(`illustrations/listening/`)이 `lib/`에 실제로 있어야 통과한다. 이 가드는
   **폴더 단위 면제 + 근거 생존**을 함께 강제한다(내가 2026-08-17에 파일 단위 `dynamicAssets`도 추가해 뒀다).
3. 이미지에는 `errorBuilder` 폴백을 단다. `SoriIllustratedCard(illustrationAsset:, fallback:)`가
   이미 그 계약이라 그대로 쓰면 된다 — **자산이 0장이어도 화면이 뜬다.** 아트와 코드를 직렬로 묶지 말 것.

### 4.4 화면 배선

```dart
// 서재: 사용자 레벨 하나만
final scenarios = await ScenarioLoader.loadLevel(
  learnerLevelForStoredCode(Storage.userLevelCode) ?? LearnerLevel.a1,
);
// 칸별 묶기 — 하드코딩 맵 없이
final byShelf = <String, List<Scenario>>{};
for (final s in scenarios.where((s) => s.dialog.isNotEmpty)) {
  (byShelf[s.shelf] ??= []).add(s);
}
```

카드 그리드는 Spiele 탭 구현을 그대로 베낀다:
- `lib/screens/sori_stage/sori_stage_catalog_screen.dart:163-190` — `SliverGrid` + `crossAxisCount` + `_cellAspectRatio`
- `lib/widgets/sori/illustrated_card.dart:30` — `SoriIllustratedCard(title:, illustrationAsset:, fallback:, imageOverlay:, footer:, state:, onTap:)`
- 분(分) 필 자리(`_MinutesPill`)에 **`n/재고` 카운트**를 넣으면 시각 문법이 그대로 맞는다.

### 4.5 진행도

현재 정본은 **단일 리스트** 하나뿐이다.

```dart
Storage.completedScenarios          // List<String>, 키 'kl_completed_scenarios'
```

칸별 카운트는 이걸로 파생한다(`완료 = 그 칸 시나리오 중 이 리스트에 든 것`). 설계 §6의
레벨별 키 분할(`kl_completed_scenarios_{level}`)은 **아직 안 했고 급하지 않다** — 한 레벨 600개면
약 12 KB라 단일 리스트로 견딘다. 다른 세션이 `storage_service.dart`를 이미 고치고 있으니
**분할을 새로 도입하려면 나와 겹친다.** 지금은 파생만 하고 분할은 보류할 것.

---

## 5. 내 남은 작업과 각각의 선행 조건

| # | 작업 | 막혀 있는 것 |
|---|---|---|
| 1 | `shelf` slug 54칸 개명(§3.1) + 마이그레이션 재실행 | §3 결정 |
| 2 | 18칸 확정 반영 — `shelf_assignment.py`의 `INTEREST_SLUGS` 교체 | §3 결정 |
| 3 | 72칸 DE/EN 표시명을 ARB로 (하드코딩 금지, AGENTS 규칙) | 다른 세션이 이미 ARB에 넣는 중 — **중복 주의**, 그쪽 키(`listeningShelf<Key>`)를 정본으로 |
| 4 | 계획 3 = Batch 12(`a1_eat` → `A1Cafe`) 47편 집필 | §3 결정(칸 이름이 배치 경계다) |
| 5 | Batch 11 36편 편입 또는 처리 | §3 결정 |
| 6 | `CurriculumCatalog` 전 코퍼스 의존 제거(호출부 19개) | 별건. 이게 남는 한 샤딩만으로 메모리가 1/6이 되지 않는다 |

**1·2번 실행 절차**(결정만 나면 30분 이내):

```bash
# shelf_assignment.py 의 slug 를 새 이름으로 바꾼 뒤
python tools/content_factory/migrate_shelf_backdrop.py            # 4지표 리포트
python tools/content_factory/migrate_shelf_backdrop.py --apply    # 샤드 재작성
python tools/content_factory/validate_content.py
flutter test test/scenario_shelf_contract_test.dart
```

⚠️ 마이그레이션은 `test/fixtures/backdrop_baseline.json`을 진실로 삼아 `backdrop`을 다시 주입한다.
`shelf`만 바꾸는 것이므로 배경은 건드려지지 않는다.

---

## 6. 이 세션에서 실제로 밟은 함정 (되풀이하지 말 것)

1. **origin/main이 작업 중 두 번 앞섰다**(총 4커밋, 다른 기기/세션). 그중 #63은 264개 중 **202개의
   문장을 다시 썼고**, #65는 **배경 6건을 재배정**했다(`office→bank` 3, `cafe→salon` 3).
   두 번 다 그냥 병합했으면 조용히 되돌아갔다. **병합 전 반드시 `git fetch` 후 데이터 파일의
   실제 diff를 확인할 것.** 텍스트 병합 대신 원격 본문 위에 마이그레이션을 재실행하는 것이 정답이다.
2. **content_factory 파이썬 스위트는 이 작업 이전부터 약 20건 빨갛다.** CI가 이 스위트를 돌리지
   않아서(워크플로가 부르는 건 `build_hanok_grants.py` 하나뿐) 드러나지 않았다.
   "테스트가 빨간데 내 탓인가"를 매번 판단하려면 **기준선과 실패 집합을 diff**해야 한다:
   ```bash
   git worktree add --detach /tmp/base origin/main
   # 양쪽에서 같은 명령을 돌려 실패 이름 집합을 comm 으로 비교
   ```
3. **파이썬 테스트는 저장소 루트에서 돌려야 한다.** `cd tools/content_factory && python -m unittest`는
   상대경로(`assets/data/...`)를 못 찾아 27건이 가짜로 실패한다.
   올바른 형태: `python -m unittest $(ls tools/content_factory/test_*.py | tr '\n' ' ')`
4. **동결된 draft와 live를 동등 비교하지 말 것.** 마이그레이션이 live에만 `shelf`/`backdrop`을 넣어서
   승인 당시 draft와 영원히 다르다. `integrate_scenario_batch.without_migration_fields()`가 그 처리다.
5. **`rootBundle`은 전역 캐싱 번들이다.** 에셋 읽기 횟수를 세는 테스트는 `setUp`에서
   `rootBundle.clear()`를 하지 않으면 테스트 순서에 따라 값이 달라진다(6이어야 할 자리에 2가 나왔다).

---

## 7. 결정이 필요한 것 (Jin)

| # | 질문 | 기본값(무응답 시) |
|---|---|---|
| 1 | ~~§3.2 — 나머지 18칸을 관심축으로 갈 것인가, 기능 확장으로 갈 것인가~~ **✅ 기능 확장으로 결정(2026-08-17, Jin: "굳이 다르게 할 이유는 없을 것 같은데")** | — |
| 2 | 카드의 카운트 표기 — `n/50`(목표)인가 `n/재고`인가. 지금 `a1_eat` 재고는 3개라 "0/50"은 고장처럼 보인다 | `n/재고`, 재고 50 도달 시 자동으로 같아짐 |
| 3 | 오디오 없는 칸을 "준비 중"으로 잠글 것인가 (설계 §8: 칸 승인 → 그 칸 TTS → 다음 칸) | 잠근다 |
| 4 | 긴 독일어 칸 이름(`Erster Besuch bei der Partnerfamilie`)이 카드 2줄에서 잘린다 — 짧은 카드용 이름을 따로 둘 것인가 | 카드용 짧은 이름을 ARB에 별도 키로 |

1번이 나머지 전부의 선행 조건이다.
