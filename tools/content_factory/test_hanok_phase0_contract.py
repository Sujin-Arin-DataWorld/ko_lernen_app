#!/usr/bin/env python3
"""Fail-closed tests for the review-only Hanok Phase 0 contracts."""

from __future__ import annotations

import copy
import importlib.util
import json
import sys
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = Path(__file__).with_name("build_hanok_grants.py")
SPEC = importlib.util.spec_from_file_location("build_hanok_grants", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot import {MODULE_PATH}")
builder = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = builder
SPEC.loader.exec_module(builder)


class HanokPhase0ContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.grants = builder.build()
        cls.masterplan, cls.remapping = builder._load_phase0_contract(cls.grants)

    def test_contract_files_are_normalized_review_only_inputs(self) -> None:
        for path, payload in (
            (builder.MASTERPLAN_PATH, self.masterplan),
            (builder.REMAPPING_PATH, self.remapping),
        ):
            self.assertEqual(
                builder._encoded(payload),
                path.read_text(encoding="utf-8"),
            )
            self.assertEqual("phase0Review", payload["status"])
            self.assertFalse(payload["runtimeEnabled"])

        serialized = json.dumps(
            [self.masterplan, self.remapping],
            ensure_ascii=False,
        ).lower()
        self.assertNotIn("assets/", serialized)
        self.assertNotIn(".png", serialized)
        self.assertNotIn(".webp", serialized)
        self.assertNotIn("firebase", serialized)
        self.assertNotIn("firestore", serialized)

    def test_masterplan_has_one_accessible_socket_and_camera_per_level(self) -> None:
        levels = list(builder.LEVEL_ORDER)
        sockets = self.masterplan["levelSockets"]
        cameras = self.masterplan["cameraReveals"]
        self.assertEqual(levels, [row["level"] for row in sockets])
        self.assertEqual(levels, [row["level"] for row in cameras])
        self.assertEqual(list(range(1, 7)), [row["order"] for row in cameras])
        self.assertTrue(
            all(row["minimumLogicalHitSize"] >= 48 for row in sockets)
        )
        self.assertEqual(
            "oneRepresentativeSocketPerLevel",
            self.masterplan["overviewSocketPolicy"],
        )
        self.assertEqual(
            {"daecheongmaru", "rear_garden"},
            set(self.masterplan["retiredStructureIds"]),
        )

    def test_masterplan_pins_approved_architectural_and_visual_canon(self) -> None:
        self.assertEqual(
            {
                "id": "unjoru_validated_original_jongga",
                "reconstructionMode": "grammarOnly",
                "frontBoundary": "integratedHaengrangAndSotdaeulmun",
                "sarangComplex": "asymmetricalWithModestNumaru",
                "anchae": "fourWingCourtyard",
                "serviceCourt": "attachedToAnchae",
                "shrine": "separateRearEnclosure",
                "elevationBands": [
                    "frontLow",
                    "sarangMiddle",
                    "anchaeShrineHigh",
                ],
            },
            self.masterplan["architecturalGrammar"],
        )
        self.assertEqual(
            {
                "id": "hangul_sori_compound_faceted_minhwa",
                "architectureAuthority": "unjoruSpatialGrammar",
                "visualDnaAuthority": "legacyCompoundAndCrossChannelGate",
                "geometryAuthority": "approvedSingleGoldenMaster",
                "legacyPixelReuse": False,
                "runtimeAssetPromotion": "deferred",
            },
            self.masterplan["visualCanon"],
        )

    def test_masterplan_uses_integrated_front_and_attached_service_zones(self) -> None:
        zones = {row["id"]: row["bounds"] for row in self.masterplan["zones"]}
        self.assertEqual(
            {
                "zone_outer_approach": {
                    "x": 0,
                    "y": 660,
                    "width": 1000,
                    "height": 90,
                },
                "zone_front_haengrang_boundary": {
                    "x": 50,
                    "y": 590,
                    "width": 900,
                    "height": 70,
                },
                "zone_sarang_court": {
                    "x": 260,
                    "y": 360,
                    "width": 480,
                    "height": 230,
                },
                "zone_sarang_complex": {
                    "x": 310,
                    "y": 275,
                    "width": 370,
                    "height": 100,
                },
                "zone_inner_threshold": {
                    "x": 440,
                    "y": 230,
                    "width": 120,
                    "height": 55,
                },
                "zone_anchae_courtyard": {
                    "x": 300,
                    "y": 55,
                    "width": 400,
                    "height": 200,
                },
                "zone_attached_kitchen_service": {
                    "x": 680,
                    "y": 245,
                    "width": 240,
                    "height": 260,
                },
                "zone_rear_shrine": {
                    "x": 750,
                    "y": 45,
                    "width": 170,
                    "height": 170,
                },
                "zone_transmission_expansion": {
                    "x": 80,
                    "y": 55,
                    "width": 190,
                    "height": 200,
                },
            },
            zones,
        )
        sockets = {row["level"]: row for row in self.masterplan["levelSockets"]}
        self.assertEqual("zone_sarang_complex", sockets["a2"]["zoneId"])
        self.assertEqual(
            "zone_attached_kitchen_service",
            sockets["b2"]["zoneId"],
        )
        self.assertEqual("zone_anchae_courtyard", sockets["c1"]["zoneId"])
        self.assertEqual(
            {
                "a1": {"x": 500, "y": 470},
                "a2": {"x": 490, "y": 325},
                "b1": {"x": 500, "y": 255},
                "b2": {"x": 790, "y": 275},
                "c1": {"x": 500, "y": 155},
                "c2": {"x": 175, "y": 170},
            },
            {level: row["position"] for level, row in sockets.items()},
        )

        cameras = {row["level"]: row for row in self.masterplan["cameraReveals"]}
        self.assertEqual(
            {
                "a1": {
                    "viewport": {"x": 200, "y": 300, "width": 600, "height": 450},
                    "visibleZoneIds": [
                        "zone_outer_approach",
                        "zone_front_haengrang_boundary",
                        "zone_sarang_court",
                        "zone_sarang_complex",
                    ],
                },
                "a2": {
                    "viewport": {"x": 240, "y": 230, "width": 520, "height": 390},
                    "visibleZoneIds": [
                        "zone_sarang_court",
                        "zone_sarang_complex",
                    ],
                },
                "b1": {
                    "viewport": {"x": 120, "y": 160, "width": 760, "height": 570},
                    "visibleZoneIds": [
                        "zone_front_haengrang_boundary",
                        "zone_sarang_court",
                        "zone_sarang_complex",
                        "zone_inner_threshold",
                        "zone_anchae_courtyard",
                        "zone_attached_kitchen_service",
                    ],
                },
                "b2": {
                    "viewport": {"x": 260, "y": 20, "width": 720, "height": 540},
                    "visibleZoneIds": [
                        "zone_anchae_courtyard",
                        "zone_attached_kitchen_service",
                        "zone_rear_shrine",
                    ],
                },
                "c1": {
                    "viewport": {"x": 80, "y": 20, "width": 840, "height": 630},
                    "visibleZoneIds": [
                        "zone_sarang_court",
                        "zone_sarang_complex",
                        "zone_inner_threshold",
                        "zone_anchae_courtyard",
                        "zone_attached_kitchen_service",
                        "zone_rear_shrine",
                    ],
                },
                "c2": {
                    "viewport": {"x": 0, "y": 0, "width": 1000, "height": 750},
                    "visibleZoneIds": [
                        "zone_outer_approach",
                        "zone_front_haengrang_boundary",
                        "zone_sarang_court",
                        "zone_sarang_complex",
                        "zone_inner_threshold",
                        "zone_anchae_courtyard",
                        "zone_attached_kitchen_service",
                        "zone_rear_shrine",
                        "zone_transmission_expansion",
                    ],
                },
            },
            {
                level: {
                    "viewport": row["viewport"],
                    "visibleZoneIds": row["visibleZoneIds"],
                }
                for level, row in cameras.items()
            },
        )

    def test_boundary_prologue_is_presentation_only_and_adds_no_grants(self) -> None:
        prologue = self.masterplan["boundaryPrologue"]
        self.assertEqual("presentationOnly", prologue["authority"])
        self.assertFalse(prologue["createsGrant"])
        self.assertEqual([], prologue["grantIds"])
        self.assertEqual(
            ["outer_wall_foundation", "outer_wall_complete", "sotdaeulmun_threshold"],
            [row["id"] for row in prologue["steps"]],
        )

    def test_remapping_preserves_all_86_grant_identities_and_order(self) -> None:
        grants = self.grants["grants"]
        mappings = self.remapping["grantMappings"]
        self.assertEqual(86, len(mappings))
        self.assertEqual(
            [row["id"] for row in grants],
            [row["grantId"] for row in mappings],
        )
        self.assertEqual(
            {"a1": 16, "a2": 16, "b1": 18, "b2": 20, "c1": 8, "c2": 8},
            dict(Counter(row["level"] for row in grants)),
        )
        self.assertEqual(86, len({row["rewardConceptId"] for row in mappings}))
        policies = {
            row["level"]: row["assetPolicy"]
            for row in self.remapping["levelPolicies"]
        }
        self.assertEqual(
            "rebuildFromApprovedGoldenMaster",
            policies["a1"],
        )
        self.assertEqual(
            {"futureSocketOnly"},
            {policy for level, policy in policies.items() if level != "a1"},
        )
        self.assertEqual(
            {
                "conceptIdsAreSemanticLabels": True,
                "literalModernPropTransfer": False,
                "readableTextInEstateOverview": False,
                "periodAppropriateMaterialTranslation": True,
            },
            self.remapping["representationPolicy"],
        )

    def test_required_gate_daecheong_and_rear_garden_remaps_are_exact(self) -> None:
        mappings = {
            row["grantId"]: row for row in self.remapping["grantMappings"]
        }
        expected = {
            "hanok_a2_lost_phone": (
                "sarangbang",
                "a2_sarangbang_hearth_warmth",
            ),
            "hanok_a2_ktx_ticket": (
                "sarangbang",
                "a2_sarangbang_lantern_light",
            ),
            "hanok_a2_rent_bank_transfer": (
                "sarangchae_life",
                "a2_sarangchae_chimney_smoke",
            ),
            "hanok_b2_public_wording_revision": (
                "gotgan",
                "b2_gotgan_platform",
            ),
            "hanok_b2_collaborative_feedback": (
                "gotgan",
                "b2_gotgan_frame",
            ),
            "hanok_b2_digital_source_judgment": (
                "gotgan",
                "b2_gotgan_complete",
            ),
            "hanok_c1_evidence_validity": (
                "estate_stewardship",
                "c1_roof_tile_inspection",
            ),
            "hanok_c1_evidence_limits_conclusion": (
                "estate_stewardship",
                "c1_drainage_channel_service",
            ),
            "hanok_c1_risk_uncertainty": (
                "estate_stewardship",
                "c1_courtyard_surface_repair",
            ),
        }
        for grant_id, (target, concept) in expected.items():
            with self.subTest(grant_id=grant_id):
                self.assertEqual(target, mappings[grant_id]["targetStructureId"])
                self.assertEqual(concept, mappings[grant_id]["rewardConceptId"])

        source_by_id = {row["id"]: row for row in self.grants["grants"]}
        self.assertTrue(
            all(
                "sotdaeulmun" in source_by_id[grant_id]["revealAssetIds"][0]
                for grant_id in (
                    "hanok_a2_lost_phone",
                    "hanok_a2_ktx_ticket",
                    "hanok_a2_rent_bank_transfer",
                )
            )
        )
        self.assertTrue(
            all(
                "daecheongmaru" in source_by_id[grant_id]["revealAssetIds"][0]
                for grant_id in (
                    "hanok_b2_public_wording_revision",
                    "hanok_b2_collaborative_feedback",
                    "hanok_b2_digital_source_judgment",
                )
            )
        )
        self.assertTrue(
            all(
                "rear_garden" in source_by_id[grant_id]["revealAssetIds"][0]
                for grant_id in (
                    "hanok_c1_evidence_validity",
                    "hanok_c1_evidence_limits_conclusion",
                    "hanok_c1_risk_uncertainty",
                )
            )
        )

    def test_c1_is_stewardship_and_c2_owns_late_transmission_concepts(self) -> None:
        source_by_id = {row["id"]: row for row in self.grants["grants"]}
        mappings = self.remapping["grantMappings"]
        c1 = [row for row in mappings if source_by_id[row["grantId"]]["level"] == "c1"]
        c2 = [row for row in mappings if source_by_id[row["grantId"]]["level"] == "c2"]
        self.assertEqual(
            {"estate_stewardship"},
            {row["targetStructureId"] for row in c1},
        )
        self.assertEqual(
            {"maintenance", "seasonalCare"},
            {row["targetRewardRole"] for row in c1},
        )
        self.assertTrue(
            {"seogo", "byeoldang"}.issubset(
                {row["targetStructureId"] for row in c2}
            )
        )

    def test_mutations_fail_closed(self) -> None:
        masterplan = copy.deepcopy(self.masterplan)
        masterplan["runtimeEnabled"] = True
        with self.assertRaisesRegex(ValueError, "cannot be runtime enabled"):
            builder._validate_masterplan(masterplan)

        missing = copy.deepcopy(self.remapping)
        missing["grantMappings"].pop()
        with self.assertRaisesRegex(ValueError, "exact 86"):
            builder._validate_remapping(
                self.grants,
                missing,
                builder._validate_masterplan(self.masterplan),
            )

        retired = copy.deepcopy(self.remapping)
        retired["grantMappings"][0]["targetStructureId"] = "rear_garden"
        with self.assertRaises(ValueError):
            builder._validate_remapping(
                self.grants,
                retired,
                builder._validate_masterplan(self.masterplan),
            )

        changed_required_remap = copy.deepcopy(self.remapping)
        changed_required_remap["grantMappings"][55][
            "targetStructureId"
        ] = "service_court"
        with self.assertRaisesRegex(ValueError, "required Phase 0 remap changed"):
            builder._validate_remapping(
                self.grants,
                changed_required_remap,
                builder._validate_masterplan(self.masterplan),
            )

        changed_grammar = copy.deepcopy(self.masterplan)
        changed_grammar["architecturalGrammar"]["frontBoundary"] = "detachedGate"
        with self.assertRaisesRegex(ValueError, "architectural grammar changed"):
            builder._validate_masterplan(changed_grammar)

        changed_canon = copy.deepcopy(self.masterplan)
        changed_canon["visualCanon"]["legacyPixelReuse"] = True
        with self.assertRaisesRegex(ValueError, "visual canon changed"):
            builder._validate_masterplan(changed_canon)

        changed_zone = copy.deepcopy(self.masterplan)
        changed_zone["zones"][8]["bounds"]["width"] += 1
        with self.assertRaisesRegex(ValueError, "zone bounds changed"):
            builder._validate_masterplan(changed_zone)

        changed_camera = copy.deepcopy(self.masterplan)
        changed_camera["cameraReveals"][0]["viewport"]["y"] += 1
        with self.assertRaisesRegex(ValueError, "camera layout changed"):
            builder._validate_masterplan(changed_camera)

        malformed_budget = copy.deepcopy(self.masterplan)
        malformed_budget["visualBudgetPercent"] = None
        with self.assertRaisesRegex(ValueError, "visual budget"):
            builder._validate_masterplan(malformed_budget)

        boolean_coordinate = copy.deepcopy(self.masterplan)
        boolean_coordinate["zones"][0]["bounds"]["x"] = False
        with self.assertRaisesRegex(ValueError, "integer coordinates"):
            builder._validate_masterplan(boolean_coordinate)

        malformed_zone_id = copy.deepcopy(self.masterplan)
        malformed_zone_id["zones"][0]["id"] = []
        with self.assertRaisesRegex(ValueError, "unique id values"):
            builder._validate_masterplan(malformed_zone_id)

        for image_reference in (
            "ASSETS\\illustrations\\hanok_compound\\sarangchae",
            "pending_review/reference.PNG",
            "pending_review/reference.jpeg",
        ):
            with self.subTest(image_reference=image_reference):
                with self.assertRaisesRegex(ValueError, "image assets"):
                    builder._validate_phase0_scope({"reference": image_reference})

        with self.assertRaisesRegex(ValueError, "Firebase configuration"):
            builder._validate_phase0_scope({"backend": "FireStore"})

        literal_props = copy.deepcopy(self.remapping)
        literal_props["representationPolicy"]["literalModernPropTransfer"] = True
        with self.assertRaisesRegex(ValueError, "representation policy changed"):
            builder._validate_remapping(
                self.grants,
                literal_props,
                builder._validate_masterplan(self.masterplan),
            )


if __name__ == "__main__":
    unittest.main()
