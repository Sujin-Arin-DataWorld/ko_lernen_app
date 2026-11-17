"""Warm, distinct mineral materials for the 220 HS10 display stones only.

Call refine_materials(scene) in the already-open R12 native scene. No render,
save, lighting, exposure or geometry operations are performed. Original material
datablocks remain intact. Six copied materials share the existing packed authored
stone image; its RGB minerals are retained instead of reduced to grey speckles.
"""

import hashlib
import json
from array import array
from collections import Counter
from pathlib import Path

VERSION = "r12-mineral-1"
ROOT = Path(__file__).resolve().parent
IMAGE_SHA256 = "7b9b8f55789fe79bc4e2ac6e4dec9c0d233e800f2d7fa12d940fa42e181d0f50"
SOURCE_LINEAR_RGB_MEAN = (.7789427260329507, .6416779761538478, .4948423093919686)
# Warm undertones throughout: greige is an ochre/cream grey, never blue-grey.
PALETTE = (("warm-greige", "B4A995", 15), ("cream-greige", "C7BBA5", 15),
           ("warm-sand", "C9B694", 25), ("soft-ochre", "BBA17A", 20),
           ("warm-mineral-grey", "BEB19B", 10), ("pale-sand", "D0C4AA", 15))
TEXTURE_REPEAT_METRES = (1.65, 2.20)
MINERAL_RGB_RATIO = (.65, 1.14)
MINERAL_STRENGTH = .72
PIT_LUMA_RANGE = (.12, .28)
PIT_DISTANCE = .0012
PIT_STRENGTH = .28
ROUGHNESS_RANGE = (.77, .91)


def _rgb(hex_color):
    def linear(v):
        return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4
    return tuple(linear(int(hex_color[i:i + 2], 16) / 255.) for i in (0, 2, 4)) + (1.,)


def _family(name):
    value = int(hashlib.sha256((VERSION + name).encode()).hexdigest()[:8], 16) % 100
    total = 0
    for i, (_, _, weight) in enumerate(PALETTE):
        total += weight
        if value < total:
            return i
    raise AssertionError("Invalid mineral palette weights")


def _value(value):
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    try:
        return tuple(value)
    except TypeError:
        return str(value)


def _tree_state(tree):
    if tree is None:
        return None
    nodes = []
    for node in tree.nodes:
        row = [node.name, node.bl_idname, node.label,
               [(s.name, _value(s.default_value)) for s in node.inputs if hasattr(s, "default_value")]]
        for key in ("operation", "blend_type", "is_active_output", "projection", "projection_blend",
                    "interpolation", "extension", "invert", "attribute_name"):
            if hasattr(node, key):
                row.append((key, _value(getattr(node, key))))
        if hasattr(node, "color_ramp"):
            row.append([(e.position, tuple(e.color)) for e in node.color_ramp.elements])
        if hasattr(node, "image"):
            image = node.image
            row.append((image.as_pointer(), image.colorspace_settings.name) if image else None)
        nodes.append(row)
    return (nodes, [(l.from_node.name, l.from_socket.identifier, l.to_node.name,
                     l.to_socket.identifier) for l in tree.links])


def _materials_hash(materials):
    return hashlib.sha256(repr([(m.name, m.use_nodes, tuple(m.diffuse_color), _tree_state(m.node_tree))
                                for m in materials]).encode()).hexdigest()


def _geometry_hash(sc):
    digest = hashlib.sha256()
    seen = set()
    for ob in sorted(sc.objects, key=lambda o: o.name):
        digest.update(repr((ob.name, ob.type, ob.data.as_pointer() if ob.data else 0,
                            ob.parent.name if ob.parent else None, ob.get("construction_parent"),
                            tuple(tuple(r) for r in ob.matrix_world), ob.hide_render, ob.hide_get())).encode())
        if ob.type != "MESH" or ob.data.as_pointer() in seen:
            continue
        mesh = ob.data
        seen.add(mesh.as_pointer())
        values = array("f", [0.]) * (len(mesh.vertices) * 3)
        mesh.vertices.foreach_get("co", values)
        digest.update(values.tobytes())
        indices = array("i", [0]) * len(mesh.loops)
        mesh.loops.foreach_get("vertex_index", indices)
        digest.update(indices.tobytes())
        digest.update(repr((len(mesh.vertices), len(mesh.edges), len(mesh.polygons))).encode())
    return digest.hexdigest()


def _protected_slots(sc, names):
    return [(o.name, tuple(s.material.as_pointer() if s.material else 0 for s in o.material_slots))
            for o in sorted(sc.objects, key=lambda o: o.name) if o.name not in names]


