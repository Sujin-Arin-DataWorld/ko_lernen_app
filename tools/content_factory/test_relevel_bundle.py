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
from validate_content import ContentValidator, GRAMMAR_HEADER, VOCAB_HEADER

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


# ---- card-style ledger fixtures (task T2.9b) -------------------------------
# tool/check_card_style.py --all's two membership ledgers for the F-E-cards
# WebP card family -- see edit_card_style_registry's docstring. These
# builders always emit the exact json.dumps(indent=2, ensure_ascii=False)+"\n"
# canonical shape edit_card_style_registry's round-trip guard requires.

BASELINE_ENTRY_X = {
    "sha256": "a" * 64, "kb": 88.2, "ivoryFrac": 0.6094, "fine": 4.86,
    "coarse": 0.739, "uniqueColors": 40149, "top8": 0.7013, "patchXY": [80, 0],
}
BASELINE_ENTRY_UNTOUCHED = {
    "sha256": "b" * 64, "kb": 70.3, "ivoryFrac": 0.789, "fine": 4.236,
    "coarse": 0.694, "uniqueColors": 19253, "top8": 0.8993, "patchXY": [320, 48],
}


def _card_style_baseline_text(files: dict) -> str:
    return json.dumps(
        {"schema": 1, "measuredAt": "2026-01-01", "grainFormulaVersion": 1, "files": files},
        ensure_ascii=False, indent=2,
    ) + "\n"


def _style_lock_text(members: list, known_deviations: dict | None = None) -> str:
    family: dict = {"members": list(members)}
    if known_deviations is not None:
        family["knownDeviations"] = known_deviations
    return json.dumps({"families": {"F-E-cards": family}}, ensure_ascii=False, indent=2) + "\n"


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

        # Only "alpha" is registered in the card-style gate ledgers (task
        # T2.9b) -- "beta" deliberately is not, exercising
        # edit_card_style_registry's "not registered -- no-op" path the same
        # way pack_artwork_catalog's dedicatedPackIds only lists alpha above
        # (a pack absent from dedicatedPackIds has no packs/*.webp at all, so
        # it can never be card-style-registered either).
        docs_assets_dir = self.root / "docs" / "assets"
        docs_assets_dir.mkdir(parents=True, exist_ok=True)
        self.card_style_baseline_path = docs_assets_dir / "CARD_STYLE_BASELINE.json"
        self.card_style_baseline_path.write_text(
            _card_style_baseline_text({
                "assets/illustrations/packs/a1_relvtest_alpha_1.webp": dict(BASELINE_ENTRY_X),
            }),
            encoding="utf-8",
        )
        self.style_lock_path = docs_assets_dir / "STYLE_LOCK.json"
        self.style_lock_path.write_text(
            _style_lock_text(["a1_relvtest_alpha_1"]), encoding="utf-8",
        )

        # Only "alpha" gets an archived pack-authoring source (task T2.9a) --
        # "beta" deliberately has none, exercising sync_pack_source_files'
        # "no source file" no-op path the same way pack_artwork_catalog's
        # dedicatedPackIds only lists alpha above.
        pack_source_dir = self.root / "tools" / "content_factory" / "data" / "packs"
        pack_source_dir.mkdir(parents=True, exist_ok=True)
        self.alpha_pack_source_path = pack_source_dir / "a1_relvtest_alpha_1.json"
        self.alpha_pack_source_path.write_text(
            json.dumps(
                {
                    "packId": "a1_relvtest_alpha_1",
                    "level": "a1",
                    "orderInLevel": 1,
                    "topic": "Relvtestalpha",
                    "unit": SOURCE_UNIT,
                    "concept": "concept_a1_relvtest_source",
                    "motif": "cloud",
                    "labels": {"ko": "렐브테스트 알파", "de": "Relvtest Alpha", "en": "Relvtest alpha"},
                    "words": [
                        [korean, german, english, "Nomen", "Noun",
                         f"{korean} 예문입니다.", f"{german} Beispielsatz.", f"{english} example sentence."]
                        for _vocab_id, korean, _rom, german, english in ALPHA_WORDS
                    ],
                },
                ensure_ascii=False, indent=2,
            ) + "\n",
            encoding="utf-8",
        )

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
            self.card_style_baseline_path,
            self.style_lock_path,
            self.alpha_pack_source_path,
            self.root / "tools" / "content_factory" / "data" / "packs" / "b1_relvtest_alpha_1.json",
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

        # Card-style ledger sync (task T2.9b): alpha is registered in both
        # docs/assets/CARD_STYLE_BASELINE.json and STYLE_LOCK.json, renamed
        # in lock-step with its .webp above; beta is registered in neither,
        # a reported no-op.
        card_style_baseline = json.loads(self.card_style_baseline_path.read_text(encoding="utf-8"))
        self.assertNotIn("assets/illustrations/packs/a1_relvtest_alpha_1.webp", card_style_baseline["files"])
        renamed_entry = card_style_baseline["files"]["assets/illustrations/packs/b1_relvtest_alpha_1.webp"]
        self.assertEqual(BASELINE_ENTRY_X, renamed_entry)  # sha256/kb/... verbatim
        style_lock = json.loads(self.style_lock_path.read_text(encoding="utf-8"))
        self.assertEqual(["b1_relvtest_alpha_1"], style_lock["families"]["F-E-cards"]["members"])
        self.assertEqual(
            [
                ("a1_relvtest_alpha_1", "b1_relvtest_alpha_1", "renamed"),
                ("a1_relvtest_beta_1", "a2_relvtest_beta_1", "not registered in the card-style ledger -- no-op"),
            ],
            report.card_style_registry_renames,
        )

        aliases_text = (self.root / "lib" / "data" / "pack_progress_aliases.dart").read_text(encoding="utf-8")
        self.assertIn("'b1_relvtest_alpha_1': 'a1_relvtest_alpha_1'", aliases_text)
        self.assertIn("'a2_relvtest_beta_1': 'a1_relvtest_beta_1'", aliases_text)

        # Pack authoring source sync (task T2.9a): alpha has one, renamed
        # in place with packId/level/unit/concept rewritten; beta has none,
        # a reported no-op that creates no file.
        pack_source_dir = self.root / "tools" / "content_factory" / "data" / "packs"
        self.assertFalse(self.alpha_pack_source_path.exists())
        new_alpha_source = json.loads(
            (pack_source_dir / "b1_relvtest_alpha_1.json").read_text(encoding="utf-8")
        )
        self.assertEqual("b1_relvtest_alpha_1", new_alpha_source["packId"])
        self.assertEqual("b1", new_alpha_source["level"])
        self.assertEqual(TARGET_UNIT_B1, new_alpha_source["unit"])
        self.assertEqual("concept_b1_relationships", new_alpha_source["concept"])
        self.assertEqual(1, new_alpha_source["orderInLevel"])  # untouched -- archival only
        self.assertEqual(3, len(new_alpha_source["words"]))
        self.assertFalse((pack_source_dir / "a1_relvtest_beta_1.json").exists())
        self.assertFalse((pack_source_dir / "a2_relvtest_beta_1.json").exists())
        self.assertEqual(
            [("a1_relvtest_alpha_1", "b1_relvtest_alpha_1")], report.pack_sources_synced,
        )
        beta_pack = by_bundle_report(report, "a1_relvtest_beta_1")
        self.assertTrue(alpha_pack.has_pack_source)
        self.assertFalse(beta_pack.has_pack_source)

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
            self.card_style_baseline_path,
            self.style_lock_path,
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


