from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tool.curriculum_evidence_inventory import build_inventory


ROOT = Path(__file__).resolve().parents[1]
RELATIVE = Path("tools/content_factory/drafts/productive_assessments.json")


def write_fixture(root: Path, data: dict) -> None:
    target = root / RELATIVE
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def fixture(**overrides):
    data = {
        "schemaVersion": 1,
        "runtimeContentApproved": False,
        "definitions": [
            {
                "assessmentItemId": "assess_a1",
                "level": "a1",
                "grammarReferenceIds": ["G1:-지 않다"],
                "authoredContextExamples": ["오늘은 운동을 안 해요."],
                "textRubric": {"requiredSourceSnippetIds": ["snippet_1"]},
            }
        ],
        "projects": [{"id": "project_a1", "steps": [{"snippetIds": ["snippet_1"]}]}],
        "sourceSnippets": [{"id": "snippet_1", "level": "a1", "text": {"ko": "오늘은 운동을 안 해요."}}],
    }
    data.update(overrides)
    return data


def resolve_pointer(document, pointer):
    value = document
    for token in pointer.lstrip("/").split("/"):
        value = value[int(token)] if isinstance(value, list) else value[token]
    return value


class CurriculumEvidenceInventoryTest(unittest.TestCase):
    def test_real_draft_counts_and_levels(self):
        inventory = build_inventory(ROOT)
        self.assertEqual(inventory["counts"]["definitions"], 118)
        self.assertEqual(inventory["counts"]["projects"], 8)
        self.assertEqual(inventory["counts"]["sourceSnippets"], 32)
        self.assertEqual(inventory["counts"]["byLevel"]["A1"]["definition"], 16)
        self.assertEqual(inventory["counts"]["published"], 0)
        self.assertEqual(inventory["counts"]["assessable"], 0)

    def test_repeated_snippet_references_are_not_records(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = fixture()
            data["projects"][0]["steps"].append({"snippetIds": ["snippet_1"]})
            write_fixture(root, data)
            inventory = build_inventory(root)
            self.assertEqual(inventory["counts"]["sourceSnippets"], 1)
            self.assertEqual(inventory["counts"]["projects"], 1)

    def test_duplicate_primary_ids_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for key, id_field in (
                ("definitions", "assessmentItemId"),
                ("projects", "id"),
                ("sourceSnippets", "id"),
            ):
                data = fixture()
                data[key].append(dict(data[key][0]))
                write_fixture(root, data)
                with self.assertRaises(ValueError):
                    build_inventory(root)

    def test_blank_primary_ids_are_rejected(self):
        for key, id_field in (
            ("definitions", "assessmentItemId"),
            ("projects", "id"),
            ("sourceSnippets", "id"),
        ):
            with self.subTest(key=key):
                with tempfile.TemporaryDirectory() as directory:
                    root = Path(directory)
                    data = fixture()
                    data[key][0][id_field] = " \t"
                    write_fixture(root, data)
                    with self.assertRaises(ValueError):
                        build_inventory(root)

    def test_unknown_level_is_rejected_and_missing_level_is_unassigned(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = fixture()
            data["definitions"][0]["level"] = "c3"
            write_fixture(root, data)
            with self.assertRaises(ValueError):
                build_inventory(root)
            data = fixture()
            del data["sourceSnippets"][0]["level"]
            write_fixture(root, data)
            self.assertEqual(build_inventory(root)["counts"]["unassigned"]["source_snippet"], 1)

    def test_approval_flag_does_not_grant_credit_and_examples_are_retained(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = fixture(runtimeContentApproved=True)
            write_fixture(root, data)
            inventory = build_inventory(root)
            self.assertTrue(inventory["metadata"]["declaredRuntimeContentApproved"])
            self.assertEqual(inventory["counts"]["assessable"], 0)
            definition = next(item for item in inventory["records"] if item["kind"] == "definition")
            self.assertEqual(definition["authoredContextExamples"], ["오늘은 운동을 안 해요."])
            self.assertEqual(definition["sourceSnippetIds"], ["snippet_1"])
            self.assertNotIn("authoredContextExamples", next(item for item in inventory["records"] if item["kind"] == "project"))
            self.assertNotIn("authoredContextExamples", next(item for item in inventory["records"] if item["kind"] == "source_snippet"))
            self.assertTrue(all(not record["runtimeLinked"] for record in inventory["records"]))
            self.assertTrue(all(not record["assessable"] for record in inventory["records"]))

    def test_connected_evidence_source_ids_are_retained_once_in_order(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = fixture()
            data["definitions"][0].pop("textRubric")
            data["definitions"][0]["connectedEvidenceRubric"] = {
                "requiredSourceSnippetIds": ["required"],
                "relationshipRequirements": [
                    {"oneOfSourceSnippetIds": ["nested_b", "nested_a", "nested_b"]},
                ],
            }
            write_fixture(root, data)
            inventory = build_inventory(root)
            definition = next(item for item in inventory["records"] if item["kind"] == "definition")
            self.assertEqual(
                definition["sourceSnippetIds"],
                ["nested_a", "nested_b", "required"],
            )

    def test_whitespace_examples_and_source_text_are_rejected(self):
        for update in (
            lambda data: data["definitions"][0].update({"authoredContextExamples": [" \t"]}),
            lambda data: data["sourceSnippets"][0]["text"].update({"ko": "\n"}),
        ):
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                data = fixture()
                update(data)
                write_fixture(root, data)
                with self.assertRaises(ValueError):
                    build_inventory(root)

    def test_original_source_text_and_pointer_are_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = fixture()
            del data["definitions"][0]["authoredContextExamples"]
            data["definitions"][0].update({"title": "한국어 제목", "prompt": "한국어 안내"})
            data["definitions"].append(
                {
                    "assessmentItemId": "assess_a0",
                    "level": "a2",
                    "grammarReferenceIds": [],
                    "textRubric": {"requiredSourceSnippetIds": ["snippet_1"]},
                }
            )
            data["projects"].append(
                {"id": "project_a0", "steps": [{"snippetIds": ["snippet_1"]}]}
            )
            data["sourceSnippets"].append(
                {"id": "snippet_0", "level": "a2", "text": {"ko": "두 번째 원문"}}
            )
            data["sourceSnippets"][0]["text"]["ko"] = "  원문 그대로  "
            write_fixture(root, data)
            inventory = build_inventory(root)
            records = {(record["kind"], record["id"]): record for record in inventory["records"]}
            self.assertEqual(
                [(record["kind"], record["id"]) for record in inventory["records"]],
                sorted((record["kind"], record["id"]) for record in inventory["records"]),
            )
            self.assertNotIn("authoredContextExamples", records[("definition", "assess_a1")])
            self.assertEqual(records[("source_snippet", "snippet_1")]["sourceKoreanText"], "  원문 그대로  ")
            primary_fields = {
                "definition": "assessmentItemId",
                "project": "id",
                "source_snippet": "id",
            }
            source_arrays = {
                "definition": "definitions",
                "project": "projects",
                "source_snippet": "sourceSnippets",
            }
            for (kind, record_id), record in records.items():
                pointer = record["source"]["jsonPointer"]
                referenced = resolve_pointer(data, pointer)
                self.assertEqual(record["source"]["recordIndex"], int(pointer.rsplit("/", 1)[1]))
                self.assertEqual(referenced[primary_fields[kind]], record_id)
                self.assertIs(referenced, data[source_arrays[kind]][record["source"]["recordIndex"]])

    def test_unsupported_schema_versions_are_rejected(self):
        for version in (0, 2, True):
            with self.subTest(version=version):
                with tempfile.TemporaryDirectory() as directory:
                    root = Path(directory)
                    write_fixture(root, fixture(schemaVersion=version))
                    with self.assertRaises(ValueError):
                        build_inventory(root)

    def test_ordering_is_deterministic_and_input_is_untouched(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = fixture()
            write_fixture(root, data)
            target = root / RELATIVE
            before = target.read_bytes()
            first = build_inventory(root)
            second = build_inventory(root)
            self.assertEqual(first, second)
            self.assertEqual(target.read_bytes(), before)
            self.assertEqual(
                [(record["kind"], record["id"]) for record in first["records"]],
                sorted((record["kind"], record["id"]) for record in first["records"]),
            )

    def test_missing_and_malformed_input_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(ValueError):
                build_inventory(root)
            target = root / RELATIVE
            target.parent.mkdir(parents=True)
            target.write_text("{", encoding="utf-8")
            with self.assertRaises(ValueError):
                build_inventory(root)

            for replacement in ([], {"schemaVersion": 1}):
                target.write_text(json.dumps(replacement), encoding="utf-8")
                with self.assertRaises(ValueError):
                    build_inventory(root)

    def test_input_symlink_escape_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            root = base / "root"
            outside = base / "outside.json"
            root_target = root / RELATIVE
            root_target.parent.mkdir(parents=True)
            outside.write_text(json.dumps(fixture()), encoding="utf-8")
            try:
                root_target.symlink_to(outside)
            except OSError:
                self.skipTest("OS denied symlink creation")
            with self.assertRaises(ValueError):
                build_inventory(root)


if __name__ == "__main__":
    unittest.main()
