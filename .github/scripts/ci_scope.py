#!/usr/bin/env python3
"""Select the minimum safe GitHub Actions jobs for a change set.

The selector intentionally fails open: if Git history cannot be compared, every
scope is enabled. Skipping an irrelevant job saves minutes; skipping a relevant
quality gate is never an acceptable fallback.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import PurePosixPath
from typing import Iterable


SCOPES = (
    "app", "website", "book", "gye", "pronunciation", "tts", "auth_cleanup",
    "content",
)

TASK_SCOPE = {
    "full": SCOPES,
    "flutter": ("app",),
    "website": ("website",),
    "book": ("book",),
    "gye": ("gye",),
    "pronunciation": ("pronunciation",),
    "tts": ("tts",),
    "auth-cleanup": ("auth_cleanup",),
    "content": ("content",),
    "release-internal": ("app",),
    "release-website": ("website",),
}

APP_DOC_PREFIXES = (
    "docs/store/",
    "docs/screenshots/",
    # docs/assets/ carries the hanok provenance JSON, the estate/A1 kit stage
    # specs, and the recipe/style-lock files the Python asset gates read —
    # these are test/tool inputs, not prose, even though the path looks like
    # a doc. See test/hanok_v1_asset_provenance_test.dart.
    "docs/assets/",
)
APP_DOC_FILES = {
    "docs/privacy.html",
    "docs/support.html",
    "docs/SESSION_CHANGES_2026-07-31.md",
}
WEBSITE_ROOT_FILES = {
    "docs/CNAME",
    "wrangler.jsonc",
    "wrangler.legacy-docs.jsonc",
}
SHARED_CULTURAL_GLOSSARY_FILES = {
    "docs/data/cultural_glossary.json",
}
AGENT_ONLY_PREFIXES = (
    ".agents/",
    ".claude/",
    ".superpowers/",
    "tasks/",
)


def _empty_scopes() -> dict[str, bool]:
    return {scope: False for scope in SCOPES}


def _all_scopes() -> dict[str, bool]:
    return {scope: True for scope in SCOPES}


def scopes_for_task(task: str) -> dict[str, bool] | None:
    """Return an explicit manual selection, or None for automatic `ci`."""
    if task == "ci":
        return None
    selected = TASK_SCOPE.get(task)
    if selected is None:
        raise ValueError(f"unsupported CI task: {task}")
    result = _empty_scopes()
    for scope in selected:
        result[scope] = True
    return result


def scopes_for_paths(paths: Iterable[str]) -> dict[str, bool]:
    """Map repository-relative paths to independently useful CI gates."""
    result = _empty_scopes()

    for raw_path in paths:
        path = PurePosixPath(raw_path.replace("\\", "/")).as_posix()
        if path.startswith("./"):
            path = path[2:]
        if not path:
            continue

        # Workflow and selector changes validate every branch of the selector.
        if path.startswith(".github/"):
            return _all_scopes()

        if path.startswith("hangul-sori-site-local/") or path in WEBSITE_ROOT_FILES:
            result["website"] = True
            continue

        if path in SHARED_CULTURAL_GLOSSARY_FILES:
            result["app"] = True
            result["website"] = True
            continue

        if path.startswith("functions/analyze_korean_text/"):
            result["book"] = True
            continue

        if path.startswith("functions/gye/"):
            result["gye"] = True
            continue

        if path.startswith("functions/pronunciation/"):
            result["pronunciation"] = True
            continue

        if path.startswith("functions/tts/"):
            result["tts"] = True
            continue

        if path.startswith("assets/data/scenarios_") and path.endswith(".json"):
            result["content"] = True
            continue

        if path in {
            "assets/data/cloze.json",
            "assets/data/satz_sentences.json",
            "assets/data/smalltalk.json",
            "assets/data/silben_puzzles.json",
            "assets/data/korean_vocab.csv",
            "assets/data/grammar.csv",
        }:
            result["content"] = True
            continue

        if path.startswith("functions/auth_cleanup/"):
            result["auth_cleanup"] = True
            continue

        # Shared deployment contracts are consumed by more than one test suite.
        if path == "firestore.rules":
            result["app"] = True
            result["book"] = True
            result["gye"] = True
            continue

        if path == "firestore.indexes.json":
            result["book"] = True
            result["gye"] = True
            continue

        if path == "firebase.json":
            # auth_cleanup is a gen-1 Auth trigger deployed outside this
            # codebases array (see firebase.json), so it is deliberately not
            # listed here — only functions declared in the array are.
            result["app"] = True
            result["gye"] = True
            result["pronunciation"] = True
            result["tts"] = True
            continue

        if path in APP_DOC_FILES or path.startswith(APP_DOC_PREFIXES):
            result["app"] = True
            continue

        # Session logs, plans, agent metadata and ordinary prose do not affect a
        # shipped artifact. Product documentation used by tests was handled above.
        if (
            path.startswith("docs/")
            or path.endswith(".md")
            or path.startswith(AGENT_ONLY_PREFIXES)
        ):
            continue

        # Unknown product/config paths retain the broad Flutter gate that existed
        # before scope selection. New areas therefore fail safe instead of vanishing.
        result["app"] = True

    return result


def _git(*args: str) -> str:
    completed = subprocess.run(
        ("git", *args),
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return completed.stdout.strip()


def _changed_paths(base: str, head: str) -> list[str]:
    if not base or not head:
        raise ValueError("missing Git comparison SHA")
    completed = subprocess.run(
        (
            "git",
            "-c",
            "core.quotepath=false",
            "diff",
            "--name-only",
            "--diff-filter=ACDMRTUXB",
            "-z",
            base,
            head,
        ),
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return [path for path in completed.stdout.split("\0") if path]


def detect_paths(env: dict[str, str]) -> list[str] | None:
    """Return changed paths, or None when a manual main run means full CI."""
    event = env.get("CI_EVENT_NAME", "")
    if event == "pull_request":
        base = env.get("CI_PR_BASE_SHA", "")
        head = env.get("CI_PR_HEAD_SHA", "")
        merge_base = _git("merge-base", base, head)
        return _changed_paths(merge_base, head)

    if event == "push":
        before = env.get("CI_BEFORE_SHA", "")
        head = env.get("CI_SHA", "")
        if not before or set(before) == {"0"}:
            return None
        return _changed_paths(before, head)

    if event == "workflow_dispatch":
        head = env.get("CI_SHA", "")
        default_branch = env.get("CI_DEFAULT_BRANCH", "main")
        ref_name = env.get("CI_REF_NAME", "")
        base = _git("merge-base", head, f"origin/{default_branch}")
        # Clicking the default task on main still means "verify current main".
        if ref_name == default_branch and base == head:
            return None
        return _changed_paths(base, head)

    raise ValueError(f"unsupported CI event: {event}")


def _write_outputs(scopes: dict[str, bool], output_path: str) -> None:
    if not output_path:
        raise ValueError("GITHUB_OUTPUT is not set")
    with open(output_path, "a", encoding="utf-8") as output:
        for scope in SCOPES:
            output.write(f"{scope}={'true' if scopes[scope] else 'false'}\n")


def main() -> int:
    env = dict(os.environ)
    task = env.get("CI_MANUAL_TASK", "ci")

    try:
        scopes = scopes_for_task(task)
        paths: list[str] | None = []
        if scopes is None:
            paths = detect_paths(env)
            scopes = _all_scopes() if paths is None else scopes_for_paths(paths)
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"::warning::CI scope detection failed; enabling every gate: {error}")
        scopes = _all_scopes()
        paths = None

    enabled = ", ".join(scope for scope, selected in scopes.items() if selected) or "none"
    print(f"Selected CI scopes: {enabled}")
    if paths is not None:
        print(f"Changed paths ({len(paths)}):")
        for path in paths[:100]:
            print(f"  {path}")
        if len(paths) > 100:
            print(f"  ... and {len(paths) - 100} more")

    _write_outputs(scopes, env.get("GITHUB_OUTPUT", ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
