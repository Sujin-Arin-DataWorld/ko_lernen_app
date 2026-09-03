"""Schema contract for tool/android_release_tools.json (stdlib only, no network).

This config is reviewed, committed source, not a download target: it holds
version pins for bundletool/firebase-tools/java/node plus the sha256 of each
binary the W2 symbol-evidence gate trusts. A sha256 cannot be computed
offline at authoring time, so this test accepts the literal placeholder
string in that field, but every other field must already be a real,
well-formed value -- a half-filled config (wrong keys, a malformed version,
or a placeholder anywhere other than sha256) must fail fast here, before it
ever reaches tool/android_release_evidence.py in CI.
"""

import json
from pathlib import Path
import re
import unittest
from urllib.parse import urlsplit


CONFIG = Path(__file__).with_name("android_release_tools.json")
PLACEHOLDER = "<fill from harvest step>"
SHA256 = re.compile(r"[0-9a-f]{64}")
SEMVER = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+")
# Temurin release identifiers look like "17.0.20.1+1" (openjdk_version), not
# strict semver -- allow 2-4 dotted numeric components plus a "+build".
JAVA_VERSION = re.compile(r"[0-9]+(?:\.[0-9]+){1,3}\+[0-9]+")
BUNDLETOOL_URL_PREFIX = "/google/bundletool/releases/download/"


class AndroidReleaseToolsConfigTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads(CONFIG.read_text(encoding="utf-8"))

    def _sha256_field(self, value):
        self.assertIsInstance(value, str)
        self.assertTrue(value == PLACEHOLDER or SHA256.fullmatch(value),
                        f"sha256 field must be 64-hex or the harvest placeholder, got {value!r}")

    def test_top_level_keys_are_exactly_the_four_pinned_tools(self):
        self.assertEqual(set(self.config), {"bundletool", "firebase-tools", "java", "node"})

    def test_bundletool_pins_a_real_github_release_jar(self):
        entry = self.config["bundletool"]
        self.assertEqual(set(entry), {"version", "url", "sha256"})
        self.assertIsInstance(entry["version"], str)
        self.assertTrue(SEMVER.fullmatch(entry["version"]), entry["version"])
        url = urlsplit(entry["url"])
        self.assertEqual(url.scheme, "https")
        self.assertEqual(url.netloc, "github.com")
        self.assertTrue(url.path.startswith(BUNDLETOOL_URL_PREFIX), url.path)
        self.assertEqual(
            url.path,
            f"{BUNDLETOOL_URL_PREFIX}{entry['version']}/bundletool-all-{entry['version']}.jar",
        )
        self._sha256_field(entry["sha256"])

    def test_firebase_tools_pins_a_real_npm_version(self):
        entry = self.config["firebase-tools"]
        self.assertEqual(set(entry), {"version", "sha256"})
        self.assertIsInstance(entry["version"], str)
        self.assertTrue(SEMVER.fullmatch(entry["version"]), entry["version"])
        self._sha256_field(entry["sha256"])

    def test_java_pins_an_exact_temurin_build(self):
        entry = self.config["java"]
        self.assertEqual(set(entry), {"version", "sha256"})
        self.assertIsInstance(entry["version"], str)
        self.assertTrue(JAVA_VERSION.fullmatch(entry["version"]), entry["version"])
        self._sha256_field(entry["sha256"])

    def test_node_pins_an_exact_release(self):
        entry = self.config["node"]
        self.assertEqual(set(entry), {"version", "sha256"})
        self.assertIsInstance(entry["version"], str)
        self.assertTrue(SEMVER.fullmatch(entry["version"]), entry["version"])
        self._sha256_field(entry["sha256"])

    def test_no_field_other_than_sha256_may_carry_the_harvest_placeholder(self):
        for name, entry in self.config.items():
            for field, value in entry.items():
                if field == "sha256":
                    continue
                with self.subTest(tool=name, field=field):
                    self.assertNotEqual(value, PLACEHOLDER)


if __name__ == "__main__":
    unittest.main()
