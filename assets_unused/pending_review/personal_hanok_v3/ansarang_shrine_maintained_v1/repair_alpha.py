"""Repair identified white porch mattes without changing any source RGB values."""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image
from scipy import ndimage

PACKAGE = Path(__file__).resolve().parent
ROOT = next(p for p in PACKAGE.parents if (p / 'pubspec.yaml').is_file())
RUNTIME = ROOT / 'assets/illustrations/personal_hanok_v3/turnarounds'
REGIONS = {
    '01_front_right': {'box': (304, 295, 333, 352), 'seeds': [(320, 320)]},
    '03_rear_right': {'box': (60, 314, 105, 359), 'seeds': [(71, 343), (94, 347)]},
    '05_rear_left': {'box': (304, 294, 331, 354), 'seeds': [(317, 321)]},
    '07_front_left': {'box': (309, 294, 333, 345), 'seeds': [(321, 321)]},
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    original_dir = PACKAGE / 'originals/ansarang_turnarounds'
    corrected_dir = PACKAGE / 'alpha_corrected'
    preview_dir = PACKAGE / 'qa'
    for directory in (original_dir, corrected_dir, preview_dir):
        directory.mkdir(parents=True, exist_ok=True)
    rows = []
    for path in sorted(RUNTIME.glob('ildu_ansarangchae_[0-9][0-9]_*.png')):
        original = original_dir / path.name
        if not original.exists():
            original.write_bytes(path.read_bytes())
        source = np.array(Image.open(original).convert('RGBA'))
        output = source.copy()
        key = path.stem.removeprefix('ildu_ansarangchae_')
        region = REGIONS.get(key)
        selected = np.zeros(source.shape[:2], dtype=bool)
        if region:
            x0, y0, x1, y1 = region['box']
            rgb = source[:, :, :3].astype(np.int16)
            low, high = rgb.min(axis=2), rgb.max(axis=2)
            allowed = (low >= 145) & ((high-low) <= 44) & (source[:, :, 3] > 0)
            allowed[:y0] = False
            allowed[y1:] = False
            allowed[:, :x0] = False
            allowed[:, x1:] = False
            labels, _ = ndimage.label(allowed)
            for x, y in region['seeds']:
                label = labels[y, x]
                assert label > 0, (key, 'seed is not in the white matte', (x, y))
                selected |= labels == label
            assert 100 < selected.sum() < 1600, (key, int(selected.sum()))
            output[selected, 3] = 0
        out = corrected_dir / path.name
        if region:
            Image.fromarray(output).save(out)
            path.write_bytes(out.read_bytes())
        else:
            out.write_bytes(original.read_bytes())
        actual = np.array(Image.open(out).convert('RGBA'))
        assert actual.shape == source.shape == (512, 384, 4)
        assert np.array_equal(actual[:, :, :3], source[:, :, :3])
        assert np.array_equal(actual[~selected], source[~selected])
        assert (actual[selected, 3] == 0).all()
        if region:
            ys, xs = np.where(selected)
            bounds = [int(xs.min()), int(ys.min()), int(xs.max())+1, int(ys.max())+1]
        else:
            bounds = None
        rows.append({'file': path.name, 'original_sha256': digest(original),
                     'corrected_sha256': digest(out), 'original_bytes': original.stat().st_size,
                     'corrected_bytes': out.stat().st_size, 'size': [384,512],
                     'rgb_changed_pixels': 0, 'alpha_changed_pixels': int(selected.sum()),
                     'changed_bounds': bounds, 'region': region,
                     'runtime_updated': bool(region)})
        if region:
            x0,y0,x1,y1 = region['box']
            box = (max(0,x0-7), max(0,y0-10), min(384,x1+10), min(512,y1+10))
            for suffix,arr in [('before',source),('after',actual)]:
                im = Image.fromarray(arr).crop(box)
                for name,color in [('dark','#172833'),('light','#efe9dd')]:
                    bg = Image.new('RGBA',im.size,color)
                    bg.alpha_composite(im)
                    bg.convert('RGB').resize((im.width*8,im.height*8),Image.Resampling.NEAREST).save(
                        preview_dir/f'{key}_{suffix}_{name}.png')
    report = {'status':'alpha_only_repair_applied_in_isolated_worktree',
              'authorization':'Jin approved Python alpha-only editing in the current conversation.',
              'frames_checked':len(rows), 'frames_modified':sum(r['runtime_updated'] for r in rows),
              'rgb_changed_pixels':sum(r['rgb_changed_pixels'] for r in rows),
              'alpha_changed_pixels':sum(r['alpha_changed_pixels'] for r in rows),
              'frames':rows}
    (PACKAGE/'alpha_repair.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='frames'},ensure_ascii=False))


if __name__ == '__main__':
    main()
