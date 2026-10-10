"""Loopback-only static preview and a narrowly scoped screenshot save endpoint."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import base64
import json
import re

ROOT = Path(__file__).resolve().parent

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        # This is an actively edited review, never serve stale CSS/movie frames.
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def do_POST(self):
        if self.path != '/save-capture':
            self.send_error(404)
            return
        try:
            size = int(self.headers.get('Content-Length', '0'))
            if not 0 < size < 8_000_000:
                raise ValueError('Invalid size')
            data = json.loads(self.rfile.read(size))
            name = data['name']
            if not re.fullmatch(r'proof-[a-z0-9-]{1,48}', name):
                raise ValueError('Invalid name')
            raw = base64.b64decode(data['jpeg'], validate=True)
            if not raw.startswith(bytes.fromhex('ffd8')):
                raise ValueError('JPEG required')
            folder = ROOT / 'review-proof'
            folder.mkdir(exist_ok=True)
            target = folder / (name + '.jpg')
            target.write_bytes(raw)
            reply = json.dumps({'saved': 'review-proof/' + target.name}).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(reply)))
            self.end_headers()
            self.wfile.write(reply)
        except (ValueError, KeyError, TypeError):
            self.send_error(400)

if __name__ == '__main__':
    print('Hangul Sori C mockups: http://127.0.0.1:8793/', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8793), Handler).serve_forever()
