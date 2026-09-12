import copy
import json
import unittest
from tool.build_phase_tasks import ROOT, build
from tool.phase_objective_contract import build as bind, requirements


class ObjectiveContractTest(unittest.TestCase):
    def setUp(self):
        self.phases=json.loads((ROOT/'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))['phases']
        self.ledger=json.loads((ROOT/'tools/content_factory/cefr_matrix/phase_content/objective_links.json').read_text(encoding='utf-8'))
        self.bundle=build(ROOT)

    def test_all_phase_paths_preserve_grammar_modes_without_claiming_mastery(self):
        rows=self.bundle['objectives']
        self.assertEqual(len(rows),len(requirements(self.phases)))
        for p in self.phases:
            for g in p['koreanGrammar']:
                for mode in ('R','P'):
                    self.assertIn(f"{p['id']}:objective:grammar/{g['grammarKey']}:{mode}",{r['id'] for r in rows})
        self.assertEqual(len(rows), 1668)
        self.assertTrue(all(r['bindings'] for r in rows))
        self.assertTrue(all(r['mastery']=='unverified' for r in rows))

    def test_removed_links_keep_requirements_in_unverified_denominator(self):
        ledger=copy.deepcopy(self.ledger)
        target=ledger['links'][0]['objectiveId']
        ledger['links']=[r for r in ledger['links'] if r['objectiveId']!=target]
        rows=bind(self.phases,self.bundle['tasks'],ledger)
        self.assertEqual(len(rows),len(self.bundle['objectives']))
        row=next(r for r in rows if r['id']==target)
        self.assertEqual(row['bindings'],[])
        self.assertEqual(row['coverage'],'unverified')
        self.assertEqual(row['mastery'],'unverified')

    def test_invalid_material_task_criterion_source_and_mode_fail_closed(self):
        for fault in ('source','task','criterion','task-hash','source-hash','mode','duplicate'):
            ledger=copy.deepcopy(self.ledger)
            row=ledger['links'][0]
            if fault=='source': ledger['sourceHash']='0'*64
            elif fault=='task': row['taskId']='KP01:missing'
            elif fault=='criterion': row['criterionIds']=['not-a-question']
            elif fault=='task-hash': row['taskHash']='0'*64
            elif fault=='source-hash': row['sourceHash']='0'*64
            elif fault=='mode': row['objectiveId']=row['objectiveId'][:-1]+'P'
            elif fault=='duplicate': ledger['links'].append(copy.deepcopy(row))
            with self.subTest(fault=fault), self.assertRaises(ValueError):
                bind(self.phases,self.bundle['tasks'],ledger)

    def test_full_free_email_is_connected_with_unscored_scope(self):
        row=next(r for r in self.bundle['objectives'] if r['id']=='KP06:objective:writing/genre/email_informal:P')
        self.assertEqual(row['bindings'][0]['taskId'],'KP06:writing:02')
        self.assertEqual(row['bindings'][0]['evaluationScope'],'includes_unscored')
        self.assertEqual(row['bindings'][0]['criterionIds'],['draft'])


if __name__=='__main__': unittest.main()
