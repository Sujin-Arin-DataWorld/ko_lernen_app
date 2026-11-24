"""Pinned content must survive squash/shallow history without hiding changes."""
import contextlib
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import validate_unit04_human_review_packet as validator


class ReviewPacketPortabilityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        original = validator.ROOT, validator.PACKET, validator.MANIFEST
        self.addCleanup(self.restore, original)
        validator.ROOT, validator.PACKET = self.root, self.root / 'packet'
        validator.PACKET.mkdir()
        validator.MANIFEST = validator.PACKET / 'MANIFEST.json'
        self.git('init', '-q')
        self.files = []
        for index in range(13):
            name = f'input{index}.md'
            body = f'reviewed {index}\n'.encode()
            (self.root / name).write_bytes(body)
            self.files.append({'path':name, 'bytes':len(body), 'sha256':hashlib.sha256(body).hexdigest()})
        self.git('add', '.')
        self.git('commit', '-qm', 'integrated snapshot')
        manifest = {'status':'READY_FOR_HUMAN_REVIEW', 'unitId':'a1_04_order_request_object',
                    'sourceCommit':'0' * 40, 'files':self.files}
        validator.MANIFEST.write_text(json.dumps(manifest), encoding='utf-8')
        (validator.PACKET / 'REVIEW_DECISIONS.json').write_text('{"status":"OPEN"}', encoding='utf-8')

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), '-c', 'core.autocrlf=false',
                                        '-c', 'user.name=Packet test', '-c', 'user.email=test@example.invalid', *args])

    @staticmethod
    def restore(original):
        validator.ROOT, validator.PACKET, validator.MANIFEST = original

    def test_valid_snapshot_without_historical_source_object(self):
        with contextlib.redirect_stdout(io.StringIO()):
            try:
                validator.main()
            except subprocess.CalledProcessError:
                self.fail('valid content must not require an unavailable historical commit')

    def test_rejects_changed_working_file(self):
        (self.root / 'input0.md').write_bytes(b'changed\n')
        with self.assertRaises(AssertionError):
            validator.main()

    def test_rejects_committed_change_hidden_by_reviewed_working_bytes(self):
        source = self.root / 'input0.md'
        reviewed = source.read_bytes()
        source.write_bytes(b'committed change\n')
        self.git('add', 'input0.md')
        self.git('commit', '-qm', 'later change')
        source.write_bytes(reviewed)
        with self.assertRaises(AssertionError):
            validator.main()

    def test_rejects_staged_change_hidden_by_reviewed_working_bytes(self):
        manifest = json.loads(validator.MANIFEST.read_text())
        manifest['sourceCommit'] = self.git('rev-parse', 'HEAD').decode().strip()
        validator.MANIFEST.write_text(json.dumps(manifest))
        source = self.root / 'input0.md'
        reviewed = source.read_bytes()
        source.write_bytes(b'staged change\n')
        self.git('add', 'input0.md')
        source.write_bytes(reviewed)
        with self.assertRaises(AssertionError):
            validator.main()


if __name__ == '__main__':
    unittest.main()
