#!/usr/bin/env python3
"""Promote approved QA A1 states into the runtime directory only as a full set."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hanok_v1_asset_contract import (
    A1_QA_STATES_ROOT,
    A1_RUNTIME_STATES_ROOT,
    ROOT,
    a1_expected_files,
    a1_hard_max_bytes,
    approved_output_digests,
    camera_geometry,
    load_provenance,
    sha256_file,
)


class PromotionError(ValueError):
    """Fail-closed A1 runtime promotion."""


def _chroma_count(image: Image.Image) -> int:
    exact = 0
    near = 0
    sample = None
    for red, green, blue in image.convert("RGB").getdata():
        if (red, green, blue) == (0, 255, 0):
            exact += 1
        elif green >= 200 and red <= 40 and blue <= 40:
            near += 1
            if sample is None:
                sample = [red, green, blue]
    # #region agent log
    import json as _json, time as _time
    open("/opt/cursor/logs/debug.log", "a").write(_json.dumps({"hypothesisId": "A", "location": "promote_hanok_a1_states.py:_chroma_count", "message": "exact #00ff00 vs near-green", "data": {"exact": exact, "near": near, "sampleRgb": sample, "size": list(image.size), "mode": image.mode}, "timestamp": int(_time.time() * 1000)}) + "\n")
    # #endregion
    return exact


def _validate_state(path: Path, geometry: dict[str, int], hard_max: int) -> None:
    if not path.is_file():
        raise PromotionError(f"missing approved QA state {path}")
    with Image.open(path) as source:
        image = source.copy()
        fmt = (source.format or "").upper()
    if fmt != "WEBP":
        raise PromotionError(f"{path} must be WebP, got {fmt}")
    if image.size != (geometry["canvas_width"], geometry["canvas_height"]):
        raise PromotionError(f"{path} has the wrong canvas")
    if image.mode != "RGB":
        raise PromotionError(f"{path} must be opaque RGB, got {image.mode}")
    if _chroma_count(image):
        raise PromotionError(f"{path} contains #00ff00 chroma-key pixels")
    if path.stat().st_size > hard_max:
        raise PromotionError(f"{path} exceeds the hard byte cap")


def collect_approved_states(
    qa_root: Path | None = None,
    provenance_path: Path | None = None,
) -> list[Path]:
    payload = load_provenance(provenance_path)
    expected = a1_expected_files(payload)
    geometry = camera_geometry(payload)
    hard_max = a1_hard_max_bytes(payload)
    root = qa_root or A1_QA_STATES_ROOT
    paths = []
    missing = []
    for name in expected:
        path = root / name
        if not path.is_file():
            missing.append(name)
            continue
        _validate_state(path, geometry, hard_max)
        paths.append(path)
    if missing:
        raise PromotionError(
            "A1 runtime promotion is atomic; still missing "
            + ", ".join(missing)
        )
    return paths


def promote_states(
    *,
    qa_root: Path | None = None,
    runtime_root: Path | None = None,
    dry_run: bool = True,
) -> list[str]:
    approved = collect_approved_states(qa_root=qa_root)
    destination = runtime_root or A1_RUNTIME_STATES_ROOT
    copied = []
    # #region agent log
    import json as _json, time as _time
    _payload = load_provenance()
    _records = _payload.get("generationLedger", {}).get("records", [])
    _approved_shas = approved_output_digests(_payload)
    _file_shas = [sha256_file(path) for path in approved]
    _locked = all(digest in _approved_shas for digest in _file_shas) if _file_shas else False
    open("/opt/cursor/logs/debug.log", "a").write(_json.dumps({"hypothesisId": "B", "location": "promote_hanok_a1_states.py:promote_states", "message": "promote apply vs empty ledger", "data": {"dryRun": dry_run, "fileCount": len(approved), "ledgerRecordCount": len(_records), "approvedOutputShaCount": len(_approved_shas), "shaLocked": _locked, "wouldCopy": not dry_run}, "timestamp": int(_time.time() * 1000)}) + "\n")
    # #endregion
    expected_names = {path.name for path in approved}
    if destination.is_dir():
        leftovers = [
            child.name
            for child in destination.iterdir()
            if child.is_file() and child.name not in expected_names
        ]
        if leftovers:
            raise PromotionError(
                "runtime A1 directory has leftover files: " + ", ".join(sorted(leftovers))
            )
    if dry_run:
        return [path.name for path in approved]
    destination.mkdir(parents=True, exist_ok=True)
    for path in approved:
        target = destination / path.name
        shutil.copy2(path, target)
        copied.append(str(target.relative_to(ROOT)) if ROOT in target.parents else str(target))
    return copied


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="copy the full approved set")
    args = parser.parse_args(argv)
    try:
        names = promote_states(dry_run=not args.apply)
    except PromotionError as error:
        print(f"[fail] {error}")
        return 1
    mode = "promoted" if args.apply else "ready"
    print(f"[pass] {mode} {len(names)} A1 states")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
