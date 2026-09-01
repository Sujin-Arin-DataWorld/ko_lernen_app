from __future__ import annotations

from pathlib import Path
import json
import sys
import tempfile
import unittest


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_theme_park_date_tts_manifest as tts_builder
from promote_theme_park_date import (
    PromotionError,
    _canonical_json_sha256,
    _merge_rows,
    _verify_tts_ready,
    promote,
)


ROOT = SCRIPT_DIR.parents[1]


class ThemeParkDatePromotionTest(unittest.TestCase):
    def test_apply_replaces_a_revised_reviewed_row_in_place(self) -> None:
        existing = [{"id": "before"}, {"id": "theme", "copy": "old"}]
        incoming = [{"id": "theme", "copy": "reviewed"}]

        self.assertEqual(
            _merge_rows(existing, incoming, label="smalltalk", check=False),
            [{"id": "before"}, {"id": "theme", "copy": "reviewed"}],
        )

    def test_check_rejects_drift_from_the_reviewed_row(self) -> None:
        with self.assertRaisesRegex(PromotionError, "differs from the reviewed draft"):
            _merge_rows(
                [{"id": "theme", "copy": "old"}],
                [{"id": "theme", "copy": "reviewed"}],
                label="scenario",
                check=True,
            )

    def test_runtime_write_requires_exact_tts_receipt_and_jin(self) -> None:
        manifest = tts_builder.build_manifest(ROOT)
        receipt = {
            "schemaVersion": 1,
            "kind": "scenario_tts_storage_verification",
            "generationId": "theme_park_date_v1",
            "scope": "corpus",
            "candidateSetSha256": manifest["candidateSetSha256"],
            "ttsManifestSha256": _canonical_json_sha256(manifest),
            "expectedCount": manifest["count"],
            "verifiedCachePathCount": manifest["count"],
            "missingCount": 0,
            "cacheRevision": "v3",
            "verificationMode": "firebase_storage_nonempty_mp3_listing",
            "minimumObjectBytes": 256,
            "bucket": "ko-lernen-app.firebasestorage.app",
        }
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "receipt.json"
            path.write_text(json.dumps(receipt), encoding="utf-8")
            accepted = _verify_tts_ready(
                ROOT,
                receipt_path=path,
                runtime_write_reviewer="Jin",
            )
            self.assertEqual(accepted["missingCount"], 0)
            with self.assertRaisesRegex(PromotionError, "reviewer Jin"):
                _verify_tts_ready(
                    ROOT,
                    receipt_path=path,
                    runtime_write_reviewer=None,
                )
            receipt["missingCount"] = 1
            path.write_text(json.dumps(receipt), encoding="utf-8")
            with self.assertRaisesRegex(PromotionError, "missingCount must be 0"):
                promote(
                    ROOT,
                    check=True,
                    tts_ready_receipt=path,
                    runtime_write_reviewer="Jin",
                )


if __name__ == "__main__":
    unittest.main()
