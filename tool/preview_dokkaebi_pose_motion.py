"""Blender-only, non-generative 2.5D feasibility preview; never a rigged avatar.

Run with Blender --background --factory-startup --python this_file -- --output DIR.
The PNGs remain intact textures. Supplied poses switch at authored frames; the
club does not move independently of its pose. Review before runtime promotion.
"""

import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def material(name, color=None, texture=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    emission = nodes.new("ShaderNodeEmission")
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    mix = nodes.new("ShaderNodeMixShader")
    alpha = nodes.new("ShaderNodeValue")
    alpha.outputs[0].default_value = 1
    if texture:
        image = bpy.data.images.load(str(texture), check_existing=True)
        image.pack()
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Linear"
        mat.node_tree.links.new(tex.outputs["Color"], emission.inputs["Color"])
        mat.node_tree.links.new(tex.outputs["Alpha"], mix.inputs[0])
    else:
        # Blender node RGB inputs are linear, while the supplied palette is sRGB.
        emission.inputs["Color"].default_value = tuple(
            v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4
            for v in color[:3]
        ) + (1,)
        mat.node_tree.links.new(alpha.outputs[0], mix.inputs[0])
    mat.node_tree.links.new(transparent.outputs[0], mix.inputs[1])
    mat.node_tree.links.new(emission.outputs[0], mix.inputs[2])
    mat.node_tree.links.new(mix.outputs[0], output.inputs["Surface"])
    mat.surface_render_method = "DITHERED"
    return mat, alpha


def plane(name, width, height, x, y, z, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([
        (-width / 2, -height / 2, 0), (width / 2, -height / 2, 0),
        (width / 2, height / 2, 0), (-width / 2, height / 2, 0),
    ], [], [(0, 1, 2, 3)])
    uv = mesh.uv_layers.new()
    for loop, coord in zip(uv.data, [(0, 0), (1, 0), (1, 1), (0, 1)]):
        loop.uv = coord
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, y, z)
    obj.data.materials.append(mat)
    return obj


def ring(name, x, y, mat):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = .023
    curve.bevel_resolution = 2
    spline = curve.splines.new("POLY")
    spline.points.add(63)
    for i, point in enumerate(spline.points):
        angle = 2 * math.pi * i / 64
        point.co = (math.cos(angle), math.sin(angle) * .36, 0, 1)
    spline.use_cyclic_u = True
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, y, .18)
    obj.data.materials.append(mat)
    return obj


