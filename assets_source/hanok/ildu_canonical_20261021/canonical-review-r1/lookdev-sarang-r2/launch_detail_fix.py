"""Stop only the superseded owned render; reuse its verified full-size controls."""
from pathlib import Path
import hashlib,json,subprocess,shutil,psutil
from PIL import Image
p=Path(__file__).resolve().parent
process=psutil.Process(12340) if psutil.pid_exists(12340) else None
if process:
    args=process.cmdline()
    assert process.name().lower()=='blender.exe' and str(p/'render_handpainted.py').lower() in [x.lower() for x in args]
    process.terminate();process.wait(timeout=10)
log=(p/'render.log').read_text(encoding='utf-8',errors='replace')
views={
 'hero':((29.4,-30.2,15.45),(7.4,1.8,2.85),22,(1400,1050)),
 'front':((6.4,-22,3.5),(6.4,0,3.35),12.8,(1400,840)),
 'wood':((18,-15,5.0),(12.5,-3.0,2.3),3.2,(1100,900)),
 'stone':((6.5,-8.5,4.8),(4.0,-1.9,.63),3.6,(1100,900)),
 'tile':((17,-12,13),(13,-1.9,4.3),4.5,(1100,900)),
 'eaves':((13.5,-12,3.7),(12.5,-4.5,3.9),2.8,(1300,650)),
 'wall':((23,1,4.3),(14.6,1.6,2.8),3.1,(1100,900))}
prior=json.loads((p/'controls-cache.json').read_text())
cache={}
for name,(pos,target,scale,res) in views.items():
    file='before-'+name+'.png';path=p/file
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    assert 'RENDER COMPLETE '+file+' '+digest in log or (name in prior and digest==prior[name]['sha256'])
    assert Image.open(path).size==res
    cache[name]=dict(file=file,cameraLocation=list(pos),target=list(target),orthoScale=scale,resolution=list(res),sha256=digest)
(p/'controls-cache.json').write_text(json.dumps(cache,indent=2)+'\n')
shutil.copy2(p/'render.log',p/'render-before-mapping-fix.log')
output=(p/'render.log').open('w',encoding='utf-8')
r=subprocess.Popen([r'C:\dev\_tools\blender-5.2.2\blender-5.2.2-windows-x64\blender.exe','-b','--python',str(p/'render_handpainted.py'),'--','--reuse-controls'],stdout=output,stderr=subprocess.STDOUT)
print('Final detail render PID',r.pid,'reusing',len(cache),'verified matched controls')
