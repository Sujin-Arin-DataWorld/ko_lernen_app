#!/usr/bin/env python3
"""Normalize one generated vocabulary-pack card and register it safely.

The creative source is produced by the approved image-generation workflow.
This tool performs only the locked F-E-cards mechanical tail:

    4:3 source -> RGB/LANCZOS 800x600 -> approved paper grain
    -> WebP q84/method6 -> style gate -> runtime directory -> ledger register

Nothing is written to the runtime asset directory until the candidate passes
the pixel gate. Registration failure restores the two ledgers and removes the
new runtime file so a half-promoted asset cannot survive.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


ROOT = Path(__file__).resolve().parents[1]
PACKS_DIR = ROOT / "assets" / "illustrations" / "packs"
BASELINE_PATH = ROOT / "docs" / "assets" / "CARD_STYLE_BASELINE.json"
STYLE_LOCK_PATH = ROOT / "docs" / "assets" / "STYLE_LOCK.json"
CHECKER_PATH = ROOT / "tool" / "check_card_style.py"
KEY_RE = re.compile(r"^[A-Za-z0-9_]+$")

sys.path.insert(0, str(ROOT / "scripts"))
from apply_paper_grain import grain  # noqa: E402


def _run_checker(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(CHECKER_PATH), *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


def process(source: Path, key: str) -> Path:
    if not KEY_RE.fullmatch(key):
        raise SystemExit(
            f"invalid key {key!r}; expected only ASCII letters, digits, underscore"
        )
    if not source.is_file():
        raise SystemExit(f"source does not exist: {source}")

    destination = PACKS_DIR / f"{key}.webp"
    if destination.exists():
        raise SystemExit(f"refusing to overwrite existing asset: {destination}")

    with Image.open(source) as opened:
        src = opened.convert("RGB")
    ratio = src.width / src.height
    if abs(ratio - 4 / 3) > 0.02:
        raise SystemExit(
            f"{key}: source must be 4:3, got {src.width}x{src.height} ({ratio:.4f})"
        )

    workdir = Path(tempfile.mkdtemp(prefix=f"vocab_pack_{key}_"))
    baseline_before = BASELINE_PATH.read_bytes()
    style_lock_before = STYLE_LOCK_PATH.read_bytes()
    try:
        resized = workdir / f"{key}.png"
        grained = workdir / f"{key}.grain.jpg"
        candidate = workdir / f"{key}.webp"

        src.resize((800, 600), Image.Resampling.LANCZOS).save(resized)
        grain(str(resized), str(grained))
        with Image.open(grained) as opened:
            opened.convert("RGB").save(
                candidate,
                "WEBP",
                quality=84,
                method=6,
            )

        verdict = _run_checker(str(candidate))
        if verdict.stdout:
            print(verdict.stdout, end="")
        if verdict.returncode != 0:
            if verdict.stderr:
                print(verdict.stderr, file=sys.stderr, end="")
            raise SystemExit(
                f"{key}: F-E-cards gate failed; candidate was not promoted"
            )

        PACKS_DIR.mkdir(parents=True, exist_ok=True)
        os.replace(candidate, destination)
        registration = _run_checker("--register", str(destination))
        if registration.stdout:
            print(registration.stdout, end="")
        if registration.returncode != 0:
            if registration.stderr:
                print(registration.stderr, file=sys.stderr, end="")
            destination.unlink(missing_ok=True)
            BASELINE_PATH.write_bytes(baseline_before)
            STYLE_LOCK_PATH.write_bytes(style_lock_before)
            raise SystemExit(
                f"{key}: registration failed; runtime file and ledgers restored"
            )

        print(
            f"promoted {source} -> {destination.relative_to(ROOT).as_posix()} "
            f"({destination.stat().st_size / 1024:.1f}KB)"
        )
        return destination
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("key")
    args = parser.parse_args()
    process(args.source.resolve(), args.key)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
