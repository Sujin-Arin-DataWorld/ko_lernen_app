"""Preserve exact artwork DEX/TOC evidence before the strict release gate runs.

Only module DEX, compiled manifests, TOC, and identity metadata are copied.
The APK set and its measurement signing keystore are never published here.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import tempfile
import zipfile


def digest_file(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def preserve_entry(archive, name, target, origin):
    entry = archive.getinfo(name)
    target.parent.mkdir(parents=True, exist_ok=True)
    sha = hashlib.sha256()
    actual_bytes = 0
    with archive.open(entry) as source, target.open('wb') as output:
        while chunk := source.read(65536):
            output.write(chunk)
            sha.update(chunk)
            actual_bytes += len(chunk)
    return {
        'origin': origin, 'entry': name, 'evidence': target.name,
        'zipDeclaredBytes': entry.file_size, 'actualBytes': actual_bytes,
        'sha256': sha.hexdigest(),
    }


def capture(aab, apks, output, source_sha=None):
    if source_sha is not None and not re.fullmatch(r'[0-9a-f]{40}', source_sha):
        raise ValueError('source-sha must be an exact Git commit identity')
    output.mkdir(parents=True, exist_ok=True)
    rows = []
    code_entries = []
    with zipfile.ZipFile(aab) as bundle:
        selected = [name for name in bundle.namelist() if name.startswith('c_artwork/')
                    and (name.endswith('.dex') or name == 'c_artwork/manifest/AndroidManifest.xml')]
        for index, name in enumerate(sorted(selected)):
            suffix = '.dex' if name.endswith('.dex') else '.manifest.pb'
            rows.append(preserve_entry(bundle, name, output / f'aab-{index}{suffix}', 'AAB'))
        code_entries.extend({'origin': 'AAB', 'entry': name} for name in bundle.namelist()
                            if name.startswith('c_artwork/')
                            and (name.endswith('.dex') or name.startswith('c_artwork/lib/')))
    with zipfile.ZipFile(apks) as archive:
        rows.append(preserve_entry(archive, 'toc.pb', output / 'toc.pb', 'APKS'))
        artwork_apks = sorted(name for name in archive.namelist()
                              if Path(name).name.startswith('c_artwork-') and name.endswith('.apk'))
        if not artwork_apks:
            raise ValueError('No measured artwork APKs found for diagnostics')
        for apk_index, name in enumerate(artwork_apks):
            # Keep large artwork payloads out of memory and out of diagnostics.
            with tempfile.TemporaryFile() as temporary:
                with archive.open(name) as source:
                    shutil.copyfileobj(source, temporary)
                temporary.seek(0)
                with zipfile.ZipFile(temporary) as apk:
                    for dex_index, entry in enumerate(sorted(apk.namelist())):
                        if entry.endswith('.dex') or entry.startswith('lib/'):
                            code_entries.append({'origin': name, 'entry': entry})
                        if entry.endswith('.dex') or entry == 'AndroidManifest.xml':
                            suffix = '.dex' if entry.endswith('.dex') else '.manifest.bin'
                            target = output / f'apk-{apk_index}-{dex_index}{suffix}'
                            rows.append(preserve_entry(apk, entry, target, name))
    report = {
        'schemaVersion': 1, 'sourceSha': source_sha, 'module': 'c_artwork',
        'aabSha256': digest_file(aab), 'apksSha256': digest_file(apks),
        'artworkApkPaths': artwork_apks, 'entries': rows, 'codeEntries': code_entries,
        'containsCredentials': False,
        'meaning': 'Diagnostic bytes only; this does not approve a new code identity or bypass the release gate.',
    }
    (output / 'inventory.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--aab', type=Path, required=True)
    parser.add_argument('--apks', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--source-sha')
    args = parser.parse_args()
    report = capture(args.aab, args.apks, args.output, args.source_sha)
    print(json.dumps(report))


if __name__ == '__main__':
    main()
