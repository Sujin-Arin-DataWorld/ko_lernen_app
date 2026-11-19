"""Extract only the user-approved book illustrations, without mockup chrome."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
import shutil

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SPECS = (
    {
        "id": "book_capture",
        "source": "codex-clipboard-20b7acfa-be5d-4a8f-84ac-1ab6b5ebb08b.png",
        "sourceSha256": "aaef1e2ab9a15dabd23013bdd4bead1bdd6bf573a18465bd948f8089ad2d93dd",
        "sourceSize": (492, 927),
        "crop": (18, 312, 474, 670),
        "output": "book_capture_approved_20261030.png",
    },
    {
        "id": "book_study",
        "source": "codex-clipboard-356b5762-c927-4b5e-9ff1-1a88152a4a7b.png",
        "sourceSha256": "d3607520de81e1439c24714bfc5eff4d8ecf2ad488431ea148dcbc51f02b3d32",
        "sourceSize": (495, 922),
        "crop": (31, 142, 474, 446),
        "excludedControlLTRB": (400, 430, 474, 446),
        "output": "book_study_approved_20261030.png",
    },
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=Path.home() / "AppData/Local/Temp")
    parser.add_argument("--retain-source-dir", type=Path)
    args = parser.parse_args()
    asset_dir = ROOT / "assets/illustrations/onboarding"
    assert asset_dir.resolve().is_relative_to(ROOT), "Refuse to write through an external asset link"
    entries = []
    for spec in SPECS:
        source = args.source_dir / spec["source"]
        original = source.read_bytes()
        assert sha256(original) == spec["sourceSha256"], f"Source changed: {source}"
        with Image.open(io.BytesIO(original)) as image:
            assert image.size == spec["sourceSize"], f"Unexpected source dimensions: {source}"
            artwork = image.crop(spec["crop"])
            if "excludedControlLTRB" in spec:
                # Preserve the final Hangul baseline, while cutting out only
                # the painted crop control in the otherwise empty corner.
                artwork = artwork.convert("RGBA")
                left, top, right, bottom = spec["excludedControlLTRB"]
                origin_x, origin_y = spec["crop"][:2]
                artwork.paste((0, 0, 0, 0), (left - origin_x, top - origin_y, right - origin_x, bottom - origin_y))
            encoded = io.BytesIO()
            artwork.save(encoded, format="PNG", optimize=True)
            output_bytes = encoded.getvalue()
            pixel_sha = sha256(artwork.tobytes())
            size = artwork.size
        output = asset_dir / spec["output"]
        if output.exists():
            assert output.read_bytes() == output_bytes, f"Refuse to replace a changed output: {output}"
        else:
            output.write_bytes(output_bytes)
        if args.retain_source_dir is not None:
            args.retain_source_dir.mkdir(parents=True, exist_ok=True)
            retained = args.retain_source_dir / source.name
            if retained.exists():
                assert retained.read_bytes() == original, f"Retained source changed: {retained}"
            else:
                shutil.copyfile(source, retained)
        entries.append(
            {
                "id": spec["id"],
                "sourceFile": spec["source"],
                "sourceSha256": spec["sourceSha256"],
                "sourceSize": list(spec["sourceSize"]),
                "cropLTRB": list(spec["crop"]),
                "excludedControlLTRB": list(spec["excludedControlLTRB"]) if "excludedControlLTRB" in spec else None,
                "assetPath": output.relative_to(ROOT).as_posix(),
                "size": list(size),
                "sha256": sha256(output_bytes),
                "pixelSha256": pixel_sha,
            }
        )
    manifest = {
        "schemaVersion": 1,
        "authority": "User attachments, approved for content artwork extraction on 2026-10-30",
        "operation": "Lossless PNG crop; transparent cutout of the painted corner control; no regeneration or resampling",
        "excluded": ["outer device frame", "outer status bar", "outer navigation chrome", "outer painted app buttons"],
        "contentContract": "Illustration only; existing level example, speech and local-only preview state remain authoritative",
        "items": entries,
    }
    manifest_path = ROOT / "docs/assets/APPROVED_BOOK_PREVIEW_20261030.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"manifest": str(manifest_path), "items": entries}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
