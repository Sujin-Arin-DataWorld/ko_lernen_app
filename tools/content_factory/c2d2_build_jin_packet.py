#!/usr/bin/env python3
"""Build docs/data/review_packets/c2d2_a1_juseyo_jin_sample.md from
tools/content_factory/c2d2_change_log.json (written by c2d2_apply_rewrite.py
--write). Deterministic 10% sample (every 10th row, sorted by kind,id) plus
the full headword-embedded relevel-candidate list."""
import json
import sys

sys.path.insert(0, "tools/content_factory")
import scan_a1_grammar as S  # noqa: E402

log = json.load(open("tools/content_factory/c2d2_change_log.json", encoding="utf-8"))
log_sorted = sorted(log, key=lambda c: (c["kind"], c["id"]))
sample = log_sorted[0::10]


def ko_de_en(kind, row):
    if kind == "vocab":
        return row["example_korean"], row["example_german"], row["example_english"]
    if kind == "cloze":
        return row["fullKo"], row["de"], row["en"]
    if kind == "satz":
        return row["targetKo"], row["promptDe"], row["promptEn"]


lines = []
lines.append("# C2d-2 A1 '-아/어 주세요' -> '-으세요' Rewrite -- Jin 10% Sample")
lines.append("")
lines.append(
    f"Deterministic pick: {len(log_sorted)} rewritten rows (vocab/cloze/satz) "
    "sorted by (kind, id), every 10th row. Jin's 2026-09-16 ruling (option "
    "a): rewrite the '-아/어 주세요' benefactive-request family with 1급 "
    "-으세요 (honorific imperative), or a softened first-person '-을 수 "
    "있어요?' question where a bare imperative loses too much without the "
    "benefactive nuance ('lend me'/'show me'/'let me hear'/'tell me' -- no "
    "clean -(으)세요 form exists once -아/어 주다 is removed). Noun + "
    "lexical 주다 ('물 주세요') is out of scope (주다 is itself a 1급 main "
    "verb); none of these rows are that shape."
)
lines.append("")
lines.append(
    f"Scope: the 38 DOCUMENTED_EXCEPTIONS rows C2d (PR #339) deferred, plus "
    "vocab_a1_0402 (+ its 2 mirrors cloze_a1_0290/satz_a1_0254, found by "
    f"exact-text match) = 41 rows total ({len(log_sorted)} actually changed "
    "-- vocab_a1_0410 excluded, see below)."
)
lines.append("")
for c in sample:
    kind, rid = c["kind"], c["id"]
    oko, ode, oen = ko_de_en(kind, c["before"])
    nko, nde, nen = ko_de_en(kind, c["after"])
    lines.append(f"## {kind}:{rid}")
    lines.append("")
    lines.append(f"- **Before KO:** {oko}")
    lines.append(f"- **Before DE:** {ode}")
    lines.append(f"- **Before EN:** {oen}")
    lines.append(f"- **After KO:** {nko}")
    lines.append(f"- **After DE:** {nde}")
    lines.append(f"- **After EN:** {nen}")
    lines.append("")
    lines.append("Jin 판정: ______")
    lines.append("")

lines.append("---")
lines.append("")
by_kind = {}
for c in log_sorted:
    by_kind.setdefault(c["kind"], 0)
    by_kind[c["kind"]] += 1
lines.append(
    f"전체 {len(log_sorted)}건 변경: vocab {by_kind.get('vocab', 0)}, "
    f"cloze {by_kind.get('cloze', 0)}, satz {by_kind.get('satz', 0)} -- "
    "phone/address exchange (a1_first_class_1), pronunciation repair "
    "(a1_repair_language_1), postal requests (a1_post_office_1), "
    "borrowing money (a1_numbers_2), waiting (a1_time_3), speaking slowly "
    "(a1_daily_4), mother-in-law smiling (a1_partner_meet_names_1), "
    "answering a question (a1_repair_language_1, b1-id/a1-level row), "
    "giving up a seat (a1_sorry_thanks_1), plus several standalone cloze/"
    "satz rows with no vocab source."
)
lines.append("")
lines.append("## Headword-embedded grammar (NOT rewritten -- relevel-to-A2 candidates)")
lines.append("")
lines.append(
    "These headwords themselves are a lexicalized -아/어 주다 compound "
    "(적어 주다, 도와주다), so no example sentence can bring them inside "
    "the 45-item 1급 table without dropping the headword. Kept verbatim, "
    "registered in scan_a1_grammar.py's HEADWORD_EMBEDDED_GRAMMAR, flagged "
    "here for a future relevel decision (LCP §F9), same treatment as C2d's "
    "own vocab_a1_0341 precedent."
)
lines.append("")
lines.append("| kind | id | headword | example (unchanged) | embedded item |")
lines.append("|---|---|---|---|---|")
for (kind, rid), note in sorted(S.HEADWORD_EMBEDDED_GRAMMAR.items()):
    if "C2d-2" not in note and rid not in ("vocab_a1_0410", "satz_a1_0317", "vocab_a1_0508", "cloze_a1_0442", "satz_a1_0423"):
        continue
    lines.append(f"| {kind} | `{rid}` | | | {note} |")
lines.append("")

out_path = "docs/data/review_packets/c2d2_a1_juseyo_jin_sample.md"
with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
print("written:", out_path, "-- sample rows:", len(sample), "total changed:", len(log_sorted))
