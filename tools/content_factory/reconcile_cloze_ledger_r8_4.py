#!/usr/bin/env python3
"""R8-4 -- re-record stale per-row cloze `entries` in the promoted copy
revision ledger after the C2c/R8/R8-2/R8-3 distractor sweep.

Many live cloze rows already carried a per-row `entries` revision from an
earlier approved edit (an older batch's own draft-vs-live diff) whose
`fields` list already includes "distractors" -- e.g. `cloze_a1_0208`. Per
`_require_reviewed_copy_revision`'s own documented behavior (Fable ruling
2026-09-15), when a row already "owns" a field via its per-row entry, the
newly-approved `cloze`/`distractors` batchFieldRevision does NOT apply to
that row (it would otherwise silently revert the C2c edit) -- instead that
row's own beforeSha256/afterSha256/fields must be RE-RECORDED to reflect
the field's later, batch-approved value. This mirrors exactly what the C2a
RR regeneration did for 9 vocab rows after its own approval (see this
ledger's romanization batchFieldRevision `postApprovalChanges`).

This script recomputes the correct beforeSha256/afterSha256/fields for
every "cloze" `entries` row whose current live distractors differ from
what its stored afterSha256 encodes, using the EXACT same projection/
fingerprint logic `validate_promoted_batch.py` itself uses (imported
directly, not reimplemented), across every manifest that has cloze
entries (batch_09, batch_07_partner_family, batch_19,
batch_25_a1_reinforcement).

Usage:
    python tools/content_factory/reconcile_cloze_ledger_r8_4.py            # dry run
    python tools/content_factory/reconcile_cloze_ledger_r8_4.py --apply
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import relevel_ledger
import validate_promoted_batch as VPB

ROOT = VPB.ROOT
LEDGER_PATH = ROOT / VPB.COPY_REVISION_LEDGER
LIVE_CLOZE = ROOT / "assets/data/cloze.json"


def main(apply: bool) -> None:
    ledger = VPB._json(LEDGER_PATH)
    manifests = sorted({
        e["manifest"] for e in ledger["entries"] if e.get("kind") == "cloze"
    })
    live_rows = {
        it["id"]: it for it in VPB._json(LIVE_CLOZE)["items"]
    }
    ledger_obj = relevel_ledger.load_ledger(relevel_ledger.DEFAULT_LEDGER_PATH)
    batch_revisions = VPB._batch_field_revisions(root=ROOT)

    draft_rows_by_manifest: dict[str, dict[str, dict]] = {}
    for m in manifests:
        manifest_data = VPB._json(ROOT / m)
        artifact = next(a for a in manifest_data["artifacts"] if a["kind"] == "cloze")
        draft_path = VPB._resolve(artifact["draft"], ROOT)
        draft_data = VPB._json(draft_path)
        draft_rows_by_manifest[m] = {row["id"]: row for row in draft_data["items"]}

    changed = 0
    checked = 0
    unresolved = []
    for entry in ledger["entries"]:
        if entry.get("kind") != "cloze":
            continue
        ident = entry["id"]
        manifest = entry["manifest"]
        draft_row = draft_rows_by_manifest[manifest].get(ident)
        live_row = live_rows.get(ident)
        if draft_row is None or live_row is None:
            unresolved.append((ident, "missing draft or live row"))
            continue
        checked += 1

        draft_projection = VPB._promotion_projection("cloze", draft_row)
        live_projection = VPB._promotion_projection("cloze", live_row)
        live_projection = VPB._relevel_normalized_live(
            "cloze", ident, live_projection, draft_projection, ledger_obj
        )

        revision_fields = set(entry.get("fields") or [])
        live_cmp = dict(live_projection)
        for field in {*draft_projection, *live_projection}:
            if draft_projection.get(field) == live_projection.get(field):
                continue
            if field in revision_fields:
                continue
            batch_revision = batch_revisions.get(("cloze", field))
            if batch_revision is not None and batch_revision.get("approval"):
                live_cmp[field] = draft_projection.get(field)

        changed_fields = sorted(
            field for field in {*draft_projection, *live_cmp}
            if draft_projection.get(field) != live_cmp.get(field)
        )
        expected = {
            "level": str(draft_projection.get("level") or "").lower(),
            "fields": changed_fields,
            "beforeSha256": VPB._fingerprint(draft_projection),
            "afterSha256": VPB._fingerprint(live_cmp),
        }

        if not changed_fields:
            unresolved.append((ident, "no residual diff -- entry no longer needed (left as-is)"))
            continue

        if any(entry.get(k) != v for k, v in expected.items()):
            entry.update(expected)
            changed += 1

    print(f"checked {checked} cloze entries across {len(manifests)} manifests; re-recorded {changed}")
    for u in unresolved[:20]:
        print("  note:", u)

    if apply:
        LEDGER_PATH.write_text(
            json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print(f"written {LEDGER_PATH}")


if __name__ == "__main__":
    main(apply="--apply" in sys.argv)
