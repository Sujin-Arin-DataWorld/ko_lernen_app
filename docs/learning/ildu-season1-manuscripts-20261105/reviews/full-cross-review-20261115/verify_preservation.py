"""Read-only verification of protected app/audio, other Git WIP and sources."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import zipfile

HERE=Path(__file__).resolve().parent
BOOK=HERE.parents[1]
def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))
def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''):
            h.update(chunk)
    return h.hexdigest()
def git(path,*args):
    return subprocess.run(['git','-C',path,*args],capture_output=True,check=True).stdout

app=read(BOOK/'APP_BASELINE.json')
changed=[]
missing=[]
for name,expected in app['files'].items():
    p=Path(app['root'])/name
    if not p.is_file():
        missing.append(name)
    elif digest(p)!=expected:
        changed.append(name)
baseline=read(HERE/'BASELINE.json')
checkpoint=read(BOOK/'CHECKPOINT_ARCHIVE.json')
checkpoint_archive=Path(checkpoint['archive'])
assert digest(checkpoint_archive)==checkpoint['archiveSha256']
original_problems=[]
with zipfile.ZipFile(checkpoint_archive) as z:
    assert z.testzip() is None
    archive_prefix=Path(checkpoint['source']).name+'/'
    assert set(z.namelist())=={archive_prefix+name for name in checkpoint['files']}
    for name,expected in checkpoint['files'].items():
        original=Path(checkpoint['source'])/name
        if not original.is_file() or digest(original)!=expected:
            original_problems.append(name)
        assert hashlib.sha256(z.read(archive_prefix+name)).hexdigest()==expected
external=[]
for source in baseline['externalSourceHashes']:
    p=Path(source['path'])
    external.append({**source,'currentSha256':digest(p) if p.is_file() else None})
snapshot=read(HERE/'GIT_PRESERVATION_BASELINE.json')
print('APP',len(app['files']),'changed',len(changed),'missing',len(missing))
print('GIT_BASELINE_KEYS',list(snapshot))
result={'checkedUtc':datetime.now(timezone.utc).isoformat(),'appRoot':app['root'],
    'pinnedFiles':len(app['files']),'changedFiles':changed,'missingFiles':missing,
    'audioFileCount':sum(name.lower().endswith(('.wav','.mp3','.ogg','.m4a','.flac')) for name in app['files']),
    'externalSources':external,'gitPreservationBaseline':snapshot,
    'checkpointArchiveSha256':checkpoint['archiveSha256'],
    'checkpointArchiveEntriesVerified':len(checkpoint['files']),
    'checkpointArchivePrefix':archive_prefix,
    'originalFolderChangedOrMissing':original_problems,
    'gitCurrent':[]}
for path in ['C:/dev/hangulsori/ko_lernen_app',app['root']]:
    status=git(path,'status','--porcelain=v1','--untracked-files=all')
    index=git(path,'ls-files','--stage')
    result['gitCurrent'].append({'path':path,'head':git(path,'rev-parse','HEAD').decode().strip(),
        'branch':git(path,'branch','--show-current').decode().strip(),
        'statusLineCount':len(status.splitlines()),'statusSha256':hashlib.sha256(status).hexdigest(),
        'indexLineCount':len(index.splitlines()),'indexSha256':hashlib.sha256(index).hexdigest()})
git_changes=[]
for before,after in zip(snapshot['checkouts'],result['gitCurrent'],strict=True):
    assert Path(before['root']).resolve()==Path(after['path']).resolve()
    for old_key,new_key in [('head','head'),('branch','branch'),('statusSha256','statusSha256'),
                            ('statusCount','statusLineCount'),('indexEntriesSha256','indexSha256'),
                            ('indexEntriesCount','indexLineCount')]:
        if before[old_key]!=after[new_key]:
            git_changes.append({'path':after['path'],'field':new_key,'before':before[old_key],'after':after[new_key]})
result['gitChanges']=git_changes
result['allProtectedStateUnchanged']=not changed and not missing and not git_changes and not original_problems and all(s['sha256']==s['currentSha256'] for s in external)
p=HERE/'PRESERVATION_VALIDATION.json'
t=p.with_suffix('.json.tmp')
t.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='')
assert read(t)==result
t.replace(p)
print(json.dumps(result['gitCurrent'],ensure_ascii=False))
assert not changed and not missing
assert all(s['sha256']==s['currentSha256'] for s in external)
assert not git_changes
assert not original_problems
