#!/usr/bin/env python3
"""Build the DEFINITIVE before/after change log for the C2d ledger: before =
the row as committed at HEAD (git show), after = the row in the current
working tree. Bypasses c2d_apply_rewrite.py's own incremental log (which
gets stale on a second/idempotent run) by diffing straight against git.
"""
from __future__ import annotations

import csv
import io
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))
import c2d_rewrite_data as D  # noqa: E402

VOCAB_IDS = set(D.VOCAB_REWRITES)
CLOZE_IDS = set(D.CLOZE_MIRROR_REWRITES) | set(D.CLOZE_ONLY_REWRITES)
SATZ_IDS = set(D.SATZ_MIRROR_REWRITES) | set(D.SATZ_ONLY_REWRITES)


def git_show(path: str) -> str:
    out = subprocess.run(
        ["git", "show", f"HEAD:{path}"], cwd=ROOT, capture_output=True, check=True
    )
    return out.stdout.decode("utf-8")


def build():
    log = []

    before_vocab = {r["id"]: r for r in csv.DictReader(io.StringIO(git_show("assets/data/korean_vocab.csv")))}
    with (ROOT / "assets/data/korean_vocab.csv").open(encoding="utf-8", newline="") as fh:
        after_vocab = {r["id"]: r for r in csv.DictReader(fh)}
    for rid in sorted(VOCAB_IDS):
        b, a = before_vocab[rid], after_vocab[rid]
        fields = sorted(k for k in b if b.get(k) != a.get(k))
        if fields:
            log.append({"kind": "vocab", "id": rid, "level": a["level"].strip().lower(),
                        "fields": fields, "before": b, "after": a})

    before_cloze = {x["id"]: x for x in json.loads(git_show("assets/data/cloze.json"))["items"]}
    after_cloze = {x["id"]: x for x in json.loads((ROOT / "assets/data/cloze.json").read_text(encoding="utf-8"))["items"]}
    for rid in sorted(CLOZE_IDS):
        b, a = before_cloze[rid], after_cloze[rid]
        fields = sorted(k for k in set(b) | set(a) if b.get(k) != a.get(k))
        if fields:
            log.append({"kind": "cloze", "id": rid, "level": a.get("level", ""),
                        "fields": fields, "before": b, "after": a})

    before_satz = {x["id"]: x for x in json.loads(git_show("assets/data/satz_sentences.json"))["items"]}
    after_satz = {x["id"]: x for x in json.loads((ROOT / "assets/data/satz_sentences.json").read_text(encoding="utf-8"))["items"]}
    for rid in sorted(SATZ_IDS):
        b, a = before_satz[rid], after_satz[rid]
        fields = sorted(k for k in set(b) | set(a) if b.get(k) != a.get(k))
        if fields:
            log.append({"kind": "satz", "id": rid, "level": a.get("level", ""),
                        "fields": fields, "before": b, "after": a})

    return log


def main():
    log = build()
    by_kind = {}
    for c in log:
        by_kind.setdefault(c["kind"], []).append(c["id"])
    for kind, ids in by_kind.items():
        print(f"{kind}: {len(ids)} rows -> {ids}")
    out_path = ROOT / "tools/content_factory/c2d_change_log.json"
    out_path.write_text(json.dumps(log, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"\nwritten: {out_path} ({len(log)} entries)")


if __name__ == "__main__":
    main()
