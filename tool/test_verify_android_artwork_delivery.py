import hashlib
from io import BytesIO
import unittest
import zipfile

from copy import deepcopy

from tool.verify_android_artwork_delivery import (
    artwork_apk_minimum, check_delivery, check_payloads, check_size,
)
from tool.android_artwork_manifest import Artwork


GOOD_MANIFEST = '''<manifest split="c_artwork"
 xmlns:android="http://schemas.android.com/apk/res/android"
 xmlns:dist="http://schemas.android.com/apk/distribution">
 <dist:module><dist:delivery><dist:install-time><dist:removable dist:value="true"/></dist:install-time></dist:delivery>
 <dist:fusing dist:include="true"/></dist:module>
 <application android:hasCode="false"/></manifest>'''


class ArtworkDeliveryTest(unittest.TestCase):
    def test_requires_install_time_separate_split_and_universal_inclusion(self):
        check_delivery(GOOD_MANIFEST)
        for bad in [
            GOOD_MANIFEST.replace('dist:removable dist:value="true"', 'dist:removable dist:value="false"'),
            GOOD_MANIFEST.replace('dist:include="true"', 'dist:include="false"'),
            GOOD_MANIFEST.replace('<dist:install-time><dist:removable dist:value="true"/></dist:install-time>', '<dist:on-demand/>'),
            GOOD_MANIFEST.replace('</dist:install-time>', '<dist:conditions/></dist:install-time>'),
        ]:
            with self.assertRaises(ValueError):
                check_delivery(bad)

    def test_rejects_missing_duplicate_or_changed_artwork(self):
        path = 'assets/illustrations/ildu_r16/original.webp'
        original = b'exact approved image'
        expected = {path: Artwork(hashlib.sha256(original).hexdigest(), len(original), 'test')}
        for extra, content, included in [
            (False, original, True), (True, original, True),
            (False, b'changed', True), (False, original, False),
        ]:
            data = BytesIO()
            with zipfile.ZipFile(data, 'w') as bundle:
                bundle.writestr('base/assets/flutter_assets/AssetManifest.bin', b'index')
                if included:
                    bundle.writestr('c_artwork/assets/flutter_assets/' + path, content)
                if extra:
                    bundle.writestr('base/assets/flutter_assets/' + path, original)
            data.seek(0)
            if not extra and content == original and included:
                self.assertEqual(check_payloads(data, expected), len(original))
            else:
                with self.assertRaises(ValueError):
                    check_payloads(data, expected)

    def test_rejects_absent_size_evidence_and_over_limit_abi(self):
        self.assertEqual(check_size('ABI,MIN,MAX\narm64-v8a,480000000,481000000'), 481000000)
        self.assertEqual(check_size('ABI,MIN,MAX\nx86_64,540000000,542000000', 56000000), 486000000)
        for bad in ['', 'ABI,MIN,MAX\nx86_64,480000000,490000001', 'ABI,MIN,MAX\nx86_64,0,0']:
            with self.assertRaises(ValueError):
                check_size(bad)
        with self.assertRaises(ValueError):
            check_size('ABI,MIN,MAX\nx86_64,540000000,547000000', 56000000)

    def test_module_size_evidence_cannot_be_reused_or_overstated(self):
        good = {
            'aabSha256': 'aab', 'apksSha256': 'apks', 'artworkManifestSha256': 'manifest', 'module': 'c_artwork',
            'assetCount': 135, 'baseMinSdk': 24, 'artworkMinSdk': 24,
            'noPackagedApplicationCode': True,
            'variantCount': 2, 'variants': [{'master': 'one'}, {'master': 'two'}],
            'masters': [
                {'path': 'one', 'assetCount': 135, 'vendorDownloadBytes': 50, 'rawApkBytes': 60, 'codeEntries': ['classes.dex']},
                {'path': 'two', 'assetCount': 135, 'vendorDownloadBytes': 52, 'rawApkBytes': 62, 'codeEntries': []},
            ], 'moduleLowerBoundBytes': 50,
        }
        self.assertEqual(artwork_apk_minimum(good, 'aab', 'apks', 135, 'manifest'), 50)
        for entries in (None, ['classes.dex', 'classes.dex'], ['classes2.dex'], ['lib/native.so']):
            bad = deepcopy(good)
            bad['masters'][0]['codeEntries'] = entries
            with self.subTest(codeEntries=entries), self.assertRaises(ValueError):
                artwork_apk_minimum(bad, 'aab', 'apks', 135, 'manifest')
        for field, value in [('aabSha256', 'other'), ('apksSha256', 'other'),
                             ('moduleLowerBoundBytes', 52), ('variantCount', 1),
                             ('variants', []), ('assetCount', 134),
                             ('noPackagedApplicationCode', False), ('artworkManifestSha256', 'stale')]:
            bad = deepcopy(good)
            bad[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                artwork_apk_minimum(bad, 'aab', 'apks', 135, 'manifest')

    def test_exact_union_rejects_unregistered_payloads_and_every_module_duplicate(self):
        payloads = {
            'assets/illustrations/ildu_r16/one.webp': b'r16',
            'assets/illustrations/concept_c/c5_scenes/two.png': b'c5',
            'assets/illustrations/future-reviewed/three.png': b'future',
        }
        expected = {key: Artwork(hashlib.sha256(value).hexdigest(), len(value), 'test')
                    for key, value in payloads.items()}
        prefix = 'c_artwork/assets/flutter_assets/'
        scenarios = [None, ('base/assets/flutter_assets/' + list(payloads)[1], b'c5'),
                     ('other/assets/flutter_assets/' + list(payloads)[1], b'c5'),
                     (prefix + 'unregistered.txt', b'extra'),
                     (prefix + list(payloads)[1], b'c5')]
        import warnings
        for extra in scenarios:
            data = BytesIO()
            with warnings.catch_warnings():
                warnings.simplefilter('ignore', UserWarning)  # Deliberate duplicate ZIP fixture.
                with zipfile.ZipFile(data, 'w') as bundle:
                    bundle.writestr('base/assets/flutter_assets/AssetManifest.bin', b'index')
                    bundle.writestr(prefix + 'directory/', b'')
                    for key, value in payloads.items():
                        bundle.writestr(prefix + key, value)
                    if extra:
                        bundle.writestr(*extra)
            data.seek(0)
            with self.subTest(extra=extra):
                if extra:
                    with self.assertRaises(ValueError):
                        check_payloads(data, expected)
                else:
                    self.assertEqual(check_payloads(data, expected), sum(map(len, payloads.values())))
                    good_payload = data.getvalue()
        wrong_size = dict(expected)
        key = list(payloads)[1]
        wrong_size[key] = Artwork(expected[key].sha256, 100, 'test')
        with self.assertRaises(ValueError):
            check_payloads(BytesIO(good_payload), wrong_size)


if __name__ == '__main__':
    unittest.main()
