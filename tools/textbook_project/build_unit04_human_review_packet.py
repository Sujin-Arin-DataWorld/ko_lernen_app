#!/usr/bin/env python3
import hashlib
import json
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
PACKET=ROOT/"docs"/"textbook_project"/"production"/"human_review_packets"/"unit04"
FILES=[
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"STUDENT_MASTER.md",
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"STUDENT_EN.md",
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"STUDENT_DE.md",
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"WORKBOOK_EN.md",
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"WORKBOOK_DE.md",
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"TEACHER_GUIDE.md",
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"data"/"UNIT04_AUDIO_SCRIPT.json",
    ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"/"data"/"UNIT04_PUBLISHING_MANIFEST.json",
    ROOT/"docs"/"textbook_project"/"data"/"ONE_A_UNIT_CONTRACTS_20261006.json",
    ROOT/"docs"/"textbook_project"/"production"/"UNIT04_ANSWER_KEY_SEED_20261006.json",
    ROOT/"docs"/"textbook_project"/"production"/"ONE_A_ANSWER_KEY_REGISTRY_20261006.json",
    ROOT/"docs"/"textbook_project"/"A1_LEARNER_ERROR_MATRIX_EN_DE_20261006.md",
    ROOT/"docs"/"textbook_project"/"SPOKEN_DISPLAY_TTS_POLICY.md",
]

def sha256(p):
    h=hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()

def main():
    missing=[str(p) for p in FILES if not p.exists()]
    assert not missing, missing
    commit=subprocess.check_output(
        ["git","-C",str(ROOT),"rev-parse","HEAD"],
        text=True
    ).strip()
    manifest={
        "schemaVersion":1,
        "date":"2026-10-06",
        "unitId":"a1_04_order_request_object",
        "status":"READY_FOR_HUMAN_REVIEW",
        "sourceCommit":commit,
        "files":[
            {
                "path":p.relative_to(ROOT).as_posix(),
                "sha256":sha256(p),
                "bytes":p.stat().st_size
            } for p in FILES
        ],
        "decisionFile":"docs/textbook_project/production/human_review_packets/unit04/REVIEW_DECISIONS.json",
        "rule":"If any listed file hash changes, regenerate this manifest before relying on previous human decisions."
    }
    out=PACKET/"MANIFEST.json"
    out.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"files":len(FILES),"commit":commit[:12],"status":manifest["status"]}))

if __name__=="__main__":
    main()
