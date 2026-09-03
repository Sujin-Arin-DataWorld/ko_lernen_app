"""Offline verification before installing/executing release tools.

Usage:
  python tool/release_integrity.py manifest
  python tool/release_integrity.py binary ffmpeg-linux-x64 DOWNLOAD_PATH
  python tool/release_integrity.py actions WORKFLOW.yml [WORKFLOW.yml ...]

The actions command requires PyYAML 6.0.2 (CI wiring must install it explicitly).
Nothing is downloaded, installed or executed by this verifier. A trusted caller
must stop on a nonzero exit code, then use the very same verified file. The
manifest is reviewed source, not input to accept from an untrusted download.
The caller must keep that file in private staging until installation: this
read-only check detects drift during verification, not replacement afterward.
Workflow wiring is deliberately separate from this helper.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys


MANIFEST = Path(__file__).with_name("release_toolchain.json")
SHA40 = re.compile(r"[0-9a-f]{40}")
SHA256 = re.compile(r"[0-9a-f]{64}")
REPOSITORY = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
VERSION = re.compile(r"v[0-9]+(?:\.[0-9]+)*")
BINARY_BASE = "https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1/"
MAX_WORKFLOW_BYTES = 1024 * 1024
MAX_YAML_DEPTH = 64
MAX_YAML_TOKENS = 100_000


class IntegrityError(Exception):
    """A safe, fixed diagnostic code, never underlying input or exception text."""


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise IntegrityError("invalid_manifest")
        result[key] = value
    return result


def load_manifest(path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    except (OSError, UnicodeError, ValueError):
        raise IntegrityError("invalid_manifest") from None
    if (
        not isinstance(data, dict)
        or set(data) != {"schemaVersion", "actions", "binaries"}
        or type(data["schemaVersion"]) is not int
        or data["schemaVersion"] != 1
        or not isinstance(data["actions"], dict)
        or not data["actions"]
        or not isinstance(data["binaries"], dict)
        or not data["binaries"]
    ):
        raise IntegrityError("invalid_manifest")
    for repository, entry in data["actions"].items():
        if (
            not REPOSITORY.fullmatch(repository)
            or not isinstance(entry, dict)
            or set(entry) != {"version", "sha"}
            or not isinstance(entry["version"], str)
            or not VERSION.fullmatch(entry["version"])
            or not isinstance(entry["sha"], str)
            or not SHA40.fullmatch(entry["sha"])
        ):
            raise IntegrityError("invalid_manifest")
    for name, entry in data["binaries"].items():
        if (
            name not in {"ffmpeg-linux-x64", "ffprobe-linux-x64"}
            or not isinstance(entry, dict)
            or set(entry) != {"url", "sha256"}
            or entry["url"] != BINARY_BASE + name
            or not isinstance(entry["sha256"], str)
            or not SHA256.fullmatch(entry["sha256"])
        ):
            raise IntegrityError("invalid_manifest")
    return data


def _regular_file_identity(info):
    if not stat.S_ISREG(info.st_mode):
        raise IntegrityError("binary_unavailable")
    return (info.st_dev, info.st_ino, info.st_mode, info.st_size,
            info.st_mtime_ns, info.st_ctime_ns)


def _hash_regular_binary(path):
    # Do not bless a link or directory that can resolve to different bytes.
    before = _regular_file_identity(path.lstat())
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as stream:
        opened = _regular_file_identity(os.fstat(stream.fileno()))
        # On Windows, path stat and descriptor fstat have different ctime
        # semantics. Compare ctime within each API, not across the two APIs.
        if opened[:-1] != before[:-1]:
            raise IntegrityError("binary_changed")
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            size += len(chunk)
            digest.update(chunk)
        after_read = _regular_file_identity(os.fstat(stream.fileno()))
    # A replaced/removed path must not inherit the old descriptor's hash.
    after_path = _regular_file_identity(path.lstat())
    if opened != after_read or before != after_path or size != before[3]:
        raise IntegrityError("binary_changed")
    return digest.hexdigest(), size, after_path


def verify_binary(manifest, name, path):
    if name not in manifest["binaries"]:
        raise IntegrityError("unknown_binary")
    try:
        first = _hash_regular_binary(path)
        actual, size, _ = first
        if size == 0:
            raise IntegrityError("empty_binary")
        if actual != manifest["binaries"][name]["sha256"]:
            raise IntegrityError("checksum_mismatch")
        # A fresh read also catches same-size edits within one filesystem
        # timestamp tick. Neither pass promises immutability after return.
        if _hash_regular_binary(path) != first:
            raise IntegrityError("binary_changed")
    except OSError:
        raise IntegrityError("binary_unavailable") from None
    return {"binary": name, "sha256": actual, "bytes": size}


def verify_action(manifest, reference, version_comment):
    if not isinstance(reference, str):
        raise IntegrityError("invalid_workflow")
    repository, separator, sha = reference.partition("@")
    if not separator or not SHA40.fullmatch(sha):
        raise IntegrityError("mutable_action")
    pin = manifest["actions"].get(repository)
    if pin is None or sha != pin["sha"]:
        raise IntegrityError("unreviewed_action")
    if version_comment != pin["version"]:
        raise IntegrityError("version_comment_mismatch")


def verify_workflow(manifest, path):
    try:
        import yaml
    except ImportError:
        raise IntegrityError("yaml_dependency_missing") from None
    try:
        with path.open("rb") as stream:
            encoded = stream.read(MAX_WORKFLOW_BYTES + 1)
        if len(encoded) > MAX_WORKFLOW_BYTES:
            raise IntegrityError("invalid_workflow")
        source = encoded.decode("utf-8")
        # GitHub workflow aliases/merges must not hide an unchecked invocation.
        # Reject these explicitly rather than evaluating a shared mapping twice.
        starts = (yaml.tokens.BlockMappingStartToken, yaml.tokens.BlockSequenceStartToken,
                  yaml.tokens.FlowMappingStartToken, yaml.tokens.FlowSequenceStartToken)
        ends = (yaml.tokens.BlockEndToken, yaml.tokens.FlowMappingEndToken,
                yaml.tokens.FlowSequenceEndToken)
        depth = 0
        for count, token in enumerate(yaml.scan(source), start=1):
            if count > MAX_YAML_TOKENS or isinstance(token, yaml.tokens.AliasToken):
                raise IntegrityError("invalid_workflow")
            if isinstance(token, starts):
                depth += 1
            elif isinstance(token, ends):
                depth -= 1
            if not 0 <= depth <= MAX_YAML_DEPTH:
                raise IntegrityError("invalid_workflow")
        tree = yaml.compose(source, Loader=yaml.SafeLoader)
    except (OSError, UnicodeError, yaml.YAMLError, RecursionError):
        raise IntegrityError("invalid_workflow") from None

    def mapping(node):
        if not isinstance(node, yaml.MappingNode):
            raise IntegrityError("invalid_workflow")
        result = {}
        for key, value in node.value:
            if not isinstance(key, yaml.ScalarNode) or key.value in result or key.value == "<<":
                raise IntegrityError("invalid_workflow")
            result[key.value] = value
        return result

    def validate_keys(node):
        if isinstance(node, yaml.MappingNode):
            for value in mapping(node).values():
                validate_keys(value)
        elif isinstance(node, yaml.SequenceNode):
            for value in node.value:
                validate_keys(value)

    try:
        validate_keys(tree)
    except RecursionError:
        raise IntegrityError("invalid_workflow") from None
    root = mapping(tree)
    jobs = mapping(root.get("jobs"))
    lines = source.splitlines()
    checked = 0

    def check_use(node):
        if (
            not isinstance(node, yaml.ScalarNode)
            or node.tag != "tag:yaml.org,2002:str"
            or node.start_mark.line != node.end_mark.line
        ):
            raise IntegrityError("invalid_workflow")
        # A version belongs to the actual scalar, not a nearby step's comment.
        tail = lines[node.end_mark.line][node.end_mark.column:]
        comment = tail.partition("#")[2].strip()
        verify_action(manifest, node.value, comment)

    for job in jobs.values():
        fields = mapping(job)
        if "uses" in fields:
            check_use(fields["uses"])
            checked += 1
        if "steps" in fields:
            if not isinstance(fields["steps"], yaml.SequenceNode):
                raise IntegrityError("invalid_workflow")
            for step in fields["steps"].value:
                item = mapping(step)
                if "uses" in item:
                    check_use(item["uses"])
                    checked += 1
    if checked == 0:
        raise IntegrityError("invalid_workflow")
    return checked


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("manifest")
    binary = commands.add_parser("binary")
    binary.add_argument("name")
    binary.add_argument("path", type=Path)
    actions = commands.add_parser("actions")
    actions.add_argument("workflows", nargs="+", type=Path)
    args = parser.parse_args(argv)
    try:
        manifest = load_manifest(args.manifest)
        if args.command == "binary":
            result = verify_binary(manifest, args.name, args.path)
        elif args.command == "actions":
            result = {"actionsChecked": sum(verify_workflow(manifest, path) for path in args.workflows)}
        else:
            result = {"schemaVersion": manifest["schemaVersion"], "verified": True}
    except IntegrityError as error:
        print(f"error[{error}]", file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
