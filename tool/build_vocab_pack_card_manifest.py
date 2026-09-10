#!/usr/bin/env python3
"""Build the vocabulary-pack artwork production ledger from live sources."""

from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import OrderedDict
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "assets/data/korean_vocab.csv"
CATALOG_PATH = ROOT / "lib/data/pack_artwork_catalog.dart"
MOTIF_PATH = ROOT / "lib/widgets/sori/dancheong_stamp.dart"
OUTPUT_PATH = ROOT / "docs/assets/VOCAB_PACK_CARD_MANIFEST.json"


def _base_pack_id(pack_id: str) -> str:
    parts = pack_id.split("_")
    if parts[-1].isdigit():
        return "_".join(parts[:-1])
    return pack_id


def _parse_dedicated_pack_ids() -> set[str]:
    source = CATALOG_PATH.read_text(encoding="utf-8")
    match = re.search(
        r"dedicatedPackIds\s*=\s*<String>\{(?P<body>.*?)\n\s*\};",
        source,
        re.DOTALL,
    )
    if match is None:
        raise RuntimeError("Could not find PackArtworkCatalog.dedicatedPackIds")
    return set(re.findall(r"'([^']+)'", match.group("body")))


def _parse_motif_map() -> dict[str, str]:
    source = MOTIF_PATH.read_text(encoding="utf-8")
    switch = re.search(
        r"return switch \(base\) \{(?P<body>.*?)\n\s*_ => DancheongMotif\.lotus,",
        source,
        re.DOTALL,
    )
    if switch is None:
        raise RuntimeError("Could not find motifForPackId switch")
    body = re.sub(r"//.*", "", switch.group("body"))
    result: dict[str, str] = {}
    for match in re.finditer(
        r"(?P<keys>(?:\s*'[^']+'\s*(?:\|\|\s*)?)+)"
        r"=>\s*DancheongMotif\.(?P<motif>\w+),",
        body,
    ):
        for key in re.findall(r"'([^']+)'", match.group("keys")):
            result[key] = match.group("motif")
    return result


def _load_packs() -> OrderedDict[str, list[dict[str, str]]]:
    packs: OrderedDict[str, list[dict[str, str]]] = OrderedDict()
    with CSV_PATH.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            pack_id = row["pack_id"].strip()
            if pack_id:
                packs.setdefault(pack_id, []).append(row)
    return packs


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    packs = _load_packs()
    dedicated = _parse_dedicated_pack_ids()
    motif_map = _parse_motif_map()
    production_path = ROOT / "docs/assets/PHASE_ARTWORK_PRODUCTION.json"
    production = json.loads(production_path.read_text(encoding="utf-8"))
    production_ids = {entry["id"] for entry in production["assets"]}
    reviewed = {
        entry["id"]: entry for entry in production["assets"]
        if entry["kind"] == "pack" and entry["status"] == "bundled"
    }
    entries = []

    for pack_id, rows in packs.items():
        base_id = _base_pack_id(pack_id)
        motif = motif_map.get(base_id, "lotus")
        is_dedicated = pack_id in dedicated
        asset_stem = pack_id if is_dedicated else motif
        relative_asset = f"assets/illustrations/packs/{asset_stem}.webp"
        asset_path = ROOT / relative_asset
        if not asset_path.is_file():
            raise FileNotFoundError(f"Missing primary artwork: {relative_asset}")

        with Image.open(asset_path) as image:
            width, height = image.size
        four_three_pass = width == 800 and height == 600
        is_legacy_b2_review = (
            is_dedicated and pack_id.startswith("b2_")
            and pack_id not in production_ids
        )
        review = reviewed.get(pack_id)
        if review:
            _validate_review(review, relative_asset, _sha256(asset_path))
        visual_status = "pass" if review or is_legacy_b2_review else "not_rechecked"
        visual_detail = (
            "Phase artwork production review" if review else
            "B2 hidden-label contact sheet" if is_legacy_b2_review else None
        )
        korean_terms = [row["korean"].strip() for row in rows if row["korean"].strip()]
        english_terms = [row["english"].strip() for row in rows if row["english"].strip()]

        entries.append(
            {
                "packId": pack_id,
                "level": rows[0]["level"].strip().upper(),
                "rewardMotif": motif,
                "primaryAsset": relative_asset,
                "subjectKo": " · ".join(korean_terms[:4]),
                "subjectPromptEn": (
                    "a modern still life expressing " + ", ".join(english_terms[:4])
                ),
                "evidenceWordIds": [row["id"].strip() for row in rows],
                "status": (
                    "approved_dedicated" if is_dedicated else "approved_motif_fallback"
                ),
                "sha256": _sha256(asset_path),
                "qa": {
                    "fourThree": {
                        "status": "pass" if four_three_pass else "fail",
                        "detail": f"{width}x{height}",
                    },
                    "sixteenTenCenterCrop": {
                        "status": visual_status,
                        "detail": visual_detail,
                    },
                    "hundredPx": {
                        "status": visual_status,
                        "detail": visual_detail,
                    },
                },
            }
        )

    unknown_dedicated = dedicated.difference(packs)
    if unknown_dedicated:
        raise RuntimeError(f"Dedicated pack IDs absent from CSV: {sorted(unknown_dedicated)}")

    payload = {
        "schemaVersion": 1,
        "generatedFrom": "assets/data/korean_vocab.csv",
        "snapshotDate": "2026-09-10",
        "packCount": len(entries),
        "dedicatedAssetCount": len(dedicated),
        "notes": [
            "The approved plan snapshot contained 223 packs; the live CSV now contains 224.",
            "The 2026-09-10 production batch adds 22 dedicated pack assets; 40 shared pack images remain.",
            "Korean vocabulary is the semantic source; subjectPromptEn is generation-only guidance.",
        ],
        "packs": entries,
    }
    OUTPUT_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"wrote {OUTPUT_PATH.relative_to(ROOT)} "
        f"packs={len(entries)} dedicated={len(dedicated)}"
    )


def _validate_review(review: dict, relative_asset: str, current_sha: str) -> None:
    if review.get("asset") != relative_asset or review.get("sha256") != current_sha:
        raise ValueError(f"Stale visual review for {review['id']}")
    if any(review.get("qa", {}).get(key) != "pass" for key in (
        "fullSize", "crop16x10", "thumbnail100px", "textFree",
        "materials", "nativeTexture", "familyShell",
    )):
        raise ValueError(f"Incomplete visual review for {review['id']}")


if __name__ == "__main__":
    main()
