#!/usr/bin/env python3
"""Normalize a transparent A1 socket layer and compose it onto the site base."""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hanok_v1_asset_contract import (
    ROOT,
    allowed_input_digests,
    camera_geometry,
    chroma_key_count,
    layer_contract,
    load_provenance,
    sha256_file,
    site_base_input,
)


ALPHA_THRESHOLD = 8


class CompositionError(ValueError):
    """Fail-closed A1 composition contract violation."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise CompositionError(message)


def _load_rgba(path: Path) -> Image.Image:
    with Image.open(path) as source:
        image = source.copy()
    _require(image.mode == "RGBA", f"{path} must be RGBA with a true alpha channel")
    return image.convert("RGBA")


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0)
    return alpha.getbbox()


def _chroma_count(image: Image.Image) -> int:
    return chroma_key_count(image)


def _corners_opaque(image: Image.Image) -> bool:
    width, height = image.size
    return all(
        image.getpixel(point)[3] == 255
        for point in ((0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1))
    )


def _looks_like_checkerboard(image: Image.Image) -> bool:
    samples = []
    width, height = image.size
    for x in (0, max(0, width // 2), max(0, width - 1)):
        for y in (0, max(0, height // 2), max(0, height - 1)):
            samples.append(image.getpixel((x, y)))
    unique = {(red, green, blue) for red, green, blue, alpha in samples if alpha > 200}
    if len(unique) < 2:
        return False
    light = any(red > 220 and green > 220 and blue > 220 for red, green, blue in unique)
    mid = any(90 <= red <= 190 and abs(red - green) < 12 and abs(green - blue) < 12 for red, green, blue in unique)
    return light and mid and _corners_opaque(image)


def resize_premultiplied(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    source = image.convert("RGBA")
    if source.size == size:
        return source
    return source.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")


def save_composed_webp(
    rgb: Image.Image,
    output_path: Path,
    *,
    quality: int,
    method: int,
    hard_max_bytes: int,
    outside: Image.Image,
    decoded_outside_mean_error_max: float,
) -> tuple[int, float]:
    """Write WebP to a sibling temp file, redecode it, then replace the dest.

    A failed size or decode check unlinks the temp file and leaves any
    existing dest bytes unchanged.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=output_path.parent,
            prefix=f".{output_path.stem}.",
            suffix=".webp",
            delete=False,
        ) as handle:
            tmp_path = Path(handle.name)
        rgb.save(
            tmp_path,
            "WEBP",
            quality=quality,
            method=method,
        )
        size_bytes = tmp_path.stat().st_size
        _require(
            size_bytes <= hard_max_bytes,
            f"composed WebP is {size_bytes} bytes, over the hard cap",
        )
        with Image.open(tmp_path) as encoded:
            decoded = encoded.convert("RGB")
        decoded_error = _mean_channel_error(rgb, decoded, outside)
        _require(
            decoded_error <= decoded_outside_mean_error_max,
            f"decoded outside mean error {decoded_error:.4f} exceeds the contract",
        )
        tmp_path.replace(output_path)
        return size_bytes, decoded_error
    except Exception:
        if tmp_path is not None:
            try:
                tmp_path.unlink(missing_ok=True)
            except OSError:
                pass
        raise


def _covers_local_anchor(
    bbox: tuple[int, int, int, int],
    local_anchor: tuple[int, int],
    *,
    socket_height: int,
) -> bool:
    left, top, right, bottom = bbox
    anchor_x, anchor_y = local_anchor
    # PIL getbbox right/lower are exclusive, so equality on the right edge
    # is one pixel outside the painted footprint.
    covers_x = left <= anchor_x < right
    if anchor_y >= socket_height:
        return covers_x and bottom == socket_height
    return covers_x and top <= anchor_y < bottom


