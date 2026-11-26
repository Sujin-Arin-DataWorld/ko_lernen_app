"""Current native frames and historical V3 retirement boundaries."""
import unittest
from tool.ildu_retirement_audit import retired_record

from tool.ildu_retirement_test_support import check_frames

from tool import promote_ildu_changgo_turntable as legacy

class PromoteIlDuChanggoTurntableTest(unittest.TestCase):
    def test_current_native_frames_keep_hashes_and_safe_alpha_margins(self):
        check_frames(self, 'changgo')

    def test_retired_v3_promotion_cannot_recreate_old_folders(self):
        with self.assertRaisesRegex(SystemExit, 'retired'):
            legacy.main([])

if __name__ == '__main__':
    unittest.main()
