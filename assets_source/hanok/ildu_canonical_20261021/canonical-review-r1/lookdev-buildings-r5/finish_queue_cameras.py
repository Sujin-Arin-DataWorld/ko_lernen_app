"""Continue this active render pipeline after the serial building queue exits."""
from pathlib import Path
import time,subprocess,json
HOME=Path(__file__).resolve().parent
BLENDER=r'C:\dev\_tools\blender-5.2.2\blender-5.2.2-windows-x64\blender.exe'
while 'QUEUE COMPLETE 12' not in (HOME/'queue.log').read_text(encoding='utf-8',errors='replace'):
    time.sleep(5)
for key in ['anchae','sadang']:
    print('REFRAME',key,flush=True)
    with (HOME/(key+'-camera.log')).open('w',encoding='utf-8') as log:
        p=subprocess.run([BLENDER,'-b','-t','8','--python-exit-code','1','--python',str(HOME/'refine_review_cameras.py'),'--',key],stdout=log,stderr=subprocess.STDOUT)
    assert p.returncode==0,(key,p.returncode)
subprocess.run(['python','-X','utf8',str(HOME/'finalize_extension.py')],check=True)
print('PIPELINE AND CAMERAS COMPLETE',flush=True)
