#!/usr/bin/env python3
"""Regression tests for the all-or-nothing reviewed-batch integration."""

from __future__ import annotations

import csv
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import integrate_review_batches as integration
from validate_content import ContentValidator
import scenario_store


class IntegrateReviewBatchesTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / "repo"
        self._copy("assets/data")
        self._copy("tools/content_factory/drafts")
        self._copy("tools/content_factory/review")
        self._copy("functions/analyze_korean_text/grammar_patterns.json")
        self._copy("lib/services/vocab_pack_service.dart")
        self._copy("lib/widgets/sori/dancheong_stamp.dart")
        self._rewind_promoted_batches()

    def _copy(self, relative: str) -> None:
        source = REPO_ROOT / relative
        target = self.root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(source, target)
        else:
            shutil.copy2(source, target)

    def _snapshot(self) -> dict[str, bytes]:
        return {
            str(path.relative_to(self.root)): path.read_bytes()
            for path in self.root.rglob("*")
            if path.is_file()
        }

    def _rewind_promoted_batches(self) -> None:
        """Build a review-only fixture from the shipped, already-merged tree."""

        data = self.root / "assets/data"

        live_targets = {
            kind: (target_name, collection)
            for kind, (target_name, collection, _) in integration.TARGETS.items()
        }
        live_targets["scenario"] = (None, "scenarios")
        live_targets["pronunciation"] = ("pronunciation_phrases.json", "phrases")

        def remove_artifacts(manifest: dict[str, object]) -> set[str]:
            """Remove one promoted manifest's authored rows from the fixture."""

            removed_ids: set[str] = set()
            artifacts = manifest.get("artifacts")
            self.assertIsInstance(artifacts, list)
            for artifact in artifacts:
                self.assertIsInstance(artifact, dict)
                kind = artifact["kind"]
                draft = self.root / artifact["draft"]
                target_name, collection = live_targets[kind]
                target = data / target_name if target_name else None
                if collection is None:
                    with draft.open(encoding="utf-8-sig", newline="") as handle:
                        incoming = list(csv.DictReader(handle))
                    with target.open(encoding="utf-8-sig", newline="") as handle:
                        reader = csv.DictReader(handle)
                        header = list(reader.fieldnames or [])
                        current = list(reader)
                    incoming_ids = {row["id"] for row in incoming}
                    with target.open("w", encoding="utf-8", newline="") as handle:
                        writer = csv.DictWriter(
                            handle,
                            fieldnames=header,
                            lineterminator="\n",
                        )
                        writer.writeheader()
                        writer.writerows(
                            row for row in current if row["id"] not in incoming_ids
                        )
                else:
                    incoming = json.loads(draft.read_text(encoding="utf-8"))[collection]
                    current = (
                        scenario_store.load_root(data)
                        if target is None
                        else json.loads(target.read_text(encoding="utf-8"))
                    )
                    incoming_ids = {row["id"] for row in incoming}
                    current[collection] = [
                        row for row in current[collection] if row["id"] not in incoming_ids
                    ]
                    if target is None:
                        scenario_store.write_shards(current["scenarios"], data)
                    else:
                        target.write_text(
                            json.dumps(current, ensure_ascii=False, indent=2) + "\n",
                            encoding="utf-8",
                        )
                removed_ids.update(incoming_ids)
            return removed_ids

        # This fixture exercises the five-artifact C0 promotion path only.
        # C1 scenario batches have a distinct manifest and transactional
        # integrator, so they must remain part of the shipped fixture.
        manifests = [
            self.root / "tools/content_factory/drafts" / f"batch_{number:02d}_manifest.json"
            for number in (1, 2, 3)
        ]
        vocab_bases: set[str] = set()
        grammar_ids: set[str] = set()
        cloze_keys: set[str] = set()

        # C1 Batch 04 scenarios depend on grammar supplied by the C0 batches
        # below.  Remove only their live payload from this pre-review fixture;
        # keep their approved ledger/manifest intact so C0 assertions remain
        # representative of the shipped repository.
        scenario_manifest = json.loads(
            (self.root / "tools/content_factory/drafts/batch_04_manifest.json").read_text(
                encoding="utf-8"
            )
        )
        scenario_draft = json.loads(
            (self.root / scenario_manifest["artifacts"][0]["draft"]).read_text(
                encoding="utf-8"
            )
        )
        scenario_ids = {row["id"] for row in scenario_draft["scenarios"]}
        scenarios = scenario_store.load_root(data)
        scenario_store.write_shards(
            [row for row in scenarios["scenarios"] if row["id"] not in scenario_ids],
            data,
        )
        curriculum_path = data / "curriculum_manifest.json"
        curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
        curriculum["contentLinks"] = [
            row for row in curriculum["contentLinks"] if row.get("contentId") not in scenario_ids
        ]
        curriculum_path.write_text(
            json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        audit_path = data / "content_audit_manifest.json"
        audit = json.loads(audit_path.read_text(encoding="utf-8"))
        for source in audit["sources"]:
            if source["kind"] == "scenario":
                source["count"] = len(scenarios["scenarios"])
            elif source["kind"] == "scenarioQuest":
                source["count"] = sum(len(row["quests"]) for row in scenarios["scenarios"])
        audit_path.write_text(
            json.dumps(audit, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )

        for manifest_path in manifests:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            remove_artifacts(manifest)

            for pack in manifest["vocabPacks"]:
                vocab_bases.add(integration._base_pack_id(pack["packId"]))
            grammar_ids.update(item["id"] for item in manifest["grammarIntents"])
            cloze_keys.update(
                f"{item['level'].lower()}:{item['topic'].lower()}"
                for item in manifest["clozeTopicMappings"]
            )
            manifest["status"] = "review_only_draft"
            manifest["provenance"].pop("approval", None)
            manifest["provenance"].pop("mergedAt", None)
            manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

            for artifact in manifest["artifacts"]:
                review = self.root / artifact["review"]
                with review.open(encoding="utf-8-sig", newline="") as handle:
                    reader = csv.DictReader(handle)
                    header = list(reader.fieldnames or [])
                    rows = list(reader)
                for row in rows:
                    row["상태"] = "draft"
                    row["jin_memo"] = ""
                with review.open("w", encoding="utf-8", newline="") as handle:
                    writer = csv.DictWriter(handle, fieldnames=header, lineterminator="\n")
                    writer.writeheader()
                    writer.writerows(rows)

        # Strip every later merged C0 manifest from this historical replay,
        # while leaving its manifest and approval ledgers in their shipped
        # state. This automatically covers Batch 05 and future C0 batches.
        later_manifests: list[dict[str, object]] = []
        for candidate_path in sorted(
            (self.root / "tools/content_factory/drafts").glob("batch_*_manifest.json")
        ):
            if candidate_path in set(manifests):
                continue
            candidate = json.loads(candidate_path.read_text(encoding="utf-8"))
            if candidate.get("status") == "merged":
                later_manifests.append(candidate)

        later_removed_ids: set[str] = set()
        later_smalltalk_mappings: list[dict[str, object]] = []
        extension_unit_ids: set[str] = set()
        extension_concept_ids: set[str] = set()
        for manifest in later_manifests:
            later_removed_ids.update(remove_artifacts(manifest))
            later_bases = {
                integration._base_pack_id(pack["packId"])
                for pack in manifest.get("vocabPacks", [])
            }
            vocab_bases.update(later_bases)
            grammar_ids.update(
                item["id"] for item in manifest.get("grammarIntents", [])
            )
            cloze_keys.update(
                f"{item['level'].lower()}:{item['topic'].lower()}"
                for item in manifest.get("clozeTopicMappings", [])
            )
            later_smalltalk_mappings.extend(
                manifest.get("smalltalkCategoryMappings", [])
            )
            extension = manifest.get("curriculumExtensions", {})
            extension_unit_ids.update(
                row["id"] for row in extension.get("courseUnits", [])
            )
            extension_concept_ids.update(
                row["id"] for row in extension.get("concepts", [])
            )

        curriculum_path = data / "curriculum_manifest.json"
        curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
        for base in vocab_bases:
            curriculum["vocabPackUnitMap"].pop(base, None)
        for ident in grammar_ids:
            curriculum["grammarRuleMap"].pop(ident, None)
        for key in cloze_keys:
            curriculum["clozeTopicUnitMap"].pop(key, None)

        curriculum["courseUnits"] = [
            row for row in curriculum["courseUnits"] if row["id"] not in extension_unit_ids
        ]
        curriculum["concepts"] = [
            row for row in curriculum["concepts"] if row["id"] not in extension_concept_ids
        ]
        smalltalk_path = data / "smalltalk.json"
        smalltalk_document = json.loads(smalltalk_path.read_text(encoding="utf-8"))
        remaining_smalltalk = []
        for row in smalltalk_document["phrases"]:
            key = f"{row['level'].lower()}:{row['category'].lower()}"
            mapping = curriculum["smalltalkCategoryUnitMap"].get(key)
            if (
                isinstance(mapping, dict)
                and mapping.get("courseUnitId") in extension_unit_ids
            ):
                later_removed_ids.add(row["id"])
                continue
            remaining_smalltalk.append(row)
        smalltalk_document["phrases"] = remaining_smalltalk
        smalltalk_path.write_text(
            json.dumps(smalltalk_document, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        remaining_smalltalk_keys = {
            f"{row['level'].lower()}:{row['category'].lower()}"
            for row in remaining_smalltalk
        }
        for mapping in later_smalltalk_mappings:
            key = f"{mapping['level'].lower()}:{mapping['category'].lower()}"
            if key not in remaining_smalltalk_keys:
                curriculum["smalltalkCategoryUnitMap"].pop(key, None)
        for ident in later_removed_ids:
            curriculum["smalltalkCheckpointPhraseMap"].pop(ident, None)
        curriculum["contentLinks"] = [
            row
            for row in curriculum["contentLinks"]
            if row.get("contentId") not in later_removed_ids
            and row.get("courseUnitId") not in extension_unit_ids
        ]
        curriculum_path.write_text(json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        audit = json.loads(audit_path.read_text(encoding="utf-8"))
        audit["graph"]["courseUnits"] = len(curriculum["courseUnits"])
        audit["graph"]["courseUnitsByLevel"] = {
            level: sum(
                1
                for unit in curriculum["courseUnits"]
                if unit["level"] == level
            )
            for level in ("a1", "a2", "b1", "b2", "c1", "c2")
        }
        for source in audit["sources"]:
            if source["kind"] == "smalltalk":
                source["count"] = len(remaining_smalltalk)
        audit_path.write_text(
            json.dumps(audit, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        service = self.root / "lib/services/vocab_pack_service.dart"
        service_text = service.read_text(encoding="utf-8")
        for base in vocab_bases:
            while True:
                line = next(
                    (
                        candidate
                        for candidate in service_text.splitlines(keepends=True)
                        if candidate.lstrip().startswith(f"'{base}':")
                    ),
                    "",
                )
                if not line:
                    break
                service_text = service_text.replace(line, "", 1)
        service.write_text(service_text, encoding="utf-8")

    def test_preview_is_read_only_and_reports_full_batch_counts(self) -> None:
        before = self._snapshot()

        counts, records = integration.integrate(
            root=self.root,
            apply=False,
            approve_all=False,
            restore_b2_recovery=False,
        )

        self.assertEqual(318, records)
        self.assertEqual(1044, counts["vocab"])
        self.assertEqual(152, counts["grammar"])
        self.assertEqual(237, counts["smalltalk"])
        after = self._snapshot()
        self.assertEqual(before.keys(), after.keys())
        for path, expected in before.items():
            self.assertEqual(expected, after[path], path)

    def test_apply_promotes_every_row_and_keeps_the_graph_valid(self) -> None:
        counts, records = integration.integrate(
            root=self.root,
            apply=True,
            approve_all=True,
            restore_b2_recovery=False,
        )

        self.assertEqual(318, records)
        self.assertEqual(1044, counts["vocab"])
        self.assertEqual([], ContentValidator(self.root).validate())
        curriculum = json.loads(
            (self.root / "assets/data/curriculum_manifest.json").read_text(
                encoding="utf-8"
            )
        )
        audit = json.loads(
            (self.root / "assets/data/content_audit_manifest.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(
            len(curriculum["courseUnits"]),
            audit["graph"]["courseUnits"],
        )
        self.assertEqual(
            {
                level: sum(
                    1
                    for unit in curriculum["courseUnits"]
                    if unit["level"] == level
                )
                for level in ("a1", "a2", "b1", "b2", "c1", "c2")
            },
            audit["graph"]["courseUnitsByLevel"],
        )
        for manifest_name in ("batch_01_manifest.json", "batch_02_manifest.json", "batch_03_manifest.json"):
            manifest_path = self.root / "tools/content_factory/drafts" / manifest_name
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual("merged", manifest["status"])
            for artifact in manifest["artifacts"]:
                ledger = self.root / str(artifact["review"])
                with ledger.open(encoding="utf-8-sig", newline="") as handle:
                    rows = list(csv.DictReader(handle))
                self.assertTrue(rows)
                self.assertEqual({"approved"}, {row["상태"] for row in rows})
        service = (self.root / "lib/services/vocab_pack_service.dart").read_text(encoding="utf-8")
        self.assertIn("'b1_housing_contract': ('Wohnen & Vertrag', 'Housing & Contracts')", service)
        self.assertIn("'b2_language_society': 25", service)

    def test_post_write_failure_restores_every_target(self) -> None:
        before = self._snapshot()
        with mock.patch.object(
            integration,
            "_verify_written_tree",
            side_effect=integration.IntegrationError("synthetic verification failure"),
        ):
            with self.assertRaisesRegex(integration.IntegrationError, "rolled back"):
                integration.integrate(
                    root=self.root,
                    apply=True,
                    approve_all=True,
                    restore_b2_recovery=False,
                )
        after = self._snapshot()
        self.assertEqual(before.keys(), after.keys())
        for path, expected in before.items():
            self.assertEqual(expected, after[path], path)


if __name__ == "__main__":
    unittest.main()
