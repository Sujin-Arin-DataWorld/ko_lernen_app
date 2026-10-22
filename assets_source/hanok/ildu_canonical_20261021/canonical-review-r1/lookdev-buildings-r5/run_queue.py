"""Serial native Blender work, with resumable per-building checkpoints."""
from pathlib import Path
import subprocess,json,sys,hashlib,shutil,time
HOME=Path(__file__).resolve().parent
BLENDER=Path(r'C:\dev\_tools\blender-5.2.2\blender-5.2.2-windows-x64\blender.exe')
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def valid(key):
    p=HOME/key
    try:
        v=json.loads((p/'verification.json').read_text(encoding='utf-8'));r=json.loads((p/'render-manifest.json').read_text(encoding='utf-8'))
        return v['passed'] and v['version']=='building-r5-2' and r['complete'] and sha(p/v['candidateNative'])==v['candidateSha256'] and all(sha(p/x['file'])==x['sha256'] for x in r['renders'])
    except (FileNotFoundError,KeyError,ValueError):return False
def main():
    keys=sys.argv[1:] or ['sadangmun','sadang','anchae','jung','arae','gokgan','angotgan','changgo','toilet','toilet1','main_gate','left_changgo','right_ansarang']
    status={};start=time.monotonic()
    for key in keys:
        if valid(key):status[key]='verified existing';continue
        free=shutil.disk_usage(HOME).free
        if free<700_000_000:raise RuntimeError('Insufficient remaining disk for safe next native: '+str(free))
        print('BUILD',key,'free GB',round(free/1e9,2),flush=True)
        status[key]='running';(HOME/'queue-state.json').write_text(json.dumps(status,indent=2),encoding='utf-8')
        with (HOME/(key+'.log')).open('w',encoding='utf-8') as log:
            result=subprocess.run([str(BLENDER),'-b','-t','8','--python-exit-code','1','--python',str(HOME/'restyle_building.py'),'--',key],stdout=log,stderr=subprocess.STDOUT)
        assert result.returncode==0 and valid(key),(key,result.returncode)
        status[key]='complete';(HOME/'queue-state.json').write_text(json.dumps(status,indent=2),encoding='utf-8')
        print('VERIFIED',key,'elapsed',round(time.monotonic()-start),flush=True)
    print('QUEUE COMPLETE',len(keys),flush=True)
if __name__=='__main__':main()
