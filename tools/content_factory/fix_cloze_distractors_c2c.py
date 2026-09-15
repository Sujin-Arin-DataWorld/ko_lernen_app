#!/usr/bin/env python3
"""C2c -- fix mechanically-flagged cloze distractors (D1/D2/D3/D4/D6).

Only replaces the SPECIFIC distractor(s) `audit_cloze_distractors.audit_item`
flags on each item -- distractors that already pass every rule are kept
untouched. KO/DE/EN fields (sentenceKo/answer/fullKo/de/en) are never
touched; only the `distractors` array can change (verified separately by
the caller via a KO/DE/EN-only diff check).

Candidate sourcing (per Fable's C2c brief, "re-pick from the same level's
live vocabulary, matching level <= item level"):
  * D2 (particle-attached answer, e.g. "여기에서"): construct candidates by
    appending the SAME particle suffix to other same-or-lower-level nouns
    (no bare vocab headword already ends in an attached particle).
  * verb/adjective-shaped answer (ending_signature resolves, incl.
    multi-word whole-predicate answers): candidates are OTHER live cloze
    items' `answer` fields (already-attested, correctly conjugated Korean)
    at or below the item's level that share the same ending (or the same
    -(으)ㄹ adnominal shape) -- not vocab.csv, whose verb/adjective rows are
    dictionary-form only. Falls back to the generalized predicate-slot
    waiver pool (dictionary-form verbs/adjectives + bare particles) when
    too few same-ending candidates exist.
  * bare noun/adverb/pronoun/expression answer: candidates are
    korean_vocab.csv rows of the same coarse POS, level <= item level,
    preferring a different `topic` than the answer's own pack topic.

Every candidate must additionally satisfy D1 (batchim class), D4 (not an
activity noun in an N+하다/배우다/잘하다 slot) and D6 (not in the sentence
remainder, not a duplicate, not the answer, under the per-level reuse cap)
regardless of which rule originally flagged the item -- a holistic re-pick,
not a narrow single-rule patch. Selection is deterministic (seeded by item
id) so reruns are stable.

Usage:
    python tools/content_factory/fix_cloze_distractors_c2c.py            # dry run
    python tools/content_factory/fix_cloze_distractors_c2c.py --apply    # write cloze.json + changes CSV
"""
from __future__ import annotations

import csv
import hashlib
import json
import random
import sys
from pathlib import Path

import cloze_distractor_rules as R
from audit_cloze_distractors import audit_item

ROOT = R.REPO_ROOT
CLOZE = ROOT / "assets/data/cloze.json"
CHANGES_CSV = ROOT / "docs/data/c2c_cloze_distractor_changes.csv"


def bad_set_for(result: dict) -> set[str]:
    bad = set()
    bad.update(result["d1_bad"])
    bad.update(result["d2_bad"])
    bad.update(result["d3_bad"])
    bad.update(result["d4_bad"])
    bad.update(result["d6_exposed"])
    bad.update(result["d6_equals_answer"])
    return bad


def triggered_rules(result: dict) -> list[str]:
    rules = []
    if result["d1_bad"]:
        rules.append("D1")
    if result["d2_bad"]:
        rules.append("D2")
    if result["d3_bad"]:
        rules.append("D3")
    if result["d4_bad"]:
        rules.append("D4")
    if result["d6_exposed"] or result["d6_duplicates"] or result["d6_equals_answer"]:
        rules.append("D6")
    return rules


def gather_verbadj_candidates(answer, a_sig, level_rank, answer_snapshot):
    use_rieul = R.rieul_adnominal_ending(answer)
    cands = []
    for word, level in answer_snapshot:
        if word == answer or R.level_rank(level) > level_rank:
            continue
        if a_sig in R.ending_signatures(word):
            cands.append(word)
        elif use_rieul and R.rieul_adnominal_ending(word):
            cands.append(word)
    return sorted(set(cands))


def gather_nominal_candidates(answer, coarse, level_rank, vocab, answer_topic):
    cands, relaxed = [], []
    for lv in R.LEVEL_ORDER[: level_rank + 1]:
        for row in vocab.by_level.get(lv, []):
            w = row["korean"].strip()
            if not w or w == answer or " " in w:
                continue
            if R.coarse_pos(w, vocab) != coarse:
                continue
            relaxed.append(w)
            if answer_topic and row.get("topic") == answer_topic:
                continue
            cands.append(w)
    pool = cands if len(cands) >= 8 else relaxed
    return sorted(set(pool))


