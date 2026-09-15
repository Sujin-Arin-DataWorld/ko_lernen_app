#!/usr/bin/env python3
"""Build docs/data/review_packets/c2d2_a1_juseyo_jin_sample.md by diffing
the TRUE pre-C2d-2 base commit (1f8416de, before this PR's branch started)
against the current live assets, for every id c2d2_rewrite_data.py has
ever touched across both rounds (round 1: Jin option a, -으세요; round 2:
Jin's authority-vs-request correction, 2026-09-16) plus vocab_a1_0141/
satz_a1_0028 (deleted entirely, not rewritten)."""
import csv
import io
import json
import subprocess
import sys

sys.path.insert(0, "tools/content_factory")
import c2d2_rewrite_data as D  # noqa: E402
import scan_a1_grammar as S  # noqa: E402

BASE_SHA = "1f8416de"


def git_show(path: str) -> str:
    return subprocess.run(
        ["git", "show", f"{BASE_SHA}:{path}"],
        capture_output=True, check=True,
    ).stdout.decode("utf-8")


def base_vocab_by_id() -> dict:
    return {r["id"]: r for r in csv.DictReader(io.StringIO(git_show("assets/data/korean_vocab.csv")))}


def base_cloze_by_id() -> dict:
    return {c["id"]: c for c in json.loads(git_show("assets/data/cloze.json"))["items"]}


def base_satz_by_id() -> dict:
    return {s["id"]: s for s in json.loads(git_show("assets/data/satz_sentences.json"))["items"]}


def live_vocab_by_id() -> dict:
    with open("assets/data/korean_vocab.csv", encoding="utf-8", newline="") as fh:
        return {r["id"]: r for r in csv.DictReader(fh)}


def live_cloze_by_id() -> dict:
    return {c["id"]: c for c in json.loads(open("assets/data/cloze.json", encoding="utf-8").read())["items"]}


def live_satz_by_id() -> dict:
    return {s["id"]: s for s in json.loads(open("assets/data/satz_sentences.json", encoding="utf-8").read())["items"]}


def ko(kind, row):
    if row is None:
        return "(deleted)"
    if kind == "vocab":
        return row["example_korean"]
    if kind == "cloze":
        return row["fullKo"]
    return row["targetKo"]


def de_en(kind, row):
    if row is None:
        return "(deleted)", "(deleted)"
    if kind == "vocab":
        return row["example_german"], row["example_english"]
    if kind == "cloze":
        return row["de"], row["en"]
    return row["promptDe"], row["promptEn"]


def main():
    ids_by_kind = {
        "vocab": sorted(set(D.VOCAB_REWRITES) | {"vocab_a1_0141"}),
        "cloze": sorted(set(D.CLOZE_MIRROR_REWRITES) | set(D.CLOZE_ONLY_REWRITES)),
        "satz": sorted(set(D.SATZ_MIRROR_REWRITES) | set(D.SATZ_ONLY_REWRITES) | {"satz_a1_0028"}),
    }
    base = {"vocab": base_vocab_by_id(), "cloze": base_cloze_by_id(), "satz": base_satz_by_id()}
    live = {"vocab": live_vocab_by_id(), "cloze": live_cloze_by_id(), "satz": live_satz_by_id()}

    rows = []
    for kind, ids in ids_by_kind.items():
        for rid in ids:
            b = base[kind].get(rid)
            l = live[kind].get(rid)
            bko = ko(kind, b)
            lko = ko(kind, l) if l is not None else "(deleted)"
            if bko == lko:
                continue
            rows.append((kind, rid, b, l))
    rows.sort(key=lambda r: (r[0], r[1]))
    sample = rows[0::4]  # ~25%, deterministic

    lines = []
    lines.append("# C2d-2 A1 '-아/어 주세요' Rewrite -- Jin Review Sample (round 2, 2026-09-16)")
    lines.append("")
    lines.append(
        f"Deterministic pick: {len(rows)} rows changed from the TRUE pre-C2d-2 base "
        f"({BASE_SHA}) to the current final state, sorted by (kind, id), every 4th row "
        f"({len(sample)} shown). Combines round 1 (Jin option a: -아/어 주세요 -> 1급 "
        "-으세요/-을 수 있어요?) and round 2 (Jin's authority-vs-request correction: "
        "-으세요 stays only when the speaker has situational authority -- clerk/"
        "teacher/postal instructions; a learner asking a stranger uses -을 수 있어요?/"
        "-을 수 있을까요? or one of exactly 3 closed-list F9 formulas -- 말해 주세요 "
        "(다시/천천히/한번/조금 variants), 도와주세요, 적어 주세요)."
    )
    lines.append("")
    lines.append(
        "vocab_a1_0141 (천 원만 빌려주세요.) is DELETED entirely (Jin: \"아예 쓰지 "
        "말자\", 2026-09-16), with its satz mirror satz_a1_0028 -- not rewritten."
    )
    lines.append("")
    for kind, rid, b, l in sample:
        oko = ko(kind, b)
        ode, oen = de_en(kind, b)
        nko = ko(kind, l) if l is not None else "(deleted)"
        nde, nen = de_en(kind, l) if l is not None else ("(deleted)", "(deleted)")
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
    lines.append(f"전체 {len(rows)}건 변경 (vocab_a1_0141 삭제 포함).")
    lines.append("")
    lines.append("## Headword-embedded grammar (NOT rewritten -- relevel-to-A2 candidates)")
    lines.append("")
    lines.append(
        "적어 주다/도와주다가 헤드워드 자체에 내장된 행은 예문을 그대로 유지하고 "
        "scan_a1_grammar.py의 HEADWORD_EMBEDDED_GRAMMAR에 등록, LCP §F9 재분류 "
        "후보로 표시한다."
    )
    lines.append("")
    lines.append("| kind | id | note |")
    lines.append("|---|---|---|")
    for (kind, rid), note in sorted(S.HEADWORD_EMBEDDED_GRAMMAR.items()):
        if rid in ("vocab_a1_0410", "satz_a1_0317", "vocab_a1_0508", "cloze_a1_0442", "satz_a1_0423"):
            lines.append(f"| {kind} | `{rid}` | {note} |")
    lines.append("")

    out_path = "docs/data/review_packets/c2d2_a1_juseyo_jin_sample.md"
    with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
    print("written:", out_path, "-- sample rows:", len(sample), "total changed:", len(rows))


if __name__ == "__main__":
    main()
