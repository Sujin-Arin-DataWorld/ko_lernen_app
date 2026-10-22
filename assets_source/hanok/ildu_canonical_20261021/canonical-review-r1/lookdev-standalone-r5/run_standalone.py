from pathlib import Path
import subprocess,json
HOME=Path(__file__).resolve().parent
BLENDER=r'C:\dev\_tools\blender-5.2.2\blender-5.2.2-windows-x64\blender.exe'
for key in ['sarang','jung']:
 print('BEGIN',key,flush=True)
 with (HOME/(key+'.log')).open('w',encoding='utf-8') as log:
  p=subprocess.run([BLENDER,'-b','-t','8','--python-exit-code','1','--python',str(HOME/'apply_standalone.py'),'--',key],stdout=log,stderr=subprocess.STDOUT)
 assert p.returncode==0,(key,p.returncode)
 print('DONE',key,flush=True)
print('BOTH STANDALONE VARIANTS COMPLETE',flush=True)
