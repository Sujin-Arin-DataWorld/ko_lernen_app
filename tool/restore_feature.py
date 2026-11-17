"""Extract one archived variant into a NEW empty directory, verifying all bytes.
Usage: python restore_feature.py REPOSITORY ARCHIVE_REF VARIANT NEW_DIRECTORY
This restores archived files only; full-app recovery needs the recorded base.
"""
from pathlib import Path
import hashlib,json,subprocess,sys
repo,ref,name,target=sys.argv[1:];out=Path(target).resolve()
if out.exists():raise SystemExit('Target must not exist')
def read(path):return subprocess.check_output(['git','-C',repo,'show',ref+':'+path])
manifest=json.loads(read('manifest.json'));v=next(v for v in manifest['variants'] if v['name']==name)
batch=subprocess.Popen(['git','-C',repo,'cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
def blob(sha):
 x=manifest['objects'][sha];batch.stdin.write((x['oid']+'\n').encode());batch.stdin.flush()
 header=batch.stdout.readline().split();n=int(header[2]);data=batch.stdout.read(n);assert batch.stdout.read(1)==b'\n'
 assert len(data)==n and hashlib.sha256(data).hexdigest()==sha
 return data
out.mkdir(parents=True)
for f in v['files']:
 p=(out/f['path']).resolve()
 if not p.is_relative_to(out):raise SystemExit('Unsafe manifest path')
 data=b''.join(blob(sha) for sha in f['chunks'])
 assert hashlib.sha256(data).hexdigest()==f['sha256']
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
(out/'ARCHIVE_RESTORE_METADATA.json').write_text(json.dumps({'baseCommit':v['baseCommit'],'absent':v['absent'],'links':v['links'],'stagedPatch':v['stagedPatch'],'note':'Extracted archived files; deletion and original link application require the recorded base worktree.'},ensure_ascii=False,indent=2),encoding='utf-8')
batch.stdin.close();batch.wait();print('RESTORED',name,len(v['files']),'files',out)
