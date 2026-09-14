"""Extract approved chroma backing by changing alpha only; never repaint RGB."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image
from scipy import ndimage

PACKAGE = Path(__file__).resolve().parent
GENERATED = Path(r'C:\Users\vjinn\.codex\generated_images\01a0a003-38d5-73e2-bfdd-da442cfdbd91')
SOURCES = {
    'ansarangchae': ('exec-5fc6d1d6-69e1-4433-a4ce-6687dcdd693a.png', 'ansarang-v2.txt'),
    'sadangmun': ('exec-6d2c06a1-8a9a-4366-a95c-9ed4f7962109.png', 'gate-v2.txt'),
    'sadang': ('exec-522a145c-3e20-4ec5-a927-5f2b3a40e6c0.png', 'shrine-v1.txt'),
}
PREVIOUS = {
    'ansarangchae-v1-checkerboard.png': 'exec-383ead60-27b2-4cb3-b24d-9f2e30f4215f.png',
    'sadangmun-v1-worn.png': 'exec-0f1b69d0-11cd-4c97-8cdb-43e9777bb2dd.png',
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    locks = [PACKAGE.parent / 'canonical' / b / 'CANONICAL_LOCK.json' for b in SOURCES]
    if any(path.exists() for path in locks):
        raise SystemExit('Approved masters are frozen. Use a separate revision directory for new extraction.')
    for directory in ('raw', 'masters', 'qa'):
        (PACKAGE / directory).mkdir(exist_ok=True)
    for name, generated in PREVIOUS.items():
        target = PACKAGE / 'raw' / name
        if not target.exists():
            target.write_bytes((GENERATED / generated).read_bytes())
    records = []
    for building, (generated, prompt) in SOURCES.items():
        raw = PACKAGE / 'raw' / f'{building}-chroma.png'
        if not raw.exists():
            raw.write_bytes((GENERATED / generated).read_bytes())
        source = np.asarray(Image.open(raw).convert('RGB'))
        rgb = source.astype(np.int16)
        # Grow only from pure chroma seeds. Red/blue mixed pigment edges can
        # also look purple, so a global hue mask would damage the Taegeuk.
        candidate = (rgb[:, :, 0] - rgb[:, :, 1] > 10) & (rgb[:, :, 2] - rgb[:, :, 1] > 10)
        # Small shaded openings can contain darker key color (e.g. the gap
        # below Ansarangchae's right porch); retain strong chroma seeds there.
        pure_chroma = (rgb[:, :, 0] > 200) & (rgb[:, :, 2] > 170) & (rgb[:, :, 1] < 80)
        labels, _ = ndimage.label(candidate)
        background_labels = np.unique(labels[pure_chroma])
        background_labels = background_labels[background_labels != 0]
        backing = np.isin(labels, background_labels)
        keep = ~backing
        distance = ndimage.distance_transform_edt(keep)
        alpha = np.clip((distance - 0.5) * 255, 0, 255).astype(np.uint8)
        output = np.dstack((source, alpha))
        assert np.array_equal(output[:, :, :3], source)
        assert np.all(alpha[backing] == 0)
        assert all(alpha[y, x] == 0 for y, x in [(0, 0), (0, -1), (-1, 0), (-1, -1)])
        if building == 'ansarangchae':
            assert alpha[590, 1330] == 0, 'The open right porch must remain transparent'
            assert alpha[759, 1419] == 0, 'The small gap below the side porch must be transparent'
            assert alpha[590, 1270] == 255, 'The front right post must remain opaque'
            assert alpha[590, 1380] == 255, 'The rear right post must remain opaque'
            assert alpha[745, 1330] == 255, 'The side porch floor must remain opaque'
        target = PACKAGE / 'masters' / f'{building}_maintained_front_right.png'
        image = Image.fromarray(output)
        image.save(target)
        bbox = image.getbbox()
        assert bbox[0] > 0 and bbox[1] > 0 and bbox[2] < image.width and bbox[3] < image.height
        for label, color in [('dark', (27, 35, 46, 255)), ('light', (244, 239, 228, 255))]:
            proof = Image.new('RGBA', image.size, color)
            proof.alpha_composite(image)
            proof.convert('RGB').save(PACKAGE / 'qa' / f'{building}-master-{label}.png')
        records.append({
            'building': building, 'status': 'review_candidate_not_runtime_promoted',
            'file': str(target.relative_to(PACKAGE)).replace('\\', '/'),
            'raw': str(raw.relative_to(PACKAGE)).replace('\\', '/'),
            'prompt': f'prompts/{prompt}', 'generated_source': str(GENERATED / generated),
            'raw_sha256': sha(raw), 'sha256': sha(target), 'bytes': target.stat().st_size,
            'size': list(image.size), 'mode': image.mode, 'alpha_bbox': list(bbox),
            'transparent_pixels': int((alpha == 0).sum()),
            'partial_alpha_pixels': int(((alpha > 0) & (alpha < 255)).sum()),
            'opaque_pixels': int((alpha == 255).sum()),
            'rgb_changed_by_alpha_extraction': int(np.any(output[:, :, :3] != source, axis=2).sum()),
            'visible_magenta_backing_pixels': int(((alpha > 0) & pure_chroma).sum()),
            'protected_pigment_pixels': int((candidate & ~backing).sum()),
            'upscaled': False,
        })
    manifest = {
        'status': 'three_maintained_masters_ready_for_visual_review',
        'runtime_promotion': False, 'construction_stage_production': False,
        'method': 'Built-in image generation redraws materials; user-authorized Python changes only alpha.',
        'alpha_extraction': 'Magenta key with one-pixel inner edge alpha; generated RGB remains identical.',
        'masters': records,
    }
    (PACKAGE / 'MANIFEST.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps([{'building': r['building'], 'size': r['size'], 'alpha0': r['transparent_pixels'], 'rgb_changed': r['rgb_changed_by_alpha_extraction']} for r in records]))


if __name__ == '__main__':
    main()
