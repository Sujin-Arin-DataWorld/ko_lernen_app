#!/usr/bin/env python3
"""Build promoted_copy_revisions_20260822.json entries for the C2d-2
rewrite (2026-09-16, Jin option a), using the TRUE historical draft files
as `before` -- mirrors tools/content_factory/c2d_build_ledger_entries.py's
approach exactly (see that script for the fingerprint rationale).

Only rows whose pack has an identifiable owning manifest get a ledger
entry: a1_partner_meet_names_1 (vocab_a1_0217/cloze_a1_0105/satz_a1_0069)
-> batch_07_partner_family_manifest.json; a1_post_office_1 (vocab_a1_0311/
0316, cloze_a1_0199/0204, satz_a1_0163/0168) and a1_sorry_thanks_1
(vocab_a1_0402, cloze_a1_0290, satz_a1_0254) -> batch_09_4x_manifest.json.
The remaining rows (a1_numbers_2, a1_time_3, a1_daily_4,
a1_repair_language_1, a1_first_class_1 packs, plus every cloze/satz-only
standalone row with no vocab source) have no manifest in the ledger's
`manifests` list -- same "Cluster C, no owning manifest, predates the
manifest/ledger system" situation C2d's own ledger script documented, so
they are skipped here (visible in the printed skip list) rather than
guessed at.
"""
from __future__ import annotations

import csv
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "content_factory"))
import c2d2_rewrite_data as D  # noqa: E402

LEDGER_PATH = ROOT / "tools/content_factory/review/promoted_copy_revisions_20260822.json"

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
}

BATCH07_IDS = {
    ("vocab", "vocab_a1_0217"), ("cloze", "cloze_a1_0105"), ("satz", "satz_a1_0069"),
}
BATCH09_IDS = {
    ("vocab", "vocab_a1_0311"), ("vocab", "vocab_a1_0316"), ("vocab", "vocab_a1_0402"),
    ("cloze", "cloze_a1_0199"), ("cloze", "cloze_a1_0204"), ("cloze", "cloze_a1_0290"),
    ("satz", "satz_a1_0163"), ("satz", "satz_a1_0168"), ("satz", "satz_a1_0254"),
}


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


def owning_manifest(kind: str, rid: str) -> str | None:
    if (kind, rid) in BATCH07_IDS:
        return "tools/content_factory/drafts/batch_07_partner_family_manifest.json"
    if (kind, rid) in BATCH09_IDS:
        return "tools/content_factory/drafts/batch_09_4x_manifest.json"
    return None


def main():
    change_log = json.loads((ROOT / "tools/content_factory/c2d2_change_log.json").read_text(encoding="utf-8"))
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

    print(f"{len(new_entries)} ledger entries built; {len(skipped)} rows skipped (no identifiable manifest):")
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
        "date": "2026-09-16",
        "scope": "C2d-2 A1 -아/어 주세요 -> -으세요 rewrite (Jin option a)",
        "method": (
            "scan_a1_grammar.py's contracted -아/어 주다/주시다/드리다 detector "
            "(added in C2d coordinator round 3) flagged 38 rows deferred by "
            "C2d as DOCUMENTED_EXCEPTIONS, plus vocab_a1_0402 (+2 mirrors) "
            "and 2 rows surfaced by promotions after the 2026-09-15 C2d "
            "scan (vocab_a1_0508's headword-embedded 도와주다 + mirrors, "
            "registered in HEADWORD_EMBEDDED_GRAMMAR, not rewritten); "
            "rewritten to 1급 -으세요 or a softened -을 수 있어요? question "
            "per Jin's 2026-09-16 ruling. vocab_a1_0410 (headword 적어 주다) "
            "also stays headword-embedded, unchanged. Entries fingerprinted "
            "against each row's true historical draft file "
            "(manifest.artifacts[].draft); rows with no identifiable owning "
            "manifest (a1_numbers_2/time_3/daily_4/repair_language_1/"
            "first_class_1 packs, standalone cloze/satz rows) got no ledger "
            "entry, same as C2d's own 'Cluster C' rows."
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
