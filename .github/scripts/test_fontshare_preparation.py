"""Font preparation contract tests use synthetic bytes, never vendor payloads."""

from contextlib import redirect_stderr
import copy
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))
import prepare_fontshare_fonts as fonts


class FontsharePreparationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.manifest = copy.deepcopy(json.loads((ROOT / fonts.MANIFEST).read_text(encoding="utf-8")))
        self.payloads = {asset: f"synthetic fixture: {asset}".encode() for asset in fonts.FILES}
        for record in self.manifest["fonts"] + self.manifest["licenses"]:
            if record["asset"] in self.payloads:
                record["sha256"] = hashlib.sha256(self.payloads[record["asset"]]).hexdigest()
        self.write_manifest()

    def write_manifest(self):
        path = self.root / fonts.MANIFEST
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self.manifest), encoding="utf-8")

    def archive(self, family, *, changed_asset=None):
        output = io.BytesIO()
        with zipfile.ZipFile(output, "w") as archive:
            for asset, (owner, member) in fonts.FILES.items():
                if owner == family:
                    payload = self.payloads[asset]
                    if changed_asset == asset:
                        payload += b"unapproved vendor update"
                    archive.writestr(member, payload)
        return output.getvalue()

    def seed_local_files(self):
        for asset, data in self.payloads.items():
            path = self.root / asset
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)

    def test_official_fetch_then_offline_idempotence_preserves_bytes_and_mtime(self):
        archives = {url: self.archive(family) for family, url in fonts.SOURCES.items()}
        with patch.object(fonts, "download", side_effect=archives.__getitem__) as download:
            self.assertEqual(fonts.prepare(self.root), 6)
            self.assertEqual({call.args[0] for call in download.call_args_list}, set(fonts.SOURCES.values()))
            self.assertEqual(download.call_count, 2)
        times = {asset: (self.root / asset).stat().st_mtime_ns for asset in fonts.FILES}
        with patch.object(fonts, "download", side_effect=AssertionError("Unexpected network")) as download:
            self.assertEqual(fonts.prepare(self.root), 0)
            self.assertEqual(fonts.prepare(self.root, check_only=True), 0)
            download.assert_not_called()
        for asset, data in self.payloads.items():
            self.assertEqual((self.root / asset).read_bytes(), data)
            self.assertEqual((self.root / asset).stat().st_mtime_ns, times[asset])

    def test_local_hash_change_fails_without_network_or_overwrite(self):
        self.seed_local_files()
        path = self.root / "assets/fonts/Chubbo/Chubbo-Bold.otf"
        path.write_bytes(b"different local font")
        with patch.object(fonts, "download") as download:
            with self.assertRaisesRegex(fonts.PreparationError, "SHA-256 mismatch"):
                fonts.prepare(self.root)
            download.assert_not_called()
        self.assertEqual(path.read_bytes(), b"different local font")

    def test_vendor_hash_change_fails_before_installing_any_file(self):
        archives = {
            fonts.SOURCES["Chubbo"]: self.archive("Chubbo"),
            fonts.SOURCES["Supreme"]: self.archive(
                "Supreme", changed_asset="assets/fonts/Supreme/Supreme-Regular.otf"
            ),
        }
        with patch.object(fonts, "download", side_effect=archives.__getitem__):
            with self.assertRaisesRegex(fonts.PreparationError, "SHA-256 mismatch"):
                fonts.prepare(self.root)
        self.assertTrue(all(not (self.root / asset).exists() for asset in fonts.FILES))

    def test_check_only_missing_inputs_returns_failure_without_network(self):
        with patch.object(fonts, "ROOT", self.root), patch.object(fonts, "download") as download:
            with redirect_stderr(io.StringIO()) as error:
                self.assertEqual(fonts.main(["--check"]), 1)
            self.assertIn("Missing Fontshare inputs", error.getvalue())
            download.assert_not_called()

    def test_source_map_cannot_redirect_download_to_another_vendor(self):
        self.manifest["fonts"][0]["source"] = "https://example.invalid/font.zip"
        self.write_manifest()
        with patch.object(fonts, "download") as download:
            with self.assertRaisesRegex(fonts.PreparationError, "Non-vendor source"):
                fonts.prepare(self.root)
            download.assert_not_called()

    def test_committed_source_map_has_exactly_the_six_reviewed_inputs(self):
        self.assertEqual(set(fonts.locked_assets(ROOT)), set(fonts.FILES))
        ignored = (ROOT / ".gitignore").read_text(encoding="utf-8").splitlines()
        self.assertTrue(all("/" + asset in ignored for asset in fonts.FILES))
        self.assertNotIn("/assets/fonts/", ignored)
        self.assertNotIn("/assets/fonts/Belgrano/", ignored)
        self.assertNotIn("/assets/fonts/EncodeSansCondensed/", ignored)


if __name__ == "__main__":
    unittest.main()
