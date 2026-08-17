# Hören 책가도 계획 1 — 기반(스키마·validator·마이그레이션·6샤드·로더) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 264개 live 시나리오에 `shelf`/`backdrop` 두 필드를 소급 부여하고, `assets/data/scenarios.json` 단일 파일을 레벨별 6샤드로 쪼개며, 런타임 로더가 레벨 단위로 읽을 수 있게 만든다 — 문장·ID·레벨은 한 글자도 바꾸지 않는다.

**Architecture:** 배정표(부록 A)를 파이썬 상수로 고정하고 4지표(DUPES/ORPHANS/GHOSTS/WRONG LEVEL)를 fail-closed 게이트로 만든다. 그 다음 `backdrop`을 `lib/models/scenario.dart`의 `_categoryById` const map에서 JSON으로 **이관**한다(삭제가 아니라 이동이므로 배경 회귀 0). 샤딩은 "샤드 생성 → 읽는 쪽 전환 → 원본 삭제" 3커밋으로 나눠 어느 커밋에서도 저장소가 초록색이 되게 한다. 파이썬은 `scenario_store.py`, Dart 테스트는 `test/support/scenario_json.dart` 단일 지점을 거치게 해서 38개 파일이 각자 6샤드를 합치는 사태를 막는다.

**Tech Stack:** Flutter 3.x / Dart 3.x (null-safety), Python 3.12 표준 라이브러리만(의존성 0), `unittest`, `flutter test`

**Spec:** `docs/superpowers/specs/2026-08-17-hoeren-shelf-per-level-design.md` (승인 2026-08-17, 커밋 `f6a7714d`). 이 계획은 스펙 §5(데이터 계약)·§10 1–3번·§11(검증)만 구현한다. UI(§7)는 계획 2, 콘텐츠 집필(§10 4번)은 계획 3이다.

**브랜치:** `claude/hoeren-shelf-20260817` (워크트리 `.claude/worktrees/claude+hoeren-shelf-20260817`). 기준 `974edac6`.

---

## Global Constraints

- ⛔ **문장·ID·레벨은 바꾸지 않는다.** 이 계획의 데이터 변경은 `shelf`/`backdrop` 필드 추가와 파일 분할뿐이다 (스펙 §5.4).
- ⛔ **커밋은 각 태스크 마지막 스텝에서만.** 푸시는 Jin이 명시적으로 요청할 때만 한다 (AGENTS.md).
- ⛔ **변경하면 `docs/SESSION_LOG.md` 최상단에 기록**한다 — 무엇을·왜·검증·커밋해시. Task 8이 이 항목을 담당한다.
- Dart `if/else`는 **한 줄이라도 반드시 중괄호**를 쓴다 (AGENTS.md, 실제 오류 이력 있음).
- 사용자에게 보이는 문자열은 만들지 않는다. 이 계획은 데이터/로더 계층이므로 ARB 변경이 없어야 한다.
- 레벨 코드는 소문자 `a1 a2 b1 b2 c1 c2` 6종이 정본이다 (`lib/models/learner_level.dart`의 `LearnerLevel.code`).
- `backdrop` 열거값은 실재하는 12종뿐이다: `airport cafe convenience directions home hotel market office pharmacy restaurant station taxi`.
- JSON 쓰기 형식은 저장소 관례를 따른다: `json.dumps(payload, ensure_ascii=False, indent=2) + "\n"` (`apply_review.py:255`, `integrate_scenario_batch.py:67`와 동일).
- `content_factory` 파이썬 테스트와 `validate_content.py`는 **CI에 없다**(워크플로에서 호출되는 content_factory 스크립트는 `build_hanok_grants.py` 하나뿐). 각 태스크에서 로컬로 직접 실행해 확인한다.

## 기준 실측 (2026-08-17, 커밋 `974edac6`에서 재현됨)

이 값들은 계획을 쓰기 전에 실제로 돌려서 확인한 것이다. 태스크의 기대값이 여기서 나온다.

| 항목 | 값 |
| --- | --- |
| `assets/data/scenarios.json` 루트 키 | `version`(=1) · `_comment` · `scenarios` |
| live 시나리오 | 264 |
| 레벨 분포 | a1 67 · a2 66 · b1 55 · b2 54 · c1 11 · c2 11 |
| 부록 A 배정 | 46칸 264개 · DUPES 0 · ORPHANS 0 · GHOSTS 0 · WRONG LEVEL 0 |
| `_categoryById` (`lib/models/scenario.dart:389`~) | 264 엔트리 · 고아 0 · 유령 0 |
| backdrop 분포 | office 84 · home 67 · cafe 23 · station 22 · market 20 · convenience 11 · restaurant 8 · taxi 7 · hotel 6 · directions 6 · pharmacy 5 · airport 5 |
| 현재 `shelf` 필드 보유 | 0개 |
| 현재 `backdrop` 필드 보유 | 0개 |
| `scenarios.json`을 직접 읽는 파일 | **38개** (lib 3 · Dart 테스트 11 · 파이썬 도구 12 · 파이썬 테스트 10 · l10n 일회성 2) |

## 스펙과 달라진 점 (실측으로 드러난 것 — Jin 확인 필요)

1. **샤딩 폭발 반경이 스펙에 없다.** 스펙 §5.3은 pubspec 수정이 필요 없다는 것만 실측했는데, `assets/data/scenarios.json` 경로를 직접 쓰는 파일이 38개다. 그래서 이 계획은 파이썬/Dart 각각에 접근 단일 지점을 먼저 만들고 전환한다(Task 3·6). 일회성 과거 스크립트 8개(`add_scenarios_batch2~5.py`, `add_interest_scenarios.py`, `fix_quest_audio_text.py`, `tools/l10n_sync_2026_08_12/*.py`)는 전환하지 않고 파일 없음으로 **시끄럽게 죽게** 둔다 — 이미 실행이 끝난 기록물이고, 조용히 stale 데이터를 읽는 것보다 낫다.
2. **샤딩만으로는 메모리가 1/6이 되지 않는다.** `CurriculumCatalog.load()`(`lib/services/curriculum_catalog.dart:69`)가 `ScenarioLoader.load()`로 **전 코퍼스**를 당기고, 이 catalog는 19개 지점에서 호출된다(`today_learning_snapshot`·`course_progress_service`·`learning_path_screen` 등). 즉 3,600개 시점에도 코스 화면에 들어가는 순간 22.3 MB가 그대로 메모리에 올라온다. 이 계획은 **파일 분할과 레벨 단위 로드 경로**까지 만들고, catalog가 시나리오 전문(全文) 대신 경량 인덱스만 쓰게 하는 리팩터는 범위 밖으로 둔다(19개 호출부를 건드려야 하므로 별건). 스펙 §5.3의 "로드량 1/6"은 Hören 경로에 한정된 주장으로 정정되어야 한다.
3. **`/listening` 화면은 이 계획에서 바꾸지 않는다.** `listening_screen.dart:132`가 `ScenarioLoader.load()`로 전 레벨을 받아 `selectInitialListeningScenario`에 넘기는데, 여기서 레벨 샤드 하나만 주면 지금의 선택 동작이 조용히 바뀐다. 로더 API(`loadLevel`)는 이 계획이 제공하고, 실제 전환은 서재 UI가 들어오는 **계획 2**에서 한다.

---

## File Structure

**새로 만드는 파일**

| 파일 | 책임 |
| --- | --- |
| `tools/content_factory/shelf_assignment.py` | 72칸 slug 표 + 부록 A 배정(46칸 264개) + 4지표 검사 함수. 데이터와 검사만, I/O 없음 |
| `tools/content_factory/test_shelf_assignment.py` | 배정표를 live 코퍼스에 대고 4지표 0 검증 |
| `tools/content_factory/scenario_store.py` | 시나리오 코퍼스 읽기/쓰기 단일 지점. 샤드 유무를 흡수 |
| `tools/content_factory/test_scenario_store.py` | 병합 순서·샤드 라우팅·왕복(round-trip) 검증 |
| `tools/content_factory/migrate_shelf_backdrop.py` | 일회성 마이그레이션. fail-closed 4지표 + backdrop 전수 커버 |
| `tools/content_factory/test_migrate_shelf_backdrop.py` | 마이그레이션 계획을 live 코퍼스에 대고 검증 |
| `test/fixtures/backdrop_baseline.json` | 마이그레이션 **이전** 264개 id→backdrop 스냅샷 (무회귀 기준선) |
| `test/support/scenario_json.dart` | Dart 테스트의 샤드 읽기 단일 지점 |
| `test/scenario_shelf_contract_test.dart` | 샤드 무결성·shelf/backdrop 계약·backdrop 무회귀 |
| `test/scenario_loader_shard_test.dart` | `load()`/`loadLevel()`/LRU 계약 |

**수정하는 파일**

| 파일 | 변경 |
| --- | --- |
| `lib/models/scenario.dart` | `shelf`/`backdrop` 필드 추가, `fromJson` 파싱, `_categoryById` 264엔트리 **삭제**, `backdropKey`를 JSON 기반으로 |
| `lib/services/scenario_loader.dart` | 6샤드 로드 + `loadLevel()` + LRU 2 |
| `tools/content_factory/validate_content.py` | 코퍼스 읽기를 store 경유로, `shelf`/`backdrop` 스키마 규칙 추가, 샤드-레벨 일치 검사 |
| `tools/content_factory/{apply_review,integrate_scenario_batch,validate_promoted_batch,validate_reference_intake,audit_game_loader_coverage,build_can_do_segments,build_level_content_4x}.py` | 대상 파일명 dispatch를 샤드 6종으로 확장 |
| 파이썬 테스트 8개 · Dart 테스트 11개 | 단일 파일 경로 → store / `scenario_json.dart` |
| `AGENTS.md` · `docs/SESSION_LOG.md` · `tools/content_factory/README.md` | 데이터 파일 맵 갱신 + 세션 기록 |

---

## Task 1: 칸 배정표를 코드로 고정하고 4지표를 게이트로 만든다

