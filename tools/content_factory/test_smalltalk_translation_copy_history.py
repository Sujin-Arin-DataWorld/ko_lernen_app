"""Copy corrections retain historical routing approval without approving new copy."""

import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_can_do_segments as builder


class SmalltalkTranslationCopyHistoryTest(unittest.TestCase):
    def test_all_eight_corrections_match_live_copy_without_changing_korean(self):
        ledger = builder._read_json(builder.SMALLTALK_TRANSLATION_LEDGER_PATH)
        rows = {
            row["id"]: row
            for row in builder._read_json(builder.DATA / "smalltalk.json")["phrases"]
        }
        self.assertEqual(8, len(ledger["changes"]))
        self.assertEqual(5, len({change["id"] for change in ledger["changes"]}))
        for change in ledger["changes"]:
            with self.subTest(change=change["id"], field=change["field"]):
                self.assertIn(change["field"], {"de", "en"})
                self.assertEqual(change["level"], rows[change["id"]]["level"])
                self.assertEqual(change["after"], rows[change["id"]][change["field"]])
                self.assertNotEqual(change["before"], change["after"])
                self.assertEqual(
                    "nativeReviewRequired",
                    builder._copy_revision_metadata(rows[change["id"]])["copyReviewStatus"],
                )

    def _case(self):
        row = next(
            row for row in builder._read_json(builder.DATA / "smalltalk.json")["phrases"]
            if row["id"] == "smalltalk_a1_0003"
        )
        before = {**row, "de": "Mir geht's heute gut."}
        approval = builder.SMALLTALK_REVIEW_APPROVALS[row["id"]]
        self.assertEqual(builder._json_fingerprint(before), approval["phraseFingerprintSha256"])
        old = {
            **approval,
            "phraseId": row["id"],
            "routingSource": "courseUnitFallback",
            "reasonCode": "topicAndFunctionMatch",
        }
        new = {
            **old,
            "phraseFingerprintSha256": builder._json_fingerprint(row),
            **builder._copy_revision_metadata(row),
        }
        wrap = lambda decision: {
            "coverage": {"smalltalkRoutingAudit": {"phraseDecisions": [decision]}}
        }
        return old, new, wrap(old), wrap(new)

    def test_translation_revision_preserves_approval_and_regenerates_exactly(self):
        old, new, previous, current = self._case()
        approvals = {old["phraseId"]: builder.SMALLTALK_REVIEW_APPROVALS[old["phraseId"]]}
        original_approvals = copy.deepcopy(approvals)
        builder._validate_smalltalk_review_history(current, previous, review_approvals=approvals)
        self.assertEqual(original_approvals, approvals)
        self.assertEqual(old["reviewRevision"], new["reviewRevision"])
        self.assertEqual("approved", new["semanticStatus"])
        self.assertEqual("nativeReviewRequired", new["copyReviewStatus"])
        self.assertEqual(old["phraseFingerprintSha256"], new["previousPhraseFingerprintSha256"])
        _, generated = builder.build_assets()
        self.assertEqual(
            builder._read_json(builder.AUTHORITY_PATH), generated,
            "Run the builder to refresh derived authorities after a copy correction.",
        )
        self.assertEqual(new, next(
            row for row in generated["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]
            if row["phraseId"] == old["phraseId"]
        ))

    def test_copy_gate_rejects_changed_route_lineage_or_forged_copy_approval(self):
        mutations = {
            "canDoSegmentId": "segment_a1_other",
            "semanticStatus": "exactMapped",
            "previousPhraseFingerprintSha256": "0" * 64,
            "copyReviewStatus": "approved",
            "copyRevisionLedger": "unregistered.json",
        }
        for field, value in mutations.items():
            with self.subTest(field=field):
                old, new, previous, current = self._case()
                new[field] = value
                with self.assertRaises(ValueError):
                    builder._validate_smalltalk_review_history(
                        current, previous, review_approvals={
                            old["phraseId"]: builder.SMALLTALK_REVIEW_APPROVALS[old["phraseId"]],
                        },
                    )

    def test_unrecorded_translation_change_is_rejected(self):
        row = next(
            row for row in builder._read_json(builder.DATA / "smalltalk.json")["phrases"]
            if row["id"] == "smalltalk_a1_0003"
        )
        row["de"] = "Unrecorded replacement"
        with self.assertRaisesRegex(ValueError, "does not match"):
            builder._copy_revision_metadata(row)
