#!/usr/bin/env python3
"""단어 레벨 재분류 적용기 — targeted re-pack (2026-08-13).

`tool/relevel/relevel_batch_*.csv` (컬럼: id, korean, old_level, new_level,
target_pack, reason) 를 `assets/data/korean_vocab.csv` (15컬럼)에 적용한다.

설계 원칙 (팩 무결성):
  - **id·행수 불변** (test/content_id_contract_test.dart 계약: 931행, id 유일).
  - 기존 팩 id 는 만들지도 지우지도 않는다 — 이동 대상 팩(target_pack)은
    반드시 **이미 존재**하고 레벨이 new_level 과 같아야 한다. pack_progress
    가 pack id 로 키잉되므로 팩 자체를 안 건드리면 진행도는 자기치유된다
    (`seen ∩ pack.words` 재계산).
  - 이동 단어는 target_pack 의 끝(pack_order = max+1)에 boss=false 로 붙는다.
  - 원 소속 팩은 이동 후 보스가 2개 미만이면 pack_order 최댓값 비보스를
    승격, 4단어 미만이 되면 경고(수동 검토).
  - satz_sentences.json 이 (level, vocabKo) 로 참조하는 단어는 거부 —
    레벨을 옮기면 참조가 끊긴다 (같은 커밋에서 satz 도 고칠 때만 수동 해제).

기본은 dry-run(계획 출력)이고 `--apply` 를 줘야 쓴다. 적용 후
docs/data/vocab_pack_map.md 를 재생성한다.

사용:
  python3 tool/relevel_vocab.py tool/relevel/relevel_batch_001.csv
  python3 tool/relevel_vocab.py tool/relevel/relevel_batch_001.csv --apply
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import OrderedDict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_CSV = REPO / "assets/data/korean_vocab.csv"
SATZ_JSON = REPO / "assets/data/satz_sentences.json"
PACK_MAP_MD = REPO / "docs/data/vocab_pack_map.md"

LEVELS = {"A1", "A2", "B1", "B2"}
MIN_PACK_SIZE = 4
MIN_BOSS = 2

COLUMNS = [
    "korean", "romanization", "german", "level", "pos_de",
    "example_korean", "example_german", "topic",
    "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]


def load_vocab(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        if header != COLUMNS:
            raise SystemExit(f"CSV 헤더가 예상과 다름: {header}")
        return [dict(zip(header, r)) for r in reader if r]


def load_batch(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    required = {"id", "korean", "old_level", "new_level", "target_pack"}
    for row in rows:
        missing = required - set(k for k, v in row.items() if v is not None)
        if missing:
            raise SystemExit(f"배치 컬럼 누락 {missing}: {row}")
    return rows


def satz_locked_keys(satz_path: Path) -> set[tuple[str, str]]:
    if not satz_path.exists():
        return set()
    satz = json.loads(satz_path.read_text(encoding="utf-8"))
    return {
        (i.get("level", "").strip().lower(), i.get("vocabKo", "").strip())
        for i in satz.get("items", [])
        if i.get("vocabKo")
    }


def apply_batch(
    vocab: list[dict[str, str]],
    batch: list[dict[str, str]],
    locked: set[tuple[str, str]],
) -> tuple[list[str], list[str]]:
    """vocab 을 제자리 수정. (계획 로그, 경고) 반환. 오류는 SystemExit."""
    by_id = {row["id"]: row for row in vocab}
    packs: dict[str, list[dict[str, str]]] = OrderedDict()
    for row in vocab:
        packs.setdefault(row["pack_id"], []).append(row)

    plan: list[str] = []
    warnings: list[str] = []
    touched_sources: set[str] = set()

    for entry in batch:
        vid = entry["id"].strip()
        row = by_id.get(vid)
        if row is None:
            raise SystemExit(f"{vid}: CSV 에 없는 id")
        if row["korean"].strip() != entry["korean"].strip():
            raise SystemExit(
                f"{vid}: korean 불일치 (csv={row['korean']} batch={entry['korean']})"
            )
        old_level = entry["old_level"].strip()
        new_level = entry["new_level"].strip()
        if row["level"].strip() != old_level:
            raise SystemExit(
                f"{vid}: old_level 불일치 (csv={row['level']} batch={old_level})"
                " — 이미 적용된 배치인지 확인"
            )
        if new_level not in LEVELS or new_level == old_level:
            raise SystemExit(f"{vid}: new_level 부적합 ({new_level})")
        if (old_level.lower(), row["korean"].strip()) in locked:
            raise SystemExit(
                f"{vid} ({row['korean']}): satz_sentences.json 이 참조 — 이동 금지"
            )
        target = entry["target_pack"].strip()
        target_rows = packs.get(target)
        if not target_rows:
            raise SystemExit(f"{vid}: target_pack '{target}' 이 존재하지 않음")
        target_levels = {r["level"].strip() for r in target_rows if r["id"] != vid}
        if target_levels != {new_level}:
            raise SystemExit(
                f"{vid}: target_pack '{target}' 레벨 {target_levels} ≠ {new_level}"
            )

        source = row["pack_id"]
        touched_sources.add(source)
        packs[source] = [r for r in packs[source] if r["id"] != vid]
        max_order = max(int(r["pack_order"]) for r in target_rows)
        row["level"] = new_level
        row["pack_id"] = target
        row["pack_order"] = str(max_order + 1)
        row["is_review_boss"] = "false"
        target_rows.append(row)
        plan.append(
            f"{vid} {row['korean']}: {old_level}/{source} → {new_level}/{target}"
            f" (order {max_order + 1})"
        )

    # 원 소속 팩 보수.
    for source in sorted(touched_sources):
        remaining = packs.get(source, [])
        if not remaining:
            warnings.append(f"⚠ {source}: 팩이 비었음 — 수동 검토 필요")
            continue
        if len(remaining) < MIN_PACK_SIZE:
            warnings.append(
                f"⚠ {source}: {len(remaining)}단어로 축소 (< {MIN_PACK_SIZE}) — 수동 검토"
            )
        bosses = [r for r in remaining if r["is_review_boss"] == "true"]
        non_bosses = sorted(
            (r for r in remaining if r["is_review_boss"] != "true"),
            key=lambda r: int(r["pack_order"]),
        )
        while len(bosses) < MIN_BOSS and non_bosses and len(remaining) >= 2:
            promoted = non_bosses.pop()
            promoted["is_review_boss"] = "true"
            bosses.append(promoted)
            plan.append(f"{source}: 보스 승격 → {promoted['korean']}")

    return plan, warnings


def write_vocab(vocab: list[dict[str, str]], path: Path) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        writer.writerow(COLUMNS)
        for row in vocab:
            writer.writerow([row[c] for c in COLUMNS])


def write_pack_map(vocab: list[dict[str, str]], path: Path) -> None:
    by_level: dict[str, OrderedDict[str, list[dict[str, str]]]] = {}
    for row in vocab:
        by_level.setdefault(row["level"], OrderedDict()).setdefault(
            row["pack_id"], []
        ).append(row)
    lines = [
        "# Vocab Pack Map (auto-generated)",
        "",
        "> 생성: `python3 tool/relevel_vocab.py --apply` (구: build_vocab_packs.py)",
        "> 절대 직접 편집 금지.",
        "",
        f"**총 단어**: {len(vocab)}",
        "",
    ]
    for level in ["A1", "A2", "B1", "B2"]:
        packs = by_level.get(level, {})
        n = sum(len(v) for v in packs.values())
        lines.append(f"## {level} — {n} 단어, {len(packs)} 팩")
        lines.append("")
        for pack_id, rows in packs.items():
            ordered = sorted(rows, key=lambda r: int(r["pack_order"]))
            words = " · ".join(
                r["korean"] + (" 👑" if r["is_review_boss"] == "true" else "")
                for r in ordered
            )
            lines.append(f"- `{pack_id}` ({len(rows)}): {words}")
        lines.append("")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch", type=Path)
    parser.add_argument("--apply", action="store_true", help="실제로 CSV 에 쓴다")
    args = parser.parse_args()

    vocab = load_vocab(VOCAB_CSV)
    before_ids = [r["id"] for r in vocab]
    batch = load_batch(args.batch)
    plan, warnings = apply_batch(vocab, batch, satz_locked_keys(SATZ_JSON))

    after_ids = [r["id"] for r in vocab]
    if sorted(before_ids) != sorted(after_ids) or len(vocab) != len(before_ids):
        raise SystemExit("불변식 위반: id 집합/행수가 변했다 — 중단")

    print(f"배치 {args.batch.name}: {len(batch)}건")
    for line in plan:
        print("  " + line)
    for warning in warnings:
        print("  " + warning)
    if not args.apply:
        print("(dry-run — 적용하려면 --apply)")
        return 0

    write_vocab(vocab, VOCAB_CSV)
    write_pack_map(vocab, PACK_MAP_MD)
    print(f"적용 완료 → {VOCAB_CSV.relative_to(REPO)}, {PACK_MAP_MD.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
