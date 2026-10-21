"""One relocated-package check. Validates native subsets without rendering images."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

OUT = Path(__file__).resolve().parent
BLENDER = Path('C:/dev/_tools/blender-5.2.2/blender-5.2.2-windows-x64/blender.exe')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    temporary = Path(tempfile.mkdtemp(prefix='.portability-check-', dir=OUT)).resolve()
    assert temporary.is_relative_to(OUT.resolve()) and temporary.name.startswith('.portability-check-')
    report = {'kind': 'single relocated package validation', 'imagesRerendered': False,
              'temporaryPath': str(temporary), 'passed': False}
    try:
        root = temporary / 'relocated' / 'drawing-r4'
        target = root / 'construction'
        shutil.copytree(OUT, target, ignore=shutil.ignore_patterns('.portability-check-*', '__pycache__'))
        shutil.copyfile(OUT.parent / 'manifest.json', root / 'manifest.json')
        original_images = {str(p.relative_to(OUT)): sha(p) for p in (OUT / 'renders').glob('*.png')}
        for gate in ['left', 'right', 'shrine']:
            for suffix in ['-new.blend', '-hero.png']:
                shutil.copyfile(OUT.parent / (gate + suffix), root / (gate + suffix))
        manifest_path = target / 'manifest.json'
        data = json.loads(manifest_path.read_text(encoding='utf-8'))
        for gate in data['gates']:
            gate['native'] = 'Z:/unavailable-provenance/' + gate['gate'] + '-new.blend'
        manifest_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
        saved_manifest = manifest_path.read_bytes()
        assert not (root.parents[2] / 'building-workbench-20261017/catalog.json').exists()
        assert not (root.parents[2] / 'mapping/r12-curriculum-display-policy.json').exists()
        # No --render: opening the relocated natives and validating their subsets only.
        dry = subprocess.run([str(BLENDER), '-b', '-t', '2', '--python',
                              str(target / 'render_construction.py')], cwd=root,
                             capture_output=True, text=True, encoding='utf-8', errors='replace', check=True)
        report['nativeDryRun'] = {'returncode': dry.returncode,
                                 'validatedGates': [line for line in dry.stdout.splitlines() if line.startswith('VALIDATED')]}
        assert len(report['nativeDryRun']['validatedGates']) == 3
        assert 'RENDER START' not in dry.stdout
        dry_data = json.loads(manifest_path.read_text(encoding='utf-8'))
        assert all(key.startswith('contracts/') for key in dry_data['bindings'])
        report['rendererUsedRelativeSnapshotBindings'] = True
        # Retain real image metadata from the completed render while running the independent verifier.
        manifest_path.write_bytes(saved_manifest)
        build = subprocess.run([sys.executable, '-X', 'utf8', str(target / 'build_review.py')],
                               cwd=root, capture_output=True, text=True, encoding='utf-8', check=True)
        verified = json.loads((target / 'verification.json').read_text(encoding='utf-8'))
        report['relocatedVerification'] = verified
        report['buildOutput'] = build.stdout.strip()
        report['relocatedImagesByteUnchanged'] = all(sha(target / name) == digest for name, digest in original_images.items())
        report['originalImagesByteUnchanged'] = all(sha(OUT / name) == digest for name, digest in original_images.items())
        report['nativeParentPathUsedDespiteInvalidProvenance'] = verified['passed']
        report['passed'] = (verified['passed'] and report['relocatedImagesByteUnchanged']
                            and report['originalImagesByteUnchanged'])
        assert report['passed']
    finally:
        # Delete only this generated test directory after confirming its resolved absolute boundary.
        assert temporary.is_relative_to(OUT.resolve()) and temporary.name.startswith('.portability-check-')
        shutil.rmtree(temporary)
        report['temporaryCopyRemoved'] = not temporary.exists()
        (OUT / 'portability-verification.json').write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'passed': report['passed'], 'temporaryCopyRemoved': report['temporaryCopyRemoved'],
                      'imagesRerendered': False, 'nativeDryRunGates': len(report['nativeDryRun']['validatedGates'])}))


if __name__ == '__main__':
    main()