def normalize_layer(
    raw: Image.Image,
    *,
    socket_width: int,
    socket_height: int,
    local_anchor: tuple[int, int],
) -> Image.Image:
    _require(raw.mode == "RGBA", "socket layer must be RGBA")
    _require(_chroma_count(raw) == 0, "socket layer contains #00ff00 chroma-key pixels")
    _require(not _corners_opaque(raw), "socket layer has an opaque matte; use true alpha")
    _require(not _looks_like_checkerboard(raw), "socket layer baked a checkerboard matte")
    if raw.size == (socket_width, socket_height):
        bbox = _alpha_bbox(raw)
        _require(bbox is not None, "socket layer is fully transparent")
        _require(
            _covers_local_anchor(
                bbox,
                local_anchor,
                socket_height=socket_height,
            ),
            "normalized layer does not cover the local anchor",
        )
        return raw

    bbox = _alpha_bbox(raw)
    _require(bbox is not None, "socket layer is fully transparent")
    cropped = raw.crop(bbox)
    scale = min(socket_width / cropped.width, socket_height / cropped.height)
    new_size = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = resize_premultiplied(cropped, new_size)
    canvas = Image.new("RGBA", (socket_width, socket_height), (0, 0, 0, 0))
    left = local_anchor[0] - resized.width // 2
    top = local_anchor[1] - resized.height
    canvas.paste(resized, (left, top), resized)
    placed = _alpha_bbox(canvas)
    _require(placed is not None, "normalized layer lost its visible footprint")
    _require(
        _covers_local_anchor(
            placed,
            local_anchor,
            socket_height=socket_height,
        ),
        "normalized layer does not cover the local anchor",
    )
    return canvas


def _mask(image: Image.Image) -> Image.Image:
    return image.getchannel("A").point(
        lambda value: 255 if value > ALPHA_THRESHOLD else 0
    )


def continuity_metrics(
    previous: Image.Image,
    current: Image.Image,
) -> dict[str, float]:
    _require(previous.size == current.size, "continuity layers must share a size")
    previous_mask = _mask(previous)
    current_mask = _mask(current)
    intersection = ImageChops.multiply(previous_mask, current_mask)
    previous_count = sum(pixel > 0 for pixel in previous_mask.getdata())
    current_count = sum(pixel > 0 for pixel in current_mask.getdata())
    intersection_count = sum(pixel > 0 for pixel in intersection.getdata())
    union_count = previous_count + current_count - intersection_count
    previous_bbox = previous_mask.getbbox()
    shared_bbox = intersection.getbbox()
    _require(previous_bbox is not None, "previous layer has no visible footprint")
    _require(shared_bbox is not None, "current layer dropped the previous footprint")
    edge_drift = max(
        abs(shared_bbox[0] - previous_bbox[0]),
        abs(shared_bbox[2] - previous_bbox[2]),
        abs(shared_bbox[3] - previous_bbox[3]),
    )
    recall = intersection_count / previous_count if previous_count else 0.0
    iou = intersection_count / union_count if union_count else 0.0
    return {
        "previous_recall": recall,
        "iou": iou,
        "edge_drift_px": float(edge_drift),
        "previous_pixels": float(previous_count),
        "current_pixels": float(current_count),
    }


def stack_layers(
    previous: Image.Image,
    candidate: Image.Image,
    *,
    margin_px: int,
) -> tuple[Image.Image, dict[str, float]]:
    """Cumulative construction: keep every previous pixel, add the candidate above.

    Generators re-draw the whole structure and drift (columns thin out, posts
    move). Instead of asking the model for pixel-exact geometry, keep the
    approved previous layer as-is and take the candidate only where the previous
    layer is transparent AND above its top edge (plus `margin_px` so joints can
    overlap the previous top). Anything the candidate re-drew lower down — the
    duplicate columns of 2026-08-17 — is discarded. Continuity is then true by
    construction (previous_recall == 1.0, edge drift 0).
    """
    _require(previous.size == candidate.size, "stack layers must share a size")
    _require(margin_px >= 0, "stack margin must be zero or positive")
    previous_bbox = _alpha_bbox(previous)
    _require(previous_bbox is not None, "previous layer has no visible footprint")
    cut_row = min(previous.height, previous_bbox[1] + margin_px)
    band = Image.new("L", previous.size, 0)
    if cut_row > 0:
        band.paste(255, (0, 0, previous.width, cut_row))
    banded = Image.new("RGBA", previous.size, (0, 0, 0, 0))
    banded.paste(candidate, (0, 0), band)
    keep_previous = _mask(previous)
    merged = Image.composite(previous, banded, keep_previous)
    added = sum(
        1
        for before, after in zip(
            previous.getchannel("A").getdata(),
            merged.getchannel("A").getdata(),
            strict=True,
        )
        if before <= ALPHA_THRESHOLD < after
    )
    _require(added > 0, "stacked candidate added nothing above the previous layer")
    return merged, {
        "mode": "stack",
        "cutRow": float(cut_row),
        "marginPx": float(margin_px),
        "addedPixels": float(added),
    }


