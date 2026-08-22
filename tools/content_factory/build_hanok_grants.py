#!/usr/bin/env python3
"""Validate the authored, provisional Living Hanok V1 grant plan.

Can-do release tracks own learner denominators. Reward identity and visual
meaning are authored explicitly in a review-only draft: this tool never infers
new rewards from a level, CourseUnit count, vocabulary, XP, Gye, or legacy
Hanok progress. Published rows, once any exist, are protected by a separate
append-only release ledger.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SEGMENTS_PATH = ROOT / "assets" / "data" / "can_do_segments.json"
OUTPUT_PATH = ROOT / "tools" / "content_factory" / "drafts" / "hanok_grants.json"
MASTERPLAN_PATH = (
    ROOT
    / "tools"
    / "content_factory"
    / "drafts"
    / "estate_masterplan_v2.json"
)
REMAPPING_PATH = (
    ROOT
    / "tools"
    / "content_factory"
    / "drafts"
    / "hanok_grant_remapping_v2.json"
)
LEDGER_PATH = (
    ROOT
    / "tools"
    / "content_factory"
    / "release_ledgers"
    / "hanok_grants_v1.json"
)

LEVEL_ORDER = {"a1": 0, "a2": 1, "b1": 2, "b2": 3, "c1": 4, "c2": 5}
RETIRED_V2_STRUCTURES = {"daecheongmaru", "rear_garden"}
EXPECTED_ARCHITECTURAL_GRAMMAR = {
    "id": "unjoru_validated_original_jongga",
    "reconstructionMode": "grammarOnly",
    "frontBoundary": "integratedHaengrangAndSotdaeulmun",
    "sarangComplex": "asymmetricalWithModestNumaru",
    "anchae": "fourWingCourtyard",
    "serviceCourt": "attachedToAnchae",
    "shrine": "separateRearEnclosure",
    "elevationBands": ["frontLow", "sarangMiddle", "anchaeShrineHigh"],
}
EXPECTED_VISUAL_CANON = {
    "id": "hangul_sori_compound_faceted_minhwa",
    "architectureAuthority": "unjoruSpatialGrammar",
    "visualDnaAuthority": "legacyCompoundAndCrossChannelGate",
    "geometryAuthority": "approvedSingleGoldenMaster",
    "legacyPixelReuse": False,
    "runtimeAssetPromotion": "deferred",
}
EXPECTED_REPRESENTATION_POLICY = {
    "conceptIdsAreSemanticLabels": True,
    "literalModernPropTransfer": False,
    "readableTextInEstateOverview": False,
    "periodAppropriateMaterialTranslation": True,
}
EXPECTED_ZONE_BOUNDS = {
    "zone_outer_approach": {"x": 0, "y": 660, "width": 1000, "height": 90},
    "zone_front_haengrang_boundary": {
        "x": 50,
        "y": 590,
        "width": 900,
        "height": 70,
    },
    "zone_sarang_court": {"x": 260, "y": 360, "width": 480, "height": 230},
    "zone_sarang_complex": {"x": 310, "y": 275, "width": 370, "height": 100},
    "zone_inner_threshold": {"x": 440, "y": 230, "width": 120, "height": 55},
    "zone_anchae_courtyard": {"x": 300, "y": 55, "width": 400, "height": 200},
    "zone_attached_kitchen_service": {
        "x": 680,
        "y": 245,
        "width": 240,
        "height": 260,
    },
    "zone_rear_shrine": {"x": 750, "y": 45, "width": 170, "height": 170},
    "zone_transmission_expansion": {
        "x": 80,
        "y": 55,
        "width": 190,
        "height": 200,
    },
}
EXPECTED_SOCKET_LAYOUT = {
    "a1": {"zoneId": "zone_sarang_court", "position": {"x": 500, "y": 470}},
    "a2": {"zoneId": "zone_sarang_complex", "position": {"x": 490, "y": 325}},
    "b1": {"zoneId": "zone_inner_threshold", "position": {"x": 500, "y": 255}},
    "b2": {
        "zoneId": "zone_attached_kitchen_service",
        "position": {"x": 790, "y": 275},
    },
    "c1": {"zoneId": "zone_anchae_courtyard", "position": {"x": 500, "y": 155}},
    "c2": {
        "zoneId": "zone_transmission_expansion",
        "position": {"x": 175, "y": 170},
    },
}
EXPECTED_CAMERA_LAYOUT = {
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
        "visibleZoneIds": ["zone_sarang_court", "zone_sarang_complex"],
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
}
PHASE0_REWARD_ROLES = {
    "ambience",
    "construction",
    "credential",
    "designOption",
    "furnishing",
    "interpretation",
    "maintenance",
    "seasonalCare",
    "venue",
}

A1_REWARDS = (
    "site_setout",
    "plan_layout",
    "foundation_gidan",
    "cornerstones_choseok",
    "timber_preparation",
    "columns",
    "beams_changbang",
    "purlins_sangnyang",
    "rafters_roof_frame",
    "roof_base",
    "giwa_roof",
    "wall_frame_sujang",
    "earth_walls",
    "ondol_maru",
    "changho_finish",
    "landscape_move_in",
)


def _json(path: Path) -> dict:
    decoded = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(decoded, dict):
        raise ValueError(f"{path} must contain one JSON object")
    return decoded


def _denominator_segment_ids(source: dict) -> set[str]:
    editions = {row["id"]: row for row in source["trackEditions"]}
    result: set[str] = set()
    for track in source["releaseTracks"]:
        if track["status"] == "draft" or track["kind"] == "replacement":
            continue
        for edition_id in track["editionIds"]:
            edition = editions[edition_id]
            if edition["status"] == "draft":
                continue
            result.update(edition["segmentIds"])
    return result


def _validate_published_ledger(candidate: dict, ledger: dict) -> None:
    if ledger.get("schemaVersion") != 1:
        raise ValueError("unsupported Hanok grant release ledger")
    published = ledger.get("publishedGrants")
    if not isinstance(published, list):
        raise ValueError("publishedGrants must be a list")
    candidate_by_id = {row["id"]: row for row in candidate["grants"]}
    if len(candidate_by_id) != len(candidate["grants"]):
        raise ValueError("candidate Hanok grant IDs must be unique")
    published_ids: set[str] = set()
    for row in published:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str):
            raise ValueError("published Hanok grant ledger row is invalid")
        grant_id = row["id"]
        if grant_id in published_ids:
            raise ValueError("published Hanok grant ledger has duplicate IDs")
        published_ids.add(grant_id)
        if candidate_by_id.get(grant_id) != row:
            raise ValueError(f"published Hanok grant changed or disappeared: {grant_id}")


def _validate_ledger_evolution(current: dict, previous: dict) -> None:
    if current.get("schemaVersion") != previous.get("schemaVersion"):
        raise ValueError("Hanok grant release ledger schema changed")
    current_rows = current.get("publishedGrants")
    previous_rows = previous.get("publishedGrants")
    if not isinstance(current_rows, list) or not isinstance(previous_rows, list):
        raise ValueError("publishedGrants must be a list")
    if current_rows[: len(previous_rows)] != previous_rows:
        raise ValueError("published Hanok grant ledger is not append-only")


def _ledger_at_revision(revision: str) -> dict | None:
    relative = LEDGER_PATH.relative_to(ROOT).as_posix()
    completed = subprocess.run(
        ["git", "show", f"{revision}:{relative}"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if completed.returncode != 0:
        missing_markers = ("does not exist", "exists on disk, but not in", "Path '")
        if any(marker in completed.stderr for marker in missing_markers):
            return None
        raise ValueError(
            f"cannot read Hanok grant ledger at {revision}: {completed.stderr.strip()}"
        )
    decoded = json.loads(completed.stdout)
    if not isinstance(decoded, dict):
        raise ValueError("historical Hanok grant ledger must be one JSON object")
    return decoded


def _default_base_revision() -> str:
    explicit = os.environ.get("CI_PR_BASE_SHA", "").strip()
    if explicit:
        return explicit
    before = os.environ.get("CI_BEFORE_SHA", "").strip()
    if before and set(before) != {"0"}:
        return before
    completed = subprocess.run(
        ["git", "merge-base", "HEAD", "origin/main"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return completed.stdout.strip()


def _validate_ledger_history(current: dict, base_revision: str) -> None:
    previous = _ledger_at_revision(base_revision)
    if previous is not None:
        _validate_ledger_evolution(current, previous)


def _validate_candidate(source: dict, candidate: dict, ledger: dict) -> dict:
    if candidate.get("schemaVersion") != 1:
        raise ValueError("unsupported provisional Hanok grant schema")
    grants = candidate.get("grants")
    if not isinstance(grants, list):
        raise ValueError("provisional Hanok grants must be a list")

    denominator_ids = _denominator_segment_ids(source)
    segment_by_id = {row["id"]: row for row in source["segments"]}
    grant_segment_ids = [row.get("canDoSegmentId") for row in grants]
    if len(grant_segment_ids) != len(set(grant_segment_ids)):
        raise ValueError("every denominator segment must own exactly one grant")
    if set(grant_segment_ids) != denominator_ids:
        missing = sorted(denominator_ids.difference(grant_segment_ids))
        extra = sorted(set(grant_segment_ids).difference(denominator_ids))
        raise ValueError(f"authored Hanok grant coverage mismatch: missing={missing}, extra={extra}")

    expected_order = sorted(
        grants,
        key=lambda row: (
            LEVEL_ORDER[segment_by_id[row["canDoSegmentId"]]["level"]],
            segment_by_id[row["canDoSegmentId"]]["order"],
            row["id"],
        ),
    )
    if grants != expected_order:
        raise ValueError("authored Hanok grants are not canonically ordered")
    for row in grants:
        segment = segment_by_id[row["canDoSegmentId"]]
        if row.get("level") != segment["level"] or row.get("order") != segment["order"]:
            raise ValueError(f"grant metadata differs from segment: {row.get('id')}")

    a1 = [row for row in grants if row["level"] == "a1"]
    expected_a1_ids = [
        f"hanok_a1_{index:02d}_{suffix}"
        for index, suffix in enumerate(A1_REWARDS, start=1)
    ]
    if [row["id"] for row in a1[: len(A1_REWARDS)]] != expected_a1_ids:
        raise ValueError("A1 must begin with the exact sixteen construction IDs")
    if any(row.get("kind") == "constructionPiece" for row in a1[len(A1_REWARDS) :]):
        raise ValueError("A1 extensions cannot extend the fixed construction sequence")

    _validate_published_ledger(candidate, ledger)
    return candidate


def _require_unique_rows(rows: object, key: str, label: str) -> dict[str, dict]:
    if not isinstance(rows, list) or not all(isinstance(row, dict) for row in rows):
        raise ValueError(f"{label} must be a list of objects")
    keys = [row.get(key) for row in rows]
    if (
        not all(isinstance(value, str) and value for value in keys)
        or len(set(keys)) != len(rows)
    ):
        raise ValueError(f"{label} must have unique {key} values")
    return {value: row for value, row in zip(keys, rows, strict=True)}


def _validate_rect(rect: object, width: int, height: int, label: str) -> None:
    if not isinstance(rect, dict):
        raise ValueError(f"{label} must be an object")
    if set(rect) != {"x", "y", "width", "height"}:
        raise ValueError(f"{label} has unsupported fields")
    values = [rect.get(name) for name in ("x", "y", "width", "height")]
    if not all(type(value) is int for value in values):
        raise ValueError(f"{label} must use integer coordinates")
    x, y, rect_width, rect_height = values
    if (
        x < 0
        or y < 0
        or rect_width <= 0
        or rect_height <= 0
        or x + rect_width > width
        or y + rect_height > height
    ):
        raise ValueError(f"{label} falls outside the master canvas")


def _all_strings(value: object) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        return [item for row in value for item in _all_strings(row)]
    if isinstance(value, dict):
        return [item for row in value.values() for item in _all_strings(row)]
    return []


def _validate_phase0_scope(payloads: object) -> None:
    for value in _all_strings(payloads):
        normalized = value.replace("\\", "/").lower()
        if normalized.startswith("assets/") or normalized.endswith(
            (".png", ".webp", ".jpg", ".jpeg", ".avif")
        ):
            raise ValueError("Phase 0 contracts cannot reference image assets")
        if "firebase" in normalized or "firestore" in normalized:
            raise ValueError("Phase 0 contracts cannot contain Firebase configuration")


def _validate_masterplan(masterplan: dict) -> dict[str, dict]:
    if masterplan.get("schemaVersion") != 2:
        raise ValueError("estate_masterplan_v2 must use schemaVersion 2")
    if masterplan.get("contractId") != "estate_masterplan_v2":
        raise ValueError("estate masterplan contractId is invalid")
    if masterplan.get("status") != "phase0Review":
        raise ValueError("estate masterplan must remain in Phase 0 review")
    if masterplan.get("runtimeEnabled") is not False:
        raise ValueError("Phase 0 estate masterplan cannot be runtime enabled")

    space = masterplan.get("coordinateSpace")
    if not isinstance(space, dict):
        raise ValueError("estate masterplan coordinateSpace is required")
    width = space.get("width")
    height = space.get("height")
    if (
        type(width) is not int
        or type(height) is not int
        or width <= 0
        or height <= 0
        or width * 3 != height * 4
        or space.get("aspectRatio") != "4:3"
    ):
        raise ValueError("estate masterplan must use a positive 4:3 coordinate space")

    budget = masterplan.get("visualBudgetPercent")
    expected_budget = {
        "architectureAndWalls": 35,
        "emptyCourtyards": 40,
        "pathsAndFutureSockets": 15,
        "plantingAndLifePropsMax": 10,
    }
    if budget != expected_budget:
        raise ValueError("estate masterplan visual budget must stay 35/40/15/10")
    if set(masterplan.get("retiredStructureIds", [])) != RETIRED_V2_STRUCTURES:
        raise ValueError("estate masterplan must retire rear garden and daecheongmaru")
    if masterplan.get("architecturalGrammar") != EXPECTED_ARCHITECTURAL_GRAMMAR:
        raise ValueError("estate masterplan architectural grammar changed")
    if masterplan.get("visualCanon") != EXPECTED_VISUAL_CANON:
        raise ValueError("estate masterplan visual canon changed")
    if masterplan.get("overviewSocketPolicy") != "oneRepresentativeSocketPerLevel":
        raise ValueError("Phase 0 must use one overview socket per level")
    if masterplan.get("focusedLevelDetailSocketPolicy") != "deferred":
        raise ValueError("focused-level detail sockets must remain deferred")

    zones = _require_unique_rows(masterplan.get("zones"), "id", "estate zones")
    if set(zones) != set(EXPECTED_ZONE_BOUNDS):
        raise ValueError("estate masterplan zones changed")
    if {zone_id: zone.get("bounds") for zone_id, zone in zones.items()} != (
        EXPECTED_ZONE_BOUNDS
    ):
        raise ValueError("estate masterplan zone bounds changed")
    for zone_id, zone in zones.items():
        _validate_rect(zone.get("bounds"), width, height, f"zone {zone_id}")

    sockets = _require_unique_rows(
        masterplan.get("levelSockets"),
        "id",
        "estate level sockets",
    )
    if len(sockets) != len(LEVEL_ORDER):
        raise ValueError("estate masterplan must have exactly six level sockets")
    socket_by_level = {row.get("level"): row for row in sockets.values()}
    if set(socket_by_level) != set(LEVEL_ORDER) or len(socket_by_level) != len(sockets):
        raise ValueError("estate masterplan must have one socket for every level")
    if {
        level: {"zoneId": row.get("zoneId"), "position": row.get("position")}
        for level, row in socket_by_level.items()
    } != EXPECTED_SOCKET_LAYOUT:
        raise ValueError("estate masterplan socket layout changed")
    for socket_id, socket in sockets.items():
        if socket.get("zoneId") not in zones:
            raise ValueError(f"unknown zone for socket {socket_id}")
        position = socket.get("position")
        if not isinstance(position, dict) or set(position) != {"x", "y"}:
            raise ValueError(f"socket {socket_id} position is invalid")
        x = position.get("x")
        y = position.get("y")
        if (
            type(x) is not int
            or type(y) is not int
            or not 0 <= x <= width
            or not 0 <= y <= height
        ):
            raise ValueError(f"socket {socket_id} falls outside the master canvas")
        if socket.get("minimumLogicalHitSize", 0) < 48:
            raise ValueError(f"socket {socket_id} must reserve a 48dp hit target")
        targets = socket.get("allowedTargetStructureIds")
        if (
            not isinstance(targets, list)
            or not targets
            or len(targets) != len(set(targets))
        ):
            raise ValueError(f"socket {socket_id} target structures are invalid")
        if RETIRED_V2_STRUCTURES.intersection(targets):
            raise ValueError(f"socket {socket_id} includes a retired structure")
        if any("gye" in target.lower() for target in targets):
            raise ValueError(f"socket {socket_id} crosses into Gye state")

    prologue = masterplan.get("boundaryPrologue")
    if (
        not isinstance(prologue, dict)
        or prologue.get("authority") != "presentationOnly"
        or prologue.get("createsGrant") is not False
        or prologue.get("grantIds") != []
    ):
        raise ValueError("boundary prologue must remain non-authoritative")
    prologue_steps = prologue.get("steps")
    if not isinstance(prologue_steps, list) or [
        row.get("order") for row in prologue_steps
    ] != [1, 2, 3]:
        raise ValueError("boundary prologue must have the fixed three-step order")

    cameras = _require_unique_rows(
        masterplan.get("cameraReveals"),
        "id",
        "estate camera reveals",
    )
    if len(cameras) != len(LEVEL_ORDER):
        raise ValueError("estate masterplan must have six camera reveals")
    camera_by_level = {row.get("level"): row for row in cameras.values()}
    if set(camera_by_level) != set(LEVEL_ORDER):
        raise ValueError("estate camera reveals must cover A1 through C2")
    expected_orders = list(range(1, len(LEVEL_ORDER) + 1))
    actual_orders = [camera_by_level[level].get("order") for level in LEVEL_ORDER]
    if actual_orders != expected_orders:
        raise ValueError("estate camera reveal order must follow A1 through C2")
    if {
        level: {
            "viewport": row.get("viewport"),
            "visibleZoneIds": row.get("visibleZoneIds"),
        }
        for level, row in camera_by_level.items()
    } != EXPECTED_CAMERA_LAYOUT:
        raise ValueError("estate masterplan camera layout changed")
    for level, camera in camera_by_level.items():
        socket = socket_by_level[level]
        if camera.get("focusSocketId") != socket["id"]:
            raise ValueError(
                f"camera {camera.get('id')} focuses the wrong level socket"
            )
        viewport = camera.get("viewport")
        _validate_rect(viewport, width, height, f"camera {camera.get('id')}")
        if viewport["width"] * 3 != viewport["height"] * 4:
            raise ValueError(f"camera {camera.get('id')} viewport must stay 4:3")
        position = socket["position"]
        if not (
            viewport["x"] <= position["x"] <= viewport["x"] + viewport["width"]
            and viewport["y"]
            <= position["y"]
            <= viewport["y"] + viewport["height"]
        ):
            raise ValueError(f"camera {camera.get('id')} does not contain its socket")
        visible_zones = camera.get("visibleZoneIds")
        if (
            not isinstance(visible_zones, list)
            or not visible_zones
            or not set(visible_zones).issubset(zones)
        ):
            raise ValueError(f"camera {camera.get('id')} has invalid visible zones")

    return socket_by_level


def _validate_remapping(
    candidate: dict,
    remapping: dict,
    socket_by_level: dict[str, dict],
) -> None:
    if remapping.get("schemaVersion") != 2:
        raise ValueError("Hanok remapping must use schemaVersion 2")
    if remapping.get("contractId") != "hanok_grant_remapping_v2":
        raise ValueError("Hanok remapping contractId is invalid")
    if remapping.get("status") != "phase0Review":
        raise ValueError("Hanok remapping must remain in Phase 0 review")
    if remapping.get("runtimeEnabled") is not False:
        raise ValueError("Phase 0 Hanok remapping cannot be runtime enabled")
    if remapping.get("sourceCatalog") != {
        "path": "tools/content_factory/drafts/hanok_grants.json",
        "schemaVersion": 1,
        "expectedGrantCount": 86,
    }:
        raise ValueError("Hanok remapping source catalog contract changed")
    if remapping.get("mappingPolicy") != {
        "version": "hanok_level_mapping_v2_phase0",
        "preserveGrantIds": True,
        "preserveCanDoAuthority": True,
        "preserveGrantOrder": True,
        "assetIdsAreAssignedLater": True,
    }:
        raise ValueError("Hanok remapping identity policy changed")
    if remapping.get("representationPolicy") != EXPECTED_REPRESENTATION_POLICY:
        raise ValueError("Hanok remapping representation policy changed")

    level_policies = _require_unique_rows(
        remapping.get("levelPolicies"),
        "level",
        "Hanok remapping level policies",
    )
    if set(level_policies) != set(LEVEL_ORDER):
        raise ValueError("Hanok remapping must define all six level policies")
    for level, policy in level_policies.items():
        if policy.get("socketId") != socket_by_level[level]["id"]:
            raise ValueError(f"Hanok remapping uses the wrong socket for {level}")
        expected_asset_policy = (
            "rebuildFromApprovedGoldenMaster" if level == "a1" else "futureSocketOnly"
        )
        if policy.get("assetPolicy") != expected_asset_policy:
            raise ValueError(f"Hanok remapping asset policy is invalid for {level}")

    mappings = remapping.get("grantMappings")
    mapping_by_id = _require_unique_rows(mappings, "grantId", "Hanok grant mappings")
    candidate_by_id = {row["id"]: row for row in candidate["grants"]}
    if len(mapping_by_id) != 86 or set(mapping_by_id) != set(candidate_by_id):
        raise ValueError("Hanok grant remapping must cover the exact 86 draft grants")
    if [row["grantId"] for row in mappings] != [
        row["id"] for row in candidate["grants"]
    ]:
        raise ValueError("Hanok grant remapping must preserve canonical grant order")
    expected_fields = {
        "grantId",
        "targetStructureId",
        "targetRewardRole",
        "rewardConceptId",
    }
    concepts: set[str] = set()
    for grant_id, mapping in mapping_by_id.items():
        if set(mapping) != expected_fields:
            raise ValueError(f"Hanok grant mapping has unsupported fields: {grant_id}")
        grant = candidate_by_id[grant_id]
        level = grant["level"]
        socket = socket_by_level[level]
        target = mapping.get("targetStructureId")
        role = mapping.get("targetRewardRole")
        concept = mapping.get("rewardConceptId")
        if target not in socket["allowedTargetStructureIds"]:
            raise ValueError(f"Hanok grant maps outside its level socket: {grant_id}")
        if target in RETIRED_V2_STRUCTURES or "gye" in target.lower():
            raise ValueError(f"Hanok grant maps to a forbidden structure: {grant_id}")
        if role not in PHASE0_REWARD_ROLES:
            raise ValueError(f"Hanok grant has an invalid target role: {grant_id}")
        if not isinstance(concept, str) or not concept.startswith(f"{level}_"):
            raise ValueError(f"Hanok grant concept is invalid: {grant_id}")
        if concept in concepts:
            raise ValueError(f"Hanok grant concepts must be unique: {concept}")
        concepts.add(concept)

    a1_mappings = [
        mapping_by_id[row["id"]]
        for row in candidate["grants"]
        if row["level"] == "a1"
    ]
    if any(
        row["targetStructureId"] != "sarangchae"
        or row["targetRewardRole"] != "construction"
        for row in a1_mappings
    ):
        raise ValueError("A1 must preserve the sixteen-step Sarangchae sequence")

    required_remaps = {
        "hanok_a2_lost_phone": ("sarangbang", "a2_sarangbang_hearth_warmth"),
        "hanok_a2_ktx_ticket": ("sarangbang", "a2_sarangbang_lantern_light"),
        "hanok_a2_rent_bank_transfer": (
            "sarangchae_life",
            "a2_sarangchae_chimney_smoke",
        ),
        "hanok_b2_public_wording_revision": ("gotgan", "b2_gotgan_platform"),
        "hanok_b2_collaborative_feedback": ("gotgan", "b2_gotgan_frame"),
        "hanok_b2_digital_source_judgment": ("gotgan", "b2_gotgan_complete"),
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
    for grant_id, (target, concept) in required_remaps.items():
        mapping = mapping_by_id[grant_id]
        if (
            mapping["targetStructureId"] != target
            or mapping["rewardConceptId"] != concept
        ):
            raise ValueError(f"required Phase 0 remap changed: {grant_id}")
    if any(
        mapping_by_id[row["id"]]["targetStructureId"] != "estate_stewardship"
        for row in candidate["grants"]
        if row["level"] == "c1"
    ):
        raise ValueError("C1 must map only to estate stewardship")


def _load_phase0_contract(candidate: dict) -> tuple[dict, dict]:
    masterplan = _json(MASTERPLAN_PATH)
    remapping = _json(REMAPPING_PATH)
    socket_by_level = _validate_masterplan(masterplan)
    _validate_remapping(candidate, remapping, socket_by_level)
    _validate_phase0_scope([masterplan, remapping])
    return masterplan, remapping


def _build_contracts() -> tuple[dict, dict, dict]:
    candidate = _validate_candidate(
        _json(SEGMENTS_PATH),
        _json(OUTPUT_PATH),
        _json(LEDGER_PATH),
    )
    masterplan, remapping = _load_phase0_contract(candidate)
    return candidate, masterplan, remapping


def build() -> dict:
    candidate, _, _ = _build_contracts()
    return candidate


def _encoded(payload: dict) -> str:
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--verify-git-history", action="store_true")
    parser.add_argument("--base-revision")
    args = parser.parse_args()
    candidate, masterplan, remapping = _build_contracts()
    normalized = {
        OUTPUT_PATH: candidate,
        MASTERPLAN_PATH: masterplan,
        REMAPPING_PATH: remapping,
    }
    if args.verify_git_history:
        _validate_ledger_history(
            _json(LEDGER_PATH),
            args.base_revision or _default_base_revision(),
        )
    if args.check:
        for path, payload in normalized.items():
            if path.read_text(encoding="utf-8") != _encoded(payload):
                raise SystemExit(f"{path.relative_to(ROOT)} is not normalized")
        return 0
    for path, payload in normalized.items():
        path.write_text(_encoded(payload), encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
