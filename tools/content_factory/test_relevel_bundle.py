#!/usr/bin/env python3
"""Tests for tools/content_factory/relevel_bundle.py (task T2.3).

Fixture strategy: copy the real repository's ``assets/data`` (already known
to pass ``ContentValidator().validate()`` end to end -- see
``test_validate_content.py``'s ``test_current_repository_content_passes``,
and ``test_integrate_scenario_batch.py`` uses the same copytree-of-real-data
pattern) into a temp directory, then inject two small synthetic A1 vocab
packs this suite owns completely (id range 9900+, far above the live
corpus's ~427 A1 vocab ids) with matching cloze/satz/curriculum-manifest/
can-do wiring. Assertions target only the two synthetic packs, so they never
depend on which real packs happen to exist.
"""

from __future__ import annotations

import ast
import copy
import csv
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import relevel_bundle as rb
import relevel_ledger
from validate_content import ContentValidator, VOCAB_HEADER

REPO = SCRIPT_DIR.parents[1]

SOURCE_UNIT = "a1_01_greetings_hangul"
SOURCE_SEGMENT_ID = "segment_a1_01_greetings_hangul"
SOURCE_CLUSTER_ID = "cluster_a1_01_greetings_hangul_v1"
TARGET_UNIT_B1 = "b1_04_relationships"
TARGET_UNIT_A2 = "a2_06_study_work"

ALPHA_WORDS = [
    ("vocab_a1_9901", "가나테스트", "gana-teseuteu", "Testwort eins", "test word one"),
    ("vocab_a1_9902", "나다테스트", "nada-teseuteu", "Testwort zwei", "test word two"),
    ("vocab_a1_9903", "다라테스트", "dara-teseuteu", "Testwort drei", "test word three"),
]
BETA_WORDS = [
    ("vocab_a1_9911", "마바테스트", "maba-teseuteu", "Betawort eins", "beta word one"),
    ("vocab_a1_9912", "바사테스트", "basa-teseuteu", "Betawort zwei", "beta word two"),
    ("vocab_a1_9913", "사아테스트", "saa-teseuteu", "Betawort drei", "beta word three"),
]

VOCAB_PACK_SERVICE_FIXTURE = """
class VocabPackService {
  static const Map<String, (String, String)> packDisplayMap = {
    // A1
    'a1_relvtest_alpha': ('Relvtest Alpha DE', 'Relvtest Alpha EN'),
    'a1_relvtest_beta': ('Relvtest Beta DE', 'Relvtest Beta EN'),
    // A2
    'a2_other_pack': ('Other DE', 'Other EN'),
  };

  static const Map<String, int> packOrderInLevel = {
    // A1
    'a1_relvtest_alpha': 1,
    'a1_relvtest_beta': 2,
    // A2
    'a2_other_pack': 1,
    // B1
    'b1_existing_pack': 1,
  };
}
"""

PACK_ARTWORK_CATALOG_FIXTURE = """
abstract final class PackArtworkCatalog {
  static const dedicatedPackIds = <String>{
    'a1_relvtest_alpha_1',
  };
}
"""

# Covers both shapes `edit_dancheong_motifs` must handle: a plain
# single-literal case ('a1_relvtest_alpha') and an OR-joined case split
# across lines ('a1_relvtest_beta' || 'a1_relvtest_beta_legacy') -- the
# latter's sibling alternative must survive the rename untouched.
DANCHEONG_STAMP_FIXTURE = """
DancheongMotif motifForPackId(String packId) {
  final base = _baseOf(packId);
  return switch (base) {
    'a1_relvtest_alpha' => DancheongMotif.crane,
    'a1_relvtest_beta' ||
    'a1_relvtest_beta_legacy' => DancheongMotif.changsal,
    _ => DancheongMotif.lotus,
  };
}
"""


