"""Preserve promoted word-web content when the original seed is rebuilt."""

from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from tool import build_word_relations as builder


class WordRelationPreservationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.live_bytes = builder.OUT.read_bytes()
        cls.live = json.loads(cls.live_bytes)
        cls.vocab = builder.load_vocab()

    def test_full_live_payload_is_preserved_including_all_48_promoted_clusters(self):
        result = builder.build_payload(self.vocab, self.live)
        self.assertEqual(result, self.live)
        self.assertEqual(len(result['clusters']), 114)
        promoted = [c for c in result['clusters']
                    if c['id'].startswith(('rel_batch19_', 'rel_batch20_'))]
        self.assertEqual(len(promoted), 48)
        self.assertEqual(builder.OUT.read_bytes(), self.live_bytes)

    def test_future_promotions_and_top_level_metadata_are_preserved(self):
        existing = deepcopy(self.live)
        future = deepcopy(existing['clusters'][-1])
        future.update(id='rel_future_01', sourceKo='future source')
        existing['clusters'].append(future)
        existing['reviewMetadata'] = {'approval': 'fixture only'}
        result = builder.build_payload(self.vocab, existing)
        self.assertEqual(result, existing)
        result['clusters'][-1]['sourceKo'] = 'changed in result only'
        self.assertEqual(existing['clusters'][-1]['sourceKo'], 'future source')

    def test_conflicting_curated_content_is_rejected_without_mutating_input(self):
        existing = deepcopy(self.live)
        existing['clusters'][0]['sourceEn'] = 'A separately reviewed correction'
        snapshot = deepcopy(existing)
        with self.assertRaisesRegex(ValueError, 'conflict.*rel_a1_0001'):
            builder.build_payload(self.vocab, existing)
        self.assertEqual(existing, snapshot)

    def test_duplicate_ids_and_source_words_are_rejected(self):
        for field in ('id', 'sourceKo'):
            with self.subTest(field=field):
                existing = deepcopy(self.live)
                extra = deepcopy(existing['clusters'][-1])
                extra.update(id='rel_future_01', sourceKo='future source')
                extra[field] = existing['clusters'][0][field]
                existing['clusters'].append(extra)
                with self.assertRaisesRegex(ValueError, 'duplicate'):
                    builder.build_payload(self.vocab, existing)

    def test_new_seed_source_cannot_collide_with_promoted_source(self):
        seed = deepcopy(self.live['clusters'][0])
        seed.update(id='rel_new', sourceKo=self.live['clusters'][-1]['sourceKo'])
        with mock.patch.object(builder, 'build', return_value=[seed]):
            with self.assertRaisesRegex(ValueError, 'duplicate source'):
                builder.build_payload(self.vocab, self.live)

    def test_missing_cluster_collection_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'clusters'):
            builder.build_payload(self.vocab, {'version': 1})

    def test_parseable_but_broken_existing_content_is_never_rewritten(self):
        invalid_payloads = [
            {'version': 1, 'clusters': []},
            {'version': 1, 'clusters': [{'id': 'rel_invalid', 'sourceKo': '불량'}]},
        ]
        for path, value in ((('version',), None),
                            (('clusters', 0, 'level'), 'D1'),
                            (('clusters', 0, 'synonyms'), {}),
                            (('clusters', 0, 'synonyms', 0, 'ko'), ''),
                            (('clusters', 0, 'synonyms', 0, 'nuanceEn'), [])):
            invalid = deepcopy(self.live)
            parent = invalid
            for key in path[:-1]:
                parent = parent[key]
            parent[path[-1]] = value
            invalid_payloads.append(invalid)
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'relations.json'
            for invalid in invalid_payloads:
                with self.subTest(invalid=str(invalid)[:65]):
                    output.write_text(json.dumps(invalid), encoding='utf-8')
                    before = output.read_bytes()
                    with mock.patch.object(builder, 'OUT', output):
                        self.assertEqual(builder.main(['--write']), 1)
                        self.assertEqual(output.read_bytes(), before)

    def test_default_and_check_and_unchanged_write_keep_exact_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'relations.json'
            output.write_bytes(self.live_bytes)
            with mock.patch.object(builder, 'OUT', output):
                for args in ([], ['--check'], ['--write']):
                    self.assertEqual(builder.main(args), 0)
                    self.assertEqual(output.read_bytes(), self.live_bytes)

    def test_missing_or_invalid_existing_file_is_never_replaced_with_66_seed_rows(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'relations.json'
            with mock.patch.object(builder, 'OUT', output):
                self.assertEqual(builder.main(['--write']), 1)
                self.assertFalse(output.exists())
                output.write_text('{bad json', encoding='utf-8')
                self.assertEqual(builder.main(['--write']), 1)
                self.assertEqual(output.read_text(encoding='utf-8'), '{bad json')

    def test_check_detects_addition_and_write_preserves_old_rows_then_is_idempotent(self):
        seed = deepcopy(self.live['clusters'][0])
        seed.update(id='rel_new', sourceKo='new seed word')
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'relations.json'
            output.write_bytes(self.live_bytes)
            with mock.patch.object(builder, 'OUT', output), \
                    mock.patch.object(builder, 'build', return_value=[seed]):
                self.assertEqual(builder.main(['--check']), 1)
                self.assertEqual(output.read_bytes(), self.live_bytes)
                self.assertEqual(builder.main(['--write']), 0)
                first = output.read_bytes()
                result = json.loads(first)
                self.assertEqual(result['clusters'][:-1], self.live['clusters'])
                self.assertEqual(result['clusters'][-1], seed)
                self.assertEqual(builder.main(['--write']), 0)
                self.assertEqual(output.read_bytes(), first)

    def test_write_conflict_leaves_existing_bytes_intact(self):
        existing = deepcopy(self.live)
        existing['clusters'][0]['sourceEn'] = 'A separately reviewed correction'
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'relations.json'
            output.write_text(json.dumps(existing), encoding='utf-8')
            before = output.read_bytes()
            with mock.patch.object(builder, 'OUT', output):
                self.assertEqual(builder.main(['--write']), 1)
                self.assertEqual(output.read_bytes(), before)

    def test_duplicate_json_keys_fail_closed_at_every_depth(self):
        valid = json.dumps(self.live)
        for invalid in ('{"clusters": [],' + valid[1:],
                        valid.replace('"id": "rel_a1_0001"',
                                      '"id": "hidden_record", "id": "rel_a1_0001"', 1)):
            with self.subTest(invalid=invalid[:45]), tempfile.TemporaryDirectory() as tmp:
                output = Path(tmp) / 'relations.json'
                output.write_text(invalid, encoding='utf-8')
                before = output.read_bytes()
                with mock.patch.object(builder, 'OUT', output):
                    self.assertEqual(builder.main(['--write']), 1)
                    self.assertEqual(output.read_bytes(), before)

    def test_failed_atomic_replace_preserves_original_and_cleans_temporary_file(self):
        seed = deepcopy(self.live['clusters'][0])
        seed.update(id='rel_new', sourceKo='new seed word')
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'relations.json'
            output.write_bytes(self.live_bytes)
            with mock.patch.object(builder, 'OUT', output), \
                    mock.patch.object(builder, 'build', return_value=[seed]), \
                    mock.patch.object(Path, 'replace', side_effect=OSError('simulated failure')):
                self.assertEqual(builder.main(['--write']), 1)
                self.assertEqual(output.read_bytes(), self.live_bytes)
                self.assertEqual(list(Path(tmp).iterdir()), [output])


if __name__ == '__main__':
    unittest.main()
