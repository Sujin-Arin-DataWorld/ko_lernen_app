import csv
import json
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_c9_sample as sample


class C9SampleTest(unittest.TestCase):
    def setUp(self):
        self.notes=json.loads((sample.ROOT/'assets/data/usage_notes.json').read_text(encoding='utf-8'))['notes']
        with (sample.ROOT/'assets/data/korean_vocab.csv').open(encoding='utf-8-sig', newline='') as handle:
            self.vocab={r['id']:r for r in csv.DictReader(handle)}

    def test_membership_and_order(self):
        self.assertEqual(sample.sample_ids(), ['vocab_a1_0290','vocab_b1_0009','vocab_b1_0036','vocab_b1_0070','vocab_b1_0111','vocab_b1_0159','vocab_b1_0187','vocab_b1_0257','vocab_b1_0392','vocab_b1_0471'])
        self.assertEqual(sample.render(self.notes,self.vocab), sample.render(list(reversed(self.notes)),self.vocab))

    def test_checked_in_packet_is_current(self):
        self.assertEqual(sample.OUTPUT.read_text(encoding='utf-8'),sample.render(self.notes,self.vocab))

    def test_source_change_changes_packet(self):
        before=sample.render(self.notes,self.vocab)
        next(n for n in self.notes if n['id']=='vocab_b1_0159')['nuance']['de']='Eine geänderte Erklärung.'
        self.assertNotEqual(before,sample.render(self.notes,self.vocab))

    def test_missing_batch_note_fails(self):
        with self.assertRaisesRegex(ValueError,'Missing batch IDs'):
            sample.render([n for n in self.notes if n['id']!='vocab_b1_0159'],self.vocab)


if __name__=='__main__': unittest.main()
