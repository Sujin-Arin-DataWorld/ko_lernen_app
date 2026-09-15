#!/usr/bin/env python3
"""C2d step 2 -- apply c2d_rewrite_data.py's content table to the live
assets (korean_vocab.csv, cloze.json, satz_sentences.json) and print a
before/after diff log used to build the ledger entries + Jin sample packet.

Usage:
    PYTHONIOENCODING=utf-8 python tools/content_factory/c2d_apply_rewrite.py [--write]
"""
from __future__ import annotations

import csv
import json
import sys
import zlib
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))
import c2d_rewrite_data as D  # noqa: E402

VOCAB_CSV = ROOT / "assets" / "data" / "korean_vocab.csv"
CLOZE_JSON = ROOT / "assets" / "data" / "cloze.json"
SATZ_JSON = ROOT / "assets" / "data" / "satz_sentences.json"
FIELDNAMES = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]

CHANGE_LOG: list[dict] = []  # kind, id, level, fields, before, after (full row dicts)


def strip_punct(tok: str) -> str:
    return tok.strip(" !?.,…~\"'()")


def apply_vocab():
    with VOCAB_CSV.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    for row in rows:
        rid = row["id"]
        if rid in D.VOCAB_REWRITES:
            ko, de, en = D.VOCAB_REWRITES[rid]
            before = dict(row)
            row["example_korean"] = ko
            row["example_german"] = de
            row["example_english"] = en
            CHANGE_LOG.append({
                "kind": "vocab", "id": rid, "level": row["level"].strip().lower(),
                "fields": ["example_korean", "example_german", "example_english"],
                "before": before, "after": dict(row),
            })
    with VOCAB_CSV.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=FIELDNAMES, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)
    return rows


def apply_cloze():
    payload = json.loads(CLOZE_JSON.read_text(encoding="utf-8"))
    items = payload["items"]
    for item in items:
        rid = item["id"]
        patch = None
        if rid in D.CLOZE_MIRROR_REWRITES:
            patch = D.CLOZE_MIRROR_REWRITES[rid]
        elif rid in D.CLOZE_ONLY_REWRITES:
            patch = D.CLOZE_ONLY_REWRITES[rid]
        if patch is None:
            continue
        before = dict(item)
        fields = []
        for key in ("sentenceKo", "answer", "fullKo", "de", "en", "distractors"):
            if key in patch and item.get(key) != patch[key]:
                item[key] = patch[key]
                fields.append(key)
        if fields:
            CHANGE_LOG.append({
                "kind": "cloze", "id": rid, "level": item.get("level", ""),
                "fields": sorted(fields), "before": before, "after": dict(item),
            })
    CLOZE_JSON.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8", newline="",
    )
    return items


def _satz_distractors(target_ko: str, all_satz_a1: list[dict]) -> list[str]:
    """Mirror build_satzbauen.py's algorithm exactly: 2 short (<=4 char)
    real eojeol from OTHER a1 sentences, not present in the target,
    crc32(target)-seeded so the pick is deterministic."""
    own = {strip_punct(t) for t in target_ko.split()}
    pool, seen = [], set()
    for it in all_satz_a1:
        for tok in it["targetKo"].split():
            tok = strip_punct(tok)
            if tok and tok not in seen and any("가" <= c <= "힣" for c in tok):
                seen.add(tok)
                pool.append(tok)
    pool = [t for t in pool if t not in own and len(t) <= 4]
    rnd = Random(zlib.crc32(target_ko.encode("utf-8")))
    return rnd.sample(pool, 2)


