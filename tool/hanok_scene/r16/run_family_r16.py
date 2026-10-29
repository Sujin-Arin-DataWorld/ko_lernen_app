"""Bounded two-worker native render queue with incremental, resumable receipts."""
import subprocess,sys,json,time,concurrent.futures,hashlib
from pathlib import Path
P=Path(__file__).resolve().parent;D=P/'family-r16';D.mkdir(exist_ok=True)
BLENDER=Path('C:/dev/_tools/blender-5.2.2/blender-5.2.2-windows-x64/blender.exe')
mode=sys.argv[1] if len(sys.argv)>1 else 'build'
keys=sys.argv[2:] or ['anchae','sadang','jung','arae','gokgan','angotgan','changgo','toilet','toilet1']
def worker(key):
 folder=D/key;folder.mkdir(exist_ok=True)
 receipt=folder/('verification.json' if mode=='build' else 'stage-renders.json')
 if receipt.exists():
  old=json.loads(receipt.read_text(encoding='utf-8'))
  if mode=='build' and old.get('renderComplete') and Path(old['native']).exists():
   digest=hashlib.sha256(Path(old['native']).read_bytes()).hexdigest()
   if digest==old['nativeSha256'] and (folder/'full.png').exists():return dict(key=key,exitCode=0,reusedVerified=True,finished=time.time())
 log=folder/(mode+'-console.log')
 script=P/('build_family_r16.py' if mode=='build' else 'render_construction_r16.py')
 with log.open('w',encoding='utf-8') as stream:
  result=subprocess.run([str(BLENDER),'--background','--threads','6','--python-exit-code','1','--python',str(script),'--',key],stdout=stream,stderr=subprocess.STDOUT,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
 return dict(key=key,exitCode=result.returncode,log=str(log),finished=time.time())
progress=dict(mode=mode,keys=keys,completed=[],running=True,started=time.time())
def save(): (D/(mode+'-queue.json')).write_text(json.dumps(progress,indent=2),encoding='utf-8')
save()
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for result in concurrent.futures.as_completed([pool.submit(worker,key) for key in keys]):
  row=result.result();progress['completed'].append(row);save();print(json.dumps(row),flush=True)
progress['running']=False;progress['finished']=time.time();save()
assert all(row['exitCode']==0 for row in progress['completed']),progress
print('QUEUE COMPLETE',mode,len(keys),flush=True)
