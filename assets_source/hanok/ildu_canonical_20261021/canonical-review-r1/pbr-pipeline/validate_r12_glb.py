"""Validate the uncompressed R12 delivery contract without starting Blender.

Requires NumPy and Pillow. Structural ``passed`` and ``surfaceGate`` are separate;
consumers must require both. A passing structural report is not visual approval,
an atlas-density assessment, or a device performance result. Budgets are supplied
explicitly; omitted thresholds are reported as not configured.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import struct
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
from PIL import Image

SOURCE_ID = "_P17_SOURCE_OBJECT_ID"
COMPONENTS = {5120: "i1", 5121: "u1", 5122: "<i2", 5123: "<u2", 5125: "<u4", 5126: "<f4"}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16}
SURFACE_TOLERANCES = {"worldAreaEpsilon": 1e-12, "unitLengthAbsolute": 1e-3,
                      "normalTangentDotAbsolute": 1e-3, "handednessAbsolute": 1e-4}


class InvalidDelivery(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise InvalidDelivery(message)


def integer(value, label, minimum=0):
    require(isinstance(value, int) and not isinstance(value, bool) and value >= minimum,
            f"{label} must be an integer >= {minimum}")
    return value


def index(items, value, label):
    integer(value, label)
    require(value < len(items), f"{label} is out of range: {value}")
    return items[value]


def json_bytes(data):
    def invalid_constant(value):
        raise InvalidDelivery(f"Non-finite JSON constant: {value}")
    return json.loads(data, parse_constant=invalid_constant)


def sha(data):
    return hashlib.sha256(data).hexdigest()


class Glb:
    """Bounds-check all views/accessors before exposing zero-copy numeric arrays."""

    def __init__(self, blob):
        self.blob = blob
        require(len(blob) >= 20, "Truncated GLB header")
        magic, version, length = struct.unpack_from("<4sII", blob)
        require(magic == b"glTF", "Invalid GLB magic")
        require(version == 2, "GLB version must be 2")
        require(length == len(blob), "GLB declared length differs from file length")
        chunks, offset = [], 12
        while offset < len(blob):
            require(offset + 8 <= len(blob), "Truncated chunk header")
            size, kind = struct.unpack_from("<II", blob, offset)
            require(size % 4 == 0, "GLB chunk length must be 4-byte aligned")
            offset += 8
            require(offset + size <= len(blob), "GLB chunk extends past file")
            chunks.append((kind, memoryview(blob)[offset:offset + size]))
            offset += size
        require(len(chunks) == 2 and [c[0] for c in chunks] == [0x4E4F534A, 0x004E4942],
                "R12 delivery requires exactly JSON then BIN chunks")
        self.doc = json_bytes(bytes(chunks[0][1]))
        require(self.doc.get("asset", {}).get("version") == "2.0", "asset.version must be 2.0")
        self.payload = chunks[1][1]
        buffers = self.doc.get("buffers", [])
        require(len(buffers) == 1 and "uri" not in buffers[0], "R12 requires one embedded buffer")
        length = integer(buffers[0].get("byteLength"), "buffer.byteLength", 1)
        require(0 <= len(self.payload) - length <= 3, "BIN size differs from declared buffer length")
        self.buffer_length = length
        self.views = self.doc.get("bufferViews", [])
        for i, view in enumerate(self.views):
            require(view.get("buffer") == 0, f"bufferView {i} uses an external buffer")
            start = integer(view.get("byteOffset", 0), f"bufferView {i} offset")
            size = integer(view.get("byteLength"), f"bufferView {i} length", 1)
            require(start + size <= length, f"bufferView {i} exceeds buffer bounds")
            if "byteStride" in view:
                stride = integer(view["byteStride"], f"bufferView {i} stride", 4)
                require(stride <= 252 and stride % 4 == 0, f"bufferView {i} has invalid stride")
        self.arrays = {}
        for i in range(len(self.doc.get("accessors", []))):
            self.array(i)

    def view(self, view_index):
        view = index(self.views, view_index, "bufferView index")
        start = view.get("byteOffset", 0)
        return self.payload[start:start + view["byteLength"]]

    def array(self, accessor_index):
        if accessor_index in self.arrays:
            return self.arrays[accessor_index]
        a = index(self.doc.get("accessors", []), accessor_index, "accessor index")
        require("sparse" not in a, "Sparse accessors are outside the R12 uncompressed delivery contract")
        view = index(self.views, a.get("bufferView"), "accessor bufferView")
        component = a.get("componentType")
        require(component in COMPONENTS and a.get("type") in WIDTHS, "Unsupported accessor layout")
        dtype = np.dtype(COMPONENTS[component])
        count = integer(a.get("count"), "accessor count", 1)
        offset = integer(a.get("byteOffset", 0), "accessor byteOffset")
        width = WIDTHS[a["type"]]
        # Matrix columns have 4-byte padding for 8/16-bit components.
        if a["type"].startswith("MAT"):
            rows = int(a["type"][-1])
            column_size = ((rows * dtype.itemsize + 3) // 4) * 4
            offsets = [col * column_size + row * dtype.itemsize for col in range(rows) for row in range(rows)]
            element_size = rows * column_size
        else:
            offsets = [j * dtype.itemsize for j in range(width)]
            element_size = width * dtype.itemsize
        stride = view.get("byteStride", element_size)
        require(stride >= element_size and stride % dtype.itemsize == 0, "Accessor stride is smaller than element")
        start = view.get("byteOffset", 0) + offset
        require(offset % dtype.itemsize == 0 and start % dtype.itemsize == 0, "Misaligned accessor")
        require(offset + (count - 1) * stride + element_size <= view["byteLength"],
                f"Accessor {accessor_index} exceeds its bufferView")
        if offsets == [j * dtype.itemsize for j in range(width)]:
            data = np.ndarray((count, width), dtype=dtype, buffer=self.payload, offset=start,
                              strides=(stride, dtype.itemsize))
        else:
            data = np.column_stack([np.ndarray((count,), dtype=dtype, buffer=self.payload,
                                               offset=start + o, strides=(stride,)) for o in offsets])
        require(np.isfinite(data).all(), f"Accessor {accessor_index} contains non-finite values")
        for bound in ("min", "max"):
            if bound in a:
                vals = np.asarray(a[bound], dtype=float)
                require(vals.shape == (width,) and np.isfinite(vals).all(), f"Invalid accessor {bound}")
        self.arrays[accessor_index] = data
        return data


def node_matrix(node):
    if "matrix" in node:
        require(not any(k in node for k in ("translation", "rotation", "scale")), "Node mixes matrix and TRS")
        values = np.asarray(node["matrix"], dtype=float)
        require(values.shape == (16,) and np.isfinite(values).all(), "Invalid node matrix")
        return values.reshape(4, 4).T
    t = np.asarray(node.get("translation", [0, 0, 0]), dtype=float)
    q = np.asarray(node.get("rotation", [0, 0, 0, 1]), dtype=float)
    s = np.asarray(node.get("scale", [1, 1, 1]), dtype=float)
    require(t.shape == (3,) and q.shape == (4,) and s.shape == (3,), "Invalid node TRS shape")
    require(all(np.isfinite(v).all() for v in (t, q, s)), "Non-finite node transform")
    require(abs(float(np.linalg.norm(q)) - 1) < 1e-4, "Node quaternion is not normalized")
    x, y, z, w = q
    result = np.eye(4)
    result[:3, :3] = np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                               [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                               [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]]) @ np.diag(s)
    result[:3, 3] = t
    return result


def active_nodes(doc):
    nodes = doc.get("nodes", [])
    scene = index(doc.get("scenes", []), doc.get("scene", 0), "default scene")
    seen, result = set(), {}

    def visit(node_index, parent):
        node = index(nodes, node_index, "scene node")
        require(node_index not in seen, "Cycle or multiply-parented node in active scene")
        seen.add(node_index)
        world = parent @ node_matrix(node)
        require(np.isfinite(world).all(), "Non-finite composed node transform")
        result[node_index] = world
        for child in node.get("children", []):
            visit(child, world)

    for root in scene.get("nodes", []):
        visit(root, np.eye(4))
    require(result, "Default scene has no nodes")
    return result


def image_info(glb):
    result = []
    for i, image in enumerate(glb.doc.get("images", [])):
        require("uri" not in image and "bufferView" in image, "Delivery images must be embedded")
        data = bytes(glb.view(image["bufferView"]))
        require(image.get("mimeType") in ("image/png", "image/jpeg"), "Unsupported delivery image MIME type")
        with Image.open(io.BytesIO(data)) as decoded:
            expected_format = "PNG" if image["mimeType"] == "image/png" else "JPEG"
            require(decoded.format == expected_format, "Image MIME type differs from encoded data")
            decoded.verify()
        with Image.open(io.BytesIO(data)) as decoded:
            decoded.load()
            has_alpha = "A" in decoded.getbands() or "transparency" in decoded.info
            rgba = decoded.convert("RGBA")
            extrema = rgba.getextrema()
            result.append({"image": i, "name": image.get("name"), "bytes": len(data), "sha256": sha(data),
                           "width": decoded.width, "height": decoded.height, "mode": decoded.mode,
                           "hasAlpha": has_alpha, "channelExtremaRGBA": [list(v) for v in extrema],
                           "alpha8Sha256": sha(rgba.getchannel("A").tobytes()),
                           "pngBitDepth": data[24] if decoded.format == "PNG" else None,
                           "rgba8DecodedBytes": decoded.width * decoded.height * 4,
                           "bufferView": image["bufferView"]})
    return result


def surface_frames(data, triangles, world):
    """Read-only frame audit; only incident positive-area triangles can fail.

    Unit/orthogonality checks use the encoded local frame. World triangle area
    uses the composed node transform in float64, matching the UV audit basis.
    Degenerates retain their geometry, IDs, attributes and separate diagnostics.
    """
    tolerances = SURFACE_TOLERANCES
    normal = data["NORMAL"].astype(np.float64)
    tangent = data["TANGENT"].astype(np.float64)
    normal_length = np.linalg.norm(normal, axis=1)
    tangent_length = np.linalg.norm(tangent[:, :3], axis=1)
    denominator = normal_length * tangent_length
    dot = np.divide(np.abs(np.einsum('ij,ij->i', normal, tangent[:, :3])), denominator,
                    out=np.zeros(len(normal)), where=denominator != 0)
    vertices = {
        "non_unit_normal": np.abs(normal_length - 1) > tolerances["unitLengthAbsolute"],
        "non_unit_tangent": np.abs(tangent_length - 1) > tolerances["unitLengthAbsolute"],
        "invalid_tangent_handedness": np.abs(np.abs(tangent[:, 3]) - 1) > tolerances["handednessAbsolute"],
        "nonorthogonal_tangent": dot > tolerances["normalTangentDotAbsolute"],
    }
    reasons = {name: mask[triangles].any(axis=1) for name, mask in vertices.items()}
    signs = np.sign(tangent[triangles, 3])
    reasons["inconsistent_triangle_handedness"] = np.any(signs != signs[:, :1], axis=1)
    local = data["POSITION"].astype(np.float64)
    positions = local @ world[:3, :3].T + world[:3, 3]
    points = positions[triangles]
    areas = np.linalg.norm(np.cross(points[:, 1] - points[:, 0], points[:, 2] - points[:, 0]), axis=1) * .5
    require(np.isfinite(areas).all(), "Non-finite world triangle area")
    positive = areas > tolerances["worldAreaEpsilon"]
    invalid = np.logical_or.reduce(list(reasons.values()))
    return {"areas": areas, "positive": positive, "invalid": invalid, "reasons": reasons,
            "invalidVertices": np.logical_or.reduce(list(vertices.values())),
            "zeroTangentVertices": int(np.count_nonzero(tangent_length == 0)),
            "reasonVertexCounts": {name: int(mask.sum()) for name, mask in vertices.items()}}


def validate(glb_path, parts_path, *, owner_map_path=None, receipt_path=None, budgets=None):
    """Return JSON-safe diagnostics; malformed or incomplete inputs fail closed."""
    report = {"schemaVersion": 2, "validator": "R12 GLB structural preservation",
              "passed": False, "visualApproval": False, "runtimePromoted": False,
              "surfaceGate": "not_evaluated", "surfaceErrors": [],
              "surfaceAudit": {"schemaVersion": 1, "tolerances": dict(SURFACE_TOLERANCES),
                               "areaBasis": "decoded Float32 positions with composed node world transform, computed in float64",
                               "frameBasis": "encoded local NORMAL/TANGENT; no attribute normalization or mutation",
                               "degeneratePolicy": "retain all triangles and IDs; exempt only area <= worldAreaEpsilon from surface failures",
                               "nativeDegenerateIdentityIndependentlyVerified": False,
                               "parts": []},
              "errors": [], "warnings": [], "budgetGate": "not_configured", "budgets": [],
              "limitations": ["No image/render parity, atlas density, or device performance approval.",
                              "Source receipts are compared as supplied; native Blender state is not reopened."]}

    def error(code, message):
        report["errors"].append({"code": code, "message": message})

    try:
        blob, parts_bytes = Path(glb_path).read_bytes(), Path(parts_path).read_bytes()
        report["inputs"] = {"glb": str(Path(glb_path).resolve()), "glbSha256": sha(blob),
                            "parts": str(Path(parts_path).resolve()), "partsSha256": sha(parts_bytes)}
        sidecar, glb = json_bytes(parts_bytes), Glb(blob)
        doc = glb.doc
        parts = sidecar.get("parts", [])
        require(parts, "Source parts sidecar is empty")
        by_id, by_name = {}, {}
        for part in parts:
            pid = integer(part.get("partId"), "source part ID")
            name = part.get("sourceObject")
            require(isinstance(name, str) and name, "Invalid source name")
            require(pid not in by_id and name not in by_name, "Duplicate source ID or name")
            by_id[pid], by_name[name] = part, pid
            require(isinstance(part.get("evaluatedEmpty"), bool), "Source lacks evaluatedEmpty flag")
            matrix = np.asarray(part.get("sourceWorld"), dtype=float)
            require(matrix.shape == (4, 4) and np.isfinite(matrix).all(), "Invalid sourceWorld matrix")
        if owner_map_path:
            map_bytes = Path(owner_map_path).read_bytes()
            owner_map = json_bytes(map_bytes)
            groups = [g for g in owner_map["groups"] if g["nativeOwner"] == sidecar["owner"]]
            require(len(groups) == 1, "Expected exactly one owner-map group")
            expected_names = groups[0]["sourceObjects"]
            require(len(set(expected_names)) == len(expected_names), "Duplicate source name in owner map")
            require(set(expected_names) == set(by_name), "Sidecar source membership differs from owner map")
            if "sourceNative" in owner_map:
                require(owner_map["sourceNative"].get("sha256") == sidecar.get("candidateSha256"),
                        "Owner map native binding differs from sidecar")
            report["inputs"]["ownerMapSha256"] = sha(map_bytes)
        else:
            report["warnings"].append("No owner map supplied: membership checked against sidecar only.")
        if receipt_path:
            receipt_bytes = Path(receipt_path).read_bytes()
            receipt = json_bytes(receipt_bytes)
            owner_receipt = next((r for r in receipt.get("owners", []) if r["owner"] == sidecar["owner"]), receipt)
            require(owner_receipt.get("sha256") == sha(blob), "Export receipt GLB hash mismatch")
            require(owner_receipt.get("sourcePartsSha256") == sha(parts_bytes), "Export receipt sidecar hash mismatch")
            require(owner_receipt.get("sourceParts") == len(parts), "Export receipt part count mismatch")
            require(owner_receipt.get("candidateSha256") == sidecar.get("candidateSha256"), "Native binding mismatch")
            if owner_map_path and "ownerMapSha256" in receipt:
                require(receipt["ownerMapSha256"] == report["inputs"]["ownerMapSha256"], "Receipt owner map hash mismatch")
            report["inputs"]["receiptSha256"] = sha(receipt_bytes)
        images = image_info(glb)
        report["images"] = images
        worlds = active_nodes(doc)
        mesh_nodes = {i for i in worlds if "mesh" in doc["nodes"][i]}
        require(mesh_nodes, "No active mesh nodes")
        require({doc["nodes"][i]["mesh"] for i in mesh_nodes} == set(range(len(doc.get("meshes", [])))),
                "Delivery has unused meshes outside the active scene")
        declared_ranges = defaultdict(list)
        for pid, part in by_id.items():
            nodes = part.get("glbNodeIndices", [])
            require(len(nodes) == len(set(nodes)), "Duplicate source glbNodeIndices")
            for ni in nodes:
                index(doc["nodes"], ni, "source node index")
                require(ni in worlds, "Source node is not in active scene")
            if part["evaluatedEmpty"]:
                require(nodes and not part.get("glbTriangleRanges"), "Empty source lacks identity-only node")
                require(all("mesh" not in doc["nodes"][ni] and doc["nodes"][ni].get("extras", {}).get("p17EmptyEvaluatedMesh")
                            and doc["nodes"][ni].get("extras", {}).get("p17SourcePartId") == pid for ni in nodes),
                        "Invalid empty source identity node")
            for r in part.get("glbTriangleRanges", []):
                for key in ("node", "mesh", "primitive", "firstTriangle", "endTriangle"):
                    integer(r.get(key), f"triangle range {key}")
                require(r["node"] in nodes and r["endTriangle"] > r["firstTriangle"], "Invalid source triangle range")
                declared_ranges[(r["node"], r["mesh"], r["primitive"])].append((r["firstTriangle"], r["endTriangle"], pid))
        actual_counts, actual_nodes = Counter(), defaultdict(set)
        part_bounds = {pid: [np.full(3, np.inf), np.full(3, -np.inf)] for pid in by_id}
        geometry_views, primitive_keys, used_materials = set(), set(), set()
        vertex_count = triangle_count = primitive_count = 0
        normal_deviations = tangent_deviations = uv_outside = 0
        surface_counts, reason_counts = Counter(), defaultdict(Counter)
        for ni in sorted(mesh_nodes):
            node = doc["nodes"][ni]
            require("skin" not in node, "Skinned delivery needs a separate evaluated-pose validator")
            mesh_index = node["mesh"]
            mesh = index(doc.get("meshes", []), mesh_index, "node mesh")
            for pi, primitive in enumerate(mesh.get("primitives", [])):
                key = (ni, mesh_index, pi)
                primitive_keys.add(key)
                require(primitive.get("mode", 4) == 4 and not primitive.get("targets"), "R12 requires static TRIANGLES primitives")
                require(not primitive.get("extensions"), "Compressed/extended primitives need a separate decoder")
                attrs = primitive.get("attributes", {})
                required = {"POSITION": 3, "NORMAL": 3, "TANGENT": 4, "TEXCOORD_0": 2, SOURCE_ID: 1}
                require(set(required) <= set(attrs), f"Primitive {key} is missing required attributes")
                data = {name: glb.array(ai) for name, ai in attrs.items()}
                count = len(data["POSITION"])
                require(all(len(v) == count for v in data.values()), "Primitive attribute counts differ")
                for name, width in required.items():
                    require(data[name].shape[1] == width, f"Incorrect {name} width")
                    accessor = doc["accessors"][attrs[name]]
                    require(not accessor.get("normalized", False), f"R12 {name} must be unnormalized")
                    if name != SOURCE_ID:
                        require(accessor["componentType"] == 5126, f"R12 {name} must be float")
                ids = data[SOURCE_ID][:, 0]
                require(np.equal(ids, np.floor(ids)).all(), "Non-integer source part ID")
                require(set(np.unique(ids).tolist()) <= set(by_id), "Foreign source part ID")
                ids = ids.astype(np.int64)
                indices = glb.array(primitive.get("indices"))
                ia = doc["accessors"][primitive["indices"]]
                require(ia["componentType"] in (5121, 5123, 5125) and ia["type"] == "SCALAR"
                        and not ia.get("normalized", False), "Triangle indices must be unsigned scalar integers")
                require(len(indices) % 3 == 0 and int(indices.max()) < count, "Invalid triangle index count or vertex index")
                triangles = indices[:, 0].reshape(-1, 3)
                triangle_ids = ids[triangles]
                require(np.equal(triangle_ids, triangle_ids[:, :1]).all(), "Triangle mixes source part IDs")
                per_triangle = triangle_ids[:, 0]
                ranges = sorted(declared_ranges.get(key, []))
                cursor = 0
                for first, end, pid in ranges:
                    require(first == cursor and end <= len(triangles), "Triangle ranges overlap, have gaps, or exceed primitive")
                    require(np.equal(per_triangle[first:end], pid).all(), "Triangle range points to another source part")
                    cursor = end
                require(cursor == len(triangles), "Triangle ranges do not cover every exported triangle")
                for pid, amount in zip(*np.unique(per_triangle, return_counts=True)):
                    pid = int(pid)
                    require(not by_id[pid]["evaluatedEmpty"], "Empty source exported triangles")
                    actual_counts[pid] += int(amount)
                    actual_nodes[pid].add(ni)
                    selected_indices = np.unique(triangles[per_triangle == pid])
                    local = data["POSITION"][selected_indices].astype(np.float64)
                    world = local @ worlds[ni][:3, :3].T + worlds[ni][:3, 3]
                    # Blender Z-up -> glTF Y-up: (x,y,z) -> (x,z,-y).
                    blender_world = world[:, [0, 2, 1]] * np.array([1, -1, 1])
                    part_bounds[pid][0] = np.minimum(part_bounds[pid][0], blender_world.min(axis=0))
                    part_bounds[pid][1] = np.maximum(part_bounds[pid][1], blender_world.max(axis=0))
                frame = surface_frames(data, triangles, worlds[ni])
                positive, invalid = frame["positive"], frame["invalid"]
                surface_counts.update(trianglesEvaluated=len(triangles), positiveWorldAreaTriangles=int(positive.sum()),
                    degenerateWorldAreaTriangles=int((~positive).sum()), invalidFrameVertices=int(frame["invalidVertices"].sum()),
                    zeroTangentVertices=frame["zeroTangentVertices"], invalidFrameTriangleIncidents=int(invalid.sum()),
                    failingPositiveWorldAreaTriangles=int((invalid & positive).sum()),
                    retainedDegenerateInvalidFrameTriangles=int((invalid & ~positive).sum()))
                for reason, mask in frame["reasons"].items():
                    reason_counts[reason].update(invalidVertices=frame["reasonVertexCounts"].get(reason, 0),
                        positiveWorldAreaTriangles=int((mask & positive).sum()),
                        retainedDegenerateTriangles=int((mask & ~positive).sum()))
                for pid in np.unique(per_triangle[invalid]):
                    selected = invalid & (per_triangle == pid)
                    failing = selected & positive
                    row = {"partId": int(pid), "sourceObject": by_id[int(pid)]["sourceObject"],
                           "node": ni, "mesh": mesh_index, "primitive": pi,
                           "invalidFrameTriangleIncidents": int(selected.sum()),
                           "failingPositiveWorldAreaTriangles": int(failing.sum()),
                           "retainedDegenerateInvalidFrameTriangles": int((selected & ~positive).sum()),
                           "samples": [{"triangle": int(ti), "worldArea": float(frame["areas"][ti]),
                                        "positiveWorldArea": bool(positive[ti]),
                                        "vertices": triangles[ti].tolist(),
                                        "reasons": [name for name, mask in frame["reasons"].items() if mask[ti]]}
                                       for ti in np.flatnonzero(selected)[:16]]}
                    report["surfaceAudit"]["parts"].append(row)
                    if failing.any():
                        report["surfaceErrors"].append({"code": "invalid_surface_frame", "partId": int(pid),
                            "sourceObject": row["sourceObject"], "node": ni, "mesh": mesh_index, "primitive": pi,
                            "positiveWorldAreaTriangles": int(failing.sum())})
                normal_deviations += int(np.count_nonzero(np.abs(np.linalg.norm(data["NORMAL"], axis=1) - 1) > 1e-3))
                tangent_deviations += int(np.count_nonzero((np.abs(np.linalg.norm(data["TANGENT"][:, :3], axis=1)-1) > 1e-3)
                                                           | (np.abs(np.abs(data["TANGENT"][:, 3])-1) > 1e-4)))
                uv_outside += int(np.count_nonzero(np.any((data["TEXCOORD_0"] < -1e-5) | (data["TEXCOORD_0"] > 1+1e-5), axis=1)))
                for ai in [*attrs.values(), primitive["indices"]]:
                    geometry_views.add(doc["accessors"][ai]["bufferView"])
                used_materials.add(primitive.get("material"))
                vertex_count += count
                triangle_count += len(triangles)
                primitive_count += 1
        require(set(declared_ranges) <= primitive_keys, "Sidecar contains ranges for nonexistent/unused primitives")
        source_results, bounds_compared, bounds_failed = [], 0, 0
        for pid, part in by_id.items():
            faces = integer(part.get("evaluatedFaceCount"), "evaluatedFaceCount")
            loops = integer(part.get("evaluatedLoopCount"), "evaluatedLoopCount")
            require(loops >= 3 * faces, "Source polygon domain counts are inconsistent")
            expected = loops - 2 * faces
            if not part["evaluatedEmpty"]:
                if actual_counts[pid] != expected or expected == 0:
                    error("source_triangle_count", f"{part['sourceObject']}: exported {actual_counts[pid]} vs source triangulation {expected}")
                require(actual_nodes[pid] == set(part.get("glbNodeIndices", [])), "Source node coverage differs from decoded IDs")
            source_result = {"partId": pid, "sourceObject": part["sourceObject"], "empty": part["evaluatedEmpty"],
                             "expectedTriangles": expected, "actualTriangles": actual_counts[pid],
                             "decodedWorldBoundsBlender": None if not actual_counts[pid] else [v.tolist() for v in part_bounds[pid]]}
            if part.get("evaluatedWorldBounds") is not None and actual_counts[pid]:
                bound = part["evaluatedWorldBounds"]
                expected_bound = np.asarray([bound["min"], bound["max"]], dtype=float)
                require(expected_bound.shape == (2, 3) and np.isfinite(expected_bound).all()
                        and np.all(expected_bound[0] <= expected_bound[1]), "Invalid evaluatedWorldBounds")
                delta = float(np.max(np.abs(expected_bound - np.asarray(part_bounds[pid]))))
                source_result["worldBoundsMaxAbsoluteError"] = delta
                bounds_compared += 1
                if delta > 1e-4:
                    bounds_failed += 1
                    error("source_world_bounds", f"{part['sourceObject']}: world bounds error {delta} exceeds 0.0001")
            source_results.append(source_result)
        report["sourceParts"] = source_results
        nonempty_parts = sum(not p["evaluatedEmpty"] for p in parts)
        report["worldBoundsGate"] = ("failed" if bounds_failed else "passed" if bounds_compared == nonempty_parts
                                     else "source_bounds_incomplete" if bounds_compared else "source_bounds_not_provided")
        report["worldBoundsComparedParts"] = bounds_compared
        report["worldBoundsTolerance"] = 1e-4
        report["limitations"].append("Bounds and triangle counts cannot prove every evaluated vertex/normal equals its native source.")
        channel_results = []
        for mi in sorted(used_materials):
            material = index(doc.get("materials", []), mi, "primitive material")
            pbr = material.get("pbrMetallicRoughness", {})
            specular = material.get("extensions", {}).get("KHR_materials_specular", {})
            channels = {"baseColor": pbr.get("baseColorTexture"), "normal": material.get("normalTexture"),
                        "roughnessMetallic": pbr.get("metallicRoughnessTexture"), "specular": specular.get("specularTexture")}
            require("KHR_materials_specular" in doc.get("extensionsUsed", []), "Specular extension is not declared")
            for channel, info in channels.items():
                require(isinstance(info, dict), f"Material {mi} lacks {channel} texture")
                texture = index(doc.get("textures", []), info.get("index"), "texture index")
                image = index(images, texture.get("source"), "texture image")
                require(info.get("texCoord", 0) == 0 and not info.get("extensions"), "Unexpected texture coordinates or transform")
                if channel == "specular" and not image["hasAlpha"]:
                    error("specular_alpha_missing", f"Material {mi} specularTexture image {image['image']} is {image['mode']}; KHR reads alpha, which defaults to 1")
                if channel == "specular":
                    factor = specular.get("specularFactor", 1.0)
                    require(isinstance(factor, (int, float)) and 0 <= factor <= 1, "Invalid specularFactor")
                    image["specularFactor"] = factor
                    image["sampledSpecularStrengthRange"] = [v / 255 * factor for v in image["channelExtremaRGBA"][3]]
                    source_channels = [c for c in sidecar.get("channels", []) if c.get("channel") == "specular"]
                    if source_channels:
                        require(len(source_channels) == 1, "Duplicate source specular channel")
                        source_channel = source_channels[0]
                        folder = Path(parts_path).resolve().parent
                        source_file = (folder / source_channel["file"]).resolve()
                        require(source_file.is_relative_to(folder), "Source channel path escapes delivery folder")
                        source_bytes = source_file.read_bytes()
                        require(sha(source_bytes) == source_channel["sha256"], "Source specular PNG hash mismatch")
                        with Image.open(io.BytesIO(source_bytes)) as decoded:
                            if "A" not in decoded.getbands() and "transparency" not in decoded.info:
                                error("source_specular_alpha_missing", "Source packed specular PNG also lacks alpha")
                            else:
                                expected_alpha = sha(decoded.convert("RGBA").getchannel("A").tobytes())
                                require(expected_alpha == image["alpha8Sha256"]
                                        and list(decoded.size) == [image["width"], image["height"]],
                                        "Embedded specular alpha differs from packed source PNG")
                                require(abs(factor - 1) < 1e-6, "Packed source specular alpha is scaled again by glTF factor")
                                image["packedSourceAlphaParity"] = "passed"
                    else:
                        report["warnings"].append("No packed source specular channel receipt: encoded alpha is measured, not compared to bake output.")
                if channel in ("normal", "roughnessMetallic") and image["mode"] not in ("RGB", "RGBA"):
                    error("texture_channels", f"{channel} requires RGB channels, got {image['mode']}")
                channel_results.append({"material": mi, "channel": channel, "image": image["image"],
                                        "sampledChannels": {"baseColor": "RGBA", "normal": "RGB", "roughnessMetallic": "G=roughness,B=metallic", "specular": "A"}[channel]})
        report["materialChannels"] = channel_results
        image_views = {v["bufferView"] for v in images}
        require(not geometry_views & image_views, "Geometry and images share a bufferView")
        metrics = {"glbBytes": len(blob), "textureBytes": sum(v["bytes"] for v in images),
                   "textureRgba8DecodedBytes": sum(v["rgba8DecodedBytes"] for v in images),
                   "geometryBytes": sum(glb.views[i]["byteLength"] for i in geometry_views),
                   "triangles": triangle_count, "vertices": vertex_count, "sourceParts": len(parts),
                   "activeMeshNodes": len(mesh_nodes), "primitives": primitive_count, "images": len(images),
                   "materials": len(used_materials), "nonUnitNormals": normal_deviations,
                   "nonUnitTangents": tangent_deviations, "uvVerticesOutsideAtlas": uv_outside}
        report["metrics"] = metrics
        report["surfaceAudit"]["counts"] = dict(surface_counts)
        report["surfaceAudit"]["reasonCounts"] = {name: dict(counts) for name, counts in reason_counts.items()}
        report["surfaceGate"] = "failed" if report["surfaceErrors"] else "passed"
        if normal_deviations or tangent_deviations:
            report["warnings"].append("Non-unit frame vectors exist: consult the mandatory surfaceGate; structural passed does not establish surface validity.")
        if uv_outside:
            report["warnings"].append("Finite atlas UVs extend outside [0,1]; inspect wrapping and coverage.")
        for key, maximum in (budgets or {}).items():
            require(key in metrics and isinstance(maximum, int) and maximum > 0, "Invalid explicit budget")
            passed = metrics[key] <= maximum
            report["budgets"].append({"metric": key, "actual": metrics[key], "maximum": maximum, "passed": passed})
            if not passed:
                error("budget_exceeded", f"{key}: {metrics[key]} exceeds {maximum}")
        if report["budgets"]:
            report["budgetGate"] = "passed" if all(v["passed"] for v in report["budgets"]) else "failed"
    except (InvalidDelivery, ValueError, TypeError, KeyError, IndexError, OSError, struct.error, RecursionError) as exc:
        error("invalid_delivery", str(exc))
    report["passed"] = not report["errors"]
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--glb", required=True, type=Path)
    parser.add_argument("--parts", required=True, type=Path)
    parser.add_argument("--owner-map", type=Path)
    parser.add_argument("--export-receipt", type=Path)
    parser.add_argument("--out", required=True, type=Path)
    budget_flags = {"glb-bytes": "glbBytes", "texture-bytes": "textureBytes", "geometry-bytes": "geometryBytes",
                    "triangles": "triangles", "vertices": "vertices", "texture-rgba8-bytes": "textureRgba8DecodedBytes"}
    for flag in budget_flags:
        parser.add_argument("--max-" + flag, type=int)
    args = parser.parse_args(argv)
    budgets = {metric: getattr(args, "max_" + flag.replace("-", "_")) for flag, metric in budget_flags.items()
               if getattr(args, "max_" + flag.replace("-", "_")) is not None}
    report = validate(args.glb, args.parts, owner_map_path=args.owner_map, receipt_path=args.export_receipt, budgets=budgets)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": report["passed"], "errors": report["errors"], "metrics": report.get("metrics"),
                      "surfaceGate": report["surfaceGate"], "surfaceErrors": report["surfaceErrors"],
                      "budgetGate": report["budgetGate"], "report": str(args.out)}, ensure_ascii=False))
    return 0 if report["passed"] and report["surfaceGate"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