def pick_replacements(it, bad, vocab, answer_snapshot, reuse, rng):
    answer, sentence, level = it["answer"], it["sentenceKo"], it["level"]
    level_rank = R.level_rank(level)
    keep = [d for d in it["distractors"] if d not in bad]
    need = 3 - len(keep)
    if need <= 0:
        return keep[:3], "unchanged"

    a_sig = R.ending_signature(answer)
    d1_kind, required_class = R.detect_required_class(sentence, answer)
    particle_suffix = R.matching_particle_suffix(answer, vocab)
    activity = R.is_activity_slot(sentence)
    activity_nouns = R.ACTIVITY_NOUN_SET | vocab.hada_activity_nouns
    remainder = R.sentence_remainder(sentence)

    if particle_suffix:
        base = {r["korean"].strip() for r in vocab.by_level_pos.get((level, "Nomen"), [])}
        for lv in R.LEVEL_ORDER[: level_rank + 1]:
            base |= {r["korean"].strip() for r in vocab.by_level_pos.get((lv, "Nomen"), [])}
        pool = sorted({w + particle_suffix for w in base if len(w) >= 2})
        pool_kind = "particle-attached"
    elif a_sig is not None:
        pool = gather_verbadj_candidates(answer, a_sig, level_rank, answer_snapshot)
        pool_kind = "verbadj-reuse"
    else:
        coarse = R.coarse_pos(answer, vocab)
        arow = vocab.by_word.get(answer)
        answer_topic = arow[0].get("topic") if arow else None
        pool = gather_nominal_candidates(answer, coarse, level_rank, vocab, answer_topic)
        pool_kind = "vocab-noun"

    def viable(c: str) -> bool:
        if c in keep or c == answer or (c and c in remainder):
            return False
        if particle_suffix and not c.endswith(particle_suffix):
            return False
        if required_class is not None:
            bc = R.batchim_class(c, d1_kind)
            if bc is not None and bc != required_class:
                return False
        if activity and c in activity_nouns:
            return False
        if reuse.count(level, c) >= reuse.LIMIT_PER_LEVEL:
            return False
        return True

    cands = [c for c in pool if viable(c)]
    rng.shuffle(cands)
    chosen: list[str] = []
    for c in cands:
        if len(chosen) >= need:
            break
        if c not in chosen:
            chosen.append(c)

    if len(chosen) < need and a_sig is not None and not particle_suffix:
        waiver_pool = sorted(R.DICTIONARY_FORM_VERBS | R.BARE_PARTICLES)
        rng.shuffle(waiver_pool)
        for c in waiver_pool:
            if len(chosen) >= need:
                break
            if viable(c) and c not in chosen:
                chosen.append(c)
        pool_kind += "+waiver"

    if len(chosen) < need:
        return None, f"UNRESOLVED need={need} pool={len(cands)} kind={pool_kind}"
    return keep + chosen[:need], pool_kind


def main(apply: bool) -> None:
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = data["items"]
    vocab = R.VocabIndex(R.load_vocab_rows())
    answer_snapshot = [(it["answer"], it["level"]) for it in items]

    reuse = R.ReuseTracker()
    for it in items:
        reuse.record(it["level"], it["distractors"])

    rows, unresolved = [], []
    for it in items:
        result = audit_item(it, vocab)
        bad = bad_set_for(result)
        if not bad:
            continue
        seed = int(hashlib.sha1(it["id"].encode()).hexdigest(), 16)
        rng = random.Random(seed)
        new_distractors, note = pick_replacements(it, bad, vocab, answer_snapshot, reuse, rng)
        if new_distractors is None:
            unresolved.append((it["id"], note))
            continue
        old_distractors = list(it["distractors"])
        if new_distractors != old_distractors:
            reuse.record(it["level"], [d for d in new_distractors if d not in old_distractors])
            rows.append({
                "id": it["id"],
                "level": it["level"],
                "old": " | ".join(old_distractors),
                "new": " | ".join(new_distractors),
                "rules": ",".join(triggered_rules(result)),
            })
            it["distractors"] = new_distractors

    print(f"items changed: {len(rows)}, unresolved: {len(unresolved)}")
    for u in unresolved[:20]:
        print("  UNRESOLVED", u)

    if apply:
        CLOZE.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        CHANGES_CSV.parent.mkdir(parents=True, exist_ok=True)
        with CHANGES_CSV.open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["id", "level", "old", "new", "rules"])
            w.writeheader()
            w.writerows(rows)
        print(f"written {CLOZE} and {CHANGES_CSV}")


if __name__ == "__main__":
    main(apply="--apply" in sys.argv)
