"""Refresh the live 002 overlay from the delivered estate wall inventory."""
from html import escape
from pathlib import Path
import json
import re
import sys

sys.path.insert(0, str(Path(__file__).parent))
from register_site002 import to_pixel

ROOT = Path(__file__).resolve().parents[2]
N = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
PAGE = Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist/placement-review.html')
contract = json.loads((N / 'estate-fabric-contract.json').read_text(encoding='utf8'))
inventory = json.loads((N / 'wall-network-inventory.json').read_text(encoding='utf8'))
html = PAGE.read_text(encoding='utf8')


def line(name, a, b, color, width):
    return (f'<line x1="{a[0]:.2f}" y1="{a[1]:.2f}" x2="{b[0]:.2f}" y2="{b[1]:.2f}" '
            f'stroke="{color}" stroke-width="{width}" stroke-linecap="round">'
            f'<title>{escape(name)}</title></line>')


retained = []
for wall in inventory['cores']:
    if wall['name'].startswith('Estate.fabric.'):
        continue
    if wall['name'].startswith('V27.') and 'wall to ' not in wall['name']:
        continue
    a, b = to_pixel([wall['start'], wall['stop']])
    retained.append(line(wall['name'], a, b, '#31483e', 4.5))

new = [line(wall['name'], wall['sourcePixelStart'], wall['sourcePixelStop'], '#b45c32', 5)
       for wall in contract['wallRoutes']]
wall_groups = (f'<g id="retained-walls" opacity=".66">{"".join(retained)}</g>'
               f'<g id="walls" opacity=".78">{"".join(new)}</g>')
html, count = re.subn(r'<g id="(?:retained-walls|walls)"[^>]*>.*?</g>(?:<g id="walls"[^>]*>.*?</g>)?(?=<g id="gardens">)',
                      wall_groups, html, count=1)
assert count == 1, 'Wall overlay anchor changed'
html = re.sub(r'<label>추가 담장 .*?</label>',
              '<label>기존 담장 <input type="checkbox" checked onchange="document.querySelector(\'#retained-walls\').style.display=this.checked?\'\':\'none\'"></label>'
              '<label>이번 연결 <input type="checkbox" checked onchange="document.querySelector(\'#walls\').style.display=this.checked?\'\':\'none\'"></label>',
              html, count=1)
html = re.sub(r'<button onclick="document.querySelector\(\'#plan\'\).setAttribute\(\'viewBox\',\'780 760 1170 1200\'\)">건물 주변</button>',
              '<button onclick="document.querySelector(\'#plan\').setAttribute(\'viewBox\',\'1240 780 780 1040\')">별당·대문채 담</button>'
              '<button onclick="document.querySelector(\'#plan\').setAttribute(\'viewBox\',\'1030 1270 600 680\')">중문채·곳간채 뒤</button>',
              html, count=1)
html = re.sub(r'<small>붉은 선은.*?</small>',
              f'<small>먹색 {len(retained)}구간: 유지한 담 · 황토색 {len(new)}구간: 이번 연결 · 점선: 작물 없는 텃밭</small>',
              html, count=1)
html = html.replace('value="75" min="0" max="100"', 'value="65" min="0" max="100"', 1)
PAGE.write_text(html, encoding='utf8')
print('PLACEMENT REVIEW REFRESHED', len(retained), len(new), PAGE)