def _lighting_state(sc):
    return repr((sc.render.engine, sc.view_settings.view_transform, sc.view_settings.look,
                 sc.view_settings.exposure, sc.view_settings.gamma,
                 sc.world.as_pointer() if sc.world else 0,
                 _tree_state(sc.world.node_tree) if sc.world else None,
                 [(o.name, o.data.energy, tuple(o.data.color), o.data.type,
                   tuple(tuple(r) for r in o.matrix_world)) for o in sc.objects if o.type == "LIGHT"]))


def _active_source(material):
    outputs = [n for n in material.node_tree.nodes if n.bl_idname == "ShaderNodeOutputMaterial" and n.is_active_output]
    if len(outputs) != 1 or len(outputs[0].inputs["Surface"].links) != 1:
        raise ValueError(f"Ambiguous active material output: {material.name}")
    shader = outputs[0].inputs["Surface"].links[0].from_node
    if shader.bl_idname != "ShaderNodeBsdfPrincipled":
        raise ValueError(f"Expected current direct Principled surface: {material.name}")
    return outputs[0], shader


def _new_material(template, image, family):
    name, hex_color, _ = PALETTE[family]
    material = template.copy()
    material.name = f"HS12 mineral | {name}"
    material["hs12_stone_material_version"] = VERSION
    material["authored_image_sha256"] = IMAGE_SHA256
    material["palette_srgb"] = hex_color
    tree = material.node_tree
    output, old_shader = _active_source(material)
    prefix = "HS12 mineral | "

    def node(kind, label):
        result = tree.nodes.new(kind)
        result.name = result.label = prefix + label
        return result

    def connect(source, output_name, destination, input_name):
        tree.links.new(source.outputs[output_name], destination.inputs[input_name])

    def math_node(operation, label, value=None):
        result = node("ShaderNodeMath", label)
        result.operation = operation
        if value is not None:
            result.inputs[1].default_value = value
        return result

    position = node("ShaderNodeNewGeometry", "world metre coordinates")
    identity = node("ShaderNodeObjectInfo", "stable individual stone")
    # Vary authored motif placement and physical repeat per object, while
    # material families remain a deterministic SHA256 choice from its name.
    scale = node("ShaderNodeMapRange", "1.65 to 2.20 metre authored repeat")
    scale.inputs["From Min"].default_value = 0.
    scale.inputs["From Max"].default_value = 1.
    scale.inputs["To Min"].default_value = 1. / TEXTURE_REPEAT_METRES[0]
    scale.inputs["To Max"].default_value = 1. / TEXTURE_REPEAT_METRES[1]
    connect(identity, "Random", scale, "Value")
    metric = node("ShaderNodeVectorMath", "physical mineral pattern scale")
    metric.operation = "SCALE"
    connect(position, "Position", metric, 0)
    connect(scale, "Result", metric, "Scale")
    offset = node("ShaderNodeCombineXYZ", "individual mineral origin")
    for axis, value in zip(("X", "Y", "Z"), (3.71, 7.93, 11.17)):
        part = math_node("MULTIPLY", f"origin {axis}", value)
        connect(identity, "Random", part, 0)
        connect(part, 0, offset, axis)
    coords = node("ShaderNodeVectorMath", "varied world origin")
    coords.operation = "ADD"
    connect(metric, "Vector", coords, 0)
    connect(offset, "Vector", coords, 1)
    authored = node("ShaderNodeTexImage", "authored ochre and grey mineral RGB")
    authored.image = image
    authored.projection = "BOX"
    authored.projection_blend = .22
    authored.interpolation = "Linear"
    authored.extension = "REPEAT"
    connect(coords, "Vector", authored, "Vector")
    relative = node("ShaderNodeVectorMath", "authored RGB relative to measured mean")
    relative.operation = "MULTIPLY"
    relative.inputs[1].default_value = tuple(1. / v for v in SOURCE_LINEAR_RGB_MEAN)
    connect(authored, "Color", relative, 0)
    floor = node("ShaderNodeVectorMath", "avoid dirty black mineral spots")
    floor.operation = "MAXIMUM"
    floor.inputs[1].default_value = (MINERAL_RGB_RATIO[0],) * 3
    connect(relative, "Vector", floor, 0)
    ceiling = node("ShaderNodeVectorMath", "retain mineral highlight headroom")
    ceiling.operation = "MINIMUM"
    ceiling.inputs[1].default_value = (MINERAL_RGB_RATIO[1],) * 3
    connect(floor, "Vector", ceiling, 0)
    pigment = node("ShaderNodeMixRGB", "warm body with authored mineral colours")
    pigment.blend_type = "MULTIPLY"
    pigment.inputs[0].default_value = MINERAL_STRENGTH
    pigment.inputs[1].default_value = _rgb(hex_color)
    connect(ceiling, "Vector", pigment, 2)
    identity_tint = node("ShaderNodeMapRange", "three percent per stone tint")
    identity_tint.inputs["To Min"].default_value = .97
    identity_tint.inputs["To Max"].default_value = 1.03
    connect(identity, "Random", identity_tint, "Value")
    final_color = node("ShaderNodeMixRGB", "individual mineral body")
    final_color.blend_type = "MULTIPLY"
    final_color.inputs[0].default_value = 1.
    connect(pigment, "Color", final_color, 1)
    connect(identity_tint, "Result", final_color, 2)
    # Greyscale is only a physical height/roughness signal, never the colour.
    density = node("ShaderNodeRGBToBW", "physical pores from authored image")
    connect(authored, "Color", density, "Color")
    pits = node("ShaderNodeMapRange", "rare pore mask below 0.28 linear luma")
    pits.interpolation_type = "SMOOTHERSTEP"
    pits.inputs["From Min"].default_value, pits.inputs["From Max"].default_value = PIT_LUMA_RANGE
    pits.inputs["To Min"].default_value = 1.
    pits.inputs["To Max"].default_value = 0.
    pits.clamp = True
    connect(density, "Val", pits, "Value")
    grain = node("ShaderNodeBump", "restrained authored surface grain")
    grain.inputs["Distance"].default_value = .00025
    grain.inputs["Strength"].default_value = .18
    connect(density, "Val", grain, "Height")
    pore_bump = node("ShaderNodeBump", "sparse shallow depressions")
    pore_bump.invert = True
    pore_bump.inputs["Distance"].default_value = PIT_DISTANCE
    pore_bump.inputs["Strength"].default_value = PIT_STRENGTH
    connect(pits, "Result", pore_bump, "Height")
    connect(grain, "Normal", pore_bump, "Normal")
    roughness = node("ShaderNodeMapRange", "mineral roughness 0.77 to 0.91")
    roughness.inputs["From Min"].default_value = .22
    roughness.inputs["From Max"].default_value = .80
    roughness.inputs["To Min"].default_value = ROUGHNESS_RANGE[1]
    roughness.inputs["To Max"].default_value = ROUGHNESS_RANGE[0]
    roughness.clamp = True
    connect(density, "Val", roughness, "Value")
    shader = node("ShaderNodeBsdfPrincipled", "active dressed mineral PBR")
    for key in ("Metallic", "IOR", "Specular IOR Level", "Alpha", "Subsurface Weight", "Coat Weight"):
        shader.inputs[key].default_value = old_shader.inputs[key].default_value
    connect(final_color, "Color", shader, "Base Color")
    connect(roughness, "Result", shader, "Roughness")
    connect(pore_bump, "Normal", shader, "Normal")
    connect(shader, "BSDF", output, "Surface")
    material.diffuse_color = _rgb(hex_color)
    assert output.inputs["Surface"].links[0].from_node == shader
    return material


