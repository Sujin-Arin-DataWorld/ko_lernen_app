#!/usr/bin/env python3
"""relevel_vocab.py 단위 테스트 — fixture 왕복으로 팩 무결성 계약 + T2.5(PR-L2a
Part C) 동기화 이동(cloze/satz/can_do 예속행/ledger) 계약을 고정한다.

실행: python3 tool/test_relevel_vocab.py
"""

from __future__ import annotations

import csv
import io
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools" / "content_factory"))

from relevel_ledger import Ledger, LedgerEntry  # noqa: E402
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
        # id must carry a REAL level segment (vocab_<level>_...) matching
        # `level` -- relevel_vocab._ledger_record derives a ledger entry's
        # `from_level` straight from `id.split("_")[1]` (mirroring
        # relevel_ledger.validate_ledger's own id-segment check), so a
        # non-level-shaped id (e.g. "vocab_test_...") would wrongly report
        # from_level='test'.
        "id": vid or f"vocab_{level.lower()}_{korean}",
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


def _batch(*entries: tuple[str, str, str, str], target: str = "b1_dst_1") -> list[dict[str, str]]:
    return [
        {
            "id": vid,
            "korean": korean,
            "old_level": old,
            "new_level": new,
            "target_pack": target,
            "reason": "test",
        }
        for vid, korean, old, new in entries
    ]


def _cloze_root(*items: dict) -> dict:
    return {"meta": {"total": 0, "perLevel": {}}, "items": list(items)}


def _satz_root(*items: dict) -> dict:
    return {"meta": {"total": 0, "perLevel": {}}, "items": list(items)}


def _authorities(*inherited: dict) -> dict:
    return {"coverage": {"inheritedContentReferences": list(inherited)}}


def _segments_doc() -> dict:
    """target_pack='b1_dst_1' 를 직접 참조하는 클러스터/세그먼트 하나."""
    return {
        "contentClusters": [
            {
                "id": "cluster_target",
                "level": "b1",
                "contentReferences": [{"kind": "vocabPack", "id": "b1_dst_1"}],
                "revision": 1,
            },
        ],
        "segments": [
            {
                "id": "segment_target",
                "level": "b1",
                "parentCourseUnitId": "unit_b1_dst",
                "contentClusterIds": ["cluster_target"],
            },
        ],
    }


def _curriculum(unit_map: dict | None = None, cloze_topic_map: dict | None = None) -> dict:
    return {
        "vocabPackUnitMap": {"b1_dst": "unit_b1_dst"} if unit_map is None else unit_map,
        "clozeTopicUnitMap": {} if cloze_topic_map is None else cloze_topic_map,
    }


def _empty_env() -> dict:
    """cloze/satz/authorities/segments/curriculum 를 전부 빈 상태로 채운 kwargs."""
    return dict(
        cloze_root=_cloze_root(),
        satz_root=_satz_root(),
        authorities=_authorities(),
        segments_doc=_segments_doc(),
        curriculum=_curriculum(),
        ledger=Ledger(version=1, entries=[]),
        batch_name="test_batch",
    )


