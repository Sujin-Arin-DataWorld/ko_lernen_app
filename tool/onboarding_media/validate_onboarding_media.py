#!/usr/bin/env python3
"""Validate one already-encoded onboarding poster or animation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from media_contract import MediaContractError, validate_file


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path)
    parser.add_argument("--poster", action="store_true")
    parser.add_argument("--max-side", type=int, default=960)
    parser.add_argument("--max-duration-ms", type=int, default=3000)
    parser.add_argument("--max-bytes", type=int, default=1_500_000)
    parser.add_argument("--max-resident-mib", type=float, default=16.0)
    args = parser.parse_args()

    report = validate_file(
        args.path,
        require_animation=not args.poster,
        max_side=args.max_side,
        max_duration_ms=None if args.poster else args.max_duration_ms,
        max_bytes=args.max_bytes,
        max_resident_bytes=round(args.max_resident_mib * 1024 * 1024),
    )
    print(json.dumps(report.to_dict(), indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MediaContractError as error:
        raise SystemExit(f"onboarding media validation failed: {error}") from error
