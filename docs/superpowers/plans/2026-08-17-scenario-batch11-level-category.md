# Batch 11 시나리오 36개 집필 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 6레벨 × 6카테고리 = 36개 시나리오를 review-only Batch 11 초안으로 집필하고, `integrate_scenario_batch.py` preview를 통과시킨다.

**Architecture:** 사람이 읽고 고치는 장면 원문(`data/batch_11_scene_scripts.py`)과 스키마를 조립하는 빌더(`build_batch_11_scenarios.py`)를 분리한다. Batch 08/10이 쓴 관용구와 같다. 빌더는 draft JSON·review CSV·manifest 세 산출물을 한 번에 쓰고, 계약 테스트가 레벨 문법 상한·ID 충돌·review projection을 고정한다.

**Tech Stack:** Python 3.13 표준 라이브러리만(`json`, `csv`, `pathlib`, `unittest`). pytest는 이 환경에 없다. 앱 코드(Dart) 변경 없음.

**Spec:** [`docs/superpowers/specs/2026-08-17-scenario-level-category-batch11-design.md`](../specs/2026-08-17-scenario-level-category-batch11-design.md)

## Global Constraints

- **커밋 금지.** AGENTS.md가 이 스킬의 기본 커밋 단계를 덮어쓴다: `git commit`/`push`는 Jin이 명시적으로 요청할 때만. 각 task는 커밋 대신 preview 통과로 닫는다.
- **`assets/data/` 수정 금지. `lib/` 수정 금지. `--apply` 금지. TTS 합성·Firebase 쓰기 금지.**
- 변경이 하나라도 생기면 `docs/SESSION_LOG.md` 최상단에 항목을 남긴다(무엇을·왜·검증).
- 한국어가 원문이고 DE/EN은 같은 정보량·같은 존대·같은 화행을 전달한다. placeholder(`TODO`/`TBD`/빈 번역) 금지.
- scenario JSON의 `level`은 소문자(`a1`), review CSV의 `level`은 대문자(`A1`).
- review CSV 헤더는 정확히 `id,level,ko,de,en,field_notes,상태,jin_memo`이고, `ko`/`de`/`en`은 draft `title.ko`/`title.de`/`title.en`과 **한 글자까지 동일**해야 한다(`integrate_scenario_batch.ARTIFACTS`의 scenario projection).
- `register`/`speechStyle`은 `polite`/`casual`/`business`/`intimate`만. legacy `formal` 금지.
- `sidekick`은 `jieun` 또는 `minsu`만.
- `backdrops` 값은 12개 `SCENE_KEYS`만: `airport, cafe, convenience, directions, home, hotel, market, office, pharmacy, restaurant, station, taxi`.
- `contentLinks[].role`은 `practice`를 쓴다(허용값 `introduce|practice|assess|review`). 새 시나리오를 평가 권한으로 선언하지 않는다.
- 대화 8턴, 퀘스트 5개(`hoerverstehen`+`uebersetzen`+`luecken`+`satzBauen`+`diktat`), `vocab` 6개 이상.
- `grammarIds`는 아래 확정표에 적힌 실존 ID만. 새 문법을 만들지 않는다.
- Windows 로컬에서는 `python`, mac에서는 `python3`. 아래 명령은 `python`으로 적었다.

---

## File Structure

| 파일 | 책임 |
| --- | --- |
| `tools/content_factory/data/batch_11_scene_scripts.py` | 36개 장면 원문. 사람이 읽고 고치는 유일한 콘텐츠 소스 |
| `tools/content_factory/build_batch_11_scenarios.py` | 장면 원문 → draft JSON + review CSV + manifest 조립 |
| `tools/content_factory/test_build_batch_11_scenarios.py` | 레벨 계약·ID 충돌·projection·셸 문구 회귀 |
| `tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json` | 빌더 산출물 (직접 편집 금지) |
| `tools/content_factory/drafts/batch_11_manifest.json` | 빌더 산출물 (직접 편집 금지) |
| `tools/content_factory/review/c1_batch11_scenarios.csv` | 빌더 산출물. Jin이 `상태`/`jin_memo`만 편집 |
| `docs/SESSION_LOG.md` | 변경 기록 |

## 36칸 확정표

`id`는 scenario ID의 전체 값이다. `grammarIds`는 실존 `grammar.csv` ID다.

### A1 — xpReward 120

| cat | id | intent | unit / concept | grammarIds | register | sidekick | relationshipContext | backdrop |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| daily | `a1_daily_recycling_day` | `check_recycling_day` | `a1_09_home_daily_life` / `concept_a1_home_daily` | `grammar_a1_direction_time_particle` | polite | jieun | `neighbors` | home |
| friends | `a1_friends_major_and_number` | `swap_contact_after_class` | `a1_15_first_class_work` / `concept_a1_first_meeting` | `grammar_a1_which_question` | polite | minsu | `new_acquaintances` | cafe |
| dating | `a1_dating_what_to_call_you` | `settle_on_a_name` | `a1_11_titles_relationships` / `concept_a1_titles_relationships` | `grammar_a1_want` | casual | jieun | `close_friends` | cafe |
| youtube | `a1_youtube_shorts_last_night` | `compare_what_we_watched` | `a1_12_daily_negation` / `concept_a1_negation` | `grammar_a1_short_negation`, `grammar_a1_polite_past` | casual | minsu | `close_friends` | home |
| gaming | `a1_gaming_one_more_round` | `invite_to_play` | `a1_04_order_request_object` / `concept_request_polite` | `grammar_a1_object_particle`, `grammar_a1_polite_request` | casual | minsu | `close_friends` | home |
| kpop | `a1_kpop_my_bias` | `introduce_my_bias` | `a1_02_self_intro_identity` / `concept_identity_polite` | `grammar_a1_copula_polite` | polite | jieun | `new_acquaintances` | cafe |

### A2 — xpReward 140

| cat | id | intent | unit / concept | grammarIds | register | sidekick | relationshipContext | backdrop |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| daily | `a2_daily_late_delivery` | `chase_late_delivery` | `a2_05_delivery_services` / `concept_a2_services` | `grammar_a2_probability` | polite | jieun | `customer_and_delivery_staff` | convenience |
| friends | `a2_friends_weekend_slot` | `fit_two_schedules` | `a2_02_plans_proposals` / `concept_proposal_polite` | `grammar_a2_polite_proposal` | casual | minsu | `close_friends` | cafe |
| dating | `a2_dating_slow_replies` | `name_a_small_hurt` | `a2_04_feelings_health` / `concept_a2_feelings` | `grammar_a2_noun_cause` | casual | jieun | `romantic_partners` | restaurant |
| youtube | `a2_youtube_send_the_link` | `explain_why_its_funny` | `a2_03_chat_relationships` / `concept_a2_relationships` | `grammar_a2_exclamation`, `grammar_a2_recommendation` | casual | minsu | `close_friends` | home |
| gaming | `a2_gaming_cant_connect` | `fix_a_login_block` | `a2_07_travel_repair` / `concept_a2_travel_repair` | `grammar_a2_ability` | casual | minsu | `close_friends` | home |
| kpop | `a2_kpop_concert_queue` | `talk_to_a_stranger_fan` | `a2_01_haeyo_transition` / `concept_action_polite` | `grammar_a2_gentle_question` | polite | jieun | `new_acquaintances` | station |

