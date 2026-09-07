import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
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


def _copy_hosting_fixture(destination: Path) -> None:
    (destination / "scripts").mkdir(parents=True)
    shutil.copy2(
        ROOT / "scripts" / "prepare_firebase_hosting.cjs",
        destination / "scripts" / "prepare_firebase_hosting.cjs",
    )
    for relative_path in EXPECTED_FILES:
        source = ROOT / "docs" / relative_path
        target = destination / "docs" / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def _create_directory_link(link: Path, target: Path) -> None:
    try:
        link.symlink_to(target, target_is_directory=True)
        return
    except OSError:
        if os.name != "nt":
            raise

    completed = subprocess.run(
        ["cmd.exe", "/d", "/c", "mklink", "/J", str(link), str(target)],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise OSError(completed.stderr or completed.stdout)


class FirebaseHostingContractTest(unittest.TestCase):
    def _fixture(self) -> Path:
        temporary = tempfile.TemporaryDirectory(prefix="firebase-hosting-contract-")
        self.addCleanup(temporary.cleanup)
        fixture_root = Path(temporary.name)
        _copy_hosting_fixture(fixture_root)
        return fixture_root

    def test_hosting_deploy_uses_only_the_explicit_public_bundle(self):
        config = json.loads((ROOT / "firebase.json").read_text(encoding="utf-8"))
        hosting = config["hosting"]
        self.assertEqual(hosting["public"], "build/firebase-hosting")
        self.assertEqual(
            hosting["predeploy"],
            ["node scripts/prepare_firebase_hosting.cjs"],
        )

        fixture_root = self._fixture()
        output = fixture_root / "build" / "firebase-hosting"

        completed = subprocess.run(
            ["node", "scripts/prepare_firebase_hosting.cjs"],
            cwd=fixture_root,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("Prepared 11 allowlisted Firebase Hosting files.", completed.stdout)

        actual_files = {
            path.relative_to(output).as_posix()
            for path in output.rglob("*")
            if path.is_file()
        }
        self.assertEqual(actual_files, EXPECTED_FILES)
        self.assertNotIn("monetization-plan.md", actual_files)
        self.assertFalse(any(path.endswith((".md", ".json")) for path in actual_files))

        for relative_path in EXPECTED_FILES:
            self.assertEqual(
                (output / relative_path).read_bytes(),
                (ROOT / "docs" / relative_path).read_bytes(),
                relative_path,
            )

    def test_hosting_bundle_rejects_linked_allowlist_inputs(self):
        fixture_root = self._fixture()
        linked_assets = fixture_root / "docs" / "assets"
        outside_assets = fixture_root / "non-public-assets"
        linked_assets.rename(outside_assets)
        _create_directory_link(linked_assets, outside_assets)

        completed = subprocess.run(
            ["node", "scripts/prepare_firebase_hosting.cjs"],
            cwd=fixture_root,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("symbolic link or reparse point", completed.stderr)
        self.assertFalse((fixture_root / "build" / "firebase-hosting").exists())


if __name__ == "__main__":
    unittest.main()
