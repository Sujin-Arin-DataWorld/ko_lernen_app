"""A manifest must not turn failed visual evidence into a pass."""
import copy
import unittest

from tool.build_vocab_pack_card_manifest import _validate_review


class ManifestVisualReviewTests(unittest.TestCase):
    def setUp(self):
        self.review = {
            "id": "example", "status": "bundled", "asset": "example.webp",
            "sha256": "reviewed-sha", "qa": {key: "pass" for key in (
                "fullSize", "crop16x10", "thumbnail100px", "textFree",
                "materials", "nativeTexture", "familyShell",
            )},
        }

    def test_matching_complete_review_is_accepted(self):
        _validate_review(self.review, "example.webp", "reviewed-sha")

    def test_failed_or_missing_visual_evidence_cannot_be_published_as_pass(self):
        for key in ("crop16x10", "thumbnail100px"):
            for state in ("fail", None):
                with self.subTest(key=key, state=state):
                    review = copy.deepcopy(self.review)
                    review["qa"][key] = state
                    with self.assertRaisesRegex(ValueError, "Incomplete visual review"):
                        _validate_review(review, "example.webp", "reviewed-sha")

    def test_replaced_asset_invalidates_manifest_review(self):
        with self.assertRaisesRegex(ValueError, "Stale visual review"):
            _validate_review(self.review, "example.webp", "new-sha")


if __name__ == "__main__":
    unittest.main()
