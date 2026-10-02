"""Reviewed game glosses survive generation, without redefining valid Korean."""
import json
import unittest
from collections import Counter
from kkeunmari_editorial_revisions import ROOT, LEDGER, apply_review


class KkeunmariEditorialTest(unittest.TestCase):
    def test_authored_copy_and_quarantine_are_preserved_when_regenerated(self):
        reviews = json.loads(LEDGER.read_text())['entries']
        source = [r['before'] for r in reviews]
        actual = apply_review(source)
        expected = {r['word']: r['copy'] for r in reviews if r['result'] == 'reviewed_bilingual_copy'}
        self.assertEqual(set(expected), {r['word'] for r in actual})
        for row in actual:
            self.assertEqual(expected[row['word']], {k: row[k] for k in ('german', 'english')})
            self.assertEqual(next(r for r in source if r['word'] == row['word'])['level'], row['level'])
        self.assertEqual(actual, apply_review(actual))

    def test_live_chain_counts_and_copies_match_final_pool(self):
        live = json.loads((ROOT / 'assets/data/kkeunmari_pool.json').read_text())['words']
        self.assertEqual(live, apply_review(live))
        counts = Counter(r['word'][0] for r in live)
        for row in live:
            count = counts[row['word'][-1]] - (row['word'][0] == row['word'][-1])
            self.assertEqual(count, row['next_count'])
            self.assertEqual(count == 0, row['is_dead_end'])

    def test_quarantine_does_not_remove_independent_dictionary_evidence(self):
        nouns = json.loads((ROOT / 'assets/data/kkeunmari_nouns.json').read_text())['words']
        self.assertIn('우리', nouns)
        self.assertIn('이건', nouns)
        live = json.loads((ROOT / 'assets/data/kkeunmari_pool.json').read_text())['words']
        self.assertNotIn('우리', {r['word'] for r in live})
