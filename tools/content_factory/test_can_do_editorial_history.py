"""Exact source lineage and published descriptors preserve approved routes."""
import copy
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_can_do_segments as builder


class CanDoEditorialHistoryTest(unittest.TestCase):
    def test_copy_collisions_keep_published_vocabulary_lineage(self):
        source = builder.SourceIndex()
        expected = {
            "cloze_a1_0045": "vocab_a1_0068",
            "cloze_a1_0141": "vocab_a1_0253",
            "cloze_a1_0290": "vocab_a1_0402",
            "cloze_a1_0578": "vocab_a1_0644",
            "cloze_a1_0738": "vocab_a1_0804",
        }
        for ident, source_id in expected.items():
            with self.subTest(id=ident):
                row = source.cloze[ident]
                vocab = source.cloze_vocab_source(row, ident)
                self.assertIsNotNone(vocab)
                self.assertEqual(source_id, vocab["id"])
                changed = {**row, "answer": "An unrecorded answer"}
                with self.assertRaises(ValueError):
                    source.cloze_vocab_source(changed, ident)
                with self.assertRaises(ValueError):
                    source.cloze_vocab_source({**row, "en": "An unrecorded translation"}, ident)

    def test_rebuild_preserves_historical_approval_and_rejects_true_route_changes(self):
        approvals = copy.deepcopy(builder.SMALLTALK_REVIEW_APPROVALS)
        catalog, authorities = builder.build_assets()
        self.assertEqual(approvals, builder.SMALLTALK_REVIEW_APPROVALS)
        previous = builder._read_json(builder.AUTHORITY_PATH)
        old = {r["phraseId"]: r for r in previous["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]}
        new = {r["phraseId"]: r for r in authorities["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]}
        for ident in ("smalltalk_b2_0012", "smalltalk_b2_0047"):
            for field in ("canDoSegmentId", "semanticStatus", "reasonCode", "routingSource", "reviewRevision"):
                self.assertEqual(old[ident][field], new[ident][field])
        with tempfile.TemporaryDirectory() as directory:
            catalog_path = Path(directory) / "catalog.json"
            authority_path = Path(directory) / "authorities.json"
            catalog_path.write_bytes(builder._json_bytes(catalog))
            authority_path.write_bytes(builder._json_bytes(authorities))
            read_json = builder._read_json
            def read_published(path):
                if path == builder.DATA / "can_do_segments.json":
                    return read_json(catalog_path)
                if path == builder.DATA / "can_do_content_authorities.json":
                    return read_json(authority_path)
                return read_json(path)
            with patch.object(builder, "CATALOG_PATH", catalog_path), patch.object(
                builder, "AUTHORITY_PATH", authority_path
            ), patch.object(builder, "_read_json", side_effect=read_published
            ):
                self.assertEqual((catalog, authorities), builder.build_assets())
        case = copy.deepcopy(new["smalltalk_b2_0012"])
        case["semanticStatus"] = "exactMapped"
        wrap = lambda row: {"coverage": {"smalltalkRoutingAudit": {"phraseDecisions": [row]}}}
        with self.assertRaisesRegex(ValueError, "changed its semantic route"):
            builder._validate_smalltalk_review_history(
                wrap(case), wrap(old[case["phraseId"]]),
                review_approvals={case["phraseId"]: approvals[case["phraseId"]]},
            )


if __name__ == "__main__":
    unittest.main()