class RelevelBundleFixture(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="relevel-bundle-test-")
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name) / "repo"
        data = self.root / "assets" / "data"
        shutil.copytree(REPO / "assets" / "data", data)

        (self.root / "tools" / "content_factory").mkdir(parents=True, exist_ok=True)
        audit_manifest_path = self.root / "tools" / "content_factory" / "content_audit_manifest.json"
        shutil.copy2(
            REPO / "tools" / "content_factory" / "content_audit_manifest.json",
            audit_manifest_path,
        )
        # This fixture adds 6 vocab/cloze/satz rows (2 packs x 3 words) on
        # top of the real corpus -- content_audit_manifest.json's counts must
        # agree with the live inventory or validate_audit_manifest() fails
        # before relevel_bundle.py's own logic is even exercised.
        audit_manifest = json.loads(audit_manifest_path.read_text(encoding="utf-8"))
        for source in audit_manifest["sources"]:
            if source["kind"] in ("vocab", "cloze", "satz"):
                source["count"] += 6
        audit_manifest_path.write_text(
            json.dumps(audit_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
        )
        (self.root / "functions" / "analyze_korean_text").mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            REPO / "functions" / "analyze_korean_text" / "grammar_patterns.json",
            self.root / "functions" / "analyze_korean_text" / "grammar_patterns.json",
        )

        (self.root / "lib" / "services").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "services" / "vocab_pack_service.dart").write_text(
            VOCAB_PACK_SERVICE_FIXTURE, encoding="utf-8",
        )
        (self.root / "lib" / "data").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "data" / "pack_artwork_catalog.dart").write_text(
            PACK_ARTWORK_CATALOG_FIXTURE, encoding="utf-8",
        )
        (self.root / "lib" / "widgets" / "sori").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart").write_text(
            DANCHEONG_STAMP_FIXTURE, encoding="utf-8",
        )
        artwork_dir = self.root / "assets" / "illustrations" / "packs"
        artwork_dir.mkdir(parents=True, exist_ok=True)
        (artwork_dir / "a1_relvtest_alpha_1.webp").write_bytes(b"fake-webp")

        self.ledger_path = Path(self._tmp.name) / "relevel_ledger.json"
        shutil.copy2(REPO / "tools" / "content_factory" / "relevel_ledger.json", self.ledger_path)

        self._inject_synthetic_packs(data)

    # ---- fixture construction -------------------------------------------

    def _inject_synthetic_packs(self, data: Path) -> None:
        self._add_vocab_cloze_satz(data, "a1_relvtest_alpha_1", "Relvtestalpha", ALPHA_WORDS)
        self._add_vocab_cloze_satz(data, "a1_relvtest_beta_1", "Relvtestbeta", BETA_WORDS)

        curriculum_path = data / "curriculum_manifest.json"
        curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
        curriculum["vocabPackUnitMap"]["a1_relvtest_alpha"] = SOURCE_UNIT
        curriculum["vocabPackUnitMap"]["a1_relvtest_beta"] = SOURCE_UNIT
        curriculum["clozeTopicUnitMap"]["a1:relvtestalpha"] = SOURCE_UNIT
        curriculum["clozeTopicUnitMap"]["a1:relvtestbeta"] = SOURCE_UNIT
        curriculum_path.write_text(json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        self._wire_can_do(data, "a1_relvtest_alpha_1", ALPHA_WORDS)
        self._wire_can_do(data, "a1_relvtest_beta_1", BETA_WORDS)

    def _add_vocab_cloze_satz(self, data: Path, pack_id: str, topic: str, words) -> None:
        vocab_path = data / "korean_vocab.csv"
        with vocab_path.open(encoding="utf-8", newline="") as handle:
            reader = csv.reader(handle)
            header = next(reader)
            assert header == VOCAB_HEADER, header
            rows = [dict(zip(header, row)) for row in reader if row]

        cloze_path = data / rb.CLOZE_JSON
        cloze_root = json.loads(cloze_path.read_text(encoding="utf-8"))
        satz_path = data / rb.SATZ_JSON
        satz_root = json.loads(satz_path.read_text(encoding="utf-8"))

        for order, (vocab_id, korean, romanization, german, english) in enumerate(words, start=1):
            example_ko = f"{korean} 예문입니다."
            rows.append({
                "korean": korean, "romanization": romanization, "german": german,
                "level": "A1", "pos_de": "Nomen",
                "example_korean": example_ko, "example_german": f"{german} Beispielsatz.",
                "topic": topic, "pack_id": pack_id, "pack_order": str(order),
                "is_review_boss": "true" if order > 1 else "false",
                "english": english, "pos_en": "noun",
                "example_english": f"{english} example sentence.", "id": vocab_id,
            })

            cloze_id = f"cloze_{vocab_id.split('_', 1)[1]}"
            answer = korean
            full_ko = example_ko
            sentence_ko = full_ko.replace(answer, "＿＿＿", 1)
            cloze_root["items"].append({
                "id": cloze_id, "level": "a1", "sentenceKo": sentence_ko, "answer": answer,
                "fullKo": full_ko, "de": f"{german} Beispielsatz.", "en": f"{english} example sentence.",
                "distractors": ["오답1", "오답2"], "topic": topic,
            })

            satz_id = f"satz_{vocab_id.split('_', 1)[1]}"
            satz_root["items"].append({
                "id": satz_id, "level": "a1", "targetKo": example_ko,
                "promptDe": f"{german} Beispielsatz.", "promptEn": f"{english} example sentence.",
                "distractors": ["오답1", "오답2"], "vocabKo": korean,
            })

        with vocab_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.writer(handle, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
            writer.writerow(VOCAB_HEADER)
            for row in rows:
                writer.writerow([row[column] for column in VOCAB_HEADER])

        rb._refresh_game_meta(cloze_root, "items")
        rb._refresh_game_meta(satz_root, "items")
        cloze_path.write_text(json.dumps(cloze_root, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        satz_path.write_text(json.dumps(satz_root, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def _wire_can_do(self, data: Path, pack_id: str, words) -> None:
        auth_path = data / rb.CAN_DO_AUTHORITIES_JSON
        authorities = json.loads(auth_path.read_text(encoding="utf-8"))
        seed_id = f"seed_vocab_pack_{pack_id}_v1"
        authorities["sourceSeeds"].append({"id": seed_id, "level": "a1"})
        authorities["contentReferences"].append({
            "kind": "vocabPack", "id": pack_id, "level": "a1",
            "sourceSeedId": seed_id, "courseUnitId": SOURCE_UNIT,
        })
        authorities["coverage"]["directReferenceCounts"]["vocabPack"] += 1

        vocab_rows = {
            vocab_id: {
                "korean": korean, "romanization": romanization, "german": german, "level": "A1",
                "pos_de": "Nomen", "example_korean": f"{korean} 예문입니다.",
                "example_german": f"{german} Beispielsatz.", "topic": "",
                "pack_id": pack_id, "pack_order": "1", "is_review_boss": "false",
                "english": english, "pos_en": "noun",
                "example_english": f"{english} example sentence.", "id": vocab_id,
            }
            for vocab_id, korean, romanization, german, english in words
        }
        # pack_order/topic/is_review_boss are the only fields that legitimately
        # differ per row and are irrelevant to the fingerprint identity for
        # this fixture's purposes (the real generator hashes the *actual* row
        # dict; this rebuilds the same shape rb._migrate_vocab will produce).
        for vocab_id, korean, romanization, german, english in words:
            cloze_id = f"cloze_{vocab_id.split('_', 1)[1]}"
            satz_id = f"satz_{vocab_id.split('_', 1)[1]}"
            row = vocab_rows[vocab_id]
            fingerprint = rb._fingerprint(row)
            authorities["coverage"]["inheritedContentReferences"].append({
                "kind": "cloze", "id": cloze_id, "sourceKind": "vocabPack", "sourceId": pack_id,
                "sourceVocabId": vocab_id, "sourceVocabFingerprintSha256": fingerprint,
                "level": "a1", "canDoSegmentId": SOURCE_SEGMENT_ID, "courseUnitId": SOURCE_UNIT,
            })
            authorities["coverage"]["inheritedContentReferences"].append({
                "kind": "satz", "id": satz_id, "sourceKind": "vocabPack", "sourceId": pack_id,
                "sourceVocabId": vocab_id, "sourceVocabFingerprintSha256": fingerprint,
                "level": "a1", "canDoSegmentId": SOURCE_SEGMENT_ID, "courseUnitId": SOURCE_UNIT,
            })
            authorities["coverage"]["inheritedReferenceCounts"]["cloze"] += 1
            authorities["coverage"]["inheritedReferenceCounts"]["satz"] += 1
        auth_path.write_text(json.dumps(authorities, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        segments_path = data / rb.CAN_DO_SEGMENTS_JSON
        segments_doc = json.loads(segments_path.read_text(encoding="utf-8"))
        cluster = next(c for c in segments_doc["contentClusters"] if c["id"] == SOURCE_CLUSTER_ID)
        cluster["contentReferences"].append({"kind": "vocabPack", "id": pack_id})
        cluster["sourceSeedIds"].append(seed_id)
        segments_path.write_text(json.dumps(segments_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # ---- helpers ----------------------------------------------------------

    def _snapshot(self) -> dict[Path, bytes]:
        paths = [
            self.root / "assets" / "data" / name for name in rb._STAGED_DATA_FILES
        ] + [
            self.root / "lib" / "services" / "vocab_pack_service.dart",
            self.root / "lib" / "data" / "pack_artwork_catalog.dart",
            self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart",
            self.root / "assets" / "illustrations" / "packs" / "a1_relvtest_alpha_1.webp",
            self.ledger_path,
        ]
        snapshot = {}
        for path in paths:
            snapshot[path] = path.read_bytes() if path.exists() else None
        aliases_path = self.root / "lib" / "data" / "pack_progress_aliases.dart"
        snapshot[aliases_path] = aliases_path.read_bytes() if aliases_path.exists() else None
        return snapshot

    def _assert_unchanged(self, snapshot: dict[Path, bytes]) -> None:
        for path, content in snapshot.items():
            current = path.read_bytes() if path.exists() else None
            self.assertEqual(content, current, f"{path} changed unexpectedly")

    def _bundle(self, moves: list[dict]) -> rb.BundleFile:
        return rb.load_bundle_from_dict({"batch": "TEST", "moves": moves})

    def _standard_moves(self) -> list[dict]:
        return [
            {
                "bundle": "a1_relvtest_alpha_1", "from": "a1", "to": "b1",
                "newPackId": "b1_relvtest_alpha_1", "courseUnitId": TARGET_UNIT_B1,
                "conceptIds": ["concept_b1_relationships"], "scenarios": [],
                "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "test move alpha",
            },
            {
                "bundle": "a1_relvtest_beta_1", "from": "a1", "to": "a2",
                "newPackId": "a2_relvtest_beta_1", "courseUnitId": TARGET_UNIT_A2,
                "conceptIds": ["concept_a2_work_study"], "scenarios": [],
                "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "test move beta",
            },
        ]


class DryRunTest(RelevelBundleFixture):
    def test_dry_run_computes_plan_and_changes_nothing(self) -> None:
        snapshot = self._snapshot()
        bundle = self._bundle(self._standard_moves())
        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)

        self.assertEqual(2, len(report.packs))
        by_bundle = {p.bundle: p for p in report.packs}
        self.assertEqual(3, by_bundle["a1_relvtest_alpha_1"].n_words)
        self.assertEqual(3, by_bundle["a1_relvtest_alpha_1"].n_cloze)
        self.assertEqual(3, by_bundle["a1_relvtest_alpha_1"].n_satz)
        # b1_04_relationships has 3 real candidate clusters (encouragement,
        # intimate_feelings, social_invitation) and none shares a slug token
        # with "relationships" -- the tie-break (revision desc, id asc) picks
        # intimate_feelings, the highest-revision real cluster among them.
        self.assertEqual("cluster_b1_intimate_feelings_v1", by_bundle["a1_relvtest_alpha_1"].target_cluster_id)
        self.assertTrue(by_bundle["a1_relvtest_alpha_1"].has_dedicated_artwork)
        self.assertFalse(by_bundle["a1_relvtest_beta_1"].has_dedicated_artwork)
        self.assertEqual("HEURISTIC: unique candidate", by_bundle["a1_relvtest_beta_1"].cluster_choice_note)

        self._assert_unchanged(snapshot)


class ApplyTest(RelevelBundleFixture):
    def test_apply_moves_everything(self) -> None:
        bundle = self._bundle(self._standard_moves())
        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        data = self.root / "assets" / "data"

        # vocab CSV
        with (data / "korean_vocab.csv").open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        alpha_rows = [r for r in rows if r["pack_id"] == "b1_relvtest_alpha_1"]
        self.assertEqual(3, len(alpha_rows))
        self.assertTrue(all(r["level"] == "B1" for r in alpha_rows))
        self.assertFalse(any(r["pack_id"] == "a1_relvtest_alpha_1" for r in rows))
        beta_rows = [r for r in rows if r["pack_id"] == "a2_relvtest_beta_1"]
        self.assertEqual(3, len(beta_rows))
        self.assertTrue(all(r["level"] == "A2" for r in beta_rows))
        # id/pack_order/is_review_boss untouched
        self.assertEqual({"vocab_a1_9901", "vocab_a1_9902", "vocab_a1_9903"}, {r["id"] for r in alpha_rows})

        # cloze / satz
        cloze_items = json.loads((data / rb.CLOZE_JSON).read_text(encoding="utf-8"))["items"]
        satz_items = json.loads((data / rb.SATZ_JSON).read_text(encoding="utf-8"))["items"]
        alpha_cloze = [c for c in cloze_items if c["id"] in {"cloze_a1_9901", "cloze_a1_9902", "cloze_a1_9903"}]
        self.assertEqual(3, len(alpha_cloze))
        self.assertTrue(all(c["level"] == "b1" for c in alpha_cloze))
        beta_satz = [s for s in satz_items if s["id"] in {"satz_a1_9911", "satz_a1_9912", "satz_a1_9913"}]
        self.assertEqual(3, len(beta_satz))
        self.assertTrue(all(s["level"] == "a2" for s in beta_satz))

        # curriculum_manifest.json
        curriculum = json.loads((data / rb.CURRICULUM_JSON).read_text(encoding="utf-8"))
        self.assertNotIn("a1_relvtest_alpha", curriculum["vocabPackUnitMap"])
        self.assertEqual(TARGET_UNIT_B1, curriculum["vocabPackUnitMap"]["b1_relvtest_alpha"])
        self.assertEqual(TARGET_UNIT_A2, curriculum["vocabPackUnitMap"]["a2_relvtest_beta"])
        self.assertNotIn("a1:relvtestalpha", curriculum["clozeTopicUnitMap"])
        self.assertEqual(TARGET_UNIT_B1, curriculum["clozeTopicUnitMap"]["b1:relvtestalpha"])
        self.assertEqual(TARGET_UNIT_A2, curriculum["clozeTopicUnitMap"]["a2:relvtestbeta"])

        # can-do authorities + segments
        authorities = json.loads((data / rb.CAN_DO_AUTHORITIES_JSON).read_text(encoding="utf-8"))
        direct = {(r["kind"], r["id"]): r for r in authorities["contentReferences"]}
        self.assertNotIn(("vocabPack", "a1_relvtest_alpha_1"), direct)
        self.assertEqual("b1", direct[("vocabPack", "b1_relvtest_alpha_1")]["level"])
        self.assertEqual(TARGET_UNIT_B1, direct[("vocabPack", "b1_relvtest_alpha_1")]["courseUnitId"])
        inherited_alpha = [
            r for r in authorities["coverage"]["inheritedContentReferences"]
            if r["sourceId"] == "b1_relvtest_alpha_1"
        ]
        self.assertEqual(6, len(inherited_alpha))
        self.assertTrue(all(r["level"] == "b1" for r in inherited_alpha))
        self.assertTrue(all(r["courseUnitId"] == TARGET_UNIT_B1 for r in inherited_alpha))
        alpha_pack = by_bundle_report(report, "a1_relvtest_alpha_1")
        self.assertTrue(all(r["canDoSegmentId"] == alpha_pack.target_segment_id for r in inherited_alpha))

        segments_doc = json.loads((data / rb.CAN_DO_SEGMENTS_JSON).read_text(encoding="utf-8"))
        clusters_by_id = {c["id"]: c for c in segments_doc["contentClusters"]}
        source_cluster = clusters_by_id[SOURCE_CLUSTER_ID]
        source_ids = {r["id"] for r in source_cluster["contentReferences"] if r["kind"] == "vocabPack"}
        self.assertNotIn("a1_relvtest_alpha_1", source_ids)
        self.assertNotIn("a1_relvtest_beta_1", source_ids)
        self.assertEqual(4, source_cluster["revision"])  # 2 (fixture baseline) + 1 per move out (x2)
        target_cluster = clusters_by_id[alpha_pack.target_cluster_id]
        target_ids = {r["id"] for r in target_cluster["contentReferences"] if r["kind"] == "vocabPack"}
        self.assertIn("b1_relvtest_alpha_1", target_ids)

        # ledger
        ledger = relevel_ledger.load_ledger(self.ledger_path)
        self.assertTrue(ledger.allows("vocab", "vocab_a1_9901", "b1"))
        self.assertTrue(ledger.allows("vocab", "vocab_a1_9913", "a2"))
        self.assertTrue(ledger.allows("cloze", "cloze_a1_9901", "b1"))
        self.assertTrue(ledger.allows("satz", "satz_a1_9911", "a2"))

        # Dart edits
        vps_text = (self.root / "lib" / "services" / "vocab_pack_service.dart").read_text(encoding="utf-8")
        self.assertNotIn("'a1_relvtest_alpha'", vps_text)
        self.assertIn("'b1_relvtest_alpha'", vps_text)
        self.assertIn("'a2_relvtest_beta'", vps_text)
        self.assertIn("Relvtest Alpha DE", vps_text)  # label preserved

        pac_text = (self.root / "lib" / "data" / "pack_artwork_catalog.dart").read_text(encoding="utf-8")
        self.assertNotIn("'a1_relvtest_alpha_1'", pac_text)
        self.assertIn("'b1_relvtest_alpha_1'", pac_text)
        self.assertFalse((self.root / "assets" / "illustrations" / "packs" / "a1_relvtest_alpha_1.webp").exists())
        self.assertTrue((self.root / "assets" / "illustrations" / "packs" / "b1_relvtest_alpha_1.webp").exists())

        aliases_text = (self.root / "lib" / "data" / "pack_progress_aliases.dart").read_text(encoding="utf-8")
        self.assertIn("'b1_relvtest_alpha_1': 'a1_relvtest_alpha_1'", aliases_text)
        self.assertIn("'a2_relvtest_beta_1': 'a1_relvtest_beta_1'", aliases_text)

        # Dancheong motif switch: plain-pattern base id renamed, OR-pattern's
        # matching side renamed, sibling alternative untouched.
        dancheong_text = (
            self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart"
        ).read_text(encoding="utf-8")
        self.assertNotIn("'a1_relvtest_alpha'", dancheong_text)
        self.assertIn("'b1_relvtest_alpha' => DancheongMotif.crane,", dancheong_text)
        self.assertNotIn("'a1_relvtest_beta' ", dancheong_text)
        self.assertIn("'a2_relvtest_beta' ||", dancheong_text)
        self.assertIn("'a1_relvtest_beta_legacy' => DancheongMotif.changsal,", dancheong_text)
        self.assertEqual(
            [("a1_relvtest_alpha", "b1_relvtest_alpha", "renamed"),
             ("a1_relvtest_beta", "a2_relvtest_beta", "renamed")],
            report.dancheong_motif_renames,
        )

        # The applied repository is genuinely valid by the same gates CI runs.
        self.assertEqual([], ContentValidator(self.root, ledger=ledger).validate())
        self.assertEqual([], rb.check_can_do_consistency(self.root))


class RollbackTest(RelevelBundleFixture):
    def test_bad_concept_ids_fails_and_leaves_everything_untouched(self) -> None:
        moves = self._standard_moves()
        moves[0]["conceptIds"] = ["concept_totally_unrelated_to_the_unit"]
        bundle = self._bundle(moves)
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        self._assert_unchanged(snapshot)

    def test_dry_run_also_rejects_bad_concept_ids(self) -> None:
        moves = self._standard_moves()
        moves[1]["conceptIds"] = ["concept_does_not_exist"]
        bundle = self._bundle(moves)
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)

        self._assert_unchanged(snapshot)


class LineEndingsTest(RelevelBundleFixture):
    """T2.3-R1 STEP 1a: every file the tool writes must be LF-only, even on
    Windows (Path.write_text/open(path, "a") both translate "\\n" -> "\\r\\n"
    there, which is exactly what produced the CRLF/"mixed" defects Fable
    found)."""

    def test_every_written_file_is_lf_only(self) -> None:
        bundle = self._bundle(self._standard_moves())
        rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        data = self.root / "assets" / "data"
        written = [data / name for name in rb._STAGED_DATA_FILES] + [
            self.root / "lib" / "services" / "vocab_pack_service.dart",
            self.root / "lib" / "data" / "pack_artwork_catalog.dart",
            self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart",
            self.root / "lib" / "data" / "pack_progress_aliases.dart",
        ]
        for path in written:
            content = path.read_bytes()
            self.assertNotIn(b"\r", content, f"{path} contains \\r")

    def test_report_append_is_lf_and_idempotent(self) -> None:
        bundle = self._bundle(self._standard_moves())
        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        report_path = self.root / "relevel_report.md"
        report_path.write_text("# Plan doc\n\nSome Fable-authored prose.\n", encoding="utf-8")

        rb.append_report_section(report_path, report, apply=True)
        first_content = report_path.read_bytes()
        self.assertNotIn(b"\r", first_content)
        self.assertEqual(1, first_content.count(b"## \xec\x8b\xa4\xed\x96\x89 \xea\xb2\xb0\xea\xb3\xbc"))

        rb.append_report_section(report_path, report, apply=True)
        second_content = report_path.read_bytes()
        self.assertNotIn(b"\r", second_content)
        self.assertEqual(1, second_content.count(b"## \xec\x8b\xa4\xed\x96\x89 \xea\xb2\xb0\xea\xb3\xbc"))
        # A second run with unchanged input reproduces the same section
        # (replace, not append-a-duplicate) -- the prose above it survives.
        self.assertEqual(first_content, second_content)
        self.assertIn(b"Some Fable-authored prose.", second_content)


class CanDoClusterIdTest(RelevelBundleFixture):
    """T2.3-R1 STEP 1b: an explicit `canDoClusterId` move field overrides the
    slug-overlap heuristic (and must be one of the real candidates)."""

    def test_explicit_candidate_is_honored_over_heuristic(self) -> None:
        moves = self._standard_moves()
        # b1_04_relationships has 3 real candidates; the heuristic tie-break
        # would pick cluster_b1_intimate_feelings_v1 (highest revision) --
        # explicitly rule for a different real candidate instead.
        moves[0]["canDoClusterId"] = "cluster_b1_encouragement_v1"
        bundle = self._bundle(moves)
        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)

        alpha = by_bundle_report(report, "a1_relvtest_alpha_1")
        self.assertEqual("cluster_b1_encouragement_v1", alpha.target_cluster_id)
        self.assertEqual("explicit (Fable ruling)", alpha.cluster_choice_note)

    def test_explicit_non_candidate_raises_naming_candidates(self) -> None:
        moves = self._standard_moves()
        moves[0]["canDoClusterId"] = "cluster_b1_totally_wrong_v1"
        bundle = self._bundle(moves)

        with self.assertRaises(rb.RelevelError) as ctx:
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)
        message = str(ctx.exception)
        self.assertIn("cluster_b1_totally_wrong_v1", message)
        self.assertIn("cluster_b1_encouragement_v1", message)
        self.assertIn("cluster_b1_intimate_feelings_v1", message)
        self.assertIn("cluster_b1_social_invitation_v1", message)


class MoveShapeTest(unittest.TestCase):
    def _base_move(self) -> dict:
        return {
            "bundle": "a1_x_1", "from": "a1", "to": "b1", "newPackId": "b1_x_1",
            "courseUnitId": "b1_04_relationships", "conceptIds": ["concept_b1_relationships"],
            "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
        }

    def test_nonempty_scenarios_raises_not_implemented(self) -> None:
        move = self._base_move()
        move["scenarios"] = [{"id": "some_scenario"}]
        with self.assertRaises(NotImplementedError):
            rb.Move.from_dict(move)

    def test_nonempty_smalltalk_raises_not_implemented(self) -> None:
        move = self._base_move()
        move["smalltalk"] = ["smalltalk_a1_0001"]
        with self.assertRaises(NotImplementedError):
            rb.Move.from_dict(move)

    def test_non_auto_cloze_raises_not_implemented(self) -> None:
        move = self._base_move()
        move["cloze"] = ["cloze_a1_0001"]
        with self.assertRaises(NotImplementedError):
            rb.Move.from_dict(move)

    def test_same_from_and_to_is_rejected(self) -> None:
        move = self._base_move()
        move["to"] = "a1"
        move["newPackId"] = "a1_x_2"
        with self.assertRaises(rb.RelevelError):
            rb.Move.from_dict(move)

    def test_valid_move_round_trips(self) -> None:
        move = rb.Move.from_dict(self._base_move())
        self.assertEqual("a1_x_1", move.bundle)
        self.assertEqual("b1", move.to_level)
        self.assertIsNone(move.can_do_cluster_id)
        self.assertIsNone(move.pack_order)

    def test_can_do_cluster_id_and_pack_order_round_trip(self) -> None:
        raw = self._base_move()
        raw["canDoClusterId"] = "cluster_b1_x_v1"
        raw["packOrder"] = 11
        move = rb.Move.from_dict(raw)
        self.assertEqual("cluster_b1_x_v1", move.can_do_cluster_id)
        self.assertEqual(11, move.pack_order)

    def test_blank_can_do_cluster_id_rejected(self) -> None:
        raw = self._base_move()
        raw["canDoClusterId"] = "   "
        with self.assertRaises(rb.RelevelError):
            rb.Move.from_dict(raw)

    def test_non_positive_pack_order_rejected(self) -> None:
        raw = self._base_move()
        raw["packOrder"] = 0
        with self.assertRaises(rb.RelevelError):
            rb.Move.from_dict(raw)


class PackOrderBumpTest(unittest.TestCase):
    """T2.3-R1 STEP 1c: explicit `packOrder` inserts at that exact number,
    shifting every existing same-level entry whose order is >= it by +1."""

    FIXTURE = """
class VocabPackService {
  static const Map<String, (String, String)> packDisplayMap = {
    'a1_old_pack': ('Old DE', 'Old EN'),
    'a2_slot_a': ('A DE', 'A EN'),
  };

  static const Map<String, int> packOrderInLevel = {
    'a1_old_pack': 5,
    'a2_slot_a': 10,
    'a2_slot_b': 11,
    'a2_slot_c': 12,
  };
}
"""

    def test_insert_at_11_shifts_ge_entries(self) -> None:
        move = rb.Move.from_dict({
            "bundle": "a1_old_pack_1", "from": "a1", "to": "a2",
            "newPackId": "a2_new_pack_1", "courseUnitId": "a2_06_study_work",
            "conceptIds": ["concept_a2_work_study"], "scenarios": [], "cloze": "auto",
            "satz": "auto", "smalltalk": [], "reason": "r", "packOrder": 11,
        })
        report = rb.MigrationReport(batch="TEST")
        new_text = rb.edit_vocab_pack_service(self.FIXTURE, (move,), report)

        _, order_body, _ = rb._extract_dart_block(new_text, rb.ORDER_MAP_OPEN, rb._CLOSE_BRACE_RE)
        _, entries = rb._parse_dart_entries(order_body)
        values = {key: value_text for key, _, value_text in entries}
        self.assertEqual(": 10,", values["a2_slot_a"])
        self.assertEqual(": 11,", values["a2_new_pack"])
        self.assertEqual(": 12,", values["a2_slot_b"])
        self.assertEqual(": 13,", values["a2_slot_c"])
        self.assertEqual([("a1_old_pack", "a2_new_pack", 11)], report.dart_order_map_renames)

    def test_second_insert_shifting_first_reports_final_value(self) -> None:
        # T2.3-R2: two same-level explicit-packOrder inserts at the same
        # slot -- the second move's `_bump_order_entries` shifts the FIRST
        # move's already-inserted entry from 10 to 11. The report must show
        # 11 for the first move, not the 10 that was only true right after
        # that move's own dart_rename_entry call.
        fixture = """
class VocabPackService {
  static const Map<String, (String, String)> packDisplayMap = {
    'a1_old_pack_x': ('X DE', 'X EN'),
    'a1_old_pack_y': ('Y DE', 'Y EN'),
  };

  static const Map<String, int> packOrderInLevel = {
    'a1_old_pack_x': 5,
    'a1_old_pack_y': 6,
    'a2_slot_a': 10,
  };
}
"""
        moves = (
            rb.Move.from_dict({
                "bundle": "a1_old_pack_x_1", "from": "a1", "to": "a2", "newPackId": "a2_new_x_1",
                "courseUnitId": "a2_06_study_work", "conceptIds": ["concept_a2_work_study"],
                "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
                "packOrder": 10,
            }),
            rb.Move.from_dict({
                "bundle": "a1_old_pack_y_1", "from": "a1", "to": "a2", "newPackId": "a2_new_y_1",
                "courseUnitId": "a2_06_study_work", "conceptIds": ["concept_a2_work_study"],
                "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
                "packOrder": 10,
            }),
        )
        report = rb.MigrationReport(batch="TEST")
        new_text = rb.edit_vocab_pack_service(fixture, moves, report)

        _, order_body, _ = rb._extract_dart_block(new_text, rb.ORDER_MAP_OPEN, rb._CLOSE_BRACE_RE)
        _, entries = rb._parse_dart_entries(order_body)
        values = {key: value_text for key, _, value_text in entries}
        self.assertEqual(": 12,", values["a2_slot_a"])
        self.assertEqual(": 11,", values["a2_new_x"])  # shifted up by move 2's insert
        self.assertEqual(": 10,", values["a2_new_y"])
        self.assertEqual(
            [("a1_old_pack_x", "a2_new_x", 11), ("a1_old_pack_y", "a2_new_y", 10)],
            report.dart_order_map_renames,
        )


class DancheongMotifRenameTest(unittest.TestCase):
    """T2.3-R1 STEP 1d: rename base-id literals inside motifForPackId's
    switch, covering a plain pattern, an OR pattern (only the matching
    alternative moves), and a base id absent from the switch entirely."""

    FIXTURE = """
DancheongMotif motifForPackId(String packId) {
  final base = _baseOf(packId);
  return switch (base) {
    'a1_old_pack' => DancheongMotif.crane,
    'a1_other' ||
    'a1_other_2026' => DancheongMotif.changsal,
    _ => DancheongMotif.lotus,
  };
}
"""

    def _move(self, bundle: str, new_pack_id: str) -> rb.Move:
        return rb.Move.from_dict({
            "bundle": bundle, "from": "a1", "to": "a2", "newPackId": new_pack_id,
            "courseUnitId": "a2_06_study_work", "conceptIds": ["concept_a2_work_study"],
            "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
        })

    def test_plain_or_and_missing_patterns(self) -> None:
        moves = (
            self._move("a1_old_pack_1", "a2_new_pack_1"),
            self._move("a1_other_1", "a2_other_renamed_1"),
            self._move("a1_missing_1", "a2_missing_renamed_1"),
        )
        report = rb.MigrationReport(batch="TEST")
        new_text = rb.edit_dancheong_motifs(self.FIXTURE, moves, report)

        self.assertNotIn("'a1_old_pack'", new_text)
        self.assertIn("'a2_new_pack' => DancheongMotif.crane,", new_text)
        self.assertNotIn("'a1_other' ", new_text)
        self.assertIn("'a2_other_renamed' ||", new_text)
        self.assertIn("'a1_other_2026' => DancheongMotif.changsal,", new_text)  # sibling untouched

        self.assertEqual(
            [
                ("a1_old_pack", "a2_new_pack", "renamed"),
                ("a1_other", "a2_other_renamed", "renamed"),
                ("a1_missing", "a2_missing_renamed", "no motif entry"),
            ],
            report.dancheong_motif_renames,
        )


class DancheongMotifGenericSiblingRenameTest(unittest.TestCase):
    """T2.3-R2: `_baseOf` (Dart) strips only ONE trailing all-digit
    segment, so a base id ending in one (a "_2026" revision year) is
    ambiguous -- a sibling live pack id with no further numeric suffix
    bases to the *generic* (year-stripped) form instead. The switch pairs
    both shapes in one OR-group; moving the "_2026" pack must rename both
    literals, matching the live `a2_housing_search`/`b1_housing_search`
    case exactly (docs/data/relevel_L2a_report.md 2026-09 rework)."""

    FIXTURE = """
DancheongMotif motifForPackId(String packId) {
  final base = _baseOf(packId);
  return switch (base) {
    'a2_housing_search_other' => DancheongMotif.wave,
    'a2_housing_search' ||
    'a2_housing_search_2026' => DancheongMotif.changsal,
    _ => DancheongMotif.lotus,
  };
}
"""

    def _move(self, bundle: str, new_pack_id: str, *, from_level="a2", to_level="b1") -> rb.Move:
        return rb.Move.from_dict({
            "bundle": bundle, "from": from_level, "to": to_level, "newPackId": new_pack_id,
            "courseUnitId": "b1_06_life_capstone", "conceptIds": ["concept_b1_daily_life"],
            "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
        })

    def test_2026_move_renames_both_the_specific_and_generic_literal(self) -> None:
        move = self._move("a2_housing_search_2026_1", "b1_housing_search_2026_1")
        report = rb.MigrationReport(batch="TEST")
        new_text = rb.edit_dancheong_motifs(self.FIXTURE, (move,), report)

        self.assertIn(
            "'b1_housing_search' ||\n    'b1_housing_search_2026' => DancheongMotif.changsal,",
            new_text,
        )
        self.assertNotIn("'a2_housing_search'", new_text)
        self.assertNotIn("'a2_housing_search_2026'", new_text)
        # A plain rename must never touch a literal that merely has the old
        # id as a *prefix* -- this unrelated, unpaired entry stays intact.
        self.assertIn("'a2_housing_search_other' => DancheongMotif.wave,", new_text)

        self.assertEqual(
            [
                ("a2_housing_search_2026", "b1_housing_search_2026", "renamed"),
                ("a2_housing_search", "b1_housing_search", "renamed (generic sibling)"),
            ],
            report.dancheong_motif_renames,
        )

    def test_non_ambiguous_base_id_skips_generic_rename(self) -> None:
        # `pack_base("a1_old_pack")` == "a1_old_pack" (no trailing digit
        # segment) -- the generic-sibling step must be a no-op, not raise
        # or emit a spurious second report entry.
        fixture = """
DancheongMotif motifForPackId(String packId) {
  final base = _baseOf(packId);
  return switch (base) {
    'a1_old_pack' => DancheongMotif.crane,
    _ => DancheongMotif.lotus,
  };
}
"""
        move = self._move("a1_old_pack_1", "a2_new_pack_1", from_level="a1", to_level="a2")
        report = rb.MigrationReport(batch="TEST")
        new_text = rb.edit_dancheong_motifs(fixture, (move,), report)
        self.assertIn("'a2_new_pack' => DancheongMotif.crane,", new_text)
        self.assertEqual(
            [("a1_old_pack", "a2_new_pack", "renamed")], report.dancheong_motif_renames,
        )


def by_bundle_report(report: rb.MigrationReport, bundle: str) -> rb.PackMoveReport:
    return next(p for p in report.packs if p.bundle == bundle)


# ───────────────────────── scenario moves (LCP PR-L2a2, T2.4b-1) ──────────


def _scenario_move_dict(**overrides) -> dict:
    base = {
        "id": "a1_relvtest_scn_cando", "from": "a1", "to": "b1", "shelf": "b1_team",
        "courseUnitId": "b1_04_relationships", "conceptIds": ["concept_b1_relationships"],
        "reason": "test scenario move",
    }
    base.update(overrides)
    return base


class ScenarioMoveShapeTest(unittest.TestCase):
    def test_valid_move_round_trips(self) -> None:
        move = rb.ScenarioMove.from_dict(_scenario_move_dict())
        self.assertEqual("a1_relvtest_scn_cando", move.id)
        self.assertEqual("a1", move.from_level)
        self.assertEqual("b1", move.to_level)
        self.assertEqual("b1_team", move.shelf)
        self.assertIsNone(move.backdrop)
        self.assertIsNone(move.can_do_cluster_id)

    def test_backdrop_and_can_do_cluster_id_are_optional_but_round_trip(self) -> None:
        move = rb.ScenarioMove.from_dict(
            _scenario_move_dict(backdrop="cafe", canDoClusterId="cluster_b1_intimate_feelings_v1")
        )
        self.assertEqual("cafe", move.backdrop)
        self.assertEqual("cluster_b1_intimate_feelings_v1", move.can_do_cluster_id)

    def test_same_from_and_to_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.ScenarioMove.from_dict(_scenario_move_dict(to="a1"))

    def test_shelf_not_matching_to_level_prefix_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.ScenarioMove.from_dict(_scenario_move_dict(shelf="a1_eat"))  # to=b1

    def test_shelf_slug_unknown_to_shelf_assignment_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.ScenarioMove.from_dict(_scenario_move_dict(shelf="b1_not_a_real_slug"))

    def test_empty_concept_ids_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.ScenarioMove.from_dict(_scenario_move_dict(conceptIds=[]))

    def test_missing_field_is_rejected(self) -> None:
        raw = _scenario_move_dict()
        del raw["reason"]
        with self.assertRaises(rb.RelevelError):
            rb.ScenarioMove.from_dict(raw)

    def test_bundle_may_have_only_scenario_moves(self) -> None:
        bundle = rb.load_bundle_from_dict({
            "batch": "TEST", "moves": [], "scenarioMoves": [_scenario_move_dict()],
        })
        self.assertEqual((), bundle.moves)
        self.assertEqual(1, len(bundle.scenario_moves))

    def test_bundle_with_neither_moves_nor_scenario_moves_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.load_bundle_from_dict({"batch": "TEST", "moves": [], "scenarioMoves": []})

    def test_duplicate_scenario_move_id_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.load_bundle_from_dict({
                "batch": "TEST", "moves": [],
                "scenarioMoves": [_scenario_move_dict(), _scenario_move_dict()],
            })


def _scenario_report(move: rb.ScenarioMove) -> rb.ScenarioMoveReport:
    return rb.ScenarioMoveReport(
        scenario_id=move.id, from_level=move.from_level, to_level=move.to_level,
        course_unit_id=move.course_unit_id, shelf=move.shelf,
    )


class EditShelfAssignmentSourceTest(unittest.TestCase):
    FIXTURE = """ASSIGNMENT: dict[str, tuple[str, ...]] = {
    "a1_eat": (
        "a1_existing_one", "a1_relvtest_scn_cando",
        "a1_existing_two",
    ),
    "b1_team": (
        "b1_existing_one",
    ),
}

SHELF_BY_ID: dict[str, str] = {
    scenario_id: shelf
    for shelf, ids in ASSIGNMENT.items()
    for scenario_id in ids
}
"""

    def test_tracked_id_moves_between_shelf_tuples(self) -> None:
        move = rb.ScenarioMove.from_dict(_scenario_move_dict())
        report = rb.MigrationReport(batch="TEST")
        report.scenarios.append(_scenario_report(move))

        new_text = rb.edit_shelf_assignment_source(self.FIXTURE, (move,), report)
        ast.parse(new_text)  # still syntactically valid
        namespace: dict = {}
        exec(new_text, namespace)  # noqa: S102 -- trusted, self-authored fixture text
        self.assertNotIn("a1_relvtest_scn_cando", namespace["ASSIGNMENT"]["a1_eat"])
        self.assertIn("a1_relvtest_scn_cando", namespace["ASSIGNMENT"]["b1_team"])
        self.assertEqual(
            ("a1_existing_one", "a1_existing_two"), namespace["ASSIGNMENT"]["a1_eat"],
        )
        self.assertEqual("b1_team", namespace["SHELF_BY_ID"]["a1_relvtest_scn_cando"])
        self.assertEqual("moved 'a1_eat' -> 'b1_team'", report.scenarios[0].shelf_assignment_note)

    def test_untracked_id_is_a_no_op_reported_either_way(self) -> None:
        move = rb.ScenarioMove.from_dict(_scenario_move_dict(id="a1_never_tracked"))
        report = rb.MigrationReport(batch="TEST")
        report.scenarios.append(_scenario_report(move))

        new_text = rb.edit_shelf_assignment_source(self.FIXTURE, (move,), report)
        self.assertEqual(self.FIXTURE, new_text)
        self.assertEqual(
            "not tracked in shelf_assignment.py ASSIGNMENT -- no update",
            report.scenarios[0].shelf_assignment_note,
        )

    def test_no_scenario_moves_is_a_no_op(self) -> None:
        report = rb.MigrationReport(batch="TEST")
        self.assertEqual(self.FIXTURE, rb.edit_shelf_assignment_source(self.FIXTURE, (), report))


class EditBuildCanDoSegmentsSourceTest(unittest.TestCase):
    # A self-executing stand-in for build_can_do_segments.py's own
    # SegmentSpec/_scenario_spec machinery -- ast.parse() never needs
    # these to resolve, but exec()ing the *edited* text to inspect real
    # SegmentSpec objects (rather than string-matching source text) is a
    # much stronger assertion.
    FIXTURE = '''from dataclasses import dataclass


@dataclass(frozen=True)
class PracticeRef:
    kind: str
    id: str


@dataclass(frozen=True)
class SegmentSpec:
    key: str
    level: str
    parent: str
    refs: tuple
    mode: str = "connectedProduction"


def _ref(kind, content_id):
    return PracticeRef(kind=kind, id=content_id)


def _scenario_spec(key, level, parent, scenario_id, mode="connectedProduction"):
    return SegmentSpec(key=key, level=level, parent=parent, refs=(_ref("scenario", scenario_id),), mode=mode)


AB_SPECS: tuple[SegmentSpec, ...] = (
    _scenario_spec("a1_relvtest_source_spec", "a1", "a1_04_order_request_object", "a1_relvtest_scn_cando"),
    _scenario_spec("b1_relvtest_anchor", "b1", "b1_04_relationships", "b1_relvtest_existing", "dictation"),
)
'''

    def _move(self, **overrides) -> rb.ScenarioMove:
        return rb.ScenarioMove.from_dict(_scenario_move_dict(**overrides))

    def test_removes_from_level_entry_and_adds_after_the_anchor(self) -> None:
        move = self._move()  # id=a1_relvtest_scn_cando, a1->b1, unit=b1_04_relationships
        report = rb.MigrationReport(batch="TEST")
        report.scenarios.append(_scenario_report(move))

        new_text = rb.edit_build_can_do_segments_source(self.FIXTURE, (move,), report)
        ast.parse(new_text)
        namespace: dict = {}
        exec(new_text, namespace)  # noqa: S102 -- trusted, self-authored fixture text
        specs = namespace["AB_SPECS"]

        self.assertEqual(2, len(specs))
        self.assertEqual("b1_relvtest_anchor", specs[0].key)  # anchor stays first
        self.assertNotIn("a1_relvtest_source_spec", [s.key for s in specs])
        new_spec = specs[1]
        self.assertEqual("b1_a1_relvtest_scn_cando", new_spec.key)
        self.assertEqual("b1", new_spec.level)
        self.assertEqual("b1_04_relationships", new_spec.parent)
        self.assertEqual("connectedProduction", new_spec.mode)  # old entry had no mode
        self.assertEqual(("scenario", "a1_relvtest_scn_cando"), (new_spec.refs[0].kind, new_spec.refs[0].id))

        note = report.scenarios[0].ab_specs_note
        self.assertIn("removed key='a1_relvtest_source_spec'", note)
        self.assertIn("added key='b1_a1_relvtest_scn_cando' after anchor='b1_relvtest_anchor'", note)
        self.assertNotIn("WARNING", note)  # key referenced nowhere else in this fixture

    def test_not_present_in_ab_specs_is_a_no_op_reported(self) -> None:
        move = self._move(id="never_seen_in_ab_specs")
        report = rb.MigrationReport(batch="TEST")
        report.scenarios.append(_scenario_report(move))

        new_text = rb.edit_build_can_do_segments_source(self.FIXTURE, (move,), report)
        self.assertEqual(self.FIXTURE, new_text)
        self.assertEqual("not present in AB_SPECS", report.scenarios[0].ab_specs_note)

    def test_no_anchor_at_target_removes_only_and_reports_fallback(self) -> None:
        # Target unit has no AB_SPECS entry at the to-level at all.
        move = self._move(to="a2", courseUnitId="a2_99_no_anchor_unit", shelf="a2_work")
        report = rb.MigrationReport(batch="TEST")
        report.scenarios.append(_scenario_report(move))

        new_text = rb.edit_build_can_do_segments_source(self.FIXTURE, (move,), report)
        namespace: dict = {}
        exec(new_text, namespace)  # noqa: S102
        specs = namespace["AB_SPECS"]
        self.assertEqual(1, len(specs))
        self.assertEqual("b1_relvtest_anchor", specs[0].key)

        note = report.scenarios[0].ab_specs_note
        self.assertIn("removed key='a1_relvtest_source_spec'", note)
        self.assertIn("no AB_SPECS anchor at 'a2'/'a2_99_no_anchor_unit'", note)

    def test_no_scenario_moves_is_a_no_op(self) -> None:
        report = rb.MigrationReport(batch="TEST")
        self.assertEqual(self.FIXTURE, rb.edit_build_can_do_segments_source(self.FIXTURE, (), report))


SCENARIO_SHELF_ASSIGNMENT_FIXTURE = """ASSIGNMENT: dict[str, tuple[str, ...]] = {
    "a1_counter": (
        "a1_relvtest_scn_cando",
    ),
    "b1_team": (
        "b1_relvtest_existing",
    ),
    "a2_work": (
        "a2_relvtest_existing",
    ),
}

SHELF_BY_ID: dict[str, str] = {
    scenario_id: shelf
    for shelf, ids in ASSIGNMENT.items()
    for scenario_id in ids
}
"""

SCENARIO_BUILD_CAN_DO_SEGMENTS_FIXTURE = '''from dataclasses import dataclass


@dataclass(frozen=True)
class PracticeRef:
    kind: str
    id: str


@dataclass(frozen=True)
class SegmentSpec:
    key: str
    level: str
    parent: str
    refs: tuple
    mode: str = "connectedProduction"


def _ref(kind, content_id):
    return PracticeRef(kind=kind, id=content_id)


def _scenario_spec(key, level, parent, scenario_id, mode="connectedProduction"):
    return SegmentSpec(key=key, level=level, parent=parent, refs=(_ref("scenario", scenario_id),), mode=mode)


AB_SPECS: tuple[SegmentSpec, ...] = (
    _scenario_spec("a1_relvtest_cando_home", "a1", "a1_04_order_request_object", "a1_relvtest_scn_cando"),
    _scenario_spec("b1_relvtest_relationships_anchor", "b1", "b1_04_relationships", "b1_relvtest_existing"),
)
'''


class ScenarioRelevelBundleFixture(unittest.TestCase):
    """Mirrors RelevelBundleFixture's strategy (real assets/data copytree +
    synthetic content on top) for scenario moves: clones two REAL,
    already-schema-valid scenarios under fresh ids -- one with live can-do
    references (bunshik_tteokbokki: direct reference + cluster + seed),
    one without (bakery_payment_bag) -- so the clones' vocab/dialog/quests/
    grammarIds shape needs no hand-authoring and is guaranteed to pass
    ContentValidator on its own merits.
    """

    CANDO_SOURCE_ID = "bunshik_tteokbokki"
    CANDO_NEW_ID = "a1_relvtest_scn_cando"
    CANDO_SOURCE_CLUSTER = "cluster_a1_04_order_request_object_v1"
    CANDO_TARGET_UNIT = "b1_04_relationships"
    CANDO_TARGET_CLUSTER = "cluster_b1_intimate_feelings_v1"

    PLAIN_SOURCE_ID = "bakery_payment_bag"
    PLAIN_NEW_ID = "a1_relvtest_scn_plain"
    PLAIN_TARGET_UNIT = "a2_06_study_work"

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="relevel-bundle-scenario-test-")
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name) / "repo"
        data = self.root / "assets" / "data"
        shutil.copytree(REPO / "assets" / "data", data)

        (self.root / "tools" / "content_factory").mkdir(parents=True, exist_ok=True)
        (self.root / "functions" / "analyze_korean_text").mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            REPO / "functions" / "analyze_korean_text" / "grammar_patterns.json",
            self.root / "functions" / "analyze_korean_text" / "grammar_patterns.json",
        )

        # Small, self-authored, fully test-controlled stand-ins -- never
        # the real 600-/3900-line checkout files (root-relative precisely
        # so a test never has to touch those).
        (self.root / "tools" / "content_factory" / "shelf_assignment.py").write_text(
            SCENARIO_SHELF_ASSIGNMENT_FIXTURE, encoding="utf-8",
        )
        (self.root / "tools" / "content_factory" / "build_can_do_segments.py").write_text(
            SCENARIO_BUILD_CAN_DO_SEGMENTS_FIXTURE, encoding="utf-8",
        )

        # migrate() unconditionally reads pack_artwork_catalog.dart (even
        # in dry-run) for its report's artwork lookup, and --apply reads
        # vocab_pack_service.dart/dancheong_stamp.dart too (edited as a
        # no-op for a bundle with `moves: []`) -- all three must exist at
        # `root` even though this fixture has zero pack moves, same as in
        # production.
        (self.root / "lib" / "data").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "data" / "pack_artwork_catalog.dart").write_text(
            "abstract final class PackArtworkCatalog {\n"
            "  static const dedicatedPackIds = <String>{\n"
            "  };\n"
            "}\n",
            encoding="utf-8",
        )
        (self.root / "lib" / "services").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "services" / "vocab_pack_service.dart").write_text(
            "class VocabPackService {\n"
            "  static const Map<String, (String, String)> packDisplayMap = {\n"
            "  };\n\n"
            "  static const Map<String, int> packOrderInLevel = {\n"
            "  };\n"
            "}\n",
            encoding="utf-8",
        )
        (self.root / "lib" / "widgets" / "sori").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart").write_text(
            "DancheongMotif motifForPackId(String packId) {\n"
            "  final base = _baseOf(packId);\n"
            "  return switch (base) {\n"
            "    _ => DancheongMotif.lotus,\n"
            "  };\n"
            "}\n",
            encoding="utf-8",
        )

        self.ledger_path = Path(self._tmp.name) / "relevel_ledger.json"
        shutil.copy2(REPO / "tools" / "content_factory" / "relevel_ledger.json", self.ledger_path)

        self._inject_synthetic_scenarios(data)

    def _inject_synthetic_scenarios(self, data: Path) -> None:
        scenarios_path = data / "scenarios_a1.json"
        root = json.loads(scenarios_path.read_text(encoding="utf-8"))
        by_id = {s["id"]: s for s in root["scenarios"]}

        cando = copy.deepcopy(by_id[self.CANDO_SOURCE_ID])
        cando["id"] = self.CANDO_NEW_ID
        root["scenarios"].append(cando)
        plain = copy.deepcopy(by_id[self.PLAIN_SOURCE_ID])
        plain["id"] = self.PLAIN_NEW_ID
        root["scenarios"].append(plain)
        scenarios_path.write_text(json.dumps(root, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        # content_audit_manifest.json's declared scenario/scenarioQuest
        # counts must agree with the live inventory (validate_audit_
        # manifest()) -- bumped by exactly what the two clones added,
        # computed here rather than hard-coded so a future change to
        # either source scenario's own quest count can't silently
        # desync this fixture from reality.
        audit_manifest_path = self.root / "tools" / "content_factory" / "content_audit_manifest.json"
        shutil.copy2(REPO / "tools" / "content_factory" / "content_audit_manifest.json", audit_manifest_path)
        audit_manifest = json.loads(audit_manifest_path.read_text(encoding="utf-8"))
        added_quests = len(cando.get("quests", [])) + len(plain.get("quests", []))
        for source in audit_manifest["sources"]:
            if source["kind"] == "scenario":
                source["count"] += 2  # two synthetic scenarios injected above
            elif source["kind"] == "scenarioQuest":
                source["count"] += added_quests
        audit_manifest_path.write_text(
            json.dumps(audit_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
        )

        curriculum_path = data / rb.CURRICULUM_JSON
        curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
        links = curriculum["contentLinks"]
        for source_id, new_id in ((self.CANDO_SOURCE_ID, self.CANDO_NEW_ID), (self.PLAIN_SOURCE_ID, self.PLAIN_NEW_ID)):
            source_link = next(
                l for l in links if l.get("contentKind") == "scenario" and l.get("contentId") == source_id
            )
            new_link = copy.deepcopy(source_link)
            new_link["contentId"] = new_id
            links.append(new_link)
        curriculum_path.write_text(json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        auth_path = data / rb.CAN_DO_AUTHORITIES_JSON
        authorities = json.loads(auth_path.read_text(encoding="utf-8"))
        source_ref = next(
            r for r in authorities["contentReferences"]
            if r.get("kind") == "scenario" and r.get("id") == self.CANDO_SOURCE_ID
        )
        self.new_seed_id = f"seed_scenario_{self.CANDO_NEW_ID}_v1"
        new_ref = copy.deepcopy(source_ref)
        new_ref["id"] = self.CANDO_NEW_ID
        new_ref["sourceSeedId"] = self.new_seed_id
        authorities["contentReferences"].append(new_ref)
        authorities["sourceSeeds"].append({"id": self.new_seed_id, "level": "a1"})
        authorities["coverage"]["directReferenceCounts"]["scenario"] += 1
        auth_path.write_text(json.dumps(authorities, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        segments_path = data / rb.CAN_DO_SEGMENTS_JSON
        segments_doc = json.loads(segments_path.read_text(encoding="utf-8"))
        cluster = next(c for c in segments_doc["contentClusters"] if c["id"] == self.CANDO_SOURCE_CLUSTER)
        cluster["contentReferences"].append({"kind": "scenario", "id": self.CANDO_NEW_ID})
        cluster["sourceSeedIds"].append(self.new_seed_id)
        segments_path.write_text(json.dumps(segments_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def _bundle(self, scenario_moves: list[dict]) -> rb.BundleFile:
        return rb.load_bundle_from_dict({"batch": "TEST", "moves": [], "scenarioMoves": scenario_moves})

    def _cando_move(self, **overrides) -> dict:
        base = {
            "id": self.CANDO_NEW_ID, "from": "a1", "to": "b1", "shelf": "b1_team",
            "courseUnitId": self.CANDO_TARGET_UNIT, "conceptIds": ["concept_b1_relationships"],
            "canDoClusterId": self.CANDO_TARGET_CLUSTER, "reason": "test cando scenario move",
        }
        base.update(overrides)
        return base

    def _plain_move(self, **overrides) -> dict:
        base = {
            "id": self.PLAIN_NEW_ID, "from": "a1", "to": "a2", "shelf": "a2_work",
            "courseUnitId": self.PLAIN_TARGET_UNIT, "conceptIds": ["concept_a2_work_study"],
            "reason": "test plain scenario move",
        }
        base.update(overrides)
        return base

    def _snapshot(self) -> dict[Path, bytes]:
        paths = [self.root / "assets" / "data" / name for name in rb._STAGED_DATA_FILES] + [
            self.root / "tools" / "content_factory" / "shelf_assignment.py",
            self.root / "tools" / "content_factory" / "build_can_do_segments.py",
            self.root / "lib" / "data" / "pack_artwork_catalog.dart",
            self.root / "lib" / "services" / "vocab_pack_service.dart",
            self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart",
            self.ledger_path,
        ]
        return {path: (path.read_bytes() if path.exists() else None) for path in paths}

    def _assert_unchanged(self, snapshot: dict[Path, bytes]) -> None:
        for path, content in snapshot.items():
            current = path.read_bytes() if path.exists() else None
            self.assertEqual(content, current, f"{path} changed unexpectedly")


class ScenarioDryRunTest(ScenarioRelevelBundleFixture):
    def test_dry_run_computes_plan_and_changes_nothing(self) -> None:
        snapshot = self._snapshot()
        bundle = self._bundle([self._cando_move(), self._plain_move()])
        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)

        self.assertEqual(2, len(report.scenarios))
        by_id = {s.scenario_id: s for s in report.scenarios}
        self.assertEqual("migrated (direct reference)", by_id[self.CANDO_NEW_ID].can_do_note)
        self.assertEqual(self.CANDO_SOURCE_CLUSTER, by_id[self.CANDO_NEW_ID].source_cluster_id)
        self.assertEqual(self.CANDO_TARGET_CLUSTER, by_id[self.CANDO_NEW_ID].target_cluster_id)
        self.assertEqual("no can-do references", by_id[self.PLAIN_NEW_ID].can_do_note)
        self.assertIsNone(by_id[self.PLAIN_NEW_ID].source_cluster_id)
        self.assertIsNone(by_id[self.PLAIN_NEW_ID].target_cluster_id)

        self._assert_unchanged(snapshot)


class ScenarioApplyTest(ScenarioRelevelBundleFixture):
    def test_apply_migrates_shard_contentlinks_ledger_can_do_and_side_files(self) -> None:
        bundle = self._bundle([self._cando_move(), self._plain_move()])
        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)
        data = self.root / "assets" / "data"

        # scenario shards: gone from a1, present at their new level with
        # the right level/shelf/courseUnitId/conceptIds, everything else
        # (title/dialog/quests/grammarIds/...) preserved from the clone.
        a1 = json.loads((data / "scenarios_a1.json").read_text(encoding="utf-8"))["scenarios"]
        a1_ids = {s["id"] for s in a1}
        self.assertNotIn(self.CANDO_NEW_ID, a1_ids)
        self.assertNotIn(self.PLAIN_NEW_ID, a1_ids)

        b1 = json.loads((data / "scenarios_b1.json").read_text(encoding="utf-8"))["scenarios"]
        cando = next(s for s in b1 if s["id"] == self.CANDO_NEW_ID)
        self.assertEqual("b1", cando["level"])
        self.assertEqual("b1_team", cando["shelf"])
        self.assertEqual(self.CANDO_TARGET_UNIT, cando["courseUnitId"])
        self.assertEqual(["concept_b1_relationships"], cando["conceptIds"])
        original = json.loads(
            (REPO / "assets" / "data" / "scenarios_a1.json").read_text(encoding="utf-8")
        )["scenarios"]
        original_bunshik = next(s for s in original if s["id"] == self.CANDO_SOURCE_ID)
        self.assertEqual(original_bunshik["title"], cando["title"])
        self.assertEqual(original_bunshik["dialog"], cando["dialog"])
        self.assertEqual(original_bunshik["grammarIds"], cando["grammarIds"])

        a2 = json.loads((data / "scenarios_a2.json").read_text(encoding="utf-8"))["scenarios"]
        plain = next(s for s in a2 if s["id"] == self.PLAIN_NEW_ID)
        self.assertEqual("a2", plain["level"])
        self.assertEqual("a2_work", plain["shelf"])
        self.assertEqual(self.PLAIN_TARGET_UNIT, plain["courseUnitId"])

        # curriculum_manifest.json contentLinks
        curriculum = json.loads((data / rb.CURRICULUM_JSON).read_text(encoding="utf-8"))
        links_by_id = {
            l["contentId"]: l for l in curriculum["contentLinks"] if l.get("contentKind") == "scenario"
        }
        self.assertEqual(self.CANDO_TARGET_UNIT, links_by_id[self.CANDO_NEW_ID]["courseUnitId"])
        self.assertEqual(["concept_b1_relationships"], links_by_id[self.CANDO_NEW_ID]["conceptIds"])
        self.assertEqual(self.PLAIN_TARGET_UNIT, links_by_id[self.PLAIN_NEW_ID]["courseUnitId"])

        # ledger
        ledger = rb.relevel_ledger.load_ledger(self.ledger_path)
        cando_entry = ledger.get("scenario", self.CANDO_NEW_ID)
        self.assertIsNotNone(cando_entry)
        self.assertEqual("a1", cando_entry.from_level)
        self.assertEqual("b1", cando_entry.to_level)
        plain_entry = ledger.get("scenario", self.PLAIN_NEW_ID)
        self.assertIsNotNone(plain_entry)
        self.assertEqual("a2", plain_entry.to_level)

        # can-do authorities + segments: direct ref moved, cluster
        # membership relocated, seed level bumped, source cluster no
        # longer references it.
        authorities = json.loads((data / rb.CAN_DO_AUTHORITIES_JSON).read_text(encoding="utf-8"))
        direct = {(r["kind"], r["id"]): r for r in authorities["contentReferences"]}
        self.assertEqual("b1", direct[("scenario", self.CANDO_NEW_ID)]["level"])
        self.assertEqual(self.CANDO_TARGET_UNIT, direct[("scenario", self.CANDO_NEW_ID)]["courseUnitId"])
        seed = next(s for s in authorities["sourceSeeds"] if s["id"] == self.new_seed_id)
        self.assertEqual("b1", seed["level"])

        segments_doc = json.loads((data / rb.CAN_DO_SEGMENTS_JSON).read_text(encoding="utf-8"))
        clusters_by_id = {c["id"]: c for c in segments_doc["contentClusters"]}
        source_cluster = clusters_by_id[self.CANDO_SOURCE_CLUSTER]
        source_refs = {(r["kind"], r["id"]) for r in source_cluster["contentReferences"]}
        self.assertNotIn(("scenario", self.CANDO_NEW_ID), source_refs)
        self.assertNotIn(self.new_seed_id, source_cluster["sourceSeedIds"])
        target_cluster = clusters_by_id[self.CANDO_TARGET_CLUSTER]
        target_refs = {(r["kind"], r["id"]) for r in target_cluster["contentReferences"]}
        self.assertIn(("scenario", self.CANDO_NEW_ID), target_refs)
        self.assertIn(self.new_seed_id, target_cluster["sourceSeedIds"])

        # shelf_assignment.py: cando id relocated between tuples; plain id
        # was never tracked, so ASSIGNMENT is untouched for it.
        shelf_text = (
            self.root / "tools" / "content_factory" / "shelf_assignment.py"
        ).read_text(encoding="utf-8")
        namespace: dict = {}
        exec(shelf_text, namespace)  # noqa: S102
        self.assertNotIn(self.CANDO_NEW_ID, namespace["ASSIGNMENT"]["a1_counter"])
        self.assertIn(self.CANDO_NEW_ID, namespace["ASSIGNMENT"]["b1_team"])
        self.assertNotIn(self.PLAIN_NEW_ID, namespace["SHELF_BY_ID"])

        # build_can_do_segments.py AB_SPECS: cando's from-level entry
        # removed and a new one added after the b1_04_relationships
        # anchor; plain never had an AB_SPECS entry to begin with.
        ab_specs_text = (
            self.root / "tools" / "content_factory" / "build_can_do_segments.py"
        ).read_text(encoding="utf-8")
        namespace2: dict = {}
        exec(ab_specs_text, namespace2)  # noqa: S102
        spec_keys = [s.key for s in namespace2["AB_SPECS"]]
        self.assertNotIn("a1_relvtest_cando_home", spec_keys)
        new_spec = next(
            s for s in namespace2["AB_SPECS"]
            if s.refs and s.refs[0].kind == "scenario" and s.refs[0].id == self.CANDO_NEW_ID
        )
        self.assertEqual("b1", new_spec.level)
        self.assertEqual(self.CANDO_TARGET_UNIT, new_spec.parent)

        by_id = {s.scenario_id: s for s in report.scenarios}
        self.assertIn("moved 'a1_counter' -> 'b1_team'", by_id[self.CANDO_NEW_ID].shelf_assignment_note)
        self.assertIn("not tracked", by_id[self.PLAIN_NEW_ID].shelf_assignment_note)
        self.assertIn("removed key='a1_relvtest_cando_home'", by_id[self.CANDO_NEW_ID].ab_specs_note)
        self.assertEqual("not present in AB_SPECS", by_id[self.PLAIN_NEW_ID].ab_specs_note)

        # Plan §4.3 step 4(7): never shells out -- the plan text and the
        # markdown report both print the follow-up TTS/manifest commands
        # instead, only when a scenario move actually applied.
        plan_text = rb.format_plan(report, apply=True)
        self.assertIn("scenario move(s) applied -- run these follow-ups next:", plan_text)
        self.assertIn("--write-first-line-manifest assets/data/tts_first_line_manifest.json", plan_text)
        self.assertIn("--check-first-line-manifest assets/data/tts_first_line_manifest.json", plan_text)
        self.assertIn("functions/tts/build_canonical_manifest.py", plan_text)

        report_path = self.root / "report.md"
        rb.append_report_section(report_path, report, apply=True)
        report_text = report_path.read_text(encoding="utf-8")
        self.assertIn("시나리오 이동이 적용됨", report_text)
        self.assertIn("build_canonical_manifest.py --check", report_text)

    def test_dry_run_prints_no_follow_up_commands(self) -> None:
        # The follow-ups are only real once something was actually
        # written -- a dry run must not suggest running them.
        bundle = self._bundle([self._cando_move()])
        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)
        plan_text = rb.format_plan(report, apply=False)
        self.assertNotIn("run these follow-ups next", plan_text)


class ScenarioRollbackTest(ScenarioRelevelBundleFixture):
    def test_bad_shelf_fails_and_leaves_everything_untouched(self) -> None:
        # Bypasses ScenarioMove.from_dict deliberately -- an invalid shelf
        # is already rejected at that front door (ScenarioMoveShapeTest),
        # so this instead proves the staged ContentValidator safety net
        # inside migrate() itself also fails closed and rolls back
        # completely, exactly like the pack-move RollbackTest does for a
        # bad conceptIds value.
        bad_move = rb.ScenarioMove(
            id=self.CANDO_NEW_ID, from_level="a1", to_level="b1", shelf="not_a_real_shelf_at_all",
            course_unit_id=self.CANDO_TARGET_UNIT, concept_ids=("concept_b1_relationships",),
            reason="test bad shelf", backdrop=None, can_do_cluster_id=self.CANDO_TARGET_CLUSTER,
        )
        bundle = rb.BundleFile(batch="TEST", moves=(), scenario_moves=(bad_move,))
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        self._assert_unchanged(snapshot)

    def test_dry_run_also_rejects_bad_shelf(self) -> None:
        bad_move = rb.ScenarioMove(
            id=self.CANDO_NEW_ID, from_level="a1", to_level="b1", shelf="not_a_real_shelf_at_all",
            course_unit_id=self.CANDO_TARGET_UNIT, concept_ids=("concept_b1_relationships",),
            reason="test bad shelf", backdrop=None, can_do_cluster_id=self.CANDO_TARGET_CLUSTER,
        )
        bundle = rb.BundleFile(batch="TEST", moves=(), scenario_moves=(bad_move,))
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)

        self._assert_unchanged(snapshot)


if __name__ == "__main__":
    unittest.main()