class PackIntegrityTest(unittest.TestCase):
    """기존(2026-08-13) 팩 무결성 계약 — target 재선정 규칙만 유지, satz 거부는
    제거되고 동기화 이동으로 대체됐다(아래 SyncedMoveTest)."""

    def test_move_appends_to_target_and_keeps_ids(self) -> None:
        vocab = _fixture()
        before_ids = sorted(r["id"] for r in vocab)
        plan, warnings, _ledger = apply_batch(
            vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **_empty_env()
        )
        self.assertEqual(sorted(r["id"] for r in vocab), before_ids)
        moved = next(r for r in vocab if r["id"] == "vocab_b2_경우")
        self.assertEqual(moved["level"], "B1")
        self.assertEqual(moved["pack_id"], "b1_dst_1")
        self.assertEqual(moved["pack_order"], "4")  # max(3)+1
        self.assertEqual(moved["is_review_boss"], "false")
        self.assertTrue(any("vocab_b2_경우" in p for p in plan))
        self.assertEqual(warnings, [])
        for pack in {"b2_src_1", "b1_dst_1"}:
            levels = {r["level"] for r in vocab if r["pack_id"] == pack}
            self.assertEqual(len(levels), 1, pack)

    def test_boss_repair_promotes_when_boss_moves(self) -> None:
        vocab = _fixture()
        apply_batch(vocab, batch=_batch(("vocab_b2_전제", "전제", "B2", "B1")), **_empty_env())
        remaining = [r for r in vocab if r["pack_id"] == "b2_src_1"]
        bosses = [r for r in remaining if r["is_review_boss"] == "true"]
        self.assertEqual(len(bosses), 2)  # 맥락 + 승격 1

    def test_min_size_warning(self) -> None:
        vocab = _fixture()
        _, warnings, _ledger = apply_batch(
            vocab,
            batch=_batch(
                ("vocab_b2_가치", "가치", "B2", "B1"),
                ("vocab_b2_경우", "경우", "B2", "B1"),
                ("vocab_b2_내용", "내용", "B2", "B1"),
            ),
            **_empty_env(),
        )
        self.assertTrue(any("b2_src_1" in w for w in warnings))

    def test_second_apply_is_rejected(self) -> None:
        vocab = _fixture()
        batch = _batch(("vocab_b2_경우", "경우", "B2", "B1"))
        apply_batch(vocab, batch=batch, **_empty_env())
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch=batch, **_empty_env())  # old_level 불일치

    def test_unknown_target_pack_is_rejected(self) -> None:
        vocab = _fixture()
        batch = _batch(("vocab_b2_경우", "경우", "B2", "B1"))
        batch[0]["target_pack"] = "b1_nope"
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch=batch, **_empty_env())

    def test_target_level_mismatch_is_rejected(self) -> None:
        vocab = _fixture()
        batch = _batch(("vocab_b2_경우", "경우", "B2", "A2"))
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch=batch, **_empty_env())  # b1_dst_1 레벨 ≠ A2

    def test_empty_reason_is_rejected(self) -> None:
        vocab = _fixture()
        batch = _batch(("vocab_b2_경우", "경우", "B2", "B1"))
        batch[0]["reason"] = ""
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch=batch, **_empty_env())

    def test_csv_round_trip_shape(self) -> None:
        vocab = _fixture()
        apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **_empty_env())
        buf = io.StringIO()
        writer = csv.writer(buf, lineterminator="\n")
        writer.writerow(COLUMNS)
        for row in vocab:
            writer.writerow([row[c] for c in COLUMNS])
        buf.seek(0)
        parsed = list(csv.reader(buf))
        self.assertEqual(len(parsed), len(vocab) + 1)
        self.assertEqual(parsed[0], COLUMNS)


