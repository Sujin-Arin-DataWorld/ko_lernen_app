"""Exact successors cannot silently approve a new route or overwrite live copy."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

import smalltalk_editorial_revisions as editorial
from enrich_smalltalk_metadata import enrich_phrase


class SmalltalkEditorialRevisionsTest(unittest.TestCase):
    def setUp(self):
        self.entry = copy.deepcopy(editorial.revisions()['smalltalk_a1_0081'])

    def test_exact_successor_keeps_historical_overlay_and_rejects_unrecorded_copy(self):
        entry = self.entry
        historical = {'field': 'de', 'after': entry['before']['de']}
        entries = {entry['id']: entry}
        self.assertTrue(editorial.verify_successor(entry['after'], historical, entries))
        changed = {**entry['after'], 'ko': '기록되지 않은 새 문장'}
        with self.assertRaisesRegex(ValueError, 'does not match'):
            editorial.verify_successor(changed, historical, entries)
        with self.assertRaisesRegex(ValueError, 'historical overlay'):
            editorial.verify_successor(entry['after'], {'field': 'de', 'after': 'forged'}, entries)

    def test_source_override_preserves_generator_audit_and_adds_authored_turn(self):
        entry = copy.deepcopy(editorial.revisions()['smalltalk_a1_0097'])
        source = {**entry['before'], 'audit': {'source': 'frozen draft'}}
        result = editorial.revise_authored_phrase(source)
        self.assertEqual({'source': 'frozen draft'}, result['audit'])
        for field in entry['fields']:
            self.assertEqual(entry['after'][field], result[field])
        self.assertEqual(result, editorial.revise_authored_phrase(copy.deepcopy(result)))

    def test_ledger_rejects_route_mutation_even_with_matching_hashes(self):
        entry = self.entry
        entry['after']['category'] = 'dating'
        entry['fields'] = sorted(set(entry['fields']) | {'category'})
        entry['afterSha256'] = editorial.fingerprint(entry['after'])
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / editorial.LEDGER_REF
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps({'scope': 'assets/data/smalltalk.json', 'entries': [entry]}))
            with self.assertRaisesRegex(ValueError, 'cannot change'):
                editorial.load_revisions(root)

    def test_ledger_rejects_tampered_fingerprint(self):
        entry = self.entry
        entry['afterSha256'] = '0' * 64
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / editorial.LEDGER_REF
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps({'scope': 'assets/data/smalltalk.json', 'entries': [entry]}))
            with self.assertRaisesRegex(ValueError, 'fingerprint'):
                editorial.load_revisions(root)

    def test_incomplete_romantic_partner_keeps_relationship_during_enrichment(self):
        row = {'id': 'not_published', 'category': 'dating', 'relationshipContext': 'romantic_partner'}
        enrich_phrase(row)
        self.assertEqual('romantic_partner', row['relationshipContext'])
        self.assertEqual('question', row['safeAlternativeQuestions'][0]['turnKind'])
        self.assertTrue(all(row['followUp'][lang] for lang in ('ko', 'de', 'en')))
