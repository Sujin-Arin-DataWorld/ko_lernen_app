from __future__ import annotations

import csv
import json
import tempfile
import unittest
from pathlib import Path

from tool.build_curriculum_backlog import BacklogError, build_backlog, build_markdown, main


MATRIX_HEADERS = ["level", "axis", "id", "label", "status", "evidence", "suggested_action"]
FINDING_HEADERS = ["check", "severity", "level", "phase", "subject", "detail", "action"]
GRAMMAR_HEADERS = ["grade", "category", "form", "variants", "meaning", "band_2stage", "band_1to4"]


def write_csv(path: Path, headers: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=headers)
        writer.writeheader()
        writer.writerows(rows)


def phase(phase_id: str, text_id: str, word: str, level: str = "A1") -> dict:
    return {
        "id": phase_id,
        "level": level,
        "textTypes": [{"id": text_id, "use": "R/P"}],
        "vocabDomains": [{"id": "domain", "sampleLexis": [{"ko": word}]}],
    }


class BuildCurriculumBacklogTest(unittest.TestCase):
    def test_source_hashes_ignore_checkout_line_endings(self) -> None:
        before = build_backlog(self.root)
        for relative in before["sourceSha256"]:
            source = self.root / relative
            source.write_bytes(source.read_bytes().replace(b"\r\n", b"\n"))
        after = build_backlog(self.root)
        self.assertEqual(before, after)

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        matrix_rows = [
            {"level": "A1", "axis": "grammar_nikl", "id": "은1", "label": "조사", "status": "missing_in_app", "evidence": "nikl", "suggested_action": "review"},
            {"level": "A1", "axis": "grammar_nikl", "id": "은2", "label": "어미", "status": "missing_in_app", "evidence": "nikl", "suggested_action": "review"},
            {"level": "A1", "axis": "grammar_anchor", "id": "anchor_only", "label": "앵커 후보", "status": "no_scenario_anchor", "evidence": "not in scenario/media", "suggested_action": "review"},
            {"level": "A1", "axis": "text_type", "id": "genre_shared", "label": "공유 장르", "status": "structural_gap", "evidence": "mode=R/P;count=0", "suggested_action": "place"},
            {"level": "A1", "axis": "text_type", "id": "genre_shared", "label": "공유 장르", "status": "structural_gap", "evidence": "mode=R/P;count=0", "suggested_action": "place"},
        ]
        write_csv(self.root / "tool/curriculum_matrix_gaps.csv", MATRIX_HEADERS, matrix_rows)
        finding_rows = [
            {"check": "C18_surface", "severity": "warn", "level": "A1", "phase": "KP01", "subject": "KP01 · genre_shared", "detail": "surface", "action": "place"},
            {"check": "C18_surface", "severity": "warn", "level": "A1", "phase": "KP02", "subject": "KP02 · genre_shared", "detail": "surface", "action": "place"},
            {"check": "C18_surface", "severity": "warn", "level": "A1", "phase": "KP01", "subject": "KP01 · genre_phase_only", "detail": "surface", "action": "place"},
            {"check": "C11_depth", "severity": "warn", "level": "", "phase": "", "subject": "topics", "detail": "breadth", "action": "review"},
        ]
        write_csv(self.root / "tool/learning_phase_findings.csv", FINDING_HEADERS, finding_rows)
        write_csv(self.root / "tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv", GRAMMAR_HEADERS, [
            {"grade": "1", "category": "조사", "form": "은1", "variants": "", "meaning": "", "band_2stage": "", "band_1to4": ""},
            {"grade": "1", "category": "어미", "form": "은2", "variants": "", "meaning": "", "band_2stage": "", "band_1to4": ""},
        ])
        phases = {"phases": [phase("KP01", "genre_shared", "반복어"), phase("KP02", "genre_shared", "반복어")]}
        phases["phases"][0]["textTypes"].append({"id": "genre_phase_only", "use": "R"})
        for relative, value in [
            ("tools/content_factory/cefr_matrix/phases.json", phases),
            ("tools/content_factory/cefr_matrix/ko.json", {"language": "ko"}),
            ("tool/learning_phase_summary.json", {"lexis": {"missingUnique": 1, "missingWords": ["반복어"], "sampleLexisTotal": 2}}),
        ]:
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(value, ensure_ascii=False), encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_joins_without_double_counting_or_automatic_missing_claims(self) -> None:
        backlog = build_backlog(self.root)
        items = {item["workKey"]: item for item in backlog["items"]}
        self.assertEqual(set(items), {
            "*|phase_depth_metadata|topics|unassigned",
            "A1|grammar_nikl|G1:은1|unassigned",
            "A1|grammar_nikl|G1:은2|unassigned",
            "A1|grammar_anchor|anchor_only|unassigned",
            "A1|sample_lexis|반복어|unassigned",
            "A1|text_type|genre_phase_only|R",
            "A1|text_type|genre_shared|P",
            "A1|text_type|genre_shared|R",
        })
        shared_r = items["A1|text_type|genre_shared|R"]
        self.assertEqual(len([ref for ref in shared_r["sourceReferences"] if ref["path"].endswith("curriculum_matrix_gaps.csv")]), 2)
        self.assertEqual(shared_r["phaseIds"], ["KP01", "KP02"])
        self.assertEqual(items["A1|text_type|genre_phase_only|R"]["phaseIds"], ["KP01"])
        self.assertEqual(items["A1|grammar_nikl|G1:은1|unassigned"]["classifications"], [])
        self.assertEqual(
            items["A1|grammar_nikl|G1:은1|unassigned"]["provisionalClassifications"],
            ["content_missing", "existing_unlinked", "matching_error"],
        )
        anchor = items["A1|grammar_anchor|anchor_only|unassigned"]
        self.assertEqual(anchor["classifications"], [])
        self.assertEqual(anchor["provisionalClassifications"], ["runtime_missing"])
        self.assertEqual(items["*|phase_depth_metadata|topics|unassigned"]["classificationStatus"], "informational")
        self.assertEqual(items["*|phase_depth_metadata|topics|unassigned"]["classifications"], [])
        contexts = items["A1|sample_lexis|반복어|unassigned"]["sampleLexisContexts"]
        self.assertEqual([context["phaseId"] for context in contexts], ["KP01", "KP02"])
        self.assertEqual(backlog["counts"]["uniqueMissingSampleWords"], 1)
        self.assertEqual(backlog["counts"]["sampleWordContextOccurrences"], 2)
        self.assertEqual(backlog["counts"]["warningsMerged"], 3)
        self.assertEqual(backlog["counts"]["warningRequirementReferencesMerged"], 5)

    def test_determinism_check_and_stale_gate(self) -> None:
        first = build_backlog(self.root)
        self.assertEqual(first, build_backlog(self.root))
        self.assertEqual(main(["--root", str(self.root), "--check"]), 1)
        json_path = self.root / "tool/curriculum_completion_backlog.json"
        markdown_path = self.root / "docs/data/curriculum_completion_backlog.md"
        json_path.write_bytes((json.dumps(first, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8"))
        markdown_path.parent.mkdir(parents=True, exist_ok=True)
        markdown_path.write_bytes(build_markdown(first).encode("utf-8"))
        self.assertEqual(main(["--root", str(self.root), "--check"]), 0)
        (self.root / "tool/curriculum_matrix_gaps.csv").write_text("bad\n", encoding="utf-8")
        self.assertEqual(main(["--root", str(self.root), "--check"]), 1)

    def test_rejects_missing_word_without_exact_phase_context(self) -> None:
        path = self.root / "tool/learning_phase_summary.json"
        path.write_text(json.dumps({"lexis": {"missingUnique": 1, "missingWords": ["없는말"], "sampleLexisTotal": 2}}, ensure_ascii=False), encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "no Phase occurrence"):
            build_backlog(self.root)

    def test_rejects_invalid_phase_use_and_headers(self) -> None:
        phases_path = self.root / "tools/content_factory/cefr_matrix/phases.json"
        phases = json.loads(phases_path.read_text(encoding="utf-8"))
        phases["phases"][0]["textTypes"][0]["use"] = "RP"
        phases_path.write_text(json.dumps(phases, ensure_ascii=False), encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "invalid Phase-use"):
            build_backlog(self.root)
        phases["phases"][0]["textTypes"][0]["use"] = "R/P"
        phases_path.write_text(json.dumps(phases, ensure_ascii=False), encoding="utf-8")
        (self.root / "tool/curriculum_matrix_gaps.csv").write_text("wrong\n", encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "malformed CSV headers"):
            build_backlog(self.root)

    def test_rejects_truncated_matrix_row_through_cli(self) -> None:
        (self.root / "tool/curriculum_matrix_gaps.csv").write_text(
            ",".join(MATRIX_HEADERS) + "\nA1,topic,id,label,status\n", encoding="utf-8"
        )
        self.assertEqual(main(["--root", str(self.root), "--check"]), 1)

    def test_rejects_invalid_explicit_text_type_mode(self) -> None:
        path = self.root / "tool/curriculum_matrix_gaps.csv"
        path.write_text(path.read_text(encoding="utf-8").replace("mode=R/P", "mode=Q"), encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "invalid explicit text_type mode"):
            build_backlog(self.root)

    def test_rejects_missing_text_type_mode_through_cli(self) -> None:
        path = self.root / "tool/curriculum_matrix_gaps.csv"
        path.write_text(path.read_text(encoding="utf-8").replace("mode=R/P;", ""), encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "missing required text_type mode"):
            build_backlog(self.root)
        self.assertEqual(main(["--root", str(self.root), "--check"]), 1)

    def test_rejects_null_phase_nested_arrays(self) -> None:
        path = self.root / "tools/content_factory/cefr_matrix/phases.json"
        phases = json.loads(path.read_text(encoding="utf-8"))
        phases["phases"][0]["vocabDomains"] = None
        path.write_text(json.dumps(phases, ensure_ascii=False), encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "invalid vocabDomains"):
            build_backlog(self.root)
        phases["phases"][0]["vocabDomains"] = [{"id": "domain", "sampleLexis": None}]
        path.write_text(json.dumps(phases, ensure_ascii=False), encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "invalid sampleLexis"):
            build_backlog(self.root)

    def test_rejects_c18_prefix_mismatch_and_sample_total_contradiction(self) -> None:
        findings_path = self.root / "tool/learning_phase_findings.csv"
        original_findings = findings_path.read_text(encoding="utf-8")
        findings_path.write_text(
            original_findings.replace("KP01 · genre_shared", "KP02 · genre_shared", 1),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(BacklogError, "C18 subject phase does not match"):
            build_backlog(self.root)
        findings_path.write_text(original_findings, encoding="utf-8")
        summary_path = self.root / "tool/learning_phase_summary.json"
        summary = json.loads(summary_path.read_text(encoding="utf-8"))
        summary["lexis"]["sampleLexisTotal"] = 999999
        summary_path.write_text(json.dumps(summary, ensure_ascii=False), encoding="utf-8")
        with self.assertRaisesRegex(BacklogError, "inconsistent sampleLexisTotal"):
            build_backlog(self.root)


if __name__ == "__main__":
    unittest.main()
