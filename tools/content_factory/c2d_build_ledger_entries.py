#!/usr/bin/env python3
"""Build promoted_copy_revisions_20260822.json entries for the C2d rewrite,
using the TRUE historical draft files (not git HEAD) as `before`, matching
exactly what validate_promoted_batch.py._require_reviewed_copy_revision
compares against (draft = the row from manifest.artifacts[].draft, live =
the row from the current live asset -- identity-projected for vocab/cloze/
satz). Cluster C (vocab_a1_0009/0045/0181 + satz mirrors) has no owning
manifest (predates the manifest/ledger system) so gets no entries here.
"""
from __future__ import annotations

import csv
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))
import c2d_rewrite_data as D  # noqa: E402

LEDGER_PATH = ROOT / "tools/content_factory/review/promoted_copy_revisions_20260822.json"


def fp(value) -> str:
    canonical = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def load_csv_by_id(path: Path) -> dict:
    with path.open(encoding="utf-8", newline="") as fh:
        return {r["id"]: r for r in csv.DictReader(fh)}


def load_json_items_by_id(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    items = data["items"] if isinstance(data, dict) else data
    return {x["id"]: x for x in items}


# manifest -> {kind: draft_path}
MANIFEST_DRAFTS = {
    "tools/content_factory/drafts/batch_07_partner_family_manifest.json": {
        "vocab": "tools/content_factory/drafts/c3_batch07_vocab_partner_family.csv",
        "cloze": "tools/content_factory/drafts/c2_batch07_cloze_partner_family.json",
        "satz": "tools/content_factory/drafts/c2_batch07_satz_partner_family.json",
    },
    "tools/content_factory/drafts/batch_09_4x_manifest.json": {
        "vocab": "tools/content_factory/drafts/c3_batch09_vocab_a1_c2.csv",
        "cloze": "tools/content_factory/drafts/c2_batch09_cloze_a1_c2.json",
        "satz": "tools/content_factory/drafts/c2_batch09_satz_a1_c2.json",
    },
    "tools/content_factory/drafts/batch_19_manifest.json": {
        "vocab": "tools/content_factory/drafts/batch19_vocab.csv",
        "cloze": "tools/content_factory/drafts/batch19_cloze.json",
        "satz": "tools/content_factory/drafts/batch19_satz.json",
    },
}

CLUSTER_A_IDS = {"vocab_a1_0218", "vocab_a1_0220", "vocab_a1_0221", "vocab_a1_0223",
                 "vocab_a1_0248", "vocab_a1_0250", "vocab_a1_0252", "vocab_a1_0253",
                 "vocab_a1_0258", "vocab_a1_0259", "vocab_a1_0261", "vocab_a1_0264",
                 "vocab_a1_0268", "vocab_a1_0269"}
CLUSTER_D_IDS = {"vocab_a1_0335", "vocab_a1_0336", "vocab_a1_0340", "vocab_a1_0341",
                 "vocab_a1_0343", "vocab_a1_0401"}


def owning_manifest(kind: str, rid: str) -> str | None:
    if kind == "vocab":
        if rid in CLUSTER_A_IDS:
            return "tools/content_factory/drafts/batch_07_partner_family_manifest.json"
        if rid in CLUSTER_D_IDS:
            return "tools/content_factory/drafts/batch_09_4x_manifest.json"
        return None
    if kind == "cloze":
        if rid in D.CLOZE_MIRROR_REWRITES and rid not in ("cloze_a1_0223", "cloze_a1_0224", "cloze_a1_0228", "cloze_a1_0229", "cloze_a1_0231", "cloze_a1_0289"):
            return "tools/content_factory/drafts/batch_07_partner_family_manifest.json"
        if rid in ("cloze_a1_0223", "cloze_a1_0224", "cloze_a1_0228", "cloze_a1_0229", "cloze_a1_0231", "cloze_a1_0289"):
            return "tools/content_factory/drafts/batch_09_4x_manifest.json"
        if rid in D.CLOZE_ONLY_REWRITES:
            return "tools/content_factory/drafts/batch_19_manifest.json"
        return None
    if kind == "satz":
        d_ids = {"satz_a1_0187", "satz_a1_0188", "satz_a1_0192", "satz_a1_0193", "satz_a1_0195", "satz_a1_0253"}
        if rid in d_ids:
            return "tools/content_factory/drafts/batch_09_4x_manifest.json"
        if rid in ("satz_a1_0046", "satz_a1_0257", "satz_a1_0265"):
            return None  # cluster C, no manifest
        if rid in D.SATZ_ONLY_REWRITES:
            return "tools/content_factory/drafts/batch_19_manifest.json"
        if rid in D.SATZ_MIRROR_REWRITES:
            return "tools/content_factory/drafts/batch_07_partner_family_manifest.json"
        return None
    return None


def main():
    change_log = json.loads((ROOT / "tools/content_factory/c2d_change_log.json").read_text(encoding="utf-8"))
    draft_cache: dict[str, dict] = {}

    def get_draft_row(manifest: str, kind: str, rid: str):
        cache_key = f"{manifest}:{kind}"
        if cache_key not in draft_cache:
            path = ROOT / MANIFEST_DRAFTS[manifest][kind]
            draft_cache[cache_key] = load_csv_by_id(path) if path.suffix == ".csv" else load_json_items_by_id(path)
        return draft_cache[cache_key].get(rid)

    new_entries = []
    skipped = []
    for change in change_log:
        kind, rid, level = change["kind"], change["id"], change["level"]
        manifest = owning_manifest(kind, rid)
        if manifest is None:
            skipped.append((kind, rid))
            continue
        draft_row = get_draft_row(manifest, kind, rid)
        if draft_row is None:
            skipped.append((kind, rid, "draft row not found"))
            continue
        live_row = change["after"]
        fields = sorted(k for k in set(draft_row) | set(live_row) if draft_row.get(k) != live_row.get(k))
        entry = {
            "manifest": manifest,
            "kind": kind,
            "id": rid,
            "level": str(draft_row.get("level") or level).lower(),
            "fields": fields,
            "beforeSha256": fp(draft_row),
            "afterSha256": fp(live_row),
        }
        new_entries.append(entry)

    print(f"{len(new_entries)} ledger entries built; {len(skipped)} rows skipped (no manifest / cluster C):")
    for s in skipped:
        print(" skip:", s)

    ledger = json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
    existing_by_key = {(e["kind"], e["id"]): i for i, e in enumerate(ledger["entries"])}
    added, updated = 0, 0
    for entry in new_entries:
        key = (entry["kind"], entry["id"])
        if key in existing_by_key:
            ledger["entries"][existing_by_key[key]] = entry
            updated += 1
        else:
            ledger["entries"].append(entry)
            added += 1
    for manifest in {e["manifest"] for e in new_entries}:
        if manifest not in ledger["manifests"]:
            ledger["manifests"].append(manifest)
    ledger["amendments"].append({
        "date": "2026-09-15",
        "scope": "C2d A1 grammar-level rewrite",
        "method": (
            "scan_a1_grammar.py flagged A1 vocab/cloze/satz rows using grade>=2 "
            "NIKL grammar (incl. 인용문/quotation constructions); 70 rows across "
            "20 vocab headwords + mirrors rewritten to stay inside the 45-item "
            "1급 grammar table (docs/CONTENT_LEVEL_BIBLE.md §B.1); entries "
            "fingerprinted against each row's true historical draft file "
            "(manifest.artifacts[].draft), not just git history."
        ),
        "added": added,
        "updated": updated,
    })
    LEDGER_PATH.write_text(
        json.dumps(ledger, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8", newline="",
    )
    print(f"\nledger written: {LEDGER_PATH} (+{added} new, {updated} updated)")


if __name__ == "__main__":
    main()
