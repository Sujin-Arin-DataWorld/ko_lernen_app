#!/usr/bin/env python3
"""Validate real iOS captures and emit their immutable release receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY_ROOT / 'tool'))

from check_app_store_screenshots import _read_png_metadata, validate_directory  # noqa: E402


EXPECTED_FILES = [
    '01-learn-catalog.png',
    '02-learning-phases.png',
    '03-phase-task.png',
    '04-vocabulary-packs.png',
    '05-real-life-scenario.png',
]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--artifact-root', required=True, type=Path)
    parser.add_argument('--expected-sha', required=True)
    parser.add_argument('--workflow-run-url', required=True)
    arguments = parser.parse_args()

    if not re.fullmatch(r'[0-9a-f]{40}', arguments.expected_sha):
        raise SystemExit('expected SHA must be 40 lowercase hexadecimal characters')
    actual_sha = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=REPOSITORY_ROOT, text=True
    ).strip()
    if actual_sha != arguments.expected_sha:
        raise SystemExit(f'checked out SHA {actual_sha} != expected {arguments.expected_sha}')

    manifest_path = arguments.artifact_root / 'device-manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    if manifest.get('runtimeVersion') != '26.2':
        raise SystemExit('capture runtime is not iOS 26.2')
    executable = manifest.get('appExecutable')
    if (
        not isinstance(executable, dict)
        or executable.get('bundleId') != 'com.hangulsori.app'
        or not isinstance(executable.get('bytes'), int)
        or executable['bytes'] <= 0
        or re.fullmatch(r'[0-9a-f]{64}', str(executable.get('sha256'))) is None
    ):
        raise SystemExit('capture manifest has no valid immutable app executable')

    captures: dict[str, dict[str, list[dict[str, object]]]] = {}
    for locale in ('de', 'en'):
        captures[locale] = {}
        for target in ('iphone-6.9', 'ipad-13'):
            folder = arguments.artifact_root / 'captures' / locale / target
            issues = validate_directory(folder, target)
            actual_files = sorted(path.name for path in folder.glob('*.png'))
            if actual_files != EXPECTED_FILES:
                issues.append(
                    f'{locale}/{target}: expected {EXPECTED_FILES}, found {actual_files}'
                )
            if issues:
                raise SystemExit('\n'.join(issues))
            rows = []
            for name in actual_files:
                path = folder / name
                width, height, color_type, has_transparency = _read_png_metadata(path)
                rows.append(
                    {
                        'file': name,
                        'width': width,
                        'height': height,
                        'pngColorType': color_type,
                        'hasTransparency': has_transparency,
                        'bytes': path.stat().st_size,
                        'sha256': _sha256(path),
                    }
                )
            captures[locale][target] = rows

    xcode = subprocess.check_output(['xcodebuild', '-version'], text=True).strip()
    sdk = subprocess.check_output(
        ['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version'], text=True
    ).strip()
    if not xcode.startswith('Xcode 26.3\n') or sdk != '26.2':
        raise SystemExit(f'unexpected toolchain: {xcode!r}, simulator SDK {sdk!r}')

    receipt = {
        'schemaVersion': 1,
        'sourceSha': actual_sha,
        'sourceBranch': 'main',
        'workflowRunUrl': arguments.workflow_run_url,
        'capturedAtUtc': datetime.now(timezone.utc).isoformat(),
        'captureKind': 'real-ios-simulator-production-routes',
        'xcode': xcode.splitlines()[0],
        'simulatorSdk': sdk,
        'deviceManifest': manifest,
        'captures': captures,
        'validation': {
            'validator': 'tool/check_app_store_screenshots.py',
            'result': 'passed',
            'rgbPngOnly': True,
        },
    }
    destination = arguments.artifact_root / 'receipt.json'
    destination.write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
    )
    print(f'Wrote {destination}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
