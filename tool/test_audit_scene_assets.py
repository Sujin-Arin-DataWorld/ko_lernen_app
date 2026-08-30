"""Contract tests for the canonical scenario scene inventory.

The runtime still uses 14 legacy category posters as fallbacks.  The strict
1536x1024 contract therefore applies to scenario-specific (dedicated) art,
while a real category fallback remains coverage debt rather than an error.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_scene_assets  # noqa: E402
import style_lock  # noqa: E402


class SceneInventoryTest(unittest.TestCase):
    def test_dedicated_output_contract_matches_scene_style_lock_ssot(self) -> None:
        family = style_lock.load_style_lock()["families"]["F-E-scene-poster"]
        output = family["canonicalOutput"]
        self.assertEqual(
            audit_scene_assets.DEDICATED_SIZE,
            (output["width"], output["height"]),
        )
        self.assertEqual(audit_scene_assets.DEDICATED_MODES, set(output["modes"]))
        self.assertEqual(output["format"], "PNG")

    def test_generated_data_markdown_is_forced_to_lf(self) -> None:
        attributes = (audit_scene_assets.ROOT / ".gitattributes").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "docs/data/*.md text eol=lf",
            attributes.splitlines(),
            "byte-exact generated Markdown checks need LF on Windows checkouts",
        )

    def test_text_source_fingerprints_are_eol_stable(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lf = root / "source_lf.dart"
            crlf = root / "source_crlf.dart"
            lf.write_bytes(b"final value = 1;\nfinal other = 2;\n")
            crlf.write_bytes(b"final value = 1;\r\nfinal other = 2;\r\n")

            self.assertEqual(
                audit_scene_assets._sha256_text_file(lf),
                audit_scene_assets._sha256_text_file(crlf),
            )

    def test_live_runtime_inventory_is_strict_and_drift_free(self) -> None:
        self.assertEqual(audit_scene_assets.main(["--check"]), 0)

    def test_live_pending_review_inventory_is_strict(self) -> None:
        self.assertEqual(
            audit_scene_assets.main(["--check", "--pending-review"]),
            0,
        )

    def _ref(
        self,
        scenario_id: str,
        *,
        backdrop: str = "office",
        shard: str = "scenarios_a1.json",
        level: str = "a1",
    ) -> audit_scene_assets.ScenarioRef:
        return audit_scene_assets.ScenarioRef(
            shard=shard,
            scenario_id=scenario_id,
            level=level,
            backdrop=backdrop,
        )

    def _poster_dir(self, root: Path) -> Path:
        path = root / "assets" / "illustrations" / "scenes"
        path.mkdir(parents=True, exist_ok=True)
        return path

    def _png(
        self,
        path: Path,
        *,
        size: tuple[int, int] = (1536, 1024),
        mode: str = "RGB",
        color: object | None = None,
    ) -> None:
        if color is None:
            color = 7 if mode == "P" else (32, 64, 96, 255) if mode == "RGBA" else (32, 64, 96)
        Image.new(mode, size, color).save(path, format="PNG", optimize=False)

    def _scan(
        self,
        root: Path,
        refs: list[audit_scene_assets.ScenarioRef],
    ) -> dict:
        return audit_scene_assets.scan_scene_inventory(
            refs,
            self._poster_dir(root),
            project_root=root,
            generated_from={"assets/data/scenarios_a1.json": "a" * 64},
        )

    @staticmethod
    def _codes(inventory: dict) -> list[str]:
        return [issue["code"] for issue in inventory["issues"]]

    def test_valid_dedicated_png_exposes_required_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._png(self._poster_dir(root) / "office_print.png")

            inventory = self._scan(root, [self._ref("office_print")])

            self.assertEqual(inventory["schemaVersion"], 1)
            self.assertEqual(inventory["scenarioCount"], 1)
            self.assertEqual(inventory["dedicatedCount"], 1)
            self.assertEqual(inventory["fallbackCount"], 0)
            self.assertEqual(inventory["missingCount"], 0)
            self.assertEqual(inventory["issues"], [])
            row = inventory["scenarios"][0]
            self.assertEqual(
                list(row),
                [
                    "shard",
                    "id",
                    "level",
                    "backdrop",
                    "dedicatedPath",
                    "resolvedPath",
                    "status",
                    "width",
                    "height",
                    "mode",
                    "colorSpace",
                    "alpha",
                    "sha256",
                    "duplicateOf",
                    "runtimeEligible",
                ],
            )
            self.assertEqual(row["status"], "dedicated")
            self.assertEqual((row["width"], row["height"]), (1536, 1024))
            self.assertEqual(row["mode"], "RGB")
            self.assertEqual(row["colorSpace"], "sRGB")
            self.assertFalse(row["alpha"])
            self.assertEqual(len(row["sha256"]), 64)
            self.assertIsNone(row["duplicateOf"])
            self.assertTrue(row["runtimeEligible"])

    def test_duplicate_scenario_id_is_strict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._png(self._poster_dir(root) / "same_id.png")
            inventory = self._scan(
                root,
                [
                    self._ref("same_id", shard="scenarios_a1.json"),
                    self._ref("same_id", shard="scenarios_a2.json", level="a2"),
                ],
            )
            self.assertIn("duplicate_scenario_id", self._codes(inventory))
            self.assertTrue(all(not row["runtimeEligible"] for row in inventory["scenarios"]))

    def test_broken_category_fallback_is_strict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            inventory = self._scan(root, [self._ref("missing_art", backdrop="typo")])
            self.assertEqual(inventory["missingCount"], 1)
            self.assertEqual(inventory["scenarios"][0]["status"], "broken_fallback")
            self.assertIn("broken_category_fallback", self._codes(inventory))

    def test_theme_park_uses_market_category_alias_until_poster_arrives(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._png(self._poster_dir(root) / "market.png", size=(1086, 1448))
            inventory = self._scan(
                root,
                [self._ref("a1_theme_park_date_choices", backdrop="theme_park")],
            )
            row = inventory["scenarios"][0]
            self.assertEqual(row["status"], "fallback")
            self.assertTrue(row["resolvedPath"].endswith("market.png"))
            self.assertTrue(row["runtimeEligible"])
            self.assertEqual(inventory["issues"], [])

    def test_wrong_dedicated_dimensions_are_strict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._png(
                self._poster_dir(root) / "wrong_size.png",
                size=(1086, 1448),
            )
            inventory = self._scan(root, [self._ref("wrong_size")])
            self.assertIn("invalid_dedicated_dimensions", self._codes(inventory))
            self.assertFalse(inventory["scenarios"][0]["runtimeEligible"])

    def test_unreadable_and_non_png_files_are_strict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            poster_dir = self._poster_dir(root)
            (poster_dir / "corrupt.png").write_bytes(b"not a png")
            Image.new("RGB", (64, 64), (1, 2, 3)).save(
                poster_dir / "wrong_extension.jpg",
                format="JPEG",
            )
            self._png(poster_dir / "office.png", size=(1086, 1448), mode="P")

            inventory = self._scan(
                root,
                [self._ref("corrupt"), self._ref("wrong_extension")],
            )
            codes = self._codes(inventory)
            self.assertIn("unreadable_image", codes)
            self.assertIn("non_png_image", codes)
            self.assertIn("filename_id_mismatch", codes)

    def test_unexpected_dedicated_color_mode_is_strict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._png(self._poster_dir(root) / "indexed.png", mode="P")
            inventory = self._scan(root, [self._ref("indexed")])
            self.assertIn("unexpected_color_mode", self._codes(inventory))
            self.assertEqual(inventory["scenarios"][0]["mode"], "P")

    def test_duplicate_dedicated_content_sets_duplicate_of(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            poster_dir = self._poster_dir(root)
            self._png(poster_dir / "alpha.png")
            (poster_dir / "beta.png").write_bytes((poster_dir / "alpha.png").read_bytes())

            inventory = self._scan(root, [self._ref("beta"), self._ref("alpha")])

            self.assertIn("duplicate_dedicated_content", self._codes(inventory))
            by_id = {row["id"]: row for row in inventory["scenarios"]}
            self.assertIsNone(by_id["alpha"]["duplicateOf"])
            self.assertEqual(by_id["beta"]["duplicateOf"], "alpha")
            self.assertTrue(by_id["alpha"]["runtimeEligible"])
            self.assertFalse(by_id["beta"]["runtimeEligible"])

    def test_orphan_filename_is_reported_as_orphan_and_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            poster_dir = self._poster_dir(root)
            self._png(poster_dir / "office.png", size=(1086, 1448), mode="P")
            self._png(poster_dir / "typo_identifier.png")

            inventory = self._scan(root, [self._ref("known")])

            codes = self._codes(inventory)
            self.assertIn("orphan_dedicated_scene_asset", codes)
            self.assertIn("filename_id_mismatch", codes)
            self.assertEqual(inventory["fallbackCount"], 1)

    def test_gitkeep_is_not_treated_as_a_scene_asset(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            poster_dir = self._poster_dir(root)
            (poster_dir / ".gitkeep").write_text("", encoding="utf-8")
            self._png(poster_dir / "office.png", size=(1086, 1448), mode="P")

            inventory = self._scan(root, [self._ref("known")])

            self.assertEqual(inventory["issues"], [])
            self.assertEqual(inventory["fallbackCount"], 1)

    def test_json_is_sorted_byte_stable_and_lf_terminated(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            poster_dir = self._poster_dir(root)
            self._png(poster_dir / "office.png", size=(1086, 1448), mode="P")
            refs = [
                self._ref("zulu", shard="scenarios_b1.json", level="b1"),
                self._ref("alpha", shard="scenarios_a2.json", level="a2"),
            ]
            inventory = self._scan(root, refs)

            first = audit_scene_assets.render_inventory_json(inventory)
            second = audit_scene_assets.render_inventory_json(inventory)

            self.assertEqual(first, second)
            self.assertTrue(first.endswith("\n"))
            self.assertNotIn("\r", first)
            self.assertEqual(
                [row["id"] for row in inventory["scenarios"]],
                ["alpha", "zulu"],
            )

    def test_manifest_drift_is_strict_and_exit_decision_is_pure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._png(self._poster_dir(root) / "alpha.png")
            inventory = self._scan(root, [self._ref("alpha")])
            checked = root / "inventory.json"
            checked.write_text("stale\n", encoding="utf-8")

            drift = audit_scene_assets.find_output_drift(
                {checked: audit_scene_assets.render_inventory_json(inventory)}
            )

            self.assertEqual([issue["code"] for issue in drift], ["manifest_drift"])
            self.assertEqual(audit_scene_assets.strict_exit_code(inventory, drift), 1)
            checked.write_text(
                audit_scene_assets.render_inventory_json(inventory),
                encoding="utf-8",
                newline="\n",
            )
            self.assertEqual(audit_scene_assets.find_output_drift({checked: checked.read_text(encoding="utf-8")}), [])
            self.assertEqual(audit_scene_assets.strict_exit_code(inventory, []), 0)

    def test_pending_review_overlay_uses_runtime_fallback_but_is_not_runtime_eligible(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            runtime_dir = root / "assets" / "illustrations" / "scenes"
            pending_dir = root / "assets_unused" / "pending_review" / "scenes"
            runtime_dir.mkdir(parents=True)
            pending_dir.mkdir(parents=True)
            self._png(runtime_dir / "office.png", size=(1086, 1448), mode="P")
            self._png(pending_dir / "alpha.png")

            inventory = audit_scene_assets.scan_scene_inventory(
                [self._ref("beta"), self._ref("alpha")],
                pending_dir,
                fallback_dir=runtime_dir,
                project_root=root,
                generated_from={},
                review_mode=True,
            )

            self.assertEqual(inventory["auditMode"], "pending_review")
            self.assertEqual(inventory["dedicatedCount"], 1)
            self.assertEqual(inventory["fallbackCount"], 1)
            self.assertEqual(inventory["issues"], [])
            by_id = {row["id"]: row for row in inventory["scenarios"]}
            self.assertEqual(by_id["alpha"]["status"], "dedicated")
            self.assertFalse(by_id["alpha"]["runtimeEligible"])
            self.assertTrue(by_id["beta"]["runtimeEligible"])
            self.assertIn("assets_unused/pending_review", by_id["alpha"]["resolvedPath"])

            valid_manifest = {
                "entries": [
                    {
                        "id": "alpha",
                        "targetPath": by_id["alpha"]["resolvedPath"],
                        "generation": {
                            "status": "generated_pending_review",
                            "normalizedSha256": by_id["alpha"]["sha256"],
                            "dimensions": [1536, 1024],
                            "mode": "RGB",
                            "alpha": False,
                            "runtimeEligible": False,
                        },
                    },
                    {
                        "id": "beta",
                        "targetPath": (
                            "assets_unused/pending_review/scenes/beta.png"
                        ),
                        "generation": {"status": "not_generated"},
                    },
                ]
            }
            self.assertEqual(
                audit_scene_assets.find_generation_manifest_issues(
                    inventory,
                    valid_manifest,
                ),
                [],
            )

            valid_manifest["entries"][0]["generation"]["normalizedSha256"] = (
                "f" * 64
            )
            self.assertEqual(
                [
                    issue["code"]
                    for issue in audit_scene_assets.find_generation_manifest_issues(
                        inventory,
                        valid_manifest,
                    )
                ],
                ["generation_manifest_metadata_drift"],
            )

            valid_manifest["entries"][0]["generation"] = {
                "status": "not_generated"
            }
            valid_manifest["entries"][1]["generation"] = {
                "status": "generated_pending_review",
                "normalizedSha256": "e" * 64,
                "dimensions": [1536, 1024],
                "mode": "RGB",
                "alpha": False,
                "runtimeEligible": False,
            }
            self.assertEqual(
                [
                    issue["code"]
                    for issue in audit_scene_assets.find_generation_manifest_issues(
                        inventory,
                        valid_manifest,
                    )
                ],
                [
                    "generation_manifest_file_missing",
                    "generation_manifest_unrecorded_file",
                ],
            )

    def test_pending_review_category_filename_is_not_a_dedicated_asset(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            runtime_dir = root / "assets" / "illustrations" / "scenes"
            pending_dir = root / "assets_unused" / "pending_review" / "scenes"
            runtime_dir.mkdir(parents=True)
            pending_dir.mkdir(parents=True)
            self._png(runtime_dir / "office.png", size=(1086, 1448), mode="P")
            self._png(pending_dir / "office.png")

            inventory = audit_scene_assets.scan_scene_inventory(
                [self._ref("alpha")],
                pending_dir,
                fallback_dir=runtime_dir,
                project_root=root,
                generated_from={},
                review_mode=True,
            )

            self.assertIn("orphan_dedicated_scene_asset", self._codes(inventory))
            self.assertIn("filename_id_mismatch", self._codes(inventory))


if __name__ == "__main__":
    unittest.main()
