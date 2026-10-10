"""Copy approved/referenced C materials unchanged; no image manipulation."""
import hashlib
import json
import shutil
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
REPO = PACKAGE.parent.parent
SOURCE = Path("C:/Users/vjinn/.codex/generated_images")
SOURCES = {
    "coin_face.png": SOURCE / "01a10981-52b8-7171-9152-7c911290e994/exec-efcabadf-1c35-408f-a052-4209b9969487.png",
    "brand_seal.png": SOURCE / "01a10981-52b8-7171-9152-7c911290e994/exec-1492b2fe-69c7-4bb6-9d4b-7e0b54c514d0.png",
    "cta_atlas.png": SOURCE / "01a120e1-8621-77f1-b07c-f6499ac0829e/exec-13f11698-1207-48f1-a3fe-04e6253e57cb.png",
    "paper_texture.png": SOURCE / "01a10981-52b8-7171-9152-7c911290e994/exec-9d0fbdc4-51c6-4f15-b161-89480d675cb9.png",
    "jade_texture.png": SOURCE / "01a10981-52b8-7171-9152-7c911290e994/exec-b1b41d0d-f8ff-48bd-848e-ab2e332badd0.png",
    "arrow.png": SOURCE / "01a107ac-29c9-7cd2-aa98-be5bfe0c4b7d/exec-593cd363-4af8-46e9-b79b-c71cb0d6d95a.png",
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    provenance_path = PACKAGE / "asset-provenance.json"
    provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
    existing = {row["file"]: row for row in provenance}
    runtime = REPO / "assets/animations/rewards"
    runtime.mkdir(parents=True, exist_ok=True)
    for name, source in SOURCES.items():
        digest = sha(source)
        package_copy = PACKAGE / "assets" / name
        if f"assets/{name}" in existing:
            assert sha(package_copy) == digest, f"Preserve existing authority: {name}"
        else:
            shutil.copyfile(source, package_copy)
            provenance.append({"file": f"assets/{name}", "source": str(source), "sha256": digest, "unchanged": True})
        shutil.copyfile(package_copy, runtime / name)
        assert sha(runtime / name) == sha(package_copy) == digest
    provenance_path.write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report_path = PACKAGE / "media-review/flutter-media-report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    report["files"] = [{"file": path.relative_to(REPO).as_posix(), "bytes": path.stat().st_size, "sha256": sha(path)} for path in sorted(runtime.iterdir()) if path.is_file()]
    report["materialCopiesUnchanged"] = True
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"unchangedCopies": len(SOURCES), "runtimeFiles": len(report["files"])}))


if __name__ == "__main__":
    main()
