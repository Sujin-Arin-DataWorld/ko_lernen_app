#!/usr/bin/env python3
"""Batch 24 P2 — supplement every pack under 8 words (A1/A2/B1/B2) with
NIKL-graded headwords of the pack's level, one level-checked example each,
plus derived cloze/satz, can-do inherited rows, counts, drafts/review ledgers.

Run:  promote_batch24.py check   (profile + contract report, no writes)
      promote_batch24.py apply
"""
from __future__ import annotations
import bisect, csv, hashlib, json, random, re, subprocess, sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool")); sys.path.insert(0, str(ROOT / "tools/content_factory"))
from cefr_lexicon import CefrLexicon, GrammarIndex, load_grammar_rows, load_nikl_grammar_rows  # noqa
from audit_content_naturalness import PARTICLE_BATCHIM, find_particle_after_blank, has_batchim  # noqa

VOCAB = ROOT / "assets/data/korean_vocab.csv"; CLOZE = ROOT / "assets/data/cloze.json"; SATZ = ROOT / "assets/data/satz_sentences.json"
CUR = ROOT / "assets/data/curriculum_manifest.json"; SEG = ROOT / "assets/data/can_do_segments.json"; AUTH = ROOT / "assets/data/can_do_content_authorities.json"
AUDIT = ROOT / "tools/content_factory/content_audit_manifest.json"
BLANK = "＿＿＿"; TODAY = "2026-09-09"; MEMO = "Fable 직독 승인 2026-09-09 (PR-L3a Batch 24 보충); Jin 10% 표본 대기"
COLUMNS = ["korean","romanization","german","level","pos_de","example_korean","example_german","topic","pack_id","pack_order","is_review_boss","english","pos_en","example_english","id"]
RANK = {"A1": 1, "A2": 2, "B1": 3, "B2": 4, "C1": 5, "C2": 6}
POS_EN = {"Nomen": "Noun", "Verb": "Verb", "Adjektiv": "Adjective", "Adverb": "Adverb"}

# pack -> (level, vocab topic, cloze topic)
PACKS = {
 "a1_transport": ("A1", "Verkehr", "Verkehr"), "a1_payment_delivery_1": ("A1", "결제와 배달", "결제와 배달"), "a1_repair_language_1": ("A1", "다시 묻기", "다시 묻기"),
 "a2_education": ("A2", "Bildung", "Bildung"), "a2_food_1": ("A2", "Essen & Trinken", "Essen & Trinken"), "a2_food_2": ("A2", "Essen & Trinken", "Essen & Trinken"),
 "a2_shopping_1": ("A2", "Einkaufen", "Einkaufen"), "a2_shopping_2": ("A2", "Einkaufen", "Einkaufen"), "a2_feelings_2": ("A2", "Gefühle", "Gefühle"),
 "a2_plans_proposals_1": ("A2", "약속과 일정", "약속과 일정"), "a2_descriptions_2": ("A2", "Beschreibung", "Beschreibung"),
 "b1_work_softening_1": ("B1", "직장 소통", "직장 소통"), "b1_emotions_relations_2": ("B1", "Motivation", "Beziehungen"), "b1_emotions_relations_3": ("B1", "Gefühle", "Beziehungen"),
 "b2_abstract_concepts_1": ("B2", "Abstrakte Begriffe", "Abstrakte Begriffe"), "b2_education": ("B2", "Bildung", "Bildung"),
}
NEW_TOPIC_ROUTES = {"a2:gefühle": "a2_04_feelings_health", "a2:beschreibung": "a2_01_haeyo_transition", "b1:직장 소통": "b1_03_work_softening", "b2:abstrakte begriffe": "b2_02_professional_opinion"}

