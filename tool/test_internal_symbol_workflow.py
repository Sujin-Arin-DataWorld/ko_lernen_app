"""Release safety contracts for exact-build symbol publication in internal CI."""

from pathlib import Path
import unittest

import yaml


ROOT = Path(__file__).resolve().parent.parent
GATE = "vars.ANDROID_SYMBOL_EVIDENCE_GATE == 'true'"


class InternalSymbolWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        workflow = yaml.safe_load((ROOT / '.github/workflows/ci.yml').read_text())
        cls.job = workflow['jobs']['release-internal']
        cls.steps = cls.job['steps']
        cls.by_name = {step['name']: step for step in cls.steps}

    def index(self, name):
        return self.steps.index(self.by_name[name])

    def test_publication_keeps_internal_track_and_existing_release_gate(self):
        self.assertIn("vars.PLAY_INTERNAL_RELEASE_ENABLED == 'true'", self.job['if'])
        self.assertIn("needs.build.result == 'success'", self.job['if'])
        self.assertEqual(self.job['environment']['name'], 'google-play-internal')
        self.assertFalse(self.job['concurrency']['cancel-in-progress'])
        publish = self.by_name['Upload to Google Play Internal Testing']
        self.assertEqual(publish['with']['tracks'], 'internal')
        self.assertEqual(publish['with']['status'], 'completed')
        self.assertEqual(publish['with']['packageName'], 'com.sujinarin.ko_lernen_app')
        self.assertNotIn('if', publish)  # Default success(), never always().
        self.assertNotIn('continue-on-error', publish)

    def test_enabled_gate_cannot_skip_a_stage_or_ignore_failure(self):
        names = [
            'Read pinned release-toolchain versions',
            'Pin release-toolchain Java',
            'Download and verify bundletool',
            'Download and verify firebase-tools',
            'Write release-evidence tools manifest',
            'Materialise Firebase credentials',
            'Upload and verify Crashlytics symbol evidence',
            'Archive symbol evidence',
            'Preserve symbol evidence artifact',
        ]
        for name in names:
            with self.subTest(step=name):
                step = self.by_name[name]
                self.assertEqual(step['if'], GATE)
                self.assertNotIn('continue-on-error', step)
                self.assertLess(self.index(name), self.index('Upload to Google Play Internal Testing'))
                if 'run' in step:
                    self.assertIn('set -euo pipefail', step['run'])
        positions = [self.index(name) for name in names]
        self.assertEqual(positions, sorted(positions))

    def test_evidence_commands_match_the_reviewed_public_testing_lane(self):
        public = yaml.safe_load((ROOT / '.github/workflows/play_closed.yml').read_text())
        public_steps = [step for job in public['jobs'].values() for step in job.get('steps', [])]
        for name in ('Read pinned release-toolchain versions', 'Pin release-toolchain Java',
                     'Download and verify bundletool', 'Download and verify firebase-tools',
                     'Write release-evidence tools manifest', 'Materialise Firebase credentials',
                     'Upload and verify Crashlytics symbol evidence', 'Archive symbol evidence'):
            with self.subTest(step=name):
                reference = next(step for step in public_steps if step.get('name') == name)
                self.assertEqual(self.by_name[name], reference)

    def test_diagnostic_inputs_survive_symbol_failure_without_credentials(self):
        inputs = self.by_name['Preserve AAB and Dart symbols']
        self.assertLess(self.index(inputs['name']), self.index('Materialise Firebase credentials'))
        self.assertEqual(inputs['with']['if-no-files-found'], 'error')
        self.assertEqual(inputs['with']['path'].splitlines(), [
            'build/app/outputs/bundle/release/app-release.aab',
            'build/app/outputs/bundle/release/app-release.aab.sha256',
            'build/app/outputs/symbols/**',
        ])
        evidence = self.by_name['Preserve symbol evidence artifact']
        self.assertEqual(evidence['with']['retention-days'], 90)
        self.assertEqual(evidence['with']['if-no-files-found'], 'error')
        self.assertEqual(evidence['with']['path'], '${{ steps.archive-evidence.outputs.archive-dir }}')
        cleanup = self.by_name['Remove temporary Firebase publisher credential']
        self.assertEqual(cleanup['if'], 'always()')
        self.assertEqual(cleanup['run'].strip(), 'rm -f -- "$RUNNER_TEMP/firebase-sa.json"')


if __name__ == '__main__':
    unittest.main()
