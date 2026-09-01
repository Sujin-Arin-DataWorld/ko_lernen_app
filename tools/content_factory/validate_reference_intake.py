#!/usr/bin/env python3
"""Validate the quarantined reference intake and clean-room seed database.

The validator checks CSV schemas, provenance links inside the quarantine, and
every live curriculum, vocabulary, and grammar reference used by clean-room
briefs. It never reads source PDFs or OCR output and never writes repository
files.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
from datetime import date
import json
from pathlib import Path
import re
import sys
from typing import Iterable

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scenario_store


ROOT = Path(__file__).resolve().parents[2]
INTAKE = ROOT / "tools" / "content_factory" / "reference_intake"

SOURCE_HEADER = [
    "source_id",
    "file_name",
    "sha256",
    "page_count",
    "content_group_id",
    "duplicate_of",
    "text_layer_mode",
    "ocr_required",
    "library_page_review",
    "local_render_review",
    "rights_status",
    "allowed_use",
    "review_status",
    "last_reviewed",
    "notes",
]
PAGE_HEADER = [
    "audit_id",
    "source_id",
    "page_start",
    "page_end",
    "method",
    "text_line_count",
    "page_image_count",
    "table_detected",
    "layout_detected",
    "extraction_confidence",
    "visual_review_required",
    "audit_status",
    "notes",
]
OBSERVATION_HEADER = [
    "observation_id",
    "source_id",
    "audit_id",
    "observation_type",
    "neutral_signal",
    "cefr_candidate",
    "skill_axis",
    "interaction_mode",
    "register_hint",
    "grammar_fact",
    "confidence",
    "rights_gate",
    "status",
]
BRIEF_HEADER = [
    "brief_id",
    "level",
    "domain",
    "communicative_goal",
    "learner_outcome",
    "register",
    "relationship_context",
    "interaction_mode",
    "grammar_targets",
    "game_targets",
    "course_unit_id",
    "concept_ids",
    "priority",
    "gap_evidence",
    "rights_basis",
    "status",
]
SEED_HEADER = [
    "seed_id",
    "brief_id",
    "level",
    "course_unit_id",
    "concept_ids",
    "vocab_ids",
    "grammar_ids",
    "scenario_ids",
    "scenario_quest_ids",
    "smalltalk_ids",
    "cloze_ids",
    "satz_ids",
    "pronunciation_ids",
    "canonical_scenario_id",
    "canonical_dialog_turn",
    "scenario_count",
    "scenario_quest_count",
    "smalltalk_count",
    "cloze_count",
    "satz_count",
    "pronunciation_count",
    "course_exposure",
    "derivation_contract",
    "review_status",
]

LEVELS = frozenset(("A1", "A2", "B1", "B2", "C1", "C2"))
LOWER_LEVELS = frozenset(level.lower() for level in LEVELS)
YES_NO = frozenset(("yes", "no"))


@dataclass(frozen=True)
class Issue:
    source: str
    message: str


class ReferenceIntakeValidator:
    def __init__(self, root: Path = ROOT) -> None:
        self.root = root.resolve()
        self.intake = self.root / "tools" / "content_factory" / "reference_intake"
        self.issues: list[Issue] = []

    def issue(self, source: str, message: str) -> None:
        self.issues.append(Issue(source, message))

    def read_csv(self, name: str, header: list[str]) -> list[dict[str, str]]:
        path = self.intake / name
        try:
            with path.open(encoding="utf-8-sig", newline="") as handle:
                reader = csv.DictReader(handle)
                if list(reader.fieldnames or []) != header:
                    self.issue(name, f"header must exactly match {header!r}")
                    return []
                rows = list(reader)
        except (OSError, csv.Error) as error:
            self.issue(name, f"cannot read CSV: {error}")
            return []
        for number, row in enumerate(rows, start=2):
            if None in row:
                self.issue(name, f"row {number} is malformed")
            for key, value in row.items():
                if key is not None and value is not None and value != value.strip():
                    self.issue(name, f"row {number} field {key!r} has outer whitespace")
                if value is not None and ("\n" in value or "\r" in value):
                    self.issue(name, f"row {number} field {key!r} contains a line break")
        return rows

    @staticmethod
    def split_ids(value: str) -> list[str]:
        return [item for item in value.split("|") if item]

    @staticmethod
    def is_positive_int(value: str) -> bool:
        return value.isdigit() and int(value) > 0

    def unique(self, source: str, rows: Iterable[dict[str, str]], key: str) -> None:
        seen: set[str] = set()
        for number, row in enumerate(rows, start=2):
            value = row.get(key, "")
            if not value:
                self.issue(source, f"row {number} has empty {key}")
            elif value in seen:
                self.issue(source, f"row {number} duplicates {key} {value!r}")
            seen.add(value)

    def load_live(
        self,
    ) -> tuple[
        dict[str, dict[str, str]],
        dict[str, dict[str, str]],
        dict[str, set[str]],
        dict[str, object],
    ]:
        vocab: dict[str, dict[str, str]] = {}
        grammar: dict[str, dict[str, str]] = {}
        units: dict[str, set[str]] = {}
        routing: dict[str, object] = {}
        try:
            with (self.root / "assets" / "data" / "korean_vocab.csv").open(
                encoding="utf-8-sig", newline=""
            ) as handle:
                for row in csv.DictReader(handle):
                    vocab[row.get("id", "")] = row
            with (self.root / "assets" / "data" / "grammar.csv").open(
                encoding="utf-8-sig", newline=""
            ) as handle:
                for row in csv.DictReader(handle):
                    grammar[row.get("id", "")] = row
            manifest = json.loads(
                (self.root / "assets" / "data" / "curriculum_manifest.json").read_text(
                    encoding="utf-8"
                )
            )
            for unit in manifest.get("courseUnits", []):
                if isinstance(unit, dict) and isinstance(unit.get("id"), str):
                    units[unit["id"]] = {
                        str(value) for value in unit.get("requiredConceptIds", [])
                    }
            for field in (
                "vocabPackUnitMap",
                "smalltalkCategoryUnitMap",
                "clozeTopicUnitMap",
            ):
                value = manifest.get(field)
                if not isinstance(value, dict):
                    self.issue("assets/data", f"curriculum manifest {field} must be an object")
                    value = {}
                routing[field] = value
        except (OSError, csv.Error, json.JSONDecodeError) as error:
            self.issue("assets/data", f"cannot read live references: {error}")
        return vocab, grammar, units, routing

    def load_available_content(self) -> dict[str, dict[str, dict[str, object]]]:
        specs = {
            # 시나리오는 레벨 샤드 6 개라 파일명이 아니라 병합 뷰로 읽는다.
            "scenario": (None, "scenarios"),
            "smalltalk": ("smalltalk.json", "phrases"),
            "cloze": ("cloze.json", "items"),
            "satz": ("satz_sentences.json", "items"),
            "pronunciation": ("pronunciation_phrases.json", "phrases"),
        }
        available: dict[str, dict[str, dict[str, object]]] = {
            kind: {} for kind in specs
        }
        source = "content sources"

        def add(
            kind: str,
            record: object,
            label: str,
            *,
            allow_identical_live_copy: bool = False,
        ) -> None:
            if not isinstance(record, dict) or not isinstance(record.get("id"), str):
                self.issue(source, f"{label}: malformed {kind} record")
                return
            ident = record["id"]
            if ident in available[kind]:
                # Draft manifests may remain review_only_draft after their IDs
                # have been promoted. The live record is the available copy;
                # frozen draft copy drift is checked by promotion ledgers.
                if allow_identical_live_copy:
                    return
                self.issue(source, f"{label}: duplicate available {kind} {ident!r}")
            available[kind][ident] = record

        try:
            for kind, (name, collection) in specs.items():
                data_dir = self.root / "assets" / "data"
                if name is None:
                    live = scenario_store.load_root(data_dir)
                    label = "scenarios (6 level shards)"
                else:
                    live = json.loads(
                        (data_dir / name).read_text(encoding="utf-8")
                    )
                    label = name
                for record in live.get(collection, []):
                    add(kind, record, label)
            for manifest_path in sorted(
                (self.root / "tools" / "content_factory" / "drafts").glob(
                    "batch_*_manifest.json"
                )
            ):
                manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
                curriculum = json.loads(
                    (data_dir / "curriculum_manifest.json").read_text(
                        encoding="utf-8"
                    )
                )
                canonical_scenario_runtime = (
                    curriculum.get("scenarioCorpusGeneration")
                    == "canonical_120_v1"
                )
                if manifest.get("status") == "merged" and not canonical_scenario_runtime:
                    continue
                for artifact in manifest.get("artifacts", []):
                    if not isinstance(artifact, dict):
                        continue
                    kind = artifact.get("kind")
                    if kind not in specs:
                        continue
                    if manifest.get("status") == "merged" and kind != "scenario":
                        continue
                    relative = artifact.get("draft")
                    if not isinstance(relative, str):
                        self.issue(source, f"{manifest_path.name}: {kind} draft path is missing")
                        continue
                    draft_path = (self.root / relative).resolve()
                    try:
                        draft_path.relative_to(self.root)
                    except ValueError:
                        self.issue(source, f"{manifest_path.name}: {kind} draft escapes repository")
                        continue
                    draft = json.loads(draft_path.read_text(encoding="utf-8"))
                    collection = specs[str(kind)][1]
                    for record in draft.get(collection, []):
                        add(
                            str(kind),
                            record,
                            draft_path.name,
                            allow_identical_live_copy=True,
                        )
        except (OSError, json.JSONDecodeError) as error:
            self.issue(source, f"cannot read content sources: {error}")
        return available

    def validate_sources(self, rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
        source = "source_inventory.csv"
        self.unique(source, rows, "source_id")
        by_id = {row.get("source_id", ""): row for row in rows}
        hashes: set[str] = set()
        allowed_modes = {"text", "mixed", "image"}
        rights = {"reference_only", "licensed", "owned", "public_domain", "unknown"}
        uses = {"coverage_audit_only", "licensed_transform", "original_source"}
        statuses = {"inventory_only", "sampled", "fully_audited", "blocked"}
        for number, row in enumerate(rows, start=2):
            label = row.get("source_id") or f"row {number}"
            if not re.fullmatch(r"ref\d{4}", label):
                self.issue(source, f"{label}: source_id must match ref####")
            digest = row.get("sha256", "")
            if not re.fullmatch(r"[0-9a-f]{64}", digest):
                self.issue(source, f"{label}: sha256 must be 64 lowercase hex characters")
            elif digest in hashes:
                self.issue(source, f"{label}: sha256 duplicates another physical file")
            hashes.add(digest)
            if not self.is_positive_int(row.get("page_count", "")):
                self.issue(source, f"{label}: page_count must be positive")
            if not re.fullmatch(r"group\d{4}", row.get("content_group_id", "")):
                self.issue(source, f"{label}: invalid content_group_id")
            if row.get("text_layer_mode") not in allowed_modes:
                self.issue(source, f"{label}: invalid text_layer_mode")
            for field in ("ocr_required", "library_page_review", "local_render_review"):
                if row.get(field) not in YES_NO:
                    self.issue(source, f"{label}: {field} must be yes or no")
            if row.get("text_layer_mode") == "image" and row.get("ocr_required") != "yes":
                self.issue(source, f"{label}: image mode requires OCR")
            if row.get("rights_status") not in rights:
                self.issue(source, f"{label}: invalid rights_status")
            if row.get("allowed_use") not in uses:
                self.issue(source, f"{label}: invalid allowed_use")
            if row.get("rights_status") in {"reference_only", "unknown"} and row.get("allowed_use") != "coverage_audit_only":
                self.issue(source, f"{label}: rights status only permits coverage audit")
            if row.get("review_status") not in statuses:
                self.issue(source, f"{label}: invalid review_status")
            try:
                date.fromisoformat(row.get("last_reviewed", ""))
            except ValueError:
                self.issue(source, f"{label}: last_reviewed must be YYYY-MM-DD")
            duplicate = row.get("duplicate_of", "")
            if duplicate:
                target = by_id.get(duplicate)
                if target is None:
                    self.issue(source, f"{label}: duplicate_of references unknown source")
                elif target.get("duplicate_of"):
                    self.issue(source, f"{label}: duplicate_of must point to a canonical row")
                elif target.get("content_group_id") != row.get("content_group_id"):
                    self.issue(source, f"{label}: duplicate must share content_group_id")
                if row.get("review_status") != "blocked":
                    self.issue(source, f"{label}: duplicate copy must be blocked")
        return by_id

    def validate_pages(
        self,
        rows: list[dict[str, str]],
        sources: dict[str, dict[str, str]],
    ) -> dict[str, dict[str, str]]:
        source = "page_audit.csv"
        self.unique(source, rows, "audit_id")
        by_id = {row.get("audit_id", ""): row for row in rows}
        methods = {"pdf_text", "library_page_read", "local_render", "combined"}
        tri = {"yes", "no", "unknown"}
        confidence = {"high", "medium", "low", "none"}
        statuses = {"sampled", "complete", "needs_followup", "blocked"}
        methods_by_source: dict[str, set[str]] = {}
        for number, row in enumerate(rows, start=2):
            label = row.get("audit_id") or f"row {number}"
            ref = sources.get(row.get("source_id", ""))
            if ref is None:
                self.issue(source, f"{label}: unknown source_id")
                continue
            if not re.fullmatch(rf"audit_{re.escape(row['source_id'])}_\d{{4}}", label):
                self.issue(source, f"{label}: audit_id does not match source_id")
            start = row.get("page_start", "")
            end = row.get("page_end", "")
            if not self.is_positive_int(start) or not self.is_positive_int(end):
                self.issue(source, f"{label}: page range must use positive integers")
            elif int(start) > int(end) or int(end) > int(ref["page_count"]):
                self.issue(source, f"{label}: page range is outside the source")
            if row.get("method") not in methods:
                self.issue(source, f"{label}: invalid method")
            for field in ("text_line_count", "page_image_count"):
                value = row.get(field, "")
                if value and not value.isdigit():
                    self.issue(source, f"{label}: {field} must be blank or a nonnegative integer")
            for field in ("table_detected", "layout_detected"):
                if row.get(field) not in tri:
                    self.issue(source, f"{label}: invalid {field}")
            if row.get("extraction_confidence") not in confidence:
                self.issue(source, f"{label}: invalid extraction_confidence")
            if row.get("visual_review_required") not in YES_NO:
                self.issue(source, f"{label}: visual_review_required must be yes or no")
            if row.get("audit_status") not in statuses:
                self.issue(source, f"{label}: invalid audit_status")
            methods_by_source.setdefault(row.get("source_id", ""), set()).add(
                row.get("method", "")
            )
        for ident, record in sources.items():
            methods = methods_by_source.get(ident, set())
            if record.get("review_status") in {"sampled", "fully_audited"} and not methods:
                self.issue(source, f"{ident}: reviewed source needs at least one page audit")
            if record.get("text_layer_mode") in {"mixed", "image"} and not (
                {"local_render", "combined"} & methods
            ):
                self.issue(source, f"{ident}: mixed or image source needs local render evidence")
        return by_id

    def validate_observations(
        self,
        rows: list[dict[str, str]],
        sources: dict[str, dict[str, str]],
        audits: dict[str, dict[str, str]],
    ) -> None:
        source = "reference_observations.csv"
        self.unique(source, rows, "observation_id")
        types = {"coverage_gap", "interaction_pattern", "skill_progression", "layout_risk", "language_fact"}
        levels = LEVELS | {"UNSET"}
        skills = {"listening", "reading", "speaking", "writing", "interaction", "mediation", "form"}
        registers = {"casual", "polite", "business", "mixed", "unset"}
        rights = {"pass_fact_only", "pass_abstract_only", "blocked"}
        statuses = {"candidate", "accepted", "rejected"}
        for number, row in enumerate(rows, start=2):
            label = row.get("observation_id") or f"row {number}"
            if not re.fullmatch(r"obs_\d{4}", label):
                self.issue(source, f"{label}: invalid observation_id")
            if row.get("source_id") not in sources:
                self.issue(source, f"{label}: unknown source_id")
            audit = audits.get(row.get("audit_id", ""))
            if audit is None or audit.get("source_id") != row.get("source_id"):
                self.issue(source, f"{label}: audit must exist and belong to source_id")
            if row.get("observation_type") not in types:
                self.issue(source, f"{label}: invalid observation_type")
            signal = row.get("neutral_signal", "")
            if not signal or len(signal) > 180:
                self.issue(source, f"{label}: neutral_signal must contain 1 to 180 characters")
            if row.get("cefr_candidate") not in levels:
                self.issue(source, f"{label}: invalid cefr_candidate")
            if row.get("skill_axis") not in skills:
                self.issue(source, f"{label}: invalid skill_axis")
            if row.get("register_hint") not in registers:
                self.issue(source, f"{label}: invalid register_hint")
            if row.get("confidence") not in {"high", "medium", "low"}:
                self.issue(source, f"{label}: invalid confidence")
            if row.get("rights_gate") not in rights:
                self.issue(source, f"{label}: invalid rights_gate")
            if row.get("status") not in statuses:
                self.issue(source, f"{label}: invalid status")
            fact = row.get("grammar_fact", "")
            if fact and row.get("observation_type") != "language_fact":
                self.issue(source, f"{label}: grammar_fact is only valid for language_fact")

    def validate_briefs(
        self,
        rows: list[dict[str, str]],
        grammar: dict[str, dict[str, str]],
        units: dict[str, set[str]],
    ) -> dict[str, dict[str, str]]:
        source = "content_briefs.csv"
        self.unique(source, rows, "brief_id")
        by_id = {row.get("brief_id", ""): row for row in rows}
        registers = {"casual", "polite", "business", "intimate"}
        game_targets = {"hoerverstehen", "uebersetzen", "luecken", "satzBauen", "diktat", "particlePop", "batchimDrop", "schreiben"}
        forbidden = re.compile(r"(?:\.pdf|ref\d{4}|audit_|source_id|page_|ocr|세종)", re.IGNORECASE)
        for number, row in enumerate(rows, start=2):
            label = row.get("brief_id") or f"row {number}"
            level = row.get("level", "")
            if level not in LEVELS or not re.fullmatch(rf"brief_{level.lower()}_[a-z0-9_]+", label):
                self.issue(source, f"{label}: brief_id and level disagree")
            for field, value in row.items():
                if forbidden.search(value or ""):
                    self.issue(source, f"{label}: {field} leaks source provenance into clean-room brief")
            if row.get("register") not in registers:
                self.issue(source, f"{label}: invalid register")
            if not re.fullmatch(r"[a-z0-9_]+", row.get("relationship_context", "")):
                self.issue(source, f"{label}: relationship_context must be snake_case")
            unit_id = row.get("course_unit_id", "")
            concepts = set(self.split_ids(row.get("concept_ids", "")))
            if unit_id not in units:
                self.issue(source, f"{label}: unknown course_unit_id")
            elif not concepts or not concepts.issubset(units[unit_id]):
                self.issue(source, f"{label}: concept_ids are not required by course unit")
            if unit_id and not unit_id.startswith(level.lower() + "_"):
                self.issue(source, f"{label}: course unit level disagrees")
            grammar_ids = self.split_ids(row.get("grammar_targets", ""))
            if not grammar_ids:
                self.issue(source, f"{label}: grammar_targets cannot be empty")
            for ident in grammar_ids:
                live = grammar.get(ident)
                if live is None or live.get("level") != level:
                    self.issue(source, f"{label}: grammar target {ident!r} is missing or wrong-level")
            targets = self.split_ids(row.get("game_targets", ""))
            if not targets or any(target not in game_targets for target in targets):
                self.issue(source, f"{label}: invalid game_targets")
            if row.get("priority") not in {"P0", "P1", "P2"}:
                self.issue(source, f"{label}: invalid priority")
            if row.get("rights_basis") != "original_clean_room":
                self.issue(source, f"{label}: rights_basis must be original_clean_room")
            if row.get("status") not in {"draft", "ready", "used", "retired"}:
                self.issue(source, f"{label}: invalid status")
        return by_id

    def validate_seeds(
        self,
        rows: list[dict[str, str]],
        briefs: dict[str, dict[str, str]],
        vocab: dict[str, dict[str, str]],
        grammar: dict[str, dict[str, str]],
        units: dict[str, set[str]],
        routing: dict[str, object],
        content: dict[str, dict[str, dict[str, object]]],
    ) -> None:
        source = "seed_bundle_plan.csv"
        self.unique(source, rows, "seed_id")
        reserved: dict[str, set[str]] = {
            key: set()
            for key in (
                "scenario_ids",
                "scenario_quest_ids",
                "smalltalk_ids",
                "cloze_ids",
                "satz_ids",
                "pronunciation_ids",
            )
        }
        patterns = {
            "scenario_ids": r"[a-z0-9_]+",
            "scenario_quest_ids": r"quest_[a-z0-9_]+",
            "smalltalk_ids": r"smalltalk_(?:a1|a2|b1|b2|c1|c2)_\d{4}",
            "cloze_ids": r"cloze_(?:a1|a2|b1|b2|c1|c2)_\d{4}",
            "satz_ids": r"satz_(?:a1|a2|b1|b2|c1|c2)_\d{4}",
            "pronunciation_ids": r"pronunciation_(?:a1|a2|b1|b2|c1|c2)_\d{4}",
        }
        kinds = {
            "scenario_ids": "scenario",
            "smalltalk_ids": "smalltalk",
            "cloze_ids": "cloze",
            "satz_ids": "satz",
            "pronunciation_ids": "pronunciation",
        }
        count_fields = {
            "scenario_ids": "scenario_count",
            "scenario_quest_ids": "scenario_quest_count",
            "smalltalk_ids": "smalltalk_count",
            "cloze_ids": "cloze_count",
            "satz_ids": "satz_count",
            "pronunciation_ids": "pronunciation_count",
        }

        def base_pack_id(value: str) -> str:
            return re.sub(r"_\d+$", "", value)

        for number, row in enumerate(rows, start=2):
            label = row.get("seed_id") or f"row {number}"
            level = row.get("level", "")
            if level not in LEVELS or not re.fullmatch(rf"seed_{level.lower()}_[a-z0-9_]+", label):
                self.issue(source, f"{label}: seed_id and level disagree")
            brief = briefs.get(row.get("brief_id", ""))
            if brief is None:
                self.issue(source, f"{label}: unknown brief_id")
            else:
                for seed_field, brief_field in (
                    ("level", "level"),
                    ("course_unit_id", "course_unit_id"),
                    ("concept_ids", "concept_ids"),
                    ("grammar_ids", "grammar_targets"),
                ):
                    if row.get(seed_field) != brief.get(brief_field):
                        self.issue(source, f"{label}: {seed_field} disagrees with brief")
            unit_id = row.get("course_unit_id", "")
            concepts = set(self.split_ids(row.get("concept_ids", "")))
            if unit_id not in units or not concepts or not concepts.issubset(units.get(unit_id, set())):
                self.issue(source, f"{label}: invalid course unit or concept mapping")
            vocab_ids = self.split_ids(row.get("vocab_ids", ""))
            if not vocab_ids:
                self.issue(source, f"{label}: vocab_ids cannot be empty")
            for ident in vocab_ids:
                live = vocab.get(ident)
                if live is None or live.get("level") != level:
                    self.issue(source, f"{label}: vocab {ident!r} is missing or wrong-level")
            grammar_ids = self.split_ids(row.get("grammar_ids", ""))
            if not grammar_ids:
                self.issue(source, f"{label}: grammar_ids cannot be empty")
            for ident in grammar_ids:
                live = grammar.get(ident)
                if live is None or live.get("level") != level:
                    self.issue(source, f"{label}: grammar {ident!r} is missing or wrong-level")
            for field, pattern in patterns.items():
                planned = self.split_ids(row.get(field, ""))
                count_field = count_fields[field]
                count = row.get(count_field, "")
                if not self.is_positive_int(count) or int(count) != len(planned):
                    self.issue(source, f"{label}: {count_field} must equal its reserved ID count")
                for ident in planned:
                    if not re.fullmatch(pattern, ident):
                        self.issue(source, f"{label}: invalid {field} value {ident!r}")
                    if ident in reserved[field]:
                        self.issue(source, f"{label}: duplicate reservation {ident!r}")
                    reserved[field].add(ident)
                    if field not in {"scenario_ids", "scenario_quest_ids"} and not ident.startswith(
                        field.removesuffix("_ids").replace("pronunciation", "pronunciation") + "_" + level.lower()
                    ):
                        self.issue(source, f"{label}: {ident!r} has the wrong level")

            planned_by_kind = {
                kind: self.split_ids(row.get(field, "")) for field, kind in kinds.items()
            }
            for kind, planned in planned_by_kind.items():
                planned_set = set(planned)
                authored = {
                    ident
                    for ident, record in content[kind].items()
                    if record.get("sourceSeedId") == label
                }
                if authored != planned_set:
                    self.issue(
                        source,
                        f"{label}: reserved {kind} IDs do not exactly match sourceSeedId records",
                    )
                for ident in planned:
                    record = content[kind].get(ident)
                    if record is None:
                        self.issue(source, f"{label}: {kind} {ident!r} is not live or in an active draft")
                        continue
                    if record.get("sourceSeedId") != label:
                        self.issue(source, f"{label}: {kind} {ident!r} has the wrong sourceSeedId")
                    if record.get("level") != level.lower():
                        self.issue(source, f"{label}: {kind} {ident!r} has the wrong level")
                    if record.get("courseUnitId") != unit_id:
                        self.issue(source, f"{label}: {kind} {ident!r} has the wrong course unit")
                    if {str(value) for value in record.get("conceptIds", [])} != concepts:
                        self.issue(source, f"{label}: {kind} {ident!r} conceptIds disagree")

            smalltalk_map = routing.get("smalltalkCategoryUnitMap")
            cloze_map = routing.get("clozeTopicUnitMap")
            pack_map = routing.get("vocabPackUnitMap")
            for ident in planned_by_kind["smalltalk"]:
                record = content["smalltalk"].get(ident, {})
                key = f"{level.lower()}:{str(record.get('category') or '').lower()}"
                rule = smalltalk_map.get(key) if isinstance(smalltalk_map, dict) else None
                if not isinstance(rule, dict) or rule.get("courseUnitId") != unit_id:
                    self.issue(source, f"{label}: smalltalk {ident!r} is not routed to its course unit")
                elif {str(value) for value in rule.get("conceptIds", [])} != concepts:
                    self.issue(source, f"{label}: smalltalk {ident!r} route concepts disagree")
            for ident in planned_by_kind["cloze"]:
                record = content["cloze"].get(ident, {})
                key = f"{level.lower()}:{str(record.get('topic') or '').lower()}"
                mapped = cloze_map.get(key) if isinstance(cloze_map, dict) else None
                if mapped != unit_id:
                    self.issue(source, f"{label}: cloze {ident!r} is not routed to its course unit")
            for ident in planned_by_kind["satz"]:
                record = content["satz"].get(ident, {})
                source_vocab = [
                    item
                    for item in vocab.values()
                    if item.get("level") == level and item.get("korean") == record.get("vocabKo")
                ]
                if len(source_vocab) != 1:
                    self.issue(source, f"{label}: satz {ident!r} needs one exact same-level vocab source")
                    continue
                pack = base_pack_id(source_vocab[0].get("pack_id", ""))
                mapped = pack_map.get(pack) if isinstance(pack_map, dict) else None
                if mapped != unit_id:
                    self.issue(source, f"{label}: satz {ident!r} source vocab is routed to another unit")

            planned_scenarios = self.split_ids(row.get("scenario_ids", ""))
            planned_quests = set(self.split_ids(row.get("scenario_quest_ids", "")))
            actual_quests: set[str] = set()
            actual_types: set[str] = set()
            canonical_id = row.get("canonical_scenario_id", "")
            if canonical_id not in planned_scenarios:
                self.issue(source, f"{label}: canonical_scenario_id must be one of scenario_ids")
            turn_raw = row.get("canonical_dialog_turn", "")
            if not self.is_positive_int(turn_raw):
                self.issue(source, f"{label}: canonical_dialog_turn must be positive")
            canonical_ko = ""
            for ident in planned_scenarios:
                scenario = content["scenario"].get(ident)
                if scenario is None:
                    self.issue(source, f"{label}: scenario {ident!r} is not live or in an active draft")
                    continue
                if set(str(value) for value in scenario.get("grammarIds", [])) != set(grammar_ids):
                    self.issue(source, f"{label}: scenario {ident!r} grammarIds disagree")
                expected_vocab = {vocab[ident]["korean"] for ident in vocab_ids if ident in vocab}
                actual_vocab = {
                    str(value.get("korean"))
                    for value in scenario.get("vocab", [])
                    if isinstance(value, dict)
                }
                if actual_vocab != expected_vocab:
                    self.issue(source, f"{label}: scenario {ident!r} vocab does not match vocab_ids")
                if ident == canonical_id and self.is_positive_int(turn_raw):
                    dialog = scenario.get("dialog")
                    turn = int(turn_raw)
                    if not isinstance(dialog, list) or turn > len(dialog):
                        self.issue(source, f"{label}: canonical dialog turn is outside the scenario")
                    elif not isinstance(dialog[turn - 1], dict) or not isinstance(dialog[turn - 1].get("ko"), str):
                        self.issue(source, f"{label}: canonical dialog turn needs Korean text")
                    else:
                        canonical_ko = str(dialog[turn - 1]["ko"])
                target_by_type: dict[str, list[str]] = {}
                for quest in scenario.get("quests", []):
                    if not isinstance(quest, dict):
                        continue
                    quest_id = quest.get("id")
                    quest_type = quest.get("type")
                    if not isinstance(quest_id, str) or not quest_id:
                        self.issue(source, f"{label}: scenario {ident!r} has an unstably identified quest")
                        continue
                    actual_quests.add(quest_id)
                    if isinstance(quest_type, str):
                        actual_types.add(quest_type)
                    quest_concepts = {str(value) for value in quest.get("conceptIds", [])}
                    if quest_concepts != concepts:
                        self.issue(source, f"{label}: quest {quest_id!r} conceptIds disagree")
                    data = quest.get("data")
                    if isinstance(data, dict) and quest_type in {"satzBauen", "diktat"}:
                        target = data.get("targetKo")
                        if isinstance(target, str):
                            target_by_type.setdefault(str(quest_type), []).append(target)
                    if isinstance(data, dict) and quest_type == "luecken":
                        sentence = data.get("sentence")
                        options = data.get("options")
                        index = data.get("correctIndex")
                        if (
                            isinstance(sentence, str)
                            and isinstance(options, list)
                            and isinstance(index, int)
                            and 0 <= index < len(options)
                            and isinstance(options[index], str)
                        ):
                            target_by_type.setdefault("luecken", []).append(
                                sentence.replace("___", options[index], 1)
                            )
                canonical_targets = {
                    target
                    for values in target_by_type.values()
                    for target in values
                }
                if {"luecken", "satzBauen", "diktat"}.issubset(target_by_type):
                    if canonical_targets != {canonical_ko}:
                        self.issue(
                            source,
                            f"{label}: scenario cloze, Satzbau, and dictation must equal the canonical dialog KO",
                        )
            if actual_quests != planned_quests:
                self.issue(source, f"{label}: scenario_quest_ids do not match the scenario draft")
            if brief is not None:
                expected_types = set(self.split_ids(brief.get("game_targets", "")))
                if actual_types != expected_types:
                    self.issue(source, f"{label}: scenario quest types disagree with game_targets")
            for kind, field in (
                ("cloze", "fullKo"),
                ("satz", "targetKo"),
                ("pronunciation", "ko"),
            ):
                records = [
                    content[kind].get(ident, {}) for ident in planned_by_kind[kind]
                ]
                canonical_records = [
                    record for record in records if record.get(field) == canonical_ko
                ]
                if len(canonical_records) != 1:
                    self.issue(source, f"{label}: {kind} needs exactly one canonical KO derivative")
                elif canonical_records[0].get("canonicalScenarioId") != canonical_id:
                    self.issue(source, f"{label}: canonical {kind} derivative has the wrong scenario marker")
            if row.get("course_exposure") != (
                "scenario_smalltalk_cloze_satz_graph_and_exact_library;"
                "pronunciation_cumulative"
            ):
                self.issue(source, f"{label}: invalid course_exposure")
            if not row.get("derivation_contract", ""):
                self.issue(source, f"{label}: derivation_contract cannot be empty")
            if row.get("review_status") not in {"draft", "approved"}:
                self.issue(source, f"{label}: invalid review_status")

    def validate(self) -> list[Issue]:
        source_rows = self.read_csv("source_inventory.csv", SOURCE_HEADER)
        page_rows = self.read_csv("page_audit.csv", PAGE_HEADER)
        observation_rows = self.read_csv("reference_observations.csv", OBSERVATION_HEADER)
        brief_rows = self.read_csv("content_briefs.csv", BRIEF_HEADER)
        seed_rows = self.read_csv("seed_bundle_plan.csv", SEED_HEADER)
        vocab, grammar, units, routing = self.load_live()
        content = self.load_available_content()
        sources = self.validate_sources(source_rows)
        audits = self.validate_pages(page_rows, sources)
        self.validate_observations(observation_rows, sources, audits)
        briefs = self.validate_briefs(brief_rows, grammar, units)
        self.validate_seeds(seed_rows, briefs, vocab, grammar, units, routing, content)
        return self.issues


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit machine-readable output")
    args = parser.parse_args()
    issues = ReferenceIntakeValidator().validate()
    if args.json:
        print(json.dumps({"ok": not issues, "issues": [asdict(issue) for issue in issues]}, ensure_ascii=False, indent=2))
    elif issues:
        for issue in issues:
            print(f"ERROR: {issue.source}: {issue.message}")
    else:
        print("OK: reference intake quarantine, clean-room briefs, and game bundle links are consistent")
    return 1 if issues else 0


if __name__ == "__main__":
    raise SystemExit(main())
