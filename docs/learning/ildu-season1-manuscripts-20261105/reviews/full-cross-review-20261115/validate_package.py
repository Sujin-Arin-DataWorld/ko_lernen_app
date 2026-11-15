"""Read-only manuscript checks; writes evidence only inside this review folder.

This checks identities, source preservation, indices, links, tables and review
freshness. It cannot certify meaning, level suitability, listening or teaching.
"""
from pathlib import Path
from collections import Counter
from datetime import datetime, timezone
import argparse
import csv
import hashlib
import json
import re
import subprocess

HERE = Path(__file__).resolve().parent
BOOK = HERE.parent.parent
REPO = BOOK.parents[2]
ROLES = ("ko-en", "ko-de", "curriculum")
COMMON_DOCS = ("README.md", "AUTHORING_BRIEF.md", "READER_INTRODUCTION.md", "SERIES_EDITORIAL_MAP.md", "TERM_AND_TRANSLATION_NOTES.md", "CURRICULUM_REUSE_NOTES.md")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def git(*args):
    return subprocess.run(
        ["git", "-C", str(REPO), *args], capture_output=True, check=True
    ).stdout


def slug(value):
    value = re.sub(r"<[^>]*>", "", value).lower()
    return re.sub(r"[^\w\- ]", "", value).replace(" ", "-")


