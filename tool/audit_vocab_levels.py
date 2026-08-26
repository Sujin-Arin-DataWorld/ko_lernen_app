#!/usr/bin/env python3
"""CEFR 레벨 분류 감사 — korean_vocab.csv (15컬럼) 전용.

2026-08-13 테스터 피드백("A2인데 양극화")의 데이터 절반: 레벨·팩별 목록을
사람이 검토할 수 있게 덤프하고, 휴리스틱으로 의심 단어를 뽑는다.

산출물:
  - docs/data/vocab_level_report.md   — 레벨·팩별 전체 목록 (검토용)
  - tool/vocab_level_suspects.csv     — 의심 단어 + 사유 + blocked 플래그

휴리스틱 (사유 코드):
  - sino3_low   : A1/A2 명사인데 순한글 3음절 이상 (한자어 추상명사 프록시)
  - topic_low   : 주제가 Gesellschaft/Politik/Umwelt/Wirtschaft 계열인데 B1 미만
  - below_topic : 단어 레벨이 소속 주제의 최빈 레벨보다 2랭크 이상 아래

blocked=true : satz_sentences.json 이 (level, vocabKo) 시맨틱 키로 이 단어를
참조 — 레벨을 옮기면 참조가 끊어지므로 배치 1에서 제외하거나 satz 를 같은
커밋에서 함께 수정해야 한다. (curriculum contentLinks 의 vocab 링크도 검사 —
현재 0개.)

사용:  python3 tool/audit_vocab_levels.py
"""

from __future__ import annotations

import csv
import json
from collections import Counter, OrderedDict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_CSV = REPO / "assets/data/korean_vocab.csv"
SATZ_JSON = REPO / "assets/data/satz_sentences.json"
MANIFEST_JSON = REPO / "assets/data/curriculum_manifest.json"
REPORT_MD = REPO / "docs/data/vocab_level_report.md"
SUSPECTS_CSV = REPO / "tool/vocab_level_suspects.csv"

LEVEL_RANK = {"A1": 0, "A2": 1, "B1": 2, "B2": 3, "C1": 4, "C2": 5}
HIGH_TOPICS = {
    "Gesellschaft",
    "Politik",
    "Umwelt",
    "Wirtschaft",
    "Wissenschaft",
    "Medien",
}


def is_hangul_syllable(ch: str) -> bool:
    return "가" <= ch <= "힣"


def hangul_len(word: str) -> int:
    return sum(1 for ch in word if is_hangul_syllable(ch))


def load_rows() -> tuple[list[str], list[dict[str, str]]]:
    with VOCAB_CSV.open(encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = [dict(zip(header, r)) for r in reader if r]
    return header, rows


def blocked_ids(rows: list[dict[str, str]]) -> dict[str, str]:
    """id → 차단 사유. satz (level:vocabKo) 참조 + curriculum vocab 링크."""
    out: dict[str, str] = {}
    satz = json.loads(SATZ_JSON.read_text(encoding="utf-8"))
    satz_keys = {
        (item.get("level", "").strip().lower(), item.get("vocabKo", "").strip())
        for item in satz.get("items", [])
        if item.get("vocabKo")
    }
    manifest = json.loads(MANIFEST_JSON.read_text(encoding="utf-8"))
    linked_vocab_ids = {
        link.get("contentId")
        for link in manifest.get("contentLinks", [])
        if link.get("contentKind") == "vocab"
    }
    for row in rows:
        key = (row["level"].strip().lower(), row["korean"].strip())
        if key in satz_keys:
            out[row["id"]] = "satz_ref"
        if row["id"] in linked_vocab_ids:
            out[row["id"]] = (out.get(row["id"], "") + "+curriculum_link").lstrip("+")
    return out


def find_suspects(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    topic_mode: dict[str, int] = {}
    by_topic: dict[str, Counter] = {}
    for row in rows:
        by_topic.setdefault(row["topic"], Counter())[row["level"]] += 1
    for topic, counts in by_topic.items():
        topic_mode[topic] = LEVEL_RANK[counts.most_common(1)[0][0]]

    blocked = blocked_ids(rows)
    suspects = []
    for row in rows:
        level = row["level"].strip()
        rank = LEVEL_RANK.get(level)
        if rank is None:
            continue
        reasons = []
        pos = row["pos_de"].strip()
        if rank <= 1 and pos == "Nomen" and hangul_len(row["korean"]) >= 3:
            reasons.append("sino3_low")
        if rank < 2 and row["topic"].strip() in HIGH_TOPICS:
            reasons.append("topic_low")
        if topic_mode.get(row["topic"], rank) - rank >= 2:
            reasons.append("below_topic")
        if not reasons:
            continue
        suspects.append(
            {
                "id": row["id"],
                "korean": row["korean"],
                "german": row["german"],
                "level": level,
                "pack_id": row["pack_id"],
                "topic": row["topic"],
                "pos_de": pos,
                "reasons": "+".join(reasons),
                "blocked": blocked.get(row["id"], ""),
            }
        )
    return suspects


def write_report(rows: list[dict[str, str]]) -> None:
    by_level: dict[str, OrderedDict[str, list[dict[str, str]]]] = {}
    for row in rows:
        by_level.setdefault(row["level"], OrderedDict()).setdefault(
            row["pack_id"], []
        ).append(row)

    lines = [
        "# Vocab Level Report (auto-generated)",
        "",
        "> 생성: `python3 tool/audit_vocab_levels.py` — 레벨 분류 검토용.",
        "> 직접 편집 금지. 재분류는 `tool/relevel/relevel_batch_*.csv` +",
        "> `python3 tool/relevel_vocab.py --apply` 로.",
        "",
        f"**총 단어**: {len(rows)}",
        "",
    ]
    for level in ["A1", "A2", "B1", "B2", "C1", "C2"]:
        packs = by_level.get(level, {})
        n = sum(len(v) for v in packs.values())
        lines.append(f"## {level} — {n} 단어, {len(packs)} 팩")
        lines.append("")
        for pack_id, pack_rows in packs.items():
            words = " · ".join(
                sorted(r["korean"] for r in pack_rows)
            )
            lines.append(f"- `{pack_id}` ({len(pack_rows)}): {words}")
        lines.append("")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    _, rows = load_rows()
    write_report(rows)
    suspects = find_suspects(rows)
    with SUSPECTS_CSV.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "id",
                "korean",
                "german",
                "level",
                "pack_id",
                "topic",
                "pos_de",
                "reasons",
                "blocked",
            ],
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(suspects)
    print(f"report  → {REPORT_MD.relative_to(REPO)}")
    print(f"suspects → {SUSPECTS_CSV.relative_to(REPO)} ({len(suspects)} rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