class SyncPackSourceFilesTest(unittest.TestCase):
    """Task T2.9a: tools/content_factory/data/packs/<packId>.json sync,
    tested directly against a small temp directory rather than the full
    RelevelBundleFixture -- ApplyTest/DryRunTest/RollbackTest above already
    cover the happy path and migrate()'s rollback wiring end to end; this
    covers sync_pack_source_files' own error-handling contract, which is
    what makes that generic rollback safe: a raise here must never delete
    or half-write anything migrate()'s `originals` dict does not already
    know how to restore."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="sync-pack-source-test-")
        self.addCleanup(self._tmp.cleanup)
        self.pack_dir = Path(self._tmp.name)

    def _write_source(self, path: Path, **overrides) -> None:
        payload = {
            "packId": "a1_x_1", "level": "a1", "orderInLevel": 1, "topic": "X",
            "unit": "a1_01_greetings_hangul", "concept": "concept_a1_x", "motif": "cloud",
            "labels": {"ko": "엑스", "de": "X", "en": "X"},
            "words": [["가", "a", "a", "Nomen", "Noun", "가 예문.", "a Satz.", "a example."]],
        }
        payload.update(overrides)
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def _move(self, **overrides) -> rb.Move:
        base = {
            "bundle": "a1_x_1", "from": "a1", "to": "b1", "newPackId": "b1_x_1",
            "courseUnitId": "b1_04_relationships", "conceptIds": ["concept_b1_relationships"],
            "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
        }
        base.update(overrides)
        return rb.Move.from_dict(base)

    def _report(self, *moves: rb.Move) -> rb.MigrationReport:
        report = rb.MigrationReport(batch="TEST")
        for move in moves:
            report.packs.append(rb.PackMoveReport(
                bundle=move.bundle, new_pack_id=move.new_pack_id,
                from_level=move.from_level, to_level=move.to_level,
                course_unit_id=move.course_unit_id,
            ))
        return report

    def test_missing_source_is_a_reported_no_op(self) -> None:
        move = self._move()
        report = self._report(move)
        rb.sync_pack_source_files((move,), report, self.pack_dir)
        self.assertEqual([], report.pack_sources_synced)
        self.assertFalse(by_bundle_report(report, "a1_x_1").has_pack_source)

    def test_renames_and_rewrites_identity_fields_only(self) -> None:
        self._write_source(self.pack_dir / "a1_x_1.json")
        move = self._move()
        report = self._report(move)
        rb.sync_pack_source_files((move,), report, self.pack_dir)

        self.assertEqual([("a1_x_1", "b1_x_1")], report.pack_sources_synced)
        self.assertTrue(by_bundle_report(report, "a1_x_1").has_pack_source)
        self.assertFalse((self.pack_dir / "a1_x_1.json").exists())
        synced = json.loads((self.pack_dir / "b1_x_1.json").read_text(encoding="utf-8"))
        self.assertEqual("b1_x_1", synced["packId"])
        self.assertEqual("b1", synced["level"])
        self.assertEqual("b1_04_relationships", synced["unit"])
        self.assertEqual("concept_b1_relationships", synced["concept"])
        # untouched
        self.assertEqual(1, synced["orderInLevel"])
        self.assertEqual([["가", "a", "a", "Nomen", "Noun", "가 예문.", "a Satz.", "a example."]], synced["words"])

    def test_target_already_existing_raises_and_leaves_source_untouched(self) -> None:
        source_path = self.pack_dir / "a1_x_1.json"
        self._write_source(source_path)
        self._write_source(self.pack_dir / "b1_x_1.json", packId="b1_x_1", level="b1")
        move = self._move()
        report = self._report(move)

        with self.assertRaisesRegex(rb.RelevelError, "already exists"):
            rb.sync_pack_source_files((move,), report, self.pack_dir)
        self.assertTrue(source_path.exists(), "a raise must never delete the source before finishing")
        self.assertEqual([], report.pack_sources_synced)

    def test_pack_id_mismatch_raises(self) -> None:
        self._write_source(self.pack_dir / "a1_x_1.json", packId="a1_wrong_id")
        move = self._move()
        report = self._report(move)
        with self.assertRaisesRegex(rb.RelevelError, "packId"):
            rb.sync_pack_source_files((move,), report, self.pack_dir)

    def test_level_mismatch_raises(self) -> None:
        self._write_source(self.pack_dir / "a1_x_1.json", level="a2")
        move = self._move()
        report = self._report(move)
        with self.assertRaisesRegex(rb.RelevelError, "level"):
            rb.sync_pack_source_files((move,), report, self.pack_dir)

    def test_multiple_concept_ids_raises_unambiguous_error(self) -> None:
        self._write_source(self.pack_dir / "a1_x_1.json")
        move = self._move(conceptIds=["concept_b1_relationships", "concept_b1_extra"])
        report = self._report(move)
        with self.assertRaisesRegex(rb.RelevelError, "single 'concept' field"):
            rb.sync_pack_source_files((move,), report, self.pack_dir)

    def test_second_move_failure_leaves_first_moves_rename_in_place(self) -> None:
        # Documents exactly why migrate() needs its own rollback around this
        # function: sync_pack_source_files does not undo earlier moves in
        # the same call when a later one fails -- the caller (migrate())
        # owns that, via its `originals` dict + report.pack_sources_synced.
        self._write_source(self.pack_dir / "a1_x_1.json")
        self._write_source(
            self.pack_dir / "a1_y_1.json", packId="a1_y_1", topic="Y", concept="concept_a1_y",
        )
        self._write_source(self.pack_dir / "b1_y_1.json", packId="b1_y_1", level="b1")  # pre-existing conflict
        move_x = self._move()
        move_y = self._move(bundle="a1_y_1", newPackId="b1_y_1")
        report = self._report(move_x, move_y)

        with self.assertRaisesRegex(rb.RelevelError, "already exists"):
            rb.sync_pack_source_files((move_x, move_y), report, self.pack_dir)

        self.assertEqual([("a1_x_1", "b1_x_1")], report.pack_sources_synced)
        self.assertFalse((self.pack_dir / "a1_x_1.json").exists())
        self.assertTrue((self.pack_dir / "b1_x_1.json").exists())
        self.assertTrue((self.pack_dir / "a1_y_1.json").exists(), "the failed move must not delete its own source")


class SyncPackSourcesEntryPointTest(unittest.TestCase):
    """The standalone --sync-pack-sources retroactive entry point (task
    T2.9a part (b)) -- idempotent replay of sync_pack_source_files against
    a bundle whose pack moves already landed in assets/data."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="sync-pack-sources-entry-test-")
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name) / "repo"
        self.pack_dir = self.root / "tools" / "content_factory" / "data" / "packs"
        self.pack_dir.mkdir(parents=True, exist_ok=True)
        self.pack_dir.joinpath("a1_x_1.json").write_text(
            json.dumps(
                {
                    "packId": "a1_x_1", "level": "a1", "orderInLevel": 1, "topic": "X",
                    "unit": "a1_01_greetings_hangul", "concept": "concept_a1_x", "motif": "cloud",
                    "labels": {"ko": "엑스", "de": "X", "en": "X"},
                    "words": [["가", "a", "a", "Nomen", "Noun", "가 예문.", "a Satz.", "a example."]],
                },
                ensure_ascii=False, indent=2,
            ) + "\n",
            encoding="utf-8",
        )
        self.bundle = rb.load_bundle_from_dict({
            "batch": "L2a-TEST",
            "moves": [{
                "bundle": "a1_x_1", "from": "a1", "to": "b1", "newPackId": "b1_x_1",
                "courseUnitId": "b1_04_relationships", "conceptIds": ["concept_b1_relationships"],
                "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
            }],
        })

    def test_dry_run_previews_and_writes_nothing(self) -> None:
        report = rb.sync_pack_sources(self.bundle, root=self.root, apply=False)
        self.assertEqual([], report.pack_sources_synced)
        self.assertTrue(by_bundle_report(report, "a1_x_1").has_pack_source)
        self.assertTrue((self.pack_dir / "a1_x_1.json").exists())

    def test_apply_syncs_and_is_idempotent_on_replay(self) -> None:
        report = rb.sync_pack_sources(self.bundle, root=self.root, apply=True)
        self.assertEqual([("a1_x_1", "b1_x_1")], report.pack_sources_synced)
        self.assertFalse((self.pack_dir / "a1_x_1.json").exists())
        self.assertTrue((self.pack_dir / "b1_x_1.json").exists())

        # Replaying against an already-synced bundle (LCP PR-L2a's real
        # L2a/L2a3 use case) must be a clean no-op, not an error.
        again = rb.sync_pack_sources(self.bundle, root=self.root, apply=True)
        self.assertEqual([], again.pack_sources_synced)
        self.assertFalse(by_bundle_report(again, "a1_x_1").has_pack_source)


def _card_style_test_move(**overrides) -> rb.Move:
    base = {
        "bundle": "a1_x_1", "from": "a1", "to": "b1", "newPackId": "b1_x_1",
        "courseUnitId": "b1_04_relationships", "conceptIds": ["concept_b1_relationships"],
        "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
    }
    base.update(overrides)
    return rb.Move.from_dict(base)


