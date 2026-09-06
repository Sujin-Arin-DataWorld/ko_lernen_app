"""Contract tests for the canonical scenario-art generation manifest."""

from __future__ import annotations

import hashlib
import re
import sys
import tempfile
import unittest
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_scene_art_manifest  # noqa: E402


class SceneArtManifestTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = build_scene_art_manifest.build_manifest(
            build_scene_art_manifest.ROOT
        )
        cls.entries = cls.manifest["entries"]
        cls.family = build_scene_art_manifest._load_scene_style_family(
            build_scene_art_manifest.ROOT
        )

    def test_exact_178_rows_and_fixed_category_counts(self) -> None:
        self.assertEqual(self.manifest["scenarioCount"], 178)
        self.assertEqual(len(self.entries), 178)
        self.assertEqual(
            self.manifest["categoryOrder"],
            [
                "office",
                "home",
                "cafe",
                "station",
                "market",
                "convenience",
                "restaurant",
                "pharmacy",
                "directions",
                "hotel",
                "taxi",
                "airport",
                "bank",
                "salon",
                "theme_park",
            ],
        )
        expected = {
            "office": 57,
            "home": 56,
            "cafe": 16,
            "station": 9,
            "market": 7,
            "theme_park": 6,
            "convenience": 1,
            "restaurant": 8,
            "pharmacy": 3,
            "directions": 7,
            "hotel": 1,
            "taxi": 3,
            "airport": 2,
            "bank": 1,
            "salon": 1,
        }
        self.assertEqual(self.manifest["categoryCounts"], expected)
        self.assertEqual(Counter(row["category"] for row in self.entries), Counter(expected))

    def test_ids_paths_and_priority_order_are_unique_and_canonical(self) -> None:
        ids = [row["id"] for row in self.entries]
        paths = [row["targetPath"] for row in self.entries]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len(paths), len(set(paths)))
        self.assertEqual(
            paths,
            [
                f"assets_unused/pending_review/scenes/{row['id']}.png"
                for row in self.entries
            ],
        )
        expected_sort = sorted(
            self.entries,
            key=lambda row: (
                build_scene_art_manifest.CATEGORY_ORDER.index(row["category"]),
                build_scene_art_manifest.LEVEL_ORDER.index(row["level"]),
                row["id"],
            ),
        )
        self.assertEqual(self.entries, expected_sort)
        self.assertEqual(
            [row["priorityOrder"] for row in self.entries],
            list(range(1, 179)),
        )

    def test_generated_from_hashes_match_canonical_sources(self) -> None:
        generated_from = self.manifest["generatedFrom"]
        self.assertEqual(
            set(generated_from),
            {
                "assets/data/scenarios_a1.json",
                "assets/data/scenarios_a2.json",
                "assets/data/scenarios_b1.json",
                "assets/data/scenarios_b2.json",
                "assets/data/scenarios_c1.json",
                "assets/data/scenarios_c2.json",
            },
        )
        for relative, digest in generated_from.items():
            actual = hashlib.sha256(
                (build_scene_art_manifest.ROOT / relative).read_bytes()
            ).hexdigest()
            self.assertEqual(digest, actual)
        for row in self.entries:
            self.assertEqual(
                row["sourceSha256"],
                generated_from[f"assets/data/{row['sourceShard']}"],
            )

    def test_style_contract_is_the_scene_only_style_lock_family(self) -> None:
        contract = self.manifest["styleContract"]
        self.assertEqual(
            contract["identifier"],
            "scene-poster/faceted-heritage-2.5d-v1",
        )
        self.assertEqual(contract["family"], "F-E-scene-poster")
        self.assertEqual(contract["path"], "docs/assets/STYLE_LOCK.json")
        self.assertEqual(
            contract["sha256"],
            hashlib.sha256(
                (build_scene_art_manifest.ROOT / contract["path"]).read_bytes()
            ).hexdigest(),
        )
        self.assertEqual(
            contract["scope"]["runtimeRoot"],
            "assets/illustrations/scenes/",
        )
        self.assertEqual(
            contract["scope"]["reviewRoot"],
            "assets_unused/pending_review/scenes/",
        )
        self.assertEqual(contract["canonicalOutput"]["aspectRatio"], "3:2")
        self.assertEqual(
            (
                contract["canonicalOutput"]["width"],
                contract["canonicalOutput"]["height"],
            ),
            (1536, 1024),
        )
        self.assertEqual(contract["approvedAnchors"], self.family["anchors"])

    def test_every_prompt_has_nonempty_korean_semantic_anchor_and_contract(self) -> None:
        korean = re.compile(r"[가-힣]")
        prompts_by_category: dict[str, list[str]] = defaultdict(list)
        for row in self.entries:
            with self.subTest(scenario=row["id"]):
                self.assertRegex(row["semanticSummaryKo"], korean)
                self.assertIn(row["semanticSummaryKo"], row["prompt"])
                self.assertTrue(row["requiredSettingKo"])
                self.assertTrue(row["requiredParticipants"])
                self.assertTrue(row["requiredPropsKo"])
                self.assertEqual(
                    row["forbiddenTextAndLogos"],
                    [
                        "readable text",
                        "letters or digits",
                        "Hangul or Hanja glyphs",
                        "signs",
                        "prices",
                        "brand logos",
                        "watermarks",
                        "UI chrome",
                    ],
                )
                self.assertEqual(
                    row["styleReferenceIdentifiers"],
                    [
                        "scene-poster/faceted-heritage-2.5d-v1",
                        f"approved-scene-anchor/{Path(row['referenceImagePath']).stem}",
                    ],
                )
                self.assertEqual(
                    row["referenceImagePath"],
                    self.family["approvedAnchorByCategory"][row["category"]],
                )
                self.assertIn(row["referenceImagePath"], self.family["anchors"])
                self.assertTrue(
                    (build_scene_art_manifest.ROOT / row["referenceImagePath"]).is_file()
                )
                self.assertEqual(row["prompt"].count(row["referenceImagePath"]), 1)
                self.assertIn(
                    "scene-poster/faceted-heritage-2.5d-v1",
                    row["prompt"],
                )
                self.assertIn("1536x1024 PNG", row["prompt"])
                self.assertIn("triangular facets", row["prompt"])
                self.assertIn("central 60% width and 65% height", row["prompt"])
                self.assertIn("56px", row["prompt"])
                self.assertNotIn("Faceted Minhwa v2", row["prompt"])
                self.assertNotIn(
                    "canonicalOutput",
                    row,
                    "canonical output belongs only to the manifest style contract",
                )
                prompts_by_category[row["category"]].append(row["prompt"])
        for category, prompts in prompts_by_category.items():
            self.assertEqual(
                len(prompts),
                len(set(prompts)),
                f"{category} contains byte-identical prompts",
            )

    def test_generation_rows_begin_truthfully_not_generated(self) -> None:
        for row in self.entries:
            generation = row["generation"]
            self.assertEqual(generation["status"], "not_generated")
            self.assertIsNone(generation["generatorResultId"])
            self.assertIsNone(generation["normalizedSha256"])
            self.assertIsNone(generation["dimensions"])
            self.assertEqual(generation["automatedIssues"], [])
            self.assertEqual(generation["visualReview"], "not_started")
            self.assertEqual(row["promptSha256"], hashlib.sha256(row["prompt"].encode("utf-8")).hexdigest())

    def test_semantic_summary_does_not_double_terminal_punctuation(self) -> None:
        summary = build_scene_art_manifest.semantic_summary_ko(
            {
                "id": "synthetic",
                "title": {"ko": "산책 취소"},
                "dialog": [{"speaker": "user", "ko": "너무 피곤해."}],
                "quests": [{"data": {"audioKo": "집에서 쉴까요?"}}],
            }
        )
        self.assertEqual(
            summary,
            "산책 취소. 대화 핵심: 너무 피곤해. 학습 목표 발화: 집에서 쉴까요?",
        )

    def test_render_is_byte_stable_and_lf_terminated(self) -> None:
        first = build_scene_art_manifest.render_manifest_json(self.manifest)
        second = build_scene_art_manifest.render_manifest_json(self.manifest)
        self.assertEqual(first, second)
        self.assertTrue(first.endswith("\n"))
        self.assertNotIn("\r", first)

    def test_generation_override_is_preserved_and_unknown_id_is_rejected(self) -> None:
        generation = dict(self.entries[0]["generation"])
        generation.update(
            {
                "status": "generated_pending_review",
                "generator": "built-in image_gen (model identity not exposed)",
                "generatorResultId": "exec-example",
                "visualReview": "pending",
            }
        )
        rebuilt = build_scene_art_manifest.build_manifest(
            build_scene_art_manifest.ROOT,
            generation_overrides={self.entries[0]["id"]: generation},
        )
        self.assertEqual(rebuilt["entries"][0]["generation"], generation)
        with self.assertRaisesRegex(ValueError, "unknown scenario"):
            build_scene_art_manifest.build_manifest(
                build_scene_art_manifest.ROOT,
                generation_overrides={"not_a_scenario": generation},
            )

    def test_old_profile_result_is_preserved_but_automatically_invalidated(self) -> None:
        row = self.entries[0]
        generation = dict(row["generation"])
        generation.update(
            {
                "status": "generated_pending_review",
                "manifestPromptSha256": "f" * 64,
                "sourcePromptSha256": "e" * 64,
                "automatedIssues": [],
                "visualReview": "pending",
                "runtimeEligible": False,
                "reviewNotes": [],
            }
        )
        rebuilt = build_scene_art_manifest.build_manifest(
            build_scene_art_manifest.ROOT,
            generation_overrides={row["id"]: generation},
        )
        migrated = rebuilt["entries"][0]["generation"]
        self.assertEqual(migrated["status"], "generated_invalid")
        self.assertEqual(migrated["previousManifestPromptSha256"], "f" * 64)
        self.assertEqual(
            migrated["manifestPromptSha256"],
            rebuilt["entries"][0]["promptSha256"],
        )
        self.assertIn("style_contract_prompt_drift", migrated["automatedIssues"])
        self.assertEqual(migrated["visualReview"], "invalidated")
        self.assertFalse(migrated["runtimeEligible"])
        self.assertIn(
            "scene-poster/faceted-heritage-2.5d-v1",
            migrated["reviewNotes"][-1],
        )

    def test_record_result_measures_png_and_keeps_visual_review_pending(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            scenario_id = self.entries[0]["id"]
            path = Path(tmp) / f"{scenario_id}.png"
            Image.new("RGB", (1536, 1024), (20, 40, 60)).save(path, "PNG")
            manifest = build_scene_art_manifest.build_manifest(
                build_scene_art_manifest.ROOT
            )
            build_scene_art_manifest.record_generation_result(
                manifest,
                scenario_id=scenario_id,
                normalized_file=path,
                generator="built-in image_gen (model identity not exposed)",
                result_id="exec-example",
                source_prompt_sha256="a" * 64,
                crop_profile="compact",
                attempts=[
                    {
                        "resultId": "exec-example",
                        "promptSha256": "a" * 64,
                        "outcome": "selected",
                        "issues": [],
                    }
                ],
                review_notes=["human visual review required"],
            )
            row = next(
                row for row in manifest["entries"] if row["id"] == scenario_id
            )
            generation = row["generation"]
            self.assertEqual(generation["status"], "generated_pending_review")
            self.assertEqual(generation["dimensions"], [1536, 1024])
            self.assertEqual(generation["mode"], "RGB")
            self.assertEqual(generation["automatedIssues"], [])
            self.assertEqual(generation["visualReview"], "pending")
            self.assertFalse(generation["runtimeEligible"])
            self.assertEqual(generation["cropProfile"], "compact")
            self.assertEqual(
                generation["normalizedSha256"],
                hashlib.sha256(path.read_bytes()).hexdigest(),
            )


if __name__ == "__main__":
    unittest.main()
