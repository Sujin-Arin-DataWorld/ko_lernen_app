#!/usr/bin/env python3
"""Naturalness and canon repairs to the pending A2 drafts (Batches 32-34).

Claude re-review, 2026-11-25, before the Jin sample approval. Draft-only:
assets/data/** is untouched.

Batches 32/33 are inputs of build_batch_34_a2_draft.py, so their rows, cloze,
satz, review ledgers, manifests and packets are edited here directly. Batch 34
is fully generated, so only its generator source is edited here (ENTRIES,
manifest note, packet header); run the generator afterwards:

    build_batch_34_a2_draft.py --apply-predecessor-repairs

Why each row changed:
  - 초등학생 / 붙이다 / 떡: the drafts cast 준 as a third-grader (an older
    profile). character_profiles.json now makes him a 16-year-old first-year
    high-school student and forbids primary-school framing. 붙이다/떡 keep
    his exclusive cue 학년 as 1학년; 초등학생 becomes a neutral row.
  - 부장: a workplace superior is 부장님 with -시- (짧게 끝내세요; 짧게 하세요
    would read as the grade-3 causative -게 하다).
  - 관광객: 이 거리에는 + action verb -> 이 거리에서는.
  - 손가락: the old line gave no reason to tell Lena one's fingers are long.
  - 허리: 허리가 아파요 usually means lower-back pain (DE/EN only).
  - 센터: a bare 센터 is vague; 서비스 센터 is the natural compound.
Deliberately unchanged: 자신 (the NIKL grade-2 sense 'oneself' is the
canon-correct A2 sense), 자리 ('우리 크리스티안' is 동선's documented
speech marker), 행복/불안 (…을 느끼다 is natural written Korean), 연결
(switching one's internet connection is idiomatic).

Run:  repair_batches_32_34_naturalness_20261125.py [--check]
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DRAFTS = ROOT / "tools/content_factory/drafts"
REVIEW = ROOT / "tools/content_factory/review"
PACKETS = ROOT / "docs/data/review_packets"
BUILDER = ROOT / "tools/content_factory/build_batch_34_a2_draft.py"
NOTE = ("2026-11-25 Claude naturalness/canon review before Jin sample approval "
        "(repair_batches_32_34_naturalness_20261125.py); IDs, packs, statuses and "
        "gap arithmetic unchanged; MODEL_QA only.")

# Batches 32/33: vocab id -> (row updates, cloze updates)
INPUT_EDITS = {
    32: [
        ("vocab_a2_0570", {
            "german": "Kreuz, unterer Rücken", "english": "lower back, waist",
            "example_german": "Ich habe lange auf dem Stuhl gesessen, deshalb tut mir der Rücken weh.",
            "example_english": "I sat in a chair for a long time, so my lower back hurts.",
        }, {}),
        ("vocab_a2_0571", {
            "example_korean": "레나 씨, 피아노를 오래 쳐서 손가락이 아파요.",
            "example_german": "Lena, ich habe lange Klavier gespielt, jetzt tun mir die Finger weh.",
            "example_english": "Lena, I played the piano for a long time, and now my fingers hurt.",
        }, {"sentenceKo": "레나 씨, 피아노를 오래 쳐서 ＿＿＿ 아파요."}),
        ("vocab_a2_0604", {
            "example_korean": "이 거리에서는 관광객이 사진을 많이 찍어요.",
        }, {"sentenceKo": "이 거리에서는 ＿＿＿ 사진을 많이 찍어요."}),
        ("vocab_a2_0619", {
            "example_korean": "제 동생은 올해 초등학생이 됐어요.",
            "example_german": "Mein jüngeres Geschwisterkind ist dieses Jahr in die Grundschule gekommen.",
            "example_english": "My younger sibling started elementary school this year.",
        }, {"sentenceKo": "제 동생은 올해 ＿＿＿ 됐어요."}),
    ],
    33: [
        ("vocab_a2_0637", {
            "example_korean": "엄마, 나 1학년 교실 벽에 그림 붙였어!",
            "example_german": "Mama, ich habe in unserem Klassenzimmer ein Bild an die Wand geklebt!",
            "example_english": "Mom, I stuck a picture on our classroom wall!",
        }, {"sentenceKo": "엄마, 나 1학년 교실 벽에 그림 ＿＿＿!"}),
        ("vocab_a2_0676", {
            "example_korean": "안드레아 씨, 저희 팀 부장님은 회의를 짧게 끝내세요.",
        }, {"sentenceKo": "안드레아 씨, 저희 팀 ＿＿＿님은 회의를 짧게 끝내세요.",
            "answer": "부장", "distractors": ["편지", "초대장", "대회"]}),
    ],
}

# Batch 34: generator ENTRIES text swaps (old, new).
BUILDER_SWAPS = [
    ("엄마, 오늘 3학년 친구들하고 떡을 나눠 먹었어!", "엄마, 오늘 1학년 친구들하고 떡을 나눠 먹었어!"),
    ("Mama, heute habe ich Reiskuchen mit meinen Freunden aus der dritten Klasse geteilt!",
     "Mama, heute habe ich mit Freunden aus meinem Jahrgang Reiskuchen geteilt!"),
    ("Mom, I shared rice cakes with my third-grade friends today!",
     "Mom, I shared rice cakes with friends from my year today!"),
    ("'센터에 전화해서 수리비를 물어봤어요.'", "'서비스 센터에 전화해서 수리비를 물어봤어요.'"),
    ("exclusive cues 대박 and 3학년.", "exclusive cues 대박 and 학년 (준 = 고등학교 1학년)."),
]
B34_CHANGES = [
    ("떡", "엄마, 오늘 3학년 친구들하고 떡을 나눠 먹었어!", "엄마, 오늘 1학년 친구들하고 떡을 나눠 먹었어!"),
    ("센터", "센터에 전화해서 수리비를 물어봤어요.", "서비스 센터에 전화해서 수리비를 물어봤어요."),
]

# Free-text evidence in the 32/33 packets that names the old framing.
PACKET_TEXT = {
    32: [
        ("청바지·초등학생(준↔크리스티안,", "청바지(준↔크리스티안,"),
        ("3행에서 반말 사용", "2행에서 반말 사용"),
        ("페르소나 화자 10건(≥8)", "페르소나 화자 9건(≥8)"),
        ("마야·다니엘·크리스티안·준 각 1회", "마야·다니엘·크리스티안 각 1회"),
        ("| 초등학생 | `vocab_a2_0619` | 준 | (a) 준 고유 표지('3학년', 준의 배경 '초등학교 3학년 학생'과 일치) |",
         "| 초등학생 | `vocab_a2_0619` | — | 중립 행(2026-11-25: 준은 현 정본상 고등학교 1학년이라 화자 귀속 제거) |"),
    ],
    33: [
        ("(a) 준 고유 표지 '3학년' (배경 '초등학교 3학년 학생'), 엄마에게 반말",
         "(a) 준 고유 표지 '1학년' (배경 '고등학교 1학년 학생'), 엄마에게 반말"),
        ("준=초3", "준=고1"),
        ("(대박=마야, 3학년=준,", "(대박=마야, 1학년=준,"),
    ],
}


def read_csv(path):
    with path.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    return rows, list(rows[0])


def write_csv(path, header, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=header, lineterminator="\n")
        w.writeheader()
        w.writerows(rows)


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def dump(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def revision_block(changes):
    block = ["## R9 개정 (2026-11-25, Claude 자연화·정본 재검수 — 승인 전)", "",
             "| 단어 | 이전 예문 | 이후 예문 |", "|---|---|---|"]
    block += [f"| {w} | {o} | {n} |" for w, o, n in changes]
    block += ["", f"사유는 `tools/content_factory/repair_batches_32_34_naturalness_20261125.py` 독스트링. {NOTE}", ""]
    return block


def edit_inputs(batch, check):
    rows_path = DRAFTS / f"batch_{batch}_a2_rows.csv"
    cloze_path = DRAFTS / f"batch_{batch}_a2_cloze.json"
    satz_path = DRAFTS / f"batch_{batch}_a2_satz.json"
    rows, header = read_csv(rows_path)
    cloze, satz = load(cloze_path), load(satz_path)
    swaps, changes = [], []
    for vid, row_up, cloze_up in INPUT_EDITS[batch]:
        row = next(r for r in rows if r["id"] == vid)
        c = next(i for i in cloze["items"] if i["sourceVocabId"] == vid)
        s = next(i for i in satz["items"] if i["sourceVocabId"] == vid)
        old, old_c = dict(row), dict(c)
        row.update(row_up)
        new_ko = row["example_korean"]
        c.update({"fullKo": new_ko, **cloze_up})
        c.update({k: v for k, v in (("de", row["example_german"]), ("en", row["example_english"])) if k in c})
        assert c["answer"] in new_ko and c["sentenceKo"] == new_ko.replace(c["answer"], "＿＿＿", 1), (vid, c)
        s["targetKo"] = new_ko
        if c["distractors"] != old_c["distractors"]:
            # satz tiles are the first two cloze distractors (batch contract)
            old_tiles, s["distractors"] = s["distractors"], c["distractors"][:2]
            swaps.append((str(old_tiles), str(s["distractors"])))
        s.update({k: v for k, v in (("promptDe", row["example_german"]), ("promptEn", row["example_english"])) if k in s})
        assert not any(d in new_ko.split() for d in s["distractors"]), (vid, s)
        swaps += [
            (old_c["sentenceKo"].replace("＿＿＿", od), c["sentenceKo"].replace("＿＿＿", nd))
            for od, nd in zip(old_c["distractors"], c["distractors"])
        ] + [
            (f"정답 `{old_c['answer']}`", f"정답 `{c['answer']}`") if old_c["answer"] != c["answer"] else ("", ""),
            (str(old_c["distractors"]), str(c["distractors"])),
            (old_c["sentenceKo"], c["sentenceKo"]),
            (old["example_korean"], new_ko),
            (old["example_german"], row["example_german"]),
            (old["example_english"], row["example_english"]),
        ]
        if old["german"] != row["german"]:
            swaps.append((f"| {old['german']} | {old['english']} |", f"| {row['german']} | {row['english']} |"))
        changes.append((row["korean"], old["example_korean"], new_ko))
        if check:
            continue
        for kind, item_id in (("vocab", vid), ("cloze", c["id"]), ("satz", s["id"])):
            lpath = REVIEW / f"batch_{batch}_a2_{kind}_review.csv"
            lrows, lheader = read_csv(lpath)
            lr = next(r for r in lrows if r["id"] == item_id)
            if kind == "vocab":
                lr.update({"de": row["german"], "en": row["english"]})
            else:
                if lr["ko"] == old["example_korean"]:
                    lr["ko"] = new_ko
                lr.update({"de": row["example_german"], "en": row["example_english"]})
                lr["field_notes"] = lr["field_notes"].replace(f"answer={old_c['answer']};", f"answer={c['answer']};")
            write_csv(lpath, lheader, lrows)
    if check:
        return changes
    write_csv(rows_path, header, rows)
    dump(cloze_path, cloze)
    dump(satz_path, satz)
    packet = PACKETS / f"batch_{batch}_a2_jin_sample.md"
    text = packet.read_text(encoding="utf-8")
    for old, new in swaps + PACKET_TEXT[batch]:
        if old and old != new:
            text = text.replace(old, new)
    if "## R9 개정" not in text:
        lines = text.split("\n")
        at = next((i for i, l in enumerate(lines) if l.startswith("## ")), len(lines))
        text = "\n".join(lines[:at] + revision_block(changes) + lines[at:])
    packet.write_text(text, encoding="utf-8", newline="\n")
    manifest_path = DRAFTS / f"batch_{batch}_a2_reinforcement_manifest.json"
    manifest = load(manifest_path)
    manifest["claudeReviewCorrectionNote20261125"] = NOTE + " Rows: " + "; ".join(
        f"{w}: {o} -> {n}" for w, o, n in changes)
    if batch == 32:
        manifest["personaRows"].pop("vocab_a2_0619", None)
    dump(manifest_path, manifest)
    return changes


def edit_builder(check):
    src = BUILDER.read_text(encoding="utf-8")
    for old, new in BUILDER_SWAPS:
        assert old in src or new in src, old
        src = src.replace(old, new)
    note = NOTE + " Rows: " + "; ".join(f"{w}: {o} -> {n}" for w, o, n in B34_CHANGES)
    anchor = '        "reviewPacket": "docs/data/review_packets/batch_34_a2_jin_sample.md",\n'
    if "claudeReviewCorrectionNote20261125" not in src:
        assert anchor in src
        src = src.replace(anchor, f'        "claudeReviewCorrectionNote20261125": {note!r},\n' + anchor)
    packet_anchor = '        "## 이번 예문의 기준", "",\n'
    if "R9 개정" not in src:
        assert packet_anchor in src
        block = ", ".join(repr(l) for l in revision_block(B34_CHANGES))
        src = src.replace(packet_anchor, f"        {block},\n" + packet_anchor)
    if not check:
        BUILDER.write_text(src, encoding="utf-8", newline="\n")
    return B34_CHANGES


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    check = ap.parse_args().check
    for batch in (32, 33):
        for w, o, n in edit_inputs(batch, check):
            print(f"{batch} {w}: {o} -> {n}")
    for w, o, n in edit_builder(check):
        print(f"34 {w}: {o} -> {n}")


if __name__ == "__main__":
    main()
