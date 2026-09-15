#!/usr/bin/env python3
"""Promote C3 Batch 25 (A1 reinforcement, 64 words) from draft to live.

Batch 25 was fully authored and Jin-approved on 2026-09-15 ("batch_25_a1_
jin_sample 승인", 7/64-row sample packet at
docs/data/review_packets/batch_25_a1_jin_sample.md). Unlike
promote_batch24_supplement.py (which authored new vocab/cloze/satz content
inline), Batch 25's drafts already contain fully-authored content at
tools/content_factory/drafts/batch_25_a1_{rows.csv,cloze.json,satz.json}.
This script only:
  1. computes each pack's courseUnitId/canDoSegmentId (same lookup
     promote_batch24_supplement.py uses) and injects `courseUnitId` into the
     draft cloze/satz items (so draft == live, per
     validate_promoted_batch.py's exact-equality contract);
  2. adds the one missing clozeTopicUnitMap route (a1:einkaufen);
  3. appends the (now-identical) draft rows/items to the live assets;
  4. records can_do_content_authorities.json inheritedContentReferences and
     refreshes their vocab fingerprints;
  5. updates content_audit_manifest.json counts;
  6. writes the three review ledgers (상태=approved, Jin memo);
  7. flips the batch manifest to status=merged with structured Jin approval.

Run:  promote_batch25_a1_reinforcement.py check   (dry run, no writes)
      promote_batch25_a1_reinforcement.py apply
"""
from __future__ import annotations

import csv
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))
sys.path.insert(0, str(ROOT / "tools/content_factory"))

DRAFTS = ROOT / "tools/content_factory/drafts"
REVIEW = ROOT / "tools/content_factory/review"
VOCAB_CSV = ROOT / "assets/data/korean_vocab.csv"
CLOZE_JSON = ROOT / "assets/data/cloze.json"
SATZ_JSON = ROOT / "assets/data/satz_sentences.json"
CUR = ROOT / "assets/data/curriculum_manifest.json"
SEG = ROOT / "assets/data/can_do_segments.json"
AUTH = ROOT / "assets/data/can_do_content_authorities.json"
AUDIT = ROOT / "tools/content_factory/content_audit_manifest.json"
MANIFEST = DRAFTS / "batch_25_a1_reinforcement_manifest.json"

DRAFT_ROWS = DRAFTS / "batch_25_a1_rows.csv"
DRAFT_CLOZE = DRAFTS / "batch_25_a1_cloze.json"
DRAFT_SATZ = DRAFTS / "batch_25_a1_satz.json"

VOCAB_COLUMNS = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
MEMO = (
    "Jin 승인 2026-09-15 (owner chat: 'batch_25_a1_jin_sample 승인'; 7/64 표본); "
    "C3-T2 승격, Fable 배분어 위생 재선정"
)
APPROVAL = {
    "authority": "Jin",
    "approvedAt": "2026-09-15",
    "source": "owner chat: 'batch_25_a1_jin_sample 승인'",
    "sample": "7/64 rows",
}


