#!/usr/bin/env python3
"""One-off: integrate the '누락이미지-압축' Jongga asset drop.

- Keys the opaque (near-white) background → transparent (border-connected
  flood fill, preserves interior whites), recompresses to P+transparency.
- Places each file in its correct app folder per docs/plans/stately-rising-jongga-assets.md.
- Mascot poses replace existing same-named files; new categories go to their
  spec folders (gye/book are new). Reports any unmapped source or missing target.
Run from repo root:  python3 tool/integrate_jongga_assets.py
"""
import os, glob
from PIL import Image, ImageDraw

SRC = "/Users/sujinpark/Downloads/누락이미지-압축"
REPO = "/Users/sujinpark/Developer/ko_lernen_app/assets"

# stem (before _optimized) -> list of (folder-under-assets, canonical-name)
MAP = {
    # ── mascot (replace same-named; perched_alt/surprised new to folder) ──
    "tiger_blink": [("illustrations/mascot", "tiger_blink")],
    "tiger_celebrate": [("illustrations/mascot", "tiger_celebrate")],
    "tiger_sleepy": [("illustrations/mascot", "tiger_sleepy")],
    "tiger_sad": [("illustrations/mascot", "tiger_sad"), ("stickers", "tiger_sad")],
    "tiger_surprised": [("illustrations/mascot", "tiger_surprised"), ("stickers", "tiger_surprised")],
    "magpie_celebrate": [("illustrations/mascot", "magpie_celebrate")],
    "magpie_perched": [("illustrations/mascot", "magpie_perched")],
    "magpie_perched_alt": [("illustrations/mascot", "magpie_perched_alt")],
    "magpie_wingdown": [("illustrations/mascot", "magpie_wingdown")],
    "magpie_wingup": [("illustrations/mascot", "magpie_wingup")],
    "magpie_worry": [("illustrations/mascot", "magpie_worry")],
    # ── stickers (§5.1/5.2/5.3/5.4/5.6) ──
    "tiger_cheer": [("stickers", "tiger_cheer")],
    "tiger_clap": [("stickers", "tiger_clap")],
    "tiger_love": [("stickers", "tiger_love")],
    "magpie_dance": [("stickers", "magpie_dance")],
    "magpie_wave": [("stickers", "magpie_wave")],
    "magpie_sleep": [("stickers", "magpie_sleep")],
    "magpie_sing": [("stickers", "magpie_sing")],
    "magpie_encourage": [("stickers", "magpie_encourage")],
    "hangul_good": [("stickers", "hangul_good")],
    "hangul_best": [("stickers", "hangul_best")],
    "hangul_kk": [("stickers", "hangul_kk")],
    "dancheong_lantern": [("stickers", "dancheong_lantern")],
    "stamp_sticker_cheer": [("stickers", "stamp_sticker_cheer")],
    "stamp_sticker_love": [("stickers", "stamp_sticker_love")],
    "stamp_sticker_happy": [("stickers", "stamp_sticker_happy")],
    "stamp_sticker_well_done": [("stickers", "stamp_sticker_well_done")],
    "stamp_sticker_fightingpng": [("stickers", "stamp_sticker_fighting")],  # typo fix
    # ── stamps (§4) ──
    "stamp_mountain": [("illustrations/stamps", "stamp_mountain")],
    "stamp_plum": [("illustrations/stamps", "stamp_plum")],
    # ── tiger_anim ambient specials (stretch/roar) ──
    "tiger_stretch_prep_threeq_right": [("illustrations/tiger_anim", "stretch_prep")],
    "tiger_stretch_full_threeq_right": [("illustrations/tiger_anim", "stretch_full")],
    "tiger_stretch_release_threeq_right": [("illustrations/tiger_anim", "stretch_release")],
    "tiger_roar_prep_threeq_right": [("illustrations/tiger_anim", "roar_prep")],
    "tiger_roar_open_threeq_right": [("illustrations/tiger_anim", "roar_open")],
    "tiger_roar_open_threeq_right2": [("illustrations/tiger_anim", "roar_open2")],
    "tiger_roar_full_threeq_right": [("illustrations/tiger_anim", "roar_full")],
    "tiger_roar_close_threeq_right": [("illustrations/tiger_anim", "roar_close")],
    "tiger_roar_recover_threeq_right": [("illustrations/tiger_anim", "roar_recover")],
    # ── gye 공동 한옥 (§6) — new folder, no consumer yet ──
    "gye_haenglangchae": [("illustrations/gye", "gye_haenglangchae")],
    "gye_byeoldang": [("illustrations/gye", "gye_byeoldang")],
    "gye_jeongja": [("illustrations/gye", "gye_jeongja")],
    "gye_pond_large": [("illustrations/gye", "gye_pond_large")],
    "gye_garden": [("illustrations/gye", "gye_garden")],
    "gye_bridge": [("illustrations/gye", "gye_bridge")],
    "gye_jangmyeongdeung_pair": [("illustrations/gye", "gye_jangmyeongdeung_pair")],
    "gye_gate_grand": [("illustrations/gye", "gye_gate_grand")],
    # ── 책 한 컷 UI (§7) — new folder, no consumer yet ──
    "book_empty_shelf": [("illustrations/book", "book_empty_shelf")],
    "book_camera_guide": [("illustrations/book", "book_camera_guide")],
    "book_analyzing": [("illustrations/book", "book_analyzing")],
    "book_success": [("illustrations/book", "book_success")],
    "book_error": [("illustrations/book", "book_error")],
}


def stem_of(fn):
    b = fn
    while b.endswith(".png"):
        b = b[:-4]
    return b.split("_optimized")[0]


def key_transparent(src):
    """P/RGB opaque → RGBA with border-connected near-white removed."""
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
             (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2),
             (4, h // 2), (w - 5, h // 2)]
    for xy in seeds:
        try:
            ImageDraw.floodfill(im, xy, (0, 0, 0, 0), thresh=46)
        except Exception:
            pass
    return im


def save_compact(rgba, path):
    a = rgba.getchannel("A")
    p = rgba.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=255, dither=Image.NONE)
    p.paste(255, mask=a.point(lambda v: 255 if v < 8 else 0).convert("1"))
    pal = p.getpalette() or []
    if len(pal) < 768:
        pal = pal + [0, 0, 0] * ((768 - len(pal)) // 3)
    p.putpalette(pal)
    p.info["transparency"] = 255
    p.save(path, optimize=True)


def main():
    files = [f for f in os.listdir(SRC) if f.lower().endswith(".png")]
    used = set()
    unmapped = []
    done = 0
    for fn in sorted(files):
        st = stem_of(fn)
        targets = MAP.get(st)
        if not targets:
            unmapped.append(fn)
            continue
        used.add(st)
        rgba = key_transparent(os.path.join(SRC, fn))
        transp = 100 * rgba.getchannel("A").histogram()[0] / (rgba.size[0] * rgba.size[1])
        for folder, name in targets:
            d = os.path.join(REPO, folder)
            os.makedirs(d, exist_ok=True)
            out = os.path.join(d, name + ".png")
            save_compact(rgba, out)
            done += 1
            print(f"  {folder}/{name}.png  ({transp:.0f}%T)")
    print(f"\nplaced {done} files. sources used {len(used)}/{len(files)}.")
    if unmapped:
        print("UNMAPPED sources (not placed):")
        for u in unmapped:
            print(f"  {u}  (stem={stem_of(u)})")
    missing = [k for k in MAP if k not in used]
    if missing:
        print("MAP keys with NO source file:")
        for m in missing:
            print(f"  {m}")


if __name__ == "__main__":
    main()
