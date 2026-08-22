#!/usr/bin/env python3
"""Contract tests for the generated Living Hanok V1 grant catalog."""

from __future__ import annotations

import copy
import importlib.util
import json
import subprocess
import sys
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = Path(__file__).with_name("build_hanok_grants.py")
SPEC = importlib.util.spec_from_file_location("build_hanok_grants", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot import {MODULE_PATH}")
builder = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = builder
SPEC.loader.exec_module(builder)


class HanokGrantGeneratorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = json.loads(builder.SEGMENTS_PATH.read_text(encoding="utf-8"))
        cls.payload = builder.build()

    def test_generated_file_is_byte_exact_and_check_mode_passes(self) -> None:
        self.assertEqual(
            builder._encoded(self.payload),
            builder.OUTPUT_PATH.read_text(encoding="utf-8"),
        )
        subprocess.run(
            [sys.executable, str(MODULE_PATH), "--check"],
            cwd=ROOT,
            check=True,
        )

    def test_every_additive_denominator_slot_has_one_grant(self) -> None:
        grants = self.payload["grants"]
        expected = builder._denominator_segment_ids(self.source)
        self.assertEqual(86, len(grants))
        self.assertEqual(expected, {row["canDoSegmentId"] for row in grants})
        self.assertEqual(86, len({row["id"] for row in grants}))
        self.assertEqual(
            {"a1": 16, "a2": 16, "b1": 18, "b2": 20, "c1": 8, "c2": 8},
            dict(Counter(row["level"] for row in grants)),
        )

    def test_a1_has_the_exact_sixteen_construction_states(self) -> None:
        a1 = [row for row in self.payload["grants"] if row["level"] == "a1"]
        self.assertEqual(
            [
                f"hanok_a1_{index:02d}_{suffix}"
                for index, suffix in enumerate(builder.A1_REWARDS, start=1)
            ],
            [row["id"] for row in a1],
        )
        self.assertEqual(
            [
                [f"hanok_a1_state_{index:02d}_{suffix}"]
                for index, suffix in enumerate(builder.A1_REWARDS, start=1)
            ],
            [row["revealAssetIds"] for row in a1],
        )
        self.assertEqual({"constructionPiece"}, {row["kind"] for row in a1})
        self.assertEqual([], a1[0]["prerequisiteGrantIds"])
        for index in range(1, len(a1)):
            self.assertEqual(
                [a1[index - 1]["id"]],
                a1[index]["prerequisiteGrantIds"],
            )

        productive = json.loads(
            (
                ROOT
                / "tools"
                / "content_factory"
                / "drafts"
                / "productive_assessments.json"
            ).read_text(encoding="utf-8")
        )
        definitions = {
            row["canDoSegmentId"]: row
            for row in productive["definitions"]
            if row["level"] == "a1"
        }
        previous_assessment_id = None
        for row in a1:
            definition = definitions[row["canDoSegmentId"]]
            self.assertEqual(
                [] if previous_assessment_id is None else [previous_assessment_id],
                definition["prerequisiteAssessmentItemIds"],
            )
            previous_assessment_id = definition["assessmentItemId"]

    def test_replacement_tracks_never_create_new_reward_slots(self) -> None:
        source = copy.deepcopy(self.source)
        source["trackEditions"].append(
            {
                "id": "edition_replacement_future_v1",
                "status": "published",
                "segmentIds": ["segment_future_replacement"],
            }
        )
        source["releaseTracks"].append(
            {
                "id": "replacement_future_v1",
                "kind": "replacement",
                "status": "published",
                "editionIds": ["edition_replacement_future_v1"],
            }
        )
        self.assertNotIn(
            "segment_future_replacement",
            builder._denominator_segment_ids(source),
        )

    def test_new_additive_slot_requires_and_accepts_an_authored_grant(self) -> None:
        source = copy.deepcopy(self.source)
        source["segments"].append(
            {
                "id": "segment_a1_future_extension",
                "level": "a1",
                "order": 17,
            }
        )
        source["trackEditions"].append(
            {
                "id": "edition_a1_future_extension_v1",
                "status": "published",
                "segmentIds": ["segment_a1_future_extension"],
            }
        )
        source["releaseTracks"].append(
            {
                "id": "a1_future_extension_v1",
                "kind": "extension",
                "status": "published",
                "editionIds": ["edition_a1_future_extension_v1"],
            }
        )
        with self.assertRaisesRegex(ValueError, "coverage mismatch"):
            builder._validate_candidate(
                source,
                copy.deepcopy(self.payload),
                {"schemaVersion": 1, "publishedGrants": []},
            )

        candidate = copy.deepcopy(self.payload)
        candidate["grants"].insert(
            16,
            {
                "id": "hanok_a1_extension_01_neighbor_welcome",
                "canDoSegmentId": "segment_a1_future_extension",
                "level": "a1",
                "era": "build",
                "order": 17,
                "kind": "ambience",
                "revealAssetIds": ["hanok_a1_extension_01_neighbor_welcome"],
                "prerequisiteGrantIds": ["hanok_a1_16_landscape_move_in"],
                "userDescriptionKey": "hanokGrant_a1_extension_01_neighbor_welcome",
            },
        )
        self.assertIs(
            candidate,
            builder._validate_candidate(
                source,
                candidate,
                {"schemaVersion": 1, "publishedGrants": []},
            ),
        )

    def test_release_ledger_blocks_rewrite_or_deletion(self) -> None:
        published = copy.deepcopy(self.payload["grants"][0])
        ledger = {"schemaVersion": 1, "publishedGrants": [published]}
        builder._validate_published_ledger(self.payload, ledger)

        changed = copy.deepcopy(self.payload)
        changed["grants"][0]["userDescriptionKey"] = "rewritten"
        with self.assertRaisesRegex(ValueError, "changed or disappeared"):
            builder._validate_published_ledger(changed, ledger)

        deleted = copy.deepcopy(self.payload)
        deleted["grants"].pop(0)
        with self.assertRaisesRegex(ValueError, "changed or disappeared"):
            builder._validate_published_ledger(deleted, ledger)

    def test_release_ledger_history_allows_only_exact_tail_append(self) -> None:
        first = copy.deepcopy(self.payload["grants"][0])
        second = copy.deepcopy(self.payload["grants"][1])
        previous = {"schemaVersion": 1, "publishedGrants": [first]}
        builder._validate_ledger_evolution(
            {"schemaVersion": 1, "publishedGrants": [first, second]},
            previous,
        )

        with self.assertRaisesRegex(ValueError, "not append-only"):
            builder._validate_ledger_evolution(
                {"schemaVersion": 1, "publishedGrants": []},
                previous,
            )
        changed = copy.deepcopy(first)
        changed["userDescriptionKey"] = "rewritten"
        with self.assertRaisesRegex(ValueError, "not append-only"):
            builder._validate_ledger_evolution(
                {"schemaVersion": 1, "publishedGrants": [changed]},
                previous,
            )

    def test_check_mode_verifies_the_git_baseline(self) -> None:
        subprocess.run(
            [
                sys.executable,
                str(MODULE_PATH),
                "--check",
                "--verify-git-history",
                "--base-revision",
                "HEAD",
            ],
            cwd=ROOT,
            check=True,
        )

    def test_draft_is_not_a_runtime_asset_and_inputs_are_explicit(self) -> None:
        self.assertFalse((ROOT / "assets" / "data" / "hanok_grants.json").exists())
        path_constants = {
            name: value
            for name, value in vars(builder).items()
            if name.endswith("_PATH") and isinstance(value, Path)
        }
        self.assertEqual(
            {
                "SEGMENTS_PATH": ROOT / "assets" / "data" / "can_do_segments.json",
                "OUTPUT_PATH": (
                    ROOT
                    / "tools"
                    / "content_factory"
                    / "drafts"
                    / "hanok_grants.json"
                ),
                "MASTERPLAN_PATH": (
                    ROOT
                    / "tools"
                    / "content_factory"
                    / "drafts"
                    / "estate_masterplan_v2.json"
                ),
                "REMAPPING_PATH": (
                    ROOT
                    / "tools"
                    / "content_factory"
                    / "drafts"
                    / "hanok_grant_remapping_v2.json"
                ),
                "LEDGER_PATH": (
                    ROOT
                    / "tools"
                    / "content_factory"
                    / "release_ledgers"
                    / "hanok_grants_v1.json"
                ),
            },
            path_constants,
        )


if __name__ == "__main__":
    unittest.main()
