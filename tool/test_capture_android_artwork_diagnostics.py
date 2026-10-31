from io import BytesIO
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from tool.capture_android_artwork_diagnostics import capture


class ArtworkDiagnosticsTest(unittest.TestCase):
    def test_preserves_exact_aab_and_all_apk_dex_but_no_artwork_or_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            aab, apks, output = root / 'source.aab', root / 'measured.apks', root / 'evidence'
            baseline = b'AAB exact marker'
            variants = [b'APK24 exact marker', b'APK29 exact marker', b'APK32 exact marker']
            with zipfile.ZipFile(aab, 'w') as bundle:
                bundle.writestr('c_artwork/dex/classes.dex', baseline)
                bundle.writestr('c_artwork/manifest/AndroidManifest.xml', b'compiled manifest')
                bundle.writestr('base/dex/classes.dex', b'base code must not be captured')
                bundle.writestr('c_artwork/assets/flutter_assets/art.webp', b'original art')
            with zipfile.ZipFile(apks, 'w') as archive:
                archive.writestr('toc.pb', b'exact toc')
                archive.writestr('size-only.jks', b'must never be copied')
                for index, data in enumerate(variants):
                    nested = BytesIO()
                    with zipfile.ZipFile(nested, 'w') as apk:
                        apk.writestr('classes.dex', data)
                        apk.writestr('AndroidManifest.xml', b'APK manifest')
                        apk.writestr('assets/art.webp', b'art must not be copied')
                    archive.writestr(f'splits/c_artwork-master_{index}.apk', nested.getvalue())
            report = capture(aab, apks, output, 'a' * 40)
            dex_rows = [row for row in report['entries'] if row['entry'].endswith('.dex')]
            self.assertEqual(len(dex_rows), 4)
            self.assertEqual(len(report['artworkApkPaths']), 3)
            for row, expected in zip(dex_rows, [baseline, *variants]):
                self.assertEqual((output / row['evidence']).read_bytes(), expected)
                self.assertEqual(row['actualBytes'], len(expected))
                self.assertEqual(row['sha256'], hashlib.sha256(expected).hexdigest())
            self.assertEqual(report['sourceSha'], 'a' * 40)
            self.assertEqual((output / 'toc.pb').read_bytes(), b'exact toc')
            allowed = {row['evidence'] for row in report['entries']} | {'inventory.json'}
            self.assertEqual({path.name for path in output.iterdir()}, allowed)
            self.assertFalse(any('jks' in path.name or 'webp' in path.name for path in output.iterdir()))
            self.assertEqual(json.loads((output / 'inventory.json').read_text())['aabSha256'],
                             hashlib.sha256(aab.read_bytes()).hexdigest())

    def test_missing_measured_module_and_invalid_source_are_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with zipfile.ZipFile(root / 'app.aab', 'w'):
                pass
            with zipfile.ZipFile(root / 'size.apks', 'w') as archive:
                archive.writestr('toc.pb', b'toc')
            with self.assertRaisesRegex(ValueError, 'No measured artwork APKs'):
                capture(root / 'app.aab', root / 'size.apks', root / 'out')
            with self.assertRaisesRegex(ValueError, 'exact Git commit'):
                capture(root / 'app.aab', root / 'size.apks', root / 'out', 'main')


if __name__ == '__main__':
    unittest.main()
