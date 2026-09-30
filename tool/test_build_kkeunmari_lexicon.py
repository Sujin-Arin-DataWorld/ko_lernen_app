import unittest
from tool.build_kkeunmari_lexicon import build, OUTPUT, SERVER_OUTPUT

class OfflineNounBuildTest(unittest.TestCase):
    def test_mobile_and_server_use_the_current_same_licensed_index(self):
        expected = build()
        self.assertEqual(OUTPUT.read_text(encoding='utf-8'), expected)
        self.assertEqual(SERVER_OUTPUT.read_text(encoding='utf-8'), expected)

if __name__ == '__main__':
    unittest.main()
