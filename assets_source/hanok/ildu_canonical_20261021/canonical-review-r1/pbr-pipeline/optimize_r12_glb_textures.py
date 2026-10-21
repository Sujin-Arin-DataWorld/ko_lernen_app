"""Losslessly recompress embedded PNG IDAT streams in a private GLB candidate.

The inflated PNG scanlines, IHDR (including bit depth), all non-IDAT chunks,
all accessor metadata and every non-image bufferView byte are preserved. There
is no pixel conversion, resize, atlas change, mesh change or material change.
Pillow decoded-byte equality is an additional check; exact inflated-byte equality
is the stronger proof for RGB/RGBA16 images that Pillow exposes as 8-bit modes.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import io
import json
import struct
import zlib
from pathlib import Path

from PIL import Image

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


class OptimizationError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise OptimizationError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def read_png(data):
    require(data.startswith(PNG_SIGNATURE), "Image is not a PNG")
    chunks, offset = [], 8
    idat_started = idat_ended = False
    while offset < len(data):
        require(offset + 12 <= len(data), "Truncated PNG chunk")
        size = struct.unpack_from(">I", data, offset)[0]
        require(size <= 0x7FFFFFFF and offset + size + 12 <= len(data), "PNG chunk exceeds image bounds")
        kind = data[offset + 4:offset + 8]
        body = data[offset + 8:offset + 8 + size]
        crc = struct.unpack_from(">I", data, offset + 8 + size)[0]
        require(crc == zlib.crc32(kind + body) & 0xFFFFFFFF, f"PNG CRC mismatch in {kind!r}")
        raw = data[offset:offset + size + 12]
        if kind == b"IDAT":
            require(not idat_ended, "PNG IDAT chunks are not consecutive")
            idat_started = True
        elif idat_started:
            idat_ended = True
        chunks.append((kind, body, raw))
        offset += size + 12
        if kind == b"IEND":
            require(size == 0 and offset == len(data), "Unexpected bytes after PNG IEND")
            break
    require(chunks and chunks[0][0] == b"IHDR" and len(chunks[0][1]) == 13, "PNG lacks an initial IHDR")
    require(chunks[-1][0] == b"IEND" and idat_started, "Incomplete PNG")
    require(sum(c[0] == b"IHDR" for c in chunks) == 1, "Multiple PNG IHDR chunks")
    width, height, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", chunks[0][1])
    require(width > 0 and height > 0 and compression == filtering == 0 and interlace in (0, 1), "Unsupported PNG header")
    require(not any(c[0] in (b"acTL", b"fcTL", b"fdAT") for c in chunks), "Animated PNG is outside this texture contract")
    packed = b"".join(c[1] for c in chunks if c[0] == b"IDAT")
    decoder = zlib.decompressobj()
    inflated = decoder.decompress(packed) + decoder.flush()
    require(decoder.eof and not decoder.unused_data and not decoder.unconsumed_tail, "Invalid or concatenated PNG zlib stream")
    return chunks, inflated, {"width": width, "height": height, "bitDepth": depth, "colorType": color, "interlace": interlace}


def pillow_pixels(data):
    with Image.open(io.BytesIO(data)) as image:
        require(image.format == "PNG", "Pillow did not recognize PNG")
        image.verify()
    with Image.open(io.BytesIO(data)) as image:
        image.load()
        return image.mode, image.size, image.tobytes()


def optimize_png(original, level=9):
    require(isinstance(level, int) and 0 <= level <= 9, "Compression level must be 0..9")
    chunks, inflated, header = read_png(original)
    packed = zlib.compress(inflated, level)
    candidate = bytearray(PNG_SIGNATURE)
    inserted = False
    for kind, _, raw in chunks:
        if kind == b"IDAT":
            if not inserted:
                candidate.extend(png_chunk(b"IDAT", packed))
                inserted = True
        else:
            candidate.extend(raw)
    candidate = bytes(candidate)
    result = candidate if len(candidate) < len(original) else original
    new_chunks, new_inflated, new_header = read_png(result)
    require(new_header == header and new_inflated == inflated, "PNG native sample/bit-depth preservation failed")
    original_metadata = b"".join(raw for kind, _, raw in chunks if kind != b"IDAT")
    new_metadata = b"".join(raw for kind, _, raw in new_chunks if kind != b"IDAT")
    require(new_metadata == original_metadata, "PNG non-IDAT chunks changed")
    before_mode, before_size, before_pixels = pillow_pixels(original)
    after_mode, after_size, after_pixels = pillow_pixels(result)
    require((before_mode, before_size, before_pixels) == (after_mode, after_size, after_pixels), "Pillow decoded pixels changed")
    return result, {
        **header, "originalBytes": len(original), "optimizedBytes": len(result), "savedBytes": len(original) - len(result),
        "originalSha256": sha(original), "optimizedSha256": sha(result), "recompressed": result != original,
        "inflatedIdatBytes": len(inflated), "inflatedIdatSha256": sha(inflated), "nativeFilteredBytesEqual": True,
        "bitDepthPreserved": True, "nonIdatChunkBytesEqual": True, "nonIdatChunkSha256": sha(original_metadata),
        "pillowMode": before_mode, "pillowDecodedBytesSha256": sha(before_pixels), "pillowDecodedBytesEqual": True,
        "pillowProofLimitation": "RGB/RGBA16 may decode to 8-bit in Pillow; exact inflated IDAT equality independently preserves every native sample bit.",
        "estimatedRuntimeRgba8Bytes": header["width"] * header["height"] * 4,
    }


def read_glb(blob):
    require(len(blob) >= 28, "Truncated GLB")
    magic, version, size = struct.unpack_from("<4sII", blob)
    require(magic == b"glTF" and version == 2 and size == len(blob), "Invalid GLB header/version/length")
    chunks, offset = [], 12
    while offset < len(blob):
        require(offset + 8 <= len(blob), "Truncated GLB chunk")
        length, kind = struct.unpack_from("<II", blob, offset)
        require(length % 4 == 0 and offset + 8 + length <= len(blob), "Invalid GLB chunk length")
        chunks.append((kind, blob[offset + 8:offset + 8 + length]))
        offset += 8 + length
    require([kind for kind, _ in chunks] == [0x4E4F534A, 0x004E4942], "Only JSON/BIN GLB delivery is supported")
    doc = json.loads(chunks[0][1])
    require(doc.get("asset", {}).get("version") == "2.0", "glTF asset.version must be 2.0")
    buffers = doc.get("buffers", [])
    require(len(buffers) == 1 and "uri" not in buffers[0], "Only one embedded buffer is supported")
    length = buffers[0]["byteLength"]
    require(isinstance(length, int) and 0 < length <= len(chunks[1][1]) and len(chunks[1][1]) - length <= 3, "Invalid BIN buffer length")
    payload = chunks[1][1][:length]
    for view in doc.get("bufferViews", []):
        start, count = view.get("byteOffset", 0), view["byteLength"]
        require(view.get("buffer") == 0 and isinstance(start, int) and isinstance(count, int)
                and start >= 0 and count > 0 and start + count <= len(payload), "Invalid bufferView bounds")
    return doc, payload


def write_glb(doc, payload):
    encoded = json.dumps(doc, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    encoded += b" " * (-len(encoded) % 4)
    binary = bytes(payload) + b"\0" * (-len(payload) % 4)
    return (struct.pack("<4sII", b"glTF", 2, 28 + len(encoded) + len(binary))
            + struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
            + struct.pack("<II", len(binary), 0x004E4942) + binary)


def view_bytes(doc, payload, vi):
    require(isinstance(vi, int) and 0 <= vi < len(doc.get("bufferViews", [])), "Invalid bufferView reference")
    view = doc["bufferViews"][vi]
    start = view.get("byteOffset", 0)
    return payload[start:start + view["byteLength"]]


def optimize_glb(original, level=9):
    doc, payload = read_glb(original)
    updated = copy.deepcopy(doc)
    replacements, image_reports, image_files = {}, [], []
    images = doc.get("images", [])
    require(images, "GLB contains no embedded images")
    for image_index, image in enumerate(images):
        require("uri" not in image and image.get("mimeType") == "image/png", "Only embedded PNG textures are supported")
        vi = image["bufferView"]
        require(vi not in replacements, "Shared image bufferViews need an explicit alias-preserving implementation")
        encoded = view_bytes(doc, payload, vi)
        optimized, receipt = optimize_png(encoded, level)
        replacements[vi] = optimized
        receipt.update(image=image_index, name=image.get("name"), bufferView=vi)
        image_reports.append(receipt)
        image_files.append(optimized)
    image_intervals = sorted((doc["bufferViews"][vi].get("byteOffset", 0),
                              doc["bufferViews"][vi].get("byteOffset", 0) + doc["bufferViews"][vi]["byteLength"], vi)
                             for vi in replacements)
    for i, (start, end, vi) in enumerate(image_intervals):
        require(i == 0 or image_intervals[i - 1][1] <= start, "Image bufferViews overlap")
        for other_vi, view in enumerate(doc["bufferViews"]):
            if other_vi == vi:
                continue
            other_start = view.get("byteOffset", 0)
            require(other_start >= end or other_start + view["byteLength"] <= start, "Image bufferView overlaps other data")
    for accessor in doc.get("accessors", []):
        require(accessor.get("bufferView") not in replacements, "An accessor aliases image data")
        if "sparse" in accessor:
            require(all(accessor["sparse"][k]["bufferView"] not in replacements for k in ("indices", "values")), "Sparse accessor aliases image data")
    output, cursor, shifts = bytearray(), 0, []
    for start, end, vi in image_intervals:
        output.extend(payload[cursor:start])
        updated["bufferViews"][vi]["byteOffset"] = len(output)
        optimized = replacements[vi]
        output.extend(optimized)
        # Keep every following source offset's alignment. Original gap bytes
        # are still copied verbatim; only fresh alignment bytes are inserted.
        output.extend(b"\0" * ((end - start - len(optimized)) % 4))
        updated["bufferViews"][vi]["byteLength"] = len(optimized)
        shifts.append((end, len(output) - end))
        cursor = end
    output.extend(payload[cursor:])
    for vi, view in enumerate(doc["bufferViews"]):
        if vi in replacements:
            continue
        start = view.get("byteOffset", 0)
        shift = next((amount for end, amount in reversed(shifts) if end <= start), 0)
        if shift or "byteOffset" in view:
            updated["bufferViews"][vi]["byteOffset"] = start + shift
    updated["buffers"][0]["byteLength"] = len(output)
    candidate = write_glb(updated, output)
    checked_doc, checked_payload = read_glb(candidate)
    preserved_views = []
    for vi in range(len(doc["bufferViews"])):
        if vi in replacements:
            continue
        before, after = view_bytes(doc, payload, vi), view_bytes(checked_doc, checked_payload, vi)
        require(before == after, f"Non-image bufferView {vi} changed")
        preserved_views.append({"bufferView": vi, "bytes": len(before), "sha256": sha(before)})
    # Normalize only permitted addressing fields and assert ALL other JSON is
    # identical, including accessors, UV bindings, materials, nodes and extras.
    normalized = copy.deepcopy(checked_doc)
    normalized["buffers"][0]["byteLength"] = doc["buffers"][0]["byteLength"]
    for vi, original_view in enumerate(doc["bufferViews"]):
        for key in ("byteOffset", "byteLength"):
            if key in original_view:
                normalized["bufferViews"][vi][key] = original_view[key]
            else:
                normalized["bufferViews"][vi].pop(key, None)
    require(normalized == doc, "GLB semantic metadata changed")
    for vi, encoded in replacements.items():
        require(view_bytes(checked_doc, checked_payload, vi) == encoded, "Repacked image bytes mismatch")
    report = {"schemaVersion": 1, "status": "private_lossless_encoding_candidate", "runtimePromoted": False,
              "visualApproval": False, "browserPixelComparison": "not_run", "compressionLevel": level,
              "sourceGlbSha256": sha(original), "candidateGlbSha256": sha(candidate),
              "sourceGlbBytes": len(original), "candidateGlbBytes": len(candidate), "savedGlbBytes": len(original)-len(candidate),
              "sourceTextureBytes": sum(r["originalBytes"] for r in image_reports),
              "candidateTextureBytes": sum(r["optimizedBytes"] for r in image_reports),
              "estimatedRuntimeRgba8BytesUnchanged": sum(r["estimatedRuntimeRgba8Bytes"] for r in image_reports),
              "runtimeMemoryMeasurement": "RGBA8 estimate before mipmaps; browser/GPU allocation not measured",
              "allNativeSampleBitsPreserved": True, "allNonIdatChunksPreserved": True,
              "allNonImageBufferViewsByteIdentical": True, "accessorMetadataUnchanged": True,
              "materialsNodesUvsExtrasUnchanged": True, "images": image_reports, "preservedBufferViews": preserved_views,
              "limitations": ["No reduction in texture resolution, native bit depth, decoded texel count or geometry.",
                              "Pixel preservation is not art approval or a device performance result.",
                              "No browser comparison was run by this tool."]}
    return candidate, image_files, report


def optimize_file(source, output_directory, level=9):
    source, output_directory = Path(source).resolve(), Path(output_directory).resolve()
    require(not output_directory.exists(), "Candidate output directory already exists; original exports must not be overwritten")
    require(not source.is_relative_to(output_directory), "Output directory contains source")
    original = source.read_bytes()
    candidate, images, report = optimize_glb(original, level)
    require(sha(source.read_bytes()) == report["sourceGlbSha256"], "Source changed during optimization")
    report["sourcePath"] = str(source)
    report["candidatePath"] = str(output_directory / source.name)
    output_directory.mkdir(parents=True, exist_ok=False)
    (output_directory / source.name).write_bytes(candidate)
    for receipt, image in zip(report["images"], images):
        name = f"image-{receipt['image']:02d}.png"
        (output_directory / name).write_bytes(image)
        receipt["candidateImageFile"] = name
    # Receipt is written last; a partial output directory has no success receipt.
    (output_directory / "texture-optimization-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--compression-level", type=int, default=9)
    args = parser.parse_args(argv)
    report = optimize_file(args.input, args.out_dir, args.compression_level)
    print(json.dumps({k: report[k] for k in ("status", "sourceGlbBytes", "candidateGlbBytes", "savedGlbBytes", "sourceTextureBytes", "candidateTextureBytes", "candidateGlbSha256", "candidatePath")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