### B1 — xpReward 160

| cat | id | intent | unit / concept | grammarIds | register | sidekick | relationshipContext | backdrop |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| daily | `b1_daily_cut_the_bills` | `plan_a_cheaper_month` | `b1_06_life_capstone` / `concept_b1_life` | `grammar_b1_decision` | casual | minsu | `close_friends` | home |
| friends | `b1_friends_he_said_that` | `undo_a_relayed_remark` | `b1_02_indirect_speech` / `concept_b1_indirect_speech` | `grammar_b1_indirect_speech` | casual | minsu | `close_friends` | cafe |
| dating | `b1_dating_anniversary_gap` | `repair_mismatched_expectations` | `b1_04_relationships` / `concept_b1_relationships` | `grammar_b1_wish` | intimate | jieun | `romantic_partners` | restaurant |
| youtube | `b1_youtube_up_all_night` | `explain_a_lost_night` | `b1_01_experience_reasons` / `concept_b1_reasons_experience` | `grammar_b1_negative_cause`, `grammar_b1_experience` | casual | minsu | `close_friends` | home |
| gaming | `b1_gaming_team_voice` | `soften_a_callout` | `b1_03_work_softening` / `concept_b1_softening` | `grammar_b1_background_contrast` | casual | minsu | `close_friends` | home |
| kpop | `b1_kpop_missing_goods` | `claim_a_missing_item` | `b1_05_complaint_resolution` / `concept_b1_complaint_resolution` | `grammar_b1_soft_request` | polite | jieun | `customer_and_shop_staff` | market |

### B2 — xpReward 180

| cat | id | intent | unit / concept | grammarIds | register | sidekick | relationshipContext | backdrop |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| daily | `b2_daily_upstairs_noise` | `demand_a_concrete_fix` | `b2_03_precise_requests` / `concept_b2_precise_requests` | `grammar_b2_formal_arrangement`, `grammar_b2_explicit_formal_request` | polite | jieun | `tenant_and_building_manager` | home |
| friends | `b2_friends_split_the_bill` | `argue_a_fair_split` | `b2_02_professional_opinion` / `concept_b2_opinion` | `grammar_b2_not_automatic_conclusion` | casual | minsu | `close_friends` | restaurant |
| dating | `b2_dating_moving_in_terms` | `negotiate_living_terms` | `b2_06_advanced_capstone` / `concept_b2_advanced` | `grammar_b2_as_long_as`, `grammar_b2_instead_tradeoff` | intimate | jieun | `romantic_partners` | home |
| youtube | `b2_youtube_collab_pitch` | `open_a_collab_pitch` | `b2_01_formal_opening` / `concept_b2_formal_opening` | `grammar_b2_formal_intention` | business | minsu | `professional_colleagues` | office |
| gaming | `b2_gaming_ban_appeal` | `contest_an_account_ban` | `b2_04_complaint_resolution` / `concept_b2_complaint` | `grammar_b2_formal_reason`, `grammar_b2_explicit_formal_request` | business | minsu | `customer_and_service_staff` | office |
| kpop | `b2_kpop_staff_interview` | `present_myself_as_staff` | `b2_05_interview` / `concept_b2_interview` | `grammar_b2_shared_merit` | business | jieun | `professional_colleagues` | office |

### C1 — xpReward 190

| cat | id | intent | unit / concept | grammarIds | register | sidekick | relationshipContext | backdrop |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| daily | `c1_daily_prices_vs_data` | `reconcile_feeling_and_data` | `c1_01_evidence_public_reasoning` / `concept_c1_evidence_reasoning` | `grammar_c1_taking_into_account` | business | jieun | `analyst_and_public_program_manager` | office |
| friends | `c1_friends_venue_access` | `raise_an_access_barrier` | `c1_02_inclusive_sustainable_systems` / `concept_c1_inclusive_systems` | `grammar_c1_two_sides` | business | minsu | `community_organizers` | cafe |
| dating | `c1_dating_app_safety` | `design_a_safety_path` | `c1_02_inclusive_sustainable_systems` / `concept_c1_inclusive_systems` | `grammar_c1_even_at_cost` | business | jieun | `user_and_platform_trust_team` | office |
| youtube | `c1_youtube_health_claims` | `limit_an_evidence_claim` | `c1_01_evidence_public_reasoning` / `concept_c1_evidence_reasoning` | `grammar_c1_room_for` | business | minsu | `analyst_and_public_program_manager` | office |
| gaming | `c1_gaming_playtime_policy` | `weigh_a_playtime_rule` | `c1_01_evidence_public_reasoning` / `concept_c1_evidence_reasoning` | `grammar_c1_unless_condition` | business | minsu | `analyst_and_public_program_manager` | office |
| kpop | `c1_kpop_fan_labor` | `question_unpaid_fan_labor` | `c1_02_inclusive_sustainable_systems` / `concept_c1_inclusive_systems` | `grammar_c1_given_situation` | business | jieun | `fan_representative_and_agency` | office |

### C2 — xpReward 200

| cat | id | intent | unit / concept | grammarIds | register | sidekick | relationshipContext | backdrop |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| daily | `c2_daily_automation_redress` | `demand_a_redress_route` | `c2_02_technology_public_ethics` / `concept_c2_accountable_systems` | `grammar_c2_nothing_more_than` | business | jieun | `citizen_advocate_and_system_owner` | office |
| friends | `c2_friends_quoted_privately` | `bound_a_private_quote` | `c2_01_interpretation_institutions` / `concept_c2_discourse_institutions` | `grammar_c2_defined_as` | business | minsu | `community_organizers` | cafe |
| dating | `c2_dating_romance_frames` | `expose_a_narrative_frame` | `c2_01_interpretation_institutions` / `concept_c2_discourse_institutions` | `grammar_c2_regardless_of_kin` | business | jieun | `panel_discussants` | office |
| youtube | `c2_youtube_algorithm_duty` | `locate_algorithmic_duty` | `c2_02_technology_public_ethics` / `concept_c2_accountable_systems` | `grammar_c2_even_assuming` | business | minsu | `citizen_advocate_and_system_owner` | office |
| gaming | `c2_gaming_auto_sanction` | `test_an_automated_sanction` | `c2_02_technology_public_ethics` / `concept_c2_accountable_systems` | `grammar_c2_on_the_premise` | business | minsu | `citizen_advocate_and_system_owner` | office |
| kpop | `c2_kpop_fandom_language` | `contest_discursive_power` | `c2_01_interpretation_institutions` / `concept_c2_discourse_institutions` | `grammar_c2_even_if_concession` | business | jieun | `fan_representative_and_agency` | office |

