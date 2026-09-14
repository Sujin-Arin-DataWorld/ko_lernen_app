"""Copy real generated stages and extract only their chroma alpha; never repaint RGB."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs/assets/ildu_ansarang_shrine_construction_20260914'
BASE = ROOT / 'assets_unused/pending_review/personal_hanok_v3'
RAW = BASE / 'construction_ansarang_shrine_v1/raw'
RUNTIME = ROOT / 'assets/illustrations/personal_hanok_v3/construction'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snake(value):
    return re.sub(r'(?<!^)(?=[A-Z])', '_', value).lower()


def main():
    data = json.loads((DOCS / 'construction_design.json').read_text(encoding='utf-8'))
    calls = json.loads((DOCS / 'generation_calls.json').read_text(encoding='utf-8'))['calls']
    records = []
    for building in data['buildings']:
        bid = building['id']
        target_dir = RUNTIME / bid
        target_dir.mkdir(parents=True, exist_ok=True)
        for step in building['steps']:
            name = f"stage_{step['number']:02d}_{snake(step['id'])}.png"
            target = target_dir / name
            final = step['id'] == 'complete'
            if final:
                source = ROOT / building['canonical']['assetPath']
                if digest(source) != building['canonical']['sha256']:
                    raise ValueError('Approved master changed: ' + bid)
                if target.exists() and digest(target) != digest(source):
                    raise ValueError('A different final PNG already exists: ' + str(target))
                shutil.copyfile(source, target)
                rgb_changes = 0
                extraction = 'exact_approved_bytes'
                raw = source
            else:
                selected = [c for c in calls if c['building'] == bid and c['number'] == step['number'] and c.get('status') == 'selected_after_agent_visual_review']
                if not selected:
                    continue
                if len(selected) != 1:
                    raise ValueError('Multiple selected outputs: ' + name)
                call = selected[0]
                source = Path(call['generatedPath'])
                raw = RAW / bid / name
                raw.parent.mkdir(parents=True, exist_ok=True)
                if raw.exists() and digest(raw) != digest(source):
                    raise ValueError('Retain older raw revision separately: ' + str(raw))
                shutil.copyfile(source, raw)
                with Image.open(raw) as im:
                    pixels = np.asarray(im.convert('RGBA'))
                    has_alpha = im.mode == 'RGBA' and np.any(pixels[:, :, 3] < 255)
                if has_alpha:
                    shutil.copyfile(raw, target)
                    extraction = 'generated_alpha_preserved'
                else:
                    rgb = pixels[:, :, :3].astype(np.int16)
                    candidate = (rgb[:, :, 0] - rgb[:, :, 1] > 10) & (rgb[:, :, 2] - rgb[:, :, 1] > 10)
                    seeds = (rgb[:, :, 0] > 200) & (rgb[:, :, 2] > 170) & (rgb[:, :, 1] < 80)
                    if seeds.mean() < .015:
                        raise ValueError('Missing clear chroma backing; do not guess extraction: ' + str(raw))
                    labels, _ = ndimage.label(candidate)
                    exterior = np.unique(labels[seeds])
                    exterior = exterior[exterior != 0]
                    backing = np.isin(labels, exterior)
                    distance = ndimage.distance_transform_edt(~backing)
                    alpha = np.clip((distance - .5) * 255, 0, 255).astype(np.uint8)
                    output = np.dstack((pixels[:, :, :3], alpha))
                    Image.fromarray(output).save(target)
                    extraction = 'alpha_only_seeded_chroma'
                with Image.open(target) as im:
                    output = np.asarray(im.convert('RGBA'))
                rgb_changes = int(np.any(output[:, :, :3] != pixels[:, :, :3], axis=2).sum())
                if rgb_changes:
                    raise ValueError('RGB was altered')
            with Image.open(target) as im:
                rgba = np.asarray(im.convert('RGBA'))
                record = {'building': bid, 'number': step['number'], 'stageId': step['id'],
                          'file': target.relative_to(ROOT).as_posix(), 'sha256': digest(target),
                          'bytes': target.stat().st_size, 'size': list(im.size), 'mode': im.mode,
                          'raw': raw.relative_to(ROOT).as_posix(), 'rawSha256': digest(raw),
                          'extraction': extraction, 'rgbChangedPixels': rgb_changes,
                          'transparentPixels': int((rgba[:, :, 3] == 0).sum()),
                          'finalExactApprovedBytes': final}
                if not record['transparentPixels']:
                    raise ValueError('Stage has no transparency: ' + str(target))
                records.append(record)
    report = {'method': 'built-in image generation; alpha-only extraction if needed; exact master copy for final',
              'stageCount': len(records), 'expectedStageCount': 34,
              'completed': len(records) == 34, 'records': records}
    (DOCS / 'ART_MANIFEST.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'stagesWritten': len(records), 'expected': 34,
                      'rgbChangedPixels': sum(r['rgbChangedPixels'] for r in records),
                      'finalsMatchApproved': all(r['sha256'] == r['rawSha256'] for r in records if r['finalExactApprovedBytes'])}))


if __name__ == '__main__':
    main()
