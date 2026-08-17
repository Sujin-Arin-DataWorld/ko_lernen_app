#!/usr/bin/env python3
"""Compose one approved transparent A1 construction layer into the estate.

The generator never receives authority over the full estate.  It may produce
only an RGBA layer with the exact primary-house socket dimensions; this tool
validates that layer and composites it onto the SHA-locked project base.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import sys
from tempfile import NamedTemporaryFile
from typing import Any

import PIL
from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parent.parent
PROVENANCE_PATH = ROOT / "docs" / "assets" / "HANOK_V1_ASSET_PROVENANCE.json"
MIN_VISIBLE_SOURCE_PIXELS = 100
ALPHA_THRESHOLD = 8


class AssetContractError(ValueError):
    """Raised when an input or output would violate the shipped asset contract."""


@dataclass(frozen=True)
class HanokA1AssetContract:
    canvas: tuple[int, int]
    socket: tuple[int, int, int, int]
    anchor_canvas: tuple[int, int]
    anchor_local: tuple[int, int]
    hard_max_bytes: int
    layer_format: str
    layer_mode: str
    encoder_library: str
    encoder_format: str
    encoder_quality: int
    encoder_method: int
    max_decoded_outside_mean_error: float
    continuity_band_height: int
    minimum_continuity_alpha_iou: float
    maximum_footprint_edge_drift: int
    base_path: Path
    base_sha256: str


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_contract() -> HanokA1AssetContract:
    try:
        payload = json.loads(PROVENANCE_PATH.read_text(encoding="utf-8"))
        camera = _object(payload.get("camera"), "camera")
        canvas = _object(camera.get("canvas"), "camera.canvas")
        socket = _object(camera.get("socket"), "camera.socket")
        anchor = _object(socket.get("anchorCanvas"), "camera.socket.anchorCanvas")
        runtime_limits = _object(payload.get("runtimeLimits"), "runtimeLimits")
        states = _object(
            runtime_limits.get("a1ConstructionStates"),
            "runtimeLimits.a1ConstructionStates",
        )
        composition = _object(states.get("composition"), "a1ConstructionStates.composition")
        layer_contract = _object(composition.get("layer"), "composition.layer")
        local_anchor = _object(
            layer_contract.get("anchorLocal"),
            "composition.layer.anchorLocal",
        )
        encoder = _object(composition.get("encoder"), "composition.encoder")
        continuity = _object(
            composition.get("cumulativeContinuity"),
            "composition.cumulativeContinuity",
        )
        allowed_inputs = payload.get("allowedModelInputs")
        if not isinstance(allowed_inputs, list):
            raise AssetContractError("allowedModelInputs must be a list")
        base_entry = next(
            (
                _object(candidate, "allowedModelInputs[]")
                for candidate in allowed_inputs
                if isinstance(candidate, dict) and candidate.get("role") == "site_base"
            ),
            None,
        )
        if base_entry is None:
            raise AssetContractError("The approved site_base input is missing")

        canvas_size = (
            _integer(canvas.get("width"), "camera.canvas.width"),
            _integer(canvas.get("height"), "camera.canvas.height"),
        )
        socket_rect = (
            _integer(socket.get("x"), "camera.socket.x"),
            _integer(socket.get("y"), "camera.socket.y"),
            _integer(socket.get("width"), "camera.socket.width"),
            _integer(socket.get("height"), "camera.socket.height"),
        )
        anchor_canvas = (
            _integer(anchor.get("x"), "camera.socket.anchorCanvas.x"),
            _integer(anchor.get("y"), "camera.socket.anchorCanvas.y"),
        )
        anchor_local = (
            anchor_canvas[0] - socket_rect[0],
            anchor_canvas[1] - socket_rect[1],
        )
        contract = HanokA1AssetContract(
            canvas=canvas_size,
            socket=socket_rect,
            anchor_canvas=anchor_canvas,
            anchor_local=anchor_local,
            hard_max_bytes=_integer(states.get("hardMaxBytes"), "hardMaxBytes"),
            layer_format=_string(layer_contract.get("format"), "layer.format"),
            layer_mode=_string(layer_contract.get("colorMode"), "layer.colorMode"),
            encoder_library=_string(encoder.get("library"), "encoder.library"),
            encoder_format=_string(encoder.get("format"), "encoder.format"),
            encoder_quality=_integer(encoder.get("quality"), "encoder.quality"),
            encoder_method=_integer(encoder.get("method"), "encoder.method"),
            max_decoded_outside_mean_error=_number(
                composition.get("decodedOutsideSocketMaxMeanError"),
                "composition.decodedOutsideSocketMaxMeanError",
            ),
            continuity_band_height=_integer(
                continuity.get("foundationBandHeight"),
                "cumulativeContinuity.foundationBandHeight",
            ),
            minimum_continuity_alpha_iou=_number(
                continuity.get("minimumAlphaIoU"),
                "cumulativeContinuity.minimumAlphaIoU",
            ),
            maximum_footprint_edge_drift=_integer(
                continuity.get("maximumFootprintEdgeDriftPixels"),
                "cumulativeContinuity.maximumFootprintEdgeDriftPixels",
            ),
            base_path=ROOT / _string(base_entry.get("path"), "site_base.path"),
            base_sha256=_sha256(base_entry.get("sha256"), "site_base.sha256"),
        )
    except (KeyError, TypeError, json.JSONDecodeError) as error:
        raise AssetContractError("Invalid Hanok V1 provenance registry") from error

    x, y, width, height = contract.socket
    if x < 0 or y < 0 or x + width > contract.canvas[0] or y + height > contract.canvas[1]:
        raise AssetContractError("The primary-house socket is outside the canvas")
    if contract.anchor_local != (width // 2, height):
        raise AssetContractError("The primary-house anchor does not match the socket")
    declared_local_anchor = (
        _integer(local_anchor.get("x"), "layer.anchorLocal.x"),
        _integer(local_anchor.get("y"), "layer.anchorLocal.y"),
    )
    if contract.anchor_local != declared_local_anchor:
        raise AssetContractError("Layer-local and canvas anchor declarations differ")
    if (
        _integer(layer_contract.get("width"), "layer.width"),
        _integer(layer_contract.get("height"), "layer.height"),
    ) != (width, height):
        raise AssetContractError("Layer dimensions do not match the primary-house socket")
    if _integer(
        composition.get("sourceOutsideSocketChangedPixels"),
        "composition.sourceOutsideSocketChangedPixels",
    ) != 0:
        raise AssetContractError("Source composition must preserve every outside pixel")
    if contract.encoder_library != "Pillow" or contract.encoder_format != "WebP":
        raise AssetContractError("Unsupported A1 state encoder contract")
    if not 1 <= contract.continuity_band_height <= contract.socket[3]:
        raise AssetContractError("Continuity foundation band is outside the socket")
    if not 0 < contract.minimum_continuity_alpha_iou <= 1:
        raise AssetContractError("Continuity alpha IoU must be in (0, 1]")
    if contract.maximum_footprint_edge_drift < 0:
        raise AssetContractError("Continuity footprint drift cannot be negative")
    return contract


def validate_layer(
    image: Image.Image,
    contract: HanokA1AssetContract,
) -> dict[str, float | int]:
    expected_size = (contract.socket[2], contract.socket[3])
    if image.size != expected_size:
        raise AssetContractError(
            f"Layer size {image.size} does not match socket {expected_size}"
        )
    if image.mode != contract.layer_mode:
        raise AssetContractError(
            f"Layer mode {image.mode} must be {contract.layer_mode}"
        )

    alpha = image.getchannel("A")
    minimum_alpha, maximum_alpha = alpha.getextrema()
    if minimum_alpha != 0 or maximum_alpha <= ALPHA_THRESHOLD:
        raise AssetContractError("Layer must contain real transparent and visible pixels")
    corners = (
        alpha.getpixel((0, 0)),
        alpha.getpixel((image.width - 1, 0)),
        alpha.getpixel((0, image.height - 1)),
        alpha.getpixel((image.width - 1, image.height - 1)),
    )
    if any(value != 0 for value in corners):
        raise AssetContractError(f"Layer corners must be transparent, got {corners}")

    alpha_values = list(alpha.getdata())
    visible_pixels = sum(value > ALPHA_THRESHOLD for value in alpha_values)
    alpha_coverage = visible_pixels / (image.width * image.height)
    if not 0.002 <= alpha_coverage <= 0.80:
        raise AssetContractError(
            f"Layer alpha coverage {alpha_coverage:.2%} is outside 0.2%-80%"
        )

    chroma_pixels = sum(
        1
        for red, green, blue, pixel_alpha in image.getdata()
        if (red, green, blue) == (0, 255, 0) and pixel_alpha > ALPHA_THRESHOLD
    )
    if chroma_pixels:
        raise AssetContractError(
            f"Layer contains {chroma_pixels} visible #00ff00 chroma pixels"
        )

    anchor_x, anchor_y = contract.anchor_local
    anchor_band = alpha.crop(
        (
            max(0, anchor_x - 48),
            max(0, anchor_y - 12),
            min(image.width, anchor_x + 49),
            min(image.height, anchor_y),
        )
    )
    anchor_pixels = sum(value > ALPHA_THRESHOLD for value in anchor_band.getdata())
    if anchor_pixels == 0:
        raise AssetContractError("Layer does not reach the fixed local anchor band")

    return {
        "visiblePixels": visible_pixels,
        "alphaCoverage": alpha_coverage,
        "anchorPixels": anchor_pixels,
        "chromaPixels": chroma_pixels,
    }


def validate_cumulative_continuity(
    previous: Image.Image,
    current: Image.Image,
    contract: HanokA1AssetContract,
) -> dict[str, float | int | list[int]]:
    """Rejects a stage that moves or rescales the established foundation."""
    validate_layer(previous, contract)
    validate_layer(current, contract)
    band_height = contract.continuity_band_height
    top = previous.height - band_height
    bounds = (0, top, previous.width, previous.height)

    def visible_band(image: Image.Image) -> Image.Image:
        return image.getchannel("A").crop(bounds).point(
            lambda value: 255 if value > ALPHA_THRESHOLD else 0,
            mode="L",
        )

    previous_band = visible_band(previous)
    current_band = visible_band(current)
    previous_pixels = list(previous_band.getdata())
    current_pixels = list(current_band.getdata())
    intersection = sum(
        before > 0 and after > 0
        for before, after in zip(previous_pixels, current_pixels, strict=True)
    )
    union = sum(
        before > 0 or after > 0
        for before, after in zip(previous_pixels, current_pixels, strict=True)
    )
    if union == 0:
        raise AssetContractError("Continuity foundation band is empty")
    alpha_iou = intersection / union
    if alpha_iou < contract.minimum_continuity_alpha_iou:
        raise AssetContractError(
            "Cumulative foundation alpha IoU is "
            f"{alpha_iou:.4f}; minimum is "
            f"{contract.minimum_continuity_alpha_iou:.4f}"
        )

    previous_bounds = previous_band.getbbox()
    current_bounds = current_band.getbbox()
    if previous_bounds is None or current_bounds is None:
        raise AssetContractError("Continuity foundation footprint is empty")
    left_drift = abs(previous_bounds[0] - current_bounds[0])
    right_drift = abs(previous_bounds[2] - current_bounds[2])
    maximum_drift = max(left_drift, right_drift)
    if maximum_drift > contract.maximum_footprint_edge_drift:
        raise AssetContractError(
            "Cumulative foundation footprint drift is "
            f"{maximum_drift}px; maximum is "
            f"{contract.maximum_footprint_edge_drift}px"
        )

    return {
        "foundationBandHeight": band_height,
        "alphaIoU": alpha_iou,
        "intersectionPixels": intersection,
        "unionPixels": union,
        "previousFootprint": list(previous_bounds),
        "currentFootprint": list(current_bounds),
        "maximumEdgeDriftPixels": maximum_drift,
    }


def normalize_layer(
    image: Image.Image,
    contract: HanokA1AssetContract,
) -> Image.Image:
    """Fits a true-alpha generated asset into the canonical socket canvas."""
    if image.mode != contract.layer_mode:
        raise AssetContractError(
            f"Generated layer mode {image.mode} must be {contract.layer_mode}"
        )
    if image.width < 16 or image.height < 16 or image.width > 8192 or image.height > 8192:
        raise AssetContractError("Generated layer dimensions are outside 16-8192 pixels")
    alpha = image.getchannel("A")
    corners = (
        alpha.getpixel((0, 0)),
        alpha.getpixel((image.width - 1, 0)),
        alpha.getpixel((0, image.height - 1)),
        alpha.getpixel((image.width - 1, image.height - 1)),
    )
    if any(value != 0 for value in corners):
        raise AssetContractError(
            f"Generated layer corners must be transparent, got {corners}"
        )
    visible_alpha = alpha.point(
        lambda value: 255 if value > ALPHA_THRESHOLD else 0,
        mode="L",
    )
    alpha_bounds = visible_alpha.getbbox()
    if alpha_bounds is None:
        raise AssetContractError("Generated layer is fully transparent")
    chroma_pixels = sum(
        1
        for red, green, blue, pixel_alpha in image.getdata()
        if (red, green, blue) == (0, 255, 0) and pixel_alpha > ALPHA_THRESHOLD
    )
    if chroma_pixels:
        raise AssetContractError(
            f"Generated layer contains {chroma_pixels} visible #00ff00 pixels"
        )

    cropped = image.crop(alpha_bounds)
    target_width, target_height = contract.socket[2:]
    maximum_width = target_width - 16
    scale = min(maximum_width / cropped.width, target_height / cropped.height)
    resized_size = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = (
        cropped.convert("RGBa")
        .resize(resized_size, Image.Resampling.LANCZOS)
        .convert("RGBA")
    )
    normalized = Image.new("RGBA", (target_width, target_height), (0, 0, 0, 0))
    normalized.alpha_composite(
        resized,
        (
            (target_width - resized.width) // 2,
            target_height - resized.height,
        ),
    )
    validate_layer(normalized, contract)
    return normalized


def write_normalized_layer(
    *,
    source_path: Path,
    output_path: Path,
    previous_layer_path: Path | None = None,
) -> dict[str, Any]:
    contract = load_contract()
    if not source_path.is_file():
        raise AssetContractError(f"Generated layer does not exist: {source_path}")
    if source_path.resolve() == output_path.resolve():
        raise AssetContractError("Normalized output must not overwrite its source")
    if output_path.suffix.lower() != f".{contract.layer_format.lower()}":
        raise AssetContractError(
            f"Normalized layer must use the .{contract.layer_format.lower()} extension"
        )
    with Image.open(source_path) as source:
        if source.format != contract.layer_format:
            raise AssetContractError(
                f"Generated layer must decode as {contract.layer_format}"
            )
        raw = source.copy()
    normalized = normalize_layer(raw, contract)
    continuity_report = None
    if previous_layer_path is not None:
        if not previous_layer_path.is_file():
            raise AssetContractError(
                f"Previous approved layer does not exist: {previous_layer_path}"
            )
        with Image.open(previous_layer_path) as previous_source:
            if previous_source.format != contract.layer_format:
                raise AssetContractError(
                    "Previous approved layer must decode as "
                    f"{contract.layer_format}"
                )
            previous = previous_source.copy()
        continuity_report = validate_cumulative_continuity(
            previous,
            normalized,
            contract,
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with NamedTemporaryFile(
            dir=output_path.parent,
            prefix=f".{output_path.stem}.",
            suffix=f".{contract.layer_format.lower()}",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
        normalized.save(temporary_path, format=contract.layer_format)
        temporary_path.replace(output_path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    with Image.open(output_path) as saved:
        metrics = validate_layer(saved.copy(), contract)
    report = {
        "sourcePath": str(source_path.resolve()),
        "sourceSha256": sha256_file(source_path),
        "outputPath": str(output_path.resolve()),
        "outputSha256": sha256_file(output_path),
        "outputBytes": output_path.stat().st_size,
        "layer": metrics,
    }
    if continuity_report is not None:
        report["cumulativeContinuity"] = continuity_report
    return report


def write_state(
    *,
    layer_path: Path,
    output_path: Path,
    base_path: Path | None = None,
) -> dict[str, Any]:
    contract = load_contract()
    approved_base = base_path or contract.base_path
    _validate_base(approved_base, contract)
    if not layer_path.is_file():
        raise AssetContractError(f"Layer does not exist: {layer_path}")
    if layer_path.suffix.lower() != f".{contract.layer_format.lower()}":
        raise AssetContractError(
            f"Transparent construction layer must be {contract.layer_format}"
        )
    if output_path.suffix.lower() != ".webp":
        raise AssetContractError("A1 runtime state must use the .webp extension")

    with Image.open(approved_base) as source:
        base = source.convert("RGB")
    with Image.open(layer_path) as source:
        if source.format != contract.layer_format:
            raise AssetContractError(
                "Transparent construction layer must decode as "
                f"{contract.layer_format}"
            )
        layer = source.copy()
    layer_metrics = validate_layer(layer, contract)

    composite = base.convert("RGBA")
    composite.alpha_composite(layer, (contract.socket[0], contract.socket[1]))
    composite = composite.convert("RGB")
    source_outside_changed = _outside_changed_pixels(base, composite, contract.socket)
    if source_outside_changed != 0:
        raise AssetContractError("Source composition changed pixels outside the socket")
    visible_source_pixels = _inside_changed_pixels(base, composite, contract.socket)
    if visible_source_pixels < MIN_VISIBLE_SOURCE_PIXELS:
        raise AssetContractError("Layer does not create a visible construction change")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with NamedTemporaryFile(
            dir=output_path.parent,
            prefix=f".{output_path.stem}.",
            suffix=".webp",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
        composite.save(
            temporary_path,
            format=contract.encoder_format.upper(),
            quality=contract.encoder_quality,
            method=contract.encoder_method,
        )
        output_bytes = temporary_path.stat().st_size
        if output_bytes > contract.hard_max_bytes:
            raise AssetContractError(
                f"Encoded state is {output_bytes} bytes; max is {contract.hard_max_bytes}"
            )
        with Image.open(temporary_path) as encoded_source:
            if encoded_source.format != "WEBP":
                raise AssetContractError("Encoded state is not WebP")
            encoded = encoded_source.copy()
        if encoded.mode != "RGB" or encoded.size != contract.canvas:
            raise AssetContractError(
                f"Encoded state is {encoded.mode} {encoded.size}; expected RGB {contract.canvas}"
            )
        outside_mean_error = _outside_mean_error(base, encoded, contract.socket)
        if outside_mean_error > contract.max_decoded_outside_mean_error:
            raise AssetContractError(
                "WebP distortion outside socket exceeds the fixed mean-error limit: "
                f"{outside_mean_error:.4f}"
            )
        temporary_path.replace(output_path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)

    return {
        "basePath": str(approved_base.resolve()),
        "baseSha256": sha256_file(approved_base),
        "layerPath": str(layer_path.resolve()),
        "layerSha256": sha256_file(layer_path),
        "outputPath": str(output_path.resolve()),
        "outputSha256": sha256_file(output_path),
        "outputBytes": output_path.stat().st_size,
        "sourceOutsideSocketChangedPixels": source_outside_changed,
        "sourceInsideSocketChangedPixels": visible_source_pixels,
        "decodedOutsideSocketMeanError": outside_mean_error,
        "encoder": {
            "library": contract.encoder_library,
            "version": PIL.__version__,
            "format": contract.encoder_format,
            "quality": contract.encoder_quality,
            "method": contract.encoder_method,
        },
        "layer": layer_metrics,
    }


def _validate_base(path: Path, contract: HanokA1AssetContract) -> None:
    if not path.is_file():
        raise AssetContractError(f"Base does not exist: {path}")
    actual_sha256 = sha256_file(path)
    if actual_sha256 != contract.base_sha256:
        raise AssetContractError("Base SHA-256 is not the approved site_base")
    with Image.open(path) as source:
        if source.size != contract.canvas or source.mode != "RGB":
            raise AssetContractError(
                f"Base is {source.mode} {source.size}; expected RGB {contract.canvas}"
            )


def _outside_mask(
    canvas: tuple[int, int],
    socket: tuple[int, int, int, int],
) -> Image.Image:
    x, y, width, height = socket
    mask = Image.new("L", canvas, 255)
    mask.paste(0, (x, y, x + width, y + height))
    return mask


def _outside_changed_pixels(
    before: Image.Image,
    after: Image.Image,
    socket: tuple[int, int, int, int],
) -> int:
    difference = ImageChops.difference(before.convert("RGB"), after.convert("RGB"))
    mask = _outside_mask(before.size, socket)
    outside = Image.composite(difference, Image.new("RGB", before.size), mask)
    return sum(pixel != (0, 0, 0) for pixel in outside.getdata())


def _inside_changed_pixels(
    before: Image.Image,
    after: Image.Image,
    socket: tuple[int, int, int, int],
) -> int:
    x, y, width, height = socket
    difference = ImageChops.difference(
        before.convert("RGB").crop((x, y, x + width, y + height)),
        after.convert("RGB").crop((x, y, x + width, y + height)),
    )
    return sum(pixel != (0, 0, 0) for pixel in difference.getdata())


def _outside_mean_error(
    base: Image.Image,
    encoded: Image.Image,
    socket: tuple[int, int, int, int],
) -> float:
    difference = ImageChops.difference(base.convert("RGB"), encoded.convert("RGB"))
    statistics = ImageStat.Stat(difference, mask=_outside_mask(base.size, socket))
    return max(statistics.mean)


def _object(value: object, field: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise AssetContractError(f"{field} must be an object")
    return value


def _integer(value: object, field: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise AssetContractError(f"{field} must be an integer")
    return value


def _string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise AssetContractError(f"{field} must be a non-empty string")
    return value


def _number(value: object, field: str) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise AssetContractError(f"{field} must be a finite number")
    result = float(value)
    if result != result or result in (float("inf"), float("-inf")):
        raise AssetContractError(f"{field} must be a finite number")
    return result


def _sha256(value: object, field: str) -> str:
    result = _string(value, field)
    if len(result) != 64 or any(character not in "0123456789abcdef" for character in result):
        raise AssetContractError(f"{field} must be a lowercase SHA-256")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("layer", type=Path, help="854x309 transparent RGBA PNG")
    parser.add_argument("output", type=Path, help="1536x1152 RGB WebP output")
    parser.add_argument(
        "--normalized-layer",
        type=Path,
        help="normalize a larger true-alpha PNG here before composition",
    )
    parser.add_argument(
        "--previous-layer",
        type=Path,
        help="fail unless the normalized foundation footprint matches this approved layer",
    )
    arguments = parser.parse_args()
    try:
        layer_path = arguments.layer
        normalization_report = None
        if arguments.normalized_layer is not None:
            normalization_report = write_normalized_layer(
                source_path=arguments.layer,
                output_path=arguments.normalized_layer,
                previous_layer_path=arguments.previous_layer,
            )
            layer_path = arguments.normalized_layer
        elif arguments.previous_layer is not None:
            contract = load_contract()
            with Image.open(arguments.previous_layer) as previous_source:
                previous = previous_source.copy()
            with Image.open(layer_path) as current_source:
                current = current_source.copy()
            normalization_report = {
                "cumulativeContinuity": validate_cumulative_continuity(
                    previous,
                    current,
                    contract,
                )
            }
        report = write_state(layer_path=layer_path, output_path=arguments.output)
        if normalization_report is not None:
            report["normalization"] = normalization_report
    except (AssetContractError, OSError) as error:
        print(f"[fail] {error}", file=sys.stderr)
        return 1
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
