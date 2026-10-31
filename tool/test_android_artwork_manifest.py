"""Exact reviewed authorities, deterministic lock, and delivery task contracts."""

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from tool.android_artwork_manifest import (
    FAMILIES, MANIFEST, ROOT, Family, check_manifest, parse_manifest,
    render_manifest, resolve_sources, safe_path, source_records,
)


class ArtworkManifestTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.families = (Family('first', 'docs/first.json', 'assets/first/', 1),
                         Family('second', 'docs/second.json', 'assets/second/', 1))
        self.records = []
        for family, suffix, content in zip(self.families, ['a.webp', 'b.png'], [b'webp', b'png']):
            key = family.root + suffix
            file = self.root / key
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(content)
            record = {'asset': key, 'sha256': hashlib.sha256(content).hexdigest(),
                      'bytes': len(content), 'source': 'C:\\provenance-only\\original.png'}
            self.records.append(record)
            authority = self.root / family.authority
            authority.parent.mkdir(parents=True, exist_ok=True)
            authority.write_text(json.dumps({'assets': [record, record]}), encoding='utf-8')

    def render(self):
        return render_manifest(*resolve_sources(self.root, self.families))

    def test_mixed_originals_collapse_repeat_references_and_ignore_provenance(self):
        text = self.render()
        rows = parse_manifest(text)
        self.assertEqual(set(rows), {row['asset'] for row in self.records})
        lock = self.root / 'lock.tsv'
        lock.write_text(text, encoding='utf-8')
        self.assertEqual(check_manifest(lock, self.root, self.families), rows)
        # Changing authority bytes without changing assets still invalidates the lock.
        authority = self.root / self.families[0].authority
        authority.write_text(authority.read_text() + '\n', encoding='utf-8')
        with self.assertRaises(ValueError):
            check_manifest(lock, self.root, self.families)

    def test_conflicting_identity_and_wrong_family_cannot_be_promoted(self):
        for change in ({'sha256': '0' * 64}, {'bytes': 99}, {'asset': 'assets/unreviewed/new.png'}):
            bad = deepcopy(self.records[0])
            bad.update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                source_records([self.records[0], bad], self.families[0])
        with self.assertRaises(ValueError):
            source_records([], self.families[0])

    def test_authority_binding_survives_git_json_lf_normalization(self):
        authority = self.root / self.families[0].authority
        value = json.loads(authority.read_text(encoding='utf-8'))
        lf = (json.dumps(value, indent=2) + '\n').encode('utf-8')
        authority.write_bytes(lf)
        lock = self.root / 'lock.tsv'
        lock.write_bytes(self.render().encode('utf-8'))
        authority.write_bytes(lf.replace(b'\n', b'\r\n'))
        self.assertEqual(len(check_manifest(lock, self.root, self.families)), 2)

    def test_no_arbitrary_unsafe_relative_paths(self):
        for value in ['/absolute', 'C:/drive', '../up', 'assets/../up', 'assets/./a',
                      'assets//a', 'assets\\a', 'assets/a\tbad', 'assets/a\nbad',
                      'assets/*.png', 'assets/?.png', 'assets/[ab].png', '']:
            with self.subTest(path=value), self.assertRaises(ValueError):
                safe_path(value)
        for replacement in ['bad-sha', '0' * 63, 'A' * 64]:
            bad = dict(self.records[0], sha256=replacement)
            with self.assertRaises(ValueError):
                source_records(bad, self.families[0])
        for replacement in [0, -1, True, '4']:
            with self.assertRaises(ValueError):
                source_records(dict(self.records[0], bytes=replacement), self.families[0])

    def test_missing_extra_and_changed_source_fail(self):
        source = self.root / self.records[0]['asset']
        original = source.read_bytes()
        source.write_bytes(b'same')  # Same length, different hash.
        with self.assertRaises(ValueError):
            self.render()
        source.unlink()
        with self.assertRaises(ValueError):
            self.render()
        source.write_bytes(original)
        (source.parent / 'unregistered.png').write_bytes(b'extra')
        with self.assertRaises(ValueError):
            self.render()

    def test_stale_duplicate_unsorted_or_wrong_count_lock_fails(self):
        text = self.render()
        lines = text.splitlines()
        for bad in [text.replace('c-artwork-manifest-v1', 'c-artwork-manifest-v2'),
                    text + lines[-1] + '\n',
                    '\n'.join(lines[:-2] + list(reversed(lines[-2:]))) + '\n',
                    text.replace('\t1\n', '\t2\n', 1)]:
            with self.subTest(text=bad[:50]), self.assertRaises(ValueError):
                parse_manifest(bad)

    def test_current_reviewed_lock_preserves_originals_and_reviewed_layers(self):
        rows = check_manifest(ROOT / MANIFEST)
        self.assertEqual({family.group: sum(row.group == family.group for row in rows.values())
                          for family in FAMILIES}, {'r16-originals': 135, 'c5-originals': 6, 'r16-layers': 31})

    def test_r16_layers_keep_original_stage_ids_and_source_identity(self):
        original = json.loads((ROOT / 'assets/data/ildu_r16_art_v1.json').read_text(encoding='utf-8'))
        native = next(building for building in original['buildings'] if building['id'] == 'sarangchae')['stages']
        catalog = json.loads((ROOT / 'assets/data/ildu_r16_sarang_layers_v1.json').read_text(encoding='utf-8'))
        receipt = json.loads((ROOT / 'docs/assets/R16_LAYERS_20261031.json').read_text(encoding='utf-8'))
        self.assertEqual(len(catalog['stages']), 16)
        self.assertEqual(catalog['shadowOperation'], 'multiply-then-foreground-source-over')
        self.assertFalse(catalog['progressOrOwnershipMigrationIncluded'])
        for old, stage in zip(native, catalog['stages']):
            self.assertEqual((stage['sequence'], stage['processId'], stage['sourceImageSha256']),
                             (old['sequence'], old['processId'], old['sha256']))
            for kind in ['foreground', 'shadow']:
                self.assertEqual((stage[kind]['width'], stage[kind]['height']), (1800, 1200))
        self.assertEqual(catalog['stages'][0]['processId'], 'ildu.sarangchae-site')
        self.assertEqual(catalog['stages'][0]['foregroundMeshCount'], 0)
        self.assertFalse(catalog['stages'][0]['renderShadowInEmptyArchitectureState'])
        self.assertFalse(receipt['unusedFull17thPairIncluded'])
        self.assertEqual(receipt['allPixelProof']['differingBytes'], 0)
        self.assertEqual(receipt['allPixelProof']['comparedPixels'], 34_560_000)

    def test_gradle_consumers_keep_task_selection_and_one_exact_union_sync(self):
        app = (ROOT / 'android/app/build.gradle.kts').read_text()
        feature = (ROOT / 'android/c_artwork/build.gradle.kts').read_text()
        def selection(text):
            return text[text.index('val cArtworkRequestedTaskLeaves'):text.index('\nif (cArtworkBundleRequested)')]
        # Comments differ, compare the executable selector and rejection block.
        app_selection = selection(app).split('\n// AABs relocate')[0]
        self.assertEqual(app_selection.rstrip(), selection(feature).rstrip())
        for source in [app, feature]:
            self.assertIn('@get:InputFile', source)
            self.assertIn('abstract val artworkManifest: RegularFileProperty', source)
            self.assertIn('abstract val authorityFiles: ConfigurableFileCollection', source)
        self.assertIn('dependsOn("copyFlutterAssets$variantSuffix")', app)
        self.assertIn('exclude(rows.map { "flutter_assets/${it.asset}" })', app)
        self.assertNotIn('exclude("$prefix/**")', app)
        self.assertEqual(feature.count('fileSystemOperations.sync {'), 1)
        self.assertIn('from(repositoryDirectory) { include(rows.map { it.asset }) }', feature)
        self.assertIn('abstract val sourceFiles: ConfigurableFileCollection', feature)
        # Both readers must enforce the same exact row/authority policy.
        def reader(text):
            return text[text.index('object CArtworkManifest {'):text.index('\ndependencies {')].strip()
        self.assertEqual(reader(app), reader(feature))


if __name__ == '__main__':
    unittest.main()
