#!/usr/bin/env python3
"""Build the original word-web seed for Hangul Sori.

Language facts (synonym / antonym pairs) plus independently written DE/EN/KO
examples. Does not copy textbook sentences or pack order.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "assets" / "data" / "korean_vocab.csv"
OUT = ROOT / "assets" / "data" / "word_relations.json"


def load_vocab() -> dict[str, dict[str, str]]:
    by_id: dict[str, dict[str, str]] = {}
    with VOCAB.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            by_id[row["id"]] = row
    return by_id


def neighbor(
    ko: str,
    de: str,
    en: str,
    nuance_de: str = "",
    nuance_en: str = "",
    vocab_id: str = "",
) -> dict[str, str]:
    return {
        "ko": ko,
        "de": de,
        "en": en,
        "nuanceDe": nuance_de,
        "nuanceEn": nuance_en,
        "vocabId": vocab_id,
    }


def expression(
    ko: str,
    de: str,
    en: str,
    example_ko: str,
    example_de: str,
    example_en: str,
) -> dict[str, str]:
    return {
        "ko": ko,
        "de": de,
        "en": en,
        "exampleKo": example_ko,
        "exampleDe": example_de,
        "exampleEn": example_en,
    }


def cluster(
    cid: str,
    source_id: str,
    vocab: dict[str, dict[str, str]],
    *,
    synonyms: list[dict[str, str]] | None = None,
    antonyms: list[dict[str, str]] | None = None,
    related: list[dict[str, str]] | None = None,
    expressions: list[dict[str, str]] | None = None,
) -> dict[str, object]:
    row = vocab[source_id]
    return {
        "id": cid,
        "sourceKo": row["korean"],
        "sourceVocabId": source_id,
        "level": row["level"],
        "synonyms": synonyms or [],
        "antonyms": antonyms or [],
        "related": related or [],
        "expressions": expressions or [],
    }


def build(vocab: dict[str, dict[str, str]]) -> list[dict[str, object]]:
    return [
        cluster(
            "rel_a1_0001",
            "vocab_a1_0001",
            vocab,
            synonyms=[
                neighbor(
                    "안녕",
                    "Hallo / Tschüss (informell)",
                    "Hi / Bye (informal)",
                    "Nur mit Freundinnen und Freunden. Zu Lehrerinnen oder Älteren wirkt es zu locker.",
                    "Only with friends. With teachers or older people it sounds too casual.",
                    "vocab_a1_0002",
                )
            ],
            related=[
                neighbor(
                    "안녕히 가세요",
                    "Auf Wiedersehen (zum Gehenden)",
                    "Goodbye (to the person leaving)",
                    "Du sagst es, wenn die andere Person geht.",
                    "You say this when the other person is leaving.",
                    "vocab_a1_0165",
                ),
                neighbor(
                    "처음 뵙겠습니다",
                    "Freut mich, Sie kennenzulernen",
                    "Nice to meet you (formal)",
                    "Passt zur ersten Begegnung, oft direkt nach der Begrüßung.",
                    "Fits a first meeting, often right after the greeting.",
                    "vocab_a1_0169",
                ),
            ],
            expressions=[
                expression(
                    "안녕하세요, 처음 뵙겠습니다",
                    "Guten Tag, schön Sie kennenzulernen",
                    "Hello, nice to meet you",
                    "안녕하세요, 처음 뵙겠습니다. 저는 수진이에요.",
                    "Guten Tag, schön Sie kennenzulernen. Ich bin Sujin.",
                    "Hello, nice to meet you. I'm Sujin.",
                )
            ],
        ),
        cluster(
            "rel_a1_0002",
            "vocab_a1_0003",
            vocab,
            synonyms=[
                neighbor(
                    "고마워요",
                    "Danke (höflich-informell)",
                    "Thank you (polite informal)",
                    "Alltag mit Bekannten. In einem Geschäft oder vor Älteren bleibt 감사합니다 sicherer.",
                    "Everyday thanks with people you know. In a shop or with older people, 감사합니다 is safer.",
                    "vocab_a1_0004",
                )
            ],
            related=[
                neighbor(
                    "천만에요",
                    "Gern geschehen",
                    "You're welcome",
                    "Antwort auf Dank. Etwas förmlicher als ein kurzes 아니에요.",
                    "A reply to thanks. A bit more formal than a short 아니에요.",
                    "vocab_a1_0172",
                )
            ],
            expressions=[
                expression(
                    "도와주셔서 감사합니다",
                    "Vielen Dank für Ihre Hilfe",
                    "Thank you for your help",
                    "길을 알려 주셔서 감사합니다.",
                    "Danke, dass Sie mir den Weg erklärt haben.",
                    "Thank you for showing me the way.",
                )
            ],
        ),
        cluster(
            "rel_a1_0003",
            "vocab_a1_0005",
            vocab,
            synonyms=[
                neighbor(
                    "미안해요",
                    "Es tut mir leid",
                    "I'm sorry",
                    "Für Freunde und Alltag. Vor Unbekannten oder in einem Laden bleibt 죄송합니다 höflicher.",
                    "For friends and everyday talk. With strangers or in a shop, 죄송합니다 stays more polite.",
                    "vocab_a1_0006",
                )
            ],
            related=[
                neighbor(
                    "실례합니다",
                    "Entschuldigen Sie",
                    "Excuse me",
                    "Bevor du fragst oder vorbeigehst, nicht nach einem Fehler.",
                    "Before you ask or pass by, not after a mistake.",
                    "vocab_a1_0174",
                )
            ],
            expressions=[
                expression(
                    "늦어서 죄송합니다",
                    "Entschuldigung, dass ich zu spät bin",
                    "Sorry I'm late",
                    "버스가 막혀서 늦었습니다. 죄송합니다.",
                    "Der Bus steckte fest, deshalb komme ich zu spät. Entschuldigung.",
                    "The bus was stuck, so I'm late. I'm sorry.",
                )
            ],
        ),
        cluster(
            "rel_a1_0004",
            "vocab_a1_0007",
            vocab,
            synonyms=[
                neighbor(
                    "괜찮다",
                    "in Ordnung sein",
                    "to be okay",
                    "Die Grundform. 괜찮아요 ist die höfliche Alltagform.",
                    "The dictionary form. 괜찮아요 is the polite everyday form.",
                )
            ],
            related=[
                neighbor(
                    "걱정하다",
                    "sich Sorgen machen",
                    "to worry",
                    "Oft in der Beruhigung: 걱정 마세요.",
                    "Often in reassurance: 걱정 마세요.",
                )
            ],
            expressions=[
                expression(
                    "괜찮아요, 걱정 마세요",
                    "Schon gut, mach dir keine Sorgen",
                    "It's okay, don't worry",
                    "가방을 떨어뜨렸지만 괜찮아요. 걱정 마세요.",
                    "Die Tasche ist gefallen, aber es ist okay. Mach dir keine Sorgen.",
                    "The bag fell, but it's okay. Don't worry.",
                )
            ],
        ),
        cluster(
            "rel_a1_0005",
            "vocab_a1_0008",
            vocab,
            antonyms=[
                neighbor(
                    "아니요",
                    "Nein",
                    "No",
                    "Klare Absage. 네 bestätigt, 아니요 lehnt ab.",
                    "A clear no. 네 agrees, 아니요 refuses.",
                    "vocab_a1_0009",
                )
            ],
            related=[
                neighbor(
                    "알겠어요",
                    "Verstanden",
                    "I see / Got it",
                    "Nach einer Erklärung, nicht als Ja/Nein-Antwort.",
                    "After an explanation, not as a yes/no answer.",
                )
            ],
            expressions=[
                expression(
                    "네, 맞아요",
                    "Ja, genau",
                    "Yes, that's right",
                    "이게 네 가방이에요? 네, 맞아요.",
                    "Ist das deine Tasche? Ja, genau.",
                    "Is this your bag? Yes, that's right.",
                )
            ],
        ),
        cluster(
            "rel_a1_0006",
            "vocab_a1_0032",
            vocab,
            synonyms=[
                neighbor(
                    "아빠",
                    "Papa",
                    "dad",
                    "Zuhause und mit der Familie. In der Schule oder auf Formularen bleibt 아버지.",
                    "At home and with family. At school or on forms, keep 아버지.",
                    "vocab_a1_0034",
                )
            ],
            related=[
                neighbor(
                    "어머니",
                    "Mutter (formell)",
                    "mother (formal)",
                    "Das formelle Paar zu 아버지.",
                    "The formal pair with 아버지.",
                    "vocab_a1_0033",
                ),
                neighbor(
                    "가족",
                    "Familie",
                    "family",
                    "Der größere Kreis um Vater und Mutter.",
                    "The wider circle around father and mother.",
                    "vocab_a1_0018",
                ),
            ],
            expressions=[
                expression(
                    "우리 아버지",
                    "mein Vater / unser Vater",
                    "my father / our father",
                    "우리 아버지는 주말에 요리해요.",
                    "Mein Vater kocht am Wochenende.",
                    "My father cooks on the weekend.",
                )
            ],
        ),
        cluster(
            "rel_a1_0007",
            "vocab_a1_0033",
            vocab,
            synonyms=[
                neighbor(
                    "엄마",
                    "Mama",
                    "mom",
                    "Warm und nah. Vor Lehrerinnen oder in einer Vorstellung bleibt 어머니 höflicher.",
                    "Warm and close. With teachers or in an introduction, 어머니 is more polite.",
                    "vocab_a1_0035",
                )
            ],
            related=[
                neighbor(
                    "아버지",
                    "Vater (formell)",
                    "father (formal)",
                    "Das formelle Paar zu 어머니.",
                    "The formal pair with 어머니.",
                    "vocab_a1_0032",
                )
            ],
            expressions=[
                expression(
                    "어머니께 전화하다",
                    "die Mutter anrufen",
                    "to call one's mother",
                    "저녁에 어머니께 전화할게요.",
                    "Am Abend rufe ich meine Mutter an.",
                    "I'll call my mother in the evening.",
                )
            ],
        ),
        cluster(
            "rel_a1_0008",
            "vocab_a1_0036",
            vocab,
            related=[
                neighbor(
                    "오빠",
                    "älterer Bruder (Sicht der Frau)",
                    "older brother (said by a woman)",
                    "Dieselbe Person, aber aus der Sicht einer jüngeren Frau.",
                    "The same person, but from a younger woman's point of view.",
                    "vocab_a1_0037",
                ),
                neighbor(
                    "누나",
                    "ältere Schwester (Sicht des Mannes)",
                    "older sister (said by a man)",
                    "Das Schwesterwort aus männlicher Sicht.",
                    "The sister word from a man's point of view.",
                    "vocab_a1_0038",
                ),
                neighbor(
                    "언니",
                    "ältere Schwester (Sicht der Frau)",
                    "older sister (said by a woman)",
                    "Das Schwesterwort aus weiblicher Sicht.",
                    "The sister word from a woman's point of view.",
                    "vocab_a1_0039",
                ),
            ],
            expressions=[
                expression(
                    "형한테 묻다",
                    "den älteren Bruder fragen",
                    "to ask one's older brother",
                    "이 길을 몰라서 형한테 물어볼게요.",
                    "Ich kenne den Weg nicht, deshalb frage ich meinen älteren Bruder.",
                    "I don't know this road, so I'll ask my older brother.",
                )
            ],
        ),
        cluster(
            "rel_a1_0009",
            "vocab_a1_0015",
            vocab,
            related=[
                neighbor(
                    "남자친구",
                    "Freund (Beziehung)",
                    "boyfriend",
                    "Nur die romantische Beziehung, nicht jeder männliche Freund.",
                    "Only a romantic partner, not every male friend.",
                    "vocab_a1_0016",
                ),
                neighbor(
                    "여자친구",
                    "Freundin (Beziehung)",
                    "girlfriend",
                    "Nur die romantische Beziehung, nicht jede Freundin.",
                    "Only a romantic partner, not every female friend.",
                    "vocab_a1_0017",
                ),
            ],
            expressions=[
                expression(
                    "친구랑 만나다",
                    "sich mit einem Freund treffen",
                    "to meet a friend",
                    "오늘 저녁에 친구랑 만나요.",
                    "Heute Abend treffe ich mich mit einem Freund.",
                    "I'm meeting a friend this evening.",
                )
            ],
        ),
        cluster(
            "rel_a1_0010",
            "vocab_a1_0116",
            vocab,
            synonyms=[
                neighbor(
                    "커다랗다",
                    "sehr groß / riesig",
                    "very large / huge",
                    "Stärker als 크다. Für etwas, das deutlich größer wirkt.",
                    "Stronger than 크다. For something that looks clearly huge.",
                )
            ],
            antonyms=[
                neighbor(
                    "작다",
                    "klein",
                    "small",
                    "Das direkte Gegenteil bei Größe.",
                    "The direct opposite for size.",
                    "vocab_a1_0117",
                )
            ],
            related=[
                neighbor(
                    "사이즈",
                    "Größe",
                    "size",
                    "Beim Kleidung- oder Schuhkauf.",
                    "When buying clothes or shoes.",
                    "vocab_a2_0097",
                )
            ],
            expressions=[
                expression(
                    "큰일 나다",
                    "in große Schwierigkeiten geraten",
                    "to get into big trouble",
                    "열쇠를 집에 두고 와서 큰일 났어요.",
                    "Ich habe den Schlüssel zu Hause gelassen. Jetzt sitze ich in der Patsche.",
                    "I left my keys at home. Now I'm in big trouble.",
                )
            ],
        ),
        cluster(
            "rel_a1_0011",
            "vocab_a1_0117",
            vocab,
            synonyms=[
                neighbor(
                    "조그맣다",
                    "winzig / sehr klein",
                    "tiny / very small",
                    "Kleiner und niedlicher als 작다.",
                    "Smaller and cuter than 작다.",
                )
            ],
            antonyms=[
                neighbor(
                    "크다",
                    "groß",
                    "big",
                    "Das direkte Gegenteil bei Größe.",
                    "The direct opposite for size.",
                    "vocab_a1_0116",
                )
            ],
            related=[
                neighbor(
                    "조금",
                    "ein bisschen",
                    "a little",
                    "Menge, nicht Körpergröße.",
                    "Amount, not physical size.",
                    "vocab_a2_0082",
                )
            ],
            expressions=[
                expression(
                    "작은 가게",
                    "ein kleiner Laden",
                    "a small shop",
                    "집 앞에 작은 가게가 있어요.",
                    "Vor dem Haus gibt es einen kleinen Laden.",
                    "There is a small shop in front of the house.",
                )
            ],
        ),
        cluster(
            "rel_a1_0012",
            "vocab_a1_0115",
            vocab,
            synonyms=[
                neighbor(
                    "괜찮다",
                    "in Ordnung / ganz gut",
                    "okay / quite good",
                    "Schwächer als 좋다. Etwas ist akzeptabel, nicht begeistert.",
                    "Weaker than 좋다. Something is acceptable, not exciting.",
                )
            ],
            antonyms=[
                neighbor(
                    "싫다",
                    "nicht mögen / unangenehm finden",
                    "to dislike / to find unpleasant",
                    "Gefühl gegen etwas. 좋다 mag, 싫다 lehnt ab.",
                    "A feeling against something. 좋다 likes, 싫다 rejects.",
                )
            ],
            related=[
                neighbor(
                    "좋아하다",
                    "mögen",
                    "to like",
                    "Die aktive Form: jemand mag etwas.",
                    "The active form: someone likes something.",
                    "vocab_a1_0099",
                )
            ],
            expressions=[
                expression(
                    "좋은 생각이에요",
                    "Das ist eine gute Idee",
                    "That's a good idea",
                    "같이 걸어서 가요. 좋은 생각이에요.",
                    "Lass uns zu Fuß gehen. Das ist eine gute Idee.",
                    "Let's walk there. That's a good idea.",
                )
            ],
        ),
        cluster(
            "rel_a1_0013",
            "vocab_a1_0119",
            vocab,
            antonyms=[
                neighbor(
                    "싸다",
                    "günstig / billig",
                    "cheap / inexpensive",
                    "Der Preisgegensatz zu 비싸다.",
                    "The price opposite of 비싸다.",
                    "vocab_a1_0120",
                )
            ],
            related=[
                neighbor(
                    "돈",
                    "Geld",
                    "money",
                    "Der Grund, warum der Preis zählt.",
                    "The reason the price matters.",
                )
            ],
            expressions=[
                expression(
                    "너무 비싸요",
                    "Das ist zu teuer",
                    "That's too expensive",
                    "이 코트는 예쁜데 너무 비싸요.",
                    "Dieser Mantel ist schön, aber zu teuer.",
                    "This coat is pretty, but it's too expensive.",
                )
            ],
        ),
        cluster(
            "rel_a1_0014",
            "vocab_a1_0120",
            vocab,
            synonyms=[
                neighbor(
                    "저렴하다",
                    "preiswert",
                    "inexpensive / reasonably priced",
                    "Höflicher als 싸다. In Läden klingt es weniger nach billig.",
                    "More polite than 싸다. In shops it sounds less like cheap.",
                )
            ],
            antonyms=[
                neighbor(
                    "비싸다",
                    "teuer",
                    "expensive",
                    "Der Preisgegensatz zu 싸다.",
                    "The price opposite of 싸다.",
                    "vocab_a1_0119",
                )
            ],
            related=[
                neighbor(
                    "할인",
                    "Rabatt",
                    "discount",
                    "Wenn etwas günstiger wird.",
                    "When something becomes cheaper.",
                )
            ],
            expressions=[
                expression(
                    "싸게 사다",
                    "günstig kaufen",
                    "to buy something cheaply",
                    "시장에서 과일을 싸게 샀어요.",
                    "Auf dem Markt habe ich Obst günstig gekauft.",
                    "I bought fruit cheaply at the market.",
                )
            ],
        ),
        cluster(
            "rel_a1_0015",
            "vocab_a1_0121",
            vocab,
            antonyms=[
                neighbor(
                    "맛없다",
                    "nicht lecker sein",
                    "to taste bad",
                    "Das direkte Gegenteil beim Essen.",
                    "The direct opposite for food.",
                    "vocab_a1_0209",
                )
            ],
            related=[
                neighbor(
                    "먹다",
                    "essen",
                    "to eat",
                    "Die Handlung zum Geschmack.",
                    "The action that goes with taste.",
                    "vocab_a1_0089",
                )
            ],
            expressions=[
                expression(
                    "정말 맛있어요",
                    "Das schmeckt wirklich gut",
                    "This is really delicious",
                    "이 김치찌개 정말 맛있어요.",
                    "Dieses Kimchi-Jjigae schmeckt wirklich gut.",
                    "This kimchi stew is really delicious.",
                )
            ],
        ),
        cluster(
            "rel_a1_0016",
            "vocab_a1_0123",
            vocab,
            antonyms=[
                neighbor(
                    "시끄럽다",
                    "laut / lärmend",
                    "loud / noisy",
                    "Das Gegenteil von ruhig.",
                    "The opposite of quiet.",
                    "vocab_a1_0124",
                )
            ],
            related=[
                neighbor(
                    "도서관",
                    "Bibliothek",
                    "library",
                    "Ein Ort, an dem 조용하다 erwartet wird.",
                    "A place where 조용하다 is expected.",
                )
            ],
            expressions=[
                expression(
                    "좀 조용히 해 주세요",
                    "Bitte sei etwas leiser",
                    "Please keep it down a bit",
                    "도서관이니까 좀 조용히 해 주세요.",
                    "Wir sind in der Bibliothek, bitte sei etwas leiser.",
                    "We're in the library, so please keep it down a bit.",
                )
            ],
        ),
        cluster(
            "rel_a1_0017",
            "vocab_a1_0124",
            vocab,
            antonyms=[
                neighbor(
                    "조용하다",
                    "leise / ruhig",
                    "quiet",
                    "Das Gegenteil von laut.",
                    "The opposite of loud.",
                    "vocab_a1_0123",
                )
            ],
            related=[
                neighbor(
                    "소리",
                    "Geräusch / Stimme",
                    "sound / voice",
                    "Was laut oder leise sein kann.",
                    "What can be loud or quiet.",
                )
            ],
            expressions=[
                expression(
                    "밖이 너무 시끄러워요",
                    "Draußen ist es zu laut",
                    "It's too noisy outside",
                    "창문을 열면 밖이 너무 시끄러워요.",
                    "Wenn ich das Fenster öffne, ist es draußen zu laut.",
                    "If I open the window, it's too noisy outside.",
                )
            ],
        ),
        cluster(
            "rel_a1_0018",
            "vocab_a1_0125",
            vocab,
            antonyms=[
                neighbor(
                    "쉽다",
                    "einfach / leicht",
                    "easy",
                    "Das Gegenteil von schwierig.",
                    "The opposite of difficult.",
                    "vocab_a1_0126",
                )
            ],
            related=[
                neighbor(
                    "공부하다",
                    "lernen / studieren",
                    "to study",
                    "Was oft schwierig oder leicht wirkt.",
                    "What often feels hard or easy.",
                    "vocab_a2_0039",
                )
            ],
            expressions=[
                expression(
                    "한국어가 어려워요",
                    "Koreanisch ist schwierig",
                    "Korean is difficult",
                    "처음에는 한국어가 어려워요. 그래도 매일 조금 해요.",
                    "Am Anfang ist Koreanisch schwierig. Trotzdem mache ich jeden Tag ein bisschen.",
                    "At first Korean is difficult. Still, I do a little every day.",
                )
            ],
        ),
        cluster(
            "rel_a1_0019",
            "vocab_a1_0126",
            vocab,
            synonyms=[
                neighbor(
                    "간단하다",
                    "einfach / unkompliziert",
                    "simple / straightforward",
                    "Betont Klarheit, nicht nur fehlende Schwierigkeit.",
                    "Stresses clarity, not just a lack of difficulty.",
                )
            ],
            antonyms=[
                neighbor(
                    "어렵다",
                    "schwierig",
                    "difficult",
                    "Das Gegenteil von leicht.",
                    "The opposite of easy.",
                    "vocab_a1_0125",
                )
            ],
            related=[
                neighbor(
                    "이해하다",
                    "verstehen",
                    "to understand",
                    "Wenn etwas leicht ist, versteht man es schneller.",
                    "When something is easy, you understand it faster.",
                    "vocab_a2_0047",
                )
            ],
            expressions=[
                expression(
                    "이 문제는 쉬워요",
                    "Diese Aufgabe ist leicht",
                    "This question is easy",
                    "첫 문제는 쉬워요. 천천히 읽어 보세요.",
                    "Die erste Aufgabe ist leicht. Lies sie langsam.",
                    "The first question is easy. Read it slowly.",
                )
            ],
        ),
        cluster(
            "rel_a1_0020",
            "vocab_a1_0128",
            vocab,
            antonyms=[
                neighbor(
                    "짧다",
                    "kurz",
                    "short",
                    "Gegenteil bei Zeit, Haar oder Weg.",
                    "Opposite for time, hair, or a path.",
                    "vocab_a1_0129",
                )
            ],
            related=[
                neighbor(
                    "시간",
                    "Zeit",
                    "time",
                    "Ein langes Video oder eine lange Wartezeit.",
                    "A long video or a long wait.",
                )
            ],
            expressions=[
                expression(
                    "머리가 길어요",
                    "Die Haare sind lang",
                    "The hair is long",
                    "요즘 머리를 안 잘라서 머리가 길어요.",
                    "Ich habe mir die Haare lange nicht schneiden lassen, deshalb sind sie lang.",
                    "I haven't cut my hair lately, so it's long.",
                )
            ],
        ),
        cluster(
            "rel_a1_0021",
            "vocab_a1_0129",
            vocab,
            antonyms=[
                neighbor(
                    "길다",
                    "lang",
                    "long",
                    "Gegenteil bei Zeit, Haar oder Weg.",
                    "Opposite for time, hair, or a path.",
                    "vocab_a1_0128",
                )
            ],
            related=[
                neighbor(
                    "잠깐",
                    "kurz / einen Moment",
                    "a moment / briefly",
                    "Kurze Zeit, nicht kurze Haare.",
                    "A short time, not short hair.",
                    "vocab_a1_0202",
                )
            ],
            expressions=[
                expression(
                    "짧게 말하다",
                    "sich kurz fassen",
                    "to keep it short",
                    "시간이 없어서 짧게 말할게요.",
                    "Wir haben wenig Zeit, deshalb fasse ich mich kurz.",
                    "We don't have much time, so I'll keep it short.",
                )
            ],
        ),
        cluster(
            "rel_a1_0022",
            "vocab_a1_0087",
            vocab,
            antonyms=[
                neighbor(
                    "오다",
                    "kommen",
                    "to come",
                    "Richtung zum Sprecher. 가다 geht weg, 오다 kommt her.",
                    "Direction toward the speaker. 가다 goes away, 오다 comes here.",
                    "vocab_a1_0088",
                )
            ],
            related=[
                neighbor(
                    "도착하다",
                    "ankommen",
                    "to arrive",
                    "Das Ende des Weggehens.",
                    "The end of going somewhere.",
                    "vocab_a2_0044",
                )
            ],
            expressions=[
                expression(
                    "집에 가다",
                    "nach Hause gehen",
                    "to go home",
                    "이제 집에 갈게요. 내일 봐요.",
                    "Ich gehe jetzt nach Hause. Bis morgen.",
                    "I'm going home now. See you tomorrow.",
                )
            ],
        ),
        cluster(
            "rel_a1_0023",
            "vocab_a1_0088",
            vocab,
            antonyms=[
                neighbor(
                    "가다",
                    "gehen",
                    "to go",
                    "Richtung weg vom Sprecher.",
                    "Direction away from the speaker.",
                    "vocab_a1_0087",
                )
            ],
            related=[
                neighbor(
                    "들어오다",
                    "hereinkommen",
                    "to come in",
                    "Kommen plus Bewegung nach innen.",
                    "Coming plus movement inward.",
                )
            ],
            expressions=[
                expression(
                    "이리 오세요",
                    "Kommen Sie bitte her",
                    "Please come this way",
                    "이쪽으로 오세요. 자리가 있어요.",
                    "Kommen Sie bitte hierher. Es ist noch Platz.",
                    "Please come this way. There's a seat.",
                )
            ],
        ),
        cluster(
            "rel_a1_0024",
            "vocab_a1_0089",
            vocab,
            related=[
                neighbor(
                    "마시다",
                    "trinken",
                    "to drink",
                    "Die Schwesterhandlung zu essen.",
                    "The sister action of eating.",
                    "vocab_a1_0090",
                ),
                neighbor(
                    "밥",
                    "Reis / Mahlzeit",
                    "rice / meal",
                    "Das häufigste Objekt von 먹다.",
                    "The most common object of 먹다.",
                    "vocab_a1_0022",
                ),
            ],
            expressions=[
                expression(
                    "밥 먹었어요?",
                    "Hast du schon gegessen?",
                    "Have you eaten?",
                    "밥 먹었어요? 아직이면 같이 가요.",
                    "Hast du schon gegessen? Wenn nicht, gehen wir zusammen.",
                    "Have you eaten? If not, let's go together.",
                )
            ],
        ),
        cluster(
            "rel_a1_0025",
            "vocab_a1_0091",
            vocab,
            antonyms=[
                neighbor(
                    "없다",
                    "nicht haben / nicht da sein",
                    "to not have / to not be there",
                    "Existenz oder Besitz verneinen.",
                    "Denies existence or possession.",
                    "vocab_a1_0092",
                )
            ],
            related=[
                neighbor(
                    "집",
                    "Haus / Zuhause",
                    "house / home",
                    "Oft in 집에 있어요.",
                    "Often in 집에 있어요.",
                    "vocab_a1_0019",
                )
            ],
            expressions=[
                expression(
                    "시간 있어요?",
                    "Hast du Zeit?",
                    "Do you have time?",
                    "잠깐 이야기할 시간 있어요?",
                    "Hast du kurz Zeit zum Reden?",
                    "Do you have a moment to talk?",
                )
            ],
        ),
        cluster(
            "rel_a1_0026",
            "vocab_a1_0092",
            vocab,
            antonyms=[
                neighbor(
                    "있다",
                    "sein / haben",
                    "to be / to have",
                    "Existenz oder Besitz bejahen.",
                    "Affirms existence or possession.",
                    "vocab_a1_0091",
                )
            ],
            related=[
                neighbor(
                    "모르다",
                    "nicht wissen",
                    "to not know",
                    "Wissen fehlt. 없다 heißt, etwas ist nicht da.",
                    "Knowledge is missing. 없다 means something is not there.",
                    "vocab_a1_0106",
                )
            ],
            expressions=[
                expression(
                    "문제 없어요",
                    "Kein Problem",
                    "No problem",
                    "천천히 해도 돼요. 문제 없어요.",
                    "Du kannst dir Zeit lassen. Kein Problem.",
                    "You can take your time. No problem.",
                )
            ],
        ),
        cluster(
            "rel_a1_0027",
            "vocab_a1_0099",
            vocab,
            antonyms=[
                neighbor(
                    "싫어하다",
                    "nicht mögen",
                    "to dislike",
                    "Das aktive Gegenteil von mögen.",
                    "The active opposite of liking.",
                    "vocab_a1_0100",
                )
            ],
            related=[
                neighbor(
                    "사랑하다",
                    "lieben",
                    "to love",
                    "Deutlich stärker als 좋아하다.",
                    "Much stronger than 좋아하다.",
                    "vocab_a1_0101",
                )
            ],
            expressions=[
                expression(
                    "이거 좋아해요",
                    "Ich mag das",
                    "I like this",
                    "매운 음식 좋아해요. 김치찌개요.",
                    "Ich mag scharfes Essen. Kimchi-Jjigae.",
                    "I like spicy food. Kimchi stew.",
                )
            ],
        ),
        cluster(
            "rel_a1_0028",
            "vocab_a1_0100",
            vocab,
            antonyms=[
                neighbor(
                    "좋아하다",
                    "mögen",
                    "to like",
                    "Das aktive Gegenteil von ablehnen.",
                    "The active opposite of disliking.",
                    "vocab_a1_0099",
                )
            ],
            related=[
                neighbor(
                    "피하다",
                    "meiden",
                    "to avoid",
                    "Nicht nur nicht mögen, sondern aus dem Weg gehen.",
                    "Not just disliking, but staying away.",
                )
            ],
            expressions=[
                expression(
                    "커피는 싫어해요",
                    "Kaffee mag ich nicht",
                    "I don't like coffee",
                    "커피는 싫어해요. 차 주세요.",
                    "Kaffee mag ich nicht. Bitte Tee.",
                    "I don't like coffee. Tea, please.",
                )
            ],
        ),
        cluster(
            "rel_a1_0029",
            "vocab_a1_0105",
            vocab,
            antonyms=[
                neighbor(
                    "모르다",
                    "nicht wissen",
                    "to not know",
                    "Das direkte Gegenteil von wissen.",
                    "The direct opposite of knowing.",
                    "vocab_a1_0106",
                )
            ],
            related=[
                neighbor(
                    "기억하다",
                    "sich erinnern",
                    "to remember",
                    "Wissen, das wiederkommt.",
                    "Knowledge that comes back.",
                    "vocab_a2_0046",
                )
            ],
            expressions=[
                expression(
                    "잘 알아요",
                    "Ich kenne das gut",
                    "I know that well",
                    "이 길은 잘 알아요. 제가 안내할게요.",
                    "Diesen Weg kenne ich gut. Ich führe.",
                    "I know this road well. I'll show the way.",
                )
            ],
        ),
        cluster(
            "rel_a1_0030",
            "vocab_a1_0106",
            vocab,
            antonyms=[
                neighbor(
                    "알다",
                    "wissen / kennen",
                    "to know",
                    "Das direkte Gegenteil von nicht wissen.",
                    "The direct opposite of not knowing.",
                    "vocab_a1_0105",
                )
            ],
            related=[
                neighbor(
                    "묻다",
                    "fragen",
                    "to ask",
                    "Was man tut, wenn man etwas nicht weiß.",
                    "What you do when you don't know something.",
                )
            ],
            expressions=[
                expression(
                    "잘 모르겠어요",
                    "Ich bin mir nicht sicher",
                    "I'm not sure",
                    "이 단어 뜻은 잘 모르겠어요.",
                    "Die Bedeutung dieses Wortes kenne ich nicht genau.",
                    "I'm not sure what this word means.",
                )
            ],
        ),
        cluster(
            "rel_a1_0031",
            "vocab_a1_0107",
            vocab,
            antonyms=[
                neighbor(
                    "받다",
                    "bekommen / empfangen",
                    "to receive / to get",
                    "Die Gegenrichtung von geben.",
                    "The opposite direction of giving.",
                    "vocab_a1_0108",
                )
            ],
            related=[
                neighbor(
                    "선물",
                    "Geschenk",
                    "gift",
                    "Was man oft gibt oder bekommt.",
                    "What people often give or receive.",
                )
            ],
            expressions=[
                expression(
                    "이거 드릴게요",
                    "Das gebe ich Ihnen",
                    "I'll give this to you",
                    "남은 빵이 있어요. 이거 드릴게요.",
                    "Es ist noch Brot übrig. Das gebe ich Ihnen.",
                    "There's bread left. I'll give this to you.",
                )
            ],
        ),
        cluster(
            "rel_a1_0032",
            "vocab_a1_0108",
            vocab,
            antonyms=[
                neighbor(
                    "주다",
                    "geben",
                    "to give",
                    "Die Gegenrichtung von bekommen.",
                    "The opposite direction of receiving.",
                    "vocab_a1_0107",
                )
            ],
            related=[
                neighbor(
                    "문자",
                    "Nachricht",
                    "text message",
                    "Etwas, das man oft bekommt.",
                    "Something people often receive.",
                )
            ],
            expressions=[
                expression(
                    "메시지를 받다",
                    "eine Nachricht bekommen",
                    "to get a message",
                    "방금 친구에게 메시지를 받았어요.",
                    "Gerade habe ich eine Nachricht von einem Freund bekommen.",
                    "I just got a message from a friend.",
                )
            ],
        ),
        cluster(
            "rel_a1_0033",
            "vocab_a1_0103",
            vocab,
            synonyms=[
                neighbor(
                    "이야기하다",
                    "sich unterhalten / erzählen",
                    "to talk / to tell",
                    "Länger und weicher als 말하다. Ein Gespräch, kein einzelner Satz.",
                    "Longer and softer than 말하다. A conversation, not a single line.",
                )
            ],
            related=[
                neighbor(
                    "듣다",
                    "hören / zuhören",
                    "to listen / to hear",
                    "Die andere Seite des Sprechens.",
                    "The other side of speaking.",
                    "vocab_a1_0095",
                )
            ],
            expressions=[
                expression(
                    "천천히 말해 주세요",
                    "Bitte sprich langsam",
                    "Please speak slowly",
                    "한국어를 배우고 있어요. 천천히 말해 주세요.",
                    "Ich lerne Koreanisch. Bitte sprich langsam.",
                    "I'm learning Korean. Please speak slowly.",
                )
            ],
        ),
        cluster(
            "rel_a1_0034",
            "vocab_a1_0029",
            vocab,
            related=[
                neighbor(
                    "내일",
                    "morgen",
                    "tomorrow",
                    "Der Tag nach heute.",
                    "The day after today.",
                    "vocab_a1_0030",
                ),
                neighbor(
                    "어제",
                    "gestern",
                    "yesterday",
                    "Der Tag vor heute.",
                    "The day before today.",
                    "vocab_a1_0031",
                ),
            ],
            expressions=[
                expression(
                    "오늘 어때요?",
                    "Wie ist dein Tag heute?",
                    "How's today going?",
                    "오늘 어때요? 바빠요?",
                    "Wie ist dein Tag heute? Bist du beschäftigt?",
                    "How's today going? Are you busy?",
                )
            ],
        ),
        cluster(
            "rel_a1_0035",
            "vocab_a1_0030",
            vocab,
            related=[
                neighbor(
                    "오늘",
                    "heute",
                    "today",
                    "Der Tag vor morgen.",
                    "The day before tomorrow.",
                    "vocab_a1_0029",
                ),
                neighbor(
                    "모레",
                    "übermorgen",
                    "the day after tomorrow",
                    "Noch ein Tag weiter als 내일.",
                    "One more day after 내일.",
                ),
            ],
            expressions=[
                expression(
                    "내일 봐요",
                    "Bis morgen",
                    "See you tomorrow",
                    "오늘은 여기까지 해요. 내일 봐요.",
                    "Für heute reicht es. Bis morgen.",
                    "That's enough for today. See you tomorrow.",
                )
            ],
        ),
        cluster(
            "rel_a1_0036",
            "vocab_a1_0031",
            vocab,
            related=[
                neighbor(
                    "오늘",
                    "heute",
                    "today",
                    "Der Tag nach gestern.",
                    "The day after yesterday.",
                    "vocab_a1_0029",
                ),
                neighbor(
                    "그제",
                    "vorgestern",
                    "the day before yesterday",
                    "Noch ein Tag vor 어제.",
                    "One more day before 어제.",
                ),
            ],
            expressions=[
                expression(
                    "어제 뭐 했어요?",
                    "Was hast du gestern gemacht?",
                    "What did you do yesterday?",
                    "어제 뭐 했어요? 집에서 쉬었어요?",
                    "Was hast du gestern gemacht? Hast du zu Hause ausgeruht?",
                    "What did you do yesterday? Did you rest at home?",
                )
            ],
        ),
        cluster(
            "rel_a1_0037",
            "vocab_a1_0086",
            vocab,
            antonyms=[
                neighbor(
                    "천천히",
                    "langsam",
                    "slowly",
                    "Das Gegenteil von schnell.",
                    "The opposite of quickly.",
                    "vocab_a1_0203",
                )
            ],
            related=[
                neighbor(
                    "빠르다",
                    "schnell sein",
                    "to be fast",
                    "Die Eigenschaft hinter 빨리.",
                    "The quality behind 빨리.",
                    "vocab_a2_0070",
                )
            ],
            expressions=[
                expression(
                    "빨리 오세요",
                    "Komm schnell",
                    "Come quickly",
                    "버스가 와요. 빨리 오세요!",
                    "Der Bus kommt. Komm schnell!",
                    "The bus is coming. Come quickly!",
                )
            ],
        ),
        cluster(
            "rel_a1_0038",
            "vocab_a1_0203",
            vocab,
            antonyms=[
                neighbor(
                    "빨리",
                    "schnell",
                    "quickly",
                    "Das Gegenteil von langsam.",
                    "The opposite of slowly.",
                    "vocab_a1_0086",
                )
            ],
            related=[
                neighbor(
                    "느리다",
                    "langsam sein",
                    "to be slow",
                    "Die Eigenschaft hinter 천천히.",
                    "The quality behind 천천히.",
                    "vocab_a2_0071",
                )
            ],
            expressions=[
                expression(
                    "천천히 걸어요",
                    "Ich gehe langsam",
                    "I walk slowly",
                    "비가 와서 천천히 걸어요.",
                    "Es regnet, deshalb gehe ich langsam.",
                    "It's raining, so I walk slowly.",
                )
            ],
        ),
        cluster(
            "rel_a1_0039",
            "vocab_a1_0084",
            vocab,
            antonyms=[
                neighbor(
                    "가끔",
                    "manchmal",
                    "sometimes",
                    "Selten statt immer.",
                    "Sometimes instead of always.",
                    "vocab_a1_0085",
                )
            ],
            related=[
                neighbor(
                    "자주",
                    "oft",
                    "often",
                    "Zwischen immer und manchmal.",
                    "Between always and sometimes.",
                    "vocab_a1_0206",
                )
            ],
            expressions=[
                expression(
                    "항상 고마워요",
                    "Danke, immer",
                    "Thank you, always",
                    "항상 도와줘서 고마워요.",
                    "Danke, dass du immer hilfst.",
                    "Thank you for always helping.",
                )
            ],
        ),
        cluster(
            "rel_a1_0040",
            "vocab_a1_0019",
            vocab,
            related=[
                neighbor(
                    "학교",
                    "Schule",
                    "school",
                    "Der andere Alltagsort neben dem Zuhause.",
                    "The other everyday place besides home.",
                    "vocab_a1_0020",
                ),
                neighbor(
                    "가족",
                    "Familie",
                    "family",
                    "Die Menschen im Haus.",
                    "The people in the house.",
                    "vocab_a1_0018",
                ),
            ],
            expressions=[
                expression(
                    "집에 있다",
                    "zu Hause sein",
                    "to be at home",
                    "오늘은 약속이 없어서 집에 있어요.",
                    "Heute habe ich keinen Termin, deshalb bin ich zu Hause.",
                    "I have no plans today, so I'm at home.",
                )
            ],
        ),
        cluster(
            "rel_a1_0041",
            "vocab_a1_0022",
            vocab,
            synonyms=[
                neighbor(
                    "식사",
                    "Mahlzeit",
                    "a meal",
                    "Höflicher und weiter als 밥. Frühstück, Mittag, Abend.",
                    "More polite and broader than 밥. Breakfast, lunch, dinner.",
                )
            ],
            related=[
                neighbor(
                    "먹다",
                    "essen",
                    "to eat",
                    "Die Handlung zu 밥.",
                    "The action for 밥.",
                    "vocab_a1_0089",
                )
            ],
            expressions=[
                expression(
                    "밥 먹으러 가요",
                    "Lass uns essen gehen",
                    "Let's go eat",
                    "배고프면 밥 먹으러 가요.",
                    "Wenn du Hunger hast, gehen wir essen.",
                    "If you're hungry, let's go eat.",
                )
            ],
        ),
        cluster(
            "rel_a1_0042",
            "vocab_a1_0013",
            vocab,
            related=[
                neighbor(
                    "선생님",
                    "Lehrer/in",
                    "teacher",
                    "Die Person, die den Schüler unterrichtet.",
                    "The person who teaches the student.",
                    "vocab_a1_0014",
                ),
                neighbor(
                    "학교",
                    "Schule",
                    "school",
                    "Der Ort des Schülers.",
                    "The student's place.",
                    "vocab_a1_0020",
                ),
            ],
            expressions=[
                expression(
                    "한국어 학생이에요",
                    "Ich bin Koreanischlernende/r",
                    "I'm a Korean student",
                    "안녕하세요. 저는 한국어 학생이에요.",
                    "Guten Tag. Ich lerne Koreanisch.",
                    "Hello. I'm a Korean-language student.",
                )
            ],
        ),
        cluster(
            "rel_a2_0001",
            "vocab_a2_0063",
            vocab,
            antonyms=[
                neighbor(
                    "슬프다",
                    "traurig sein",
                    "to be sad",
                    "Das Gefühlgegenteil von glücklich.",
                    "The feeling opposite of happy.",
                    "vocab_a2_0064",
                )
            ],
            related=[
                neighbor(
                    "웃다",
                    "lachen / lächeln",
                    "to laugh / to smile",
                    "Was oft mit Glück zusammenkommt.",
                    "What often comes with happiness.",
                )
            ],
            expressions=[
                expression(
                    "오늘 정말 행복해요",
                    "Heute bin ich wirklich glücklich",
                    "I'm really happy today",
                    "친구를 오래만에 만나서 오늘 정말 행복해요.",
                    "Ich habe eine Freundin nach langer Zeit getroffen. Heute bin ich wirklich glücklich.",
                    "I met a friend after a long time. I'm really happy today.",
                )
            ],
        ),
        cluster(
            "rel_a2_0002",
            "vocab_a2_0064",
            vocab,
            antonyms=[
                neighbor(
                    "행복하다",
                    "glücklich sein",
                    "to be happy",
                    "Das Gefühlgegenteil von traurig.",
                    "The feeling opposite of sad.",
                    "vocab_a2_0063",
                )
            ],
            related=[
                neighbor(
                    "울다",
                    "weinen",
                    "to cry",
                    "Was Trauer oft sichtbar macht.",
                    "What sadness often makes visible.",
                )
            ],
            expressions=[
                expression(
                    "슬픈 이야기",
                    "eine traurige Geschichte",
                    "a sad story",
                    "그 영화는 슬픈 이야기라서 중간에 울었어요.",
                    "Der Film ist eine traurige Geschichte, deshalb habe ich zwischendurch geweint.",
                    "The film is a sad story, so I cried in the middle.",
                )
            ],
        ),
        cluster(
            "rel_a2_0003",
            "vocab_a2_0061",
            vocab,
            antonyms=[
                neighbor(
                    "한가하다",
                    "frei / nicht beschäftigt sein",
                    "to be free / not busy",
                    "Zeit haben. Das Gegenteil von voller Termine.",
                    "Having time. The opposite of a full calendar.",
                )
            ],
            related=[
                neighbor(
                    "일하다",
                    "arbeiten",
                    "to work",
                    "Ein häufiger Grund, beschäftigt zu sein.",
                    "A common reason to be busy.",
                    "vocab_a1_0114",
                )
            ],
            expressions=[
                expression(
                    "요즘 너무 바빠요",
                    "Ich bin zurzeit sehr beschäftigt",
                    "I'm very busy these days",
                    "시험이 있어서 요즘 너무 바빠요.",
                    "Ich habe Prüfungen, deshalb bin ich zurzeit sehr beschäftigt.",
                    "I have exams, so I'm very busy these days.",
                )
            ],
        ),
        cluster(
            "rel_a2_0004",
            "vocab_a2_0048",
            vocab,
            antonyms=[
                neighbor(
                    "가르치다",
                    "lehren / unterrichten",
                    "to teach",
                    "Die Gegenrichtung: jemand gibt Wissen, jemand nimmt es auf.",
                    "The opposite direction: someone gives knowledge, someone takes it in.",
                    "vocab_a2_0049",
                )
            ],
            related=[
                neighbor(
                    "공부하다",
                    "lernen / studieren",
                    "to study",
                    "Lernen als Arbeit. 배우다 betont das Neue.",
                    "Learning as work. 배우다 stresses something new.",
                    "vocab_a2_0039",
                )
            ],
            expressions=[
                expression(
                    "한국어를 배우고 있어요",
                    "Ich lerne gerade Koreanisch",
                    "I'm learning Korean",
                    "작년부터 한국어를 배우고 있어요.",
                    "Seit letztem Jahr lerne ich Koreanisch.",
                    "I've been learning Korean since last year.",
                )
            ],
        ),
        cluster(
            "rel_a2_0005",
            "vocab_a2_0084",
            vocab,
            antonyms=[
                neighbor(
                    "같이",
                    "zusammen",
                    "together",
                    "Nicht allein, sondern mit jemandem.",
                    "Not alone, but with someone.",
                    "vocab_a2_0085",
                )
            ],
            related=[
                neighbor(
                    "외롭다",
                    "einsam sein",
                    "to be lonely",
                    "Alleinsein als Gefühl, nicht nur als Tatsache.",
                    "Being alone as a feeling, not just a fact.",
                    "vocab_a2_0079",
                )
            ],
            expressions=[
                expression(
                    "혼자 살아요",
                    "Ich wohne allein",
                    "I live alone",
                    "지금은 서울에서 혼자 살아요.",
                    "Im Moment wohne ich allein in Seoul.",
                    "I live alone in Seoul right now.",
                )
            ],
        ),
        cluster(
            "rel_a2_0006",
            "vocab_a2_0085",
            vocab,
            antonyms=[
                neighbor(
                    "혼자",
                    "allein",
                    "alone",
                    "Ohne die andere Person.",
                    "Without the other person.",
                    "vocab_a2_0084",
                )
            ],
            related=[
                neighbor(
                    "함께",
                    "gemeinsam",
                    "together / along with",
                    "Etwas förmlicher als 같이.",
                    "A bit more formal than 같이.",
                )
            ],
            expressions=[
                expression(
                    "같이 갈래요?",
                    "Willst du mitkommen?",
                    "Want to go together?",
                    "커피 마시러 같이 갈래요?",
                    "Willst du mitkommen, einen Kaffee trinken?",
                    "Want to go get coffee together?",
                )
            ],
        ),
        cluster(
            "rel_a2_0007",
            "vocab_a2_0062",
            vocab,
            synonyms=[
                neighbor(
                    "졸리다",
                    "schläfrig sein",
                    "to be sleepy",
                    "Augen fallen zu. 피곤하다 ist der Körper nach Arbeit.",
                    "The eyes want to close. 피곤하다 is the body after work.",
                )
            ],
            related=[
                neighbor(
                    "쉬다",
                    "sich ausruhen",
                    "to rest",
                    "Was man bei Müdigkeit braucht.",
                    "What you need when you're tired.",
                    "vocab_a2_0045",
                )
            ],
            expressions=[
                expression(
                    "오늘 너무 피곤해요",
                    "Ich bin heute sehr müde",
                    "I'm very tired today",
                    "일을 많이 해서 오늘 너무 피곤해요.",
                    "Ich habe viel gearbeitet, deshalb bin ich heute sehr müde.",
                    "I worked a lot, so I'm very tired today.",
                )
            ],
        ),
        cluster(
            "rel_a2_0008",
            "vocab_a2_0069",
            vocab,
            antonyms=[
                neighbor(
                    "건강하다",
                    "gesund sein",
                    "to be healthy",
                    "Der Körperzustand gegenüber Krankheit oder Schmerz.",
                    "The body state opposite illness or pain.",
                    "vocab_a2_0068",
                )
            ],
            related=[
                neighbor(
                    "병원",
                    "Krankenhaus / Arztpraxis",
                    "hospital / clinic",
                    "Wohin man bei 아프다 oft geht.",
                    "Where people often go when they 아프다.",
                )
            ],
            expressions=[
                expression(
                    "머리가 아파요",
                    "Ich habe Kopfschmerzen",
                    "I have a headache",
                    "잠을 못 자서 머리가 아파요.",
                    "Ich habe schlecht geschlafen, deshalb tut der Kopf weh.",
                    "I didn't sleep well, so I have a headache.",
                )
            ],
        ),
    ]


def main() -> None:
    vocab = load_vocab()
    clusters = build(vocab)
    ids = [c["id"] for c in clusters]
    if len(ids) != len(set(ids)):
        raise SystemExit("duplicate cluster ids")
    sources = [c["sourceKo"] for c in clusters]
    if len(sources) != len(set(sources)):
        raise SystemExit("duplicate source words")
    payload = {
        "_comment": (
            "Word-web seed: synonyms, antonyms, related words, and expressions "
            "for learned Hangul Sori vocab. rights: original. Language facts "
            "plus independently written DE/EN/KO examples. Not a can-do or "
            "Hanok authority."
        ),
        "version": 1,
        "clusters": clusters,
    }
    OUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {len(clusters)} clusters to {OUT}")


if __name__ == "__main__":
    main()
