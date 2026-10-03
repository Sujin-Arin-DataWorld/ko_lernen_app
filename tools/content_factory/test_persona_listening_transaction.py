"""Reviewed listening append must preserve legacy records and be idempotent."""
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import integrate_scenario_batch as integration

sys.path.insert(0, str(ROOT / 'tool'))
import author_listening_lessons as author


class PersonaListeningTransactionTest(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads((ROOT / 'tools/content_factory/drafts/batch_35_persona_a2_manifest.json').read_text(encoding='utf-8'))
        self.scenes = json.loads((ROOT / self.manifest['artifacts'][0]['draft']).read_text(encoding='utf-8'))['scenarios']
        self.draft = json.loads((ROOT / self.manifest['listeningDraft']).read_text(encoding='utf-8'))
        self.live = json.loads((ROOT / 'assets/data/listening_lessons.json').read_text(encoding='utf-8'))
        new_ids = {l['id'] for l in self.draft['lessons']}
        self.original = {**self.live, 'lessons': [l for l in self.live['lessons'] if l['id'] not in new_ids]}

    def stage(self, root):
        data = root / 'assets/data'
        data.mkdir(parents=True)
        target = root / self.manifest['listeningDraft']
        target.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / self.manifest['listeningDraft'], target)
        (data / 'listening_lessons.json').write_text(json.dumps(self.original, ensure_ascii=False), encoding='utf-8')
        return data

    def test_append_preserves_all_178_original_records_and_ids(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = self.stage(root)
            integration._stage_listening(root, data, {**self.manifest, 'status': 'approved'}, self.scenes)
            catalog = json.loads((data / 'listening_lessons.json').read_text(encoding='utf-8'))
            self.assertEqual(len(self.original['lessons']), 178)
            self.assertEqual(catalog['lessons'][:-3], self.original['lessons'])
            self.assertEqual(catalog['lessons'][-3:], self.draft['lessons'])
            merged = {**self.manifest, 'status': 'merged'}
            before = (data / 'listening_lessons.json').read_bytes()
            integration._stage_listening(root, data, merged, self.scenes)
            self.assertEqual((data / 'listening_lessons.json').read_bytes(), before)

    def test_invalid_grounding_fails_before_any_write(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = self.stage(root)
            target = data / 'listening_lessons.json'
            before = target.read_bytes()
            draft = json.loads((root / self.manifest['listeningDraft']).read_text(encoding='utf-8'))
            draft['lessons'][0]['questions'][0]['evidenceKo'] = '이 말은 원문에 없어요.'
            (root / self.manifest['listeningDraft']).write_text(json.dumps(draft, ensure_ascii=False), encoding='utf-8')
            with self.assertRaisesRegex(integration.ScenarioIntegrationError, 'invalid'):
                integration._stage_listening(root, data, self.manifest, self.scenes)
            self.assertEqual(target.read_bytes(), before)

    def test_new_three_have_exact_reproducible_authored_source(self):
        result = author.build()
        self.assertEqual(result['lessons'][-3:], self.draft['lessons'])
        self.assertEqual(len(result['lessons']), 181)
        new_source_ids = {s['id'] for s in self.scenes}
        old_sources = [s for s in author.load_sources() if s['id'] not in new_source_ids]
        with patch.object(author, 'load_sources', return_value=old_sources), patch.object(author, 'reviewed_supplements', return_value={}):
            original_generator = author.build()
        self.assertEqual(result['lessons'][:-3], original_generator['lessons'])


if __name__ == '__main__':
    unittest.main()
