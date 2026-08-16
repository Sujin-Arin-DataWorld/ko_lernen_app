#!/usr/bin/env python3
"""Contract tests for the generated canonical can-do catalog."""

from __future__ import annotations

import csv
import copy
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"
MODULE_PATH = Path(__file__).with_name("build_can_do_segments.py")
SPEC = importlib.util.spec_from_file_location("build_can_do_segments", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot import {MODULE_PATH}")
builder = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = builder
SPEC.loader.exec_module(builder)


def _json(path: str) -> dict:
    return json.loads((DATA / path).read_text(encoding="utf-8"))


def _csv(path: str) -> list[dict[str, str]]:
    with (DATA / path).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


class CanDoSegmentGeneratorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog, cls.authorities = builder.build_assets()
        cls.direct = {
            (row["kind"], row["id"]): row
            for row in cls.authorities["contentReferences"]
        }
        cls.inherited = {
            (row["kind"], row["id"]): row
            for row in cls.authorities["coverage"]["inheritedContentReferences"]
        }
        clusters = {row["id"]: row for row in cls.catalog["contentClusters"]}
        cls.segment_by_reference = {}
        for segment in cls.catalog["segments"]:
            for cluster_id in segment["contentClusterIds"]:
                for reference in clusters[cluster_id]["contentReferences"]:
                    cls.segment_by_reference.setdefault(
                        (reference["kind"], reference["id"]), set()
                    ).add(segment["id"])

    def test_generated_files_are_byte_exact_and_check_mode_passes(self) -> None:
        expected_catalog = builder._json_bytes(self.catalog)
        expected_authorities = builder._json_bytes(self.authorities)
        self.assertEqual(expected_catalog, builder.CATALOG_PATH.read_bytes())
        self.assertEqual(expected_authorities, builder.AUTHORITY_PATH.read_bytes())
        subprocess.run(
            [sys.executable, str(MODULE_PATH), "--check"],
            cwd=ROOT,
            check=True,
        )

    def test_core_has_86_immutable_segments_and_full_mode_ids(self) -> None:
        segments = self.catalog["segments"]
        self.assertEqual(86, len(segments))
        self.assertEqual(
            builder.EXPECTED_COUNTS,
            dict(Counter(row["level"] for row in segments)),
        )
        self.assertEqual(len(segments), len(self.catalog["contentClusters"]))
        self.assertEqual(6, len(self.catalog["trackEditions"]))
        for segment in segments:
            self.assertEqual(segment["id"], segment["constructLineageId"])
            self.assertEqual(1, segment["proofRevision"])
            self.assertEqual("published", segment["lifecycle"])
            self.assertEqual("allOf", segment["evidencePolicy"])
            for requirement in segment["assessmentRequirements"]:
                suffix = builder.MODE_SUFFIX[requirement["evidenceMode"]]
                key = segment["id"].removeprefix("segment_")
                self.assertEqual(
                    f"assess_{key}_{suffix}_v1",
                    requirement["assessmentItemId"],
                )
                self.assertEqual(
                    f"mission_{key}_{suffix}_v1",
                    requirement["missionContentLinkId"],
                )
                self.assertEqual(0.7, requirement["minimumScore"])

    def test_all_primary_content_is_directly_routed_once(self) -> None:
        vocab_pack_ids = {row["pack_id"] for row in _csv("korean_vocab.csv")}
        grammar_ids = {row["id"] for row in _csv("grammar.csv")}
        smalltalk_ids = {row["id"] for row in _json("smalltalk.json")["phrases"]}
        scenario_ids = {row["id"] for row in _json("scenarios.json")["scenarios"]}
        expected = {
            "vocabPack": vocab_pack_ids,
            "grammar": grammar_ids,
            "smalltalk": smalltalk_ids,
            "scenario": scenario_ids,
        }
        for kind, ids in expected.items():
            self.assertEqual(
                ids,
                {content_id for ref_kind, content_id in self.direct if ref_kind == kind},
            )
            self.assertEqual(
                len(ids),
                self.authorities["coverage"]["directReferenceCounts"][kind],
            )

    def test_cloze_and_satz_have_disjoint_exact_lineage(self) -> None:
        cloze_rows = {row["id"]: row for row in _json("cloze.json")["items"]}
        satz_rows = {row["id"]: row for row in _json("satz_sentences.json")["items"]}
        vocab_rows = _csv("korean_vocab.csv")
        vocab_by_pack = {}
        vocab_by_example: dict[tuple[str, str], list[dict[str, str]]] = {}
        vocab_by_term: dict[tuple[str, str], list[dict[str, str]]] = {}
        for row in vocab_rows:
            vocab_by_pack.setdefault(row["pack_id"], []).append(row)
            vocab_by_example.setdefault(
                (row["level"].lower(), row["example_korean"]), []
            ).append(row)
            vocab_by_term.setdefault(
                (row["level"].lower(), row["korean"]), []
            ).append(row)

        for kind, rows in (("cloze", cloze_rows), ("satz", satz_rows)):
            direct_ids = {
                content_id for ref_kind, content_id in self.direct if ref_kind == kind
            }
            inherited_ids = {
                content_id for ref_kind, content_id in self.inherited if ref_kind == kind
            }
            self.assertFalse(direct_ids & inherited_ids)
            self.assertEqual(set(rows), direct_ids | inherited_ids)

        for (kind, content_id), lineage in self.inherited.items():
            self.assertEqual("vocabPack", lineage["sourceKind"])
            source_rows = vocab_by_pack[lineage["sourceId"]]
            self.assertEqual({lineage["level"]}, {row["level"].lower() for row in source_rows})
            source = next(
                row for row in vocab_rows if row["id"] == lineage["sourceVocabId"]
            )
            self.assertEqual(
                builder._json_fingerprint(source),
                lineage["sourceVocabFingerprintSha256"],
            )
            if kind == "cloze":
                row = cloze_rows[content_id]
                self.assertEqual(row["fullKo"], source["example_korean"])
                candidates = vocab_by_example[(lineage["level"], row["fullKo"])]
                candidate_packs = {candidate["pack_id"] for candidate in candidates}
                if len(candidate_packs) > 1:
                    self.assertEqual(row["answer"], source["korean"])
                    self.assertEqual(
                        builder.DERIVED_SOURCE_VOCAB_OVERRIDES[content_id],
                        source["id"],
                    )
            else:
                row = satz_rows[content_id]
                self.assertTrue(
                    source["example_korean"] == row["targetKo"]
                    or source["korean"] == row["vocabKo"]
                )
                exact_candidates = vocab_by_example.get(
                    (lineage["level"], row["targetKo"]), []
                )
                exact_packs = {
                    candidate["pack_id"] for candidate in exact_candidates
                }
                if exact_candidates:
                    self.assertEqual(1, len(exact_packs))
                else:
                    candidates = vocab_by_term[(lineage["level"], row["vocabKo"])]
                    self.assertEqual(1, len({row["pack_id"] for row in candidates}))
            self.assertEqual(lineage["sourceId"], source["pack_id"])

        self.assertEqual(
            set(builder.DERIVED_SOURCE_VOCAB_OVERRIDES),
            {
                content_id
                for (kind, content_id), lineage in self.inherited.items()
                if kind == "cloze"
                and len(
                    {
                        row["pack_id"]
                        for row in vocab_by_example[
                            (lineage["level"], cloze_rows[content_id]["fullKo"])
                        ]
                    }
                )
                > 1
            },
        )

    def test_smalltalk_audit_partitions_all_a1_b2_phrases(self) -> None:
        audit = self.authorities["coverage"]["smalltalkRoutingAudit"]
        partitions = [
            set(audit["exactRouteOverrideIds"]),
            set(audit["categoryFallbackIds"]),
            set(audit["courseUnitFallbackIds"]),
        ]
        self.assertFalse(partitions[0] & partitions[1])
        self.assertFalse(partitions[0] & partitions[2])
        self.assertFalse(partitions[1] & partitions[2])
        expected = {
            row["id"]
            for row in _json("smalltalk.json")["phrases"]
            if row["level"] in ("a1", "a2", "b1", "b2")
        }
        self.assertEqual(expected, set().union(*partitions))
        self.assertEqual([], audit["unresolvedAmbiguousIds"])
        for row in audit["legacyCourseUnitOverrides"]:
            self.assertIn(row["id"], partitions[0])
            self.assertNotEqual(row["legacyCourseUnitId"], row["courseUnitId"])
            authority = self.direct[("smalltalk", row["id"])]
            self.assertEqual(row["courseUnitId"], authority["courseUnitId"])

        phrases = {
            row["id"]: row
            for row in _json("smalltalk.json")["phrases"]
            if row["level"] in ("a1", "a2", "b1", "b2")
        }
        segments = {row["id"]: row for row in self.catalog["segments"]}
        decisions = {row["phraseId"]: row for row in audit["phraseDecisions"]}
        self.assertEqual(set(phrases), set(decisions))
        for phrase_id, decision in decisions.items():
            self.assertEqual(
                builder._json_fingerprint(phrases[phrase_id]),
                decision["phraseFingerprintSha256"],
            )
            segment = segments[decision["canDoSegmentId"]]
            self.assertEqual(
                builder._json_fingerprint(
                    {"title": segment["title"], "canDo": segment["canDo"]}
                ),
                decision["canDoFingerprintSha256"],
            )
            self.assertIn(
                decision["semanticStatus"],
                ("approved", "bestAvailable", "exactMapped"),
            )
            self.assertEqual(
                {decision["canDoSegmentId"]},
                self.segment_by_reference[("smalltalk", phrase_id)],
            )
            if decision["routingSource"] != "exactOverride":
                self.assertEqual("bestAvailable", decision["semanticStatus"])
                self.assertEqual(
                    "closestPublishedCoreSegment", decision["reasonCode"]
                )

        self.assertEqual(
            "bestAvailable", decisions["smalltalk_b1_0012"]["semanticStatus"]
        )

        expected_exact_routes = {
            "smalltalk_a2_0038": "segment_a2_subway_transfer",
            "smalltalk_a2_0040": "segment_a2_taxi_street",
            "smalltalk_a2_0042": "segment_a2_ktx_ticket",
            "smalltalk_b1_0043": "segment_b1_property_damage_report",
            "smalltalk_b2_0033": "segment_b2_shared_space_coordination",
            "smalltalk_b2_0039": "segment_b2_contract_scope",
            "smalltalk_b2_0043": "segment_b2_household_safety_rule",
            "smalltalk_b2_0069": "segment_b2_personal_boundaries",
        }
        for phrase_id, segment_id in expected_exact_routes.items():
            self.assertEqual(segment_id, decisions[phrase_id]["canDoSegmentId"])
            if phrase_id not in builder.BEST_AVAILABLE_SMALLTALK_IDS:
                self.assertEqual(
                    "exactMapped", decisions[phrase_id]["semanticStatus"]
                )
                self.assertEqual(
                    "explicitSemanticRoute", decisions[phrase_id]["reasonCode"]
                )

    def test_c_projects_are_eight_shared_theme_sources(self) -> None:
        c_segments = [
            row for row in self.catalog["segments"] if row["level"] in ("c1", "c2")
        ]
        self.assertEqual(16, len(c_segments))
        self.assertTrue(
            all(len(row["assessmentRequirements"]) == 3 for row in c_segments)
        )
        projects = {
            row["id"]
            for row in self.authorities["contentReferences"]
            if row["kind"] == "project"
        }
        self.assertEqual(8, len(projects))
        project_cluster_uses = Counter(
            reference["id"]
            for cluster in self.catalog["contentClusters"]
            for reference in cluster["contentReferences"]
            if reference["kind"] == "project"
        )
        self.assertEqual({2}, set(project_cluster_uses.values()))

    def test_content_growth_appends_history_and_bumps_only_changed_cluster(self) -> None:
        previous = copy.deepcopy(self.catalog)
        current = copy.deepcopy(self.catalog)
        cluster = current["contentClusters"][0]
        old = previous["contentClusters"][0]
        old_requirements = {
            row["id"]: copy.deepcopy(row["assessmentRequirements"])
            for row in previous["segments"]
        }
        cluster["sourceSeedIds"].insert(0, "seed_future_practice_v1")
        cluster["contentReferences"].insert(
            0,
            {"kind": "smalltalk", "id": "smalltalk_future_practice_v1"},
        )

        builder._preserve_cluster_history(current, previous)

        self.assertEqual(old["revision"] + 1, cluster["revision"])
        self.assertEqual(
            old["sourceSeedIds"],
            cluster["sourceSeedIds"][: len(old["sourceSeedIds"])],
        )
        self.assertEqual(
            old["contentReferences"],
            cluster["contentReferences"][: len(old["contentReferences"])],
        )
        self.assertEqual(
            previous["contentClusters"][1]["revision"],
            current["contentClusters"][1]["revision"],
        )
        self.assertEqual(
            old_requirements,
            {
                row["id"]: row["assessmentRequirements"]
                for row in current["segments"]
            },
        )

    def test_review_only_content_requires_approved_live_non_assessment_promotion(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as raw_directory:
            root = Path(raw_directory)
            draft_path = root / "draft.json"
            manifest_path = root / "manifest.json"
            draft_path.write_text(
                json.dumps({"phrases": [{"id": "smalltalk_review_0001"}]}),
                encoding="utf-8",
            )
            manifest_path.write_text(
                json.dumps(
                    {
                        "status": "review_only_draft",
                        "artifacts": [
                            {
                                "kind": "smalltalk",
                                "draft": "draft.json",
                                "collection": "phrases",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            raw_ids = {"smalltalk": {"smalltalk_review_0001"}}
            with self.assertRaisesRegex(ValueError, "approved\\+live"):
                builder._validate_review_batch_boundaries(
                    raw_ids,
                    manifest_paths=(manifest_path,),
                    promotions={},
                    repository_root=root,
                )

            builder._validate_review_batch_boundaries(
                raw_ids,
                manifest_paths=(manifest_path,),
                promotions={
                    ("smalltalk", "smalltalk_review_0001"): {
                        "approved": True,
                        "live": True,
                        "canDoSegmentKey": "b1_complaint_repair",
                        "assessmentAuthority": False,
                    }
                },
                repository_root=root,
            )

            with self.assertRaisesRegex(ValueError, "non-assessment"):
                builder._validate_review_batch_boundaries(
                    raw_ids,
                    manifest_paths=(manifest_path,),
                    promotions={
                        ("smalltalk", "smalltalk_review_0001"): {
                            "approved": True,
                            "live": True,
                            "canDoSegmentKey": "b1_complaint_repair",
                            "assessmentAuthority": True,
                        }
                    },
                    repository_root=root,
                )

    def test_batch06_scenario_content_is_review_promoted(self) -> None:
        for scenario_id, target_segment in builder.BATCH06_PROVISIONAL_SCENARIO_TARGETS.items():
            promotion = builder.REVIEW_CONTENT_PROMOTIONS[("scenario", scenario_id)]
            self.assertEqual(target_segment, promotion["canDoSegmentKey"])

    def test_published_cluster_and_authority_history_cannot_move(self) -> None:
        previous = copy.deepcopy(self.catalog)
        removed = copy.deepcopy(self.catalog)
        removed["contentClusters"][0]["contentReferences"].pop()
        with self.assertRaisesRegex(ValueError, "cannot remove or move refs"):
            builder._preserve_cluster_history(removed, previous)

        previous_authorities = copy.deepcopy(self.authorities)
        changed_authorities = copy.deepcopy(self.authorities)
        changed_authorities["contentReferences"][0]["courseUnitId"] = (
            "different_course_unit"
        )
        with self.assertRaisesRegex(ValueError, "content authority"):
            builder._validate_authority_history(
                changed_authorities,
                previous_authorities,
            )

    def test_new_or_changed_smalltalk_requires_explicit_human_review(self) -> None:
        previous = copy.deepcopy(self.authorities)
        current = copy.deepcopy(self.authorities)
        audit = current["coverage"]["smalltalkRoutingAudit"]
        decision = copy.deepcopy(audit["phraseDecisions"][0])
        decision["phraseId"] = "smalltalk_a1_future_review"
        decision["phraseFingerprintSha256"] = "a" * 64
        audit["phraseDecisions"].append(decision)

        with self.assertRaisesRegex(ValueError, "requires an explicit"):
            builder._validate_smalltalk_review_history(
                current,
                previous,
                review_approvals={},
            )

        approval = {
            "phraseFingerprintSha256": decision["phraseFingerprintSha256"],
            "canDoSegmentId": decision["canDoSegmentId"],
            "canDoFingerprintSha256": decision["canDoFingerprintSha256"],
            "semanticStatus": decision["semanticStatus"],
            "reviewRevision": 1,
        }
        builder._validate_smalltalk_review_history(
            current,
            previous,
            review_approvals={decision["phraseId"]: approval},
        )
        builder._validate_smalltalk_review_history(
            copy.deepcopy(current),
            current,
            review_approvals={decision["phraseId"]: approval},
        )

    def test_conservative_smalltalk_status_downgrade_preserves_route(self) -> None:
        previous = copy.deepcopy(self.authorities)
        current = copy.deepcopy(self.authorities)
        old = previous["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"][0]
        decision = current["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"][0]
        old["semanticStatus"] = "approved"
        old["reasonCode"] = "topicAndFunctionMatch"
        old["reviewRevision"] = 1
        decision["semanticStatus"] = "bestAvailable"
        decision["reasonCode"] = "closestPublishedCoreSegment"
        decision["reviewRevision"] = 1

        builder._validate_smalltalk_review_history(
            current,
            previous,
            review_approvals={},
        )

        self.assertEqual(2, decision["reviewRevision"])


if __name__ == "__main__":
    unittest.main()
