"""Check whether Flutter asset declarations exist in one committed Git tree.

This is a narrow, offline preflight.  It does not check Dart consumers, build
an asset bundle, or make any release-readiness claim.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys


class AssetCheckError(Exception):
    """A fixed diagnostic code for invalid local input."""


def _git(repo: Path, args: list[str], error: str) -> bytes:
    environment = os.environ.copy()
    # A partial clone may otherwise fetch a promised object while this local
    # preflight reads it. Missing objects must fail locally instead.
    environment["GIT_NO_LAZY_FETCH"] = "1"
    try:
        result = subprocess.run(
            ["git", "-C", str(repo), *args],
            env=environment,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
            timeout=15,
        )
    except FileNotFoundError:
        raise AssetCheckError("git_unavailable") from None
    except (OSError, subprocess.TimeoutExpired):
        raise AssetCheckError("git_unavailable") from None
    if result.returncode != 0:
        raise AssetCheckError(error)
    return result.stdout


def resolve_commit(repo: Path, ref: str) -> str:
    output = _git(
        repo,
        ["rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}"],
        "invalid_ref",
    )
    try:
        commit = output.decode("ascii").strip()
    except UnicodeDecodeError:
        raise AssetCheckError("invalid_ref") from None
    if len(commit) != 40 or any(character not in "0123456789abcdef" for character in commit):
        raise AssetCheckError("invalid_ref")
    return commit


def _load_pubspec(source: bytes) -> dict:
    try:
        import yaml
    except ImportError:
        raise AssetCheckError("yaml_dependency_missing") from None
    class UniqueKeyLoader(yaml.SafeLoader):
        pass

    def construct_mapping(loader, node, deep=False):
        result = {}
        for key_node, value_node in node.value:
            key = loader.construct_object(key_node, deep=deep)
            if not isinstance(key, str) or key in result:
                raise yaml.YAMLError("invalid mapping key")
            result[key] = loader.construct_object(value_node, deep=deep)
        return result

    UniqueKeyLoader.add_constructor(
        yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping
    )
    try:
        data = yaml.load(source.decode("utf-8"), Loader=UniqueKeyLoader)
    except (UnicodeDecodeError, yaml.YAMLError):
        raise AssetCheckError("invalid_pubspec") from None
    if not isinstance(data, dict):
        raise AssetCheckError("invalid_pubspec")
    return data


def _path(value: object, *, allow_directory: bool) -> tuple[str, bool]:
    if not isinstance(value, str) or not value:
        raise AssetCheckError("unsupported_declaration")
    is_directory = value.endswith("/")
    if is_directory and not allow_directory:
        raise AssetCheckError("unsupported_declaration")
    parts = value.split("/")
    useful_parts = parts[:-1] if is_directory else parts
    if (
        not useful_parts
        or any(not part or part in {".", ".."} or "\\" in part or ":" in part for part in useful_parts)
        or value.startswith("/")
    ):
        raise AssetCheckError("invalid_asset_path")
    return value, is_directory


def declarations(pubspec: dict) -> tuple[list[tuple[str, bool]], list[str]]:
    flutter = pubspec.get("flutter", {})
    if not isinstance(flutter, dict):
        raise AssetCheckError("unsupported_declaration")

    assets_value = flutter.get("assets", [])
    if not isinstance(assets_value, list):
        raise AssetCheckError("unsupported_declaration")
    assets = [_path(item, allow_directory=True) for item in assets_value]

    fonts_value = flutter.get("fonts", [])
    if not isinstance(fonts_value, list):
        raise AssetCheckError("unsupported_declaration")
    font_files = []
    for family in fonts_value:
        if not isinstance(family, dict) or not isinstance(family.get("fonts"), list):
            raise AssetCheckError("unsupported_declaration")
        for variant in family["fonts"]:
            if not isinstance(variant, dict) or "asset" not in variant:
                raise AssetCheckError("unsupported_declaration")
            path, is_directory = _path(variant["asset"], allow_directory=False)
            if is_directory:
                raise AssetCheckError("unsupported_declaration")
            font_files.append(path)
    return assets, font_files


def committed_regular_files(repo: Path, commit: str) -> set[str]:
    output = _git(repo, ["ls-tree", "-r", "-z", "--full-tree", commit], "invalid_tree")
    files = set()
    try:
        entries = output.split(b"\0")
        for entry in entries:
            if not entry:
                continue
            metadata, raw_path = entry.split(b"\t", 1)
            mode, kind, _object_id = metadata.split(b" ", 2)
            if kind == b"blob" and mode in {b"100644", b"100755"}:
                files.add(raw_path.decode("utf-8"))
    except (UnicodeDecodeError, ValueError):
        raise AssetCheckError("invalid_tree") from None
    return files


def missing_declarations(
    assets: list[tuple[str, bool]], font_files: list[str], regular_files: set[str]
) -> list[str]:
    missing = []
    for path, is_directory in assets:
        if is_directory:
            prefix = path
            present = any(
                candidate.startswith(prefix) and "/" not in candidate[len(prefix):]
                for candidate in regular_files
            )
        else:
            present = path in regular_files
        if not present:
            missing.append(path)
    missing.extend(path for path in font_files if path not in regular_files)
    return sorted(set(missing))


def check(repo: Path, ref: str) -> dict:
    commit = resolve_commit(repo, ref)
    pubspec = _load_pubspec(_git(repo, ["show", f"{commit}:pubspec.yaml"], "invalid_pubspec"))
    assets, font_files = declarations(pubspec)
    missing = missing_declarations(assets, font_files, committed_regular_files(repo, commit))
    return {
        "assetDeclarations": len(assets),
        "commit": commit,
        "declarationPresence": "present" if not missing else "missing",
        "fontFiles": len(font_files),
        "missingPaths": missing,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="local Git repository")
    parser.add_argument("--ref", default="HEAD", help="commit-ish resolved once before reading")
    args = parser.parse_args(argv)
    try:
        result = check(args.repo, args.ref)
    except AssetCheckError as error:
        print(f"error[{error}]", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 1 if result["missingPaths"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
