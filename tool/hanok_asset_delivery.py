#!/usr/bin/env python3
"""Reproducible, fail-closed tooling for hybrid Hanok artwork delivery.

This module never uploads or deploys anything.  Normal commands write only the
checked-in manifest or ignored review artifacts.  ``activate`` is the sole
command that can replace pubspec.yaml, and it does so only after current-source,
local-byte, worktree, fingerprint, and fresh remote-byte verification.
"""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any, Callable, Iterable
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import HTTPRedirectHandler, Request, build_opener


SCHEMA_VERSION = 1
STORAGE_BUCKET = "ko-lernen-app.firebasestorage.app"
STORAGE_PREFIX = "learning-art/v1/"
FIREBASE_MEDIA_ORIGIN = "https://firebasestorage.googleapis.com"
MANIFEST_PATH = Path("assets/data/hanok_download_manifest.json")
CONSTRUCTION_CATALOG = Path("assets/data/ildu_construction_art_v1.json")
WORLD_CATALOG = Path("assets/data/ildu_world_manifest_v1.json")
TURNTABLE_CATALOG = Path("lib/data/ildu_turntable_catalog.dart")
PUBSPEC_PATH = Path("pubspec.yaml")
ART_ROOT = PurePosixPath("assets/illustrations/personal_hanok_v3")
MAX_DECLARED_ASSET_BYTES = 64 * 1024 * 1024
DEFAULT_REMOTE_TIMEOUT_SECONDS = 20.0

EXPECTED_CONSTRUCTION_IDS = {
    "hyeopmun",
    "changgo",
    "jungmunganchae",
    "araechae",
    "anchae",
    "anchae-store",
    "ansarangchae",
    "sadangmun",
    "sadang",
}
BUNDLED_CONSTRUCTION_IDS = {"hyeopmun"}

TURNTABLE_GROUPS = {
    "anchae": "anchae",
    "anchae_store": "anchae-store",
    "ansarangchae": "ansarangchae",
    "araechae": "araechae",
    "changgo": "changgo",
    "gokgan": "gokgan",
    "jungmunganchae": "jungmunganchae",
    "sadang": "sadang",
    "sadang_hyeopmun": "hyeopmun",
    "sadangmun": "sadangmun",
    "sotdaeulmun": "main-gate",
    "toilet": "toilet",
}

PACK_TITLES = {
    "anchae": {"ko": "안채", "en": "Anchae", "de": "Anchae"},
    "anchae-store": {
        "ko": "안채곳간채",
        "en": "Anchae storehouse",
        "de": "Speicher am Anchae",
    },
    "ansarangchae": {
        "ko": "안사랑채",
        "en": "Ansarangchae",
        "de": "Ansarangchae",
    },
    "araechae": {"ko": "아랫채", "en": "Araechae", "de": "Araechae"},
    "changgo": {
        "ko": "창고",
        "en": "Changgo · Storehouse",
        "de": "Changgo · Lagerhaus",
    },
    "gokgan": {"ko": "곳간채", "en": "Granary", "de": "Großes Speicherhaus"},
    "hyeopmun": {
        "ko": "협문",
        "en": "Hyeopmun · Side gate",
        "de": "Hyeopmun · Seitentor",
    },
    "jungmunganchae": {
        "ko": "중문채",
        "en": "Jungmunganchae",
        "de": "Jungmunganchae",
    },
    "main-gate": {"ko": "솟을대문", "en": "Main gate", "de": "Haupttor"},
    "sadang": {"ko": "사당", "en": "Sadang", "de": "Ahnenschrein"},
    "sadangmun": {"ko": "사당문", "en": "Sadangmun", "de": "Schreintor"},
    "toilet": {
        "ko": "화장실채",
        "en": "Service outhouses",
        "de": "Nebengebäude",
    },
    "world": {
        "ko": "일두고택 마당",
        "en": "Ildu Gotaek estate",
        "de": "Ildu-Gotaek-Anwesen",
    },
}

_HASH_RE = re.compile(r"^[0-9a-f]{64}$")
_PACK_ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
_FRAME_RE = re.compile(r"_frame\(\s*'([^']+)'", re.MULTILINE)
_FRAME_NAME_RE = re.compile(r"^ildu_(.+)_\d{2}_[^.]+\.png$")
_ASSET_ITEM_RE = re.compile(
    r"^(?P<indent>\s*)-\s+(?P<path>[^#\r\n]+?)(?P<comment>\s+#.*)?(?P<newline>\r?\n)?$"
)
_FONT_ASSET_RE = re.compile(r"^\s*-\s+asset:\s+([^#\r\n]+)")


class DeliveryError(RuntimeError):
    """Base exception for a refused or failed delivery operation."""


class ManifestError(DeliveryError):
    """The manifest or its source catalogs violate the fixed contract."""


class VerificationError(DeliveryError):
    """Local or remote bytes did not match the trusted manifest."""


class ActivationRefused(DeliveryError):
    """Activation safety preconditions were not satisfied."""


