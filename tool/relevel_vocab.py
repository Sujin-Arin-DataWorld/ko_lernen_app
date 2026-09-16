#!/usr/bin/env python3
"""단어 레벨 재분류 적용기 — targeted re-pack (2026-08-13; T2.5 PR-L2a Part C
개정, 2026-09-07: satz 거부를 동기화 이동으로 교체).

`tool/relevel/relevel_batch_*.csv` (컬럼: id, korean, old_level, new_level,
target_pack, reason) 를 `assets/data/korean_vocab.csv` (15컬럼)에 적용한다.

설계 원칙 (팩 무결성, 2026-08-13 원안 그대로):
  - **id·행수 불변** (test/content_id_contract_test.dart 계약:
    `tools/content_factory/content_audit_manifest.json`의 `sources[kind=vocab]
    .count` 와 정확히 일치해야 함 -- 이 스크립트는 행을 추가/삭제하지 않고
    이동만 하므로 그 카운트 자체는 건드리지 않는다. id 는 유일).
  - 기존 팩 id 는 만들지도 지우지도 않는다 — 이동 대상 팩(target_pack)은
    반드시 **이미 존재**하고 레벨이 new_level 과 같아야 한다. pack_progress
    가 pack id 로 키잉되므로 팩 자체를 안 건드리면 진행도는 자기치유된다
    (`seen ∩ pack.words` 재계산).
  - 이동 단어는 target_pack 의 끝(pack_order = max+1)에 boss=false 로 붙는다.
  - 원 소속 팩은 이동 후 보스가 2개 미만이면 pack_order 최댓값 비보스를
    승격, 4단어 미만이 되면 경고(수동 검토).

T2.5 개정 -- satz 거부 대신 동기화 이동 (plan §3.E/§14):
  단어가 레벨을 옮기면, 그 단어를 참조하는 다른 콘텐츠도 같은 트랜잭션
  안에서 함께 옮긴다 (relevel_bundle.py 의 `_migrate_cloze`/`_migrate_satz`/
  `_migrate_can_do` 와 동일한 매칭 규칙, 다만 팩 전체가 아니라 단어 하나
  단위):
    1. `satz_sentences.json` 의 (level==old, vocabKo==korean) 항목 →
       level=new.
    2. `cloze.json` 의 (level==old, fullKo==example_korean) 항목 → level=new.
    3. `can_do_content_authorities.json` 의 `coverage
       .inheritedContentReferences` 중 `sourceVocabId==id` 인 행 →
       `sourceId`=target_pack, `level`=new, `courseUnitId`=
       `vocabPackUnitMap[pack_base(target_pack)]`, `canDoSegmentId`= target
       팩을 직접 참조하는 contentCluster 를 소유한 segment (없으면 실패).
       `sourceVocabFingerprintSha256` 은 이 스크립트가 건드리지 않는다 --
       apply 후 별도로 `python tool/refresh_can_do_vocab_fingerprints.py`
       를 실행해야 한다 (ContentValidator 는 fingerprint 를 검사하지 않지만
       `relevel_bundle.check_can_do_consistency`/Dart 로더는 검사한다).
    4. `relevel_ledger.json` 에 이동한 vocab id 하나 + 옮겨진 cloze/satz id
       전부를 기록한다 (batch=CSV 파일명, movedAt=오늘, reason=배치 행의
       reason 컬럼 -- 빈 문자열이면 거부).
    5. cloze/satz 의 `meta.total`/`meta.perLevel` 을
       `relevel_bundle._refresh_game_meta` 로 재계산한다.
    6. `word_relations.json` 의 `sourceVocabId==id` 인 클러스터도
       level=new 로 동기화한다. 저작한 관계·예문·ID는 유지한다.
    7. 실제 저장소에 쓰기 전, `assets/data` 전체를 임시 스테이지로 복사해
       그 위에서 위 1-6 을 수행하고 `ContentValidator(stage, ledger=...)
       .validate()` 가 깨끗할 때만 스테이지를 실저장소로 복사한다
       (relevel_bundle.py 의 스테이징 패턴과 동일 -- dry-run 도 스테이지를
       끝까지 만들고 검증하므로 안전성을 증명하지만 실저장소는 건드리지
       않는다).

기본은 dry-run(계획 출력)이고 `--apply` 를 줘야 쓴다. 적용 후
docs/data/vocab_pack_map.md 를 재생성한다.

사용:
  python3 tool/relevel_vocab.py tool/relevel/relevel_batch_001.csv
  python3 tool/relevel_vocab.py tool/relevel/relevel_batch_001.csv --apply
"""