def validate(require_reviews=False):
    mapping = read_json(BOOK / "sources/LEVEL_STORY_100.json")
    units = mapping["units"]
    ids = [u["unit_id"] for u in units]
    problems = []
    warnings = []
    paths = {p.stem: p for p in (BOOK / "manuscripts").glob("*.md")}
    expected_bands = {"F0.1": 3, "F0.2": 7, "F0.3": 11, "F0.4": 7}
    expected_bands.update({f"{level}.{part}": 6 for level in ("A1", "A2", "B1", "B2", "C1", "C2") for part in (1, 2)})
    if len(ids) != 100 or len(set(ids)) != 100 or set(ids) != set(paths):
        problems.append({"kind": "unit_ids", "missing": sorted(set(ids)-set(paths)), "unexpected": sorted(set(paths)-set(ids))})
    band_counts = dict(Counter(u["band"] for u in units))
    if band_counts != expected_bands:
        problems.append({"kind": "band_counts", "actual": band_counts})
    curriculum_ids = []
    for name in ("FOUNDATION.psv", "UNITS.psv"):
        with (BOOK / "sources" / name).open(encoding="utf-8-sig", newline="") as stream:
            curriculum_ids.extend(row["id"] for row in csv.DictReader(stream, delimiter="|"))
    if len(curriculum_ids) != 100 or set(curriculum_ids) != set(ids):
        problems.append({"kind": "curriculum_ids"})
    archive = read_json(BOOK / "CHECKPOINT_ARCHIVE.json")
    for name, expected in archive["files"].items():
        if name.startswith("sources/") and sha(BOOK / name) != expected:
            problems.append({"kind": "source_mutated", "path": name})
    index = {u["unitId"]: u for u in read_json(BOOK / "MANUSCRIPT_INDEX.json")["units"]}
    inventory = {u["id"]: u for u in read_json(BOOK / "DRAFT_INVENTORY.json")["units"]}
    hashes = {key: sha(path) for key, path in paths.items()}
    for unit in units:
        key = unit["unit_id"]
        if key not in paths:
            continue
        text = paths[key].read_text(encoding="utf-8-sig")
        if key not in text.splitlines()[0]:
            problems.append({"kind": "title_id", "unitId": key})
        gate = unit["spoiler_gate"]["this_scene_gate"]
        if gate not in text:
            problems.append({"kind": "gate_literal", "unitId": key, "expected": gate})
        if index.get(key, {}).get("sha256") != hashes[key] or inventory.get(key, {}).get("draftSha256") != hashes[key]:
            problems.append({"kind": "stale_index", "unitId": key})
        if index.get(key, {}).get("gate") != gate or inventory.get(key, {}).get("readCondition") != gate:
            problems.append({"kind": "index_gate", "unitId": key})
    common = [BOOK / name for name in ("README.md", "INDEX.md", "AUTHORING_BRIEF.md", "READER_INTRODUCTION.md", "SERIES_EDITORIAL_MAP.md", "TERM_AND_TRANSLATION_NOTES.md", "CURRICULUM_REUSE_NOTES.md")]
    link_count = table_rows = 0
    for path in list(paths.values()) + common:
        text = path.read_text(encoding="utf-8-sig")
        expected_width = None
        details_depth = 0
        for number, line in enumerate(text.splitlines(), 1):
            details_depth += line.count("<details>") - line.count("</details>")
            if details_depth < 0:
                problems.append({"kind": "unexpected_details_close", "path": path.relative_to(BOOK).as_posix(), "line": number})
            if line.startswith("|") and line.endswith("|"):
                width = len(re.split(r"(?<!\\)\|", line)) - 2
                if expected_width is None:
                    expected_width = width
                if width != expected_width:
                    problems.append({"kind": "table_width", "path": path.relative_to(BOOK).as_posix(), "line": number})
                table_rows += 1
            else:
                expected_width = None
        if details_depth:
            problems.append({"kind": "unclosed_details", "path": path.relative_to(BOOK).as_posix()})
        if any(marker in text for marker in ("<<<<<<<", ">>>>>>>", "\x00")):
            problems.append({"kind": "corrupt_text_marker", "path": path.relative_to(BOOK).as_posix()})
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", text):
            target = target.strip("<>")
            if re.match(r"(?:https?|mailto|plugin|app|codex):", target):
                continue
            local, _, anchor = target.partition("#")
            if re.match(r"[A-Za-z]:[/\\]", local):
                warnings.append({"kind": "external_local_reference", "path": path.relative_to(BOOK).as_posix(), "target": target})
                continue
            destination = path.parent / local if local else path
            link_count += 1
            if not destination.exists():
                problems.append({"kind": "missing_link", "path": path.relative_to(BOOK).as_posix(), "target": target})
            elif anchor and destination.suffix == ".md":
                content = destination.read_text(encoding="utf-8-sig")
                anchors = set(re.findall(r'<a\s+(?:id|name)="([^"]+)"', content))
                anchors.update(slug(line.lstrip("# ")) for line in content.splitlines() if line.startswith("#"))
                if anchor not in anchors:
                    problems.append({"kind": "missing_anchor", "path": path.relative_to(BOOK).as_posix(), "target": target})
    quotes = read_json(BOOK / "reviews/first-four-cross-review-20261114/CANON_QUOTES_BEFORE.json")["canonicalQuotes"]
    first = paths["F0.1.sound-signs"].read_text(encoding="utf-8-sig")
    for quote in quotes:
        if quote["ko"] not in first:
            problems.append({"kind": "canonical_quote_missing", "quote": quote["ko"]})
    coverage = {}
    common_coverage = {}
    for role in ROLES:
        read_units = {}
        for report in sorted((HERE / role).glob("*.json")):
            if report.name.startswith("COMMON"):
                continue
            data = read_json(report)
            for row in data.get("units", []):
                if row.get("unitId") in ids:
                    read_units[row["unitId"]] = {**row, "report": report.relative_to(BOOK).as_posix()}
        # Final reviews override initial reports explicitly, including the
        # separately owned KO-DE C2 final review. Summary ordering is irrelevant.
        for final in sorted((HERE / role).glob("FINAL*.json")):
            for row in read_json(final).get("units", []):
                if row.get("unitId") in ids:
                    read_units[row["unitId"]] = {**row, "report": final.relative_to(BOOK).as_posix()}
        missing = [key for key in ids if key not in read_units]
        stale = [key for key, row in read_units.items() if row.get("sha256") != hashes.get(key)]
        unsettled = [key for key, row in read_units.items() if row.get("verdict") != "PASS" or not row.get("fullTextRead") or not row.get("tasksSolvedAsText")]
        coverage[role] = {"read": len(read_units), "missing": missing, "stale": stale, "unsettled": unsettled, "units": read_units}
        if require_reviews and (missing or stale or unsettled):
            problems.append({"kind": "review_not_complete", "role": role, "missing": missing, "stale": stale, "unsettled": unsettled})
        documents = {}
        for name in ("COMMON.json", "COMMON_FINAL.json"):
            report = HERE / role / name
            if not report.exists():
                continue
            data = read_json(report)
            for row in data.get("documents", []) + data.get("units", []):
                key = row.get("file", row.get("unitId"))
                if key in COMMON_DOCS:
                    documents[key] = {**row, "report": report.relative_to(BOOK).as_posix()}
        missing_common = [name for name in COMMON_DOCS if name not in documents]
        stale_common = [name for name, row in documents.items() if row.get("sha256") != sha(BOOK / name)]
        unsettled_common = [name for name, row in documents.items() if row.get("verdict") != "PASS" or not row.get("fullTextRead")]
        common_coverage[role] = {"read": len(documents), "missing": missing_common, "stale": stale_common, "unsettled": unsettled_common, "documents": documents}
        if require_reviews and (missing_common or stale_common or unsettled_common):
            problems.append({"kind": "common_review_not_complete", "role": role, "missing": missing_common, "stale": stale_common, "unsettled": unsettled_common})
    journal = read_json(HERE / "EDITOR_DECISIONS.json")
    decisions = {row["id"]: row for row in journal["findingDecisions"]}
    required_findings = {}
    for role in ROLES:
        for report in sorted((HERE / role).glob("*.json")):
            data = read_json(report)
            for finding in data.get("findings", []) + data.get("resolvedFindings", []) + data.get("resolvedFinalFindings", []):
                if finding.get("severity") == "required":
                    required_findings[finding["id"]] = finding
    for decision in journal["findingDecisions"]:
        if decision.get("severity") == "required":
            required_findings.setdefault(decision["id"], decision)
    unresolved = [key for key in required_findings if decisions.get(key, {}).get("state") != "closed_after_independent_review"]
    if require_reviews and unresolved:
        problems.append({"kind": "required_findings_unresolved", "ids": unresolved})
    changes = git("diff", "3594a000b0ee3c255ed50890efa34c05c1c38d0c", "--name-only").decode().splitlines()
    changes += git("ls-files", "--others", "--exclude-standard").decode().splitlines()
    allowed_prefix = "docs/learning/ildu-season1-manuscripts-20261105/"
    plan = "docs/superpowers/plans/2026-11-15-season1-manuscript-cross-review.md"
    forbidden = [name for name in changes if not name.startswith(allowed_prefix) and name != plan]
    if forbidden:
        problems.append({"kind": "outside_document_scope", "paths": forbidden})
    result = {"checkedUtc": datetime.now(timezone.utc).isoformat(), "mode": "final" if require_reviews else "structure_and_progress", "units": len(paths), "bands": band_counts, "canonicalQuotesPreserved": len(quotes), "tableRowsChecked": table_rows, "localLinksChecked": link_count, "sourceHashChecks": 4, "problems": problems, "warnings": warnings, "reviewCoverage": coverage, "commonReviewCoverage": common_coverage, "requiredFindings": len(required_findings), "unresolvedRequiredFindings": unresolved, "finalSha256": hashes, "humanReviewComplete": False, "actualAudioVerified": False, "synthesisPerformed": False, "appModifiedByThisTask": False, "limitations": "Mechanical integrity only; semantic evidence is in the three independent role reports. No runtime, audio or student validation."}
    output = HERE / ("FINAL_VALIDATION.json" if require_reviews else "STRUCTURE_AND_PROGRESS.json")
    temporary = output.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="")
    assert read_json(temporary) == result
    temporary.replace(output)
    print(json.dumps({"units": len(paths), "problems": problems, "reviews": {role: data["read"] for role, data in coverage.items()}, "output": str(output)}, ensure_ascii=False))
    return not problems


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-reviews", action="store_true")
    options = parser.parse_args()
    raise SystemExit(0 if validate(options.require_reviews) else 1)
