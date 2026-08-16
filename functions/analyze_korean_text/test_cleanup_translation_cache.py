import io
import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import datetime, timezone
from pathlib import Path
from unittest import mock

import cleanup_translation_cache as cleanup


class _Snapshot:
    def __init__(self, data, reference):
        self._data = data
        self.reference = reference

    def to_dict(self):
        return self._data


class _Batch:
    def __init__(self):
        self.deleted = []
        self.commits = 0

    def delete(self, reference):
        self.deleted.append(reference)

    def commit(self):
        self.commits += 1


class TranslationCacheCleanupTest(unittest.TestCase):
    def test_selection_includes_source_old_version_and_invalid_ttl(self):
        valid_expiry = datetime.now(timezone.utc)
        self.assertTrue(
            cleanup.should_delete_document(
                {
                    "src": "private text",
                    "version": "current",
                    "expiresAt": valid_expiry,
                },
                "current",
            )
        )
        self.assertTrue(cleanup.should_delete_document({"version": "old"}, "current"))
        self.assertTrue(
            cleanup.should_delete_document(
                {"version": "current", "expiresAt": "not-a-timestamp"},
                "current",
            )
        )
        self.assertFalse(
            cleanup.should_delete_document(
                {
                    "t": "translation",
                    "version": "current",
                    "expiresAt": valid_expiry,
                },
                "current",
            )
        )

    def test_dry_run_never_queues_or_commits_deletes(self):
        batch = _Batch()
        valid_expiry = datetime.now(timezone.utc)
        snapshots = [
            _Snapshot({"src": "sensitive", "version": "old"}, "legacy"),
            _Snapshot(
                {
                    "t": "safe",
                    "version": "current",
                    "expiresAt": valid_expiry,
                },
                "current",
            ),
        ]

        report = cleanup.cleanup_documents(
            snapshots,
            current_version="current",
            apply=False,
            batch_factory=lambda: batch,
        )

        self.assertEqual(report, cleanup.CleanupReport(2, 1, 0, 1, 1, 1))
        self.assertEqual(batch.deleted, [])
        self.assertEqual(batch.commits, 0)

    def test_apply_deletes_only_matching_documents(self):
        batches = []

        def make_batch():
            batch = _Batch()
            batches.append(batch)
            return batch

        report = cleanup.cleanup_documents(
            [
                _Snapshot({"version": "old"}, "legacy"),
                _Snapshot(
                    {
                        "version": "current",
                        "expiresAt": datetime.now(timezone.utc),
                    },
                    "current",
                ),
            ],
            current_version="current",
            apply=True,
            batch_factory=make_batch,
        )

        self.assertEqual(report, cleanup.CleanupReport(2, 1, 1, 0, 1, 1))
        self.assertEqual(batches[0].deleted, ["legacy"])
        self.assertEqual(batches[0].commits, 1)

    def test_cli_summary_never_prints_document_values(self):
        output = io.StringIO()
        report = cleanup.CleanupReport(
            scanned=379,
            matched=379,
            deleted=0,
            source_bearing=379,
            missing_expires_at=379,
            version_mismatch=379,
        )

        with mock.patch.object(
            cleanup, "run", return_value=report
        ) as mocked_run, redirect_stdout(output):
            exit_code = cleanup.main(["--project", "test-project"])

        self.assertEqual(exit_code, 0)
        self.assertIn("mode=dry-run", output.getvalue())
        self.assertIn("source_bearing=379", output.getvalue())
        self.assertIn("missing_expires_at=379", output.getvalue())
        self.assertNotIn("src", output.getvalue())
        self.assertNotIn("translation", output.getvalue())
        mocked_run.assert_called_once_with(
            project="test-project",
            apply=False,
            main_path=mock.ANY,
            use_gcloud_credentials=False,
        )

    def test_cache_version_is_read_from_main_without_importing_runtime(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "main.py"
            source.write_text('_CACHE_VERSION = "ko-source-v3"\n', encoding="utf-8")

            self.assertEqual(cleanup.cache_version_from_source(source), "ko-source-v3")
