"""Copy selected packed native R12 images without modifying the source blend."""

import bpy
import hashlib
import json
import shutil
from pathlib import Path

OUT = Path(__file__).resolve().parent / 'reference-textures'
OUT.mkdir(exist_ok=True)
NAMES = {
    'wood-long-members-trim-v1.png': 'wood-long-members-trim-v1.png',
    'wood-endgrain-atlas-v1.png': 'wood-endgrain-atlas-v1.png',
    'tile-blue-charcoal-v1.png': 'tile-blue-charcoal-v1.png',
    'gye-clay-matte-v26.png': 'gye-clay-matte-v26.png',
    'gye-fieldstone-brush-v26.png': 'gye-fieldstone-brush-v26.png',
}
records = []
for source_name, output_name in NAMES.items():
    image = next((im for im in bpy.data.images if im.name == source_name), None)
    if image is None:
        raise RuntimeError(f'Missing source image: {source_name}')
    output = OUT / output_name
    if image.packed_file:
        output.write_bytes(bytes(image.packed_file.data))
    else:
        shutil.copyfile(bpy.path.abspath(image.filepath), output)
    records.append({
        'sourceImage': image.name,
        'path': str(output),
        'width': image.size[0],
        'height': image.size[1],
        'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
    })
source = Path(bpy.data.filepath)
with source.open('rb') as stream:
    source_sha = hashlib.file_digest(stream, 'sha256').hexdigest()
receipt = {
    'sourceBlend': str(source),
    'sourceBlendSha256': source_sha,
    'extractedImages': records,
}
(OUT / 'source-receipt.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(records, ensure_ascii=False))
