from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import unittest


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_theme_park_date_tts_manifest as builder


ROOT = SCRIPT_DIR.parents[1]


class ThemeParkDateTtsManifestTest(unittest.TestCase):
    def test_manifest_is_exactly_scoped_to_six_reviewed_scenarios(self) -> None:
        manifest = builder.build_manifest(ROOT)

        self.assertEqual(manifest["generationId"], "theme_park_date_v1")
        self.assertEqual(manifest["scope"], "corpus")
        self.assertEqual(manifest["count"], 59)
        self.assertEqual(
            {item["source"] for item in manifest["items"]},
            {"dialog", "quest"},
        )
        self.assertEqual(
            len({item["scenarioId"] for item in manifest["items"]}),
            6,
        )
        self.assertEqual(
            sum(item["source"] == "dialog" for item in manifest["items"]),
            48,
        )
        self.assertEqual(
            sum(item["source"] == "quest" for item in manifest["items"]),
            11,
        )

    def test_cache_paths_are_derived_from_exact_voice_and_text(self) -> None:
        manifest = builder.build_manifest(ROOT)

        for item in manifest["items"]:
            digest = hashlib.sha1(
                f"{item['voice']}|{item['text']}".encode("utf-8")
            ).hexdigest()
            self.assertEqual(
                item["cachePath"],
                f"tts/v3/{item['voice']}/{digest}.mp3",
            )


if __name__ == "__main__":
    unittest.main()
