"""Refine the existing HS12 stone material after the first R12 render review.

Copies six current display materials once. Broad mineral colour, palette spread
and surface response change; geometry, exposure, source materials and sparse pore
parameters do not. Reapplying fails before allocating more material copies.
"""

import hashlib
import json
from collections import Counter
from pathlib import Path

import stone_material_r12 as baseline

VERSION = "r12-mineral-review-1"
ROOT = Path(__file__).resolve().parent
PALETTE_SPREAD = 1.35
TAP_OFFSET = .0065
TAPS = ((1., 1., 1.), (1., -1., -1.), (-1., 1., -1.), (-1., -1., 1.))
MINERAL_RATIO = (.48, 1.18)
MINERAL_BLEND = .90
ROUGHNESS = (.68, .90)
TOOL_BUMP_DISTANCE = .0025
TOOL_BUMP_STRENGTH = .30
PREFIX = "HS12 review | "


def _node(material, suffix):
    node = material.node_tree.nodes.get("HS12 mineral | " + suffix)
    if node is None:
        raise ValueError(f"Missing reviewed HS12 shader node: {material.name}: {suffix}")
    return node


def _pore_signature(material):
    bump = _node(material, "sparse shallow depressions")
    mask = _node(material, "rare pore mask below 0.28 linear luma")
    return (bump.invert, bump.inputs["Distance"].default_value,
            bump.inputs["Strength"].default_value, mask.interpolation_type, mask.clamp,
            tuple(mask.inputs[k].default_value for k in ("From Min", "From Max", "To Min", "To Max")),
            tuple((l.from_node.name, l.from_socket.name) for l in mask.inputs["Value"].links))


