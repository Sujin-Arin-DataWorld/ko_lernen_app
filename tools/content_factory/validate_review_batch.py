#!/usr/bin/env python3
"""Validate any supported review-only B1/B2 batch without changing files.

Unlike the immutable ``validate_batch_01.py`` entry point, this command uses
the batch manifest's own draft/review paths, counts, and optional pending-pack
reservations.  It currently supports the shared five-asset authoring set:
vocab, grammar, smalltalk, cloze, and Satzbau.

Usage:
    python3 tools/content_factory/validate_review_batch.py \
      --manifest tools/content_factory/drafts/batch_02_manifest.json
"""

from __future__ import annotations

import argparse
from pathlib import Path

from validate_batch_01 import BatchValidationError, validate_review_batch


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        required=True,
        help="repository-relative review-only batch manifest",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    try:
        result = validate_review_batch(manifest_path=Path(args.manifest))
    except BatchValidationError as error:
        for message in error.messages:
            print(f"ERROR: {message}")
        return 1
    print(
        "OK: review-batch pre-review overlay passed: "
        f"{result.record_count} records; pack plans {', '.join(result.planned_pack_ids)}; "
        "no repository source files were written.",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
