#!/usr/bin/env python3
import hashlib
import json
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
PACKET=ROOT/"docs"/"textbook_project"/"production"/"human_review_packets"/"unit04"
MANIFEST=PACKET/"MANIFEST.json"

def sha256(p):
    h=hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()

def main():
    m=json.loads(MANIFEST.read_text(encoding="utf-8-sig"))
    assert m["status"]=="READY_FOR_HUMAN_REVIEW"
    assert m["unitId"]=="a1_04_order_request_object"
    assert len(m["files"])==13

    listed=[]
    for item in m["files"]:
        relative = Path(item["path"])
        assert not relative.is_absolute() and ".." not in relative.parts, item["path"]
        p=ROOT/item["path"]
        assert p.exists(), p
        assert sha256(p)==item["sha256"], item["path"]
        assert p.stat().st_size==item["bytes"], item["path"]
        listed.append(item["path"])
        # The historical source SHA is provenance. Squash/rebase merges and
        # shallow clones need not contain that object: current bytes are the gate.
        # Check HEAD and index separately so a restored worktree cannot hide an
        # unreviewed committed or staged change.
        for revision in ("HEAD:" + item["path"], ":" + item["path"]):
            blob = subprocess.check_output(["git", "-C", str(ROOT), "show", revision])
            assert hashlib.sha256(blob).hexdigest() == item["sha256"], (item["path"], revision)
            assert len(blob) == item["bytes"], (item["path"], revision)

    source=m["sourceCommit"]

    decisions=PACKET/"REVIEW_DECISIONS.json"
    assert decisions.exists()
    d=json.loads(decisions.read_text(encoding="utf-8-sig"))
    assert d["status"]=="OPEN"

    print(f"PASS unit04_human_packet files={len(listed)} sourceCommit={source[:12]} decisions=open")

if __name__=="__main__":
    main()
