import json
import shutil
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "build" / "firebase-hosting"
EXPECTED_FILES = {
    "account-deletion-page.js",
    "account-deletion.html",
    "assets/favicon.png",
    "assets/gate.png",
    "assets/logo.png",
    "assets/welcome-hero.png",
    "impressum.html",
    "index.html",
    "privacy.html",
    "support.html",
    "terms.html",
}


class FirebaseHostingContractTest(unittest.TestCase):
    def tearDown(self):
        shutil.rmtree(OUTPUT, ignore_errors=True)

    def test_hosting_deploy_uses_only_the_explicit_public_bundle(self):
        config = json.loads((ROOT / "firebase.json").read_text(encoding="utf-8"))
        hosting = config["hosting"]
        self.assertEqual(hosting["public"], "build/firebase-hosting")
        self.assertEqual(
            hosting["predeploy"],
            ["node scripts/prepare_firebase_hosting.cjs"],
        )

        completed = subprocess.run(
            ["node", "scripts/prepare_firebase_hosting.cjs"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("Prepared 11 allowlisted Firebase Hosting files.", completed.stdout)

        actual_files = {
            path.relative_to(OUTPUT).as_posix()
            for path in OUTPUT.rglob("*")
            if path.is_file()
        }
        self.assertEqual(actual_files, EXPECTED_FILES)
        self.assertNotIn("monetization-plan.md", actual_files)
        self.assertFalse(any(path.endswith((".md", ".json")) for path in actual_files))

        for relative_path in EXPECTED_FILES:
            self.assertEqual(
                (OUTPUT / relative_path).read_bytes(),
                (ROOT / "docs" / relative_path).read_bytes(),
                relative_path,
            )


if __name__ == "__main__":
    unittest.main()
