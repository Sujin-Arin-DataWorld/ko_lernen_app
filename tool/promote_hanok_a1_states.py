#!/usr/bin/env python3
"""Promote approved QA A1 states into the runtime directory only as a full set."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path
from typing import Any

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hanok_v1_asset_contract import (
    A1_QA_STATES_ROOT,
    A1_RUNTIME_STATES_ROOT,
    ROOT,
    a1_approved_state_digests,
    a1_expected_files,
    a1_hard_max_bytes,
    camera_geometry,
    chroma_key_count,
    load_provenance,
    sha256_file,
)


class PromotionError(ValueError):
    """Fail-closed A1 runtime promotion."""


def _chroma_count(image: Image.Image) -> int:
    return chroma_key_count(image)


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


def _require_approved_ledger(paths: list[Path], provenance: dict[str, Any]) -> None:
    expected = a1_expected_files(provenance)
    digests = a1_approved_state_digests(provenance)
    if not digests:
        raise PromotionError(
            "generationLedger has no approved A1 state outputs; refuse promotion"
        )
    missing = [name for name in expected if name not in digests]
    if missing:
        raise PromotionError(
            "generationLedger is missing approved outputs for "
            + ", ".join(missing)
        )
    mismatched = [
        path.name
        for path in paths
        if digests.get(path.name) != sha256_file(path)
    ]
    if mismatched:
        raise PromotionError(
            "QA A1 state SHA-256 does not match approved ledger output for "
            + ", ".join(mismatched)
        )


def collect_approved_states(
    qa_root: Path | None = None,
    provenance_path: Path | None = None,
    provenance: dict[str, Any] | None = None,
) -> list[Path]:
    payload = provenance or load_provenance(provenance_path)
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
    provenance: dict[str, Any] | None = None,
    provenance_path: Path | None = None,
) -> list[str]:
    payload = provenance or load_provenance(provenance_path)
    approved = collect_approved_states(qa_root=qa_root, provenance=payload)
    _require_approved_ledger(approved, payload)
    destination = runtime_root or A1_RUNTIME_STATES_ROOT
    copied = []
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