def assert_continuity(
    previous: Image.Image,
    current: Image.Image,
    *,
    min_previous_recall: float,
    max_edge_drift_px: float,
) -> dict[str, float]:
    metrics = continuity_metrics(previous, current)
    _require(
        metrics["previous_recall"] >= min_previous_recall,
        "current layer dropped previous construction geometry "
        f"(recall={metrics['previous_recall']:.4f})",
    )
    _require(
        metrics["edge_drift_px"] <= max_edge_drift_px,
        "current layer moved the previous footprint "
        f"(edge_drift={metrics['edge_drift_px']:.1f}px)",
    )
    return metrics


def _outside_mask(size: tuple[int, int], socket: dict[str, int]) -> Image.Image:
    mask = Image.new("L", size, 255)
    hole = Image.new(
        "L",
        (socket["socket_width"], socket["socket_height"]),
        0,
    )
    mask.paste(hole, (socket["socket_x"], socket["socket_y"]))
    return mask


def _changed_pixels(left: Image.Image, right: Image.Image, mask: Image.Image) -> int:
    difference = ImageChops.difference(left.convert("RGB"), right.convert("RGB"))
    return sum(
        1
        for rgb, keep in zip(difference.getdata(), mask.getdata(), strict=True)
        if keep and rgb != (0, 0, 0)
    )


def _mean_channel_error(left: Image.Image, right: Image.Image, mask: Image.Image) -> float:
    left_rgb = left.convert("RGB")
    right_rgb = right.convert("RGB")
    total = 0.0
    count = 0
    for left_px, right_px, keep in zip(
        left_rgb.getdata(),
        right_rgb.getdata(),
        mask.getdata(),
        strict=True,
    ):
        if not keep:
            continue
        total += (
            abs(left_px[0] - right_px[0])
            + abs(left_px[1] - right_px[1])
            + abs(left_px[2] - right_px[2])
        ) / 3
        count += 1
    return total / count if count else 0.0