---

## Task 1: 빌더·계약 테스트·A1 6개 (수직 슬라이스)

**Files:**
- Create: `tools/content_factory/data/batch_11_scene_scripts.py`
- Create: `tools/content_factory/build_batch_11_scenarios.py`
- Create: `tools/content_factory/test_build_batch_11_scenarios.py`
- Generated: `tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json`, `tools/content_factory/drafts/batch_11_manifest.json`, `tools/content_factory/review/c1_batch11_scenarios.csv`

**Interfaces:**
- Produces:
  - `batch_11_scene_scripts.SCENES: list[dict]` — 장면 원문. 각 원소 키: `id`, `level`, `category`, `intent`, `courseUnitId`, `conceptIds: list[str]`, `grammarIds: list[str]`, `register`, `speechStyle`, `relationshipContext`, `sidekick`, `emoji`, `xpReward: int`, `backdrop`, `title: {ko,de,en}`, `intro: {ko,de,en}`, `grammarBlock: {title:{ko,de,en}, explanation:{ko,de,en}}`, `vocab: list[dict]`, `dialog: list[{speaker,ko,de,en}]`, `quests: list[dict]`, `culturalNote: {title:{ko,de,en}, body:{ko,de,en}} | None`, `fieldNotes: str`
  - `build_batch_11_scenarios.build(root: Path = ROOT) -> dict[str, int]` — 세 산출물을 쓰고 `{"scenarios": n, "quests": m}` 반환
  - `build_batch_11_scenarios.LEVEL_GRAMMAR_ALLOWLIST: dict[str, frozenset[str]]` — 레벨별 허용 grammar ID
  - `build_batch_11_scenarios.QUEST_SUFFIXES: tuple[str, ...]` = `("hear", "tr", "gap", "build", "dict")`

- [ ] **Step 1: 계약 테스트를 먼저 쓴다**

`tools/content_factory/test_build_batch_11_scenarios.py`:

```python
#!/usr/bin/env python3
"""Batch 11 시나리오 초안의 레벨 계약·ID 충돌·review projection 회귀."""

from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_batch_11_scenarios as builder
from data.batch_11_scene_scripts import SCENES

ROOT = SCRIPT_DIR.parents[1]
CATEGORIES = ("daily", "friends", "dating", "youtube", "gaming", "kpop")
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
QUEST_TYPES = ("hoerverstehen", "uebersetzen", "luecken", "satzBauen", "diktat")
REGISTERS = ("polite", "casual", "business", "intimate")
SCENE_KEYS = ("airport", "cafe", "convenience", "directions", "home", "hotel",
              "market", "office", "pharmacy", "restaurant", "station", "taxi")
SHELL_PHRASES = (
    "알겠습니다. 지금 바로 확인하겠습니다.",
    "네, 그렇게 해 주세요.",
    "안녕하세요. 무엇을 도와드릴까요?",
)


def authored_levels() -> tuple[str, ...]:
    return tuple(level for level in LEVELS if any(s["level"] == level for s in SCENES))


class SceneContractTest(unittest.TestCase):
    def test_authored_levels_have_six_categories_each(self):
        for level in authored_levels():
            cats = sorted(s["category"] for s in SCENES if s["level"] == level)
            self.assertEqual(cats, sorted(CATEGORIES), f"{level} category set")

    def test_ids_follow_level_category_pattern(self):
        for scene in SCENES:
            self.assertTrue(
                scene["id"].startswith(f"{scene['level']}_{scene['category']}_"),
                f"{scene['id']} must start with level_category",
            )

    def test_no_collision_with_live_scenarios(self):
        live = json.loads((ROOT / "assets/data/scenarios.json").read_text(encoding="utf-8"))
        live_ids = {item["id"] for item in live["scenarios"]}
        live_quests = {q["id"] for item in live["scenarios"] for q in item.get("quests", [])}
        for scene in SCENES:
            self.assertNotIn(scene["id"], live_ids, f"{scene['id']} already live")
            for quest in scene["quests"]:
                self.assertNotIn(quest["id"], live_quests, f"{quest['id']} already live")

    def test_dialog_is_eight_trilingual_turns(self):
        for scene in SCENES:
            self.assertEqual(len(scene["dialog"]), 8, f"{scene['id']} dialog length")
            for turn in scene["dialog"]:
                self.assertIn(turn["speaker"], ("user", scene["sidekick"]))
                for key in ("ko", "de", "en"):
                    self.assertTrue(turn[key].strip(), f"{scene['id']} empty {key}")

    def test_five_quests_one_of_each_type(self):
        for scene in SCENES:
            types = [quest["type"] for quest in scene["quests"]]
            self.assertEqual(sorted(types), sorted(QUEST_TYPES), f"{scene['id']} quest types")
            for quest, suffix in zip(scene["quests"], builder.QUEST_SUFFIXES):
                self.assertEqual(quest["id"], f"quest_{scene['id']}_{suffix}")
                self.assertEqual(quest["conceptIds"], scene["conceptIds"])

    def test_vocab_has_at_least_six_entries(self):
        for scene in SCENES:
            self.assertGreaterEqual(len(scene["vocab"]), 6, f"{scene['id']} vocab count")
            for entry in scene["vocab"]:
                self.assertTrue(entry["korean"].strip())

    def test_grammar_ids_exist_and_match_level(self):
        rows = list(csv.DictReader((ROOT / "assets/data/grammar.csv").open(encoding="utf-8")))
        live = {row["id"]: row["level"].lower() for row in rows}
        for scene in SCENES:
            self.assertTrue(scene["grammarIds"], f"{scene['id']} needs a grammar id")
            for gid in scene["grammarIds"]:
                self.assertIn(gid, live, f"{gid} missing from grammar.csv")
                self.assertEqual(live[gid], scene["level"], f"{gid} level mismatch")
                self.assertIn(gid, builder.LEVEL_GRAMMAR_ALLOWLIST[scene["level"]],
                              f"{gid} outside {scene['level']} allowlist")

    def test_units_and_concepts_exist(self):
        manifest = json.loads((ROOT / "assets/data/curriculum_manifest.json").read_text(encoding="utf-8"))
        units = {u["id"]: (u["level"], set(u["requiredConceptIds"])) for u in manifest["courseUnits"]}
        for scene in SCENES:
            level, concepts = units[scene["courseUnitId"]]
            self.assertEqual(level, scene["level"], f"{scene['id']} unit level")
            for concept in scene["conceptIds"]:
                self.assertIn(concept, concepts, f"{concept} not required by {scene['courseUnitId']}")

    def test_enums_and_backdrops(self):
        for scene in SCENES:
            self.assertIn(scene["register"], REGISTERS)
            self.assertIn(scene["speechStyle"], REGISTERS)
            self.assertIn(scene["sidekick"], ("jieun", "minsu"))
            self.assertIn(scene["backdrop"], SCENE_KEYS)
            self.assertTrue(scene["emoji"].strip())

    def test_no_shell_phrases_and_no_repeated_lines(self):
        for scene in SCENES:
            lines = [turn["ko"] for turn in scene["dialog"]]
            self.assertEqual(len(lines), len(set(lines)), f"{scene['id']} repeats a Korean line")
            for line in lines:
                self.assertNotIn(line, SHELL_PHRASES, f"{scene['id']} uses a shell phrase")

    def test_intents_are_unique(self):
        intents = [scene["intent"] for scene in SCENES]
        self.assertEqual(len(intents), len(set(intents)), "intents must be unique")


class BuildOutputTest(unittest.TestCase):
    def setUp(self):
        self.counts = builder.build()
        self.draft = json.loads(
            (ROOT / "tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json").read_text(encoding="utf-8"))
        self.manifest = json.loads(
            (ROOT / "tools/content_factory/drafts/batch_11_manifest.json").read_text(encoding="utf-8"))
        with (ROOT / "tools/content_factory/review/c1_batch11_scenarios.csv").open(
                encoding="utf-8", newline="") as handle:
            self.review = list(csv.DictReader(handle))

    def test_manifest_counts_match_draft(self):
        records = self.draft["scenarios"]
        self.assertEqual(self.manifest["recordCount"], len(records))
        self.assertEqual(self.counts["scenarios"], len(records))
        quests = [q for record in records for q in record["quests"]]
        self.assertEqual(self.manifest["questCount"], len(quests))
        artifact = self.manifest["artifacts"][0]
        self.assertEqual(artifact["count"], len(records))
        levels = {}
        for record in records:
            levels[record["level"]] = levels.get(record["level"], 0) + 1
        self.assertEqual(artifact["levels"], levels)

    def test_review_projection_is_byte_identical(self):
        records = self.draft["scenarios"]
        self.assertEqual([row["id"] for row in self.review], [r["id"] for r in records])
        for row, record in zip(self.review, records):
            self.assertEqual(row["level"], record["level"].upper())
            self.assertEqual(row["ko"], record["title"]["ko"])
            self.assertEqual(row["de"], record["title"]["de"])
            self.assertEqual(row["en"], record["title"]["en"])
            self.assertEqual(row["상태"], "draft")
            self.assertTrue(row["field_notes"].strip())

    def test_manifest_links_and_backdrops_cover_every_scenario(self):
        ids = [record["id"] for record in self.draft["scenarios"]]
        self.assertEqual([link["contentId"] for link in self.manifest["contentLinks"]], ids)
        self.assertEqual(set(self.manifest["backdrops"]), set(ids))
        for link in self.manifest["contentLinks"]:
            self.assertEqual(link["role"], "practice")
            self.assertEqual(link["contentKind"], "scenario")

    def test_manifest_stays_review_only(self):
        self.assertEqual(self.manifest["status"], "review_only_draft")
        self.assertEqual(self.manifest["batch"], "11")
        self.assertEqual(self.manifest["provenance"]["rights"], "original")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: 테스트를 돌려 실패를 확인한다**

Run: `python tools/content_factory/test_build_batch_11_scenarios.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'build_batch_11_scenarios'`

- [ ] **Step 3: 장면 원문 파일의 골격과 A1 6개를 쓴다**

`tools/content_factory/data/batch_11_scene_scripts.py`. 아래는 첫 칸의 **완성 예시**다. 남은 A1 5칸은 확정표의 metadata를 그대로 쓰고 문장만 새로 쓴다.

```python
#!/usr/bin/env python3
"""Batch 11 장면 원문: 일상·친구·연애·유튜브·게임·덕질. 한국어가 원문이다."""

