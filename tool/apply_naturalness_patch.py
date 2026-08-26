"""자연성 심사 id-키 패치 적용기 (Task 12 Part A / Step 1).

Task 3 프리필터(`docs/data/naturalness_candidates.md`) 를 사람이 검토하고,
Task 12 Step 2 LLM 심사 + Step 3 Jin 승인을 거쳐 나온 "승인분"을 실제
코퍼스(JSON/CSV) 에 반영하는 도구다. **이 스크립트 자체는 승인 게이트를
모른다** — 이미 승인된 patch.json 을 구조 불변·지정 필드만 바꿔 적용하는
기계적 최종 단계일 뿐이다. 리포트 작성(Step 2)·승인(Step 3)·실제 코퍼스
적용(승인 후)은 이 파일이 아니라 컨트롤러/별도 세션이 수행한다.

패치 형식
---------
JSON 배열, 각 원소는 정확히 3개 키:

    [{"id": "cloze_a1_0001", "file": "cloze", "fields": {"topic": "..."}}]

- `file` 은 `cloze` | `vocab` | `satz` 중 하나.
    - cloze  -> assets/data/cloze.json          (items[].id 매칭)
    - vocab  -> assets/data/korean_vocab.csv    (id 컬럼 매칭)
    - satz   -> assets/data/satz_sentences.json (items[].id 매칭)
- `fields` 는 해당 파일 타입에서 이미 알려진 필드 이름만 허용한다(아래
  `ALLOWED_FIELDS`). `id` 자체는 매칭 키라 패치 대상이 될 수 없다.
- `--level-only` 를 주면 `fields` 는 정확히 `{"level": ...}` 만 허용한다
  (검수 16 계약 — 레벨 재분류 배치는 다른 필드를 절대 건드리지 않는다).

안전 계약
---------
- 패치 전체를 먼저 검증한다(알 수 없는 id/필드/타입/level-only 위반을 전부
  모아서 보고) — 하나라도 있으면 **아무 파일도 쓰지 않는다**(전부-거부,
  부분 적용 없음).
- `--dry-run` 은 검증 + "무엇이 바뀔지" 출력까지만 하고 파일을 쓰지 않는다.
- 구조 보존: JSON 은 `json.dumps(data, ensure_ascii=False, indent=2) + "\\n"`
  (기존 cloze.json/satz_sentences.json 과 바이트 단위로 동일한 직렬화 —
  round-trip 검증됨), CSV 는 `csv.writer(..., quoting=csv.QUOTE_MINIMAL,
  lineterminator="\\n")` 로 컬럼 순서 고정(`tool/relevel_vocab.py` 와 동일
  관례). 지정 필드의 **값만** 바뀌고 그 외 키/행/컬럼/순서/따옴표 관례는
  그대로다.
- 실제 적용(dry-run 아님) 후에는 `flutter test test/cloze_content_guard_test.dart`
  실행 안내를 출력한다.

`--self-test`
-------------
실제 파일을 임시 디렉터리에 **복사**한 뒤 그 사본에만 합성 패치를 적용해
검증한다 — 실제 `assets/data/*` 는 read-only 로만 열어보고(복사를 위해),
절대 쓰지 않는다. 무변경 재직렬화가 원본과 바이트 동일한지, 지정 필드만
바뀌고 나머지는 완전히 동일한지, `--level-only`/미지 id/미지 필드/
`--dry-run`/부분-적용-거부 계약이 전부 지켜지는지 검사한다. 하나라도
실패하면 0 이 아닌 코드로 종료한다.

사용:
    python tool/apply_naturalness_patch.py --self-test
    python tool/apply_naturalness_patch.py --patch patch.json --dry-run
    python tool/apply_naturalness_patch.py --patch patch.json
    python tool/apply_naturalness_patch.py --patch level_batch.json --level-only
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
import shutil
import sys
import tempfile
from dataclasses import dataclass, field as dc_field
from typing import Optional

# ---------------------------------------------------------------------------
# 경로 (tool/audit_content_naturalness.py 와 동일한 ROOT 계산 관례)
# ---------------------------------------------------------------------------

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(ROOT, "assets", "data")

CLOZE_PATH = os.path.join(DATA_DIR, "cloze.json")
VOCAB_PATH = os.path.join(DATA_DIR, "korean_vocab.csv")
SATZ_PATH = os.path.join(DATA_DIR, "satz_sentences.json")

DEFAULT_PATHS = {"cloze": CLOZE_PATH, "vocab": VOCAB_PATH, "satz": SATZ_PATH}

# vocab CSV 컬럼 순서 — tool/relevel_vocab.py:COLUMNS 와 동일(15컬럼, id 마지막).
VOCAB_COLUMNS = [
    "korean", "romanization", "german", "level", "pos_de",
    "example_korean", "example_german", "topic",
    "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]

# 파일 타입별 패치 가능 필드 — "id" 는 매칭 키라 의도적으로 제외.
CLOZE_FIELDS = {
    "level", "sentenceKo", "answer", "fullKo", "de", "en", "distractors",
    "topic", "canonicalScenarioId", "conceptIds", "courseUnitId",
    "sourceSeedId",
}
SATZ_FIELDS = {
    "level", "targetKo", "promptDe", "promptEn", "distractors", "vocabKo",
    "canonicalScenarioId", "conceptIds", "courseUnitId", "sourceSeedId",
}
VOCAB_FIELDS = set(VOCAB_COLUMNS) - {"id"}

ALLOWED_FIELDS = {"cloze": CLOZE_FIELDS, "satz": SATZ_FIELDS, "vocab": VOCAB_FIELDS}

# 리스트(문자열 배열) 값이 기대되는 필드 — 그 외 JSON 필드는 전부 문자열 기대.
LIST_FIELDS = {
    "cloze": {"distractors", "conceptIds"},
    "satz": {"distractors", "conceptIds"},
    "vocab": set(),
}

GUARD_TEST_HINT = "flutter test test/cloze_content_guard_test.dart"


# ---------------------------------------------------------------------------
# 오류
# ---------------------------------------------------------------------------


class PatchError(Exception):
    """패치 검증 실패 — errors 는 사람이 읽을 오류 문자열 목록(전부 모아서)."""

    def __init__(self, errors: list):
        super().__init__("; ".join(errors) if errors else "패치 오류")
        self.errors = list(errors)


# ---------------------------------------------------------------------------
# 패치 항목
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class PatchEntry:
    file: str
    id: str
    fields: dict = dc_field(default_factory=dict)


def load_patch_entries(patch_path: str) -> list:
    """패치 JSON 파일을 읽어 구조적으로 검증된 PatchEntry 리스트를 돌려준다.

    오류가 하나라도 있으면 전부 모아서 PatchError 로 던진다(부분 정보로
    진행하지 않음).
    """
    try:
        with open(patch_path, encoding="utf-8") as f:
            raw = json.load(f)
    except OSError as exc:
        raise PatchError([f"패치 파일을 열 수 없음: {patch_path} ({exc})"])
    except json.JSONDecodeError as exc:
        raise PatchError([f"패치 JSON 파싱 실패: {patch_path}: {exc}"])

    if not isinstance(raw, list):
        raise PatchError([f"패치 파일 최상위는 JSON 배열([...])이어야 함: {patch_path}"])

    errors = []
    entries = []
    seen = set()

    for i, raw_entry in enumerate(raw):
        prefix = f"entry[{i}]"
        if not isinstance(raw_entry, dict):
            errors.append(f"{prefix}: 객체(dict)가 아님")
            continue

        extra_keys = sorted(set(raw_entry.keys()) - {"id", "file", "fields"})
        missing_keys = sorted({"id", "file", "fields"} - set(raw_entry.keys()))
        if extra_keys:
            errors.append(f"{prefix}: 알 수 없는 최상위 키 {extra_keys} (허용: id/file/fields)")
        if missing_keys:
            errors.append(f"{prefix}: 필수 키 누락 {missing_keys}")
        if extra_keys or missing_keys:
            continue

        entry_id = raw_entry["id"]
        entry_file = raw_entry["file"]
        entry_fields = raw_entry["fields"]

        if not isinstance(entry_id, str) or not entry_id.strip():
            errors.append(f"{prefix}: id 는 비어있지 않은 문자열이어야 함 (got {entry_id!r})")
            continue
        if entry_file not in ALLOWED_FIELDS:
            errors.append(
                f"{prefix} (id={entry_id}): file 값 {entry_file!r} 은(는)"
                f" {sorted(ALLOWED_FIELDS)} 중 하나여야 함"
            )
            continue
        if not isinstance(entry_fields, dict) or not entry_fields:
            errors.append(f"{prefix} (id={entry_id}): fields 는 비어있지 않은 객체여야 함")
            continue

        key = (entry_file, entry_id)
        if key in seen:
            errors.append(
                f"{prefix}: 패치 안에서 동일 대상 중복 (file={entry_file}, id={entry_id})"
                " — 같은 id 는 한 번만 등장해야 함"
            )
            continue
        seen.add(key)
        entries.append(PatchEntry(file=entry_file, id=entry_id, fields=dict(entry_fields)))

    if errors:
        raise PatchError(errors)
    return entries


def _validate_value_type(file_type: str, field_name: str, value) -> Optional[str]:
    if file_type == "vocab":
        if not isinstance(value, str):
            return f"vocab CSV 필드 값은 문자열이어야 함 (got {type(value).__name__})"
        return None
    if field_name in LIST_FIELDS.get(file_type, set()):
        if not isinstance(value, list) or not all(isinstance(v, str) for v in value):
            return "리스트(문자열 원소) 값이어야 함"
        return None
    if not isinstance(value, str):
        return f"문자열 값이어야 함 (got {type(value).__name__})"
    return None


def validate_fields(entries: list, level_only: bool) -> None:
    """필드 이름 화이트리스트 + `--level-only` 계약 + 값 타입을 검증.

    오류가 하나라도 있으면 전부 모아 PatchError 로 던진다.
    """
    errors = []
    for e in entries:
        allowed = ALLOWED_FIELDS[e.file]
        unknown = sorted(set(e.fields) - allowed)
        if "id" in unknown:
            errors.append(f"{e.file}:{e.id}: 'id' 는 매칭 키라 패치 필드로 쓸 수 없음")
            unknown = [u for u in unknown if u != "id"]
        if unknown:
            errors.append(
                f"{e.file}:{e.id}: 알 수 없는 필드 {unknown} (허용: {sorted(allowed)})"
            )
            continue

        if level_only and set(e.fields) != {"level"}:
            rejected = sorted(set(e.fields) - {"level"})
            errors.append(
                f"{e.file}:{e.id}: --level-only 모드에서는 level 필드만 허용"
                f" (거부된 필드: {rejected})"
            )
            continue

        for fname, value in e.fields.items():
            err = _validate_value_type(e.file, fname, value)
            if err:
                errors.append(f"{e.file}:{e.id}.{fname}: {err}")

    if errors:
        raise PatchError(errors)


# ---------------------------------------------------------------------------
# 파일 로더/라이터 — 구조 보존 직렬화
# ---------------------------------------------------------------------------


def _atomic_write_text(path: str, text: str) -> None:
    tmp = path + ".tmp-apply-naturalness-patch"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    os.replace(tmp, path)


class JsonItemsFile:
    """cloze.json / satz_sentences.json 공통 — 최상위 {"meta":..., "items":[...]}."""

    def __init__(self, path: str):
        self.path = path
        with open(path, encoding="utf-8") as f:
            self.data = json.load(f)
        items = self.data.get("items")
        if not isinstance(items, list):
            raise PatchError([f"{path}: 최상위 'items' 리스트 없음"])
        self.items = items
        self.index = {}
        for item in self.items:
            iid = item.get("id") if isinstance(item, dict) else None
            if iid and iid not in self.index:
                self.index[iid] = item

    def get(self, item_id: str):
        return self.index.get(item_id)

    def write(self) -> None:
        # round-trip 검증됨: 무변경 시 원본과 바이트 단위로 동일(self-test 참고).
        text = json.dumps(self.data, ensure_ascii=False, indent=2) + "\n"
        _atomic_write_text(self.path, text)


class VocabCsvFile:
    """korean_vocab.csv — id 컬럼으로 매칭, 컬럼 순서/따옴표 관례 고정."""

    def __init__(self, path: str):
        self.path = path
        with open(path, encoding="utf-8", newline="") as f:
            reader = csv.reader(f)
            try:
                header = next(reader)
            except StopIteration:
                header = []
            self.header = header
            self.rows = [dict(zip(header, r)) for r in reader if r]
        if self.header != VOCAB_COLUMNS:
            raise PatchError([f"{path}: CSV 헤더가 예상과 다름: {self.header}"])
        self.index = {}
        for row in self.rows:
            rid = row.get("id")
            if rid and rid not in self.index:
                self.index[rid] = row

    def get(self, item_id: str):
        return self.index.get(item_id)

    def write(self) -> None:
        buf = io.StringIO(newline="")
        writer = csv.writer(buf, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        writer.writerow(self.header)
        for row in self.rows:
            writer.writerow([row[c] for c in self.header])
        _atomic_write_text(self.path, buf.getvalue())


FILE_CLASSES = {"cloze": JsonItemsFile, "satz": JsonItemsFile, "vocab": VocabCsvFile}


def load_targets(files_needed, targets_override: Optional[dict] = None) -> dict:
    override = targets_override or {}
    loaded = {}
    for f in sorted(files_needed):
        path = override.get(f, DEFAULT_PATHS[f])
        loaded[f] = FILE_CLASSES[f](path)
    return loaded


# ---------------------------------------------------------------------------
# 해석(id 존재 확인) + 계획 + 적용
# ---------------------------------------------------------------------------


def resolve_entries(entries: list, loaded: dict) -> list:
    """각 PatchEntry 를 실제 항목(dict/row)에 매칭. 미지 id 는 전부 모아 거부."""
    unknown_by_file = {}
    resolved = []
    for e in entries:
        target = loaded[e.file].get(e.id)
        if target is None:
            unknown_by_file.setdefault(e.file, []).append(e.id)
            continue
        resolved.append((e, target))
    if unknown_by_file:
        errors = []
        for f in sorted(unknown_by_file):
            ids = sorted(unknown_by_file[f])
            errors.append(f"{f}: 알 수 없는 id {len(ids)}건 — {ids}")
        raise PatchError(errors)
    return resolved


def build_plan(resolved: list) -> list:
    """(file, id, field, old, new) 튜플 리스트, 결정적 정렬."""
    plan = []
    for e, target in resolved:
        for fname in sorted(e.fields):
            old = target.get(fname)
            plan.append((e.file, e.id, fname, old, e.fields[fname]))
    plan.sort(key=lambda t: (t[0], t[1], t[2]))
    return plan


def apply_changes(resolved: list, loaded: dict) -> None:
    for e, target in resolved:
        for fname, value in e.fields.items():
            target[fname] = value
    for f in sorted(loaded):
        loaded[f].write()


def run_patch(
    patch_path: str,
    level_only: bool = False,
    dry_run: bool = False,
    targets_override: Optional[dict] = None,
):
    """패치 전체 파이프라인. 성공 시 (plan, applied) 를 돌려준다.

    검증 실패(구조/필드명/level-only/타입/미지 id) 는 전부 PatchError 로
    던져진다 — 그 시점까지 어떤 파일도 쓰지 않았음이 보장된다(대상 파일은
    읽기만 함). dry_run=True 면 검증까지만 하고 applied=False 로 돌아온다.
    """
    entries = load_patch_entries(patch_path)
    validate_fields(entries, level_only)
    if not entries:
        return [], False

    files_needed = {e.file for e in entries}
    loaded = load_targets(files_needed, targets_override)
    resolved = resolve_entries(entries, loaded)
    plan = build_plan(resolved)

    if dry_run:
        return plan, False

    apply_changes(resolved, loaded)
    return plan, True


# ---------------------------------------------------------------------------
# self-test — 실제 assets/data/* 는 절대 쓰지 않는다(읽어서 임시 사본만 만듦)
# ---------------------------------------------------------------------------


def _read(path: str) -> str:
    with open(path, encoding="utf-8", newline="") as f:
        return f.read()


def _reset_tmp(tmp_paths: dict, pristine: dict) -> None:
    for key, path in tmp_paths.items():
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(pristine[key])


def _write_json_patch(tmpdir: str, name: str, patch: list) -> str:
    path = os.path.join(tmpdir, name)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(patch, f, ensure_ascii=False)
    return path


def _diff_json_items_single_change(orig: dict, new: dict, target_id: str, expected: dict, label: str) -> list:
    problems = []
    if orig.get("meta") != new.get("meta"):
        problems.append(f"{label}: meta 변경됨")
    orig_items = orig.get("items", [])
    new_items = new.get("items", [])
    if len(orig_items) != len(new_items):
        problems.append(f"{label}: item 개수 변경 {len(orig_items)}->{len(new_items)}")
        return problems
    for i, (oi, ni) in enumerate(zip(orig_items, new_items)):
        if oi.get("id") != ni.get("id"):
            problems.append(f"{label}: index {i} id 순서/값 변경")
            continue
        if oi.get("id") != target_id:
            if oi != ni:
                problems.append(f"{label}: {oi.get('id')} 항목이 패치 대상이 아닌데 변경됨")
            continue
        if list(oi.keys()) != list(ni.keys()):
            problems.append(
                f"{label}: {target_id} 키 순서/집합 변경 {list(oi.keys())} -> {list(ni.keys())}"
            )
        for k in oi:
            if k in expected:
                if ni.get(k) != expected[k]:
                    problems.append(f"{label}: {target_id}.{k} 기대값 아님 (got {ni.get(k)!r})")
            elif oi.get(k) != ni.get(k):
                problems.append(f"{label}: {target_id}.{k} 의도치 않게 변경됨")
    return problems


def _parse_csv_text(text: str) -> list:
    reader = csv.reader(io.StringIO(text))
    header = next(reader)
    return [dict(zip(header, r)) for r in reader if r]


def _diff_csv_rows_single_change(orig_text: str, new_text: str, target_id: str, expected: dict) -> list:
    problems = []
    orig_rows = _parse_csv_text(orig_text)
    new_rows = _parse_csv_text(new_text)
    if len(orig_rows) != len(new_rows):
        problems.append(f"vocab: 행 개수 변경 {len(orig_rows)}->{len(new_rows)}")
        return problems
    for oi, ni in zip(orig_rows, new_rows):
        if oi.get("id") != ni.get("id"):
            problems.append("vocab: id 순서 변경")
            continue
        if oi.get("id") != target_id:
            if oi != ni:
                problems.append(f"vocab: {oi.get('id')} 행이 패치 대상이 아닌데 변경됨")
            continue
        for k in oi:
            if k in expected:
                if ni.get(k) != expected[k]:
                    problems.append(f"vocab: {target_id}.{k} 기대값 아님 (got {ni.get(k)!r})")
            elif oi.get(k) != ni.get(k):
                problems.append(f"vocab: {target_id}.{k} 의도치 않게 변경됨")
    return problems


def _line_diff_check(orig_text: str, new_text: str, expected_changed_lines: int, must_contain: list) -> list:
    problems = []
    orig_lines = orig_text.splitlines()
    new_lines = new_text.splitlines()
    if len(orig_lines) != len(new_lines):
        problems.append(f"라인 수 변경 {len(orig_lines)}->{len(new_lines)}")
        return problems
    diffs = [i for i in range(len(orig_lines)) if orig_lines[i] != new_lines[i]]
    if len(diffs) != expected_changed_lines:
        problems.append(
            f"변경된 라인 수 기대와 다름: {len(diffs)}건 (기대 {expected_changed_lines}건), at {diffs[:5]}"
        )
    for i in diffs:
        if not any(token in new_lines[i] for token in must_contain):
            problems.append(f"라인 {i} 변경이 예상 필드({must_contain}) 관련이 아닌 것으로 보임: {new_lines[i]!r}")
    return problems


def _check_roundtrip_identity(tmp_paths: dict, pristine: dict, tmpdir: str):
    _reset_tmp(tmp_paths, pristine)
    problems = []
    for key in ("cloze", "satz"):
        JsonItemsFile(tmp_paths[key]).write()
        if _read(tmp_paths[key]) != pristine[key]:
            problems.append(f"{key}: 무변경 재직렬화가 원본과 바이트 불일치")
    VocabCsvFile(tmp_paths["vocab"]).write()
    if _read(tmp_paths["vocab"]) != pristine["vocab"]:
        problems.append("vocab: 무변경 재직렬화가 원본과 바이트 불일치")
    _reset_tmp(tmp_paths, pristine)
    return (
        "무변경 재직렬화 == 원본 바이트 (JSON indent=2/LF, CSV QUOTE_MINIMAL/LF)",
        not problems,
        "; ".join(problems) or None,
    )


def _check_synthetic_patch_apply(tmp_paths: dict, pristine: dict, tmpdir: str):
    _reset_tmp(tmp_paths, pristine)
    patch = [
        {"id": "cloze_a1_0001", "file": "cloze", "fields": {"topic": "SELFTEST_TOPIC", "en": "SELFTEST EN VALUE"}},
        {"id": "satz_a1_0001", "file": "satz", "fields": {"promptDe": "SELFTEST DE VALUE"}},
        {"id": "vocab_a1_0001", "file": "vocab", "fields": {"topic": "SELFTEST_TOPIC_VOCAB"}},
    ]
    patch_path = _write_json_patch(tmpdir, "selftest_patch_ok.json", patch)

    problems = []
    try:
        plan, applied = run_patch(patch_path, level_only=False, dry_run=False, targets_override=tmp_paths)
        if not applied:
            problems.append("applied=False (실제 적용 모드인데 적용 안 됨)")
        if len(plan) != 4:  # cloze 2필드 + satz 1필드 + vocab 1필드
            problems.append(f"plan 길이 예상과 다름: {len(plan)} (기대 4)")
    except PatchError as exc:
        return ("합성 패치 적용(3파일 동시) — 지정 필드만 변경, 구조 보존", False, f"예상 밖 거부: {exc.errors}")

    orig_cloze = json.loads(pristine["cloze"])
    new_cloze = json.loads(_read(tmp_paths["cloze"]))
    problems += _diff_json_items_single_change(
        orig_cloze, new_cloze, "cloze_a1_0001",
        {"topic": "SELFTEST_TOPIC", "en": "SELFTEST EN VALUE"}, "cloze",
    )

    orig_satz = json.loads(pristine["satz"])
    new_satz = json.loads(_read(tmp_paths["satz"]))
    problems += _diff_json_items_single_change(
        orig_satz, new_satz, "satz_a1_0001", {"promptDe": "SELFTEST DE VALUE"}, "satz",
    )

    problems += _diff_csv_rows_single_change(
        pristine["vocab"], _read(tmp_paths["vocab"]), "vocab_a1_0001", {"topic": "SELFTEST_TOPIC_VOCAB"},
    )

    problems += _line_diff_check(
        pristine["cloze"], _read(tmp_paths["cloze"]), expected_changed_lines=2, must_contain=["topic", "en"],
    )
    problems += _line_diff_check(
        pristine["satz"], _read(tmp_paths["satz"]), expected_changed_lines=1, must_contain=["promptDe"],
    )

    _reset_tmp(tmp_paths, pristine)
    return (
        "합성 패치 적용(3파일 동시) — 지정 필드만 변경, 나머지 완전 동일(구조 보존)",
        not problems,
        "; ".join(problems) or None,
    )


def _check_level_only_contract(tmp_paths: dict, pristine: dict, tmpdir: str):
    _reset_tmp(tmp_paths, pristine)
    problems = []

    bad_patch = [{"id": "cloze_a1_0001", "file": "cloze", "fields": {"level": "a2", "topic": "X"}}]
    bad_path = _write_json_patch(tmpdir, "selftest_patch_level_only_bad.json", bad_patch)
    try:
        run_patch(bad_path, level_only=True, dry_run=False, targets_override=tmp_paths)
        problems.append("level 외 필드 포함 패치가 --level-only 에서 거부되지 않음")
    except PatchError:
        pass
    if _read(tmp_paths["cloze"]) != pristine["cloze"]:
        problems.append("거부된 패치인데 cloze.json 이 변경됨")

    good_patch = [{"id": "cloze_a1_0001", "file": "cloze", "fields": {"level": "a1"}}]
    good_path = _write_json_patch(tmpdir, "selftest_patch_level_only_good.json", good_patch)
    try:
        plan, applied = run_patch(good_path, level_only=True, dry_run=False, targets_override=tmp_paths)
        if not applied or len(plan) != 1:
            problems.append("level 단독 필드 패치가 --level-only 에서 정상 적용되지 않음")
    except PatchError as exc:
        problems.append(f"level 단독 필드 패치가 잘못 거부됨: {exc.errors}")

    _reset_tmp(tmp_paths, pristine)
    return (
        "--level-only 계약 (level 외 필드 거부, level 단독은 허용)",
        not problems,
        "; ".join(problems) or None,
    )


def _check_unknown_id_rejected(tmp_paths: dict, pristine: dict, tmpdir: str):
    _reset_tmp(tmp_paths, pristine)
    patch = [{"id": "cloze_does_not_exist_9999", "file": "cloze", "fields": {"topic": "X"}}]
    path = _write_json_patch(tmpdir, "selftest_patch_unknown_id.json", patch)
    problems = []
    try:
        run_patch(path, level_only=False, dry_run=False, targets_override=tmp_paths)
        problems.append("존재하지 않는 id 가 거부되지 않음")
    except PatchError as exc:
        if not any("cloze_does_not_exist_9999" in e for e in exc.errors):
            problems.append(f"오류 메시지에 문제 id 가 나열되지 않음: {exc.errors}")
    if _read(tmp_paths["cloze"]) != pristine["cloze"]:
        problems.append("거부된 패치인데 cloze.json 이 변경됨")
    return ("알 수 없는 id 거부 + 무변경(no partial write)", not problems, "; ".join(problems) or None)


def _check_unknown_field_rejected(tmp_paths: dict, pristine: dict, tmpdir: str):
    _reset_tmp(tmp_paths, pristine)
    patch = [{"id": "vocab_a1_0001", "file": "vocab", "fields": {"bogus_column_xyz": "X"}}]
    path = _write_json_patch(tmpdir, "selftest_patch_unknown_field.json", patch)
    problems = []
    try:
        run_patch(path, level_only=False, dry_run=False, targets_override=tmp_paths)
        problems.append("알 수 없는 필드가 거부되지 않음")
    except PatchError as exc:
        if not any("bogus_column_xyz" in e for e in exc.errors):
            problems.append(f"오류 메시지에 문제 필드가 나열되지 않음: {exc.errors}")
    if _read(tmp_paths["vocab"]) != pristine["vocab"]:
        problems.append("거부된 패치인데 korean_vocab.csv 가 변경됨")
    return ("알 수 없는 필드명 거부 + 무변경", not problems, "; ".join(problems) or None)


def _check_dry_run_no_write(tmp_paths: dict, pristine: dict, tmpdir: str):
    _reset_tmp(tmp_paths, pristine)
    patch = [{"id": "satz_a1_0001", "file": "satz", "fields": {"promptEn": "DRYRUN SHOULD NOT APPLY"}}]
    path = _write_json_patch(tmpdir, "selftest_patch_dry_run.json", patch)
    problems = []
    try:
        plan, applied = run_patch(path, level_only=False, dry_run=True, targets_override=tmp_paths)
        if applied:
            problems.append("dry-run 인데 applied=True")
        if len(plan) != 1:
            problems.append(f"plan 길이 예상과 다름: {len(plan)} (기대 1)")
    except PatchError as exc:
        problems.append(f"정상 패치가 dry-run 에서 거부됨: {exc.errors}")
    if _read(tmp_paths["satz"]) != pristine["satz"]:
        problems.append("dry-run 인데 satz_sentences.json 이 변경됨")
    return ("--dry-run 은 검증만 하고 파일을 쓰지 않음", not problems, "; ".join(problems) or None)


def _check_partial_write_refused(tmp_paths: dict, pristine: dict, tmpdir: str):
    _reset_tmp(tmp_paths, pristine)
    patch = [
        {"id": "cloze_a1_0001", "file": "cloze", "fields": {"topic": "SHOULD_NOT_APPLY"}},
        {"id": "cloze_does_not_exist_9999", "file": "cloze", "fields": {"topic": "X"}},
    ]
    path = _write_json_patch(tmpdir, "selftest_patch_partial.json", patch)
    problems = []
    try:
        run_patch(path, level_only=False, dry_run=False, targets_override=tmp_paths)
        problems.append("유효 항목 + 무효 id 가 섞인 패치가 거부되지 않음")
    except PatchError:
        pass
    if _read(tmp_paths["cloze"]) != pristine["cloze"]:
        problems.append("부분 적용 발생 — cloze.json 이 변경됨(전부-거부 원칙 위반)")
    return (
        "전부-거부 원칙 (유효 항목이 섞여 있어도 무효 id 가 있으면 전체 거부)",
        not problems,
        "; ".join(problems) or None,
    )


def run_self_test() -> bool:
    all_ok = True
    with tempfile.TemporaryDirectory(prefix="apply_naturalness_patch_selftest_") as tmpdir:
        tmp_paths = {}
        for key, real_path in DEFAULT_PATHS.items():
            dest = os.path.join(tmpdir, os.path.basename(real_path))
            shutil.copy2(real_path, dest)  # 실제 파일은 여기서 읽기만 함(복사원)
            tmp_paths[key] = dest
        pristine = {key: _read(path) for key, path in tmp_paths.items()}

        checks = [
            _check_roundtrip_identity(tmp_paths, pristine, tmpdir),
            _check_synthetic_patch_apply(tmp_paths, pristine, tmpdir),
            _check_level_only_contract(tmp_paths, pristine, tmpdir),
            _check_unknown_id_rejected(tmp_paths, pristine, tmpdir),
            _check_unknown_field_rejected(tmp_paths, pristine, tmpdir),
            _check_dry_run_no_write(tmp_paths, pristine, tmpdir),
            _check_partial_write_refused(tmp_paths, pristine, tmpdir),
        ]
        for name, ok, detail in checks:
            status = "PASS" if ok else "FAIL"
            print(f"[self-test] {status} — {name}" + (f" :: {detail}" if detail else ""))
            if not ok:
                all_ok = False

    print(f"[self-test] {'전체 통과 (real 파일 미접촉, 임시 사본에서만 검증)' if all_ok else '실패 있음'}")
    return all_ok


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _fmt_value(v) -> str:
    if isinstance(v, list):
        return "[" + ", ".join(v) + "]"
    return str(v)


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--patch", help="패치 JSON 파일 경로 (--self-test 없으면 필수)")
    parser.add_argument("--dry-run", action="store_true", help="검증 + 변경 예정 내역만 출력, 파일 쓰지 않음")
    parser.add_argument(
        "--level-only", action="store_true",
        help="fields 가 level 외 다른 키를 포함하면 거부(검수 16 계약)",
    )
    parser.add_argument("--self-test", action="store_true", help="임시 사본으로 자가 테스트 실행 후 종료")
    return parser


def main(argv=None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)

    if args.self_test:
        return 0 if run_self_test() else 1

    if not args.patch:
        parser.error("--patch 가 필요합니다 (또는 --self-test)")

    try:
        plan, applied = run_patch(args.patch, level_only=args.level_only, dry_run=args.dry_run)
    except PatchError as exc:
        print("[apply_naturalness_patch] 패치 거부 — 아무 파일도 쓰지 않음:")
        for line in exc.errors:
            print(f"  - {line}")
        return 1

    if not plan:
        print("[apply_naturalness_patch] 패치에 적용할 항목이 없음(entries 0건) — 아무 파일도 건드리지 않음")
        return 0

    n_items = len({(f, i) for f, i, _fname, _old, _new in plan})
    label = "DRY-RUN (검증만, 파일 미변경)" if not applied else "적용 완료"
    print(f"[apply_naturalness_patch] {label} — 항목 {n_items}개, 필드 {len(plan)}개")
    for file_, id_, fname, old, new in plan:
        print(f"  {file_}:{id_}.{fname}: {_fmt_value(old)!r} -> {_fmt_value(new)!r}")

    if applied:
        print()
        print(f"[apply_naturalness_patch] 다음을 실행해 확인: {GUARD_TEST_HINT}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
