import os
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.dirname(__file__))
import generate_tts  # noqa: E402


class TtsGeneratorContractTest(unittest.TestCase):
    def test_v3_storage_key_matches_flutter_and_function_contract(self):
        self.assertEqual(generate_tts.TTS_CACHE_REVISION, "v3")
        self.assertEqual(
            generate_tts.cache_relative_path("female", "안녕하세요"),
            "tts/v3/female/d84734f7d89bbd707dc52168c47309aed72b7f80.mp3",
        )

    def test_gcloud_calls_use_an_argument_vector_without_a_shell(self):
        with patch.object(
            generate_tts.shutil,
            "which",
            side_effect=[None, r"C:\\Tools\\GoogleCloudSDK\\gcloud.cmd"],
        ):
            self.assertEqual(
                generate_tts.gcloud_argv("auth", "print-access-token"),
                [r"C:\\Tools\\GoogleCloudSDK\\gcloud.cmd", "auth", "print-access-token"],
            )


if __name__ == "__main__":
    unittest.main()
