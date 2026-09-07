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


if __name__ == "__main__":
    unittest.main()
