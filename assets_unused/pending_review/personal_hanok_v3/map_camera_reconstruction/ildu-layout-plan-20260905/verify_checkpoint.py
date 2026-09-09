from __future__ import annotations

from argparse import ArgumentParser
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
import hashlib
import json

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
MANIFEST = ROOT / "CHECKPOINT_MANIFEST.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def portable_path(value: str, label: str) -> Path:
    pure = PurePosixPath(value)
    require(not pure.is_absolute(), f"absolute {label}: {value}")
    require(".." not in pure.parts, f"escaping {label}: {value}")
    require("\\" not in value, f"non-portable {label}: {value}")
    return Path(*pure.parts)


class LocalReferenceParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.references: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        for name, value in attrs:
            if name not in {"src", "href"} or not value:
                continue
            if value.startswith(("#", "data:", "http://", "https://")):
                continue
            self.references.add(value.split("?", 1)[0].split("#", 1)[0])


parser = ArgumentParser(description="Verify the portable IlDu map checkpoint.")
parser.add_argument("--source", type=Path, help="Optional retained external working set to verify byte-for-byte")
args = parser.parse_args()

manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
require(manifest["schemaVersion"] == 2, "unexpected checkpoint manifest schema")
source_meta = manifest["sourceWorkingSet"]
source_inventory_path = ROOT / portable_path(source_meta["inventory"], "source inventory path")
require(source_inventory_path.is_file(), "source working-set inventory is missing")
require(sha256(source_inventory_path) == source_meta["inventorySha256"], "source inventory hash mismatch")
source_inventory = json.loads(source_inventory_path.read_text(encoding="utf-8"))
source_records = source_inventory["files"]
require(source_inventory["fileCount"] == len(source_records), "source inventory file count mismatch")
require(source_inventory["bytes"] == sum(record["bytes"] for record in source_records), "source inventory byte count mismatch")
require(source_meta["fileCountAtCheckpoint"] == source_inventory["fileCount"], "checkpoint source file count mismatch")
require(source_meta["bytesAtCheckpoint"] == source_inventory["bytes"], "checkpoint source byte count mismatch")

record_paths: set[str] = set()
for record in source_records:
    portable_path(record["path"], "source inventory record")
    require(record["path"] not in record_paths, f"duplicate source inventory record: {record['path']}")
    record_paths.add(record["path"])

source_verified = False
if args.source:
    source = args.source.resolve()
    require(source.is_dir(), f"source working set is missing: {source}")
    live_files = {
        path.relative_to(source).as_posix(): path
        for path in source.rglob("*")
        if path.is_file()
    }
    require(set(live_files) == record_paths, "source working-set file list differs from inventory")
    for record in source_records:
        path = live_files[record["path"]]
        require(path.stat().st_size == record["bytes"], f"source size mismatch: {record['path']}")
        require(sha256(path) == record["sha256"], f"source SHA-256 mismatch: {record['path']}")
    source_verified = True

entries = manifest["files"]
require(entries, "manifest contains no files")
for entry in entries:
    path = ROOT / portable_path(entry["path"], "checkpoint manifest path")
    require(path.is_file(), f"missing checkpoint file: {entry['path']}")
    require(path.stat().st_size == entry["bytes"], f"size mismatch: {entry['path']}")
    require(sha256(path) == entry["checkpointSha256"], f"SHA-256 mismatch: {entry['path']}")

selected = Image.open(ROOT / "sarangchae-user-selected-source.png").convert("RGB")
transparent = Image.open(ROOT / "sarangchae-candidate05-transparent.png").convert("RGBA")
require(selected.size == transparent.size, "selected and transparent master sizes differ")
require(ImageChops.difference(selected, transparent.convert("RGB")).getbbox() is None, "transparent conversion changed RGB pixels")
alpha_histogram = transparent.getchannel("A").histogram()
transparent_count = alpha_histogram[0]
opaque_count = alpha_histogram[255]
partial_count = sum(alpha_histogram[1:255])
require(transparent_count > 0 and opaque_count > 0, "transparent master lacks real foreground/background alpha")

alpha_report = json.loads((ROOT / "sarangchae-candidate05-alpha-verification.json").read_text(encoding="utf-8"))
require(alpha_report["rgbChangedPixels"] == 0, "alpha report records changed RGB pixels")
require(alpha_report["checks"]["realAlphaChannel"], "alpha report did not pass real-alpha check")
require(alpha_report["checks"]["rgbBytePreserved"], "alpha report did not preserve RGB")
require(alpha_report["outputSha256"] == sha256(ROOT / "sarangchae-candidate05-transparent.png"), "alpha report output hash is stale")

