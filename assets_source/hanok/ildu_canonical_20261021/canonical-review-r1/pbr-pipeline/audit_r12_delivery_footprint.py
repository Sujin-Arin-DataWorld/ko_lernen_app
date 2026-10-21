"""Inventory encoded bytes and conservative decoded texture cost, not FPS.

Does not modify GLBs or assign a mobile approval. RGBA8 is the browser upload
estimate; compressed image file size is never used as GPU texture size.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path


def inspect(path):
    raw = path.read_bytes()
    magic, version, size = struct.unpack_from('<III', raw)
    if (magic, version, size) != (0x46546C67, 2, len(raw)):
        raise ValueError(f'Invalid GLB: {path}')
    offset, doc, payload = 12, None, None
    while offset < len(raw):
        length, kind = struct.unpack_from('<II', raw, offset)
        chunk = raw[offset + 8:offset + 8 + length]
        if kind == 0x4E4F534A:
            doc = json.loads(chunk)
        elif kind == 0x004E4942:
            payload = chunk
        offset += 8 + length
    if doc is None or payload is None:
        raise ValueError('Expected embedded GLB JSON and BIN')
    images = []
    for entry in doc.get('images', []):
        view = doc['bufferViews'][entry['bufferView']]
        start = view.get('byteOffset', 0)
        encoded = payload[start:start + view['byteLength']]
        if encoded[:8] != b'\x89PNG\r\n\x1a\n':
            raise ValueError('Add a format-specific memory audit before use')
        width, height, bits, color = struct.unpack_from('>IIBB', encoded, 16)
        images.append(dict(bytes=len(encoded), width=width, height=height,
                           bitDepth=bits, colorType=color,
                           rgba8BaseBytes=width * height * 4,
                           rgba8WithMipsBytes=sum(max(1, width >> i) * max(1, height >> i) * 4
                               for i in range(max(width, height).bit_length()))))
    draws = [primitive for node in doc.get('nodes', []) if 'mesh' in node
             for primitive in doc['meshes'][node['mesh']]['primitives']]
    return dict(file=str(path), sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw),
                embeddedImageBytes=sum(x['bytes'] for x in images),
                otherEncodedBytes=len(raw) - sum(x['bytes'] for x in images),
                textureRgba8BaseBytes=sum(x['rgba8BaseBytes'] for x in images),
                textureRgba8WithMipsBytes=sum(x['rgba8WithMipsBytes'] for x in images),
                textureCount=len(images), images=images,
                drawPrimitives=len(draws), triangles=sum(doc['accessors'][p['indices']]['count'] // 3
                    for p in draws if p.get('mode', 4) == 4),
                extensions=doc.get('extensionsRequired', []))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
    rows = [inspect(args.manifest.parent / row['file']) for row in manifest['owners']]
    report = dict(schemaVersion=1, sourceManifest=str(args.manifest),
                  sourceManifestSha256=hashlib.sha256(args.manifest.read_bytes()).hexdigest(),
                  assets=rows, totals={field:sum(row[field] for row in rows) for field in
                     ('bytes','embeddedImageBytes','otherEncodedBytes','textureRgba8BaseBytes',
                      'textureRgba8WithMipsBytes','textureCount','drawPrimitives','triangles')},
                  measuredOnDevice=False, mobileBudgetApproved=False,
                  limitations=['Decoded texture estimate excludes geometry, shadow maps, render targets, CPU image copies and driver overhead.',
                               'Summed cost assumes all listed independent GLBs resident; it is not a measured peak.',
                               'Encoding compression does not reduce decoded texture cost.'])
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report['totals']))


if __name__ == '__main__':
    main()
