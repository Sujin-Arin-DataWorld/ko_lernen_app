"""Read-only audit of original research asset bytes and PNG dimensions."""
import hashlib
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
directory = root/'assets/illustrations/dancheong_studio/v1'
manifest = json.loads((directory/'manifest.json').read_text(encoding='utf-8'))
for asset in manifest['assets']:
    file = directory/asset['file']
    data = file.read_bytes()
    assert len(data) == asset['bytes']
    assert hashlib.sha256(data).hexdigest() == asset['sha256']
    source = Path(asset['source'])
    if source.exists():
        assert data == source.read_bytes()
    with Image.open(file) as image:
        image.verify()
    with Image.open(file) as image:
        print(f"{file.name}: {image.width}x{image.height}, SHA-256 verified")
