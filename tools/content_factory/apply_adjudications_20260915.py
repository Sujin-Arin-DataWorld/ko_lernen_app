#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Apply Jin's 2026-09-15 adjudication decisions to live content assets (C1-T2).

Sources (Jin's final decisions, column "Jin 판정"):
  - docs/data/review_packets/2026-09-15_adjudication_translation11_natural_final.md
  - docs/data/review_packets/2026-09-15_adjudication_batch23_24_natural_final.md
  - docs/data/review_packets/2026-09-15_adjudication_scenarios52_natural_final.md

What this script touches:
  - assets/data/cloze.json            (translation11 primary edits + mirrors)
  - assets/data/korean_vocab.csv       (batch23/24 primary edits + mirrors;
                                         example_korean/german/english only)
  - assets/data/satz_sentences.json    (derived-copy propagation only)
  - assets/data/scenarios_{level}.json (dialog ko/de/en for all 52 scenarios)

Design notes:
  - The translation11 and batch23_24 packets are small (11 + 10 rows) with
    natural-language "Jin 판정" cells that mix approvals, partial rewrites,
    and one KO+answer rewrite. Rather than free-text-parse that prose (error
    prone for content that ships to users), the exact before/after values
    below were transcribed by hand from the packets and are asserted against
    the live assets at run time -- any drift between this script's "old"
    values and what is actually live aborts the run immediately.
  - The scenarios52 packet's "최종 자연화본" <details> blocks are fully
    regular (numbered speaker/KO/DE/EN turns), so those ARE parsed
    programmatically from the markdown.
  - "Derived copies": cloze.json, korean_vocab.csv and satz_sentences.json
    all contain independently-maintained copies of the same Korean example
    sentences (discovered by exact KO-text match across all three corpora).
    Whichever corpus this task's edits land in first, the sentence's other
    verbatim copies are updated too so one Korean sentence never carries two
    different "canonical" DE/EN translations across the app. This applies in
    both directions: batch23_24 vocab-CSV edits propagate to their cloze/satz
    mirrors, and translation11 cloze edits propagate to their vocab/satz
    mirrors.
"""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
ASSETS = REPO_ROOT / "assets" / "data"
PACKETS = REPO_ROOT / "docs" / "data" / "review_packets"

CLOZE_PATH = ASSETS / "cloze.json"
VOCAB_PATH = ASSETS / "korean_vocab.csv"
SATZ_PATH = ASSETS / "satz_sentences.json"
SCENARIO_LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
SCENARIO_PATHS = {lvl: ASSETS / f"scenarios_{lvl}.json" for lvl in SCENARIO_LEVELS}

SCENARIOS52_PACKET = PACKETS / "2026-09-15_adjudication_scenarios52_natural_final.md"

CHANGE_LOG: list[dict] = []


def record(source: str, item_id: str, field: str, before, after) -> None:
    if before == after:
        return
    CHANGE_LOG.append(
        {"source": source, "id": item_id, "field": field, "before": before, "after": after}
    )


def write_json(path: Path, data: dict) -> None:
    text = json.dumps(data, ensure_ascii=False, indent=2)
    path.write_text(text + "\n", encoding="utf-8", newline="\n")


# ---------------------------------------------------------------------------
# translation11: cloze.json id -> {field: (old, new)}
# One item (cloze_b1_0119) was 승인 (approved as-is) and is intentionally
# absent here -- no field of it changes.
# ---------------------------------------------------------------------------
CLOZE_UPDATES: dict[str, dict[str, tuple[str, str]]] = {
    "cloze_b1_0118": {
        "de": (
            "Hyunwoo hat mir zugeflüstert, ich solle das nicht so schludrig machen.",
            "Hyunwoo flüsterte mir zu, ich solle das nicht so schludrig machen.",
        ),
        "en": (
            "Hyunwoo whispered to me not to do it carelessly.",
            "Hyunwoo whispered to me not to do it so carelessly.",
        ),
    },
    "cloze_b2_0264": {
        "de": (
            "Weil ich zuerst gesagt habe, wie wir zueinander stehen, passte der Moment für den Handschlag.",
            "Weil ich zuerst erklärt habe, in welcher Beziehung wir zueinander stehen, passte der Zeitpunkt für den Handschlag.",
        ),
        "en": (
            "Because I said first how we were related, the handshake came at the right moment.",
            "Once I explained our relationship, the timing of the handshake felt right.",
        ),
    },
    "cloze_c1_0076": {
        "de": (
            "Als wir die Fairness bewusst geplant hatten, blieb am Ende eine Tabelle statt verletzter Gefühle.",
            "Als wir Fairness bewusst mit einplanten, blieb am Ende eine Tabelle statt verletzter Gefühle.",
        ),
        "en": (
            "Once we had designed the fairness deliberately, what remained was a table, not hurt feelings.",
            "Once we deliberately designed for fairness, what remained was a table rather than hurt feelings.",
        ),
    },
    "cloze_c2_0075": {
        "de": (
            "Als wir die Erinnerungen neu geordnet hatten, war ich nicht mehr nur ein Gast.",
            "Als wir die Erinnerungen neu ordneten, war ich nicht mehr nur ein Gast.",
        ),
        "en": (
            "Once the memories were rearranged, I was no longer just a guest.",
            "Once we rearranged the memories, I was no longer just a guest.",
        ),
    },
    "cloze_c2_0076": {
        "de": (
            "Weil wir die Erzählung gemeinsam trugen, wurde aus dem Scherz einer Person nicht die Geschichte aller.",
            "Weil wir die Erzählung gemeinsam trugen, wurde der Scherz einer einzelnen Person nicht zur Geschichte aller.",
        ),
        "en": (
            "Because we shared the story, one person's joke did not become everyone's history.",
            "Because we shared the narrative, one person's joke didn't become everyone's history.",
        ),
    },
    "cloze_b1_0109": {
        "de": (
            "Die lange Rede gab ich knapp weiter, so blieb nur der Kern.",
            "Die lange Geschichte fasste ich beim Weitergeben zusammen, sodass nur das Wesentliche blieb.",
        ),
        "en": (
            "I passed the long story on as a summary, so only the core was left.",
            "I summarized the long story as I passed it on, so only the key points remained.",
        ),
    },
    "cloze_b1_0153": {
        "fullKo": (
            "잠자리 경계 다시 정하니 둘이 편해졌어요.",
            "잠자리 경계를 다시 정하니 둘 다 편해졌어요.",
        ),
        "answer": ("경계 다시 정하니", "경계를 다시 정하니"),
        "de": (
            "Als wir die Schlafregelung neu festlegten, wurde es für uns beide leichter.",
            "Als wir die Schlafregelung neu festlegten, fühlten wir uns beide wohler.",
        ),
        "en": (
            "Once we reset the sleeping arrangement, it got easier for both of us.",
            "Once we reset the sleeping arrangements, we both felt more comfortable.",
        ),
    },
    "cloze_c1_0075": {
        "de": (
            "Arbeit sichtbar zu machen verschob, wem gedankt wurde.",
            "Als wir die Arbeit sichtbar machten, änderte sich, wem gedankt wurde.",
        ),
        "en": (
            "Making labor visible changed who received thanks.",
            "Making the work visible changed who was thanked.",
        ),
    },
    "cloze_c2_0062": {
        "de": (
            "Als ich die Macht beim Namen nannte, wurde es im Raum kurz still, dann kam der Atem zurück.",
            "Als ich die Macht beim Namen nannte, wurde es im Raum kurz still; dann konnten alle wieder atmen.",
        ),
    },
    "cloze_c2_0063": {
        "de": (
            "Nicht die Stimmung, sondern ein Verfahren zu verlangen machte die nächste Entscheidung transparent.",
            "Dass ich nicht nach Stimmung, sondern nach einem klaren Verfahren verlangte, machte die nächste Entscheidung transparenter.",
        ),
        "en": (
            "Demanding a procedure, not a mood, made the next decision clearer.",
            "Demanding a clear procedure rather than going by mood made the next decision more transparent.",
        ),
    },
}

# Each translation11 cloze id mirrors exactly one korean_vocab.csv row and one
# satz_sentences.json item (same fullKo/example_korean/targetKo, found by
# exact-text match across the corpus). de/en/fullKo fixes propagate there.
CLOZE_MIRRORS: dict[str, tuple[str, str]] = {
    "cloze_b1_0118": ("vocab_b1_0306", "satz_b1_0114"),
    "cloze_b2_0264": ("vocab_b2_0525", "satz_b2_0250"),
    "cloze_c1_0076": ("vocab_c1_0072", "satz_c1_0078"),
    "cloze_c2_0075": ("vocab_c2_0071", "satz_c2_0077"),
    "cloze_c2_0076": ("vocab_c2_0072", "satz_c2_0078"),
    "cloze_b1_0109": ("vocab_b1_0297", "satz_b1_0105"),
    "cloze_b1_0153": ("vocab_b1_0341", "satz_b1_0149"),
    "cloze_c1_0075": ("vocab_c1_0071", "satz_c1_0077"),
    "cloze_c2_0062": ("vocab_c2_0058", "satz_c2_0064"),
    "cloze_c2_0063": ("vocab_c2_0059", "satz_c2_0065"),
}

# ---------------------------------------------------------------------------
# Batch 23/24: korean_vocab.csv id -> {column: (old, new)}. Only
# example_korean / example_german / example_english may change.
# ---------------------------------------------------------------------------
VOCAB_UPDATES: dict[str, dict[str, tuple[str, str]]] = {
    "vocab_a1_0428": {
        "example_german": ("In Korea ist jetzt Herbst.", "In Korea ist gerade Herbst."),
        "example_english": ("It's autumn in Korea now.", "It's fall in Korea right now."),
    },
    "vocab_b1_0488": {
        "example_german": (
            "Ich glaube, wir hatten ein Missverständnis.",
            "Ich glaube, zwischen uns gab es ein Missverständnis.",
        ),
    },
    "vocab_b2_0649": {
        "example_english": (
            "Once you know the principle, applying it isn't hard.",
            "Once you understand the principle, applying it isn't difficult.",
        ),
    },
    "vocab_b2_0654": {
        "example_korean": (
            "그 교수님 강의는 항상 자리가 없어요.",
            "그 교수님 강의는 항상 자리가 꽉 차요.",
        ),
        "example_german": (
            "In der Vorlesung von diesem Professor sind die Plätze immer voll.",
            "Die Vorlesungen dieses Professors sind immer voll.",
        ),
    },
}

# Each changed batch23/24 vocab row mirrors exactly one cloze.json item and
# one satz_sentences.json item (same example_korean/fullKo/targetKo).
VOCAB_MIRRORS: dict[str, tuple[str, str]] = {
    "vocab_a1_0428": ("cloze_a1_0351", "satz_a1_0339"),
    "vocab_b1_0488": ("cloze_b1_0290", "satz_b1_0483"),
    "vocab_b2_0649": ("cloze_b2_0394", "satz_b2_0552"),
    "vocab_b2_0654": ("cloze_b2_0399", "satz_b2_0557"),
}


# ---------------------------------------------------------------------------
# scenarios52: parse the "최종 자연화본" <details> blocks programmatically.
# ---------------------------------------------------------------------------
_BLOCK_RE = re.compile(
    r"<details><summary>(\d+)\. `([a-z0-9_]+)` — ([^(]+)\(([^)]*)\)</summary>\n\n(.*?)\n\n</details>",
    re.DOTALL,
)
_TURN_RE = re.compile(
    r"(\d+)\.\s+\*\*(\S+)\*\*\s*\n\s*-\s*KO:\s*(.*)\n\s*-\s*DE:\s*(.*)\n\s*-\s*EN:\s*(.*)"
)


def parse_scenarios52_packet() -> dict[str, list[dict[str, str]]]:
    text = SCENARIOS52_PACKET.read_text(encoding="utf-8")
    blocks = _BLOCK_RE.findall(text)
    if len(blocks) != 52:
        raise AssertionError(f"expected 52 scenario blocks, parsed {len(blocks)}")
    result: dict[str, list[dict[str, str]]] = {}
    for _num, sid, _title, _meta, body in blocks:
        turns = _TURN_RE.findall(body)
        nums = [int(t[0]) for t in turns]
        if nums != list(range(1, len(nums) + 1)):
            raise AssertionError(f"{sid}: non-sequential turn numbers {nums}")
        result[sid] = [
            {"speaker": speaker, "ko": ko, "de": de, "en": en}
            for (_n, speaker, ko, de, en) in turns
        ]
    return result


def apply_scenarios(scenario_dialogs: dict[str, list[dict[str, str]]]) -> list[str]:
    """Replace dialog ko/de/en for all 52 scenarios. Returns scenario ids whose
    FIRST dialog line's KO text changed (bundled first-line TTS becomes stale)."""
    first_line_changed: list[str] = []
    for lvl in SCENARIO_LEVELS:
        path = SCENARIO_PATHS[lvl]
        data = json.loads(path.read_text(encoding="utf-8"))
        touched = False
        for scenario in data["scenarios"]:
            sid = scenario["id"]
            if sid not in scenario_dialogs:
                continue
            new_turns = scenario_dialogs[sid]
            live_dialog = scenario["dialog"]
            if len(live_dialog) != len(new_turns):
                raise AssertionError(
                    f"{sid}: live dialog has {len(live_dialog)} turns, "
                    f"packet has {len(new_turns)}"
                )
            for i, (live_turn, new_turn) in enumerate(zip(live_dialog, new_turns)):
                if live_turn["speaker"] != new_turn["speaker"]:
                    raise AssertionError(
                        f"{sid}[{i}]: speaker mismatch live={live_turn['speaker']} "
                        f"packet={new_turn['speaker']}"
                    )
                for field in ("ko", "de", "en"):
                    before = live_turn[field]
                    after = new_turn[field]
                    if before != after:
                        record("scenarios52", f"{sid}[{i}].{field}", field, before, after)
                        live_turn[field] = after
                        touched = True
                        if i == 0 and field == "ko":
                            first_line_changed.append(sid)
        if touched:
            write_json(path, data)
    return first_line_changed


BLANK = "＿＿＿"


def _resync_sentence_ko(cloze_item: dict, source: str) -> None:
    """Recompute the blanked sentenceKo template from the (possibly just
    updated) fullKo + answer, and sanity-check the reconstruction round-trips."""
    full_ko = cloze_item["fullKo"]
    answer = cloze_item["answer"]
    if answer not in full_ko:
        raise AssertionError(
            f"{cloze_item['id']}: answer {answer!r} not found in fullKo {full_ko!r}"
        )
    new_sentence_ko = full_ko.replace(answer, BLANK, 1)
    before = cloze_item["sentenceKo"]
    if before != new_sentence_ko:
        record(source, cloze_item["id"], "sentenceKo", before, new_sentence_ko)
        cloze_item["sentenceKo"] = new_sentence_ko


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def apply_cloze_vocab_satz() -> None:
    cloze_data = load_json(CLOZE_PATH)
    cloze_by_id = {item["id"]: item for item in cloze_data["items"]}

    with VOCAB_PATH.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        vocab_fieldnames = reader.fieldnames
        vocab_rows = list(reader)
    vocab_by_id = {row["id"]: row for row in vocab_rows}

    satz_data = load_json(SATZ_PATH)
    satz_by_id = {item["id"]: item for item in satz_data["items"]}

    # --- Step A: translation11 primary edits (cloze.json) -----------------
    for cid, field_updates in CLOZE_UPDATES.items():
        item = cloze_by_id[cid]
        for field, (old, new) in field_updates.items():
            live = item[field]
            if live != old:
                raise AssertionError(
                    f"{cid}.{field}: live value does not match expected 'old' "
                    f"value.\n  live={live!r}\n  expected old={old!r}"
                )
            record("translation11", cid, field, old, new)
            item[field] = new
        if "fullKo" in field_updates or "answer" in field_updates:
            _resync_sentence_ko(item, "translation11")

        # propagate de/en/fullKo fixes to this item's vocab + satz mirror
        vocab_mid, satz_mid = CLOZE_MIRRORS[cid]
        vrow = vocab_by_id[vocab_mid]
        sitem = satz_by_id[satz_mid]
        if "fullKo" in field_updates:
            record("translation11-mirror", vocab_mid, "example_korean", vrow["example_korean"], item["fullKo"])
            vrow["example_korean"] = item["fullKo"]
            record("translation11-mirror", satz_mid, "targetKo", sitem["targetKo"], item["fullKo"])
            sitem["targetKo"] = item["fullKo"]
        if "de" in field_updates:
            record("translation11-mirror", vocab_mid, "example_german", vrow["example_german"], item["de"])
            vrow["example_german"] = item["de"]
            record("translation11-mirror", satz_mid, "promptDe", sitem["promptDe"], item["de"])
            sitem["promptDe"] = item["de"]
        if "en" in field_updates:
            record("translation11-mirror", vocab_mid, "example_english", vrow["example_english"], item["en"])
            vrow["example_english"] = item["en"]
            record("translation11-mirror", satz_mid, "promptEn", sitem["promptEn"], item["en"])
            sitem["promptEn"] = item["en"]

    # --- Step B: batch23/24 primary edits (korean_vocab.csv) ---------------
    for vid, field_updates in VOCAB_UPDATES.items():
        row = vocab_by_id[vid]
        for field, (old, new) in field_updates.items():
            live = row[field]
            if live != old:
                raise AssertionError(
                    f"{vid}.{field}: live value does not match expected 'old' "
                    f"value.\n  live={live!r}\n  expected old={old!r}"
                )
            record("batch23_24", vid, field, old, new)
            row[field] = new

        # propagate example_* fixes to this row's cloze + satz mirror
        cloze_mid, satz_mid = VOCAB_MIRRORS[vid]
        citem = cloze_by_id[cloze_mid]
        sitem = satz_by_id[satz_mid]
        if "example_korean" in field_updates:
            record("batch23_24-mirror", cloze_mid, "fullKo", citem["fullKo"], row["example_korean"])
            citem["fullKo"] = row["example_korean"]
            _resync_sentence_ko(citem, "batch23_24-mirror")
            record("batch23_24-mirror", satz_mid, "targetKo", sitem["targetKo"], row["example_korean"])
            sitem["targetKo"] = row["example_korean"]
        if "example_german" in field_updates:
            record("batch23_24-mirror", cloze_mid, "de", citem["de"], row["example_german"])
            citem["de"] = row["example_german"]
            record("batch23_24-mirror", satz_mid, "promptDe", sitem["promptDe"], row["example_german"])
            sitem["promptDe"] = row["example_german"]
        if "example_english" in field_updates:
            record("batch23_24-mirror", cloze_mid, "en", citem["en"], row["example_english"])
            citem["en"] = row["example_english"]
            record("batch23_24-mirror", satz_mid, "promptEn", sitem["promptEn"], row["example_english"])
            sitem["promptEn"] = row["example_english"]

    write_json(CLOZE_PATH, cloze_data)
    write_json(SATZ_PATH, satz_data)

    with VOCAB_PATH.open("w", encoding="utf-8", newline="\n") as f:
        writer = csv.DictWriter(f, fieldnames=vocab_fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(vocab_rows)


def print_change_table() -> None:
    print(f"\n=== Per-change table ({len(CHANGE_LOG)} field changes) ===")
    print(f"{'source':<22} {'id':<28} {'field':<12} before -> after")
    for c in CHANGE_LOG:
        before = c["before"].replace("\n", "\\n")
        after = c["after"].replace("\n", "\\n")
        print(f"{c['source']:<22} {c['id']:<28} {c['field']:<12} {before!r} -> {after!r}")


def main() -> int:
    apply_cloze_vocab_satz()
    scenario_dialogs = parse_scenarios52_packet()
    first_line_changed = apply_scenarios(scenario_dialogs)

    print_change_table()

    print("\n=== Summary ===")
    by_source: dict[str, int] = {}
    for c in CHANGE_LOG:
        by_source[c["source"]] = by_source.get(c["source"], 0) + 1
    for source, count in sorted(by_source.items()):
        print(f"  {source}: {count} field changes")
    print(f"  total field changes: {len(CHANGE_LOG)}")
    print(f"\n  scenarios with FIRST dialog line KO change (TTS bundled mp3 now missing):")
    for sid in first_line_changed:
        print(f"    - {sid}")
    if not first_line_changed:
        print("    (none)")

    log_path = REPO_ROOT / "tools" / "content_factory" / "_adjudications_20260915_changelog.json"
    log_path.write_text(
        json.dumps(
            {"changes": CHANGE_LOG, "first_line_ko_changed_scenarios": first_line_changed},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"\nWrote changelog: {log_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
