#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACTS = ROOT / "docs" / "textbook_project" / "data" / "ONE_A_UNIT_CONTRACTS_20261006.json"
ERRORS = ROOT / "docs" / "textbook_project" / "data" / "A1_LEARNER_ERROR_MATRIX_EN_DE_20261006.json"
LEARNER_META = ROOT / "docs" / "textbook_project" / "data" / "ONE_A_LEARNER_FACING_META_EN_DE_20261006.json"
SCENARIOS = ROOT / "assets" / "data" / "scenarios_a1.json"
OUT_ROOT = ROOT / "docs" / "textbook_project" / "pilot_1A"

SKIP = {"a1_04_order_request_object"}

SPEAKER_LABELS = {
    "en": {
        "official": "Official",
        "user": "Learner",
        "server": "Staff",
        "clerk": "Staff",
        "staff": "Staff",
        "friend": "Friend",
        "passerby": "Passerby",
        "driver": "Driver",
    },
    "de": {
        "official": "Beamte/r",
        "user": "Lernende/r",
        "server": "Mitarbeiter/in",
        "clerk": "Mitarbeiter/in",
        "staff": "Mitarbeiter/in",
        "friend": "Freund/in",
        "passerby": "Passant/in",
        "driver": "Fahrer/in",
    },
}

DE_RISK_NOTES = {
    "DE-A1-E-ESEO-EURO": (
        "Koreanische Orts- und Richtungs-Partikeln direkt deutschen Präpositionen oder Kasus zuordnen.",
        "Mit Ziel, Aufenthaltsort, Handlungsort und Richtung als Bedeutungsräumen arbeiten; keine 1:1-Präpositionstabelle."
    ),
    "DE-A1-PARTICLE-CASE": (
        "Koreanische 조사 wie deutsche Kasusartikel behandeln.",
        "Explizit markieren: 조사 ist kein Kasusartikel. Formen in Prädikatsrahmen und echten Situationen lernen."
    ),
    "DE-A1-TOPIC-FOCUS": (
        "Für 은/는 und 이/가 nach einem deutschen Kasusäquivalent suchen.",
        "Über Frage-Antwort-Kontext und Informationsstruktur erklären, nicht über Nominativ/Akkusativ."
    ),
    "DE-A1-DU-SIE": (
        "존댓말 automatisch mit Sie und 반말 automatisch mit du gleichsetzen.",
        "Beide sozialen Systeme getrennt darstellen; koreanisches 해요체 kann je nach Beziehung natürlich mit deutschem du zusammenpassen."
    ),
    "DE-A1-HONORIFIC-SUBJECT": (
        "Für -(으)시- ein deutsches Pronomen- oder Höflichkeitsäquivalent suchen.",
        "Respekt gegenüber der handelnden Person getrennt von du/Sie und vom Gesprächspartner erklären."
    ),
    "DE-A1-WORDORDER": (
        "Die Eselsbrücke 'Koreanisch ist wie ein deutscher Nebensatz' zu weit verallgemeinern.",
        "Verbfinalität höchstens als vorläufige Analogie nutzen; koreanische Satzstruktur als eigenes System aufbauen."
    ),
    "DE-A1-SUBJECT-OMISSION": (
        "ich/du mechanisch in koreanische Sätze einsetzen, obwohl der Kontext die Person bereits klar macht.",
        "Dialogketten zeigen, in denen das Thema einmal gesetzt und danach natürlich ausgelassen wird."
    ),
    "DE-A1-COUNTERS": (
        "Die deutsche Struktur Zahl + Nomen direkt auf Koreanisch übertragen.",
        "Häufige Mengen als Chunks lernen, z. B. 한 잔, 두 명, 세 시, bevor eine große Zähleinheitentabelle kommt."
    ),
}

def load_json(p: Path):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def bullets(items):
    return "\n".join(f"- {x}" for x in items)

def risk_block(ids, lookup, lang):
    if not ids:
        return "- No specific transfer risk recorded." if lang == "en" else "- Kein spezielles Transfer-Risiko vermerkt."
    lines=[]
    for rid in ids:
        if lang == "de":
            risk, response = DE_RISK_NOTES[rid]
            lines.append(f"### {rid}\n\n**Risiko:** {risk}\n\n**Lernstrategie:** {response}")
        else:
            r=lookup[rid]
            lines.append(f"### {rid}\n\n**Risk:** {r['risk']}\n\n**Teaching response:** {r['pedagogy']}")
    return "\n\n".join(lines)

