#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
P = ROOT / "docs" / "textbook_project" / "data" / "A1_LEARNER_ERROR_MATRIX_EN_DE_20261006.json"

def main():
    d = json.loads(P.read_text(encoding="utf-8-sig"))
    assert set(d["evidenceTiers"]) == {"A","B","C"}
    assert len(d["en"]) >= 8
    assert len(d["de"]) >= 8
    for lang in ("en","de"):
        ids=set()
        for row in d[lang]:
            assert row["id"] not in ids
            ids.add(row["id"])
            assert row["evidenceTier"] in d["evidenceTiers"]
            assert row["risk"].strip()
            assert row["pedagogy"].strip()
            assert row["units"]
    assert any(x["evidenceTier"]=="A" for x in d["en"])
    assert any(x["evidenceTier"]=="A" for x in d["de"])
    print(f"PASS en={len(d['en'])} de={len(d['de'])} evidence_tiers=3")

if __name__ == "__main__":
    main()