from __future__ import annotations

from typing import Any

SCENES: list[dict[str, Any]] = [
    {
        "id": "a1_daily_recycling_day",
        "level": "a1",
        "category": "daily",
        "intent": "check_recycling_day",
        "courseUnitId": "a1_09_home_daily_life",
        "conceptIds": ["concept_a1_home_daily"],
        "grammarIds": ["grammar_a1_direction_time_particle"],
        "register": "polite",
        "speechStyle": "polite",
        "relationshipContext": "neighbors",
        "sidekick": "jieun",
        "emoji": "🗑️",
        "xpReward": 120,
        "backdrop": "home",
        "title": {
            "ko": "분리수거는 무슨 요일에",
            "de": "An welchem Tag kommt der Müll raus",
            "en": "Which day is recycling day",
        },
        "intro": {
            "ko": "박스를 들고 나갔는데 수거장이 비어 있습니다. 옆집 사람에게 요일을 물어봅니다.",
            "de": "Du stehst mit deinem Karton vor einer leeren Sammelstelle und fragst die Nachbarin.",
            "en": "You carry a box down to an empty collection point and ask your neighbor.",
        },
        "grammarBlock": {
            "title": {"ko": "N에", "de": "N에: Zeitangabe", "en": "N에: time marker"},
            "explanation": {
                "ko": "요일이나 시간 뒤에 에를 붙여 언제 하는 일인지 말한다. 수요일에, 저녁에처럼 쓴다.",
                "de": "에 hängt an Wochentage und Uhrzeiten und sagt, wann etwas passiert: 수요일에, 저녁에.",
                "en": "Attach 에 to a weekday or time to say when something happens: 수요일에, 저녁에.",
            },
        },
        "vocab": [
            {"korean": "분리수거"},
            {"korean": "요일"},
            {"korean": "박스"},
            {"korean": "수요일"},
            {"korean": "저녁"},
            {"korean": "버리다"},
        ],
        "dialog": [
            {"speaker": "user", "ko": "안녕하세요. 여기 박스 버려요?",
             "de": "Hallo. Kommen die Kartons hier hin?",
             "en": "Hi. Do the boxes go here?"},
            {"speaker": "jieun", "ko": "네, 맞아요. 그런데 오늘은 아니에요.",
             "de": "Ja, genau. Heute aber nicht.",
             "en": "Yes, right here. Just not today."},
            {"speaker": "user", "ko": "그럼 무슨 요일에 버려요?",
             "de": "An welchem Tag denn?",
             "en": "So which day do they go out?"},
            {"speaker": "jieun", "ko": "박스는 수요일에 나가요.",
             "de": "Kartons kommen mittwochs raus.",
             "en": "Boxes go out on Wednesdays."},
            {"speaker": "user", "ko": "몇 시에 놓으면 돼요?",
             "de": "Um welche Zeit soll ich sie rausstellen?",
             "en": "What time should I put them out?"},
            {"speaker": "jieun", "ko": "저녁에 놓으면 돼요.",
             "de": "Abends hinstellen reicht.",
             "en": "Putting them out in the evening is fine."},
            {"speaker": "user", "ko": "알았어요. 수요일 저녁에 올게요.",
             "de": "Gut, dann komme ich Mittwochabend.",
             "en": "Got it, I'll come Wednesday evening."},
            {"speaker": "jieun", "ko": "네, 그때 봐요.",
             "de": "Bis dann.",
             "en": "See you then."},
        ],
        "quests": [
            {
                "id": "quest_a1_daily_recycling_day_hear",
                "type": "hoerverstehen",
                "conceptIds": ["concept_a1_home_daily"],
                "data": {
                    "audioKo": "박스는 수요일에 나가요.",
                    "options": [
                        {"de": "Kartons kommen mittwochs raus.", "en": "Boxes go out on Wednesdays."},
                        {"de": "Kartons kommen samstags raus.", "en": "Boxes go out on Saturdays."},
                        {"de": "Kartons darf man nicht wegwerfen.", "en": "Boxes may not be thrown away."},
                        {"de": "Die Sammelstelle ist geschlossen.", "en": "The collection point is closed."},
                    ],
                    "correctIndex": 0,
                },
            },
            {
                "id": "quest_a1_daily_recycling_day_tr",
                "type": "uebersetzen",
                "conceptIds": ["concept_a1_home_daily"],
                "data": {
                    "promptDe": "An welchem Tag denn?",
                    "promptEn": "So which day do they go out?",
                    "options": [
                        {"ko": "그럼 무슨 요일에 버려요?"},
                        {"ko": "그럼 얼마예요?"},
                        {"ko": "여기가 어디예요?"},
                        {"ko": "이거 제 박스예요?"},
                    ],
                    "correctIndex": 0,
                },
            },
            {
                "id": "quest_a1_daily_recycling_day_gap",
                "type": "luecken",
                "conceptIds": ["concept_a1_home_daily"],
                "data": {
                    "sentence": "박스는 수요일___ 나가요.",
                    "options": ["에", "에서", "도", "만"],
                    "correctIndex": 0,
                },
            },
            {
                "id": "quest_a1_daily_recycling_day_build",
                "type": "satzBauen",
                "conceptIds": ["concept_a1_home_daily"],
                "data": {
                    "targetKo": "저녁에 놓으면 돼요.",
                    "promptDe": "Abends hinstellen reicht.",
                    "promptEn": "Putting them out in the evening is fine.",
                    "distractors": ["아침에", "박스를"],
                },
            },
            {
                "id": "quest_a1_daily_recycling_day_dict",
                "type": "diktat",
                "conceptIds": ["concept_a1_home_daily"],
                "data": {
                    "targetKo": "수요일 저녁에 올게요.",
                    "promptDe": "Ich komme Mittwochabend.",
                    "promptEn": "I'll come Wednesday evening.",
                },
            },
        ],
        "culturalNote": None,
        "fieldNotes": "rights: original; category=daily; unit=a1_09_home_daily_life; grammar=N에; answer=에",
    },
]
```

남은 A1 5칸의 소재:

| id | 대화가 끝내야 하는 일 |
| --- | --- |
| `a1_friends_major_and_number` | 수업 끝나고 이름·전공을 묻고 번호를 주고받는다 |
| `a1_dating_what_to_call_you` | 이름/오빠/씨 중 서로 부를 말을 정한다 |
| `a1_youtube_shorts_last_night` | 어제 본 쇼츠를 서로 봤는지/안 봤는지 확인한다 |
| `a1_gaming_one_more_round` | 한 판만 같이 하자고 요청하고 시간을 정한다 |
| `a1_kpop_my_bias` | 최애가 누구인지 소개하고 이유를 한 문장 덧붙인다 |

`a1_kpop_my_bias`의 `vocab`에는 `최애`를 넣고 `note{ko,de,en}`로 뜻을 준다.

- [ ] **Step 4: 빌더를 쓴다**

`tools/content_factory/build_batch_11_scenarios.py`:

```python
#!/usr/bin/env python3
"""Emit review-only Batch 11 scenario drafts: daily, friends, dating, youtube, gaming, kpop.

Preview only. This script never writes assets/data or lib.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from data.batch_11_scene_scripts import SCENES

ROOT = SCRIPT_DIR.parents[1]
DRAFT_PATH = Path("tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json")
MANIFEST_PATH = Path("tools/content_factory/drafts/batch_11_manifest.json")
REVIEW_PATH = Path("tools/content_factory/review/c1_batch11_scenarios.csv")
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
QUEST_SUFFIXES = ("hear", "tr", "gap", "build", "dict")
LEVEL_ORDER = ("a1", "a2", "b1", "b2", "c1", "c2")
CATEGORY_ORDER = ("daily", "friends", "dating", "youtube", "gaming", "kpop")

LEVEL_GRAMMAR_ALLOWLIST: dict[str, frozenset[str]] = {
    "a1": frozenset({
        "grammar_a1_direction_time_particle", "grammar_a1_which_question", "grammar_a1_want",
        "grammar_a1_short_negation", "grammar_a1_polite_past", "grammar_a1_object_particle",
        "grammar_a1_polite_request", "grammar_a1_copula_polite",
    }),
    "a2": frozenset({
        "grammar_a2_probability", "grammar_a2_polite_proposal", "grammar_a2_noun_cause",
        "grammar_a2_exclamation", "grammar_a2_recommendation", "grammar_a2_ability",
        "grammar_a2_gentle_question",
    }),
    "b1": frozenset({
        "grammar_b1_decision", "grammar_b1_indirect_speech", "grammar_b1_wish",
        "grammar_b1_negative_cause", "grammar_b1_experience", "grammar_b1_background_contrast",
        "grammar_b1_soft_request",
    }),
    "b2": frozenset({
        "grammar_b2_formal_arrangement", "grammar_b2_explicit_formal_request",
        "grammar_b2_not_automatic_conclusion", "grammar_b2_as_long_as",
        "grammar_b2_instead_tradeoff", "grammar_b2_formal_intention",
        "grammar_b2_formal_reason", "grammar_b2_shared_merit",
    }),
    "c1": frozenset({
        "grammar_c1_taking_into_account", "grammar_c1_room_for", "grammar_c1_unless_condition",
        "grammar_c1_two_sides", "grammar_c1_even_at_cost", "grammar_c1_given_situation",
    }),
    "c2": frozenset({
        "grammar_c2_even_assuming", "grammar_c2_on_the_premise", "grammar_c2_nothing_more_than",
        "grammar_c2_defined_as", "grammar_c2_regardless_of_kin", "grammar_c2_even_if_concession",
    }),
}

SCENARIO_KEYS = (
    "id", "level", "emoji", "register", "speechStyle", "relationshipContext", "intent",
    "courseUnitId", "conceptIds", "surfaceFormIds", "sidekick", "xpReward",
    "title", "intro", "vocab", "grammarIds", "grammarBlock", "dialog", "quests",
)


def _sort_key(scene: dict[str, Any]) -> tuple[int, int]:
    return LEVEL_ORDER.index(scene["level"]), CATEGORY_ORDER.index(scene["category"])


def _to_record(scene: dict[str, Any]) -> dict[str, Any]:
    record: dict[str, Any] = {}
    for key in SCENARIO_KEYS:
        record[key] = [] if key == "surfaceFormIds" else scene[key]
    if scene.get("culturalNote"):
        record["culturalNote"] = scene["culturalNote"]
    return record


def build(root: Path = ROOT) -> dict[str, int]:
    scenes = sorted(SCENES, key=_sort_key)
    records = [_to_record(scene) for scene in scenes]
    quests = [quest for record in records for quest in record["quests"]]

    levels: dict[str, int] = {}
    for record in records:
        levels[record["level"]] = levels.get(record["level"], 0) + 1

    draft = {
        "version": 1,
        "_comment": "Review-only Batch 11 scenarios. Six categories per CEFR level.",
        "scenarios": records,
    }
    manifest = {
        "version": 1,
        "batch": "11",
        "status": "review_only_draft",
        "provenance": {
            "scope": "Original everyday, friendship, dating, video, gaming and fandom episodes for A1-C2.",
            "rights": "original",
            "requiresJinReview": True,
            "originalPlan": "docs/superpowers/specs/2026-08-17-scenario-level-category-batch11-design.md",
        },
        "artifacts": [
            {
                "kind": "scenario",
                "draft": DRAFT_PATH.as_posix(),
                "review": REVIEW_PATH.as_posix(),
                "collection": "scenarios",
                "count": len(records),
                "levels": levels,
            }
        ],
        "recordCount": len(records),
        "questCount": len(quests),
        "contentLinks": [
            {
                "contentKind": "scenario",
                "contentId": record["id"],
                "courseUnitId": record["courseUnitId"],
                "conceptIds": list(record["conceptIds"]),
                "role": "practice",
            }
            for record in records
        ],
        "backdrops": {scene["id"]: scene["backdrop"] for scene in scenes},
        "nonMergeGuards": [
            "Jin approval required before --apply",
            "no TTS synthesis or Firebase writes",
            "no assets/data or lib edits from this batch",
        ],
    }

    (root / DRAFT_PATH).write_text(
        json.dumps(draft, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    (root / MANIFEST_PATH).write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    with (root / REVIEW_PATH).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        for scene, record in zip(scenes, records):
            writer.writerow({
                "id": record["id"],
                "level": record["level"].upper(),
                "ko": record["title"]["ko"],
                "de": record["title"]["de"],
                "en": record["title"]["en"],
                "field_notes": scene["fieldNotes"],
                "상태": "draft",
                "jin_memo": "",
            })
    return {"scenarios": len(records), "quests": len(quests)}


def main() -> int:
    counts = build()
    print(f"OK: staged {counts['scenarios']} scenarios and {counts['quests']} quests (review-only)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

`tools/content_factory/data/`에서 `from data.batch_11_scene_scripts import SCENES`가 실패하면
Batch 10이 쓰는 import 형태를 그대로 확인해 맞춘다. `data/__init__.py`가 필요하면 빈 파일로 추가한다.

- [ ] **Step 5: 빌더를 실행한다**

Run: `python tools/content_factory/build_batch_11_scenarios.py`
Expected: `OK: staged 6 scenarios and 30 quests (review-only)`

- [ ] **Step 6: 계약 테스트를 통과시킨다**

Run: `python tools/content_factory/test_build_batch_11_scenarios.py -v`
Expected: PASS (전 케이스). 실패하면 장면 원문을 고치고 Step 5부터 다시.

- [ ] **Step 7: 통합 preview로 전체 그래프를 검증한다**

Run: `python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json`
Expected: `OK: preview 6 records; inventory {...}` — `--apply` 없이. 실패 메시지는 어느 계약이 깨졌는지 알려주므로 그 필드만 고친다.

- [ ] **Step 8: A1 6개 전문을 읽고 품질 6항목을 확인한다**

스펙 §10의 6항목(획일 intent·셸 문구·삼언어 등가·레벨 상한·문장 반복·AI 티)을 눈으로 확인한다. 커밋하지 않는다.

---

## Task 2: A2 6개

**Files:**
- Modify: `tools/content_factory/data/batch_11_scene_scripts.py` (SCENES에 6개 추가)
- Generated: draft/manifest/review 재생성

**Interfaces:**
- Consumes: `SCENES`, `builder.build()`, `builder.LEVEL_GRAMMAR_ALLOWLIST["a2"]`
- Produces: 없음(데이터만 증가)

- [ ] **Step 1: A2 6칸을 확정표대로 추가한다**

metadata는 확정표 A2 행을 그대로 쓴다. 소재:

| id | 대화가 끝내야 하는 일 |
| --- | --- |
| `a2_daily_late_delivery` | 배달이 늦은 이유를 묻고 대안(환불/재배송)을 하나 정한다 |
| `a2_friends_weekend_slot` | 서로 다른 일정에서 겹치는 한 칸을 찾아 약속을 확정한다 |
| `a2_dating_slow_replies` | 답장이 느려 서운했던 일을 비난 없이 말하고 규칙 하나를 합의한다 |
| `a2_youtube_send_the_link` | 링크를 보내고 왜 웃긴지 설명해 상대가 보게 만든다 |
| `a2_gaming_cant_connect` | 접속이 안 되는 원인을 좁혀 해결하고 다시 만날 시간을 정한다 |
| `a2_kpop_concert_queue` | 콘서트 대기줄에서 처음 본 팬과 해요체로 굿즈·입장 정보를 나눈다 |

`xpReward`는 140, 퀘스트 ID 접미어는 `hear/tr/gap/build/dict` 순서를 지킨다.
`a2_kpop_concert_queue`의 `culturalNote`에 대기줄·번호표 문화를 한 문단으로 넣는다.

- [ ] **Step 2: 빌더 실행**

Run: `python tools/content_factory/build_batch_11_scenarios.py`
Expected: `OK: staged 12 scenarios and 60 quests (review-only)`

- [ ] **Step 3: 계약 테스트**

Run: `python tools/content_factory/test_build_batch_11_scenarios.py -v`
Expected: PASS

- [ ] **Step 4: preview 검증**

Run: `python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json`
Expected: `OK: preview 12 records; ...`

- [ ] **Step 5: A2 6개 전문 품질 확인 (스펙 §10 6항목)**

---

## Task 3: B1 6개

**Files:**
- Modify: `tools/content_factory/data/batch_11_scene_scripts.py`

**Interfaces:**
- Consumes: `SCENES`, `builder.build()`, `builder.LEVEL_GRAMMAR_ALLOWLIST["b1"]`

- [ ] **Step 1: B1 6칸을 확정표대로 추가한다**

| id | 대화가 끝내야 하는 일 |
| --- | --- |
| `b1_daily_cut_the_bills` | 다음 달 고정비를 줄일 항목 두 개를 정해 실행을 약속한다 |
| `b1_friends_he_said_that` | 전해 들은 말의 원래 맥락을 확인해 오해를 되돌린다 |
| `b1_dating_anniversary_gap` | 기념일 기대가 어긋난 이유를 말하고 다음 방식을 함께 정한다 |
| `b1_youtube_up_all_night` | 영상 보느라 밤샌 경험을 이유와 함께 설명하고 습관을 조정한다 |
| `b1_gaming_team_voice` | 팀원의 플레이를 완곡하게 지적하고 다음 판 역할을 나눈다 |
| `b1_kpop_missing_goods` | 굿즈 누락을 알리고 교환/재발송 중 하나를 확정한다 |

`b1_dating_anniversary_gap`은 `intimate` 반말이고 존대가 섞이지 않는다.
`b1_kpop_missing_goods`만 `polite`이며 상대가 판매자다.

- [ ] **Step 2: 빌더 실행**

Run: `python tools/content_factory/build_batch_11_scenarios.py`
Expected: `OK: staged 18 scenarios and 90 quests (review-only)`

- [ ] **Step 3: 계약 테스트**

Run: `python tools/content_factory/test_build_batch_11_scenarios.py -v`
Expected: PASS

- [ ] **Step 4: preview 검증**

Run: `python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json`
Expected: `OK: preview 18 records; ...`

- [ ] **Step 5: B1 6개 전문 품질 확인 (스펙 §10 6항목)**

---

## Task 4: B2 6개

**Files:**
- Modify: `tools/content_factory/data/batch_11_scene_scripts.py`

**Interfaces:**
- Consumes: `SCENES`, `builder.build()`, `builder.LEVEL_GRAMMAR_ALLOWLIST["b2"]`

- [ ] **Step 1: B2 6칸을 확정표대로 추가한다**

| id | 대화가 끝내야 하는 일 |
| --- | --- |
| `b2_daily_upstairs_noise` | 반복된 층간 소음에 대해 구체적 재발 방지책과 기한을 받아낸다 |
| `b2_friends_split_the_bill` | 회비 분담 방식의 근거를 대며 논쟁하고 한 방식으로 합의한다 |
| `b2_dating_moving_in_terms` | 동거 조건(비용·공간·거리)을 조건절로 협의한다 |
| `b2_youtube_collab_pitch` | 협업 목적·분량·일정을 갖춘 첫 제안을 공식 톤으로 연다 |
| `b2_gaming_ban_appeal` | 제재 근거를 확인하고 서면 재심 절차를 요청한다 |
| `b2_kpop_staff_interview` | 팬 커뮤니티 운영 경험을 근거로 지원 동기를 설명한다 |

`business` 칸(`youtube`/`gaming`/`kpop`)은 문어적 요청 형태를 쓰되 실제 화자가 쓰지 않는 공문체 나열은 피한다.

- [ ] **Step 2: 빌더 실행**

Run: `python tools/content_factory/build_batch_11_scenarios.py`
Expected: `OK: staged 24 scenarios and 120 quests (review-only)`

- [ ] **Step 3: 계약 테스트**

Run: `python tools/content_factory/test_build_batch_11_scenarios.py -v`
Expected: PASS

- [ ] **Step 4: preview 검증**

Run: `python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json`
Expected: `OK: preview 24 records; ...`

- [ ] **Step 5: B2 6개 전문 품질 확인 (스펙 §10 6항목)**

---

## Task 5: C1 6개

**Files:**
- Modify: `tools/content_factory/data/batch_11_scene_scripts.py`

**Interfaces:**
- Consumes: `SCENES`, `builder.build()`, `builder.LEVEL_GRAMMAR_ALLOWLIST["c1"]`

- [ ] **Step 1: C1 6칸을 확정표대로 추가한다**

C1은 유닛이 `c1_01_evidence_public_reasoning`과 `c1_02_inclusive_sustainable_systems` 둘뿐이므로 소재를 담론 층위로 올린다.

| id | 대화가 끝내야 하는 일 |
| --- | --- |
| `c1_daily_prices_vs_data` | 체감 물가와 통계의 간극을 근거의 한계까지 밝혀 설명한다 |
| `c1_friends_venue_access` | 모임 장소의 접근성 장벽을 제기하고 대안 절차를 제안한다 |
| `c1_dating_app_safety` | 데이팅앱 신고·차단 절차를 안전과 표현 사이에서 설계한다 |
| `c1_youtube_health_claims` | 조회수 높은 건강 주장의 근거가 어디까지 말할 수 있는지 한정한다 |
| `c1_gaming_playtime_policy` | 이용시간 자료로 규제안의 효과와 부작용을 함께 검토한다 |
| `c1_kpop_fan_labor` | 무보수 팬 노동의 지속 가능성을 문제로 세우고 조정안을 낸다 |

결론을 근거보다 강하게 단정하지 않는다. 각 대화는 불확실성을 한 번 이상 명시한다.

- [ ] **Step 2: 빌더 실행**

Run: `python tools/content_factory/build_batch_11_scenarios.py`
Expected: `OK: staged 30 scenarios and 150 quests (review-only)`

- [ ] **Step 3: 계약 테스트**

Run: `python tools/content_factory/test_build_batch_11_scenarios.py -v`
Expected: PASS

- [ ] **Step 4: preview 검증**

Run: `python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json`
Expected: `OK: preview 30 records; ...`

- [ ] **Step 5: C1 6개 전문 품질 확인 (스펙 §10 6항목)**

---

## Task 6: C2 6개

**Files:**
- Modify: `tools/content_factory/data/batch_11_scene_scripts.py`

**Interfaces:**
- Consumes: `SCENES`, `builder.build()`, `builder.LEVEL_GRAMMAR_ALLOWLIST["c2"]`

- [ ] **Step 1: C2 6칸을 확정표대로 추가한다**

| id | 대화가 끝내야 하는 일 |
| --- | --- |
| `c2_daily_automation_redress` | 생활 자동화 오작동의 구제 경로가 형식에 불과하지 않게 만든다 |
| `c2_friends_quoted_privately` | 사적 대화가 공적으로 인용될 때의 경계를 정의한다 |
| `c2_dating_romance_frames` | 연애 서사가 만드는 관점의 편향을 관계와 무관하게 분리해 본다 |
| `c2_youtube_algorithm_duty` | 추천 결과의 책임이 누구에게 어디까지 있는지 가정법으로 따진다 |
| `c2_gaming_auto_sanction` | 자동 제재의 전제를 드러내고 이의 절차의 설계 조건을 요구한다 |
| `c2_kpop_fandom_language` | 팬덤 언어가 만드는 담론 권력을 양보 구문으로 반박한다 |

과장된 학술체를 쓰지 않는다. 실제 토론자가 말하는 길이와 리듬을 유지한다.

- [ ] **Step 2: 빌더 실행**

Run: `python tools/content_factory/build_batch_11_scenarios.py`
Expected: `OK: staged 36 scenarios and 180 quests (review-only)`

- [ ] **Step 3: 계약 테스트**

Run: `python tools/content_factory/test_build_batch_11_scenarios.py -v`
Expected: PASS — 이 시점에 `test_authored_levels_have_six_categories_each`가 6레벨 전부를 검사한다.

- [ ] **Step 4: preview 검증**

Run: `python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json`
Expected: `OK: preview 36 records; ...`

- [ ] **Step 5: C2 6개 전문 품질 확인 (스펙 §10 6항목)**

---

## Task 7: humanizer 통과·검수 패킷·기록

**Files:**
- Modify: `tools/content_factory/data/batch_11_scene_scripts.py` (문구 교정)
- Create: `tools/content_factory/review/batch_11_review_packet.md`
- Modify: `docs/SESSION_LOG.md`

**Interfaces:**
- Consumes: 완성된 36개 `SCENES`
- Produces: Jin이 읽을 검수 패킷 한 개

- [ ] **Step 1: humanizer 스킬로 DE/EN 전체를 훑는다**

`humanizer` 스킬을 호출해 36×8턴의 DE/EN과 `intro`/`grammarBlock`/`culturalNote`를 검사한다.
고치는 대상: 과장 수식, 3항 나열, 불필요한 수동태, `In der heutigen Welt` 류 상투구,
em dash 남용, 원문에 없는 정보 추가. 한국어 원문의 뜻·존대·화행은 바꾸지 않는다.

- [ ] **Step 2: 셸 문구·중복 스캔을 코드로 한 번 더 돌린다**

Run:
```bash
python -c "import sys; sys.path.insert(0,'tools/content_factory'); from data.batch_11_scene_scripts import SCENES; import collections; ko=[t['ko'] for s in SCENES for t in s['dialog']]; dup=[k for k,v in collections.Counter(ko).items() if v>1]; print('total',len(ko)); print('cross-scenario duplicate KO lines:',dup)"
```
Expected: `total 288`. 중복 목록이 비어 있거나 인사말 수준의 정당한 반복만 남는다. 정당하지 않은 중복은 고친다.

- [ ] **Step 3: 빌더·테스트·preview를 마지막으로 함께 돌린다**

Run:
```bash
python tools/content_factory/build_batch_11_scenarios.py
python tools/content_factory/test_build_batch_11_scenarios.py -v
python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json
python tools/content_factory/validate_content.py
```
Expected: 네 명령 모두 성공. `validate_content.py`는 live 자산을 검사하므로 이 batch가 live를 건드리지 않았음을 함께 확인한다.

- [ ] **Step 4: 검수 패킷을 만든다**

Run: `python tools/content_factory/render_review_packet.py --manifest tools/content_factory/drafts/batch_11_manifest.json --output tools/content_factory/review/batch_11_review_packet.md`
Expected: 36개 레코드가 든 Markdown 생성. 이 스크립트가 scenario kind를 지원하지 않으면 실패 메시지를 그대로 보고하고, 패킷 대신 draft JSON 경로를 Jin에게 안내한다(도구를 수정하지 않는다).

- [ ] **Step 5: `docs/SESSION_LOG.md` 최상단에 기록한다**

형식은 기존 항목을 따르고 다음을 담는다: 무엇을(Batch 11 시나리오 36개 review-only 초안,
6레벨×6카테고리), 왜(유튜브·게임·덕질·데이트 소재 공백과 레벨 편중), 검증(계약 테스트,
preview 36 records, validate_content), 금지(미승인이라 `--apply`·TTS·Firebase 없음),
브랜치명 `claude/scenario-batch11-20260817`. 커밋 해시는 Jin이 커밋을 요청한 뒤 채운다.

- [ ] **Step 6: Jin에게 승인 요청 항목을 정리해 보고한다**

보고에 포함할 것: 36개 ID 목록(레벨×카테고리 표), 검증 결과, review CSV 경로,
승인 후 병합 절차(`--apply`가 `scenarios.json`·`curriculum_manifest.json`·
`ScenarioBackdrop._categoryById`를 원자적으로 갱신), TTS는 별도 승인이 필요하다는 사실.

---

## Self-Review

**1. Spec coverage**

| 스펙 항목 | 담당 |
| --- | --- |
| §2 확정 결정(36개·6카테고리·데이터 taxonomy·humanizer) | Global Constraints, Task 1–7 |
| §4 카테고리 정의 | 36칸 확정표의 `cat` |
| §5 36칸 배치(유닛·개념·상황·말투·backdrop) | 확정표 + Task 1–6 Step 1 |
| §6 레벨 계약(문법 상한) | `LEVEL_GRAMMAR_ALLOWLIST` + `test_grammar_ids_exist_and_match_level` |
| §7 시나리오 계약(8턴·5퀘스트·6단어·xp·enum·ID 규칙) | Task 1 테스트 케이스 |
| §8 산출물 5개 파일 | File Structure + 빌더 |
| §9 검증·금지 | Task 1 Step 7, Task 7 Step 3, Global Constraints |
| §10 품질 게이트 6항목 | 각 Task 마지막 Step + Task 7 Step 1–2 |
| §11 위험(C1/C2 유닛 2개, 병행 세션, 총합 불균형) | Task 5·6 Step 1 주의문, Global Constraints |

**2. 스펙 정정 반영:** 스펙 §9는 검증 명령으로 `validate_review_batch.py --manifest`를 적었지만
그 도구에는 scenario 처리가 없다. 실제 경로는 `integrate_scenario_batch.py --manifest`(`--apply` 없이 preview)다.
이 계획은 정정된 명령을 쓰며, 스펙 §9도 같은 값으로 고친다.

**3. Placeholder scan:** `TBD`/`TODO` 없음. 각 Task의 콘텐츠 단계는 소재 표로 "무엇을 끝내야 하는지"를
지정하고, 스키마·metadata는 확정표와 Task 1의 완성 예시가 제공한다.

**4. Type consistency:** `QUEST_SUFFIXES`, `LEVEL_GRAMMAR_ALLOWLIST`, `build()`, `SCENES`의
이름과 키가 테스트·빌더·후속 Task에서 동일하다. review projection은 `title.{ko,de,en}`로 일관된다.
퀘스트 ID는 전 Task에서 `quest_<scenario_id>_<suffix>` 한 형태만 쓴다.