def compose_state(
    raw_path: Path,
    output_path: Path,
    *,
    normalized_layer_path: Path | None = None,
    previous_layer_path: Path | None = None,
    provenance: dict[str, Any] | None = None,
    base_path: Path | None = None,
    require_lineage: bool = False,
    input_ledger_path: str | None = None,
    stack_on_previous: bool = False,
    stack_margin_px: int = 8,
) -> dict[str, Any]:
    payload = provenance or load_provenance()
    _require(
        not stack_on_previous or previous_layer_path is not None,
        "--stack-on-previous needs --previous-layer",
    )
    geometry = camera_geometry(payload)
    contract = layer_contract(payload)
    base_record = site_base_input(payload)
    site_base = Path(base_path or ROOT / base_record["path"])
    expected_base_sha = str(base_record["sha256"])
    if base_path is None:
        _require(
            sha256_file(site_base) == expected_base_sha,
            "site base SHA-256 no longer matches the provenance allowlist",
        )
    if require_lineage:
        digest = sha256_file(raw_path)
        allowed = allowed_input_digests(payload)
        if input_ledger_path:
            path_ok = allowed.get(input_ledger_path) == digest
        else:
            try:
                ledger_path = str(raw_path.resolve().relative_to(ROOT))
            except ValueError:
                path_ok = False
            else:
                path_ok = allowed.get(ledger_path) == digest
        _require(
            path_ok,
            "raw layer SHA is not bound to an allowlisted or approved ledger path",
        )

    raw = _load_rgba(raw_path)
    layer = normalize_layer(
        raw,
        socket_width=geometry["socket_width"],
        socket_height=geometry["socket_height"],
        local_anchor=(geometry["local_anchor_x"], geometry["local_anchor_y"]),
    )
    continuity = None
    stack = None
    if previous_layer_path is not None:
        previous = _load_rgba(previous_layer_path)
        if previous.size != layer.size:
            previous = normalize_layer(
                previous,
                socket_width=geometry["socket_width"],
                socket_height=geometry["socket_height"],
                local_anchor=(geometry["local_anchor_x"], geometry["local_anchor_y"]),
            )
        if stack_on_previous:
            layer, stack = stack_layers(previous, layer, margin_px=stack_margin_px)
        continuity = assert_continuity(
            previous,
            layer,
            min_previous_recall=float(contract["continuity"]["minPreviousRecall"]),
            max_edge_drift_px=float(contract["continuity"]["maxEdgeDriftPx"]),
        )

    with Image.open(site_base) as source:
        base = source.convert("RGBA")
    _require(
        base.size == (geometry["canvas_width"], geometry["canvas_height"]),
        "site base canvas does not match the provenance camera",
    )
    composed = base.copy()
    composed.alpha_composite(layer, dest=(geometry["socket_x"], geometry["socket_y"]))
    outside = _outside_mask(base.size, geometry)
    source_outside_changed = _changed_pixels(base, composed, outside)
    _require(
        source_outside_changed == int(contract["qa"]["sourceOutsideChangedPixels"]),
        f"composition changed {source_outside_changed} pixels outside the socket",
    )

    if normalized_layer_path is not None:
        normalized_layer_path.parent.mkdir(parents=True, exist_ok=True)
        layer.save(normalized_layer_path, "PNG")

    rgb = composed.convert("RGB")
    size_bytes, decoded_error = save_composed_webp(
        rgb,
        output_path,
        quality=int(contract["output"]["quality"]),
        method=int(contract["output"]["method"]),
        hard_max_bytes=int(contract["output"]["hardMaxBytes"]),
        outside=outside,
        decoded_outside_mean_error_max=float(
            contract["qa"]["decodedOutsideMeanErrorMax"]
        ),
    )
    report = {
        "normalizedSize": list(layer.size),
        "anchorPixels": sum(alpha > ALPHA_THRESHOLD for *_, alpha in layer.getdata()),
        "chromaPixels": _chroma_count(layer),
        "sourceOutsideChangedPixels": source_outside_changed,
        "decodedOutsideMeanError": decoded_error,
        "outputBytes": size_bytes,
        "outputSha256": sha256_file(output_path),
    }
    if continuity is not None:
        report["continuity"] = continuity
    if stack is not None:
        report["stack"] = stack
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("raw_png")
    parser.add_argument("output_webp")
    parser.add_argument("--normalized-layer")
    parser.add_argument("--previous-layer")
    parser.add_argument("--require-lineage", action="store_true")
    parser.add_argument("--input-ledger-path")
    parser.add_argument(
        "--stack-on-previous",
        action="store_true",
        help=(
            "keep every pixel of --previous-layer and take the candidate only "
            "above the previous top edge (+ --stack-margin-px); continuity "
            "becomes true by construction"
        ),
    )
    parser.add_argument("--stack-margin-px", type=int, default=8)
    args = parser.parse_args(argv)
    report = compose_state(
        Path(args.raw_png),
        Path(args.output_webp),
        normalized_layer_path=Path(args.normalized_layer) if args.normalized_layer else None,
        previous_layer_path=Path(args.previous_layer) if args.previous_layer else None,
        require_lineage=args.require_lineage,
        input_ledger_path=args.input_ledger_path,
        stack_on_previous=args.stack_on_previous,
        stack_margin_px=args.stack_margin_px,
    )
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except CompositionError as error:
        print(f"[fail] {error}")
        raise SystemExit(1)
