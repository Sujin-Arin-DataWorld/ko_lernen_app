#!/usr/bin/env python3
"""Batch 24 P1 — cloze distractor hygiene (deterministic, all levels).

Rules enforced per cloze item (mirrors tool/audit_content_naturalness.py
particle_mismatch and test/cloze_content_guard_test.dart distractor guard):
  * a distractor directly before 이/가·은/는·을/를·과/와 must carry the same
    batchim class as the particle demands;
  * no distractor may be a substring of sentenceKo (exposed in the remainder);
  * distractors stay 3, distinct, != answer.
Only offending distractors are replaced, and only for items whose answer is
a *noun headword of the same level* in korean_vocab.csv (pos_de == Nomen).
Expression, verb, inflected-stem and multiword answers are skipped: the
vocabulary has no same-class pool for them, so a rule-based swap would put an
unrelated noun into a verb slot (PR #288 review, cloze_b2_0204 "다시 여쭤보").
Those items are curated by hand per pack (see F10 2026-09-09, Batch 24).
Replacement pool = noun headwords of the same level, a different topic than
the answer's pack topic, 2+ syllables, single token, not in the sentence, not
already used.  Selection is deterministic (seeded by item id) so reruns are
stable.
"""
from __future__ import annotations
import csv, json, random, sys, hashlib
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))
from audit_content_naturalness import PARTICLE_BATCHIM, find_particle_after_blank, has_batchim  # noqa: E402

CLOZE = ROOT / "assets/data/cloze.json"
VOCAB = ROOT / "assets/data/korean_vocab.csv"
BLANK = "＿＿＿"


def syllables(s):
    return sum(1 for ch in s if 0xAC00 <= ord(ch) <= 0xD7A3)


def main(apply: bool) -> None:
    rows = list(csv.DictReader(VOCAB.open(encoding="utf-8", newline="")))
    by_level_pos = defaultdict(list)
    info = {}
    for r in rows:
        lv = r["level"].lower()
        info[(lv, r["korean"])] = r
        if " " in r["korean"] or syllables(r["korean"]) < 2:
            continue
        by_level_pos[(lv, r["pos_de"])].append(r)
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    changed = 0; slots = 0; unresolved = []; skipped_non_noun = 0
    for it in data["items"]:
        lv = it["level"]; s = it["sentenceKo"]; a = it["answer"]
        particle = find_particle_after_blank(s)
        need = PARTICLE_BATCHIM[particle] if particle else None
        bad = []
        for d in it["distractors"]:
            exposed = d in s
            bc = has_batchim(d)
            mismatch = need is not None and bc is not None and bc != need
            if exposed or mismatch or d == a:
                bad.append(d)
        if not bad:
            continue
        arow = info.get((lv, a))
        if arow is None or arow["pos_de"] != "Nomen":
            # Not a same-level noun headword: no same-class pool exists, so
            # leave the reviewed distractors alone (hand curation only).
            skipped_non_noun += 1
            continue
        pool = by_level_pos.get((lv, "Nomen"), [])
        atopic = arow["topic"]
        keep = [d for d in it["distractors"] if d not in bad]
        rng = random.Random(int(hashlib.sha1(it["id"].encode()).hexdigest(), 16))
        cands = [r["korean"] for r in pool
                 if r["korean"] != a and r["korean"] not in keep and r["korean"] not in s
                 and not (atopic and r["topic"] == atopic)
                 and (need is None or has_batchim(r["korean"]) == need)
                 and r["korean"] not in a and a not in r["korean"]]
        cands = sorted(set(cands)); rng.shuffle(cands)
        new = list(keep)
        for c in cands:
            if len(new) >= 3:
                break
            new.append(c)
        if len(new) < 3:
            unresolved.append((it["id"], bad, len(cands)))
            continue
        slots += len(bad); changed += 1
        it["distractors"] = new
    print(f"items changed: {changed}, distractor slots replaced: {slots}, unresolved: {len(unresolved)}, skipped (non-noun-headword answer): {skipped_non_noun}")
    for u in unresolved[:10]:
        print("  unresolved", u)
    if apply:
        CLOZE.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("written")


if __name__ == "__main__":
    main(apply="--apply" in sys.argv)
