from __future__ import annotations

from collections import Counter
import csv
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "content_factory" / "build_theme_park_date_smalltalk.py"
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")


class ThemeParkDateBuildTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._temp_dir = tempfile.TemporaryDirectory()
        cls.output_root = Path(cls._temp_dir.name)
        cls.result = subprocess.run(
            [
                sys.executable,
                "-X",
                "utf8",
                str(SCRIPT),
                "--output-root",
                str(cls.output_root),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )
        base = cls.output_root / "tools" / "content_factory"
        cls.smalltalk = json.loads(
            (base / "drafts" / "theme_park_date_smalltalk_v1.json").read_text(
                encoding="utf-8"
            )
        )
        cls.scenarios = json.loads(
            (base / "drafts" / "theme_park_date_scenarios_v1.json").read_text(
                encoding="utf-8"
            )
        )
        cls.manifest = json.loads(
            (base / "drafts" / "batch_21_theme_park_date_manifest.json").read_text(
                encoding="utf-8"
            )
        )
        cls.audit = json.loads(
            (base / "review" / "theme_park_date_content_v1_audit.json").read_text(
                encoding="utf-8"
            )
        )
        cls.review_rows: dict[str, list[dict[str, str]]] = {}
        for kind in ("smalltalk", "scenarios"):
            path = base / "review" / f"theme_park_date_{kind}_v1.csv"
            with path.open(encoding="utf-8-sig", newline="") as handle:
                cls.review_rows[kind] = list(csv.DictReader(handle))

    @classmethod
    def tearDownClass(cls) -> None:
        cls._temp_dir.cleanup()

    def test_cli_builds_all_artifacts(self) -> None:
        self.assertEqual(self.result.returncode, 0, self.result.stderr)
        self.assertEqual(self.manifest["status"], "merged")
        self.assertEqual(self.manifest["recordCount"], 66)
        self.assertEqual(self.manifest["questCount"], 31)

    def test_smalltalk_matrix_and_signature_scenes_are_exact(self) -> None:
        phrases = self.smalltalk["phrases"]
        self.assertEqual(len(phrases), 60)
        self.assertEqual(
            Counter(row["level"] for row in phrases),
            Counter({level: 10 for level in LEVELS}),
        )
        self.assertEqual(
            self.smalltalk["category"],
            {
                "id": "theme_park_date",
                "emoji": "🎢",
                "label": {
                    "ko": "놀이공원 데이트",
                    "de": "Date im Freizeitpark",
                    "en": "Theme park date",
                },
            },
        )
        korean = "\n".join(row["ko"] for row in phrases)
        for fragment in (
            "360도",
            "탁탁탁탁",
            "바지가 다 젖었어",
            "발바닥이 너무 아파",
            "크리스마스 마켓",
            "갈색 지갑",
            "안전바",
            "소리를 마음껏 질렀더니",
            "웃음이 가득",
            "다음에 올 이유",
        ):
            self.assertIn(fragment, korean)

    def test_smalltalk_relationship_and_safety_contracts(self) -> None:
        phrases = {row["id"]: row for row in self.smalltalk["phrases"]}
        self.assertEqual(
            phrases["smalltalk_b2_0124"]["ko"],
            "아직 들어온 분실물은 없는데요. 공원 안내 데스크에 한번 문의해 보시겠어요?",
        )
        self.assertIn("직원한테 물어보자", phrases["smalltalk_b2_0126"]["ko"])
        korean = "\n".join(row["ko"] for row in phrases.values())
        self.assertNotIn("안경은 꼭 잡고", korean)
        for row in phrases.values():
            self.assertIn(row["relationshipContext"], {"romantic_partner", "service"})
            for language in ("ko", "de", "en"):
                self.assertTrue(row[language].strip())
                self.assertTrue(row["followUp"][language].strip())

    def test_sujin_and_christian_have_one_scenario_per_level(self) -> None:
        scenarios = self.scenarios["scenarios"]
        self.assertEqual(len(scenarios), 6)
        self.assertEqual(
            Counter(row["level"] for row in scenarios),
            Counter({level: 1 for level in LEVELS}),
        )
        for row in scenarios:
            with self.subTest(row=row["id"]):
                self.assertEqual(row["playerCharacterId"], "sujin")
                self.assertEqual(row["participantIds"], ["sujin", "christian"])
                self.assertEqual(row["sidekick"], "christian")
                self.assertEqual(row["relationshipContext"], "romantic_partners")
                self.assertEqual(row["shelf"], f"{row['level']}_dating")
                self.assertEqual(row["backdrop"], "theme_park")
                self.assertEqual(len(row["dialog"]), 8)
                expected_types = {
                    "hoerverstehen",
                    "uebersetzen",
                    "luecken",
                    "satzBauen",
                    "diktat",
                }
                if row["level"] == "a1":
                    expected_types.add("particlePop")
                self.assertEqual(len(row["quests"]), len(expected_types))
                self.assertEqual(
                    {quest["type"] for quest in row["quests"]},
                    expected_types,
                )

    def test_review_and_audit_do_not_fake_human_language_qa(self) -> None:
        self.assertFalse(self.manifest["provenance"]["humanLanguageQaClaim"])
        self.assertFalse(self.audit["humanLanguageQaClaim"])
        self.assertEqual(self.audit["modelQaClaim"], "MODEL_QA_PASS")
        for rows, expected_count in (
            (self.review_rows["smalltalk"], 60),
            (self.review_rows["scenarios"], 6),
        ):
            self.assertEqual(len(rows), expected_count)
            for row in rows:
                self.assertEqual(row["상태"], "approved")
                self.assertIn("rights: original", row["field_notes"])
                self.assertTrue(row["jin_memo"].strip())

    def test_manifest_declares_runtime_listening_tts_and_visual_handoff(self) -> None:
        self.assertEqual(
            self.manifest["promotion"],
            {
                "runtime": True,
                "listening": True,
                "tts": "dynamic_runtime",
                "firebase": False,
            },
        )
        self.assertEqual(
            self.manifest["visualAsset"],
            {
                "runtimeKey": "theme_park",
                "futurePosterPath": "assets/illustrations/scenes/theme_park.png",
                "currentFallbackKey": "market",
                "ambientLoopRequired": False,
            },
        )
        self.assertEqual(len(self.manifest["smalltalkCategoryMappings"]), 6)


if __name__ == "__main__":
    unittest.main()
