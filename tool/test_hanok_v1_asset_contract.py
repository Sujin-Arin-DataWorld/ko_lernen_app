from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from hanok_v1_asset_contract import (
    a1_approved_state_digests,
    a1_expected_files,
    chroma_key_count,
    is_chroma_key_rgb,
    load_provenance,
)


class HanokV1AssetContractTest(unittest.TestCase):
    def test_lossy_q82_green_is_chroma_and_dancheong_is_not(self) -> None:
        self.assertTrue(is_chroma_key_rgb(0, 255, 0))
        self.assertTrue(is_chroma_key_rgb(0, 255, 1))
        self.assertTrue(is_chroma_key_rgb(2, 255, 1))
        self.assertFalse(is_chroma_key_rgb(0x1F, 0x7A, 0x6B))

        with tempfile.TemporaryDirectory() as temp_dir:
            lossy = Path(temp_dir) / "green_q82.webp"
            Image.new("RGB", (256, 256), (0, 255, 0)).save(
                lossy,
                "WEBP",
                quality=82,
                method=6,
            )
            decoded = Image.open(lossy).convert("RGB")
            self.assertGreater(chroma_key_count(decoded), 0)
            self.assertGreater(chroma_key_count(decoded.convert("RGBA")), 0)

        dancheong = Image.new("RGBA", (32, 32), (0x1F, 0x7A, 0x6B, 255))
        self.assertEqual(chroma_key_count(dancheong), 0)
        ghost = Image.new("RGBA", (8, 8), (0, 255, 0, 8))
        self.assertEqual(chroma_key_count(ghost), 0)

    def test_empty_repo_ledger_has_no_approved_a1_digests(self) -> None:
        payload = load_provenance()
        self.assertEqual(payload["generationLedger"]["records"], [])
        self.assertEqual(a1_approved_state_digests(payload), {})
        self.assertEqual(len(a1_expected_files(payload)), 16)

    def test_approved_state_digests_key_by_basename(self) -> None:
        payload = json.loads(json.dumps(load_provenance()))
        expected = a1_expected_files(payload)
        payload["generationLedger"]["records"] = [
            {
                "outputAssets": [
                    {
                        "path": f"assets_unused/pending_review/a1_states/{expected[0]}",
                        "sha256": "a" * 64,
                        "decision": "approved",
                    },
                    {
                        "path": "assets_unused/pending_review/other.png",
                        "sha256": "b" * 64,
                        "decision": "approved",
                    },
                ]
            }
        ]
        self.assertEqual(
            a1_approved_state_digests(payload),
            {expected[0]: "a" * 64},
        )

    def test_conflicting_approved_a1_digests_fail_closed(self) -> None:
        payload = json.loads(json.dumps(load_provenance()))
        name = a1_expected_files(payload)[0]
        payload["generationLedger"]["records"] = [
            {
                "outputAssets": [
                    {
                        "path": f"assets_unused/pending_review/a1_states/{name}",
                        "sha256": "a" * 64,
                        "decision": "approved",
                    },
                    {
                        "path": f"assets_unused/pending_review/a1_states/{name}",
                        "sha256": "b" * 64,
                        "decision": "approved",
                    },
                ]
            }
        ]
        with self.assertRaises(ValueError):
            a1_approved_state_digests(payload)


if __name__ == "__main__":
    unittest.main()
