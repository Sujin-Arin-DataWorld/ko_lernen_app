#!/usr/bin/env python3
"""Verify that file/line anchors and backtick-quoted identifiers in a brief
markdown file actually exist in the repository -- a fast pre-check meant to
run BEFORE dispatching a brief (see
.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-3-brief.md).

Motivation: PR1 briefs T5/T7/T8 cited a wrong constant name, a wrong JSON
key and a wrong scope gate -- brief-authoring errors a 2-second check would
have caught. This tool never writes anything; it only reads the brief and
the source files its anchors point at.

Note: a backtick-quoted term naming an external concept (a Dart lint rule
such as `comment_references`, a package, an SDK type) reads as MISSING
since it names no symbol in the file -- intentional; read the table.

Note: a backtick-quoted prose word anywhere after a path token on the same
line binds to that path (nearest-preceding-path heuristic) even when it is
unrelated commentary rather than an identifier of that file -- a known
heuristic limit, not a bug.

Usage:
    python tool/check_brief_anchors.py <brief.md> [--root DIR] [--window N]
"""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path

EXTS = r"dart|py|ya?ml|json|arb|md|csv"
PATH_RE = re.compile(
    r"(?P<path>[A-Za-z0-9_./-]+\.(?:%s))(?::(?P<l1>\d+)(?:-(?P<l2>\d+))?)?" % EXTS
)
L_ANCHOR_RE = re.compile(r"\bL(\d+)(?:-(\d+))?\b")
IDENT_RE = re.compile(r"`([A-Za-z_][A-Za-z0-9_.]*)(?:\([^`]*\)|\s*=[^`]*)?`")
SEARCH_DIRS = ("lib", "test", "tool", ".github", "docs", "assets")
SKIP_DIRS = {".dart_tool", "build", ".git"}


def _resolve(path_str: str, root: Path):
    """Return (resolved_path, candidates) -- at most one is truthy. Tries
    the literal repo-root path first (so `pubspec.yaml`, `AGENTS.md`, and
    dir-qualified `assets/data/x.json` all resolve directly); only a bare
    filename with no direct hit falls back to a walk under SEARCH_DIRS."""
    direct = root / path_str
    if direct.is_file():
        return direct, None
    if "/" in path_str:
        return None, None
    found = []
    for d in SEARCH_DIRS:
        base = root / d
        if not base.is_dir():
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [dn for dn in dirnames if dn not in SKIP_DIRS]
            if path_str in filenames:
                found.append((Path(dirpath) / path_str).relative_to(root).as_posix())
    if len(found) == 1:
        return root / found[0], None
    if not found:
        return None, None
    return None, sorted(found)


def _find(name: str, flines: list[str], lo: int, hi: int):
    """First 1-indexed line in [lo, hi] (clamped) with `name` (or, dotted,
    its last segment) at a token boundary -- `stop` must not match inside
    `stopImpl`; lookarounds, not `\\b` (Korean is a `re` word char too)."""
    last = name.rsplit(".", 1)[-1]
    boundary = r"(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])"
    full_re = re.compile(boundary % re.escape(name))
    last_re = full_re if last == name else re.compile(boundary % re.escape(last))
    lo = max(1, lo)
    hi = min(len(flines), hi)
    for i in range(lo, hi + 1):
        text = flines[i - 1]
        if full_re.search(text) or last_re.search(text):
            return i
    return None


def _col(path: str, l1: int, l2: int) -> str:
    return f"{path}:{l1}" if l1 == l2 else f"{path}:{l1}-{l2}"


def _owner(paths: list[dict], pos: int):
    cands = [p for p in paths if p["end"] <= pos]
    return max(cands, key=lambda p: p["end"]) if cands else None


