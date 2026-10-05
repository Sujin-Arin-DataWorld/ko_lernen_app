from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools/content_factory/extract_scenario_key_vocab.py"
SPEC = importlib.util.spec_from_file_location("extract_scenario_key_vocab", MODULE_PATH)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class ExtractScenarioKeyVocabTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.result = module.build(
            scenarios_path=ROOT / "tools/content_factory/drafts/persona_culture_scenarios_20261005.json",
            culture_links_path=ROOT / "tools/content_factory/drafts/persona_culture_links_20261005.json",
            glossary_path=ROOT / "docs/data/cultural_glossary.json",
            live_vocab_path=ROOT / "assets/data/korean_vocab.csv",
        )
        cls.checked = json.loads(
            (
                ROOT
                / "tools/content_factory/review/persona_culture_vocab_leveling_20261005.json"
            ).read_text(encoding="utf-8")
        )

    def test_checked_sidecar_is_reproducible(self) -> None:
        self.assertEqual(self.result, self.checked)

    def test_batch38_has_no_unmapped_key_vocab(self) -> None:
        self.assertEqual(self.result["totals"]["items"], 30)
        self.assertEqual(self.result["totals"]["unmappedCandidate"], 0)
        self.assertEqual(self.result["totals"]["cultureAnchor"], 5)

    def test_culture_anchors_are_only_linked_scene_terms(self) -> None:
        anchors = {
            (scene["scenarioId"], item["korean"], item["cultureTermId"])
            for scene in self.result["scenes"]
            for item in scene["keyWords"]
            if item["classification"] == "culture_anchor"
        }
        self.assertEqual(
            anchors,
            {
                ("b1_dongsun_norigae_shop_post", "노리개", "norigae"),
                ("b1_dongsun_norigae_shop_post", "매듭", "maedeup"),
                (
                    "b1_byeongcheol_hwaseong_memory_check",
                    "수원화성",
                    "suwon_hwaseong",
                ),
                ("c1_maya_hyuna_daniel_talchum_shortform", "탈춤", "talchum"),
                ("b2_daniel_hyuna_hanji_filming_scope", "한지", "hanji"),
            },
        )

    def test_a2_jun_scene_surfaces_words_needing_level_review(self) -> None:
        scene = next(
            row
            for row in self.result["scenes"]
            if row["scenarioId"] == "a2_jun_hwaseong_school_slide"
        )
        above = {
            item["korean"]
            for item in scene["keyWords"]
            if item["classification"] == "above_target"
        }
        self.assertEqual(above, {"발표", "슬라이드", "출처", "연도"})
        photo = next(item for item in scene["keyWords"] if item["korean"] == "사진")
        self.assertEqual(photo["classification"], "at_or_below_target")
        self.assertEqual(photo["lexical"]["cefr"], "A1")


if __name__ == "__main__":
    unittest.main()
