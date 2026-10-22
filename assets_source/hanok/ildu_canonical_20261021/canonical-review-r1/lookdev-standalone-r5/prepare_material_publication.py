"""Exact scoped publication staging, with LFS placeholders to avoid binary duplication.
The live source assets stay in drawing-r4. Publication checkout native files are
valid LFS pointers, as in a skip-smudge checkout. Remote receives full LFS bytes.
"""
from pathlib import Path
import json,hashlib,subprocess,shutil
HOME=Path(__file__).resolve().parent;P=HOME.parent;ROOT=P.parent
GITDIR=ROOT/'.git/publication.git';WORK=ROOT/'.git/publication-work'
PREFIX=Path('assets_source/hanok/ildu_canonical_20261021');DEST=WORK/PREFIX
BRANCH='codex/ildu-courtyard-gate-stages-20261021'
def git(*args,input=None):
 return subprocess.check_output(['git','-c','core.longpaths=true','--git-dir='+str(GITDIR),'--work-tree='+str(WORK),*args],input=input,cwd=WORK)
def sha(path):
 with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def snapshot():
 app=Path(r'C:\dev\hangulsori\ko_lernen_app_worktrees\ildu-r12-app-integration-20261015')
 def g(*a):return subprocess.check_output(['git','-C',str(app),*a])
 return dict(head=g('rev-parse','HEAD').decode().strip(),statusSha256=hashlib.sha256(g('status','--porcelain=v1','-z')).hexdigest())
def selected_sources():
 old=json.loads((DEST/'PACKAGE_FILES.json').read_text(encoding='utf-8'));sources={}
 # Synchronize the already scoped source package, preserving missing historical
 # prepared files rather than deleting anything.
 for row in old['files']:
  src=ROOT/row['path']
  if src.is_file():sources[row['path']]=src
 for folder in P.glob('lookdev-*'):
  for src in folder.rglob('*'):
   if not src.is_file() or '__pycache__' in src.parts:continue
   if src.suffix.lower() not in ['.py','.md','.json','.png','.jpg','.jpeg','.blend','.html','.js','.css']:continue
   if src.name.endswith('-changes.json') or src.name in ['reviewed-input-changes.json','image-state-differences.json']:continue
   sources[src.relative_to(ROOT).as_posix()]=src
 for rel in ['estate-yard-wall-r1/ildu-estate-yard-wall-r1.blend','canonical-review-r1/MATERIAL_CANONICAL_PROMOTION_R5.json','canonical-review-r1/catalog.json','canonical-review-r1/app.js','canonical-review-r1/index.html','canonical-review-r1/export_building_pbr.py']:
  sources[rel]=ROOT/rel
 return old,sources
def main():
 assert git('branch','--show-current').decode().strip()==BRANCH
 head=git('rev-parse','HEAD').decode().strip();remote=git('ls-remote','origin','refs/heads/'+BRANCH).decode().split()[0];assert head==remote
 assert not git('diff','--cached','--name-only').strip(),'Existing unrelated staging must be preserved'
 assert not git('status','--porcelain=v1').strip(),'Publication checkout is not clean'
 promotion=json.loads((P/'MATERIAL_CANONICAL_PROMOTION_R5.json').read_text(encoding='utf-8'));assert len(promotion['entries'])==17
 for r in promotion['entries']:assert sha(P/r['native'])==r['sha256']
 old,sources=selected_sources();oldmap={r['path']:r for r in old['files']};records=dict(oldmap);changes=[];new_lfs_bytes=0
 for rel,src in sources.items():
  digest=sha(src);row=dict(path=rel,bytes=src.stat().st_size,sha256=digest);records[rel]=row
  if oldmap.get(rel)!=row:
   changes.append(rel)
   if src.suffix.lower() in ['.blend','.glb']:
    obj=GITDIR/'lfs/objects'/digest[:2]/digest[2:4]/digest
    if not obj.exists():new_lfs_bytes+=row['bytes']
 free=shutil.disk_usage(ROOT).free
 assert free>new_lfs_bytes+500_000_000,('Not enough space for LFS storage',free,new_lfs_bytes)
 before=snapshot();prepared=[]
 for rel in changes:
  src=sources[rel];dst=(DEST/rel).resolve();assert dst.is_relative_to(DEST.resolve());dst.parent.mkdir(parents=True,exist_ok=True)
  row=records[rel]
  if src.suffix.lower() in ['.blend','.glb']:
   # Standard LFS clean stores actual bytes in this repository's LFS object store.
   command=['git','--git-dir='+str(GITDIR),'--work-tree='+str(WORK),'lfs','clean',(PREFIX/rel).as_posix()]
   with src.open('rb') as f:pointer=subprocess.check_output(command,stdin=f)
   text=pointer.decode('ascii');assert 'oid sha256:'+row['sha256'] in text and 'size '+str(row['bytes']) in text
   dst.write_bytes(pointer)
  else:
   shutil.copyfile(src,dst);assert sha(dst)==row['sha256']
  prepared.append((PREFIX/rel).as_posix())
  print('PREPARED',rel,flush=True)
 record=dict(kind='canonical production source and structural review, not runtime release',files=sorted(records.values(),key=lambda r:r['path']),currentMaterialPromotion='canonical-review-r1/MATERIAL_CANONICAL_PROMOTION_R5.json')
 (DEST/'PACKAGE_FILES.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');prepared.append((PREFIX/'PACKAGE_FILES.json').as_posix())
 pathspec=HOME/'publication-paths.txt';pathspec.write_bytes(b'\0'.join(x.encode('utf-8') for x in prepared)+b'\0')
 git('add','--pathspec-from-file='+str(pathspec),'--pathspec-file-nul')
 staged=git('diff','--cached','--name-only','-z').decode().strip('\0').split('\0')
 assert set(staged)<=set(prepared) and staged
 lfs=0
 for path in staged:
  if Path(path).suffix.lower() not in ['.blend','.glb']:continue
  rel=Path(path).relative_to(PREFIX).as_posix();r=records[rel];pointer=git('show',':'+path).decode('ascii')
  assert len(pointer)<512 and 'oid sha256:'+r['sha256'] in pointer and 'size '+str(r['bytes']) in pointer
  obj=GITDIR/'lfs/objects'/r['sha256'][:2]/r['sha256'][2:4]/r['sha256'];assert obj.exists() and sha(obj)==r['sha256'];lfs+=1
 assert snapshot()==before,'App checkout changed during source preparation; inspect before proceeding'
 receipt=dict(branch=BRANCH,baseCommit=head,remoteCommit=remote,scope=PREFIX.as_posix(),stagedPaths=staged,files=len(staged),changedLfsFiles=lfs,newLfsBytes=new_lfs_bytes,
   sourceAssetBytesUnchanged=True,workingNativeFilesUseLfsPointers=True,appSnapshot=before,appCheckoutUnchanged=True,canonicalPromotion='canonical-review-r1/MATERIAL_CANONICAL_PROMOTION_R5.json')
 (HOME/'PUBLICATION_PREPARED.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print('STAGING VERIFIED',len(staged),'files',lfs,'LFS',new_lfs_bytes,'new storage bytes',flush=True)
if __name__=='__main__':main()
