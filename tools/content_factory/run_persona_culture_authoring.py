#!/usr/bin/env python3
"""Run the persona-culture authoring/audit pipeline.

For a new batch this is a review-only authoring pipeline. After explicit
approval/promotion, the same command can audit the frozen merged source bundle
without mutating learner-facing assets.

Pipeline contract:
1. persona writer-bible identities/relationships
2. structured culture-scene authoring brief
3. scenario + listening draft
4. key-vocabulary extraction and CEFR audit
5. CulturalGlossary / scenario-culture-link integrity
6. review-only culture-story arc integrity
7. full scenario integration preview
8. human-readable review packet

This command never promotes content and never mutates live learner assets.
With --write-derived it only regenerates derived evidence declared in the
manifest (vocab-leveling sidecar, review packet, pipeline report). It never
writes live learner assets.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = Path(__file__).resolve().parent
TOOL_DIR = ROOT / "tool"
for path in (SCRIPT_DIR, TOOL_DIR):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

import extract_scenario_key_vocab  # noqa: E402
import integrate_scenario_batch  # noqa: E402
from render_review_packet import render_packet  # noqa: E402
from validate_listening_lessons import validate_records  # noqa: E402


class PersonaCulturePipelineError(ValueError):
    """Raised when a review-only persona-culture batch violates its contract."""


def _under_root(raw: str, label: str) -> Path:
    if not isinstance(raw, str) or not raw.strip():
        raise PersonaCulturePipelineError(f"{label} must be a repository-relative path")
    path = (ROOT / raw).resolve()
    try:
        path.relative_to(ROOT.resolve())
    except ValueError as error:
        raise PersonaCulturePipelineError(f"{label} escapes repository: {raw}") from error
    return path


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PersonaCulturePipelineError(f"cannot read {label} {path}: {error}") from error
    if not isinstance(value, dict):
        raise PersonaCulturePipelineError(f"{label} root must be an object")
    return value


def _repo_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def _nonempty_text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise PersonaCulturePipelineError(f"{label} must be nonempty text")
    return value.strip()


def _scenario_artifact(manifest: dict[str, Any]) -> dict[str, Any]:
    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list):
        raise PersonaCulturePipelineError("manifest artifacts must be an array")
    scenarios = [
        item
        for item in artifacts
        if isinstance(item, dict) and item.get("kind") == "scenario"
    ]
    if len(scenarios) != 1:
        raise PersonaCulturePipelineError("persona-culture batch needs exactly one scenario artifact")
    return scenarios[0]


def _profile_map() -> dict[str, dict[str, Any]]:
    payload = _read_json(
        ROOT / "tools/content_factory/canonical_scenarios/character_profiles.json",
        "character profiles",
    )
    recurring = payload.get("recurringCharacters")
    if not isinstance(recurring, list) or any(not isinstance(item, dict) for item in recurring):
        raise PersonaCulturePipelineError("character profiles recurringCharacters must be objects")
    result: dict[str, dict[str, Any]] = {}
    for item in recurring:
        ident = _nonempty_text(item.get("id"), "character id")
        if ident in result:
            raise PersonaCulturePipelineError(f"duplicate recurring character id: {ident}")
        result[ident] = item
    return result


def _glossary_ids() -> set[str]:
    payload = _read_json(ROOT / "docs/data/cultural_glossary.json", "cultural glossary")
    entries = payload.get("entries")
    if not isinstance(entries, list):
        raise PersonaCulturePipelineError("cultural glossary entries must be an array")
    return {
        str(item.get("termId") or "").strip()
        for item in entries
        if isinstance(item, dict) and str(item.get("termId") or "").strip()
    }



def _validate_story_arcs(
    *,
    manifest: dict[str, Any],
    scenarios: list[dict[str, Any]],
    culture_links: list[dict[str, Any]],
) -> dict[str, Any]:
    arcs_path = _under_root(
        _nonempty_text(
            manifest.get("cultureStoryArcsDraft"),
            "manifest cultureStoryArcsDraft",
        ),
        "cultureStoryArcsDraft",
    )
    payload = _read_json(arcs_path, "culture story arcs")
    if payload.get("schemaVersion") != 1 or payload.get("status") != "review_only":
        raise PersonaCulturePipelineError(
            "culture story arcs must use schemaVersion 1 and status review_only"
        )

    arcs = payload.get("arcs")
    if (
        not isinstance(arcs, list)
        or not arcs
        or any(not isinstance(item, dict) for item in arcs)
    ):
        raise PersonaCulturePipelineError(
            "culture story arcs must contain a nonempty arcs array"
        )

    scenario_by_id = {
        _nonempty_text(scene.get("id"), "scenario id"): scene
        for scene in scenarios
    }
    links_by_id = {
        _nonempty_text(link.get("scenarioId"), "culture-link scenarioId"): link
        for link in culture_links
    }
    required_languages = {"de", "en", "ko"}
    forbidden_state_fields = {
        "reward",
        "rewards",
        "rewardSlug",
        "xp",
        "mastery",
        "masteryId",
        "progressLedger",
        "unlockLedger",
    }

    arc_ids: list[str] = []
    step_count = 0
    for arc in arcs:
        arc_id = _nonempty_text(arc.get("arcId"), "culture story arcId")
        if arc_id in arc_ids:
            raise PersonaCulturePipelineError(
                f"duplicate culture story arcId: {arc_id}"
            )
        arc_ids.append(arc_id)

        forbidden = sorted(forbidden_state_fields.intersection(arc))
        if forbidden:
            raise PersonaCulturePipelineError(
                f"{arc_id}: story arc may not own reward/mastery state {forbidden}"
            )
        if arc.get("progressMode") != "derived_read_only":
            raise PersonaCulturePipelineError(
                f"{arc_id}: progressMode must be derived_read_only"
            )

        for copy_field in ("title", "summary"):
            copy = arc.get(copy_field)
            if not isinstance(copy, dict) or set(copy) != required_languages:
                raise PersonaCulturePipelineError(
                    f"{arc_id}: {copy_field} must contain exactly de, en, and ko"
                )
            for language in required_languages:
                _nonempty_text(
                    copy.get(language),
                    f"{arc_id}.{copy_field}.{language}",
                )

        steps = arc.get("steps")
        if (
            not isinstance(steps, list)
            or not steps
            or any(not isinstance(item, dict) for item in steps)
        ):
            raise PersonaCulturePipelineError(
                f"{arc_id}: steps must be a nonempty array of objects"
            )

        seen_scenarios: set[str] = set()
        for step in steps:
            forbidden = sorted(forbidden_state_fields.intersection(step))
            if forbidden:
                raise PersonaCulturePipelineError(
                    f"{arc_id}: story step may not own reward/mastery state {forbidden}"
                )

            scenario_id = _nonempty_text(
                step.get("scenarioId"),
                f"{arc_id}.scenarioId",
            )
            if scenario_id in seen_scenarios:
                raise PersonaCulturePipelineError(
                    f"{arc_id}: duplicate scenario step {scenario_id}"
                )
            seen_scenarios.add(scenario_id)
            scene = scenario_by_id.get(scenario_id)
            if scene is None:
                raise PersonaCulturePipelineError(
                    f"{arc_id}: unknown review-only scenario {scenario_id}"
                )
            link = links_by_id.get(scenario_id)
            if link is None:
                raise PersonaCulturePipelineError(
                    f"{arc_id}: scenario has no culture-link draft {scenario_id}"
                )

            persona_ids = step.get("personaIds")
            if (
                not isinstance(persona_ids, list)
                or not persona_ids
                or any(
                    not isinstance(item, str) or not item.strip()
                    for item in persona_ids
                )
                or len(set(persona_ids)) != len(persona_ids)
            ):
                raise PersonaCulturePipelineError(
                    f"{arc_id}/{scenario_id}: personaIds must be unique and nonempty"
                )
            participant_ids = scene.get("participantIds")
            if not isinstance(participant_ids, list):
                raise PersonaCulturePipelineError(
                    f"{arc_id}/{scenario_id}: scenario participants are malformed"
                )
            unknown_personas = sorted(set(persona_ids) - set(participant_ids))
            if unknown_personas:
                raise PersonaCulturePipelineError(
                    f"{arc_id}/{scenario_id}: personas are not scenario participants "
                    f"{unknown_personas}"
                )

            term_ids = step.get("termIds")
            if (
                not isinstance(term_ids, list)
                or not term_ids
                or any(
                    not isinstance(item, str) or not item.strip()
                    for item in term_ids
                )
                or len(set(term_ids)) != len(term_ids)
            ):
                raise PersonaCulturePipelineError(
                    f"{arc_id}/{scenario_id}: termIds must be unique and nonempty"
                )
            linked_terms = link.get("termIds")
            if not isinstance(linked_terms, list):
                raise PersonaCulturePipelineError(
                    f"{arc_id}/{scenario_id}: culture-link terms are malformed"
                )
            unknown_terms = sorted(set(term_ids) - set(linked_terms))
            if unknown_terms:
                raise PersonaCulturePipelineError(
                    f"{arc_id}/{scenario_id}: arc terms are not linked to the scenario "
                    f"{unknown_terms}"
                )

            step_count += 1

    return {
        "path": _repo_path(arcs_path),
        "arcCount": len(arcs),
        "stepCount": step_count,
        "arcIds": arc_ids,
        "liveWritePerformed": False,
    }


def _validate_authoring_brief(
    *,
    manifest: dict[str, Any],
    scenarios: list[dict[str, Any]],
    culture_links: list[dict[str, Any]],
) -> dict[str, Any]:
    brief_path = _under_root(
        _nonempty_text(manifest.get("authoringBrief"), "manifest authoringBrief"),
        "authoringBrief",
    )
    brief = _read_json(brief_path, "authoring brief")
    if brief.get("schemaVersion") != 1 or brief.get("status") != "review_only":
        raise PersonaCulturePipelineError(
            "authoring brief must use schemaVersion 1 and status review_only"
        )
    rows = brief.get("scenes")
    if not isinstance(rows, list) or any(not isinstance(item, dict) for item in rows):
        raise PersonaCulturePipelineError("authoring brief scenes must be an array of objects")

    scenario_ids = [str(scene.get("id") or "") for scene in scenarios]
    brief_ids = [str(row.get("scenarioId") or "") for row in rows]
    if brief_ids != scenario_ids:
        raise PersonaCulturePipelineError(
            "authoring brief scene IDs/order must exactly match scenario draft"
        )
    link_by_id = {
        str(item.get("scenarioId") or ""): item
        for item in culture_links
        if isinstance(item, dict)
    }
    if set(link_by_id) != set(scenario_ids):
        raise PersonaCulturePipelineError(
            "culture-link draft must cover every authoring-brief scene exactly"
        )

    profiles = _profile_map()
    glossary_ids = _glossary_ids()
    scene_by_id = {str(scene["id"]): scene for scene in scenarios}

    relation_checks: list[dict[str, Any]] = []
    for row in rows:
        scenario_id = _nonempty_text(row.get("scenarioId"), "brief scenarioId")
        scene = scene_by_id[scenario_id]
        level = _nonempty_text(row.get("level"), f"{scenario_id}.level").lower()
        if level != str(scene.get("level") or "").lower():
            raise PersonaCulturePipelineError(f"{scenario_id}: brief level disagrees with scenario")

        player = _nonempty_text(
            row.get("playerCharacterId"),
            f"{scenario_id}.playerCharacterId",
        )
        if player != scene.get("playerCharacterId"):
            raise PersonaCulturePipelineError(
                f"{scenario_id}: brief playerCharacterId disagrees with scenario"
            )

        persona_ids = row.get("personaIds")
        if (
            not isinstance(persona_ids, list)
            or len(persona_ids) < 2
            or any(not isinstance(item, str) or not item.strip() for item in persona_ids)
            or len(set(persona_ids)) != len(persona_ids)
        ):
            raise PersonaCulturePipelineError(
                f"{scenario_id}: personaIds must contain unique recurring character IDs"
            )
        persona_ids = [item.strip() for item in persona_ids]
        unknown_personas = sorted(set(persona_ids) - profiles.keys())
        if unknown_personas:
            raise PersonaCulturePipelineError(
                f"{scenario_id}: unknown recurring personas {unknown_personas}"
            )
        participants = scene.get("participantIds")
        if participants != persona_ids:
            raise PersonaCulturePipelineError(
                f"{scenario_id}: brief personaIds must exactly match participantIds/order"
            )
        if player not in persona_ids:
            raise PersonaCulturePipelineError(
                f"{scenario_id}: player must be one of personaIds"
            )

        culture_ids = row.get("cultureTermIds")
        if (
            not isinstance(culture_ids, list)
            or not culture_ids
            or any(not isinstance(item, str) or not item.strip() for item in culture_ids)
            or len(set(culture_ids)) != len(culture_ids)
        ):
            raise PersonaCulturePipelineError(
                f"{scenario_id}: cultureTermIds must be unique and nonempty"
            )
        culture_ids = [item.strip() for item in culture_ids]
        unknown_terms = sorted(set(culture_ids) - glossary_ids)
        if unknown_terms:
            raise PersonaCulturePipelineError(
                f"{scenario_id}: authoring brief uses unknown culture terms {unknown_terms}"
            )
        linked_terms = link_by_id[scenario_id].get("termIds")
        if linked_terms != culture_ids:
            raise PersonaCulturePipelineError(
                f"{scenario_id}: authoring brief culture terms disagree with culture-link draft"
            )

        _nonempty_text(row.get("realTaskKo"), f"{scenario_id}.realTaskKo")
        _nonempty_text(row.get("learningIntentKo"), f"{scenario_id}.learningIntentKo")
        boundaries = row.get("personaBoundaries")
        if (
            not isinstance(boundaries, list)
            or not boundaries
            or any(not isinstance(item, str) or not item.strip() for item in boundaries)
        ):
            raise PersonaCulturePipelineError(
                f"{scenario_id}: personaBoundaries must contain reviewable text"
            )

        # Every pair in a multi-person authored scene must already have at least
        # one declared relationship direction in the writer bible. This prevents
        # a draft from silently inventing a new social connection.
        for index, left in enumerate(persona_ids):
            for right in persona_ids[index + 1 :]:
                left_rel = profiles[left].get("relationships")
                right_rel = profiles[right].get("relationships")
                if not isinstance(left_rel, dict) or not isinstance(right_rel, dict):
                    raise PersonaCulturePipelineError(
                        f"{scenario_id}: malformed relationships for {left}/{right}"
                    )
                if right not in left_rel and left not in right_rel:
                    raise PersonaCulturePipelineError(
                        f"{scenario_id}: undeclared persona relationship {left}<->{right}"
                    )
                relation_checks.append(
                    {
                        "scenarioId": scenario_id,
                        "left": left,
                        "right": right,
                        "declaredBy": (
                            left if right in left_rel else right
                        ),
                    }
                )

    return {
        "path": _repo_path(brief_path),
        "sceneCount": len(rows),
        "relationChecks": relation_checks,
    }


def _validate_listening(
    manifest: dict[str, Any],
    scenarios: list[dict[str, Any]],
) -> dict[str, Any]:
    listening_path = _under_root(
        _nonempty_text(manifest.get("listeningDraft"), "manifest listeningDraft"),
        "listeningDraft",
    )
    listening = _read_json(listening_path, "listening draft")
    sources = {str(scene["id"]): scene for scene in scenarios}
    try:
        result = validate_records(listening, sources)
    except (AssertionError, KeyError, TypeError) as error:
        detail = error.args[0] if getattr(error, "args", ()) else "structural assertion failed"
        raise PersonaCulturePipelineError(
            f"listening draft is not grounded in scenario dialogue: {detail}"
        ) from error
    return {"path": _repo_path(listening_path), **result}


def _vocab_sidecar(
    *,
    manifest: dict[str, Any],
    scenarios_path: Path,
    culture_links_path: Path,
    write_derived: bool,
) -> tuple[dict[str, Any], str]:
    output_path = _under_root(
        _nonempty_text(
            manifest.get("vocabLevelingReview"),
            "manifest vocabLevelingReview",
        ),
        "vocabLevelingReview",
    )
    result = extract_scenario_key_vocab.build(
        scenarios_path=scenarios_path,
        culture_links_path=culture_links_path,
        glossary_path=ROOT / "docs/data/cultural_glossary.json",
        live_vocab_path=ROOT / "assets/data/korean_vocab.csv",
    )
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if write_derived:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered, encoding="utf-8")
    else:
        try:
            current = output_path.read_text(encoding="utf-8")
        except OSError as error:
            raise PersonaCulturePipelineError(
                f"missing vocab leveling sidecar: {output_path}"
            ) from error
        if current != rendered:
            raise PersonaCulturePipelineError(
                "vocab leveling sidecar is stale; rerun with --write-derived"
            )
    return result, _repo_path(output_path)


def _review_packet(
    *,
    manifest_path: Path,
    manifest: dict[str, Any],
    write_derived: bool,
) -> str:
    output_path = _under_root(
        _nonempty_text(manifest.get("reviewPacket"), "manifest reviewPacket"),
        "reviewPacket",
    )
    packet = render_packet(manifest_path=manifest_path, root=ROOT)
    arcs_path = _under_root(
        _nonempty_text(
            manifest.get("cultureStoryArcsDraft"),
            "manifest cultureStoryArcsDraft",
        ),
        "cultureStoryArcsDraft",
    )
    arcs_payload = _read_json(arcs_path, "culture story arcs")
    arc_lines = [
        "",
        "## Culture Story Arcs (review-only)",
        "",
        "> Grouping metadata only. These arcs create no mastery, reward, XP, or live progress.",
        "",
    ]
    for arc in arcs_payload.get("arcs", []):
        title = arc["title"]
        arc_lines.extend(
            [
                f"### `{arc['arcId']}`",
                "",
                f"- KO: {title['ko']}",
                f"- DE: {title['de']}",
                f"- EN: {title['en']}",
                f"- progressMode: `{arc['progressMode']}`",
                "",
                "| Step | Scenario | Personas | Culture terms |",
                "|---:|---|---|---|",
            ]
        )
        for index, step in enumerate(arc["steps"], start=1):
            personas = ", ".join(f"`{item}`" for item in step["personaIds"])
            terms = ", ".join(f"`{item}`" for item in step["termIds"])
            arc_lines.append(
                f"| {index} | `{step['scenarioId']}` | {personas} | {terms} |"
            )
        arc_lines.extend(["", "**Summary**", ""])
        for language in ("ko", "de", "en"):
            arc_lines.append(f"- {language.upper()}: {arc['summary'][language]}")
        arc_lines.append("")
    packet = packet + "\n" + "\n".join(arc_lines)
    if not packet.endswith("\n"):
        packet += "\n"

    if write_derived:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(packet, encoding="utf-8")
    else:
        try:
            current = output_path.read_text(encoding="utf-8")
        except OSError as error:
            raise PersonaCulturePipelineError(
                f"missing review packet: {output_path}"
            ) from error
        if current != packet:
            raise PersonaCulturePipelineError(
                "review packet is stale; rerun with --write-derived"
            )
    return _repo_path(output_path)


def run_pipeline(
    *,
    manifest_path: Path,
    write_derived: bool,
) -> dict[str, Any]:
    if not manifest_path.is_absolute():
        manifest_path = (ROOT / manifest_path).resolve()
    manifest = _read_json(manifest_path, "manifest")
    manifest_status = manifest.get("status")
    if manifest_status not in {"review_only_draft", "approved", "merged"}:
        raise PersonaCulturePipelineError(
            "authoring/audit pipeline only accepts review_only_draft, approved, or merged manifests"
        )
    provenance = manifest.get("provenance")
    if (
        not isinstance(provenance, dict)
        or provenance.get("requiresJinReview") is not True
        or provenance.get("humanLanguageQaClaim") is not False
    ):
        raise PersonaCulturePipelineError(
            "manifest must require Jin review and must not claim human language QA"
        )

    artifact = _scenario_artifact(manifest)
    scenarios_path = _under_root(
        _nonempty_text(artifact.get("draft"), "scenario draft"),
        "scenario draft",
    )
    scenario_root = _read_json(scenarios_path, "scenario draft")
    scenarios = scenario_root.get("scenarios")
    if not isinstance(scenarios, list) or any(not isinstance(item, dict) for item in scenarios):
        raise PersonaCulturePipelineError("scenario draft scenarios must be objects")

    culture_links_path = _under_root(
        _nonempty_text(manifest.get("cultureLinksDraft"), "cultureLinksDraft"),
        "cultureLinksDraft",
    )
    culture_root = _read_json(culture_links_path, "culture-link draft")
    culture_links = culture_root.get("links")
    if not isinstance(culture_links, list) or any(
        not isinstance(item, dict) for item in culture_links
    ):
        raise PersonaCulturePipelineError("culture-link draft links must be objects")

    brief_result = _validate_authoring_brief(
        manifest=manifest,
        scenarios=scenarios,
        culture_links=culture_links,
    )
    story_arcs_result = _validate_story_arcs(
        manifest=manifest,
        scenarios=scenarios,
        culture_links=culture_links,
    )
    listening_result = _validate_listening(manifest, scenarios)
    vocab_result, vocab_path = _vocab_sidecar(
        manifest=manifest,
        scenarios_path=scenarios_path,
        culture_links_path=culture_links_path,
        write_derived=write_derived,
    )
    packet_path = _review_packet(
        manifest_path=manifest_path,
        manifest=manifest,
        write_derived=write_derived,
    )

    try:
        inventory, amount = integrate_scenario_batch.integrate(
            root=ROOT,
            manifest_path=manifest_path.relative_to(ROOT),
            apply=False,
        )
    except integrate_scenario_batch.ScenarioIntegrationError as error:
        raise PersonaCulturePipelineError(
            f"scenario integration preview failed: {error}"
        ) from error

    report_status = {
        "review_only_draft": "REVIEW_ONLY_PIPELINE_PASS",
        "approved": "APPROVED_PIPELINE_PASS",
        "merged": "MERGED_AUDIT_PASS",
    }[manifest_status]
    report = {
        "schemaVersion": 1,
        "status": report_status,
        "manifest": _repo_path(manifest_path),
        "batch": manifest.get("batch"),
        "scenarioCount": amount,
        "scenarioIds": [str(scene["id"]) for scene in scenarios],
        "authoringBrief": brief_result,
        "cultureStoryArcs": story_arcs_result,
        "listening": listening_result,
        "vocabLeveling": {
            "path": vocab_path,
            "totals": vocab_result["totals"],
        },
        "cultureLinkCount": len(culture_links),
        "reviewPacket": packet_path,
        "integrationPreviewInventory": inventory,
        "liveWritePerformed": False,
        "humanApprovalClaimed": manifest_status in {"approved", "merged"},
    }

    report_raw = manifest.get("pipelineReport")
    if report_raw:
        report_path = _under_root(
            _nonempty_text(report_raw, "manifest pipelineReport"),
            "pipelineReport",
        )
        rendered = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
        if write_derived:
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text(rendered, encoding="utf-8")
        else:
            try:
                current = report_path.read_text(encoding="utf-8")
            except OSError as error:
                raise PersonaCulturePipelineError(
                    f"missing pipeline report: {report_path}"
                ) from error
            if current != rendered:
                raise PersonaCulturePipelineError(
                    "pipeline report is stale; rerun with --write-derived"
                )

    return report


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument(
        "--write-derived",
        action="store_true",
        help="regenerate derived sidecars/packets/reports; never write live assets",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    try:
        report = run_pipeline(
            manifest_path=Path(args.manifest),
            write_derived=args.write_derived,
        )
    except (PersonaCulturePipelineError, OSError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}")
        return 1
    print(
        "OK:",
        report["status"],
        f"batch={report['batch']}",
        f"scenarios={report['scenarioCount']}",
        f"cultureLinks={report['cultureLinkCount']}",
        f"vocab={report['vocabLeveling']['totals']}",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