from __future__ import annotations

import argparse
import csv
import shutil
import sys
import tempfile
from collections import OrderedDict
from datetime import date
from pathlib import Path
from typing import Any, Mapping

REPO = Path(__file__).resolve().parent.parent
CONTENT_FACTORY_DIR = REPO / "tools" / "content_factory"
if str(CONTENT_FACTORY_DIR) not in sys.path:
    sys.path.insert(0, str(CONTENT_FACTORY_DIR))

import relevel_ledger  # noqa: E402
from relevel_ledger import Ledger, LedgerEntry  # noqa: E402
from relevel_bundle import (  # noqa: E402
    _find_cluster_containing,
    _read_json,
    _refresh_game_meta,
    _segment_for_cluster,
    _write_json,
    pack_base,
)
import scan_grammar_level as _scan_grammar_level  # noqa: E402
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402
from validate_content import ContentValidator  # noqa: E402
from word_relation_relevel import sync_word_relation_levels  # noqa: E402

DEFAULT_LEDGER_PATH = relevel_ledger.DEFAULT_LEDGER_PATH
PACK_MAP_MD = REPO / "docs" / "data" / "vocab_pack_map.md"

LEVELS = {"A1", "A2", "B1", "B2", "C1", "C2"}
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
    required = {"id", "korean", "old_level", "new_level", "target_pack", "reason"}
    for row in rows:
        missing = required - set(k for k, v in row.items() if v is not None)
        if missing:
            raise SystemExit(f"배치 컬럼 누락 {missing}: {row}")
    return rows


def _ledger_record(
    ledger: Ledger,
    *,
    kind: str,
    entry_id: str,
    to_level: str,
    moved_at: str,
    batch_name: str,
    reason: str,
) -> Ledger:
    """`kind`/`entry_id` 에 대한 ledger 항목을 추가(첫 이동)하거나 교체(재
    이동)한다. `from_level` 은 항상 id 에 박힌 세그먼트에서 직접 뽑는다
    (`relevel_ledger.validate_ledger`의 세그먼트 검사와 정확히 같은 규칙 --
    `id.split("_")[1]`), 오늘 배치의 old_level 이 아니다: 한 id 가 생애
    두 번째로 재분류되면(예: PR-L2a 의 팩 이동으로 a1→a2 였다가, 이번
    배치로 다시 a2→b2), 원장은 "현재" 드리프트 하나만 기록하므로
    `Ledger.append`의 중복 id 거부를 그냥 부르면 깨진다 -- 기존 항목을
    지우고 새 항목(같은 id, 원래 from, 새 to)으로 교체해야 한다."""

    segments = entry_id.split("_")
    from_level = segments[1] if len(segments) > 2 else to_level
    new_entry = LedgerEntry(
        id=entry_id, kind=kind, from_level=from_level, to_level=to_level,
        movedAt=moved_at, batch=batch_name, reason=reason,
    )
    if ledger.get(kind, entry_id) is not None:
        remaining = [e for e in ledger.entries if e.id != entry_id]
        return Ledger(version=ledger.version, entries=[*remaining, new_entry], path=ledger.path)
    return ledger.append(new_entry)


_GRAMMAR_SCAN_LEXICON: CefrLexicon | None = None
_GRAMMAR_SCAN_INDEX: GrammarIndex | None = None


