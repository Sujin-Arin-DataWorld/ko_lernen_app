"""Preserve each edited tracked file's checkpoint line-ending convention."""
from pathlib import Path
import subprocess

HERE=Path(__file__).resolve().parent
BOOK=HERE.parents[1]
REPO=BOOK.parents[2]
CHECKPOINT='174c449c173c0d00b90d5e86c4bf71c2e904b982'
changed=subprocess.check_output(['git','diff',CHECKPOINT,'--name-only'],cwd=REPO).decode().splitlines()
fixed=[]
for name in changed:
    if not name.startswith('docs/learning/ildu-season1-manuscripts-20261105/'):
        continue
    path=REPO/name
    if path.suffix not in ('.md','.json','.py'):
        continue
    old=subprocess.check_output(['git','show',CHECKPOINT+':'+name],cwd=REPO)
    cr=old.count(b'\r\n'); lf=old.count(b'\n')-cr
    assert not (cr and lf), 'Mixed checkpoint convention needs individual review: '+name
    current=path.read_bytes()
    normalized=current.replace(b'\r\n',b'\n')
    wanted=normalized.replace(b'\n',b'\r\n') if cr else normalized
    if wanted!=current:
        temp=path.with_suffix(path.suffix+'.tmp')
        temp.write_bytes(wanted)
        assert temp.read_bytes()==wanted
        temp.replace(path)
        fixed.append(name)
print('Restored checkpoint line-ending convention for',len(fixed),'edited files')
