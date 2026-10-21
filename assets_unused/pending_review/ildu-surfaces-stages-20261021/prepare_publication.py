"""Build a portable review package without checking out or changing the app repo."""
import argparse
import hashlib
import json
import shutil
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent
PREFIX = Path('assets_unused/pending_review/ildu-surfaces-stages-20261021')
GATES = ('left', 'right', 'shrine')
VIEWS = ('hero', 'front', 'side', 'back', 'plan', 'eaves', 'underside')
ROOT_FILES = (
    'README.md', 'SURFACE_REVIEW.md', 'WORK.md', 'CONTINUATION.md', 'index.html',
    'build_gates.py', 'measured_assemblies.py', 'audit_geometry.py',
    'validate_drawings.py', 'verify_surface_package.py', 'extract_reference_textures.py',
    'fetch_drawing_sources.py', 'compare_surface_metrics.py', 'prepare_publication.py',
    'manifest.json', 'validation-summary.json', 'surface-package-verification.json',
    'surface-r6-comparison.json',
)
OMIT = {'__pycache__', 'rejected-initial', 'rejected-first', 'rejected-stone'}
ESTATE_OMIT = {'ildu-estate-yard-wall-r1.blend', 'geometry-before.json',
               'geometry-after.json', 'bindings-before.json', 'bindings-after.json'}


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def build(out):
    out.mkdir(parents=True, exist_ok=True)
    files = set(ROOT_FILES)
    for gate in GATES:
        files.update(f'{gate}-{view}.png' for view in VIEWS)
        files.update((f'{gate}-new.blend', f'{gate}-validation.json',
                      f'geometry-before-{gate}.json', f'geometry-after-{gate}.json'))
    for folder in ('surface-before', 'surface-r5', 'surface-r6b-before-wood'):
        files.update(f'{folder}/{g}-{v}.png' for g in GATES for v in VIEWS)
    for folder in ('sources', 'reference-textures', 'construction', 'estate-yard-wall-r1'):
        for path in (ROOT / folder).rglob('*'):
            rel = path.relative_to(ROOT)
            if not path.is_file() or set(rel.parts) & OMIT or any('rejected' in part.lower() for part in rel.parts):
                continue
            if path.suffix.lower() not in {'.json', '.py', '.md', '.html', '.png', '.jpg', '.blend'}:
                continue
            if folder == 'estate-yard-wall-r1' and (path.name in ESTATE_OMIT or (path.suffix.lower() == '.blend' and path.stat().st_size >= 100 * 1024 * 1024)):
                continue
            files.add(rel.as_posix())
    for name in sorted(files):
        src, dst = ROOT / name, out / name
        assert src.is_file(), name
        assert src.stat().st_size < 100 * 1024 * 1024, f'GitHub file limit: {name}'
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        assert sha(src) == sha(dst), name
    # Contract snapshots and the package manifest verify original bytes.
    (out / '.gitattributes').write_text('* -text\n*.blend binary\n*.png binary\n*.jpg binary\n', encoding='utf-8')
    manifest = read(out / 'manifest.json')
    for native in manifest['nativeFiles']:
        native['path'] = Path(native['path']).name
    for render in manifest['renders']:
        render['file'] = Path(render['file']).name
    write(out / 'manifest.json', manifest)
    reports = read(out / 'validation-summary.json')
    for report in reports:
        report['file'] = Path(report['file']).name
        write(out / f"{report['gate']}-validation.json", report)
    write(out / 'validation-summary.json', reports)
    receipt = read(out / 'reference-textures/source-receipt.json')
    for item in receipt['extractedImages']:
        item['path'] = 'reference-textures/' + Path(item['path']).name
    write(out / 'reference-textures/source-receipt.json', receipt)
    source_index = read(out / 'sources/source-index.json')
    for item in source_index:
        item['file'] = 'sources/' + item['id'] + '.jpg'
    write(out / 'sources/source-index.json', source_index)
    records = [{'path': f.relative_to(out).as_posix(), 'bytes': f.stat().st_size, 'sha256': sha(f)}
               for f in sorted(out.rglob('*')) if f.is_file() and f.name != 'package-files.json']
    write(out / 'package-files.json', {'kind': 'review-only; not Flutter runtime', 'files': records,
        'largeEstateNative': 'Local candidate retained; use the packed material patch and canonical R12 source to reconstruct.',
        'nativeGeometryEdited': False, 'appIntegrated': False})
    return {'path': str(out), 'files': len(records), 'bytes': sum(x['bytes'] for x in records)}


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.paths = []

    def handle_starttag(self, tag, attrs):
        self.paths.extend(v for k, v in attrs if k in ('src', 'href') and v)


def verify(out):
    records = read(out / 'package-files.json')['files']
    for row in records:
        path = out / row['path']
        assert path.is_file() and path.stat().st_size == row['bytes'] and sha(path) == row['sha256'], row['path']
    for page in out.rglob('*.html'):
        links = Links()
        links.feed(page.read_text(encoding='utf-8'))
        for link in links.paths:
            url = urlsplit(link)
            if url.scheme or url.netloc or not url.path or '__' in url.path:
                continue
            assert (page.parent / unquote(url.path)).exists(), (page.relative_to(out), link)
    from PIL import Image
    for path in out.rglob('*.png'):
        with Image.open(path) as image:
            image.verify()
    return {'passed': True, 'files': len(records)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT / '.git/publication-work' / PREFIX)
    opts = parser.parse_args()
    result = build(opts.out)
    result.update(verify(opts.out))
    print(json.dumps(result, ensure_ascii=False, indent=2))
