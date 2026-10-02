import copy
import hashlib
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tool.audit_phase_context_evidence import ROOT, LEDGER, audit, context_hash, report, reviewed_phase_passages
from tool.curriculum_context_inventory import build_inventory


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


class ArchivedContextEvidenceTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        data = self.root / 'assets/data'
        data.mkdir(parents=True)
        (data / 'grammar.csv').write_text('id,level\nfixture,a1\n', encoding='utf-8')
        (data / 'scenarios_a1.json').write_text(json.dumps({
            'scenarios': [{'id': 'demo', 'level': 'a1',
                           'dialog': [{'ko': '학교에 가요.'}]}],
        }, ensure_ascii=False), encoding='utf-8')
        phases = self.root / 'tools/content_factory/cefr_matrix/phases.json'
        phases.parent.mkdir(parents=True)
        phases.write_text(json.dumps({'phases': [{
            'id': 'KP01', 'level': 'A1',
            'koreanGrammar': [{'grammarKey': 'G1:-에'}, {'grammarKey': 'G1:-아요'}],
        }]}), encoding='utf-8')
        self.active = dict(
            phaseId='KP01', grammarKey='G1:-아요', sourcePath='assets/data/scenarios_a1.json',
            recordId='demo', jsonPointer='/scenarios/0/dialog/0/ko', sourceLevel='A1',
            quote='학교에 가요.', contextSha256=context_hash(build_inventory(self.root)['passages']),
            decision='accepted', reviewer='Astra', status='MODEL_QA_PASS', mode='R',
            rationaleKo='정확한 현재 지문을 검토했어요.',
        )
        historical = {**self.active, 'grammarKey': 'G1:-에', 'quote': '집에 가요.',
                      'contextSha256': 'a' * 64}
        digest = hashlib.sha256(json.dumps(historical, ensure_ascii=False,
            sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        self.archived = dict(review=historical, reviewSha256=digest,
            reviewStatus='UNVERIFIED_REVIEW_REQUIRED', humanApprovalClaim=False,
            reason='quote_absent')

    def _write_ledger(self, archived):
        (self.root / LEDGER).write_text(json.dumps(dict(schemaVersion=1,
            reviews=[self.active], invalidatedReviews=[archived]), ensure_ascii=False),
            encoding='utf-8')

    def test_archived_accepted_review_never_counts_as_current_coverage(self):
        for reason in ('quote_absent', 'adjacent_context_changed', 'source_passage_changed'):
            with self.subTest(reason=reason):
                archived = {**self.archived, 'reason': reason}
                self._write_ledger(archived)

                result = audit(self.root)

                self.assertEqual([archived], result['invalidatedReviews'])
                self.assertEqual(1, len(result['reviews']))
                rows = {row['grammarKey']: row for row in result['requirements']}
                historical = rows['G1:-에']
                self.assertEqual('unverified', historical['contextStatus'])
                for count in ('sameLevelAnchors', 'otherLevelAnchors', 'rejectedCandidates',
                              'legacyAnchors', 'authoredPhaseAnchors'):
                    self.assertEqual(0, historical[count], count)
                self.assertEqual('source_review_required', historical['contentDisposition'])
                self.assertEqual('unverified', historical['productiveAssessment'])
                self.assertEqual('reviewed_receptive_use', rows['G1:-아요']['contextStatus'])
                self.assertEqual(1, rows['G1:-아요']['sameLevelAnchors'])

    def test_malformed_or_tampered_historical_hash_is_rejected(self):
        for fault in ('malformed_hash', 'wrong_hash', 'changed_original'):
            with self.subTest(fault=fault):
                archived = copy.deepcopy(self.archived)
                if fault == 'changed_original':
                    archived['review']['quote'] = '원본 기록을 바꿨어요.'
                else:
                    archived['reviewSha256'] = 'not-a-sha256' if fault == 'malformed_hash' else '0' * 64
                self._write_ledger(archived)
                with self.assertRaisesRegex(ValueError, 'Invalidated review history changed'):
                    audit(self.root)

    def test_archive_cannot_claim_active_or_human_approval(self):
        for field, value in (('reviewStatus', 'MODEL_QA_PASS'),
                             ('humanApprovalClaim', True), ('reason', 'approved')):
            with self.subTest(field=field):
                self._write_ledger({**self.archived, field: value})
                with self.assertRaisesRegex(ValueError, 'cannot make an active coverage claim'):
                    audit(self.root)
