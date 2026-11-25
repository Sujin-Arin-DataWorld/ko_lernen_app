#!/usr/bin/env python3
"""Register the 16 new A2 packs of Batches 32-34 before promotion.

promote_a1_reinforcement_batch.py requires every pack to already have a
direct vocabPack content authority (can_do_content_authorities.json), an
owning content cluster (can_do_segments.json) whose segment's parent unit
matches it, and a vocabPackUnitMap route for the pack's base id
(curriculum_manifest.json). Batch 30's promotion did this by hand; this is
the same registration, done once and idempotently (2026-11-25, Jin approved
the Batch 32-34 samples). Cluster choice follows the existing base-id unit
routes where a base already exists (a2_food/a2_clothing/a2_feelings/
a2_weather*), otherwise the closest A2 can-do cluster by topic. Also keeps the
authority sourceSeeds list and coverage.directReferenceCounts.vocabPack in step.

Run:  register_a2_packs_batches_32_34.py [--check]
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SEG = ROOT / "assets/data/can_do_segments.json"
AUTH = ROOT / "assets/data/can_do_content_authorities.json"
CUR = ROOT / "assets/data/curriculum_manifest.json"

PACK_CLUSTER = {
    "a2_body_1": "cluster_a2_feeling_sick_v1",
    "a2_food_3": "cluster_a2_cafe_starbucks_basic_v1",
    "a2_clothing_2": "cluster_a2_myeongdong_shopping_v1",
    "a2_travel_1": "cluster_a2_taxi_street_v1",
    "a2_school_1": "cluster_a2_cafe_study_v1",
    "a2_daily_actions_1": "cluster_a2_haeyo_register_transition_v1",
    "a2_health_symptoms_1": "cluster_a2_pharmacy_headache_v1",
    "a2_feelings_3": "cluster_a2_feeling_sick_v1",
    "a2_directions_1": "cluster_a2_subway_directions_v1",
    "a2_workplace_1": "cluster_a2_cafe_study_v1",
    "a2_events_1": "cluster_a2_friend_birthday_v1",
    "a2_problems_help_1": "cluster_a2_lost_phone_v1",
    "a2_dishes_1": "cluster_a2_cafe_starbucks_basic_v1",
    "a2_home_routines_1": "cluster_a2_rent_bank_transfer_v1",
    "a2_time_span_1": "cluster_a2_plans_with_friend_v1",
    "a2_weather_sky_1": "cluster_a2_running_late_v1",
}


def load(p):
    return json.loads(p.read_text(encoding="utf-8"))


def dump(p, v):
    p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def base_id(pack: str) -> str:
    return re.sub(r"_\d+$", "", pack)


def main(check: bool) -> None:
    seg, auth, cur = load(SEG), load(AUTH), load(CUR)
    unit_of_cluster = {cid: s["parentCourseUnitId"] for s in seg["segments"] for cid in s["contentClusterIds"]}
    clusters = {c["id"]: c for c in seg["contentClusters"]}
    refs = auth["contentReferences"]
    direct = {r["id"] for r in refs if r["kind"] == "vocabPack"}
    vmap = cur["vocabPackUnitMap"]
    added = []
    for pack, cid in PACK_CLUSTER.items():
        unit = unit_of_cluster[cid]
        base = base_id(pack)
        if base in vmap and vmap[base] != unit:
            raise SystemExit(f"{pack}: base {base} routes to {vmap[base]}, cluster {cid} is in {unit}")
        seed = f"seed_vocab_pack_{pack}_v1"
        if pack not in direct:
            last = max(i for i, r in enumerate(refs) if r["kind"] == "vocabPack")
            refs.insert(last + 1, {"kind": "vocabPack", "id": pack, "level": "a2",
                                   "sourceSeedId": seed, "courseUnitId": unit})
            direct.add(pack)
            added.append(f"authority {pack} -> {unit}")
        c = clusters[cid]
        if not any(r["kind"] == "vocabPack" and r["id"] == pack for r in c["contentReferences"]):
            c["contentReferences"].append({"kind": "vocabPack", "id": pack})
            if seed not in c["sourceSeedIds"]:
                c["sourceSeedIds"].append(seed)
            c["revision"] = c.get("revision", 1) + 1
            added.append(f"cluster {cid} += {pack}")
        if base not in vmap:
            vmap[base] = unit
            added.append(f"unit map {base} -> {unit}")
        seeds = auth["sourceSeeds"]
        if not any(x["id"] == seed for x in seeds):
            last = max(i for i, x in enumerate(seeds) if x["id"].startswith("seed_vocab_pack_"))
            seeds.insert(last + 1, {"id": seed, "level": "a2"})
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