def key(obj, frame, fields):
    for field in fields:
        obj.keyframe_insert(data_path=field, frame=frame)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--frames", default="all")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    frame_dir = output / "frames"
    frame_dir.mkdir(exist_ok=True)
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((root / "assets_unused/approved_texture_originals/dokkaebi-poses-20261003/manifest.json").read_text("utf-8"))
    source_entries = {Path(e["runtime"]).stem: e for e in manifest["entries"]}
    source_facts = []
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 2
    scene.render.resolution_x = scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.fps = 30
    scene.frame_start, scene.frame_end = 1, 60
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.world.color = (0, 0, 0)
    camera_data = bpy.data.cameras.new("LockedOrthographic")
    camera = bpy.data.objects.new("LockedOrthographic", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (0, 0, 10)
    camera_data.type, camera_data.ortho_scale = "ORTHO", 7.4
    scene.camera = camera
    width, height = 2.9, 2.9 * 1448 / 1086
    center_x, center_y = .2, .1
    # Explicit UV contact on the ready-pose club tip, not a claim of mesh contact.
    contact_uv = (.551, .98)
    contact_x = center_x + (contact_uv[0] - .5) * width
    contact_y = center_y + (.5 - contact_uv[1]) * height
    poses = {}
    for name in ("ready", "celebrate", "helping"):
        entry = source_entries[f"dokkaebi_{name}"]
        path = root / entry["runtime"]
        assert sha(path) == entry["sha256"], name
        mat, _ = material(f"Original_{name}", texture=path)
        poses[name] = plane(f"OriginalPNG_{name}", width, height, center_x, center_y, .05, mat)
        source_facts.append({"pose": name, "path": entry["runtime"], "sha256": sha(path), "bytes": path.stat().st_size})
    fire_path = root / "assets/illustrations/decorations/decoration_dokkaebi_fire.png"
    assert sha(fire_path) == "9848a7c6fa2cb93b305ea3180043c1fc96321179c54e3d1731706891646001e5"
    fire_mat, _ = material("OriginalFire", texture=fire_path)
    fires = [plane("Fire_Left", .65, .65, -1.65, 1.6, .1, fire_mat),
             plane("Fire_Right", .48, .48, 1.9, 1.1, .12, fire_mat)]
    cream, _ = material("BlankHintCard", color=(.985, .969, .935, 1))
    edge, _ = material("CardDepth", color=(.79, .76, .67, 1))
    blue, blue_alpha = material("ContactWave", color=(.22, .76, .89, 1))
    gold, _ = material("BlankTiles", color=(.89, .84, .71, 1))
    card_height, card_y = 1.1, contact_y - .55
    plane("Card_Lower_Edge", 4.65, card_height, .15, card_y - .08, -.06, edge)
    plane("Card_Face", 4.65, card_height, .15, card_y, -.03, cream)
    for i in range(3):
        plane(f"Blank_Tile_{i}", .43, .42, -.55 + i * .62, card_y, .01, gold)
    wave = ring("One_Contact_Wave", contact_x, contact_y, blue)
    samples = []
    for frame in range(1, 61):
        scene.frame_set(frame)
        if frame <= 7:
            active, lift, tilt = "ready", -.055 * math.sin(math.pi * (frame - 1) / 6), -.035 * (frame - 1) / 6
        elif frame <= 17:
            p = (frame - 8) / 9
            active, lift, tilt = "celebrate", .45 + .35 * math.sin(math.pi * p), -.08 + .16 * p
        elif frame <= 24:
            p = (frame - 18) / 6
            active, lift, tilt = "helping", .45 * (1 - p), .07 * (1 - p)
        else:
            active = "ready"
            lift = .045 * math.exp(-(frame - 25) / 6) * abs(math.sin((frame - 25) * math.pi / 7))
            tilt = 0
        for name, obj in poses.items():
            obj.hide_render = obj.hide_viewport = name != active
            obj.location = (center_x, center_y + lift, .05)
            obj.rotation_euler = (0, 0, tilt)
            key(obj, frame, ["hide_render", "hide_viewport", "location", "rotation_euler"])
        for i, fire in enumerate(fires):
            t = (frame - 1) / 30
            fire.location.x = (-1.65 if i == 0 else 1.9) + .10 * math.sin(2.2 * t + i)
            fire.location.y = (1.6 if i == 0 else 1.1) + .14 * math.sin(3.0 * t + i)
            fire.rotation_euler.z = .12 * math.sin(2.8 * t + i)
            key(fire, frame, ["location", "rotation_euler"])
        p = max(0, min(1, (frame - 25) / 12))
        wave.hide_render = wave.hide_viewport = frame < 25 or frame > 38
        wave.scale = (.08 + 1.3 * p,) * 3
        key(wave, frame, ["hide_render", "hide_viewport", "scale"])
        blue_alpha.outputs[0].default_value = 1 - p
        blue_alpha.outputs[0].keyframe_insert(data_path="default_value", frame=frame)
        scene.view_layers[0].update()
        frame_bounds = []
        for obj in [poses[active], *fires]:
            corners = [world_to_camera_view(scene, camera, obj.matrix_world @ Vector(corner)) for corner in obj.bound_box]
            bounds = [min(v.x for v in corners), min(v.y for v in corners), max(v.x for v in corners), max(v.y for v in corners)]
            margin = min(bounds[0], bounds[1], 1 - bounds[2], 1 - bounds[3])
            assert margin >= .08, (frame, obj.name, bounds)
            assert all(abs(v - 1) < 1e-7 for v in obj.scale)
            frame_bounds.append({"object": obj.name, "bounds_normalized": bounds, "margin": margin})
        samples.append({"frame": frame, "seconds": (frame - 1) / 30, "pose": active, "bounds": frame_bounds})
    scene.timeline_markers.new("POSE SWITCH: AIRBORNE", frame=8)
    scene.timeline_markers.new("POSE SWITCH: DESCENT", frame=18)
    scene.timeline_markers.new("ONE IMPACT / APP HINT CUE", frame=25)
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "dokkaebi_pose_impact_review.blend"))
    report = {
        "format": "2.5D PNG pose animation; no skeletal or facial animation",
        "armatures": 0, "mesh_deformation": False, "club_independent_rotation": False,
        "original_pngs_preserved": source_facts,
        "fire_sha256": sha(fire_path), "camera": "locked orthographic; square 720px; 7.4 units",
        "duration_seconds": 2, "frames": 60, "fps": 30,
        "contact_frame": 25, "contact_seconds": .8, "authored_tip_uv": contact_uv,
        "card_edge_contact": [contact_x, contact_y],
        "minimum_full_image_plane_margin": min(b["margin"] for f in samples for b in f["bounds"]),
        "pose_switch_frames": [8, 18, 25],
        "limitations": ["discrete supplied pose switches", "not one continuous club revolution", "no independent limb motion", "no automatic PNG-to-3D identity reconstruction"],
        "samples": samples,
    }
    (output / "motion-state.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    selected = range(1, 61) if args.frames == "all" else [int(f) for f in args.frames.split(",")]
    for frame in selected:
        scene.frame_set(frame)
        scene.render.filepath = str(frame_dir / f"{frame:04}.png")
        bpy.ops.render.render(write_still=True)
    for item in source_facts:
        assert sha(root / item["path"]) == item["sha256"]
    print("REVIEW ONLY: original PNGs preserved; all 60 frames pass full-plane bounds; impact once at frame 25")


if __name__ == "__main__":
    main()
