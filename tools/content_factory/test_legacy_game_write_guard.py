"""Legacy bootstrap writers must not erase current IDs or edited choices."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
import build_cloze
import build_satzbauen


class LegacyGameWriteGuardTest(unittest.TestCase):
    builders = ((build_cloze, 'cloze.json'), (build_satzbauen, 'satz_sentences.json'))

    def seed_row(self, builder, filename):
        row = json.loads((ROOT / 'assets/data' / filename).read_text(encoding='utf-8'))['items'][0]
        fields = ('level', 'sentenceKo', 'answer', 'distractors', 'de') if builder is build_cloze else (
            'level', 'targetKo', 'promptDe', 'distractors', 'vocabKo')
        return {field: row[field] for field in fields}

    def run_cli(self, builder, destination, *, write=True, rows=None):
        args = [builder.__file__] + (['--write'] if write else [])
        with (patch.object(builder, 'OUT', str(destination)),
              patch.object(sys, 'argv', args),
              patch.object(builder, 'load_rows', return_value=[]),
              patch.object(builder, 'build', return_value=(rows or [], {})),
              redirect_stdout(io.StringIO())):
            builder.main()

    def test_actual_curated_corpora_reject_before_generation_and_preserve_every_byte(self):
        for builder, filename in self.builders:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                before = (ROOT / 'assets/data' / filename).read_bytes()
                destination = Path(temp) / filename
                destination.write_bytes(before)
                with (patch.object(builder, 'OUT', str(destination)),
                      patch.object(sys, 'argv', [builder.__file__, '--write']),
                      patch.object(builder, 'load_rows', side_effect=AssertionError('generation began'))):
                    with self.assertRaises(SystemExit) as raised:
                        builder.main()
                self.assertIn('curated', str(raised.exception))
                self.assertEqual(before, destination.read_bytes())

    def test_dry_run_keeps_curated_data_available_and_unchanged(self):
        for builder, filename in self.builders:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                destination = Path(temp) / filename
                before = (ROOT / 'assets/data' / filename).read_bytes()
                destination.write_bytes(before)
                self.run_cli(builder, destination, write=False)
                self.assertEqual(before, destination.read_bytes())

    def test_unreadable_destination_rejects_without_truncation(self):
        for builder, filename in self.builders:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                destination = Path(temp) / filename
                before = b'{broken'
                destination.write_bytes(before)
                with self.assertRaises(SystemExit):
                    self.run_cli(builder, destination)
                self.assertEqual(before, destination.read_bytes())

    def test_explicit_provenance_without_id_still_rejects(self):
        for builder, filename in self.builders:
            for key in ('sourceVocabId', 'courseUnitIds', 'copyRevision'):
                with self.subTest(filename=filename, key=key), tempfile.TemporaryDirectory() as temp:
                    destination = Path(temp) / filename
                    before = json.dumps({'items': [{key: ''}]}).encode()
                    destination.write_bytes(before)
                    with self.assertRaises(SystemExit):
                        self.run_cli(builder, destination)
                    self.assertEqual(before, destination.read_bytes())

    def test_unknown_existing_structure_rejects_without_truncation(self):
        for builder, filename in self.builders:
            for payload in ({'items': {}}, {'items': [7]}, {'meta': {}},
                            {'items': [{}]}, {'items': [{'unexpected': 'preserve me'}]}):
                with self.subTest(filename=filename, payload=payload), tempfile.TemporaryDirectory() as temp:
                    destination = Path(temp) / filename
                    before = json.dumps(payload).encode()
                    destination.write_bytes(before)
                    with self.assertRaises(SystemExit):
                        self.run_cli(builder, destination)
                    self.assertEqual(before, destination.read_bytes())

    def test_nonempty_unidentified_rows_are_also_preserved(self):
        for builder, filename in self.builders:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                destination = Path(temp) / filename
                before = json.dumps({'items': [self.seed_row(builder, filename)]}).encode()
                destination.write_bytes(before)
                with self.assertRaises(SystemExit):
                    self.run_cli(builder, destination)
                self.assertEqual(before, destination.read_bytes())

    def test_curated_update_during_generation_is_preserved(self):
        for builder, filename in self.builders:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                destination = Path(temp) / filename
                destination.write_text('{"items": []}', encoding='utf-8')
                incoming = (ROOT / 'assets/data' / filename).read_bytes()

                def generate(_rows):
                    destination.write_bytes(incoming)
                    return [], {}

                with (patch.object(builder, 'OUT', str(destination)),
                      patch.object(sys, 'argv', [builder.__file__, '--write']),
                      patch.object(builder, 'load_rows', return_value=[]),
                      patch.object(builder, 'build', side_effect=generate),
                      redirect_stdout(io.StringIO())):
                    with self.assertRaises(SystemExit):
                        builder.main()
                self.assertEqual(incoming, destination.read_bytes())

    def test_empty_unidentified_seed_can_still_be_bootstrapped(self):
        for builder, filename in self.builders:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                destination = Path(temp) / filename
                destination.write_text('{"items": []}', encoding='utf-8')
                rows = [self.seed_row(builder, filename)]
                self.run_cli(builder, destination, rows=rows)
                self.assertEqual(rows, json.loads(destination.read_text(encoding='utf-8'))['items'])

    def test_new_destination_can_still_be_bootstrapped(self):
        for builder, filename in self.builders:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as temp:
                destination = Path(temp) / filename
                rows = [self.seed_row(builder, filename)]
                self.run_cli(builder, destination, rows=rows)
                self.assertEqual(rows, json.loads(destination.read_text(encoding='utf-8'))['items'])


if __name__ == '__main__':
    unittest.main()
