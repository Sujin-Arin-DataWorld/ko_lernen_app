#!/usr/bin/env python3
"""Contract tests for the offline 120-scenario canonical pipeline."""

from __future__ import annotations

import ast
from collections import Counter
import copy
from dataclasses import replace
import json
from pathlib import Path
import sys
import tempfile
import unittest


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_corpus_pipeline as pipeline
import audit_canonical_scenarios as editorial_audit
import materialize_canonical_scenarios as materializer


ROOT = SCRIPT_DIR.parents[1]


def _candidate() -> dict:
    passed = {"verdict": "pass", "notes": []}
    return {
        "kind": "scenario_candidate",
        "scenarioId": "bakery_queue",
        "scenario": {
            "id": "bakery_queue",
            "level": "a1",
            "emoji": "🥐",
            "register": "polite",
            "title": {
                "ko": "빵집에서 줄을 잘못 섰을 때",
                "de": "In der falschen Schlange",
                "en": "Joining the wrong queue",
            },
            "intro": {
                "ko": "빵집이 붐벼요.",
                "de": "In der Bäckerei ist viel los.",
                "en": "The bakery is busy.",
            },
            "courseUnitId": "a1_08_clarify_repair",
            "playerCharacterId": "christian",
            "participantIds": ["christian", "sujin"],
            "relationshipContext": "처음 보는 두 사람",
            "intent": "줄을 잘못 선 실수를 바로 수습한다",
            "shelf": "a1_daily",
            "backdrop": "market",
            "vocab": [],
            "conceptIds": [],
            "surfaceFormIds": [],
            "grammarIds": [],
            "grammarBlock": None,
            "dialog": [
                {
                    "speaker": "sujin",
                    "ko": "여기 줄 서 있는데요.",
                    "de": "Wir stehen hier an.",
                    "en": "The line starts here.",
                },
                {
                    "speaker": "user",
                    "ko": "아, 죄송합니다. 몰랐어요.",
                    "de": "Oh, Entschuldigung. Das wusste ich nicht.",
                    "en": "Oh, sorry. I didn't realize.",
                },
                {
                    "speaker": "sujin",
                    "ko": "괜찮아요. 뒤가 줄이에요.",
                    "de": "Kein Problem. Das Ende ist dort hinten.",
                    "en": "No problem. The end is back there.",
                },
                {
                    "speaker": "user",
                    "ko": "네, 뒤에 설게요.",
                    "de": "Okay, ich stelle mich hinten an.",
                    "en": "Okay, I'll join at the back.",
                },
            ],
            "quests": [
                {
                    "type": "satzBauen",
                    "data": {
                        "targetKo": "몰랐어요.",
                        "audioKo": "몰랐어요.",
                    },
                }
            ],
            "culturalNote": None,
            "xpReward": 100,
        },
        "audit": {
            "criticalErrors": [],
            "accuracy": passed,
            "naturalness": passed,
            "pragmatics": passed,
            "relationship": passed,
            "cefr": passed,
            "warnings": [],
        },
    }


class ScenarioCorpusPipelineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.sources = pipeline.load_sources(ROOT)

    def test_portfolio_is_exact_and_keeps_runtime_wires(self) -> None:
        report = pipeline.validate_portfolio(ROOT)
        self.assertTrue(report.ok, report.errors)
        self.assertEqual(len(self.sources.briefs), 120)
        self.assertEqual(len(self.sources.course_unit_blueprint), 48)
        for level in pipeline.LEVELS:
            self.assertEqual(
                len([brief for brief in self.sources.briefs if brief.level == level]),
                20,
            )
        ids = {brief.scenario_id for brief in self.sources.briefs}
        self.assertTrue(pipeline.RUNTIME_WIRE_SCENARIO_IDS.issubset(ids))

    def test_anchor_language_is_locked_in_briefs(self) -> None:
        by_id = {brief.scenario_id: brief for brief in self.sources.briefs}
        self.assertIn(
            "기사님, 천천히 좀 가 주실 수 있을까요?",
            by_id["taxi_slow_down"].must_include_ko,
        )
        awkward = " ".join(by_id["fremdschaemen_live"].must_include_ko)
        self.assertIn("내가 다 민망", awkward)
        self.assertIn("보는 내가 다 부끄러", awkward)

    def test_grammar_extraction_prefers_the_nearest_attested_level(self) -> None:
        patterns = [
            {
                "id": "grammar_a1_direction_time_particle",
                "level": "A1",
                "pattern": "N에",
                "type_de": "A1",
                "type_en": "A1",
                "explanation_de": "A1",
                "explanation_en": "A1",
            },
            {
                "id": "grammar_b2_instead_tradeoff",
                "level": "B2",
                "pattern": "V-는 대신(에)",
                "type_de": "B2",
                "type_en": "B2",
                "explanation_de": "B2",
                "explanation_en": "B2",
            },
        ]

        grammar = materializer._grammar_for(
            level="c2",
            korean="회의에 참석하는 대신 의견서를 냈습니다.",
            patterns=patterns,
        )

        self.assertEqual(grammar["id"], "grammar_b2_instead_tradeoff")

    def test_grammar_extraction_recognizes_c2_no_more_than_form(self) -> None:
        grammar = materializer._grammar_for(
            level="c2",
            korean="영상을 고치는 데 그치지 않고 이후 변화도 확인해야 합니다.",
            patterns=materializer._load_grammar_patterns(ROOT),
        )

        self.assertEqual(grammar["id"], "grammar_c2_no_more_than_doing")

    def test_every_prompt_stage_has_locked_context(self) -> None:
        packet = pipeline.build_prompt_packet("bakery_queue", root=ROOT)
        self.assertFalse(packet["externalApiAllowed"])
        self.assertFalse(packet["modelMayApprove"])
        for stage in packet["stages"]:
            prompt = stage.get("prompt") or stage.get("promptTemplate")
            self.assertNotIn("[LEVEL_PROFILE_JSON]", prompt)
            self.assertNotIn("[SCENARIO_BRIEF_JSON]", prompt)
            self.assertNotIn("[CHARACTER_PROFILES_JSON]", prompt)
        rendered = pipeline.render_stage_prompt(
            packet,
            "localize",
            {"kind": "learning_bundle_draft", "scenarioId": "bakery_queue"},
        )
        self.assertNotIn("[STAGE_INPUT_JSON]", rendered)
        self.assertIn('"scenarioId": "bakery_queue"', rendered)

        master_prompt = (ROOT / pipeline.PROMPT_RELATIVE).read_text(encoding="utf-8")
        self.assertIn("`title`과 `body`", master_prompt)
        self.assertNotIn("`inThisScene`", master_prompt)

    def test_candidate_contract_and_character_voice_resolution(self) -> None:
        payload = _candidate()
        brief = next(
            item for item in self.sources.briefs if item.scenario_id == "bakery_queue"
        )
        report = pipeline.validate_candidate(payload, brief, self.sources)
        self.assertTrue(report.ok, report.errors)
        pending = pipeline.build_tts_pending_manifest([payload], root=ROOT)
        voices = {
            (item["speaker"], item["resolvedCharacterId"], item["voice"])
            for item in pending["items"]
        }
        self.assertIn(("user", "christian", "male"), voices)
        self.assertIn(("sujin", "sujin", "female"), voices)
        quest_items = [item for item in pending["items"] if item["source"] == "quest"]
        self.assertEqual(len(quest_items), 1)
        self.assertEqual(quest_items[0]["path"], "/quests/0/data/audioKo")
        self.assertEqual(quest_items[0]["speaker"], "auto")
        self.assertFalse(pending["synthesisRequested"])
        self.assertFalse(pending["uploadRequested"])
        self.assertEqual(pending["scope"], "a1")
        self.assertEqual(pending["cacheRevision"], "v3")
        self.assertEqual(
            pending["candidateSetSha256"],
            pipeline.candidate_set_hash([payload]),
        )

    def test_candidate_requires_runtime_compatible_localized_cultural_note(self) -> None:
        payload = _candidate()
        brief = next(
            item for item in self.sources.briefs if item.scenario_id == "bakery_queue"
        )
        payload["scenario"]["culturalNote"] = {
            "inThisScene": "줄을 잘못 섰어요.",
            "range": "이 장면에서만 봐요.",
            "learnerAction": "짧게 사과해요.",
        }

        report = pipeline.validate_candidate(payload, brief, self.sources)

        self.assertFalse(report.ok)
        self.assertTrue(
            any("culturalNote.title" in item for item in report.errors),
            report.errors,
        )
        self.assertTrue(
            any("culturalNote.body" in item for item in report.errors),
            report.errors,
        )

    def test_runtime_write_requires_exact_tts_receipt_and_jin_authorization(self) -> None:
        candidates = [_candidate()]
        manifest = pipeline.build_tts_pending_manifest(candidates, root=ROOT)
        receipt = {
            "schemaVersion": 1,
            "kind": pipeline.TTS_READINESS_KIND,
            "generationId": pipeline.GENERATION_ID,
            "scope": "a1",
            "candidateSetSha256": pipeline.candidate_set_hash(candidates),
            "ttsManifestSha256": pipeline.tts_pending_manifest_hash(manifest),
            "expectedCount": manifest["count"],
            "verifiedCachePathCount": manifest["count"],
            "missingCount": 0,
            "cacheRevision": pipeline.TTS_CACHE_REVISION,
            "verificationMode": "firebase_storage_listing",
        }
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "tts-ready.json"
            path.write_text(json.dumps(receipt), encoding="utf-8")
            accepted = pipeline.assert_tts_ready_for_promotion(
                level="a1",
                candidates=candidates,
                manifest=manifest,
                receipt_path=path,
                runtime_write_reviewer="Jin",
                root=ROOT,
            )
            self.assertEqual(accepted, receipt)

            with self.assertRaisesRegex(pipeline.CorpusError, "explicit"):
                pipeline.assert_tts_ready_for_promotion(
                    level="a1",
                    candidates=candidates,
                    manifest=manifest,
                    receipt_path=path,
                    runtime_write_reviewer=None,
                    root=ROOT,
                )

            receipt["missingCount"] = 1
            path.write_text(json.dumps(receipt), encoding="utf-8")
            with self.assertRaisesRegex(pipeline.CorpusError, "missingCount"):
                pipeline.assert_tts_ready_for_promotion(
                    level="a1",
                    candidates=candidates,
                    manifest=manifest,
                    receipt_path=path,
                    runtime_write_reviewer="Jin",
                    root=ROOT,
                )

    def test_model_cannot_approve_or_impersonate_player_id(self) -> None:
        payload = _candidate()
        payload["approvedBy"] = "Jin"
        payload["scenario"]["dialog"][1]["speaker"] = "christian"
        brief = next(
            item for item in self.sources.briefs if item.scenario_id == "bakery_queue"
        )
        report = pipeline.validate_candidate(payload, brief, self.sources)
        self.assertFalse(report.ok)
        self.assertTrue(any("human-only approval" in item for item in report.errors))
        self.assertTrue(any("speaker=user" in item for item in report.errors))

    def test_candidate_rejects_invented_or_silent_audio_quest_contracts(self) -> None:
        payload = _candidate()
        brief = next(
            item for item in self.sources.briefs if item.scenario_id == "bakery_queue"
        )
        payload["scenario"]["quests"][0]["type"] = "modelInventedQuest"
        report = pipeline.validate_candidate(payload, brief, self.sources)
        self.assertTrue(
            any("supported runtime quest" in item for item in report.errors)
        )

        payload = _candidate()
        del payload["scenario"]["quests"][0]["data"]["audioKo"]
        report = pipeline.validate_candidate(payload, brief, self.sources)
        self.assertTrue(any("required for TTS playback" in item for item in report.errors))

    def test_only_jin_and_an_unchanged_full_level_can_pass_approval_gate(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaises(pipeline.CorpusError):
                pipeline.record_level_approval(
                    level="a1",
                    candidate_directory=Path(temp),
                    reviewer="model",
                    root=ROOT,
                )
        with self.assertRaises(pipeline.CorpusError):
            pipeline.assert_level_approved(
                level="a1",
                candidates=[],
                sources=self.sources,
            )

    def test_promotion_requires_each_earlier_level_to_be_promoted(self) -> None:
        candidates = [{"scenarioId": f"b1-{index}"} for index in range(20)]
        approvals = copy.deepcopy(self.sources.approvals)
        for level in ("a1", "a2"):
            approvals["levels"][level] = {
                "decision": "approved",
                "reviewer": "Jin",
                "reviewedScenarioCount": 20,
                "candidateSetSha256": "not-used-for-earlier-levels",
                "approvedAt": "2026-08-27T00:00:00+00:00",
                "promotedAt": (
                    "2026-08-27T01:00:00+00:00" if level == "a1" else None
                ),
            }
        approvals["levels"]["b1"] = {
            "decision": "approved",
            "reviewer": "Jin",
            "reviewedScenarioCount": 20,
            "candidateSetSha256": pipeline.candidate_set_hash(candidates),
            "approvedAt": "2026-08-27T02:00:00+00:00",
            "promotedAt": None,
        }
        sources = replace(self.sources, approvals=approvals)

        with self.assertRaisesRegex(pipeline.CorpusError, "A2 promotion first"):
            pipeline.assert_level_approved(
                level="b1",
                candidates=candidates,
                sources=sources,
            )

    def test_pipeline_module_has_no_network_client_import(self) -> None:
        tree = ast.parse(
            (SCRIPT_DIR / "scenario_corpus_pipeline.py").read_text(encoding="utf-8")
        )
        imported = {
            alias.name.split(".")[0]
            for node in ast.walk(tree)
            if isinstance(node, (ast.Import, ast.ImportFrom))
            for alias in node.names
        }
        self.assertTrue(
            imported.isdisjoint({"requests", "httpx", "urllib", "anthropic", "openai"})
        )

    def test_candidate_hash_changes_after_content_edit(self) -> None:
        original = _candidate()
        changed = copy.deepcopy(original)
        changed["scenario"]["dialog"][3]["ko"] = "네, 바로 뒤로 갈게요."
        self.assertNotEqual(
            pipeline.candidate_set_hash([original]),
            pipeline.candidate_set_hash([changed]),
        )

    def test_materialized_release_corpus_is_exact_and_editorially_clean(self) -> None:
        candidate_directory = (
            ROOT / "tools/content_factory/review/canonical_120_v1/candidates"
        )
        candidates = pipeline.load_corpus_candidates(
            candidate_directory,
            root=ROOT,
        )
        self.assertEqual(len(candidates), 120)
        self.assertEqual(
            {level: 20 for level in pipeline.LEVELS},
            dict(
                sorted(
                    Counter(
                        str(item["scenario"]["level"]) for item in candidates
                    ).items()
                )
            ),
        )
        self.assertEqual(
            sum(len(item["scenario"]["quests"]) for item in candidates),
            360,
        )
        report = editorial_audit.audit_corpus(candidate_directory, root=ROOT)
        self.assertTrue(report["summary"]["ok"], report["errors"])
        self.assertEqual(report["summary"]["errorCount"], 0)
        self.assertEqual(report["summary"]["warningCount"], 0)
        self.assertEqual(
            report["germanAddressPolicy"]["mixedSpeakerCount"],
            0,
        )
        self.assertFalse(report["automatedAuditIsApproval"])
        self.assertTrue(report["humanApprovalRequired"])

    def test_full_corpus_preflight_keeps_48_units_wires_and_tts_gate(self) -> None:
        result = pipeline.preflight_corpus(
            candidate_directory=(
                ROOT / "tools/content_factory/review/canonical_120_v1/candidates"
            ),
            root=ROOT,
        )
        self.assertEqual(result["candidateCount"], 120)
        self.assertEqual(result["scenarioCounts"], {level: 20 for level in pipeline.LEVELS})
        self.assertEqual(result["courseUnitCount"], 48)
        self.assertEqual(result["scenarioLinkCount"], 120)
        self.assertEqual(result["checkpointCount"], 48)
        self.assertEqual(result["questCount"], 360)
        self.assertEqual(result["ttsPendingCount"], 837)
        self.assertEqual(
            result["wireContentLinkIds"],
            {
                "introduce_yourself": "link:94c139e887716700674589b2",
                "bunshik_tteokbokki": "link:e6a9f1197b48c79f58655c9a",
                "taxi_kakao": "link:49a189a1b8b9e4fa022a4557",
            },
        )
        self.assertFalse(result["approvalRecorded"])
        self.assertFalse(result["runtimeWritten"])
        self.assertFalse(result["releaseReady"])

    def test_nonrelease_regression_ladders_are_exact(self) -> None:
        directory = (
            ROOT
            / "tools/content_factory/review/canonical_120_v1/regression_candidates"
        )
        candidates = pipeline.load_regression_candidates(directory, root=ROOT)
        self.assertEqual(len(candidates), 12)
        by_level = Counter(
            str(item["scenario"]["level"]) for item in candidates
        )
        self.assertEqual(by_level, {level: 2 for level in pipeline.LEVELS})
        self.assertTrue(
            all(len(item["scenario"]["dialog"]) >= 6 for item in candidates)
        )
        report = pipeline.preflight_regression_ladders(directory, root=ROOT)
        self.assertTrue(report["ok"])
        self.assertFalse(report["releaseEligible"])
        self.assertFalse(report["lengthIsApprovalCriterion"])
        self.assertEqual(set(report["themes"]), set(self.sources.manifest.raw["regressionThemes"]))
        self.assertTrue(
            all(
                [row["level"] for row in rows] == list(pipeline.LEVELS)
                for rows in report["themes"].values()
            )
        )

    def test_all_offline_corpus_tools_avoid_network_clients(self) -> None:
        imported: set[str] = set()
        for name in (
            "scenario_corpus_pipeline.py",
            "manage_scenario_corpus.py",
            "materialize_canonical_scenarios.py",
            "audit_canonical_scenarios.py",
        ):
            tree = ast.parse((SCRIPT_DIR / name).read_text(encoding="utf-8"))
            imported.update(
                alias.name.split(".")[0]
                for node in ast.walk(tree)
                if isinstance(node, (ast.Import, ast.ImportFrom))
                for alias in node.names
            )
        self.assertTrue(
            imported.isdisjoint(
                {"requests", "httpx", "urllib", "anthropic", "openai"}
            )
        )


if __name__ == "__main__":
    unittest.main()