def apply_satz():
    payload = json.loads(SATZ_JSON.read_text(encoding="utf-8"))
    items = payload["items"]
    all_a1 = [it for it in items if it.get("level") == "a1"]
    for item in items:
        rid = item["id"]
        new_ko = new_de = new_en = None
        if rid in D.SATZ_MIRROR_REWRITES:
            new_ko, new_de, new_en = D.SATZ_MIRROR_REWRITES[rid]
        elif rid in D.SATZ_ONLY_REWRITES:
            new_ko, new_de, new_en = D.SATZ_ONLY_REWRITES[rid]
        if new_ko is None:
            continue
        before = dict(item)
        fields = []
        if item.get("targetKo") != new_ko:
            item["targetKo"] = new_ko
            fields.append("targetKo")
        if item.get("promptDe") != new_de:
            item["promptDe"] = new_de
            fields.append("promptDe")
        if item.get("promptEn") != new_en:
            item["promptEn"] = new_en
            fields.append("promptEn")
        new_distractors = _satz_distractors(new_ko, all_a1)
        if item.get("distractors") != new_distractors:
            item["distractors"] = new_distractors
            fields.append("distractors")
        if fields:
            CHANGE_LOG.append({
                "kind": "satz", "id": rid, "level": item.get("level", ""),
                "fields": sorted(fields), "before": before, "after": dict(item),
            })
    SATZ_JSON.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8", newline="",
    )
    return items


def main():
    write = "--write" in sys.argv
    if not write:
        print("DRY RUN -- pass --write to apply. Showing planned changes only.\n")

    if write:
        apply_vocab()
        apply_cloze()
        apply_satz()
    else:
        # Compute the change log without touching disk by loading a copy.
        import copy
        global CHANGE_LOG
        with VOCAB_CSV.open(encoding="utf-8", newline="") as fh:
            rows = list(csv.DictReader(fh))
        for row in rows:
            rid = row["id"]
            if rid in D.VOCAB_REWRITES:
                ko, de, en = D.VOCAB_REWRITES[rid]
                before = dict(row)
                after = dict(row)
                after["example_korean"], after["example_german"], after["example_english"] = ko, de, en
                CHANGE_LOG.append({"kind": "vocab", "id": rid, "level": row["level"].strip().lower(),
                                    "fields": ["example_korean", "example_german", "example_english"],
                                    "before": before, "after": after})
        cloze_payload = json.loads(CLOZE_JSON.read_text(encoding="utf-8"))
        for item in cloze_payload["items"]:
            rid = item["id"]
            patch = D.CLOZE_MIRROR_REWRITES.get(rid) or D.CLOZE_ONLY_REWRITES.get(rid)
            if not patch:
                continue
            before = dict(item)
            after = dict(item)
            fields = []
            for key in ("sentenceKo", "answer", "fullKo", "de", "en", "distractors"):
                if key in patch and after.get(key) != patch[key]:
                    after[key] = patch[key]
                    fields.append(key)
            if fields:
                CHANGE_LOG.append({"kind": "cloze", "id": rid, "level": item.get("level", ""),
                                    "fields": sorted(fields), "before": before, "after": after})
        satz_payload = json.loads(SATZ_JSON.read_text(encoding="utf-8"))
        all_a1 = [it for it in satz_payload["items"] if it.get("level") == "a1"]
        for item in satz_payload["items"]:
            rid = item["id"]
            new = D.SATZ_MIRROR_REWRITES.get(rid) or D.SATZ_ONLY_REWRITES.get(rid)
            if not new:
                continue
            new_ko, new_de, new_en = new
            before = dict(item)
            after = dict(item)
            fields = []
            if after.get("targetKo") != new_ko:
                after["targetKo"] = new_ko; fields.append("targetKo")
            if after.get("promptDe") != new_de:
                after["promptDe"] = new_de; fields.append("promptDe")
            if after.get("promptEn") != new_en:
                after["promptEn"] = new_en; fields.append("promptEn")
            nd = _satz_distractors(new_ko, all_a1)
            if after.get("distractors") != nd:
                after["distractors"] = nd; fields.append("distractors")
            if fields:
                CHANGE_LOG.append({"kind": "satz", "id": rid, "level": item.get("level", ""),
                                    "fields": sorted(fields), "before": before, "after": after})

    by_kind = {}
    for c in CHANGE_LOG:
        by_kind.setdefault(c["kind"], []).append(c["id"])
    for kind, ids in by_kind.items():
        print(f"{kind}: {len(ids)} rows changed -> {sorted(ids)}")

    log_path = ROOT / "tools" / "content_factory" / "c2d_change_log.json"
    log_path.write_text(
        json.dumps(CHANGE_LOG, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(f"\nchange log written: {log_path} ({len(CHANGE_LOG)} entries)")


if __name__ == "__main__":
    main()
