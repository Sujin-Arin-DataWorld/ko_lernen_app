"""The recovery validator must scope only changes after its chosen base."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).with_name('validate_package.py')
spec = importlib.util.spec_from_file_location('manuscript_validation', SOURCE)
validation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validation)


class RecoveryScopeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.repo = Path(self.tmp.name)
        self.original_repo = validation.REPO
        validation.REPO = self.repo
        self.addCleanup(setattr, validation, 'REPO', self.original_repo)
        self.git('init', '-q')
        (self.repo / 'app.dart').write_text('before\n')
        self.git('add', 'app.dart')
        self.git('-c', 'user.name=Scope test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'baseline')
        self.base = self.git('rev-parse', 'HEAD').strip()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args], text=True)

    def test_allows_manuscript_changes_from_selected_base(self):
        doc = self.repo / 'docs/learning/ildu-season1-manuscripts-20261105/README.md'
        doc.parent.mkdir(parents=True)
        doc.write_text('manuscript\n')
        self.assertEqual(validation.scope_violations(self.base), [])

    def test_rejects_untracked_application_file(self):
        (self.repo / 'new_app.dart').write_text('runtime\n')
        self.assertEqual(validation.scope_violations(self.base), ['new_app.dart'])

    def test_rejects_tracked_application_change(self):
        (self.repo / 'app.dart').write_text('changed\n')
        self.assertEqual(validation.scope_violations(self.base), ['app.dart'])

    def test_excludes_upstream_changes_before_recovery_base(self):
        (self.repo / 'app.dart').write_text('upstream\n')
        self.git('-c', 'user.name=Scope test', '-c', 'user.email=test@example.invalid', 'commit', '-qam', 'upstream')
        base = self.git('rev-parse', 'HEAD').strip()
        self.assertEqual(validation.scope_violations(base), [])

    def test_rejects_runtime_renamed_into_document_directory(self):
        destination = self.repo / 'docs/learning/ildu-season1-manuscripts-20261105/moved.md'
        destination.parent.mkdir(parents=True)
        self.git('mv', 'app.dart', str(destination.relative_to(self.repo)))
        self.assertEqual(validation.scope_violations(self.base), ['app.dart'])

    def test_rejects_staged_runtime_change_hidden_by_worktree_bytes(self):
        source = self.repo / 'app.dart'
        source.write_text('staged runtime change\n')
        self.git('add', 'app.dart')
        source.write_text('before\n')
        self.assertEqual(validation.scope_violations(self.base), ['app.dart'])


if __name__ == '__main__':
    unittest.main()
