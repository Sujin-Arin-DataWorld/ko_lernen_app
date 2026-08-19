"""Tests for tool/asset_recipe.py.

Covers Phase 2-3's recipe runner: --check/--plan/--emit-work-order against
both the real, committed docs/assets/recipes/*.json files and small
synthetic recipes for individual rules, plus an end-to-end --ingest run for
the `cutout` kind against a synthetic (non-AI-generated) chroma image, since
this session had no real generation result to test the automated path
against.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import asset_recipe  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
RECIPES_DIR = ROOT / "docs" / "assets" / "recipes"


def _minimal_cutout_recipe(**overrides) -> dict:
    recipe = {
        "recipeId": "test-recipe",
        "kind": "cutout",
        "family": "F-A",
        "targetSlug": "decoration_geomungo",  # a real F-A member, for family_for_slug
        "model": "GPT Image 2",
        "resolution": "2K",
        "aspectRatio": "3:2",
        "referenceImages": [
            "assets/illustrations/decorations/decoration_seoan.png",
        ],
        "assembleFromFamily": False,
        "promptTemplate": "draw a {SUBJECT}",
        "promptVars": {"SUBJECT": "test object"},
        "subjectGuards": ["must look like the described subject"],
        "expectedCreditsPerCall": 4,
        "outputPath": "assets/illustrations/decorations/decoration_test.png",
    }
    recipe.update(overrides)
    return recipe


class RealRecipesBaselineTest(unittest.TestCase):
    """Ready recipes must pass --check. DRAFT recipes must not emit."""

    def test_ready_committed_recipes_pass_check_and_drafts_do_not(self) -> None:
        paths = sorted(RECIPES_DIR.glob("*.json"))
        self.assertGreaterEqual(
            len(paths), 7, "expected 4 frameEdit + 2 newBuilding + F-A cutouts"
        )
        ready = 0
        drafts = 0  # DRAFT is a lifecycle state, not a fixed population: byeoldang
        # and seogo were the only two and Jin approved both on 2026-08-19, so the
        # count is legitimately 0 today. What must hold is the behaviour on each
        # side of the flag, which the loop below asserts per recipe.
        for path in paths:
            with self.subTest(recipe=path.name):
                recipe = asset_recipe.load_recipe(path)
                problems = asset_recipe.check(recipe)
                if asset_recipe.is_draft(recipe):
                    drafts += 1
                    self.assertTrue(
                        any("DRAFT" in problem for problem in problems),
                        f"{path.name} is DRAFT but --check did not refuse: {problems}",
                    )
                    with self.assertRaises(asset_recipe.RecipeError):
                        asset_recipe.emit_work_order(recipe)
                    plan_text = asset_recipe.plan(recipe)
                    self.assertIn("DRAFT", plan_text)
                else:
                    ready += 1
                    self.assertEqual(problems, [], f"{path.name}: {problems}")
        self.assertGreaterEqual(ready, 5)
        self.assertEqual(ready + drafts, len(paths))

    def test_frameEdit_recipes_reproduce_the_exact_historical_prompt_hash(self) -> None:
        # Cross-check against the real sha256 computed independently during
        # this session's ledger backfill (see docs/assets/HANOK_V1_ASSET_
        # PROVENANCE.json records estate-frame-*-2026-08-18).
        known_hashes = {
            "sotdaeulmun": "ce600e3494a3edc5aebf7e9122d8e44d8c05844a729d8b1c65cc247d9f4ebf1d",
            "haengrangchae": "ec9562e94fa1d6a8ff88ef2114543023bb7c9165832a09b3c926b4eb1aaa60f8",
            "anchae": "2d56aee0843ca4a9544471e602a0cee6682084715e3904e9fd8fd4105520b8b9",
            "sadang": "93f08c7199a85db6efd689602a6d90bdb33bc29bdb406be7bd6f5bfda901122e",
        }
        for building, expected_sha in known_hashes.items():
            with self.subTest(building=building):
                recipe = asset_recipe.load_recipe(RECIPES_DIR / f"estate-frame-{building}.json")
                work_order = asset_recipe.emit_work_order(recipe)
                self.assertEqual(work_order["promptSha256"], expected_sha)


class CheckRuleTest(unittest.TestCase):
    def test_unknown_kind_fails(self) -> None:
        problems = asset_recipe.check({"kind": "not-a-real-kind"})
        self.assertEqual(len(problems), 1)

    def test_missing_required_field_fails(self) -> None:
        recipe = _minimal_cutout_recipe()
        del recipe["subjectGuards"]
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("subjectGuards" in p for p in problems))

    def test_cutout_without_subject_guards_fails(self) -> None:
        recipe = _minimal_cutout_recipe(subjectGuards=[])
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("subjectGuards" in p for p in problems))

    def test_more_than_one_reference_image_is_flagged(self) -> None:
        recipe = _minimal_cutout_recipe(
            referenceImages=[
                "assets/illustrations/decorations/decoration_seoan.png",
                "assets/illustrations/decorations/decoration_soban.png",
            ]
        )
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("generationFacts.referenceCount" in p for p in problems))

    def test_zero_reference_images_is_flagged(self) -> None:
        recipe = _minimal_cutout_recipe(referenceImages=[])
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("exactly 1" in p for p in problems))

    def test_omitting_resolution_is_a_missing_required_field(self) -> None:
        recipe = _minimal_cutout_recipe()
        del recipe["resolution"]
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("resolution" in p for p in problems))

    def test_explicit_null_resolution_is_flagged_for_every_kind(self) -> None:
        recipe = _minimal_cutout_recipe(resolution=None)
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("2K" in p for p in problems))

    def test_seedream_is_a_hard_failure_on_f_a(self) -> None:
        recipe = _minimal_cutout_recipe(model="Seedream V4.5")
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("denied" in p for p in problems))
        with self.assertRaises(asset_recipe.RecipeError):
            asset_recipe.emit_work_order(recipe)

    def test_unknown_model_is_a_hard_failure(self) -> None:
        recipe = _minimal_cutout_recipe(model="Totally Unknown Model XYZ")
        problems = asset_recipe.check(recipe)
        self.assertTrue(problems)
        self.assertFalse(any("warning-worthy" in p for p in problems))
        with self.assertRaises(asset_recipe.RecipeError):
            asset_recipe.emit_work_order(recipe)

    def test_nonexistent_reference_image_is_flagged(self) -> None:
        recipe = _minimal_cutout_recipe(referenceImages=["assets/does/not/exist.png"])
        problems = asset_recipe.check(recipe)
        self.assertTrue(any("does not exist" in p for p in problems))


class EmitWorkOrderTest(unittest.TestCase):
    def test_renders_the_prompt_and_hashes_it(self) -> None:
        recipe = _minimal_cutout_recipe()
        work_order = asset_recipe.emit_work_order(recipe)
        self.assertEqual(work_order["prompt"], "draw a test object")
        import hashlib
        self.assertEqual(
            work_order["promptSha256"], hashlib.sha256(b"draw a test object").hexdigest()
        )

    def test_refuses_when_check_fails(self) -> None:
        recipe = _minimal_cutout_recipe(subjectGuards=[])
        with self.assertRaises(asset_recipe.RecipeError):
            asset_recipe.emit_work_order(recipe)

    def test_assemble_from_family_injects_palette_camera_and_guards(self) -> None:
        recipe = _minimal_cutout_recipe(
            assembleFromFamily=True,
            promptVars={"SUBJECT": "a walnut test block"},
        )
        problems = asset_recipe.check(recipe)
        self.assertEqual(problems, [])
        prompt = asset_recipe.render_prompt(recipe)
        self.assertIn("a walnut test block", prompt)
        self.assertIn("#A2663A", prompt)
        self.assertIn("CAMERA AND LIGHT", prompt)
        self.assertIn("flat pure #00FF00", prompt)
        self.assertIn("must look like the described subject", prompt)
        self.assertNotEqual(prompt, "draw a test object")

    def test_frameEdit_work_order_carries_2k(self) -> None:
        recipe = asset_recipe.load_recipe(RECIPES_DIR / "estate-frame-anchae.json")
        work_order = asset_recipe.emit_work_order(recipe)
        self.assertEqual(work_order["resolution"], "2K")


def _synthetic_generation(color: tuple[int, int, int], size=(200, 200)) -> np.ndarray:
    """A flat #00FF00 field with one solid-colour rectangle -- stands in for
    a real model's chroma-key output without needing a real generation call."""
    canvas = np.zeros((size[1], size[0], 3), dtype=np.uint8)
    canvas[:, :] = (0, 255, 0)
    canvas[40:160, 40:160] = color
    return canvas


