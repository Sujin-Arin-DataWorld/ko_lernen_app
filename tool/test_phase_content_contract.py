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
        tasks = [t for t in bundle['tasks'] if t['phaseId'] == 'KP01']
        self.assertEqual(len(tasks), 33)
        self.assertEqual({t['skill'] for t in tasks}, {'reading', 'writing', 'listening', 'speaking'})
        self.assertEqual(len({k for t in tasks for k in t['requirementKeys']}), 12)
        self.assertEqual(bundle['publications']['KP01'], 'partial')

    def test_published_grammar_production_is_separate_from_recognition(self):
        bundle = build(ROOT)
        phases = json.loads((ROOT / 'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))['phases']
        for phase in phases[:16]:
            tasks = [t for t in bundle['tasks'] if t['phaseId'] == phase['id'] and ':production:' in t['id']]
            self.assertEqual({k for t in tasks for k in t['requirementKeys']}, {g['grammarKey'] for g in phase['koreanGrammar']})
            for task in tasks:
                self.assertEqual(task['mode'], 'P')
                self.assertEqual(task['skill'], 'writing')
                for mode in ('practice', 'assessment'):
                    question = task[mode]['questions'][0]
                    self.assertEqual(question['kind'], 'boundedSentence')
                    self.assertTrue(question['required'])
                    self.assertNotIn(question['acceptedAnswers'][0], task[mode]['sourceKo'])
                for answer in task['assessment']['questions'][0]['acceptedAnswers']:
                    self.assertNotIn(answer, '\n'.join(task['examplesKo']))

    def test_published_phases_keep_required_grammar_and_four_skill_paths(self):
        bundle = build(ROOT)
        phases = json.loads((ROOT / 'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))['phases']
        for phase in phases[:16]:
            tasks = [t for t in bundle['tasks'] if t['phaseId'] == phase['id']]
            self.assertEqual({t['skill'] for t in tasks}, {'reading', 'writing', 'listening', 'speaking'})
            self.assertEqual({k for t in tasks for k in t['requirementKeys']}, {g['grammarKey'] for g in phase['koreanGrammar']})
            self.assertEqual(bundle['publications'][phase['id']], 'partial')
            for t in tasks:
                if t['skill'] == 'speaking':
                    self.assertEqual(t['assessment']['questions'], [])

    def test_a1_critical_time_quantity_and_polarity_criteria_are_required(self):
        tasks = {t['id']: t for t in build(ROOT)['tasks']}
        expected = {
            'KP16:listening:01': {'counterfactual', 'condition', 'concession', 'fallback', 'disclosure', 'contact', 'decision'},
            'KP16:reading:01': {'necessary', 'conclusion', 'exception', 'counterpoint', 'comparison', 'authority'},
            'KP15:listening:01': {'neutral', 'evaluation', 'unexpected', 'overlap', 'near', 'ongoing', 'hypothesis'},
            'KP15:reading:01': {'shared', 'attribution', 'system', 'record', 'responsibility', 'proposal'},
            'KP14:listening:01': {'definition', 'role', 'means', 'denominator', 'relation', 'causal', 'request'},
            'KP14:reading:02': {'scope', 'exception', 'authority', 'means', 'responsibility'},
            'KP10:listening:01': {'plan', 'interrupted', 'source', 'cause', 'prepared'},
            'KP10:reading:01': {'fact', 'quote', 'interpretation', 'limit'},
            'KP02:listening:01': {'start', 'end', 'place', 'transport', 'class_start', 'class_end'},
            'KP02:listening:02': {'purpose', 'time', 'room'},
            'KP03:reading:01': {'quantity', 'total', 'budget'},
            'KP04:listening:01': {'fact', 'time', 'sequence'},
        }
        for tid, criterion_ids in expected.items():
            for mode in ('practice', 'assessment'):
                self.assertEqual({q['id'] for q in tasks[tid][mode]['questions'] if q['required']}, criterion_ids)

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
            self.assertNotIn(task['assessment']['sourceKo'], '\n'.join(task['examplesKo']), task['id'])

    def test_free_writing_has_no_automatic_key_and_remains_required(self):
        task = copy.deepcopy(next(t for t in build(ROOT)['tasks'] if t['skill'] == 'writing'))
        q = task['assessment']['questions'][0]
        q.update(kind='freeText', acceptedAnswers=[], options=[], required=True)
        q.pop('rejectedAnswers', None)
        validate_task(task)
        for mutation in ({'acceptedAnswers': ['rubric keyword']}, {'required': False}, {'rejectedAnswers': ['free wording']}):
            bad = copy.deepcopy(task)
            bad['assessment']['questions'][0].update(mutation)
            with self.assertRaises(ValueError):
                validate_task(bad)

    def test_assessment_in_study_examples_is_rejected(self):
        task = copy.deepcopy(build(ROOT)['tasks'][0])
        task['examplesKo'] = [task['assessment']['sourceKo']]
        with self.assertRaisesRegex(ValueError, 'Study examples reveal'):
            validate_task(task)

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
