"""KOREAN_REVIEW_*.md 리뷰 스냅샷 재생성.

소스: assets/data/korean_vocab.csv · scenarios.json · smalltalk.json
출력: docs/KOREAN_REVIEW_2026-07-01.md (덮어쓰기)
"""

from __future__ import annotations
import csv
import json
from pathlib import Path

OUT = Path("docs/KOREAN_REVIEW_2026-07-01.md")
VOCAB = Path("assets/data/korean_vocab.csv")
SCEN = Path("assets/data/scenarios.json")
SMALL = Path("assets/data/smalltalk.json")

LEVEL_ORDER = ["A1", "A2", "B1", "B2"]


def render_vocab() -> str:
    with VOCAB.open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    lines: list[str] = ["## 1. 단어 예문 (558) — `단어 · 예문 · (뜻)`", ""]
    # group by level in encounter order (CSV order). But original md
    # groups by level split — with each level potentially appearing
    # multiple times (topics reintroduce levels). We follow that:
    # emit section header on each level-run change.
    prev = None
    for r in rows:
        lvl = r["level"]
        if lvl != prev:
            lines.append("")
            lines.append(f"### {lvl}")
            lines.append("")
            prev = lvl
        ko = r["korean"]
        ex = r["example_korean"]
        de = r["german"]
        lines.append(f"- **{ko}** · {ex}  _({de})_")
    lines.append("")
    return "\n".join(lines)


def render_scenarios() -> str:
    with SCEN.open(encoding="utf-8") as f:
        d = json.load(f)
    lines: list[str] = ["", "## 2. 시나리오 대사 (33개)", ""]
    for sc in d["scenarios"]:
        title_ko = sc["title"]["ko"]
        title_de = sc["title"]["de"]
        lines.append("")
        lines.append(f"### {sc['id']} — {title_ko} _({title_de})_")
        for turn in sc.get("dialog", []):
            speaker = turn.get("speaker", "?")
            ko = turn.get("ko", "")
            lines.append(f"- [{speaker}] {ko}")
    lines.append("")
    return "\n".join(lines)


def render_smalltalk() -> str:
    with SMALL.open(encoding="utf-8") as f:
        d = json.load(f)
    lines: list[str] = ["", "## 3. 스몰토크 (145)", ""]
    for p in d["phrases"]:
        ko = p["ko"]
        reply = p.get("reply_ko")
        # reply may be a dict {ko, de, en}
        if reply is None:
            reply = p.get("reply")
        if isinstance(reply, dict):
            reply_ko = reply.get("ko", "")
        elif isinstance(reply, str):
            reply_ko = reply
        else:
            reply_ko = ""
        if reply_ko:
            lines.append(f"- {ko}  → {reply_ko}")
        else:
            lines.append(f"- {ko}")
    lines.append("")
    return "\n".join(lines)


def main():
    header = (
        "# 한국어 사용자 대면 텍스트 전수 리뷰 — 2026-07-01\n"
        "\n"
        "> Jin(원어민) 검수용. 어색한 곳에 표시해주시면 반영합니다. (§0: KO 최종 판정=원어민)\n"
        "> 2026-07-01 원어민 자연어 최적화 pass 반영본 (vocab 408 · 시나리오 7 · smalltalk 18 교체).\n"
        "\n"
    )
    md = header + render_vocab() + render_scenarios() + render_smalltalk()
    OUT.write_text(md, encoding="utf-8")
    print(f"작성 완료: {OUT} ({len(md.splitlines())} 줄)")


if __name__ == "__main__":
    main()
