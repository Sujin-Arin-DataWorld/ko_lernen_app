#!/usr/bin/env python3
"""Validate and append records to docs/assets/HANOK_V1_ASSET_PROVENANCE.json's
generationLedger — Phase 2-3 of the "살아 있는 한옥" plan.

`--validate` reproduces, in Python, the exact rules
test/hanok_v1_asset_provenance_test.dart enforces at runtime (both
'every ledger record obeys the declared schema and the credit cap' and
'future generation records fail closed on rights, hashes, and budget') so a
session can get a fast pre-check before paying for a full `flutter test`
run. It is deliberately NOT a reimplementation that could drift from the
Dart source of truth in spirit -- every rule below cites the exact Dart test
name it mirrors; if that test changes, this validator must change with it.

`--append` builds one well-formed record from a description JSON (paths only
-- it computes every sha256 itself, so a caller can never accidentally
record a hash of bytes it didn't actually read) and refuses to write it if
`--validate` would then fail.

Usage:
    python3 tool/ledger_append.py --validate [--ledger PATH]
    python3 tool/ledger_append.py --append RECORD.json [--ledger PATH]

RECORD.json shape (see docs/assets/HANOK_V1_ASSET_PROVENANCE.json for real
examples): {id, provider, model, providerTaskId?, mediaKind, occurredAtUtc,
costCredits, promptText or promptSha256, promptSource?, note?,
inputAssets: [{path}], outputAssets: [{path, decision, kind?}]}
-- inputAssets/outputAssets need only `path` (+ optional `kind`/`decision`);
sha256 is computed from the file on disk. `promptText` (preferred) is hashed
here; pass `promptSha256` directly only when the real prompt text can't be
recovered (mirrors the a2-exterior-traces-v1-rejected precedent).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LEDGER = ROOT / "docs" / "assets" / "HANOK_V1_ASSET_PROVENANCE.json"

REQUIRED_RECORD_FIELDS = (
    "id",
    "provider",
    "model",
    "mediaKind",
    "occurredAtUtc",
    "costCredits",
    "promptSha256",
    "inputAssets",
    "outputAssets",
)
INPUT_ASSET_FIELDS = ("path", "sha256")
OUTPUT_ASSET_FIELDS = ("path", "sha256", "decision")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


class LedgerValidationError(ValueError):
    pass


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _require_sha256(value: Any, label: str) -> str:
    if not isinstance(value, str) or not SHA256_RE.match(value):
        raise LedgerValidationError(f"{label} must be a lower-case SHA-256 digest, got {value!r}")
    return value


def load_ledger(path: Path = DEFAULT_LEDGER) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate(data: dict[str, Any]) -> list[str]:
    """Returns a list of problems (empty = valid). Mirrors
    hanok_v1_asset_provenance_test.dart's two 'Generation ledger' tests."""
    problems: list[str] = []
    ledger = data.get("generationLedger")
    if not isinstance(ledger, dict):
        return ["generationLedger is missing or not an object"]

    schema = ledger.get("recordSchema", {})
    required = schema.get("requiredFields", list(REQUIRED_RECORD_FIELDS))
    input_fields = schema.get("inputAssetFields", list(INPUT_ASSET_FIELDS))
    output_fields = schema.get("outputAssetFields", list(OUTPUT_ASSET_FIELDS))
    kinds = set(schema.get("outputAssetKinds", []))

    allowed_inputs: dict[str, str] = {}
    for entry in data.get("allowedModelInputs", []):
        path = entry.get("path")
        sha = entry.get("sha256")
        if path and sha:
            allowed_inputs[path] = sha
    known_inputs = dict(allowed_inputs)

    records = ledger.get("records", [])
    if not records:
        problems.append("generationLedger.records is empty (A1 states are promoted, so it cannot be)")

    seen_ids: set[str] = set()
    static_credits = 0.0
    video_credits = 0.0
    baseline_credits = 0.0  # for the staticMax-vs-priorDiscarded check

    for record in records:
        rid = record.get("id", "<missing id>")
        for field in required:
            if field not in record:
                problems.append(f"{rid}: missing required field {field!r}")
        if rid in seen_ids:
            problems.append(f"duplicate generation record id {rid!r}")
        seen_ids.add(rid)

        provider = record.get("provider")
        media_kind = record.get("mediaKind")
        if media_kind not in ("static", "video"):
            problems.append(f"{rid}: mediaKind must be 'static' or 'video', got {media_kind!r}")

        occurred = record.get("occurredAtUtc", "")
        parsed = None
        try:
            parsed = datetime.fromisoformat(occurred.replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            pass
        if parsed is None or parsed.tzinfo is None or not occurred.endswith("Z"):
            problems.append(f"{rid}: occurredAtUtc must be canonical UTC ending in 'Z', got {occurred!r}")

        credits = record.get("costCredits")
        if not isinstance(credits, (int, float)):
            problems.append(f"{rid}: costCredits must be numeric")
            credits = 0.0
        if provider == "local":
            if credits != 0:
                problems.append(f"{rid}: provider 'local' must cost exactly 0, got {credits}")
        else:
            if not (credits > 0):
                problems.append(f"{rid}: a paid provider call must cost > 0, got {credits}")

        try:
            _require_sha256(record.get("promptSha256"), f"{rid}.promptSha256")
        except LedgerValidationError as exc:
            problems.append(str(exc))

        for entry in record.get("inputAssets", []):
            for field in input_fields:
                if field not in entry:
                    problems.append(f"{rid}: input asset missing {field!r}")
            path = entry.get("path")
            sha = entry.get("sha256")
            try:
                _require_sha256(sha, f"{rid}.inputAssets[{path}].sha256")
            except LedgerValidationError as exc:
                problems.append(str(exc))
                continue
            if known_inputs.get(path) != sha:
                problems.append(
                    f"{rid}: input {path!r} is not a known allowlisted-or-approved-output "
                    "path+sha256 at this point in the record order"
                )

        for entry in record.get("outputAssets", []):
            for field in output_fields:
                if field not in entry:
                    problems.append(f"{rid}: output asset missing {field!r}")
            path = entry.get("path", "")
            if ".." in path or re.match(r"^[A-Za-z]:", path):
                problems.append(f"{rid}: output path looks unsafe: {path!r}")
            sha = entry.get("sha256")
            try:
                _require_sha256(sha, f"{rid}.outputAssets[{path}].sha256")
            except LedgerValidationError as exc:
                problems.append(str(exc))
                continue
            decision = entry.get("decision")
            if decision not in ("approved", "rejected"):
                problems.append(f"{rid}: output {path!r} decision must be approved/rejected, got {decision!r}")
            kind = entry.get("kind")
            if kind is not None and kinds and kind not in kinds:
                problems.append(f"{rid}: output {path!r} kind {kind!r} not in declared outputAssetKinds {sorted(kinds)}")
            if decision == "approved":
                known_inputs[path] = sha
                full_path = ROOT / path
                if not full_path.is_file():
                    problems.append(f"{rid}: approved output {path!r} does not exist on disk")
                elif sha256_file(full_path) != sha:
                    problems.append(f"{rid}: approved output {path!r} sha256 no longer matches — file changed after approval")

        if media_kind == "static":
            static_credits += credits
        else:
            video_credits += credits
        baseline_credits += credits

    budgets = ledger.get("budgetCredits", {})
    static_max = budgets.get("staticMax")
    video_max = budgets.get("videoMax")
    total_max = budgets.get("totalMax")
    if static_max is not None and static_credits > static_max:
        problems.append(f"static credits {static_credits} exceed staticMax {static_max}")
    if video_max is not None and video_credits > video_max:
        problems.append(f"video credits {video_credits} exceed videoMax {video_max}")
    if total_max is not None and (static_credits + video_credits) > total_max:
        problems.append(f"total credits {static_credits + video_credits} exceed totalMax {total_max}")

    prior = ledger.get("priorDiscardedCredits", {}).get("credits", 0.0)
    if static_max is not None and (baseline_credits + prior) > static_max:
        problems.append(
            f"records total {baseline_credits} + priorDiscardedCredits {prior} "
            f"= {baseline_credits + prior} exceeds staticMax {static_max}"
        )

    return problems


def build_record(spec: dict[str, Any]) -> dict[str, Any]:
    """Turn a path-only RECORD.json description into a fully-hashed record."""
    record = dict(spec)
    if "promptSha256" not in record:
        prompt_text = record.pop("promptText", None)
        if prompt_text is None:
            raise LedgerValidationError("record needs either promptText or promptSha256")
        record["promptSha256"] = sha256_text(prompt_text)
    else:
        record.pop("promptText", None)

    input_assets = []
    for entry in spec.get("inputAssets", []):
        path = entry["path"]
        input_assets.append({"path": path, "sha256": sha256_file(ROOT / path)})
    record["inputAssets"] = input_assets

    output_assets = []
    for entry in spec.get("outputAssets", []):
        path = entry["path"]
        out = {
            "path": path,
            "sha256": sha256_file(ROOT / path),
            "decision": entry.get("decision", "approved"),
        }
        if "kind" in entry:
            out["kind"] = entry["kind"]
        output_assets.append(out)
    record["outputAssets"] = output_assets
    return record


def append_record(ledger_path: Path, record_spec_path: Path) -> None:
    data = load_ledger(ledger_path)
    spec = json.loads(record_spec_path.read_text(encoding="utf-8"))
    record = build_record(spec)

    existing_ids = {r["id"] for r in data["generationLedger"]["records"]}
    if record["id"] in existing_ids:
        raise LedgerValidationError(f"record id {record['id']!r} already exists in the ledger")

    trial = json.loads(json.dumps(data))  # deep copy
    trial["generationLedger"]["records"].append(record)
    problems = validate(trial)
    if problems:
        raise LedgerValidationError(
            "refusing to append -- the ledger would fail validation:\n"
            + "\n".join(f"  - {p}" for p in problems)
        )

    data["generationLedger"]["records"].append(record)
    ledger_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"appended {record['id']} to {ledger_path}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--append", type=Path, metavar="RECORD.json")
    args = parser.parse_args(argv)

    if args.append:
        try:
            append_record(args.ledger, args.append)
        except LedgerValidationError as exc:
            print(f"[fail] {exc}")
            return 1
        return 0

    if args.validate:
        data = load_ledger(args.ledger)
        problems = validate(data)
        if problems:
            for problem in problems:
                print(f"[fail] {problem}")
            print(f"\n{len(problems)} problem(s)")
            return len(problems)
        n = len(data["generationLedger"]["records"])
        print(f"[ok] {n} records valid, budget within cap")
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