def rj(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def wj(p: Path, v):
    p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_vocab_csv(p: Path):
    with p.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_vocab_csv(p: Path, rows):
    with p.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        w.writerow(VOCAB_COLUMNS)
        for r in rows:
            w.writerow([r[c] for c in VOCAB_COLUMNS])


def base_pack(pack_id: str) -> str:
    parts = pack_id.split("_")
    return "_".join(parts[:-1]) if parts and parts[-1].isdigit() else pack_id


def write_review_csv(path: Path, entries):
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(REVIEW_HEADER)
        for e in entries:
            w.writerow(e)


def main(apply: bool) -> None:
    draft_rows = read_vocab_csv(DRAFT_ROWS)
    draft_cloze = rj(DRAFT_CLOZE)["items"]
    draft_satz = rj(DRAFT_SATZ)["items"]
    manifest = rj(MANIFEST)

    live_rows = read_vocab_csv(VOCAB_CSV)
    live_korean = {r["korean"] for r in live_rows}
    live_ids = {r["id"] for r in live_rows}
    cloze_doc = rj(CLOZE_JSON)
    live_cloze = cloze_doc["items"]
    live_cloze_ids = {c["id"] for c in live_cloze}
    satz_doc = rj(SATZ_JSON)
    live_satz = satz_doc["items"]
    live_satz_ids = {s["id"] for s in live_satz}
    cur = rj(CUR)
    seg = rj(SEG)
    auth = rj(AUTH)
    audit = rj(AUDIT)

    problems = []
    for r in draft_rows:
        if r["korean"] in live_korean:
            problems.append(f"vocab {r['id']}: korean {r['korean']!r} already live")
        if r["id"] in live_ids:
            problems.append(f"vocab {r['id']}: id already live")
    for c in draft_cloze:
        if c["id"] in live_cloze_ids:
            problems.append(f"cloze {c['id']}: id already live")
    for s in draft_satz:
        if s["id"] in live_satz_ids:
            problems.append(f"satz {s['id']}: id already live")

    # -- courseUnitId / canDoSegmentId lookup (same as promote_batch24_supplement.py) --
    direct = {r["id"]: r for r in auth["contentReferences"] if r["kind"] == "vocabPack"}
    owner = {}
    for c in seg["contentClusters"]:
        for ref in c["contentReferences"]:
            if ref["kind"] == "vocabPack":
                owner.setdefault(ref["id"], c["id"])
    cl2seg = {cid: s for s in seg["segments"] for cid in s["contentClusterIds"]}

    pack_unit = {}
    pack_segment = {}
    packs = sorted({r["pack_id"] for r in draft_rows})
    for pack in packs:
        d = direct.get(pack)
        if d is None:
            problems.append(f"pack {pack}: no direct vocabPack content reference")
            continue
        s = cl2seg.get(owner.get(pack))
        if s is None or d["courseUnitId"] != s["parentCourseUnitId"] or d["level"] != "a1" or s["level"] != "a1":
            problems.append(f"pack {pack}: content-authority/segment mismatch")
            continue
        pack_unit[pack] = d["courseUnitId"]
        pack_segment[pack] = s["id"]

    rows_by_id = {r["id"]: r for r in draft_rows}

    # -- clozeTopicUnitMap coverage --
    ctu = cur["clozeTopicUnitMap"]
    needed_ctu = {}
    for c in draft_cloze:
        key = f"{c['level']}:{c['topic'].lower()}"
        if key not in ctu:
            pack = rows_by_id.get(c.get("sourceVocabId", ""), {}).get("pack_id")
            unit = pack_unit.get(pack)
            if unit is None:
                problems.append(f"cloze {c['id']}: missing clozeTopicUnitMap {key!r} and no pack-derived unit")
                continue
            needed_ctu.setdefault(key, unit)

    print(f"planned: {len(draft_rows)} vocab, {len(draft_cloze)} cloze, {len(draft_satz)} satz")
    print(f"new clozeTopicUnitMap entries: {needed_ctu}")
    print(f"problems: {len(problems)}")
    for p in problems:
        print("  !", p)
    if problems or not apply:
        return

    # -- inject courseUnitId into draft cloze/satz items (draft == live) --
    for c in draft_cloze:
        pack = rows_by_id[c["sourceVocabId"]]["pack_id"]
        c["courseUnitId"] = pack_unit[pack]
    for s in draft_satz:
        pack = rows_by_id[s["sourceVocabId"]]["pack_id"]
        s["courseUnitId"] = pack_unit[pack]
    wj(DRAFT_CLOZE, {"items": draft_cloze})
    wj(DRAFT_SATZ, {"items": draft_satz})

    # -- curriculum_manifest.json: add missing cloze topic routes --
    ctu.update(needed_ctu)
    wj(CUR, cur)

    # -- append to live assets (verbatim -- draft now == live projection) --
    live_rows.extend(draft_rows)
    write_vocab_csv(VOCAB_CSV, live_rows)
    live_cloze.extend(draft_cloze)
    cloze_doc["items"] = live_cloze
    cloze_doc["meta"]["total"] = len(live_cloze)
    cloze_doc["meta"]["perLevel"]["a1"] += len(draft_cloze)
    wj(CLOZE_JSON, cloze_doc)
    live_satz.extend(draft_satz)
    satz_doc["items"] = live_satz
    satz_doc["meta"]["total"] = len(live_satz)
    satz_doc["meta"]["perLevel"]["a1"] += len(draft_satz)
    wj(SATZ_JSON, satz_doc)

    # -- can_do_content_authorities.json inherited rows --
    inh = []
    for c in draft_cloze:
        pack = rows_by_id[c["sourceVocabId"]]["pack_id"]
        inh.append({
            "kind": "cloze", "id": c["id"], "sourceKind": "vocabPack", "sourceId": pack,
            "sourceVocabId": c["sourceVocabId"], "sourceVocabFingerprintSha256": "0" * 64,
            "level": "a1", "canDoSegmentId": pack_segment[pack], "courseUnitId": pack_unit[pack],
        })
    for s in draft_satz:
        pack = rows_by_id[s["sourceVocabId"]]["pack_id"]
        inh.append({
            "kind": "satz", "id": s["id"], "sourceKind": "vocabPack", "sourceId": pack,
            "sourceVocabId": s["sourceVocabId"], "sourceVocabFingerprintSha256": "0" * 64,
            "level": "a1", "canDoSegmentId": pack_segment[pack], "courseUnitId": pack_unit[pack],
        })

    def insert_sorted(lst, item, key):
        keys = [key(x) for x in lst]
        import bisect
        if keys == sorted(keys):
            lst.insert(bisect.bisect_left(keys, key(item)), item)
        else:
            lst.append(item)

    lst = auth["coverage"]["inheritedContentReferences"]
    existing = {(x["kind"], x["id"]) for x in lst}
    for row in inh:
        assert (row["kind"], row["id"]) not in existing, row
        insert_sorted(lst, row, key=lambda x: (x["kind"], x["id"]))
    for kind in ("cloze", "satz"):
        auth["coverage"]["inheritedReferenceCounts"][kind] = sum(1 for x in lst if x["kind"] == kind)
    wj(AUTH, auth)

    # -- content_audit_manifest.json counts --
    counts = {"vocab": len(live_rows), "cloze": len(live_cloze), "satz": len(live_satz)}
    for src in audit["sources"]:
        if src["kind"] in counts:
            src["count"] = counts[src["kind"]]
    wj(AUDIT, audit)

    # -- review ledgers --
    REVIEW.mkdir(parents=True, exist_ok=True)
    vocab_entries = [
        (r["id"], "A1", r["korean"], r["german"], r["english"],
         f"rights: original_clean_room; pack={r['pack_id']}; order={r['pack_order']}; boss=false; "
         f"seed: NIKL 2017 kiiq grade-1 headword selection (KOGL 1유형); C3 Batch 25 A1 reinforcement",
         "approved", MEMO)
        for r in draft_rows
    ]
    cloze_entries = [
        (c["id"], "a1", c["fullKo"], c["de"], c["en"],
         f"rights: original_clean_room; answer={c['answer']}; topic={c['topic']}; unit={c['courseUnitId']}; "
         f"derived from {c['sourceVocabId']}",
         "approved", MEMO)
        for c in draft_cloze
    ]
    satz_entries = [
        (s["id"], "a1", s["targetKo"], s["promptDe"], s["promptEn"],
         f"rights: original_clean_room; vocabKo={s['vocabKo']}; unit={s['courseUnitId']}; "
         f"source {s['sourceVocabId']}",
         "approved", MEMO)
        for s in draft_satz
    ]
    write_review_csv(REVIEW / "batch_25_a1_vocab_review.csv", vocab_entries)
    write_review_csv(REVIEW / "batch_25_a1_cloze_review.csv", cloze_entries)
    write_review_csv(REVIEW / "batch_25_a1_satz_review.csv", satz_entries)

    # -- manifest: flip to merged + structured approval --
    manifest["status"] = "merged"
    manifest["provenance"]["approval"] = APPROVAL
    manifest["artifacts"][0]["collection"] = None
    manifest["artifacts"][0]["review"] = "tools/content_factory/review/batch_25_a1_vocab_review.csv"
    manifest["artifacts"][1]["collection"] = "items"
    manifest["artifacts"][1]["review"] = "tools/content_factory/review/batch_25_a1_cloze_review.csv"
    manifest["artifacts"][2]["collection"] = "items"
    manifest["artifacts"][2]["review"] = "tools/content_factory/review/batch_25_a1_satz_review.csv"
    manifest["promotion"] = {
        "runtime": True,
        "assetsDataWritten": True,
        "tts": False,
        "firebase": False,
        "note": (
            "Promoted 2026-09-15 (C3-T2) after Jin approval. TTS synthesis pending "
            "-- run tool/generate_tts.py --missing-from-storage before this batch's "
            "audio is available (no OS-voice fallback)."
        ),
    }
    wj(MANIFEST, manifest)

    # -- fingerprints + sanity --
    proc = subprocess.run(
        [sys.executable, "tool/refresh_can_do_vocab_fingerprints.py"],
        cwd=ROOT, capture_output=True, text=True,
    )
    print("refresh_can_do_vocab_fingerprints:", proc.stdout.strip()[-500:], proc.stderr.strip()[-500:])

    from relevel_bundle import check_can_do_consistency
    print("can-do issues:", check_can_do_consistency(ROOT))

    from relevel_vocab import write_pack_map
    write_pack_map(read_vocab_csv(VOCAB_CSV), ROOT / "docs/data/vocab_pack_map.md")

    print("done:", counts)


if __name__ == "__main__":
    main(apply=(len(sys.argv) > 1 and sys.argv[1] == "apply"))