**Files:**
- Create: `tools/content_factory/shelf_assignment.py`
- Test: `tools/content_factory/test_shelf_assignment.py`

**Interfaces:**
- Consumes: `assets/data/scenarios.json` (읽기만)
- Produces:
  - `LEVELS: tuple[str, ...]` — `("a1","a2","b1","b2","c1","c2")`
  - `FUNCTIONAL_SLUGS: dict[str, tuple[str, ...]]` — 레벨 → 기능 9칸 slug
  - `INTEREST_SLUGS: tuple[str, ...]` — `("friends","dating","fandom")` (모든 레벨 공통)
  - `SHELF_SLUGS: dict[str, tuple[str, ...]]` — 레벨 → 12칸 slug (기능 9 + 관심 3)
  - `ALL_SHELVES: frozenset[str]` — 72개 `{level}_{slug}`
  - `ASSIGNMENT: dict[str, tuple[str, ...]]` — `{level}_{slug}` → 시나리오 id 튜플 (부록 A, 46칸 264개)
  - `SHELF_BY_ID: dict[str, str]` — 시나리오 id → `{level}_{slug}`
  - `check_assignment(live_levels: dict[str, str]) -> dict[str, list[str]]` — 키 `dupes`/`orphans`/`ghosts`/`wrong_level`, 모두 정렬된 리스트

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`tools/content_factory/test_shelf_assignment.py`:

```python
#!/usr/bin/env python3
"""Task 1 — 부록 A 배정표의 fail-closed 4지표.

Run with:
    python3 -m unittest tools/content_factory/test_shelf_assignment.py
"""

from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from shelf_assignment import (
    ALL_SHELVES,
    ASSIGNMENT,
    LEVELS,
    SHELF_BY_ID,
    SHELF_SLUGS,
    check_assignment,
)

ROOT = SCRIPT_DIR.parents[1]
DATA = ROOT / "assets" / "data"


def _live_levels() -> dict[str, str]:
    with (DATA / "scenarios.json").open(encoding="utf-8") as handle:
        root = json.load(handle)
    return {
        str(item["id"]): str(item["level"]).strip().lower()
        for item in root["scenarios"]
    }


class ShelfAssignmentTest(unittest.TestCase):
    def test_every_level_has_twelve_shelves(self) -> None:
        for level in LEVELS:
            self.assertEqual(len(SHELF_SLUGS[level]), 12, level)
            self.assertEqual(len(set(SHELF_SLUGS[level])), 12, level)
        self.assertEqual(len(ALL_SHELVES), 72)

    def test_assignment_covers_the_live_corpus_exactly(self) -> None:
        live = _live_levels()
        self.assertEqual(len(live), 264)
        report = check_assignment(live)
        self.assertEqual(report["dupes"], [])
        self.assertEqual(report["orphans"], [])
        self.assertEqual(report["ghosts"], [])
        self.assertEqual(report["wrong_level"], [])

    def test_assigned_shelves_are_declared_shelves(self) -> None:
        self.assertTrue(set(ASSIGNMENT).issubset(ALL_SHELVES))
        self.assertEqual(len(SHELF_BY_ID), 264)

    def test_interest_shelves_are_declared_but_unseeded(self) -> None:
        # 관심 3칸은 Batch 11 이 들어오기 전까지 재고가 없다. 칸 자체는 존재해야
        # 계획 3 이 그 칸으로 draft 를 넣을 수 있다.
        for level in LEVELS:
            for slug in ("friends", "dating", "fandom"):
                shelf = f"{level}_{slug}"
                self.assertIn(shelf, ALL_SHELVES)
                self.assertEqual(ASSIGNMENT.get(shelf, ()), ())


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 실패를 확인한다**

Run: `python3 -m unittest tools/content_factory/test_shelf_assignment.py`
Expected: FAIL — `ModuleNotFoundError: No module named 'shelf_assignment'`

- [ ] **Step 3: 배정표를 만든다**

`tools/content_factory/shelf_assignment.py`. slug 표는 스펙 §4.1/§4.2, `ASSIGNMENT`은 스펙 **부록 A를 그대로 옮긴다**(46칸 264 id). 부록 A에 없는 26칸(재고 0)은 키를 만들지 않는다 — `ALL_SHELVES`가 72칸을 따로 선언하므로 칸의 존재와 재고는 분리된다.

```python
#!/usr/bin/env python3
"""레벨별 12칸 서재(책가도)의 칸 정의와 live 264개 배정.

정본은 docs/superpowers/specs/2026-08-17-hoeren-shelf-per-level-design.md 의
§4(축 설계)와 부록 A(전수 배정)다.  이 모듈은 그 표를 실행 가능한 형태로
옮긴 것이며, I/O 를 하지 않는다 — 읽기는 scenario_store, 주입은
migrate_shelf_backdrop 이 한다.
"""

from __future__ import annotations

LEVELS: tuple[str, ...] = ("a1", "a2", "b1", "b2", "c1", "c2")

# 기능 9칸 — 레벨마다 축이 다르다 (스펙 §4.1).
FUNCTIONAL_SLUGS: dict[str, tuple[str, ...]] = {
    "a1": ("transit", "taxi_stay", "counter", "eat", "home", "greet", "repeat", "body", "partner"),
    "a2": ("move", "money", "buy", "eat", "body", "apt", "work", "plan", "partner"),
    "b1": ("repair", "refund", "bill", "delay", "form", "team", "neighbor", "feel", "partner"),
    "b2": ("meeting", "evidence", "negotiate", "contract", "notice", "travel", "health", "public", "partner"),
    "c1": ("briefing", "uncertainty", "access", "labor", "conflict_interest", "policy", "clinical", "critique", "mediation"),
    "c2": ("automation", "record", "discourse", "mandate", "impact", "memory", "ethics", "history", "aesthetic"),
}

# 관심 3칸 — 모든 레벨 공통 slug (스펙 §4.2).
INTEREST_SLUGS: tuple[str, ...] = ("friends", "dating", "fandom")

SHELF_SLUGS: dict[str, tuple[str, ...]] = {
    level: FUNCTIONAL_SLUGS[level] + INTEREST_SLUGS for level in LEVELS
}

ALL_SHELVES: frozenset[str] = frozenset(
    f"{level}_{slug}" for level in LEVELS for slug in SHELF_SLUGS[level]
)

# 부록 A — live 264 전수 배정.  재고 0 인 26칸은 키가 없다.
ASSIGNMENT: dict[str, tuple[str, ...]] = {
    "a1_transit": (
        "a1_bus_late", "a1_last_train", "a1_platform_line", "a1_station_rest",
        "a1_subway_exit", "a1_thanks_seat", "a1_card_topup", "a1_locker_key",
        "a1_meet_station",
    ),
    "a1_taxi_stay": (
        "a1_airport_cart", "a1_taxi_address", "a1_direction_left", "a1_hotel_key",
        "airport_arrival", "hotel_checkin", "taxi_kakao",
    ),
    # … 부록 A 의 나머지 44칸을 같은 형식으로 옮긴다.  한 칸도 빼지 않는다 —
    # Step 1 의 test_assignment_covers_the_live_corpus_exactly 가 264 전수를 센다.
}

SHELF_BY_ID: dict[str, str] = {
    scenario_id: shelf
    for shelf, ids in ASSIGNMENT.items()
    for scenario_id in ids
}


def check_assignment(live_levels: dict[str, str]) -> dict[str, list[str]]:
    """부록 A 배정을 live 코퍼스에 맞춰 검사한다.

    반환하는 네 리스트가 **전부 비어야** 마이그레이션이 진행될 수 있다
    (스펙 §4.3).  ``live_levels`` 는 시나리오 id → 소문자 레벨 코드다.
    """

    seen: dict[str, int] = {}
    for ids in ASSIGNMENT.values():
        for scenario_id in ids:
            seen[scenario_id] = seen.get(scenario_id, 0) + 1

    assigned = set(seen)
    live = set(live_levels)
    wrong_level = [
        scenario_id
        for shelf, ids in ASSIGNMENT.items()
        for scenario_id in ids
        if scenario_id in live_levels
        and live_levels[scenario_id] != shelf.split("_", 1)[0]
    ]
    return {
        "dupes": sorted(key for key, count in seen.items() if count > 1),
        "orphans": sorted(live - assigned),
        "ghosts": sorted(assigned - live),
        "wrong_level": sorted(wrong_level),
    }
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

Run: `python3 -m unittest tools/content_factory/test_shelf_assignment.py -v`
Expected: 4 tests PASS. 실패하면 부록 A 전사에서 빠뜨린 칸이 있다는 뜻이다 — `orphans` 목록이 그대로 빠진 id를 알려준다.

- [ ] **Step 5: 커밋**

```bash
git add tools/content_factory/shelf_assignment.py tools/content_factory/test_shelf_assignment.py
git commit -m "feat(shelf): 부록 A 72칸 배정표를 코드로 고정 + 4지표 게이트"
```

---

## Task 2: backdrop 무회귀 기준선을 박제한다

`_categoryById`는 Task 6에서 삭제된다. 삭제 뒤에는 "마이그레이션 전 값"을 되찾을 방법이 없으므로, **지우기 전에** 264개 스냅샷을 파일로 남기고 그 파일을 영구 계약으로 만든다 (스펙 §11 "backdrop 무회귀").

**Files:**
- Create: `test/fixtures/backdrop_baseline.json`
- Create: `test/scenario_shelf_contract_test.dart`

**Interfaces:**
- Consumes: `lib/models/scenario.dart`의 `ScenarioBackdrop._categoryById` (이번 한 번만)
- Produces: `test/fixtures/backdrop_baseline.json` — `{"generated_from": "<commit sha>", "entries": {"<scenario_id>": "<backdrop key>", …}}` 264 엔트리. 이후 모든 태스크가 이 파일을 진실로 삼는다.

- [ ] **Step 1: 기준선을 뽑는다**

