"""Prevent sentence-sized tiles and partial writes during authored materialization."""

import copy
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import materialize_canonical_scenarios as materializer


def dialogue():
    return [
        {"speaker": speaker, "ko": ko, "de": de, "en": en}
        for speaker, ko, de, en in [
            ("sujin", "여기 줄이에요.", "Hier ist die Schlange.", "Here's the line."),
            ("user", "뒤에 설게요.", "Ich stelle mich hinten an.", "I'll join at the back."),
            ("sujin", "빵이 맛있어요.", "Das Brot schmeckt gut.", "The bread is tasty."),
            ("user", "저도 좋아해요.", "Ich mag es auch.", "I like it too."),
            ("sujin", "천천히 고르세요.", "Wählen Sie in Ruhe.", "Take your time choosing."),
            ("user", "이 빵 주세요.", "Dieses Brot bitte.", "This bread, please."),
        ]
    ]


class AuthoredWordTileTests(unittest.TestCase):
    def setUp(self):
        self.spec = {"targetKo": "이 빵 주세요.", "distractors": ["커피", "마셔요", "어제"]}

    def test_missing_authored_tiles_rejects_old_sentence_fallback(self):
        with self.assertRaisesRegex(materializer.AuthoredSourceError, "sentenceBuild"):
            materializer._quests("bakery", dialogue(), ["ordering"])

    def test_explicit_tiles_and_user_translations_are_preserved(self):
        quest = materializer._quests("bakery", dialogue(), ["ordering"], self.spec)[-1]
        self.assertEqual(quest["data"]["distractors"], self.spec["distractors"])
        self.assertEqual(quest["data"]["audioKo"], self.spec["targetKo"])
        self.assertEqual(quest["data"]["promptDe"], dialogue()[-1]["de"])
        self.assertEqual(quest["data"]["promptEn"], dialogue()[-1]["en"])
        self.assertEqual(quest["conceptIds"], ["ordering"])

    def test_unsafe_tile_sets_are_rejected(self):
        for tiles in [
            ["커피 마셔요", "마셔요", "어제"],
            ["커피\n마셔요", "마셔요", "어제"],
            ["커피", "커피", "어제"],
            ["빵", "마셔요", "어제"],
            ["커피.", "마셔요", "어제"],
            [" 커피", "마셔요", "어제"],
            ["", "마셔요", "어제"],
            ["?", "마셔요", "어제"],
            [1, "마셔요", "어제"],
            ["커피", "어제"],
            "커피 마셔요 어제",
        ]:
            with self.subTest(tiles=tiles):
                spec = dict(self.spec, distractors=tiles)
                with self.assertRaises(materializer.AuthoredSourceError):
                    materializer._quests("bakery", dialogue(), ["ordering"], spec)

    def test_stale_or_other_speaker_target_is_rejected(self):
        for target in ["이 빵을 주세요.", dialogue()[0]["ko"], dialogue()[1]["ko"]]:
            with self.subTest(target=target):
                with self.assertRaisesRegex(materializer.AuthoredSourceError, "targetKo"):
                    materializer._quests("bakery", dialogue(), [], dict(self.spec, targetKo=target))

    def test_learner_repeating_another_speaker_remains_a_production_target(self):
        lines = dialogue()
        lines.append(dict(lines[0], speaker="user"))
        spec = dict(self.spec, targetKo=lines[-1]["ko"])
        quest = materializer._quests("bakery", lines, [], spec)[-1]
        self.assertEqual(quest["data"]["targetKo"], lines[-1]["ko"])
        with self.assertRaisesRegex(materializer.AuthoredSourceError, "targetKo"):
            materializer._quests("bakery", lines, [], self.spec)

    def test_repeated_learner_line_has_no_duplicate_translation_options(self):
        lines = [dict(line, speaker="sujin") for line in dialogue()]
        lines.append(dict(lines[0], speaker="user"))
        spec = dict(self.spec, targetKo=lines[-1]["ko"])
        quests = materializer._quests("bakery", lines, [], spec)
        options = [option["ko"] for option in quests[1]["data"]["options"]]
        self.assertEqual(len(set(options)), 4)
        self.assertEqual(options[0], lines[-1]["ko"])

    def test_no_learner_turn_is_a_clear_source_error(self):
        lines = [dict(line, speaker="sujin") for line in dialogue()]
        with self.assertRaisesRegex(materializer.AuthoredSourceError, "learner"):
            materializer._quests("bakery", lines, [], self.spec)

    def test_materialize_one_consumes_authored_tiles(self):
        sources = materializer.pipeline.load_sources(materializer.ROOT)
        brief = next(item for item in sources.briefs if item.level == "a1")
        authored = materializer._load_authored(materializer.AUTHORED_DIR / "a1.json")
        source = copy.deepcopy(next(item for item in authored if item["id"] == brief.scenario_id))
        target = [line for line in materializer._dialog(source, brief) if line["speaker"] == "user"][-1]
        source["sentenceBuild"] = {"targetKo": target["ko"], "distractors": ["어제", "커피", "마셔요"]}
        candidate = materializer.materialize_one(
            source=source, brief=brief, sources=sources,
            concepts_by_unit=materializer._concepts_by_unit(materializer.ROOT),
            grammar_patterns=materializer._load_grammar_patterns(materializer.ROOT),
        )
        self.assertEqual(candidate["scenario"]["quests"][-1]["data"]["distractors"], source["sentenceBuild"]["distractors"])


class MaterializationPreflightTests(unittest.TestCase):
    def test_late_invalid_source_cannot_partially_overwrite_review_files(self):
        briefs = [SimpleNamespace(level="a1", scenario_id=name) for name in ["first", "second"]]
        sources = SimpleNamespace(briefs=briefs)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            target = root / "review" / "a1"
            target.mkdir(parents=True)
            original = target / "first.json"
            original.write_bytes(b'{"review": "already approved"}\n')
            before = {path.name: path.read_bytes() for path in target.iterdir()}
            with (
                patch.object(materializer, "_load_authored", return_value=[{"id": "first"}, {"id": "second"}]),
                patch.object(materializer.pipeline, "load_sources", return_value=sources),
                patch.object(materializer, "_load_grammar_patterns", return_value=[]),
                patch.object(materializer, "_concepts_by_unit", return_value={}),
                patch.object(materializer, "materialize_one", side_effect=[{"scenarioId": "first"}, materializer.AuthoredSourceError("second: missing sentenceBuild")]),
            ):
                with self.assertRaisesRegex(materializer.AuthoredSourceError, "second"):
                    materializer.materialize_level(level="a1", root=root, output=Path("review"))
            self.assertEqual({path.name: path.read_bytes() for path in target.iterdir()}, before)


if __name__ == "__main__":
    unittest.main()