# korean, roman, german, pos_de, ko, de, en, cloze answer form (as it appears in ko), optional vocab-topic override
W = {
 "a1_transport": [
  ("자동차","jadongcha","Auto","Nomen","저는 자동차로 회사에 가요.","Ich fahre mit dem Auto zur Arbeit.","I go to work by car.","자동차"),
  ("역","yeok","Bahnhof, Station","Nomen","역 앞에서 만나요.","Wir treffen uns vor dem Bahnhof.","Let's meet in front of the station.","만나요"),
  ("공항","gonghang","Flughafen","Nomen","공항까지 버스로 가요.","Zum Flughafen fahre ich mit dem Bus.","I take the bus to the airport.","공항"),
  ("출발","chulbal","Abfahrt","Nomen","출발 시간이 몇 시예요?","Um wie viel Uhr ist die Abfahrt?","What time is the departure?","출발"),
  ("도착","dochak","Ankunft","Nomen","서울에 도착 후에 전화해요.","Nach der Ankunft in Seoul rufe ich an.","After arriving in Seoul, I'll call.","도착"),
  ("타다","tada","einsteigen; fahren mit","Verb","버스를 타고 학교에 가요.","Ich fahre mit dem Bus zur Schule.","I take the bus to school.","타고"),
  ("내리다","naerida","aussteigen","Verb","다음 역에서 내려요.","Ich steige an der nächsten Station aus.","I get off at the next station.","내려요"),
 ],
 "a1_payment_delivery_1": [
  ("돈","don","Geld","Nomen","지금 돈이 없어요.","Ich habe gerade kein Geld.","I don't have money right now.","없어요"),
  ("원","won","Won (Währung)","Nomen","커피는 사천 원이에요.","Der Kaffee kostet viertausend Won.","The coffee is four thousand won.","커피"),
  ("번호","beonho","Nummer","Nomen","제 번호는 십오 번이에요.","Meine Nummer ist die Fünfzehn.","My number is fifteen.","번호"),
  ("기다리다","gidarida","warten","Verb","문 앞에서 기다려요.","Ich warte vor der Tür.","I'm waiting in front of the door.","기다려요"),
 ],
 "a1_repair_language_1": [
  ("다시","dasi","noch einmal, wieder","Adverb","다시 한번 말해 주세요.","Bitte sagen Sie es noch einmal.","Please say it once more.","다시"),
  ("단어","daneo","Wort, Vokabel","Nomen","이 단어는 무슨 뜻이에요?","Was bedeutet dieses Wort?","What does this word mean?","단어"),
  ("사전","sajeon","Wörterbuch","Nomen","사전에서 단어를 찾아요.","Ich schlage das Wort im Wörterbuch nach.","I look the word up in the dictionary.","사전"),
 ],
 "a2_education": [
  ("학년","hangnyeon","Schuljahr; Studienjahr","Nomen","저는 지금 대학교 이 학년이에요.","Ich bin jetzt im zweiten Studienjahr.","I'm in my second year of university now.","학년"),
  ("복습","bokseup","Wiederholung (des Gelernten)","Nomen","수업 후에 꼭 복습을 해요.","Nach dem Unterricht wiederhole ich den Stoff auf jeden Fall.","I always review after class.","복습"),
  ("예습","yeseup","Vorbereitung auf den Unterricht","Nomen","내일 수업 예습은 벌써 끝냈어요.","Die Vorbereitung für den Unterricht morgen habe ich schon fertig.","I've already finished preparing for tomorrow's class.","예습"),
 ],
 "a2_food_1": [
  ("국","guk","Suppe","Nomen","국이 좀 식었네요.","Die Suppe ist etwas kalt geworden.","The soup has gotten a bit cold.","식었네요"),
  ("접시","jeopsi","Teller","Nomen","접시 하나만 더 주세요.","Bitte noch einen Teller.","One more plate, please.","접시"),
  ("설탕","seoltang","Zucker","Nomen","커피에 설탕은 안 넣어요.","In den Kaffee tue ich keinen Zucker.","I don't put sugar in my coffee.","설탕"),
 ],
 "a2_food_2": [
  ("끓이다","kkeurida","kochen (Wasser, Suppe)","Verb","물을 끓여서 차를 마셔요.","Ich koche Wasser und trinke Tee.","I boil water and drink tea.","끓여서"),
  ("볶다","bokda","anbraten, pfannenrühren","Verb","고기를 먼저 볶으세요.","Braten Sie zuerst das Fleisch an.","Stir-fry the meat first.","볶으세요"),
  ("굽다","gupda","grillen; backen","Verb","생선은 굽는 게 제일 맛있어요.","Fisch schmeckt gegrillt am besten.","Fish tastes best grilled.","굽는"),
 ],
 "a2_shopping_1": [
  ("마트","mateu","Supermarkt","Nomen","퇴근하고 마트에 들를게요.","Nach der Arbeit gehe ich noch kurz in den Supermarkt.","I'll stop by the supermarket after work.","마트"),
  ("상자","sangja","Karton, Kiste","Nomen","이 상자에 다 넣어 주세요.","Bitte legen Sie alles in diesen Karton.","Please put everything in this box.","상자"),
  ("디자인","dijain","Design","Nomen","디자인은 예쁘지만 좀 비싸요.","Das Design ist schön, aber etwas teuer.","The design is pretty, but it's a bit pricey.","디자인"),
 ],
 "a2_shopping_2": [
  ("반바지","banbaji","kurze Hose","Nomen","여름이라서 반바지를 샀어요.","Weil Sommer ist, habe ich eine kurze Hose gekauft.","Since it's summer, I bought shorts.","반바지"),
  ("단추","danchu","Knopf","Nomen","단추가 하나 떨어졌어요.","Ein Knopf ist abgegangen.","A button has come off.","단추"),
  ("모양","moyang","Form","Nomen","모양은 마음에 들지만 색이 별로예요.","Die Form gefällt mir, aber die Farbe nicht so.","I like the shape, but the color isn't great.","모양"),
 ],
 "a2_feelings_2": [
  ("심심하다","simsimhada","sich langweilen","Adjektiv","주말에 혼자 있으니까 심심해요.","Am Wochenende bin ich allein, deshalb ist mir langweilig.","I'm alone on the weekend, so I'm bored.","심심해요"),
  ("편하다","pyeonhada","bequem; angenehm","Adjektiv","이 신발은 정말 편해요.","Diese Schuhe sind wirklich bequem.","These shoes are really comfortable.","편해요"),
  ("즐겁다","jeulgeopda","vergnüglich, fröhlich","Adjektiv","오늘 하루가 정말 즐거워요.","Der Tag heute ist wirklich schön.","Today is really enjoyable.","즐거워요"),
 ],
 "a2_plans_proposals_1": [
  ("약속","yaksok","Verabredung; Versprechen","Nomen","이번 주말에 약속 있어요?","Hast du am Wochenende schon etwas vor?","Do you have plans this weekend?","약속"),
  ("계획","gyehoek","Plan","Nomen","방학 계획은 세웠어요?","Hast du schon Pläne für die Ferien gemacht?","Have you made plans for the vacation?","계획"),
  ("시간표","siganpyo","Stundenplan; Fahrplan","Nomen","시간표를 보고 시간을 정해요.","Wir schauen auf den Stundenplan und legen die Zeit fest.","Let's check the timetable and set a time.","시간표"),
  ("비다","bida","frei sein (Zeit); leer sein","Verb","목요일 오후는 시간이 비어요.","Donnerstagnachmittag habe ich Zeit.","Thursday afternoon I'm free.","비어요"),
  ("가능하다","ganeunghada","möglich sein","Adjektiv","다음 주로 바꾸는 것도 가능해요.","Man kann es auch auf nächste Woche verschieben.","Changing it to next week is also possible.","가능해요"),
  ("휴일","hyuil","freier Tag; Feiertag","Nomen","휴일에는 보통 늦게 일어나요.","An freien Tagen stehe ich meistens spät auf.","On days off I usually get up late.","휴일"),
 ],
 "a2_descriptions_2": [
  ("하늘색","haneulsaek","Hellblau","Nomen","하늘색 셔츠가 잘 어울려요.","Das hellblaue Hemd steht dir gut.","The light blue shirt suits you.","하늘색","Farben"),
  ("진하다","jinhada","kräftig, dunkel (Farbe); stark (Kaffee)","Adjektiv","커피가 너무 진해요.","Der Kaffee ist zu stark.","The coffee is too strong.","진해요"),
  ("두껍다","dukkeopda","dick","Adjektiv","코트가 두껍고 따뜻해요.","Der Mantel ist dick und warm.","The coat is thick and warm.","두껍고"),
 ],
 "b1_work_softening_1": [
  ("부담","budam","Belastung; Druck","Nomen","부담 갖지 말고 편하게 말씀해 주세요.","Fühlen Sie sich nicht unter Druck gesetzt, sprechen Sie ganz offen.","Please don't feel pressured; speak freely.","부담"),
  ("협조","hyeopjo","Mitwirkung, Kooperation","Nomen","일정 조정에 협조해 주셔서 감사합니다.","Danke, dass Sie bei der Terminabstimmung mitgeholfen haben.","Thank you for cooperating with the schedule change.","협조"),
  ("출근","chulgeun","Arbeitsbeginn; zur Arbeit gehen","Nomen","내일은 출근이 조금 늦을 것 같아요.","Morgen komme ich wahrscheinlich etwas später zur Arbeit.","I'll probably be a little late to work tomorrow.","출근"),
  ("퇴근","toegeun","Feierabend","Nomen","퇴근 전에 보고서를 보낼게요.","Vor Feierabend schicke ich den Bericht.","I'll send the report before I leave work.","퇴근"),
 ],
 "b1_emotions_relations_2": [
  ("격려하다","gyeongnyeohada","ermutigen","Verb","힘들 때마다 친구가 저를 격려해 줬어요.","Immer wenn es schwer war, hat mich meine Freundin ermutigt.","Whenever things were hard, my friend encouraged me.","격려해"),
  ("위로하다","wirohada","trösten","Verb","슬퍼하는 친구를 위로했어요.","Ich habe meinen traurigen Freund getröstet.","I comforted my sad friend.","위로했어요"),
  ("존중하다","jonjunghada","respektieren","Verb","서로의 의견을 존중하는 게 중요해요.","Es ist wichtig, die Meinung des anderen zu respektieren.","It's important to respect each other's opinions.","존중하는"),
 ],
 "b1_emotions_relations_3": [
  ("감정","gamjeong","Gefühl, Emotion","Nomen","제 감정을 말로 표현하기가 어려워요.","Es fällt mir schwer, meine Gefühle in Worte zu fassen.","It's hard for me to put my feelings into words.","감정"),
  ("오해","ohae","Missverständnis","Nomen","서로 오해가 있었던 것 같아요.","Ich glaube, wir hatten ein Missverständnis.","I think there was a misunderstanding between us.","오해"),
  ("화해하다","hwahaehada","sich versöhnen","Verb","싸운 다음 날 바로 화해했어요.","Am Tag nach dem Streit haben wir uns gleich versöhnt.","We made up the day right after the fight.","화해했어요"),
 ],
 "b2_abstract_concepts_1": [
  ("개념","gaenyeom","Begriff, Konzept","Nomen","이 개념은 예를 들어 설명하는 편이 이해하기 쉬워요.","Diesen Begriff versteht man leichter, wenn man ihn mit Beispielen erklärt.","This concept is easier to understand when explained with examples.","개념"),
  ("요소","yoso","Element, Faktor","Nomen","성공에는 운도 중요한 요소예요.","Auch Glück ist ein wichtiger Faktor für den Erfolg.","Luck is also an important factor in success.","요소"),
  ("원리","wolli","Prinzip","Nomen","원리를 알면 응용은 어렵지 않아요.","Wenn man das Prinzip versteht, ist die Anwendung nicht schwer.","Once you know the principle, applying it isn't hard.","원리"),
  ("가치","gachi","Wert","Nomen","이 일의 가치는 돈으로 따질 수 없어요.","Der Wert dieser Arbeit lässt sich nicht in Geld messen.","The value of this work can't be measured in money.","가치"),
  ("본질","bonjil","Wesen, Kern","Nomen","문제의 본질을 먼저 파악해야 해요.","Man muss zuerst den Kern des Problems erfassen.","You have to grasp the essence of the problem first.","본질"),
  ("특징","teukjing","Merkmal, Besonderheit","Nomen","이 제품의 가장 큰 특징은 가벼운 무게예요.","Das größte Merkmal dieses Produkts ist sein geringes Gewicht.","This product's biggest feature is its light weight.","특징"),
 ],
 "b2_education": [
  ("학문","hangmun","Wissenschaft; akademisches Fach","Nomen","학문의 길은 끝이 없는 것 같아요.","Der Weg der Wissenschaft scheint kein Ende zu haben.","The path of scholarship seems to have no end.","학문"),
  ("강의","gangui","Vorlesung","Nomen","그 교수님 강의는 항상 자리가 없어요.","In der Vorlesung von diesem Professor sind die Plätze immer voll.","That professor's lectures are always full.","강의"),
  ("지식","jisik","Wissen","Nomen","지식보다 경험이 더 중요할 때도 있어요.","Manchmal ist Erfahrung wichtiger als Wissen.","Sometimes experience matters more than knowledge.","지식"),
  ("과제","gwaje","Aufgabe; Hausarbeit (Uni)","Nomen","이번 학기 과제는 팀으로 진행해요.","Die Hausarbeit in diesem Semester machen wir im Team.","This semester's assignment is done in teams.","과제"),
  ("성과","seonggwa","Ergebnis, Leistung","Nomen","일 년 동안의 연구 성과를 발표했어요.","Ich habe die Forschungsergebnisse eines Jahres vorgestellt.","I presented the results of a year's research.","성과"),
 ],
}


