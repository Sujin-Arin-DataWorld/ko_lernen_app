"""Contract tests for the canonical scenario-art generation manifest."""

from __future__ import annotations

import hashlib
import re
import sys
import unittest
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_scene_art_manifest  # noqa: E402


class SceneArtManifestTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = build_scene_art_manifest.build_manifest(
            build_scene_art_manifest.ROOT
        )
        cls.entries = cls.manifest["entries"]

    def test_exact_413_rows_and_fixed_category_counts(self) -> None:
        self.assertEqual(self.manifest["scenarioCount"], 413)
        self.assertEqual(len(self.entries), 413)
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
            ],
        )
        expected = {
            "office": 172,
            "home": 86,
            "cafe": 36,
            "station": 27,
            "market": 22,
            "convenience": 14,
            "restaurant": 13,
            "pharmacy": 9,
            "directions": 8,
            "hotel": 8,
            "taxi": 7,
            "airport": 5,
            "bank": 3,
            "salon": 3,
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
            list(range(1, 414)),
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
                        "brand logos",
                        "watermarks",
                        "UI chrome",
                    ],
                )
                self.assertEqual(
                    row["styleReferenceIdentifiers"],
                    [
                        "asset-generation-bible/faceted-minhwa-v2",
                        f"runtime-scene-category/{row['category']}",
                    ],
                )
                self.assertEqual(
                    row["referenceImagePath"],
                    f"assets/illustrations/scenes/{row['category']}.png",
                )
                self.assertTrue(
                    (build_scene_art_manifest.ROOT / row["referenceImagePath"]).is_file()
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


if __name__ == "__main__":
    unittest.main()
