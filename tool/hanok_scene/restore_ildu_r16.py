"""Restore one archived variant into a NEW directory with full SHA-256 checks.

Usage: python restore_ildu_r16.py REPOSITORY PINNED_COMMIT VARIANT NEW_DIRECTORY
Fetch the pinned private archive commit into REPOSITORY first.
"""
from pathlib import Path, PureWindowsPath
import hashlib,json,subprocess,sys

def member(root, relative):
    value=str(relative)
    if Path(value).is_absolute() or PureWindowsPath(value).drive or PureWindowsPath(value).is_absolute():
        raise ValueError('Absolute archive path')
    dest=(root/value).resolve()
    if not dest.is_relative_to(root) or dest==root:raise ValueError('Unsafe archive path')
    current=root
    for part in Path(value).parts:
        current=current/part
        if current.is_symlink() or current.is_junction():raise ValueError('Linked archive path')
    return dest

def restore(repo,ref,name,target):
    target=Path(target).resolve()
    if target.exists():raise ValueError('Target must not exist')
    if len(ref)!=40 or any(c not in '0123456789abcdef' for c in ref.lower()):
        raise ValueError('Use the pinned full Git commit')
    manifest=json.loads(subprocess.check_output(['git','-C',repo,'show',ref+':manifest.json']))
    if manifest.get('complete') is not True or manifest.get('schemaVersion')!=2:
        raise ValueError('Incomplete or unsupported archive')
    variant=manifest['variants'][name]
    for item in variant['files']:member(target,item['path'])
    batch=subprocess.Popen(['git','-C',repo,'cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
    target.mkdir(parents=True)
    try:
        for item in variant['files']:
            dest=member(target,item['path'])
            dest.parent.mkdir(parents=True,exist_ok=True);whole=hashlib.sha256();size=0
            with dest.open('xb') as out:
                for digest in item['chunks']:
                    blob=manifest['objects'][digest]
                    batch.stdin.write((blob['oid']+'\n').encode());batch.stdin.flush()
                    header=batch.stdout.readline().split()
                    if len(header)!=3 or header[1]!=b'blob' or int(header[2])!=blob['bytes']:raise ValueError('Missing archive blob')
                    remaining=int(header[2]);chunk=hashlib.sha256()
                    while remaining:
                        data=batch.stdout.read(min(remaining,2**20))
                        if not data:raise EOFError('Truncated archive blob')
                        out.write(data);chunk.update(data);whole.update(data);size+=len(data);remaining-=len(data)
                    if batch.stdout.read(1)!=b'\n' or chunk.hexdigest()!=digest:raise ValueError('Chunk checksum mismatch')
            if size!=item['bytes'] or whole.hexdigest()!=item['sha256']:raise ValueError('File checksum mismatch: '+item['path'])
    finally:
        batch.stdin.close();batch.wait()
    print('RESTORED',name,len(variant['files']),'files')

if __name__=='__main__':restore(*sys.argv[1:])
