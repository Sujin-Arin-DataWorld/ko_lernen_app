"""Current native frames and historical V3 retirement boundaries."""
import unittest
from tool.ildu_retirement_audit import retired_record

from tool.ildu_retirement_test_support import check_frames

from tool import promote_ildu_final_three_turntables as legacy

class PromoteIlDuFinalThreeTurntablesTest(unittest.TestCase):
    def test_original_approvals_are_preserved_by_exact_git_identity(self):
        for key, spec in legacy.BUILDINGS.items():
            with self.subTest(building=key):
                original = retired_record(spec.source_original, spec.expected_source_sha256)
                preserved = retired_record(spec.preserved_original, spec.expected_source_sha256)
                self.assertEqual(original['sha256'], preserved['sha256'])
                self.assertEqual(original['bytes'], preserved['bytes'])

    def test_current_models_keep_distinct_eight_view_transparent_frames(self):
        for key in ['angotgan', 'gokgan', 'toilet', 'toilet1']:
            with self.subTest(building=key):
                check_frames(self, key)

    def test_retired_v3_promotion_cannot_recreate_old_folders(self):
        with self.assertRaisesRegex(SystemExit, 'retired'):
            legacy.main([])

if __name__ == '__main__':
    unittest.main()
