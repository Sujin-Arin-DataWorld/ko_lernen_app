import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.dirname(__file__))
import generate_tts  # noqa: E402


class TtsGeneratorContractTest(unittest.TestCase):
    def test_short_tts_candidate_is_losslessly_polished_and_measured(self):
        raw = b"raw mp3 bytes"
        with (
            patch.object(generate_tts.shutil, "which", return_value="ffmpeg"),
            patch.object(
                generate_tts.polish_tts,
                "handle",
                return_value=("trimmed", "unused", 0.5),
            ) as handle,
            patch.object(
                generate_tts.polish_tts,
                "probe",
                return_value=(0.62, 0.06, 0.18),
            ),
            patch.object(
                generate_tts,
                "_silence_metrics",
                return_value=(0.06, 0.24),
            ),
        ):
            polished, total, head, active = (
                generate_tts._polish_and_measure_short_candidate(raw)
            )

        self.assertEqual(polished, raw)
        self.assertEqual((total, head), (0.62, 0.06))
        self.assertAlmostEqual(active, 0.38)
        self.assertEqual(handle.call_args.kwargs, {"dry_run": False})

    def test_silence_metrics_subtracts_internal_and_unclosed_tail_silence(self):
        stderr = """
[silencedetect] silence_start: 0
[silencedetect] silence_end: 0.06 | silence_duration: 0.06
[silencedetect] silence_start: 0.15
[silencedetect] silence_end: 0.50 | silence_duration: 0.35
[silencedetect] silence_start: 0.60
"""
        completed = generate_tts.subprocess.CompletedProcess(
            args=["ffmpeg"],
            returncode=0,
            stderr=stderr,
        )
        with patch.object(generate_tts.subprocess, "run", return_value=completed):
            head, silence = generate_tts._silence_metrics("candidate.mp3", 0.70)

        self.assertAlmostEqual(head, 0.06)
        self.assertAlmostEqual(silence, 0.51)
        self.assertAlmostEqual(0.70 - silence, 0.19)

    def test_active_duration_floors_match_audited_short_speech(self):
        self.assertEqual(generate_tts._min_active_duration_for("흐"), 0.30)
        self.assertEqual(generate_tts._min_active_duration_for("아"), 0.22)
        self.assertAlmostEqual(
            generate_tts._min_active_duration_for("우리가"),
            0.54,
        )

    def test_short_tts_quality_gate_fails_closed_without_ffmpeg(self):
        with patch.object(generate_tts.shutil, "which", return_value=None):
            with self.assertRaisesRegex(RuntimeError, "ffmpeg is required"):
                generate_tts._polish_and_measure_short_candidate(b"mp3")

    def test_short_tts_retries_excessive_leading_silence(self):
        with (
            patch.object(generate_tts, "GATE_RATES", (1.0, 0.7)),
            patch.object(
                generate_tts,
                "_synth_raw",
                side_effect=[b"delayed", b"immediate"],
            ) as raw,
            patch.object(
                generate_tts,
                "_polish_and_measure_short_candidate",
                side_effect=[
                    (b"delayed-polished", 0.80, 0.20, 0.40),
                    (b"immediate-polished", 0.56, 0.06, 0.32),
                ],
            ),
            patch.object(generate_tts, "mp3_peak_dbfs", return_value=-6.0),
        ):
            result = generate_tts.synth("token", "male", "흐")

        self.assertEqual(result, b"immediate-polished")
        self.assertEqual(raw.call_count, 2)

    def test_short_tts_retries_effectively_empty_active_region(self):
        with (
            patch.object(generate_tts, "GATE_RATES", (1.0, 0.7)),
            patch.object(
                generate_tts,
                "_synth_raw",
                side_effect=[b"click", b"speech"],
            ),
            patch.object(
                generate_tts,
                "_polish_and_measure_short_candidate",
                side_effect=[
                    (b"click-polished", 0.70, 0.06, 0.03),
                    (b"speech-polished", 0.54, 0.06, 0.31),
                ],
            ),
            # A loud click proves peak volume cannot replace active duration.
            patch.object(generate_tts, "mp3_peak_dbfs", return_value=-3.0),
        ):
            result = generate_tts.synth("token", "male", "흐")

        self.assertEqual(result, b"speech-polished")

    def test_short_tts_never_adopts_known_bad_best_take(self):
        with (
            patch.object(generate_tts, "GATE_RATES", (1.0, 0.7)),
            patch.object(
                generate_tts,
                "_synth_raw",
                side_effect=[b"silent-one", b"silent-two"],
            ),
            patch.object(
                generate_tts,
                "_polish_and_measure_short_candidate",
                side_effect=[
                    (b"silent-one-polished", 0.80, 0.30, 0.02),
                    (b"silent-two-polished", 0.75, 0.25, 0.03),
                ],
            ),
            patch.object(generate_tts, "mp3_peak_dbfs", return_value=-4.0),
        ):
            with self.assertRaisesRegex(RuntimeError, "failed the quality gate"):
                generate_tts.synth("token", "male", "흐")

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

    def test_first_line_manifest_covers_exact_canonical_scenarios(self):
        manifest = generate_tts.build_first_line_manifest(generate_tts.ROOT)

        self.assertEqual(manifest["schemaVersion"], 1)
        self.assertEqual(manifest["kind"], "tts_first_line_manifest")
        self.assertEqual(manifest["cacheRevision"], "v3")
        self.assertEqual(manifest["scenarioCount"], 178)
        self.assertEqual(len(manifest["items"]), 178)
        # Task 7 (지시서 4.4 / 스윕 tts-07), W10 Wave 2로 178편 갱신: 176개
        # 유니크 첫 문장 mp3가 실제로 assets/tts/v3/ 에 다운로드돼 커밋됐다 —
        # 178개 항목(2개가 같은 storagePath 공유) 전부 bundled:true 여야 한다.
        self.assertEqual(manifest["bundledCount"], 178)
        ids = [item["scenarioId"] for item in manifest["items"]]
        self.assertEqual(len(ids), len(set(ids)))
        order = [
            (item["sourceShard"], item["scenarioId"])
            for item in manifest["items"]
        ]
        self.assertEqual(order, sorted(order))
        self.assertEqual(
            set(manifest["generatedFrom"]),
            {
                "assets/data/scenarios_a1.json",
                "assets/data/scenarios_a2.json",
                "assets/data/scenarios_b1.json",
                "assets/data/scenarios_b2.json",
                "assets/data/scenarios_c1.json",
                "assets/data/scenarios_c2.json",
            },
        )
        self.assertTrue(
            all(len(item["sourceSha256"]) == 64 for item in manifest["items"])
        )
        self.assertTrue(all(item["bundled"] for item in manifest["items"]))
        self.assertTrue(
            all(
                item["bundledAssetPath"] is not None
                and item["bundledAssetPath"].startswith("assets/tts/v3/")
                for item in manifest["items"]
            )
        )
        self.assertTrue(
            all(
                item["bundledSha256"] is not None and len(item["bundledSha256"]) == 64
                for item in manifest["items"]
            )
        )

    def test_first_line_manifest_selects_first_dialog_and_legacy_voice_rule(self):
        payload = {
            "scenarios": [
                {
                    "id": "z_user_first",
                    "dialog": [
                        {"speaker": "user", "ko": "  안녕하세요  "},
                        {"speaker": "officer", "ko": "두 번째 줄"},
                    ],
                },
                {
                    "id": "a_officer_first",
                    "dialog": [
                        {"speaker": "officer", "ko": "여권 보여주세요."},
                        {"speaker": "user", "ko": "여기 있어요."},
                    ],
                },
            ]
        }
        with tempfile.TemporaryDirectory() as temp:
            root = os.path.abspath(temp)
            data_dir = os.path.join(root, "assets", "data")
            os.makedirs(data_dir)
            with open(
                os.path.join(data_dir, "scenarios_a1.json"),
                "w",
                encoding="utf-8",
            ) as handle:
                json.dump(payload, handle, ensure_ascii=False)

            manifest = generate_tts.build_first_line_manifest(root)

        by_id = {item["scenarioId"]: item for item in manifest["items"]}
        user = by_id["z_user_first"]
        self.assertEqual(user["firstDialogKo"], "안녕하세요")
        self.assertEqual(user["normalizedText"], "안녕하세요")
        self.assertEqual(user["speakerRole"], "user")
        self.assertEqual(user["voice"], "female")
        self.assertEqual(
            user["storagePath"],
            generate_tts.cache_relative_path("female", "안녕하세요"),
        )
        self.assertEqual(user["cacheHashSha1"], user["storagePath"].split("/")[-1][:-4])
        officer = by_id["a_officer_first"]
        self.assertEqual(officer["firstDialogKo"], "여권 보여주세요.")
        self.assertEqual(officer["voice"], "male")

    def test_source_sha256_is_line_ending_independent(self):
        """CRLF(윈도우 autocrlf 워킹카피)와 LF(Linux CI 체크아웃) 원본이 같은
        내용이면 sourceSha256/전체 매니페스트가 동일해야 한다 — 아니면
        --check-first-line-manifest 가 플랫폼에 따라 다른 결과를 낸다."""
        payload = {
            "scenarios": [
                {
                    "id": "crlf_lf_parity",
                    "dialog": [
                        {"speaker": "officer", "ko": "여권을 보여주세요."},
                    ],
                },
            ]
        }
        encoded_lf = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        encoded_crlf = encoded_lf.replace(b"\n", b"\r\n")
        self.assertIn(b"\n", encoded_lf)
        self.assertNotIn(b"\r", encoded_lf)
        self.assertNotEqual(encoded_lf, encoded_crlf)

        manifests = {}
        for label, raw in (("lf", encoded_lf), ("crlf", encoded_crlf)):
            with tempfile.TemporaryDirectory() as temp:
                root = os.path.abspath(temp)
                data_dir = os.path.join(root, "assets", "data")
                os.makedirs(data_dir)
                with open(os.path.join(data_dir, "scenarios_a1.json"), "wb") as handle:
                    handle.write(raw)
                manifests[label] = generate_tts.build_first_line_manifest(root)

        item_lf = manifests["lf"]["items"][0]
        item_crlf = manifests["crlf"]["items"][0]
        self.assertEqual(item_lf["sourceSha256"], item_crlf["sourceSha256"])
        self.assertEqual(
            manifests["lf"]["generatedFrom"], manifests["crlf"]["generatedFrom"]
        )
        self.assertEqual(
            generate_tts.render_first_line_manifest(manifests["lf"]),
            generate_tts.render_first_line_manifest(manifests["crlf"]),
        )

    def test_first_line_manifest_render_is_byte_stable(self):
        manifest = generate_tts.build_first_line_manifest(generate_tts.ROOT)
        first = generate_tts.render_first_line_manifest(manifest)
        second = generate_tts.render_first_line_manifest(manifest)

        self.assertEqual(first, second)
        self.assertTrue(first.endswith("\n"))
        self.assertNotIn("\r", first)

    def test_checked_first_line_manifest_matches_current_canonical_sources(self):
        expected = generate_tts.build_first_line_manifest(generate_tts.ROOT)
        path = os.path.join(
            generate_tts.ROOT,
            "assets",
            "data",
            "tts_first_line_manifest.json",
        )
        with open(path, encoding="utf-8") as handle:
            checked = json.load(handle)

        self.assertEqual(checked, expected)

    def test_first_line_manifest_rejects_duplicate_id_and_missing_first_dialog(self):
        with tempfile.TemporaryDirectory() as temp:
            data_dir = os.path.join(temp, "assets", "data")
            os.makedirs(data_dir)
            with open(
                os.path.join(data_dir, "scenarios_a1.json"),
                "w",
                encoding="utf-8",
            ) as handle:
                json.dump(
                    {
                        "scenarios": [
                            {"id": "duplicate", "dialog": []},
                            {"id": "duplicate", "dialog": []},
                        ]
                    },
                    handle,
                )
            with self.assertRaisesRegex(ValueError, "Duplicate canonical scenario ID"):
                generate_tts.build_first_line_manifest(temp)

        with tempfile.TemporaryDirectory() as temp:
            data_dir = os.path.join(temp, "assets", "data")
            os.makedirs(data_dir)
            with open(
                os.path.join(data_dir, "scenarios_a1.json"),
                "w",
                encoding="utf-8",
            ) as handle:
                json.dump({"scenarios": [{"id": "empty", "dialog": []}]}, handle)
            with self.assertRaisesRegex(ValueError, "first Korean dialog"):
                generate_tts.build_first_line_manifest(temp)

    def test_first_line_manifest_cli_never_uses_auth_synthesis_or_network(self):
        with tempfile.TemporaryDirectory() as temp:
            output = os.path.join(temp, "manifest.json")
            with (
                patch.object(generate_tts, "_auth") as auth,
                patch.object(generate_tts, "synth") as synth,
                patch.object(generate_tts, "remote_cache_objects") as remote,
                patch.object(generate_tts.subprocess, "run") as run,
                patch.object(generate_tts.subprocess, "check_output") as check_output,
                patch("builtins.print"),
            ):
                result = generate_tts.main(
                    ["--write-first-line-manifest", output]
                )

            self.assertEqual(result, 0)
            with open(output, encoding="utf-8") as handle:
                written = json.load(handle)

        self.assertEqual(written["scenarioCount"], 178)
        auth.assert_not_called()
        synth.assert_not_called()
        remote.assert_not_called()
        run.assert_not_called()
        check_output.assert_not_called()

    def test_first_line_manifest_check_detects_drift_without_writing(self):
        with tempfile.TemporaryDirectory() as temp:
            output = os.path.join(temp, "manifest.json")
            with open(output, "w", encoding="utf-8", newline="\n") as handle:
                handle.write("stale\n")
            with patch("builtins.print"):
                drift = generate_tts.main(
                    ["--check-first-line-manifest", output]
                )
            with open(output, encoding="utf-8") as handle:
                unchanged = handle.read()
            expected = generate_tts.build_first_line_manifest(generate_tts.ROOT)
            generate_tts.write_first_line_manifest(output, expected)
            with patch("builtins.print"):
                clean = generate_tts.main(
                    ["--check-first-line-manifest", output]
                )

        self.assertEqual(drift, 1)
        self.assertEqual(unchanged, "stale\n")
        self.assertEqual(clean, 0)

    def test_scenario_pending_manifest_is_an_exact_validated_scope(self):
        voice = "female"
        text = "기사님, 천천히 좀 가 주실 수 있을까요?"
        manifest = {
            "schemaVersion": 1,
            "kind": "scenario_tts_pending_manifest",
            "generationId": "canonical_120_v1",
            "scope": "a2",
            "candidateSetSha256": "a" * 64,
            "cacheRevision": "v3",
            "count": 1,
            "items": [
                {
                    "voice": voice,
                    "text": text,
                    "cachePath": generate_tts.cache_relative_path(voice, text),
                }
            ],
        }
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "pending.json")
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(manifest, handle, ensure_ascii=False)

            pairs, loaded = generate_tts.load_scenario_pending_manifest(path)

        self.assertEqual(pairs, [(voice, text)])
        self.assertEqual(loaded, manifest)

        receipt, missing = generate_tts.build_storage_verification_receipt(
            manifest,
            {manifest["items"][0]["cachePath"]: 1024},
        )
        self.assertEqual(missing, [])
        self.assertEqual(receipt["missingCount"], 0)
        self.assertEqual(receipt["verifiedCachePathCount"], 1)
        self.assertEqual(
            receipt["ttsManifestSha256"],
            generate_tts._canonical_json_sha256(manifest),
        )

        receipt, missing = generate_tts.build_storage_verification_receipt(
            manifest,
            {manifest["items"][0]["cachePath"]: 0},
        )
        self.assertEqual(missing, [manifest["items"][0]["cachePath"]])
        self.assertEqual(receipt["missingCount"], 1)

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

        # canonical_120_v1 런타임은 user 역할도 playerCharacterId로 해석한다.
        # 프로필이 없는 레거시 레코드에만 user=여성, NPC=남성 폴백이 남는다.
        data_dir = _os.path.join(root, "assets", "data")
        with open(
            _os.path.join(
                root,
                "tools/content_factory/canonical_scenarios/character_profiles.json",
            ),
            encoding="utf-8",
        ) as f:
            profile_payload = json.load(f)
        character_voices = {
            item["id"]: generate_tts.normalize_voice(item.get("voice"))
            for item in profile_payload.get("recurringCharacters", [])
        }
        character_voices.update(
            {
                role_id: generate_tts.normalize_voice(item.get("voice"))
                for role_id, item in profile_payload.get(
                    "runtimeRoleProfiles", {}
                ).items()
            }
        )
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
                speaker = (line.get("speaker") or "").strip().lower()
                resolved = (
                    (sc.get("playerCharacterId") or "").strip().lower()
                    if speaker == "user"
                    else speaker
                )
                voice = character_voices.get(
                    resolved,
                    "female" if speaker == "user" else "male",
                )
                self.assertIn((voice, ko), pairs)
                sampled = True
            if sampled:
                break
        self.assertTrue(sampled)

        female_count = sum(1 for voice, _ in pairs if voice == "female")
        male_count = len(pairs) - female_count
        self.assertLessEqual(abs(female_count - male_count), len(pairs) * 0.05)

    def test_collect_includes_luecken_uebersetzen_and_particle_pop_full_sentences(
        self,
    ):
        """지시서 2.9 — 답 공개 후 1회 읽기는 정답 완성문이 canonical corpus에
        있어야 한다(#254 게이트). 세 퀘스트 타입 각각의 파생 완성문을 합성
        시나리오 fixture로 검증한다(luecken은 sentence의 '___'를
        options[correctIndex]로 치환, uebersetzen은 options[correctIndex].ko,
        particlePop은 prefix+options[correctIndex]+suffix)."""
        synthetic_scenario = {
            "id": "scenario_test_quest_collect",
            "quests": [
                {
                    "id": "quest_test_luecken",
                    "type": "luecken",
                    "data": {
                        "sentence": "롤러코스터를 타___ 싶어.",
                        "options": ["고", "면", "서", "지만"],
                        "correctIndex": 0,
                    },
                },
                {
                    "id": "quest_test_uebersetzen",
                    "type": "uebersetzen",
                    "data": {
                        "promptDe": "Ja, hier bitte.",
                        "options": [
                            {"ko": "네, 여기 있어요."},
                            {"ko": "안녕하세요."},
                        ],
                        "correctIndex": 0,
                    },
                },
                {
                    "id": "quest_test_particle_pop",
                    "type": "particlePop",
                    "data": {
                        "prefix": "저는 학생",
                        "suffix": " 아니에요.",
                        "options": ["이", "가", "은", "는"],
                        "correctIndex": 0,
                    },
                },
            ],
        }
        synthetic_sources = [
            {
                "sourceShard": "scenarios_test.json",
                "sourcePath": "assets/data/scenarios_test.json",
                "sourceSha256": "0" * 64,
                "scenario": synthetic_scenario,
            }
        ]
        with patch.object(
            generate_tts,
            "load_canonical_scenario_sources",
            return_value=synthetic_sources,
        ):
            pairs = set(generate_tts.collect())

        expected_texts = {
            "롤러코스터를 타고 싶어.",  # luecken: 빈칸 -> options[0]
            "네, 여기 있어요.",  # uebersetzen: options[0].ko
            "저는 학생이 아니에요.",  # particlePop: prefix+options[0]+suffix
        }
        for text in expected_texts:
            self.assertIn(
                (generate_tts.auto_voice(text), text),
                pairs,
                msg=f"collect()가 {text!r} 를 auto 음성으로 수집하지 않았다",
            )

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

    def test_bare_invocation_is_rejected(self):
        # F2 — 무플래그 실행 = 전량 합성+업로드(실사고 전력, docs/
        # CONTENT_UIUX_FINISH_PLAN_2026-08-19.md L462 함정 9). 모드 플래그를
        # 하나도 주지 않으면 합성/업로드에 도달하기 전에 argparse가 거부해야
        # 한다.
        with patch("builtins.print"), patch("sys.stderr"):
            with self.assertRaises(SystemExit) as ctx:
                generate_tts.main([])
        self.assertNotEqual(ctx.exception.code, 0)

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

    def test_pending_manifest_dry_run_does_not_collect_runtime_or_use_network(self):
        voice = "male"
        text = "첨부파일을 또 안 붙였어요."
        manifest = {
            "schemaVersion": 1,
            "kind": "scenario_tts_pending_manifest",
            "generationId": "canonical_120_v1",
            "scope": "a2",
            "candidateSetSha256": "b" * 64,
            "cacheRevision": "v3",
            "count": 1,
            "items": [
                {
                    "voice": voice,
                    "text": text,
                    "cachePath": generate_tts.cache_relative_path(voice, text),
                }
            ],
        }
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "pending.json")
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(manifest, handle, ensure_ascii=False)
            with (
                patch.object(generate_tts, "collect") as collect,
                patch.object(generate_tts, "_auth") as auth,
                patch.object(generate_tts, "synth") as synth,
                patch.object(generate_tts, "remote_cache_paths") as remote,
                patch("builtins.print"),
            ):
                result = generate_tts.main(
                    ["--dry-run", "--scenario-pending-manifest", path]
                )

        self.assertEqual(result, 0)
        collect.assert_not_called()
        auth.assert_not_called()
        synth.assert_not_called()
        remote.assert_not_called()

    def test_synthesis_failure_aborts_before_any_upload(self):
        # F2/FIX-2a: 전량 합성은 이제 `--synthesize`를 명시해야 도달한다 —
        # `_parse_args` 우회 없이 실제 CLI 인자로 그 분기까지 간다.
        pairs = [("female", "안녕하세요")]
        with tempfile.TemporaryDirectory() as temp:
            with (
                patch.object(generate_tts, "OUT", temp),
                patch.object(generate_tts, "collect", return_value=pairs),
                patch.object(generate_tts, "_auth", return_value="token"),
                patch.object(
                    generate_tts,
                    "synth",
                    side_effect=RuntimeError("failed"),
                ),
                patch.object(generate_tts.shutil, "which", return_value="gcloud"),
                patch.object(generate_tts.subprocess, "run") as run,
                patch("builtins.print"),
            ):
                with self.assertRaisesRegex(
                    SystemExit,
                    "Firebase 업로드는 하지 않았습니다",
                ):
                    generate_tts.main(["--synthesize", "--workers", "1"])

        run.assert_not_called()

    def test_invalid_short_local_cache_is_resynthesized_not_uploaded_as_is(self):
        voice = "male"
        text = "흐"
        relative_path = generate_tts.cache_relative_path(voice, text)
        old_audio = b"old delayed cache" * 32
        new_audio = b"new immediate cache" * 32
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, *relative_path.split("/"))
            os.makedirs(os.path.dirname(path))
            with open(path, "wb") as handle:
                handle.write(old_audio)
            with (
                patch.object(generate_tts, "OUT", temp),
                patch.object(generate_tts, "collect", return_value=[(voice, text)]),
                patch.object(generate_tts, "_auth", return_value="token"),
                patch.object(generate_tts.shutil, "which", return_value="gcloud"),
                patch.object(generate_tts, "mp3_duration", return_value=0.80),
                patch.object(
                    generate_tts,
                    "_polish_and_measure_short_candidate",
                    return_value=(old_audio, 0.80, 0.30, 0.03),
                ),
                patch.object(generate_tts, "mp3_peak_dbfs", return_value=-5.0),
                patch.object(generate_tts, "synth", return_value=new_audio) as synth,
                patch.object(generate_tts.subprocess, "run") as run,
                patch("builtins.print"),
            ):
                result = generate_tts.main(["--synthesize", "--workers", "1"])
                with open(path, "rb") as handle:
                    saved = handle.read()

        self.assertEqual(result, 0)
        self.assertEqual(saved, new_audio)
        synth.assert_called_once_with("token", voice, text)
        run.assert_called_once()

    def test_manifest_upload_uses_only_the_exact_selected_object(self):
        # F2/FIX-2a: `--synthesize`가 실제 합성+업로드 분기를 명시적으로
        # 연다 — manifest 기반 업로드 범위 정확성을 실 CLI 인자로 검증한다.
        voice = "female"
        text = "안녕하세요"
        relative_path = generate_tts.cache_relative_path(voice, text)
        manifest = {
            "schemaVersion": 1,
            "kind": "scenario_tts_pending_manifest",
            "generationId": "canonical_120_v1",
            "scope": "a1",
            "candidateSetSha256": "c" * 64,
            "cacheRevision": "v3",
            "count": 1,
            "items": [{"voice": voice, "text": text, "cachePath": relative_path}],
        }
        with tempfile.TemporaryDirectory() as temp:
            manifest_path = os.path.join(temp, "pending.json")
            with open(manifest_path, "w", encoding="utf-8") as handle:
                json.dump(manifest, handle, ensure_ascii=False)
            valid_mp3 = b"I" * 512
            with (
                patch.object(generate_tts, "OUT", temp),
                patch.object(generate_tts, "_auth", return_value="token"),
                patch.object(generate_tts, "synth", return_value=valid_mp3),
                patch.object(generate_tts, "mp3_duration", return_value=1.0),
                patch.object(generate_tts.shutil, "which", return_value="gcloud"),
                patch.object(generate_tts.subprocess, "run") as run,
                patch("builtins.print"),
            ):
                result = generate_tts.main(
                    [
                        "--synthesize",
                        "--scenario-pending-manifest",
                        manifest_path,
                        "--workers",
                        "1",
                    ]
                )

        self.assertEqual(result, 0)
        run.assert_called_once()
        argv = run.call_args.args[0]
        self.assertEqual(argv[1:3], ["storage", "cp"])
        self.assertEqual(argv[4], f"gs://{generate_tts.BUCKET}/{relative_path}")
        self.assertNotIn("rsync", argv)

    def test_download_first_line_bundle_dedupes_shared_storage_paths(self):
        items = [
            {"storagePath": "tts/v3/female/aaa.mp3", "voice": "female", "cacheHashSha1": "aaa"},
            {
                # 두 시나리오가 같은 (voice, text) 첫 문장을 공유(126개 중 125
                # 유니크). 같은 storagePath는 한 번만 다운로드해야 한다.
                "storagePath": "tts/v3/female/aaa.mp3",
                "voice": "female",
                "cacheHashSha1": "aaa",
            },
            {"storagePath": "tts/v3/male/bbb.mp3", "voice": "male", "cacheHashSha1": "bbb"},
        ]
        calls = []

        def fake_run(argv, check=True):
            calls.append(argv)
            target = argv[4]
            # >= MIN_REMOTE_MP3_BYTES (256): 43 bytes would fail the same
            # size floor real downloads are held to.
            with open(target, "wb") as handle:
                handle.write(b"ID3" + bytes(300))
            return subprocess.CompletedProcess(argv, 0)

        with tempfile.TemporaryDirectory() as tmp:
            with (
                patch.object(generate_tts.shutil, "which", return_value="gcloud"),
                patch.object(generate_tts.subprocess, "run", side_effect=fake_run),
            ):
                downloaded = generate_tts.download_first_line_bundle(
                    items, project_root=tmp
                )
        self.assertEqual(len(calls), 2, "중복 storagePath는 한 번만 다운로드해야 한다")
        self.assertEqual(len(downloaded), 2)

    def test_download_first_line_bundle_batches_multi_item_voice_directories(self):
        # 실제 125개 다운로드는 목소리당 한 프로세스(청크 <=chunk_size)로 묶어야
        # 파일당 gcloud 프로세스 125개(각 ~10-16s)를 피한다 — 컨트롤러 룰링.
        items = [
            {"storagePath": f"tts/v3/female/{name}.mp3", "voice": "female", "cacheHashSha1": name}
            for name in ("aaa", "bbb", "ccc")
        ]
        calls = []

        def fake_run(argv, check=True):
            calls.append(argv)
            # Multi-source form: [... "cp", src1, src2, ..., dest_dir, "--project", PROJECT]
            # Single-source form: [... "cp", src, dest_file, "--project", PROJECT]
            dest = argv[-3]
            sources = argv[3:-3]
            if len(sources) == 1:
                with open(dest, "wb") as handle:
                    handle.write(b"ID3" + bytes(300))
            else:
                for source in sources:
                    digest = source.rsplit("/", 1)[-1]
                    with open(os.path.join(dest, digest), "wb") as handle:
                        handle.write(b"ID3" + bytes(300))
            return subprocess.CompletedProcess(argv, 0)

        with tempfile.TemporaryDirectory() as tmp:
            with (
                patch.object(generate_tts.shutil, "which", return_value="gcloud"),
                patch.object(generate_tts.subprocess, "run", side_effect=fake_run),
            ):
                downloaded = generate_tts.download_first_line_bundle(
                    items, project_root=tmp, chunk_size=2
                )
                voice_dir = os.path.join(tmp, "assets", "tts", "v3", "female")
                remaining = sorted(os.listdir(voice_dir))

        # chunk_size=2 over 3 items => one batched call (2 sources) + one
        # single-source call, never one process per file.
        self.assertEqual(len(calls), 2)
        self.assertEqual(len(downloaded), 3)
        self.assertEqual(remaining, ["aaa.mp3", "bbb.mp3", "ccc.mp3"])

    def test_download_first_line_bundle_skips_an_already_valid_local_file(self):
        items = [{"storagePath": "tts/v3/female/aaa.mp3", "voice": "female", "cacheHashSha1": "aaa"}]
        with tempfile.TemporaryDirectory() as tmp:
            voice_dir = os.path.join(tmp, "assets", "tts", "v3", "female")
            os.makedirs(voice_dir)
            existing = os.path.join(voice_dir, "aaa.mp3")
            with open(existing, "wb") as handle:
                handle.write(b"ID3" + bytes(300))
            with (
                patch.object(generate_tts.shutil, "which", return_value="gcloud"),
                patch.object(generate_tts.subprocess, "run") as run,
            ):
                downloaded = generate_tts.download_first_line_bundle(
                    items, project_root=tmp
                )
        run.assert_not_called()
        self.assertEqual(downloaded, [])

    def test_verify_storage_mode_reaches_its_own_read_only_branch(self):
        # FIX-2a(2026-09-01 정정): --verify-storage 는 이제 --demo/--dry-run
        # 등과 같은 그룹의 정식 모드다 — 합성/업로드 코드를 전혀 안 타고
        # 원격 목록만 읽어 비교하는 자기 분기에 도달해야 한다.
        pairs = [("female", "안녕하세요")]
        remote_path = generate_tts.cache_relative_path("female", "안녕하세요")
        with (
            patch.object(generate_tts, "collect", return_value=pairs),
            patch.object(generate_tts, "_auth") as auth,
            patch.object(generate_tts, "synth") as synth,
            patch.object(generate_tts.shutil, "which", return_value="gcloud"),
            patch.object(
                generate_tts,
                "remote_cache_objects",
                return_value={remote_path: 4096},
            ) as remote,
            patch.object(generate_tts.subprocess, "run") as run,
            patch("builtins.print"),
        ):
            result = generate_tts.main(["--verify-storage"])

        self.assertEqual(result, 0)
        remote.assert_called_once()
        auth.assert_not_called()
        synth.assert_not_called()
        run.assert_not_called()

    def test_delete_stale_requires_verify_storage(self):
        with patch("builtins.print"), patch("sys.stderr"):
            with self.assertRaises(SystemExit) as ctx:
                generate_tts.main(["--delete-stale"])
        self.assertNotEqual(ctx.exception.code, 0)

    def test_verify_storage_lists_stale_paths_without_deleting(self):
        pairs = [("female", "안녕하세요")]
        remote_path = generate_tts.cache_relative_path("female", "안녕하세요")
        stale_path = "tts/v3/female/deadbeef00000000000000000000000000000000.mp3"
        with (
            patch.object(generate_tts, "collect", return_value=pairs),
            patch.object(generate_tts.shutil, "which", return_value="gcloud"),
            patch.object(
                generate_tts, "remote_cache_objects",
                return_value={remote_path: 4096, stale_path: 4096},
            ),
            patch.object(generate_tts, "delete_remote_objects") as delete,
            patch.object(generate_tts.subprocess, "run") as run,
            patch("builtins.print") as printed,
        ):
            result = generate_tts.main(["--verify-storage", "--delete-stale"])
        self.assertEqual(result, 0)
        delete.assert_not_called()
        run.assert_not_called()
        stale_lines = [
            call.args[0]
            for call in printed.call_args_list
            if call.args and str(call.args[0]).startswith("STALE\t")
        ]
        self.assertEqual(stale_lines, [f"STALE\t{stale_path}"])

    def test_verify_storage_without_delete_stale_does_not_list_stale_paths(self):
        # F4 — a bare --verify-storage run (the CI completeness gate) must
        # print only the stale *count* in the summary line, never one
        # STALE\t line per object. With thousands of already-stale objects
        # (voice-migration debris etc.) the unconditional per-path listing
        # was thousands of lines of CI noise; the per-path preview is only
        # useful together with --delete-stale (see the sibling test below).
        pairs = [("female", "안녕하세요")]
        remote_path = generate_tts.cache_relative_path("female", "안녕하세요")
        stale_path = "tts/v3/female/deadbeef00000000000000000000000000000000.mp3"
        with (
            patch.object(generate_tts, "collect", return_value=pairs),
            patch.object(generate_tts.shutil, "which", return_value="gcloud"),
            patch.object(
                generate_tts, "remote_cache_objects",
                return_value={remote_path: 4096, stale_path: 4096},
            ),
            patch.object(generate_tts, "delete_remote_objects") as delete,
            patch.object(generate_tts.subprocess, "run") as run,
            patch("builtins.print") as printed,
        ):
            result = generate_tts.main(["--verify-storage"])
        self.assertEqual(result, 0)
        delete.assert_not_called()
        run.assert_not_called()
        stale_lines = [
            call.args[0]
            for call in printed.call_args_list
            if call.args and str(call.args[0]).startswith("STALE\t")
        ]
        self.assertEqual(stale_lines, [])
        summary_lines = [
            call.args[0]
            for call in printed.call_args_list
            if call.args and str(call.args[0]).startswith("Storage verify")
        ]
        self.assertEqual(
            summary_lines,
            ["Storage verify — expected 1, remote 2, missing 0, stale 1"],
        )

    def test_confirm_delete_requires_delete_stale(self):
        # I3(a) — the destructive path (--delete-stale --confirm-delete)
        # previously had no coverage at all for the argparse guard that
        # rejects --confirm-delete without --delete-stale.
        with patch("builtins.print"), patch("sys.stderr"):
            with self.assertRaises(SystemExit) as ctx:
                generate_tts.main(["--verify-storage", "--confirm-delete"])
        self.assertNotEqual(ctx.exception.code, 0)

    def test_delete_stale_with_confirm_calls_delete_remote_objects_with_stale_set(
        self,
    ):
        # I3(a) — pins the destructive --verify-storage --delete-stale
        # --confirm-delete path: delete_remote_objects must be called with
        # exactly the stale set (never the expected/remote sets themselves),
        # and a run with nothing missing must still exit 0.
        pairs = [("female", "안녕하세요")]
        remote_path = generate_tts.cache_relative_path("female", "안녕하세요")
        stale_path = "tts/v3/female/deadbeef00000000000000000000000000000000.mp3"
        with (
            patch.object(generate_tts, "collect", return_value=pairs),
            patch.object(generate_tts.shutil, "which", return_value="gcloud"),
            patch.object(
                generate_tts, "remote_cache_objects",
                return_value={remote_path: 4096, stale_path: 4096},
            ),
            patch.object(generate_tts, "delete_remote_objects") as delete,
            patch.object(generate_tts.subprocess, "run") as run,
            patch("builtins.print"),
        ):
            result = generate_tts.main(
                ["--verify-storage", "--delete-stale", "--confirm-delete"]
            )
        self.assertEqual(result, 0)
        delete.assert_called_once_with({stale_path})
        run.assert_not_called()

    def test_delete_remote_objects_chunks_at_fifty_paths_per_call(self):
        # I3(b) — delete_remote_objects must chunk like the download path
        # (<=50 paths per `gcloud storage rm` invocation) instead of putting
        # an unbounded argv on one process.
        paths = {f"tts/v3/female/{i:040d}.mp3" for i in range(120)}
        with (
            patch.object(generate_tts.shutil, "which", return_value="gcloud"),
            patch.object(generate_tts.subprocess, "run") as run,
        ):
            generate_tts.delete_remote_objects(paths)
        self.assertEqual(run.call_count, 3)

    def test_missing_from_storage_mode_reads_remote_before_synthesizing(self):
        # FIX-2a(2026-09-01 정정): --missing-from-storage 와 --synthesize 는
        # 같은 그룹의 서로 다른 모드다 — 결손분만 합성하는
        # --missing-from-storage 만 remote_cache_paths() 로 원격 목록을 먼저
        # 읽어야 한다(그래서 이미 원격에 있는 항목은 합성도 업로드도 없이
        # 건너뛴다). --synthesize 가 이 호출을 안 함은
        # test_manifest_upload_uses_only_the_exact_selected_object 가
        # (patch 없이 실행돼도 원격 접근이 없다는 사실로) 이미 검증한다.
        pairs = [("female", "안녕하세요")]
        remote_path = generate_tts.cache_relative_path("female", "안녕하세요")
        with tempfile.TemporaryDirectory() as temp:
            with (
                patch.object(generate_tts, "OUT", temp),
                patch.object(generate_tts, "collect", return_value=pairs),
                patch.object(generate_tts, "_auth", return_value="token"),
                patch.object(
                    generate_tts,
                    "remote_cache_paths",
                    return_value={remote_path},
                ) as remote,
                patch.object(generate_tts, "synth") as synth,
                patch.object(generate_tts.shutil, "which", return_value="gcloud"),
                patch.object(generate_tts.subprocess, "run") as run,
                patch("builtins.print"),
            ):
                result = generate_tts.main(
                    ["--missing-from-storage", "--workers", "1"]
                )

        self.assertEqual(result, 0)
        remote.assert_called_once()
        synth.assert_not_called()
        run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