selection = json.loads((ROOT / "sarangchae-selection-registration-v1.json").read_text(encoding="utf-8"))
map_report = json.loads((ROOT / "sarangchae-selected-small-map-verification.json").read_text(encoding="utf-8"))
require(selection["status"] == "asset_selected_map_scale_review_pending", "unexpected Sarangchae selection status")
require(selection["nextGenerationAllowed"] is False, "next generation must remain blocked")
require(selection["mapRegistration"]["mapScaleApprovalConfirmed"] is False, "map scale must remain pending")
require(map_report["mapSize"] == [1202, 1308], "unexpected review map size")
require(map_report["spriteCanvasSizeOnMap"] == [282, 188], "unexpected Sarangchae map canvas")
require(map_report["spriteOriginOnMap"] == [358, 686], "unexpected Sarangchae map origin")
require(map_report["linearScaleVersusPreviousPercent"] == 78.33, "unexpected map scale")
require(map_report["changedRgbPixelsOutsideAuthorizedLayers"] == 0, "map changed outside authorized layers")
for side in ("left", "right"):
    require(map_report["gateVisibilityAfterBuilding"][side]["visiblePercent"] == 100.0, f"{side} gate is obscured")

html_path = ROOT / "map-transfer-review.html"
html_parser = LocalReferenceParser()
html_parser.feed(html_path.read_text(encoding="utf-8"))
for reference in sorted(html_parser.references):
    require((ROOT / portable_path(reference, "HTML local reference")).is_file(), f"HTML local reference is missing: {reference}")

camera = json.loads((ROOT / "camera-selection.json").read_text(encoding="utf-8"))
camera_reference = REPO / portable_path(camera["reference"]["path"], "camera reference")
require(camera_reference.is_file(), "camera reference is missing")

layout = json.loads((ROOT / "layout-plan.json").read_text(encoding="utf-8"))
layout_source = ROOT / portable_path(layout["source"]["path"], "layout source")
require(layout_source.is_file(), "layout source is missing")
require(sha256(layout_source) == layout["source"]["sha256"], "layout source hash mismatch")
names_path = ROOT / portable_path(layout["authority"]["names"], "layout names authority")
require(names_path.is_file(), "layout names authority is missing")
for gate in layout["gateAssets"].values():
    source_path = REPO / portable_path(gate["sourcePath"], "gate source path")
    preview_path = ROOT / portable_path(gate["previewFile"], "gate preview path")
    require(source_path.is_file(), f"gate source is missing: {gate['sourcePath']}")
    require(preview_path.is_file(), f"gate preview is missing: {gate['previewFile']}")
    require(sha256(source_path) == gate["sha256"], f"gate source hash mismatch: {gate['sourcePath']}")
    require(sha256(preview_path) == gate["sha256"], f"gate preview hash mismatch: {gate['previewFile']}")
    for turnaround in gate["turnaroundFiles"]:
        require((REPO / portable_path(turnaround, "gate turnaround path")).is_file(), f"gate turnaround is missing: {turnaround}")

identifications = json.loads(names_path.read_text(encoding="utf-8"))
identification_source = REPO / portable_path(identifications["layout_source"], "building identification layout source")
require(identification_source.is_file(), "building identification layout source is missing")
require(sha256(identification_source).upper() == identifications["layout_source_sha256"].upper(), "building identification layout hash mismatch")

spec = json.loads((ROOT / "next-batch-generation-spec-v1.json").read_text(encoding="utf-8"))
require(spec["sarangchaeGate"]["nextGenerationAllowed"] is False, "generation spec incorrectly opens the next gate")
require(spec["sarangchaeGate"]["mapScaleApprovalConfirmed"] is False, "generation spec incorrectly approves the map scale")
for job in spec["jobs"]:
    require(len(job["inputs"]) <= 5, f"{job['id']} exceeds the five-input limit")
    for source in job["inputs"]:
        require((REPO / portable_path(source, "next-batch input")).is_file(), f"missing next-batch input: {source}")

preflight = json.loads((ROOT / "next-batch-source-preflight-v1.json").read_text(encoding="utf-8"))
require(preflight["generationPerformed"] is False, "preflight incorrectly records generation")
for source in preflight["sources"].values():
    for record in source["files"].values():
        source_path = REPO / portable_path(record["path"], "preflight source")
        require(source_path.is_file(), f"preflight source missing: {record['path']}")
        require(sha256(source_path) == record["sha256"], f"preflight source hash mismatch: {record['path']}")

print(json.dumps({
    "status": "ok",
    "manifestFiles": len(entries),
    "sourceInventoryFiles": source_inventory["fileCount"],
    "sourceWorkingSetVerified": source_verified,
    "transparentPixels": transparent_count,
    "opaquePixels": opaque_count,
    "partialAlphaPixels": partial_count,
    "localHtmlReferences": len(html_parser.references),
    "nextGenerationAllowed": False,
}, ensure_ascii=False))
