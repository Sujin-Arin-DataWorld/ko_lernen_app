#!/usr/bin/env python3
"""add_b2_environment_pack.py — neues B2-Vokabelpaket "Umwelt" anhängen.

B2 war dünn (nur ~72 Wörter, kein Umwelt/Klima-Thema). Diese 12 Standard-
Umweltbegriffe (KO/DE/EN + Beispielsätze) füllen die Lücke und speisen zugleich
Cloze/Satzbau/Speed-Match/Kkeunmari (deren Generatoren die vocab-CSV lesen).

⚠️ Von Claude verfasst — Jin (Muttersprachler) sollte KO/DE stichprobenartig
prüfen (Projekt-Konvention: generieren → Muttersprachler-Review → commit).

Idempotent: bereits vorhandene koreanische Wörter werden übersprungen.
Nutzung: python3 tools/content_factory/add_b2_environment_pack.py --write
"""
import csv
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
VOCAB = os.path.join(ROOT, "assets", "data", "korean_vocab.csv")

PACK = "b2_environment_1"
TOPIC = "Umwelt"
# (korean, rom, de, pos_de, ex_ko, ex_de, order, boss, en, pos_en, ex_en)
ROWS = [
    ("온난화", "onnanhwa", "Erwärmung", "Nomen",
     "지구 온난화가 심각해요.", "Die globale Erwärmung ist ernst.",
     1, "false", "global warming", "Noun", "Global warming is serious."),
    ("오염", "oyeom", "Verschmutzung", "Nomen",
     "공기 오염이 점점 심해져요.", "Die Luftverschmutzung wird immer schlimmer.",
     2, "false", "pollution", "Noun", "Air pollution is getting worse."),
    ("배출", "baechul", "Ausstoß", "Nomen",
     "탄소 배출을 줄여야 해요.", "Wir müssen den CO2-Ausstoß senken.",
     3, "false", "emission", "Noun", "We must reduce carbon emissions."),
    ("재활용", "jaehwaryong", "Recycling", "Nomen",
     "저는 항상 재활용을 해요.", "Ich recycle immer.",
     4, "false", "recycling", "Noun", "I always recycle."),
    ("멸종", "myeoljong", "Aussterben", "Nomen",
     "많은 동물이 멸종 위기예요.", "Viele Tiere sind vom Aussterben bedroht.",
     5, "false", "extinction", "Noun", "Many animals face extinction."),
    ("생태계", "saengtaegye", "Ökosystem", "Nomen",
     "우리는 생태계를 보호해야 해요.", "Wir müssen das Ökosystem schützen.",
     6, "false", "ecosystem", "Noun", "We must protect the ecosystem."),
    ("자원", "jawon", "Ressource", "Nomen",
     "자원을 아껴 써야 해요.", "Wir müssen sparsam mit Ressourcen umgehen.",
     7, "false", "resource", "Noun", "We must use resources sparingly."),
    ("폐기물", "pyegimul", "Abfall", "Nomen",
     "폐기물을 줄이는 게 중요해요.", "Abfall zu reduzieren ist wichtig.",
     8, "false", "waste", "Noun", "Reducing waste is important."),
    ("태양광", "taeyanggwang", "Solarenergie", "Nomen",
     "태양광 에너지가 늘고 있어요.", "Solarenergie nimmt zu.",
     9, "false", "solar power", "Noun", "Solar energy is increasing."),
    ("온실가스", "onsilgaseu", "Treibhausgas", "Nomen",
     "온실가스가 지구를 데워요.", "Treibhausgase erwärmen die Erde.",
     10, "true", "greenhouse gas", "Noun", "Greenhouse gases warm the earth."),
    ("친환경", "chinhwangyeong", "umweltfreundlich", "Adjektiv",
     "친환경 제품을 자주 사요.", "Ich kaufe oft umweltfreundliche Produkte.",
     11, "true", "eco-friendly", "Adjective", "I often buy eco-friendly products."),
    ("지속 가능성", "jisok ganeungseong", "Nachhaltigkeit", "Nomen",
     "지속 가능성이 아주 중요해요.", "Nachhaltigkeit ist sehr wichtig.",
     12, "true", "sustainability", "Noun", "Sustainability is very important."),
]

HEADER = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english",
]


def main():
    rows = list(csv.DictReader(open(VOCAB, encoding="utf-8")))
    existing = {r["korean"] for r in rows}
    to_add = []
    for (ko, rom, de, posde, exko, exde, order, boss, en, posen, exen) in ROWS:
        if ko in existing:
            print(f"skip (exists): {ko}")
            continue
        assert not any("," in f for f in (ko, de, exko, exde, en, exen)), f"comma in {ko}"
        to_add.append([
            ko, rom, de, "B2", posde, exko, exde, TOPIC, PACK, order, boss,
            en, posen, exen,
        ])
    print(f"neu: {len(to_add)} / {len(ROWS)}  → Paket '{PACK}'")
    for r in to_add:
        print(f"  {r[0]} ({r[9]}{'★' if r[10]=='true' else ''}) — {r[2]} | {r[5]}")

    if "--write" in sys.argv and to_add:
        with open(VOCAB, "a", encoding="utf-8", newline="") as f:
            w = csv.writer(f)
            for r in to_add:
                w.writerow(r)
        print(f"\n✅ {len(to_add)} Zeilen an {VOCAB} angehängt")
    else:
        print("\n(Dry-Run — mit --write anhängen)")


if __name__ == "__main__":
    main()
