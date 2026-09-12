import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("curriculum_context_inventory.py")
SPEC = importlib.util.spec_from_file_location("curriculum_context_inventory", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class CurriculumContextInventoryTest(unittest.TestCase):
    def fixture(self, *, scenarios=None, media=None, grammar="g1,a1\n") -> Path:
        root = Path(self.enterContext(tempfile.TemporaryDirectory()))
        data = root / "assets" / "data"
        data.mkdir(parents=True)
        (data / "grammar.csv").write_text("id,level\n" + grammar, encoding="utf-8")
        for level in ("a1", "a2", "b1", "b2", "c1", "c2"):
            if scenarios is not None and level == "a1":
                (data / f"scenarios_{level}.json").write_text(
                    json.dumps({"version": 1, "scenarios": scenarios}, ensure_ascii=False),
                    encoding="utf-8",
                )
        if media is not None:
            (data / "media_phrases.json").write_text(
                json.dumps({"version": 1, "phrases": media}, ensure_ascii=False),
                encoding="utf-8",
            )
        return root

    def test_heading_only_record_has_no_context(self):
        root = self.fixture(
            scenarios=[{"id": "heading", "level": "a1", "grammarIds": ["g1"], "dialog": []}]
        )
        result = MODULE.build_inventory(root)
        self.assertEqual(result["passages"], [])
        self.assertEqual(result["declaredCandidateGrammarLinks"], [])
        self.assertEqual(result["knownGrammarIdsWithoutCandidate"], ["g1"])

    def test_dialogue_is_exact_candidate_with_pointer(self):
        root = self.fixture(
            scenarios=[
                {
                    "id": "scene",
                    "level": "a1",
                    "grammarIds": ["g1"],
                    "title": {"ko": "제목"},
                    "dialog": [{"speaker": "user", "ko": "그대로 남겨요", "de": "", "en": ""}],
                }
            ]
        )
        result = MODULE.build_inventory(root)
        passage = result["passages"][0]
        self.assertEqual(passage["text"], "그대로 남겨요")
        self.assertEqual(passage["jsonPointer"], "/scenarios/0/dialog/0/ko")
        self.assertEqual(result["verifiedAnchors"], [])
        self.assertEqual(result["stage"], "candidate_only")
        self.assertEqual(result["declaredCandidateGrammarLinks"][0]["grammarId"], "g1")

    def test_blank_media_is_not_context(self):
        root = self.fixture(media=[{"id": "m", "level": "A1", "korean": "", "grammar_ids": ["g1"]}])
        result = MODULE.build_inventory(root)
        self.assertEqual(result["passages"], [])
        self.assertEqual(result["knownGrammarIdsWithoutCandidate"], ["g1"])

    def test_dangling_grammar_is_visible(self):
        root = self.fixture(
            scenarios=[
                {
                    "id": "scene",
                    "level": "a1",
                    "grammarIds": ["missing"],
                    "dialog": [{"ko": "문장"}],
                }
            ]
        )
        result = MODULE.build_inventory(root)
        self.assertEqual(result["declaredCandidateGrammarLinks"][0]["grammarId"], "missing")
        self.assertEqual(result["unknownDeclaredGrammarIds"][0]["grammarId"], "missing")
        self.assertEqual(result["knownGrammarIdsWithoutCandidate"], ["g1"])

    def test_duplicate_and_malformed_sources_are_rejected(self):
        duplicate = self.fixture(
            scenarios=[
                {"id": "same", "level": "a1", "grammarIds": [], "dialog": []},
                {"id": "same", "level": "a1", "grammarIds": [], "dialog": []},
            ]
        )
        with self.assertRaises(ValueError):
            MODULE.build_inventory(duplicate)
        malformed = self.fixture(scenarios={"not": "a list"})
        with self.assertRaises(ValueError):
            MODULE.build_inventory(malformed)

    def test_result_is_deterministic_and_optional_files_are_diagnostic(self):
        root = self.fixture(media=None, scenarios=[])
        first = MODULE.build_inventory(root)
        second = MODULE.build_inventory(root)
        self.assertEqual(first, second)
        self.assertEqual(
            first["diagnostics"]["missingOptionalFiles"],
            [
                "assets/data/scenarios_a2.json",
                "assets/data/scenarios_b1.json",
                "assets/data/scenarios_b2.json",
                "assets/data/scenarios_c1.json",
                "assets/data/scenarios_c2.json",
                "assets/data/media_phrases.json",
            ],
        )

    def test_path_escape_is_rejected_when_symlinks_are_supported(self):
        root = self.fixture(scenarios=[])
        outside = Path(self.enterContext(tempfile.TemporaryDirectory())) / "grammar.csv"
        outside.write_text("id,level\ng1,a1\n", encoding="utf-8")
        target = root / "assets" / "data" / "grammar.csv"
        target.unlink()
        try:
            target.symlink_to(outside)
        except (OSError, NotImplementedError):
            self.skipTest("symlink creation is unavailable")
        with self.assertRaises(ValueError):
            MODULE.build_inventory(root)


if __name__ == "__main__":
    unittest.main()
