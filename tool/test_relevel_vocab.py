#!/usr/bin/env python3
"""relevel_vocab.py 단위 테스트 — fixture 왕복으로 팩 무결성 계약 고정.

실행: python3 tool/test_relevel_vocab.py
"""

from __future__ import annotations

import csv
import io
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from relevel_vocab import COLUMNS, apply_batch  # noqa: E402


def _row(
    korean: str,
    level: str,
    pack_id: str,
    order: int,
    *,
    boss: bool = False,
    vid: str = "",
) -> dict[str, str]:
    return {
        "korean": korean,
        "romanization": korean,
        "german": f"de-{korean}",
        "level": level,
        "pos_de": "Nomen",
        "example_korean": f"{korean} 예문",
        "example_german": f"de {korean}",
        "topic": "test",
        "pack_id": pack_id,
        "pack_order": str(order),
        "is_review_boss": "true" if boss else "false",
        "english": "",
        "pos_en": "",
        "example_english": "",
        "id": vid or f"v_{korean}",
    }


def _fixture() -> list[dict[str, str]]:
    return [
        # b2 팩: 6단어, 마지막 2개 boss.
        _row("가치", "B2", "b2_src_1", 1),
        _row("경우", "B2", "b2_src_1", 2),
        _row("내용", "B2", "b2_src_1", 3),
        _row("본질", "B2", "b2_src_1", 4),
        _row("맥락", "B2", "b2_src_1", 5, boss=True),
        _row("전제", "B2", "b2_src_1", 6, boss=True),
        # b1 대상 팩: 3단어.
        _row("문제", "B1", "b1_dst_1", 1),
        _row("방법", "B1", "b1_dst_1", 2),
        _row("상황", "B1", "b1_dst_1", 3, boss=True),
    ]


def _batch(*entries: tuple[str, str, str, str]) -> list[dict[str, str]]:
    return [
        {
            "id": vid,
            "korean": korean,
            "old_level": old,
            "new_level": new,
            "target_pack": "b1_dst_1",
            "reason": "test",
        }
        for vid, korean, old, new in entries
    ]


class RelevelTest(unittest.TestCase):
    def test_move_appends_to_target_and_keeps_ids(self) -> None:
        vocab = _fixture()
        before_ids = sorted(r["id"] for r in vocab)
        plan, warnings = apply_batch(
            vocab, _batch(("v_경우", "경우", "B2", "B1")), locked=set()
        )
        self.assertEqual(sorted(r["id"] for r in vocab), before_ids)
        moved = next(r for r in vocab if r["id"] == "v_경우")
        self.assertEqual(moved["level"], "B1")
        self.assertEqual(moved["pack_id"], "b1_dst_1")
        self.assertEqual(moved["pack_order"], "4")  # max(3)+1
        self.assertEqual(moved["is_review_boss"], "false")
        self.assertTrue(any("v_경우" in p for p in plan))
        self.assertEqual(warnings, [])
        # 팩 레벨 동질성.
        for pack in {"b2_src_1", "b1_dst_1"}:
            levels = {r["level"] for r in vocab if r["pack_id"] == pack}
            self.assertEqual(len(levels), 1, pack)

    def test_boss_repair_promotes_when_boss_moves(self) -> None:
        vocab = _fixture()
        apply_batch(vocab, _batch(("v_전제", "전제", "B2", "B1")), locked=set())
        remaining = [r for r in vocab if r["pack_id"] == "b2_src_1"]
        bosses = [r for r in remaining if r["is_review_boss"] == "true"]
        self.assertEqual(len(bosses), 2)  # 맥락 + 승격 1

    def test_min_size_warning(self) -> None:
        vocab = _fixture()
        _, warnings = apply_batch(
            vocab,
            _batch(
                ("v_가치", "가치", "B2", "B1"),
                ("v_경우", "경우", "B2", "B1"),
                ("v_내용", "내용", "B2", "B1"),
            ),
            locked=set(),
        )
        self.assertTrue(any("b2_src_1" in w for w in warnings))

    def test_second_apply_is_rejected(self) -> None:
        vocab = _fixture()
        batch = _batch(("v_경우", "경우", "B2", "B1"))
        apply_batch(vocab, batch, locked=set())
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch, locked=set())  # old_level 불일치

    def test_satz_locked_word_is_rejected(self) -> None:
        vocab = _fixture()
        with self.assertRaises(SystemExit):
            apply_batch(
                vocab,
                _batch(("v_경우", "경우", "B2", "B1")),
                locked={("b2", "경우")},
            )

    def test_unknown_target_pack_is_rejected(self) -> None:
        vocab = _fixture()
        batch = _batch(("v_경우", "경우", "B2", "B1"))
        batch[0]["target_pack"] = "b1_nope"
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch, locked=set())

    def test_target_level_mismatch_is_rejected(self) -> None:
        vocab = _fixture()
        batch = _batch(("v_경우", "경우", "B2", "A2"))
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch, locked=set())  # b1_dst_1 레벨 ≠ A2

    def test_csv_round_trip_shape(self) -> None:
        vocab = _fixture()
        apply_batch(vocab, _batch(("v_경우", "경우", "B2", "B1")), locked=set())
        buf = io.StringIO()
        writer = csv.writer(buf, lineterminator="\n")
        writer.writerow(COLUMNS)
        for row in vocab:
            writer.writerow([row[c] for c in COLUMNS])
        buf.seek(0)
        parsed = list(csv.reader(buf))
        self.assertEqual(len(parsed), len(vocab) + 1)
        self.assertEqual(parsed[0], COLUMNS)


if __name__ == "__main__":
    unittest.main()
