"""Publish only this task's verified source package to its existing authorized branch."""
import hashlib,json,subprocess,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
GITDIR=ROOT/'.git/publication.git';WORK=ROOT/'.git/publication-work'
PREFIX='assets_source/hanok/ildu_canonical_20261021';DEST=WORK/PREFIX
BRANCH='codex/ildu-courtyard-gate-stages-20261021'
def git(*args):return subprocess.check_output(['git','--git-dir='+str(GITDIR),'--work-tree='+str(WORK),*args])
assert git('branch','--show-current').decode().strip()==BRANCH
manifest=json.loads((DEST/'PACKAGE_FILES.json').read_text(encoding='utf-8'))
staged=git('diff','--cached','--name-only','-z').decode().strip('\0').split('\0')
expected={PREFIX+'/'+r['path'] for r in manifest['files']}|{PREFIX+'/PACKAGE_FILES.json'}
assert set(staged)==expected,('Unexpected staged paths',set(staged)^expected)
lfs=[]
for r in manifest['files']:
 p=DEST/r['path']
 with p.open('rb') as f:assert hashlib.file_digest(f,'sha256').hexdigest()==r['sha256'],r['path']
 if p.suffix in ('.blend','.glb'):
  path=PREFIX+'/'+r['path'];size=int(git('cat-file','-s',':'+path))
  assert size<512,('Binary was not staged in LFS',path,size)
  pointer=git('show',':'+path).decode('ascii')
  assert 'oid sha256:'+r['sha256'] in pointer and 'size '+str(r['bytes']) in pointer,path
  lfs.append(path)
for name in ['material-model-verification.json','material-browser-qa.json','package-verification.json','browser-controls-qa.json']:
 assert json.loads((DEST/'canonical-review-r1'/name).read_text(encoding='utf-8'))['passed']
remote=git('ls-remote','origin','refs/heads/'+BRANCH).decode().split()[0]
head=git('rev-parse','HEAD').decode().strip();assert remote==head,('Remote moved; do not overwrite',remote,head)
print('PUBLICATION VERIFIED',len(staged),'files',len(lfs),'LFS objects',head,flush=True)
if '--commit' not in sys.argv:sys.exit(0)
subprocess.run(['git','--git-dir='+str(GITDIR),'--work-tree='+str(WORK),'commit','-m','feat(hanok): promote approved gate sources and colored construction stages'],check=True,stdout=subprocess.DEVNULL)
commit=git('rev-parse','HEAD').decode().strip()
record=dict(branch=BRANCH,commit=commit,previousCommit=head,packagePrefix=PREFIX,files=len(staged),lfsFiles=len(lfs),approvedNativeGeometryPreserved=True,materialStages=20,illustrationPilot='sadangmun 8 stages; live lighting candidate',appIntegrated=False,pushed=False)
path=ROOT/'CANONICAL_COMMIT.json';path.write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print('COMMITTED',commit,flush=True)
if '--push' in sys.argv:
 with (OUT/'canonical-push.log').open('w',encoding='utf-8') as f:
  p=subprocess.run(['git','--git-dir='+str(GITDIR),'--work-tree='+str(WORK),'push','origin','HEAD:refs/heads/'+BRANCH],stdout=f,stderr=subprocess.STDOUT)
 assert p.returncode==0,('Push failed; inspect log',p.returncode)
 actual=git('ls-remote','origin','refs/heads/'+BRANCH).decode().split()[0];assert actual==commit
 record['pushed']=True;path.write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8');print('PUSH VERIFIED',commit,flush=True)