class IngestCutoutTest(unittest.TestCase):
    """End-to-end (minus the AI call): cut -> gate -> ledger-spec, against a
    synthetic chroma image since no real generation result exists to test
    the automated cutout path against this session."""

    def test_a_walnut_toned_synthetic_cutout_passes_the_F_A_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            raw = tmp_path / "raw.png"
            # #A2663A is STYLE_LOCK.json's F-A walnut anchor.
            Image.fromarray(_synthetic_generation((0xA2, 0x66, 0x3A)), mode="RGB").save(raw)

            recipe = _minimal_cutout_recipe()
            # Route pending_review output under a temp dir by monkeypatching ROOT-relative
            # paths is more invasive than needed -- instead just point outputPath/targetSlug
            # at a throwaway slug and clean up the real pending_review dir afterward.
            recipe["targetSlug"] = "decoration_test_synthetic_walnut"
            result = {
                "provider": "local-test",
                "model": "synthetic",
                "providerTaskId": "test-task",
                "occurredAtUtc": "2026-08-18T00:00:00Z",
                "costCredits": 0.0,
                "promptSentText": "draw a test object",
                "rawOutputPath": str(raw.relative_to(ROOT)) if raw.is_relative_to(ROOT) else str(raw),
            }
            result_path = tmp_path / "result.json"
            result_path.write_text(json.dumps(result), encoding="utf-8")

            pending_dir = ROOT / "assets_unused/pending_review/asset_recipe/decoration_test_synthetic_walnut"
            try:
                exit_code = asset_recipe.ingest(recipe, result_path)
                self.assertEqual(exit_code, 0)
                cut_file = pending_dir / "decoration_test_synthetic_walnut_cut.png"
                self.assertTrue(cut_file.is_file())
                spec_file = pending_dir / "decoration_test_synthetic_walnut_ledger_spec.json"
                self.assertTrue(spec_file.is_file())
                spec = json.loads(spec_file.read_text(encoding="utf-8"))
                self.assertEqual(spec["provider"], "local-test")
                self.assertEqual(spec["outputAssets"][0]["decision"], "approved")
            finally:
                if pending_dir.exists():
                    for f in pending_dir.iterdir():
                        f.unlink()
                    pending_dir.rmdir()

    def test_a_neon_synthetic_cutout_is_rejected_not_promoted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            raw = tmp_path / "raw.png"
            # Bright saturated red -- well past F-A's neon ceiling.
            Image.fromarray(_synthetic_generation((255, 20, 20)), mode="RGB").save(raw)

            recipe = _minimal_cutout_recipe()
            recipe["targetSlug"] = "decoration_test_synthetic_neon"
            result = {
                "provider": "local-test",
                "model": "synthetic",
                "providerTaskId": "test-task-2",
                "occurredAtUtc": "2026-08-18T00:00:00Z",
                "costCredits": 0.0,
                "promptSentText": "draw a test object",
                "rawOutputPath": str(raw.relative_to(ROOT)) if raw.is_relative_to(ROOT) else str(raw),
            }
            result_path = tmp_path / "result.json"
            result_path.write_text(json.dumps(result), encoding="utf-8")

            pending_dir = ROOT / "assets_unused/pending_review/asset_recipe/decoration_test_synthetic_neon"
            try:
                exit_code = asset_recipe.ingest(recipe, result_path)
                self.assertEqual(exit_code, 1)
                approved_spec = pending_dir / "decoration_test_synthetic_neon_ledger_spec.json"
                self.assertFalse(
                    approved_spec.exists(),
                    "a rejected cutout must not produce an 'approved' ledger spec file",
                )
                rejected_spec = pending_dir / "decoration_test_synthetic_neon_rejected_ledger_spec.json"
                self.assertTrue(rejected_spec.is_file(), "rejected ingest must write a spec to disk")
                spec = json.loads(rejected_spec.read_text(encoding="utf-8"))
                self.assertEqual(spec["outputAssets"][0]["decision"], "rejected")
                self.assertIn("rejected:", spec["note"])
            finally:
                if pending_dir.exists():
                    for f in pending_dir.iterdir():
                        f.unlink()
                    pending_dir.rmdir()


if __name__ == "__main__":
    unittest.main()
