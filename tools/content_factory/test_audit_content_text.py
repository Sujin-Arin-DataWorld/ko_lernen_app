from __future__ import annotations

import json
import unittest
from pathlib import Path

from audit_content_text import (
    SURFACES,
    build_inventory,
    collect_copy_leaves,
    find_incomplete_language_triplets,
)
from apply_content_humanization import apply as verify_humanized_copy


class ContentTextAuditTest(unittest.TestCase):
    def test_humanization_ledger_matches_runtime_and_covers_every_level(self) -> None:
        self.assertEqual(verify_humanized_copy(check_only=True), 0)

    def test_humanized_smalltalk_keeps_semantic_routes_pending_native_copy_review(
        self,
    ) -> None:
        root = Path(__file__).parents[2]
        ledger = json.loads(
            (root / "tools/content_factory/review/content_humanization_20260821.json").read_text(
                encoding="utf-8"
            )
        )
        changed_ids = {
            row["id"]
            for row in ledger["changes"]
            if row["level"] in {"a1", "a2", "b1", "b2"}
        }
        authority = json.loads(
            (root / "assets/data/can_do_content_authorities.json").read_text(
                encoding="utf-8"
            )
        )
        decisions = {
            row["phraseId"]: row
            for row in authority["coverage"]["smalltalkRoutingAudit"][
                "phraseDecisions"
            ]
        }

        self.assertEqual(len(changed_ids), 42)
        for record_id in changed_ids:
            decision = decisions[record_id]
            self.assertEqual(decision["copyRevision"], 1)
            self.assertEqual(decision["copyReviewStatus"], "nativeReviewRequired")
            self.assertEqual(
                decision["copyRevisionLedger"],
                "tools/content_factory/review/content_humanization_20260821.json",
            )

    def test_smalltalk_known_machine_like_copy_is_humanized_across_a1_to_c2(self) -> None:
        data = json.loads(
            (Path(__file__).parents[2] / "assets" / "data" / "smalltalk.json").read_text(
                encoding="utf-8"
            )
        )
        by_id = {row["id"]: row for row in data["phrases"]}

        expected = {
            "smalltalk_a1_0025": {
                "de": "Schlaf gut und träum was Schönes.",
                "en": "Sleep well. Sweet dreams.",
            },
            "smalltalk_a1_0081": {
                "de": "Sie haben nicht vergessen, heute Abend den Müll rauszubringen, oder?",
                "en": "You haven't forgotten to take out the trash tonight, right?",
            },
            "smalltalk_a2_0050": {
                "reply.de": "Wählen Sie zuerst die Landesvorwahl.",
                "reply.en": "Dial the country code first.",
            },
            "smalltalk_b1_0071": {
                "de": "Wenn wir den Entwurf heute noch durchsehen wollen, womit sollten wir anfangen?",
                "en": "If we want to look over the draft today, where should we start?",
            },
            "smalltalk_b2_0099": {
                "de": "Ich überlege, ob ich diese Erfahrung als Ergebnis oder als Prozess darstelle.",
                "en": "I'm deciding whether to present this experience in terms of the outcome or the process.",
            },
            "smalltalk_c1_0014": {
                "de": "Die Installation ist günstig, die laufenden Kosten sind aber hoch. Sollen wir das Gerät trotzdem wählen?",
                "en": "Installation is cheap, but the running costs are high. Should we still choose the equipment?",
            },
            "smalltalk_c1_0027": {
                "de": "Haben Sie Daten gesehen, die zeigen, dass die Spielzeitbegrenzung tatsächlich wirksam war?",
            },
            "smalltalk_c2_0026": {
                "de": "Nur weil es eine Anlaufstelle gibt, ist noch keine wirksame Abhilfe gewährleistet.",
                "en": "Having an appeals channel does not guarantee an effective remedy.",
            },
            "smalltalk_c2_0029": {
                "en": "Whose perspective do you think shapes the way the story is being told now?",
            },
        }

        for record_id, fields in expected.items():
            row = by_id[record_id]
            for field_path, value in fields.items():
                actual = row
                for part in field_path.split("."):
                    actual = actual[part]
                self.assertEqual(actual, value, f"{record_id}.{field_path}")

    def test_every_shipped_data_file_has_an_explicit_content_classification(self) -> None:
        inventory = build_inventory()
        self.assertEqual(inventory["coveredFiles"], len(SURFACES))
        self.assertEqual(inventory["unclassifiedFiles"], [])
        self.assertEqual(inventory["missingFiles"], [])

    def test_text_inventory_has_no_unresolved_markers(self) -> None:
        inventory = build_inventory()
        self.assertEqual(inventory["totals"]["unresolvedMarkers"], 0)
        self.assertGreater(inventory["totals"]["textValues"], 0)

    def test_copy_leaf_ledger_keeps_record_level_language_and_stable_path(self) -> None:
        fixture = {
            "phrases": [
                {
                    "id": "smalltalk_c1_demo",
                    "level": "c1",
                    "ko": "근거를 같이 확인해 볼까요?",
                    "de": "Wollen wir die Belege gemeinsam prüfen?",
                    "en": "Shall we check the evidence together?",
                    "reply": {
                        "ko": "좋아요.",
                        "de": "Gern.",
                        "en": "Sure.",
                    },
                }
            ]
        }

        leaves = collect_copy_leaves(fixture, file_name="smalltalk.json")

        self.assertEqual(
            [leaf["fieldPath"] for leaf in leaves],
            [
                "$.phrases[0].ko",
                "$.phrases[0].de",
                "$.phrases[0].en",
                "$.phrases[0].reply.ko",
                "$.phrases[0].reply.de",
                "$.phrases[0].reply.en",
            ],
        )
        self.assertEqual({leaf["recordId"] for leaf in leaves}, {"smalltalk_c1_demo"})
        self.assertEqual({leaf["level"] for leaf in leaves}, {"c1"})
        self.assertEqual(
            [leaf["language"] for leaf in leaves],
            ["ko", "de", "en", "ko", "de", "en"],
        )
        self.assertEqual(leaves[0]["text"], "근거를 같이 확인해 볼까요?")
        self.assertTrue(all(len(leaf["sha256"]) == 64 for leaf in leaves))

    def test_copy_leaf_ledger_catalogues_optional_blank_without_dropping_it(self) -> None:
        leaves = collect_copy_leaves(
            {"id": "scenario_a1_demo", "level": "a1", "body": ""},
            file_name="scenarios_a1.json",
        )

        self.assertEqual(len(leaves), 1)
        self.assertEqual(leaves[0]["coverageState"], "catalogued_blank")
        self.assertEqual(leaves[0]["recordId"], "scenario_a1_demo")

    def test_partial_korean_translation_triplet_is_reported(self) -> None:
        gaps = find_incomplete_language_triplets(
            {
                "phrases": [
                    {
                        "id": "smalltalk_b2_demo",
                        "level": "b2",
                        "ko": "자료를 다시 확인해 볼게요.",
                        "de": "Ich prüfe die Unterlagen noch einmal.",
                    },
                    {
                        "id": "metadata_only",
                        "de": "Metadaten",
                        "en": "Metadata",
                    },
                ]
            },
            file_name="smalltalk.json",
        )

        self.assertEqual(
            gaps,
            [
                {
                    "file": "smalltalk.json",
                    "recordId": "smalltalk_b2_demo",
                    "level": "b2",
                    "objectPath": "$.phrases[0]",
                    "missingLanguages": ["en"],
                }
            ],
        )