def _configure(material, mean):
    tree = material.node_tree
    authored = _node(material, "authored ochre and grey mineral RGB")
    relative = _node(material, "authored RGB relative to measured mean")
    pigment = _node(material, "warm body with authored mineral colours")
    old_color = tuple(pigment.inputs[1].default_value)
    color = tuple(mean[i] + PALETTE_SPREAD * (old_color[i] - mean[i]) for i in range(3)) + (1.,)
    if not all(0. <= v <= 1. for v in color):
        raise ValueError("Palette spread would clip a colour channel")
    pore_before = _pore_signature(material)

    def node(kind, label):
        result = tree.nodes.new(kind)
        result.name = result.label = PREFIX + label
        return result

    def connect(source, output, destination, input):
        tree.links.new(source.outputs[output], destination.inputs[input])

    if len(authored.inputs["Vector"].links) != 1:
        raise ValueError("Authored mineral texture lacks its world-metre mapping")
    coordinates = authored.inputs["Vector"].links[0].from_socket
    taps = []
    for i, signs in enumerate(TAPS):
        shift = node("ShaderNodeVectorMath", f"broad colour sample offset {i}")
        shift.operation = "ADD"
        shift.inputs[1].default_value = tuple(TAP_OFFSET * s for s in signs)
        tree.links.new(coordinates, shift.inputs[0])
        sample = node("ShaderNodeTexImage", f"authored broad mineral sample {i}")
        sample.image = authored.image
        sample.projection, sample.projection_blend = authored.projection, authored.projection_blend
        sample.interpolation, sample.extension = authored.interpolation, authored.extension
        connect(shift, "Vector", sample, "Vector")
        taps.append(sample)
    pair_sums = []
    for i in (0, 2):
        add = node("ShaderNodeVectorMath", f"mineral sample pair {i // 2}")
        add.operation = "ADD"
        connect(taps[i], "Color", add, 0)
        connect(taps[i + 1], "Color", add, 1)
        pair_sums.append(add)
    total = node("ShaderNodeVectorMath", "four authored mineral samples")
    total.operation = "ADD"
    connect(pair_sums[0], "Vector", total, 0)
    connect(pair_sums[1], "Vector", total, 1)
    broad = node("ShaderNodeVectorMath", "broad mineral RGB average")
    broad.operation = "SCALE"
    broad.inputs["Scale"].default_value = .25
    connect(total, "Vector", broad, 0)
    # Only the broad colour pass receives the increased contrast. The original
    # unfiltered image still drives the restrained grain and rare pore mask.
    connect(broad, "Vector", relative, 0)
    _node(material, "avoid dirty black mineral spots").inputs[1].default_value = (MINERAL_RATIO[0],) * 3
    _node(material, "retain mineral highlight headroom").inputs[1].default_value = (MINERAL_RATIO[1],) * 3
    pigment.inputs[0].default_value = MINERAL_BLEND
    pigment.inputs[1].default_value = color
    material.diffuse_color = color
    density = node("ShaderNodeRGBToBW", "broad authored mineral density")
    connect(broad, "Vector", density, "Color")
    roughness = _node(material, "mineral roughness 0.77 to 0.91")
    roughness.label = PREFIX + "mineral roughness 0.68 to 0.90"
    roughness.inputs["To Min"].default_value = ROUGHNESS[1]
    roughness.inputs["To Max"].default_value = ROUGHNESS[0]
    connect(density, "Val", roughness, "Value")
    tool_height = node("ShaderNodeMapRange", "shallow authored tool plane height")
    tool_height.interpolation_type = "SMOOTHERSTEP"
    tool_height.clamp = True
    tool_height.inputs["From Min"].default_value = .45
    tool_height.inputs["From Max"].default_value = .77
    tool_height.inputs["To Min"].default_value = 0.
    tool_height.inputs["To Max"].default_value = 1.
    connect(density, "Val", tool_height, "Value")
    tool = node("ShaderNodeBump", "0.75mm peak tool surface response")
    tool.inputs["Distance"].default_value = TOOL_BUMP_DISTANCE
    tool.inputs["Strength"].default_value = TOOL_BUMP_STRENGTH
    connect(tool_height, "Result", tool, "Height")
    pores = _node(material, "sparse shallow depressions")
    if len(pores.inputs["Normal"].links) != 1:
        raise ValueError("Expected the existing authored-grain normal chain")
    previous_normal = pores.inputs["Normal"].links[0].from_socket
    tree.links.new(previous_normal, tool.inputs["Normal"])
    connect(tool, "Normal", pores, "Normal")
    if _pore_signature(material) != pore_before:
        raise AssertionError("Sparse pore mask or pore parameters changed")
    output, shader = baseline._active_source(material)
    if shader != _node(material, "active dressed mineral PBR"):
        raise AssertionError("Reviewed changes are not on the effective PBR surface")
    if relative.inputs[0].links[0].from_node != broad:
        raise AssertionError("Broad mineral colour is not connected")
    if shader.inputs["Normal"].links[0].from_node != pores:
        raise AssertionError("Pore/tool/grain normal chain is not active")
    material["hs12_stone_review_version"] = VERSION
    material["review_base_linear_rgba"] = color
    return dict(material=material.name, baseBefore=old_color, baseAfter=color,
                activeSurface=shader.name, authoredImage=authored.image.name,
                newNodeCount=sum(n.name.startswith(PREFIX) for n in tree.nodes),
                sparsePoreParametersUnchanged=True)