일회성 추출이다. `test/scene_asset_resolver_test.dart:153-170`이 쓰는 것과 같은 정규식 방식을 쓴다(맵이 private이라 소스를 읽는다). 아래를 그대로 실행한다:

```bash
python3 - <<'PY'
import json, re, subprocess
from pathlib import Path

src = Path("lib/models/scenario.dart").read_text(encoding="utf-8").replace("\r\n", "\n")
start = src.index("static const _categoryById")
end = src.index("\n  };\n", start)
entries = dict(re.findall(r"'([a-z0-9_]+)': '([a-z]+)'", src[start:end]))
assert len(entries) == 264, len(entries)

live = {s["id"] for s in json.loads(Path("assets/data/scenarios.json").read_text(encoding="utf-8"))["scenarios"]}
assert set(entries) == live, "categoryById 와 live id 집합이 다르다"

commit = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True, check=True).stdout.strip()
payload = {"generated_from": commit, "entries": dict(sorted(entries.items()))}
Path("test/fixtures/backdrop_baseline.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print("wrote", len(entries), "entries from", commit)
PY
```

Expected: `wrote 264 entries from <sha>`

- [ ] **Step 2: 기준선을 강제하는 테스트를 쓴다**

`test/scenario_shelf_contract_test.dart` (이 파일은 Task 4·6에서 그룹이 더 붙는다):

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';

