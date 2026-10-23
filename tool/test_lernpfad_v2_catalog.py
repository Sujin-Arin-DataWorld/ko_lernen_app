"""Contracts for the derived path, not a duplicate grammar authority."""
import csv
import io
import json
import hashlib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class LernpfadCatalogContract(unittest.TestCase):
    def test_runtime_character_bytes_match_user_canonical_sources(self):
        manifest = json.loads((ROOT / 'docs/learning/lernpfad-v2/CHARACTER_SOURCES.json').read_text(encoding='utf-8'))
        self.assertEqual(len(manifest['roots']), 6)
        for mapping in manifest['runtime']:
            self.assertTrue(any(mapping['source'].startswith(root) for root in manifest['roots']))
            self.assertEqual(hashlib.sha256((ROOT / mapping['asset']).read_bytes()).hexdigest(), mapping['sha256'])

    def test_declared_dependency_graph_has_no_cycles_and_sources_stay_explicit(self):
        report = json.loads((ROOT / 'docs/learning/lernpfad-v2/COVERAGE_AUDIT.json').read_text(encoding='utf-8'))
        self.assertEqual(report['dependencyAudit']['cycles'], 0)
        self.assertEqual(report['dependencyAudit']['grammarNodesChecked'], 336)
        self.assertGreater(report['dependencyAudit']['derivedPreparationEdges'], 0)
        rows = json.loads((ROOT / 'docs/learning/lernpfad-v2/DIMENSION_CROSSWALK.json').read_text(encoding='utf-8'))['rows']
        self.assertEqual(len(rows), 30 * 13)

    def test_every_original_row_has_one_traceable_mapping(self):
        source = list(csv.DictReader(io.StringIO((ROOT / 'docs/learning/lernpfad-v2/reference/EXISTING_GRAMMAR_INVENTORY.csv').read_text(encoding='utf-8-sig'))))
        target_path = ROOT / 'docs/learning/lernpfad-v2/GRAMMAR_CROSSWALK.csv'
        self.assertTrue(target_path.exists(), 'Derived crosswalk must exist')
        target = list(csv.DictReader(io.StringIO(target_path.read_text(encoding='utf-8-sig'))))
        self.assertEqual(len(source), len(target))
        self.assertEqual([(r['existing_phase_id'], r['grammar_key'], r['role']) for r in source],
                         [(r['existing_phase_id'], r['grammar_key'], r['role']) for r in target])
        self.assertTrue(all(r['band_id'] and r['decision_reason'] for r in target))

    def test_all_bands_have_goals_and_all_published_tasks_remain_reachable(self):
        path = ROOT / 'assets/data/lernpfad_v2.json'
        self.assertTrue(path.exists(), 'Runtime path catalog must exist')
        data = json.loads(path.read_text(encoding='utf-8'))
        self.assertEqual(len(data['bands']), 16)
        for band in data['bands']:
            self.assertTrue(all(band['outcome'].get(lang) for lang in ('ko', 'de', 'en')))
            self.assertTrue(band['activityIds'])
            self.assertTrue(band['reviewStatus'])
        tasks = json.loads((ROOT / 'assets/data/phase_tasks.json').read_text(encoding='utf-8'))['tasks']
        linked = [a['taskId'] for a in data['activities'] if a['kind'] == 'phaseTask']
        self.assertCountEqual(linked, [t['id'] for t in tasks])
        self.assertEqual(len(linked), len(set(linked)))

    def test_first_lesson_teaches_only_a_eo_and_does_not_claim_cefr(self):
        path = ROOT / 'assets/data/lernpfad_foundation.json'
        self.assertTrue(path.exists(), 'Beginner teaching must exist')
        data = json.loads(path.read_text(encoding='utf-8'))
        first = data['lessons'][0]
        self.assertEqual(first['id'], 'F0.1.sound-signs')
        self.assertEqual(first['introduced'], ['ㅇ', 'ㅏ', 'ㅓ'])
        self.assertEqual(first['evidenceScope'], 'taught_symbol_recognition')
        self.assertEqual(first['teaching'][0]['target'], '아')
        self.assertEqual(first['teaching'][1]['target'], '어')
        self.assertNotIn('cefrCertification', data)


if __name__ == '__main__':
    unittest.main()
