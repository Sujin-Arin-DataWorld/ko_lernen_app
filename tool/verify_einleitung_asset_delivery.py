"""Verify real Flutter web responses against recorded whole image assets."""

import argparse
import hashlib
import json
from pathlib import Path
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', default='http://127.0.0.1:7392')
    parser.add_argument('--output', default='tool/einleitung_http_verification.json')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((root / 'tool/einleitung_generated_assets.json').read_text(encoding='utf-8'))
    for item in manifest.get('preservedFiles', []):
        preserved = (root / item['asset']).read_bytes()
        assert hashlib.sha256(preserved).hexdigest() == item['sha256'], item['asset'] + ': preserved source mismatch'
    records = []
    for item in [*manifest['files'], *manifest.get('runtimeAliases', [])]:
        source = (root / item['asset']).read_bytes()
        expected = hashlib.sha256(source).hexdigest()
        assert expected == item['sha256'], item['asset'] + ': source mismatch'
        url = args.url.rstrip('/') + '/assets/' + item['asset']
        with urllib.request.urlopen(url, timeout=30) as response:
            data = response.read()
            record = dict(asset=item['asset'], status=response.status,
                          contentType=response.headers.get_content_type(),
                          bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        assert record['status'] == 200, record
        content_type = item.get('contentType', 'image/png')
        assert record['contentType'] == content_type, record
        if content_type == 'image/jpeg':
            assert data.startswith(b'\xff\xd8\xff') and len(data) > 3, record
        else:
            assert content_type == 'image/png', record
            assert data.startswith(b'\x89PNG\r\n\x1a\n') and len(data) > 8, record
        assert record['sha256'] == expected, record
        records.append(record)
    shipped = {p.relative_to(root).as_posix() for p in (root / 'assets/illustrations/einleitung_generated').iterdir() if p.suffix.lower() in {'.png', '.jpg', '.jpeg'}}
    assert shipped == {item['asset'] for item in manifest['files']}, 'Unexpected or missing bundled image'
    output = root / args.output
    output.write_text(json.dumps(dict(url=args.url, passed=True, count=len(records), assets=records), indent=2) + '\n', encoding='utf-8')
    print(f'{len(records)} image responses verified: HTTP 200, recorded MIME type, exact SHA-256')


if __name__ == '__main__':
    main()