/// 마이그레이션 전/후 264개의 backdrop 이 완전히 동일함을 고정한다 (스펙 §11).
/// `_categoryById` 는 Task 6 에서 사라지므로, 이 기준선 파일이 그 값의 유일한
/// 사후 증인이다.
void main() {
  group('backdrop 무회귀 기준선', () {
    late Map<String, String> baseline;

    setUpAll(() {
      final raw =
          jsonDecode(
                File('test/fixtures/backdrop_baseline.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      baseline = (raw['entries'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      );
    });

    test('기준선은 264개다', () {
      expect(baseline.length, 264);
    });

    test('모든 시나리오의 backdropKey 가 기준선과 같다', () {
      final scenarios =
          (jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
                  as Map<String, dynamic>)['scenarios']
              as List;
      expect(scenarios.length, baseline.length);
      for (final raw in scenarios) {
        final scenario = Scenario.fromJson(raw as Map<String, dynamic>);
        expect(
          scenario.backdropKey,
          baseline[scenario.id],
          reason: '${scenario.id} 의 배경이 바뀌었습니다',
        );
      }
    });
  });
}
```

- [ ] **Step 3: 통과를 확인한다**

Run: `flutter test test/scenario_shelf_contract_test.dart`
Expected: 2 tests PASS (지금은 `backdropKey`가 아직 `_categoryById`에서 나오므로 자명하게 통과한다 — 이 테스트의 값은 **앞으로** 나온다)

- [ ] **Step 4: 커밋**

```bash
git add test/fixtures/backdrop_baseline.json test/scenario_shelf_contract_test.dart
git commit -m "test(scenario): 마이그레이션 전 backdrop 264개 기준선 박제"
```

---

## Task 3: 파이썬 코퍼스 접근을 단일 지점으로 모은다

아직 샤딩은 하지 않는다. **읽는 쪽을 먼저 갈아끼워서** 샤딩 커밋이 한 파일만 건드리게 만드는 준비 태스크다.

**Files:**
- Create: `tools/content_factory/scenario_store.py`
- Create: `tools/content_factory/test_scenario_store.py`
- Modify: `tools/content_factory/validate_content.py` (3개 호출부: `:299`, `:1001`, `:1417`)
- Modify: `tools/content_factory/audit_game_loader_coverage.py:100`
- Modify: `tools/content_factory/build_can_do_segments.py:1823`
- Modify: `tools/content_factory/build_level_content_4x.py:159,1002`
- Modify: `tools/content_factory/test_build_can_do_segments.py:101`
- Modify: `tools/content_factory/test_level_content_4x.py:35`

**Interfaces:**
- Consumes: `shelf_assignment.LEVELS` (Task 1)
- Produces:
  - `DATA: Path` — `<repo>/assets/data`
  - `LEGACY_NAME: str` — `"scenarios.json"`
  - `shard_name(level: str) -> str` — `"scenarios_a1.json"` 형식, 미지의 레벨은 `ValueError`
  - `shard_paths(data: Path = DATA) -> list[Path]`
  - `has_shards(data: Path = DATA) -> bool`
  - `load_shard(level: str, data: Path = DATA) -> dict[str, Any]`
  - `load_root(data: Path = DATA) -> dict[str, Any]` — 병합된 `{"version", "scenarios"}`. 샤드가 있으면 샤드, 없으면 레거시 단일 파일
  - `load_scenarios(data: Path = DATA) -> list[dict[str, Any]]`
  - `target_shard(scenario: dict[str, Any]) -> str`
  - `write_shards(scenarios, data: Path = DATA, version: int = 1) -> dict[str, int]` — 레벨 → 개수

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`tools/content_factory/test_scenario_store.py`:

```python
#!/usr/bin/env python3
"""Task 3 — 코퍼스 접근 단일 지점.

Run with:
    python3 -m unittest tools/content_factory/test_scenario_store.py
"""

from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_store


def _scenario(scenario_id: str, level: str) -> dict:
    return {"id": scenario_id, "level": level}


class ScenarioStoreTest(unittest.TestCase):
    def test_shard_name_rejects_unknown_level(self) -> None:
        self.assertEqual(scenario_store.shard_name("A1"), "scenarios_a1.json")
        with self.assertRaises(ValueError):
            scenario_store.shard_name("d1")

    def test_reads_legacy_single_file_when_no_shards(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            data = Path(tmp)
            (data / "scenarios.json").write_text(
                json.dumps({"version": 1, "scenarios": [_scenario("x", "b1")]}),
                encoding="utf-8",
            )
            self.assertFalse(scenario_store.has_shards(data))
            self.assertEqual(
                [item["id"] for item in scenario_store.load_scenarios(data)], ["x"]
            )

    def test_write_then_read_round_trips_in_level_order(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            data = Path(tmp)
            counts = scenario_store.write_shards(
                [_scenario("c", "c2"), _scenario("a", "a1"), _scenario("b", "a1")],
                data,
            )
            self.assertEqual(counts["a1"], 2)
            self.assertEqual(counts["c2"], 1)
            self.assertEqual(counts["b1"], 0)
            self.assertTrue(scenario_store.has_shards(data))
            self.assertEqual(
                [item["id"] for item in scenario_store.load_scenarios(data)],
                ["a", "b", "c"],
            )

    def test_shards_win_over_a_stale_legacy_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            data = Path(tmp)
            scenario_store.write_shards([_scenario("fresh", "a2")], data)
            (data / "scenarios.json").write_text(
                json.dumps({"version": 1, "scenarios": [_scenario("stale", "a2")]}),
                encoding="utf-8",
            )
            self.assertEqual(
                [item["id"] for item in scenario_store.load_scenarios(data)], ["fresh"]
            )

    def test_write_rejects_an_unknown_level(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                scenario_store.write_shards([_scenario("x", "")], Path(tmp))

    def test_target_shard_follows_the_level(self) -> None:
        self.assertEqual(
            scenario_store.target_shard(_scenario("x", "B2")), "scenarios_b2.json"
        )

    def test_live_corpus_is_readable_and_complete(self) -> None:
        self.assertEqual(len(scenario_store.load_scenarios()), 264)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 실패를 확인한다**

Run: `python3 -m unittest tools/content_factory/test_scenario_store.py`
Expected: FAIL — `ModuleNotFoundError: No module named 'scenario_store'`

- [ ] **Step 3: store 를 만든다**

`tools/content_factory/scenario_store.py`:

```python
#!/usr/bin/env python3
"""레벨 샤딩된 시나리오 코퍼스의 유일한 읽기/쓰기 지점.

`assets/data/scenarios.json` 을 직접 열던 도구가 38 개였다.  샤딩 이후에도
각자 6 개 파일을 합치게 두면 병합 순서와 쓰기 대상이 파일마다 갈린다.
모든 도구는 이 모듈만 부른다.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Iterable

from shelf_assignment import LEVELS

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"
LEGACY_NAME = "scenarios.json"
SCHEMA_VERSION = 1
SHARD_COMMENT = (
    "Szenarien für Phase 5, nach CEFR-Level geshardet. "
    "Schema: lib/models/scenario.dart. Pflege-Pattern: ko ist Lerninhalt; "
    "de/en sind Mutterspracheübersetzungen. "
    "Schreiben nur über tools/content_factory/scenario_store.py."
)


def shard_name(level: str) -> str:
    normalized = str(level).strip().lower()
    if normalized not in LEVELS:
        raise ValueError(f"unknown scenario level {level!r}")
    return f"scenarios_{normalized}.json"


def shard_paths(data: Path = DATA) -> list[Path]:
    return [data / shard_name(level) for level in LEVELS]


def has_shards(data: Path = DATA) -> bool:
    return all(path.exists() for path in shard_paths(data))


def load_shard(level: str, data: Path = DATA) -> dict[str, Any]:
    with (data / shard_name(level)).open(encoding="utf-8") as handle:
        return json.load(handle)


def load_root(data: Path = DATA) -> dict[str, Any]:
    """병합된 코퍼스 뷰.  샤드가 전부 있으면 샤드가, 아니면 레거시가 진실이다."""

    if not has_shards(data):
        with (data / LEGACY_NAME).open(encoding="utf-8") as handle:
            return json.load(handle)
    scenarios: list[dict[str, Any]] = []
    version = SCHEMA_VERSION
    for level in LEVELS:
        root = load_shard(level, data)
        version = root.get("version", version)
        scenarios.extend(root.get("scenarios", []))
    return {"version": version, "scenarios": scenarios}


def load_scenarios(data: Path = DATA) -> list[dict[str, Any]]:
    return list(load_root(data).get("scenarios", []))


def target_shard(scenario: dict[str, Any]) -> str:
    """이 시나리오가 들어갈 샤드 파일명.  레벨이 곧 대상이라 모호함이 없다."""

    return shard_name(scenario.get("level", ""))


def write_shards(
    scenarios: Iterable[dict[str, Any]],
    data: Path = DATA,
    version: int = SCHEMA_VERSION,
) -> dict[str, int]:
    """전 코퍼스를 6 개 샤드로 덮어쓴다.  빈 레벨도 파일을 만든다."""

    buckets: dict[str, list[dict[str, Any]]] = {level: [] for level in LEVELS}
    for scenario in scenarios:
        level = str(scenario.get("level", "")).strip().lower()
        if level not in buckets:
            raise ValueError(
                f"scenario {scenario.get('id')!r} has unknown level {level!r}"
            )
        buckets[level].append(scenario)
    counts: dict[str, int] = {}
    for level in LEVELS:
        payload = {
            "version": version,
            "_comment": SHARD_COMMENT,
            "scenarios": buckets[level],
        }
        (data / shard_name(level)).write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        counts[level] = len(buckets[level])
    return counts
```

- [ ] **Step 4: store 테스트 통과를 확인한다**

Run: `python3 -m unittest tools/content_factory/test_scenario_store.py -v`
Expected: 7 tests PASS

- [ ] **Step 5: `validate_content.py`의 3개 호출부를 store 로 돌린다**

파일 상단 import 에 추가:

```python
import scenario_store
```

`ContentValidator`에 메서드를 추가한다(테스트가 이 지점을 갈아끼울 수 있어야 하므로 `load_json`처럼 인스턴스 메서드로 둔다). `load_json` 정의(`:149`) 바로 아래에 넣는다:

```python
    def load_scenario_root(self) -> Any:
        """샤딩된 코퍼스의 병합 뷰.  실패는 issue 로 낮춰 게이트를 죽이지 않는다."""

        try:
            return scenario_store.load_root(self.data)
        except (OSError, json.JSONDecodeError, ValueError) as error:
            self.issue("scenarios", f"cannot load scenario corpus: {error}")
            return None
```

세 호출부를 바꾼다:

- `validate_scenarios` 첫 두 줄 (`:298-299`)
  ```python
        name = "scenarios.json"
        root = self.load_json(name)
  ```
  →
  ```python
        name = "scenarios"
        root = self.load_scenario_root()
  ```
- `validate_curriculum_graph` (`:1001`)
  ```python
        scenarios_root = self.load_json("scenarios.json")
  ```
  →
  ```python
        scenarios_root = self.load_scenario_root()
  ```
  같은 함수 안 `self._validate_scenario_graph_metadata("scenarios.json", …)`(`:1007-1009`)의 첫 인자도 `"scenarios"`로 바꾼다.
- `inventory_counts` (`:1417`)
  ```python
            root = self.load_json("scenarios.json")
  ```
  →
  ```python
            root = self.load_scenario_root()
  ```

`MANIFEST_SOURCE_FILES`(`:119-120`)의 `"scenario"`/`"scenarioQuest"` 값은 `"scenarios.json"` → `"scenarios"`로 바꾼다. 이 값은 사람이 읽는 출처 라벨이므로 샤드 6개를 나열하지 않는다.

- [ ] **Step 6: 나머지 라이브 도구 3개를 store 로 돌린다**

세 파일 모두 상단에 `import scenario_store` 를 추가한 뒤:

- `audit_game_loader_coverage.py:100`
  ```python
            "scenario": list(_read_json(self._asset("scenarios.json"))["scenarios"]),
  ```
  →
  ```python
            "scenario": list(scenario_store.load_scenarios(self._asset("").parent)),
  ```
  `self._asset(name)`이 실제로 무엇을 반환하는지 `:90-105`를 먼저 읽고, assets/data 디렉터리를 직접 가리키는 필드가 있으면 그것을 `load_scenarios()`에 넘긴다. 그런 필드가 없으면 `scenario_store.load_scenarios()`(기본 `DATA`)를 쓴다.
- `build_can_do_segments.py:1823`
  ```python
        scenario_root = _read_json(DATA / "scenarios.json")
  ```
  →
  ```python
        scenario_root = scenario_store.load_root(DATA)
  ```
- `build_level_content_4x.py:159`
  ```python
    scenarios = json.loads((DATA / "scenarios.json").read_text(encoding="utf-8"))
  ```
  →
  ```python
    scenarios = scenario_store.load_root(DATA)
  ```
  `:1002`의 `live_path = DATA / "scenarios.json"` 은 **먼저 `:995-1015`를 읽고** 읽기인지 쓰기인지 확인한다. 읽기면 `scenario_store.load_root(DATA)`로, 쓰기면 `scenario_store.write_shards(root["scenarios"], DATA)`로 바꾼다.

- [ ] **Step 7: 파이썬 테스트 2개의 경로를 돌린다**

- `test_build_can_do_segments.py:101`
  ```python
        scenario_ids = {row["id"] for row in _json("scenarios.json")["scenarios"]}
  ```
  →
  ```python
        scenario_ids = {row["id"] for row in scenario_store.load_scenarios()}
  ```
- `test_level_content_4x.py:35` — `LIVE_SCENARIOS = SCRIPT_DIR.parents[1] / "assets" / "data" / "scenarios.json"` 상수를 지우고, 그 상수를 쓰던 곳을 `scenario_store.load_root()`로 바꾼다.

두 파일 모두 상단 `sys.path` 삽입 뒤에 `import scenario_store` 를 추가한다.

- [ ] **Step 8: 파이썬 게이트 전체를 돌린다**

```bash
python3 tools/content_factory/validate_content.py
cd tools/content_factory && python3 -m unittest discover -p "test_*.py"; cd ../..
```
Expected: `OK: Content validation passed.` + 전 테스트 PASS. 아직 데이터는 단일 파일이므로 동작이 하나도 바뀌지 않아야 한다.

- [ ] **Step 9: 커밋**

```bash
git add tools/content_factory/
git commit -m "refactor(content): 시나리오 코퍼스 읽기를 scenario_store 한 곳으로 모음"
```

---

## Task 4: Dart 모델에 `shelf`/`backdrop` 필드를 연다

데이터에는 아직 두 필드가 없다. 모델이 **없어도 견디는** 상태로 먼저 들어가야 마이그레이션 커밋이 안전하다.

**Files:**
- Modify: `lib/models/scenario.dart` (필드 선언 `:274`~, 생성자 `:296`~, `fromJson` `:319`~)
- Modify: `test/scenario_shelf_contract_test.dart` (그룹 추가)

**Interfaces:**
- Consumes: Task 2의 `test/scenario_shelf_contract_test.dart`
- Produces:
  - `Scenario.shelf: String` — `{level}_{slug}`, 없으면 `''`
  - `Scenario.backdrop: String` — 12 열거값 중 하나, 없으면 `''`
  - `ScenarioBackdrop.backdropKey`는 이 태스크에서 **아직 바꾸지 않는다** (Task 6)

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/scenario_shelf_contract_test.dart`의 `main()` 안, 기존 그룹 아래에 추가한다:

```dart
  group('Scenario 모델의 shelf/backdrop 파싱', () {
    Map<String, dynamic> minimal(Map<String, dynamic> extra) => {
      'id': 'x_probe',
      'level': 'a1',
      ...extra,
    };

    test('필드가 없으면 빈 문자열이다', () {
      final scenario = Scenario.fromJson(minimal(const {}));
      expect(scenario.shelf, '');
      expect(scenario.backdrop, '');
    });

    test('필드가 있으면 그대로 읽는다', () {
      final scenario = Scenario.fromJson(
        minimal(const {'shelf': 'a1_eat', 'backdrop': 'cafe'}),
      );
      expect(scenario.shelf, 'a1_eat');
      expect(scenario.backdrop, 'cafe');
    });

    test('공백은 다듬는다', () {
      final scenario = Scenario.fromJson(
        minimal(const {'shelf': '  a1_eat  ', 'backdrop': ' cafe '}),
      );
      expect(scenario.shelf, 'a1_eat');
      expect(scenario.backdrop, 'cafe');
    });
  });
```

- [ ] **Step 2: 실패를 확인한다**

Run: `flutter test test/scenario_shelf_contract_test.dart`
Expected: FAIL — `The getter 'shelf' isn't defined for the type 'Scenario'`

- [ ] **Step 3: 모델에 필드를 넣는다**

`lib/models/scenario.dart` 필드 선언부의 `final String intent;` 아래에 추가:

```dart
  /// 책가도 서재의 칸 — `{level}_{slug}` (예 `a1_eat`).  빈 문자열은 아직
  /// 배정되지 않은 시나리오다 (스펙 §5.1).
  final String shelf;

  /// 장면 배경 카테고리 — 12 열거값 중 하나.  `shelf` 와 **독립**이다:
  /// shelf 는 무엇을 배우나, backdrop 은 어디서 벌어지나다 (스펙 §5.1).
  final String backdrop;
```

생성자의 선택 파라미터 블록(`this.intent = '',` 아래)에 추가:

```dart
    this.shelf = '',
    this.backdrop = '',
```

`fromJson`의 `intent:` 줄 아래에 추가:

```dart
    shelf: ((j['shelf'] as String?) ?? '').trim(),
    backdrop: ((j['backdrop'] as String?) ?? '').trim(),
```

- [ ] **Step 4: 통과를 확인한다**

Run: `flutter test test/scenario_shelf_contract_test.dart`
Expected: 5 tests PASS (Task 2의 2개 + 새 3개)

- [ ] **Step 5: 회귀 없음을 확인한다**

Run: `flutter analyze lib/models/scenario.dart && flutter test test/data_integrity_test.dart test/scene_asset_resolver_test.dart`
Expected: analyze 무경고, 두 테스트 PASS

- [ ] **Step 6: 커밋**

```bash
git add lib/models/scenario.dart test/scenario_shelf_contract_test.dart
git commit -m "feat(scenario): shelf/backdrop 필드를 모델에 열어둠 (데이터는 아직 없음)"
```

---

## Task 5: 마이그레이션 — 두 필드 주입 + 6샤드 생성 (원본은 남긴다)

이 태스크가 끝나면 `assets/data/`에 **7개 파일**이 잠깐 공존한다(레거시 1 + 샤드 6). 원본 삭제는 Task 6이다. 이렇게 나누는 이유는, 삭제와 전환을 한 커밋에 묶으면 38개 파일이 동시에 깨지는 순간이 생기기 때문이다.

**Files:**
- Create: `tools/content_factory/migrate_shelf_backdrop.py`
- Create: `tools/content_factory/test_migrate_shelf_backdrop.py`
- Create: `assets/data/scenarios_{a1,a2,b1,b2,c1,c2}.json` (스크립트가 생성)

**Interfaces:**
- Consumes: `shelf_assignment.{SHELF_BY_ID, check_assignment}` (Task 1), `scenario_store.{load_scenarios, write_shards, DATA}` (Task 3), `test/fixtures/backdrop_baseline.json` (Task 2)
- Produces:
  - `ROOT: Path` — 저장소 루트
  - `BACKDROP_KEYS: frozenset[str]` — 번들에 실재하는 12 카테고리
  - `read_baseline(root: Path = ROOT) -> dict[str, str]`
  - `plan_migration(scenarios: list[dict], baseline: dict[str, str]) -> tuple[list[dict], dict[str, list[str]]]` — `(주입된 시나리오, 리포트)`. 리포트 키: `dupes`/`orphans`/`ghosts`/`wrong_level`/`missing_backdrop`/`unknown_backdrop`. 하나라도 비어 있지 않으면 첫 원소는 빈 리스트다
  - `main(argv: list[str] | None = None) -> int`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`tools/content_factory/test_migrate_shelf_backdrop.py`:

```python
#!/usr/bin/env python3
"""Task 5 — shelf/backdrop 주입의 fail-closed 계약.

Run with:
    python3 -m unittest tools/content_factory/test_migrate_shelf_backdrop.py
"""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import migrate_shelf_backdrop as migrate
import scenario_store
from shelf_assignment import SHELF_BY_ID


class MigrationPlanTest(unittest.TestCase):
    def setUp(self) -> None:
        self.scenarios = scenario_store.load_scenarios()
        self.baseline = migrate.read_baseline()

    def test_live_corpus_migrates_clean(self) -> None:
        migrated, report = migrate.plan_migration(self.scenarios, self.baseline)
        self.assertEqual(report["dupes"], [])
        self.assertEqual(report["orphans"], [])
        self.assertEqual(report["ghosts"], [])
        self.assertEqual(report["wrong_level"], [])
        self.assertEqual(report["missing_backdrop"], [])
        self.assertEqual(report["unknown_backdrop"], [])
        self.assertEqual(len(migrated), 264)

    def test_every_scenario_gets_both_fields(self) -> None:
        migrated, _ = migrate.plan_migration(self.scenarios, self.baseline)
        for item in migrated:
            self.assertEqual(item["shelf"], SHELF_BY_ID[item["id"]])
            self.assertEqual(item["backdrop"], self.baseline[item["id"]])

    def test_sentences_and_ids_are_untouched(self) -> None:
        migrated, _ = migrate.plan_migration(self.scenarios, self.baseline)
        for before, after in zip(self.scenarios, migrated):
            stripped = {
                key: value
                for key, value in after.items()
                if key not in ("shelf", "backdrop")
            }
            self.assertEqual(stripped, before)

    def test_a_scenario_missing_from_the_baseline_is_fail_closed(self) -> None:
        migrated, report = migrate.plan_migration(
            [{"id": "ghost_probe", "level": "a1"}], {}
        )
        self.assertEqual(migrated, [])
        self.assertIn("ghost_probe", report["orphans"])

    def test_unknown_backdrop_value_is_fail_closed(self) -> None:
        one = self.scenarios[:1]
        migrated, report = migrate.plan_migration(
            one, {one[0]["id"]: "spaceship"}
        )
        self.assertEqual(migrated, [])
        self.assertEqual(report["unknown_backdrop"], [one[0]["id"]])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 실패를 확인한다**

Run: `python3 -m unittest tools/content_factory/test_migrate_shelf_backdrop.py`
Expected: FAIL — `ModuleNotFoundError: No module named 'migrate_shelf_backdrop'`

- [ ] **Step 3: 마이그레이션 스크립트를 쓴다**

`tools/content_factory/migrate_shelf_backdrop.py`:

```python
#!/usr/bin/env python3
"""live 264 개에 shelf/backdrop 을 소급 부여하고 레벨 샤드로 분할한다.

문장·ID·레벨은 건드리지 않는다 (스펙 §5.4).  네 지표
(DUPES/ORPHANS/GHOSTS/WRONG LEVEL) 와 backdrop 커버리지 중 하나라도
비어 있지 않으면 아무것도 쓰지 않는다.

Usage:
    python3 tools/content_factory/migrate_shelf_backdrop.py            # 리포트만
    python3 tools/content_factory/migrate_shelf_backdrop.py --apply    # 샤드 생성
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import scenario_store
from shelf_assignment import SHELF_BY_ID, check_assignment

ROOT = Path(__file__).resolve().parents[2]
BASELINE_RELATIVE = Path("test") / "fixtures" / "backdrop_baseline.json"
BACKDROP_KEYS = frozenset(
    (
        "airport", "cafe", "convenience", "directions", "home", "hotel",
        "market", "office", "pharmacy", "restaurant", "station", "taxi",
    )
)


def read_baseline(root: Path = ROOT) -> dict[str, str]:
    with (root / BASELINE_RELATIVE).open(encoding="utf-8") as handle:
        payload = json.load(handle)
    return {str(key): str(value) for key, value in payload["entries"].items()}


def plan_migration(
    scenarios: list[dict[str, Any]],
    baseline: dict[str, str],
) -> tuple[list[dict[str, Any]], dict[str, list[str]]]:
    """주입된 사본과 리포트를 만든다.  입력은 변형하지 않는다."""

    levels = {
        str(item.get("id")): str(item.get("level", "")).strip().lower()
        for item in scenarios
    }
    report = check_assignment(levels)
    report["missing_backdrop"] = sorted(
        scenario_id for scenario_id in levels if scenario_id not in baseline
    )
    report["unknown_backdrop"] = sorted(
        scenario_id
        for scenario_id, key in baseline.items()
        if scenario_id in levels and key not in BACKDROP_KEYS
    )
    if any(report[key] for key in report):
        return [], report

    migrated: list[dict[str, Any]] = []
    for item in scenarios:
        scenario_id = str(item["id"])
        copied = dict(item)
        copied["shelf"] = SHELF_BY_ID[scenario_id]
        copied["backdrop"] = baseline[scenario_id]
        migrated.append(copied)
    return migrated, report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="샤드를 실제로 쓴다")
    args = parser.parse_args(argv)

    scenarios = scenario_store.load_scenarios()
    migrated, report = plan_migration(scenarios, read_baseline())

    failures = {key: value for key, value in report.items() if value}
    if failures:
        for key, value in sorted(failures.items()):
            print(f"FAIL {key}: {len(value)} — {value[:10]}")
        return 1

    print(f"OK: {len(migrated)} scenarios ready (shelf + backdrop injected).")
    if not args.apply:
        print("Dry run. Re-run with --apply to write the shards.")
        return 0

    counts = scenario_store.write_shards(migrated, scenario_store.DATA)
    for level, count in counts.items():
        print(f"  scenarios_{level}.json  {count}")
    print(f"  total {sum(counts.values())}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: 테스트 통과를 확인한다**

Run: `python3 -m unittest tools/content_factory/test_migrate_shelf_backdrop.py -v`
Expected: 5 tests PASS

- [ ] **Step 5: 드라이런 후 실제로 돌린다**

```bash
python3 tools/content_factory/migrate_shelf_backdrop.py
python3 tools/content_factory/migrate_shelf_backdrop.py --apply
```
Expected: 첫 줄 `OK: 264 scenarios ready (shelf + backdrop injected).`, `--apply` 뒤에는

```
  scenarios_a1.json  67
  scenarios_a2.json  66
  scenarios_b1.json  55
  scenarios_b2.json  54
  scenarios_c1.json  11
  scenarios_c2.json  11
  total 264
```

개수가 하나라도 다르면 **커밋하지 말고** 멈춘다 — 기준 실측표의 레벨 분포와 다르다는 뜻이다.

- [ ] **Step 6: 샤드가 원본과 같은 코퍼스인지 확인한다**

```bash
python3 - <<'PY'
import json, sys
from pathlib import Path
sys.path.insert(0, "tools/content_factory")
import scenario_store

legacy = json.loads(Path("assets/data/scenarios.json").read_text(encoding="utf-8"))["scenarios"]
shards = scenario_store.load_scenarios()
assert sorted(s["id"] for s in legacy) == sorted(s["id"] for s in shards), "id 집합이 다르다"
by_id = {s["id"]: s for s in shards}
for item in legacy:
    after = dict(by_id[item["id"]])
    after.pop("shelf"); after.pop("backdrop")
    assert after == item, f"{item['id']} 의 본문이 변했다"
print("id sets identical:", len(legacy), "· bodies identical except shelf/backdrop")
PY
```
Expected: `id sets identical: 264 · bodies identical except shelf/backdrop`

- [ ] **Step 7: 커밋**

```bash
git add assets/data/scenarios_a1.json assets/data/scenarios_a2.json assets/data/scenarios_b1.json assets/data/scenarios_b2.json assets/data/scenarios_c1.json assets/data/scenarios_c2.json tools/content_factory/migrate_shelf_backdrop.py tools/content_factory/test_migrate_shelf_backdrop.py
git commit -m "feat(content): 264개에 shelf/backdrop 주입 + 레벨 6샤드 생성 (원본 유지)"
```

---

## Task 6: 읽는 쪽을 샤드로 넘기고 원본과 `_categoryById`를 지운다

이 태스크가 끝나면 `assets/data/scenarios.json`과 `_categoryById` 264엔트리가 저장소에서 사라진다.

**Files:**
- Create: `test/support/scenario_json.dart`
- Modify: `lib/models/scenario.dart` (`:1` 문서 주석, `_categoryById` 삭제 `:366-672`, `backdropKey` 재정의)
- Modify: `lib/services/scenario_loader.dart` (`:6` 주석, `:12-43` `load()`)
- Modify: `test/scene_asset_resolver_test.dart` (`:152-190` 소스 파싱 → JSON 기반)
- Modify: Dart 테스트 10개 — `a1_real_life_scenarios_test.dart:14`, `arb_l10n_guard_test.dart:99`, `can_do_segment_asset_test.dart:79`, `course_graph_test.dart:308`, `data_integrity_test.dart:16`, `diktat_quest_test.dart:100`, `learner_copy_scan_test.dart:10,82,117`, `satz_bauen_quest_test.dart:187`, `scenario_quest_catalog_integrity_test.dart:11`, `scenario_stage_plan_test.dart:100`
- Modify: `tools/content_factory/validate_content.py` (shelf/backdrop 규칙 + 샤드-레벨 일치)
- Modify: `tools/content_factory/apply_review.py:55`, `integrate_scenario_batch.py:33`, `validate_promoted_batch.py:29`, `validate_reference_intake.py:226`
- Modify: 파이썬 테스트 5개 — `test_integrate_review_batches.py:63,136`, `test_validate_batch_01.py:69,122`, `test_integrate_scenario_batch.py:77`, `test_validate_promoted_batch.py:70`, `test_validate_reference_intake.py:20`, `test_validate_content.py:118-122`
- Delete: `assets/data/scenarios.json`

**Interfaces:**
- Consumes: Task 3의 `scenario_store`, Task 4의 `Scenario.{shelf, backdrop}`, Task 5의 샤드 6개
- Produces:
  - `test/support/scenario_json.dart`: `scenarioShardLevels: List<String>`, `scenarioShardPath(String level) -> String`, `scenarioShardRoot(String level) -> Map<String, dynamic>`, `allScenarioJson() -> List<Map<String, dynamic>>`
  - `ScenarioBackdrop.backdropKey` — `backdrop.isEmpty ? null : backdrop`
  - `ScenarioLoader.shardPath(LearnerLevel level) -> String`, `ScenarioLoader.shardLevels -> List<LearnerLevel>`
  - `validate_content.py`: `SCENARIO_BACKDROP_KEYS: frozenset[str]`, `ContentValidator.validate_scenario_shards() -> None`

- [ ] **Step 1: Dart 테스트 헬퍼를 만든다**

`test/support/scenario_json.dart`:

```dart
import 'dart:convert';
import 'dart:io';

/// 시나리오 코퍼스는 레벨 샤드 6 개다.  테스트가 각자 경로를 조립하면 샤드가
/// 늘거나 이름이 바뀔 때 11 개 파일이 같이 깨진다 — 여기만 고치면 되게 둔다.
const scenarioShardLevels = <String>['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];

String scenarioShardPath(String level) => 'assets/data/scenarios_$level.json';

Map<String, dynamic> scenarioShardRoot(String level) =>
    jsonDecode(File(scenarioShardPath(level)).readAsStringSync())
        as Map<String, dynamic>;

/// 레벨 순서(a1→c2)로 병합된 전 코퍼스.
List<Map<String, dynamic>> allScenarioJson() {
  final merged = <Map<String, dynamic>>[];
  for (final level in scenarioShardLevels) {
    final items = (scenarioShardRoot(level)['scenarios'] as List?) ?? const [];
    merged.addAll(items.cast<Map<String, dynamic>>());
  }
  return merged;
}
```

- [ ] **Step 2: 실패하는 테스트를 쓴다**

`test/scenario_shelf_contract_test.dart` 상단에 `import 'support/scenario_json.dart';` 를 추가하고, Task 2의 무회귀 테스트에서 단일 파일을 읽던 블록을

```dart
      final scenarios =
          (jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
                  as Map<String, dynamic>)['scenarios']
              as List;
```

다음으로 바꾼다:

```dart
      final scenarios = allScenarioJson();
```

그리고 새 그룹을 추가한다:

```dart
  group('샤드 무결성과 shelf/backdrop 계약', () {
    const backdropKeys = <String>{
      'airport', 'cafe', 'convenience', 'directions', 'home', 'hotel',
      'market', 'office', 'pharmacy', 'restaurant', 'station', 'taxi',
    };
    const expectedCounts = <String, int>{
      'a1': 67, 'a2': 66, 'b1': 55, 'b2': 54, 'c1': 11, 'c2': 11,
    };

    test('레거시 단일 파일은 사라졌다', () {
      expect(File('assets/data/scenarios.json').existsSync(), isFalse);
    });

    test('샤드별 개수가 고정값과 같다', () {
      for (final level in scenarioShardLevels) {
        final items = scenarioShardRoot(level)['scenarios'] as List;
        expect(items.length, expectedCounts[level], reason: level);
      }
      expect(allScenarioJson().length, 264);
    });

    test('샤드에는 자기 레벨만 들어 있다', () {
      for (final level in scenarioShardLevels) {
        for (final raw in scenarioShardRoot(level)['scenarios'] as List) {
          expect((raw as Map<String, dynamic>)['level'], level);
        }
      }
    });

    test('id 는 코퍼스 전체에서 유일하다', () {
      final ids = allScenarioJson().map((e) => e['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('모든 시나리오에 shelf 와 backdrop 이 있다', () {
      for (final raw in allScenarioJson()) {
        final scenario = Scenario.fromJson(raw);
        expect(
          scenario.shelf,
          startsWith('${scenario.level.code}_'),
          reason: scenario.id,
        );
        expect(backdropKeys, contains(scenario.backdrop), reason: scenario.id);
      }
    });
  });
```

- [ ] **Step 3: 실패를 확인한다**

Run: `flutter test test/scenario_shelf_contract_test.dart`
Expected: FAIL — `레거시 단일 파일은 사라졌다`가 실패한다(아직 파일이 있다). 나머지 4개는 통과한다 — 샤드에는 이미 두 필드가 있으므로.

- [ ] **Step 4: 런타임 로더를 샤드로 바꾼다**

`lib/services/scenario_loader.dart` 전문을 아래로 바꾼다. `load()`의 계약(전 레벨 union)은 그대로 유지한다 — `CurriculumCatalog` 등 8개 호출부가 이 의미에 의존한다.

```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/scenario.dart';

/// Lädt und cached Szenarien aus `assets/data/scenarios_{level}.json`
/// (6 Level-Shards seit 2026-08-17). Singleton-Pattern wie [DataLoader].
class ScenarioLoader {
  static const List<LearnerLevel> shardLevels = LearnerLevel.values;

  static List<Scenario>? _cached;
  static String? lastError;

  static String shardPath(LearnerLevel level) =>
      'assets/data/scenarios_${level.code}.json';

  /// Parst einen Shard und meldet die Zahl der übersprungenen Einträge.
  /// Eine fehlerhafte Definition darf NICHT die ganze Liste leeren.
  static int _parseInto(String raw, List<Scenario> into) {
    var skipped = 0;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    for (final e in (json['scenarios'] as List? ?? const [])) {
      if (e is! Map<String, dynamic>) {
        skipped++;
        continue;
      }
      try {
        into.add(Scenario.fromJson(e));
      } catch (err) {
        skipped++;
      }
    }
    return skipped;
  }

  /// Alle Level. Für Korpus-weite Konsumenten (Kurs-Katalog, Wortschatz-Suche).
  static Future<List<Scenario>> load() async {
    if (_cached != null) {
      return _cached!;
    }
    final list = <Scenario>[];
    var skipped = 0;
    final failed = <String>[];
    for (final level in shardLevels) {
      try {
        skipped += _parseInto(
          await rootBundle.loadString(shardPath(level)),
          list,
        );
      } catch (e) {
        // Ein fehlender Shard darf die anderen fünf Level nicht mitnehmen.
        failed.add(level.code);
      }
    }
    _cached = list;
    if (failed.isNotEmpty) {
      lastError = 'Szenarien-Shards fehlgeschlagen: ${failed.join(", ")}';
    } else if (list.isEmpty && skipped > 0) {
      lastError = 'Keine gültigen Szenarien ($skipped übersprungen).';
    } else {
      lastError = null;
    }
    return list;
  }

  static Scenario? byId(String id) {
    for (final s in (_cached ?? const <Scenario>[])) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }

  static List<Scenario> byLevel(LearnerLevel level) =>
      (_cached ?? const <Scenario>[]).where((s) => s.level == level).toList();

  /// Cache invalidieren — z.B. nach reset oder Hot-Reload.
  static void reset() {
    _cached = null;
    lastError = null;
  }
}
```

- [ ] **Step 5: `_categoryById`를 지운다**

`lib/models/scenario.dart`에서 `extension ScenarioBackdrop on Scenario` 위의 장문 주석과 264엔트리 const map을 **통째로** 삭제하고 아래로 대체한다. 확장 이름과 `backdropKey` 시그니처는 그대로 둔다 — `scene_asset_resolver.dart:55,73`이 이 이름을 쓴다.

```dart
/// 장면 배경은 이제 JSON `backdrop` 필드가 정본이다.  2026-08-17 이전에는 여기
/// 264 엔트리 const map 이 있었고, 시나리오를 추가할 때마다 Dart 를 고쳐야 했다
/// (스펙 §5.2).  값은 `test/fixtures/backdrop_baseline.json` 으로 그대로 옮겨졌고
/// 무회귀는 `test/scenario_shelf_contract_test.dart` 가 지킨다.
///
/// ⚠️ 카테고리는 `assets/illustrations/scenes/{key}.png` 가 **번들에 실제로 있는**
/// 12 종뿐이다: airport · cafe · convenience · directions · home · hotel ·
/// market · office · pharmacy · restaurant · station · taxi.
/// `SceneAssetResolver` 의 per-scenario 오버라이드 동작은 바뀌지 않았다.
extension ScenarioBackdrop on Scenario {
  /// Category scene key for this scenario, or null if the data has none.
  String? get backdropKey => backdrop.isEmpty ? null : backdrop;
}
```

파일 첫 줄 문서 주석의 `assets/data/scenarios.json` 도 `assets/data/scenarios_{level}.json` 으로 고친다.

- [ ] **Step 6: `scene_asset_resolver_test.dart`를 JSON 기반으로 고친다**

`mapEntries()`(소스 정규식 파싱, `:152-170`)를 지우고, 그것을 쓰던 세 테스트(`:171`, `:185-189`, `:192`)를 아래 두 개로 대체한다. 파일 상단에 `import 'support/scenario_json.dart';` 를 추가한다.

```dart
    test('모든 시나리오에 backdrop 이 있다', () {
      for (final raw in allScenarioJson()) {
        expect(
          (raw['backdrop'] as String?) ?? '',
          isNotEmpty,
          reason: '${raw['id']} 에 backdrop 이 없습니다',
        );
      }
    });

    test('쓰이는 모든 카테고리에 실제 포스터 PNG 가 있다', () {
      final categories = allScenarioJson()
          .map((raw) => raw['backdrop'] as String)
          .toSet();
      expect(categories, isNotEmpty);
      for (final key in categories) {
        expect(
          File('assets/illustrations/scenes/$key.png').existsSync(),
          isTrue,
          reason: '$key 카테고리의 포스터 PNG 가 번들에 없습니다',
        );
      }
    });
```

고아/유령 검사는 없앤다 — 맵이 사라지고 필드가 시나리오에 직접 붙었으므로 구조적으로 발생할 수 없다.

- [ ] **Step 7: 나머지 Dart 테스트 10개의 경로를 바꾼다**

각 파일 상단에 `import 'support/scenario_json.dart';` 를 추가하고, 아래 패턴을

```dart
jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
    as Map<String, dynamic>
```

`allScenarioJson()` 호출로 바꾼다. 루트 객체가 필요한 곳(`data_integrity_test.dart:15-19`)은 목록을 `allScenarioJson()`으로, 버전 확인이 필요하면 `scenarioShardRoot('a1')['version']`으로 바꾼다. `learner_copy_scan_test.dart:10`의 스캔 대상 상수 목록에서는 `'assets/data/scenarios.json'` 한 줄을 6줄로 펼친다:

```dart
  'assets/data/scenarios_a1.json',
  'assets/data/scenarios_a2.json',
  'assets/data/scenarios_b1.json',
  'assets/data/scenarios_b2.json',
  'assets/data/scenarios_c1.json',
  'assets/data/scenarios_c2.json',
```

- [ ] **Step 8: validator 에 shelf/backdrop 규칙을 넣는다**

`tools/content_factory/validate_content.py` 상단 상수에 추가:

```python
from shelf_assignment import ALL_SHELVES

SCENARIO_BACKDROP_KEYS = frozenset(
    (
        "airport", "cafe", "convenience", "directions", "home", "hotel",
        "market", "office", "pharmacy", "restaurant", "station", "taxi",
    )
)
```

`validate_scenarios`의 level 검사(`:331-333`) 바로 뒤에 넣는다:

```python
            shelf = scenario.get("shelf")
            if not isinstance(shelf, str) or shelf not in ALL_SHELVES:
                self.issue(
                    name, f"{ident} shelf must be one of the 72 shelves, got {shelf!r}"
                )
            elif isinstance(level, str) and not shelf.startswith(f"{level.lower()}_"):
                self.issue(
                    name, f"{ident} shelf {shelf!r} does not match level {level!r}"
                )
            backdrop = scenario.get("backdrop")
            if not isinstance(backdrop, str) or backdrop not in SCENARIO_BACKDROP_KEYS:
                self.issue(
                    name,
                    f"{ident} backdrop must be a bundled scene key, got {backdrop!r}",
                )
```

샤드-레벨 일치는 별도 메서드로 넣고 `validate()`(`:173`)에서 `self.validate_scenarios(grammar)` 다음 줄에 부른다:

```python
    def validate_scenario_shards(self) -> None:
        """샤드 파일이 자기 레벨만 담고 있는지 — 잘못 라우팅된 append 를 잡는다."""

        for level in scenario_store.LEVELS:
            file_name = scenario_store.shard_name(level)
            root = self.load_json(file_name)
            if not isinstance(root, dict) or not isinstance(
                root.get("scenarios"), list
            ):
                self.issue(file_name, "root must contain a scenarios array")
                continue
            for item in root["scenarios"]:
                if not isinstance(item, dict):
                    continue
                actual = str(item.get("level", "")).strip().lower()
                if actual != level:
                    self.issue(
                        file_name,
                        f"{item.get('id')!r} has level {actual!r} in the {level} shard",
                    )
```

`test_validate_content.py:118-122`의 오버라이드는 파일명 키로 동작하므로 아래로 바꾼다:

```python
        scenarios = copy.deepcopy(scenario_store.load_root())
        # …기존의 변형…
        validator = ContentValidator()
        validator.load_scenario_root = lambda: scenarios  # type: ignore[method-assign]
```

- [ ] **Step 9: 쓰기 도구 4개의 대상 allowlist 를 넓힌다**

- `apply_review.py:55` `JSON_COLLECTIONS` — `"scenarios.json"` 항목을 샤드 6개로 펼친다:
  ```python
  JSON_COLLECTIONS = {
      **{
          scenario_store.shard_name(level): ("scenario", "scenarios")
          for level in scenario_store.LEVELS
      },
      "cloze.json": ("cloze", "items"),
      "satz_sentences.json": ("satz", "items"),
      "smalltalk.json": ("smalltalk", "phrases"),
      "pronunciation_phrases.json": ("pronunciation", "phrases"),
  }
  ```
  `_resolve_target`의 `allowed` 집합(`:105-110`)이 `JSON_COLLECTIONS` 키에서 파생되는지 **먼저 읽고 확인**한다. 하드코딩돼 있으면 같은 방식으로 파생시킨다.
- `integrate_scenario_batch.py:33` — 이 도구는 배치 하나를 대상 파일 하나에 붙인다. 한 배치가 여러 레벨을 담을 수 있으므로 **레코드마다** 대상을 정하게 바꾼다: `("scenarios.json", "scenarios", (…))` 튜플의 첫 항목을 쓰던 자리에서 `scenario_store.target_shard(record)` 를 부르고, 같은 샤드끼리 모아 파일당 한 번 쓴다.
- `validate_promoted_batch.py:29`, `validate_reference_intake.py:226` — 같은 튜플 형식이므로 `apply_review.py`와 같은 dict comprehension 으로 6개를 펼친다.
- 대응 테스트 5개(`test_integrate_review_batches.py:63,136`, `test_validate_batch_01.py:69,122`, `test_integrate_scenario_batch.py:77`, `test_validate_promoted_batch.py:70`, `test_validate_reference_intake.py:20`)는 임시 트리에 픽스처를 직접 만든다. `(data / "scenarios.json").write_text(...)` 를 `scenario_store.write_shards(records, data)` 로 바꾸면 `has_shards(data)` 가 참이 되어 store 가 샤드를 읽는다.

- [ ] **Step 10: 원본을 지운다**

```bash
git rm assets/data/scenarios.json
```

과거 일회성 스크립트 8개(`add_scenarios_batch2.py`, `add_scenarios_batch3.py`, `add_scenarios_batch4.py`, `add_scenarios_batch5.py`, `add_interest_scenarios.py`, `fix_quest_audio_text.py`, `tools/l10n_sync_2026_08_12/apply_language_fixes.py`, `tools/l10n_sync_2026_08_12/fix_scenarios_rest.py`)는 고치지 않는다. 각 파일 docstring 아래에 두 줄만 추가한다:

```python
# 2026-08-17 이후 무효: 코퍼스는 assets/data/scenarios_{level}.json 6 샤드다.
# 이 스크립트는 이미 실행이 끝난 기록물이라 갱신하지 않는다 (재실행 시 파일 없음으로 죽는다).
```

- [ ] **Step 11: 전체 게이트를 돌린다**

```bash
python3 tools/content_factory/validate_content.py
cd tools/content_factory && python3 -m unittest discover -p "test_*.py"; cd ../..
flutter analyze
flutter test
```
Expected: 모두 통과. `flutter test`가 `scenarios.json`을 못 찾아 죽는 파일이 남아 있으면 Step 7에서 빠뜨린 것이다. 잔재는 `grep -rn "scenarios\.json" lib/ test/` 로 찾는다 — 기대 결과는 위 8개 일회성 스크립트의 주석 외에 **0건**이다.

- [ ] **Step 12: 커밋**

```bash
git add -A
git commit -m "refactor(content): 코퍼스를 6샤드로 전환하고 _categoryById 264엔트리 제거"
```

---

## Task 7: `ScenarioLoader.loadLevel()` 과 상주 2개 LRU 를 만든다

**Files:**
- Modify: `lib/services/scenario_loader.dart`
- Test: `test/scenario_loader_shard_test.dart`

**Interfaces:**
- Consumes: Task 6의 `ScenarioLoader.{load, shardPath, shardLevels, reset, _parseInto}`
- Produces:
  - `ScenarioLoader.loadLevel(LearnerLevel level) -> Future<List<Scenario>>`
  - `ScenarioLoader.maxResidentShards -> int` (=2, 스펙 §6)
  - `ScenarioLoader.residentLevels -> List<LearnerLevel>` — 오래된 것부터. 테스트 seam
  - `ScenarioLoader.byId` 는 전 코퍼스와 상주 샤드를 모두 본다

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/scenario_loader_shard_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

/// 어떤 샤드를 실제로 읽었는지를 세어 레벨 단위 로드와 LRU 를 고정한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requested = <String>[];

  setUp(() {
    ScenarioLoader.reset();
    requested.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = const StringCodec().decodeMessage(message)!;
          requested.add(key);
          const empty = '{"version":1,"scenarios":[]}';
          return ByteData.sublistView(
            Uint8List.fromList(const Utf8Encoder().convert(empty)),
          );
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  int shardReads() =>
      requested.where((path) => path.contains('scenarios_')).length;

  test('loadLevel 은 그 레벨 샤드 하나만 요청한다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.b1);
    expect(requested, contains('assets/data/scenarios_b1.json'));
    expect(shardReads(), 1);
  });

  test('세 번째 레벨을 열면 가장 오래된 샤드가 내려간다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.a1);
    await ScenarioLoader.loadLevel(LearnerLevel.a2);
    await ScenarioLoader.loadLevel(LearnerLevel.b1);
    expect(ScenarioLoader.maxResidentShards, 2);
    expect(ScenarioLoader.residentLevels, [LearnerLevel.a2, LearnerLevel.b1]);
  });

  test('같은 레벨을 다시 열면 다시 읽지 않는다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.c1);
    final first = shardReads();
    await ScenarioLoader.loadLevel(LearnerLevel.c1);
    expect(shardReads(), first);
  });

  test('전 코퍼스가 이미 상주하면 loadLevel 은 추가 IO 를 하지 않는다', () async {
    await ScenarioLoader.load();
    final afterFull = shardReads();
    expect(afterFull, 6);
    await ScenarioLoader.loadLevel(LearnerLevel.a1);
    expect(shardReads(), afterFull);
  });

  test('reset 은 전 코퍼스와 샤드를 함께 비운다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.a1);
    ScenarioLoader.reset();
    expect(ScenarioLoader.residentLevels, isEmpty);
  });
}
```

파일 상단에 `import 'dart:convert';` 와 `import 'dart:typed_data';` 를 추가한다.

- [ ] **Step 2: 실패를 확인한다**

Run: `flutter test test/scenario_loader_shard_test.dart`
Expected: FAIL — `The method 'loadLevel' isn't defined for the type 'ScenarioLoader'`

- [ ] **Step 3: 로더를 확장한다**

`lib/services/scenario_loader.dart`에 추가한다. Task 6의 `load()`는 그대로 둔다.

```dart
  /// Wie viele Level-Shards gleichzeitig im Speicher bleiben dürfen (Spec §6).
  static const int maxResidentShards = 2;

  static final Map<LearnerLevel, List<Scenario>> _shards = {};
  static final List<LearnerLevel> _lru = [];

  /// Resident shards, ältester zuerst. Test-Seam.
  static List<LearnerLevel> get residentLevels => List.unmodifiable(_lru);

  /// Lädt nur den Shard eines Levels. Das Regal (Hören) braucht die anderen
  /// fünf Level nicht — bei 3.600 Szenarien wären das 22 MB statt 3,7 MB.
  static Future<List<Scenario>> loadLevel(LearnerLevel level) async {
    final full = _cached;
    if (full != null) {
      // Voller Korpus liegt schon: kein zweites Lesen derselben Daten.
      return full.where((s) => s.level == level).toList();
    }
    final resident = _shards[level];
    if (resident != null) {
      _touch(level);
      return resident;
    }
    final list = <Scenario>[];
    try {
      _parseInto(await rootBundle.loadString(shardPath(level)), list);
      lastError = null;
    } catch (e) {
      lastError = 'Szenarien (${level.code}) konnten nicht geladen werden: $e';
    }
    _shards[level] = list;
    _touch(level);
    while (_lru.length > maxResidentShards) {
      _shards.remove(_lru.removeAt(0));
    }
    return list;
  }

  static void _touch(LearnerLevel level) {
    _lru.remove(level);
    _lru.add(level);
  }
```

`byId`와 `reset`을 샤드까지 보게 고친다:

```dart
  static Scenario? byId(String id) {
    for (final s in (_cached ?? const <Scenario>[])) {
      if (s.id == id) {
        return s;
      }
    }
    for (final shard in _shards.values) {
      for (final s in shard) {
        if (s.id == id) {
          return s;
        }
      }
    }
    return null;
  }

  static void reset() {
    _cached = null;
    _shards.clear();
    _lru.clear();
    lastError = null;
  }
```

- [ ] **Step 4: 통과를 확인한다**

Run: `flutter test test/scenario_loader_shard_test.dart -v`
Expected: 5 tests PASS

- [ ] **Step 5: 기존 로더 소비자가 안 깨졌는지 확인한다**

Run: `flutter test test/course_graph_test.dart test/content_audit_manifest_test.dart test/scenario_stage_plan_test.dart test/a1_real_life_scenario_test.dart`
Expected: 전부 PASS. `load()`의 계약(전 레벨 union)이 바뀌지 않았으므로 `CurriculumCatalog` 경로는 그대로여야 한다.

- [ ] **Step 6: 커밋**

```bash
git add lib/services/scenario_loader.dart test/scenario_loader_shard_test.dart
git commit -m "feat(scenario): 레벨 샤드 단위 로드 + 상주 2개 LRU"
```

---

## Task 8: 문서·기록을 맞추고 전체 게이트를 돌린다

**Files:**
- Modify: `AGENTS.md:178`
- Modify: `tools/content_factory/README.md:273` 부근
- Modify: `docs/SESSION_LOG.md` (최상단)

- [ ] **Step 1: `AGENTS.md`의 데이터 줄을 고친다**

`:178`의

```
- `assets/data/scenarios.json` — 회화 시나리오
```

을 다음으로 바꾼다:

```
- `assets/data/scenarios_{a1,a2,b1,b2,c1,c2}.json` — 회화 시나리오, **레벨 샤드 6개**
  (2026-08-17). 단일 `scenarios.json` 은 없다. 읽기/쓰기는 파이썬
  `tools/content_factory/scenario_store.py`, Dart 테스트는
  `test/support/scenario_json.dart`, 런타임은 `ScenarioLoader.load()`(전 레벨) /
  `loadLevel()`(단일 샤드, 상주 2). 칸(`shelf`)·배경(`backdrop`) 필드는 필수이며
  칸 정의는 `tools/content_factory/shelf_assignment.py` 가 정본이다.
```

- [ ] **Step 2: `tools/content_factory/README.md`의 시나리오 병합 절에 한 문단을 넣는다**

```markdown
**시나리오는 레벨 샤드다 (2026-08-17).** `assets/data/scenarios.json` 은 없어졌고
`scenarios_{a1..c2}.json` 6 개가 정본이다. 어떤 도구도 경로를 직접 조립하지 말고
`scenario_store.py` 의 `load_scenarios()` / `write_shards()` / `target_shard()` 를 쓴다.
draft 레코드에는 `shelf`(72칸 중 하나) 와 `backdrop`(번들에 있는 12 종 중 하나)이
반드시 들어가야 `validate_content.py` 를 통과한다.
```

- [ ] **Step 3: 전체 게이트를 돌린다**

```bash
python3 tools/content_factory/validate_content.py
cd tools/content_factory && python3 -m unittest discover -p "test_*.py"; cd ../..
flutter analyze
flutter test
```
Expected: `OK: Content validation passed.` · 파이썬 전 테스트 PASS · analyze 무경고 · `flutter test` 전 통과. 실패가 하나라도 있으면 **여기서 멈추고** 원인을 고친 뒤 다시 돌린다 — 세션 로그의 "검증"에 적을 값이 이 실행 결과다.

- [ ] **Step 4: `docs/SESSION_LOG.md` 최상단에 기록한다**

기존 최상단 항목(2026-08-17 설계) **위에** 새 항목을 넣는다. 무엇을·왜·검증·커밋해시 네 가지를 모두 적는다. 검증 줄에는 Step 3의 실제 출력(시나리오 264, 샤드별 67/66/55/54/11/11, `flutter test` 통과 수, 파이썬 테스트 수)을 적고, 커밋 해시는 Task 1–7의 실제 해시를 나열한다. "스펙과 달라진 점" 3가지도 한 문단으로 남긴다 — 계획 2가 그 위에서 판단해야 한다.

- [ ] **Step 5: 커밋**

```bash
git add AGENTS.md docs/SESSION_LOG.md tools/content_factory/README.md
git commit -m "docs(hoeren): 레벨 샤드 전환을 파일맵·세션로그에 반영"
```

---

## 완료 조건

1. `assets/data/scenarios.json` 이 저장소에 없다.
2. `assets/data/scenarios_{a1..c2}.json` 6개가 있고 개수가 67/66/55/54/11/11 이다.
3. 264개 전부에 `shelf`(72칸 중 하나, 레벨 접두사 일치)와 `backdrop`(번들 12종 중 하나)이 있다.
4. `test/fixtures/backdrop_baseline.json` 대비 배경 회귀가 0이다.
5. `lib/models/scenario.dart` 에 `_categoryById` 가 없다.
6. `ScenarioLoader.loadLevel(level)` 이 그 레벨 샤드 하나만 읽고, 상주 샤드가 2개를 넘지 않는다.
7. `python3 tools/content_factory/validate_content.py` · content_factory `unittest discover` · `flutter analyze` · `flutter test` 가 전부 통과한다.
8. `docs/SESSION_LOG.md` 최상단에 커밋 해시가 박힌 기록이 있다.

## 이 계획이 하지 않는 것

- `/listening` 화면 변경 — 계획 2 (서재 UI). 로더 API만 준비한다.
- 진행도 키 분할(`kl_completed_scenarios_{level}`) — 계획 2. 스펙 §6도 "우선순위는 샤딩보다 낮다"고 적었다.
- `CurriculumCatalog` 의 전 코퍼스 의존 제거 — 19개 호출부를 건드리는 별건. 위 "스펙과 달라진 점" 2번.
- Batch 11 draft 18개에 `shelf` 넣기 — 다른 워크트리(locked)의 소유. 그 세션이 완주할 때 이 계획의 `ALL_SHELVES`·validator 규칙을 그대로 쓰면 된다.
- 신규 집필(`a1_eat` 47개) — 계획 3 (Batch 12).
- TTS — Jin 직접 합성, 설계 범위 밖 (스펙 §8).
