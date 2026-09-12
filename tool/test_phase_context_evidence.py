import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tool.audit_phase_context_evidence import ROOT, LEDGER, audit, report, reviewed_phase_passages


class PhaseContextEvidenceTest(unittest.TestCase):
    def test_phase_sources_exclude_metadata_help_and_productive_prompts(self):
        passages = reviewed_phase_passages(ROOT)
        self.assertTrue(passages)
        self.assertTrue(all(p['jsonPointer'].endswith('/sourceKo') for p in passages))
        self.assertFalse(any(':production:' in p['recordId'] or ':speaking:' in p['recordId'] for p in passages))
        self.assertTrue(all(p['provenance'] == 'authored_phase_material' for p in passages))

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