def _read_text_exact(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return handle.read()


def _json_file(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"Cannot read JSON source {path}: {error}") from error
    if not isinstance(value, dict):
        raise ManifestError(f"JSON source must contain an object: {path}")
    return value


def _json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _canonical_relative_path(value: str) -> str:
    if not isinstance(value, str) or not value:
        raise ManifestError("Asset path must be a non-empty string")
    if "\\" in value:
        raise ManifestError(f"Asset path must use forward slashes: {value!r}")
    path = PurePosixPath(value)
    if path.is_absolute() or any(part in {"", ".", ".."} for part in path.parts):
        raise ManifestError(f"Asset path is not canonical and relative: {value!r}")
    normalized = path.as_posix()
    if normalized != value:
        raise ManifestError(f"Asset path is not normalized: {value!r}")
    return normalized


def _content_type(path: str) -> str:
    suffix = PurePosixPath(path).suffix.lower()
    if suffix == ".png":
        return "image/png"
    if suffix == ".webp":
        return "image/webp"
    raise ManifestError(f"Only PNG and WebP artwork can be published: {path}")


def _asset_record(root: Path, relative: str) -> dict[str, Any]:
    relative = _canonical_relative_path(relative)
    source = root / Path(*PurePosixPath(relative).parts)
    if not source.is_file():
        raise ManifestError(f"Referenced artwork is missing: {relative}")
    length = source.stat().st_size
    if length <= 0 or length > MAX_DECLARED_ASSET_BYTES:
        raise ManifestError(f"Artwork size is outside the supported bound: {relative} ({length})")
    digest = _sha256_file(source).lower()
    extension = PurePosixPath(relative).suffix.lower().lstrip(".")
    return {
        "asset": relative,
        "sha256": digest,
        "bytes": length,
        "contentType": _content_type(relative),
        "storagePath": f"{STORAGE_PREFIX}{digest}.{extension}",
    }


def _world_asset_paths(catalog: dict[str, Any]) -> set[str]:
    names: set[str] = set()
    canvas = catalog.get("canvas")
    if not isinstance(canvas, dict) or not isinstance(canvas.get("asset"), str):
        raise ManifestError("World catalog canvas.asset is required")
    names.add(canvas["asset"])
    # Decorations resolve through assets/illustrations/decorations/, not the V3
    # world root, and remain bundled as shared/reward artwork.
    for section in ("gates", "buildings"):
        values = catalog.get(section)
        if not isinstance(values, list):
            raise ManifestError(f"World catalog {section} must be a list")
        for index, item in enumerate(values):
            if not isinstance(item, dict) or not isinstance(item.get("asset"), str):
                raise ManifestError(f"World catalog {section}[{index}].asset is required")
            names.add(item["asset"])
    return {
        (ART_ROOT / "world" / name).as_posix()
        for name in names
    }


def _turntable_assets(catalog_text: str) -> dict[str, set[str]]:
    file_names = _FRAME_RE.findall(catalog_text)
    if not file_names:
        raise ManifestError("No literal _frame(...) file names found in turntable catalog")
    grouped: dict[str, set[str]] = {}
    for file_name in file_names:
        match = _FRAME_NAME_RE.fullmatch(file_name)
        if not match:
            raise ManifestError(f"Unexpected literal turntable frame name: {file_name}")
        source_group = match.group(1)
        pack_id = TURNTABLE_GROUPS.get(source_group)
        if pack_id is None:
            raise ManifestError(f"Turntable group has no reviewed pack mapping: {source_group}")
        grouped.setdefault(pack_id, set()).add(
            (ART_ROOT / "turnarounds" / file_name).as_posix()
        )
    missing_groups = set(TURNTABLE_GROUPS.values()) - set(grouped)
    if missing_groups:
        raise ManifestError(
            "Turntable catalog is missing reviewed groups: " + ", ".join(sorted(missing_groups))
        )
    return grouped


def build_manifest(root: Path) -> dict[str, Any]:
    """Build schemaVersion 1 entirely from current catalogs and source bytes."""

    root = Path(root).resolve()
    construction = _json_file(root / CONSTRUCTION_CATALOG)
    series = construction.get("series")
    if not isinstance(series, list):
        raise ManifestError("Construction catalog series must be a list")
    by_id: dict[str, dict[str, Any]] = {}
    for item in series:
        if not isinstance(item, dict) or not isinstance(item.get("buildingId"), str):
            raise ManifestError("Every construction series requires buildingId")
        building_id = item["buildingId"]
        if building_id in by_id:
            raise ManifestError(f"Duplicate construction buildingId: {building_id}")
        by_id[building_id] = item
    if set(by_id) != EXPECTED_CONSTRUCTION_IDS:
        raise ManifestError(
            "Construction series changed outside the reviewed delivery set; expected "
            f"{sorted(EXPECTED_CONSTRUCTION_IDS)}, got {sorted(by_id)}"
        )

    pack_paths: dict[str, set[str]] = {}
    for building_id, item in by_id.items():
        if building_id in BUNDLED_CONSTRUCTION_IDS:
            continue
        stages = item.get("stages")
        if not isinstance(stages, list) or not stages:
            raise ManifestError(f"Construction series {building_id} has no stages")
        for index, stage in enumerate(stages):
            if not isinstance(stage, dict) or not isinstance(stage.get("asset"), str):
                raise ManifestError(
                    f"Construction series {building_id} stage {index} lacks asset"
                )
            pack_paths.setdefault(building_id, set()).add(stage["asset"])

    turntable_text = _read_text_exact(root / TURNTABLE_CATALOG)
    for pack_id, paths in _turntable_assets(turntable_text).items():
        pack_paths.setdefault(pack_id, set()).update(paths)

    pack_paths["world"] = _world_asset_paths(_json_file(root / WORLD_CATALOG))

    unknown_titles = set(pack_paths) - set(PACK_TITLES)
    if unknown_titles:
        raise ManifestError(f"Missing readable pack titles: {sorted(unknown_titles)}")

    source_owner: dict[str, str] = {}
    packs: list[dict[str, Any]] = []
    for pack_id in sorted(pack_paths):
        assets: list[dict[str, Any]] = []
        for relative in sorted(pack_paths[pack_id]):
            existing = source_owner.get(relative)
            if existing is not None and existing != pack_id:
                raise ManifestError(
                    f"Source path belongs to multiple packs: {relative} ({existing}, {pack_id})"
                )
            source_owner[relative] = pack_id
            assets.append(_asset_record(root, relative))
        if not assets:
            raise ManifestError(f"Pack is empty: {pack_id}")
        packs.append(
            {
                "id": pack_id,
                "title": dict(PACK_TITLES[pack_id]),
                "assets": assets,
            }
        )

    manifest = {
        "schemaVersion": SCHEMA_VERSION,
        "storageBucket": STORAGE_BUCKET,
        "packs": packs,
    }
    validate_manifest(manifest)
    return manifest


def validate_manifest(manifest: dict[str, Any]) -> None:
    """Validate the fixed JSON trust-root schema without touching local files."""

    if not isinstance(manifest, dict):
        raise ManifestError("Manifest must be an object")
    if set(manifest) != {"schemaVersion", "storageBucket", "packs"}:
        raise ManifestError("Manifest top-level keys must match schemaVersion/storageBucket/packs")
    if manifest["schemaVersion"] != SCHEMA_VERSION:
        raise ManifestError(f"Unsupported manifest schemaVersion: {manifest['schemaVersion']!r}")
    if manifest["storageBucket"] != STORAGE_BUCKET:
        raise ManifestError(f"Unexpected storageBucket: {manifest['storageBucket']!r}")
    packs = manifest["packs"]
    if not isinstance(packs, list) or not packs:
        raise ManifestError("Manifest packs must be a non-empty list")

    pack_ids: set[str] = set()
    source_paths: set[str] = set()
    objects: dict[str, tuple[str, int, str]] = {}
    for pack in packs:
        if not isinstance(pack, dict) or set(pack) != {"id", "title", "assets"}:
            raise ManifestError("Every pack must contain exactly id/title/assets")
        pack_id = pack["id"]
        if not isinstance(pack_id, str) or not _PACK_ID_RE.fullmatch(pack_id):
            raise ManifestError(f"Invalid pack id: {pack_id!r}")
        if pack_id in pack_ids:
            raise ManifestError(f"Duplicate pack id: {pack_id}")
        pack_ids.add(pack_id)
        title = pack["title"]
        if not isinstance(title, dict) or set(title) != {"ko", "en", "de"}:
            raise ManifestError(f"Pack {pack_id} title must contain exactly ko/en/de")
        if any(not isinstance(title[key], str) or not title[key].strip() for key in title):
            raise ManifestError(f"Pack {pack_id} title values must be non-empty strings")
        assets = pack["assets"]
        if not isinstance(assets, list) or not assets:
            raise ManifestError(f"Pack {pack_id} must contain at least one asset")
        for asset in assets:
            required = {"asset", "sha256", "bytes", "contentType", "storagePath"}
            if not isinstance(asset, dict) or set(asset) != required:
                raise ManifestError(f"Pack {pack_id} has an asset with unexpected keys")
            source = _canonical_relative_path(asset["asset"])
            if not source.startswith(ART_ROOT.as_posix() + "/"):
                raise ManifestError(f"Asset is outside the canonical Hanok root: {source}")
            if source in source_paths:
                raise ManifestError(f"Duplicate source path: {source}")
            source_paths.add(source)
            digest = asset["sha256"]
            if not isinstance(digest, str) or not _HASH_RE.fullmatch(digest):
                raise ManifestError(f"Invalid lowercase SHA-256 for {source}")
            length = asset["bytes"]
            if (
                isinstance(length, bool)
                or not isinstance(length, int)
                or length <= 0
                or length > MAX_DECLARED_ASSET_BYTES
            ):
                raise ManifestError(f"Invalid byte length for {source}: {length!r}")
            content_type = _content_type(source)
            if asset["contentType"] != content_type:
                raise ManifestError(f"Invalid contentType for {source}")
            extension = PurePosixPath(source).suffix.lower().lstrip(".")
            expected_storage = f"{STORAGE_PREFIX}{digest}.{extension}"
            if asset["storagePath"] != expected_storage:
                raise ManifestError(f"Invalid immutable storagePath for {source}")
            signature = (digest, length, content_type)
            previous = objects.setdefault(expected_storage, signature)
            if previous != signature:
                raise ManifestError(f"Conflicting declarations for {expected_storage}")


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = _json_file(path)
    validate_manifest(manifest)
    return manifest


def iter_assets(manifest: dict[str, Any]) -> Iterable[tuple[str, dict[str, Any]]]:
    validate_manifest(manifest)
    for pack in manifest["packs"]:
        for asset in pack["assets"]:
            yield pack["id"], asset


def verify_local_assets(root: Path, manifest: dict[str, Any]) -> dict[str, int]:
    """Verify every declared local source length and digest exactly."""

    root = Path(root).resolve()
    count = 0
    total = 0
    for _pack_id, asset in iter_assets(manifest):
        source = root / Path(*PurePosixPath(asset["asset"]).parts)
        if not source.is_file():
            raise VerificationError(f"Local source is missing: {asset['asset']}")
        actual_length = source.stat().st_size
        if actual_length != asset["bytes"]:
            raise VerificationError(
                f"Local length mismatch for {asset['asset']}: "
                f"expected {asset['bytes']}, got {actual_length}"
            )
        actual_digest = _sha256_file(source)
        if actual_digest != asset["sha256"]:
            raise VerificationError(
                f"Local SHA-256 mismatch for {asset['asset']}: "
                f"expected {asset['sha256']}, got {actual_digest}"
            )
        count += 1
        total += actual_length
    return {"assetCount": count, "bytes": total}


def verify_manifest_current(root: Path, manifest: dict[str, Any]) -> None:
    """Reject a manifest that is not the deterministic current-source result."""

    validate_manifest(manifest)
    expected = build_manifest(root)
    if manifest != expected:
        raise VerificationError(
            "Manifest is stale or non-canonical; regenerate it from the current catalogs and bytes"
        )


def firebase_media_url(storage_path: str) -> str:
    if not isinstance(storage_path, str) or not storage_path.startswith(STORAGE_PREFIX):
        raise ManifestError(f"Unexpected Firebase storage path: {storage_path!r}")
    if ".." in PurePosixPath(storage_path).parts or "\\" in storage_path:
        raise ManifestError(f"Unsafe Firebase storage path: {storage_path!r}")
    encoded = quote(storage_path, safe="")
    return f"{FIREBASE_MEDIA_ORIGIN}/v0/b/{STORAGE_BUCKET}/o/{encoded}?alt=media"


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):  # noqa: ANN001
        return None


