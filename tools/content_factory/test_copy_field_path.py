import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_can_do_segments as builder
from copy_field_path import text_field


class CopyFieldPathTest(unittest.TestCase):
    def test_indexed_question_targets_one_existing_text_leaf(self):
        row = {"id": "demo", "questions": [{"de": "eins"}, {"de": "zwei"}]}
        parent, key = text_field(row, "questions.1.de")
        parent[key] = "changed"
        self.assertEqual(["eins", "changed"], [r["de"] for r in row["questions"]])

    def test_invalid_paths_never_create_or_select_an_unintended_field(self):
        row = {"id": "demo", "questions": [{"de": "eins"}], "reply": {"de": "ja"}}
        before = copy.deepcopy(row)
        for path in ("", "questions", "questions.-1.de", "questions.01.de",
                     "questions.1.de", "questions.x.de", "questions.0.en",
                     "questions..de", "reply.de.extra"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                text_field(row, path)
        self.assertEqual(before, row)

    def test_array_copy_revision_reconstructs_exact_previous_phrase(self):
        before = {"id": "demo", "safeAlternativeQuestions": [{"ko": "같이 말해 볼래요?", "de": "alt"}]}
        after = copy.deepcopy(before)
        after["safeAlternativeQuestions"][0]["de"] = "neu"
        changes = [{"field": "safeAlternativeQuestions.0.de", "before": "alt", "after": "neu"}]
        with patch.object(builder, "_humanization_changes_by_id", return_value={"demo": changes}):
            revision = builder._copy_revision_metadata(after)
            self.assertEqual(builder._json_fingerprint(before), revision["previousPhraseFingerprintSha256"])
            self.assertEqual("nativeReviewRequired", revision["copyReviewStatus"])
            after["safeAlternativeQuestions"][0]["de"] = "unreviewed"
            with self.assertRaisesRegex(ValueError, "does not match"):
                builder._copy_revision_metadata(after)