def _grammar_scan_tools() -> tuple[CefrLexicon, GrammarIndex]:
    """Lazily build/cache the same lexicon + grammar index
    `tools/content_factory/scan_grammar_level.py` uses, so the post-apply
    gate below is byte-identical in behaviour to the CI/local `--level`
    scan (Fable R8/R9, 2026-09-16 -- a relevel only moves the `level`
    LABEL; it never touches the sentence, so a word whose example was
    authored at its old, higher level can leave that level's grammar on a
    now-lower-level card, e.g. B2 시댁/처가/드시다 moved straight to A1
    without their -는 게/다고 했다/네요 examples being rewritten)."""
    global _GRAMMAR_SCAN_LEXICON, _GRAMMAR_SCAN_INDEX
    if _GRAMMAR_SCAN_LEXICON is None:
        _GRAMMAR_SCAN_LEXICON = CefrLexicon.load(REPO)
        _GRAMMAR_SCAN_INDEX = GrammarIndex.load(REPO)
    assert _GRAMMAR_SCAN_INDEX is not None
    return _GRAMMAR_SCAN_LEXICON, _GRAMMAR_SCAN_INDEX


def check_target_level_grammar(
    ledger: Ledger,
    *,
    batch_name: str,
    vocab_by_id: Mapping[str, dict[str, str]],
    cloze_by_id: Mapping[str, dict[str, Any]],
    satz_by_id: Mapping[str, dict[str, Any]],
) -> list[str]:
    """Post-apply gate (Fable R8/R9, 2026-09-16): for every id this batch
    moved (looked up from the ledger entries stamped with `batch_name`,
    so it covers the vocab row AND every synced cloze/satz derivative),
    re-run `scan_grammar_level`'s own detector against that id's sentence
    at its NEW (target) level. Returns the sorted list of offending ids
    (empty when clean) -- `migrate()` turns a non-empty result into a
    `SystemExit` before anything is copied back to the real repo, exactly
    like the existing `ContentValidator` stage gate. Only A1/A2/B1/B2 are
    checked (`LEVEL_CONFIG`'s own coverage, scan_grammar_level.py has no
    C1/C2 mode) -- a batch that ever moves something to C1/C2 is silently
    not covered here, matching the scanner's own current limits."""

    lexicon, grammar_index = _grammar_scan_tools()
    offenders: list[str] = []
    text_by_kind_id: dict[tuple[str, str], tuple[str, str]] = {}
    for entry in ledger.entries:
        if entry.batch != batch_name:
            continue
        level_name = entry.to_level.upper()
        cfg = _scan_grammar_level.LEVEL_CONFIG.get(level_name)
        if cfg is None:
            continue
        if entry.kind == "vocab":
            row = vocab_by_id.get(entry.id)
            text = row["example_korean"] if row else None
        elif entry.kind == "cloze":
            item = cloze_by_id.get(entry.id)
            text = item.get("fullKo") if item else None
        elif entry.kind == "satz":
            item = satz_by_id.get(entry.id)
            text = item.get("targetKo") if item else None
        else:
            continue
        if not text:
            continue
        text_by_kind_id[(entry.kind, entry.id)] = (text, level_name)

    for (kind, ident), (text, level_name) in sorted(text_by_kind_id.items()):
        threshold = _scan_grammar_level.LEVEL_CONFIG[level_name]["threshold"]
        hits = (
            _scan_grammar_level._grammar_hits_ge(lexicon, grammar_index, text, threshold)
            or _scan_grammar_level._attributive_noun_hits(text, threshold)
            or _scan_grammar_level._contracted_aux_hits(text, threshold)
        )
        if hits:
            offenders.append(f"{ident} ({kind}, target {level_name}): {text!r} -> {hits}")

    return offenders


