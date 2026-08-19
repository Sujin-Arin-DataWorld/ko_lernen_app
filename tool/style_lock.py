#!/usr/bin/env python3
"""Reader for docs/assets/STYLE_LOCK.json — the style-family SSoT.

Priority order (see STYLE_LOCK.json's own "note" field, and the banners this
module's sibling tool/check_style_lock_docs.py enforces on the older docs):

    STYLE_LOCK.json  >  docs/HANOK_ASSET_INVENTORY_2026-08-17.md  >  docs/ASSET_GENERATION_BIBLE.md

Nothing here mutates the file; this is a thin, validated accessor so other
tools (asset_recipe.py, check_style_conformance.py) don't each re-parse and
re-guess the schema.

Usage:
    from style_lock import load_style_lock, family_for_slug, gates_for_family

    lock = load_style_lock()
    family = family_for_slug(lock, "decoration_geomungo")   # -> "F-A"
    gates = gates_for_family(lock, "F-A")                    # -> dict
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
STYLE_LOCK_PATH = ROOT / "docs" / "assets" / "STYLE_LOCK.json"

REQUIRED_FAMILY_FIELDS = (
    "label",
    "dirs",
    "members",
    "anchors",
    "palette",
    "camera",
    "promptSkeleton",
    "modelRouting",
    "postProcess",
    "gates",
    "registration",
)


def load_style_lock(path: Path = STYLE_LOCK_PATH) -> dict[str, Any]:
    """Load and structurally validate STYLE_LOCK.json.

    Validates only the shape every downstream reader depends on (family
    presence + the 11 required per-family keys) -- it does not re-validate
    measured numbers, which are provenance, not schema.
    """
    data = json.loads(path.read_text(encoding="utf-8"))
    families = data.get("families")
    if not isinstance(families, dict) or not families:
        raise ValueError(f"{path}: 'families' must be a non-empty object")
    for name, family in families.items():
        missing = [f for f in REQUIRED_FAMILY_FIELDS if f not in family]
        if missing:
            raise ValueError(f"{path}: family '{name}' missing fields {missing}")
    if "chroma" not in data:
        raise ValueError(f"{path}: top-level 'chroma' is required")
    if "generationFacts" not in data:
        raise ValueError(f"{path}: top-level 'generationFacts' is required")
    return data


def family_for_slug(lock: dict[str, Any], slug: str) -> str | None:
    """Which family owns this decoration/asset slug (bare name, no extension)."""
    bare = Path(slug).stem
    for name, family in lock["families"].items():
        if bare in family.get("members", []):
            return name
    return None


def gates_for_family(lock: dict[str, Any], family_name: str) -> dict[str, Any]:
    family = lock["families"].get(family_name)
    if family is None:
        raise KeyError(f"unknown style family: {family_name}")
    return family["gates"]


def all_member_dirs(lock: dict[str, Any]) -> set[str]:
    """Every directory any family declares -- for cross-checking pubspec.yaml."""
    return {d for family in lock["families"].values() for d in family["dirs"]}


def allowed_models(lock: dict[str, Any], family_name: str) -> set[str]:
    """Models with allowed:true. Empty routing means the family does not generate."""
    family = lock["families"].get(family_name) or {}
    return {
        entry["model"]
        for entry in family.get("modelRouting") or []
        if entry.get("model") and entry.get("allowed") is True
    }


def denied_models(lock: dict[str, Any], family_name: str) -> set[str]:
    """Models with allowed:false (e.g. Seedream on F-A / F-B)."""
    family = lock["families"].get(family_name) or {}
    return {
        entry["model"]
        for entry in family.get("modelRouting") or []
        if entry.get("model") and entry.get("allowed") is False
    }


def model_routing_error(lock: dict[str, Any], family_name: str, model: str) -> str | None:
    """Hard-fail reason, or None if this model may be used for the family."""
    routing = (lock["families"].get(family_name) or {}).get("modelRouting") or []
    if not routing:
        return (
            f"family {family_name!r} has an empty modelRouting — no generation is allowed"
        )
    if model in denied_models(lock, family_name):
        return f"model {model!r} is denied for family {family_name}"
    allowed = allowed_models(lock, family_name)
    if allowed and model not in allowed:
        return (
            f"model {model!r} is not in the allowed list for family {family_name}: "
            f"{sorted(allowed)}"
        )
    if not allowed and model not in {entry.get("model") for entry in routing}:
        return (
            f"model {model!r} is not in STYLE_LOCK.json families.{family_name}.modelRouting"
        )
    return None


if __name__ == "__main__":
    lock = load_style_lock()
    print(f"families: {sorted(lock['families'])}")
    for name in sorted(lock["families"]):
        gates = gates_for_family(lock, name)
        print(f"  {name}: satMean={gates['satMean']} valMean={gates['valMean']} neonMax={gates['neonMax']}")
