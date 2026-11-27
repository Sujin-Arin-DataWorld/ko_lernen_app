#!/usr/bin/env python3
"""Register the new packs of Batches 43 (B1), 44 (C1) and 45 (A2) before promotion.

promote_a1_reinforcement_batch.py requires every pack to already have a
direct vocabPack content authority (can_do_content_authorities.json) and an
owning content cluster (can_do_segments.json) whose segment's parent unit
matches it. Same registration as register_a2_packs_batches_32_34.py, but
level-aware and sibling-driven (Jin approved all three samples 2026-11-27):

- A new partial of an existing base (a2_food_4, b1_daily_4, ...) joins the
  cluster that owns its lowest live sibling, so the base keeps one unit.
- c1_work_economy_1 is the only new base; it joins the C1 inclusive and
  sustainable systems unit (cluster_c1_local_tradeoff_adaptation_v1), the
  closest can-do topic for jobs, income and the economy, and gets a new
  vocabPackUnitMap route.

Also keeps the authority sourceSeeds list and
coverage.directReferenceCounts.vocabPack in step. Idempotent.

Run:  register_reinforcement_packs_batches_43_45.py [--check]
"""
from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SEG = ROOT / "assets/data/can_do_segments.json"
AUTH = ROOT / "assets/data/can_do_content_authorities.json"
CUR = ROOT / "assets/data/curriculum_manifest.json"
DRAFTS = ROOT / "tools/content_factory/drafts"
BATCH_ROWS = ("batch_43_b1_rows.csv", "batch_44_c1_rows.csv", "batch_45_a2_rows.csv")
EXPLICIT_CLUSTER = {"c1_work_economy_1": "cluster_c1_local_tradeoff_adaptation_v1"}


def load(p):
    return json.loads(p.read_text(encoding="utf-8"))


def dump(p, v):
    p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def base_id(pack: str) -> str:
    return re.sub(r"_\d+$", "", pack)


def batch_packs() -> list[str]:
    packs = set()
    for name in BATCH_ROWS:
        with (DRAFTS / name).open(encoding="utf-8", newline="") as f:
            packs |= {r["pack_id"] for r in csv.DictReader(f)}
    return sorted(packs)


def main(check: bool) -> None:
    seg, auth, cur = load(SEG), load(AUTH), load(CUR)
    unit_of_cluster = {cid: s["parentCourseUnitId"] for s in seg["segments"] for cid in s["contentClusterIds"]}
    clusters = {c["id"]: c for c in seg["contentClusters"]}
    owner = {}
    for c in seg["contentClusters"]:
        for ref in c["contentReferences"]:
            if ref["kind"] == "vocabPack":
                owner.setdefault(ref["id"], c["id"])
    refs = auth["contentReferences"]
    direct = {r["id"] for r in refs if r["kind"] == "vocabPack"}
    vmap = cur["vocabPackUnitMap"]
    added = []
    for pack in batch_packs():
        if pack in direct and pack in owner:
            continue
        level = pack.split("_", 1)[0]
        siblings = sorted(p for p in owner if base_id(p) == base_id(pack) and p != pack)
        cid = EXPLICIT_CLUSTER.get(pack) or (owner[siblings[0]] if siblings else None)
        if cid is None:
            raise SystemExit(f"{pack}: no sibling cluster and no explicit cluster")
        unit = unit_of_cluster[cid]
        base = base_id(pack)
        if not siblings and base in vmap and vmap[base] != unit:
            raise SystemExit(f"{pack}: base {base} routes to {vmap[base]}, cluster {cid} is in {unit}")
        seed = f"seed_vocab_pack_{pack}_v1"
        if pack not in direct:
            last = max(i for i, r in enumerate(refs) if r["kind"] == "vocabPack")
            refs.insert(last + 1, {"kind": "vocabPack", "id": pack, "level": level,
                                   "sourceSeedId": seed, "courseUnitId": unit})
            direct.add(pack)
            added.append(f"authority {pack} -> {unit}")
        c = clusters[cid]
        if not any(r["kind"] == "vocabPack" and r["id"] == pack for r in c["contentReferences"]):
            c["contentReferences"].append({"kind": "vocabPack", "id": pack})
            if seed not in c["sourceSeedIds"]:
                c["sourceSeedIds"].append(seed)
            c["revision"] = c.get("revision", 1) + 1
            owner[pack] = cid
            added.append(f"cluster {cid} += {pack}")
        if base not in vmap:
            vmap[base] = unit
            added.append(f"unit map {base} -> {unit}")
        seeds = auth["sourceSeeds"]
        if not any(x["id"] == seed for x in seeds):
            last = max(i for i, x in enumerate(seeds) if x["id"].startswith("seed_vocab_pack_"))
            seeds.insert(last + 1, {"id": seed, "level": level})
            added.append(f"authority seed {seed}")
    counts = auth["coverage"]["directReferenceCounts"]
    actual = sum(1 for r in refs if r["kind"] == "vocabPack")
    if counts["vocabPack"] != actual:
        added.append(f"coverage vocabPack {counts['vocabPack']} -> {actual}")
        counts["vocabPack"] = actual
    for line in added:
        print(line)
    if not check:
        dump(SEG, seg)
        dump(AUTH, auth)
        dump(CUR, cur)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    main(ap.parse_args().check)
