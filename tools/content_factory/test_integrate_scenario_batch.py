#!/usr/bin/env python3
"""Scenario-batch transaction and review-only validation regressions."""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import integrate_scenario_batch as integration
from integrate_scenario_batch import (
    REVIEW_HEADER,
    ScenarioIntegrationError,
    _refresh_meta,
    _validate_batch,
    _validate_bundle,
)
from render_review_packet import render_packet
import scenario_store


class ScenarioBatchTransactionTest(unittest.TestCase):
    def test_merged_batch36_replay_rejects_frozen_copy_without_overwriting_runtime(self) -> None:
        repository = SCRIPT_DIR.parents[1]
        relative_manifest = Path("tools/content_factory/drafts/batch_36_priority_surfaces_manifest.json")
        manifest = json.loads((repository / relative_manifest).read_text(encoding="utf-8"))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "repo"
            shutil.copytree(repository / "assets/data", root / "assets/data")
            evidence_paths = [
                relative_manifest,
                Path("functions/analyze_korean_text/grammar_patterns.json"),
                Path("tools/content_factory/content_audit_manifest.json"),
                Path("tools/content_factory/review/promoted_copy_revisions_20260822.json"),
                *[Path(row[key]) for row in manifest["artifacts"] for key in ("draft", "review")],
            ]
            for relative in evidence_paths:
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(repository / relative, target)
            protected = [
                *[path for path in (root / "assets/data").rglob("*") if path.is_file()],
                *[root / relative for relative in evidence_paths],
            ]
            before = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in protected}
            # Exercise the real frozen review, copy-revision checker and merge
            # transaction. A stale historical replay must refuse current copy
            # before any write, including when --apply was explicitly requested.
            with mock.patch.object(integration, "_atomic_write") as writer:
                with self.assertRaisesRegex(
                    ScenarioIntegrationError,
                    "merged scenario payload no longer matches its approved draft",
                ):
                    integration.integrate(root=root, manifest_path=relative_manifest, apply=True)
                writer.assert_not_called()
            self.assertEqual(before, {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in protected})

    def test_atomic_restore_preserves_original_bytes_and_newlines(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "content.csv"
            original = b"id,level\r\nexample,a1\r\n"
            target.write_bytes(original)

            integration._atomic_write(target, "id,level\nchanged,c2\n")
            integration._atomic_restore(target, original)

            self.assertEqual(original, target.read_bytes())
            self.assertFalse(
                target.with_name(f".{target.name}.scenario-integration.tmp").exists()
            )

    def test_atomic_write_retries_one_transient_windows_lock(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "content.json"
            target.write_text('{"old":true}\n', encoding="utf-8")
            real_replace = integration.os.replace
            calls = 0

            def flaky_replace(source, destination):
                nonlocal calls
                calls += 1
                if calls == 1:
                    raise PermissionError(5, "transient Windows file lock")
                return real_replace(source, destination)

            with (
                mock.patch.object(integration.os, "replace", side_effect=flaky_replace),
                mock.patch.object(integration.time, "sleep") as sleeper,
            ):
                integration._atomic_write(target, '{"new":true}\n')

            self.assertEqual(target.read_text(encoding="utf-8"), '{"new":true}\n')
            self.assertEqual(calls, 2)
            sleeper.assert_called_once()

    def test_manifest_write_can_fallback_when_windows_blocks_rename(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "batch_manifest.json"
            target.write_text('{"status":"approved"}\n', encoding="utf-8")

            with mock.patch.object(
                integration,
                "_replace_with_retry",
                side_effect=PermissionError(5, "persistent Windows file lock"),
            ):
                integration._atomic_write(
                    target,
                    '{"status":"merged"}\n',
                    allow_in_place_fallback=True,
                )

            self.assertEqual(
                target.read_text(encoding="utf-8"),
                '{"status":"merged"}\n',
            )
            self.assertFalse(
                target.with_name(
                    f".{target.name}.scenario-integration.tmp"
                ).exists()
            )

    def test_post_write_failure_restores_every_target_byte_exactly(self) -> None:
        repository = SCRIPT_DIR.parents[1]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "repo"
            shutil.copytree(repository / "assets" / "data", root / "assets" / "data")

            grammar_source = (
                repository
                / "functions"
                / "analyze_korean_text"
                / "grammar_patterns.json"
            )
            grammar_target = (
                root / "functions" / "analyze_korean_text" / "grammar_patterns.json"
            )
            grammar_target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(grammar_source, grammar_target)

            # F6 (2026-09-01): content_audit_manifest.json은 번들 제외를
            # 위해 assets/data/ 밖 tools/content_factory/ 로 옮겼다.
            audit_source = repository / "tools" / "content_factory" / "content_audit_manifest.json"
            audit_target = root / "tools" / "content_factory" / "content_audit_manifest.json"
            audit_target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(audit_source, audit_target)

            relative_manifest = Path(
                "tools/content_factory/drafts/rollback_probe_manifest.json"
            )
            manifest_target = root / relative_manifest
            manifest_target.parent.mkdir(parents=True, exist_ok=True)
            manifest_target.write_bytes(b'{"status":"approved"}\r\n')

            data_dir = root / "assets" / "data"
            scenarios_root = scenario_store.load_root(data_dir)
            record = dict(scenarios_root["scenarios"][0])
            scenarios_target = data_dir / scenario_store.target_shard(record)
            record["id"] = "scenario_transaction_rollback_probe"
            unit_id = record["courseUnitId"]
            manifest = {
                "batch": "99",
                "status": "approved",
                "recordCount": 1,
                "contentLinks": [
                    {
                        "contentKind": "scenario",
                        "contentId": record["id"],
                        "courseUnitId": unit_id,
                        "role": "practice",
                    }
                ],
                "provenance": {},
            }
            outputs = [
                scenarios_target,
                root / "assets" / "data" / "curriculum_manifest.json",
                # F6 (2026-09-01): 최종 목적지는 tools/content_factory/ 다.
                root / "tools" / "content_factory" / "content_audit_manifest.json",
                manifest_target,
            ]
            originals = {path: path.read_bytes() for path in outputs}
            failure = SimpleNamespace(
                source="rollback-probe",
                message="forced post-write validation failure",
            )

            with (
                mock.patch.object(
                    integration,
                    "_validate_bundle",
                    return_value=(
                        manifest_target,
                        manifest,
                        {"scenario": [record]},
                        {record["id"]: "home"},
                    ),
                ),
                mock.patch.object(
                    integration.ContentValidator,
                    "validate",
                    side_effect=[[], [failure]],
                ),
            ):
                with self.assertRaisesRegex(
                    integration.ScenarioIntegrationError,
                    "scenario integration rolled back",
                ):
                    integration.integrate(
                        root=root,
                        manifest_path=relative_manifest,
                        apply=True,
                    )

            for path, expected in originals.items():
                self.assertEqual(expected, path.read_bytes(), path)
                self.assertFalse(
                    path.with_name(
                        f".{path.name}.scenario-integration.tmp"
                    ).exists(),
                    path,
                )


class ScenarioBatchValidationTest(unittest.TestCase):
    def make_batch(self, root: Path, *, quest_count: int = 2) -> Path:
        draft_path = root / "tools" / "content_factory" / "drafts" / "scenarios.json"
        review_path = root / "tools" / "content_factory" / "review" / "scenarios.csv"
        manifest_path = root / "tools" / "content_factory" / "drafts" / "batch_06_manifest.json"
        draft_path.parent.mkdir(parents=True)
        review_path.parent.mkdir(parents=True)
        scenarios = [
            {
                "id": "c1_review_example",
                "level": "c1",
                "title": {"ko": "근거 검토", "de": "Evidenz prüfen", "en": "Reviewing evidence"},
                "quests": [{"id": "quest_c1_review", "type": "diktat", "data": {}}],
            },
            {
                "id": "c2_appeal_example",
                "level": "c2",
                "title": {"ko": "이의 제기", "de": "Einspruch", "en": "Appeal"},
                "quests": [{"id": "quest_c2_appeal", "type": "diktat", "data": {}}],
            },
        ]
        draft_path.write_text(
            json.dumps({"version": 1, "scenarios": scenarios}, ensure_ascii=False),
            encoding="utf-8",
        )
        with review_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
            writer.writeheader()
            for record in scenarios:
                writer.writerow(
                    {
                        "id": record["id"],
                        "level": record["level"].upper(),
                        "ko": record["title"]["ko"],
                        "de": record["title"]["de"],
                        "en": record["title"]["en"],
                        "field_notes": "rights: original",
                        "상태": "draft",
                        "jin_memo": "",
                    }
                )
        manifest = {
            "version": 1,
            "batch": "06",
            "status": "review_only_draft",
            "artifacts": [
                {
                    "kind": "scenario",
                    "draft": "tools/content_factory/drafts/scenarios.json",
                    "review": "tools/content_factory/review/scenarios.csv",
                    "count": 2,
                    "levels": {"c1": 1, "c2": 1},
                }
            ],
            "recordCount": 2,
            "questCount": quest_count,
            "contentLinks": [
                {
                    "contentKind": "scenario",
                    "contentId": "c1_review_example",
                    "courseUnitId": "c1_example",
                    "role": "assess",
                },
                {
                    "contentKind": "scenario",
                    "contentId": "c2_appeal_example",
                    "courseUnitId": "c2_example",
                    "role": "assess",
                },
            ],
            "backdrops": {
                "c1_review_example": "office",
                "c2_appeal_example": "office",
            },
        }
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        return manifest_path.relative_to(root)

    def test_preview_accepts_review_only_c1_c2_batch(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_batch(root)
            _, parsed, records, backdrops = _validate_batch(
                root,
                manifest,
                require_approved=False,
            )
            self.assertEqual(parsed["batch"], "06")
            self.assertEqual([record["level"] for record in records], ["c1", "c2"])
            self.assertEqual(set(backdrops), {"c1_review_example", "c2_appeal_example"})

    def test_complete_review_packet_supports_scenario_bundles(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_batch(root)

            packet = render_packet(manifest_path=manifest, root=root)

            self.assertIn("# Batch 06 — Complete Review Packet", packet)
            self.assertIn("## Scenario (2)", packet)
            self.assertIn("`c1_review_example` · C1", packet)

    def test_apply_rejects_unapproved_batch(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_batch(root)
            with self.assertRaisesRegex(ScenarioIntegrationError, "approved before promotion"):
                _validate_batch(root, manifest, require_approved=True)

    def test_quest_count_is_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.make_batch(root, quest_count=3)
            with self.assertRaisesRegex(ScenarioIntegrationError, "quest count disagrees"):
                _validate_batch(root, manifest, require_approved=False)

    def test_companion_game_artifact_is_validated_and_counted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest_path = root / self.make_batch(root)
            draft_path = root / "tools" / "content_factory" / "drafts" / "pronunciation.json"
            review_path = root / "tools" / "content_factory" / "review" / "pronunciation.csv"
            record = {
                "id": "pronunciation_c1_9999",
                "level": "c1",
                "ko": "근거를 다시 검토하겠습니다.",
                "de": "Ich werde die Evidenz erneut prüfen.",
                "en": "I will review the evidence again.",
                "focus": "문장 끝 억양",
            }
            draft_path.write_text(
                json.dumps({"version": 1, "phrases": [record]}, ensure_ascii=False),
                encoding="utf-8",
            )
            with review_path.open("w", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
                writer.writeheader()
                writer.writerow(
                    {
                        "id": record["id"],
                        "level": "C1",
                        "ko": record["ko"],
                        "de": record["de"],
                        "en": record["en"],
                        "field_notes": "rights: original",
                        "상태": "draft",
                        "jin_memo": "",
                    }
                )
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["artifacts"].append(
                {
                    "kind": "pronunciation",
                    "draft": "tools/content_factory/drafts/pronunciation.json",
                    "review": "tools/content_factory/review/pronunciation.csv",
                    "collection": "phrases",
                    "count": 1,
                    "levels": {"c1": 1},
                }
            )
            manifest["recordCount"] = 3
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            _, _, records, _ = _validate_bundle(
                root,
                manifest_path.relative_to(root),
                require_approved=False,
            )
            self.assertEqual(set(records), {"scenario", "pronunciation"})

    def test_meta_refresh_uses_all_six_levels(self) -> None:
        root = {
            "meta": {"total": 1, "perLevel": {"a1": 1}},
            "items": [
                {"level": "a1"},
                {"level": "c1"},
                {"level": "c2"},
            ],
        }
        _refresh_meta(root, "items")
        self.assertEqual(root["meta"]["total"], 3)
        self.assertEqual(
            root["meta"]["perLevel"],
            {"a1": 1, "a2": 0, "b1": 0, "b2": 0, "c1": 1, "c2": 1},
        )


class ScenarioCultureLinkTransactionTest(unittest.TestCase):
    def make_root(self, directory: str, *, term_id: str = "term_a") -> tuple[Path, Path, Path]:
        root = Path(directory)
        (root / "assets" / "data").mkdir(parents=True)
        (root / "docs" / "data").mkdir(parents=True)
        draft = root / "tools" / "content_factory" / "drafts" / "culture_links.json"
        draft.parent.mkdir(parents=True)
        (root / "assets" / "data" / "scenario_culture_links.json").write_text(
            json.dumps({"schemaVersion": 1, "links": []}),
            encoding="utf-8",
        )
        (root / "docs" / "data" / "cultural_glossary.json").write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "entries": [{"termId": term_id}],
                }
            ),
            encoding="utf-8",
        )
        return root, root / "assets" / "data", draft

    def test_culture_links_are_staged_with_their_scenarios(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, data, draft = self.make_root(directory)
            draft.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "links": [{"scenarioId": "scene_a", "termIds": ["term_a"]}],
                    }
                ),
                encoding="utf-8",
            )
            manifest = {
                "status": "review_only_draft",
                "cultureLinksDraft": str(draft.relative_to(root)),
                "cultureLinkCount": 1,
            }

            self.assertTrue(
                integration._stage_culture_links(
                    root, data, manifest, [{"id": "scene_a"}]
                )
            )
            staged = json.loads(
                (data / "scenario_culture_links.json").read_text(encoding="utf-8")
            )
            self.assertEqual(
                staged["links"],
                [{"scenarioId": "scene_a", "termIds": ["term_a"]}],
            )

    def test_culture_links_reject_unknown_glossary_terms(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, data, draft = self.make_root(directory)
            draft.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "links": [
                            {"scenarioId": "scene_a", "termIds": ["missing_term"]}
                        ],
                    }
                ),
                encoding="utf-8",
            )
            manifest = {
                "status": "review_only_draft",
                "cultureLinksDraft": str(draft.relative_to(root)),
                "cultureLinkCount": 1,
            }

            with self.assertRaisesRegex(
                ScenarioIntegrationError, "unknown terms"
            ):
                integration._stage_culture_links(
                    root, data, manifest, [{"id": "scene_a"}]
                )

    def test_merged_culture_links_are_idempotent_but_frozen(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, data, draft = self.make_root(directory)
            link = {"scenarioId": "scene_a", "termIds": ["term_a"]}
            draft.write_text(
                json.dumps({"schemaVersion": 1, "links": [link]}),
                encoding="utf-8",
            )
            (data / "scenario_culture_links.json").write_text(
                json.dumps({"schemaVersion": 1, "links": [link]}),
                encoding="utf-8",
            )
            manifest = {
                "status": "merged",
                "cultureLinksDraft": str(draft.relative_to(root)),
                "cultureLinkCount": 1,
            }

            before = (data / "scenario_culture_links.json").read_bytes()
            self.assertTrue(
                integration._stage_culture_links(
                    root, data, manifest, [{"id": "scene_a"}]
                )
            )
            self.assertEqual(
                (data / "scenario_culture_links.json").read_bytes(), before
            )

            draft.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "links": [
                            {"scenarioId": "scene_a", "termIds": ["term_a", "other"]}
                        ],
                    }
                ),
                encoding="utf-8",
            )
            manifest["cultureLinkCount"] = 1
            # Add the second term to the glossary so the frozen-payload check,
            # not glossary validation, owns this failure.
            glossary_path = root / "docs" / "data" / "cultural_glossary.json"
            glossary_path.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "entries": [{"termId": "term_a"}, {"termId": "other"}],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                ScenarioIntegrationError, "no longer matches"
            ):
                integration._stage_culture_links(
                    root, data, manifest, [{"id": "scene_a"}]
                )