def rj(p): return json.loads(p.read_text(encoding="utf-8"))
def wj(p, v): p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
def syl(s): return sum(1 for ch in s if 0xAC00 <= ord(ch) <= 0xD7A3)
def rd_vocab():
    with VOCAB.open(encoding="utf-8", newline="") as f: return list(csv.DictReader(f))
def wr_vocab(rows):
    with VOCAB.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n"); w.writerow(COLUMNS); [w.writerow([r[c] for c in COLUMNS]) for r in rows]
def insert_sorted(lst, item, key):
    keys = [key(x) for x in lst]
    if keys == sorted(keys): lst.insert(bisect.bisect_left(keys, key(item)), item)
    else: lst.append(item)


def main(apply: bool):
    lex = CefrLexicon.load(); gi = GrammarIndex.build(load_grammar_rows(), load_nikl_grammar_rows())
    rows = rd_vocab(); have = defaultdict(list)
    for r in rows: have[r["korean"]].append(r["level"])
    by_pack = defaultdict(list)
    for r in rows: by_pack[r["pack_id"]].append(r)
    pool = defaultdict(list); info = {}
    for r in rows:
        lv = r["level"].lower(); info[(lv, r["korean"])] = r
        if " " not in r["korean"] and syl(r["korean"]) >= 2: pool[(lv, r["pos_de"])].append(r)
    problems = []; new_rows = []; plan = []
    nxt = {}
    for lvl in ("a1", "a2", "b1", "b2"):
        nxt[lvl] = max(int(r["id"].rsplit("_", 1)[1]) for r in rows if r["id"].startswith(f"vocab_{lvl}_")) + 1
    for pack, entries in W.items():
        level, vtopic, ctopic = PACKS[pack]; lvl = level.lower()
        assert by_pack[pack], pack
        order = max(int(r["pack_order"]) for r in by_pack[pack])
        for e in entries:
            ko, rom, de, pos, ex, exde, exen, ans = e[:8]; vt = e[8] if len(e) > 8 else vtopic
            if ko in have: problems.append(f"{pack}:{ko} already exists at {have[ko]}")
            g = lex.word_grade(ko).grade
            if g is None or g > RANK[level] + 1: problems.append(f"{pack}:{ko} grade {g} vs level {level}")
            p = lex.sentence_profile(ex, gi)
            if p.unknown: problems.append(f"{pack}:{ko} unknown tokens {p.unknown}")
            if RANK.get(p.level_estimate, 9) > RANK[level]: problems.append(f"{pack}:{ko} sentence est {p.level_estimate} > {level}: {ex}")
            if ans not in ex: problems.append(f"{pack}:{ko} answer form {ans} not in {ex}")
            if syl(ans) < 2: problems.append(f"{pack}:{ko} answer {ans} single syllable")
            if len(ex.split(" ")) < 3: problems.append(f"{pack}:{ko} example under 3 tokens")
            order += 1
            rid = f"vocab_{lvl}_{nxt[lvl]:04d}"; nxt[lvl] += 1
            new_rows.append({"korean": ko, "romanization": rom, "german": de, "level": level, "pos_de": pos, "example_korean": ex, "example_german": exde,
                             "topic": vt, "pack_id": pack, "pack_order": str(order), "is_review_boss": "false", "english": e[6] and exen and E_MAP.get(ko, "") or "", "pos_en": POS_EN[pos], "example_english": exen, "id": rid})
            plan.append((pack, level, ctopic, new_rows[-1], ans))
    # english headword glosses
    for r in new_rows:
        r["english"] = E_MAP[r["korean"]]
    print(f"planned rows: {len(new_rows)}; problems: {len(problems)}")
    for pr in problems: print("  !", pr)
    if problems or not apply:
        return
    # ── apply ──
    cur = rj(CUR)
    for k, u in NEW_TOPIC_ROUTES.items():
        assert k not in cur["clozeTopicUnitMap"], k; cur["clozeTopicUnitMap"][k] = u
    for pack, (level, vt, ct) in PACKS.items():
        key = f"{level.lower()}:{ct.lower()}"; assert key in cur["clozeTopicUnitMap"], key
    seg = rj(SEG); auth = rj(AUTH)
    owner = {}
    for c in seg["contentClusters"]:
        for ref in c["contentReferences"]:
            if ref["kind"] == "vocabPack": owner.setdefault(ref["id"], c["id"])
    cl2seg = {cid: s for s in seg["segments"] for cid in s["contentClusterIds"]}
    direct = {r["id"]: r for r in auth["contentReferences"] if r["kind"] == "vocabPack"}
    cloze = rj(CLOZE); satz = rj(SATZ)
    nc = {lv: max(int(i["id"].rsplit("_", 1)[1]) for i in cloze["items"] if i["id"].startswith(f"cloze_{lv}_")) + 1 for lv in ("a1", "a2", "b1", "b2")}
    ns = {lv: max(int(i["id"].rsplit("_", 1)[1]) for i in satz["items"] if i["id"].startswith(f"satz_{lv}_")) + 1 for lv in ("a1", "a2", "b1", "b2")}
    inh = []; new_cloze = []; new_satz = []
    for pack, level, ctopic, r, ans in plan:
        lvl = level.lower(); d = direct[pack]; s = cl2seg[owner[pack]]
        assert d["courseUnitId"] == s["parentCourseUnitId"] and d["level"] == lvl == s["level"], (pack, d, s["id"])
        unit = d["courseUnitId"]; ex = r["example_korean"]
        sentence = ex.replace(ans, BLANK, 1)
        particle = find_particle_after_blank(sentence); need = PARTICLE_BATCHIM[particle] if particle else None
        arow = info.get((lvl, ans), r)
        pos = arow["pos_de"]; keys = [(lvl, pos)] if pos in ("Nomen", "Verb", "Adjektiv", "Adverb") else [(lvl, "Nomen")]
        if ans != r["korean"] and (lvl, ans) not in info:
            # conjugated answer: parallel forms of same-level verbs/adjectives
            vpool = [x["korean"] for k in ((lvl, "Verb"), (lvl, "Adjektiv")) for x in pool.get(k, []) if x["korean"].endswith("다") and " " not in x["korean"]]
            forms = set()
            if ans.endswith("고"):
                forms = {v[:-1] + "고" for v in vpool}
            elif ans.endswith("는"):
                forms = {v[:-1] + "는" for v in vpool if not v.endswith("하다") or True}
            elif ans.endswith("해") or ans.endswith("해서") or ans.endswith("해요") or ans.endswith("했어요"):
                suffix = next(e for e in ("했어요", "해서", "해요", "해") if ans.endswith(e))
                forms = {v[:-2] + suffix for v in vpool if v.endswith("하다")}
            if len(forms) < 6:
                tail = ans[-2:]
                forms |= {i["answer"] for i in cloze["items"] if i["level"] == lvl and i["answer"].endswith(tail)}
            if len(forms) < 6 and ans.endswith("서"):
                forms |= {v[:-2] + "해서" for v in vpool if v.endswith("하다")}
            if len(forms) < 6 and ans.endswith("요"):
                forms |= {i["answer"] for i in cloze["items"] if i["level"] == lvl and i["answer"].endswith("요")}
            if len(forms) < 6:
                forms |= {i["answer"] for i in cloze["items"] if i["level"] == lvl and i["answer"].endswith(ans[-1])}
            if len(forms) < 6:
                forms |= {v[:-2] + "해요" for v in vpool if v.endswith("하다")}
            cands = sorted({f for f in forms if f != ans and syl(f) >= 2 and f not in sentence and f not in ex and f != r["korean"]})
        else:
            cands = sorted({x["korean"] for k in keys for x in pool.get(k, []) if x["korean"] != ans and x["korean"] not in sentence and x["topic"] != arow["topic"] and (need is None or has_batchim(x["korean"]) == need) and x["korean"] not in ex})
        rng = random.Random(int(hashlib.sha1(r["id"].encode()).hexdigest(), 16)); rng.shuffle(cands)
        ds = cands[:3]; assert len(ds) == 3, (r["id"], len(cands))
        cid = f"cloze_{lvl}_{nc[lvl]:04d}"; nc[lvl] += 1
        new_cloze.append({"id": cid, "level": lvl, "topic": ctopic, "fullKo": ex, "answer": ans, "sentenceKo": sentence, "de": r["example_german"], "en": r["example_english"], "distractors": ds, "courseUnitId": unit})
        inh.append({"kind": "cloze", "id": cid, "sourceKind": "vocabPack", "sourceId": pack, "sourceVocabId": r["id"], "sourceVocabFingerprintSha256": "0" * 64, "level": lvl, "canDoSegmentId": s["id"], "courseUnitId": unit})
        toks = {re.sub(r"[ !?.,]", "", t) for t in ex.split(" ")}
        sc = sorted({x["korean"] for x in pool.get((lvl, "Nomen"), []) if x["korean"] not in toks and x["korean"] not in ex and x["topic"] != r["topic"]}); rng.shuffle(sc)
        sid = f"satz_{lvl}_{ns[lvl]:04d}"; ns[lvl] += 1
        new_satz.append({"id": sid, "level": lvl, "targetKo": ex, "promptDe": r["example_german"], "promptEn": r["example_english"], "vocabKo": r["korean"], "distractors": sc[:2], "courseUnitId": unit})
        inh.append({"kind": "satz", "id": sid, "sourceKind": "vocabPack", "sourceId": pack, "sourceVocabId": r["id"], "sourceVocabFingerprintSha256": "0" * 64, "level": lvl, "canDoSegmentId": s["id"], "courseUnitId": unit})
    from relevel_bundle import _refresh_game_meta
    rows.extend(new_rows); cloze["items"].extend(new_cloze); satz["items"].extend(new_satz)
    _refresh_game_meta(cloze, "items"); _refresh_game_meta(satz, "items")
    lst = auth["coverage"]["inheritedContentReferences"]; existing = {(x["kind"], x["id"]) for x in lst}
    for row in inh:
        assert (row["kind"], row["id"]) not in existing; insert_sorted(lst, row, key=lambda x: (x["kind"], x["id"]))
    for kind in ("cloze", "satz"): auth["coverage"]["inheritedReferenceCounts"][kind] = sum(1 for x in lst if x["kind"] == kind)
    man = rj(AUDIT); counts = {"vocab": len(rows), "cloze": len(cloze["items"]), "satz": len(satz["items"])}
    for src in man["sources"]:
        if src["kind"] in counts: src["count"] = counts[src["kind"]]
    wr_vocab(rows); wj(CLOZE, cloze); wj(SATZ, satz); wj(AUTH, auth); wj(CUR, cur); wj(AUDIT, man)
    print("counts", counts, "new cloze", len(new_cloze), "new satz", len(new_satz))
    drafts = ROOT / "tools/content_factory/drafts"; review = ROOT / "tools/content_factory/review"
    with (drafts / "c3_batch24_vocab_supplement.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator="\n"); w.writeheader(); w.writerows(new_rows)
    with (review / "c3_batch24_vocab_supplement.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n"); w.writerow(["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"])
        for r in new_rows:
            w.writerow([r["id"], r["level"], r["korean"], r["german"], r["english"], f"rights: original_clean_room; pack={r['pack_id']}; order={r['pack_order']}; boss=false; seed: NIKL 등급 목록(KOGL 1유형) 표제어 선택만; 소형 팩(<8단어) 보충", "approved", MEMO])
    wj(drafts / "c2_batch24_cloze_supplement.json", {"items": new_cloze}); wj(drafts / "c2_batch24_satz_supplement.json", {"items": new_satz})
    with (review / "c2_batch24_cloze_supplement.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n"); w.writerow(["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"])
        for it, row in zip(new_cloze, [x for x in inh if x["kind"] == "cloze"]):
            w.writerow([it["id"], it["level"], it["fullKo"], it["de"], it["en"], f"answer={it['answer']}; topic={it['topic']}; unit={it['courseUnitId']}; derived from {row['sourceVocabId']}", "approved", MEMO])
    with (review / "c2_batch24_satz_supplement.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n"); w.writerow(["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"])
        for it, row in zip(new_satz, [x for x in inh if x["kind"] == "satz"]):
            w.writerow([it["id"], it["level"], it["targetKo"], it["promptDe"], it["promptEn"], f"vocabKo={it['vocabKo']}; unit={it['courseUnitId']}; source {row['sourceVocabId']}", "approved", MEMO])
    proc = subprocess.run([sys.executable, "tool/refresh_can_do_vocab_fingerprints.py"], cwd=ROOT, capture_output=True, text=True); print(proc.stdout.strip()[-300:], proc.stderr.strip()[-300:])
    from relevel_bundle import check_can_do_consistency
    print("can-do issues:", check_can_do_consistency(ROOT))
    from relevel_vocab import write_pack_map
    write_pack_map(rd_vocab(), ROOT / "docs/data/vocab_pack_map.md")
    print("done")


E_MAP = {"자동차":"car","역":"station","공항":"airport","출발":"departure","도착":"arrival","타다":"to ride, to take (transport)","내리다":"to get off",
 "돈":"money","원":"won (currency)","번호":"number","기다리다":"to wait","다시":"again, once more","단어":"word, vocabulary","사전":"dictionary",
 "학년":"school year, grade","복습":"review (of a lesson)","예습":"preparation (before a lesson)","국":"soup","접시":"plate","설탕":"sugar",
 "끓이다":"to boil","볶다":"to stir-fry","굽다":"to grill, to bake","마트":"supermarket","상자":"box","디자인":"design","반바지":"shorts","단추":"button","모양":"shape",
 "심심하다":"to be bored","편하다":"to be comfortable","즐겁다":"to be enjoyable","약속":"appointment; promise","계획":"plan","시간표":"timetable","비다":"to be free (time); to be empty","가능하다":"to be possible","휴일":"day off, holiday",
 "하늘색":"sky blue","진하다":"to be dark (color); to be strong (coffee)","두껍다":"to be thick",
 "부담":"burden; pressure","협조":"cooperation","출근":"going to work","퇴근":"leaving work",
 "격려하다":"to encourage","위로하다":"to comfort","존중하다":"to respect","감정":"emotion, feeling","오해":"misunderstanding","화해하다":"to make up, to reconcile",
 "개념":"concept","요소":"element, factor","원리":"principle","가치":"value","본질":"essence","특징":"feature, characteristic",
 "학문":"scholarship, academic study","강의":"lecture","지식":"knowledge","과제":"assignment","성과":"result, achievement"}

if __name__ == "__main__":
    main(apply=(sys.argv[1] == "apply"))
