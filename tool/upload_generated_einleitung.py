"""Upload whole generated source files to the one-time Figma asset endpoints."""
import concurrent.futures
import json
from pathlib import Path
import urllib.request
import sys

ROOT = Path(__file__).resolve().parents[1]
tasks = json.loads((ROOT / (sys.argv[1] if len(sys.argv) > 1 else 'tmp/einleitung-upload.json')).read_text())

def upload(task):
    boundary = 'einleitung-generated-whole-asset'
    data = Path(task['source']).read_bytes()
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{task["name"]}.png"\r\nContent-Type: image/png\r\n\r\n').encode() + data + f'\r\n--{boundary}--\r\n'.encode()
    request = urllib.request.Request(task['submitUrl'], data=body, headers={'Content-Type': f'multipart/form-data; boundary={boundary}'}, method='POST')
    with urllib.request.urlopen(request, timeout=180) as response:
        result = json.loads(response.read())
    return {'name': task['name'], 'response': result}

with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(upload, tasks))
output = ROOT / 'tool/einleitung_figma_uploads.json'
previous = json.loads(output.read_text(encoding='utf-8')) if output.exists() else []
output.write_text(json.dumps(previous + results, indent=2), encoding='utf-8')
print(json.dumps(results, indent=2))
