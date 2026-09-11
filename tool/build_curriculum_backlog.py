"""Build a deterministic, review-first W0b3 curriculum triage backlog.

The backlog joins diagnostics; it does not claim completed curriculum, a card
count, or a requirement denominator.  In particular, automatic grammar
diagnostics remain candidates until semantic review supplies evidence.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


LEVELS = ("A1", "A2", "B1", "B2", "C1", "C2")
LEVEL_GRADE = dict(zip(LEVELS, range(1, 7)))
REQUIRED_CSV_HEADERS = {
    "curriculum_matrix_gaps.csv": (
        "level", "axis", "id", "label", "status", "evidence", "suggested_action"
    ),
    "learning_phase_findings.csv": (
        "check", "severity", "level", "phase", "subject", "detail", "action"
    ),
    "nikl_kiiq_2017_grammar.csv": (
        "grade", "category", "form", "variants", "meaning", "band_2stage", "band_1to4"
    ),
}
REQUIRED_CSV_VALUES = {
    "curriculum_matrix_gaps.csv": REQUIRED_CSV_HEADERS["curriculum_matrix_gaps.csv"],
    "learning_phase_findings.csv": ("check", "severity", "subject", "detail", "action"),
    "nikl_kiiq_2017_grammar.csv": ("grade", "category", "form"),
}
SOURCE_PATHS = (
    "tool/curriculum_matrix_gaps.csv",
    "tool/learning_phase_findings.csv",
    "tool/learning_phase_summary.json",
    "tools/content_factory/cefr_matrix/phases.json",
    "tools/content_factory/cefr_matrix/ko.json",
    "tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv",
)
VALID_CLASSIFICATIONS = {
    "matching_error", "existing_unlinked", "wrong_level_or_sense", "draft_only",
    "content_missing", "assessment_missing", "runtime_missing",
}
MODE_RE = re.compile(r"(?:^|;)mode=(R/P|R|P)(?:;|$)")
EXPLICIT_MODE_RE = re.compile(r"(?:^|;)mode=([^;]*)(?:;|$)")


class BacklogError(ValueError):
    """An input cannot safely produce a reproducible backlog."""


def _inside(root: Path, relative: str) -> Path:
    root = root.resolve()
    candidate = (root / relative).resolve()
    try:
        candidate.relative_to(root)
    except ValueError as exc:
        raise BacklogError(f"path escapes root: {relative}") from exc
    return candidate


def _read_bytes(root: Path, relative: str) -> bytes:
    path = _inside(root, relative)
    if not path.is_file():
        raise BacklogError(f"missing required input: {relative}")
    return path.read_bytes()


def _read_json(root: Path, relative: str) -> Any:
    try:
        return json.loads(_read_bytes(root, relative).decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise BacklogError(f"invalid JSON: {relative}: {exc}") from exc


def _read_csv(root: Path, relative: str) -> list[dict[str, str]]:
    try:
        text = _read_bytes(root, relative).decode("utf-8-sig")
        reader = csv.DictReader(text.splitlines())
        expected = REQUIRED_CSV_HEADERS[Path(relative).name]
        if reader.fieldnames != list(expected):
            raise BacklogError(
                f"malformed CSV headers in {relative}: expected {list(expected)!r}, got {reader.fieldnames!r}"
            )
        rows = list(reader)
    except UnicodeDecodeError as exc:
        raise BacklogError(f"invalid UTF-8 CSV: {relative}") from exc
    required_values = REQUIRED_CSV_VALUES[Path(relative).name]
    for row_number, row in enumerate(rows, start=2):
        if None in row or any(value is None for value in row.values()):
            raise BacklogError(f"malformed CSV row in {relative} at row {row_number}")
        if any(not row[field] for field in required_values):
            raise BacklogError(f"missing required CSV value in {relative} at row {row_number}")
    return rows


def _hashes(root: Path) -> dict[str, str]:
    return {relative: hashlib.sha256(_read_bytes(root, relative)).hexdigest() for relative in SOURCE_PATHS}


def _mode(evidence: str) -> list[str]:
    explicit = EXPLICIT_MODE_RE.search(evidence)
    if not explicit:
        raise BacklogError("missing required text_type mode")
    if explicit and explicit.group(1) not in {"R", "P", "R/P"}:
        raise BacklogError(f"invalid explicit text_type mode: {explicit.group(1)!r}")
    match = MODE_RE.search(evidence)
    if not match:
        return ["unassigned"]
    value = match.group(1)
    return ["R", "P"] if value == "R/P" else [value]


def _validate_phases(phases_doc: Any) -> list[dict[str, Any]]:
    if not isinstance(phases_doc, dict) or not isinstance(phases_doc.get("phases"), list):
        raise BacklogError("invalid phases.json structure: phases list is required")
    phases = phases_doc["phases"]
    seen_phase_ids: set[str] = set()
    seen_text_type_modes: set[tuple[str, str, str]] = set()
    for index, phase in enumerate(phases):
        if not isinstance(phase, dict):
            raise BacklogError(f"invalid phase at /phases/{index}")
        phase_id, level = phase.get("id"), phase.get("level")
        if not isinstance(phase_id, str) or not phase_id or level not in LEVELS:
            raise BacklogError(f"invalid phase id or level at /phases/{index}")
        if phase_id in seen_phase_ids:
            raise BacklogError(f"duplicate contradictory phase id: {phase_id}")
        seen_phase_ids.add(phase_id)
        text_types = phase.get("textTypes", [])
        if not isinstance(text_types, list):
            raise BacklogError(f"invalid textTypes at /phases/{index}")
        for text_index, text_type in enumerate(text_types):
            if not isinstance(text_type, dict) or not isinstance(text_type.get("id"), str):
                raise BacklogError(f"invalid textType at /phases/{index}/textTypes/{text_index}")
            use = text_type.get("use")
            if use not in {"R", "P", "R/P"}:
                raise BacklogError(
                    f"invalid Phase-use mode at /phases/{index}/textTypes/{text_index}: {use!r}"
                )
            for mode in ("R", "P") if use == "R/P" else (use,):
                key = (phase_id, text_type["id"], mode)
                if key in seen_text_type_modes:
                    raise BacklogError(f"duplicate contradictory phase text type: {key}")
                seen_text_type_modes.add(key)
        vocab_domains = phase.get("vocabDomains", [])
        if not isinstance(vocab_domains, list):
            raise BacklogError(f"invalid vocabDomains at /phases/{index}")
        for domain_index, domain in enumerate(vocab_domains):
            if not isinstance(domain, dict):
                raise BacklogError(f"invalid vocabDomain at /phases/{index}/vocabDomains/{domain_index}")
            sample_lexis = domain.get("sampleLexis", [])
            if not isinstance(sample_lexis, list):
                raise BacklogError(
                    f"invalid sampleLexis at /phases/{index}/vocabDomains/{domain_index}"
                )
    return phases


def _grammar_keys(root: Path) -> dict[tuple[int, str], str]:
    rows = _read_csv(root, "tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv")
    result: dict[tuple[int, str], str] = {}
    for row in rows:
        try:
            grade = int(row["grade"])
        except ValueError as exc:
            raise BacklogError("invalid NIKL grammar grade") from exc
        form = row["form"]
        if grade not in range(1, 7) or not form:
            raise BacklogError("invalid NIKL grammar source row")
        key = (grade, form)
        if key in result:
            raise BacklogError(f"duplicate contradictory NIKL grammar key: G{grade}:{form}")
        result[key] = f"G{grade}:{form}"
    return result


def _classification(axis: str, status: str) -> tuple[list[str], list[str], str, str]:
    """Return confirmed, provisional, review status, and Korean guidance."""
    if axis == "grammar_nikl" and status == "missing_in_app":
        return (
            [], ["matching_error", "existing_unlinked", "content_missing"], "needs_review",
            "자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.",
        )
    if status == "structural_gap":
        return (
            ["runtime_missing"], [], "needs_review",
            "앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.",
        )
    if status == "no_scenario_anchor":
        return (
            [], ["runtime_missing"], "needs_review",
            "현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.",
        )
    if status == "level_mismatch":
        return (
            [], ["wrong_level_or_sense"], "needs_review",
            "레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.",
        )
    if status in {"missing", "thin", "recognition_missing", "absent"}:
        return (
            [], ["existing_unlinked", "content_missing", "assessment_missing"], "needs_review",
            "진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.",
        )
    return ([], [], "needs_review", "근거를 검토해 처리 상태를 결정합니다.")


def _item_key(level: str, axis: str, requirement_id: str, mode: str) -> str:
    return "|".join((level, axis, requirement_id, mode))


def _source_ref(path: str, row_number: int | None = None, pointer: str | None = None) -> dict[str, Any]:
    value: dict[str, Any] = {"path": path}
    if row_number is not None:
        value["csvRow"] = row_number
    if pointer is not None:
        value["jsonPointer"] = pointer
    return value


def build_backlog(root: Path) -> dict[str, Any]:
    """Read inputs below *root* and return deterministic JSON-compatible data."""
    root = root.resolve()
    hashes = _hashes(root)
    matrix_rows = _read_csv(root, "tool/curriculum_matrix_gaps.csv")
    finding_rows = _read_csv(root, "tool/learning_phase_findings.csv")
    summary = _read_json(root, "tool/learning_phase_summary.json")
    phases = _validate_phases(_read_json(root, "tools/content_factory/cefr_matrix/phases.json"))
    ko = _read_json(root, "tools/content_factory/cefr_matrix/ko.json")
    if not isinstance(ko, dict):
        raise BacklogError("invalid ko.json structure")
    grammar_keys = _grammar_keys(root)

    lexis = summary.get("lexis") if isinstance(summary, dict) else None
    if not isinstance(lexis, dict) or not isinstance(lexis.get("missingWords"), list):
        raise BacklogError("invalid learning_phase_summary.json lexis.missingWords")
    missing_words = lexis["missingWords"]
    if not all(isinstance(word, str) and word for word in missing_words):
        raise BacklogError("invalid missing word")
    if len(set(missing_words)) != len(missing_words) or lexis.get("missingUnique") != len(missing_words):
        raise BacklogError("inconsistent missingUnique count")
    if not isinstance(lexis.get("sampleLexisTotal"), int):
        raise BacklogError("invalid sampleLexisTotal count")

    items: dict[str, dict[str, Any]] = {}
    diagnostic_counts = Counter()

    def add(
        level: str, axis: str, requirement_id: str, mode: str, *, label: str,
        source: dict[str, Any], reason: str, action: str, classifications: list[str],
        provisional: list[str], classification_status: str, guidance: str,
        phase_id: str | None = None, warning_check: str | None = None,
    ) -> None:
        if level not in LEVELS and level != "*":
            raise BacklogError(f"unknown level: {level}")
        if mode not in {"R", "P", "unassigned"}:
            raise BacklogError(f"invalid mode: {mode}")
        if not set(classifications).issubset(VALID_CLASSIFICATIONS) or not set(provisional).issubset(VALID_CLASSIFICATIONS):
            raise BacklogError("invalid classification")
        key = _item_key(level, axis, requirement_id, mode)
        item = items.setdefault(key, {
            "workKey": key, "level": level, "axis": axis, "id": requirement_id, "mode": mode,
            "labels": [], "reasons": [], "suggestedActions": [], "sourceReferences": [],
            "phaseIds": [], "warningChecks": [], "classifications": [],
            "provisionalClassifications": [], "classificationStatus": classification_status,
            "koreanGuidance": guidance,
        })
        for field, value in (("labels", label), ("reasons", reason), ("suggestedActions", action)):
            if value and value not in item[field]:
                item[field].append(value)
        if source not in item["sourceReferences"]:
            item["sourceReferences"].append(source)
        for value in classifications:
            if value not in item["classifications"]:
                item["classifications"].append(value)
        for value in provisional:
            if value not in item["provisionalClassifications"]:
                item["provisionalClassifications"].append(value)
        if phase_id and phase_id not in item["phaseIds"]:
            item["phaseIds"].append(phase_id)
        if warning_check and warning_check not in item["warningChecks"]:
            item["warningChecks"].append(warning_check)

    for row_number, row in enumerate(matrix_rows, start=2):
        level, axis, requirement_id = row["level"], row["axis"], row["id"]
        if level not in LEVELS and level != "*":
            raise BacklogError(f"unknown matrix level at row {row_number}: {level}")
        if not axis or not requirement_id:
            raise BacklogError(f"missing matrix identity at row {row_number}")
        modes = _mode(row["evidence"]) if axis == "text_type" else ["unassigned"]
        level_for_item = level
        if axis == "grammar_nikl":
            if level_for_item == "*":
                raise BacklogError(f"grammar_nikl row {row_number} cannot be cross-level")
            grade = LEVEL_GRADE[level_for_item]
            grammar_key = grammar_keys.get((grade, requirement_id))
            if grammar_key is None:
                raise BacklogError(
                    f"grammar_nikl row {row_number} has no exact NIKL key for level {level_for_item}: {requirement_id}"
                )
            requirement_id = grammar_key
        classifications, provisional, review_status, guidance = _classification(axis, row["status"])
        diagnostic_counts["matrixRows"] += 1
        for mode in modes:
            add(level_for_item, axis, requirement_id, mode, label=row["label"],
                source=_source_ref("tool/curriculum_matrix_gaps.csv", row_number),
                reason=f"{row['status']}: {row['evidence']}", action=row["suggested_action"],
                classifications=classifications, provisional=provisional,
                classification_status=review_status, guidance=guidance)

    phase_by_id = {phase["id"]: phase for phase in phases}
    phase_text_types: dict[tuple[str, str, str], int] = {}
    word_contexts: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for phase_index, phase in enumerate(phases):
        for text_index, text_type in enumerate(phase.get("textTypes", [])):
            for mode in ("R", "P") if text_type["use"] == "R/P" else (text_type["use"],):
                phase_text_types[(phase["id"], text_type["id"], mode)] = text_index
        for domain_index, domain in enumerate(phase["vocabDomains"]):
            for word_index, sample in enumerate(domain["sampleLexis"]):
                if not isinstance(sample, dict) or not isinstance(sample.get("ko"), str) or not sample["ko"]:
                    raise BacklogError("invalid sampleLexis entry")
                word_contexts[sample["ko"]].append({
                    "phaseId": phase["id"], "level": phase["level"], "domainId": domain.get("id"),
                    "jsonPointer": f"/phases/{phase_index}/vocabDomains/{domain_index}/sampleLexis/{word_index}/ko",
                })
    phase_sample_lexis_total = sum(len(contexts) for contexts in word_contexts.values())
    if lexis["sampleLexisTotal"] != phase_sample_lexis_total:
        raise BacklogError(
            f"inconsistent sampleLexisTotal count: summary={lexis['sampleLexisTotal']}, phases={phase_sample_lexis_total}"
        )

    for row_number, row in enumerate(finding_rows, start=2):
        check, level, phase_id = row["check"], row["level"], row["phase"]
        if level not in LEVELS and not (check == "C11_depth" and level == ""):
            raise BacklogError(f"invalid phase finding level at row {row_number}")
        if phase_id and (phase_id not in phase_by_id or phase_by_id[phase_id]["level"] != level):
            raise BacklogError(f"invalid phase finding at row {row_number}")
        source = _source_ref("tool/learning_phase_findings.csv", row_number)
        if check == "C18_surface":
            diagnostic_counts["c18WarningRows"] += 1
            try:
                subject_phase_id, text_id = row["subject"].split(" · ", 1)
            except ValueError as exc:
                raise BacklogError(f"invalid C18 subject at row {row_number}") from exc
            if subject_phase_id != phase_id:
                raise BacklogError(
                    f"C18 subject phase does not match phase column at row {row_number}: "
                    f"{subject_phase_id} != {phase_id}"
                )
            found = [(mode, pointer) for (found_phase, found_id, mode), pointer in phase_text_types.items()
                     if found_phase == phase_id and found_id == text_id]
            if not found:
                raise BacklogError(f"C18 warning has no matching phase text type at row {row_number}")
            for mode, text_index in sorted(found):
                add(level, "text_type", text_id, mode, label=text_id, source=source,
                    reason=f"{check}: {row['detail']}", action=row["action"],
                    classifications=["runtime_missing"], provisional=[], classification_status="needs_review",
                    guidance="Phase 장르의 앱 표면/배치 경로가 없다는 경고입니다. 실제 자료·평가 결손은 별도 검토합니다.",
                    phase_id=phase_id, warning_check=check)
                item = items[_item_key(level, "text_type", text_id, mode)]
                phase_source = _source_ref(
                    "tools/content_factory/cefr_matrix/phases.json",
                    pointer=f"/phases/{phases.index(phase_by_id[phase_id])}/textTypes/{text_index}",
                )
                if phase_source not in item["sourceReferences"]:
                    item["sourceReferences"].append(phase_source)
                diagnostic_counts["c18RequirementReferences"] += 1
            continue
        if check == "C11_depth":
            diagnostic_counts["c11DepthRows"] += 1
            add(level or "*", "phase_depth_metadata", row["subject"], "unassigned", label=row["subject"], source=source,
                reason=f"{check}: {row['detail']}", action="향후 과제 기반 깊이 검증으로 확인한다.",
                classifications=[], provisional=[], classification_status="informational",
                guidance="C11_depth는 고급 Phase의 폭 비교 정보입니다. 콘텐츠 결손 할당량이 아니며 과제 기반 깊이 검증으로 다룹니다.",
                phase_id=phase_id, warning_check=check)
            continue
        diagnostic_counts["otherPhaseFindingRows"] += 1
        add(level, "phase_warning", f"{check}:{row['subject']}", "unassigned", label=row["subject"], source=source,
            reason=f"{check}: {row['detail']}", action=row["action"], classifications=[],
            provisional=[], classification_status="needs_review",
            guidance="Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.",
            phase_id=phase_id, warning_check=check)

    missing_contexts = 0
    for word_index, word in enumerate(missing_words):
        contexts = word_contexts.get(word, [])
        if not contexts:
            raise BacklogError(f"missing source word has no Phase occurrence: {word}")
        levels = sorted({context["level"] for context in contexts}, key=LEVELS.index)
        # Vocabulary candidate is global by word. Its level is a neutral, explicit namespace marker.
        item_level = levels[0]
        add(item_level, "sample_lexis", word, "unassigned", label=word,
            source=_source_ref("tool/learning_phase_summary.json", pointer=f"/lexis/missingWords/{word_index}"),
            reason="sampleLexis missing from current app vocabulary audit", action="Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.",
            classifications=[], provisional=["existing_unlinked", "content_missing"], classification_status="needs_review",
            guidance="Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.")
        item = items[_item_key(item_level, "sample_lexis", word, "unassigned")]
        item["sampleLexisContexts"] = sorted(contexts, key=lambda x: (LEVELS.index(x["level"]), x["phaseId"], x["domainId"], x["jsonPointer"]))
        missing_contexts += len(contexts)
        diagnostic_counts["missingSampleWordEntries"] += 1

    ordered_items = []
    for key in sorted(items):
        item = items[key]
        for field in ("labels", "reasons", "suggestedActions", "phaseIds", "warningChecks", "classifications", "provisionalClassifications"):
            item[field] = sorted(item[field])
        item["sourceReferences"] = sorted(item["sourceReferences"], key=lambda x: (x["path"], x.get("csvRow", -1), x.get("jsonPointer", "")))
        ordered_items.append(item)

    mode_requirements = Counter(item["mode"] for item in ordered_items)
    level_context_counts = Counter(context["level"] for word in missing_words for context in word_contexts[word])
    return {
        "schemaVersion": 1,
        "purpose": "W0b3 review-first triage queue; not completed curriculum, a definitive missing-card count, or a full requirement denominator.",
        "sourceSha256": hashes,
        "counts": {
            "diagnosticRows": {key: diagnostic_counts[key] for key in sorted(diagnostic_counts)},
            "uniqueWorkItems": len(ordered_items),
            "modeRequirements": {key: mode_requirements[key] for key in sorted(mode_requirements)},
            "warningsMerged": diagnostic_counts["c18WarningRows"],
            "warningRequirementReferencesMerged": diagnostic_counts["c18RequirementReferences"],
            "warningsInformational": diagnostic_counts["c11DepthRows"],
            "uniqueMissingSampleWords": len(missing_words),
            "sampleWordContextOccurrences": missing_contexts,
            "sampleWordContextsByLevel": {key: level_context_counts[key] for key in LEVELS if level_context_counts[key]},
        },
        "classificationVocabulary": sorted(VALID_CLASSIFICATIONS),
        "items": ordered_items,
    }


def build_markdown(backlog: dict[str, Any]) -> str:
    counts = backlog["counts"]
    lines = [
        "# Curriculum completion triage backlog",
        "",
        "> 이 목록은 W0b3의 검토용 분류 큐입니다. 완료된 교육과정, 확정된 카드 누락 수, 전체 요구 분모를 뜻하지 않습니다.",
        "",
        f"- 고유 작업 항목: {counts['uniqueWorkItems']}",
        f"- 고유 sampleLexis 후보: {counts['uniqueMissingSampleWords']} (Phase×단어 맥락 {counts['sampleWordContextOccurrences']})",
        f"- Phase C18 병합 경고 참조: {counts['warningsMerged']}; C11 정보성 참조: {counts['warningsInformational']}",
        "- 자동 문법 진단은 의미·원 급·기존 연결 검토 전 확정 결손이 아닙니다.",
        "",
        "## Source hashes",
        "",
    ]
    lines.extend(f"- `{path}`: `{digest}`" for path, digest in backlog["sourceSha256"].items())
    lines.extend(["", "## Work items", ""])
    for item in backlog["items"]:
        labels = "; ".join(item["labels"])
        lines.extend([
            f"### `{item['workKey']}`",
            "",
            f"- 항목: {labels}",
            f"- 상태: {item['classificationStatus']}; 확정 분류: {', '.join(item['classifications']) or '없음'}; 후보: {', '.join(item['provisionalClassifications']) or '없음'}",
            f"- 안내: {item['koreanGuidance']}",
            f"- 조치: {'; '.join(item['suggestedActions'])}",
            f"- 근거: {' | '.join(item['reasons'])}",
            "",
        ])
    return "\n".join(lines)


def _outputs(root: Path) -> tuple[Path, Path]:
    return (_inside(root, "tool/curriculum_completion_backlog.json"), _inside(root, "docs/data/curriculum_completion_backlog.md"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--check", action="store_true", help="verify generated files without writing")
    args = parser.parse_args(argv)
    try:
        backlog = build_backlog(args.root)
        json_bytes = (json.dumps(backlog, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")
        markdown_bytes = build_markdown(backlog).encode("utf-8")
        json_path, markdown_path = _outputs(args.root.resolve())
        if args.check:
            stale = [str(path) for path, expected in ((json_path, json_bytes), (markdown_path, markdown_bytes))
                     if not path.is_file() or path.read_bytes() != expected]
            if stale:
                raise BacklogError("stale or missing generated output: " + ", ".join(stale))
        else:
            json_path.parent.mkdir(parents=True, exist_ok=True)
            markdown_path.parent.mkdir(parents=True, exist_ok=True)
            json_path.write_bytes(json_bytes)
            markdown_path.write_bytes(markdown_bytes)
    except BacklogError as exc:
        print(f"build_curriculum_backlog: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