def dialogue_md(dialogue, lang):
    key={"en":"en","de":"de"}[lang]
    out=[]
    for line in dialogue:
        raw_speaker=line.get("speaker","speaker")
        speaker=SPEAKER_LABELS.get(lang,{}).get(raw_speaker,raw_speaker.replace("_"," ").title())
        ko=line.get("ko","").strip()
        tr=line.get(key,"").strip()
        out += [f"**{speaker}**", ko, f"*{tr}*", ""]
    return "\n".join(out).strip()

def audio_dialogue(dialogue):
    result=[]
    for line in dialogue:
        result.append({
            "speaker": line.get("speaker","speaker"),
            "displaySurfaceKo": line.get("ko",""),
            "spokenSurfaceKo": line.get("ko",""),
            "performanceCue": ["natural conversational delivery"],
            "en": line.get("en",""),
            "de": line.get("de",""),
        })
    return result

def render_student(u, scenario, lang, err_lookup, learner_meta):
    is_en=lang=="en"
    meta=learner_meta[u["unitId"]][lang]
    title=u["titleEn"] if is_en else u["titleDe"]
    intro="By the end of this unit, you can:" if is_en else "Nach dieser Einheit kannst du:"
    scene_label="Core scene" if is_en else "Kernszene"
    prod_label="What you should be able to say" if is_en else "Das solltest du selbst sagen können"
    rec_label="Understand first — do not overlearn yet" if is_en else "Zuerst verstehen — noch nicht überlernen"
    native_label="Living Korean"
    sound_label="Sound focus" if is_en else "Aussprachefokus"
    interaction_label="Interaction mission" if is_en else "Interaktionsaufgabe"
    assess_label="Exit task" if is_en else "Abschlussaufgabe"
    recycle_label="You will meet this again" if is_en else "Das kommt später wieder"
    risk_ids=u.get("enLearnerRisks",[]) if is_en else u.get("deLearnerRisks",[])

    can_do="\n".join(f"- {x}" for x in meta["canDo"])
    prod="\n".join(f"- **{x}**" for x in u["coreChunks"])
    if is_en:
        rec="\n".join(
            f"- **{x['form']}** — {x['reason']}"
            for x in u.get("recognitionOnly",[])
        ) or "- No extra recognition-only form in this unit."
        grammar="\n".join(
            f"- **{x['form']}** — {x['function']}"
            for x in u["productiveGrammar"]
        )
        pron="\n".join(f"- {x}" for x in u["pronunciation"])
    else:
        rec="\n".join(
            f"- **{x['form']}** — zunächst im Kontext erkennen"
            for x in u.get("recognitionOnly",[])
        ) or "- Keine zusätzliche reine Erkennungsform in dieser Einheit."
        grammar="\n".join(
            f"- **{x['form']}** — aktive Form dieser Einheit"
            for x in u["productiveGrammar"]
        )
        pron="\n".join(f"- {x}" for x in u["coreChunks"][:3])
    prag="\n".join(f"- {x}" for x in meta["pragmatics"])
    culture="\n".join(f"- {x}" for x in meta["culture"])
    inp="\n".join(f"- {x}" for x in meta["input"])
    outp="\n".join(f"- {x}" for x in meta["output"])
    read="\n".join(f"- {x}" for x in meta["reading"])
    write="\n".join(f"- {x}" for x in meta["writing"])

    if is_en:
        guidance = f"""# Korean 1A · Unit {u['order']:02d}
# {title}

## {intro}

{can_do}

## Why this unit exists

{meta['problem']}

## 1. {scene_label}

{dialogue_md(scenario['dialog'], 'en')}

### First task

Do not translate every word. Identify:
- who is speaking;
- what the immediate goal is;
- which line solves the problem.

## 2. {prod_label}

{prod}

These are the productive chunks for this unit.

### Productive grammar

{grammar}

The goal is not to memorize labels. Use the forms to solve the scene.

## 3. {rec_label}

{rec}

Authentic input can contain grammar above your current production target. Understanding it does not mean you must produce it now.

## 4. {native_label}

### Pragmatics

{prag}

### Culture/context

{culture}

Avoid the rule “Koreans always say X.” Learn who says what, to whom, and why.

## 5. English-speaker transfer notes

{risk_block(risk_ids, err_lookup, 'en')}

## 6. {sound_label}

{pron}

## 7. Input mission

{inp}

## 8. Output mission

{outp}

## 9. Reading

{read}

## 10. Writing

{write}

## 11. {interaction_label}

{meta['interaction']}

## 12. {assess_label}

You must be able to produce:

{bullets(u['assessment']['mustProduce'])}

You must be able to recognize:

{bullets(u['assessment']['mustRecognize'])}

**Success:** {meta['success']}

## Production ceiling

{meta['ceiling']}

## {recycle_label}

This unit is part of a spaced-recycling curriculum. The target language returns in later contexts.
"""
    else:
        guidance = f"""# Koreanisch 1A · Einheit {u['order']:02d}
# {title}

## {intro}

{can_do}

## Warum diese Einheit existiert

{meta['problem']}

## 1. {scene_label}

{dialogue_md(scenario['dialog'], 'de')}

### Erste Aufgabe

Übersetze nicht sofort jedes Wort. Finde zuerst heraus:
- wer spricht;
- welches unmittelbare Ziel die Personen haben;
- welcher Satz das Problem löst.

## 2. {prod_label}

{prod}

Diese Chunks gehören zur aktiven Produktion dieser Einheit.

### Produktive Grammatik

{grammar}

Die Bezeichnungen sind nicht das Lernziel. Benutze die Formen, um die Situation zu lösen.

## 3. {rec_label}

{rec}

Authentischer Input kann Formen enthalten, die noch über deinem aktiven Produktionsziel liegen. Verstehen ist hier genug.

## 4. {native_label}

### Pragmatik

{prag}

### Kultur/Kontext

{culture}

Lerne nicht „Koreaner sagen immer X“, sondern Beziehung, Situation und Funktion.

## 5. Hinweise für Deutschsprachige

{risk_block(risk_ids, err_lookup, 'de')}

## 6. {sound_label}

{pron}

## 7. Hör-/Inputaufgabe

{inp}

## 8. Sprech-/Outputaufgabe

{outp}

## 9. Lesen

{read}

## 10. Schreiben

{write}

## 11. {interaction_label}

{meta['interaction']}

## 12. {assess_label}

Das solltest du produzieren können:

{bullets(u['assessment']['mustProduce'])}

Das solltest du erkennen können:

{bullets(u['assessment']['mustRecognize'])}

**Erfolg:** {meta['success']}

## Produktionsgrenze

{meta['ceiling']}

## {recycle_label}

Die Sprache dieser Einheit wird später in neuen Situationen wiederverwendet.
"""
    return guidance