def apply(sc) -> dict:
    import bpy
    expected = {r["name"] for r in json.loads((ROOT / "sarang-stone-masonry-r10/verification.json").read_text(encoding="utf-8"))["addedSolidStones"]}
    objects = sorted((o for o in sc.objects if o.name in expected), key=lambda o: o.name)
    if len(objects) != 220 or any(o.type != "MESH" or len(o.material_slots) != 1 for o in objects):
        raise ValueError("Expected the 220 existing HS10 display stones")
    if any(o.get("hs12_stone_review_version") for o in objects):
        raise ValueError("Stone review already applied; reopen the saved R12 source")
    materials = sorted({o.material_slots[0].material for o in objects}, key=lambda m: m.name if m else "")
    if len(materials) != 6 or any(m is None or m.get("hs12_stone_material_version") != baseline.VERSION for m in materials):
        raise ValueError("Expected the six existing HS12 mineral materials")
    if any(m.get("hs12_stone_review_version") for m in materials):
        raise ValueError("Reviewed material copies already present; refusing nested copies")
    for material in materials:
        baseline._active_source(material)
    data_ids = {o.data.as_pointer() for o in objects}
    if any(o.name not in expected and o.type == "MESH" and o.data.as_pointer() in data_ids for o in sc.objects):
        raise ValueError("Display mesh shared with a protected object")
    mean = tuple(sum(_node(o.material_slots[0].material, "warm body with authored mineral colours").inputs[1].default_value[i]
                     for o in objects) / len(objects) for i in range(3))
    old_materials = list(bpy.data.materials)
    old_material_state = baseline._materials_hash(old_materials)
    geometry_state = baseline._geometry_hash(sc)
    protected_slots = baseline._protected_slots(sc, expected)
    lighting_state = baseline._lighting_state(sc)
    copies, material_receipts, assignments, objects_receipts = {}, [], [], []
    try:
        for original in materials:
            copy = original.copy()
            copies[original] = copy
            copy.name = original.name.replace("HS12 mineral |", "HS12 mineral review |")
            material_receipts.append(_configure(copy, mean))
        for ob in objects:
            old = ob.material_slots[0].material
            assignments.append((ob, old))
            ob.material_slots[0].material = copies[old]
            ob["hs12_stone_review_version"] = VERSION
            objects_receipts.append(dict(object=ob.name, sourceMaterial=old.name,
                                         material=copies[old].name))
        if baseline._materials_hash(old_materials) != old_material_state:
            raise AssertionError("An existing material datablock changed")
        if baseline._geometry_hash(sc) != geometry_state:
            raise AssertionError("Geometry, hierarchy, visibility or construction binding changed")
        if baseline._protected_slots(sc, expected) != protected_slots:
            raise AssertionError("A protected material binding changed")
        if baseline._lighting_state(sc) != lighting_state:
            raise AssertionError("Lighting, exposure or colour management changed")
        after_mean = tuple(sum(_node(o.material_slots[0].material, "warm body with authored mineral colours").inputs[1].default_value[i]
                               for o in objects) / len(objects) for i in range(3))
        if max(abs(a - b) for a, b in zip(mean, after_mean)) > 5e-8:
            raise AssertionError("Weighted palette mean changed")
    except Exception:
        for ob, old in assignments:
            ob.material_slots[0].material = old
            if "hs12_stone_review_version" in ob:
                del ob["hs12_stone_review_version"]
        for copy in copies.values():
            if copy.users == 0:
                bpy.data.materials.remove(copy)
        raise
    return dict(version=VERSION, appliedObjects=len(objects), copiedMaterials=len(copies),
                objects=objects_receipts, materials=material_receipts,
                assignmentCounts=dict(Counter(r["material"] for r in objects_receipts)),
                paletteSpread=PALETTE_SPREAD, weightedRGBMeanBefore=mean,
                weightedRGBMeanAfter=after_mean, weightedPaletteMeanPreserved=True,
                broadColourSamples=4, normalizedTapOffset=TAP_OFFSET,
                physicalFilterSpanMetres=[2. * TAP_OFFSET * v for v in baseline.TEXTURE_REPEAT_METRES],
                broadMineralRatioClamp=MINERAL_RATIO, broadMineralBlend=MINERAL_BLEND,
                roughnessRange=ROUGHNESS, broadToolBumpDistance=TOOL_BUMP_DISTANCE,
                broadToolBumpStrength=TOOL_BUMP_STRENGTH,
                peakEffectiveToolHeightMetres=TOOL_BUMP_DISTANCE * TOOL_BUMP_STRENGTH,
                sparsePoresUnchanged=True, restrainedGrainUnchanged=True,
                sourceMaterialDatablocksUnchanged=True, original711Unchanged=True,
                geometryUnchanged=True, protectedMaterialBindingsUnchanged=True,
                lightingExposureColourManagementUnchanged=True,
                activePBRVerified=True, repeatApplication="fail before copying",
                savedBlend=False, rendered=False)
