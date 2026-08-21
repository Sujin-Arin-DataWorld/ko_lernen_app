#!/usr/bin/env python3
"""Fail if known semantic regressions re-enter learner or factory data."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SCAN_ROOTS = (
    ROOT / "assets" / "data",
    ROOT / "tools" / "content_factory",
)
SKIP_PARTS = {".git", "node_modules", ".code-review-graph"}

REJECTED = (
    "run it by my manager",
    "When will your manager see it",
    "spell it out",
    "Es muss nach oben",
    "It has to go up",
    "die Leitung entscheiden",
    "sign it off",
    "Bitte nach oben geben",
    "Wann geht es nach oben",
    "When will it move up the chain",
    "Mandatsgrenze",
    "mandate edge",
    "Sagen Sie es ruhig",
    "Augenbitte",
    "Blick, der um Übersetzung",
    "look asking for a translation",
    "When does it go up?",
    "When will it go up?",
    "I'll line it up like that",
    "Do not write long",
)


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
            if path.suffix.lower() not in {".json", ".csv", ".py"}:
                continue
            text = path.read_text(encoding="utf-8")
            for phrase in REJECTED:
                if phrase in text:
                    hits.append(f"{path.relative_to(ROOT)}: {phrase}")
    if hits:
        print("rejected phrases:")
        for hit in hits:
            print(f"  {hit}")
        return 1
    print("rejected-phrases: clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
