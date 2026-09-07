#!/usr/bin/env python3
"""Ledger of content items whose ``id`` level segment disagrees with their
current live level (plan §3.E, §4.3; task T1.7).

An ID is immutable once assigned (``vocab_a1_0216`` stays ``vocab_a1_0216``
forever, plan §Global Constraints "ID는 불변"). When a relevel transaction
moves the *row* to a different level, the ID's embedded level segment goes
stale on purpose. ``validate_content.py`` used to hard-code three
``LEGACY_*_LEVEL_EXCEPTIONS`` frozensets to tolerate that drift; this module
replaces them with a single auditable, appendable, self-validating ledger
file (``relevel_ledger.json``) that any content kind can register against.

Contract:
    * ``Ledger.allows(kind, ident, level)`` is the drop-in replacement for
      ``ident not in LEGACY_..._EXCEPTIONS`` -- it is ``True`` iff the ledger
      has an entry for that exact ``(kind, id)`` pair whose recorded ``to``
      level equals ``level`` (case must already match -- callers pass
      lowercase levels, matching the JSON schema).
    * The ledger is data, not code: no import in this repo other than
      ``validate_content.py`` needs to reach into it, so there is nothing to
      keep import-compatible.
    * ``load_ledger`` resolves its default path relative to *this file*, not
      to any ``root``/``stage`` argument a caller passes to
      ``ContentValidator``. Staging directories built by
      ``integrate_scenario_batch.py``/``integrate_review_batches.py`` copy
      only ``assets/data`` (plus an explicit few tools/content_factory
      files); they never copy this module's sibling JSON. Because Python
      does not duplicate ``.py`` files into the stage either,
      ``Path(__file__).resolve().parent`` always points back at this real
      checkout's ``tools/content_factory/`` -- exactly like the existing
      ``import scenario_store`` / ``from shelf_assignment import
      ALL_SHELVES`` code-level dependencies already do.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field, replace
from pathlib import Path
from typing import Any, Mapping

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_LEDGER_PATH = SCRIPT_DIR / "relevel_ledger.json"

LEVELS: frozenset[str] = frozenset(("a1", "a2", "b1", "b2", "c1", "c2"))
KINDS: frozenset[str] = frozenset(
    ("vocab", "cloze", "satz", "smalltalk", "pronunciation", "grammar")
)

_ID_PREFIX_BY_KIND = {kind: f"{kind}_" for kind in KINDS}


class LedgerError(ValueError):
    """Raised for a structurally or semantically invalid ledger.

    Fail-closed: a corrupt or malformed ``relevel_ledger.json`` must stop the
    validator, not silently grant tolerance to content it was never told
    about.
    """


@dataclass(frozen=True)
class LedgerEntry:
    """One relevel-tolerance record.

    ``from_level``/``to_level`` hold the JSON document's ``from``/``to``
    fields -- renamed because ``from`` is a Python keyword and cannot be a
    dataclass field name.
    """

    id: str
    kind: str
    from_level: str
    to_level: str
    movedAt: str
    batch: str
    reason: str

    def __post_init__(self) -> None:
        if not self.id or not isinstance(self.id, str):
            raise LedgerError(f"ledger entry id must be a nonempty string, got {self.id!r}")
        if self.kind not in KINDS:
            raise LedgerError(
                f"{self.id}: unknown ledger kind {self.kind!r} (expected one of {sorted(KINDS)})"
            )
        if self.from_level not in LEVELS:
            raise LedgerError(
                f"{self.id}: from level {self.from_level!r} is not one of {sorted(LEVELS)}"
            )
        if self.to_level not in LEVELS:
            raise LedgerError(
                f"{self.id}: to level {self.to_level!r} is not one of {sorted(LEVELS)}"
            )
        prefix = _ID_PREFIX_BY_KIND[self.kind]
        if not self.id.startswith(prefix):
            raise LedgerError(
                f"{self.id}: id does not start with {prefix!r} for kind {self.kind!r}"
            )
        for label, value in (
            ("movedAt", self.movedAt),
            ("batch", self.batch),
            ("reason", self.reason),
        ):
            if not value or not isinstance(value, str):
                raise LedgerError(f"{self.id}: {label} must be a nonempty string")

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "LedgerEntry":
        required = ("id", "kind", "from", "to", "movedAt", "batch", "reason")
        missing = [key for key in required if key not in data]
        if missing:
            raise LedgerError(f"ledger entry missing field(s) {missing}: {data!r}")
        return cls(
            id=str(data["id"]),
            kind=str(data["kind"]),
            from_level=str(data["from"]),
            to_level=str(data["to"]),
            movedAt=str(data["movedAt"]),
            batch=str(data["batch"]),
            reason=str(data["reason"]),
        )

    def to_dict(self) -> dict[str, str]:
        return {
            "id": self.id,
            "kind": self.kind,
            "from": self.from_level,
            "to": self.to_level,
            "movedAt": self.movedAt,
            "batch": self.batch,
            "reason": self.reason,
        }


def _sort_key(entry: LedgerEntry) -> tuple[str, str]:
    return (entry.kind, entry.id)


@dataclass
class Ledger:
    """In-memory view of ``relevel_ledger.json`` plus the operations
    ``validate_content.py`` and ``relevel_bundle.py`` (PR-L2a) need.
    """

    version: int
    entries: list[LedgerEntry] = field(default_factory=list)
    path: Path | None = None

    def __post_init__(self) -> None:
        seen: dict[str, LedgerEntry] = {}
        for entry in self.entries:
            if entry.id in seen:
                raise LedgerError(f"duplicate ledger id {entry.id!r}")
            seen[entry.id] = entry
        self.entries = sorted(self.entries, key=_sort_key)

    def allows(self, kind: str, ident: str, level: str) -> bool:
        """True iff an entry exists for ``(kind, ident)`` whose ``to`` level
        equals ``level``. ``level`` must already be lowercase -- callers own
        their own case normalization, matching the JSON schema's ``from``/
        ``to`` convention (plan §3.E)."""

        return any(
            entry.kind == kind and entry.id == ident and entry.to_level == level
            for entry in self.entries
        )

    def ids_for(self, kind: str) -> frozenset[str]:
        """All ledgered ids for one content kind, regardless of ``to``.

        Drop-in replacement for the old bare ``LEGACY_*_LEVEL_EXCEPTIONS``
        frozensets when a caller only needs membership, not the ``to``
        check that ``allows`` performs.
        """

        return frozenset(entry.id for entry in self.entries if entry.kind == kind)

    def get(self, kind: str, ident: str) -> LedgerEntry | None:
        for entry in self.entries:
            if entry.kind == kind and entry.id == ident:
                return entry
        return None

    def append(self, entry: LedgerEntry) -> "Ledger":
        """Return a new ``Ledger`` with ``entry`` added, sorted by
        ``(kind, id)``. Raises ``LedgerError`` if ``entry.id`` is already
        present -- ids are unique across the whole ledger, not just within a
        kind, because the id itself already embeds the kind prefix."""

        if any(existing.id == entry.id for existing in self.entries):
            raise LedgerError(f"duplicate ledger id {entry.id!r}: already present")
        return replace(self, entries=sorted([*self.entries, entry], key=_sort_key))

    def to_dict(self) -> dict[str, Any]:
        return {
            "version": self.version,
            "entries": [entry.to_dict() for entry in sorted(self.entries, key=_sort_key)],
        }

    def save(self, path: Path | None = None) -> None:
        target = path or self.path
        if target is None:
            raise LedgerError("Ledger.save() needs a path (none given, none stored on load)")
        target.write_text(
            json.dumps(self.to_dict(), ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )


def load_ledger(path: Path = DEFAULT_LEDGER_PATH) -> Ledger:
    """Load and structurally validate ``relevel_ledger.json``.

    Fail-closed: any missing file, bad JSON, wrong shape, unknown kind,
    non-canonical level, or duplicate id raises ``LedgerError`` rather than
    returning a partial/empty ledger -- a validator that silently dropped
    ledger tolerance would let genuinely mismatched ids back into the "no
    exception, no mercy" default path.
    """

    try:
        raw_text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise LedgerError(f"cannot read ledger {path}: {error}") from error
    try:
        raw = json.loads(raw_text)
    except json.JSONDecodeError as error:
        raise LedgerError(f"cannot parse ledger {path}: {error}") from error
    if not isinstance(raw, dict):
        raise LedgerError(f"ledger {path} root must be an object")
    version = raw.get("version")
    if not isinstance(version, int) or version < 1:
        raise LedgerError(f"ledger {path} version must be a positive integer, got {version!r}")
    raw_entries = raw.get("entries")
    if not isinstance(raw_entries, list):
        raise LedgerError(f"ledger {path} entries must be a list")
    entries = [LedgerEntry.from_dict(item) for item in raw_entries]
    return Ledger(version=version, entries=entries, path=path)


def validate_ledger(ledger: Ledger, live_levels: Mapping[str, Mapping[str, str]]) -> list[str]:
    """Cross-check every ledger entry against the live content it claims to
    describe (plan §4.3 ``validate_ledger(ledger, live_levels)``).

    ``live_levels`` maps ``kind -> {id: level}`` (level lowercase) built from
    the content actually on disk right now. Three things must hold for every
    entry, each reported as its own issue string when violated:
      1. the id must still exist in the live ``kind`` data;
      2. its live level must equal the entry's ``to``;
      3. the id's own level segment (``vocab_a1_0216`` -> ``a1``) must equal
         the entry's ``from``.
    """

    issues: list[str] = []
    for entry in ledger.entries:
        segment = entry.id.split("_")[1] if entry.id.count("_") >= 2 else None
        if segment != entry.from_level:
            issues.append(
                f"{entry.id}: ledger from={entry.from_level!r} does not match "
                f"id segment {segment!r}"
            )
        kind_levels = live_levels.get(entry.kind, {})
        if entry.id not in kind_levels:
            issues.append(f"{entry.id}: not found in live {entry.kind} data")
            continue
        live_level = kind_levels[entry.id]
        if live_level != entry.to_level:
            issues.append(
                f"{entry.id}: ledger to={entry.to_level!r} does not match "
                f"live {entry.kind} level {live_level!r}"
            )
    return issues
