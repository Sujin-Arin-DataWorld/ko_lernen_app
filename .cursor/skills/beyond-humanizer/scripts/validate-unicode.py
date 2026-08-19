#!/usr/bin/env python3
"""Fail if learner or factory text contains U+FFFD replacement characters."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SCAN_ROOTS = (
    ROOT / "assets" / "data",
    ROOT / "tools" / "content_factory",
)
SKIP_PARTS = {".git", "node_modules", ".code-review-graph"}


def main() -> int:
    hits: list[str] = []
    for root in SCAN_ROOTS:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if any(part in SKIP_PARTS for part in path.parts):
                continue
            if path.suffix.lower() not in {".json", ".csv", ".py", ".md", ".txt"}:
                continue
            text = path.read_text(encoding="utf-8")
            if "\ufffd" in text:
                hits.append(str(path.relative_to(ROOT)))
    if hits:
        print("U+FFFD in:")
        for hit in hits:
            print(f"  {hit}")
        return 1
    print("unicode: no U+FFFD")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
