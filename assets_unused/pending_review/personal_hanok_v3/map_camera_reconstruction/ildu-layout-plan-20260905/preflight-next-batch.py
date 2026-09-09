from __future__ import annotations

from pathlib import Path
import hashlib
import json
import math

from PIL import Image


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
TURN = REPO / "assets_unused/pending_review/personal_hanok_v3/turnaround_2d"
PLAN = json.loads((ROOT / "layout-plan.json").read_text(encoding="utf-8"))
CAMERA = json.loads((ROOT / "camera-selection.json").read_text(encoding="utf-8"))
OUT = ROOT / "next-batch-source-preflight-v1.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def image_record(path: Path) -> dict:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        alpha = rgba.getchannel("A")
        return {
            "path": path.relative_to(REPO).as_posix(),
            "size": list(image.size),
            "mode": image.mode,
            "alphaBounds": list(alpha.getbbox() or ()),
            "cornerAlpha": [alpha.getpixel(p) for p in ((0, 0), (image.width - 1, 0), (0, image.height - 1), (image.width - 1, image.height - 1))],
            "sha256": sha256(path),
        }


def edge_heading(p: list[float], q: list[float]) -> float:
    return math.degrees(math.atan2(q[1] - p[1], q[0] - p[0]))


def long_axis_heading(points: list[list[float]]) -> float:
    top = ((points[0][0] + points[1][0]) / 2, (points[0][1] + points[1][1]) / 2)
    bottom = ((points[-1][0] + points[-2][0]) / 2, (points[-1][1] + points[-2][1]) / 2)
    return edge_heading(top, bottom)


buildings = {item["id"]: item for item in PLAN["buildings"]}
gates = {item["id"]: item for item in PLAN["gates"]}

sources = {
    "jungmunchae": {
        "status": "user-approved V05 byte-locked source archive",
        "canonical": TURN / "ildu_jungmunganchae_v05_final_byte_locked/00_front_source_exact.png",
        "front": TURN / "ildu_jungmunganchae_v05_final_byte_locked/transparent_28deg/00_front_000.png",
        "frontRight": TURN / "ildu_jungmunganchae_v05_final_byte_locked/transparent_28deg/01_front_right_045.png",
        "reviewSheet": TURN / "ildu_jungmunganchae_v05_final_byte_locked/ildu_jungmunganchae_v05_8view_review_sheet.png",
    },
    "changgo": {
        "status": "runtime-promoted 2026-08-29 review archive",
        "canonical": REPO / "assets_unused/pending_review/personal_hanok_v3/changgo_final.png",
        "front": TURN / "ildu_changgo_blueprint200_28deg_v01/transparent_28deg/00_front_000.png",
        "frontRight": TURN / "ildu_changgo_blueprint200_28deg_v01/transparent_28deg/01_front_right_045.png",
        "reviewSheet": TURN / "ildu_changgo_blueprint200_28deg_v01/ildu_changgo_8view_review_sheet.png",
    },
    "hyeopmun": {
        "status": "runtime-source-promoted 2026-08-29 review archive",
        "canonical": TURN / "ildu_sadang_hyeopmun_v01/references/source_hyeopmun_try03_cut.png",
        "front": TURN / "ildu_sadang_hyeopmun_v01/transparent_views/ildu_sadang_hyeopmun_000_front.png",
        "frontRight": TURN / "ildu_sadang_hyeopmun_v01/transparent_views/ildu_sadang_hyeopmun_045_front_right.png",
        "reviewSheet": TURN / "ildu_sadang_hyeopmun_v01/ildu_sadang_hyeopmun_turnaround_sheet.png",
    },
}

records = {}
for key, value in sources.items():
    files = {}
    for role in ("canonical", "front", "frontRight", "reviewSheet"):
        path = value[role]
        if not path.exists():
            raise FileNotFoundError(path)
        files[role] = image_record(path)
    records[key] = {"status": value["status"], "files": files}

orientation = {}
for key in ("jungmunchae", "changgo"):
    heading = long_axis_heading(buildings[key]["polygon"])
    # Both long service buildings open toward the central courtyard on the
    # reference map, so their facade normal points to image-right.
    front = heading - 90
    orientation[key] = {
        "longAxisHeadingDegrees": heading,
        "frontNormalHeadingDegrees": front,
        "frontDirectionEvidence": "central courtyard side in the approved layout",
        "relativeFrontToNumericCameraDegrees": front - CAMERA["azimuth"],
        "recommendedDirectionInputs": ["front", "frontRight"],
    }
for gate_id in ("G02", "G04"):
    heading = edge_heading(*gates[gate_id]["span"])
    orientation[gate_id] = {
        "doorPlaneHeadingDegrees": heading,
        "frontDirection": "Resolve visually from the target context; do not infer a 180-degree choice from the polygon alone.",
        "recommendedDirectionInputs": ["front", "frontRight"],
        "role": "Sarangchae left hyeopmun" if gate_id == "G02" else "Sarangchae right hyeopmun",
    }

report = {
    "status": "prepared_waiting_for_sarangchae_map_scale_approval",
    "generationPerformed": False,
    "order": ["jungmunchae", "changgo", "G02", "G04"],
    "sources": records,
    "orientation": orientation,
    "cameraUse": "Numeric 34/-15/1.25 camera is an orientation aid. The later user-selected natural map remains the placement authority.",
    "rules": [
        "Use each building's own canonical and adjacent direction views; never use another building as a visual source.",
        "Do not paste or distort the 28-degree frame; redraw the visible faces for the target map view.",
        "The user selected Sarangchae candidate 05. Do not generate the next item until the 78.33% map-scale registration is explicitly approved.",
        "Preserve every already-approved map layer outside the next item's authorized mask.",
    ],
    "layoutPlanSha256": sha256(ROOT / "layout-plan.json"),
    "cameraSelectionSha256": sha256(ROOT / "camera-selection.json"),
}
OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"status": report["status"], "items": list(records), "orientation": orientation}, ensure_ascii=False))
