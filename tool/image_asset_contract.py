"""Shared pixel checks for shipped image assets."""

from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHROMA_KEY_RGB = (0, 255, 0)
CHROMA_KEY_TOLERANCE = 8
CHROMA_KEY_ALPHA_MIN = 8


def is_chroma_key_rgb(red: int, green: int, blue: int) -> bool:
    return all(
        abs(actual - expected) <= CHROMA_KEY_TOLERANCE
        for actual, expected in zip((red, green, blue), CHROMA_KEY_RGB)
    )
