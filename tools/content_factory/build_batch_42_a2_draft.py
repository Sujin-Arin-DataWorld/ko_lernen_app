#!/usr/bin/env python3
"""Build the draft-only C3 Batch 42 A2 review artifacts (14 words).

Scope: the NIKL grade-2 headwords that the Sejong textbook comparison
(2026-11-23) found missing from the app and that the 2026-11-25 Jin
decision ("정본 기준") places at A2: Sejong A1 units teach them, but the
level canon is the NIKL international-standard grade. 바르다 (already live
from Batch 33) and 긴장되다 (긴장 / 긴장하다 already live) were dropped.

Examples, translations and every distractor are authored data below
(Claude, 2026-11-26); IDs, review ledgers, the manifest and the Jin packet
are rendered deterministically. Draft only: assets/data/** is untouched
until Jin approves the sample (level-canon program rule D-4).

Distractor design: each cloze distractor keeps the answer's particle or
ending (same surface contract as Batches 31-34) and is wrong in the
sentence, read with the DE/EN prompt. Satz tiles are the first two cloze
distractors (Batch 33 contract).

Run:  build_batch_42_a2_draft.py [--output-root DIR]
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from rr_romanize import romanize_korean  # noqa: E402

VOCAB_HEADER = [
    "korean", "romanization", "german", "level", "pos_de",
    "example_korean", "example_german", "topic", "pack_id",
    "pack_order", "is_review_boss", "english", "pos_en",
    "example_english", "id",
]
FIRST_VOCAB, FIRST_CLOZE, FIRST_SATZ = 760, 567, 752
NEW_PACK = "a2_daily_4"


def E(word, de, pos_de, en, pos_en, pack, order, boss, topic, ko, de_ex, en_ex, answer, distractors, persona=None):
    return dict(word=word, de=de, pos_de=pos_de, en=en, pos_en=pos_en, pack=pack, order=order,
                boss=boss, topic=topic, ko=ko, de_ex=de_ex, en_ex=en_ex, answer=answer,
                distractors=distractors, persona=persona)


ENTRIES = [
    # a2_work: fills the empty pack_order 1-2 slots (10 -> 12); Boss words already set.
    E("간호사", "Krankenpfleger/in", "Nomen", "nurse", "Noun", "a2_work", 1, False, "Beruf",
      "제 언니는 병원에서 간호사로 일해요.",
      "Meine ältere Schwester arbeitet als Krankenpflegerin im Krankenhaus.",
      "My older sister works as a nurse at a hospital.",
      "간호사로", ["학교로", "바다로", "우유로"]),
    E("선수", "Spieler/in, Sportler/in", "Nomen", "player, athlete", "Noun", "a2_work", 2, False, "Beruf",
      "마야 씨, 제 동생은 축구 선수예요.",
      "Maya, mein jüngerer Bruder ist Fußballspieler.",
      "Maya, my younger brother is a soccer player.",
      "선수예요", ["의자예요", "우유예요", "바다예요"], persona="maya"),
    # a2_weather: fills the empty pack_order 1-2 slots (10 -> 12).
    E("피다", "blühen", "Verb", "to bloom", "Verb", "a2_weather", 1, False, "Wetter",
      "봄이 와서 공원에 꽃이 많이 피었어요.",
      "Der Frühling ist da, und im Park blühen viele Blumen.",
      "Spring has come, and lots of flowers are blooming in the park.",
      "피었어요", ["먹었어요", "읽었어요", "입었어요"]),
    E("파랗다", "blau sein", "Adjektiv", "to be blue", "Adjective", "a2_weather", 2, False, "Wetter",
      "비가 그친 후에 파란 하늘이 보여요.",
      "Nach dem Regen ist ein blauer Himmel zu sehen.",
      "After the rain, you can see a blue sky.",
      "파란", ["짠", "매운", "신"]),
    # a2_daily_4: new pack under the existing a2_daily base (10 words).
    E("꽃집", "Blumenladen", "Nomen", "flower shop", "Noun", NEW_PACK, 1, False, "Alltag",
      "어머니 생신이라서 꽃집에서 꽃을 샀어요.",
      "Zum Geburtstag meiner Mutter habe ich im Blumenladen Blumen gekauft.",
      "For my mother's birthday, I bought flowers at the flower shop.",
      "꽃집에서", ["약국에서", "은행에서", "세탁소에서"]),
    E("시내", "Innenstadt", "Nomen", "downtown, city center", "Noun", NEW_PACK, 2, False, "Alltag",
      "주말에 친구랑 시내에서 영화를 봤어요.",
      "Am Wochenende war ich mit einem Freund in der Innenstadt im Kino.",
      "On the weekend, I watched a movie downtown with a friend.",
      "시내에서", ["부엌에서", "교실에서", "병원에서"]),
    E("닭고기", "Hähnchenfleisch", "Nomen", "chicken (meat)", "Noun", NEW_PACK, 3, False, "Alltag",
      "저는 소고기보다 닭고기를 더 좋아해요.",
      "Ich mag Hähnchen lieber als Rindfleisch.",
      "I like chicken more than beef.",
      "닭고기를", ["우유를", "의자를", "바지를"]),
    E("물티슈", "Feuchttuch", "Nomen", "wet wipe", "Noun", NEW_PACK, 4, False, "Alltag",
      "더러운 손을 물티슈로 닦았어요.",
      "Ich habe meine schmutzigen Hände mit einem Feuchttuch abgewischt.",
      "I wiped my dirty hands with a wet wipe.",
      "물티슈로", ["우유로", "의자로", "주스로"]),
    E("생기다", "entstehen, neu aufmachen", "Verb", "to come into being, to open", "Verb", NEW_PACK, 5, False, "Alltag",
      "회사 근처에 새 카페가 생겼어요.",
      "In der Nähe der Firma hat ein neues Café aufgemacht.",
      "A new café has opened near the office.",
      "생겼어요", ["읽었어요", "먹었어요", "걸었어요"]),
    E("결석하다", "fehlen (im Unterricht)", "Verb", "to be absent", "Verb", NEW_PACK, 6, False, "Alltag",
      "레나 씨, 어제 감기에 걸려서 수업에 결석했어요.",
      "Lena, ich hatte gestern eine Erkältung und habe im Unterricht gefehlt.",
      "Lena, I had a cold yesterday, so I missed class.",
      "결석했어요", ["졸업했어요", "청소했어요", "요리했어요"], persona="lena"),
    E("여쭙다", "(höflich) fragen", "Verb", "to ask (humbly)", "Verb", NEW_PACK, 7, False, "Alltag",
      "모르는 단어를 선생님께 여쭤봤어요.",
      "Ich habe die Lehrerin nach einem unbekannten Wort gefragt.",
      "I asked my teacher about a word I didn't know.",
      "여쭤봤어요", ["입어봤어요", "찾아봤어요", "들어봤어요"]),
    E("더럽다", "schmutzig sein", "Adjektiv", "to be dirty", "Adjective", NEW_PACK, 8, False, "Alltag",
      "옷이 더러워서 빨래를 했어요.",
      "Meine Kleidung war schmutzig, also habe ich Wäsche gewaschen.",
      "My clothes were dirty, so I did the laundry.",
      "더러워서", ["추워서", "더워서", "매워서"]),
    E("확인하다", "überprüfen, nachsehen", "Verb", "to check", "Verb", NEW_PACK, 9, True, "Alltag",
      "수진 씨, 메일을 확인했어요? 회의 시간이 바뀌었어요.",
      "Sujin, haben Sie die E-Mail gesehen? Die Besprechung wurde verlegt.",
      "Sujin, did you check the email? The meeting time has changed.",
      "확인했어요", ["청소했어요", "운동했어요", "요리했어요"], persona="sujin"),
    E("이용하다", "benutzen, nutzen", "Verb", "to use", "Verb", NEW_PACK, 10, True, "Alltag",
      "출퇴근할 때 지하철을 이용해요.",
      "Für den Arbeitsweg nehme ich die U-Bahn.",
      "I take the subway to commute.",
      "이용해요", ["공부해요", "청소해요", "요리해요"]),
]

NOTE = ("Draft only; Jin sample approval pending (level-canon D-4). Examples, translations and "
        "distractors authored by Claude 2026-11-26; MODEL_QA only, no human-language QA claim.")


def write_csv(path: Path, header, rows) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=header, lineterminator="\n")
        w.writeheader()
        w.writerows(rows)


def dump(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def build(output_root: Path) -> None:
    drafts = output_root / "tools/content_factory/drafts"
    review = output_root / "tools/content_factory/review"
    rows, cloze, satz, persona_rows = [], [], [], {}
    for i, e in enumerate(ENTRIES):
        vid, cid, sid = f"vocab_a2_{FIRST_VOCAB + i:04d}", f"cloze_a2_{FIRST_CLOZE + i:04d}", f"satz_a2_{FIRST_SATZ + i:04d}"
        assert e["answer"] in e["ko"], e["word"]
        assert len(e["distractors"]) == 3 and len(set(e["distractors"])) == 3, e["word"]
        rows.append({
            "korean": e["word"], "romanization": romanize_korean(e["word"], pos=e["pos_de"]),
            "german": e["de"], "level": "A2", "pos_de": e["pos_de"],
            "example_korean": e["ko"], "example_german": e["de_ex"], "topic": e["topic"],
            "pack_id": e["pack"], "pack_order": e["order"], "is_review_boss": str(e["boss"]).lower(),
            "english": e["en"], "pos_en": e["pos_en"], "example_english": e["en_ex"], "id": vid,
        })
        cloze.append({
            "id": cid, "sourceVocabId": vid, "fullKo": e["ko"],
            "sentenceKo": e["ko"].replace(e["answer"], "＿＿＿", 1), "answer": e["answer"],
            "distractors": e["distractors"], "de": e["de_ex"], "en": e["en_ex"],
            "level": "a2", "topic": e["topic"],
        })
        satz.append({
            "id": sid, "sourceVocabId": vid, "vocabKo": e["word"], "targetKo": e["ko"],
            "distractors": e["distractors"][:2], "promptDe": e["de_ex"], "promptEn": e["en_ex"], "level": "a2",
        })
        if e["persona"]:
            persona_rows[vid] = e["persona"]
    write_csv(drafts / "batch_42_a2_rows.csv", VOCAB_HEADER, rows)
    dump(drafts / "batch_42_a2_cloze.json", {"items": cloze})
    dump(drafts / "batch_42_a2_satz.json", {"items": satz})

    header = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
    write_csv(review / "batch_42_a2_vocab_review.csv", header, [{
        "id": r["id"], "level": "A2", "ko": r["korean"], "de": r["german"], "en": r["english"],
        "field_notes": (f"rights: original_clean_room; pack={r['pack_id']}; order={r['pack_order']}; "
                        f"boss={r['is_review_boss']}; seed: NIKL 2017 kiiq grade-2 headword (KOGL 1유형) found "
                        "missing by the Sejong comparison; C3 Batch 42 A2 reinforcement"),
        "상태": "pending", "jin_memo": "",
    } for r in rows])
    by_id = {r["id"]: r for r in rows}
    for kind, items in (("cloze", cloze), ("satz", satz)):
        write_csv(review / f"batch_42_a2_{kind}_review.csv", header, [{
            "id": it["id"], "level": "a2", "ko": by_id[it["sourceVocabId"]]["example_korean"],
            "de": by_id[it["sourceVocabId"]]["example_german"], "en": by_id[it["sourceVocabId"]]["example_english"],
            "field_notes": ("rights: original_clean_room; "
                            + (f"answer={it['answer']}; " if kind == "cloze" else f"vocabKo={it['vocabKo']}; ")
                            + f"unit=(assigned at promotion); derived from {it['sourceVocabId']}"),
            "상태": "pending", "jin_memo": "",
        } for it in items])

    manifest = {
        "version": 1,
        "batch": "c3_batch42_a2_reinforcement",
        "status": "draft",
        "provenance": {
            "scope": ("A2(2급) reinforcement - 14 NIKL grade-2 headwords that the Sejong textbook comparison "
                      "found missing; placed at A2 by the 2026-11-25 Jin decision to follow the NIKL canon."),
            "rights": "original_clean_room",
            "seedSource": "Sejong comparison https://claude.ai/artifact/FcNwxgGMW9PJCK31jj2NBd + NIKL 2017 kiiq grades",
            "requiresJinReview": True,
            "approval": {},
            "modelLanguageQa": "CLAUDE_MODEL_QA",
            "humanLanguageQaClaim": False,
            "droppedCandidates": {"바르다": "already live (Batch 33)", "긴장되다": "긴장 / 긴장하다 already live"},
        },
        "artifacts": [
            {"kind": "vocab", "draft": "tools/content_factory/drafts/batch_42_a2_rows.csv", "collection": None,
             "count": len(rows), "level": "A2", "review": "tools/content_factory/review/batch_42_a2_vocab_review.csv"},
            {"kind": "cloze", "draft": "tools/content_factory/drafts/batch_42_a2_cloze.json", "collection": "items",
             "count": len(cloze), "level": "A2", "review": "tools/content_factory/review/batch_42_a2_cloze_review.csv"},
            {"kind": "satz", "draft": "tools/content_factory/drafts/batch_42_a2_satz.json", "collection": "items",
             "count": len(satz), "level": "A2", "review": "tools/content_factory/review/batch_42_a2_satz_review.csv"},
        ],
        "recordCount": 3 * len(rows),
        "packsFilledTo12": [
            {"pack_id": "a2_work", "addedWords": ["간호사", "선수"], "note": "fills empty pack_order 1-2; Boss words unchanged"},
            {"pack_id": "a2_weather", "addedWords": ["피다", "파랗다"], "note": "fills empty pack_order 1-2; Boss words unchanged"},
        ],
        "newPacks": [{"pack_id": NEW_PACK, "displayName": {"de": "Alltag (A2) 4", "en": "Daily Life (A2) 4"},
                      "wordCount": 10, "note": "existing a2_daily base; Boss = final 2 pack_order rows"}],
        "personaRowsNote": "3 rows use a leading vocative (마야, 레나, 수진); no persona appears more than once.",
        "personaRows": persona_rows,
        "reviewPacket": "docs/data/review_packets/batch_42_a2_jin_sample.md",
        "promotion": {"assetsDataWritten": False, "runtime": False, "tts": False, "firebase": False, "note": NOTE},
    }
    dump(drafts / "batch_42_a2_reinforcement_manifest.json", manifest)

    lines = [
        "# C3 Batch 42 A2 Jin review packet", "",
        "상태: **초안 14단어 / 빈칸 14세트 / 문장 조립 14세트** — 승인 전, 앱 데이터(`assets/data/**`) 무수정.", "",
        "## 범위", "",
        "- 세종 교재 대조에서 앱에 없던 단어 중 국립국어원 2급 14개. 2026-11-25 Jin 결정(정본 기준)에 따라 A2에 둔다.",
        "- 뺀 후보: 바르다(배치 33에서 이미 앱에 있음), 긴장되다(긴장·긴장하다가 이미 있음).",
        "- 팩: `a2_work` 비어 있던 1·2번 자리에 간호사·선수, `a2_weather` 1·2번 자리에 피다·파랗다, 새 팩 `a2_daily_4`(기존 a2_daily 계열)에 10단어.",
        "- 오답 보기는 정답의 조사·어미를 그대로 두고, DE/EN 뜻과 함께 읽으면 틀린 것으로 골랐다. 문장 조립 타일은 빈칸 오답 앞의 두 개.", "",
        "판정 3항목: ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가 ③ A2 안인가.", "",
        "## 전체 14행 (배치가 작아 표본 대신 전체를 싣는다)", "",
        "| # | 단어 | 팩 | 예문 | DE | EN | 빈칸 정답 | 오답 보기 |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for i, (r, c) in enumerate(zip(rows, cloze), 1):
        lines.append(f"| {i} | {r['korean']} | `{r['pack_id']}` {r['pack_order']} | {r['example_korean']} | "
                     f"{r['example_german']} | {r['example_english']} | `{c['answer']}` | {', '.join(c['distractors'])} |")
    lines += ["", f"_{NOTE}_", ""]
    packet = output_root / "docs/data/review_packets/batch_42_a2_jin_sample.md"
    packet.parent.mkdir(parents=True, exist_ok=True)
    packet.write_text("\n".join(lines), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output-root", type=Path, default=ROOT)
    build(ap.parse_args().output_root.resolve())
    print("built Batch 42 draft artifacts")
