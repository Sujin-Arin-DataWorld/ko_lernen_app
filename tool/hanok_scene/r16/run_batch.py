"""Sequential native production on the local CPU. No canonical overwrite or publication."""
import sys,json,subprocess,time,hashlib
from pathlib import Path
OUT=Path(__file__).resolve().parent;BLENDER='C:/dev/_tools/blender-5.2.2/blender-5.2.2-windows-x64/blender.exe'
scope=json.loads((OUT/'CURRENT_SCOPE.json').read_text(encoding='utf-8'))
keys=list(scope['activeBuildings'])
mode=sys.argv[1] if len(sys.argv)>1 else 'complete'
if len(sys.argv)>2:keys=sys.argv[2:]
outside=set(keys)-set(scope['activeBuildings'])
if outside:raise SystemExit('Outside current user scope: '+', '.join(sorted(outside)))
for key in keys:
 done=OUT/key/('construction.json' if mode=='construction' else 'render-manifest.json')
 if done.exists():
  data=json.loads(done.read_text(encoding='utf-8'))
  if data.get('complete') and (mode=='construction' or (OUT/key/'complete.png').exists()):
   print('VERIFIED OUTPUT EXISTS',key,mode,flush=True);continue
 args=[BLENDER,'-b','--factory-startup','--disable-autoexec','--python-exit-code','1','--python',str(OUT/'produce.py'),'--',key]
 if mode=='construction':args.append('--construction')
 with (OUT/f'{key}-{mode}.log').open('w',encoding='utf-8') as f:
  p=subprocess.run(args,stdout=f,stderr=subprocess.STDOUT)
 if p.returncode!=0:raise SystemExit(f'Failed {key} {mode}: {p.returncode}')
 data=json.loads(done.read_text(encoding='utf-8'));assert data['complete'],key
 print('COMPLETE',key,mode,flush=True)
