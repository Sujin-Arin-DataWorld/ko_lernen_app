"""Analysis-only contact sheets. Original and runtime art remain unchanged."""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
inventory = json.loads((ROOT / "audit/october-style-inventory.json").read_text(encoding="utf-8"))
items = [row for row in inventory["images"] if not row.get("duplicateOf")]
output = ROOT / "audit/october-contact-sheets"
output.mkdir(parents=True, exist_ok=True)
font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 16)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 12)
pages = []
for start in range(0, len(items), 24):
    rows = items[start : start + 24]
    sheet = Image.new("RGB", (1440, 1872), "#ddd3c2")
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(rows):
        x, y = (index % 4) * 360, (index // 4) * 312
        draw.rectangle((x + 3, y + 3, x + 356, y + 308), fill="#f6ede0")
        with Image.open(row["path"]) as original:
            thumb = original.convert("RGBA")
            thumb.thumbnail((344, 266), Image.Resampling.LANCZOS)
            sheet.paste(thumb, (x + (360 - thumb.width) // 2, y + 6 + (266 - thumb.height) // 2), thumb)
        draw.text((x + 9, y + 275), row["id"], fill="#1c2520", font=font)
        draw.text((x + 9, y + 295), f'{row["width"]} x {row["height"]} | {row["created"][:10]}', fill="#4b5148", font=small)
    name = f"sheet-{len(pages) + 1:02d}.jpg"
    sheet.save(output / name, quality=92)
    pages.append({"file": name, "items": [row["id"] for row in rows]})
(output / "index.json").write_text(json.dumps(pages, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"uniqueImages": len(items), "sheets": len(pages), "output": str(output)}))