class EditCardStyleRegistryTest(unittest.TestCase):
    """Task T2.9b: docs/assets/CARD_STYLE_BASELINE.json path rename +
    STYLE_LOCK.json families.F-E-cards.members stem rename, tested directly
    against small in-memory JSON texts -- mirrors SyncPackSourceFilesTest's
    reasoning above: ApplyTest/RollbackTest already cover migrate()'s
    end-to-end wiring (including rollback) for the "alpha" pack, this covers
    edit_card_style_registry's own field-preservation, no-op, and
    already-registered-target contracts directly."""

    def test_renames_baseline_entry_verbatim_and_leaves_untouched_entry_intact(self) -> None:
        baseline_text = _card_style_baseline_text({
            "assets/illustrations/packs/a1_x_1.webp": dict(BASELINE_ENTRY_X),
            "assets/illustrations/packs/a1_untouched_1.webp": dict(BASELINE_ENTRY_UNTOUCHED),
        })
        lock_text = _style_lock_text(["a1_untouched_1", "a1_x_1"])
        move = _card_style_test_move()
        report = rb.MigrationReport(batch="TEST")

        new_baseline_text, new_lock_text = rb.edit_card_style_registry(
            baseline_text, lock_text, (move,), report,
        )

        new_baseline = json.loads(new_baseline_text)
        self.assertNotIn("assets/illustrations/packs/a1_x_1.webp", new_baseline["files"])
        renamed_entry = new_baseline["files"]["assets/illustrations/packs/b1_x_1.webp"]
        self.assertEqual(BASELINE_ENTRY_X, renamed_entry)  # sha256 + every other field verbatim
        untouched_entry = new_baseline["files"]["assets/illustrations/packs/a1_untouched_1.webp"]
        self.assertEqual(BASELINE_ENTRY_UNTOUCHED, untouched_entry)  # byte-for-byte (as a dict) untouched
        self.assertEqual(sorted(new_baseline["files"]), list(new_baseline["files"]))  # re-sorted by path

        new_lock = json.loads(new_lock_text)
        members = new_lock["families"]["F-E-cards"]["members"]
        self.assertEqual(["a1_untouched_1", "b1_x_1"], members)  # renamed + re-sorted

        self.assertEqual([("a1_x_1", "b1_x_1", "renamed")], report.card_style_registry_renames)

    def test_pack_absent_from_both_ledgers_is_a_reported_no_op_and_bytes_unchanged(self) -> None:
        baseline_text = _card_style_baseline_text({
            "assets/illustrations/packs/a1_untouched_1.webp": dict(BASELINE_ENTRY_UNTOUCHED),
        })
        lock_text = _style_lock_text(["a1_untouched_1"])
        move = _card_style_test_move()  # a1_x_1 -- not registered anywhere
        report = rb.MigrationReport(batch="TEST")

        new_baseline_text, new_lock_text = rb.edit_card_style_registry(
            baseline_text, lock_text, (move,), report,
        )

        self.assertEqual(baseline_text, new_baseline_text)
        self.assertEqual(lock_text, new_lock_text)
        self.assertEqual(
            [("a1_x_1", "b1_x_1", "not registered in the card-style ledger -- no-op")],
            report.card_style_registry_renames,
        )

    def test_rename_target_already_registered_in_baseline_raises(self) -> None:
        baseline_text = _card_style_baseline_text({
            "assets/illustrations/packs/a1_x_1.webp": dict(BASELINE_ENTRY_X),
            "assets/illustrations/packs/b1_x_1.webp": dict(BASELINE_ENTRY_UNTOUCHED),
        })
        lock_text = _style_lock_text(["a1_x_1", "b1_x_1"])
        move = _card_style_test_move()
        report = rb.MigrationReport(batch="TEST")

        with self.assertRaisesRegex(rb.RelevelError, "already has an entry"):
            rb.edit_card_style_registry(baseline_text, lock_text, (move,), report)

    def test_known_deviation_member_list_is_also_renamed(self) -> None:
        baseline_text = _card_style_baseline_text({
            "assets/illustrations/packs/a1_x_1.webp": dict(BASELINE_ENTRY_X),
        })
        lock_text = _style_lock_text(
            ["a1_x_1"],
            known_deviations={"C1-source-original": {"members": ["a1_other_1", "a1_x_1"]}},
        )
        move = _card_style_test_move()
        report = rb.MigrationReport(batch="TEST")

        _, new_lock_text = rb.edit_card_style_registry(baseline_text, lock_text, (move,), report)

        deviation_members = (
            json.loads(new_lock_text)["families"]["F-E-cards"]["knownDeviations"]["C1-source-original"]["members"]
        )
        self.assertEqual(["a1_other_1", "b1_x_1"], deviation_members)

    def test_idempotent_replay_after_already_renamed_is_a_no_op(self) -> None:
        baseline_text = _card_style_baseline_text({
            "assets/illustrations/packs/a1_x_1.webp": dict(BASELINE_ENTRY_X),
        })
        lock_text = _style_lock_text(["a1_x_1"])
        move = _card_style_test_move()

        once_baseline, once_lock = rb.edit_card_style_registry(
            baseline_text, lock_text, (move,), rb.MigrationReport(batch="TEST"),
        )
        again_report = rb.MigrationReport(batch="TEST")
        twice_baseline, twice_lock = rb.edit_card_style_registry(
            once_baseline, once_lock, (move,), again_report,
        )

        self.assertEqual(once_baseline, twice_baseline)
        self.assertEqual(once_lock, twice_lock)
        self.assertEqual(
            [("a1_x_1", "b1_x_1", "not registered in the card-style ledger -- no-op")],
            again_report.card_style_registry_renames,
        )


