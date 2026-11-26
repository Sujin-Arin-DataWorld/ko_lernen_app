"""Retirement evidence stays distinct from active runtime image loading."""
import base64
import copy
import unittest
from unittest.mock import patch

from tool import ildu_retirement_audit as audit


class IlDuRetirementAuditTest(unittest.TestCase):
    def test_all_retired_sources_have_git_identity_and_are_absent(self):
        data = audit.receipt()
        self.assertEqual(len(data['retiredFiles']), 1249)
        self.assertRegex(data['retiredSourceCommit'], r'^[a-f0-9]{40}$')
        for path, record in data['retiredFiles'].items():
            with self.subTest(path=path):
                self.assertFalse((audit.ROOT / path).exists())
                self.assertRegex(record['gitBlob'], r'^[a-f0-9]{40}$')
                self.assertRegex(record['sha256'], r'^[a-f0-9]{64}$')
                self.assertGreaterEqual(record['bytes'], 0)

    def test_corrupted_historical_lock_payload_is_rejected(self):
        data = copy.deepcopy(audit.receipt())
        path = next(iter(data['retiredMetadata']))
        payload = bytearray(base64.b64decode(data['retiredMetadata'][path]))
        payload[0] ^= 1
        data['retiredMetadata'][path] = base64.b64encode(payload).decode()
        with patch.object(audit, 'receipt', return_value=data):
            with self.assertRaisesRegex(ValueError, 'original Git object'):
                audit.retired_json(path)

    def test_retirement_evidence_is_not_a_runtime_fallback(self):
        with self.assertRaises(ValueError):
            audit.retired_record('assets/illustrations/ildu_r16_support/world/sarangchae.png')
        with self.assertRaises(KeyError):
            audit.retired_record('assets/illustrations/personal_hanok_v3/unrecorded.png')


if __name__ == '__main__':
    unittest.main()
