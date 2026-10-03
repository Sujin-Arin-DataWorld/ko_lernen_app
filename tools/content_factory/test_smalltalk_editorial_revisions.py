"""Exact successors cannot silently approve a new route or overwrite live copy."""
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

import smalltalk_editorial_revisions as editorial
from enrich_smalltalk_metadata import enrich_phrase
import build_smalltalk
from data.theme_park_date_records import RECORDS


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


class SmalltalkEditorialSuccessionTest(unittest.TestCase):
    """The follow-up simplifications extend, rather than rewrite, old evidence."""

    def setUp(self):
        self.original_bytes = (editorial.ROOT / editorial.LEDGER_REF).read_bytes()
        self.successors = json.loads((editorial.ROOT / editorial.SUCCESSOR_REF).read_text(encoding='utf-8'))

    def load_fixture(self, mutate=None, mutate_original=None):
        payload = copy.deepcopy(self.successors)
        original_bytes = self.original_bytes
        if mutate_original:
            original = json.loads(original_bytes)
            mutate_original(original)
            original_bytes = json.dumps(original, ensure_ascii=False).encode('utf-8')
        if mutate:
            mutate(payload)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original_path = root / editorial.LEDGER_REF
            original_path.parent.mkdir(parents=True)
            original_path.write_bytes(original_bytes)
            (root / editorial.SUCCESSOR_REF).write_text(json.dumps(payload), encoding='utf-8')
            result = editorial.load_revisions(root)
            self.assertEqual(original_bytes, original_path.read_bytes())
            return result

    def test_live_copy_and_metadata_bind_the_exact_latest_follow_up(self):
        originals = {entry['id']: entry for entry in json.loads(self.original_bytes)['entries']}
        live = {row['id']: row for row in json.loads(
            (editorial.ROOT / 'assets/data/smalltalk.json').read_text(encoding='utf-8'))['phrases']}
        entries = self.load_fixture()
        self.assertEqual({'smalltalk_a1_0018', 'smalltalk_a1_0024', 'smalltalk_a2_0089'},
                         {entry['id'] for entry in self.successors['entries']})
        self.assertEqual(hashlib.sha256(self.original_bytes).hexdigest(),
                         self.successors['predecessorLedgerSha256'])
        for successor in self.successors['entries']:
            ident = successor['id']
            with self.subTest(ident=ident):
                self.assertEqual(originals[ident]['before'], entries[ident]['before'])
                self.assertEqual(live[ident], entries[ident]['after'])
                self.assertEqual(editorial.fingerprint(live[ident]), entries[ident]['afterSha256'])
                metadata = editorial.copy_revision_metadata(live[ident])
                self.assertEqual(editorial.SUCCESSOR_REF, metadata['copyRevisionLedger'])
                self.assertEqual(successor['beforeSha256'], metadata['previousPhraseFingerprintSha256'])
                self.assertEqual('nativeReviewRequired', metadata['copyReviewStatus'])
                changed = copy.deepcopy(live[ident])
                changed['followUp']['en'] += ' Unregistered copy.'
                with self.assertRaisesRegex(ValueError, 'does not match'):
                    editorial.copy_revision_metadata(changed)
        self.assertEqual("If we get permission, let's take the photo next to the character.",
                         entries['smalltalk_a2_0089']['after']['followUp']['en'])

    def test_source_builders_and_enrichment_cannot_reinject_old_follow_ups(self):
        entries = editorial.revisions()
        for ident in ('smalltalk_a1_0018', 'smalltalk_a1_0024'):
            entry = entries[ident]
            args = next(row for row in build_smalltalk.P if all(
                row[index] == entry['before'][key]
                for index, key in ((0, 'category'), (1, 'level'), (3, 'ko'))))
            built = build_smalltalk._phrase(*args)
            self.assertEqual(entry['after']['followUp'], built['followUp'])
            self.assertEqual(built, build_smalltalk._phrase(*args))
        authored = next(row for row in RECORDS if row['id'] == 'smalltalk_a2_0089')
        self.assertEqual(entries[authored['id']]['after']['followUp'], authored['followUp'])
        self.assertEqual(authored, editorial.revise_authored_phrase(copy.deepcopy(authored)))
        for ident in ('smalltalk_a1_0018', 'smalltalk_a1_0024', 'smalltalk_a2_0089'):
            row = {**copy.deepcopy(entries[ident]['before']), 'audit': {'source': 'frozen draft'}}
            enrich_phrase(row)
            self.assertEqual(entries[ident]['after']['followUp'], row['followUp'])
            self.assertEqual({'source': 'frozen draft'}, row['audit'])
            before_second_run = copy.deepcopy(row)
            enrich_phrase(row)
            self.assertEqual(before_second_run, row)

    def test_original_entry_tampering_fails_even_when_row_hashes_are_recomputed(self):
        def tamper_original(payload):
            entry = next(row for row in payload['entries'] if row['id'] == 'smalltalk_a1_0018')
            entry['after']['followUp']['en'] = 'A substituted predecessor.'
            entry['afterSha256'] = editorial.fingerprint(entry['after'])
        with self.assertRaisesRegex(ValueError, 'frozen predecessor'):
            self.load_fixture(mutate_original=tamper_original)

    def test_successor_rejects_route_frame_or_unregistered_copy_even_with_new_hash(self):
        def mutation(field, value):
            def mutate(payload):
                entry = payload['entries'][0]
                if field.startswith('followUp.'):
                    entry['after']['followUp'][field.split('.')[1]] = value
                else:
                    entry['after'][field] = value
                entry['afterSha256'] = editorial.fingerprint(entry['after'])
            return mutate
        for field, value in (('level', 'c2'), ('category', 'dating'), ('kind', 'opener'),
                             ('relationshipContext', 'service'), ('followUp.turnKind', 'question'),
                             ('ko', 'Unregistered phrase')):
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, 'non-copy or route'):
                self.load_fixture(mutation(field, value))
        for mutate in (
            lambda payload: payload.update(humanApprovalClaim=True),
            lambda payload: payload.update(sourceGitCommit='bad'),
            lambda payload: payload.update(authoringReceiptSha256='bad'),
            lambda payload: payload.update(entries={}),
            lambda payload: payload['entries'][0].update(beforeSha256='0' * 64),
            lambda payload: payload['entries'][0].update(predecessorEntrySha256='0' * 64),
        ):
            with self.subTest(mutate=mutate), self.assertRaises(ValueError):
                self.load_fixture(mutate)

    def test_source_override_refuses_a_new_level_for_an_existing_id(self):
        row = copy.deepcopy(editorial.revisions()['smalltalk_a2_0089']['before'])
        row['level'] = 'c2'
        with self.assertRaisesRegex(ValueError, 'routing identity'):
            editorial.revise_authored_phrase(row)
