import copy
import json
import unittest
import tempfile
import shutil
from pathlib import Path

from tool.build_phase_tasks import build, validate_task, fingerprint

ROOT = Path(__file__).resolve().parents[1]


class PhaseContentContractTest(unittest.TestCase):
    def test_kp01_has_four_skills_and_twelve_exact_grammar_keys(self):
        bundle = build(ROOT)
        self.assertEqual(len(bundle['tasks']), 16)
        self.assertEqual({t['skill'] for t in bundle['tasks']}, {'reading', 'writing', 'listening', 'speaking'})
        self.assertEqual(len({k for t in bundle['tasks'] for k in t['requirementKeys']}), 12)
        self.assertEqual(bundle['publications']['KP01'], 'partial')

    def test_invalid_answer_and_empty_translation_rejected(self):
        task = build(ROOT)['tasks'][0]
        for mutate in (
            lambda t: t['assessment']['questions'][0].update(acceptedAnswers=['missing']),
            lambda t: t['title'].update(de=''),
            lambda t: t.update(minimumScore=True),
            lambda t: t.update(mode='P'),
        ):
            bad = copy.deepcopy(task)
            mutate(bad)
            with self.assertRaises(ValueError):
                validate_task(bad)

    def test_practice_and_assessment_are_independent(self):
        for task in build(ROOT)['tasks']:
            self.assertNotEqual(task['practice']['sourceKo'], task['assessment']['sourceKo'])

    def test_generated_output_is_fresh(self):
        self.assertEqual(json.loads((ROOT / 'assets/data/phase_tasks.json').read_text(encoding='utf-8')), build(ROOT))

    def test_changed_review_bad_level_and_prerequisite_graph_fail_closed(self):
        for fault in ('stale', 'missing-review', 'bad-level', 'missing-ref', 'cycle'):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                folder = root / 'tools/content_factory/cefr_matrix'
                folder.mkdir(parents=True)
                shutil.copyfile(ROOT / 'tools/content_factory/cefr_matrix/phases.json', folder / 'phases.json')
                shutil.copytree(ROOT / 'tools/content_factory/cefr_matrix/phase_content', folder / 'phase_content')
                path = folder / 'phase_content/kp01.json'
                review_path = path.with_name('kp01_review.json')
                data = json.loads(path.read_text(encoding='utf-8'))
                review = json.loads(review_path.read_text(encoding='utf-8'))
                task = data['tasks'][0]
                if fault == 'stale':
                    task['title']['de'] += '!'
                elif fault == 'missing-review':
                    review['reviews'].pop()
                else:
                    if fault == 'bad-level':
                        task['level'] = 'C2'
                    else:
                        task['prerequisiteTaskIds'] = ['KP01:missing' if fault == 'missing-ref' else task['id']]
                    # Synthetic re-review is only in an isolated negative test fixture.
                    next(r for r in review['reviews'] if r['taskId'] == task['id'])['sha256'] = fingerprint(task)
                path.write_text(json.dumps(data,ensure_ascii=False),encoding='utf-8')
                review_path.write_text(json.dumps(review),encoding='utf-8')
                with self.assertRaises(ValueError):
                    build(root)
