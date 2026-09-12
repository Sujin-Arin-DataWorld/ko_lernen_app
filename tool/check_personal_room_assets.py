#!/usr/bin/env python3
"""Fail-closed image contract for the shipped Sarangbang room surface."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
BACKGROUND = ROOT / "assets" / "illustrations" / "hanok" / "sarangbang_empty.png"
DECORATION_ROOT = ROOT / "assets" / "illustrations" / "decorations"
BACKGROUND_CANVAS = (1086, 1448)
ROOM_DECORATIONS = (
    "decoration_baduk.png",
    "decoration_bandaji.png",
    "decoration_bangseok_pair.png",
    "decoration_boryo_set.png",
    "decoration_byeongpung_small.png",
    "decoration_chaekgado.png",
    "decoration_deungjan.png",
    "decoration_gat_buchae.png",
    "decoration_geomungo.png",
    "decoration_gobi.png",
    "decoration_hwaro.png",
    "decoration_hyangno.png",
    "decoration_jagae_mungap.png",
    "decoration_mokchim.png",
    "decoration_munbangsau.png",
    "decoration_pyeonaek.png",
    "decoration_sabangtakja.png",
    "decoration_sagunja_guk.png",
    "decoration_sagunja_juk.png",
    "decoration_sagunja_maehwa.png",
    "decoration_sagunja_nan.png",
    "decoration_seoan.png",
    "decoration_soban.png",
)


def _chroma_key_count(image: Image.Image) -> int:
    return sum(
        1
        for red, green, blue, alpha in image.convert("RGBA").getdata()
        if (red, green, blue) == (0, 255, 0) and alpha > 8
    )


def _check(
    path: Path,
    *,
    expected_size: tuple[int, int] | None = None,
    require_opaque: bool = False,
    require_transparency: bool = False,
) -> list[str]:
    with Image.open(path) as source:
        image = source.copy()

    rgba = image.convert("RGBA")
    alpha_min, alpha_max = rgba.getchannel("A").getextrema()
    chroma = _chroma_key_count(rgba)
    errors: list[str] = []
    if expected_size is not None and image.size != expected_size:
        errors.append(
            f"size={image.width}x{image.height}, "
            f"expected={expected_size[0]}x{expected_size[1]}"
        )
    if image.mode not in {"RGB", "RGBA", "P"}:
        errors.append(f"mode={image.mode}, expected RGB, RGBA, or P+tRNS")
    if require_opaque and (alpha_min != 255 or alpha_max != 255):
        errors.append(f"alpha range={alpha_min}-{alpha_max}, expected fully opaque")
    if require_transparency and alpha_min == 255:
        errors.append("expected a transparent cutout")
    if chroma:
        errors.append(f"contains {chroma} opaque #00ff00 chroma-key pixels")
    detail = (
        f"{image.width}x{image.height} mode={image.mode} "
        f"alpha={alpha_min}-{alpha_max} key={chroma}"
    )
    relative = path.relative_to(ROOT)
    if errors:
        return [f"[fail] {relative} {detail}: {'; '.join(errors)}"]
    return [f"[pass] {relative} {detail}"]


def main() -> int:
    specifications = [
        (BACKGROUND, {"expected_size": BACKGROUND_CANVAS, "require_opaque": True}),
        *[
            (DECORATION_ROOT / name, {"require_transparency": True})
            for name in ROOM_DECORATIONS
        ],
    ]
    problems = 0
    for path, options in specifications:
        if not path.is_file():
            print(f"[missing] {path.relative_to(ROOT)}")
            problems += 1
            continue
        for line in _check(path, **options):
            print(line)
            if line.startswith("[fail]"):
                problems += 1
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