def refine_materials(sc) -> dict:
    import bpy
    expected = {r["name"] for r in json.loads((ROOT / "sarang-stone-masonry-r10/verification.json").read_text(encoding="utf-8"))["addedSolidStones"]}
    original = set(json.loads((ROOT / "sarang/geometry-lock.json").read_text(encoding="utf-8"))["objects"])
    objects = sorted((o for o in sc.objects if o.name.startswith("HS10 ")), key=lambda o: o.name)
    if len(objects) != 220 or {o.name for o in objects} != expected or expected & original:
        raise ValueError("Expected only the exact 220 HS10 display stones")
    if any(o.type != "MESH" or len(o.material_slots) != 1 or o.material_slots[0].material is None for o in objects):
        raise ValueError("Expected one existing PBR material per display stone")
    if any(o.get("hs12_stone_material_version") for o in objects):
        raise ValueError("R12 mineral material already applied")
    data_ids = {o.data.as_pointer() for o in objects}
    if any(o.type == "MESH" and o.name not in expected and o.data.as_pointer() in data_ids for o in sc.objects):
        raise ValueError("Display stone mesh is shared with a protected object")
    source_materials = {o.material_slots[0].material for o in objects}
    for material in source_materials:
        _active_source(material)
    template = sorted(source_materials, key=lambda m: m.name)[0]
    images = {n.image for n in template.node_tree.nodes if n.bl_idname == "ShaderNodeTexImage" and n.image and n.image.name == "stone-material.png"}
    if len(images) != 1:
        raise ValueError("Expected the existing authored stone-material.png PBR image")
    image = images.pop()
    if image.colorspace_settings.name != "sRGB":
        raise ValueError("Authored colour texture must retain sRGB input decoding")
    image_bytes = bytes(image.packed_file.data) if image.packed_file else Path(bpy.path.abspath(image.filepath)).read_bytes()
    if hashlib.sha256(image_bytes).hexdigest() != IMAGE_SHA256:
        raise ValueError("Authored image changed; remeasure the RGB normalization")
    all_original_materials = list(bpy.data.materials)
    material_before = _materials_hash(all_original_materials)
    geometry_before = _geometry_hash(sc)
    slots_before = _protected_slots(sc, expected)
    lighting_before = _lighting_state(sc)
    created, assignments, receipts = [], [], []
    old_body_luma = []
    try:
        for i in range(len(PALETTE)):
            created.append(_new_material(template, image, i))
        for ob in objects:
            old = ob.material_slots[0].material
            family = _family(ob.name)
            body = next((n for n in old.node_tree.nodes if "R8 distinct dressed stone bodies" in n.label), None)
            if body:
                old_body_luma.append(sum(a * b for a, b in zip(body.color_ramp.elements[0].color, (.2126, .7152, .0722))))
            assignments.append((ob, old))
            ob.material_slots[0].material = created[family]
            ob["hs12_stone_material_version"] = VERSION
            receipts.append(dict(object=ob.name, sourceMaterial=old.name, material=created[family].name,
                                 family=PALETTE[family][0], baseSRGB=PALETTE[family][1],
                                 baseLinearRGBA=_rgb(PALETTE[family][1])))
        if _materials_hash(all_original_materials) != material_before:
            raise AssertionError("An existing material datablock changed")
        if _geometry_hash(sc) != geometry_before or _protected_slots(sc, expected) != slots_before:
            raise AssertionError("Geometry or a protected object's material binding changed")
        if _lighting_state(sc) != lighting_before:
            raise AssertionError("Lighting or colour management changed")
        for material in created:
            output, shader = _active_source(material)
            if shader.name != "HS12 mineral | active dressed mineral PBR":
                raise AssertionError("New PBR is not the effective surface output")
            if not all(shader.inputs[k].is_linked for k in ("Base Color", "Roughness", "Normal")):
                raise AssertionError("Incomplete mineral PBR output")
    except Exception:
        for ob, old in assignments:
            ob.material_slots[0].material = old
            if "hs12_stone_material_version" in ob:
                del ob["hs12_stone_material_version"]
        for material in created:
            if material.users == 0:
                bpy.data.materials.remove(material)
        raise
    lumas = [sum(a * b for a, b in zip(r["baseLinearRGBA"], (.2126, .7152, .0722))) for r in receipts]
    return dict(version=VERSION, appliedObjectCount=len(receipts), createdMaterialCount=len(created),
                familyCounts=dict(Counter(r["family"] for r in receipts)), objects=receipts,
                sourceMaterialDatablocksUnchanged=True, original711MaterialsUnchanged=True,
                allGeometryUnchanged=True, protectedMaterialBindingsUnchanged=True,
                lightingExposureColourManagementUnchanged=True, effectivePBRRootsVerified=True,
                authoredImage=image.name, authoredImageSHA256=IMAGE_SHA256,
                sourceLinearRGBMean=SOURCE_LINEAR_RGB_MEAN, authoredRGBRetained=True,
                paletteWeightedLinearLuma=sum(lumas) / len(lumas), paletteLinearLumaRange=[min(lumas), max(lumas)],
                previousPaletteWeightedLinearLuma=sum(old_body_luma) / len(old_body_luma) if old_body_luma else None,
                textureRepeatMetres=TEXTURE_REPEAT_METRES, relativeRGBClamp=MINERAL_RGB_RATIO,
                mineralBlendStrength=MINERAL_STRENGTH, perStoneTintRange=[.97, 1.03],
                roughnessRange=ROUGHNESS_RANGE, poreMaskLinearLumaRange=PIT_LUMA_RANGE,
                poreBumpDistanceMetres=PIT_DISTANCE, poreBumpStrength=PIT_STRENGTH,
                sourcePoreMaskCoverageApprox=.006, sourceCoverageMeasuredFromAuthoredImage=True,
                geometryDisplacementUsed=False, savedBlend=False, rendered=False)
