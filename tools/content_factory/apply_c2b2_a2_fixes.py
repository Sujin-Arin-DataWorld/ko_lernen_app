#!/usr/bin/env python3
"""C2b-2 (2026-09-15) step 4 — apply the REWRITES table in
c2b2_rewrite_data.py to korean_vocab.csv and propagate to the matching
cloze.json/satz_sentences.json mirrors (matched by OLD example_korean/
fullKo/targetKo text equality, since there is no explicit vocab<->cloze/
satz id link in this schema). Writes docs/data/c2b2_a2_translation_changes.csv
(id, field, old, new, rule) for every changed field across all three files.

Usage:
    PYTHONIOENCODING=utf-8 python tools/content_factory/apply_c2b2_a2_fixes.py
"""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))
from c2b2_rewrite_data import REWRITES  # noqa: E402

VOCAB_CSV = ROOT / "assets" / "data" / "korean_vocab.csv"
CLOZE_JSON = ROOT / "assets" / "data" / "cloze.json"
SATZ_JSON = ROOT / "assets" / "data" / "satz_sentences.json"
CHANGES_CSV = ROOT / "docs" / "data" / "c2b2_a2_translation_changes.csv"


def main() -> int:
    changes: list[tuple[str, str, str, str, str]] = []  # id, field, old, new, rule
    unresolved: list[str] = []

    # --- vocab ---
    with VOCAB_CSV.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        fieldnames = reader.fieldnames
        rows = list(reader)
    old_ko_by_id: dict[str, str] = {}
    for row in rows:
        rid = row.get("id", "")
        spec = REWRITES.get(rid)
        if not spec:
            continue
        old_ko_by_id[rid] = row.get("example_korean", "")
        for field, key in (("example_korean", "ko"), ("example_german", "de"), ("example_english", "en")):
            new_val = spec.get(key)
            if new_val is None:
                continue
            old_val = row.get(field, "")
            if old_val != new_val:
                changes.append((rid, field, old_val, new_val, f"{spec['category']}: {spec['rule']}"))
                row[field] = new_val
    with VOCAB_CSV.open("w", encoding="utf-8", newline="\n") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

    # --- cloze.json (match by OLD fullKo) ---
    cloze_root = json.loads(CLOZE_JSON.read_text(encoding="utf-8"))
    cloze_by_old_text: dict[str, list[dict]] = {}
    for item in cloze_root["items"]:
        cloze_by_old_text.setdefault(item.get("fullKo", ""), []).append(item)
    for rid, spec in REWRITES.items():
        old_ko = old_ko_by_id.get(rid)
        if old_ko is None:
            continue
        for item in cloze_by_old_text.get(old_ko, []):
            new_ko = spec.get("ko")
            if new_ko and new_ko != item.get("fullKo"):
                changes.append((item["id"], "fullKo", item.get("fullKo", ""), new_ko, f"mirrors {rid}"))
                item["fullKo"] = new_ko
                answer = item.get("answer", "")
                if answer and answer in new_ko:
                    new_blank = new_ko.replace(answer, "＿＿＿", 1)
                    if new_blank != item.get("sentenceKo"):
                        changes.append((item["id"], "sentenceKo", item.get("sentenceKo", ""), new_blank, f"mirrors {rid} (re-blanked)"))
                        item["sentenceKo"] = new_blank
                else:
                    unresolved.append(f"cloze {item['id']} (answer {answer!r} not found in new fullKo, sentenceKo NOT recomputed -- needs manual check)")
            for field, key in (("de", "de"), ("en", "en")):
                new_val = spec.get(key)
                if new_val is None:
                    continue
                if item.get(field) != new_val:
                    changes.append((item["id"], field, item.get(field, ""), new_val, f"mirrors {rid}"))
                    item[field] = new_val
    CLOZE_JSON.write_text(json.dumps(cloze_root, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")

    # --- satz_sentences.json (match by OLD targetKo) ---
    satz_root = json.loads(SATZ_JSON.read_text(encoding="utf-8"))
    satz_by_old_text: dict[str, list[dict]] = {}
    for item in satz_root["items"]:
        satz_by_old_text.setdefault(item.get("targetKo", ""), []).append(item)
    for rid, spec in REWRITES.items():
        old_ko = old_ko_by_id.get(rid)
        if old_ko is None:
            continue
        for item in satz_by_old_text.get(old_ko, []):
            new_ko = spec.get("ko")
            if new_ko and new_ko != item.get("targetKo"):
                changes.append((item["id"], "targetKo", item.get("targetKo", ""), new_ko, f"mirrors {rid}"))
                item["targetKo"] = new_ko
            for field, key in (("promptDe", "de"), ("promptEn", "en")):
                new_val = spec.get(key)
                if new_val is None:
                    continue
                if item.get(field) != new_val:
                    changes.append((item["id"], field, item.get(field, ""), new_val, f"mirrors {rid}"))
                    item[field] = new_val
    SATZ_JSON.write_text(json.dumps(satz_root, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")

    # --- report which vocab ids had NO cloze/satz mirror found (expected for
    # some rows -- not every vocab row has one) ---
    missing_mirrors = []
    for rid in REWRITES:
        old_ko = old_ko_by_id.get(rid)
        if old_ko is None:
            missing_mirrors.append(f"{rid}: not found in korean_vocab.csv at all")
            continue
        if not cloze_by_old_text.get(old_ko):
            missing_mirrors.append(f"{rid}: no cloze.json mirror (fullKo match)")
        if not satz_by_old_text.get(old_ko):
            missing_mirrors.append(f"{rid}: no satz_sentences.json mirror (targetKo match)")

    CHANGES_CSV.parent.mkdir(parents=True, exist_ok=True)
    with CHANGES_CSV.open("w", encoding="utf-8", newline="\n") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(["id", "field", "old", "new", "rule"])
        for row in changes:
            writer.writerow(row)

    print(f"vocab rows targeted: {len(REWRITES)}")
    print(f"total field changes recorded: {len(changes)}")
    print(f"changes CSV: {CHANGES_CSV}")
    if missing_mirrors:
        print("missing mirrors:")
        for m in missing_mirrors:
            print(" -", m)
    if unresolved:
        print("unresolved cloze re-blank (needs manual check):")
        for u in unresolved:
            print(" -", u)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