class SyncedMoveTest(unittest.TestCase):
    """T2.5 Part C: satz 거부 대신 cloze/satz/can_do 예속행을 함께 옮긴다."""

    def test_satz_word_is_moved_not_rejected(self) -> None:
        vocab = _fixture()
        satz_root = _satz_root({"id": "satz_b2_0001", "level": "b2", "vocabKo": "경우"})
        env = _empty_env()
        env["satz_root"] = satz_root
        plan, _warnings, ledger = apply_batch(
            vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env
        )
        self.assertEqual(satz_root["items"][0]["level"], "b1")
        self.assertTrue(any("satz_b2_0001" in p for p in plan))
        entry = ledger.get("satz", "satz_b2_0001")
        self.assertIsNotNone(entry)
        self.assertEqual((entry.from_level, entry.to_level), ("b2", "b1"))
        self.assertEqual(entry.batch, "test_batch")

    def test_cloze_word_is_moved_via_example_korean(self) -> None:
        vocab = _fixture()
        cloze_root = _cloze_root(
            {"id": "cloze_b2_0001", "level": "b2", "fullKo": "경우 예문"},
            # 다른 레벨/다른 문장은 건드리지 않는다.
            {"id": "cloze_b2_0002", "level": "b2", "fullKo": "가치 예문"},
        )
        env = _empty_env()
        env["cloze_root"] = cloze_root
        apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env)
        moved = next(i for i in cloze_root["items"] if i["id"] == "cloze_b2_0001")
        untouched = next(i for i in cloze_root["items"] if i["id"] == "cloze_b2_0002")
        self.assertEqual(moved["level"], "b1")
        self.assertEqual(untouched["level"], "b2")

    def test_cloze_topic_unit_map_gains_new_level_key_and_prunes_vacated_one(self) -> None:
        # relevel_bundle._migrate_curriculum_manifest's own add/prune rule,
        # replicated per-word: ContentValidator requires every live
        # (level, topic) cloze combination to have a clozeTopicUnitMap key.
        cloze_root = _cloze_root({
            "id": "cloze_b2_0001", "level": "b2", "fullKo": "경우 예문", "topic": "Alltag",
        })
        env = _empty_env()
        env["cloze_root"] = cloze_root
        env["curriculum"] = _curriculum(cloze_topic_map={"b2:alltag": "unit_b2_old"})
        vocab = _fixture()
        plan, _warnings, _ledger = apply_batch(
            vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env
        )
        topic_map = env["curriculum"]["clozeTopicUnitMap"]
        self.assertEqual(topic_map.get("b1:alltag"), "unit_b1_dst")  # added
        self.assertNotIn("b2:alltag", topic_map)  # pruned (no b2 cloze left)
        self.assertTrue(any("clozeTopicUnitMap" in p for p in plan))

    def test_cloze_topic_unit_map_key_not_pruned_while_another_item_still_uses_it(self) -> None:
        cloze_root = _cloze_root(
            {"id": "cloze_b2_0001", "level": "b2", "fullKo": "경우 예문", "topic": "Alltag"},
            # 다른 팩 소속 단어의 cloze 지만 같은 (level, topic) -- 살아있는 채로 남는다.
            {"id": "cloze_b2_0099", "level": "b2", "fullKo": "다른 문장", "topic": "Alltag"},
        )
        env = _empty_env()
        env["cloze_root"] = cloze_root
        env["curriculum"] = _curriculum(cloze_topic_map={"b2:alltag": "unit_b2_old"})
        vocab = _fixture()
        apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env)
        topic_map = env["curriculum"]["clozeTopicUnitMap"]
        self.assertIn("b2:alltag", topic_map)  # NOT pruned -- cloze_b2_0099 still there

    def test_cloze_and_satz_meta_per_level_refreshed(self) -> None:
        vocab = _fixture()
        cloze_root = _cloze_root({"id": "cloze_b2_0001", "level": "b2", "fullKo": "경우 예문"})
        satz_root = _satz_root({"id": "satz_b2_0001", "level": "b2", "vocabKo": "경우"})
        env = _empty_env()
        env["cloze_root"] = cloze_root
        env["satz_root"] = satz_root
        apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env)
        self.assertEqual(cloze_root["meta"]["total"], 1)
        self.assertEqual(cloze_root["meta"]["perLevel"]["b1"], 1)
        self.assertEqual(cloze_root["meta"]["perLevel"]["b2"], 0)
        self.assertEqual(satz_root["meta"]["perLevel"]["b1"], 1)

    def test_can_do_inherited_row_follows_target_pack(self) -> None:
        vocab = _fixture()
        authorities = _authorities({
            "kind": "cloze", "id": "cloze_b2_0001", "sourceKind": "vocabPack",
            "sourceId": "b2_src_1", "sourceVocabId": "vocab_b2_경우",
            "sourceVocabFingerprintSha256": "stale-hash",
            "level": "b2", "canDoSegmentId": "segment_old", "courseUnitId": "unit_old",
        })
        env = _empty_env()
        env["authorities"] = authorities
        apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env)
        row = authorities["coverage"]["inheritedContentReferences"][0]
        self.assertEqual(row["sourceId"], "b1_dst_1")
        self.assertEqual(row["level"], "b1")
        self.assertEqual(row["courseUnitId"], "unit_b1_dst")
        self.assertEqual(row["canDoSegmentId"], "segment_target")
        # 지문에 따라 fingerprint 는 이 함수의 책임이 아니다 (refresh_can_do_
        # vocab_fingerprints.py 가 apply 이후 별도로 재계산) -- 건드리지 않고
        # 그대로 두는지 확인.
        self.assertEqual(row["sourceVocabFingerprintSha256"], "stale-hash")

    def test_can_do_inherited_row_untouched_when_id_does_not_match(self) -> None:
        vocab = _fixture()
        authorities = _authorities({
            "kind": "cloze", "id": "cloze_b2_9999", "sourceKind": "vocabPack",
            "sourceId": "b2_src_1", "sourceVocabId": "vocab_b2_다른단어",
            "sourceVocabFingerprintSha256": "unrelated",
            "level": "b2", "canDoSegmentId": "segment_old", "courseUnitId": "unit_old",
        })
        env = _empty_env()
        env["authorities"] = authorities
        apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env)
        row = authorities["coverage"]["inheritedContentReferences"][0]
        self.assertEqual(row["sourceId"], "b2_src_1")  # 안 옮겨짐

    def test_word_with_no_inherited_rows_is_not_an_error(self) -> None:
        vocab = _fixture()
        plan, warnings, _ledger = apply_batch(
            vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **_empty_env()
        )
        self.assertTrue(any("vocab_b2_경우" in p for p in plan))

    def test_target_pack_missing_from_unit_map_is_rejected(self) -> None:
        vocab = _fixture()
        env = _empty_env()
        env["curriculum"] = _curriculum(unit_map={})
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env)

    def test_target_pack_with_no_cluster_reference_is_rejected(self) -> None:
        vocab = _fixture()
        env = _empty_env()
        env["segments_doc"] = {"contentClusters": [], "segments": []}
        with self.assertRaises(SystemExit):
            apply_batch(vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env)

    def test_vocab_ledger_entry_recorded(self) -> None:
        vocab = _fixture()
        batch = _batch(("vocab_b2_경우", "경우", "B2", "B1"))
        batch[0]["reason"] = "kiiq b1, Fable 룰링 2026-09-07"
        _plan, _warnings, ledger = apply_batch(vocab, batch=batch, **_empty_env())
        entry = ledger.get("vocab", "vocab_b2_경우")
        self.assertIsNotNone(entry)
        self.assertEqual((entry.from_level, entry.to_level), ("b2", "b1"))
        self.assertEqual(entry.reason, "kiiq b1, Fable 룰링 2026-09-07")
        self.assertEqual(entry.batch, "test_batch")

    def test_second_relevel_of_the_same_id_updates_not_duplicates_the_ledger(self) -> None:
        # A word can legitimately move MORE than once over its lifetime
        # (e.g. an earlier PR-L2a *pack* move already took it a1->a2, and
        # this batch now moves it again a2->b1 as a per-word T2.5 move).
        # The id's OWN embedded level segment never changes ("vocab_a1_..."
        # stays "a1" forever, plan "ID는 불변") even though its live level
        # has already drifted once -- Ledger.append() rejects a second
        # entry for the same id outright, so relevel_vocab must instead
        # REPLACE the existing entry, preserving the ORIGINAL from_level
        # (matching relevel_ledger.validate_ledger's own id-segment check)
        # rather than recording today's batch old_level ("b2") as from.
        vocab = _fixture()
        reused = next(r for r in vocab if r["korean"] == "경우")
        reused["id"] = "vocab_a1_경우"
        reused["level"] = "B2"
        pre_existing = Ledger(version=1, entries=[
            LedgerEntry(
                id="vocab_a1_경우", kind="vocab", from_level="a1", to_level="b2",
                movedAt="2026-01-01", batch="earlier_batch", reason="earlier move",
            ),
        ])
        env = _empty_env()
        env["ledger"] = pre_existing
        _plan, _warnings, ledger = apply_batch(
            vocab, batch=_batch(("vocab_a1_경우", "경우", "B2", "B1")), **env
        )
        matching = [e for e in ledger.entries if e.id == "vocab_a1_경우"]
        self.assertEqual(len(matching), 1)  # replaced, not appended alongside
        entry = matching[0]
        self.assertEqual(entry.from_level, "a1")  # preserved from the ORIGINAL move
        self.assertEqual(entry.to_level, "b1")  # updated to today's target
        self.assertEqual(entry.batch, "test_batch")  # today's batch, not the old one

    def test_ledger_grows_across_multiple_entries_in_one_batch(self) -> None:
        vocab = _fixture()
        cloze_root = _cloze_root({"id": "cloze_b2_0001", "level": "b2", "fullKo": "경우 예문"})
        env = _empty_env()
        env["cloze_root"] = cloze_root
        _plan, _warnings, ledger = apply_batch(
            vocab, batch=_batch(("vocab_b2_경우", "경우", "B2", "B1")), **env
        )
        kinds = sorted((e.kind, e.id) for e in ledger.entries)
        self.assertIn(("cloze", "cloze_b2_0001"), kinds)
        self.assertIn(("vocab", "vocab_b2_경우"), kinds)


if __name__ == "__main__":
    unittest.main()