def render_workbook(u):
    chunks=u["coreChunks"]
    funcs=u["targetFunctions"]
    return f"""# Korean 1A Unit {u['order']:02d} Workbook
# {u['titleKo']}

Status: DRAFT_MATERIALIZED

## A. Meaning first

Read the core chunks and match each one to its communicative job.

{bullets(chunks)}

Functions:
{bullets(funcs)}

## B. Rebuild the chunk

Cover the model and rebuild three core chunks from memory.

1. ______________________________
2. ______________________________
3. ______________________________

## C. Controlled variation

Change one meaningful element in each model:
- person / item / place / time / channel / condition as appropriate to the unit.

Do not change grammar just to make the sentence harder.

## D. Recognition-only check

The following may appear in authentic input but are not all active targets yet:

{bullets([x["form"] for x in u.get("recognitionOnly",[])]) if u.get("recognitionOnly") else "- none"}

For each, write only:
1. who might say it;
2. what it does in the scene.

## E. Listening grid

Listen once for meaning, then again for form.

| Information | Answer |
|---|---|
| Who is speaking? | |
| What is the immediate goal? | |
| Key word/chunk | |
| What happens next? | |

## F. Interaction

{u['interactionTask']}

## G. Delayed retrieval

Close the unit.

Produce:
{bullets(u['assessment']['mustProduce'])}

Recognize:
{bullets(u['assessment']['mustRecognize'])}

## H. Self-check

I can do the task without translating every sentence first:

- [ ] not yet
- [ ] with support
- [ ] independently
"""

