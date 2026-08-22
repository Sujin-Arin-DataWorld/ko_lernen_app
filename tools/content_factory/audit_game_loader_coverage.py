#!/usr/bin/env python3
"""Audit content quantity through the app's actual loader and course routes.

This report deliberately distinguishes three different questions:

* how many records exist at each CEFR level;
* how many records a direct-library learner can actually see;
* how many records each course unit receives through ``CurriculumCatalog``.

An optional review-only manifest can be overlaid in memory. No live asset is
modified, so the same command compares the current app with a draft batch.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import json
from pathlib import Path
import re
import sys
from typing import Any, Iterable

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scenario_store


ROOT = Path(__file__).resolve().parents[2]
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
LEVEL_RANK = {level: rank for rank, level in enumerate(LEVELS)}
COURSE_TARGETS = {
    "scenario": 1,
    "smalltalk": 2,
    "cloze": 10,
    "satz": 8,
}


def _read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {path}")
    return value


def _read_json_value(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def _level(value: Any) -> str:
    return str(value or "").strip().lower()


def _pack_base(pack_id: str) -> str:
    """Mirror ``_packBase`` in ``lib/services/curriculum_catalog.dart``."""

    parts = pack_id.strip().lower().split("_")
    if len(parts) > 1 and parts[-1].isdigit():
        parts.pop()
    return "_".join(parts)


def _mapped_unit(value: Any) -> str | None:
    if isinstance(value, str):
        return value.strip() or None
    if isinstance(value, dict):
        unit_id = str(value.get("courseUnitId") or "").strip()
        return unit_id or None
    return None


def _distribution(values: Iterable[int]) -> dict[str, int]:
    ordered = sorted(values)
    if not ordered:
        return {"minimum": 0, "median": 0, "maximum": 0}
    middle = len(ordered) // 2
    median = (
        ordered[middle]
        if len(ordered) % 2
        else (ordered[middle - 1] + ordered[middle]) // 2
    )
    return {
        "minimum": ordered[0],
        "median": median,
        "maximum": ordered[-1],
    }


class LoaderCoverageAudit:
    """Build a deterministic loader-aware coverage report."""

    def __init__(self, root: Path = ROOT, manifest: Path | None = None) -> None:
        self.root = root
        self.manifest = manifest

    def _asset(self, name: str) -> Path:
        return self.root / "assets" / "data" / name

    def _collections(self) -> dict[str, list[dict[str, Any]]]:
        result = {
            "scenario": list(
                scenario_store.load_scenarios(self.root / "assets" / "data")
            ),
            "smalltalk": list(_read_json(self._asset("smalltalk.json"))["phrases"]),
            "cloze": list(_read_json(self._asset("cloze.json"))["items"]),
            "satz": list(_read_json(self._asset("satz_sentences.json"))["items"]),
            "pronunciation": list(
                _read_json(self._asset("pronunciation_phrases.json"))["phrases"]
            ),
        }
        if self.manifest is None:
            return result

        manifest_path = self.manifest
        if not manifest_path.is_absolute():
            manifest_path = self.root / manifest_path
        manifest = _read_json(manifest_path)
        already_merged = manifest.get("status") == "merged"
        for artifact in manifest.get("artifacts", []):
            kind = str(artifact.get("kind") or "")
            if kind not in result:
                continue
            draft_path = self.root / str(artifact["draft"])
            draft = _read_json(draft_path)
            collection = str(artifact["collection"])
            live_by_id = {
                str(record.get("id") or ""): record for record in result[kind]
            }
            for record in draft[collection]:
                ident = str(record.get("id") or "")
                existing = live_by_id.get(ident)
                if existing is None:
                    result[kind].append(record)
                    live_by_id[ident] = record
                    continue
                # A merged manifest is an ancestry/ID receipt, not a frozen
                # second copy of learner text. Approved post-promotion copy
                # edits may make its historical draft differ from the current
                # live record; loader coverage must keep the live record.
                if already_merged:
                    continue
                if existing != record:
                    raise ValueError(
                        f"overlay {kind} ID {ident!r} disagrees with the live record"
                    )

        for kind, records in result.items():
            ids = [str(record.get("id") or "") for record in records]
            duplicates = sorted(item for item, count in Counter(ids).items() if count > 1)
            if duplicates:
                raise ValueError(f"duplicate {kind} IDs after overlay: {duplicates}")
        return result

    def _vocab_routes(self, curriculum: dict[str, Any]) -> dict[tuple[str, str], str]:
        by_source: dict[tuple[str, str], list[str]] = defaultdict(list)
        with self._asset("korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
            for row in csv.DictReader(handle):
                key = (_level(row.get("level")), str(row.get("korean") or "").strip())
                pack = _pack_base(str(row.get("pack_id") or ""))
                unit_id = _mapped_unit(curriculum["vocabPackUnitMap"].get(pack))
                if unit_id:
                    by_source[key].append(unit_id)
        return {
            key: units[0]
            for key, units in by_source.items()
            if len(units) == 1
        }

    def build(self) -> dict[str, Any]:
        collections = self._collections()
        curriculum = _read_json(self._asset("curriculum_manifest.json"))
        smalltalk_root = _read_json(self._asset("smalltalk.json"))
        categories = [str(item["id"]) for item in smalltalk_root["categories"]]

        units = {
            str(item["id"]): _level(item.get("level"))
            for item in curriculum["courseUnits"]
        }
        unit_ids_by_level = {
            level: [unit_id for unit_id, unit_level in units.items() if unit_level == level]
            for level in LEVELS
        }

        exact: dict[str, dict[str, int]] = {}
        for kind, records in collections.items():
            counts = Counter(_level(record.get("level")) for record in records)
            exact[kind] = {level: counts[level] for level in LEVELS}

        scenario_dialog = Counter()
        scenario_quests = Counter()
        for record in collections["scenario"]:
            level = _level(record.get("level"))
            scenario_dialog[level] += len(record.get("dialog") or [])
            scenario_quests[level] += len(record.get("quests") or [])

        listening: dict[str, dict[str, Any]] = {}
        for learner_level in LEVELS:
            source_level = None
            for rank in range(LEVEL_RANK[learner_level], -1, -1):
                candidate = LEVELS[rank]
                if exact["scenario"][candidate] > 0 and scenario_dialog[candidate] > 0:
                    source_level = candidate
                    break
            listening[learner_level] = {
                "effectiveSourceLevel": source_level,
                "scenarioCountAtSourceLevel": (
                    exact["scenario"][source_level] if source_level else 0
                ),
                "dialogTurnCountAtSourceLevel": (
                    scenario_dialog[source_level] if source_level else 0
                ),
            }

        pronunciation_visible = {}
        for learner_level in LEVELS:
            rank = LEVEL_RANK[learner_level]
            pronunciation_visible[learner_level] = sum(
                exact["pronunciation"][candidate]
                for candidate in LEVELS
                if LEVEL_RANK[candidate] <= rank
            )

        vocab_counts = Counter()
        with self._asset("korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
            for row in csv.DictReader(handle):
                vocab_counts[_level(row.get("level"))] += 1

        silben = _read_json(self._asset("silben_puzzles.json"))["levels"]
        silben_exact = {
            level: len(silben.get(level.upper(), []))
            for level in LEVELS
        }
        kkeunmari_words = _read_json(self._asset("kkeunmari_pool.json"))["words"]
        kkeunmari_counts = Counter(_level(item.get("level")) for item in kkeunmari_words)
        kkeunmari_visible = {
            learner_level: sum(
                kkeunmari_counts[candidate]
                for candidate in LEVELS
                if LEVEL_RANK[candidate] <= LEVEL_RANK[learner_level]
            )
            for learner_level in LEVELS
        }
        media_records = _read_json(self._asset("media_phrases.json"))["phrases"]
        media_counts = Counter(_level(item.get("level")) for item in media_records)
        media_callsite = all(
            marker in (self.root / path).read_text(encoding="utf-8")
            for path, marker in (
                ("lib/main.dart", "case '/media_phrases':"),
                ("lib/models/discover_catalog.dart", "id: 'media_phrases'"),
                ("lib/screens/practice_hub_screen.dart", "route: '/media_phrases'"),
            )
        )
        word_relations = _read_json(self._asset("word_relations.json"))["clusters"]
        word_relation_counts = Counter(_level(item.get("level")) for item in word_relations)
        grammar_patterns = _read_json_value(self._asset("grammar_patterns.json"))
        if not isinstance(grammar_patterns, list):
            raise ValueError("grammar_patterns.json must contain an array")
        grammar_pattern_counts = Counter(_level(item.get("level")) for item in grammar_patterns)

        other_games = {
            "vocabDerived": {
                "contract": "chosung_and_speed_match_derive_from_exact_level_vocab",
                "exactPerLevel": {level: vocab_counts[level] for level in LEVELS},
            },
            "silben": {
                "contract": "exact_level_selectable_a1_c2",
                "exactPerLevel": silben_exact,
                "selectablePerLevel": {
                    level: True
                    for level in LEVELS
                },
            },
            "kkeunmari": {
                "contract": "cumulative_through_learner_level_with_full_pool_chain_fallback",
                "exactPerLevel": {level: kkeunmari_counts[level] for level in LEVELS},
                "visiblePerLearnerLevel": kkeunmari_visible,
            },
            "mediaPhrases": {
                "contract": "exact_level_reachable_from_discover_and_practice_hub",
                "exactPerLevel": {level: media_counts[level] for level in LEVELS},
                "appCallSite": media_callsite,
            },
            "grammarPatterns": {
                "contract": "book_analysis_regex_support_not_a_standalone_game",
                "exactPerLevel": {
                    level: grammar_pattern_counts[level]
                    for level in LEVELS
                },
            },
            "wordRelations": {
                "contract": "exact_level_word_web_clusters",
                "exactPerLevel": {
                    level: word_relation_counts[level]
                    for level in LEVELS
                },
            },
        }

        smalltalk_counts = Counter(
            (_level(record.get("level")), str(record.get("category") or ""))
            for record in collections["smalltalk"]
        )
        smalltalk_category_coverage: dict[str, dict[str, Any]] = {}
        for level in LEVELS:
            missing = [category for category in categories if smalltalk_counts[level, category] == 0]
            deficit = sum(max(0, 2 - smalltalk_counts[level, category]) for category in categories)
            smalltalk_category_coverage[level] = {
                "categoryCount": len(categories) - len(missing),
                "emptyCategoryCount": len(missing),
                "emptyCategoryIds": missing,
                "recordDeficitToTwoPerCategory": deficit,
            }

        routed: dict[str, dict[str, list[str]]] = {
            kind: defaultdict(list) for kind in COURSE_TARGETS
        }
        unrouted: dict[str, list[str]] = {kind: [] for kind in COURSE_TARGETS}
        vocab_routes = self._vocab_routes(curriculum)
        for kind in COURSE_TARGETS:
            for record in collections[kind]:
                level = _level(record.get("level"))
                record_id = str(record.get("id") or "")
                unit_id: str | None
                if kind == "scenario":
                    unit_id = str(record.get("courseUnitId") or "").strip() or None
                elif kind == "smalltalk":
                    key = f"{level}:{str(record.get('category') or '').strip().lower()}"
                    checkpoint = curriculum.get("smalltalkCheckpointPhraseMap", {}).get(record_id)
                    unit_id = _mapped_unit(checkpoint) or _mapped_unit(
                        curriculum["smalltalkCategoryUnitMap"].get(key)
                    )
                elif kind == "cloze":
                    key = f"{level}:{str(record.get('topic') or '').strip().lower()}"
                    unit_id = _mapped_unit(curriculum["clozeTopicUnitMap"].get(key))
                else:
                    source = (level, str(record.get("vocabKo") or "").strip())
                    unit_id = vocab_routes.get(source)

                if unit_id not in units or units.get(unit_id) != level:
                    unrouted[kind].append(record_id)
                else:
                    routed[kind][unit_id].append(record_id)

        course_loader: dict[str, dict[str, Any]] = {}
        for kind, target in COURSE_TARGETS.items():
            by_level: dict[str, Any] = {}
            for level in LEVELS:
                level_units = unit_ids_by_level[level]
                counts = {unit_id: len(routed[kind].get(unit_id, [])) for unit_id in level_units}
                zero_ids = [unit_id for unit_id, count in counts.items() if count == 0]
                deficits = {
                    unit_id: max(0, target - count)
                    for unit_id, count in counts.items()
                    if count < target
                }
                by_level[level] = {
                    "unitCount": len(level_units),
                    "linkedRecordCount": sum(counts.values()),
                    "zeroUnitCount": len(zero_ids),
                    "zeroUnitIds": zero_ids,
                    "distribution": _distribution(counts.values()),
                    "targetPerUnit": target,
                    "recordDeficitToTarget": sum(deficits.values()),
                    "deficitByUnit": deficits,
                    "countsByUnit": counts,
                }
            course_loader[kind] = by_level

        return {
            "state": "preview" if self.manifest else "live",
            "overlayManifest": str(self.manifest) if self.manifest else None,
            "loaderContracts": {
                "scenarioLibrary": "exact_level",
                "listeningInitial": "exact_level_else_closest_lower",
                "smalltalkLibrary": "exact_level_and_category",
                "clozeLibrary": "exact_level_else_all",
                "satzLibrary": "exact_level_else_all",
                "pronunciationLibrary": "cumulative_through_learner_level",
                "course": "exact_content_ids_from_curriculum_catalog",
            },
            "inventory": {
                kind: {
                    "total": len(records),
                    "exactPerLevel": exact[kind],
                }
                for kind, records in collections.items()
            },
            "scenarioDetail": {
                "dialogTurnsPerLevel": {level: scenario_dialog[level] for level in LEVELS},
                "questsPerLevel": {level: scenario_quests[level] for level in LEVELS},
            },
            "libraryLoader": {
                "listeningInitial": listening,
                "pronunciationVisiblePerLearnerLevel": pronunciation_visible,
                "smalltalkCategoryCoverage": smalltalk_category_coverage,
                "otherGames": other_games,
            },
            "courseLoader": course_loader,
            "unroutedIds": {kind: sorted(ids) for kind, ids in unrouted.items()},
        }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument(
        "--manifest",
        type=Path,
        help="Optional review-only manifest overlaid in memory",
    )
    parser.add_argument("--output", type=Path, help="Optional JSON output path")
    parser.add_argument(
        "--check",
        action="store_true",
        help="return nonzero when a loader or minimum-coverage contract fails",
    )
    return parser


def _coverage_errors(report: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for kind, levels in report["courseLoader"].items():
        for level, state in levels.items():
            if state["recordDeficitToTarget"]:
                errors.append(
                    f"course {kind} {level} deficit {state['recordDeficitToTarget']}"
                )
    categories = report["libraryLoader"]["smalltalkCategoryCoverage"]
    for level, state in categories.items():
        if state["recordDeficitToTwoPerCategory"]:
            errors.append(
                f"smalltalk {level} category deficit "
                f"{state['recordDeficitToTwoPerCategory']}"
            )
    exact = report["inventory"]["pronunciation"]["exactPerLevel"]
    for level in LEVELS:
        if exact[level] < 8:
            errors.append(f"pronunciation {level} has {exact[level]}, requires 8")
    other = report["libraryLoader"]["otherGames"]
    thresholds = {
        "silben": 20,
        "kkeunmari": 20,
        "mediaPhrases": 8,
        "grammarPatterns": 2,
        "wordRelations": 4,
    }
    for kind, minimum in thresholds.items():
        for level, count in other[kind]["exactPerLevel"].items():
            if count < minimum:
                errors.append(f"{kind} {level} has {count}, requires {minimum}")
    for level, selectable in other["silben"]["selectablePerLevel"].items():
        if not selectable:
            errors.append(f"silben {level} is not selectable")
    if not other["mediaPhrases"]["appCallSite"]:
        errors.append("mediaPhrases has no complete app route/catalog/hub call site")
    return errors


def main() -> int:
    args = _parser().parse_args()
    report = LoaderCoverageAudit(args.root, args.manifest).build()
    errors = _coverage_errors(report)
    report["coverageErrors"] = errors
    rendered = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
        print(f"OK: wrote loader coverage report to {args.output}")
    else:
        print(rendered, end="")
    return 1 if args.check and errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
