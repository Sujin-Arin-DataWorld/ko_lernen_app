"""Deterministic C9 contracts; these tests cannot approve language quality."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_content import ContentValidator
from scan_usage_notes_de import scan_text


class UsageNoteContractTest(unittest.TestCase):
    def setUp(self):
        self.validator = ContentValidator()
        self.validator._live_levels['vocab'] = {'vocab_b1_0001': 'b1'}
        triad = dict(ko='오해 풀기는 오해를 바로잡는 일이다.',
                     de='Ein Missverständnis klären.', en='Clearing up a misunderstanding.')
        self.note = dict(id='vocab_b1_0001', level='B1', register='neutral',
            nuance=triad.copy(), situation=triad.copy(), patterns=[triad.copy()],
            collocations=[triad.copy(), triad.copy()],
            contrasts=[dict(headword='오해', vocabId=None, **triad)],
            examples=[dict(register='written', ko='이 문제를 확인했습니다.', de='Wir haben das Problem geprüft.', en='We examined the problem.'),
                      dict(register='casual', ko='내가 잘못 들었어.', de='Ich habe mich verhört.', en='I misheard.')])
        self.front = dict(id=self.note['id'], example_korean='오해가 생겼어요.',
                          example_german='Es gab ein Missverständnis.', example_english='There was a misunderstanding.')
        self.validator.load_json = lambda _: dict(schemaVersion=1, notes=[self.note])
        self.validator.load_csv = lambda _: ([], [self.front])

    def messages(self):
        self.validator.validate_usage_notes()
        return [issue.message for issue in self.validator.issues]

    def test_legitimate_compound_and_high_text_overlap_is_not_semantic_failure(self):
        # Intentionally identical explanations: editorial review, not string arithmetic.
        self.assertEqual(self.messages(), [])

    def test_exact_front_duplicates_in_each_language(self):
        for lang, column in [('ko', 'example_korean'), ('de', 'example_german'), ('en', 'example_english')]:
            with self.subTest(lang=lang):
                self.setUp()
                self.note['examples'][1][lang] = '  ' + self.front[column].upper().replace('.', '!') + '  '
                self.assertTrue(any('duplicates the front-card' in m for m in self.messages()))

    def test_unicode_whitespace_and_punctuation_normalization(self):
        import unicodedata
        self.note['examples'][1]['ko'] = unicodedata.normalize('NFD', '오해가  생겼어요!')
        self.assertTrue(any('duplicates the front-card' in m for m in self.messages()))

    def test_pairwise_duplicate_in_each_language(self):
        for lang in ['ko', 'de', 'en']:
            with self.subTest(lang=lang):
                self.setUp()
                self.note['examples'][1][lang] = self.note['examples'][0][lang]
                self.assertTrue(any('duplicate each other' in m for m in self.messages()))

    def test_different_events_with_shared_words_pass(self):
        self.note['examples'][0]['en']='I spoke to my friend about the train.'
        self.note['examples'][1]['en']='I spoke to my friend about the exam.'
        self.assertEqual(self.messages(), [])

    def test_register_cardinality(self):
        for registers in [('casual', 'casual'), ('formal', 'written')]:
            with self.subTest(registers=registers):
                self.setUp()
                for e, register in zip(self.note['examples'], registers): e['register']=register
                self.assertTrue(any("exactly one 'casual'" in m for m in self.messages()))

    def test_invalid_register_and_example_count(self):
        self.note['examples'][0]['register']='polite'
        self.assertTrue(any('register must be one of' in m for m in self.messages()))
        self.setUp()
        self.note['examples'].pop()
        self.assertTrue(any('exactly 2 examples' in m for m in self.messages()))

    def test_current_usage_notes_structural_contract(self):
        v=ContentValidator()
        v.validate_vocab()
        v.issues.clear()
        v.validate_usage_notes()
        self.assertEqual(v.issues, [])


class GermanTriageTest(unittest.TestCase):
    def test_legitimate_tokens_and_case_variants(self):
        self.assertEqual(scan_text('Steuer Steuern Quelle Quellen STEUER quelle')['leftover'], [])

    def test_candidate_typos_and_inflections(self):
        hits=scan_text('fuer groessere Strassen moglichen DRUCKTE Gebuhren')
        self.assertEqual(hits['leftover'], ['fuer', 'groessere'])
        self.assertIn('Strassen', hits['ss'])
        words=[h[0] for h in hits['homograph']]
        for expected in ['moglichen', 'DRUCKTE', 'Gebuhren']: self.assertIn(expected, words)

    def test_homographs_are_candidates_even_when_correct(self):
        self.assertIn('druckt', [h[0] for h in scan_text('Der Drucker druckt schon.')['homograph']])


class UsageNoteAuditCoverageTest(unittest.TestCase):
    def test_live_usage_notes_are_in_copy_audit(self):
        import json
        from audit_content_text import build_inventory, DATA_DIR
        audit=build_inventory()
        self.assertNotIn('usage_notes.json',audit['unclassifiedFiles'])
        surface=next(item for item in audit['files'] if item['path']=='usage_notes.json')
        count=len(json.loads((DATA_DIR/'usage_notes.json').read_text(encoding='utf-8'))['notes'])
        self.assertEqual(surface['recordCount'],count)
        self.assertGreater(surface['textValueCount'],0)


if __name__=='__main__': unittest.main()