def render_workbook_localized(u, lang, learner_meta):
    meta=learner_meta[u["unitId"]][lang]
    chunks=u["coreChunks"]
    rec=[x["form"] for x in u.get("recognitionOnly",[])]
    produce=u["assessment"]["mustProduce"]
    recognize=u["assessment"]["mustRecognize"]

    if lang=="en":
        return f"""# Korean 1A Unit {u['order']:02d} Workbook
# {u['titleEn']}

## A. Meaning first

Match the Korean chunks to what they do in the situation.

{bullets(chunks)}

Do not translate word by word first. Identify the communicative job.

## B. Rebuild from memory

Cover the model and rebuild three useful chunks.

1. ______________________________
2. ______________________________
3. ______________________________

## C. Controlled variation

Change one meaningful element that fits the unit:
- person;
- item;
- place;
- time;
- channel;
- condition.

Use only a change that makes sense in this scene.

## D. Understand before producing

These forms may appear in authentic input:

{bullets(rec) if rec else "- No extra recognition-only form in this unit."}

For each form, write:
1. who says it;
2. what it does.

You do not need to produce every form yet.

## E. Listening grid

Listen once for meaning and again for form.

| Information | Answer |
|---|---|
| Who is speaking? | |
| Immediate goal | |
| Key Korean chunk | |
| What happens next? | |

## F. Interaction

{meta['interaction']}

## G. Delayed retrieval

Close the student pages.

Produce:
{bullets(produce)}

Recognize:
{bullets(recognize)}

## H. Self-check

I can complete the communicative task:

- [ ] not yet
- [ ] with support
- [ ] independently

**Success criterion:** {meta['success']}
"""
    return f"""# Koreanisch 1A Einheit {u['order']:02d} Arbeitsbuch
# {u['titleDe']}

## A. Zuerst die Funktion verstehen

Ordne die koreanischen Chunks ihrer Funktion in der Situation zu.

{bullets(chunks)}

Nicht zuerst Wort für Wort übersetzen. Erkenne, was der Satz im Gespräch tut.

## B. Aus dem Gedächtnis aufbauen

Verdecke das Modell und rekonstruiere drei nützliche Chunks.

1. ______________________________
2. ______________________________
3. ______________________________

## C. Kontrollierte Variation

Ändere genau ein sinnvolles Element:
- Person;
- Gegenstand;
- Ort;
- Zeit;
- Kontaktkanal;
- Bedingung.

Die Änderung muss zur Situation passen.

## D. Erst verstehen, später produzieren

Diese Formen können im authentischen Input vorkommen:

{bullets(rec) if rec else "- Keine zusätzliche reine Erkennungsform in dieser Einheit."}

Notiere zu jeder Form:
1. wer sie sagt;
2. welche Funktion sie hat.

Du musst sie noch nicht alle selbst produzieren.

## E. Hör-Raster

Höre einmal auf die Bedeutung und ein zweites Mal auf die Form.

| Information | Antwort |
|---|---|
| Wer spricht? | |
| Unmittelbares Ziel | |
| Wichtiger koreanischer Chunk | |
| Was passiert danach? | |

## F. Interaktion

{meta['interaction']}

## G. Verzögertes Abrufen

Schließe die Erklärungsseiten.

Produzieren:
{bullets(produce)}

Erkennen:
{bullets(recognize)}

## H. Selbstkontrolle

Ich kann die kommunikative Aufgabe lösen:

- [ ] noch nicht
- [ ] mit Hilfe
- [ ] selbstständig

**Erfolgskriterium:** {meta['success']}
"""

def render_teacher(u, err_lookup):
    enrisks="\n".join(f"- **{rid}**: {err_lookup[rid]['risk']}" for rid in u.get("enLearnerRisks",[])) or "- none"
    derisks="\n".join(f"- **{rid}**: {err_lookup[rid]['risk']}" for rid in u.get("deLearnerRisks",[])) or "- none"
    prod="\n".join(f"- {x['form']}: {x['function']}" for x in u["productiveGrammar"])
    rec="\n".join(f"- {x['form']}: {x['reason']}" for x in u.get("recognitionOnly",[])) or "- none"
    return f"""# Teacher Guide — Korean 1A Unit {u['order']:02d}
# {u['titleKo']}

Status: DRAFT_MATERIALIZED

## Can-do

{bullets(u['canDo'])}

## Communicative problem

{u['communicativeProblem']}

## Relationship / register

- Primary relationship: {u['relationship']['primary']}
- Korean register: {u['relationship']['registerKo']}
- EN default: {u['relationship']['enAddressDefault']}
- DE default: {u['relationship']['deAddressDefault']}

## Productive language

{prod}

## Recognition/context only

{rec}

## Teaching order

1. play/read the scene;
2. establish meaning;
3. notice core chunks;
4. explain only necessary form;
5. contrast native-use variation;
6. address EN/DE transfer risk;
7. run interaction task;
8. delayed retrieval.

## EN-L1 risk

{enrisks}

## DE-L1 risk

{derisks}

## Pragmatics

{bullets(u['pragmatics'])}

## Culture caution

{bullets(u['culture'])}

Do not convert contextual patterns into universal rules.

## Pronunciation

{bullets(u['pronunciation'])}

## Assessment

Must produce:
{bullets(u['assessment']['mustProduce'])}

Must recognize:
{bullets(u['assessment']['mustRecognize'])}

Success:
{u['assessment']['success']}

## Production ceiling

{u['productionCeiling']}

## Recycling

From:
{bullets(u.get('recycleFrom',[])) if u.get('recycleFrom') else "- entry unit"}

Into:
{bullets(u.get('recycleInto',[])) if u.get('recycleInto') else "- later 1A/1B contexts"}

## Editorial status

This package is automatically materialized from a locked unit contract and canonical scenario.
It requires a unit-specific editorial pass before becoming a reference vertical slice.
"""

