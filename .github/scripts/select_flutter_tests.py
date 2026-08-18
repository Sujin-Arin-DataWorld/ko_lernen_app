#!/usr/bin/env python3
"""Pick which Flutter tests a pull_request run has to execute.

`main` pushes and manual runs keep the full suite. Pull requests run only the
tests whose Dart import closure touches a changed file, plus a small set of
always-on repository guards. Changes that can invalidate tests without any
Dart import edge (content data, localization, pubspec, goldens, platform
folders) fall back to the full suite.

Like ci_scope.py this selector fails open: any error means the full suite.
"""

from __future__ import annotations

import os
import re
from pathlib import Path, PurePosixPath
from typing import Iterable

import ci_scope

PACKAGE_NAME = "ko_lernen_app"

# Any change here can break tests that never import the changed file.
FULL_SUITE_PREFIXES = (
    "assets/",
    "lib/l10n/",
    "test/goldens/",
    "android/",
    "ios/",
    "web/",
    "macos/",
    "linux/",
    "windows/",
)
FULL_SUITE_FILES = {
    "pubspec.yaml",
    "pubspec.lock",
    "analysis_options.yaml",
    "l10n.yaml",
    "dart_test.yaml",
}

# Cheap repository guards every pull request still runs.
ALWAYS_ON_TESTS = (
    "test/typography_guard_test.dart",
    "test/l10n_parity_test.dart",
    "test/arb_l10n_guard_test.dart",
    "test/sori_activity_catalog_test.dart",
    # 2026-08-18 테스터 피드백(Amor) 재발 방지. 셋 다 소스/데이터를 직접
    # 스캔하는 가드라 import 그래프로는 선택되지 않는다 — 여기 없으면
    # 정작 문제를 만든 PR 에서 돌지 않는다.
    "test/ui_string_locale_guard_test.dart",
    "test/hangul_content_locale_test.dart",
    "test/jamo_speech_test.dart",
    # 덱 제스처 방향 계약(좌=모름·우=앎·위=저장·아래=넘어가기). 소스 스캔이라
    # import 그래프로는 선택되지 않는다.
    "test/deck_direction_contract_test.dart",
    # 덱 물리/어포던스 센서. §1 이 위젯 카운터(무효 판정)에서 **소스 래칫**으로
    # 바뀌었고 nudge⇒onNudgePlayed 호출부 스캔도 들어 있어, import 그래프만으론
    # 정작 그 규약을 깨는 PR 에서 안 돈다.
    "test/deck_swipe_physics_test.dart",
)

_IMPORT_LINE = re.compile(r"^\s*(?:import|export|part)\s")
_QUOTED = re.compile(r"""['"]([^'"]+)['"]""")


def classify_paths(paths: Iterable[str]) -> str:
    """Return 'full' or 'scoped' for a pull request change set."""
    for raw in paths:
        path = PurePosixPath(raw).as_posix()
        if path in FULL_SUITE_FILES or path.startswith(FULL_SUITE_PREFIXES):
            return "full"
    return "scoped"


def dart_import_specs(text: str) -> list[str]:
    specs: list[str] = []
    for line in text.splitlines():
        if _IMPORT_LINE.match(line):
            specs.extend(_QUOTED.findall(line))
    return specs


def resolve_import(importer: str, spec: str) -> str | None:
    """Map an import spec to a repo-relative posix path inside lib/ or test/."""
    if spec.startswith("dart:"):
        return None
    if spec.startswith("package:"):
        prefix = f"package:{PACKAGE_NAME}/"
        if not spec.startswith(prefix):
            return None
        return f"lib/{spec[len(prefix):]}"
    base = PurePosixPath(importer).parent
    resolved = os.path.normpath((base / spec).as_posix()).replace("\\", "/")
    if resolved.startswith("lib/") or resolved.startswith("test/"):
        return resolved
    return None


def build_import_graph(root: Path) -> dict[str, set[str]]:
    graph: dict[str, set[str]] = {}
    for folder in ("lib", "test"):
        for file in (root / folder).rglob("*.dart"):
            rel = file.relative_to(root).as_posix()
            try:
                text = file.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                text = file.read_text(encoding="utf-8", errors="replace")
            edges = set()
            for spec in dart_import_specs(text):
                target = resolve_import(rel, spec)
                if target is not None:
                    edges.add(target)
            graph[rel] = edges
    return graph


def _closure(graph: dict[str, set[str]], start: str, memo: dict[str, set[str]]) -> set[str]:
    if start in memo:
        return memo[start]
    seen: set[str] = set()
    stack = [start]
    while stack:
        node = stack.pop()
        if node in seen:
            continue
        seen.add(node)
        stack.extend(graph.get(node, ()))
    memo[start] = seen
    return seen


def select_tests(
    changed: Iterable[str],
    graph: dict[str, set[str]],
    always_on: Iterable[str] = ALWAYS_ON_TESTS,
) -> list[str]:
    changed_set = {PurePosixPath(p).as_posix() for p in changed}
    tests = sorted(
        node for node in graph if node.startswith("test/") and node.endswith("_test.dart")
    )
    memo: dict[str, set[str]] = {}
    selected: set[str] = set()
    for test in tests:
        if test in changed_set or _closure(graph, test, memo) & changed_set:
            selected.add(test)
    for guard in always_on:
        if guard in graph:
            selected.add(guard)
    return sorted(selected)


def _write_outputs(mode: str, tests: list[str], output_path: str) -> None:
    if not output_path:
        raise ValueError("GITHUB_OUTPUT is not set")
    with open(output_path, "a", encoding="utf-8") as output:
        output.write(f"flutter_test_mode={mode}\n")
        output.write(f"flutter_tests={' '.join(tests)}\n")


def decide(env: dict[str, str], root: Path) -> tuple[str, list[str], list[str]]:
    """Return (mode, tests, changed_paths) for the current CI event."""
    if env.get("CI_EVENT_NAME", "") != "pull_request":
        return "full", [], []
    if env.get("CI_MANUAL_TASK", "ci") != "ci":
        return "full", [], []
    paths = ci_scope.detect_paths(env) or []
    mode = classify_paths(paths)
    if mode == "full":
        return mode, [], paths
    graph = build_import_graph(root)
    return mode, select_tests(paths, graph), paths


def main() -> int:
    env = dict(os.environ)
    root = Path(__file__).resolve().parents[2]
    try:
        mode, tests, paths = decide(env, root)
    except Exception as error:  # noqa: BLE001 - fail open on purpose
        print(f"::warning::Flutter test selection failed; running the full suite: {error}")
        mode, tests, paths = "full", [], []

    if mode == "full":
        print("Flutter tests: full suite")
    else:
        print(f"Flutter tests: scoped pull_request run, {len(tests)} test files")
        for test in tests:
            print(f"  {test}")
    if paths:
        print(f"Changed paths considered ({len(paths)}):")
        for path in paths[:100]:
            print(f"  {path}")

    _write_outputs(mode, tests, env.get("GITHUB_OUTPUT", ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
