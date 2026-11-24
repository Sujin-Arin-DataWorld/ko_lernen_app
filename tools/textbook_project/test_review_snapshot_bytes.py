"""A review manifest must hash identically on Windows and Linux."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

import build_unit04_human_review_packet as builder


class SnapshotBytesTests(unittest.TestCase):
    def test_generated_manifest_uses_lf_bytes(self):
        original = builder.ROOT, builder.PACKET, builder.FILES
        self.addCleanup(self.restore, original)
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'source.md'
            source.write_bytes('읽기\n'.encode('utf-8'))
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            subprocess.run(['git', '-C', str(root), 'add', 'source.md'], check=True)
            subprocess.run(['git', '-C', str(root), '-c', 'user.name=Snapshot test',
                            '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'source'], check=True)
            builder.ROOT, builder.PACKET, builder.FILES = root, root, [source]
            with contextlib.redirect_stdout(io.StringIO()):
                builder.main()
            body = (root / 'MANIFEST.json').read_bytes()
            self.assertNotIn(b'\r\n', body)
            self.assertEqual(json.loads(body)['files'][0]['bytes'], len(source.read_bytes()))

    @staticmethod
    def restore(original):
        builder.ROOT, builder.PACKET, builder.FILES = original


if __name__ == '__main__':
    unittest.main()
