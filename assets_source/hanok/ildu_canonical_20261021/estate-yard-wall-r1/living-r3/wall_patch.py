"""R3 stone-wall surface study; call patch_walls(scene) from the integration script.

No operator, save, render, geometry, transform, UV or attribute writes. Only the
explicit R1 wall slots are rebound to copied materials. No bpy import side effect.
"""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROLES = {"stone", "mortar", "earthwall"}
REPORT = {}


def wall_bindings():
    """Exact whitelist; no object-name prefix or material-name fuzzy matching."""
    return [r for r in json.loads((ROOT / "material-changes.json").read_text(
        encoding="utf-8")) if r["role"] in ROLES]


def _node(t, kind, label):
    n = t.nodes.new(kind)
    n.name = "LR3 wall | " + label
    n.label = label
    return n


def _set(t, socket, value):
    if hasattr(value, "node"):
        t.links.new(value, socket)
    else:
        socket.default_value = value


def _math(t, operation, a, b, label):
    n = _node(t, "ShaderNodeMath", label)
    n.operation = operation
    _set(t, n.inputs[0], a)
    _set(t, n.inputs[1], b)
    return n.outputs[0]


def _vec(t, operation, a, b, label):
    n = _node(t, "ShaderNodeVectorMath", label)
    n.operation = operation
    _set(t, n.inputs[0], a)
    _set(t, n.inputs[1], b)
    return n.outputs["Value" if operation == "DISTANCE" else "Vector"]


def _range(t, value, lo, hi, label, in_lo=0.0, in_hi=1.0):
    n = _node(t, "ShaderNodeMapRange", label)
    n.clamp = True
    n.interpolation_type = "SMOOTHERSTEP"
    _set(t, n.inputs["Value"], value)
    n.inputs["From Min"].default_value = in_lo
    n.inputs["From Max"].default_value = in_hi
    n.inputs["To Min"].default_value = lo
    n.inputs["To Max"].default_value = hi
    return n.outputs["Result"]


def _noise(t, p, scale, detail, label):
    n = _node(t, "ShaderNodeTexNoise", label)
    _set(t, n.inputs["Vector"], p)
    n.inputs["Scale"].default_value = scale
    n.inputs["Detail"].default_value = detail
    n.inputs["Roughness"].default_value = 0.61
    return n


def _mix(t, a, b, factor, label, mode="MIX"):
    n = _node(t, "ShaderNodeMixRGB", label)
    n.blend_type = mode
    for socket, value in zip(n.inputs, (factor, a, b)):
        _set(t, socket, value)
    return n.outputs[0]


def _source(socket):
    return socket.links[0].from_socket if socket.is_linked else tuple(socket.default_value)


