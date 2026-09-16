#!/usr/bin/env python3
"""R8 round 4 (2026-09-16, PR #362 review) -- German orthography scan for
`assets/data/usage_notes.json`.

Two passes over every DE field (nuance/situation/patterns/collocations/
contrasts/examples), reusable for future usage_notes batches:

1. ASCII-umlaut/eszett substitution candidates -- word-boundary matches on
   `ae|oe|ue` plus a curated ss->ss ("gross", "heisst", ...) list, with an
   allowlist of genuinely-correct German words that happen to contain
   those letter sequences without being an umlaut substitution (e.g.
   "schaue" from "schauen", "neue", "dauerhaft"). These are almost always
   real bugs once whitelisted words are excluded.

2. "Manual judgment" homograph pairs -- word pairs where the umlaut-
   stripped ASCII form is ALSO a real German word, so pass 1 cannot catch
   them by pattern alone (e.g. "druckt" [prints] vs the intended "drückt"
   [presses/expresses]). This pass just lists every occurrence of the
   stripped form for a human (or model) to judge in context -- most hits
   are correct as written (schon/wurde/konnte/wurde/Bruder are common,
   legitimately-unumlauted German words), so do NOT bulk-replace this
   list; read each hit's sentence.

Usage:
    PYTHONIOENCODING=utf-8 python tools/content_factory/scan_usage_notes_de.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
USAGE_NOTES_JSON = ROOT / "assets" / "data" / "usage_notes.json"

# -- pass 1: ASCII ae/oe/ue -> a/o/u-umlaut substitution candidates -------

LEFTOVER_RE = re.compile(r"\b\w*(?:ae|oe|ue)\w*\b")

# Genuinely-correct German (or loanword/English) tokens that legitimately
# contain "ae"/"oe"/"ue" as plain letters, not an umlaut substitution.
# Extend this list rather than removing the pattern check.
SAFE_AEOEUE_WORDS = {
    "schaue", "schauen", "schaut", "schaust",
    "Frauen", "Frau", "genauen", "genaue", "genau", "genauer",
    "neue", "neuen", "neuer", "neues", "Neue", "Neues", "erneuten", "erneut",
    "Cafe", "Café", "bauen", "gebaut", "aufbauen", "Baustelle",
    "Museum", "Ideen", "Idee",
    "freue", "freuen", "freut",
    "gedauert", "dauern", "dauert", "dauerte", "dauerhaft",
    "individuelle", "individuellen", "individuell",
    "anvertrauen", "vertrauen", "Vertrauen",
    "anzufeuern", "Anfeuern", "anfeuern", "Feuer",
    "Trauer", "trauern",
    "aktuelle", "aktuellen", "aktueller",
    "zuerst", "Zuerst",
    "anzuerkennen", "erkennen", "anerkennen",
    "bedauerlichen", "bedauerliche", "bedauern",
}

SS_TO_ESZETT_HITS_RE = re.compile(
    r"\b\w*(gross|schliess|drauss|strasse|spass\w|bloss|heisst)\w*\b|"
    r"\bausser\b|\bausserhalb\b|\bBussgeld\b|\bVerstoss\w*\b|\bGesetzesverstoss\b",
    re.IGNORECASE,
)

# -- pass 2: homograph pairs (umlaut-stripped form is ALSO a real word) ---
# (stripped_form, intended_umlaut_form, one-line gloss of the risk)
HOMOGRAPH_PAIRS = [
    ("druckt", "drückt", "druckt = prints; drückt ... aus = expresses"),
    ("schon", "schön", "schon = already (adverb); schön = beautiful/nice (adjective)"),
    ("konnte", "könnte", "konnte = could (Präteritum); könnte = could (Konjunktiv II)"),
    ("wurde", "würde", "wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)"),
    ("fordern", "fördern", "fordern = to demand; fördern = to promote/support"),
    ("Zuge", "Züge", "Zuge = (rare, dative of Zug sg.); Züge = trains (plural)"),
    ("Bruder", "Brüder", "Bruder = brother (singular); Brüder = brothers (plural)"),
    ("Mutter", "Mütter", "Mutter = mother (singular); Mütter = mothers (plural)"),
    ("Tur", "Tür", "Tur = (not standard German); Tür = door"),
    ("Kuche", "Küche", "Kuche = (not standard German); Küche = kitchen"),
    ("Grosse", "Größe", "Grosse = big one/large person; Größe = size"),
    ("Losung", "Lösung", "Losung = slogan/password; Lösung = solution"),
    ("Hohe", "Höhe", "Hohe = high one/high (adj. inflected); Höhe = height"),
    ("Muhe", "Mühe", "Muhe = (not standard German, or 'moo'); Mühe = effort"),
    ("Nahe", "Nähe", "Nahe = close (adj., rare noun use); Nähe = vicinity"),
    ("Gebuhr", "Gebühr", "Gebuhr = (not standard German); Gebühr = fee"),
    ("Prufung", "Prüfung", "Prufung = (not standard German); Prüfung = exam/check"),
    ("Kundigung", "Kündigung", "Kundigung = (not standard German); Kündigung = termination/notice"),
    ("Uberweisung", "Überweisung", "Uberweisung = (not standard German); Überweisung = bank transfer"),
    ("Uberstunden", "Überstunden", "Uberstunden = (not standard German); Überstunden = overtime"),
    ("Eroffnung", "Eröffnung", "Eroffnung = (not standard German); Eröffnung = opening"),
    ("Anderung", "Änderung", "Anderung = (not standard German); Änderung = change/amendment"),
    ("Arger", "Ärger", "Arger = (not standard German); Ärger = annoyance/trouble"),
    ("offnen", "öffnen", "offnen = (not standard German); öffnen = to open"),
    ("gultig", "gültig", "gultig = (not standard German); gültig = valid"),
    ("naturlich", "natürlich", "naturlich = (not standard German); natürlich = naturally/of course"),
    ("moglich", "möglich", "moglich = (not standard German); möglich = possible"),
    ("hoflich", "höflich", "hoflich = (not standard German); höflich = polite"),
    ("taglich", "täglich", "taglich = (not standard German); täglich = daily"),
    ("fruh", "früh", "fruh = (not standard German); früh = early"),
    ("spater", "später", "spater = (not standard German); später = later"),
]


def de_fields(note: dict):
    """Yield (field_label, text) for every DE string in one note."""
    yield "nuance", note.get("nuance", {}).get("de", "")
    yield "situation", note.get("situation", {}).get("de", "")
    for i, p in enumerate(note.get("patterns", []) or []):
        yield f"patterns[{i}]", p.get("de", "")
    for i, c in enumerate(note.get("collocations", []) or []):
        yield f"collocations[{i}]", c.get("de", "")
    for i, c in enumerate(note.get("contrasts", []) or []):
        yield f"contrasts[{i}]", c.get("de", "")
    for i, ex in enumerate(note.get("examples", []) or []):
        yield f"examples[{i}]", ex.get("de", "")


def run() -> tuple[str, dict]:
    if not USAGE_NOTES_JSON.exists():
        return "usage_notes.json not found -- nothing to scan.\n", {"leftover": 0, "ss": 0, "homograph": 0}
    root = json.loads(USAGE_NOTES_JSON.read_text(encoding="utf-8"))
    notes = root.get("notes", []) if isinstance(root, dict) else []

    leftover_hits = []
    ss_hits = []
    homograph_hits = []

    for note in notes:
        if not isinstance(note, dict):
            continue
        note_id = note.get("id", "?")
        for field, text in de_fields(note):
            if not text:
                continue
            for m in LEFTOVER_RE.finditer(text):
                w = m.group(0)
                if w not in SAFE_AEOEUE_WORDS:
                    leftover_hits.append((note_id, field, w, text))
            for m in SS_TO_ESZETT_HITS_RE.finditer(text):
                ss_hits.append((note_id, field, m.group(0), text))
            for stripped, umlaut_form, gloss in HOMOGRAPH_PAIRS:
                for m in re.finditer(rf"\b{re.escape(stripped)}\b", text):
                    homograph_hits.append((note_id, field, stripped, umlaut_form, gloss, text))

    lines = [
        "# usage_notes.json DE orthography scan",
        "",
        "> Two passes: (1) ASCII ae/oe/ue substitution leftovers + ss-for-ß "
        "candidates, checked against an allowlist of genuinely-correct German "
        "words -- treat every hit here as a real bug to fix. (2) a 'manual "
        "judgment' list of homograph pairs where the stripped ASCII form is "
        "ALSO a real word (druckt/drückt, schon/schön, ...) -- these cannot "
        "be pattern-matched as bugs; read each sentence and judge whether the "
        "umlaut was actually intended before changing anything.",
        "",
        f"- ASCII-umlaut leftovers (pass 1): **{len(leftover_hits)}**",
        f"- ss-for-ß candidates (pass 1): **{len(ss_hits)}**",
        f"- homograph-pair hits for manual judgment (pass 2): **{len(homograph_hits)}**",
        "",
        "## Pass 1 -- ASCII-umlaut leftovers (fix these)",
        "",
    ]
    if leftover_hits:
        lines += ["| id | field | token | sentence |", "|---|---|---|---|"]
        for note_id, field, w, text in leftover_hits:
            lines.append(f"| `{note_id}` | {field} | {w!r} | {text} |")
    else:
        lines.append("(none)")
    lines.append("")

    lines.append("## Pass 1b -- ss-for-ß candidates (fix these)")
    lines.append("")
    if ss_hits:
        lines += ["| id | field | token | sentence |", "|---|---|---|---|"]
        for note_id, field, w, text in ss_hits:
            lines.append(f"| `{note_id}` | {field} | {w!r} | {text} |")
    else:
        lines.append("(none)")
    lines.append("")

    lines.append("## Pass 2 -- homograph pairs (manual judgment, do NOT bulk-replace)")
    lines.append("")
    if homograph_hits:
        lines += ["| id | field | stripped form | check if this should be | sentence |", "|---|---|---|---|---|"]
        for note_id, field, stripped, umlaut_form, gloss, text in homograph_hits:
            lines.append(f"| `{note_id}` | {field} | `{stripped}` | `{umlaut_form}` ({gloss}) | {text} |")
    else:
        lines.append("(none)")
    lines.append("")

    counts = {"leftover": len(leftover_hits), "ss": len(ss_hits), "homograph": len(homograph_hits)}
    return "\n".join(lines), counts


def main() -> int:
    report, counts = run()
    out_path = ROOT / "docs" / "data" / "usage_notes_de_scan_2026-09-16.md"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(report, encoding="utf-8")
    print(
        f"leftover={counts['leftover']} ss={counts['ss']} "
        f"homograph_hits_for_review={counts['homograph']}"
    )
    print(f"report written: {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