class CultureStoryArcTransactionTest(unittest.TestCase):
    def make_root(self, directory: str) -> tuple[Path, Path, Path]:
        root = Path(directory)
        data = root / "assets" / "data"
        data.mkdir(parents=True)
        draft = (
            root
            / "tools"
            / "content_factory"
            / "drafts"
            / "culture_story_arcs.json"
        )
        draft.parent.mkdir(parents=True)
        (data / "scenario_culture_links.json").write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "links": [
                        {"scenarioId": "scene_a", "termIds": ["term_a"]},
                        {"scenarioId": "scene_b", "termIds": ["term_b"]},
                    ],
                }
            ),
            encoding="utf-8",
        )
        (data / "culture_story_arcs.json").write_text(
            json.dumps({"schemaVersion": 1, "arcs": []}),
            encoding="utf-8",
        )
        return root, data, draft

    def arc_payload(self) -> dict:
        return {
            "schemaVersion": 1,
            "status": "review_only",
            "arcs": [
                {
                    "arcId": "sample_arc",
                    "title": {
                        "ko": "표본 문화 길",
                        "de": "Beispiel-Kulturpfad",
                        "en": "Sample culture path",
                    },
                    "summary": {
                        "ko": "기존 장면을 묶는 읽기 전용 문화 길입니다.",
                        "de": "Ein schreibgeschützter Kulturpfad aus bestehenden Szenen.",
                        "en": "A read-only culture path grouping existing scenes.",
                    },
                    "progressMode": "derived_read_only",
                    "steps": [
                        {
                            "scenarioId": "scene_a",
                            "personaIds": ["maya"],
                            "termIds": ["term_a"],
                        },
                        {
                            "scenarioId": "scene_b",
                            "personaIds": ["jun"],
                            "termIds": ["term_b"],
                        },
                    ],
                }
            ],
        }

    def test_story_arcs_stage_only_after_scenario_culture_links_exist(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, data, draft = self.make_root(directory)
            draft.write_text(
                json.dumps(self.arc_payload(), ensure_ascii=False),
                encoding="utf-8",
            )
            manifest = {
                "status": "review_only_draft",
                "cultureStoryArcsDraft": str(draft.relative_to(root)),
            }

            self.assertTrue(
                integration._stage_culture_story_arcs(root, data, manifest)
            )
            staged = json.loads(
                (data / "culture_story_arcs.json").read_text(encoding="utf-8")
            )
            self.assertEqual(staged["arcs"][0]["arcId"], "sample_arc")

    def test_story_arcs_reject_non_live_scenario_or_unlinked_term(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, data, draft = self.make_root(directory)
            payload = self.arc_payload()
            payload["arcs"][0]["steps"][1]["scenarioId"] = "review_only_scene"
            draft.write_text(
                json.dumps(payload, ensure_ascii=False),
                encoding="utf-8",
            )
            manifest = {
                "status": "review_only_draft",
                "cultureStoryArcsDraft": str(draft.relative_to(root)),
            }
            with self.assertRaisesRegex(
                ScenarioIntegrationError, "references non-live scenario"
            ):
                integration._stage_culture_story_arcs(root, data, manifest)

            payload = self.arc_payload()
            payload["arcs"][0]["steps"][0]["termIds"] = ["other_term"]
            draft.write_text(
                json.dumps(payload, ensure_ascii=False),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                ScenarioIntegrationError, "not linked to that scenario"
            ):
                integration._stage_culture_story_arcs(root, data, manifest)

    def test_merged_story_arcs_are_idempotent_but_frozen(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, data, draft = self.make_root(directory)
            payload = self.arc_payload()
            payload["status"] = "merged"
            draft.write_text(
                json.dumps(payload, ensure_ascii=False),
                encoding="utf-8",
            )
            (data / "culture_story_arcs.json").write_text(
                json.dumps(
                    {"schemaVersion": 1, "arcs": payload["arcs"]},
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            manifest = {
                "status": "merged",
                "cultureStoryArcsDraft": str(draft.relative_to(root)),
            }
            before = (data / "culture_story_arcs.json").read_bytes()
            self.assertTrue(
                integration._stage_culture_story_arcs(root, data, manifest)
            )
            self.assertEqual(
                (data / "culture_story_arcs.json").read_bytes(),
                before,
            )

            payload["arcs"][0]["summary"]["en"] = "Changed after review."
            draft.write_text(
                json.dumps(payload, ensure_ascii=False),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                ScenarioIntegrationError, "no longer matches"
            ):
                integration._stage_culture_story_arcs(root, data, manifest)


if __name__ == "__main__":
    unittest.main()
