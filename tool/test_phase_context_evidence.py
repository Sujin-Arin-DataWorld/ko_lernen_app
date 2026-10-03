import json
from copy import deepcopy
import shutil
import tempfile
import unittest
from pathlib import Path

from tool.audit_phase_context_evidence import ROOT, LEDGER, audit, report, reviewed_phase_passages


class PhaseContextEvidenceTest(unittest.TestCase):
    def test_source_revalidation_is_bound_to_original_review_and_current_context(self):
        ledger = json.loads((ROOT / LEDGER).read_text(encoding='utf-8'))
        row = deepcopy(ledger['reviews'][0])
        original = deepcopy(row)
        original['contextSha256'] = '0' * 64
        row['originalReview'] = original
        row['sourceRevalidation'] = {
            'reviewer': 'Codex', 'status': 'MODEL_QA_PASS',
            'reviewedOn': '2026-10-03',
            'checks': ['exact-quote', 'adjacent-context', 'grammar-function'],
            'previousContextSha256': original['contextSha256'],
            'contextSha256': row['contextSha256'], 'quote': row['quote'],
        }
        for fault in (None, 'missing-original', 'identity', 'decision', 'reviewer',
                      'human-approval', 'context', 'previous-context', 'quote', 'checks'):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                for relative in ['assets/data/grammar.csv', 'assets/data/scenarios_a1.json',
                                 'tools/content_factory/cefr_matrix/phases.json', str(LEDGER)]:
                    target = root / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(ROOT / relative, target)
                candidate = deepcopy(row)
                if fault == 'missing-original':
                    candidate.pop('originalReview')
                elif fault in ('identity', 'decision'):
                    key = 'recordId' if fault == 'identity' else 'decision'
                    candidate['originalReview'][key] = 'different'
                elif fault:
                    field, value = {
                        'reviewer': ('reviewer', 'Unverified'),
                        'human-approval': ('status', 'HUMAN_APPROVED'),
                        'context': ('contextSha256', '1' * 64),
                        'previous-context': ('previousContextSha256', '2' * 64),
                        'quote': ('quote', 'Unreviewed quote'),
                        'checks': ('checks', ['exact-quote']),
                    }[fault]
                    candidate['sourceRevalidation'][field] = value
                (root / LEDGER).write_text(json.dumps(
                    {'schemaVersion': 1, 'reviews': [candidate]}, ensure_ascii=False),
                    encoding='utf-8')
                if fault is None:
                    self.assertEqual(audit(root)['reviews'][0]['sourceRevalidation'],
                                     row['sourceRevalidation'])
                else:
                    with self.assertRaisesRegex(ValueError, 'source revalidation'):
                        audit(root)

    def test_phase_sources_exclude_metadata_help_and_productive_prompts(self):
        passages = reviewed_phase_passages(ROOT)
        self.assertTrue(passages)
        self.assertTrue(all(p['jsonPointer'].endswith('/sourceKo') for p in passages))
        self.assertFalse(any(':production:' in p['recordId'] or ':speaking:' in p['recordId'] for p in passages))
        self.assertTrue(all(p['provenance'] == 'authored_phase_material' for p in passages))

    def test_withdrawn_reviews_preserve_history_without_counting_as_current_evidence(self):
        result = audit()
        withdrawn = result['withdrawnReviews']
        self.assertEqual(len(withdrawn), 6)
        identity = lambda row: (row['phaseId'], row['grammarKey'], row['sourcePath'],
                                row['jsonPointer'])
        active = {identity(row) for row in result['reviews']}
        self.assertTrue(all(identity(row['originalReview']) not in active
                            for row in withdrawn))
        for grammar in ('G2:-지 말다', 'G2:-으면서'):
            requirements = [row for row in result['requirements']
                            if row['grammarKey'] == grammar]
            self.assertTrue(requirements)
            self.assertTrue(all(row['legacyAnchors'] == 0 for row in requirements))
        self.assertTrue(all(row['status'] == 'SOURCE_SUPERSEDED'
                            and row['originalReview']['reviewer'] == 'Astra'
                            for row in withdrawn))

    def test_authored_source_requires_current_individual_review(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            relative = Path('tools/content_factory/cefr_matrix/phase_content')
            (root / relative).mkdir(parents=True)
            for name in ('kp09.json', 'kp09_review.json'):
                shutil.copyfile(ROOT / relative / name, root / relative / name)
            path = root / relative / 'kp09.json'
            source = json.loads(path.read_text(encoding='utf-8'))
            source['tasks'][0]['practice']['sourceKo'] += ' 문맥 변경.'
            path.write_text(json.dumps(source, ensure_ascii=False), encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'Stale Phase source review'):
                reviewed_phase_passages(root)

    def test_actual_quotes_preserve_all_phase_requirements(self):
        result = audit()
        phases = json.loads((ROOT / 'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))['phases']
        self.assertEqual(len(result['requirements']), sum(len(p['koreanGrammar']) for p in phases))
        self.assertEqual(len({r['grammarKey'] for r in result['requirements']}), 336)
        self.assertTrue(all(r['productiveAssessment'] == 'unverified' for r in result['requirements']))
        rejected = {(r['grammarKey'], r['quote']) for r in result['reviews'] if r['decision'] == 'rejected'}
        self.assertIn(('G1:-은 후에', '식사 후에 드세요.'), rejected)
        self.assertIn(('G1:-기 전에', '두 달 전에 왔어요.'), rejected)

    def test_source_drift_false_quote_metadata_and_productive_claim_fail(self):
        for fault in ('quote', 'pointer', 'level', 'context', 'productive', 'unknown-key', 'duplicate'):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                for relative in ['assets/data/grammar.csv', 'assets/data/scenarios_a1.json',
                                 'tools/content_factory/cefr_matrix/phases.json', str(LEDGER)]:
                    target = root / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(ROOT / relative, target)
                ledger = json.loads((root / LEDGER).read_text(encoding='utf-8'))
                ledger['reviews'] = [ledger['reviews'][0]]
                row = ledger['reviews'][0]
                if fault == 'context':
                    source = root / row['sourcePath']
                    raw = json.loads(source.read_text(encoding='utf-8'))
                    raw['scenarios'][0]['dialog'][0]['ko'] += ' 문맥 변경.'
                    source.write_text(json.dumps(raw,ensure_ascii=False),encoding='utf-8')
                elif fault == 'duplicate':
                    ledger['reviews'].append(dict(row))
                else:
                    field, value = {
                        'quote': ('quote','파일 제목만 보고 만든 인용'),
                        'pointer': ('jsonPointer','/scenarios/0/id'),
                        'level': ('sourceLevel','C2'),
                        'productive': ('mode','P'),
                        'unknown-key': ('grammarKey','G1:missing'),
                    }[fault]
                    row[field] = value
                (root / LEDGER).write_text(json.dumps(ledger,ensure_ascii=False),encoding='utf-8')
                with self.assertRaises(ValueError):
                    audit(root)

    def test_reports_are_current(self):
        result = audit()
        self.assertEqual(json.loads((ROOT / 'docs/data/phase_context_evidence_report.json').read_text(encoding='utf-8')), result)
        self.assertEqual((ROOT / 'docs/data/phase_context_evidence_report.md').read_text(encoding='utf-8'), report(result))
