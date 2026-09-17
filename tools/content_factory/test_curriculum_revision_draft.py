"""Approval, TTS, and production-task boundaries for pending scene revisions."""

import hashlib
import json
from pathlib import Path
import re
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scenario_corpus_pipeline as pipeline

ROOT = Path(__file__).resolve().parents[2]
DRAFT = ROOT / "tools/content_factory/review/canonical_120_revisions_20260916"
ORIGINALS = ROOT / "tools/content_factory/review/canonical_120_v1/candidates"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


class CurriculumRevisionDraftTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = read(DRAFT / "revision_manifest.json")
        cls.sources = pipeline.load_sources(ROOT)
        cls.candidates = [read(ROOT / row["proposedCandidate"]) for row in cls.manifest["candidates"]]

    def test_proposed_candidates_validate_and_hashes_cover_exact_bytes(self):
        for row, candidate in zip(self.manifest["candidates"], self.candidates):
            with self.subTest(scene=row["id"]):
                _, _, report = pipeline.load_and_validate_candidate(ROOT / row["proposedCandidate"], root=ROOT)
                report.require_ok()
                for field, digest in [("originalCandidate", "originalFileSha256"), ("proposedCandidate", "proposedFileSha256")]:
                    self.assertEqual(hashlib.sha256((ROOT / row[field]).read_bytes()).hexdigest(), row[digest])
        self.assertEqual(pipeline.candidate_set_hash(self.candidates), self.manifest["candidateSetSha256"])

    def test_old_approval_rejects_changed_candidates_in_actual_promotion_gate(self):
        for row, candidate in zip(self.manifest["candidates"], self.candidates):
            with self.subTest(level=row["level"]):
                originals = pipeline.load_level_candidates(ORIGINALS, row["level"], root=ROOT)
                self.assertEqual(pipeline.candidate_set_hash(originals), row["originalLevelCandidateSetSha256"])
                pipeline.assert_level_approved(level=row["level"], candidates=originals, sources=self.sources)
                proposed = [candidate if item["scenarioId"] == row["id"] else item for item in originals]
                self.assertEqual(pipeline.candidate_set_hash(proposed), row["proposedLevelCandidateSetSha256"])
                with self.assertRaisesRegex(pipeline.CorpusError, "changed after approval"):
                    pipeline.assert_level_approved(level=row["level"], candidates=proposed, sources=self.sources)

    def test_tts_pending_is_derived_from_current_text_and_character_voices(self):
        manifest = read(DRAFT / "tts_pending.json")
        self.assertEqual(manifest, pipeline.build_tts_pending_manifest(self.candidates, root=ROOT))
        self.assertFalse(manifest["synthesisRequested"])
        self.assertFalse(manifest["uploadRequested"])

    def test_production_tasks_use_learner_turns_and_word_sized_foils(self):
        edge = r'^[\s.,!?…·"”’]+|[\s.,!?…·"”’]+$'
        for candidate in self.candidates:
            scenario = candidate["scenario"]
            learner = {line["ko"]: line for line in scenario["dialog"] if line["speaker"] == "user"}
            for quest in scenario["quests"]:
                if quest["type"] != "satzBauen":
                    continue
                with self.subTest(quest=quest["id"]):
                    data = quest["data"]
                    line = learner[data["targetKo"]]
                    self.assertEqual(data["audioKo"], line["ko"])
                    self.assertEqual(data["promptDe"], line["de"])
                    self.assertEqual(data["promptEn"], line["en"])
                    self.assertTrue(set(quest["conceptIds"]) <= set(scenario["conceptIds"]))
                    tiles = data["distractors"]
                    self.assertEqual(len(set(tiles)), 3)
                    target = {re.sub(edge, "", word) for word in line["ko"].split()}
                    for tile in tiles:
                        self.assertNotRegex(tile, r"\s")
                        self.assertEqual(re.sub(edge, "", tile), tile)
                        self.assertNotIn(tile, target)

    def test_revisions_preserve_route_identity_and_existing_quest_ids(self):
        for row, candidate in zip(self.manifest["candidates"], self.candidates):
            old = read(ROOT / row["originalCandidate"])["scenario"]
            new = candidate["scenario"]
            for field in ["id", "level", "courseUnitId", "playerCharacterId", "participantIds", "conceptIds", "xpReward"]:
                self.assertEqual(old[field], new[field], (row["id"], field))
            quest_ids = [quest["id"] for quest in new["quests"]]
            self.assertEqual(len(quest_ids), len(set(quest_ids)))
            self.assertTrue({quest["id"] for quest in old["quests"]} <= set(quest_ids))

    def test_manifest_does_not_claim_promotion_or_human_approval(self):
        self.assertEqual(self.manifest["humanReviewStatus"], "pending")
        for field in ["runtimeChanged", "approvalAdded", "releaseReady"]:
            self.assertFalse(self.manifest[field])
        blueprint = {item["unitId"]: item for item in self.sources.course_unit_blueprint}
        for row in self.manifest["courseUnitCopy"]:
            original = blueprint[row["unitId"]]["canDo"]
            self.assertEqual(row["before"], original["en"])
            self.assertEqual(row["canonicalKo"], original["ko"])
            self.assertEqual(row["canonicalDe"], original["de"])
            self.assertEqual(row["humanReviewStatus"], "pending")


if __name__ == "__main__":
    unittest.main()
