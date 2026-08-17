from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from derive_hanok_a1_thumbnails import ThumbnailError, derive_thumbnail
from hanok_v1_asset_contract import ROOT, a1_expected_files, load_provenance, sha256_file
from promote_hanok_a1_states import (
    PromotionError,
    _validate_state,
    collect_approved_states,
    promote_states,
)


def _write_qa_states(qa: Path, color: tuple[int, int, int] = (12, 24, 36)) -> None:
    qa.mkdir(parents=True, exist_ok=True)
    for name in a1_expected_files():
        Image.new("RGB", (1536, 1152), color).save(
            qa / name,
            "WEBP",
            quality=80,
            method=6,
        )


def _ledger_for(qa: Path) -> dict:
    payload = json.loads(json.dumps(load_provenance()))
    payload["generationLedger"]["records"] = [
        {
            "outputAssets": [
                {
                    "path": f"assets_unused/pending_review/a1_states/{name}",
                    "sha256": sha256_file(qa / name),
                    "decision": "approved",
                }
                for name in a1_expected_files()
            ]
        }
    ]
    return payload


class PromoteAndThumbnailTest(unittest.TestCase):
    def test_promotion_stays_fail_closed_until_all_sixteen_exist(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            Image.new("RGB", (1536, 1152), (10, 10, 10)).save(
                root / "06_columns.webp",
                "WEBP",
                quality=82,
            )
            with self.assertRaises(PromotionError):
                collect_approved_states(qa_root=root)

    def test_promotion_rejects_empty_generation_ledger(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            runtime = Path(temp_dir) / "runtime"
            _write_qa_states(qa)
            with self.assertRaises(PromotionError):
                promote_states(qa_root=qa, runtime_root=runtime, dry_run=True)
            with self.assertRaises(PromotionError):
                promote_states(qa_root=qa, runtime_root=runtime, dry_run=False)
            self.assertFalse(runtime.exists())

    def test_promotion_refuses_when_the_contract_disables_the_ledger_gate(self) -> None:
        """The contract declares requireApprovedLedgerSha256; nothing used to read it."""
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            runtime = Path(temp_dir) / "runtime"
            _write_qa_states(qa)
            provenance = json.loads(json.dumps(_ledger_for(qa)))
            provenance["a1TransparentLayerContract"]["promotion"][
                "requireApprovedLedgerSha256"
            ] = False
            with self.assertRaises(PromotionError) as caught:
                promote_states(
                    qa_root=qa,
                    runtime_root=runtime,
                    dry_run=False,
                    provenance=provenance,
                )
            self.assertIn("requireApprovedLedgerSha256", str(caught.exception))
            self.assertFalse(runtime.exists())

    def test_promotion_refuses_a_forbidden_in_repo_runtime_root(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            _write_qa_states(qa)
            provenance = _ledger_for(qa)
            forbidden = ROOT / "assets" / "illustrations" / "gye" / "a1"
            with self.assertRaises(PromotionError) as caught:
                promote_states(
                    qa_root=qa,
                    runtime_root=forbidden,
                    dry_run=True,
                    provenance=provenance,
                )
            self.assertIn("forbidden runtime path", str(caught.exception))
            self.assertFalse(forbidden.exists())

    def test_promotion_copies_only_a_complete_valid_set(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            runtime = Path(temp_dir) / "runtime"
            _write_qa_states(qa)
            provenance = _ledger_for(qa)
            names = promote_states(
                qa_root=qa,
                runtime_root=runtime,
                dry_run=True,
                provenance=provenance,
            )
            self.assertEqual(names, a1_expected_files())
            self.assertFalse(runtime.exists())
            copied = promote_states(
                qa_root=qa,
                runtime_root=runtime,
                dry_run=False,
                provenance=provenance,
            )
            self.assertEqual(len(copied), 16)
            self.assertTrue((runtime / "16_landscape_move_in.webp").is_file())

    def test_promotion_rejects_sha_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            _write_qa_states(qa)
            provenance = _ledger_for(qa)
            provenance["generationLedger"]["records"][0]["outputAssets"][0][
                "sha256"
            ] = "0" * 64
            with self.assertRaises(PromotionError):
                promote_states(
                    qa_root=qa,
                    runtime_root=Path(temp_dir) / "runtime",
                    dry_run=True,
                    provenance=provenance,
                )

    def test_promotion_rejects_rgba_or_chroma_webp(self) -> None:
        geometry = {"canvas_width": 1536, "canvas_height": 1152}
        with tempfile.TemporaryDirectory() as temp_dir:
            chroma = Path(temp_dir) / "chroma.webp"
            Image.new("RGB", (1536, 1152), (0, 255, 0)).save(
                chroma,
                "WEBP",
                lossless=True,
            )
            with self.assertRaises(PromotionError):
                _validate_state(chroma, geometry, 350000)

            lossy = Path(temp_dir) / "lossy_chroma.webp"
            Image.new("RGB", (256, 256), (0, 255, 0)).save(
                lossy,
                "WEBP",
                quality=82,
                method=6,
            )
            decoded = Image.open(lossy).convert("RGB")
            from hanok_v1_asset_contract import chroma_key_count

            self.assertGreater(chroma_key_count(decoded), 0)

            rgba = Path(temp_dir) / "rgba.webp"
            layer = Image.new("RGBA", (1536, 1152), (12, 24, 36, 255))
            layer.putpixel((0, 0), (12, 24, 36, 0))
            layer.save(rgba, "WEBP", lossless=True)
            with self.assertRaises(PromotionError):
                _validate_state(rgba, geometry, 350000)

    def test_promotion_rejects_runtime_leftovers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            qa = Path(temp_dir) / "qa"
            runtime = Path(temp_dir) / "runtime"
            runtime.mkdir()
            (runtime / "extra.webp").write_bytes(b"nope")
            _write_qa_states(qa)
            with self.assertRaises(PromotionError):
                promote_states(
                    qa_root=qa,
                    runtime_root=runtime,
                    dry_run=True,
                    provenance=_ledger_for(qa),
                )

    def test_thumbnail_hash_gate_rejects_a_changed_source(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            source = Path(temp_dir) / "state.webp"
            output = Path(temp_dir) / "thumb.webp"
            Image.new("RGB", (1536, 1152), (40, 30, 20)).save(source, "WEBP")
            actual = sha256_file(source)
            derive_thumbnail(source, output, expected_source_sha256=actual)
            self.assertTrue(output.is_file())
            with self.assertRaises(ThumbnailError):
                derive_thumbnail(
                    source,
                    output,
                    expected_source_sha256="0" * 64,
                )


if __name__ == "__main__":
    unittest.main()
