"""Extract exact approved art; never repaint or regenerate source pixels."""

from hashlib import sha256
import json
from pathlib import Path
import shutil

from PIL import Image

SOURCE = Path(r"C:\Users\vjinn\.codex\generated_images\Spiele최종")
DEST = Path(__file__).resolve().parents[1] / "assets/illustrations/concept_c/spiele_preview"
MANIFEST = Path(__file__).resolve().parents[1] / "docs/assets/APPROVED_SPIELE_PREVIEW_20261029.json"

# Rectangles use original pixel coordinates. No phone or OS chrome is included.
PARTS = {
    "jade.png": ("exec-0564b871-d2f6-410a-ab29-775cdea4de27.png", None),
    "paper.png": ("exec-5f8a2686-de4b-48bf-bdeb-a15d5f5f0eed.png", None),
    "paper_card.png": ("exec-d518d6fd-36c8-4401-a815-9933dc108d4d.png", (0, 17, 1750, 792)),
    "wood_tray.png": ("exec-7c40205a-853b-4d3b-a129-3b13093d7287.png", (0, 0, 1506, 992)),
    "silben_board.png": ("exec-ed1541c3-53c8-4623-9ca7-fa9967fcdacb.png", (26, 610, 825, 1260)),
    "silben_tile.png": ("exec-ed1541c3-53c8-4623-9ca7-fa9967fcdacb.png", (58, 1280, 233, 1412)),
    "silben_clue.png": ("exec-ed1541c3-53c8-4623-9ca7-fa9967fcdacb.png", (30, 264, 824, 375)),
    "jade_action.png": ("exec-d7a8c9e2-53f2-4cac-9984-afd5f00888e2.png", (30, 40, 1230, 229)),
    "paper_action.png": ("exec-d7a8c9e2-53f2-4cac-9984-afd5f00888e2.png", (30, 415, 1230, 618)),
    "daily_board.png": ("exec-4be90d08-29f5-4cc3-b8e0-589a69113b6f.png", (0, 270, 850, 1850)),
    "daily_header.png": ("exec-4be90d08-29f5-4cc3-b8e0-589a69113b6f.png", (0, 270, 850, 615)),
    "chain_board.png": ("exec-a58edbd0-463a-4d0b-aa57-97778a772b18.png", (0, 300, 850, 1148)),
    "chain_submit.png": ("exec-a58edbd0-463a-4d0b-aa57-97778a772b18.png", (38, 1565, 809, 1692)),
}


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    records = []
    for name, (relative, box) in PARTS.items():
        source = SOURCE / relative
        target = DEST / name
        if box is None:
            shutil.copyfile(source, target)
        else:
            with Image.open(source) as original:
                original.crop(box).save(target)
        records.append({
            "asset": target.relative_to(DEST.parents[3]).as_posix(),
            "source": str(source),
            "sourceSha256": digest(source),
            "crop": box,
            "sha256": digest(target),
        })
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps({
        "policy": "Exact source copy or rectangular extraction only; no redraw, generated art, phone frame or fake OS UI.",
        "approvalBoundary": "Approved source art is distinct from native layout/device acceptance. Full Anlaut, Blitz-Paare and Karten screens are absent from this source folder.",
        "assets": records,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Extracted {len(records)} approved source parts to {DEST}")


if __name__ == "__main__":
    main()
