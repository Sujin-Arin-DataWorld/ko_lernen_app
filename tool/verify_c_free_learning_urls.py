from __future__ import annotations

import json
import os
import shutil
import socket
import subprocess
import tempfile
import threading
import time
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import requests
import websocket

ROOT = Path(__file__).resolve().parents[1]
MOCKUP = ROOT / 'docs/design/c_free_learning_mockup_20261005'
LEDGER = MOCKUP / 'trigger-ledger.json'
OUT = ROOT / 'docs/design/c_runtime_trigger_parity_audit_20261005/FREE_LEARNING_BROWSER_AUDIT.json'


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


def free_port() -> int:
    with socket.socket() as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]


def chrome_path() -> str:
    candidates = [
        os.environ.get('CHROME_PATH'),
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    ]
    for value in candidates:
        if value and Path(value).is_file():
            return value
    found = shutil.which('chrome') or shutil.which('msedge')
    if found:
        return found
    raise RuntimeError('Chrome/Edge not found')


class CDP:
    def __init__(self, ws_url: str):
        os.environ['NO_PROXY'] = '127.0.0.1,localhost'
        os.environ['no_proxy'] = '127.0.0.1,localhost'
        self.ws = websocket.create_connection(
            ws_url, timeout=30, origin='http://127.0.0.1',
            http_proxy_host=None,
        )
        self.next_id = 1

    def call(self, method: str, params: dict | None = None):
        call_id = self.next_id
        self.next_id += 1
        self.ws.send(json.dumps({'id': call_id, 'method': method, 'params': params or {}}))
        while True:
            payload = json.loads(self.ws.recv())
            if payload.get('id') != call_id:
                continue
            if 'error' in payload:
                raise RuntimeError(f'{method}: {payload["error"]}')
            return payload.get('result', {})

    def eval(self, expression: str):
        result = self.call('Runtime.evaluate', {
            'expression': expression,
            'returnByValue': True,
            'awaitPromise': True,
        })
        if result.get('exceptionDetails'):
            raise RuntimeError(json.dumps(result['exceptionDetails'], ensure_ascii=False))
        return result.get('result', {}).get('value')

    def close(self):
        self.ws.close()


def wait_debug(debug_port: int, timeout: float = 20.0) -> str:
    deadline = time.time() + timeout
    url = f'http://127.0.0.1:{debug_port}/json/list'
    while time.time() < deadline:
        try:
            pages = requests.get(url, timeout=1).json()
            page = next((p for p in pages if p.get('type') == 'page'), None)
            if page and page.get('webSocketDebuggerUrl'):
                return page['webSocketDebuggerUrl']
        except Exception:
            pass
        time.sleep(.1)
    raise RuntimeError('Chrome DevTools endpoint did not start')


def verify_batch(cdp: CDP, urls: list[str]) -> dict:
    encoded = json.dumps(urls, ensure_ascii=False)
    expression = f'''(() => {{
      window.__C_FREE_LEARNING_HEADLESS_BATCH__ = true;
      const urls = {encoded};
      const failures = [];
      let minText = Infinity, maxText = 0, zeroText = 0;
      for (let i = 0; i < urls.length; i++) {{
        const result = window.__C_FREE_LEARNING_AUDIT__.navigate(urls[i]);
        const n = result?.textLength ?? 0;
        minText = Math.min(minText,n); maxText = Math.max(maxText,n);
        if (!n) zeroText++;
        if (!result?.ok || n < 20) {{
          failures.push({{index:i,url:urls[i],result}});
          if (failures.length >= 100) break;
        }}
      }}
      window.__C_FREE_LEARNING_HEADLESS_BATCH__ = false;
      return {{total:urls.length,failures,minText:Number.isFinite(minText)?minText:0,maxText,zeroText}};
    }})()'''
    return cdp.eval(expression)


def main() -> None:
    ledger = json.loads(LEDGER.read_text(encoding='utf-8'))
    urls = [row['url'] for row in ledger['records']]
    httpd = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=str(ROOT)))
    server_port = httpd.server_address[1]
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()

    debug_port = free_port()
    user_data = tempfile.mkdtemp(prefix='hangulsori-c-free-chrome-')
    chrome = subprocess.Popen([
        chrome_path(), '--headless=new', '--disable-gpu', '--no-first-run',
        '--no-default-browser-check', '--disable-background-networking',
        '--disable-component-update', '--remote-allow-origins=*',
        f'--remote-debugging-port={debug_port}', f'--user-data-dir={user_data}',
        'about:blank',
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    cdp = None
    try:
        ws_url = wait_debug(debug_port)
        cdp = CDP(ws_url)
        cdp.call('Page.enable')
        cdp.call('Runtime.enable')
        entry = f'http://127.0.0.1:{server_port}/docs/design/c_free_learning_mockup_20261005/screen.html?view=home&m=words&fresh=1'
        cdp.call('Page.navigate', {'url': entry})
        deadline = time.time() + 40
        ready = False
        while time.time() < deadline:
            try:
                ready = bool(cdp.eval('Boolean(window.__C_FREE_LEARNING_READY__)'))
            except Exception:
                ready = False
            if ready:
                break
            time.sleep(.1)
        if not ready:
            diagnostic = cdp.eval("({href:location.href,readyState:document.readyState,body:(document.body?.innerText||'').slice(0,2000),scripts:[...document.scripts].map(s=>s.src),hook:typeof window.__C_FREE_LEARNING_AUDIT__,bootError:window.__C_FREE_LEARNING_BOOT_ERROR__||null})")
            print('BOOT_DIAGNOSTIC', json.dumps(diagnostic, ensure_ascii=False, indent=2))
            raise RuntimeError('Free-learning app did not become ready')

        batches = []
        failures = []
        batch_size = 500
        min_text = None
        max_text = 0
        zero_text = 0
        for start in range(0, len(urls), batch_size):
            batch = urls[start:start + batch_size]
            result = verify_batch(cdp, batch)
            for failure in result['failures']:
                failure['index'] += start
                failures.append(failure)
            min_text = result['minText'] if min_text is None else min(min_text,result['minText'])
            max_text = max(max_text,result['maxText'])
            zero_text += result['zeroText']
            batches.append({'start':start,'count':len(batch),'failures':len(result['failures'])})
            print(f'{start + len(batch)}/{len(urls)} failures={len(failures)}')
            if len(failures) >= 100:
                break

        payload = {
            'schemaVersion': 1,
            'totalLedgerUrls': len(urls),
            'testedUrls': sum(x['count'] for x in batches),
            'failedUrls': len(failures),
            'zeroText': zero_text,
            'minTextLength': min_text or 0,
            'maxTextLength': max_text,
            'status': 'PASS' if not failures and sum(x['count'] for x in batches) == len(urls) else 'FAIL',
            'batches': batches,
            'failureExamples': failures[:100],
            'chrome': chrome_path(),
        }
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(json.dumps(payload,ensure_ascii=False,indent=2) + '\n',encoding='utf-8')
        print(json.dumps(payload,ensure_ascii=False,indent=2))
        if payload['status'] != 'PASS':
            raise SystemExit(1)
    finally:
        if cdp:
            cdp.close()
        chrome.terminate()
        try:
            chrome.wait(timeout=5)
        except subprocess.TimeoutExpired:
            chrome.kill()
        httpd.shutdown()
        httpd.server_close()
        shutil.rmtree(user_data, ignore_errors=True)


if __name__ == '__main__':
    main()
