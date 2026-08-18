#!/usr/bin/env python3
"""Machine-generated inventory of every bundled/unbundled image asset.

Answers three questions per file, from the files themselves — never from a doc:
  1. what is it (size, mode, alpha coverage, bytes, sha256)
  2. does it ship (is its directory declared in pubspec.yaml — Flutter includes
     a declared directory NON-recursively, so each leaf must be listed)
  3. does anything use it (filename or stem present anywhere in lib/)

Run:
    /usr/local/bin/python3.12 tool/asset_inventory.py            # markdown to stdout
    /usr/local/bin/python3.12 tool/asset_inventory.py --json     # machine readable
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
SCAN_ROOTS = (
    "assets/illustrations",
    "assets/stickers",
    "assets/icons",
    "assets_unused",
    "docs/assets",
)


# Which visual family a directory belongs to. New art must join exactly one
# family and be generated against that family's anchor file — mixing them is
# what produced the rejected 2026-08-17 A2 attempt.
FAMILIES: tuple[tuple[str, str, str], str] = (
    ("assets/illustrations/decorations/", "F-A/F-B", "사랑방 실내 컷아웃 6 + 마당 장식 18 (앵커: seoan·soban·munbangsau·jagae_mungap)"),
    ("assets/illustrations/personal_hanok_v2/", "F-C", "개인 한옥 estate 1536×1152 (앵커: map/structures/sarangchae.png)"),
    ("assets/illustrations/hanok/", "F-D", "방 배경·배너·게이트 (sarangbang_empty 1086×1448)"),
    ("assets/illustrations/hanok_stages/", "F-F", "레거시 12단계 배경 — 신규 참조 금지"),
    ("assets/illustrations/hanok_compound/", "F-F", "동결 프로토타입 — 번들 제외·참조 금지"),
    ("assets/illustrations/gye/", "F-F", "계 공동 한옥 — 개인 한옥 재사용/모델 입력 금지"),
    ("assets/illustrations/packs/", "F-E", "카드 세트 (스타일 앵커: plum.webp)"),
    ("assets/illustrations/activities/", "F-E", "카드 세트"),
    ("assets/illustrations/listening/", "F-E", "듣기 카드 (다른 세션 진행 중)"),
    ("assets/illustrations/scenes/", "F-E", "시나리오 배경 포스터 1086×1448"),
    ("assets/illustrations/stamps/", "F-G", "단청 도장 14 (런타임 조립)"),
    ("assets/stickers/", "F-G", "스티커 30 (계 피드·방 꾸미기)"),
    ("assets/illustrations/mascot/", "F-H", "마스코트 포즈"),
    ("assets_unused/", "—", "번들 제외 (QA·원본·격리)"),
    ("docs/assets/", "—", "문서·홈페이지·프롬프트 자료"),
)


def family_for(directory: str) -> tuple[str, str]:
    for prefix, family, note in FAMILIES:
        if directory.startswith(prefix):
            return family, note
    return "—", ""


def pubspec_asset_dirs() -> set[str]:
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    dirs: set[str] = set()
    for match in re.finditer(r"^\s+- (assets/\S+/)\s*$", text, re.MULTILINE):
        dirs.add(match.group(1))
    return dirs


def lib_source() -> str:
    chunks = []
    for path in (ROOT / "lib").rglob("*.dart"):
        chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(chunks)


def lib_reference(source: str, name: str) -> bool:
    stem = name.rsplit(".", 1)[0]
    return name in source or stem in source


def describe(path: Path) -> dict:
    data = path.read_bytes()
    row = {
        "path": str(path.relative_to(ROOT)).replace("\\", "/"),
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "width": None,
        "height": None,
        "mode": None,
        "alphaCoveragePct": None,
        "error": None,
    }
    try:
        with Image.open(path) as im:
            row["width"], row["height"] = im.size
            row["mode"] = im.mode
            has_alpha = im.mode in ("RGBA", "LA") or "transparency" in im.info
            if has_alpha:
                alpha = im.convert("RGBA").getchannel("A")
                histogram = alpha.histogram()
                visible = sum(histogram[9:])
                total = im.size[0] * im.size[1]
                row["alphaCoveragePct"] = round(100.0 * visible / max(1, total), 2)
    except Exception as exc:  # noqa: BLE001 - inventory must not die on one file
        row["error"] = f"{type(exc).__name__}: {exc}"
    return row


def collect() -> list[dict]:
    declared = pubspec_asset_dirs()
    source = lib_source()
    rows: list[dict] = []
    for root in SCAN_ROOTS:
        base = ROOT / root
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in IMAGE_SUFFIXES:
                continue
            row = describe(path)
            directory = str(path.parent.relative_to(ROOT)).replace("\\", "/") + "/"
            row["dir"] = directory
            row["bundled"] = directory in declared
            row["usedInLib"] = lib_reference(source, path.name)
            rows.append(row)
    return rows


def markdown(rows: list[dict]) -> str:
    out: list[str] = []
    by_dir: dict[str, list[dict]] = {}
    for row in rows:
        by_dir.setdefault(row["dir"], []).append(row)

    total_bytes = sum(r["bytes"] for r in rows)
    out.append(f"총 {len(rows)}개 이미지 · {total_bytes / 1024 / 1024:.1f} MB · 디렉터리 {len(by_dir)}개\n")
    for directory in sorted(by_dir):
        group = by_dir[directory]
        size_mb = sum(r["bytes"] for r in group) / 1024 / 1024
        bundled = "번들 O" if group[0]["bundled"] else "번들 X"
        unused = [r for r in group if not r["usedInLib"]]
        family, note = family_for(directory)
        out.append(f"\n### `{directory}` — {len(group)}개 · {size_mb:.1f} MB · {bundled} · lib 미참조 {len(unused)}개")
        out.append(f"\n가족 **{family}** · {note}\n" if note else "")
        out.append("| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |")
        out.append("|---|---|---|---:|---:|---|:--:|")
        for row in group:
            name = row["path"].rsplit("/", 1)[-1]
            dims = f"{row['width']}×{row['height']}" if row["width"] else "?"
            cov = "" if row["alphaCoveragePct"] is None else f"{row['alphaCoveragePct']:.1f}"
            used = "O" if row["usedInLib"] else "**X**"
            out.append(
                f"| `{name}` | {dims} | {row['mode']} | {cov} | {row['bytes'] // 1024} | "
                f"`{row['sha256'][:12]}` | {used} |"
            )
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    rows = collect()
    if args.json:
        json.dump(rows, sys.stdout, ensure_ascii=False, indent=1)
        print()
    else:
        print(markdown(rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