class CardStyleRegistrySyncEntryPointTest(unittest.TestCase):
    """The standalone --sync-artwork-registry retroactive entry point (task
    T2.9b) -- idempotent replay of edit_card_style_registry against a
    bundle whose dedicated pack artwork was already renamed on disk (LCP
    PR-L2a's real L2a/L2a3 use case: 16 packs renamed by migrate() before
    this sync step existed)."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="sync-artwork-registry-entry-test-")
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name) / "repo"
        assets_dir = self.root / "docs" / "assets"
        assets_dir.mkdir(parents=True, exist_ok=True)
        self.baseline_path = assets_dir / "CARD_STYLE_BASELINE.json"
        self.baseline_path.write_text(
            _card_style_baseline_text({
                "assets/illustrations/packs/a1_x_1.webp": dict(BASELINE_ENTRY_X),
            }),
            encoding="utf-8",
        )
        self.lock_path = assets_dir / "STYLE_LOCK.json"
        self.lock_path.write_text(_style_lock_text(["a1_x_1"]), encoding="utf-8")
        self.bundle = rb.load_bundle_from_dict({
            "batch": "L2a-TEST",
            "moves": [{
                "bundle": "a1_x_1", "from": "a1", "to": "b1", "newPackId": "b1_x_1",
                "courseUnitId": "b1_04_relationships", "conceptIds": ["concept_b1_relationships"],
                "scenarios": [], "cloze": "auto", "satz": "auto", "smalltalk": [], "reason": "r",
            }],
        })

    def test_dry_run_previews_and_writes_nothing(self) -> None:
        report = rb.sync_card_style_registry(self.bundle, root=self.root, apply=False)
        self.assertEqual([("a1_x_1", "b1_x_1", "renamed")], report.card_style_registry_renames)
        # dry run: nothing written -- the old stem is still on disk
        self.assertIn("a1_x_1", self.baseline_path.read_text(encoding="utf-8"))
        self.assertIn("a1_x_1", self.lock_path.read_text(encoding="utf-8"))

    def test_apply_syncs_and_is_idempotent_on_replay(self) -> None:
        report = rb.sync_card_style_registry(self.bundle, root=self.root, apply=True)
        self.assertEqual([("a1_x_1", "b1_x_1", "renamed")], report.card_style_registry_renames)
        baseline = json.loads(self.baseline_path.read_text(encoding="utf-8"))
        self.assertIn("assets/illustrations/packs/b1_x_1.webp", baseline["files"])
        self.assertNotIn("assets/illustrations/packs/a1_x_1.webp", baseline["files"])
        lock = json.loads(self.lock_path.read_text(encoding="utf-8"))
        self.assertEqual(["b1_x_1"], lock["families"]["F-E-cards"]["members"])

        # Replaying against an already-synced bundle (the real LCP PR-L2a
        # use case: this CLI mode runs once against relevel_bundle_L2a.json
        # and once against relevel_bundle_L2a3.json, and must be safe to
        # re-run) must be a clean no-op, not an error.
        again = rb.sync_card_style_registry(self.bundle, root=self.root, apply=True)
        self.assertEqual(
            [("a1_x_1", "b1_x_1", "not registered in the card-style ledger -- no-op")],
            again.card_style_registry_renames,
        )

    def test_missing_ledger_files_is_a_whole_bundle_no_op(self) -> None:
        self.baseline_path.unlink()
        self.lock_path.unlink()
        report = rb.sync_card_style_registry(self.bundle, root=self.root, apply=True)
        self.assertEqual(
            [("a1_x_1", "b1_x_1", "no card-style ledger at this root -- no-op")],
            report.card_style_registry_renames,
        )


def _scenario_test_move(**overrides) -> rb.ScenarioMove:
    base = {
        "id": "move_me", "from": "a1", "to": "b1", "shelf": "b1_team",
        "courseUnitId": "b1_04_relationships", "conceptIds": ["concept_b1_relationships"],
        "reason": "test",
    }
    base.update(overrides)
    return rb.ScenarioMove.from_dict(base)


def _scenario_test_report(*moves: rb.ScenarioMove) -> rb.MigrationReport:
    report = rb.MigrationReport(batch="TEST")
    for move in moves:
        report.scenarios.append(rb.ScenarioMoveReport(
            scenario_id=move.id, from_level=move.from_level, to_level=move.to_level,
            course_unit_id=move.course_unit_id, shelf=move.shelf,
        ))
    return report


class BucketForShelfTest(unittest.TestCase):
    def test_unique_match_resolves(self) -> None:
        self.assertEqual("study_work_digital_communication", rb._bucket_for_shelf("b1", "b1_team"))

    def test_regression_catch_all_is_excluded_from_ambiguity(self) -> None:
        # materialize_canonical_scenarios.SHELF_BY_BUCKET["a2"] maps BOTH
        # "study_work_digital_media" and "regression" to "a2_work" -- a
        # real, current collision in that table, not a hypothetical.
        self.assertEqual("study_work_digital_media", rb._bucket_for_shelf("a2", "a2_work"))

    def test_unknown_level_raises(self) -> None:
        with self.assertRaisesRegex(rb.RelevelError, "no level"):
            rb._bucket_for_shelf("a0", "a0_x")

    def test_shelf_with_no_match_raises(self) -> None:
        with self.assertRaisesRegex(rb.RelevelError, "cannot uniquely resolve"):
            rb._bucket_for_shelf("b1", "b1_not_a_real_shelf")


class SyncCanonicalAuthoredScenariosTest(unittest.TestCase):
    """Uses the *real* tools/content_factory/canonical_scenarios/authored/
    <level>.json format directly (raw text, not json.dumps(indent=2)): the
    outer document is pretty-printed, but each entry's title/intro objects
    and dialog turns are hand-collapsed onto one line apiece. A fixture
    built via json.dumps like build_level_content_4x's own tests use would
    not have caught the bug this class exists to pin down -- sync_
    canonical_authored_scenarios must edit this file's *text* directly, or
    a full parse+rewrite silently reformats every untouched scenario too.
    """

    A1_TEXT = (
        '{\n'
        '  "schemaVersion": 1,\n'
        '  "generationId": "test",\n'
        '  "level": "a1",\n'
        '  "scenarios": [\n'
        '    {\n'
        '      "id": "keep_a1",\n'
        '      "title": {"de": "D1", "en": "E1"},\n'
        '      "intro": {"ko": "K1", "de": "D1", "en": "E1"},\n'
        '      "dialog": [\n'
        '        {"speaker": "user", "ko": "안녕하세요", "de": "Hallo", "en": "Hello"}\n'
        '      ]\n'
        '    },\n'
        '    {\n'
        '      "id": "move_me",\n'
        '      "title": {"de": "D2", "en": "E2"},\n'
        '      "intro": {"ko": "K2", "de": "D2", "en": "E2"},\n'
        '      "dialog": [\n'
        '        {"speaker": "user", "ko": "안녕, 반가워요", "de": "Hallo, freut mich", "en": "Hi, nice to meet you"}\n'
        '      ]\n'
        '    },\n'
        '    {\n'
        '      "id": "keep_a1_after",\n'
        '      "title": {"de": "D3", "en": "E3"},\n'
        '      "intro": {"ko": "K3", "de": "D3", "en": "E3"},\n'
        '      "dialog": [\n'
        '        {"speaker": "user", "ko": "잘 가요", "de": "Tsch\\u00fcss", "en": "Bye"}\n'
        '      ]\n'
        '    }\n'
        '  ]\n'
        '}\n'
    )
    B1_TEXT = (
        '{\n'
        '  "schemaVersion": 1,\n'
        '  "generationId": "test",\n'
        '  "level": "b1",\n'
        '  "scenarios": [\n'
        '    {\n'
        '      "id": "already_here",\n'
        '      "title": {"de": "D4", "en": "E4"},\n'
        '      "intro": {"ko": "K4", "de": "D4", "en": "E4"},\n'
        '      "dialog": [\n'
        '        {"speaker": "user", "ko": "네, 알겠습니다", "de": "Ja, verstanden", "en": "Yes, understood"}\n'
        '      ]\n'
        '    }\n'
        '  ]\n'
        '}\n'
    )

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="sync-canonical-authored-test-")
        self.addCleanup(self._tmp.cleanup)
        self.authored_dir = Path(self._tmp.name)
        (self.authored_dir / "a1.json").write_bytes(self.A1_TEXT.encode("utf-8"))
        (self.authored_dir / "b1.json").write_bytes(self.B1_TEXT.encode("utf-8"))

    def test_missing_directory_is_a_silent_no_op(self) -> None:
        move = _scenario_test_move()
        report = _scenario_test_report(move)
        rb.sync_canonical_authored_scenarios((move,), report, self.authored_dir / "does_not_exist")
        self.assertFalse((self.authored_dir / "does_not_exist").exists())

    def test_moves_entry_unedited_and_preserves_every_other_bytes(self) -> None:
        move = _scenario_test_move()
        report = _scenario_test_report(move)
        rb.sync_canonical_authored_scenarios((move,), report, self.authored_dir)

        a1_text = (self.authored_dir / "a1.json").read_text(encoding="utf-8")
        a1 = json.loads(a1_text)
        self.assertEqual(["keep_a1", "keep_a1_after"], [s["id"] for s in a1["scenarios"]])
        # the two untouched entries' exact hand-collapsed lines survive
        # byte-for-byte -- proving this is a text edit, not a reformat.
        self.assertIn('      "title": {"de": "D1", "en": "E1"},\n', a1_text)
        self.assertIn(
            '        {"speaker": "user", "ko": "잘 가요", "de": "Tsch\\u00fcss", "en": "Bye"}\n', a1_text,
        )
        self.assertTrue(a1_text.startswith('{\n  "schemaVersion": 1,\n'))

        b1_text = (self.authored_dir / "b1.json").read_text(encoding="utf-8")
        b1 = json.loads(b1_text)
        self.assertEqual(["already_here", "move_me"], [s["id"] for s in b1["scenarios"]])
        moved = next(s for s in b1["scenarios"] if s["id"] == "move_me")
        self.assertEqual(
            [{"speaker": "user", "ko": "안녕, 반가워요", "de": "Hallo, freut mich", "en": "Hi, nice to meet you"}],
            moved["dialog"],
        )
        # the moved entry's own hand-collapsed dialog line is untouched too
        self.assertIn(
            '        {"speaker": "user", "ko": "안녕, 반가워요", "de": "Hallo, freut mich", '
            '"en": "Hi, nice to meet you"}\n',
            b1_text,
        )
        # the pre-existing "already_here" entry (now no longer last) gained
        # exactly the trailing comma a valid array needs and nothing else.
        self.assertIn('      ]\n    },\n    {\n      "id": "move_me"', b1_text)
        self.assertEqual(
            "authored/a1.json -> authored/b1.json", report.scenarios[0].canonical_authored_note,
        )
        for path in (self.authored_dir / "a1.json", self.authored_dir / "b1.json"):
            self.assertNotIn(b"\r\n", path.read_bytes())

    def test_moving_the_only_remaining_entry_leaves_valid_json(self) -> None:
        # Removing "move_me" from a1 when it sits *between* two kept
        # entries must not leave a dangling/missing comma at the splice
        # point -- covered structurally by the previous test's JSON parse,
        # this one drives the harder edge: b1 has a single entry, so
        # inserting after it must add the separator itself.
        move = _scenario_test_move(
            id="already_here", **{"from": "b1"}, to="a1", shelf="a1_friends",
            courseUnitId="a1_16_survival_capstone", conceptIds=["concept_a1_survival"],
        )
        report = _scenario_test_report(move)
        rb.sync_canonical_authored_scenarios((move,), report, self.authored_dir)
        b1 = json.loads((self.authored_dir / "b1.json").read_text(encoding="utf-8"))
        self.assertEqual([], b1["scenarios"])
        a1 = json.loads((self.authored_dir / "a1.json").read_text(encoding="utf-8"))
        self.assertEqual(
            ["keep_a1", "move_me", "keep_a1_after", "already_here"],
            [s["id"] for s in a1["scenarios"]],
        )

    def test_id_not_found_raises(self) -> None:
        move = _scenario_test_move(id="ghost_scenario")
        report = _scenario_test_report(move)
        with self.assertRaisesRegex(rb.RelevelError, "not found in canonical authored source"):
            rb.sync_canonical_authored_scenarios((move,), report, self.authored_dir)
        # the source file must be untouched by a failed move
        self.assertEqual(self.A1_TEXT, (self.authored_dir / "a1.json").read_text(encoding="utf-8"))


class EditScenarioBriefsSourceTest(unittest.TestCase):
    FIXTURE = (
        '{\n'
        '  "scenarios": [\n'
        '    {"id":"keep_a1","level":"a1","portfolioBucket":"identity_relationships","titleKo":"x"},\n'
        '    {"id":"move_me","level":"a1","portfolioBucket":"school_leisure","titleKo":"y",'
        '"courseUnitId":"a1_16_survival_capstone"},\n'
        '    {"id":"last_no_comma","level":"c2","portfolioBucket":"academic_science_professional","titleKo":"z"}\n'
        '  ]\n'
        '}\n'
    )

    def test_rewrites_level_bucket_and_unit_leaves_other_fields_untouched(self) -> None:
        move = _scenario_test_move()
        report = _scenario_test_report(move)
        new_text = rb.edit_scenario_briefs_source(self.FIXTURE, (move,), report)

        lines = new_text.split("\n")
        untouched = [line for line in lines if '"keep_a1"' in line or '"last_no_comma"' in line]
        self.assertEqual(2, len(untouched))
        for line in untouched:
            self.assertIn(line, self.FIXTURE)

        moved_line = next(line for line in lines if '"move_me"' in line)
        entry = json.loads(moved_line.strip().rstrip(","))
        self.assertEqual("b1", entry["level"])
        self.assertEqual("study_work_digital_communication", entry["portfolioBucket"])
        self.assertEqual("b1_04_relationships", entry["courseUnitId"])
        self.assertEqual("y", entry["titleKo"])  # untouched field survives
        self.assertEqual(
            "level='b1' portfolioBucket='study_work_digital_communication'",
            report.scenarios[0].scenario_brief_note,
        )
        # the file's own JSON structure (indentation, key ordering outside
        # the rewritten line) survives -- proving this is a line edit, not
        # a full json.loads()/dumps() round trip of the whole file.
        self.assertTrue(new_text.startswith('{\n  "scenarios": [\n'))

    def test_level_mismatch_raises(self) -> None:
        # FIXTURE's "move_me" entry says level "a1"; claim it moved from
        # "a2" instead, to trigger the from-level cross-check.
        move = _scenario_test_move(**{"from": "a2"})
        report = _scenario_test_report(move)
        with self.assertRaisesRegex(rb.RelevelError, "disagrees with move.from"):
            rb.edit_scenario_briefs_source(self.FIXTURE, (move,), report)

    def test_id_not_found_raises(self) -> None:
        move = _scenario_test_move(id="ghost_scenario")
        report = _scenario_test_report(move)
        with self.assertRaisesRegex(rb.RelevelError, "scenario id.s. not found"):
            rb.edit_scenario_briefs_source(self.FIXTURE, (move,), report)

    def test_no_scenario_moves_is_a_no_op(self) -> None:
        report = rb.MigrationReport(batch="TEST")
        self.assertEqual(self.FIXTURE, rb.edit_scenario_briefs_source(self.FIXTURE, (), report))


class SyncReviewCandidateScenariosTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="sync-review-candidate-test-")
        self.addCleanup(self._tmp.cleanup)
        self.candidates_dir = Path(self._tmp.name)
        (self.candidates_dir / "a1").mkdir(parents=True, exist_ok=True)
        self._write_candidate("a1", "move_me")

    def _write_candidate(self, level: str, scenario_id: str, **scenario_overrides) -> None:
        scenario = {
            "id": scenario_id, "level": level, "shelf": "a1_friends",
            "courseUnitId": "a1_16_survival_capstone", "conceptIds": ["concept_a1_survival"],
            "title": {"ko": "K", "de": "D", "en": "E"}, "dialog": [], "quests": [], "xpReward": 100,
        }
        scenario.update(scenario_overrides)
        (self.candidates_dir / level).mkdir(parents=True, exist_ok=True)
        (self.candidates_dir / level / f"{scenario_id}.json").write_text(
            json.dumps(
                {"kind": "scenario_candidate", "scenarioId": scenario_id, "scenario": scenario,
                 "editorialSource": "canonical_scenarios/authored"},
                ensure_ascii=False, indent=2,
            ) + "\n",
            encoding="utf-8",
        )

    def test_missing_directory_is_a_silent_no_op(self) -> None:
        move = _scenario_test_move()
        report = _scenario_test_report(move)
        rb.sync_review_candidate_scenarios((move,), report, self.candidates_dir / "does_not_exist")
        self.assertFalse((self.candidates_dir / "does_not_exist").exists())

    def test_missing_candidate_for_this_id_is_a_per_move_no_op(self) -> None:
        move = _scenario_test_move(id="no_candidate_for_this_one")
        report = _scenario_test_report(move)
        rb.sync_review_candidate_scenarios((move,), report, self.candidates_dir)
        self.assertEqual([], report.review_candidates_synced)

    def test_moves_and_patches_routing_fields_only(self) -> None:
        move = _scenario_test_move()
        report = _scenario_test_report(move)
        rb.sync_review_candidate_scenarios((move,), report, self.candidates_dir)

        self.assertFalse((self.candidates_dir / "a1" / "move_me.json").exists())
        payload = json.loads((self.candidates_dir / "b1" / "move_me.json").read_text(encoding="utf-8"))
        scenario = payload["scenario"]
        self.assertEqual("b1", scenario["level"])
        self.assertEqual("b1_team", scenario["shelf"])
        self.assertEqual("b1_04_relationships", scenario["courseUnitId"])
        self.assertEqual(["concept_b1_relationships"], scenario["conceptIds"])
        # untouched
        self.assertEqual(100, scenario["xpReward"])
        self.assertEqual("canonical_scenarios/authored", payload["editorialSource"])
        self.assertEqual([("move_me", "a1", "b1")], report.review_candidates_synced)
        self.assertEqual("a1/ -> b1/move_me.json", report.scenarios[0].review_candidate_note)

    def test_target_already_existing_raises_and_leaves_source_untouched(self) -> None:
        self._write_candidate("b1", "move_me")
        move = _scenario_test_move()
        report = _scenario_test_report(move)
        with self.assertRaisesRegex(rb.RelevelError, "already exists"):
            rb.sync_review_candidate_scenarios((move,), report, self.candidates_dir)
        self.assertTrue((self.candidates_dir / "a1" / "move_me.json").exists())
        self.assertEqual([], report.review_candidates_synced)


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


# ───────────────────────── grammarMoves (LCP PR-L2b phase 1) ──────────────


def _grammar_move_dict(**overrides) -> dict:
    base = {
        "id": "grammar_a1_relvtest_alpha",
        "to": "a2",
        "courseUnitId": "a2_06_study_work",
        "conceptIds": ["concept_a2_work_study"],
        "reason": "test grammar move",
    }
    base.update(overrides)
    return base


class GrammarMoveShapeTest(unittest.TestCase):
    def test_valid_move_round_trips(self) -> None:
        move = rb.GrammarMove.from_dict(_grammar_move_dict())
        self.assertEqual(move.id, "grammar_a1_relvtest_alpha")
        self.assertEqual(move.to_level, "a2")
        self.assertEqual(move.course_unit_id, "a2_06_study_work")
        self.assertEqual(move.concept_ids, ("concept_a2_work_study",))
        self.assertIsNone(move.can_do_cluster_id)
        self.assertIsNone(move.from_level)

    def test_optional_from_and_can_do_cluster_id_round_trip(self) -> None:
        move = rb.GrammarMove.from_dict(
            _grammar_move_dict(**{"from": "a1", "canDoClusterId": "cluster_a2_x_v1"})
        )
        self.assertEqual(move.from_level, "a1")
        self.assertEqual(move.can_do_cluster_id, "cluster_a2_x_v1")

    def test_missing_field_is_rejected(self) -> None:
        for key in ("id", "to", "courseUnitId", "conceptIds", "reason"):
            raw = _grammar_move_dict()
            del raw[key]
            with self.assertRaises(rb.RelevelError):
                rb.GrammarMove.from_dict(raw)

    def test_bad_id_prefix_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.GrammarMove.from_dict(_grammar_move_dict(id="vocab_a1_0001"))

    def test_bad_to_level_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.GrammarMove.from_dict(_grammar_move_dict(to="a9"))

    def test_empty_concept_ids_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.GrammarMove.from_dict(_grammar_move_dict(conceptIds=[]))

    def test_declared_from_equal_to_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.GrammarMove.from_dict(_grammar_move_dict(**{"from": "a2"}))  # to is already "a2"

    def test_blank_can_do_cluster_id_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.GrammarMove.from_dict(_grammar_move_dict(canDoClusterId="   "))

    def test_bundle_may_have_only_grammar_moves(self) -> None:
        bundle = rb.load_bundle_from_dict({"batch": "TEST", "grammarMoves": [_grammar_move_dict()]})
        self.assertEqual(len(bundle.grammar_moves), 1)
        self.assertEqual(bundle.moves, ())
        self.assertEqual(bundle.scenario_moves, ())

    def test_bundle_with_nothing_at_all_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.load_bundle_from_dict({"batch": "TEST"})

    def test_duplicate_grammar_move_id_is_rejected(self) -> None:
        with self.assertRaises(rb.RelevelError):
            rb.load_bundle_from_dict({
                "batch": "TEST",
                "grammarMoves": [_grammar_move_dict(), _grammar_move_dict()],
            })


class DistractorRepairUnitTest(unittest.TestCase):
    """Direct unit tests of ``_repair_grammar_quiz_distractors`` against a
    small, fully self-contained synthetic ``grammar_rows`` list (no fixture,
    no real corpus) so the exact chosen replacement ids can be hand-verified
    (see the derivation of the expected tuple below)."""

    @staticmethod
    def _row(ident: str, level: str, type_en: str, *, enabled: str = "true",
              distractors: tuple[str, ...] = ()) -> dict[str, str]:
        return {
            "id": ident, "level": level, "type_en": type_en, "quiz_enabled": enabled,
            "quiz_distractor_ids": "|".join(distractors),
        }

    def _rows(self) -> list[dict[str, str]]:
        return [
            self._row("grammar_a1_aaa", "A1", "Family1",
                      distractors=("grammar_a1_bbb", "grammar_a1_ccc", "grammar_a1_zzz")),
            self._row("grammar_a1_bbb", "A1", "Family1",
                      distractors=("grammar_a1_aaa", "grammar_a1_ccc", "grammar_a1_ddd")),
            self._row("grammar_a1_ccc", "A1", "Family2",
                      distractors=("grammar_a1_aaa", "grammar_a1_bbb", "grammar_a1_ddd")),
            self._row("grammar_a1_ddd", "A1", "Family1",
                      distractors=("grammar_a1_bbb", "grammar_a1_ccc", "grammar_a1_eee")),
            self._row("grammar_a1_eee", "A1", "Family2",
                      distractors=("grammar_a1_aaa", "grammar_a1_bbb", "grammar_a1_ccc")),
            # Simulates a row that already moved away to A2 (its own quiz
            # disabled here purely so this fixture doesn't also need 3
            # OTHER A2 rows just to make grammar_a1_zzz's own repair
            # possible -- that path is covered by
            # test_too_few_candidates_raises below instead).
            self._row("grammar_a1_zzz", "A2", "Family1", enabled="false"),
        ]

    def test_only_the_row_whose_distractor_moved_away_is_repaired(self) -> None:
        rows = self._rows()
        report = rb.MigrationReport(batch="TEST")
        rb._repair_grammar_quiz_distractors(rows, report)

        repaired_ids = {r.grammar_id for r in report.distractor_repairs}
        self.assertEqual(repaired_ids, {"grammar_a1_aaa"})

    def test_replacement_prefers_same_type_en_family_then_id_distance(self) -> None:
        # By hand: aaa's valid A1 quiz-enabled siblings are {bbb, ccc, ddd,
        # eee}. Same family (Family1, matching aaa) = {bbb, ddd}; other
        # family = {ccc, eee}. Sorted id list [aaa,bbb,ccc,ddd,eee] puts aaa
        # at index 0, so distances are bbb=1, ccc=2, ddd=3, eee=4. Family
        # tier sorted by distance: [bbb, ddd]; other tier: [ccc, eee].
        # First 3 of family+other = [bbb, ddd, ccc].
        rows = self._rows()
        report = rb.MigrationReport(batch="TEST")
        rb._repair_grammar_quiz_distractors(rows, report)

        by_id = {row["id"]: row for row in rows}
        self.assertEqual(
            by_id["grammar_a1_aaa"]["quiz_distractor_ids"],
            "grammar_a1_bbb|grammar_a1_ddd|grammar_a1_ccc",
        )
        [repair] = report.distractor_repairs
        self.assertEqual(repair.grammar_id, "grammar_a1_aaa")
        self.assertEqual(repair.old_distractor_ids, ("grammar_a1_bbb", "grammar_a1_ccc", "grammar_a1_zzz"))
        self.assertEqual(repair.new_distractor_ids, ("grammar_a1_bbb", "grammar_a1_ddd", "grammar_a1_ccc"))

    def test_unaffected_rows_are_untouched(self) -> None:
        rows = self._rows()
        before = {row["id"]: dict(row) for row in rows if row["id"] != "grammar_a1_aaa"}
        report = rb.MigrationReport(batch="TEST")
        rb._repair_grammar_quiz_distractors(rows, report)
        after = {row["id"]: row for row in rows if row["id"] != "grammar_a1_aaa"}
        self.assertEqual(before, after)

    def test_too_few_candidates_raises(self) -> None:
        rows = [
            self._row("grammar_c2_solo", "C2", "Lonely",
                      distractors=("grammar_c2_ghost1", "grammar_c2_ghost2", "grammar_c2_ghost3")),
        ]
        report = rb.MigrationReport(batch="TEST")
        with self.assertRaises(rb.RelevelError):
            rb._repair_grammar_quiz_distractors(rows, report)


class ScenarioGrammarRegressionUnitTest(unittest.TestCase):
    def test_flags_only_the_scenario_now_below_the_referenced_grammar(self) -> None:
        scenarios = [
            {"id": "s_ok_higher_level", "level": "b1", "grammarIds": ["grammar_a1_x"]},
            {"id": "s_now_below", "level": "a1", "grammarIds": ["grammar_a1_x"]},
            {"id": "s_no_grammar_ids", "level": "a1", "grammarIds": []},
            {"id": "s_unknown_level", "level": "not_a_level", "grammarIds": ["grammar_a1_x"]},
        ]
        # grammar_a1_x has since moved to a2 (post-move live level).
        grammar_rows = [{"id": "grammar_a1_x", "level": "A2"}]
        report = rb.MigrationReport(batch="TEST")

        rb._check_scenario_grammar_regressions(scenarios, grammar_rows, report)

        self.assertEqual(len(report.scenario_grammar_regressions), 1)
        self.assertIn("s_now_below", report.scenario_grammar_regressions[0])
        self.assertIn("grammar_a1_x", report.scenario_grammar_regressions[0])

    def test_no_move_means_no_warnings(self) -> None:
        scenarios = [{"id": "s1", "level": "a1", "grammarIds": ["grammar_a1_x"]}]
        grammar_rows = [{"id": "grammar_a1_x", "level": "A1"}]
        report = rb.MigrationReport(batch="TEST")
        rb._check_scenario_grammar_regressions(scenarios, grammar_rows, report)
        self.assertEqual(report.scenario_grammar_regressions, [])


GRAMMAR_SOURCE_UNIT = "a1_01_greetings_hangul"
GRAMMAR_SOURCE_CLUSTER_ID = "cluster_a1_01_greetings_hangul_v1"
GRAMMAR_SOURCE_CONCEPT = "concept_greeting_politeness"
GRAMMAR_TARGET_UNIT_A2 = "a2_06_study_work"
GRAMMAR_TARGET_CONCEPT_A2 = "concept_a2_work_study"

# 4 synthetic A1 rows: alpha/beta/gamma get full can-do wiring, delta gets
# none (exercises the "report candidates otherwise" path). Each row's
# quiz_distractor_ids lists the *other 3* synthetic ids, so moving one row
# away invalidates every other row's distractor set -- a real cross-row
# repair, not just a self-repair.
GRAMMAR_SYNTHETIC_IDS = (
    "grammar_a1_relvtest_alpha",
    "grammar_a1_relvtest_beta",
    "grammar_a1_relvtest_gamma",
    "grammar_a1_relvtest_delta",
)


def _synthetic_grammar_row(ident: str) -> dict[str, str]:
    others = tuple(i for i in GRAMMAR_SYNTHETIC_IDS if i != ident)
    return {
        "pattern": f"TEST-{ident}", "level": "A1", "type_de": "Testtyp",
        "explanation_de": "Testerklärung.", "example_korean": f"{ident} 테스트예요.",
        "example_german": f"Das ist {ident} Test.", "note": "Testnotiz.",
        "type_en": "Test type", "explanation_en": "Test explanation.",
        "example_en": f"This is {ident} test.", "note_en": "Test note.", "id": ident,
        "quiz_focus_de": ident, "quiz_focus_en": ident, "quiz_enabled": "true",
        "quiz_distractor_ids": "|".join(others),
    }


class GrammarRelevelBundleFixture(unittest.TestCase):
    """Copies the real, already-valid ``assets/data`` (same strategy as
    ``RelevelBundleFixture``) and injects 4 synthetic A1 grammar.csv rows
    this suite owns completely, so assertions never depend on which real
    grammar ids happen to exist or what NIKL-canon moves Fable has ruled on
    yet."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="relevel-grammar-test-")
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
        audit_manifest = json.loads(audit_manifest_path.read_text(encoding="utf-8"))
        for source in audit_manifest["sources"]:
            if source["kind"] == "grammar":
                source["count"] += len(GRAMMAR_SYNTHETIC_IDS)
        audit_manifest_path.write_text(
            json.dumps(audit_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
        )
        (self.root / "functions" / "analyze_korean_text").mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            REPO / "functions" / "analyze_korean_text" / "grammar_patterns.json",
            self.root / "functions" / "analyze_korean_text" / "grammar_patterns.json",
        )

        # migrate() unconditionally previews/edits these 3 Dart sources when
        # `bundle.moves` (vocab) is nonempty; a grammar-only bundle leaves
        # `bundle.moves` empty, so these stubs are read but never meaningfully
        # touched (0 vocab moves = a no-op edit) -- provisioned anyway so the
        # unconditional read never raises FileNotFoundError.
        (self.root / "lib" / "services").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "services" / "vocab_pack_service.dart").write_text(
            "class VocabPackService {\n"
            "  static const Map<String, (String, String)> packDisplayMap = {\n  };\n"
            "  static const Map<String, int> packOrderInLevel = {\n  };\n}\n", encoding="utf-8",
        )
        (self.root / "lib" / "data").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "data" / "pack_artwork_catalog.dart").write_text(
            "abstract final class PackArtworkCatalog {\n"
            "  static const dedicatedPackIds = <String>{\n  };\n}\n",
            encoding="utf-8",
        )
        (self.root / "lib" / "widgets" / "sori").mkdir(parents=True, exist_ok=True)
        (self.root / "lib" / "widgets" / "sori" / "dancheong_stamp.dart").write_text(
            "DancheongMotif motifForPackId(String packId) {\n"
            "  final base = _baseOf(packId);\n"
            "  return switch (base) {\n    _ => DancheongMotif.lotus,\n  };\n}\n", encoding="utf-8",
        )
        (self.root / "assets" / "illustrations" / "packs").mkdir(parents=True, exist_ok=True)

        self.ledger_path = Path(self._tmp.name) / "relevel_ledger.json"
        shutil.copy2(REPO / "tools" / "content_factory" / "relevel_ledger.json", self.ledger_path)

        self._inject_synthetic_grammar_rows(data)

    def _inject_synthetic_grammar_rows(self, data: Path) -> None:
        grammar_path = data / "grammar.csv"
        with grammar_path.open(encoding="utf-8", newline="") as handle:
            reader = csv.reader(handle)
            header = next(reader)
            assert header == GRAMMAR_HEADER, header
            rows = [dict(zip(header, row)) for row in reader if row]
        rows.extend(_synthetic_grammar_row(ident) for ident in GRAMMAR_SYNTHETIC_IDS)
        with grammar_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.writer(handle, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
            writer.writerow(GRAMMAR_HEADER)
            for row in rows:
                writer.writerow([row[column] for column in GRAMMAR_HEADER])

        curriculum_path = data / "curriculum_manifest.json"
        curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
        for ident in GRAMMAR_SYNTHETIC_IDS:
            curriculum["grammarRuleMap"][ident] = {
                "courseUnitId": GRAMMAR_SOURCE_UNIT, "conceptIds": [GRAMMAR_SOURCE_CONCEPT],
            }
        curriculum_path.write_text(
            json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
        )

        # alpha/beta/gamma get full can-do wiring; delta deliberately does
        # not (exercises the no-direct-reference "report candidates" path).
        auth_path = data / rb.CAN_DO_AUTHORITIES_JSON
        authorities = json.loads(auth_path.read_text(encoding="utf-8"))
        segments_path = data / rb.CAN_DO_SEGMENTS_JSON
        segments_doc = json.loads(segments_path.read_text(encoding="utf-8"))
        cluster = next(c for c in segments_doc["contentClusters"] if c["id"] == GRAMMAR_SOURCE_CLUSTER_ID)
        for ident in GRAMMAR_SYNTHETIC_IDS[:3]:
            seed_id = f"seed_grammar_{ident}_v1"
            authorities["sourceSeeds"].append({"id": seed_id, "level": "a1"})
            authorities["contentReferences"].append({
                "kind": "grammar", "id": ident, "level": "a1",
                "sourceSeedId": seed_id, "courseUnitId": GRAMMAR_SOURCE_UNIT,
            })
            authorities["coverage"]["directReferenceCounts"]["grammar"] += 1
            cluster["contentReferences"].append({"kind": "grammar", "id": ident})
            cluster["sourceSeedIds"].append(seed_id)
        auth_path.write_text(json.dumps(authorities, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        segments_path.write_text(json.dumps(segments_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # ---- helpers ----------------------------------------------------------

    def _snapshot(self) -> dict[Path, bytes]:
        paths = [self.root / "assets" / "data" / name for name in rb._STAGED_DATA_FILES] + [self.ledger_path]
        return {path: (path.read_bytes() if path.exists() else None) for path in paths}

    def _assert_unchanged(self, snapshot: dict[Path, bytes]) -> None:
        for path, content in snapshot.items():
            current = path.read_bytes() if path.exists() else None
            self.assertEqual(content, current, f"{path} changed unexpectedly")

    def _bundle(self, grammar_moves: list[dict]) -> rb.BundleFile:
        return rb.load_bundle_from_dict({"batch": "TEST", "grammarMoves": grammar_moves})

    def _read_grammar_rows(self) -> dict[str, dict[str, str]]:
        with (self.root / "assets" / "data" / "grammar.csv").open(encoding="utf-8", newline="") as handle:
            reader = csv.reader(handle)
            header = next(reader)
            self.assertEqual(header, GRAMMAR_HEADER)
            return {row["id"]: row for row in (dict(zip(header, r)) for r in reader if r)}


class GrammarDryRunTest(GrammarRelevelBundleFixture):
    def test_dry_run_computes_plan_and_changes_nothing(self) -> None:
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_beta", to="a2",
            courseUnitId=GRAMMAR_TARGET_UNIT_A2, conceptIds=[GRAMMAR_TARGET_CONCEPT_A2],
        )
        bundle = self._bundle([move])
        snapshot = self._snapshot()

        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)

        self.assertEqual(len(report.grammar), 1)
        grammar_report = report.grammar[0]
        self.assertEqual(grammar_report.grammar_id, "grammar_a1_relvtest_beta")
        self.assertEqual(grammar_report.from_level, "a1")
        self.assertEqual(grammar_report.to_level, "a2")
        self.assertIn("moved", grammar_report.can_do_note)
        # alpha/beta/gamma/delta all referenced beta as a distractor (and
        # beta itself needs new A2 distractors) -- exactly these 4, nothing
        # from the real corpus (which cannot reference a synthetic id).
        self.assertEqual(
            {r.grammar_id for r in report.distractor_repairs},
            set(GRAMMAR_SYNTHETIC_IDS),
        )
        self.assertTrue(report.grammar_patterns_note)
        plan = rb.format_plan(report, apply=False)
        self.assertIn("grammar_a1_relvtest_beta", plan)
        self.assertIn("dry-run", plan)

        self._assert_unchanged(snapshot)


class GrammarApplyTest(GrammarRelevelBundleFixture):
    def test_apply_moves_level_curriculum_can_do_and_repairs_distractors(self) -> None:
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_beta", to="a2",
            courseUnitId=GRAMMAR_TARGET_UNIT_A2, conceptIds=[GRAMMAR_TARGET_CONCEPT_A2],
        )
        bundle = self._bundle([move])

        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        rows = self._read_grammar_rows()
        self.assertEqual(rows["grammar_a1_relvtest_beta"]["level"], "A2")
        for ident in ("grammar_a1_relvtest_alpha", "grammar_a1_relvtest_gamma", "grammar_a1_relvtest_delta"):
            self.assertEqual(rows[ident]["level"], "A1")

        # Every quiz-enabled row's distractors are now internally valid
        # (same level, unique, non-self, quiz-enabled) -- including beta's
        # own freshly repaired A2 set.
        for ident in GRAMMAR_SYNTHETIC_IDS:
            distractor_ids = rows[ident]["quiz_distractor_ids"].split("|")
            self.assertEqual(len(distractor_ids), 3)
            self.assertEqual(len(set(distractor_ids)), 3)
            self.assertNotIn(ident, distractor_ids)
            for distractor_id in distractor_ids:
                self.assertEqual(rows[distractor_id]["level"], rows[ident]["level"])

        ledger = relevel_ledger.load_ledger(self.ledger_path)
        entry = ledger.get("grammar", "grammar_a1_relvtest_beta")
        self.assertIsNotNone(entry)
        self.assertEqual((entry.from_level, entry.to_level), ("a1", "a2"))

        curriculum = json.loads(
            (self.root / "assets" / "data" / "curriculum_manifest.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            curriculum["grammarRuleMap"]["grammar_a1_relvtest_beta"],
            {"courseUnitId": GRAMMAR_TARGET_UNIT_A2, "conceptIds": [GRAMMAR_TARGET_CONCEPT_A2]},
        )

        authorities = json.loads(
            (self.root / "assets" / "data" / rb.CAN_DO_AUTHORITIES_JSON).read_text(encoding="utf-8")
        )
        direct = next(
            r for r in authorities["contentReferences"]
            if r.get("kind") == "grammar" and r.get("id") == "grammar_a1_relvtest_beta"
        )
        self.assertEqual(direct["level"], "a2")
        self.assertEqual(direct["courseUnitId"], GRAMMAR_TARGET_UNIT_A2)

        segments_doc = json.loads(
            (self.root / "assets" / "data" / rb.CAN_DO_SEGMENTS_JSON).read_text(encoding="utf-8")
        )
        clusters_by_id = {c["id"]: c for c in segments_doc["contentClusters"]}
        source_cluster = clusters_by_id[GRAMMAR_SOURCE_CLUSTER_ID]
        self.assertNotIn(
            {"kind": "grammar", "id": "grammar_a1_relvtest_beta"}, source_cluster["contentReferences"],
        )
        target_cluster_id = report.grammar[0].target_cluster_id
        self.assertIn(
            {"kind": "grammar", "id": "grammar_a1_relvtest_beta"},
            clusters_by_id[target_cluster_id]["contentReferences"],
        )

        # A final post-write ContentValidator pass (migrate() already ran
        # one internally before returning) proves the whole staged/applied
        # tree -- grammar.csv, curriculum, can-do, quiz distractors -- is
        # self-consistent end to end, not just "didn't crash".
        issues = ContentValidator(self.root, ledger=relevel_ledger.load_ledger(self.ledger_path)).validate()
        self.assertEqual(issues, [], [f"{i.source}: {i.message}" for i in issues])


class GrammarNoDirectCanDoReferenceTest(GrammarRelevelBundleFixture):
    def test_move_without_can_do_reference_reports_candidates_and_still_succeeds(self) -> None:
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_delta", to="a2",
            courseUnitId=GRAMMAR_TARGET_UNIT_A2, conceptIds=[GRAMMAR_TARGET_CONCEPT_A2],
        )
        bundle = self._bundle([move])

        report = rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        grammar_report = report.grammar[0]
        self.assertIn("no direct can-do reference", grammar_report.can_do_note)
        self.assertIsNone(grammar_report.target_cluster_id)

        rows = self._read_grammar_rows()
        self.assertEqual(rows["grammar_a1_relvtest_delta"]["level"], "A2")
        # delta was never wired into can_do_content_authorities.json, so
        # applying its move must not have invented a reference for it.
        authorities = json.loads(
            (self.root / "assets" / "data" / rb.CAN_DO_AUTHORITIES_JSON).read_text(encoding="utf-8")
        )
        self.assertFalse(any(
            r.get("kind") == "grammar" and r.get("id") == "grammar_a1_relvtest_delta"
            for r in authorities["contentReferences"]
        ))


class GrammarRollbackTest(GrammarRelevelBundleFixture):
    def test_bad_concept_id_fails_and_leaves_everything_untouched(self) -> None:
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_beta", to="a2",
            courseUnitId=GRAMMAR_TARGET_UNIT_A2, conceptIds=["concept_does_not_exist"],
        )
        bundle = self._bundle([move])
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        self._assert_unchanged(snapshot)

    def test_dry_run_also_rejects_bad_concept_id(self) -> None:
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_beta", to="a2",
            courseUnitId=GRAMMAR_TARGET_UNIT_A2, conceptIds=["concept_does_not_exist"],
        )
        bundle = self._bundle([move])
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=False)

        self._assert_unchanged(snapshot)

    def test_already_at_target_level_fails_and_leaves_everything_untouched(self) -> None:
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_beta", to="a1",  # already a1 -- no-op move is rejected
            courseUnitId=GRAMMAR_SOURCE_UNIT, conceptIds=[GRAMMAR_SOURCE_CONCEPT],
        )
        bundle = self._bundle([move])
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        self._assert_unchanged(snapshot)

    def test_declared_from_disagreeing_with_live_row_fails(self) -> None:
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_beta", to="a2", **{"from": "b1"},  # live row is actually a1
            courseUnitId=GRAMMAR_TARGET_UNIT_A2, conceptIds=[GRAMMAR_TARGET_CONCEPT_A2],
        )
        bundle = self._bundle([move])
        snapshot = self._snapshot()

        with self.assertRaises(rb.RelevelError):
            rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=True)

        self._assert_unchanged(snapshot)


if __name__ == "__main__":
    unittest.main()