def apply_batch(
    vocab: list[dict[str, str]],
    *,
    cloze_root: dict[str, Any],
    satz_root: dict[str, Any],
    authorities: dict[str, Any],
    segments_doc: dict[str, Any],
    curriculum: dict[str, Any],
    word_relations: dict[str, Any],
    batch: list[dict[str, str]],
    ledger: Ledger,
    batch_name: str,
) -> tuple[list[str], list[str], Ledger]:
    """vocab/cloze_root/satz_root/authorities/curriculum 을 제자리 수정.
    (계획 로그, 경고, 새 항목이 추가된 ledger) 반환. 오류는 SystemExit."""

    by_id = {row["id"]: row for row in vocab}
    packs: dict[str, list[dict[str, str]]] = OrderedDict()
    for row in vocab:
        packs.setdefault(row["pack_id"], []).append(row)

    vocab_pack_unit_map = curriculum.get("vocabPackUnitMap")
    if not isinstance(vocab_pack_unit_map, dict):
        raise SystemExit("curriculum_manifest.json: vocabPackUnitMap 이 object 가 아님")
    cloze_topic_unit_map = curriculum.get("clozeTopicUnitMap")
    if not isinstance(cloze_topic_unit_map, dict):
        raise SystemExit("curriculum_manifest.json: clozeTopicUnitMap 이 object 가 아님")

    cloze_items = cloze_root.get("items")
    satz_items = satz_root.get("items")
    if not isinstance(cloze_items, list) or not isinstance(satz_items, list):
        raise SystemExit("cloze.json/satz_sentences.json 는 items 배열이 필요")

    clusters = segments_doc.get("contentClusters")
    segments = segments_doc.get("segments")
    if not isinstance(clusters, list) or not isinstance(segments, list):
        raise SystemExit("can_do_segments.json: contentClusters/segments 배열 필요")
    clusters_by_id = {c["id"]: c for c in clusters}

    coverage = authorities.get("coverage")
    if not isinstance(coverage, dict):
        raise SystemExit("can_do_content_authorities.json: coverage 객체 필요")
    inherited = coverage.get("inheritedContentReferences")
    if not isinstance(inherited, list):
        raise SystemExit(
            "can_do_content_authorities.json: coverage.inheritedContentReferences 배열 필요"
        )

    plan: list[str] = []
    warnings: list[str] = []
    touched_sources: set[str] = set()
    stale_cloze_topic_candidates: set[tuple[str, str]] = set()
    moved_at = date.today().isoformat()

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
        reason = (entry.get("reason") or "").strip()
        if not reason:
            raise SystemExit(f"{vid}: reason 컬럼이 비어 있음 (ledger 필수)")
        target = entry["target_pack"].strip()
        target_rows = packs.get(target)
        if not target_rows:
            raise SystemExit(f"{vid}: target_pack '{target}' 이 존재하지 않음")
        target_levels = {r["level"].strip() for r in target_rows if r["id"] != vid}
        if target_levels != {new_level}:
            raise SystemExit(
                f"{vid}: target_pack '{target}' 레벨 {target_levels} ≠ {new_level}"
            )

        example_korean = row["example_korean"]
        korean = row["korean"]
        old_lc, new_lc = old_level.lower(), new_level.lower()

        target_base = pack_base(target)
        target_unit = vocab_pack_unit_map.get(target_base)
        if target_unit is None:
            raise SystemExit(
                f"{vid}: target_pack '{target}' (base {target_base!r}) 이 "
                "curriculum_manifest.json 의 vocabPackUnitMap 에 없음"
            )
        target_cluster = _find_cluster_containing(clusters_by_id, "vocabPack", target)
        if target_cluster is None:
            raise SystemExit(
                f"{vid}: target_pack '{target}' 를 직접 참조하는 contentCluster 가 없음"
            )
        target_segment = _segment_for_cluster(segments, target_cluster["id"])
        if target_segment is None:
            raise SystemExit(
                f"{vid}: cluster {target_cluster['id']!r} 를 소유한 segment 가 없음"
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
        ledger = _ledger_record(
            ledger, kind="vocab", entry_id=vid, to_level=new_lc,
            moved_at=moved_at, batch_name=batch_name, reason=reason,
        )

        # (1) satz_sentences.json 동기화.
        matched_satz = [
            item for item in satz_items
            if item.get("level") == old_lc and item.get("vocabKo") == korean
        ]
        for item in matched_satz:
            item["level"] = new_lc
            ledger = _ledger_record(
                ledger, kind="satz", entry_id=item["id"], to_level=new_lc,
                moved_at=moved_at, batch_name=batch_name, reason=reason,
            )
            plan.append(f"  satz {item['id']}: {old_lc} → {new_lc}")

        # (2) cloze.json 동기화 + curriculum_manifest.json 의
        # clozeTopicUnitMap 갱신 (relevel_bundle._migrate_curriculum_manifest
        # 의 add/prune 규칙과 동일 -- ContentValidator 가 모든 (level:topic)
        # 조합이 clozeTopicUnitMap 에 있는지 검사한다).
        matched_cloze = [
            item for item in cloze_items
            if item.get("level") == old_lc and item.get("fullKo") == example_korean
        ]
        for item in matched_cloze:
            item["level"] = new_lc
            ledger = _ledger_record(
                ledger, kind="cloze", entry_id=item["id"], to_level=new_lc,
                moved_at=moved_at, batch_name=batch_name, reason=reason,
            )
            plan.append(f"  cloze {item['id']}: {old_lc} → {new_lc}")
            topic = item.get("topic")
            if isinstance(topic, str) and topic:
                new_key = f"{new_lc}:{topic.lower()}"
                if new_key not in cloze_topic_unit_map:
                    cloze_topic_unit_map[new_key] = target_unit
                stale_cloze_topic_candidates.add((old_lc, topic))

        # (3) can_do_content_authorities.json 의 예속(inherited) 행 동기화.
        word_inherited = [r for r in inherited if r.get("sourceVocabId") == vid]
        for row_ref in word_inherited:
            row_ref["sourceId"] = target
            row_ref["level"] = new_lc
            row_ref["courseUnitId"] = target_unit
            row_ref["canDoSegmentId"] = target_segment["id"]
        if word_inherited:
            plan.append(
                f"  can_do inherited {len(word_inherited)}건: sourceId={target}, "
                f"courseUnitId={target_unit}, canDoSegmentId={target_segment['id']}"
                " (fingerprint 는 refresh_can_do_vocab_fingerprints.py 가 별도 갱신)"
            )

    moved_ids = {entry["id"].strip() for entry in batch}
    for cluster_id in sync_word_relation_levels(word_relations, by_id, moved_ids):
        plan.append(f"  word relation {cluster_id}: source level synchronized")

    # clozeTopicUnitMap 정리: (from_level, topic) 조합에 살아있는 cloze 항목이
    # 하나도 안 남았으면 그 키를 지운다 (다른 팩이 같은 topic 단어를 여전히
    # 그 레벨에서 쓸 수 있으므로, 이동 건별이 아니라 최종 cloze 목록 전체를
    # 다시 세어 판단 -- relevel_bundle._migrate_curriculum_manifest 와 동일).
    for from_level, topic in sorted(stale_cloze_topic_candidates):
        remaining = any(
            item.get("level") == from_level and item.get("topic") == topic
            for item in cloze_items
        )
        key = f"{from_level}:{topic.lower()}"
        if not remaining and key in cloze_topic_unit_map:
            del cloze_topic_unit_map[key]
            plan.append(f"  clozeTopicUnitMap 제거: {key}")

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

    _refresh_game_meta(cloze_root, "items")
    _refresh_game_meta(satz_root, "items")

    return plan, warnings, ledger


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
    for level in ["A1", "A2", "B1", "B2", "C1", "C2"]:
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
    # write_bytes, not write_text: Path.write_text() on Windows retranslates
    # every "\n" back into "\r\n" in text mode with no explicit `newline`
    # kwarg (the exact CRLF defect relevel_bundle.py's own `_write_json`
    # comment documents, T2.3-R1 STEP 1a) -- this file is `docs/data/*.md
    # text eol=lf` in .gitattributes, so it must be written LF-only here,
    # not rely on a later git-checkout normalization pass.
    content = "\n".join(lines) + "\n"
    path.write_bytes(content.encode("utf-8"))


def migrate(
    batch_path: Path,
    *,
    root: Path = REPO,
    ledger_path: Path = DEFAULT_LEDGER_PATH,
    apply: bool,
) -> tuple[list[str], list[str]]:
    """전체 트랜잭션: 배치를 읽어 `assets/data` 스테이지 사본 위에서
    `apply_batch`를 실행하고, `ContentValidator`로 깨끗함을 확인한 뒤에만
    (그리고 `apply=True` 일 때만) 실저장소/ledger/vocab_pack_map.md 를 쓴다
    (relevel_bundle.py 의 스테이징 패턴과 동일 -- 모듈 docstring 참고)."""

    ledger = relevel_ledger.load_ledger(ledger_path)
    batch = load_batch(batch_path)
    batch_name = batch_path.stem

    with tempfile.TemporaryDirectory(prefix="relevel-vocab-") as directory:
        stage = Path(directory) / "repo"
        shutil.copytree(root / "assets" / "data", stage / "assets" / "data")
        stage_manifest_dir = stage / "tools" / "content_factory"
        stage_manifest_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            root / "tools" / "content_factory" / "content_audit_manifest.json",
            stage_manifest_dir / "content_audit_manifest.json",
        )
        grammar_mirror_target = stage / "functions" / "analyze_korean_text" / "grammar_patterns.json"
        grammar_mirror_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            root / "functions" / "analyze_korean_text" / "grammar_patterns.json",
            grammar_mirror_target,
        )
        data = stage / "assets" / "data"

        vocab = load_vocab(data / "korean_vocab.csv")
        before_ids = [r["id"] for r in vocab]
        cloze_root = _read_json(data / "cloze.json")
        satz_root = _read_json(data / "satz_sentences.json")
        authorities = _read_json(data / "can_do_content_authorities.json")
        segments_doc = _read_json(data / "can_do_segments.json")
        curriculum = _read_json(data / "curriculum_manifest.json")
        word_relations = _read_json(data / "word_relations.json")

        plan, warnings, ledger = apply_batch(
            vocab,
            cloze_root=cloze_root,
            satz_root=satz_root,
            authorities=authorities,
            segments_doc=segments_doc,
            curriculum=curriculum,
            word_relations=word_relations,
            batch=batch,
            ledger=ledger,
            batch_name=batch_name,
        )

        after_ids = [r["id"] for r in vocab]
        if sorted(before_ids) != sorted(after_ids) or len(vocab) != len(before_ids):
            raise SystemExit("불변식 위반: id 집합/행수가 변했다 — 중단")

        write_vocab(vocab, data / "korean_vocab.csv")
        _write_json(data / "cloze.json", cloze_root)
        _write_json(data / "satz_sentences.json", satz_root)
        _write_json(data / "can_do_content_authorities.json", authorities)
        _write_json(data / "curriculum_manifest.json", curriculum)
        _write_json(data / "word_relations.json", word_relations)

        # T2.5: `check_can_do_consistency` 는 여기서 일부러 안 돌린다 -- 이
        # 함수는 sourceVocabFingerprintSha256 이 라이브 CSV 행과 일치하는지
        # 검사하는데, 이 스크립트는 fingerprint 를 의도적으로 그대로 둔다
        # (apply 후 refresh_can_do_vocab_fingerprints.py 가 별도로 재계산 --
        # 모듈 docstring 참고). ContentValidator 는 fingerprint 를 전혀
        # 검사하지 않으므로(grep 확인) 이 단계에서는 안전하다.
        content_issues = ContentValidator(stage, ledger=ledger).validate()
        if content_issues:
            detail = "\n".join(f"{issue.source}: {issue.message}" for issue in content_issues)
            raise SystemExit(f"스테이지 검증 실패:\n{detail}")

        grammar_offenders = check_target_level_grammar(
            ledger,
            batch_name=batch_name,
            vocab_by_id={row["id"]: row for row in vocab},
            cloze_by_id={item["id"]: item for item in cloze_root["items"]},
            satz_by_id={item["id"]: item for item in satz_root["items"]},
        )
        if grammar_offenders:
            detail = "\n".join(f"  {line}" for line in grammar_offenders)
            raise SystemExit(
                "이동한 문장이 목표 레벨 문법 상한을 넘는다 — 레벨만 옮기고 예문은 안 고침"
                f" (scan_grammar_level.py 재실행: python tools/content_factory/"
                f"scan_grammar_level.py --level <레벨>):\n{detail}"
            )

        print(f"배치 {batch_path.name}: {len(batch)}건")
        for line in plan:
            print("  " + line)
        for warning in warnings:
            print("  " + warning)

        if not apply:
            print("(dry-run — 적용하려면 --apply)")
            return plan, warnings

        real_data = root / "assets" / "data"
        stage_ledger = stage / "ledger.json"
        stage_pack_map = stage / "vocab_pack_map.md"
        ledger.save(stage_ledger)
        write_pack_map(vocab, stage_pack_map)
        outputs = [
            (data / name, real_data / name)
            for name in (
                "korean_vocab.csv", "cloze.json", "satz_sentences.json",
                "can_do_content_authorities.json", "curriculum_manifest.json",
                "word_relations.json",
            )
        ] + [
            (stage_ledger, ledger_path),
            (stage_pack_map, root / "docs" / "data" / "vocab_pack_map.md"),
        ]
        originals = {
            target: target.read_bytes() if target.exists() else None
            for _, target in outputs
        }
        attempted: list[Path] = []
        try:
            for source, target in outputs:
                # Include a partially written destination if copy2 raises.
                attempted.append(target)
                shutil.copy2(source, target)
        except BaseException as write_error:
            restore_errors: list[tuple[Path, Exception]] = []
            for target in reversed(attempted):
                original = originals[target]
                try:
                    if original is None:
                        target.unlink(missing_ok=True)
                    elif not target.exists() or target.read_bytes() != original:
                        target.write_bytes(original)
                except Exception as restore_error:
                    # A locked file must not prevent restoration of the rest.
                    restore_errors.append((target, restore_error))
            if restore_errors:
                # Keep originals outside the temporary stage, which is deleted
                # on exit. Never report successful rollback with lost bytes.
                recovery = Path(tempfile.mkdtemp(prefix="relevel-vocab-recovery-"))
                records = []
                for index, (target, error) in enumerate(restore_errors):
                    original = originals[target]
                    backup = f"{index}.original" if original is not None else None
                    if backup is not None:
                        (recovery / backup).write_bytes(original)
                    records.append({"path": str(target.resolve()), "original": backup, "error": str(error)})
                _write_json(recovery / "manifest.json", {"writeError": str(write_error), "unrestored": records})
                raise RuntimeError(
                    f"Write failed ({write_error}); could not restore "
                    f"{', '.join(str(path) for path, _ in restore_errors)}. "
                    f"Recovery originals: {recovery}"
                ) from write_error
            raise
        print(
            f"적용 완료 → {real_data / 'korean_vocab.csv'}, "
            f"{ledger_path}, {root / 'docs' / 'data' / 'vocab_pack_map.md'}"
        )
        print(
            "다음 단계: python tool/refresh_can_do_vocab_fingerprints.py "
            "(can_do_content_authorities.json 의 sourceVocabFingerprintSha256 갱신)"
        )
    return plan, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch", type=Path)
    parser.add_argument("--apply", action="store_true", help="실제로 파일에 쓴다")
    args = parser.parse_args()

    migrate(args.batch, apply=args.apply)
    return 0


if __name__ == "__main__":
    sys.exit(main())
