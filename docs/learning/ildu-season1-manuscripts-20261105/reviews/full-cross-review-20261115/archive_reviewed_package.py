"""Archive committed manuscript bytes and verify every ZIP entry on readback.

The receipt is stored beside the archive to avoid a self-referential ZIP hash.
No original file, app file, audio asset, or existing archive is overwritten.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import json
import subprocess
import zipfile

HERE=Path(__file__).resolve().parent
BOOK=HERE.parents[1]
REPO=BOOK.parents[2]
PLAN=REPO/'docs/superpowers/plans/2026-11-15-season1-manuscript-cross-review.md'
def git(*args):
    return subprocess.run(['git','-C',str(REPO),*args],capture_output=True,check=True).stdout
def sha(data):
    return hashlib.sha256(data).hexdigest()

args=argparse.ArgumentParser(description=__doc__)
args.add_argument('output',type=Path)
options=args.parse_args()
archive=options.output.resolve()
receipt=archive.with_suffix('.json')
assert not archive.exists() and not receipt.exists(), 'Use a new archive name; preserve prior evidence.'
validation=json.loads((HERE/'FINAL_VALIDATION.json').read_text(encoding='utf-8'))
assert validation['mode']=='final' and not validation['problems']
assert not git('status','--porcelain=v1','--untracked-files=all').strip(), 'Commit the final package first.'
sources={p.relative_to(BOOK).as_posix():p for p in sorted(BOOK.rglob('*')) if p.is_file()}
assert not any(p.suffix=='.tmp' or '__pycache__' in p.parts for p in sources.values())
sources['review_execution_plan.md']=PLAN
commit=git('rev-parse','HEAD').decode().strip()
manifest={}
for name,p in sources.items():
    data=p.read_bytes()
    assert git('show',f'{commit}:{p.relative_to(REPO).as_posix()}')==data, f'Not identical to commit: {name}'
    manifest[name]=sha(data)
for key,expected in validation['finalSha256'].items():
    assert manifest[f'manuscripts/{key}.md']==expected
temporary=archive.with_suffix('.zip.tmp')
assert not temporary.exists()
with zipfile.ZipFile(temporary,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for name,p in sources.items():
        z.write(p,name)
with zipfile.ZipFile(temporary) as z:
    assert z.testzip() is None
    assert len(z.namelist())==len(manifest) and set(z.namelist())==set(manifest)
    assert all(sha(z.read(name))==expected for name,expected in manifest.items())
record={'verifiedUtc':datetime.now(timezone.utc).isoformat(),'archive':str(archive),
    'sha256':sha(temporary.read_bytes()),'bytes':temporary.stat().st_size,
    'fileCount':len(manifest),'commit':commit,'branch':git('branch','--show-current').decode().strip(),
    'sourceRoot':str(BOOK),'executionPlanSource':str(PLAN),'crcVerified':True,
    'allEntriesByteVerified':True,'allFilesMatchCommit':True,'files':manifest}
receipt_temp=receipt.with_suffix('.json.tmp')
assert not receipt_temp.exists()
receipt_temp.write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='')
assert json.loads(receipt_temp.read_text(encoding='utf-8'))==record
temporary.replace(archive)
receipt_temp.replace(receipt)
print(json.dumps({k:v for k,v in record.items() if k!='files'},ensure_ascii=False))
