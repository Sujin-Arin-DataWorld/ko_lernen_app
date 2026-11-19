import tempfile
from pathlib import Path
import unittest

from tool.verify_firebase_security_patch import verify


class FirebaseSecurityPatchTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.packages = {
            "cloud_firestore": "6.10.2", "firebase_core": "4.15.2",
            "firebase_auth": "6.7.1",
            "firebase_analytics": "12.6.1", "firebase_app_check": "0.4.9",
        }
        self.runtime = {"frameworkVersion": "3.47.8", "dartSdkVersion": "3.13.7"}
        (self.root / "ios").mkdir()
        self.native("12.19.3")

    def native(self, value):
        (self.root / "ios/Podfile.lock").write_text(f"PODS:\n  - FirebaseFirestore ({value}):\n", encoding="utf-8")

    def check(self):
        (self.root / "pubspec.lock").write_text("packages:\n" + "".join(
            f'  {name}:\n    dependency: "direct main"\n    version: "{value}"\n'
            for name, value in self.packages.items()
        ), encoding="utf-8")
        return verify(self.root, self.runtime, ios_lock=True)

    def test_accepts_resolved_backports(self):
        self.assertEqual(self.check(), [])

    def test_old_flutter_or_dart_is_rejected_independently(self):
        for key, old in (("frameworkVersion", "3.44.8"), ("dartSdkVersion", "3.13.6")):
            with self.subTest(key=key):
                saved = self.runtime[key]
                self.runtime[key] = old
                self.assertTrue(self.check())
                self.runtime[key] = saved

    def test_unpatched_packages_and_initial_major_are_rejected(self):
        for value in ("6.8.0", "7.0.0"):
            with self.subTest(value=value):
                self.packages["cloud_firestore"] = value
                self.assertTrue(self.check())

    def test_stale_native_lock_cannot_pass_with_new_dart_packages(self):
        for value in ("12.17.0", "13.1.0"):
            with self.subTest(value=value):
                self.native(value)
                self.assertTrue(self.check())

    def test_patched_next_major_is_accepted(self):
        self.packages.update(cloud_firestore="7.1.0", firebase_core="5.1.0")
        self.native("13.1.1")
        self.assertEqual(self.check(), [])

    def test_missing_package_cannot_pass(self):
        del self.packages["firebase_core"]
        self.assertTrue(self.check())

    def test_auth_must_match_the_core_native_interface(self):
        self.packages["firebase_auth"] = "6.5.7"
        self.assertTrue(self.check())


if __name__ == "__main__":
    unittest.main()
