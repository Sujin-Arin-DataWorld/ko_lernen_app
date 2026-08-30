"""Build the measured Ildu Gotaek sarangchae in Blender.

The default keeps the approved review-only blockout v01 reproducible.  Passing
``--detail-v02`` adds a versioned architectural detail and stylized-material
pass without overwriting the approved blockout outputs.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


# ---------------------------------------------------------------------------
# Measured source values (metres)
# ---------------------------------------------------------------------------

FRONT_BAYS = [2.595, 2.675, 2.645, 2.660, 1.985, 1.985]
FRONT_TOTAL = 14.545
MAIN_DEPTH = 3.985
SIDE_TOTAL_RIGHT = 7.980
WING_DEPTH = SIDE_TOTAL_RIGHT - MAIN_DEPTH
WING_WIDTH = 3.970
EAVE_PROJECTION = 1.380
RIDGE_Z = 7.080
MAIN_FLOOR_Z = 1.550
NUMARU_FLOOR_Z = MAIN_FLOOR_Z + 0.200
EAVE_BEAM_Z = 4.560
MAIN_PODIUM_Z = 1.350
REAR_PODIUM_Z = 0.245
NUMARU_LOW_PODIUM_Z = 0.410

X_MIN = -FRONT_TOTAL / 2.0
X_MAX = FRONT_TOTAL / 2.0
X_WING_MIN = X_MAX - WING_WIDTH
Y_FRONT = 0.0
Y_REAR = MAIN_DEPTH
Y_WING_FRONT = -WING_DEPTH

PROJECT_DIR = Path(__file__).resolve().parent.parent
SOURCE_DIR = PROJECT_DIR / "source"
EXPORT_DIR = PROJECT_DIR / "exports"
RENDER_DIR = PROJECT_DIR / "renders" / "blockout_v01"
BLEND_PATH = SOURCE_DIR / "ildu_sarangchae_blockout_v01.blend"
GLB_PATH = EXPORT_DIR / "ildu_sarangchae_blockout_v01.glb"
MANIFEST_PATH = PROJECT_DIR / "blockout_v01_manifest.json"
ASSET_VERSION = "blockout_v01"
OUTPUT_STEM = "ildu_sarangchae_blockout_v01"
DETAIL_MODE = False
FINAL_MODE = False

COLLECTIONS: dict[str, bpy.types.Collection] = {}
MATERIALS: dict[str, bpy.types.Material] = {}
ROOT: bpy.types.Object | None = None
SOURCE_ANCHOR_PATH = PROJECT_DIR.parent.parent / "sarangchae_try07_edit.png"
SOURCE_PROJECTION_PATH = PROJECT_DIR / "textures" / "final_v03" / "sarangchae_source_projection_canvas.png"
SOURCE_ANCHOR_VIEW = "00_source_anchor"
SOURCE_PROJECTION_UV = "SourceProjectionUV"
SOURCE_ANCHOR_ANGLE_DEGREES = 0.0


def parse_args() -> argparse.Namespace:
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-renders", action="store_true")
    parser.add_argument("--detail-v02", action="store_true")
    parser.add_argument("--final-v03", action="store_true")
    parser.add_argument("--anchor-only", action="store_true")
    parser.add_argument("--resolution-x", type=int, default=1280)
    parser.add_argument("--resolution-y", type=int, default=960)
    return parser.parse_args(argv)


def configure_variant(detail_v02: bool, final_v03: bool) -> None:
    global ASSET_VERSION, OUTPUT_STEM, DETAIL_MODE, FINAL_MODE
    global RENDER_DIR, BLEND_PATH, GLB_PATH, MANIFEST_PATH
    FINAL_MODE = final_v03
    DETAIL_MODE = detail_v02 or final_v03
    ASSET_VERSION = "final_v03" if final_v03 else ("detail_v02" if detail_v02 else "blockout_v01")
    OUTPUT_STEM = f"ildu_sarangchae_{ASSET_VERSION}"
    RENDER_DIR = PROJECT_DIR / "renders" / ASSET_VERSION
    BLEND_PATH = SOURCE_DIR / f"{OUTPUT_STEM}.blend"
    GLB_PATH = EXPORT_DIR / f"{OUTPUT_STEM}.glb"
    MANIFEST_PATH = PROJECT_DIR / f"{ASSET_VERSION}_manifest.json"


def clean_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def ensure_directories() -> None:
    for path in (SOURCE_DIR, EXPORT_DIR, RENDER_DIR):
        path.mkdir(parents=True, exist_ok=True)


def create_collection(name: str) -> bpy.types.Collection:
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    COLLECTIONS[name] = collection
    return collection


def move_to_collection(obj: bpy.types.Object, collection_name: str) -> None:
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    COLLECTIONS[collection_name].objects.link(obj)


def parent_to_root(obj: bpy.types.Object) -> None:
    if ROOT is not None and obj is not ROOT:
        obj.parent = ROOT


def hex_rgba(value: str) -> tuple[float, float, float, float]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) / 255.0 for i in (0, 2, 4)) + (1.0,)


def material(name: str, color: str, roughness: float = 0.88) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    rgba = hex_rgba(color)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = rgba
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = 0.0
    MATERIALS[name] = mat
    return mat


def stylized_material(
    name: str,
    dark_color: str,
    light_color: str,
    roughness: float,
    scale: float,
    bump_strength: float,
) -> bpy.types.Material:
    """Create matte stepped tonal variation resembling the approved V3 facets."""
    mat = material(name, light_color, roughness)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    if bsdf is None:
        return mat

    texcoord = nodes.new("ShaderNodeTexCoord")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.noise_dimensions = "3D"
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 2.2
    noise.inputs["Roughness"].default_value = 0.72
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    dark = hex_rgba(dark_color)
    light = hex_rgba(light_color)
    ramp.color_ramp.elements[0].position = 0.24
    ramp.color_ramp.elements[0].color = dark
    middle = ramp.color_ramp.elements.new(0.52)
    middle.color = tuple(dark[i] * 0.52 + light[i] * 0.48 for i in range(4))
    upper = ramp.color_ramp.elements.new(0.72)
    upper.color = tuple(dark[i] * 0.25 + light[i] * 0.75 for i in range(4))
    ramp.color_ramp.elements[-1].position = 0.86
    ramp.color_ramp.elements[-1].color = light
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = bump_strength
    bump.inputs["Distance"].default_value = 0.08
    links.new(texcoord.outputs["Generated"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def assign_material(obj: bpy.types.Object, mat: bpy.types.Material) -> None:
    if hasattr(obj.data, "materials"):
        obj.data.materials.append(mat)


def apply_scale(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.select_set(False)


def add_box(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    mat: bpy.types.Material,
    collection: str,
    bevel: float = 0.02,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    apply_scale(obj)
    if bevel > 0:
        modifier = obj.modifiers.new("softened_edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    assign_material(obj, mat)
    move_to_collection(obj, collection)
    parent_to_root(obj)
    return obj


def add_cylinder(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    rotation: tuple[float, float, float],
    mat: bpy.types.Material,
    collection: str,
    vertices: int = 12,
    bevel: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    if bevel > 0:
        modifier = obj.modifiers.new("softened_edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    assign_material(obj, mat)
    move_to_collection(obj, collection)
    parent_to_root(obj)
    return obj


def add_ico_sphere(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    mat: bpy.types.Material,
    collection: str,
    subdivisions: int = 2,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=subdivisions,
        radius=radius,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    assign_material(obj, mat)
    move_to_collection(obj, collection)
    parent_to_root(obj)
    return obj


def add_post(
    name: str,
    x: float,
    y: float,
    z_bottom: float,
    z_top: float,
    radius_bottom: float = 0.126,
    radius_top: float = 0.085,
    vertices: int = 12,
    mat: bpy.types.Material | None = None,
    collection: str = "20_FRAME",
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius_bottom,
        radius2=radius_top,
        depth=z_top - z_bottom,
        location=(x, y, (z_bottom + z_top) / 2.0),
    )
    obj = bpy.context.object
    obj.name = name
    assign_material(obj, mat or MATERIALS["timber"])
    move_to_collection(obj, collection)
    parent_to_root(obj)
    return obj


def add_beam_between(
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    thickness: float,
    mat: bpy.types.Material,
    collection: str,
    bevel: float = 0.015,
) -> bpy.types.Object:
    start_v = Vector(start)
    end_v = Vector(end)
    direction = end_v - start_v
    length = direction.length
    midpoint = (start_v + end_v) / 2.0
    obj = add_box(
        name,
        tuple(midpoint),
        (length, thickness, thickness),
        mat,
        collection,
        bevel,
    )
    obj.rotation_euler = direction.to_track_quat("X", "Z").to_euler()
    return obj


def add_curve(
    name: str,
    points: list[tuple[float, float, float]],
    bevel_depth: float,
    mat: bpy.types.Material,
    collection: str,
    resolution: int = 2,
) -> bpy.types.Object:
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = resolution
    curve.bevel_depth = bevel_depth
    curve.bevel_resolution = 2
    curve.use_fill_caps = True
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, coords in zip(spline.bezier_points, points):
        point.co = coords
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    COLLECTIONS[collection].objects.link(obj)
    assign_material(obj, mat)
    parent_to_root(obj)
    return obj


def add_triangle(
    name: str,
    vertices: list[tuple[float, float, float]],
    mat: bpy.types.Material,
    collection: str,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(vertices, [], [(0, 1, 2)])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    COLLECTIONS[collection].objects.link(obj)
    assign_material(obj, mat)
    parent_to_root(obj)
    solidify = obj.modifiers.new("gable_thickness", "SOLIDIFY")
    solidify.thickness = 0.08
    return obj


def add_sloped_prism(
    name: str,
    xmin: float,
    xmax: float,
    ymin: float,
    ymax: float,
    bottom_front: float,
    bottom_rear: float,
    top_front: float,
    top_rear: float,
    mat: bpy.types.Material,
    collection: str,
    bevel_width: float = 0.02,
) -> bpy.types.Object:
    """Create a solid prism whose bottom and top can follow the site grade."""
    vertices = [
        (xmin, ymin, bottom_front),
        (xmax, ymin, bottom_front),
        (xmax, ymax, bottom_rear),
        (xmin, ymax, bottom_rear),
        (xmin, ymin, top_front),
        (xmax, ymin, top_front),
        (xmax, ymax, top_rear),
        (xmin, ymax, top_rear),
    ]
    faces = [
        (0, 3, 2, 1),
        (4, 5, 6, 7),
        (0, 1, 5, 4),
        (1, 2, 6, 5),
        (2, 3, 7, 6),
        (3, 0, 4, 7),
    ]
    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    COLLECTIONS[collection].objects.link(obj)
    assign_material(obj, mat)
    parent_to_root(obj)
    if bevel_width > 0:
        bevel = obj.modifiers.new("softened_edges", "BEVEL")
        bevel.width = bevel_width
        bevel.segments = 2
    return obj


def make_roof_mesh(
    name: str,
    axis: str,
    xmin: float,
    xmax: float,
    ymin: float,
    ymax: float,
    ridge_start: float,
    ridge_end: float,
    eave_z: float,
    ridge_z: float,
) -> bpy.types.Object:
    if axis == "X":
        yc = (ymin + ymax) / 2.0
        vertices = [
            (xmin, ymin, eave_z),
            (xmax, ymin, eave_z),
            (xmax, ymax, eave_z),
            (xmin, ymax, eave_z),
            (ridge_start, yc, ridge_z),
            (ridge_end, yc, ridge_z),
        ]
        faces = [(0, 1, 5, 4), (3, 4, 5, 2), (0, 4, 3), (1, 2, 5)]
    else:
        xc = (xmin + xmax) / 2.0
        vertices = [
            (xmin, ymin, eave_z),
            (xmax, ymin, eave_z),
            (xmax, ymax, eave_z),
            (xmin, ymax, eave_z),
            (xc, ridge_start, ridge_z),
            (xc, ridge_end, ridge_z),
        ]
        faces = [(0, 4, 5, 3), (1, 2, 5, 4), (0, 1, 4), (3, 5, 2)]
    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    COLLECTIONS["50_ROOF"].objects.link(obj)
    assign_material(obj, MATERIALS["giwa"])
    parent_to_root(obj)
    solidify = obj.modifiers.new("roof_thickness", "SOLIDIFY")
    solidify.thickness = 0.12
    solidify.offset = -0.6
    bevel = obj.modifiers.new("roof_edge_softness", "BEVEL")
    bevel.width = 0.025
    bevel.segments = 2
    return obj


def cumulative(values: list[float], start: float) -> list[float]:
    positions = [start]
    current = start
    for value in values:
        current += value
        positions.append(current)
    return positions


def build_foundations() -> None:
    granite = MATERIALS["granite"]
    groove = MATERIALS["stone_joint"]
    earth = MATERIALS["grade_earth"]
    high_xmax = X_WING_MIN
    high_ymin = -1.280
    high_ymax = Y_REAR + 0.690

    # A separate, toggleable grade proxy is necessary to explain why the same
    # level floor has a 1.2 m courtyard podium but only a 0.245 m rear face.
    # It is not fused to the building and can be hidden for site integration.
    add_box(
        "front_flat_grade_proxy",
        (0.0, (Y_WING_FRONT - 1.0 + high_ymin) / 2.0, -0.045),
        (FRONT_TOTAL + 3.4, high_ymin - (Y_WING_FRONT - 1.0), 0.09),
        earth,
        "05_GRADE_PROXY",
        0.02,
    )
    rear_grade = MAIN_PODIUM_Z - REAR_PODIUM_Z
    add_sloped_prism(
        "rising_rear_grade_proxy",
        X_MIN - 1.7,
        X_MAX + 1.7,
        high_ymin,
        high_ymax + 0.55,
        -0.08,
        rear_grade - 0.08,
        0.0,
        rear_grade,
        earth,
        "05_GRADE_PROXY",
        0.025,
    )

    add_sloped_prism(
        "main_high_podium_core",
        X_MIN,
        high_xmax,
        high_ymin,
        high_ymax,
        0.0,
        rear_grade,
        MAIN_PODIUM_Z,
        MAIN_PODIUM_Z,
        granite,
        "10_FOUNDATION",
        0.045,
    )
    for z in (0.42, 0.84, 1.18):
        add_box(
            f"podium_horizontal_joint_{z:.2f}",
            ((X_MIN + high_xmax) / 2.0, high_ymin - 0.012, z),
            (high_xmax - X_MIN - 0.08, 0.025, 0.025),
            groove,
            "10_FOUNDATION",
            0.0,
        )
    row_counts = (8, 9, 7)
    for row, count in enumerate(row_counts):
        z = 0.21 + row * 0.42
        usable = high_xmax - X_MIN
        spacing = usable / count
        offset = spacing / 2.0 if row % 2 else 0.0
        for index in range(1, count):
            x = X_MIN + index * spacing + offset
            if x >= high_xmax - 0.15:
                continue
            add_box(
                f"podium_vertical_joint_{row}_{index}",
                (x, high_ymin - 0.014, z),
                (0.026, 0.028, 0.34),
                groove,
                "10_FOUNDATION",
                0.0,
            )

    # The right/rear room bar follows the same grade and therefore exposes
    # only a low stone face at the back instead of repeating the front wall.
    add_sloped_prism(
        "right_rear_graded_podium",
        X_WING_MIN,
        X_MAX,
        Y_FRONT,
        Y_REAR + 0.30,
        NUMARU_LOW_PODIUM_Z,
        rear_grade,
        MAIN_PODIUM_Z,
        MAIN_PODIUM_Z,
        granite,
        "10_FOUNDATION",
        0.035,
    )
    add_box(
        "numaru_low_podium",
        ((X_WING_MIN + X_MAX) / 2.0, (Y_WING_FRONT + Y_FRONT) / 2.0, NUMARU_LOW_PODIUM_Z / 2.0),
        (WING_WIDTH + 0.55, WING_DEPTH + 0.6, NUMARU_LOW_PODIUM_Z),
        granite,
        "10_FOUNDATION",
        0.055,
    )

    # Measured central 1.2 m stair, six 0.19 m-ish rises and 0.30 m treads.
    stair_x = -0.35
    steps = 6
    for index in range(steps):
        height = (index + 1) * (MAIN_PODIUM_Z / steps)
        depth = (steps - index) * 0.30
        y_center = high_ymin - depth / 2.0
        add_box(
            f"central_stair_{index + 1:02d}",
            (stair_x, y_center, height / 2.0),
            (1.20, depth, height),
            granite,
            "10_FOUNDATION",
            0.035,
        )

    # Column stones: natural-square blocks for the frame and octagonal bases for hwalju.
    grid_x = cumulative(FRONT_BAYS, X_MIN)
    for row_name, y in (("front", Y_FRONT), ("rear", Y_REAR)):
        for index, x in enumerate(grid_x):
            add_box(
                f"plinth_{row_name}_{index:02d}",
                (x, y, MAIN_FLOOR_Z - 0.10),
                (0.48, 0.48, 0.20),
                granite,
                "10_FOUNDATION",
                0.04,
            )
    for x in (X_WING_MIN, X_WING_MIN + FRONT_BAYS[-1], X_MAX):
        for y in (Y_WING_FRONT, -1.335):
            add_box(
                f"plinth_numaru_{x:.3f}_{y:.3f}",
                (x, y, NUMARU_LOW_PODIUM_Z + 0.12),
                (0.58, 0.58, 0.24),
                granite,
                "10_FOUNDATION",
                0.05,
            )


def build_frame() -> None:
    timber = MATERIALS["timber"]
    dark_timber = MATERIALS["timber_dark"]
    grid_x = cumulative(FRONT_BAYS, X_MIN)

    add_box(
        "main_wood_floor",
        ((X_MIN + X_WING_MIN) / 2.0, (Y_FRONT + Y_REAR) / 2.0, MAIN_FLOOR_Z),
        (X_WING_MIN - X_MIN, Y_REAR - Y_FRONT, 0.18),
        dark_timber,
        "20_FRAME",
        0.025,
    )
    add_box(
        "rear_right_floor",
        ((X_WING_MIN + X_MAX) / 2.0, (Y_FRONT + Y_REAR) / 2.0, MAIN_FLOOR_Z),
        (X_MAX - X_WING_MIN, Y_REAR - Y_FRONT, 0.18),
        dark_timber,
        "20_FRAME",
        0.025,
    )
    add_box(
        "numaru_floor",
        ((X_WING_MIN + X_MAX) / 2.0, (Y_WING_FRONT + Y_FRONT) / 2.0, NUMARU_FLOOR_Z),
        (WING_WIDTH, WING_DEPTH, 0.22),
        dark_timber,
        "20_FRAME",
        0.025,
    )

    # Long main frame.  The front and rear rows remain identical in plan so
    # the model cannot invent a new rear footprint when rotated.
    for row_name, y in (("front", Y_FRONT), ("rear", Y_REAR)):
        for index, x in enumerate(grid_x):
            add_post(
                f"main_{row_name}_post_{index:02d}",
                x,
                y,
                MAIN_FLOOR_Z,
                EAVE_BEAM_Z,
                mat=timber,
            )
        add_box(
            f"main_{row_name}_head_beam",
            ((X_MIN + X_MAX) / 2.0, y, EAVE_BEAM_Z),
            (FRONT_TOTAL + 0.25, 0.23, 0.25),
            dark_timber,
            "20_FRAME",
            0.025,
        )
        add_box(
            f"main_{row_name}_sill",
            ((X_MIN + X_MAX) / 2.0, y, 1.90),
            (FRONT_TOTAL, 0.16, 0.17),
            timber,
            "20_FRAME",
            0.018,
        )

    # Internal centre row records the 5-ryang structural depth without making
    # an unverified decorative bracket forest.
    for index, x in enumerate(grid_x):
        add_post(
            f"main_middle_post_{index:02d}",
            x,
            MAIN_DEPTH / 2.0,
            MAIN_FLOOR_Z,
            EAVE_BEAM_Z - 0.12,
            radius_bottom=0.105,
            radius_top=0.085,
            vertices=8,
            mat=dark_timber,
        )

    # The projecting nummaru wing has two measured 1.985 m front bays.
    wing_x = [X_WING_MIN, X_WING_MIN + FRONT_BAYS[-1], X_MAX]
    wing_y = [Y_WING_FRONT, -1.335, Y_FRONT]
    for yi, y in enumerate(wing_y):
        for xi, x in enumerate(wing_x):
            add_post(
                f"wing_upper_post_{yi}_{xi}",
                x,
                y,
                NUMARU_FLOOR_Z,
                EAVE_BEAM_Z,
                mat=timber,
            )
    for x in wing_x:
        for y in (Y_WING_FRONT, -1.335):
            add_post(
                f"wing_octagonal_underpost_{x:.3f}_{y:.3f}",
                x,
                y,
                NUMARU_LOW_PODIUM_Z + 0.24,
                NUMARU_FLOOR_Z,
                radius_bottom=0.170,
                radius_top=0.156,
                vertices=8,
                mat=timber,
            )
    for x in (X_WING_MIN, X_MAX):
        add_box(
            f"wing_side_head_beam_{x:.3f}",
            (x, (Y_WING_FRONT + Y_FRONT) / 2.0, EAVE_BEAM_Z),
            (0.23, WING_DEPTH + 0.20, 0.25),
            dark_timber,
            "20_FRAME",
            0.025,
        )
    add_box(
        "wing_front_head_beam",
        ((X_WING_MIN + X_MAX) / 2.0, Y_WING_FRONT, EAVE_BEAM_Z),
        (WING_WIDTH + 0.22, 0.23, 0.25),
        dark_timber,
        "20_FRAME",
        0.025,
    )

    # Simple bracket blocks at every visible front post: one bracket family,
    # never palace-scale multi-po clusters.
    for index, x in enumerate(grid_x):
        add_box(
            f"front_bracket_{index:02d}",
            (x, -0.12, EAVE_BEAM_Z + 0.18),
            (0.42, 0.42, 0.22),
            dark_timber,
            "60_DETAILS",
            0.035,
        )


def add_lattice_y(
    name: str,
    x0: float,
    x1: float,
    y: float,
    z0: float,
    z1: float,
    columns: int,
    rows: int,
    outward: float,
) -> None:
    hanji = MATERIALS["hanji"]
    timber = MATERIALS["timber_dark"]
    width = x1 - x0
    height = z1 - z0
    centre_y = y + outward
    add_box(
        f"{name}_hanji",
        ((x0 + x1) / 2.0, centre_y, (z0 + z1) / 2.0),
        (width, 0.075, height),
        hanji,
        "40_WINDOWS",
        0.008,
    )
    frame = 0.085
    for x in (x0, x1):
        add_box(
            f"{name}_frame_v_{x:.3f}",
            (x, centre_y + math.copysign(0.045, outward), (z0 + z1) / 2.0),
            (frame, 0.085, height + frame),
            timber,
            "40_WINDOWS",
            0.008,
        )
    for z in (z0, z1):
        add_box(
            f"{name}_frame_h_{z:.3f}",
            ((x0 + x1) / 2.0, centre_y + math.copysign(0.045, outward), z),
            (width + frame, 0.085, frame),
            timber,
            "40_WINDOWS",
            0.008,
        )
    for index in range(1, columns):
        x = x0 + width * index / columns
        add_box(
            f"{name}_lattice_v_{index:02d}",
            (x, centre_y + math.copysign(0.052, outward), (z0 + z1) / 2.0),
            (0.026, 0.055, height),
            timber,
            "40_WINDOWS",
            0.004,
        )
    for index in range(1, rows):
        z = z0 + height * index / rows
        add_box(
            f"{name}_lattice_h_{index:02d}",
            ((x0 + x1) / 2.0, centre_y + math.copysign(0.052, outward), z),
            (width, 0.055, 0.028),
            timber,
            "40_WINDOWS",
            0.004,
        )


def add_lattice_x(
    name: str,
    y0: float,
    y1: float,
    x: float,
    z0: float,
    z1: float,
    columns: int,
    rows: int,
    outward: float,
) -> None:
    hanji = MATERIALS["hanji"]
    timber = MATERIALS["timber_dark"]
    width = y1 - y0
    height = z1 - z0
    centre_x = x + outward
    add_box(
        f"{name}_hanji",
        (centre_x, (y0 + y1) / 2.0, (z0 + z1) / 2.0),
        (0.075, width, height),
        hanji,
        "40_WINDOWS",
        0.008,
    )
    frame = 0.085
    for y in (y0, y1):
        add_box(
            f"{name}_frame_v_{y:.3f}",
            (centre_x + math.copysign(0.045, outward), y, (z0 + z1) / 2.0),
            (0.085, frame, height + frame),
            timber,
            "40_WINDOWS",
            0.008,
        )
    for z in (z0, z1):
        add_box(
            f"{name}_frame_h_{z:.3f}",
            (centre_x + math.copysign(0.045, outward), (y0 + y1) / 2.0, z),
            (0.085, width + frame, frame),
            timber,
            "40_WINDOWS",
            0.008,
        )
    for index in range(1, columns):
        y = y0 + width * index / columns
        add_box(
            f"{name}_lattice_v_{index:02d}",
            (centre_x + math.copysign(0.052, outward), y, (z0 + z1) / 2.0),
            (0.055, 0.026, height),
            timber,
            "40_WINDOWS",
            0.004,
        )
    for index in range(1, rows):
        z = z0 + height * index / rows
        add_box(
            f"{name}_lattice_h_{index:02d}",
            (centre_x + math.copysign(0.052, outward), (y0 + y1) / 2.0, z),
            (0.055, width, 0.028),
            timber,
            "40_WINDOWS",
            0.004,
        )


def build_walls_and_openings() -> None:
    wall = MATERIALS["wall"]
    plank = MATERIALS["plank"]
    grid_x = cumulative(FRONT_BAYS, X_MIN)

    # Main front: four broad bays on the high podium, each intentionally given
    # a different opening rhythm instead of cloning one generic window module.
    for bay in range(4):
        x0 = grid_x[bay] + 0.16
        x1 = grid_x[bay + 1] - 0.16
        add_box(
            f"front_wall_bay_{bay + 1}",
            ((x0 + x1) / 2.0, 0.035, 3.03),
            (x1 - x0, 0.12, 2.65),
            wall,
            "30_WALLS",
            0.018,
        )
        inset = 0.08 if bay < 2 else (x1 - x0) * 0.16
        add_lattice_y(
            f"front_opening_bay_{bay + 1}",
            x0 + inset,
            x1 - inset,
            -0.035,
            2.12 if bay < 2 else 2.35,
            3.94 if bay < 2 else 3.75,
            12 if bay == 0 else (10 if bay == 1 else 6),
            5 if bay < 2 else 4,
            -1.0,
        )
    # The rear-right room bar is present behind the projecting nummaru.
    for bay in range(4, 6):
        x0 = grid_x[bay] + 0.15
        x1 = grid_x[bay + 1] - 0.15
        add_box(
            f"front_return_wall_{bay + 1}",
            ((x0 + x1) / 2.0, 0.04, 3.05),
            (x1 - x0, 0.12, 2.60),
            wall,
            "30_WALLS",
            0.018,
        )
        add_lattice_y(
            f"front_return_window_{bay + 1}",
            x0 + 0.30,
            x1 - 0.30,
            -0.03,
            2.55,
            3.65,
            5,
            4,
            -1.0,
        )

    # Rear: more plaster and smaller openings, making it visibly a true back.
    for bay in range(6):
        x0 = grid_x[bay] + 0.15
        x1 = grid_x[bay + 1] - 0.15
        add_box(
            f"rear_wall_bay_{bay + 1}",
            ((x0 + x1) / 2.0, Y_REAR - 0.035, 3.03),
            (x1 - x0, 0.12, 2.60),
            wall,
            "30_WALLS",
            0.018,
        )
        if bay in (0, 2, 4, 5):
            add_lattice_y(
                f"rear_window_bay_{bay + 1}",
                x0 + (x1 - x0) * 0.24,
                x1 - (x1 - x0) * 0.24,
                Y_REAR + 0.04,
                2.58,
                3.58,
                5,
                4,
                1.0,
            )
        add_box(
            f"rear_lower_plank_{bay + 1}",
            ((x0 + x1) / 2.0, Y_REAR + 0.045, 1.86),
            (x1 - x0, 0.10, 0.40),
            plank,
            "30_WALLS",
            0.012,
        )

    # Left side is two bays; right side is four narrower bays.
    left_y = [Y_FRONT, Y_FRONT + 1.995, Y_REAR]
    for bay in range(2):
        y0 = left_y[bay] + 0.15
        y1 = left_y[bay + 1] - 0.15
        add_box(
            f"left_wall_bay_{bay + 1}",
            (X_MIN + 0.035, (y0 + y1) / 2.0, 3.03),
            (0.12, y1 - y0, 2.60),
            wall,
            "30_WALLS",
            0.018,
        )
        add_lattice_x(
            f"left_window_bay_{bay + 1}",
            y0 + 0.12,
            y1 - 0.12,
            X_MIN - 0.035,
            2.30,
            3.75,
            6,
            4,
            -1.0,
        )
    right_y = [Y_FRONT + MAIN_DEPTH * i / 4.0 for i in range(5)]
    for bay in range(4):
        y0 = right_y[bay] + 0.10
        y1 = right_y[bay + 1] - 0.10
        add_box(
            f"right_wall_bay_{bay + 1}",
            (X_MAX - 0.035, (y0 + y1) / 2.0, 3.03),
            (0.12, y1 - y0, 2.60),
            wall,
            "30_WALLS",
            0.018,
        )
        if bay in (0, 2):
            add_lattice_x(
                f"right_window_bay_{bay + 1}",
                y0 + 0.12,
                y1 - 0.12,
                X_MAX + 0.035,
                2.55,
                3.55,
                4,
                4,
                1.0,
            )

    # Projecting nummaru front: two windows sit behind a continuous railing.
    wing_x = [X_WING_MIN, X_WING_MIN + FRONT_BAYS[-1], X_MAX]
    for bay in range(2):
        x0 = wing_x[bay] + 0.16
        x1 = wing_x[bay + 1] - 0.16
        add_box(
            f"numaru_front_wall_{bay + 1}",
            ((x0 + x1) / 2.0, Y_WING_FRONT + 0.035, 3.25),
            (x1 - x0, 0.12, 1.95),
            wall,
            "30_WALLS",
            0.018,
        )
        add_lattice_y(
            f"numaru_front_window_{bay + 1}",
            x0 + 0.16,
            x1 - 0.16,
            Y_WING_FRONT - 0.035,
            2.55,
            3.68,
            5,
            4,
            -1.0,
        )


def build_railings() -> None:
    timber = MATERIALS["timber_dark"]
    z_low = NUMARU_FLOOR_Z + 0.14
    z_high = NUMARU_FLOOR_Z + 0.62
    y_front = Y_WING_FRONT - 0.18
    x_points = [X_WING_MIN, X_WING_MIN + FRONT_BAYS[-1], X_MAX]
    add_box(
        "numaru_front_bottom_rail",
        ((X_WING_MIN + X_MAX) / 2.0, y_front, z_low),
        (WING_WIDTH + 0.18, 0.09, 0.10),
        timber,
        "60_DETAILS",
        0.012,
    )
    add_box(
        "numaru_front_top_rail",
        ((X_WING_MIN + X_MAX) / 2.0, y_front, z_high),
        (WING_WIDTH + 0.22, 0.11, 0.12),
        timber,
        "60_DETAILS",
        0.012,
    )
    for index, x in enumerate(x_points):
        add_box(
            f"numaru_front_railing_post_{index}",
            (x, y_front, (z_low + z_high) / 2.0),
            (0.11, 0.11, z_high - z_low + 0.16),
            timber,
            "60_DETAILS",
            0.012,
        )
    for bay in range(2):
        x0 = x_points[bay] + 0.10
        x1 = x_points[bay + 1] - 0.10
        panel_count = 3 if DETAIL_MODE else 1
        panel_width = (x1 - x0) / panel_count
        for panel in range(panel_count):
            panel_x0 = x0 + panel_width * panel
            panel_x1 = x0 + panel_width * (panel + 1)
            up_name = (
                f"numaru_xbrace_up_{bay}_{panel}"
                if DETAIL_MODE
                else f"numaru_xbrace_up_{bay}"
            )
            down_name = (
                f"numaru_xbrace_down_{bay}_{panel}"
                if DETAIL_MODE
                else f"numaru_xbrace_down_{bay}"
            )
            if DETAIL_MODE and panel > 0:
                add_box(
                    f"numaru_front_detail_post_{bay}_{panel}",
                    (panel_x0, y_front, (z_low + z_high) / 2.0),
                    (0.075, 0.075, z_high - z_low),
                    timber,
                    "60_DETAILS",
                    0.008,
                )
            add_beam_between(
                up_name,
                (panel_x0 + 0.035, y_front - 0.01, z_low + 0.05),
                (panel_x1 - 0.035, y_front - 0.01, z_high - 0.05),
                0.052 if DETAIL_MODE else 0.065,
                timber,
                "60_DETAILS",
                0.008,
            )
            add_beam_between(
                down_name,
                (panel_x0 + 0.035, y_front - 0.015, z_high - 0.05),
                (panel_x1 - 0.035, y_front - 0.015, z_low + 0.05),
                0.052 if DETAIL_MODE else 0.065,
                timber,
                "60_DETAILS",
                0.008,
            )
    # The measured front uses repeated X panels, while the side uses the
    # distinct ansang/cloud family from the railing detail sheet.
    for side_x in (X_WING_MIN - 0.18, X_MAX + 0.18):
        add_box(
            f"numaru_side_top_rail_{side_x:.3f}",
            (side_x, (Y_WING_FRONT + Y_FRONT) / 2.0, z_high),
            (0.11, WING_DEPTH, 0.12),
            timber,
            "60_DETAILS",
            0.012,
        )
        add_box(
            f"numaru_side_bottom_rail_{side_x:.3f}",
            (side_x, (Y_WING_FRONT + Y_FRONT) / 2.0, z_low),
            (0.09, WING_DEPTH, 0.10),
            timber,
            "60_DETAILS",
            0.012,
        )
        if DETAIL_MODE:
            side_panels = 4
            panel_depth = WING_DEPTH / side_panels
            for panel in range(side_panels):
                y0 = Y_WING_FRONT + panel_depth * panel
                y1 = Y_WING_FRONT + panel_depth * (panel + 1)
                if panel > 0:
                    add_box(
                        f"numaru_side_detail_post_{side_x:.3f}_{panel}",
                        (side_x, y0, (z_low + z_high) / 2.0),
                        (0.075, 0.075, z_high - z_low),
                        timber,
                        "60_DETAILS",
                        0.008,
                    )
                mid_y = (y0 + y1) / 2.0
                mid_z = (z_low + z_high) / 2.0
                inset = 0.09
                add_curve(
                    f"numaru_side_ansang_{side_x:.3f}_{panel}",
                    [
                        (side_x, y0 + inset, mid_z),
                        (side_x, y0 + panel_depth * 0.23, mid_z + 0.11),
                        (side_x, mid_y - panel_depth * 0.10, mid_z + 0.035),
                        (side_x, mid_y, mid_z - 0.105),
                        (side_x, mid_y + panel_depth * 0.10, mid_z + 0.035),
                        (side_x, y1 - panel_depth * 0.23, mid_z + 0.11),
                        (side_x, y1 - inset, mid_z),
                    ],
                    0.026,
                    timber,
                    "60_DETAILS",
                    2,
                )
        else:
            for index in range(1, 6):
                y = Y_WING_FRONT + WING_DEPTH * index / 6.0
                add_box(
                    f"numaru_side_vertical_{side_x:.3f}_{index}",
                    (side_x, y, (z_low + z_high) / 2.0),
                    (0.075, 0.075, z_high - z_low),
                    timber,
                    "60_DETAILS",
                    0.008,
                )


def build_surface_details() -> None:
    """Add measured leaf rhythm and restrained domestic timber detailing."""
    timber = MATERIALS["timber_dark"]
    plank = MATERIALS["plank"]
    edge = MATERIALS["giwa_end"]
    grid_x = cumulative(FRONT_BAYS, X_MIN)

    # The first two broad openings are four-leaf groups; the next two read as
    # paired leaves.  Strong stiles remain legible after an oblique sprite bake.
    for bay in range(4):
        x0 = grid_x[bay] + 0.24
        x1 = grid_x[bay + 1] - 0.24
        leaf_count = 4 if bay < 2 else 2
        leaf_width = (x1 - x0) / leaf_count
        panel_bottom = 1.78
        panel_top = 2.10 if bay < 2 else 2.33
        for leaf in range(leaf_count):
            leaf_x0 = x0 + leaf_width * leaf
            leaf_x1 = x0 + leaf_width * (leaf + 1)
            add_box(
                f"front_meoreum_bay_{bay + 1}_leaf_{leaf + 1}",
                ((leaf_x0 + leaf_x1) / 2.0, -0.105, (panel_bottom + panel_top) / 2.0),
                (leaf_x1 - leaf_x0 - 0.035, 0.075, panel_top - panel_bottom),
                plank,
                "65_SURFACE_DETAIL",
                0.008,
            )
            if leaf > 0:
                add_box(
                    f"front_leaf_stile_bay_{bay + 1}_{leaf}",
                    (leaf_x0, -0.135, 2.91),
                    (0.060, 0.065, 2.10),
                    timber,
                    "65_SURFACE_DETAIL",
                    0.006,
                )
        # Modest paired ring pulls sit at the central meeting stile.
        pull_x = (x0 + x1) / 2.0
        for side in (-1.0, 1.0):
            add_cylinder(
                f"front_ring_pull_bay_{bay + 1}_{'l' if side < 0 else 'r'}",
                (pull_x + side * 0.075, -0.185, 2.70),
                0.042,
                0.032,
                (math.radians(90), 0.0, 0.0),
                edge,
                "65_SURFACE_DETAIL",
                12,
                0.004,
            )

    # The projecting nummaru has paired front leaves above a deeper lower band.
    wing_x = [X_WING_MIN, X_WING_MIN + FRONT_BAYS[-1], X_MAX]
    for bay in range(2):
        x0 = wing_x[bay] + 0.30
        x1 = wing_x[bay + 1] - 0.30
        mid_x = (x0 + x1) / 2.0
        add_box(
            f"numaru_front_leaf_stile_{bay + 1}",
            (mid_x, Y_WING_FRONT - 0.135, 3.11),
            (0.060, 0.065, 1.42),
            timber,
            "65_SURFACE_DETAIL",
            0.006,
        )
        for leaf in range(2):
            leaf_x0 = x0 if leaf == 0 else mid_x
            leaf_x1 = mid_x if leaf == 0 else x1
            add_box(
                f"numaru_meoreum_bay_{bay + 1}_leaf_{leaf + 1}",
                ((leaf_x0 + leaf_x1) / 2.0, Y_WING_FRONT - 0.105, 2.34),
                (leaf_x1 - leaf_x0 - 0.035, 0.075, 0.34),
                plank,
                "65_SURFACE_DETAIL",
                0.008,
            )
        for side in (-1.0, 1.0):
            add_cylinder(
                f"numaru_ring_pull_bay_{bay + 1}_{'l' if side < 0 else 'r'}",
                (mid_x + side * 0.065, Y_WING_FRONT - 0.185, 2.94),
                0.038,
                0.030,
                (math.radians(90), 0.0, 0.0),
                edge,
                "65_SURFACE_DETAIL",
                12,
                0.004,
            )

    # Short, single-stage bracket arms support the deep domestic eave.  They
    # intentionally avoid temple-scale stacked gongpo or decorative dancheong.
    for index, x in enumerate(grid_x):
        add_beam_between(
            f"front_detail_bracket_arm_{index:02d}",
            (x, -0.13, EAVE_BEAM_Z + 0.13),
            (x, -0.52, EAVE_BEAM_Z + 0.30),
            0.095,
            timber,
            "65_SURFACE_DETAIL",
            0.012,
        )
    for index, x in enumerate(wing_x):
        add_beam_between(
            f"numaru_detail_bracket_arm_{index:02d}",
            (x, Y_WING_FRONT - 0.13, EAVE_BEAM_Z + 0.13),
            (x, Y_WING_FRONT - 0.48, EAVE_BEAM_Z + 0.28),
            0.090,
            timber,
            "65_SURFACE_DETAIL",
            0.012,
        )


def build_roofs() -> None:
    tile_line = MATERIALS["giwa_highlight"]
    ridge_mat = MATERIALS["giwa_ridge"]
    timber_dark = MATERIALS["timber_dark"]

    main_xmin = X_MIN - EAVE_PROJECTION
    main_xmax = X_MAX + EAVE_PROJECTION
    main_ymin = Y_FRONT - EAVE_PROJECTION
    main_ymax = Y_REAR + EAVE_PROJECTION
    main_ridge_start = X_MIN + 0.485
    main_ridge_end = X_MAX - 0.480
    main_yc = (main_ymin + main_ymax) / 2.0
    make_roof_mesh(
        "main_paljak_roof",
        "X",
        main_xmin,
        main_xmax,
        main_ymin,
        main_ymax,
        main_ridge_start,
        main_ridge_end,
        4.62,
        RIDGE_Z,
    )

    # Main roof tile rhythm.  These are visual ribs, not a false claim that
    # every one of the measured 173 rafters has been individually reconstructed.
    for index in range(43):
        t = index / 42.0
        x = main_ridge_start + (main_ridge_end - main_ridge_start) * t
        lift = 0.20 * (abs(t - 0.5) * 2.0) ** 2
        add_curve(
            f"main_front_tile_rib_{index:02d}",
            [
                (x, main_ymin - 0.02, 4.60 + lift),
                (x, (main_ymin + main_yc) / 2.0, 5.55),
                (x, main_yc - 0.03, RIDGE_Z - 0.06),
            ],
            0.045,
            tile_line,
            "50_ROOF",
        )
        add_curve(
            f"main_rear_tile_rib_{index:02d}",
            [
                (x, main_ymax + 0.02, 4.60 + lift),
                (x, (main_ymax + main_yc) / 2.0, 5.55),
                (x, main_yc + 0.03, RIDGE_Z - 0.06),
            ],
            0.045,
            tile_line,
            "50_ROOF",
        )
    main_front_eave_points = (
        [
            (main_xmin, main_ymin - 0.05, 4.98),
            (main_ridge_start, main_ymin - 0.05, 4.66),
            (0.0, main_ymin - 0.05, 4.56),
            (X_WING_MIN - EAVE_PROJECTION, main_ymin - 0.05, 4.61),
        ]
        if DETAIL_MODE
        else [
            (main_xmin, main_ymin - 0.05, 4.98),
            (main_ridge_start, main_ymin - 0.05, 4.66),
            (0.0, main_ymin - 0.05, 4.56),
            (main_ridge_end, main_ymin - 0.05, 4.66),
            (main_xmax, main_ymin - 0.05, 4.98),
        ]
    )
    add_curve(
        "main_front_upturned_eave",
        main_front_eave_points,
        0.12,
        ridge_mat,
        "50_ROOF",
    )
    add_curve(
        "main_rear_upturned_eave",
        [
            (main_xmin, main_ymax + 0.05, 4.98),
            (main_ridge_start, main_ymax + 0.05, 4.66),
            (0.0, main_ymax + 0.05, 4.56),
            (main_ridge_end, main_ymax + 0.05, 4.66),
            (main_xmax, main_ymax + 0.05, 4.98),
        ],
        0.12,
        ridge_mat,
        "50_ROOF",
    )
    add_curve(
        "main_ridge_five_course_proxy",
        [
            (main_ridge_start, main_yc, RIDGE_Z + 0.05),
            (0.0, main_yc, RIDGE_Z + 0.14),
            (main_ridge_end, main_yc, RIDGE_Z + 0.05),
        ],
        0.145,
        ridge_mat,
        "50_ROOF",
    )
    main_hips = [
        ("main_hip_front_left", (main_xmin, main_ymin, 4.98), (main_ridge_start, main_yc, RIDGE_Z)),
        ("main_hip_rear_left", (main_xmin, main_ymax, 4.98), (main_ridge_start, main_yc, RIDGE_Z)),
        ("main_hip_front_right", (main_xmax, main_ymin, 4.98), (main_ridge_end, main_yc, RIDGE_Z)),
        ("main_hip_rear_right", (main_xmax, main_ymax, 4.98), (main_ridge_end, main_yc, RIDGE_Z)),
    ]
    if DETAIL_MODE:
        # The projecting roof occupies this corner; keeping the independent hip
        # here makes the two roofs read as stacked pavilions rather than one ㄱ.
        main_hips = [item for item in main_hips if item[0] != "main_hip_front_right"]
    for name, corner, ridge in main_hips:
        add_curve(name, [corner, ridge], 0.105, ridge_mat, "50_ROOF")

    # Main left/right gable boards are deliberately modest: domestic paljak,
    # no temple-style layered bracket or dancheong.
    add_triangle(
        "main_left_gable_board",
        [
            (main_ridge_start - 0.03, main_yc - 1.00, 5.38),
            (main_ridge_start - 0.03, main_yc + 1.00, 5.38),
            (main_ridge_start - 0.03, main_yc, RIDGE_Z - 0.10),
        ],
        MATERIALS["gable_wood"] if DETAIL_MODE else timber_dark,
        "60_DETAILS",
    )
    add_triangle(
        "main_right_gable_board",
        [
            (main_ridge_end + 0.03, main_yc + 1.00, 5.38),
            (main_ridge_end + 0.03, main_yc - 1.00, 5.38),
            (main_ridge_end + 0.03, main_yc, RIDGE_Z - 0.10),
        ],
        MATERIALS["gable_wood"] if DETAIL_MODE else timber_dark,
        "60_DETAILS",
    )

    # Perpendicular roof over the measured 3.970 m nummaru wing.
    wing_xmin = X_WING_MIN - EAVE_PROJECTION
    wing_xmax = X_MAX + EAVE_PROJECTION
    wing_ymin = Y_WING_FRONT - EAVE_PROJECTION
    wing_ymax = main_yc + 0.04 if DETAIL_MODE else Y_FRONT + EAVE_PROJECTION
    wing_xc = (wing_xmin + wing_xmax) / 2.0
    wing_ridge_start = Y_WING_FRONT + 0.45
    wing_ridge_end = main_yc if DETAIL_MODE else Y_FRONT + 1.20
    make_roof_mesh(
        "numaru_paljak_roof",
        "Y",
        wing_xmin,
        wing_xmax,
        wing_ymin,
        wing_ymax,
        wing_ridge_start,
        wing_ridge_end,
        4.66,
        RIDGE_Z + 0.01,
    )
    for index in range(19):
        t = index / 18.0
        y = wing_ridge_start + (wing_ridge_end - wing_ridge_start) * t
        add_curve(
            f"wing_left_tile_rib_{index:02d}",
            [
                (wing_xmin - 0.02, y, 4.66),
                ((wing_xmin + wing_xc) / 2.0, y, 5.58),
                (wing_xc - 0.03, y, RIDGE_Z - 0.04),
            ],
            0.045,
            tile_line,
            "50_ROOF",
        )
        add_curve(
            f"wing_right_tile_rib_{index:02d}",
            [
                (wing_xmax + 0.02, y, 4.66),
                ((wing_xmax + wing_xc) / 2.0, y, 5.58),
                (wing_xc + 0.03, y, RIDGE_Z - 0.04),
            ],
            0.045,
            tile_line,
            "50_ROOF",
        )
    for side_name, x in (("left", wing_xmin), ("right", wing_xmax)):
        wing_eave_points = (
            [
                (x, wing_ymin, 4.98),
                (x, wing_ridge_start, 4.66),
                (x, main_ymin - 0.04, 4.61),
            ]
            if DETAIL_MODE
            else [
                (x, wing_ymin, 4.98),
                (x, wing_ridge_start, 4.66),
                (x, (wing_ridge_start + wing_ridge_end) / 2.0, 4.58),
                (x, wing_ridge_end, 4.66),
                (x, wing_ymax, 4.98),
            ]
        )
        add_curve(
            f"wing_{side_name}_upturned_eave",
            wing_eave_points,
            0.12,
            ridge_mat,
            "50_ROOF",
        )
    add_curve(
        "wing_ridge_five_course_proxy",
        [
            (wing_xc, wing_ridge_start, RIDGE_Z + 0.06),
            (wing_xc, (wing_ridge_start + wing_ridge_end) / 2.0, RIDGE_Z + 0.14),
            (wing_xc, wing_ridge_end, RIDGE_Z + 0.06),
        ],
        0.145,
        ridge_mat,
        "50_ROOF",
    )
    wing_hips = [
        ("wing_hip_front_left", (wing_xmin, wing_ymin, 4.98), (wing_xc, wing_ridge_start, RIDGE_Z)),
        ("wing_hip_front_right", (wing_xmax, wing_ymin, 4.98), (wing_xc, wing_ridge_start, RIDGE_Z)),
        ("wing_hip_rear_left", (wing_xmin, wing_ymax, 4.98), (wing_xc, wing_ridge_end, RIDGE_Z)),
        ("wing_hip_rear_right", (wing_xmax, wing_ymax, 4.98), (wing_xc, wing_ridge_end, RIDGE_Z)),
    ]
    if DETAIL_MODE:
        wing_hips = [item for item in wing_hips if "rear" not in item[0]]
    for name, corner, ridge in wing_hips:
        add_curve(name, [corner, ridge], 0.105, ridge_mat, "50_ROOF")
    add_triangle(
        "numaru_front_gable_board",
        [
            (wing_xc - 1.00, wing_ridge_start - 0.03, 5.40),
            (wing_xc + 1.00, wing_ridge_start - 0.03, 5.40),
            (wing_xc, wing_ridge_start - 0.03, RIDGE_Z - 0.08),
        ],
        MATERIALS["gable_wood"] if DETAIL_MODE else timber_dark,
        "60_DETAILS",
    )

    # Exposed single-rafter eaves: one row only, reinforcing 홑처마.
    for index in range(37):
        x = main_ridge_start + (main_ridge_end - main_ridge_start) * index / 36.0
        add_beam_between(
            f"single_eave_rafter_front_{index:02d}",
            (x, main_ymin + 0.04, 4.18),
            (x, main_ymin + 0.52, 4.30),
            0.075,
            timber_dark,
            "60_DETAILS",
            0.005,
        )

    if DETAIL_MODE:
        build_roof_details(
            main_xmin,
            main_xmax,
            main_ymin,
            main_ymax,
            main_ridge_start,
            main_ridge_end,
            main_yc,
            wing_xmin,
            wing_xmax,
            wing_ymin,
            wing_ymax,
            wing_ridge_start,
            wing_ridge_end,
            wing_xc,
        )


def build_roof_details(
    main_xmin: float,
    main_xmax: float,
    main_ymin: float,
    main_ymax: float,
    main_ridge_start: float,
    main_ridge_end: float,
    main_yc: float,
    wing_xmin: float,
    wing_xmax: float,
    wing_ymin: float,
    wing_ymax: float,
    wing_ridge_start: float,
    wing_ridge_end: float,
    wing_xc: float,
) -> None:
    ridge = MATERIALS["giwa_ridge"]
    edge = MATERIALS["giwa_end"]
    timber = MATERIALS["timber_dark"]
    gable = MATERIALS["gable_wood"]

    # Stacked ridge courses read as domestic giwa construction without the
    # oversized temple silhouette that a single thick tube produced.
    for course, (y_offset, z_offset, radius) in enumerate(
        ((-0.08, 0.02, 0.075), (0.08, 0.08, 0.070), (0.0, 0.17, 0.060))
    ):
        add_curve(
            f"main_ridge_course_{course + 1}",
            [
                (main_ridge_start, main_yc + y_offset, RIDGE_Z + z_offset),
                (0.0, main_yc + y_offset, RIDGE_Z + z_offset + 0.07),
                (main_ridge_end, main_yc + y_offset, RIDGE_Z + z_offset),
            ],
            radius,
            ridge,
            "55_ROOF_DETAIL",
        )
    for course, (x_offset, z_offset, radius) in enumerate(
        ((-0.08, 0.02, 0.070), (0.08, 0.08, 0.065), (0.0, 0.16, 0.055))
    ):
        add_curve(
            f"wing_ridge_course_{course + 1}",
            [
                (wing_xc + x_offset, wing_ridge_start, RIDGE_Z + z_offset),
                (wing_xc + x_offset, (wing_ridge_start + wing_ridge_end) / 2.0, RIDGE_Z + z_offset + 0.05),
                (wing_xc + x_offset, wing_ridge_end, RIDGE_Z + z_offset),
            ],
            radius,
            ridge,
            "55_ROOF_DETAIL",
        )

    # 회첨골: the single internal valley joins the front eave re-entrant corner
    # to the common ridge intersection and visually seals the two roof shells.
    valley_points = [
        (wing_xmin + 0.05, main_ymin + 0.08, 4.72),
        ((wing_xmin + wing_xc) / 2.0, (main_ymin + main_yc) / 2.0, 5.58),
        (wing_xc, main_yc, RIDGE_Z + 0.06),
    ]
    add_curve("hoecheom_valley_underlay", valley_points, 0.135, ridge, "55_ROOF_DETAIL")
    add_curve(
        "hoecheom_valley_highlight",
        [(x, y - 0.015, z + 0.055) for x, y, z in valley_points],
        0.045,
        MATERIALS["giwa_highlight"],
        "55_ROOF_DETAIL",
    )

    # Warm, low-poly maksae faces make roof direction legible at sprite scale.
    for index in range(43):
        t = index / 42.0
        x = main_ridge_start + (main_ridge_end - main_ridge_start) * t
        lift = 0.20 * (abs(t - 0.5) * 2.0) ** 2
        for side, y, rotation in (
            ("front", main_ymin - 0.08, (math.radians(90), 0.0, 0.0)),
            ("rear", main_ymax + 0.08, (math.radians(90), 0.0, 0.0)),
        ):
            add_cylinder(
                f"main_{side}_maksae_{index:02d}",
                (x, y, 4.64 + lift),
                0.082,
                0.11,
                rotation,
                edge,
                "55_ROOF_DETAIL",
                10,
                0.008,
            )
    for index in range(21):
        t = index / 20.0
        y = (
            wing_ymin + 0.14 + (main_ymin - wing_ymin - 0.24) * t
            if DETAIL_MODE
            else wing_ridge_start + (wing_ridge_end - wing_ridge_start) * t
        )
        lift = 0.16 * (1.0 - t) ** 2
        for side, x, rotation in (
            ("left", wing_xmin - 0.08, (0.0, math.radians(90), 0.0)),
            ("right", wing_xmax + 0.08, (0.0, math.radians(90), 0.0)),
        ):
            add_cylinder(
                f"wing_{side}_maksae_{index:02d}",
                (x, y, 4.68 + lift),
                0.082,
                0.11,
                rotation,
                edge,
                "55_ROOF_DETAIL",
                10,
                0.008,
            )

    # Round exposed rafter ends reinforce that this is a deep single eave.
    for index in range(37):
        t = index / 36.0
        x = main_ridge_start + (main_ridge_end - main_ridge_start) * t
        for side, y in (("front", main_ymin + 0.02), ("rear", main_ymax - 0.02)):
            add_cylinder(
                f"main_{side}_rafter_end_{index:02d}",
                (x, y, 4.18),
                0.065,
                0.13,
                (math.radians(90), 0.0, 0.0),
                timber,
                "55_ROOF_DETAIL",
                10,
            )

    # The front hapgak has restrained ventilation slats, as in the elevation.
    gable_y = wing_ridge_start - 0.10
    for index, (z, width) in enumerate(((5.62, 1.18), (5.82, 0.94), (6.02, 0.68))):
        add_box(
            f"numaru_hapgak_vent_{index + 1}",
            (wing_xc, gable_y, z),
            (width, 0.055, 0.055),
            gable,
            "55_ROOF_DETAIL",
            0.012,
        )
    add_box(
        "numaru_hapgak_centre_stile",
        (wing_xc, gable_y - 0.005, 5.91),
        (0.07, 0.06, 0.78),
        gable,
        "55_ROOF_DETAIL",
        0.012,
    )

    # Modest decorative ridge-end caps; no readable lettering or dancheong.
    for name, location, rotation in (
        ("main_ridge_endcap_left", (main_ridge_start - 0.05, main_yc, RIDGE_Z + 0.15), (0.0, math.radians(90), 0.0)),
        ("main_ridge_endcap_right", (main_ridge_end + 0.05, main_yc, RIDGE_Z + 0.15), (0.0, math.radians(90), 0.0)),
        ("wing_ridge_endcap_front", (wing_xc, wing_ridge_start - 0.05, RIDGE_Z + 0.14), (math.radians(90), 0.0, 0.0)),
    ):
        add_cylinder(name, location, 0.17, 0.13, rotation, edge, "55_ROOF_DETAIL", 12, 0.012)

    # Rounded eave terminals prevent oblique views from reading a dark tube
    # cross-section as a hole in the roof skin.
    eave_terminals = [
        (main_xmin, main_ymin - 0.05, 4.98),
        (main_xmin, main_ymax + 0.05, 4.98),
        (main_xmax, main_ymax + 0.05, 4.98),
        (wing_xmin, wing_ymin, 4.98),
        (wing_xmax, wing_ymin, 4.98),
    ]
    for index, location in enumerate(eave_terminals):
        add_ico_sphere(
            f"eave_terminal_cap_{index:02d}",
            location,
            0.128,
            edge,
            "55_ROOF_DETAIL",
        )


def build_hwalju() -> None:
    granite = MATERIALS["granite"]
    timber = MATERIALS["timber"]
    positions = [
        (X_MIN - 1.10, Y_FRONT - 1.22, 4.78 if DETAIL_MODE else 4.88, "body_left"),
        (X_MAX + 1.05, Y_WING_FRONT - 1.18, 4.80 if DETAIL_MODE else 4.92, "numaru_outer"),
    ]
    for x, y, z_top, label in positions:
        bpy.ops.mesh.primitive_cone_add(
            vertices=8,
            radius1=0.34,
            radius2=0.28,
            depth=0.62,
            location=(x, y, 0.31),
        )
        base = bpy.context.object
        base.name = f"hwalju_octagonal_stone_base_{label}"
        assign_material(base, granite)
        move_to_collection(base, "10_FOUNDATION")
        parent_to_root(base)
        add_post(
            f"hwalju_load_bearing_post_{label}",
            x,
            y,
            0.62,
            z_top,
            radius_bottom=0.105,
            radius_top=0.090,
            vertices=12,
            mat=timber,
            collection="60_DETAILS",
        )
        add_beam_between(
            f"hwalju_top_contact_{label}",
            (x, y, z_top - 0.05),
            (
                x + (-0.25 if label == "body_left" else 0.25),
                y + 0.18,
                z_top + (0.05 if DETAIL_MODE else 0.08),
            ),
            0.11,
            timber,
            "60_DETAILS",
            0.012,
        )


def build_dimension_guides() -> None:
    guide = MATERIALS["guide"]
    z = 0.035
    # These guides are viewport-only and excluded from renders/exports.
    outline_points = [
        (X_MIN, Y_FRONT, z),
        (X_MAX, Y_FRONT, z),
        (X_MAX, Y_REAR, z),
        (X_MIN, Y_REAR, z),
        (X_MIN, Y_FRONT, z),
    ]
    add_curve("measured_main_footprint", outline_points, 0.028, guide, "00_REFERENCE", 1)
    wing_points = [
        (X_WING_MIN, Y_WING_FRONT, z),
        (X_MAX, Y_WING_FRONT, z),
        (X_MAX, Y_FRONT, z),
        (X_WING_MIN, Y_FRONT, z),
        (X_WING_MIN, Y_WING_FRONT, z),
    ]
    add_curve("measured_wing_footprint", wing_points, 0.028, guide, "00_REFERENCE", 1)
    COLLECTIONS["00_REFERENCE"].hide_render = True


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_scene(resolution_x: int, resolution_y: int) -> bpy.types.Object:
    scene = bpy.context.scene
    # Blender 5.2 exposes Eevee as BLENDER_EEVEE (the 4.x NEXT identifier was
    # folded back into the stable name).
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = resolution_x
    scene.render.resolution_y = resolution_y
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.render.image_settings.compression = 25
    scene.render.resolution_percentage = 100
    scene.render.pixel_aspect_x = 1.0
    scene.render.pixel_aspect_y = 1.0
    scene.render.use_file_extension = True
    scene.render.fps = 24
    try:
        scene.view_settings.look = "AgX - Medium High Contrast"
    except TypeError:
        pass

    world = bpy.data.worlds.new("Ildu neutral world")
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.12, 0.14, 0.14, 1.0)
    background.inputs["Strength"].default_value = 0.55
    scene.world = world

    camera_data = bpy.data.cameras.new("personal_map_north_up_oblique_v3")
    camera = bpy.data.objects.new("personal_map_north_up_oblique_v3", camera_data)
    COLLECTIONS["90_CAMERA_LIGHT"].objects.link(camera)
    camera.location = (0.0, -32.0, 10.0)
    camera_data.type = "ORTHO"
    # Blender's orthographic scale is the camera-frame width.  23 m safely
    # contains the 20.37 m plan diagonal plus both load-bearing hwalju, so no
    # cardinal or diagonal render can crop a roof tip.
    camera_data.ortho_scale = 23.0
    camera_data.lens = 70.0
    look_at(camera, (0.0, 0.0, 3.15))
    scene.camera = camera

    key_data = bpy.data.lights.new("soft_upper_left_key", "AREA")
    key_data.energy = 1150.0
    key_data.shape = "DISK"
    key_data.size = 9.0
    key = bpy.data.objects.new("soft_upper_left_key", key_data)
    COLLECTIONS["90_CAMERA_LIGHT"].objects.link(key)
    key.location = (-11.0, -13.0, 17.0)
    look_at(key, (0.0, 0.0, 2.8))

    fill_data = bpy.data.lights.new("soft_rear_fill", "AREA")
    fill_data.energy = 650.0
    fill_data.shape = "DISK"
    fill_data.size = 10.0
    fill = bpy.data.objects.new("soft_rear_fill", fill_data)
    COLLECTIONS["90_CAMERA_LIGHT"].objects.link(fill)
    fill.location = (10.0, 9.0, 12.0)
    look_at(fill, (0.0, 0.0, 3.0))

    sun_data = bpy.data.lights.new("gentle_sun", "SUN")
    sun_data.energy = 1.25
    sun_data.angle = math.radians(20.0)
    sun = bpy.data.objects.new("gentle_sun", sun_data)
    COLLECTIONS["90_CAMERA_LIGHT"].objects.link(sun)
    sun.rotation_euler = (math.radians(32), math.radians(-18), math.radians(-28))
    return camera


def find_node(nodes: bpy.types.Nodes, bl_idname: str, fallback_name: str) -> bpy.types.Node | None:
    """Find a shader node without depending on the Blender UI language."""

    for node in nodes:
        if node.bl_idname == bl_idname:
            return node
    return nodes.get(fallback_name)


def projected_material(
    base_material: bpy.types.Material,
    source_image: bpy.types.Image,
    cache: dict[str, bpy.types.Material],
) -> bpy.types.Material:
    """Overlay the unchanged user image through the anchor-camera UV layer."""

    cached = cache.get(base_material.name)
    if cached is not None:
        return cached
    projected = base_material.copy()
    projected.name = f"{base_material.name}_source_projected"
    projected["source_base_material"] = base_material.name
    base_material["source_projected_material"] = projected.name
    projected.use_nodes = True
    nodes = projected.node_tree.nodes
    links = projected.node_tree.links
    output = find_node(nodes, "ShaderNodeOutputMaterial", "Material Output")
    if output is None or not output.inputs["Surface"].is_linked:
        cache[base_material.name] = projected
        return projected
    links.remove(output.inputs["Surface"].links[0])
    uv_node = nodes.new("ShaderNodeUVMap")
    uv_node.name = "Source projection UV"
    uv_node.uv_map = SOURCE_PROJECTION_UV
    image_node = nodes.new("ShaderNodeTexImage")
    image_node.name = "Original sarangchae source"
    image_node.image = source_image
    image_node.interpolation = "Linear"
    image_node.extension = "CLIP"
    emission = nodes.new("ShaderNodeEmission")
    emission.name = "Source image emission"
    emission.inputs["Strength"].default_value = 1.0
    luminance = nodes.new("ShaderNodeRGBToBW")
    non_black = nodes.new("ShaderNodeMath")
    non_black.operation = "GREATER_THAN"
    non_black.inputs[1].default_value = 0.018
    usable_alpha = nodes.new("ShaderNodeMath")
    usable_alpha.operation = "MULTIPLY"
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    transparent.name = "Transparent outside source silhouette"
    mix = nodes.new("ShaderNodeMixShader")
    links.new(uv_node.outputs["UV"], image_node.inputs["Vector"])
    links.new(image_node.outputs["Color"], emission.inputs["Color"])
    links.new(image_node.outputs["Color"], luminance.inputs["Color"])
    links.new(luminance.outputs["Val"], non_black.inputs[0])
    links.new(image_node.outputs["Alpha"], usable_alpha.inputs[0])
    links.new(non_black.outputs[0], usable_alpha.inputs[1])
    links.new(usable_alpha.outputs[0], mix.inputs["Fac"])
    links.new(transparent.outputs["BSDF"], mix.inputs[1])
    links.new(emission.outputs["Emission"], mix.inputs[2])
    links.new(mix.outputs["Shader"], output.inputs["Surface"])
    cache[base_material.name] = projected
    return projected


def apply_source_projection(camera: bpy.types.Object) -> dict[str, int | float | str]:
    """Project the source PNG onto anchor-visible geometry and pack it in the blend."""

    assert ROOT is not None
    if not SOURCE_ANCHOR_PATH.is_file():
        raise FileNotFoundError(f"Projection source is missing: {SOURCE_ANCHOR_PATH}")
    if not SOURCE_PROJECTION_PATH.is_file():
        raise FileNotFoundError(
            f"Projection canvas is missing: {SOURCE_PROJECTION_PATH}. "
            "Run prepare_ildu_sarangchae_projection.py first."
        )
    scene = bpy.context.scene
    scene.view_settings.view_transform = "Standard"
    try:
        scene.view_settings.look = "Medium High Contrast"
    except TypeError:
        scene.view_settings.look = "None"
    original_image = bpy.data.images.load(str(SOURCE_ANCHOR_PATH), check_existing=True)
    original_image.name = "Sarangchae unchanged original source"
    original_image.alpha_mode = "STRAIGHT"
    original_image.pack()
    original_image.use_fake_user = True
    source_image = bpy.data.images.load(str(SOURCE_PROJECTION_PATH), check_existing=True)
    source_image.name = "Sarangchae projection framing derivative"
    source_image.alpha_mode = "STRAIGHT"
    source_image.pack()
    source_image.use_fake_user = True

    for obj in COLLECTIONS["55_ROOF_DETAIL"].objects:
        obj["projection_proxy"] = True

    ROOT.rotation_euler[2] = math.radians(SOURCE_ANCHOR_ANGLE_DEGREES)
    bpy.context.view_layer.update()
    cache: dict[str, bpy.types.Material] = {}
    projected_objects = 0
    projected_faces = 0
    rejected_faces = 0
    for obj in [item for item in scene.objects if item.type == "MESH"]:
        collection_names = {collection.name for collection in obj.users_collection}
        if "00_REFERENCE" in collection_names or "05_GRADE_PROXY" in collection_names:
            continue
        if obj.get("projection_proxy", False):
            continue
        mesh = obj.data
        uv_layer = mesh.uv_layers.get(SOURCE_PROJECTION_UV)
        if uv_layer is None:
            uv_layer = mesh.uv_layers.new(name=SOURCE_PROJECTION_UV)
        world_matrix = obj.matrix_world
        normal_matrix = world_matrix.to_3x3()
        visible_faces = 0
        for polygon in mesh.polygons:
            center_world = world_matrix @ polygon.center
            toward_camera = (camera.location - center_world).normalized()
            normal_world = (normal_matrix @ polygon.normal).normalized()
            if normal_world.dot(toward_camera) <= 0.02:
                for loop_index in polygon.loop_indices:
                    uv_layer.data[loop_index].uv = (-2.0, -2.0)
                rejected_faces += 1
                continue
            for loop_index in polygon.loop_indices:
                vertex_index = mesh.loops[loop_index].vertex_index
                world_coordinate = world_matrix @ mesh.vertices[vertex_index].co
                camera_coordinate = world_to_camera_view(scene, camera, world_coordinate)
                uv_layer.data[loop_index].uv = (camera_coordinate.x, camera_coordinate.y)
            visible_faces += 1
            projected_faces += 1
        if visible_faces == 0:
            continue
        for slot in obj.material_slots:
            if slot.material is not None:
                slot.material = projected_material(slot.material, source_image, cache)
        obj["source_projection_target"] = True
        projected_objects += 1
    ROOT.rotation_euler[2] = 0.0
    bpy.context.view_layer.update()
    result: dict[str, int | float | str] = {
        "sourceSha256": hashlib.sha256(SOURCE_ANCHOR_PATH.read_bytes()).hexdigest(),
        "projectionCanvasSha256": hashlib.sha256(SOURCE_PROJECTION_PATH.read_bytes()).hexdigest(),
        "anchorView": SOURCE_ANCHOR_VIEW,
        "anchorAngleDegrees": SOURCE_ANCHOR_ANGLE_DEGREES,
        "projectedObjects": projected_objects,
        "projectedFaces": projected_faces,
        "rejectedBackFaces": rejected_faces,
        "uvLayer": SOURCE_PROJECTION_UV,
        "status": "passed",
    }
    print(f"PROJECTION_VALIDATION {json.dumps(result, ensure_ascii=False)}")
    return result


def set_final_projection_enabled(enabled: bool) -> None:
    if not FINAL_MODE:
        return
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        for slot in obj.material_slots:
            current = slot.material
            if current is None:
                continue
            target_name = (
                current.get("source_projected_material")
                if enabled
                else current.get("source_base_material")
            )
            if target_name:
                target = bpy.data.materials.get(target_name)
                if target is not None:
                    slot.material = target


def set_projection_proxies_visible(visible: bool) -> None:
    for obj in bpy.context.scene.objects:
        if obj.get("projection_proxy", False):
            obj.hide_render = not visible
            obj.hide_set(not visible)


def set_final_render_visibility(anchor: bool) -> None:
    """Keep review guides/terrain out and isolate projected surfaces at the anchor."""

    if not FINAL_MODE:
        return
    for obj in bpy.context.scene.objects:
        collection_names = {collection.name for collection in obj.users_collection}
        always_hidden = bool(collection_names & {"00_REFERENCE", "05_GRADE_PROXY"})
        anchor_hidden = (
            anchor
            and obj.type in {"MESH", "CURVE"}
            and not obj.get("source_projection_target", False)
        )
        hidden = always_hidden or anchor_hidden
        obj.hide_render = hidden
        obj.hide_set(hidden)


def build_metadata() -> None:
    assert ROOT is not None
    ROOT["asset_id"] = "ildu_sarangchae"
    ROOT["status"] = f"pending_review_{ASSET_VERSION}"
    ROOT["asset_version"] = ASSET_VERSION
    ROOT["source_report"] = "2007 국가민속문화재 함양 일두고택 기록화보고서"
    ROOT["front_total_m"] = FRONT_TOTAL
    ROOT["main_depth_m"] = MAIN_DEPTH
    ROOT["right_side_total_m"] = SIDE_TOTAL_RIGHT
    ROOT["wing_width_m"] = WING_WIDTH
    ROOT["eave_projection_m"] = EAVE_PROJECTION
    ROOT["ridge_level_m_front_gl"] = RIDGE_Z
    ROOT["front_bays_mm"] = json.dumps([round(v * 1000) for v in FRONT_BAYS])
    ROOT["coordinate_system"] = "X=long body, negative Y=courtyard/front, Z=up"


def validate_model() -> dict[str, int | float | str]:
    """Fail fast when a future edit breaks a measured structural invariant."""
    assert abs(sum(FRONT_BAYS) - FRONT_TOTAL) < 0.000001
    assert abs(MAIN_DEPTH + WING_DEPTH - SIDE_TOTAL_RIGHT) < 0.000001
    objects = list(bpy.context.scene.objects)
    names = {obj.name for obj in objects}
    checks = {
        "mainFrontPosts": sum(name.startswith("main_front_post_") for name in names),
        "mainRearPosts": sum(name.startswith("main_rear_post_") for name in names),
        "wingUpperPosts": sum(name.startswith("wing_upper_post_") for name in names),
        "wingOctagonalUnderposts": sum(name.startswith("wing_octagonal_underpost_") for name in names),
        "hwalju": sum(name.startswith("hwalju_load_bearing_post_") for name in names),
        "roofVolumes": sum(name in {"main_paljak_roof", "numaru_paljak_roof"} for name in names),
        "sceneObjects": len(objects),
    }
    if DETAIL_MODE:
        checks.update(
            {
                "roofValleyCurves": sum(name.startswith("hoecheom_valley_") for name in names),
                "maksaeFaces": sum("_maksae_" in name for name in names),
                "exposedRafterEnds": sum("_rafter_end_" in name for name in names),
                "frontRailingBraces": sum(name.startswith("numaru_xbrace_") for name in names),
                "sideAnsangPanels": sum(name.startswith("numaru_side_ansang_") for name in names),
                "frontMeoreumLeaves": sum(name.startswith("front_meoreum_bay_") for name in names),
                "numaruMeoreumLeaves": sum(name.startswith("numaru_meoreum_bay_") for name in names),
                "detailBracketArms": sum("detail_bracket_arm_" in name for name in names),
                "eaveTerminalCaps": sum(name.startswith("eave_terminal_cap_") for name in names),
            }
        )
    assert checks["mainFrontPosts"] == 7
    assert checks["mainRearPosts"] == 7
    assert checks["wingUpperPosts"] == 9
    assert checks["wingOctagonalUnderposts"] == 6
    assert checks["hwalju"] == 2
    assert checks["roofVolumes"] == 2
    assert "front_opening_bay_1_hanji" in names
    assert "rear_window_bay_1_hanji" in names
    assert "numaru_front_window_1_hanji" in names
    assert not any("dancheong" in name.lower() for name in names)
    if DETAIL_MODE:
        assert checks["roofValleyCurves"] == 2
        assert checks["maksaeFaces"] == 128
        assert checks["exposedRafterEnds"] == 74
        assert checks["frontRailingBraces"] == 12
        assert checks["sideAnsangPanels"] == 8
        assert checks["frontMeoreumLeaves"] == 12
        assert checks["numaruMeoreumLeaves"] == 4
        assert checks["detailBracketArms"] == 10
        assert checks["eaveTerminalCaps"] == 5
        assert not any(name.startswith("numaru_side_vertical_") for name in names)
    checks["status"] = "passed"
    print(f"MODEL_VALIDATION {json.dumps(checks, ensure_ascii=False)}")
    return checks


def render_turnaround(anchor_only: bool = False) -> list[str]:
    assert ROOT is not None
    names = (
        [
            ("00_source_anchor", 0.0),
            ("01_clockwise_045", 45.0),
            ("02_clockwise_090", 90.0),
            ("03_clockwise_135", 135.0),
            ("04_clockwise_180", 180.0),
            ("05_clockwise_225", 225.0),
            ("06_clockwise_270", 270.0),
            ("07_clockwise_315", 315.0),
        ]
        if FINAL_MODE
        else [
            ("00_front", 0.0),
            ("01_front_right", 45.0),
            ("02_right", 90.0),
            ("03_rear_right", 135.0),
            ("04_rear", 180.0),
            ("05_rear_left", 225.0),
            ("06_left", 270.0),
            ("07_front_left", 315.0),
        ]
    )
    if anchor_only:
        names = names[:1]
    scene = bpy.context.scene
    outputs: list[str] = []
    for name, angle in names:
        if FINAL_MODE:
            anchor = name == SOURCE_ANCHOR_VIEW
            set_final_projection_enabled(anchor)
            set_projection_proxies_visible(not anchor)
            set_final_render_visibility(anchor)
        ROOT.rotation_euler[2] = math.radians(angle)
        bpy.context.view_layer.update()
        path = RENDER_DIR / f"{OUTPUT_STEM}_{name}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        outputs.append(str(path))
        print(f"RENDERED {angle:6.1f} deg -> {path}")
    ROOT.rotation_euler[2] = 0.0
    if FINAL_MODE:
        set_final_projection_enabled(True)
        set_projection_proxies_visible(True)
        set_final_render_visibility(False)
    bpy.context.view_layer.update()
    return outputs


def export_files() -> None:
    assert ROOT is not None
    ROOT.rotation_euler[2] = 0.0
    bpy.context.view_layer.update()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH), check_existing=False)
    glb_excluded_objects = [
        *COLLECTIONS["00_REFERENCE"].objects,
        *COLLECTIONS["05_GRADE_PROXY"].objects,
    ]
    for obj in glb_excluded_objects:
        obj.hide_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        export_apply=True,
        use_visible=True,
        export_extras=True,
        export_cameras=False,
        export_lights=False,
    )
    for obj in glb_excluded_objects:
        obj.hide_set(False)


def write_manifest(
    render_outputs: list[str],
    validation: dict[str, int | float | str],
    projection_validation: dict[str, int | float | str] | None = None,
) -> None:
    source_files = [
        "docs/data/heritage_houses/_sprite_spec_2026-08-24.md",
        "docs/data/heritage_houses/ildu_gotaek_measured.json",
        "assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_지붕_평면도.jpg",
        "assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_정면도.jpg",
        "assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_우측면도.jpg",
        "assets_unused/pending_review/personal_hanok_v3/sarangchae_try07_edit.png",
    ]
    if DETAIL_MODE:
        source_files.extend(
            [
                "assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_난간_상세도.jpg",
                "assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_1번,2번,3번,4번_안허리_상세도.jpg",
                "assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_5번,6번_안허리_상세도.jpg",
                "assets_unused/pending_review/personal_hanok_v3/함양_일두고택_전경_서비스.jpg",
                "assets_unused/pending_review/personal_hanok_v3/함양_일두고택_우측_전경_원본.jpg",
                "assets_unused/pending_review/personal_hanok_v3/함양_일두고택_좌측면_서비스.jpg",
                "assets_unused/pending_review/personal_hanok_v3/함양_일두고택_배면_서비스.jpg",
            ]
        )
    data = {
        "assetId": "ildu_sarangchae",
        "version": ASSET_VERSION,
        "status": "pending_review_only",
        "frontAppearanceAuthority": "assets_unused/pending_review/personal_hanok_v3/sarangchae_try07_edit.png",
        "turnaroundPolicy": (
            {
                "sourceUsage": "the unchanged original PNG is camera-projected onto anchor-visible 3D surfaces",
                "anchorView": SOURCE_ANCHOR_VIEW,
                "allEightViews": "rendered from one rotating Blender model; no source frame is pasted into the set",
                "rotatedViewMaterials": "paired 3D base materials prevent camera-projection stretching in views 01-07",
                "projection": projection_validation,
            }
            if FINAL_MODE
            else "all eight frames are Blender renders"
        ),
        "editableSource": str(BLEND_PATH),
        "portablePreviewModel": str(GLB_PATH),
        "turnaroundSheet": str(
            PROJECT_DIR / "final_sprite_v03" / "ildu_sarangchae_turnaround_sheet.png"
            if FINAL_MODE
            else RENDER_DIR / f"{OUTPUT_STEM}_turnaround_sheet.png"
        ),
        "portablePreviewExcludes": [
            "00_REFERENCE collection",
            "05_GRADE_PROXY collection",
            "cameras",
            "lights",
        ],
        "renders": render_outputs,
        "validation": validation,
        "coordinateSystem": {
            "x": "long main body, left to right in the front elevation",
            "y": "positive is rear; the nummaru wing projects into negative Y",
            "z": "up",
        },
        "measuredMeters": {
            "frontTotal": FRONT_TOTAL,
            "frontBays": FRONT_BAYS,
            "mainDepth": MAIN_DEPTH,
            "rightSideTotal": SIDE_TOTAL_RIGHT,
            "wingDepth": WING_DEPTH,
            "wingWidth": WING_WIDTH,
            "eaveProjection": EAVE_PROJECTION,
            "ridgeLevelFromFrontGL": RIDGE_Z,
            "mainFloor": MAIN_FLOOR_Z,
            "numaruFloorRelativeRise": 0.200,
        },
        "invariants": [
            "asymmetric L plan remains identical in every view",
            "six front bay widths use the measured 2595/2675/2645/2660/1985/1985 mm sequence",
            "right projecting nummaru remains two 1985 mm bays",
            "front high podium and rear low podium are distinct",
            "nummaru upper round posts and lower octagonal posts are separate",
            "one fixed orthographic camera; the building root rotates",
        ],
        "knownSimplifications": (
            [
                "final_v03 uses the unchanged source PNG as the anchor-camera projection authority on measured 3D geometry",
                "views 01-07 use the same geometry with paired Blender materials to avoid projection stretching",
                "the connected valley remains a detailed visual cover rather than conservation-grade watertight BIM topology",
                "the Blender source is authoritative; normalized PNGs remain pending visual approval",
            ]
            if FINAL_MODE
            else
            [
                "roof tile ribs are a readable blockout proxy, not all 173 measured rafters",
                "roof valley/intersection is volumetric overlap and needs the detail-pass boolean/topology cleanup",
                "site grade is a separate toggleable proxy; final app terrain must reproduce the same rise",
                "openings preserve front/rear/side distinction but are not yet every measured door leaf",
                "materials are flat review materials; final hand-painted V3 textures are intentionally absent",
            ]
            if not DETAIL_MODE
            else [
                "the connected valley is a clean visual cover over intersecting roof volumes, not final watertight production topology",
                "tile rows and exposed rafters preserve measured rhythm but do not instantiate all 173 report members",
                "procedural V3 tonal variation is Blender-render authoritative; GLB carries portable base materials until textures are baked",
                "site grade is a separate toggleable proxy and is excluded from the portable GLB",
                "rear and side openings are differentiated but some interior-only leaf mechanics remain intentionally omitted",
            ]
        ),
        "sourceFiles": source_files,
    }
    MANIFEST_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    global ROOT
    args = parse_args()
    configure_variant(args.detail_v02, args.final_v03)
    ensure_directories()
    clean_scene()
    for name in (
        "00_REFERENCE",
        "05_GRADE_PROXY",
        "10_FOUNDATION",
        "20_FRAME",
        "30_WALLS",
        "40_WINDOWS",
        "50_ROOF",
        "55_ROOF_DETAIL",
        "60_DETAILS",
        "65_SURFACE_DETAIL",
        "90_CAMERA_LIGHT",
    ):
        create_collection(name)

    ROOT = bpy.data.objects.new("ILDU_SARANGCHAE_ROOT", None)
    bpy.context.scene.collection.objects.link(ROOT)
    ROOT.empty_display_type = "PLAIN_AXES"
    ROOT.empty_display_size = 1.0

    if DETAIL_MODE:
        stylized_material("granite", "#6F675D", "#B8AD98", 0.96, 3.6, 0.20)
        material("stone_joint", "#4D4943", 0.98)
        stylized_material("grade_earth", "#80735D", "#B8A47D", 0.99, 2.8, 0.08)
        stylized_material("timber", "#3B271B", "#8F5130", 0.92, 4.2, 0.12)
        stylized_material("timber_dark", "#211914", "#5A3623", 0.95, 4.8, 0.10)
        stylized_material("plank", "#4A2E1E", "#844A2D", 0.94, 5.4, 0.14)
        stylized_material("wall", "#BDA982", "#E2D1AD", 0.97, 2.2, 0.07)
        stylized_material("hanji", "#C6AE8B", "#E9D7B7", 0.98, 5.8, 0.035)
        stylized_material("giwa", "#202529", "#41494F", 0.97, 12.0, 0.08)
        stylized_material("giwa_highlight", "#353C41", "#596167", 0.96, 14.0, 0.05)
        stylized_material("giwa_ridge", "#191D20", "#353C42", 0.98, 10.0, 0.07)
        stylized_material("giwa_end", "#776C5D", "#B8A58A", 0.96, 4.0, 0.06)
        stylized_material("gable_wood", "#4B2F1D", "#9B6035", 0.94, 5.2, 0.10)
    else:
        material("granite", "#9C988F", 0.96)
        material("stone_joint", "#625E57", 0.98)
        material("grade_earth", "#B7A889", 0.99)
        material("timber", "#6A5140", 0.92)
        material("timber_dark", "#3E2B21", 0.94)
        material("plank", "#7A5C46", 0.94)
        material("wall", "#D8D0C1", 0.96)
        material("hanji", "#EEE4CF", 0.97)
        material("giwa", "#424A50", 0.96)
        material("giwa_highlight", "#596269", 0.95)
        material("giwa_ridge", "#30373C", 0.97)
    guide = material("guide", "#B14B42", 0.90)
    guide.diffuse_color = (*hex_rgba("#B14B42")[:3], 0.55)

    build_foundations()
    build_frame()
    build_walls_and_openings()
    build_railings()
    build_roofs()
    if DETAIL_MODE:
        build_surface_details()
    build_hwalju()
    build_dimension_guides()
    build_metadata()
    camera = setup_scene(args.resolution_x, args.resolution_y)
    projection_validation = apply_source_projection(camera) if FINAL_MODE else None
    validation = validate_model()

    render_outputs: list[str] = []
    if not args.skip_renders:
        render_outputs = render_turnaround(args.anchor_only)
    else:
        render_outputs = [
            str(path)
            for path in sorted(RENDER_DIR.glob(f"{OUTPUT_STEM}_0?_*.png"))
        ]
    export_files()
    write_manifest(render_outputs, validation, projection_validation)
    print(f"SAVED_BLEND {BLEND_PATH}")
    print(f"EXPORTED_GLB {GLB_PATH}")
    print(f"WROTE_MANIFEST {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
