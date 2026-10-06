#!/usr/bin/env python3
import csv
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INV = ROOT / "docs" / "textbook_project" / "data" / "APP_CONTENT_INVENTORY.csv"
OUT = ROOT / "docs" / "textbook_project" / "data" / "MANUAL_TOPIC_REVIEW_QUEUE.csv"


def main():
    rows = list(csv.DictReader(INV.open(encoding="utf-8-sig", newline="")))
    unresolved = [r for r in rows if not r["canonicalTopicId"]]

    groups = defaultdict(list)
    for r in unresolved:
        if r["surface"] in {"live_scenario", "canonical_scenario", "listening_lesson"}:
            root_id = r["linkId"] or r["sourceId"]
            key = ("scenario_family", root_id)
        else:
            key = (r["surface"], r["sourceId"])
        groups[key].append(r)

    out_rows = []
    for (kind, root_id), items in sorted(groups.items()):
        preferred = next((r for r in items if r["surface"] == "live_scenario"), items[0])
        surfaces = sorted({r["surface"] for r in items})
        out_rows.append({
            "reviewKind": kind,
            "rootId": root_id,
            "level": preferred["currentLevel"],
            "currentTopic": preferred["currentTopic"],
            "titleKo": preferred["titleKo"],
            "titleEn": preferred["titleEn"],
            "titleDe": preferred["titleDe"],
            "linkedSurfaces": "|".join(surfaces),
            "unmappedReason": preferred["unmappedReason"],
            "manualPrimaryTopicId": "",
            "manualSecondaryTopicIds": "",
            "reviewNote": "",
            "reviewStatus": "PENDING",
        })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(out_rows[0].keys()))
        writer.writeheader()
        writer.writerows(out_rows)

    print(f"unresolved_rows={len(unresolved)} deduped_manual_reviews={len(out_rows)} output={OUT}")


if __name__ == "__main__":
    main()
