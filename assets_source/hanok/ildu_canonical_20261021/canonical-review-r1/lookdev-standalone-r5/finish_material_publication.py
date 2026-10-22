"""Resume the exact prepared scope after Windows Git's long-path limit."""
from pathlib import Path
import json,hashlib,subprocess,shutil
HOME=Path(__file__).resolve().parent;P=HOME.parent;ROOT=P.parent
GITDIR=ROOT/'.git/publication.git';WORK=ROOT/'.git/publication-work'
PREFIX=Path('assets_source/hanok/ildu_canonical_20261021');DEST=WORK/PREFIX
BRANCH='codex/ildu-courtyard-gate-stages-20261021'
def git(*args):
 return subprocess.check_output(['git','-c','core.longpaths=true','--git-dir='+str(GITDIR),'--work-tree='+str(WORK),*args],cwd=WORK)
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def main():
 assert git('branch','--show-current').decode().strip()==BRANCH
 head=git('rev-parse','HEAD').decode().strip();assert head==git('ls-remote','origin','refs/heads/'+BRANCH).decode().split()[0]
 prepared=(HOME/'publication-paths.txt').read_bytes().decode().strip('\0').split('\0')
 staged_before=git('diff','--cached','--name-only','-z').decode().strip('\0').split('\0')
 assert set(x for x in staged_before if x)<=set(prepared),'Inspect unexpected existing staging'
 changed=git('status','--porcelain=v1','-z','--untracked-files=all').decode().strip('\0').split('\0')
 assert all(x[3:] in prepared for x in changed if x),[x for x in changed if x and x[3:] not in prepared]
 manifest=json.loads((DEST/'PACKAGE_FILES.json').read_text(encoding='utf-8'));records={r['path']:r for r in manifest['files']}
 for extra in ['finish_material_publication.py','BROWSER_QA.json','FINAL_REVIEW.md','WORK.md','prepare_material_publication.py']:
  src=HOME/extra
  if src.is_file():prepared.append((PREFIX/src.relative_to(ROOT)).as_posix())
 prepared=sorted(set(prepared))
 for path in prepared:
  rel=Path(path).relative_to(PREFIX).as_posix()
  if rel=='PACKAGE_FILES.json':continue
  src=ROOT/rel;dst=DEST/rel
  assert src.is_file() and dst.resolve().is_relative_to(DEST.resolve()),path
  row=dict(path=rel,bytes=src.stat().st_size,sha256=sha(src));records[rel]=row
  if src.suffix.lower() in ['.blend','.glb']:
   obj=GITDIR/'lfs/objects'/row['sha256'][:2]/row['sha256'][2:4]/row['sha256']
   assert obj.is_file() and sha(obj)==row['sha256']
   expected='version https://git-lfs.github.com/spec/v1\noid sha256:'+row['sha256']+'\nsize '+str(row['bytes'])+'\n'
   assert dst.read_text(encoding='ascii')==expected
  else:shutil.copyfile(src,dst);assert sha(dst)==row['sha256']
 manifest['files']=sorted(records.values(),key=lambda x:x['path'])
 (DEST/'PACKAGE_FILES.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 (HOME/'publication-paths.txt').write_bytes(b'\0'.join(x.encode() for x in prepared)+b'\0')
 git('add','--pathspec-from-file='+str(HOME/'publication-paths.txt'),'--pathspec-file-nul')
 staged=git('diff','--cached','--name-only','-z').decode().strip('\0').split('\0');assert staged and set(staged)<=set(prepared)
 lfs=0
 for path in staged:
  blob=git('show',':'+path);rel=Path(path).relative_to(PREFIX).as_posix()
  if rel=='PACKAGE_FILES.json':assert json.loads(blob)==manifest;continue
  row=records[rel]
  if Path(path).suffix.lower() in ['.blend','.glb']:
   assert len(blob)<512 and 'oid sha256:'+row['sha256'] in blob.decode() and 'size '+str(row['bytes']) in blob.decode();lfs+=1
  else:assert hashlib.sha256(blob).hexdigest()==row['sha256'],path
 git('-c','core.whitespace=cr-at-eol','diff','--cached','--check')
 promotion=json.loads((P/'MATERIAL_CANONICAL_PROMOTION_R5.json').read_text(encoding='utf-8'))
 for r in promotion['entries']:assert sha(P/r['native'])==r['sha256']
 receipt=dict(branch=BRANCH,baseCommit=head,stagedPaths=staged,files=len(staged),changedLfsFiles=lfs,scope=PREFIX.as_posix(),allIndexedBytesVerified=True,canonicalNativeCount=len(promotion['entries']),approvedSarangSha256='cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8',workingNativeFilesUseLfsPointers=True,freeDiskBytes=shutil.disk_usage(ROOT).free,windowsLongPathsEnabledPerCommand=True)
 (HOME/'PUBLICATION_PREPARED.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print('STAGING VERIFIED',len(staged),'files;',lfs,'LFS; all indexed bytes match; free',receipt['freeDiskBytes'],flush=True)
if __name__=='__main__':main()
