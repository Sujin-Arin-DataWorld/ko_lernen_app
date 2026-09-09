from __future__ import annotations

from argparse import ArgumentParser
from pathlib import Path
import hashlib
import json


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "CHECKPOINT_MANIFEST.json"
SOURCE_OUT = ROOT / "SOURCE_WORKING_SET_MANIFEST.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative_files(root: Path) -> list[Path]:
    return sorted(
        (path for path in root.rglob("*") if path.is_file()),
        key=lambda path: path.relative_to(root).as_posix().lower(),
    )


parser = ArgumentParser(description="Create the portable IlDu checkpoint manifests.")
parser.add_argument("--source", type=Path, required=True, help="Retained external working-set directory")
args = parser.parse_args()
source = args.source.resolve()
if not source.is_dir():
    raise FileNotFoundError(f"source working set is missing: {source}")

source_records = [
    {
        "path": path.relative_to(source).as_posix(),
        "bytes": path.stat().st_size,
        "sha256": sha256(path),
    }
    for path in relative_files(source)
]
source_manifest = {
    "schemaVersion": 1,
    "purpose": "Content-addressed inventory of the retained IlDu map working set.",
    "sourceRootName": source.name,
    "fileCount": len(source_records),
    "bytes": sum(record["bytes"] for record in source_records),
    "files": source_records,
}
SOURCE_OUT.write_text(
    json.dumps(source_manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
    newline="\n",
)

source_by_name = {record["path"]: record for record in source_records}
files = []
for path in sorted(
    (item for item in ROOT.iterdir() if item.is_file() and item.name != OUT.name),
    key=lambda item: item.name.lower(),
):
    entry = {
        "path": path.name,
        "bytes": path.stat().st_size,
        "checkpointSha256": sha256(path),
    }
    original = source_by_name.get(path.name)
    if original:
        entry["sourceSha256"] = original["sha256"]
        entry["byteIdenticalToSource"] = entry["checkpointSha256"] == entry["sourceSha256"]
    else:
        entry["createdForCheckpoint"] = True
    files.append(entry)

manifest = {
    "schemaVersion": 2,
    "purpose": "Review-only reproducible checkpoint for the user-selected V3 Sarangchae and fixed map camera.",
    "runtimeIntegrated": False,
    "sourceWorkingSet": {
        "inventory": SOURCE_OUT.name,
        "inventorySha256": sha256(SOURCE_OUT),
        "sourceRootName": source.name,
        "fileCountAtCheckpoint": source_manifest["fileCount"],
        "bytesAtCheckpoint": source_manifest["bytes"],
    },
    "selection": {
        "asset": "sarangchae-user-selected-source.png",
        "assetSha256": sha256(ROOT / "sarangchae-user-selected-source.png"),
        "transparentMaster": "sarangchae-candidate05-transparent.png",
        "transparentMasterSha256": sha256(ROOT / "sarangchae-candidate05-transparent.png"),
        "mapReview": "map-transfer-selected-small-map.png",
        "mapScaleVersusPreviousPercent": 78.33,
        "mapScaleApprovalConfirmed": False,
        "nextGenerationAllowed": False,
    },
    "files": files,
}
OUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({
    "manifestFiles": len(files),
    "checkpointBytes": sum(entry["bytes"] for entry in files),
    "externalFiles": source_manifest["fileCount"],
    "externalBytes": source_manifest["bytes"],
}, ensure_ascii=False))
