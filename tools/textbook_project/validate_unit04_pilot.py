#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/"docs"/"textbook_project"/"pilot_1A"/"unit04"
MANIFEST=BASE/"data"/"UNIT04_PUBLISHING_MANIFEST.json"
AUDIO=BASE/"data"/"UNIT04_AUDIO_SCRIPT.json"
CONTRACTS=ROOT/"docs"/"textbook_project"/"data"/"ONE_A_UNIT_CONTRACTS_20261006.json"

REQUIRED=[
    BASE/"STUDENT_MASTER.md",
    BASE/"WORKBOOK.md",
    BASE/"TEACHER_GUIDE.md",
    BASE/"PUBLISHING_QA.md",
    MANIFEST,
    AUDIO,
]

def main():
    for p in REQUIRED:
        assert p.exists() and p.stat().st_size>100, p

    m=json.loads(MANIFEST.read_text(encoding="utf-8-sig"))
    a=json.loads(AUDIO.read_text(encoding="utf-8-sig"))
    c=json.loads(CONTRACTS.read_text(encoding="utf-8-sig"))
    u=next(x for x in c["units"] if x["unitId"]=="a1_04_order_request_object")

    assert m["unitId"]==u["unitId"]
    assert m["status"]=="PILOT_VERTICAL_SLICE_DRAFT"
    assert m["surfacePolicy"]["ttsOwner"]=="Jin"
    assert m["surfacePolicy"]["audioGenerated"] is False
    assert a["ttsOwner"]=="Jin"
    assert a["status"]=="SCRIPT_ONLY_NO_TTS_GENERATION"

    core=set(m["productiveTargets"]["coreChunks"])
    assert "떡볶이 하나 주세요." in core
    assert "포장해 주세요." in core
    assert all("-ㄹ게요" not in x for x in core)

    recognition=set(m["recognitionOnly"])
    assert "주문하시겠어요?" in recognition
    assert "안 매운 걸로 드릴게요." in recognition

    text=(BASE/"STUDENT_MASTER.md").read_text(encoding="utf-8-sig")
    assert "Give me" in text
    assert "Ich hätte gern" in text
    assert "Living Korean" in text
    assert "romanization" not in text.lower()
    assert "떡볶이 하나 주세요." in text

    audio_lines=[
        line
        for track in a["tracks"]
        if track["type"]=="dialogue"
        for line in track["lines"]
    ]
    assert audio_lines
    assert all("displaySurfaceKo" in x and "spokenSurfaceKo" in x for x in audio_lines)
    assert all("ㅋㅋ" not in x["spokenSurfaceKo"] and "ㅎㅎ" not in x["spokenSurfaceKo"] for x in audio_lines)

    selected={x["id"] for x in m["selectedPracticeSources"]}
    assert {"cloze_a1_0037","cloze_a1_0039","cloze_a1_0509"} <= selected

    print(f"PASS unit04 files={len(REQUIRED)} dialogue_lines={len(audio_lines)} selected_practice={len(selected)}")

if __name__=="__main__":
    main()
