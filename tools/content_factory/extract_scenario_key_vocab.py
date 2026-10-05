#!/usr/bin/env python3
"""Build a review-only key-vocabulary leveling sidecar for scenario drafts.

The scenario's explicit vocab[].korean list remains the author-selected set
of key words/phrases. This tool does not mutate runtime content. It classifies
those author-selected items against the repository CEFR lexicon, exact live
vocabulary headwords, and linked CulturalGlossary terms.

Culture anchors are reported separately because a culture-specific word can
legitimately be lexically rare while remaining usable in a lower-level scene
when the UI provides immediate glossary support.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import sys
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
TOOL_DIR = ROOT / "tool"
if str(TOOL_DIR) not in sys.path:
    sys.path.insert(0, str(TOOL_DIR))

from cefr_lexicon import CEFR_TO_GRADE, CefrLexicon  # noqa: E402


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def _repo_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def _live_vocab_by_headword(path: Path) -> dict[str, list[dict[str, str]]]:
    result: dict[str, list[dict[str, str]]] = {}
    with path.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            korean = (row.get("korean") or "").strip()
            if not korean:
                continue
            result.setdefault(korean, []).append(
                {
                    "id": row.get("id") or "",
                    "level": row.get("level") or "",
                    "packId": row.get("pack_id") or "",
                }
            )
    return result


def _culture_terms(glossary_path: Path) -> tuple[dict[str, dict[str, Any]], dict[str, str]]:
    root = _read_json(glossary_path)
    entries = root.get("entries")
    if not isinstance(entries, list):
        raise ValueError(f"{glossary_path}: entries must be an array")
    by_id: dict[str, dict[str, Any]] = {}
    ko_to_id: dict[str, str] = {}
    for raw in entries:
        if not isinstance(raw, dict):
            continue
        term_id = str(raw.get("termId") or "").strip()
        ko = str(raw.get("ko") or "").strip()
        if not term_id or not ko:
            continue
        by_id[term_id] = raw
        ko_to_id[ko] = term_id
    return by_id, ko_to_id


def _culture_links(path: Path | None) -> dict[str, list[str]]:
    if path is None:
        return {}
    root = _read_json(path)
    links = root.get("links")
    if not isinstance(links, list):
        raise ValueError(f"{path}: links must be an array")
    result: dict[str, list[str]] = {}
    for raw in links:
        if not isinstance(raw, dict):
            continue
        scenario_id = str(raw.get("scenarioId") or "").strip()
        terms = raw.get("termIds")
        if not scenario_id or not isinstance(terms, list):
            continue
        result[scenario_id] = [str(term).strip() for term in terms if str(term).strip()]
    return result


def _attested_in_dialog(korean: str, dialog_text: str) -> bool:
    if korean in dialog_text:
        return True
    # Scenario vocab uses dictionary-form predicates while dialogue carries
    # conjugated surface forms. A narrow stem check avoids flagging ordinary
    # 하다/adjective/verb inflection as unattested without pretending to be a
    # full morphological analyzer.
    if " " not in korean and korean.endswith("다") and len(korean) > 2:
        return korean[:-1] in dialog_text
    return False


def _classification(
    *,
    target_grade: int,
    lexical_grade: int | None,
    culture_term_id: str | None,
) -> tuple[str, str]:
    if culture_term_id is not None:
        return "culture_anchor", "keep_with_glossary_support"
    if lexical_grade is None:
        return "unmapped_candidate", "human_level_review"
    if lexical_grade <= target_grade:
        return "at_or_below_target", "keep"
    return "above_target", "review_rewrite_or_level_exception"


def build(
    *,
    scenarios_path: Path,
    culture_links_path: Path | None,
    glossary_path: Path,
    live_vocab_path: Path,
) -> dict[str, Any]:
    root = _read_json(scenarios_path)
    scenarios = root.get("scenarios")
    if not isinstance(scenarios, list) or any(not isinstance(item, dict) for item in scenarios):
        raise ValueError(f"{scenarios_path}: scenarios must be an array of objects")

    lexicon = CefrLexicon.load(ROOT)
    live_vocab = _live_vocab_by_headword(live_vocab_path)
    glossary_by_id, glossary_ko_to_id = _culture_terms(glossary_path)
    links = _culture_links(culture_links_path)

    scene_rows: list[dict[str, Any]] = []
    totals = {
        "items": 0,
        "cultureAnchor": 0,
        "atOrBelowTarget": 0,
        "aboveTarget": 0,
        "unmappedCandidate": 0,
        "phraseCandidate": 0,
    }

    for scene in scenarios:
        scenario_id = str(scene.get("id") or "").strip()
        target_level = str(scene.get("level") or "").strip().upper()
        target_grade = CEFR_TO_GRADE.get(target_level)
        if not scenario_id or target_grade is None:
            raise ValueError(f"invalid scenario id/level: {scenario_id!r} {target_level!r}")

        linked_term_ids = links.get(scenario_id, [])
        linked_ko = {
            str(glossary_by_id[term_id].get("ko") or ""): term_id
            for term_id in linked_term_ids
            if term_id in glossary_by_id
        }
        dialog_text = "\n".join(
            str(line.get("ko") or "")
            for line in scene.get("dialog", [])
            if isinstance(line, dict)
        )

        key_words: list[dict[str, Any]] = []
        raw_vocab = scene.get("vocab")
        if not isinstance(raw_vocab, list):
            raise ValueError(f"{scenario_id}: vocab must be an array")
        for item in raw_vocab:
            if not isinstance(item, dict):
                raise ValueError(f"{scenario_id}: vocab item must be an object")
            korean = str(item.get("korean") or "").strip()
            if not korean:
                raise ValueError(f"{scenario_id}: vocab item needs korean")

            profile = lexicon.phrase_grade(korean)
            culture_term_id = linked_ko.get(korean)
            if culture_term_id is None:
                possible = glossary_ko_to_id.get(korean)
                if possible in linked_term_ids:
                    culture_term_id = possible

            classification, action = _classification(
                target_grade=target_grade,
                lexical_grade=profile.grade,
                culture_term_id=culture_term_id,
            )
            flags: list[str] = []
            if " " in korean:
                flags.append("phrase_candidate")
                totals["phraseCandidate"] += 1
            attested = _attested_in_dialog(korean, dialog_text)
            if not attested:
                flags.append("not_attested_in_dialog")
            if any(word.confidence == "low" for word in profile.words):
                flags.append("low_confidence_lexicon_source")

            live_matches = live_vocab.get(korean, [])
            live_grades = [
                CEFR_TO_GRADE[level.upper()]
                for level in (row["level"] for row in live_matches)
                if level.upper() in CEFR_TO_GRADE
            ]
            if live_grades and max(live_grades) > target_grade:
                flags.append("live_vocab_above_target")
            if (
                profile.grade is not None
                and live_grades
                and profile.grade not in set(live_grades)
            ):
                flags.append("lexicon_live_level_mismatch")

            source_rows = [
                {
                    "matched": word.matched,
                    "cefr": word.cefr,
                    "grade": word.grade,
                    "source": word.source,
                    "confidence": word.confidence,
                }
                for word in profile.words
            ]
            row = {
                "korean": korean,
                "kind": "phrase" if " " in korean else "term",
                "attestedInDialog": attested,
                "cultureTermId": culture_term_id,
                "lexical": {
                    "cefr": profile.cefr,
                    "grade": profile.grade,
                    "unknown": list(profile.unknown),
                    "parts": source_rows,
                },
                "liveVocabMatches": live_matches,
                "classification": classification,
                "flags": flags,
                "recommendedAction": action,
            }
            key_words.append(row)
            totals["items"] += 1
            totals[
                {
                    "culture_anchor": "cultureAnchor",
                    "at_or_below_target": "atOrBelowTarget",
                    "above_target": "aboveTarget",
                    "unmapped_candidate": "unmappedCandidate",
                }[classification]
            ] += 1

        scene_rows.append(
            {
                "scenarioId": scenario_id,
                "targetLevel": target_level,
                "linkedCultureTermIds": linked_term_ids,
                "keyWords": key_words,
                "summary": {
                    "items": len(key_words),
                    "cultureAnchor": sum(
                        item["classification"] == "culture_anchor" for item in key_words
                    ),
                    "aboveTarget": sum(
                        item["classification"] == "above_target" for item in key_words
                    ),
                    "unmappedCandidate": sum(
                        item["classification"] == "unmapped_candidate" for item in key_words
                    ),
                },
            }
        )

    return {
        "schemaVersion": 1,
        "status": "review_only",
        "purpose": "Authoring evidence only; does not mutate live vocabulary or scenario level.",
        "sources": {
            "scenarios": _repo_path(scenarios_path),
            "cultureLinks": (
                _repo_path(culture_links_path) if culture_links_path else None
            ),
            "culturalGlossary": _repo_path(glossary_path),
            "liveVocab": _repo_path(live_vocab_path),
            "cefrLexicon": "tool/cefr_lexicon.py",
        },
        "policy": {
            "cultureAnchor": "Keep when the scene directly teaches the linked culture term and glossary support is available.",
            "aboveTarget": "Review wording; rewrite, move, or add an explicit governed exception. Do not silently promote the learner level.",
            "unmappedCandidate": "Requires human level review; the tool does not guess.",
            "phraseCandidate": "Review as a phrase or expression before adding a dictionary headword.",
        },
        "totals": totals,
        "scenes": scene_rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenarios", required=True)
    parser.add_argument("--culture-links")
    parser.add_argument("--output", required=True)
    parser.add_argument("--glossary", default="docs/data/cultural_glossary.json")
    parser.add_argument("--live-vocab", default="assets/data/korean_vocab.csv")
    args = parser.parse_args()

    scenarios_path = (ROOT / args.scenarios).resolve()
    links_path = (ROOT / args.culture_links).resolve() if args.culture_links else None
    glossary_path = (ROOT / args.glossary).resolve()
    live_vocab_path = (ROOT / args.live_vocab).resolve()
    output_path = (ROOT / args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    result = build(
        scenarios_path=scenarios_path,
        culture_links_path=links_path,
        glossary_path=glossary_path,
        live_vocab_path=live_vocab_path,
    )
    output_path.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("OK:", result["totals"], "->", _repo_path(output_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
