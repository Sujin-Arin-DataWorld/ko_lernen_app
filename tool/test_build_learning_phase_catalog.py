"""Release contracts for the projection, not a second curriculum authority."""
import json
from pathlib import Path
import tempfile
import unittest

from tool import build_learning_phase_catalog as catalog


class LearningPhaseProjectionTests(unittest.TestCase):
    def test_live_projection_is_fresh_and_preserves_canonical_goals(self):
        actual = catalog.build()
        source = json.loads((catalog.ROOT / catalog.SOURCE).read_text(encoding="utf-8"))
        self.assertEqual((catalog.ROOT / catalog.OUTPUT).read_text(encoding="utf-8"), catalog.render())
        self.assertEqual(len(actual["phases"]), 30)
        for phase, original in zip(actual["phases"], source["phases"]):
            self.assertEqual(phase["title"], original["title"])
            self.assertEqual(phase["goal"], original["coreGoal"])
            self.assertEqual(
                phase["illustrationAsset"],
                f"assets/illustrations/phases/{phase['id'].lower()}.webp",
            )
        self.assertEqual(actual["coverage"], "phase_tasks_partial")
        self.assertEqual(actual["schemaVersion"], 2)
        self.assertEqual(len(actual["phases"][0]["taskIds"]), 33)
        self.assertEqual([len(p["taskIds"]) for p in actual["phases"][:4]], [33, 32, 32, 31])
        self.assertEqual([len(p["taskIds"]) for p in actual["phases"][4:8]], [29, 38, 35, 38])
        self.assertEqual(len(actual["phases"][8]["taskIds"]), 28)
        self.assertEqual(len(actual["phases"][9]["taskIds"]), 40)
        self.assertEqual(len(actual["phases"][10]["taskIds"]), 35)
        self.assertEqual(len(actual["phases"][11]["taskIds"]), 32)
        self.assertEqual(len(actual["phases"][12]["taskIds"]), 32)
        self.assertEqual(len(actual["phases"][13]["taskIds"]), 25)
        self.assertEqual(len(actual["phases"][14]["taskIds"]), 34)
        self.assertEqual(len(actual["phases"][15]["taskIds"]), 28)
        self.assertEqual(len(actual["phases"][16]["taskIds"]), 31)
        self.assertEqual(len(actual["phases"][17]["taskIds"]), 42)
        self.assertEqual(len(actual["phases"][18]["taskIds"]), 28)
        self.assertEqual(len(actual["phases"][19]["taskIds"]), 22)
        self.assertEqual(len(actual["phases"][20]["taskIds"]), 25)
        self.assertEqual(len(actual["phases"][21]["taskIds"]), 22)
        self.assertEqual(len(actual["phases"][22]["taskIds"]), 21)
        self.assertEqual(len(actual["phases"][23]["taskIds"]), 29)
        self.assertEqual(len(actual["phases"][24]["taskIds"]), 21)
        self.assertEqual(len(actual["phases"][25]["taskIds"]), 21)
        self.assertEqual(len(actual["phases"][26]["taskIds"]), 27)
        self.assertEqual(len(actual["phases"][27]["taskIds"]), 27)
        self.assertEqual(len(actual["phases"][28]["taskIds"]), 26)
        self.assertEqual(len(actual["phases"][29]["taskIds"]), 38)
        units = json.loads((catalog.ROOT / "assets/data/curriculum_manifest.json").read_text(encoding="utf-8"))["courseUnits"]
        self.assertEqual({u["id"] for u in units}, {u for p in actual["phases"] for u in p["practiceUnitIds"]})

    def check_bad_binding(self, mutate):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for rel in (catalog.SOURCE, catalog.BINDINGS, Path("assets/data/curriculum_manifest.json"), Path("pubspec.yaml")):
                path = root / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes((catalog.ROOT / rel).read_bytes())
            path = root / catalog.BINDINGS
            data = json.loads(path.read_text(encoding="utf-8"))
            for phase in data["phases"]:
                phase["artwork"] = {"status": "pending", "asset": None}
            mutate(data["phases"])
            path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            with self.assertRaises(ValueError):
                catalog.build(root)

    def test_rejects_unknown_or_cross_level_missions(self):
        for uid in ("missing", "c2_01_interpretation_institutions"):
            with self.subTest(uid=uid):
                self.check_bad_binding(lambda p: p[0].update(practiceUnitIds=[uid]))

    def test_rejects_missing_or_duplicate_phases(self):
        self.check_bad_binding(lambda p: p.pop())
        self.check_bad_binding(lambda p: p[1].update(phaseId="KP01"))

    def test_rejects_missing_locale_and_empty_practice(self):
        self.check_bad_binding(lambda p: p[0]["practiceFocus"].update(de=""))
        self.check_bad_binding(lambda p: p[0].update(practiceUnitIds=[]))

    def test_pending_art_cannot_request_a_file(self):
        self.check_bad_binding(lambda p: p[0]["artwork"].update(asset="assets/illustrations/packs/noemun.webp"))

    def test_approved_art_must_exist(self):
        self.check_bad_binding(lambda p: p[0].update(artwork={"status":"approved", "asset":"assets/illustrations/phases/kp01.webp"}))

    def test_approved_art_must_be_in_flutter_bundle(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for rel in (catalog.SOURCE, catalog.BINDINGS, Path("assets/data/curriculum_manifest.json"), Path("pubspec.yaml")):
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_bytes((catalog.ROOT / rel).read_bytes())
            path = root / catalog.BINDINGS
            data = json.loads(path.read_text(encoding="utf-8"))
            for phase in data["phases"]:
                phase["artwork"] = {"status": "pending", "asset": None}
            data["phases"][0]["artwork"] = {"status":"approved", "asset":"assets/illustrations/unbundled/phase.webp"}
            path.write_text(json.dumps(data), encoding="utf-8")
            art = root / "assets/illustrations/unbundled/phase.webp"
            art.parent.mkdir(parents=True)
            art.write_bytes(b"test existence only")
            with self.assertRaisesRegex(ValueError, "not registered"):
                catalog.build(root)
            with (root / "pubspec.yaml").open("a", encoding="utf-8") as f:
                f.write("\n")
            spec = (root / "pubspec.yaml").read_text(encoding="utf-8")
            (root / "pubspec.yaml").write_text(spec.replace("  assets:\n", "  assets:\n    - assets/illustrations/unbundled/\n"), encoding="utf-8")
            self.assertEqual(catalog.build(root)["phases"][0]["illustrationAsset"], "assets/illustrations/unbundled/phase.webp")


if __name__ == "__main__":
    unittest.main()
