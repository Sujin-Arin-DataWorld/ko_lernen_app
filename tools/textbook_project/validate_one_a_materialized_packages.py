#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/"docs"/"textbook_project"/"pilot_1A"
CONTRACTS=ROOT/"docs"/"textbook_project"/"data"/"ONE_A_UNIT_CONTRACTS_20261006.json"

REQUIRED_COMMON=[
    "STUDENT_EN.md",
    "STUDENT_DE.md",
    "WORKBOOK_EN.md",
    "WORKBOOK_DE.md",
    "TEACHER_GUIDE.md",
]

BAD_DE_EDITORIAL=[
    "**Risk:**",
    "**Teaching response:**",
    "service politeness",
    "repair is normal, not failure",
    "short response is acceptable",
    "basic copula identification",
    "polite request",
    "subject honorification appears",
    "hear greeting",
    "distinguish statement",
    "production ceiling",
]

BAD_INTERNAL_SPEAKERS=[
    "**official**","**user**","**server**","**clerk**","**staff**",
    "**maya**","**friend**","**driver**","**passerby**",
]

def load_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))

def main():
    contracts=load_json(CONTRACTS)
    units=contracts["units"]
    assert len(units)==8

    total_dialogue_lines=0
    for u in units:
        order=u["order"]
        folder=BASE/f"unit{order:02d}"
        assert folder.exists(), folder

        for name in REQUIRED_COMMON:
            p=folder/name
            assert p.exists() and p.stat().st_size>200, p

        en=(folder/"STUDENT_EN.md").read_text(encoding="utf-8-sig")
        de=(folder/"STUDENT_DE.md").read_text(encoding="utf-8-sig")
        wb_en=(folder/"WORKBOOK_EN.md").read_text(encoding="utf-8-sig")
        wb_de=(folder/"WORKBOOK_DE.md").read_text(encoding="utf-8-sig")

        assert "By the end of this unit" in en, (u["unitId"],"EN header")
        assert "Nach dieser Einheit" in de, (u["unitId"],"DE header")
        assert "Self-check" in wb_en or "Self-check" in en, (u["unitId"],"EN workbook")
        assert "Selbstkontrolle" in wb_de, (u["unitId"],"DE workbook")

        # Raw Korean editorial meta from the contract must not leak into learner L1 pages.
        for raw in u["canDo"]+[u["communicativeProblem"]]:
            assert raw not in en, (u["unitId"],"raw KO meta in EN",raw)
            assert raw not in de, (u["unitId"],"raw KO meta in DE",raw)

        for bad in BAD_DE_EDITORIAL:
            assert bad not in de, (u["unitId"],"EN editorial leak in DE",bad)

        for bad in BAD_INTERNAL_SPEAKERS:
            assert bad not in en, (u["unitId"],"internal speaker EN",bad)
            assert bad not in de, (u["unitId"],"internal speaker DE",bad)

        if order==4:
            manifest=load_json(folder/"data"/"UNIT04_PUBLISHING_MANIFEST.json")
            audio=load_json(folder/"data"/"UNIT04_AUDIO_SCRIPT.json")
            assert manifest["status"]=="PILOT_VERTICAL_SLICE_DRAFT"
        else:
            manifest=load_json(folder/"data"/"UNIT_MANIFEST.json")
            audio=load_json(folder/"data"/"AUDIO_SCRIPT.json")
            assert manifest["status"]=="DRAFT_MATERIALIZED_NO_UNIT_EDITORIAL_PASS"

        assert manifest["unitId"]==u["unitId"]
        assert manifest["surfacePolicy"]["ttsOwner"]=="Jin"
        assert manifest["surfacePolicy"]["audioGenerated"] is False
        assert audio["ttsOwner"]=="Jin"
        assert audio["status"]=="SCRIPT_ONLY_NO_TTS_GENERATION"

        lines=[
            line
            for track in audio["tracks"]
            if track.get("type")=="dialogue"
            for line in track.get("lines",[])
        ]
        assert lines, u["unitId"]
        total_dialogue_lines += len(lines)
        assert all("displaySurfaceKo" in x and "spokenSurfaceKo" in x for x in lines)
        assert all("ㅋㅋ" not in x["spokenSurfaceKo"] and "ㅎㅎ" not in x["spokenSurfaceKo"] for x in lines)

        # Learner-facing editions use Korean target material but no line-by-line romanization layer.
        assert "romanization:" not in en.lower()
        assert "romanisierung:" not in de.lower()

    print(f"PASS 1A_packages=8 localized_student_editions=16 localized_workbooks=16 dialogue_lines={total_dialogue_lines}")

if __name__=="__main__":
    main()
