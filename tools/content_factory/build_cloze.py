#!/usr/bin/env python3
"""build_cloze.py — Lückentext-Spiel (Cloze) aus VORHANDENEN, muttersprachlich
geprüften Sätzen erzeugen. KEINE neue Übersetzung, KEINE Halluzination (§0).

Quelle: assets/data/korean_vocab.csv — wir nehmen `example_korean` (ein echter
Beispielsatz) und ersetzen das Stichwort (`korean`) durch eine Lücke. Antwort =
das Stichwort. Distraktoren = andere Stichwörter desselben CEFR-Levels (gleiche
Wortart bevorzugt, ähnliche Länge). Übersetzung = `example_german` /
`example_english` (bereits vorhanden, geprüft).

Cloze-im-Kontext schlägt isolierte Karteikarten am Mittelstufen-Plateau
(Forschung), und füllt zugleich unsere dünnen B1/B2-Inhalte mit Aktiv-Abruf.

Nutzung:
    python3 tools/content_factory/build_cloze.py            # Dry-Run (Statistik + Beispiele)
    python3 tools/content_factory/build_cloze.py --write    # nach assets/data/cloze.json schreiben
"""
import csv
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
VOCAB = os.path.join(ROOT, "assets", "data", "korean_vocab.csv")
OUT = os.path.join(ROOT, "assets", "data", "cloze.json")

BLANK = "＿＿＿"  # full-width underscores → liest sich als Lücke
MIN_TOKENS = 2    # Beispielsatz muss ≥2 Eojeol (durch Leerzeichen) haben
MIN_ANSWER_SYLL = 2  # 1-Silben-Antworten (Zahlen/Zähler) sind unfair → raus
NUM_DISTRACTORS = 3

# Erste Silbe gängiger Partikel/Kopula/Endungen NACH einem Nomen. Nur wenn die
# an die Lücke anschließende Silbe hieraus stammt, ist die Lücke ein sauberer
# Nomen-Slot. Sonst (z. B. 해요/역/님/들) würde die Lücke ein Wort zerschneiden
# oder die Antwort verraten → ablehnen. (Review-Findings #1/#2)
PARTICLE_STARTS = set("은는이가을를에의도만와과로으께부까마나든라예였입야여한랑밖처같보뿐죠요세서")


def is_hangul(c):
    return "가" <= c <= "힣"


def syllable_len(s):
    return len([c for c in s if is_hangul(c)])


def is_clean_blank(ex, ko):
    """True, wenn `ko` in `ex` als sauberer (wortgrenzen-respektierender)
    Nomen-Slot ausgeblendet werden kann — kein zerschnittenes Kompositum/Verb."""
    i = ex.find(ko)
    if i < 0:
        return False
    # Zeichen davor muss eine Grenze sein (kein Hangul) → sonst Suffix-Teil.
    if i > 0 and is_hangul(ex[i - 1]):
        return False
    # Rest innerhalb desselben Eojeol (bis zum nächsten Leerzeichen).
    j = i + len(ko)
    tail = ""
    k = j
    while k < len(ex) and ex[k] != " ":
        tail += ex[k]
        k += 1
    if tail and is_hangul(tail[0]) and tail[0] not in PARTICLE_STARTS:
        return False  # z. B. ＿＿＿해요 / ＿＿＿역 / ＿＿＿님 → zerschnitten
    return True


def load_rows():
    with open(VOCAB, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def pick_distractors(answer, level, pos, by_level):
    """3 plausible Distraktoren: gleiches Level, andere Wörter; gleiche Wortart
    und ähnliche Silbenzahl bevorzugt. Deterministisch (sortiert)."""
    target_len = syllable_len(answer)
    pool = [
        r for r in by_level.get(level, [])
        if r["korean"] != answer and r["korean"].strip()
    ]
    # dedup nach koreanischem Wort
    seen = set()
    uniq = []
    for r in pool:
        if r["korean"] in seen:
            continue
        seen.add(r["korean"])
        uniq.append(r)

    def rank(r):
        same_pos = 0 if (pos and r.get("pos_de", "") == pos) else 1
        len_gap = abs(syllable_len(r["korean"]) - target_len)
        return (same_pos, len_gap, r["korean"])

    uniq.sort(key=rank)
    return [r["korean"] for r in uniq[:NUM_DISTRACTORS]]


def build(rows):
    by_level = {}
    for r in rows:
        by_level.setdefault(r["level"], []).append(r)

    items = []
    skipped = {
        "short": 0,
        "no_match": 0,
        "no_translation": 0,
        "few_distractors": 0,
        "single_syll": 0,
        "mid_word": 0,
    }
    for r in rows:
        ko = r["korean"].strip()
        ex = r["example_korean"].strip()
        de = r["example_german"].strip()
        en = r["example_english"].strip()
        level = r["level"].strip()
        pos = r.get("pos_de", "").strip()

        if not ex or ko not in ex:
            skipped["no_match"] += 1
            continue
        if len(ex.split()) < MIN_TOKENS:
            skipped["short"] += 1
            continue
        if not de:
            skipped["no_translation"] += 1
            continue
        # 1-Silben-Antworten (Zahlen/Zähler 일/사/시…) → unfair (Lücke ＿＿＿
        # signalisiert 3 Zeichen, Übersetzung verrät die Antwort).
        if syllable_len(ko) < MIN_ANSWER_SYLL:
            skipped["single_syll"] += 1
            continue
        # Wortgrenzen-Check → kein zerschnittenes Kompositum/Verb.
        if not is_clean_blank(ex, ko):
            skipped["mid_word"] += 1
            continue

        blanked = ex.replace(ko, BLANK, 1)
        # Lücke muss echten Restkontext lassen (nicht nur "＿＿＿!")
        if len(blanked.replace(BLANK, "").strip(" !?.,…~")) < 2:
            skipped["short"] += 1
            continue

        distractors = pick_distractors(ko, level, pos, by_level)
        if len(distractors) < NUM_DISTRACTORS:
            skipped["few_distractors"] += 1
            continue

        items.append({
            "level": level.lower(),
            "sentenceKo": blanked,
            "answer": ko,
            "fullKo": ex,
            "de": de,
            "en": en,
            "distractors": distractors,
            "topic": r.get("topic", "").strip(),
        })

    return items, skipped


def main():
    rows = load_rows()
    items, skipped = build(rows)
    by_level = {}
    for it in items:
        by_level[it["level"]] = by_level.get(it["level"], 0) + 1

    print(f"Quelle: {len(rows)} Vokabeln")
    print(f"Cloze erzeugt: {len(items)}")
    print(f"  pro Level: {dict(sorted(by_level.items()))}")
    print(f"  übersprungen: {skipped}")
    print("\nBeispiele:")
    for it in items[:10]:
        print(f"  [{it['level']}] {it['sentenceKo']}  → {it['answer']}  "
              f"(Dist: {it['distractors']})  | {it['de']}")

    if "--write" in sys.argv:
        payload = {
            "meta": {
                "total": len(items),
                "perLevel": dict(sorted(by_level.items())),
                "source": "korean_vocab.csv example sentences (native-reviewed)",
                "note": "Generated by build_cloze.py — blank = headword in its own example sentence. No new translation (§0).",
            },
            "items": items,
        }
        with open(OUT, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=1)
        print(f"\n✅ geschrieben: {OUT} ({len(items)} Items)")
    else:
        print("\n(Dry-Run — mit --write speichern)")


if __name__ == "__main__":
    main()
