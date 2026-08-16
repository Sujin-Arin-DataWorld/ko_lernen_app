import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock
import zipfile

import verify_deployed_source as verifier


class DeployedSourceVerificationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.source_dir = Path(self.temporary.name) / "source"
        self.source_dir.mkdir()
        ignore = "*\n" + "".join(f"!{name}\n" for name in verifier.RUNTIME_FILES)
        (self.source_dir / ".gcloudignore").write_text(ignore, encoding="utf-8")
        for index, name in enumerate(verifier.RUNTIME_FILES):
            (self.source_dir / name).write_bytes(f"content-{index}".encode())

    def _archive(self, *, extra: tuple[str, bytes] | None = None) -> Path:
        archive_path = Path(self.temporary.name) / "source.zip"
        with zipfile.ZipFile(archive_path, "w") as archive:
            for name in verifier.RUNTIME_FILES:
                archive.writestr(name, (self.source_dir / name).read_bytes())
            if extra:
                archive.writestr(*extra)
        return archive_path

    def test_exact_archive_matches_local_canonical_digest(self):
        archive_path = self._archive()

        digest = verifier.verify_archive(self.source_dir, archive_path)

        self.assertEqual(digest, verifier.local_source_digest(self.source_dir))

    def test_changed_runtime_bytes_fail(self):
        archive_path = self._archive()
        (self.source_dir / "main.py").write_text("new code", encoding="utf-8")

        with self.assertRaises(verifier.SourceVerificationError):
            verifier.verify_archive(self.source_dir, archive_path)

    def test_unexpected_secret_file_fails_without_echoing_its_name(self):
        archive_path = self._archive(extra=(".env", b"DEEPL_API_KEY=secret-value"))

        with self.assertRaises(verifier.SourceVerificationError) as caught:
            verifier.verify_archive(self.source_dir, archive_path)

        message = str(caught.exception)
        self.assertNotIn(".env", message)
        self.assertNotIn("secret-value", message)

    def test_allowlist_drift_fails_before_packaging(self):
        with (self.source_dir / ".gcloudignore").open("a", encoding="utf-8") as ignore:
            ignore.write("!smoke_test.py\n")

        with self.assertRaises(verifier.SourceVerificationError):
            verifier.validate_local_manifest(self.source_dir)

    def test_gcloud_upload_manifest_must_be_the_same_exact_seven_files(self):
        output = "\n".join(reversed(verifier.RUNTIME_FILES)) + "\n"

        with mock.patch.object(verifier, "_run_gcloud", return_value=output) as run:
            uploaded = verifier.validate_gcloud_upload_manifest(self.source_dir)

        self.assertEqual(set(uploaded), set(verifier.RUNTIME_FILES))
        run.assert_called_once_with(
            ["meta", "list-files-for-upload", str(self.source_dir)]
        )

    def test_gcloud_upload_rejects_every_non_runtime_file_category(self):
        prohibited = (
            ".env",
            ".env.production",
            "deploy.env.yaml",
            "test_main.py",
            "smoke_test.py",
            "main.pyc",
            "__pycache__/main.cpython-312.pyc",
        )
        for filename in prohibited:
            with self.subTest(filename=filename):
                output = "\n".join((*verifier.RUNTIME_FILES, filename)) + "\n"
                with mock.patch.object(verifier, "_run_gcloud", return_value=output):
                    with self.assertRaises(
                        verifier.SourceVerificationError
                    ) as caught:
                        verifier.validate_gcloud_upload_manifest(self.source_dir)

                self.assertNotIn(filename, str(caught.exception))

    def test_deploy_app_ids_match_flutter_and_android_runtime_configs(self):
        repository = Path(self.temporary.name) / "repository"
        source_dir = repository / "functions" / "analyze_korean_text"
        options_path = repository / "lib" / "firebase_options.dart"
        android_path = repository / "android" / "app" / "google-services.json"
        deploy_path = source_dir / "deploy.env.yaml"
        source_dir.mkdir(parents=True)
        options_path.parent.mkdir(parents=True)
        android_path.parent.mkdir(parents=True)
        android_id = "1:123:android:abc"
        ios_id = "1:123:ios:def"
        options_path.write_text(
            "static const FirebaseOptions android = FirebaseOptions(\n"
            f"  appId: '{android_id}',\n"
            ");\n"
            "static const FirebaseOptions ios = FirebaseOptions(\n"
            f"  appId: '{ios_id}',\n"
            ");\n",
            encoding="utf-8",
        )
        android_path.write_text(
            json.dumps(
                {
                    "client": [
                        {"client_info": {"mobilesdk_app_id": android_id}}
                    ]
                }
            ),
            encoding="utf-8",
        )
        deploy_path.write_text(
            f'ALLOWED_FIREBASE_APP_IDS: "{android_id},{ios_id}"\n',
            encoding="utf-8",
        )

        self.assertEqual(
            verifier.validate_deploy_app_ids(source_dir),
            (android_id, ios_id),
        )

        deploy_path.write_text(
            f'ALLOWED_FIREBASE_APP_IDS: "{android_id},1:123:ios:wrong"\n',
            encoding="utf-8",
        )
        with self.assertRaises(verifier.SourceVerificationError):
            verifier.validate_deploy_app_ids(source_dir)
