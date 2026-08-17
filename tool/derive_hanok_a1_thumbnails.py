#!/usr/bin/env python3
"""Derive deterministic 4:3 thumbnails from approved A1 composites."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hanok_v1_asset_contract import sha256_file


THUMB_SIZE = (384, 288)


class ThumbnailError(ValueError):
    """Fail-closed thumbnail derivation."""


def derive_thumbnail(
    source: Path,
    output: Path,
    *,
    expected_source_sha256: str | None = None,
    sidecar: Path | None = None,
) -> dict[str, str | int]:
    actual = sha256_file(source)
    if expected_source_sha256 is not None and actual != expected_source_sha256:
        raise ThumbnailError(
            "sourceSha256 does not match the approved composite; "
            "refusing to reuse a stale thumbnail"
        )
    with Image.open(source) as image:
        rgb = image.convert("RGB")
        if rgb.size[0] * 3 != rgb.size[1] * 4:
            raise ThumbnailError("thumbnail source must stay 4:3")
        thumb = rgb.resize(THUMB_SIZE, Image.Resampling.LANCZOS)
    output.parent.mkdir(parents=True, exist_ok=True)
    thumb.save(output, "WEBP", quality=82, method=6)
    record = {
        "source": str(source),
        "sourceSha256": actual,
        "output": str(output),
        "outputSha256": sha256_file(output),
        "width": THUMB_SIZE[0],
        "height": THUMB_SIZE[1],
    }
    if sidecar is not None:
        sidecar.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return record


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source")
    parser.add_argument("output")
    parser.add_argument("--source-sha256")
    parser.add_argument("--sidecar")
    args = parser.parse_args(argv)
    try:
        record = derive_thumbnail(
            Path(args.source),
            Path(args.output),
            expected_source_sha256=args.source_sha256,
            sidecar=Path(args.sidecar) if args.sidecar else None,
        )
    except ThumbnailError as error:
        print(f"[fail] {error}")
        return 1
    print(json.dumps(record, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
