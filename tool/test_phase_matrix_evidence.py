import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tool.audit_curriculum_matrix import run_audit
from tool.build_phase_tasks import ROOT, build
from tool.phase_matrix_evidence import attach


class PhaseMatrixEvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.bundle = build(ROOT)
        cls.rows = run_audit(ROOT)[2].evidence_requirements

    def test_all_matrix_modes_have_sampled_paths_without_mastery(self):
        self.assertEqual(len(self.rows), 186)
        for row in self.rows:
            self.assertTrue(row['taskBindings'])
            self.assertFalse(row['assessable'])
            self.assertEqual(row['mastery'], 'unverified')
            self.assertTrue(all(e['kind'] == 'authored_criteria_not_learner_attempt'
                                for e in row['assessmentEvidence']))
        b1 = next(r for r in self.rows if r['requirementKey'] ==
                  'B1:speechAct:structure_discourse_open_close_scope:R')
        self.assertTrue({'opening', 'closing'} <= set(b1['taskBindings'][0]['criterionIds']))

    def test_stale_hash_wrong_mode_and_invented_criterion_fail(self):
        rel = Path('tools/content_factory/cefr_matrix/phase_content/matrix_links.json')
        for fault in ('hash', 'source', 'mode', 'criterion', 'duplicate'):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                ledger = json.loads((ROOT / rel).read_text(encoding='utf-8'))
                rows = copy.deepcopy(self.rows)
                link = ledger['links'][0]
                if fault == 'hash': link['taskHash'] = '0' * 64
                elif fault == 'source': link['sourceHash'] = '0' * 64
                elif fault == 'criterion': link['criterionIds'] = ['invented']
                elif fault == 'duplicate': ledger['links'].append(copy.deepcopy(link))
                else:
                    next(r for r in rows if r['requirementKey'] == link['requirementKey'])['mode'] = 'P'
                (root / rel).parent.mkdir(parents=True)
                (root / rel).write_text(json.dumps(ledger), encoding='utf-8')
                with patch('tool.phase_matrix_evidence.build', return_value=self.bundle):
                    with self.assertRaises(ValueError): attach(root, rows)

    def test_candidate_alone_does_not_supply_a_missing_reviewed_path(self):
        bundle = copy.deepcopy(self.bundle)
        for objective in bundle['objectives']:
            if objective['level'] == 'A1' and objective['sourceRequirementKey'] == 'functions/greet_introduce_self':
                objective['bindings'] = []
        rows = copy.deepcopy(self.rows)
        target = next(r for r in rows if r['requirementKey'] == 'A1:speechAct:greet_introduce_self:P')
        target.update(taskBindings=[], assessmentEvidence=[], runtimeEvidence=[],
                      evidenceStage='unverified_unmapped')
        self.assertTrue(target['contentCandidates'])
        with patch('tool.phase_matrix_evidence.build', return_value=bundle):
            attach(ROOT, rows)
        self.assertEqual(target['taskBindings'], [])
        self.assertEqual(target['evidenceStage'], 'unverified_unmapped')