def main():
    contracts=load_json(CONTRACTS)
    errors=load_json(ERRORS)
    learner_meta=load_json(LEARNER_META)["units"]
    scenarios=load_json(SCENARIOS)["scenarios"]
    scen_by_id={x["id"]:x for x in scenarios}
    err_lookup={x["id"]:x for lang in ("en","de") for x in errors[lang]}

    made=[]
    for u in contracts["units"]:
        if u["unitId"] in SKIP:
            continue
        folder=OUT_ROOT/f"unit{u['order']:02d}"
        data_dir=folder/"data"
        data_dir.mkdir(parents=True,exist_ok=True)

        sid=u["authoritativeScenarioIds"][0]
        scenario=scen_by_id[sid]

        manifest={
            "schemaVersion":1,
            "date":"2026-10-06",
            "status":"DRAFT_MATERIALIZED_NO_UNIT_EDITORIAL_PASS",
            "unitId":u["unitId"],
            "order":u["order"],
            "titleKo":u["titleKo"],
            "unitContract":"docs/textbook_project/data/ONE_A_UNIT_CONTRACTS_20261006.json",
            "authoritativeScenarioId":sid,
            "supplementarySourceIds":u.get("supplementarySourceIds",[]),
            "nativeUsageTopics":u["nativeUsageTopics"],
            "enLearnerRisks":u.get("enLearnerRisks",[]),
            "deLearnerRisks":u.get("deLearnerRisks",[]),
            "productiveGrammar":u["productiveGrammar"],
            "recognitionOnly":u.get("recognitionOnly",[]),
            "surfacePolicy":{
                "displayVsSpokenSeparated":True,
                "romanization":False,
                "ttsOwner":"Jin",
                "audioGenerated":False,
            },
            "editorialRequirements":[
                "unit-specific Korean editorial pass",
                "EN pedagogy pass",
                "DE pedagogy pass",
                "practice-bank selection",
                "adult learner pilot",
            ],
        }
        (data_dir/"UNIT_MANIFEST.json").write_text(
            json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",
            encoding="utf-8"
        )
        audio={
            "schemaVersion":1,
            "unitId":u["unitId"],
            "status":"SCRIPT_ONLY_NO_TTS_GENERATION",
            "ttsOwner":"Jin",
            "tracks":[{
                "trackId":f"u{u['order']:02d}_core_dialogue",
                "type":"dialogue",
                "relationshipContext":scenario.get("relationshipContext",""),
                "lines":audio_dialogue(scenario.get("dialog",[])),
            }],
        }
        (data_dir/"AUDIO_SCRIPT.json").write_text(
            json.dumps(audio,ensure_ascii=False,indent=2)+"\n",
            encoding="utf-8"
        )
        (folder/"STUDENT_EN.md").write_text(render_student(u,scenario,"en",err_lookup,learner_meta),encoding="utf-8")
        (folder/"STUDENT_DE.md").write_text(render_student(u,scenario,"de",err_lookup,learner_meta),encoding="utf-8")
        (folder/"WORKBOOK.md").write_text(render_workbook(u),encoding="utf-8")
        (folder/"WORKBOOK_EN.md").write_text(render_workbook_localized(u,"en",learner_meta),encoding="utf-8")
        (folder/"WORKBOOK_DE.md").write_text(render_workbook_localized(u,"de",learner_meta),encoding="utf-8")
        (folder/"TEACHER_GUIDE.md").write_text(render_teacher(u,err_lookup),encoding="utf-8")
        made.append(u["unitId"])

    print(json.dumps({"materialized":len(made),"units":made},ensure_ascii=False))

if __name__=="__main__":
    main()
