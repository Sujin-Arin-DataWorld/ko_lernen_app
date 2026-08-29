#!/usr/bin/env python3
"""CLI for the zero-API canonical scenario workflow."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

import scenario_corpus_pipeline as pipeline


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CANDIDATES = ROOT / "tools/content_factory/review/canonical_120_v1/candidates"
DEFAULT_REGRESSION_CANDIDATES = (
    ROOT / "tools/content_factory/review/canonical_120_v1/regression_candidates"
)


def _write(path: Path, value: object, *, markdown: bool = False) -> Path:
    target = path if path.is_absolute() else ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    text = value if markdown else pipeline.json_text(value)
    target.write_text(str(text), encoding="utf-8")
    return target


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)

    commands.add_parser("validate-portfolio")

    packet = commands.add_parser("packet")
    packet.add_argument("scenario_id")
    packet.add_argument("--regression", action="store_true")
    packet.add_argument("--output", type=Path, required=True)

    stage = commands.add_parser("stage-prompt")
    stage.add_argument("packet", type=Path)
    stage.add_argument("stage_id", choices=("ko_scene", "learning_extract", "localize", "audit"))
    stage.add_argument("--input", type=Path)
    stage.add_argument("--output", type=Path, required=True)

    candidate = commands.add_parser("validate-candidate")
    candidate.add_argument("candidate", type=Path)

    review = commands.add_parser("render-review")
    review.add_argument("level", choices=pipeline.LEVELS)
    review.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    review.add_argument("--output", type=Path, required=True)

    preflight = commands.add_parser("preflight-level")
    preflight.add_argument("level", choices=pipeline.LEVELS)
    preflight.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    preflight.add_argument("--output", type=Path)

    corpus_preflight = commands.add_parser("preflight-corpus")
    corpus_preflight.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    corpus_preflight.add_argument("--output", type=Path)

    commands.add_parser("validate-regression")

    regression_preflight = commands.add_parser("preflight-regression")
    regression_preflight.add_argument(
        "--candidates",
        type=Path,
        default=DEFAULT_REGRESSION_CANDIDATES,
    )
    regression_preflight.add_argument("--output", type=Path)

    regression_review = commands.add_parser("render-regression-review")
    regression_review.add_argument(
        "--candidates",
        type=Path,
        default=DEFAULT_REGRESSION_CANDIDATES,
    )
    regression_review.add_argument("--output", type=Path, required=True)

    approval = commands.add_parser("approve-level")
    approval.add_argument("level", choices=pipeline.LEVELS)
    approval.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    approval.add_argument("--reviewer", required=True)
    approval.add_argument("--candidate-set-sha256", required=True)
    approval.add_argument(
        "--editorial-audit",
        type=Path,
        default=Path(
            "tools/content_factory/review/canonical_120_v1/editorial_audit.json"
        ),
    )
    approval.add_argument("--model-audit", type=Path, required=True)
    approval.add_argument(
        "--output",
        type=Path,
        default=Path("tools/content_factory/canonical_scenarios/approvals.json"),
    )

    tts = commands.add_parser("tts-pending")
    tts.add_argument("level", choices=pipeline.LEVELS)
    tts.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    tts.add_argument("--output", type=Path, required=True)

    corpus_tts = commands.add_parser("tts-pending-corpus")
    corpus_tts.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    corpus_tts.add_argument("--output", type=Path, required=True)

    promote = commands.add_parser("promote-level")
    promote.add_argument("level", choices=pipeline.LEVELS)
    promote.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    promote.add_argument("--tts-output", type=Path, required=True)
    promote.add_argument(
        "--tts-readiness",
        type=Path,
        help="Receipt written by generate_tts.py --verify-storage for this exact level.",
    )
    promote.add_argument(
        "--runtime-write-reviewer",
        help="Explicit runtime-write authorization; must be Jin when --write is used.",
    )
    promote.add_argument("--write", action="store_true")
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "validate-portfolio":
            report = pipeline.validate_portfolio(ROOT)
            print(pipeline.json_text(report.to_json()), end="")
            return 0 if report.ok else 1
        if args.command == "packet":
            value = pipeline.build_prompt_packet(
                args.scenario_id,
                root=ROOT,
                regression=args.regression,
            )
            print(_write(args.output, value))
            return 0
        if args.command == "stage-prompt":
            packet = pipeline.read_json(args.packet)
            stage_input = None if args.input is None else pipeline.read_json(args.input)
            prompt = pipeline.render_stage_prompt(packet, args.stage_id, stage_input)
            print(_write(args.output, prompt, markdown=True))
            return 0
        if args.command == "validate-candidate":
            _, _, report = pipeline.load_and_validate_candidate(args.candidate, root=ROOT)
            print(pipeline.json_text(report.to_json()), end="")
            return 0 if report.ok else 1
        if args.command == "render-review":
            candidates = pipeline.load_level_candidates(args.candidates, args.level, root=ROOT)
            review = pipeline.render_level_review(candidates, root=ROOT)
            print(_write(args.output, review, markdown=True))
            return 0
        if args.command == "preflight-level":
            result = pipeline.preflight_level(
                level=args.level,
                candidate_directory=args.candidates,
                root=ROOT,
            )
            if args.output is not None:
                print(_write(args.output, result))
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0
        if args.command == "preflight-corpus":
            result = pipeline.preflight_corpus(
                candidate_directory=args.candidates,
                root=ROOT,
            )
            if args.output is not None:
                print(_write(args.output, result))
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0
        if args.command == "validate-regression":
            candidates = pipeline.load_regression_candidates(
                DEFAULT_REGRESSION_CANDIDATES,
                root=ROOT,
            )
            print(pipeline.json_text({"ok": True, "count": len(candidates)}), end="")
            return 0
        if args.command == "preflight-regression":
            result = pipeline.preflight_regression_ladders(
                args.candidates,
                root=ROOT,
            )
            if args.output is not None:
                print(_write(args.output, result))
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0
        if args.command == "render-regression-review":
            candidates = pipeline.load_regression_candidates(args.candidates, root=ROOT)
            review = pipeline.render_regression_review(candidates, root=ROOT)
            print(_write(args.output, review, markdown=True))
            return 0
        if args.command == "approve-level":
            approval = pipeline.record_level_approval(
                level=args.level,
                candidate_directory=args.candidates,
                reviewer=args.reviewer,
                reviewed_candidate_set_sha256=args.candidate_set_sha256,
                editorial_audit_path=args.editorial_audit,
                model_audit_path=args.model_audit,
                root=ROOT,
            )
            print(_write(args.output, approval))
            return 0
        if args.command == "tts-pending":
            candidates = pipeline.load_level_candidates(args.candidates, args.level, root=ROOT)
            manifest = pipeline.build_tts_pending_manifest(candidates, root=ROOT)
            print(_write(args.output, manifest))
            return 0
        if args.command == "tts-pending-corpus":
            candidates = pipeline.load_corpus_candidates(args.candidates, root=ROOT)
            manifest = pipeline.build_tts_pending_manifest(candidates, root=ROOT)
            print(_write(args.output, manifest))
            return 0
        if args.command == "promote-level":
            result = pipeline.promote_level(
                level=args.level,
                candidate_directory=args.candidates,
                tts_manifest_output=(args.tts_output if args.tts_output.is_absolute() else ROOT / args.tts_output),
                tts_readiness_receipt=args.tts_readiness,
                runtime_write_reviewer=args.runtime_write_reviewer,
                root=ROOT,
                write=args.write,
            )
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0
        raise pipeline.CorpusError(f"unknown command {args.command}")
    except (pipeline.CorpusError, OSError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
