"""Copy only the approved canonical source package to the existing publication branch."""
import hashlib,json,shutil,subprocess
from pathlib import Path
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
PREFIX=Path('assets_source/hanok/ildu_canonical_20261021')
WORK=ROOT/'.git/publication-work';DEST=WORK/PREFIX
APP=ROOT.parents[2].parent.parent/'ko_lernen_app_worktrees/ildu-r12-app-integration-20261015'
def sha(p):
 with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def snapshot():
 actual=Path(r'C:/dev/hangulsori/ko_lernen_app_worktrees/ildu-r12-app-integration-20261015')
 def git(*a):return subprocess.check_output(['git','-C',str(actual),*a])
 return dict(head=git('rev-parse','HEAD').decode().strip(),statusSha256=hashlib.sha256(git('status','--porcelain=v1','-z')).hexdigest(),indexTree=git('write-tree').decode().strip())
def copy(src,rel):
 dst=DEST/rel;dst.parent.mkdir(parents=True,exist_ok=True)
 if not dst.exists() or sha(dst)!=sha(src):shutil.copyfile(src,dst)
 assert sha(src)==sha(dst)
files=set(['CANONICAL_PROMOTION.json','build_gates.py','measured_assemblies.py','validate_drawings.py','audit_geometry.py','verify_surface_package.py','manifest.json','validation-summary.json','surface-package-verification.json'])
for g in ('left','right','shrine'):
 files.add(g+'-new.blend');files.add(g+'-validation.json')
 for v in ('hero','front','side','back','plan','eaves','underside'):files.add(g+'-'+v+'.png')
 for name in ('geometry-before-','geometry-after-'):files.add(name+g+'.json')
for folder in ('construction','sources','reference-textures','canonical-review-r1'):
 for p in (ROOT/folder).rglob('*'):
  rel=p.relative_to(ROOT)
  if p.is_file() and '__pycache__' not in rel.parts and p.suffix.lower() in ('.png','.jpg','.jpeg','.json','.blend','.glb','.html','.js','.css','.md','.py','.map'):
   if p.name in ('source-inspection.json','assembly-source-differences.json','add_variant_control.py'):continue
   if p.name in ('shrine-pbr-first.png','shrine-pbr-depth-fixed.png','shrine-illustrated-full.png','shrine-front-pbr-check.png','shrine-normal-zero.png','shrine-reference-light-check.png','shrine-depth-probe.png','shrine-continuous-paint.png'):continue
   if rel.as_posix() in ['canonical-review-r1/models/'+k+'.glb' for k in ('left_changgo','right_ansarang','sadangmun')]:continue
   files.add(rel.as_posix())
# Keep source-stage bindings and the compact verified R5 material libraries without mockup images.
for sub,lib in [('living-r3','living-yard-wall-r3-refined.blend'),('living-r4','courtyard-soil-r4.blend'),('living-r5','continuous-yard-r5.blend')]:
 folder=ROOT/'estate-yard-wall-r1'/sub
 for p in folder.iterdir():
  if p.is_file() and (p.name==lib or p.suffix.lower() in ('.py','.json','.md')):
   files.add(p.relative_to(ROOT).as_posix())
for name in ('audit_source.py','material_patch.py','material-patch.json','patch-reconstruction-verification.json','manifest.json'):
 files.add('estate-yard-wall-r1/'+name)
before=snapshot()
# Remove only verified, previously prepared copies that are no longer selected.
old_manifest=DEST/'PACKAGE_FILES.json'
if old_manifest.exists():
 for r in json.loads(old_manifest.read_text(encoding='utf-8'))['files']:
  if r['path'] in files or r['path']=='.gitattributes':continue
  stale=(DEST/r['path']).resolve();assert stale.is_relative_to(DEST.resolve())
  if stale.is_file():
   assert sha(stale)==r['sha256'],('Prepared copy was changed; preserve it',str(stale))
   stale.unlink()
for rel in sorted(files):copy(ROOT/rel,rel)
# All binary geometry is stored using LFS; image bytes are left unchanged.
(DEST/'.gitattributes').write_text('* -text\n*.blend filter=lfs diff=lfs merge=lfs -text\n*.glb filter=lfs diff=lfs merge=lfs -text\n*.png binary\n*.jpg binary\n',encoding='utf-8')
records=[dict(path=p.relative_to(DEST).as_posix(),bytes=p.stat().st_size,sha256=sha(p)) for p in sorted(DEST.rglob('*')) if p.is_file() and p.name!='PACKAGE_FILES.json']
(DEST/'PACKAGE_FILES.json').write_text(json.dumps(dict(kind='canonical production source and structural review, not runtime release',files=records),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
after=snapshot();assert after==before
(ROOT/'CANONICAL_PUBLICATION_PREPARED.json').write_text(json.dumps(dict(prefix=PREFIX.as_posix(),files=len(records)+1,bytes=sum(r['bytes'] for r in records),appCheckoutUnchanged=True,appSnapshot=before),indent=2)+'\n',encoding='utf-8')
print('CANONICAL PACKAGE PREPARED',len(records)+1,'files',sum(r['bytes'] for r in records),'bytes',str(DEST),flush=True)