def _contact_anchors(scene, rows):
    """Read native ground once, then find sparse actual wall/soil contacts.

    Uses raw mesh vertices and world matrices; never evaluates/mutates depsgraph.
    Returns numeric coordinates only: the shader has no object references.
    """
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree

    ground_names = {r["object"] for r in json.loads((ROOT / "material-changes.json").read_text(
        encoding="utf-8")) if r["role"] == "yard"}
    trees = []
    for name in sorted(ground_names):
        obj = scene.objects.get(name)
        if obj is None or obj.type != "MESH":
            continue
        verts = [tuple(obj.matrix_world @ v.co) for v in obj.data.vertices]
        faces = [tuple(p.vertices) for p in obj.data.polygons]
        trees.append(BVHTree.FromPolygons(verts, faces, all_triangles=False))
    if not trees:
        return []

    candidates = []
    for name in sorted({r["object"] for r in rows if r["role"] == "stone"}):
        obj = scene.objects[name]
        # Lowest point in a coarse XY cell finds the existing bottom envelope,
        # including sloped walls; it does not manufacture a horizontal datum.
        cells = {}
        for vertex in obj.data.vertices:
            p = obj.matrix_world @ vertex.co
            key = (math.floor(p.x / 0.8), math.floor(p.y / 0.8))
            if key not in cells or p.z < cells[key].z:
                cells[key] = p
        points = sorted(cells.values(), key=lambda p: (p.x, p.y, p.z))
        step = max(1, math.ceil(len(points) / 64))
        for p in points[::step]:
            hits = []
            for tree in trees:
                hit, _normal, _face, _distance = tree.ray_cast(
                    Vector((p.x, p.y, p.z + 20.0)), Vector((0, 0, -1)), 50.0)
                if hit is not None:
                    hits.append(hit.z)
            if not hits:
                continue
            floor = max(hits)
            if -0.08 <= p.z - floor <= 0.26:
                candidates.append((round(p.x, 4), round(p.y, 4), round(floor, 4)))
    # Stable spatial selection, not random colors or seeded per-frame noise.
    candidates = sorted(set(candidates), key=lambda p: hashlib.sha256(
        repr(p).encode("ascii")).hexdigest())
    selected = []
    for p in candidates:
        if all((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 > 4.0 ** 2 for q in selected):
            selected.append(p)
            if len(selected) == 24:
                break
    return selected


def _material(original, role, anchors):
    material = original.copy()
    material.name = "Living R3 wall | " + original.name
    material["living_r3_wall"] = True
    material["living_r3_source_material"] = original.name
    material["living_r3_role"] = role
    t = material.node_tree
    bs = next(n for n in t.nodes if n.type == "BSDF_PRINCIPLED")
    old_color = _source(bs.inputs["Base Color"])
    old_normal = bs.inputs["Normal"].links[0].from_socket if bs.inputs["Normal"].is_linked else None
    # Retain all pigment nodes; soften uniform source-image powder before adding
    # sparse mineral relief. This affects only the copied material.
    for n in t.nodes:
        if n.type == "NORMAL_MAP":
            n.inputs["Strength"].default_value *= 0.70

    geo = _node(t, "ShaderNodeNewGeometry", "world metres; no UV repetition")
    p = geo.outputs["Position"]
    warp = _noise(t, p, 0.81, 2.0, "broad irregular mineral domain")
    offset = _vec(t, "MULTIPLY", _vec(t, "SUBTRACT", warp.outputs["Color"],
        (0.5, 0.5, 0.5), "centre mineral drift"), (0.26, 0.26, 0.26), "26cm domain drift")
    q = _vec(t, "ADD", p, offset, "nonperiodic mineral coordinates")
    body = _noise(t, q, 1.1, 1.6, "35cm to 1m mineral bodies")
    cluster = _range(t, body.outputs["Fac"], 0, 1, "sparse rough face clusters", 0.46, 0.68)
    meso = _noise(t, q, 19.0, 2.1, "3 to 8cm granular mineral planes")
    grit = _noise(t, q, 170.0, 2.0, "separate fine stone grit")

    if role == "stone":
        color = _mix(t, old_color, _range(t, body.outputs["Fac"], 0.84, 1.12,
            "existing pigment; bounded broad value", 0.28, 0.72), 1, "keep original ivory grey ochre", "MULTIPLY")
        island = geo.outputs.get("Random Per Island")
        if island is not None:
            color = _mix(t, color, _range(t, island, 0.965, 1.035,
                "quiet existing stone island value"), 1, "individual stones without random hues", "MULTIPLY")
        # Fracture is normal-only: no dark drawn cracks or fake damage.
        fracture = _node(t, "ShaderNodeTexVoronoi", "fine mineral fracture; normal only")
        fracture.feature = "DISTANCE_TO_EDGE"
        fracture.inputs["Scale"].default_value = 38.0
        _set(t, fracture.inputs["Vector"], q)
        hairline = _range(t, fracture.outputs["Distance"], 0.0, 1.0,
            "shallow natural grain seams", 0.008, 0.07)
        microheight = _mix(t, grit.outputs["Fac"], hairline, 0.16, "grit with restrained fine fracture")
        rough = _range(t, meso.outputs["Fac"], 0.78, 0.96, "dry granular matte response")
        rough = _math(t, "ADD", rough, _math(t, "MULTIPLY", cluster, 0.025,
            "rough clusters scatter light"), "no polished stone sheen")
        meso_distance, micro_distance = 0.010, 0.0025
    else:
        # Mortar/body color and its recessed position stay exactly as R1.
        color = old_color
        microheight = grit.outputs["Fac"]
        rough = _range(t, meso.outputs["Fac"], 0.89, 0.98, "dry existing lime earth")
        meso_distance, micro_distance = 0.0025, 0.0010

    contact = 0.0
    for i, anchor in enumerate(anchors):
        delta = _vec(t, "SUBTRACT", p, anchor, "actual earth contact %02d" % i)
        delta = _vec(t, "MULTIPLY", delta, (1.0, 1.0, 5.0), "shallow local contact %02d" % i)
        distance = _vec(t, "DISTANCE", delta, (0.0, 0.0, 0.0), "contact radius %02d" % i)
        local = _range(t, distance, 1.0, 0.0, "soft contact feather %02d" % i, 0.12, 0.95)
        contact = _math(t, "MAXIMUM", contact, local, "isolated grounded patches %02d" % i)
    if anchors:
        contact = _math(t, "MULTIPLY", contact, _range(t, meso.outputs["Fac"],
            0.2, 1.0, "broken contact edge"), "uneven soil contact")
        # Multiplication stays within existing warm mineral family, no moss hue.
        color = _mix(t, color, _mix(t, color, (0.91, 0.89, 0.85, 1.0), 1,
            "bounded warm soil settling", "MULTIPLY"), _math(t, "MULTIPLY", contact,
            0.62, "thin contact pigment"), "local contact only")
    _set(t, bs.inputs["Base Color"], color)
    _set(t, bs.inputs["Roughness"], rough)
    bs.inputs["Specular IOR Level"].default_value = 0.23 if role == "stone" else 0.14

    broad_bump = _node(t, "ShaderNodeBump", "shallow rough mineral planes; no displacement")
    broad_bump.inputs["Distance"].default_value = meso_distance
    if role == "stone":
        distance = _node(t, "ShaderNodeMapRange", "10 to 14mm only in rough clusters")
        distance.clamp = True
        distance.inputs["To Min"].default_value = 0.010
        distance.inputs["To Max"].default_value = 0.014
        _set(t, distance.inputs["Value"], cluster)
        _set(t, broad_bump.inputs["Distance"], distance.outputs["Result"])
    _set(t, broad_bump.inputs["Strength"], _range(t, cluster, 0.16, 0.55, "quiet and rough faces"))
    _set(t, broad_bump.inputs["Height"], meso.outputs["Fac"])
    if old_normal is not None:
        _set(t, broad_bump.inputs["Normal"], old_normal)
    fine_bump = _node(t, "ShaderNodeBump", "perceptible local grit; quiet faces retained")
    fine_bump.inputs["Distance"].default_value = micro_distance
    _set(t, fine_bump.inputs["Strength"], _range(t, cluster, 0.18, 0.62, "patchy grit density"))
    _set(t, fine_bump.inputs["Height"], microheight)
    _set(t, fine_bump.inputs["Normal"], broad_bump.outputs["Normal"])
    _set(t, bs.inputs["Normal"], fine_bump.outputs["Normal"])
    return material


def patch_walls(scene):
    """Assign copied surface materials; return {prior_material_name: material}.

    Requires the existing R1 candidate loaded. Preflight all 207 exact bindings
    before mutation. Audit records are available as patch_walls.last_report.
    Repeated application rejects rather than stacking shader chains.
    """
    global REPORT
    rows = wall_bindings()
    planned, grouped = [], {}
    for row in rows:
        obj = scene.objects.get(row["object"])
        assert obj is not None and obj.type == "MESH", row["object"]
        assert row["slot"] < len(obj.material_slots), row
        slot = obj.material_slots[row["slot"]]
        material = slot.material
        assert material is not None and material.name == row["new"], (
            "Expected exact R1 wall binding", row["object"], row["slot"], material.name if material else None)
        assert not material.get("living_r3_wall"), "R3 already applied"
        assert material.use_nodes and any(n.type == "BSDF_PRINCIPLED"
            for n in material.node_tree.nodes), material.name
        prior = grouped.setdefault(material.name, {"material": material, "role": row["role"], "rows": []})
        assert prior["role"] == row["role"], "Shared source has conflicting wall roles"
        prior["rows"].append(row)
        planned.append((obj, row, slot, material.name))
    anchors = _contact_anchors(scene, rows)
    copies = {}
    for name, group in grouped.items():
        boxes = [r["bounds"] for r in group["rows"]]
        local = [p for p in anchors if any(
            lo[0] - 1.0 <= p[0] <= hi[0] + 1.0 and lo[1] - 1.0 <= p[1] <= hi[1] + 1.0
            for lo, hi in boxes)]
        copies[name] = _material(group["material"], group["role"], local)
    changes = []
    for obj, row, slot, name in planned:
        slot.link = "OBJECT"
        slot.material = copies[name]
        changes.append({"object": obj.name, "slot": row["slot"], "role": row["role"],
            "old": name, "new": slot.material.name})
    REPORT = {"scope": "exact R1 wall inventory only", "slot_count": len(changes),
        "material_count": len(copies), "changes": changes,
        "contact_anchors_world_metres": anchors, "ground_bvh": "raw world mesh read once; no depsgraph",
        "geometry_uv_transform_attribute_writes": False, "rendered_by_this_module": False}
    patch_walls.last_report = REPORT
    return copies


patch_walls.last_report = REPORT
