#!/usr/bin/env python3
"""Build docs/data/review_packets/c2d_a1_grammar_jin_sample.md from
c2d_full_changelog.json (built by hand each round via git show against the
pre-C2d base commit a43c8d0b -- see git history for the exact commands)."""
import json

log = json.load(open("tools/content_factory/c2d_full_changelog.json", encoding="utf-8"))
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
lines.append("# C2d A1 Grammar Rewrite -- Jin 10% Sample")
lines.append("")
lines.append(
    f"Deterministic pick: {len(log_sorted)} rewritten rows (vocab/cloze/satz) "
    "sorted by (kind, id), every 10th row."
)
lines.append(
    "Reflects FINAL text after Fable round 3 (2026-09-15): the 3 remaining "
    "현우 rows fixed (persona canon + embedded grade>=2 grammar the "
    "detector had missed), detector extended for contracted -아/어 보다 / "
    "-아/어 주다 / -는 법 / -는 게. That extension surfaced 38 further rows "
    "(one large '-아/어 주세요' benefactive-request family spanning many "
    "packs) -- reported, NOT rewritten, per the coordinator's >30-hits "
    "stop-and-report threshold; see the scan doc and PR body for the full "
    "list and current status."
)
lines.append("Full list: docs/data/a1_grammar_scan_2026-09-15.md (scan) + PR diff.")
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
lines.append(
    f"전체 {len(log_sorted)}건 변경 요약: vocab 23, cloze 31, satz 25 -- "
    "a1_partner_meet_names_1/table_basic_1/seollal_basic_1 가족팩(인용문+는데"
    "+으면서+을 때+전성어미+aux 등), a1_01_greetings_hangul 인사말 팩(인용 "
    "래퍼 제거), a1_weekend_promise_1/a1_sorry_thanks_1(깨진 사전형 삽입+"
    "문법), 단독 다수."
)
lines.append("")
lines.append("## Round history")
lines.append("")
lines.append(
    "1. **C2d initial (70 rows)**: scan_a1_grammar.py's original detector "
    "(GrammarIndex reuse + explicit 인용 regex) found and fixed 20 vocab + "
    "28 cloze + 22 satz rows."
)
lines.append(
    "2. **Fable R8 (9 sentences)**: greetings-pack completeness "
    "(cloze_a1_0294/0295/0296/0299/0344), headword preservation "
    "(vocab_a1_0341, registered in HEADWORD_EMBEDDED_GRAMMAR), persona "
    "canon (vocab_a1_0253: 현우->수진), tense naturalness (vocab_a1_0252). "
    "Detector gained ATTRIBUTIVE_NOUN_PATTERNS (관형사형+noun, grade 2)."
)
lines.append(
    "3. **Coordinator round 3 (3 rows + detector extension)**: the last 3 "
    "현우 rows fixed (vocab_a1_0218/0220/0261 -> 수진, each also carrying "
    "grade>=2 grammar the detector missed: 물어봤어요/-아 어보다, 는 법, "
    "알려 줬어요/-아 어주다). Detector extended for contracted/batched "
    "-아/어 보다 and -아/어 주다 (expand_contractions only undoes "
    "unbatched vowel fusion, e.g. 봐<-보아, not a batched -았/었- fusion "
    "like 봤/줬) plus -는 법 and -는 게. Re-scan found 38 further rows, "
    "almost all the SAME '-아/어 주세요' benefactive-request pattern "
    "spanning many packs (phone/address exchange, pronunciation repair, "
    "postal requests, borrowing money) -- exceeds the coordinator's "
    "30-hit stop threshold, so these are reported (see PR body) but NOT "
    "rewritten in this PR; tracked as a documented, deliberate exception "
    "list in test_scan_a1_grammar.py pending a rewrite-strategy decision."
)
lines.append("")
lines.append("## Persona-canon grep (report only, not fixed in this PR)")
lines.append("")
lines.append(
    "No further 현우 occurrences remain in the A1 corpus after this round "
    "(all confirmed instances fixed)."
)

out_path = "docs/data/review_packets/c2d_a1_grammar_jin_sample.md"
with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
print("written:", out_path)
