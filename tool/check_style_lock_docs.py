#!/usr/bin/env python3
"""Guard that the 4 pre-STYLE_LOCK docs still carry their priority banners.

docs/assets/STYLE_LOCK.json became the style SSoT on 2026-08-18 without
rewriting the 4 older documents that used to hold that role (AGENTS.md,
ASSET_GENERATION_BIBLE.md x2, HANOK_ASSET_INVENTORY_2026-08-17.md x2,
docs/README.md) -- instead each got a short banner pointing readers at the
new priority order. This mirrors test/asset_orphan_guard_test.dart's own
"exemption is not free" pattern: if a banner's exact evidence string
disappears, that means someone rewrote the section without noticing it was
now stale, and this gate should fail loudly rather than let the drift back in
silently.

Usage:
    python3 tool/check_style_lock_docs.py
Exit code is the number of missing banners (0 = all present).
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# path -> list of exact substrings that must all be present.
REQUIRED_BANNERS: dict[str, list[str]] = {
    "AGENTS.md": [
        "정정(2026-08-18): 한옥/장식 계열은 위 문장이 stale하다",
        "docs/assets/STYLE_LOCK.json",
    ],
    "docs/ASSET_GENERATION_BIBLE.md": [
        "정정(2026-08-18): 한옥/장식 계열(F-A/F-B/F-C)은 이 절이 stale하다",
        "F-A는 그림자 완전 금지가 정본이다",
    ],
    "docs/HANOK_ASSET_INVENTORY_2026-08-17.md": [
        "정정(2026-08-18): 이 절은 F-A 6종만 실측한 스냅샷이다",
        "generationFacts`가 이 절보다 우선한다",
    ],
    "docs/README.md": [
        "정정(2026-08-18)**: for hanok/decoration style facts",
    ],
}


def check() -> int:
    missing = 0
    for rel_path, substrings in REQUIRED_BANNERS.items():
        path = ROOT / rel_path
        if not path.exists():
            print(f"[fail] {rel_path}: file does not exist")
            missing += len(substrings)
            continue
        text = path.read_text(encoding="utf-8")
        for substring in substrings:
            if substring not in text:
                print(f"[fail] {rel_path}: missing banner text {substring!r}")
                missing += 1
    if missing == 0:
        print(f"[ok] all {sum(len(v) for v in REQUIRED_BANNERS.values())} banner strings present across {len(REQUIRED_BANNERS)} files")
    return missing


if __name__ == "__main__":
    raise SystemExit(check())
