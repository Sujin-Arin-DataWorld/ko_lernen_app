#!/usr/bin/env python3
"""Tests for render_adjudication_packets.py (C1-T1).

Asserts the three packets exist, row counts are exactly 52/11/10, every id
exists in the live assets, and no row has an empty 원문 cell.

Run with the project venv:
    .venv/Scripts/python.exe -m unittest \
      tools/content_factory/test_render_adjudication_packets.py -v
"""

from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

import render_adjudication_packets as rap  # noqa: E402


ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*`([^`]+)`\s*\|\s*([A-Z0-9]*)\s*\|(.*)\|$")


def parse_table_rows(markdown: str) -> list[tuple[int, str, str, list[str]]]:
    """Parse the data rows of the single pipe table in a packet.

    Returns a list of (index, id, level, [원문, 문제, 제안, Jin판정]) tuples.
    Skips the header and separator lines.
    """
    rows: list[tuple[int, str, str, list[str]]] = []
    for line in markdown.splitlines():
        if line.startswith("|---"):
            continue
        match = ROW_RE.match(line.strip())
        if not match:
            continue
        index_str, item_id, level, remainder = match.groups()
        # remainder holds exactly: 원문 | 문제 | 제안 | Jin판정 (4 cells, the last
        # one is intentionally blank until Jin fills it in).
        cells = [c.strip() for c in remainder.split(" | ")]
        rows.append((int(index_str), item_id, level, cells))
    return rows


class RenderAdjudicationPacketsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.outputs = rap.render_all()
        cls.live_scenarios = rap.load_live_scenarios()
        cls.live_cloze = rap.load_live_cloze()
        cls.live_vocab = rap.load_live_vocab()
        cls.live_satz = rap.load_live_satz()

    def test_three_packet_paths_are_expected(self) -> None:
        names = sorted(p.name for p in self.outputs)
        self.assertEqual(
            names,
            [
                "2026-09-15_adjudication_batch23_24.md",
                "2026-09-15_adjudication_scenarios52.md",
                "2026-09-15_adjudication_translation11.md",
            ],
        )

    def test_packets_written_to_disk_exist(self) -> None:
        rap.PACKETS_DIR.mkdir(parents=True, exist_ok=True)
        for path, content in self.outputs.items():
            path.write_text(content, encoding="utf-8")
        for path in self.outputs:
            self.assertTrue(path.is_file(), f"missing packet: {path}")

    def test_scenarios52_row_count_and_ids(self) -> None:
        markdown = self.outputs[rap.PACKETS_DIR / "2026-09-15_adjudication_scenarios52.md"]
        rows = parse_table_rows(markdown)
        self.assertEqual(len(rows), 52, "scenarios52 packet must have exactly 52 rows")
        seen_ids = set()
        for _, item_id, _level, cells in rows:
            self.assertIn(item_id, self.live_scenarios, f"id not in live assets: {item_id}")
            seen_ids.add(item_id)
            origin_cell = cells[0]
            self.assertTrue(origin_cell.strip(), f"empty 원문 cell for {item_id}")
        self.assertEqual(len(seen_ids), 52, "scenario ids must be unique")

    def test_translation11_row_count_and_ids(self) -> None:
        markdown = self.outputs[rap.PACKETS_DIR / "2026-09-15_adjudication_translation11.md"]
        rows = parse_table_rows(markdown)
        self.assertEqual(len(rows), 11, "translation11 packet must have exactly 11 rows")
        for _, item_id, _level, cells in rows:
            self.assertIn(item_id, self.live_cloze, f"id not in live assets: {item_id}")
            origin_cell = cells[0]
            self.assertTrue(origin_cell.strip(), f"empty 원문 cell for {item_id}")

    def test_batch23_24_row_count_and_ids(self) -> None:
        markdown = self.outputs[rap.PACKETS_DIR / "2026-09-15_adjudication_batch23_24.md"]
        rows = parse_table_rows(markdown)
        self.assertEqual(len(rows), 10, "batch23_24 packet must have exactly 10 rows")
        for _, item_id, _level, cells in rows:
            in_vocab = item_id in self.live_vocab
            in_satz = item_id in self.live_satz
            self.assertTrue(in_vocab or in_satz, f"id not in live assets: {item_id}")
            origin_cell = cells[0]
            self.assertTrue(origin_cell.strip(), f"empty 원문 cell for {item_id}")

    def test_no_row_has_empty_origin_cell_anywhere(self) -> None:
        for path, markdown in self.outputs.items():
            rows = parse_table_rows(markdown)
            self.assertTrue(rows, f"no rows parsed from {path.name}")
            for index, item_id, _level, cells in rows:
                self.assertGreaterEqual(len(cells), 4, f"{path.name} row {index} malformed")
                self.assertTrue(
                    cells[0].strip(),
                    f"{path.name} row {index} ({item_id}) has empty 원문 cell",
                )

    def test_header_states_no_modify_rule(self) -> None:
        for path, markdown in self.outputs.items():
            self.assertIn(rap.NO_MODIFY_RULE, markdown, f"{path.name} missing no-modify rule")

    def test_render_does_not_touch_assets_or_source_files(self) -> None:
        asset_files = list(rap.ASSETS.glob("*.json")) + list(rap.ASSETS.glob("*.csv"))
        before = {p: p.stat().st_mtime for p in asset_files}
        rap.render_all()
        after = {p: p.stat().st_mtime for p in asset_files}
        self.assertEqual(before, after, "render_all() must not modify assets/data/*")

        source_files = [rap.SCENARIO_SOURCE, rap.TRANSLATION_SOURCE, rap.BATCH23_SOURCE]
        before_src = {p: p.stat().st_mtime for p in source_files}
        rap.render_all()
        after_src = {p: p.stat().st_mtime for p in source_files}
        self.assertEqual(before_src, after_src, "render_all() must not modify the source review docs")


if __name__ == "__main__":
    unittest.main()