def _validate_app_check_token(token: str | None) -> None:
    if token is not None and (not token or not re.fullmatch(r"[\x21-\x7e]+", token)):
        raise VerificationError("App Check token must be nonempty printable ASCII without whitespace")


def _app_check_token_from_env(name: str | None) -> str | None:
    if name is None:
        return None
    token = os.environ.get(name)
    if token is None:
        raise VerificationError("The requested App Check token environment variable is unset")
    _validate_app_check_token(token)
    return token


def _open_remote(url: str, timeout: float, app_check_token: str | None = None):
    headers = {"Accept": "application/octet-stream"}
    if app_check_token is not None:
        headers["X-Firebase-AppCheck"] = app_check_token
    request = Request(url, headers=headers, method="GET")
    return build_opener(_NoRedirect).open(request, timeout=timeout)


def _unique_objects(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    objects: dict[str, dict[str, Any]] = {}
    for _pack_id, asset in iter_assets(manifest):
        existing = objects.setdefault(asset["storagePath"], asset)
        if (
            existing["sha256"] != asset["sha256"]
            or existing["bytes"] != asset["bytes"]
            or existing["contentType"] != asset["contentType"]
        ):
            raise ManifestError(f"Conflicting immutable object: {asset['storagePath']}")
    return [objects[key] for key in sorted(objects)]


def _check_deadline(deadline: float) -> None:
    if time.monotonic() >= deadline:
        raise VerificationError("Remote object exceeded the total verification deadline")


def _read_bounded(response: Any, expected_length: int, *, deadline: float) -> bytes:
    chunks: list[bytes] = []
    remaining = expected_length + 1
    # HTTPResponse.read1 returns after one underlying read. read(size) may wait
    # for the entire size while a peer trickles bytes, bypassing a socket timeout.
    read_chunk = getattr(response, "read1", response.read)
    while remaining > 0:
        _check_deadline(deadline)
        chunk = read_chunk(min(64 * 1024, remaining))
        _check_deadline(deadline)
        if not chunk:
            break
        if not isinstance(chunk, (bytes, bytearray)):
            raise VerificationError("Remote response returned non-byte content")
        chunks.append(bytes(chunk))
        remaining -= len(chunk)
    payload = b"".join(chunks)
    if len(payload) != expected_length:
        relation = "oversized" if len(payload) > expected_length else "truncated"
        raise VerificationError(
            f"Remote object is {relation}: expected {expected_length}, got {len(payload)}"
        )
    return payload


def verify_remote_assets(
    manifest: dict[str, Any],
    *,
    open_url: Callable[[str, float], Any] | None = None,
    timeout: float = DEFAULT_REMOTE_TIMEOUT_SECONDS,
    app_check_token: str | None = None,
) -> dict[str, int]:
    """Fetch and verify every unique object from the one fixed media endpoint."""

    validate_manifest(manifest)
    if not math.isfinite(timeout) or timeout <= 0 or timeout > 60:
        raise VerificationError("Remote timeout must be greater than zero and at most 60 seconds")
    _validate_app_check_token(app_check_token)
    opener = open_url or (lambda url, duration: _open_remote(url, duration, app_check_token))
    objects = _unique_objects(manifest)
    total = 0
    for asset in objects:
        expected_url = firebase_media_url(asset["storagePath"])
        deadline = time.monotonic() + timeout
        try:
            response = opener(expected_url, timeout)
            manager = response if hasattr(response, "__enter__") else contextlib.closing(response)
            with manager as opened:
                _check_deadline(deadline)
                status = getattr(opened, "status", None)
                if status is None and hasattr(opened, "getcode"):
                    status = opened.getcode()
                if status != 200:
                    raise VerificationError(
                        f"Remote object returned HTTP {status}: {asset['storagePath']}"
                    )
                final_url = opened.geturl() if hasattr(opened, "geturl") else None
                if final_url != expected_url:
                    raise VerificationError(
                        f"Remote redirect/origin change rejected for {asset['storagePath']}"
                    )
                headers = getattr(opened, "headers", {})
                declared = headers.get("Content-Length") if hasattr(headers, "get") else None
                if declared is not None:
                    try:
                        declared_length = int(declared)
                    except (TypeError, ValueError) as error:
                        raise VerificationError(
                            f"Invalid remote Content-Length for {asset['storagePath']}"
                        ) from error
                    if declared_length != asset["bytes"]:
                        raise VerificationError(
                            f"Remote Content-Length mismatch for {asset['storagePath']}: "
                            f"expected {asset['bytes']}, got {declared_length}"
                        )
                payload = _read_bounded(opened, asset["bytes"], deadline=deadline)
        except VerificationError:
            raise
        except (HTTPError, URLError, OSError, TimeoutError) as error:
            raise VerificationError(
                f"Remote object could not be verified: {asset['storagePath']} ({type(error).__name__})"
            ) from error
        digest = _sha256_bytes(payload)
        if digest != asset["sha256"]:
            raise VerificationError(
                f"Remote SHA-256 mismatch for {asset['storagePath']}: "
                f"expected {asset['sha256']}, got {digest}"
            )
        total += len(payload)
    return {"objectCount": len(objects), "bytes": total}


def _asset_block(lines: list[str]) -> tuple[int, int, int]:
    start = -1
    base_indent = -1
    for index, line in enumerate(lines):
        without_newline = line.rstrip("\r\n")
        match = re.fullmatch(r"(\s*)assets:\s*(?:#.*)?", without_newline)
        if match:
            start = index
            base_indent = len(match.group(1))
            break
    if start < 0:
        raise DeliveryError("pubspec.yaml does not contain an assets block")
    end = len(lines)
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(lines[index]) - len(lines[index].lstrip())
        if indent <= base_indent:
            end = index
            break
    return start, end, base_indent


def _manifest_source_paths(manifest: dict[str, Any]) -> set[str]:
    return {asset["asset"] for _pack_id, asset in iter_assets(manifest)}


def hybrid_pubspec(root: Path, manifest: dict[str, Any]) -> str:
    """Return a candidate pubspec excluding exactly manifest-owned artwork.

    Affected directory entries are expanded to explicit retained siblings.  The
    source pubspec and artwork are not modified.
    """

    root = Path(root).resolve()
    validate_manifest(manifest)
    deferred = _manifest_source_paths(manifest)
    source_text = _read_text_exact(root / PUBSPEC_PATH)
    lines = source_text.splitlines(keepends=True)
    _start, end, _base_indent = _asset_block(lines)
    newline = "\r\n" if "\r\n" in source_text else "\n"
    output: list[str] = []
    for index, line in enumerate(lines):
        if index >= end:
            output.append(line)
            continue
        match = _ASSET_ITEM_RE.fullmatch(line)
        if match is None:
            output.append(line)
            continue
        entry = match.group("path").strip()
        indent = match.group("indent")
        comment = match.group("comment")
        entry_newline = match.group("newline") or newline
        if entry in deferred:
            if comment:
                output.append(f"{indent}{comment.strip()}{entry_newline}")
            continue
        affected = entry.endswith("/") and any(path.startswith(entry) for path in deferred)
        if not affected:
            output.append(line)
            continue
        directory = root / Path(*PurePosixPath(entry).parts)
        if not directory.is_dir():
            raise DeliveryError(f"Affected pubspec asset directory is missing: {entry}")
        retained = []
        for child in directory.iterdir():
            if not child.is_file():
                continue
            relative = child.relative_to(root).as_posix()
            if relative not in deferred:
                retained.append(relative)
        if comment:
            output.append(f"{indent}{comment.strip()}{entry_newline}")
        for relative in sorted(retained):
            output.append(f"{indent}- {relative}{entry_newline}")
    candidate = "".join(output)
    before = pubspec_asset_paths(root, source_text)
    after = pubspec_asset_paths(root, candidate)
    removed = before - after
    added = after - before
    if removed != deferred:
        missing = sorted(deferred - removed)
        extra = sorted(removed - deferred)
        raise DeliveryError(
            f"Candidate pubspec exclusion is not exact; unremoved={missing}, extraRemoved={extra}"
        )
    if added:
        raise DeliveryError(f"Candidate pubspec unexpectedly adds assets: {sorted(added)}")
    return candidate


def _pubspec_entries(text: str) -> list[str]:
    lines = text.splitlines(keepends=True)
    start, end, _base_indent = _asset_block(lines)
    entries: list[str] = []
    for line in lines[start + 1 : end]:
        match = _ASSET_ITEM_RE.fullmatch(line)
        if match is not None:
            entries.append(match.group("path").strip())
    return entries


def pubspec_asset_paths(root: Path, text: str) -> set[str]:
    """Expand the asset block with Flutter's non-recursive directory semantics."""

    root = Path(root).resolve()
    paths: set[str] = set()
    for entry in _pubspec_entries(text):
        local = root / Path(*PurePosixPath(entry).parts)
        if entry.endswith("/"):
            if not local.is_dir():
                raise DeliveryError(f"pubspec asset directory is missing: {entry}")
            for child in local.iterdir():
                if child.is_file():
                    paths.add(child.relative_to(root).as_posix())
        else:
            if not local.is_file():
                raise DeliveryError(f"pubspec asset file is missing: {entry}")
            paths.add(PurePosixPath(entry).as_posix())
    return paths


def pubspec_font_paths(root: Path, text: str) -> set[str]:
    """Return font files registered by ``flutter.fonts`` entries."""

    root = Path(root).resolve()
    paths: set[str] = set()
    for line in text.splitlines():
        match = _FONT_ASSET_RE.fullmatch(line)
        if match is None:
            continue
        relative = PurePosixPath(match.group(1).strip()).as_posix()
        local = root / Path(*PurePosixPath(relative).parts)
        if not local.is_file():
            raise DeliveryError(f"pubspec font file is missing: {relative}")
        paths.add(relative)
    return paths


def _sum_paths(root: Path, paths: Iterable[str]) -> int:
    return sum((root / Path(*PurePosixPath(path).parts)).stat().st_size for path in paths)


def retained_strays(root: Path, manifest: dict[str, Any]) -> dict[str, list[str]]:
    """List unreferenced siblings retained while affected directories expand."""

    root = Path(root).resolve()
    deferred = _manifest_source_paths(manifest)
    parents = {PurePosixPath(path).parent for path in deferred}
    image: list[str] = []
    nonimage: list[str] = []
    for parent in sorted(parents, key=lambda value: value.as_posix()):
        directory = root / Path(*parent.parts)
        for child in sorted(directory.iterdir(), key=lambda value: value.name):
            if not child.is_file():
                continue
            relative = child.relative_to(root).as_posix()
            if relative in deferred:
                continue
            target = image if child.suffix.lower() in {".png", ".webp"} else nonimage
            target.append(relative)
    return {"unreferencedImagesRetained": image, "nonImageFilesRetained": nonimage}


def packaging_report(root: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    root = Path(root).resolve()
    verify_manifest_current(root, manifest)
    local = verify_local_assets(root, manifest)
    before_text = _read_text_exact(root / PUBSPEC_PATH)
    candidate = hybrid_pubspec(root, manifest)
    before = pubspec_asset_paths(root, before_text)
    after = pubspec_asset_paths(root, candidate)
    fonts = pubspec_font_paths(root, before_text)
    removed = before - after
    deferred = _manifest_source_paths(manifest)
    if removed != deferred:
        raise DeliveryError("Packaging report detected an inexact candidate exclusion")
    unique_objects = _unique_objects(manifest)
    starter_prefixes = (
        "assets/illustrations/personal_hanok_v3/sarangchae/",
        "assets/illustrations/personal_hanok_v3/construction/hyeopmun/",
        "assets/illustrations/personal_hanok_v3/construction/lessons/",
    )
    starter_paths = sorted(
        path for path in before if any(path.startswith(prefix) for prefix in starter_prefixes)
    )
    missing_starters = [path for path in starter_paths if path not in after]
    if missing_starters:
        raise DeliveryError(f"Candidate removes bundled starter/shared art: {missing_starters}")
    return {
        "schemaVersion": SCHEMA_VERSION,
        "manifestSha256": _sha256_bytes(_json_text(manifest).encode("utf-8")),
        "inputPubspecSha256": _sha256_file(root / PUBSPEC_PATH),
        "candidatePubspecSha256": _sha256_bytes(candidate.encode("utf-8")),
        "manifestAssetCount": local["assetCount"],
        "manifestAssetBytes": local["bytes"],
        "uniqueRemoteObjectCount": len(unique_objects),
        "uniqueRemoteObjectBytes": sum(asset["bytes"] for asset in unique_objects),
        "beforeBundledAssetCount": len(before),
        "beforeBundledRawBytes": _sum_paths(root, before),
        "afterBundledAssetCount": len(after),
        "afterBundledRawBytes": _sum_paths(root, after),
        "fontFileCount": len(fonts),
        "fontRawBytes": _sum_paths(root, fonts),
        "beforeProjectAssetAndFontCount": len(before | fonts),
        "beforeProjectAssetAndFontRawBytes": _sum_paths(root, before | fonts),
        "afterProjectAssetAndFontCount": len(after | fonts),
        "afterProjectAssetAndFontRawBytes": _sum_paths(root, after | fonts),
        "removedFromBundleCount": len(removed),
        "removedFromBundleRawBytes": _sum_paths(root, removed),
        "bundledStarterAndSharedCount": len(starter_paths),
        "bundledStarterAndSharedBytes": _sum_paths(root, starter_paths),
        "candidateExcludesExactlyManifest": removed == deferred,
        **retained_strays(root, manifest),
    }


def write_review_report(root: Path, manifest: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    output_dir.mkdir(parents=True, exist_ok=True)
    candidate = hybrid_pubspec(root, manifest)
    report = packaging_report(root, manifest)
    (output_dir / "candidate-pubspec.yaml").write_text(candidate, encoding="utf-8", newline="")
    (output_dir / "asset-report.json").write_text(
        _json_text(report), encoding="utf-8", newline="\n"
    )
    return report


def stage_upload_objects(root: Path, manifest: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    """Copy immutable objects and metadata locally; perform no network mutation."""

    root = Path(root).resolve()
    verify_manifest_current(root, manifest)
    verify_local_assets(root, manifest)
    staging = output_dir / "staging"
    object_root = staging / "objects"
    metadata_entries: list[dict[str, Any]] = []
    by_storage: dict[str, list[str]] = {}
    source_for_storage: dict[str, dict[str, Any]] = {}
    for _pack_id, asset in iter_assets(manifest):
        by_storage.setdefault(asset["storagePath"], []).append(asset["asset"])
        source_for_storage.setdefault(asset["storagePath"], asset)
    for storage_path in sorted(by_storage):
        asset = source_for_storage[storage_path]
        destination = object_root / Path(*PurePosixPath(storage_path).parts)
        destination.parent.mkdir(parents=True, exist_ok=True)
        source = root / Path(*PurePosixPath(asset["asset"]).parts)
        shutil.copyfile(source, destination)
        if destination.stat().st_size != asset["bytes"] or _sha256_file(destination) != asset["sha256"]:
            raise VerificationError(f"Staged object copy failed verification: {storage_path}")
        metadata_entries.append(
            {
                "storagePath": storage_path,
                "sha256": asset["sha256"],
                "bytes": asset["bytes"],
                "contentType": asset["contentType"],
                "customMetadata": {"canonical": "true"},
                "sourceAssets": sorted(by_storage[storage_path]),
            }
        )
    metadata = {
        "schemaVersion": SCHEMA_VERSION,
        "storageBucket": STORAGE_BUCKET,
        "manifestSha256": _sha256_bytes(_json_text(manifest).encode("utf-8")),
        "objects": metadata_entries,
    }
    staging.mkdir(parents=True, exist_ok=True)
    (staging / "metadata.json").write_text(_json_text(metadata), encoding="utf-8", newline="\n")
    instructions = (
        "# Hanok immutable upload staging\n\n"
        "This directory is a local, byte-verified staging area. It does not upload or deploy anything.\n"
        "A separately approved publisher must upload each file below `objects/` to the matching\n"
        f"path in `{STORAGE_BUCKET}`, preserve `contentType`, and set custom metadata\n"
        "`canonical=true`. After publishing, run the tool's `verify-remote` command. Only an\n"
        "explicit `activate` command with the recorded pubspec SHA-256 can change packaging.\n"
    )
    (staging / "PUBLISHING_INSTRUCTIONS.md").write_text(
        instructions, encoding="utf-8", newline="\n"
    )
    return {
        "objectCount": len(metadata_entries),
        "bytes": sum(entry["bytes"] for entry in metadata_entries),
        "metadata": (staging / "metadata.json").as_posix(),
    }


def _git_output(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ActivationRefused(
            f"Git safety check failed ({' '.join(args)}): {result.stderr.strip()}"
        )
    return result.stdout.strip()


def ensure_non_main_worktree(root: Path) -> None:
    root = Path(root).resolve()
    if not (root / ".git").is_file():
        raise ActivationRefused("Activation requires a linked non-main Git worktree")
    top_level = Path(_git_output(root, "rev-parse", "--show-toplevel")).resolve()
    if top_level != root:
        raise ActivationRefused(f"Activation root is not the Git worktree root: {top_level}")
    branch = _git_output(root, "branch", "--show-current")
    if not branch:
        raise ActivationRefused("Activation is refused on a detached HEAD")
    if branch in {"main", "master"} or branch.endswith("/main"):
        raise ActivationRefused(f"Activation is refused on main branch: {branch}")


def _atomic_replace(path: Path, content: bytes, *, expected_sha256: str | None = None) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.hanok-delivery-", suffix=".tmp", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        if expected_sha256 is not None and _sha256_file(path) != expected_sha256:
            raise ActivationRefused("pubspec.yaml changed during activation; original file preserved")
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def activate(
    root: Path,
    manifest: dict[str, Any],
    *,
    expected_pubspec_sha256: str,
    output_dir: Path,
    open_url: Callable[[str, float], Any] | None = None,
    timeout: float = DEFAULT_REMOTE_TIMEOUT_SECONDS,
    app_check_token: str | None = None,
) -> dict[str, Any]:
    """Atomically activate hybrid packaging after every fail-closed gate passes."""

    root = Path(root).resolve()
    ensure_non_main_worktree(root)
    verify_manifest_current(root, manifest)
    if load_manifest(root / MANIFEST_PATH) != manifest:
        raise ActivationRefused("The shipped manifest differs from the verified manifest")
    local_summary = verify_local_assets(root, manifest)
    pubspec = root / PUBSPEC_PATH
    original_bytes = pubspec.read_bytes()
    actual_pubspec_sha256 = _sha256_bytes(original_bytes)
    if not _HASH_RE.fullmatch(expected_pubspec_sha256):
        raise ActivationRefused("Expected pubspec fingerprint must be 64 lowercase hex characters")
    if actual_pubspec_sha256 != expected_pubspec_sha256:
        raise ActivationRefused(
            "pubspec.yaml fingerprint changed; regenerate and review the candidate before activation"
        )
    candidate_text = hybrid_pubspec(root, manifest)
    candidate_bytes = candidate_text.encode("utf-8")
    report = packaging_report(root, manifest)
    if MANIFEST_PATH.as_posix() not in pubspec_asset_paths(root, candidate_text):
        raise ActivationRefused("The hybrid candidate does not bundle the verified manifest")
    remote_summary = verify_remote_assets(
        manifest, open_url=open_url, timeout=timeout, app_check_token=app_check_token
    )

    # Remote verification may take minutes. Recheck inputs and branch before
    # touching packaging so concurrent local work cannot be overwritten.
    ensure_non_main_worktree(root)
    verify_manifest_current(root, manifest)
    if load_manifest(root / MANIFEST_PATH) != manifest:
        raise ActivationRefused("The shipped manifest changed during remote verification")
    if _sha256_file(pubspec) != actual_pubspec_sha256:
        raise ActivationRefused("pubspec.yaml changed during remote verification; original file preserved")

    output_dir.mkdir(parents=True, exist_ok=True)
    backup = output_dir / "pubspec.full-bundle.yaml"
    candidate_path = output_dir / "candidate-pubspec.yaml"
    receipt_path = output_dir / "activation-receipt.json"
    backup.write_bytes(original_bytes)
    candidate_path.write_bytes(candidate_bytes)
    receipt = {
        "schemaVersion": SCHEMA_VERSION,
        "manifestSha256": report["manifestSha256"],
        "inputPubspecSha256": actual_pubspec_sha256,
        "candidatePubspecSha256": _sha256_bytes(candidate_bytes),
        "local": local_summary,
        "remote": remote_summary,
        "removedFromBundleCount": report["removedFromBundleCount"],
        "removedFromBundleRawBytes": report["removedFromBundleRawBytes"],
        "rollbackPubspec": backup.as_posix(),
    }
    receipt_path.write_text(_json_text(receipt), encoding="utf-8", newline="\n")
    _atomic_replace(pubspec, candidate_bytes, expected_sha256=actual_pubspec_sha256)
    if _sha256_file(pubspec) != receipt["candidatePubspecSha256"]:
        raise VerificationError("Atomic pubspec activation did not produce the reviewed candidate")
    return receipt


def _resolve(root: Path, value: str | None, default: Path) -> Path:
    path = Path(value) if value is not None else default
    return path if path.is_absolute() else root / path


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Build, verify, stage, and safely activate hybrid Hanok artwork delivery."
    )
    parser.add_argument("--root", default=".", help="repository root (default: current directory)")
    subcommands = parser.add_subparsers(dest="command", required=True)

    generate = subcommands.add_parser("generate", help="generate the deterministic checked-in manifest")
    generate.add_argument("--output", help=f"output path (default: {MANIFEST_PATH.as_posix()})")

    check = subcommands.add_parser("check", help="validate manifest identity and every local source byte")
    check.add_argument("--manifest", help=f"manifest path (default: {MANIFEST_PATH.as_posix()})")

    candidate = subcommands.add_parser("candidate", help="write a reviewable hybrid pubspec only")
    candidate.add_argument("--manifest", help="manifest path")
    candidate.add_argument(
        "--output", default="build/hanok-delivery/candidate-pubspec.yaml", help="candidate path"
    )

    report = subcommands.add_parser("report", help="write candidate pubspec and raw-byte report")
    report.add_argument("--manifest", help="manifest path")
    report.add_argument("--output-dir", default="build/hanok-delivery", help="review output directory")

    stage = subcommands.add_parser(
        "stage", help="copy immutable objects plus metadata locally; never upload"
    )
    stage.add_argument("--manifest", help="manifest path")
    stage.add_argument("--output-dir", default="build/hanok-delivery", help="review output directory")

    remote = subcommands.add_parser(
        "verify-remote", help="freshly verify every immutable object at the fixed Firebase endpoint"
    )
    remote.add_argument("--manifest", help="manifest path")
    remote.add_argument("--timeout", type=float, default=DEFAULT_REMOTE_TIMEOUT_SECONDS)
    remote.add_argument("--app-check-token-env", help="environment variable containing a current App Check token")

    activation = subcommands.add_parser(
        "activate", help="verify all gates and atomically replace only pubspec.yaml"
    )
    activation.add_argument("--manifest", help="manifest path")
    activation.add_argument("--expected-pubspec-sha256", required=True)
    activation.add_argument("--output-dir", default="build/hanok-delivery", help="receipt directory")
    activation.add_argument(
        "--confirm",
        choices=["ACTIVATE_HYBRID_HANOK"],
        required=True,
        help="explicit local activation acknowledgement",
    )
    activation.add_argument("--timeout", type=float, default=DEFAULT_REMOTE_TIMEOUT_SECONDS)
    activation.add_argument("--app-check-token-env", help="environment variable containing a current App Check token")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    try:
        if args.command == "generate":
            manifest = build_manifest(root)
            output = _resolve(root, args.output, MANIFEST_PATH)
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(_json_text(manifest), encoding="utf-8", newline="\n")
            result: Any = {
                "manifest": output.as_posix(),
                "packs": len(manifest["packs"]),
                **verify_local_assets(root, manifest),
            }
        else:
            manifest_path = _resolve(root, getattr(args, "manifest", None), MANIFEST_PATH)
            manifest = load_manifest(manifest_path)
            if args.command == "check":
                verify_manifest_current(root, manifest)
                result = {"manifest": manifest_path.as_posix(), **verify_local_assets(root, manifest)}
            elif args.command == "candidate":
                verify_manifest_current(root, manifest)
                verify_local_assets(root, manifest)
                output = _resolve(root, args.output, Path("build/hanok-delivery/candidate-pubspec.yaml"))
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_text(hybrid_pubspec(root, manifest), encoding="utf-8", newline="")
                result = {"candidate": output.as_posix(), "sha256": _sha256_file(output)}
            elif args.command == "report":
                output_dir = _resolve(root, args.output_dir, Path("build/hanok-delivery"))
                result = write_review_report(root, manifest, output_dir)
            elif args.command == "stage":
                output_dir = _resolve(root, args.output_dir, Path("build/hanok-delivery"))
                result = stage_upload_objects(root, manifest, output_dir)
            elif args.command == "verify-remote":
                verify_manifest_current(root, manifest)
                verify_local_assets(root, manifest)
                result = verify_remote_assets(
                    manifest, timeout=args.timeout,
                    app_check_token=_app_check_token_from_env(args.app_check_token_env),
                )
            elif args.command == "activate":
                output_dir = _resolve(root, args.output_dir, Path("build/hanok-delivery"))
                result = activate(
                    root,
                    manifest,
                    expected_pubspec_sha256=args.expected_pubspec_sha256,
                    output_dir=output_dir,
                    timeout=args.timeout,
                    app_check_token=_app_check_token_from_env(args.app_check_token_env),
                )
            else:  # pragma: no cover - argparse enforces the choices
                parser.error(f"Unknown command: {args.command}")
                return 2
        print(_json_text(result), end="")
        return 0
    except DeliveryError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
