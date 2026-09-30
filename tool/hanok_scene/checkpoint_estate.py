"""Inventory Blender dependencies or make a byte-preserving source archive.

Blender: blender -b --python tool/hanok_scene/checkpoint_estate.py
Python:  python tool/hanok_scene/checkpoint_estate.py
Neither mode changes the native scene.
"""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
N = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
OUT = N / 'checkpoint'
OUT.mkdir(exist_ok=True)


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


try:
    import bpy
except ImportError:
    bpy = None

if bpy is not None:
    records = []
    for filename in ('estate-fabric.blend', 'detail-redraw.blend'):
        scene = N / filename
        bpy.ops.wm.open_mainfile(filepath=str(scene))
        images = []
        for image in bpy.data.images:
            if image.source != 'FILE':
                continue
            path = Path(bpy.path.abspath(image.filepath))
            packed = bool(image.packed_file or image.packed_files)
            row = {'name': image.name, 'filepath': image.filepath,
                   'resolved': str(path), 'packed': packed, 'exists': path.is_file()}
            if path.is_file():
                row.update(bytes=path.stat().st_size, sha256=sha(path))
            images.append(row)
        libraries = [bpy.path.abspath(lib.filepath) for lib in bpy.data.libraries]
        assert not libraries, 'Linked Blender libraries need explicit preservation'
        records.append({'file': filename, 'sha256': sha(scene),
                        'bytes': scene.stat().st_size, 'images': images})
    (OUT / 'native-dependencies.json').write_text(
        json.dumps(records, ensure_ascii=False, indent=2), encoding='utf8')
    external = {row['resolved']: row for rec in records for row in rec['images']
                if not row['packed']}
    missing = [row['resolved'] for row in external.values() if not row['exists']]
    print(json.dumps({'scenes': len(records), 'externalImages': len(external),
                      'externalBytes': sum(row.get('bytes', 0) for row in external.values()),
                      'missing': missing}), flush=True)
    assert not missing, missing
else:
    records = json.loads((OUT / 'native-dependencies.json').read_text(encoding='utf8'))
    archive = OUT / 'estate-source-20260930.zip'
    if '--split-existing' in sys.argv:
        report = json.loads((OUT / 'source-checkpoint.json').read_text(encoding='utf8'))
        assert sha(archive) == report['sha256']
        report['parts'] = []
        with archive.open('rb') as source:
            index = 0
            while chunk := source.read(90 * 1024 * 1024):
                part = OUT / (archive.name + '.part' + str(index).zfill(2))
                part.write_bytes(chunk)
                report['parts'].append({'file': part.name, 'bytes': len(chunk),
                                        'sha256': sha(part)})
                index += 1
        (OUT / 'source-checkpoint.json').write_text(json.dumps(report, indent=2), encoding='utf8')
        print(json.dumps(report), flush=True)
        sys.exit(0)
    inputs = {}
    for rec in records:
        path = N / rec['file']
        assert sha(path) == rec['sha256']
        inputs['native/' + rec['file']] = path
        for row in rec['images']:
            if row['packed']:
                continue
            path = Path(row['resolved'])
            assert path.is_file() and sha(path) == row['sha256'], path
            name = 'images/' + row['sha256'] + path.suffix.lower()
            row['archiveFile'] = name
            inputs[name] = path
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for name, path in sorted(inputs.items()):
            z.write(path, name)
        z.writestr('native-dependencies.json', json.dumps(records, ensure_ascii=False, indent=2))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        for name, path in inputs.items():
            assert hashlib.sha256(z.read(name)).hexdigest() == sha(path), name
    report = {'archive': archive.name, 'sha256': sha(archive),
              'bytes': archive.stat().st_size, 'members': len(inputs),
              'sceneSha256': records[0]['sha256'],
              'note': 'Exact native bytes and external image bytes. Historical scenes/GLBs are kept locally.'}
    (OUT / 'source-checkpoint.json').write_text(json.dumps(report, indent=2), encoding='utf8')
    (OUT / 'native-dependencies.json').write_text(
        json.dumps(records, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps(report), flush=True)