def _segments(line: str) -> list[dict]:
    """Split one brief line into per-path segments: {path, start, end,
    anchors: [(l1, l2)], idents: [name]}, each anchor/identifier bound to
    its nearest preceding path token."""
    paths = []
    for m in PATH_RE.finditer(line):
        path_str = m.group("path")
        if path_str.startswith("../"):
            continue
        prefix = line[max(0, m.start() - 8) : m.start()]
        if prefix.endswith("package:") or prefix.endswith("dart:"):
            continue
        seg = {"path": path_str, "start": m.start(), "end": m.end(), "anchors": [], "idents": []}
        if m.group("l1"):
            l1 = int(m.group("l1"))
            l2 = int(m.group("l2")) if m.group("l2") else l1
            seg["anchors"].append((l1, l2))
        paths.append(seg)
    if not paths:
        return paths
    spans = [(p["start"], p["end"]) for p in paths]
    for am in L_ANCHOR_RE.finditer(line):
        if any(s <= am.start() < e for s, e in spans):
            continue
        owner = _owner(paths, am.start())
        if owner is None:
            continue
        l1 = int(am.group(1))
        l2 = int(am.group(2)) if am.group(2) else l1
        owner["anchors"].append((l1, l2))
    for im in IDENT_RE.finditer(line):
        s, e = im.start(), im.end()
        if any(s < pe and e > ps for ps, pe in spans):
            continue
        name = im.group(1)
        if re.fullmatch(r"L\d+(?:-\d+)?", name):
            continue
        owner = _owner(paths, s)
        if owner is None:
            continue
        owner["idents"].append(name)
    return paths


def check_brief(text: str, root: Path, window: int):
    rows: list[tuple[int, str, str, str, str]] = []
    cache: dict[Path, list[str]] = {}
    for line_no, line in enumerate(text.splitlines(), start=1):
        for seg in _segments(line):
            path_str = seg["path"]
            resolved, candidates = _resolve(path_str, root)
            if candidates:
                rows.append((line_no, path_str, "DRIFT", path_str, "ambiguous: " + ", ".join(candidates)))
                continue
            if resolved is None:
                rows.append((line_no, path_str, "MISSING", path_str, "no such file"))
                continue
            if resolved not in cache:
                cache[resolved] = resolved.read_text(encoding="utf-8").splitlines()
            flines = cache[resolved]
            valid = []
            for l1, l2 in seg["anchors"]:
                if l1 > len(flines):
                    rows.append((line_no, path_str, "MISSING", _col(path_str, l1, l2), f"EOF at {len(flines)}"))
                else:
                    valid.append((l1, l2))
            if not seg["idents"]:
                if valid:
                    for l1, l2 in valid:
                        rows.append((line_no, path_str, "OK", _col(path_str, l1, l2), ""))
                elif not seg["anchors"]:
                    rows.append((line_no, path_str, "OK", path_str, ""))
                continue
            for name in seg["idents"]:
                if valid:
                    col = _col(path_str, *valid[0])
                    found = None
                    for a1, a2 in valid:
                        found = _find(name, flines, a1 - window, a2 + window)
                        if found:
                            break
                    if found:
                        rows.append((line_no, path_str, "OK", col, name))
                        continue
                    found = _find(name, flines, 1, len(flines))
                    if found:
                        rows.append((line_no, path_str, "DRIFT", col, f"{name} found at line {found}"))
                    else:
                        rows.append((line_no, path_str, "MISSING", col, f"{name} not found"))
                else:
                    found = _find(name, flines, 1, len(flines))
                    if found:
                        rows.append((line_no, path_str, "OK", path_str, name))
                    else:
                        rows.append((line_no, path_str, "MISSING", path_str, f"{name} not found"))
    rows.sort(key=lambda r: (r[0], r[1]))
    return [(status, f"brief:{ln}", col, detail) for ln, _p, status, col, detail in rows]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("brief", type=Path)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--window", type=int, default=25)
    args = parser.parse_args(argv)

    text = args.brief.read_text(encoding="utf-8")
    rows = check_brief(text, args.root, args.window)
    ok = drift = missing = 0
    for status, brief_col, path_col, detail in rows:
        print(f"{status}\t{brief_col}\t{path_col}\t{detail}")
        if status == "OK":
            ok += 1
        elif status == "DRIFT":
            drift += 1
        else:
            missing += 1
    print(f"OK {ok} · DRIFT {drift} · MISSING {missing}")
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
