import os
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.dirname(__file__))
import generate_tts  # noqa: E402


class TtsGeneratorContractTest(unittest.TestCase):
    def test_auto_voice_matches_dart_contract_vectors(self):
        self.assertEqual(generate_tts.auto_voice("안녕하세요"), "male")
        self.assertEqual(generate_tts.auto_voice("  안녕하세요  "), "male")
        self.assertEqual(generate_tts.auto_voice("감사합니다"), "female")

    def test_v3_storage_key_matches_flutter_and_function_contract(self):
        self.assertEqual(generate_tts.TTS_CACHE_REVISION, "v3")
        self.assertEqual(
            generate_tts.cache_relative_path("female", "안녕하세요"),
            "tts/v3/female/d84734f7d89bbd707dc52168c47309aed72b7f80.mp3",
        )

    def test_collect_covers_every_fixed_tts_source(self):
        """고정 콘텐츠가 수집에 빠지면 런타임에 OS 폴백(옛 음성)으로 샌다.

        2026-08-12: satz 목표문장 55/191 이 수집에 없어 Satz bauen 재생이
        로봇 음성으로 떨어졌다 — 전수 포함을 회귀로 고정한다."""
        import json
        import os as _os

        pairs = set(generate_tts.collect())
        auto = {
            text
            for voice, text in pairs
            if voice == generate_tts.auto_voice(text)
        }

        root = generate_tts.ROOT

        # Satz bauen: 모든 targetKo 가 auto 음성으로 수집돼야 한다.
        with open(
            _os.path.join(root, "assets/data/satz_sentences.json"), encoding="utf-8"
        ) as f:
            satz_targets = [
                (it.get("targetKo") or "").strip()
                for it in json.load(f).get("items", [])
            ]
        satz_targets = [t for t in satz_targets if t]
        self.assertGreater(len(satz_targets), 100)
        missing = [t for t in satz_targets if t not in auto]
        self.assertEqual(missing, [])

        # Pronunciation studio: every reviewed Korean reference sentence is
        # played through the deterministic default auto TTS path.
        with open(
            _os.path.join(root, "assets/data/pronunciation_phrases.json"),
            encoding="utf-8",
        ) as f:
            pronunciation_targets = [
                (item.get("ko") or "").strip()
                for item in json.load(f).get("phrases", [])
            ]
        pronunciation_targets = [text for text in pronunciation_targets if text]
        self.assertGreaterEqual(len(pronunciation_targets), 4)
        missing = [text for text in pronunciation_targets if text not in auto]
        self.assertEqual(missing, [])

        # Media phrase and word-web screens expose direct TTS buttons.
        with open(
            _os.path.join(root, "assets/data/media_phrases.json"), encoding="utf-8"
        ) as f:
            media_targets = [
                (item.get("korean") or "").strip()
                for item in json.load(f).get("phrases", [])
            ]
        self.assertTrue(media_targets)
        self.assertEqual([text for text in media_targets if text not in auto], [])

        with open(
            _os.path.join(root, "assets/data/word_relations.json"), encoding="utf-8"
        ) as f:
            clusters = json.load(f).get("clusters", [])
        relation_targets = []
        for cluster in clusters:
            relation_targets.append((cluster.get("sourceKo") or "").strip())
            for key in ("synonyms", "antonyms", "related"):
                relation_targets.extend(
                    (item.get("ko") or "").strip()
                    for item in cluster.get(key, [])
                )
            for item in cluster.get("expressions", []):
                relation_targets.extend(
                    ((item.get("ko") or "").strip(), (item.get("exampleKo") or "").strip())
                )
        relation_targets = [text for text in relation_targets if text]
        self.assertTrue(relation_targets)
        self.assertEqual([text for text in relation_targets if text not in auto], [])

        with open(
            _os.path.join(root, "assets/data/silben_puzzles.json"), encoding="utf-8"
        ) as f:
            silben_levels = json.load(f).get("levels", {})
        silben_targets = [
            (word.get("answer") or "").strip()
            for puzzles in silben_levels.values()
            for puzzle in puzzles
            for word in puzzle.get("words", [])
        ]
        self.assertTrue(silben_targets)
        self.assertEqual([text for text in silben_targets if text not in auto], [])

        # 듣기(Hören)=시나리오 대화: user=여성, NPC=남성 화자 매핑 표본 확인.
        data_dir = _os.path.join(root, "assets", "data")
        scenarios = []
        for name in sorted(_os.listdir(data_dir)):
            if not (name.startswith("scenarios_") and name.endswith(".json")):
                continue
            with open(_os.path.join(data_dir, name), encoding="utf-8") as f:
                scenarios.extend(json.load(f).get("scenarios", []))
        self.assertTrue(scenarios, "no scenario shards under assets/data/")
        sampled = False
        for sc in scenarios:
            for line in sc.get("dialog", []):
                ko = (line.get("ko") or "").strip()
                if not ko:
                    continue
                voice = "female" if line.get("speaker") == "user" else "male"
                self.assertIn((voice, ko), pairs)
                sampled = True
            if sampled:
                break
        self.assertTrue(sampled)

        female_count = sum(1 for voice, _ in pairs if voice == "female")
        male_count = len(pairs) - female_count
        self.assertLessEqual(abs(female_count - male_count), len(pairs) * 0.05)

    def test_gcloud_calls_use_an_argument_vector_without_a_shell(self):
        with patch.object(
            generate_tts.shutil,
            "which",
            side_effect=[None, r"C:\\Tools\\GoogleCloudSDK\\gcloud.cmd"],
        ):
            self.assertEqual(
                generate_tts.gcloud_argv("auth", "print-access-token"),
                [r"C:\\Tools\\GoogleCloudSDK\\gcloud.cmd", "auth", "print-access-token"],
            )

    def test_dry_run_never_authenticates_synthesizes_or_uploads(self):
        pairs = [("female", "안녕하세요"), ("male", "감사합니다")]
        with (
            patch.object(generate_tts, "collect", return_value=pairs),
            patch.object(generate_tts, "_auth") as auth,
            patch.object(generate_tts, "synth") as synth,
            patch.object(generate_tts.subprocess, "run") as run,
            patch("builtins.print"),
        ):
            result = generate_tts.main(["--dry-run"])

        self.assertEqual(result, 0)
        auth.assert_not_called()
        synth.assert_not_called()
        run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
