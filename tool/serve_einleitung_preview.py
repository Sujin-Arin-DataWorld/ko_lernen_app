"""Serve an unmodified Flutter web build on loopback for visual verification."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class PreviewHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', default='build/web')
    parser.add_argument('--port', type=int, default=7392)
    args = parser.parse_args()
    directory = Path(args.directory).resolve(strict=True)
    if not (directory / 'index.html').is_file() or not (directory / 'main.dart.js').is_file():
        raise SystemExit('Expected an existing Flutter web build with index.html and main.dart.js')
    server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(PreviewHandler, directory=str(directory)))
    print(f'Serving {directory} at http://127.0.0.1:{args.port}', flush=True)
    server.serve_forever()
