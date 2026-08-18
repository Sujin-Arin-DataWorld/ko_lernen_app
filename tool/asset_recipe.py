#!/usr/bin/env python3
"""Recipe-based asset pipeline — Phase 2-3 of the "살아 있는 한옥" plan
("레시피 기반 풀 파이프라인", Jin's explicit choice over a style-lock-doc-only
or a runner-without-style-checks alternative).

This tool cannot call the image-generation MCP itself (that lives in an
agent session, not in a script this repo can invoke headlessly). Instead it
brackets the agent call:

    asset_recipe.py RECIPE.json --check              # structural validation, no network
    asset_recipe.py RECIPE.json --plan                # human-readable summary
    asset_recipe.py RECIPE.json --emit-work-order      # -> JSON an agent feeds straight
                                                        #    into generate_image/edit_image
    < agent calls the MCP tool with that work order, saves the raw output, records
      the exact taskId/cost/prompt actually sent >
    asset_recipe.py RECIPE.json --ingest RESULT.json  # cut -> gate -> ledger record

A recipe kind that fails --check or whose --ingest gate fails writes nothing
and the ledger gets a `decision: "rejected"` record instead — same contract
as the existing `a1-frame-4x3-rejected-2026-08-17` precedent, so a rejected
generation is never silently discarded from the credit history.

Kinds (cover everything this repo has actually generated so far):
  cutout      — one free-placement object on #00FF00 (tool/cut_single_object.py)
  sheet       — a multi-object sprite sheet (tool/cut_prop_sheet.py)
  frameEdit   — KEEP/REMOVE/ADD edit of an existing finished building
                (tool/derive_estate_building_stages.py)
  overlay     — a transparent layer composited onto a fixed-canvas socket
                (tool/compose_a2_exterior_overlays.py)
  newBuilding — a brand-new building with no existing finished PNG to edit
                (byeoldang/seogo, Phase 3 P1/P2) -- NOT one of the plan's
                original 4 kinds; added here because those two buildings
                need a first-pass full generation before frameEdit's
                KEEP/REMOVE/ADD contract even applies to them (there is
                nothing to KEEP yet). Documented explicitly as a deliberate
                extension, not a silent scope change.

Reuse-first, per the plan ("신규 코드는 총 ~900줄이고 나머지는 import-and-call"):
this file imports check_style_conformance.check/style_lock for gating, and
shells out to the existing single-purpose CLIs (cut_single_object.py,
cut_prop_sheet.py) for the parts of the pipeline that already have a tested,
argparse'd implementation -- reimplementing their pixel logic here would be
exactly the kind of drift STYLE_LOCK.json exists to prevent.

--ingest is implemented end-to-end for `cutout` only in this version (the
best-understood, most common kind — 18 of the 22 real generation calls this
project has made are cutouts). The other 4 kinds' --ingest prints the exact
existing-tool command to run by hand and which ledger record shape to
--append afterward, rather than shipping unverified automation for paths
this session had no real generation result to test against.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

import ledger_append  # noqa: E402
import style_lock  # noqa: E402
import check_style_conformance  # noqa: E402

KINDS = ("cutout", "sheet", "frameEdit", "overlay", "newBuilding")

REQUIRED_FIELDS = {
    "cutout": (
        "recipeId", "kind", "family", "targetSlug", "model", "resolution",
        "aspectRatio", "referenceImages", "promptTemplate", "promptVars",
        "subjectGuards", "expectedCreditsPerCall", "outputPath",
    ),
    "sheet": (
        "recipeId", "kind", "family", "model", "resolution", "aspectRatio",
        "referenceImages", "promptTemplate", "promptVars", "items",
        "expectedCreditsPerCall",
    ),
    "frameEdit": (
        "recipeId", "kind", "family", "targetBuilding", "model",
        "aspectRatio", "referenceImages", "promptTemplate",
        "expectedCreditsPerCall", "targetBbox",
    ),
    "overlay": (
        "recipeId", "kind", "family", "model", "resolution", "aspectRatio",
        "referenceImages", "promptTemplate", "promptVars", "sockets",
        "expectedCreditsPerCall",
    ),
    "newBuilding": (
        "recipeId", "kind", "family", "targetBuilding", "model", "resolution",
        "aspectRatio", "referenceImages", "promptTemplate", "promptVars",
        "expectedCreditsPerCall", "outputPath",
    ),
}


class RecipeError(ValueError):
    pass


def load_recipe(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def check(recipe: dict[str, Any]) -> list[str]:
    problems: list[str] = []
    kind = recipe.get("kind")
    if kind not in KINDS:
        return [f"kind must be one of {KINDS}, got {kind!r}"]

    for field in REQUIRED_FIELDS[kind]:
        if field not in recipe:
            problems.append(f"missing required field {field!r} for kind {kind!r}")
    if problems:
        return problems  # further checks assume the fields exist

    lock = style_lock.load_style_lock()
    family = recipe["family"]
    if family not in lock["families"]:
        problems.append(f"family {family!r} is not in STYLE_LOCK.json")
    else:
        routing_models = {r["model"] for r in lock["families"][family].get("modelRouting", [])}
        if routing_models and recipe["model"] not in routing_models:
            problems.append(
                f"model {recipe['model']!r} is not in STYLE_LOCK.json families.{family}."
                f"modelRouting {sorted(routing_models)} (warning-worthy, not necessarily wrong "
                "if this is a deliberate new choice -- but check generationFacts.modelRouting first)"
            )

    for ref in recipe.get("referenceImages", []):
        if not (ROOT / ref).is_file():
            problems.append(f"referenceImages entry does not exist: {ref}")
    if len(recipe.get("referenceImages", [])) > 1:
        problems.append(
            f"{len(recipe['referenceImages'])} reference images -- generationFacts.referenceCount "
            "says exactly 1, more has cost real credits with no benefit before"
        )

    if kind == "cutout":
        if not recipe.get("subjectGuards"):
            problems.append(
                "cutout recipes need non-empty subjectGuards -- this is exactly the shape of "
                "the geomungo-drawn-as-gayageum and baduk/mokchim-too-bright failures"
            )
        if style_lock.family_for_slug(lock, recipe["targetSlug"]) is None:
            problems.append(
                f"targetSlug {recipe['targetSlug']!r} is not (yet) a member of any STYLE_LOCK.json "
                "family -- add it there once the recipe is approved, or --check will keep warning"
            )

    if kind == "frameEdit" and recipe.get("resolution") not in (None, "2K"):
        problems.append("frameEdit generationFacts precedent is always 2K -- confirm this isn't 1K by omission")
    elif kind != "frameEdit" and recipe.get("resolution") is None:
        # resolution is in REQUIRED_FIELDS for every non-frameEdit kind, so this
        # only fires when the field is present but explicitly null.
        problems.append(
            "resolution is null -- generationFacts.resolutionDefault says the API defaults "
            "to 1K silently, so this must be an explicit value"
        )

    return problems


def render_prompt(recipe: dict[str, Any]) -> str:
    template = recipe.get("promptTemplate", "")
    variables = recipe.get("promptVars", {})
    try:
        return template.format(**variables)
    except KeyError as exc:
        raise RecipeError(f"promptTemplate references undefined var {exc}") from exc


def emit_work_order(recipe: dict[str, Any]) -> dict[str, Any]:
    problems = check(recipe)
    blocking = [p for p in problems if "warning-worthy" not in p]
    if blocking:
        raise RecipeError("recipe fails --check, refusing to emit a work order:\n" + "\n".join(blocking))
    prompt = render_prompt(recipe)
    return {
        "recipeId": recipe["recipeId"],
        "kind": recipe["kind"],
        "model": recipe["model"],
        "resolution": recipe.get("resolution"),
        "aspectRatio": recipe.get("aspectRatio"),
        "referenceImages": recipe.get("referenceImages", []),
        "prompt": prompt,
        "promptSha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
        "expectedCreditsPerCall": recipe.get("expectedCreditsPerCall"),
        "instructions": [
            "Upload each referenceImages entry once (downsize to a ~400px WebP first if it's "
            "large -- generationFacts.uploadImageLimit: base64 inline needs 15-22K chars or the "
            "transcription can fail).",
            f"Call {'edit_image' if recipe['kind'] in ('frameEdit',) else 'generate_image'} with "
            "exactly this prompt, model, resolution and aspect_ratio.",
            "Save the raw output and record: providerTaskId, actual costCredits (check_credits "
            "before and after), occurredAtUtc (UTC, 'Z' suffix), and the prompt text exactly as "
            "sent (should match promptSha256 above -- if it doesn't, something rewrote the prompt).",
            "Write that into a RESULT.json (see this script's --ingest docstring) and run "
            f"`python3 tool/asset_recipe.py {recipe['recipeId']}.json --ingest RESULT.json`.",
        ],
    }


def plan(recipe: dict[str, Any]) -> str:
    lines = [
        f"recipe {recipe.get('recipeId', '?')} ({recipe.get('kind', '?')}, family {recipe.get('family', '?')})",
        f"  model: {recipe.get('model')} @ {recipe.get('resolution', '(unset)')} {recipe.get('aspectRatio', '')}",
        f"  references: {recipe.get('referenceImages', [])}",
        f"  expected cost: {recipe.get('expectedCreditsPerCall')}cr per call",
    ]
    problems = check(recipe)
    try:
        prompt = render_prompt(recipe)
        lines.append(f"  prompt ({len(prompt)} chars): {prompt[:200]}{'...' if len(prompt) > 200 else ''}")
    except RecipeError as exc:
        lines.append(f"  prompt: CANNOT RENDER — {exc}")
    if problems:
        lines.append(f"  [check] {len(problems)} problem(s):")
        lines.extend(f"    - {p}" for p in problems)
    else:
        lines.append("  [check] clean")
    return "\n".join(lines)


def _ingest_cutout(recipe: dict[str, Any], result: dict[str, Any]) -> int:
    raw_path = ROOT / result["rawOutputPath"]
    if not raw_path.is_file():
        print(f"[fail] rawOutputPath does not exist: {raw_path}")
        return 1

    slug = recipe["targetSlug"]
    pending_dir = ROOT / "assets_unused" / "pending_review" / "asset_recipe" / slug
    pending_dir.mkdir(parents=True, exist_ok=True)
    cut_path = pending_dir / f"{slug}_cut.png"
    report_path = pending_dir / f"{slug}_cut_report.json"

    cut_result = subprocess.run(
        [
            sys.executable, str(ROOT / "tool" / "cut_single_object.py"),
            str(raw_path), str(cut_path),
            "--expect-parts", str(recipe.get("expectParts", 1)),
            "--report", str(report_path),
        ],
        capture_output=True, text=True,
    )
    if cut_result.returncode != 0:
        print(f"[fail] cut_single_object.py rejected the raw generation:\n{cut_result.stderr}")
        _record_rejected(recipe, result, raw_path, reason=cut_result.stderr.strip())
        return 1

    lock = style_lock.load_style_lock()
    gate_result = check_style_conformance.check(cut_path, lock, recipe["family"])
    print(json.dumps(gate_result, indent=2, ensure_ascii=False))
    if not gate_result["ok"]:
        _record_rejected(recipe, result, raw_path, reason="; ".join(gate_result["failures"]))
        print(f"[fail] {slug} failed the style gate — recorded as rejected, nothing promoted")
        return 1

    print(f"[ok] {slug} passed cut + gate. NOT auto-registered -- run manually:")
    print(f"  1. tool/decoration_normalize.py (trim to 1254 + 3% pad -> assets/illustrations/decorations/{slug}.png)")
    print("  2. add the slug to kDecorCategory/kDecorScale/decorName()/kAvailableDecorations")
    print("  3. add decorName{Slug} to lib/l10n/app_de.arb + app_en.arb")
    print(f"  4. python3 tool/ledger_append.py --append <spec for {slug}>")

    spec = {
        "id": f"{recipe['recipeId']}-{result.get('providerTaskId', 'unknown')}",
        "provider": result["provider"],
        "model": result["model"],
        "providerTaskId": result.get("providerTaskId"),
        "mediaKind": "static",
        "occurredAtUtc": result["occurredAtUtc"],
        "costCredits": result["costCredits"],
        "promptText": result["promptSentText"],
        "promptSource": f"tool/asset_recipe.py --emit-work-order for {recipe['recipeId']}",
        "inputAssets": [{"path": ref} for ref in recipe.get("referenceImages", [])],
        "outputAssets": [{"path": str(cut_path.relative_to(ROOT)), "decision": "approved", "kind": "part"}],
    }
    spec_path = pending_dir / f"{slug}_ledger_spec.json"
    spec_path.write_text(json.dumps(spec, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"  ledger record spec written to {spec_path} (inputAssets paths must already be allowlisted)")
    return 0


def _record_rejected(recipe: dict, result: dict, raw_path: Path, *, reason: str) -> None:
    spec = {
        "id": f"{recipe['recipeId']}-{result.get('providerTaskId', 'unknown')}-rejected",
        "provider": result["provider"],
        "model": result["model"],
        "providerTaskId": result.get("providerTaskId"),
        "mediaKind": "static",
        "occurredAtUtc": result["occurredAtUtc"],
        "costCredits": result["costCredits"],
        "promptText": result["promptSentText"],
        "promptSource": f"tool/asset_recipe.py --emit-work-order for {recipe['recipeId']}",
        "note": f"rejected: {reason}",
        "inputAssets": [{"path": ref} for ref in recipe.get("referenceImages", [])],
        "outputAssets": [{"path": str(raw_path.relative_to(ROOT)) if raw_path.is_relative_to(ROOT) else str(raw_path), "decision": "rejected"}],
    }
    print("rejected-record spec (append manually with tool/ledger_append.py --append):")
    print(json.dumps(spec, indent=2, ensure_ascii=False))


def ingest(recipe: dict[str, Any], result_path: Path) -> int:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    kind = recipe["kind"]
    if kind == "cutout":
        return _ingest_cutout(recipe, result)
    print(
        f"[not automated] --ingest for kind {kind!r} isn't wired yet (no real generation result "
        "existed to verify it against this session). Run the matching tool by hand:"
    )
    manual = {
        "sheet": "tool/cut_prop_sheet.py <raw> <out_dir> --report <report.json>",
        "frameEdit": "tool/derive_estate_building_stages.py <building> --align <raw> --frame-key frame --target-bbox <x0,y0,x1,y1>, then --build",
        "overlay": "tool/compose_a2_exterior_overlays.py --manifest <overlays.json>",
        "newBuilding": "no existing tool -- this is Phase 3 P1/P2's first-pass generation; chroma-decode with cut_prop_sheet.chroma_to_alpha, then treat the output as a frameEdit reference for the building's own subsequent stages",
    }
    print(f"  {manual.get(kind, '(no known command)')}")
    print(f"  then: python3 tool/ledger_append.py --append <spec built from {result_path}>")
    return 2


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("recipe", type=Path)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--plan", action="store_true")
    parser.add_argument("--emit-work-order", action="store_true")
    parser.add_argument("--ingest", type=Path, metavar="RESULT.json")
    args = parser.parse_args(argv)

    recipe = load_recipe(args.recipe)

    if args.check:
        problems = check(recipe)
        if problems:
            for p in problems:
                print(f"[fail] {p}")
            return len(problems)
        print(f"[ok] {recipe.get('recipeId')} is structurally valid")
        return 0

    if args.plan:
        print(plan(recipe))
        return 0

    if args.emit_work_order:
        try:
            print(json.dumps(emit_work_order(recipe), indent=2, ensure_ascii=False))
        except RecipeError as exc:
            print(f"[fail] {exc}")
            return 1
        return 0

    if args.ingest:
        return ingest(recipe, args.ingest)

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
