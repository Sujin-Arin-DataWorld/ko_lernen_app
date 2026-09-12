"""Inventory actual contextual passages without making semantic claims."""

from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any


LEVELS = frozenset({"a1", "a2", "b1", "b2", "c1", "c2"})
SCENARIO_LEVELS = tuple(sorted(LEVELS))
DATA_RELATIVE = Path("assets") / "data"


def _safe_path(root: Path, relative: Path, *, required: bool) -> Path | None:
    root = root.resolve()
    path = root / relative
    resolved = path.resolve(strict=False)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ValueError(f"source path escapes root: {relative}") from exc
    if required and not path.is_file():
        raise FileNotFoundError(path)
    if not required and not path.exists():
        return None
    if not path.is_file():
        raise ValueError(f"source is not a file: {relative}")
    return path


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"malformed JSON: {path}") from exc


def _level(value: Any, location: str) -> str:
    if not isinstance(value, str) or value.strip().lower() not in LEVELS:
        raise ValueError(f"invalid authored level at {location}: {value!r}")
    return value


def _nonempty_string(value: Any, location: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"expected nonempty string at {location}")
    return value


def _string_list(value: Any, location: str) -> list[str]:
    if not isinstance(value, list) or any(not isinstance(item, str) for item in value):
        raise ValueError(f"expected string list at {location}")
    return value


def _pointer(*parts: int | str) -> str:
    def escape(part: int | str) -> str:
        return str(part).replace("~", "~0").replace("/", "~1")

    return "/" + "/".join(escape(part) for part in parts)


def _passage(
    source_path: str,
    record_id: str,
    level: str,
    pointer: str,
    text: str,
) -> dict[str, str]:
    return {
        "sourcePath": source_path,
        "recordId": record_id,
        "level": level,
        "jsonPointer": pointer,
        "text": text,
    }


def build_inventory(root: Path) -> dict[str, Any]:
    """Build a deterministic inventory from the repository's actual data files.

    Grammar annotations are intentionally only candidate metadata.  This function
    never decides that a grammar form occurs in a passage.
    """

    root = Path(root)
    grammar_relative = DATA_RELATIVE / "grammar.csv"
    grammar_path = _safe_path(root, grammar_relative, required=True)
    assert grammar_path is not None
    known_ids: set[str] = set()
    try:
        with grammar_path.open("r", encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream)
            if not reader.fieldnames or not {"id", "level"} <= set(reader.fieldnames):
                raise ValueError("grammar.csv must contain id and level columns")
            for row_number, row in enumerate(reader, start=2):
                grammar_id = _nonempty_string(row.get("id"), f"grammar.csv:{row_number}:id")
                _level(row.get("level"), f"grammar.csv:{row_number}:level")
                if grammar_id in known_ids:
                    raise ValueError(f"duplicate grammar ID: {grammar_id}")
                known_ids.add(grammar_id)
    except (OSError, UnicodeError) as exc:
        raise ValueError("malformed grammar.csv") from exc

    passages: list[dict[str, str]] = []
    declarations: list[tuple[str, dict[str, str]]] = []
    unknown: list[dict[str, str]] = []
    seen_ids: set[str] = set()
    missing_optional: list[str] = []

    def add_record(
        record: dict[str, Any],
        source_path: str,
        index: int,
        *,
        media: bool,
        level_hint: str | None = None,
    ) -> None:
        record_id = _nonempty_string(record.get("id"), f"{source_path}{_pointer(index, 'id')}")
        if record_id in seen_ids:
            raise ValueError(f"duplicate record ID: {record_id}")
        seen_ids.add(record_id)
        level = _level(record.get("level"), f"{source_path}{_pointer(index, 'level')}")
        if level_hint is not None and level.lower() != level_hint:
            raise ValueError(f"record level does not match source shard: {record_id}")
        grammar_key = "grammar_ids" if media else "grammarIds"
        grammar_ids = _string_list(
            record.get(grammar_key, []),
            f"{source_path}{_pointer(index, grammar_key)}",
        )
        record_passages: list[dict[str, str]] = []
        if media:
            text = record.get("korean")
            if not isinstance(text, str):
                raise ValueError(f"expected korean text at {source_path}{_pointer(index, 'korean')}")
            if text.strip():
                record_passages.append(
                    _passage(source_path, record_id, level, _pointer("phrases", index, "korean"), text)
                )
        else:
            dialog = record.get("dialog")
            if not isinstance(dialog, list):
                raise ValueError(f"expected dialog list at {source_path}{_pointer(index, 'dialog')}")
            for dialog_index, turn in enumerate(dialog):
                if not isinstance(turn, dict):
                    raise ValueError(f"expected dialog record at {source_path}{_pointer(index, 'dialog', dialog_index)}")
                text = turn.get("ko")
                if not isinstance(text, str):
                    raise ValueError(
                        f"expected dialogue ko text at {source_path}{_pointer(index, 'dialog', dialog_index, 'ko')}"
                    )
                if text.strip():
                    record_passages.append(
                        _passage(
                            source_path,
                            record_id,
                            level,
                            _pointer("scenarios", index, "dialog", dialog_index, "ko"),
                            text,
                        )
                    )
        passages.extend(record_passages)
        for grammar_id in grammar_ids:
            if grammar_id not in known_ids:
                unknown.append(
                    {
                        "grammarId": grammar_id,
                        "sourcePath": source_path,
                        "recordId": record_id,
                        "level": level,
                    }
                )
            for passage in record_passages:
                declarations.append((grammar_id, passage))

    for level_hint in SCENARIO_LEVELS:
        relative = DATA_RELATIVE / f"scenarios_{level_hint}.json"
        source_path = relative.as_posix()
        path = _safe_path(root, relative, required=False)
        if path is None:
            missing_optional.append(source_path)
            continue
        payload = _load_json(path)
        if not isinstance(payload, dict) or not isinstance(payload.get("scenarios"), list):
            raise ValueError(f"expected scenarios list: {source_path}")
        for index, record in enumerate(payload["scenarios"]):
            if not isinstance(record, dict):
                raise ValueError(f"expected scenario record at {source_path}{_pointer('scenarios', index)}")
            add_record(record, source_path, index, media=False, level_hint=level_hint)

    media_relative = DATA_RELATIVE / "media_phrases.json"
    media_source = media_relative.as_posix()
    media_path = _safe_path(root, media_relative, required=False)
    if media_path is None:
        missing_optional.append(media_source)
    else:
        payload = _load_json(media_path)
        if not isinstance(payload, dict) or not isinstance(payload.get("phrases"), list):
            raise ValueError(f"expected phrases list: {media_source}")
        for index, record in enumerate(payload["phrases"]):
            if not isinstance(record, dict):
                raise ValueError(f"expected media record at {media_source}{_pointer('phrases', index)}")
            add_record(record, media_source, index, media=True)

    links = [
        {**passage, "grammarId": grammar_id}
        for grammar_id, passage in declarations
    ]
    candidate_ids = {link["grammarId"] for link in links if link["grammarId"] in known_ids}
    return {
        "stage": "candidate_only",
        "verifiedAnchors": [],
        "passages": passages,
        "declaredCandidateGrammarLinks": links,
        "knownGrammarIdsWithoutCandidate": sorted(known_ids - candidate_ids),
        "unknownDeclaredGrammarIds": unknown,
        "diagnostics": {
            "missingOptionalFiles": missing_optional,
            "unknownDeclaredGrammarIds": unknown,
        },
    }
