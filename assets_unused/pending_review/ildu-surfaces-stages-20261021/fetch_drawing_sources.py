"""Fetch public full-resolution drawings from their observed official viewer links."""
from pathlib import Path
from urllib.parse import urljoin
from concurrent.futures import ThreadPoolExecutor
import requests, json, hashlib
from urllib3.util.retry import Retry
from bs4 import BeautifulSoup
P=Path(__file__).resolve().parent/'sources';P.mkdir(exist_ok=True)
items=[('left019','2828781'),('left020','2828779'),('left080','2828730'),('left081','2828728'),('left082','2828729'),('left083','2828727'),('right089','2828724'),('right091','2828720'),('right092','2828722'),('right093','2828723')]
def fetch(item):
 name,seq=item; page='https://www.heritage.go.kr/heri/cul/chartImgHeritage.do?file_seq='+seq
 session=requests.Session();session.mount('https://',requests.adapters.HTTPAdapter(max_retries=Retry(total=3,backoff_factor=.5)))
 r=session.get(page,timeout=40);r.raise_for_status();s=BeautifulSoup(r.content,'html.parser');im=s.select_one('img[data-info]');assert im
 url=urljoin(page,im['src']);f=P/(name+'.jpg')
 if not f.exists():
  r=session.get(url,timeout=60);r.raise_for_status();assert r.content[:2]==b'\xff\xd8';f.write_bytes(r.content)
 data=f.read_bytes()
 return dict(id=name,file=str(f),viewer=page,image=url,sha256=hashlib.sha256(data).hexdigest(),bytes=len(data))
with ThreadPoolExecutor(max_workers=3) as pool: results=list(pool.map(fetch,items))
existing=json.loads((P/'source-index.json').read_text(encoding='utf8')) if (P/'source-index.json').is_file() else []
fetched={row['id'] for row in results}
results += [row for row in existing if row['id'] not in fetched]
(P/'source-index.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf8')
for row in results:print(row['id'],row['bytes'],row['sha256'])
