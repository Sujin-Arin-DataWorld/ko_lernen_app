"""Releveling must not invent an unreviewed grammar answer set."""
from __future__ import annotations

import copy
from dataclasses import replace
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import relevel_bundle as rb
from test_relevel_bundle import (
    GrammarRelevelBundleFixture, _grammar_move_dict,
    GRAMMAR_TARGET_UNIT_A2, GRAMMAR_TARGET_CONCEPT_A2,
)


class GrammarQuizRepairContractTest(unittest.TestCase):
    def rows(self):
        rows = []
        for ident in ("target", "permission", "reason", "past", "future"):
            rows.append({
                "id": f"grammar_{ident}", "level": "A2", "type_en": "Permission",
                "quiz_enabled": "true",
                "quiz_distractor_ids": "",
            })
        # All unaffected rows have valid authored sets. Only the target has
        # a reference to a card that has moved to another level.
        for row in rows:
            row["quiz_distractor_ids"] = "|".join([r["id"] for r in rows if r is not row][:3])
        rows[0]["quiz_distractor_ids"] = "grammar_permission|grammar_reason|grammar_moved"
        rows.append({"id": "grammar_moved", "level": "B1", "type_en": "Permission",
                     "quiz_enabled": "false", "quiz_distractor_ids": ""})
        return rows

    def test_same_family_candidates_do_not_authorize_an_automatic_repair(self):
        rows = self.rows()
        before = copy.deepcopy(rows)
        report = rb.MigrationReport(batch="TEST")
        with self.assertRaisesRegex(rb.RelevelError, "grammarQuizRepairs.*grammar_target"):
            rb._repair_grammar_quiz_distractors(rows, report)
        self.assertEqual(before, rows)
        self.assertEqual([], report.distractor_repairs)

    def repair(self, **changes):
        raw = {"id": "grammar_target",
               "beforeIds": ["grammar_permission", "grammar_reason", "grammar_moved"],
               "afterIds": ["grammar_reason", "grammar_past", "grammar_future"],
               "reason": "Authored synthetic alternatives avoid the permission synonym."}
        raw.update(changes)
        return rb.GrammarQuizRepair.from_dict(raw)

    def test_exact_authored_repair_preserves_other_rows(self):
        rows = self.rows()
        before = copy.deepcopy(rows[1:])
        report = rb.MigrationReport(batch="TEST")
        rb._repair_grammar_quiz_distractors(rows, report, (self.repair(),))
        self.assertEqual("grammar_reason|grammar_past|grammar_future", rows[0]["quiz_distractor_ids"])
        self.assertEqual(before, rows[1:])
        self.assertEqual(["grammar_target"], [r.grammar_id for r in report.distractor_repairs])

    def test_stale_before_ids_and_invalid_candidates_leave_all_rows_unchanged(self):
        for change in (
            {"beforeIds": ["grammar_reason", "grammar_permission", "grammar_moved"]},
            {"afterIds": ["grammar_reason", "grammar_past", "grammar_unknown"]},
            {"afterIds": ["grammar_reason", "grammar_past", "grammar_moved"]},
        ):
            with self.subTest(change=change):
                rows = self.rows()
                before = copy.deepcopy(rows)
                report = rb.MigrationReport(batch="TEST")
                with self.assertRaises(rb.RelevelError):
                    rb._repair_grammar_quiz_distractors(rows, report, (self.repair(**change),))
                self.assertEqual(before, rows)
                self.assertEqual([], report.distractor_repairs)

    def test_disabled_same_level_candidate_is_rejected(self):
        rows = self.rows()
        rows[-1]["level"] = "A2"
        repair = self.repair(afterIds=["grammar_reason", "grammar_past", "grammar_moved"])
        with self.assertRaisesRegex(rb.RelevelError, "afterIds must be enabled"):
            rb._repair_grammar_quiz_distractors(rows, rb.MigrationReport(batch="TEST"), (repair,))

    def test_unused_repair_is_rejected_instead_of_rewriting_an_unaffected_question(self):
        rows = self.rows()
        extra = self.repair(id="grammar_permission")
        with self.assertRaisesRegex(rb.RelevelError, "unused=.*grammar_permission"):
            rb._repair_grammar_quiz_distractors(rows, rb.MigrationReport(batch="TEST"),
                                                (self.repair(), extra))

    def test_all_repairs_are_preflighted_before_the_first_write(self):
        rows = self.rows()
        rows[1]["quiz_distractor_ids"] = rows[0]["quiz_distractor_ids"]
        before = copy.deepcopy(rows)
        valid_first = self.repair(id="grammar_permission")
        invalid_last = self.repair(afterIds=["grammar_reason", "grammar_past", "grammar_unknown"])
        report = rb.MigrationReport(batch="TEST")
        with self.assertRaises(rb.RelevelError):
            rb._repair_grammar_quiz_distractors(rows, report, (valid_first, invalid_last))
        self.assertEqual(before, rows)
        self.assertEqual([], report.distractor_repairs)

    def test_parser_rejects_duplicate_self_missing_reason_and_wrong_shapes(self):
        for change in (
            {"afterIds": ["grammar_reason"] * 3},
            {"afterIds": ["grammar_target", "grammar_reason", "grammar_past"]},
            {"beforeIds": "grammar_reason"}, {"afterIds": None}, {"reason": " "},
        ):
            with self.subTest(change=change), self.assertRaises(rb.RelevelError):
                self.repair(**change)


class GrammarMissingReviewTransactionTest(GrammarRelevelBundleFixture):
    def test_missing_repair_blocks_dry_run_and_apply_without_file_changes(self):
        move = _grammar_move_dict(
            id="grammar_a1_relvtest_beta", to="a2",
            courseUnitId=GRAMMAR_TARGET_UNIT_A2, conceptIds=[GRAMMAR_TARGET_CONCEPT_A2],
        )
        bundle = replace(self._bundle([move]), grammar_quiz_repairs=())
        before = self._snapshot()
        for apply in (False, True):
            with self.subTest(apply=apply), self.assertRaisesRegex(rb.RelevelError, "grammarQuizRepairs"):
                rb.migrate(root=self.root, bundle=bundle, ledger_path=self.ledger_path, apply=apply)
            self._assert_unchanged(before)


if __name__ == "__main__":
    unittest.main()
