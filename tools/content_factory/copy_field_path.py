"""Resolve an existing text leaf, including objects inside indexed arrays."""
import re
from typing import Any


def text_field(record: dict[str, Any], path: str) -> tuple[dict[str, Any], str]:
    parts = path.split(".")
    current: Any = record
    if not all(parts):
        raise ValueError(f"{record.get('id')}.{path}: empty field path component")
    for part in parts[:-1]:
        if isinstance(current, dict) and part in current:
            current = current[part]
        elif isinstance(current, list) and re.fullmatch(r"0|[1-9][0-9]*", part):
            index = int(part)
            if index >= len(current):
                raise ValueError(f"{record.get('id')}.{path}: array index out of range")
            current = current[index]
        else:
            raise ValueError(f"{record.get('id')}.{path}: missing field component {part}")
    key = parts[-1]
    if not isinstance(current, dict) or not isinstance(current.get(key), str):
        raise ValueError(f"{record.get('id')}.{path}: expected an existing text field")
    return current, key
