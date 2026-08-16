#!/usr/bin/env python3
"""Render source-free PDF page samples and contact sheets for visual audit.

Outputs belong in a temporary directory and must not be committed. The JSON
manifest contains only file names and page numbers; no extracted text is kept.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any


def sample_pages(page_count: int) -> list[int]:
    if page_count < 1:
        raise ValueError("page_count must be positive")
    values = (5 if page_count >= 5 else 1, (page_count + 1) // 2, max(1, page_count - 5))
    return list(dict.fromkeys(values))


def _run_renderer(renderer: Path, pdf: Path, page: int, prefix: Path) -> None:
    arguments = [
        str(renderer),
        "-f",
        str(page),
        "-l",
        str(page),
        "-png",
        "-scale-to",
        "900",
        "-singlefile",
        str(pdf),
        str(prefix),
    ]
    if renderer.suffix.lower() in {".cmd", ".bat"}:
        arguments = ["cmd.exe", "/d", "/s", "/c", subprocess.list2cmdline(arguments)]
    result = subprocess.run(arguments, capture_output=True, check=False)
    if result.returncode != 0:
        stderr = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(stderr or f"renderer failed for {pdf.name} page {page}")


def _contact_sheets(output_dir: Path, records: list[dict[str, Any]]) -> list[str]:
    from PIL import Image, ImageDraw

    sheet_names: list[str] = []
    cell_width, cell_height = 450, 620
    for start in range(0, len(records), 3):
        group = records[start : start + 3]
        sheet = Image.new("RGB", (cell_width * 3, cell_height * len(group)), "white")
        draw = ImageDraw.Draw(sheet)
        for row, record in enumerate(group):
            for column, sample in enumerate(record["samples"]):
                path = output_dir / sample["image"]
                with Image.open(path) as source:
                    page = source.convert("RGB")
                    page.thumbnail((430, 570))
                    x = column * cell_width + (cell_width - page.width) // 2
                    y = row * cell_height + 30
                    sheet.paste(page, (x, y))
                draw.text((column * cell_width + 10, row * cell_height + 8), sample["label"], fill="black")
        sheet_name = f"contact-{start // 3 + 1:02d}.png"
        sheet.save(output_dir / sheet_name)
        sheet_names.append(sheet_name)
    return sheet_names


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdfs", nargs="+", type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--renderer", type=Path)
    args = parser.parse_args(argv)

    try:
        from pypdf import PdfReader
    except ImportError:
        print("ERROR: pypdf is required; run with the bundled workspace Python", file=sys.stderr)
        return 1

    renderer = args.renderer or Path(shutil.which("pdftoppm") or "")
    if not renderer.is_file():
        print("ERROR: pdftoppm renderer was not found", file=sys.stderr)
        return 1
    args.output_dir.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, Any]] = []
    try:
        for index, pdf in enumerate(args.pdfs, start=1):
            page_count = len(PdfReader(pdf).pages)
            samples: list[dict[str, Any]] = []
            for page in sample_pages(page_count):
                stem = f"pdf-{index:02d}-p{page:04d}"
                _run_renderer(renderer, pdf, page, args.output_dir / stem)
                samples.append(
                    {
                        "page": page,
                        "image": f"{stem}.png",
                        "label": f"PDF {index:02d} / page {page}",
                    }
                )
            records.append(
                {
                    "index": index,
                    "file_name": pdf.name,
                    "page_count": page_count,
                    "samples": samples,
                }
            )
        sheets = _contact_sheets(args.output_dir, records)
    except (OSError, RuntimeError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    manifest = {"records": records, "contact_sheets": sheets}
    (args.output_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="",
    )
    print(f"OK: rendered {sum(len(record['samples']) for record in records)} page samples")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
