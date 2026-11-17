"""Package generated tactile topic icons; never edit the original PNGs."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for topic in ("tales", "home", "learning"):
        parser.add_argument(f"--{topic}", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    originals = root / "assets_unused/source_originals/dokkaebi-topic-icons-20261003"
    runtime = root / "assets/illustrations/tactile/dokkaebi_topics"
    originals.mkdir(parents=True, exist_ok=True)
    runtime.mkdir(parents=True, exist_ok=True)
    assets = []
    for topic in ("tales", "home", "learning"):
        source = getattr(args, topic).resolve(strict=True)
        preserved = originals / f"{topic}.png"
        shutil.copyfile(source, preserved)
        assert digest(source) == digest(preserved)
        image = Image.open(source)
        assert image.mode == "RGBA", f"{topic}: generated alpha required"
        assert image.getchannel("A").getextrema()[0] == 0
        bounds = image.getchannel("A").point(lambda v: 255 if v >= 8 else 0).getbbox()
        assert bounds and min(bounds[0], bounds[1], image.width - bounds[2], image.height - bounds[3]) >= 32
        derivative = runtime / f"{topic}.webp"
        image.resize((256, 256), Image.Resampling.LANCZOS).save(
            derivative, "WEBP", lossless=True, method=6, exact=True
        )
        assets.append({
            "id": topic,
            "source": str(source),
            "original": preserved.relative_to(root).as_posix(),
            "source_sha256": digest(source),
            "source_bytes": source.stat().st_size,
            "source_size": list(image.size),
            "alpha_bounds_at_8": list(bounds),
            "runtime": derivative.relative_to(root).as_posix(),
            "runtime_sha256": digest(derivative),
            "runtime_bytes": derivative.stat().st_size,
            "derivation": "whole-canvas 256x256 LANCZOS resize; lossless WebP with alpha; no crop/repaint",
        })
    manifest = {
        "schema": 1,
        "generation": "built-in imagegen; one output per topic",
        "style_reference": str(args.reference.resolve(strict=True)),
        "style_reference_sha256": digest(args.reference),
        "assets": assets,
    }
    (originals / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(assets, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
