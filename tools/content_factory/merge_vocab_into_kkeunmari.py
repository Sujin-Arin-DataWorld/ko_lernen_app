#!/usr/bin/env python3
"""merge_vocab_into_kkeunmari.py — Kkeunmari-Pool OHNE externe API-Keys erweitern.

Statt stdict/DeepL (Keys nötig) mergen wir die bereits muttersprachlich
geprüften NOMEN aus korean_vocab.csv (haben schon de+en Glossen) in den Pool.
§0-sicher: keine neue Übersetzung, keine Halluzination — nur echte, geglosste
Nomen. next_count/is_dead_end werden über die GESAMTE gemergte Menge neu
berechnet (dieselbe Regel wie build_kkeunmari_pool.py: last-Silbe → first-Silbe,
exakter Silben-Match, Selbstbezug abgezogen).

Nutzung:
    python3 tools/content_factory/merge_vocab_into_kkeunmari.py          # Dry-Run
    python3 tools/content_factory/merge_vocab_into_kkeunmari.py --write  # schreiben
"""
import csv
import json
import os
import sys
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
POOL = os.path.join(ROOT, "assets", "data", "kkeunmari_pool.json")
VOCAB = os.path.join(ROOT, "assets", "data", "korean_vocab.csv")


def is_hangul_word(w):
    return len(w) >= 2 and all("가" <= c <= "힣" for c in w)


def recompute(entries):
    """next_count/is_dead_end über die Menge neu berechnen (build_kkeunmari_pool-Regel)."""
    firstcnt = Counter(e["word"][0] for e in entries)
    for e in entries:
        w = e["word"]
        nc = firstcnt.get(w[-1], 0) - (1 if w[0] == w[-1] else 0)
        e["first"] = w[0]
        e["last"] = w[-1]
        e["next_count"] = nc
        e["is_dead_end"] = nc == 0
    return entries


def main():
    pool = json.load(open(POOL, encoding="utf-8"))
    entries = pool["words"]
    existing = {e["word"] for e in entries}

    rows = list(csv.DictReader(open(VOCAB, encoding="utf-8")))
    added = 0
    skipped = {"not_noun": 0, "not_word": 0, "no_gloss": 0, "dupe": 0}
    for r in rows:
        w = r["korean"].strip()
        if r["pos_de"].strip() != "Nomen":
            skipped["not_noun"] += 1
            continue
        if not is_hangul_word(w):
            skipped["not_word"] += 1
            continue
        if not r["german"].strip():
            skipped["no_gloss"] += 1
            continue
        if w in existing:
            skipped["dupe"] += 1
            continue
        existing.add(w)
        entries.append({
            "word": w,
            "first": w[0],
            "last": w[-1],
            "level": r["level"].strip(),
            "german": r["german"].strip(),
            "topic": r["topic"].strip() or "Vokabel",
            "next_count": 0,
            "is_dead_end": True,
        })
        added += 1

    recompute(entries)

    dead = sum(1 for e in entries if e["is_dead_end"])
    start = sum(1 for e in entries if e["next_count"] >= 2)
    from collections import Counter as C
    by_level = C(e["level"] for e in entries)
    print(f"기존 {len(entries) - added} + 추가 {added} = 총 {len(entries)}")
    print(f"  레벨: {dict(sorted(by_level.items()))}")
    print(f"  dead-end {dead} ({dead * 100 // len(entries)}%) · startable(≥2) {start}")
    print(f"  vocab 건너뜀: {skipped}")

    if "--write" in sys.argv:
        pool["meta"]["total"] = len(entries)
        pool["meta"]["merge_2026_07_vocab"] = (
            f"korean_vocab.csv Nomen (geprüfte de/en-Glossen) gemergt: +{added} → "
            f"{len(entries)}. Keine neue Übersetzung (§0). next_count/is_dead_end "
            f"über die Gesamtmenge neu berechnet."
        )
        pool["words"] = entries
        with open(POOL, "w", encoding="utf-8") as f:
            json.dump(pool, f, ensure_ascii=False, indent=1)
        print(f"\n✅ geschrieben: {POOL}")
    else:
        print("\n(Dry-Run — mit --write speichern)")


if __name__ == "__main__":
    main()
