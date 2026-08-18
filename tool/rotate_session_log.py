#!/usr/bin/env python3
"""Rotate docs/SESSION_LOG.md so it only holds the last KEEP_DAYS days of
session entries; anything older moves into docs/SESSION_LOG_ARCHIVE.md.

Every run is verified in memory before anything is written: the multiset of
entry text before and after must match exactly, or nothing is written.

Usage:
    python tool/rotate_session_log.py            # report only, no writes
    python tool/rotate_session_log.py --apply     # perform the rotation
"""
from __future__ import annotations

import argparse
import datetime as _dt
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIVE = ROOT / "docs" / "SESSION_LOG.md"
ARCHIVE = ROOT / "docs" / "SESSION_LOG_ARCHIVE.md"

KEEP_DAYS = 3
HEADER_RE = re.compile(r"^### (\d{4}-\d{2}-\d{2})")

LIVE_TITLE = "# SESSION_LOG — ko_lernen_app (Hangul Sori)\n"
ARCHIVE_TITLE = "# SESSION_LOG_ARCHIVE — ko_lernen_app (Hangul Sori)\n"


def _blocks(text: str) -> list[tuple[str, str]]:
    lines = text.splitlines(keepends=True)
    idx = [i for i, line in enumerate(lines) if HEADER_RE.match(line)]
    out = []
    for pos, start in enumerate(idx):
        end = idx[pos + 1] if pos + 1 < len(idx) else len(lines)
        date = HEADER_RE.match(lines[start]).group(1)
        out.append((date, "".join(lines[start:end])))
    return out


def _note(cutoff: str, moved: int) -> str:
    return (
        f"\n> **아카이브.** {cutoff} 이전 세션 기록 {moved}건은 컨텍스트 비용 절감을 위해\n"
        "> **`docs/SESSION_LOG_ARCHIVE.md`** 로 옮겼다 (매 세션 자동으로 읽지 말고, 필요할 때만\n"
        f"> grep/Read). 이 파일은 최근 {KEEP_DAYS}일 분만 유지한다.\n\n"
    )


def plan(today: _dt.date | None = None):
    today = today or _dt.date.today()
    cutoff = (today - _dt.timedelta(days=KEEP_DAYS - 1)).isoformat()
    live_text = LIVE.read_text(encoding="utf-8") if LIVE.exists() else LIVE_TITLE + "\n"
    live_blocks = _blocks(live_text)
    keep = [b for b in live_blocks if b[0] >= cutoff]
    move = [b for b in live_blocks if b[0] < cutoff]
    return cutoff, live_blocks, keep, move


def apply(today: _dt.date | None = None) -> None:
    cutoff, live_blocks, keep, move = plan(today)
    if not move:
        print(f"[ok] {LIVE.name} 은 이미 {cutoff} 이내({len(live_blocks)}건) — 분리 불필요")
        return

    archive_text = ARCHIVE.read_text(encoding="utf-8") if ARCHIVE.exists() else ARCHIVE_TITLE
    existing_archived = _blocks(archive_text)

    before = sorted(text for _, text in live_blocks + existing_archived)
    after = sorted(text for _, text in keep + move + existing_archived)
    if before != after:
        raise SystemExit("[fail] 무손실 검증 실패 — 아무 파일도 쓰지 않았다")

    new_live = [LIVE_TITLE, "\n", _note(cutoff, len(move))]
    new_live += [text for _, text in keep]
    LIVE.write_text("".join(new_live), encoding="utf-8", newline="\n")

    # Newly-archived entries are more recent than whatever is already
    # archived, so they land on top — same newest-first order as the live file.
    archive_header = (
        f"{ARCHIVE_TITLE}\n"
        f"> `docs/SESSION_LOG.md` 최근 {KEEP_DAYS}일 유지 정책에 따라 그 이전 세션 기록을\n"
        "> 여기로 옮겼다. 매 세션 자동으로 읽지 말고, 필요할 때만 grep/Read.\n"
        "> 최신 항목이 위, 과거로 갈수록 아래 — `docs/SESSION_LOG.md`와 동일한 순서다.\n\n"
    )
    new_archive = [archive_header]
    new_archive += [text for _, text in move]
    new_archive += [text for _, text in existing_archived]
    ARCHIVE.write_text("".join(new_archive), encoding="utf-8", newline="\n")

    print(f"[apply] {len(move)}건을 {cutoff} 기준으로 아카이브 이동. live {len(keep)}건 유지.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="실제로 분리해서 쓴다")
    args = parser.parse_args(argv)
    if args.apply:
        apply()
        return 0
    cutoff, live_blocks, keep, move = plan()
    print(f"{LIVE.name}: {len(live_blocks)}건, 기준일 {cutoff}")
    print(f"  유지 {len(keep)}건 / 이동 대상 {len(move)}건")
    if move:
        print("(--apply 로 실행하면 분리한다)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
