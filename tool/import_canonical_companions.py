"""Import the approved family without altering source bytes; verify every hash."""
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
FILES = [
    ('백호정본채택', 'exec-d9e47a8d-6278-485e-a4f3-effc288da9a4.png', 'taego.png', '9dd03e4c62fb4513b5c97f788d48189bce939e510d39a1b34a2bd9b0415bfbe2', 'full_body'),
    ('백호정본채택', 'exec-da0092d4-29ab-4c7d-99ac-3d6628855a4e.png', 'taego_guide.png', '8eace5ec15342a2d816f095bd1953aa73c22cdf4c9c1b8fe06a235b458ac4f98', 'inward_guide'),
    ('백호정본채택', 'exec-2283fd5e-881e-4887-b4e5-528dd38f289c.png', 'taego_seated.png', '444eed7e6e7188432b5fe0c6e125dc5790d84a71c93255e9149396b12ee20a2f', 'seated'),
    ('백호정본채택', 'exec-59fe7aff-0d16-40cf-8904-8f433de124e4.png', 'taego_portrait.png', '8d7137edfe97df4c63b5048962c6660e189c9ad37b6031799b152abf38065479', 'portrait'),
    ('까치정본', 'exec-75fbc678-9c71-4a8f-af27-8920e62b9896.png', 'joy.png', 'c1d79c59ea954d2bacee01abe48d4283d6e8ee7dc3fd47a9a30d80b58742a588', 'full_body'),
    ('까치정본', 'exec-fb0af650-849a-4385-8c42-520916394aea.png', 'joy_guide.png', '0d793e51b645df67603b90b6fcedb3a358f03f1d714838f8d9ccf1ab8b3228cc', 'inward_guide'),
    ('까치정본', 'exec-dbbba68f-00b2-451c-8dc1-d24169650b4f.png', 'joy_celebrate.png', 'f70f5fcee6770a0953071afb4cd526ec88dce3fef17ec1cf313ac4328e7a4db5', 'celebration'),
    ('까치정본', 'exec-257d9975-6169-40f6-9211-ae5befad4040.png', 'joy_portrait.png', '15c3c966c0ae190c11777977587943cdef1975d7e186349b4dc7408987749d29', 'portrait'),
    ('도깨비', 'making_money.mp4', 'making_money.mp4', '6e850b717ec285fd1d9be057da361fed629c178e750a15c77b592cbda6f91ff5', 'confirmed_daily_first_reward'),
]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    art = APP / 'assets/illustrations/companions/canonical'
    movie = APP / 'assets/video/rewards'
    art.mkdir(parents=True, exist_ok=True)
    movie.mkdir(parents=True, exist_ok=True)
    manifest = {'version': 1, 'approved': '2026-10-04', 'selection_ids': ['tiger', 'magpie'], 'files': []}
    for folder, filename, runtime, sha, role in FILES:
        source = args.source / folder / filename
        if digest(source) != sha:
            raise ValueError(f'Unapproved source bytes: {source}')
        dest = (movie if runtime.endswith('.mp4') else art) / runtime
        shutil.copyfile(source, dest)
        assert digest(dest) == sha
        manifest['files'].append({'source': f'{folder}/{filename}', 'asset': dest.relative_to(APP).as_posix(), 'sha256': sha, 'role': role})
    poster = art / 'making_money_poster.png'
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(movie / 'making_money.mp4'), '-frames:v', '1', str(poster)], check=True)
    manifest['files'].append({'asset': poster.relative_to(APP).as_posix(), 'sha256': digest(poster), 'role': 'poster', 'derived_from': 'assets/video/rewards/making_money.mp4', 'frame': 0})
    (APP / 'docs/assets/CANONICAL_COMPANIONS_20261004.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Verified and imported {len(FILES)} originals and frame-zero poster.')

if __name__ == '__main__':
    main()
