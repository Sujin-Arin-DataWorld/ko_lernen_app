#!/usr/bin/env python3
"""Build the exact Theme Park Date scenario TTS operation manifest.

The manifest contains only runtime dialogue and quest audio from the six
reviewed Theme Park Date scenarios.  It performs no authentication, synthesis,
upload, Firebase write, or runtime promotion.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any, Mapping


ROOT = Path(__file__).resolve().parents[2]
SCENARIO_DRAFT = Path(
    "tools/content_factory/drafts/theme_park_date_scenarios_v1.json"
)
CHARACTER_PROFILES = Path(
    "tools/content_factory/canonical_scenarios/character_profiles.json"
)
DEFAULT_OUTPUT = Path(
    "tools/content_factory/review/theme_park_date_tts_pending.json"
)
GENERATION_ID = "theme_park_date_v1"
CACHE_REVISION = "v3"
AUTO_VOICE_SALT = "hangul-sori-auto-voice-v1"
AUDIO_KO_QUESTS = frozenset(("satzBauen", "batchimDrop", "hoerverstehen"))


class ThemeParkTtsManifestError(ValueError):
    """Raised when reviewed Theme Park Date TTS input is malformed."""


def _json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ThemeParkTtsManifestError(f"{label} must be an object")
    return value


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ThemeParkTtsManifestError(f"{label} must be a nonempty string")
    return value.strip()


def _auto_voice(text: str) -> str:
    digest = hashlib.sha1(
        f"{AUTO_VOICE_SALT}|{text.strip()}".encode("utf-8")
    ).digest()
    return "male" if digest[0] & 1 else "female"


def _cache_path(voice: str, text: str) -> str:
    digest = hashlib.sha1(f"{voice}|{text.strip()}".encode("utf-8")).hexdigest()
    return f"tts/{CACHE_REVISION}/{voice}/{digest}.mp3"


def _candidate_set_hash(scenarios: list[dict[str, Any]]) -> str:
    canonical = json.dumps(
        sorted(scenarios, key=lambda item: str(item.get("id") or "")),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _character_voices(root: Path) -> dict[str, str]:
    payload = _mapping(_json(root / CHARACTER_PROFILES), "character profiles")
    result: dict[str, str] = {}
    for index, raw in enumerate(payload.get("recurringCharacters", [])):
        row = _mapping(raw, f"recurringCharacters[{index}]")
        character_id = _text(row.get("id"), f"recurringCharacters[{index}].id")
        voice = _text(row.get("voice"), f"recurringCharacters[{index}].voice")
        if voice not in {"female", "male"}:
            raise ThemeParkTtsManifestError(
                f"recurringCharacters[{index}] has unsupported voice {voice!r}"
            )
        result[character_id] = voice
    return result


def _quest_audio(quest: Mapping[str, Any], label: str) -> tuple[str, str] | None:
    data = _mapping(quest.get("data"), f"{label}.data")
    quest_type = str(quest.get("type") or "")
    if quest_type in AUDIO_KO_QUESTS:
        value = data.get("audioKo")
        field = "audioKo"
    elif quest_type == "diktat":
        value = data.get("audioKo") or data.get("targetKo")
        field = "audioKo" if data.get("audioKo") else "targetKo"
    elif quest_type == "particlePop":
        options = data.get("options")
        index = data.get("correctIndex", 0)
        if not isinstance(options, list) or type(index) is not int:
            raise ThemeParkTtsManifestError(
                f"{label} has invalid particlePop options or correctIndex"
            )
        if index < 0 or index >= len(options):
            raise ThemeParkTtsManifestError(f"{label}.correctIndex is outside options")
        value = (
            str(data.get("prefix") or "")
            + str(options[index])
            + str(data.get("suffix") or "")
        )
        field = "derivedFullSentence"
    else:
        return None
    if value is None or not str(value).strip():
        return None
    return str(value).strip(), field


def build_manifest(root: Path = ROOT) -> dict[str, Any]:
    payload = _mapping(_json(root / SCENARIO_DRAFT), "Theme Park Date draft")
    raw_scenarios = payload.get("scenarios")
    if not isinstance(raw_scenarios, list):
        raise ThemeParkTtsManifestError("Theme Park Date draft needs scenarios")
    scenarios = [
        _mapping(row, f"scenarios[{index}]")
        for index, row in enumerate(raw_scenarios)
    ]
    if len(scenarios) != 6:
        raise ThemeParkTtsManifestError(
            f"Theme Park Date TTS requires six scenarios, got {len(scenarios)}"
        )
    voices = _character_voices(root)
    items: list[dict[str, Any]] = []
    seen: set[tuple[str, str]] = set()

    def add_item(
        *,
        scenario_id: str,
        path: str,
        source: str,
        speaker: str,
        resolved_character_id: str | None,
        voice: str,
        text: str,
    ) -> None:
        normalized = text.strip()
        key = (voice, normalized)
        if key in seen:
            return
        seen.add(key)
        items.append(
            {
                "scenarioId": scenario_id,
                "path": path,
                "source": source,
                "speaker": speaker,
                "resolvedCharacterId": resolved_character_id,
                "voice": voice,
                "text": normalized,
                "cachePath": _cache_path(voice, normalized),
                "status": "pending",
            }
        )

    for scenario_index, scenario in enumerate(scenarios):
        scenario_id = _text(scenario.get("id"), f"scenarios[{scenario_index}].id")
        player_id = _text(
            scenario.get("playerCharacterId"),
            f"{scenario_id}.playerCharacterId",
        )
        dialog = scenario.get("dialog")
        if not isinstance(dialog, list):
            raise ThemeParkTtsManifestError(f"{scenario_id}.dialog must be an array")
        for index, raw_line in enumerate(dialog):
            line = _mapping(raw_line, f"{scenario_id}.dialog[{index}]")
            speaker = _text(line.get("speaker"), f"{scenario_id}.dialog[{index}].speaker")
            if speaker == "narrator":
                continue
            resolved = player_id if speaker == "user" else speaker
            voice = voices.get(resolved)
            if voice is None:
                raise ThemeParkTtsManifestError(
                    f"{scenario_id}.dialog[{index}] has no voice for {resolved!r}"
                )
            text = _text(line.get("ko"), f"{scenario_id}.dialog[{index}].ko")
            add_item(
                scenario_id=scenario_id,
                path=f"/dialog/{index}/ko",
                source="dialog",
                speaker=speaker,
                resolved_character_id=resolved,
                voice=voice,
                text=text,
            )
        quests = scenario.get("quests")
        if not isinstance(quests, list):
            raise ThemeParkTtsManifestError(f"{scenario_id}.quests must be an array")
        for index, raw_quest in enumerate(quests):
            quest = _mapping(raw_quest, f"{scenario_id}.quests[{index}]")
            resolved = _quest_audio(quest, f"{scenario_id}.quests[{index}]")
            if resolved is None:
                continue
            text, field = resolved
            add_item(
                scenario_id=scenario_id,
                path=f"/quests/{index}/data/{field}",
                source="quest",
                speaker="auto",
                resolved_character_id=None,
                voice=_auto_voice(text),
                text=text,
            )

    return {
        "schemaVersion": 1,
        "kind": "scenario_tts_pending_manifest",
        "generationId": GENERATION_ID,
        "scope": "corpus",
        "candidateSetSha256": _candidate_set_hash(scenarios),
        "cacheRevision": CACHE_REVISION,
        "synthesisRequested": False,
        "uploadRequested": False,
        "releaseGate": "blocked_until_all_items_exist",
        "count": len(items),
        "items": items,
    }


def render_manifest(manifest: Mapping[str, Any]) -> str:
    return json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    root = args.root.resolve()
    output = args.output if args.output.is_absolute() else root / args.output
    try:
        manifest = build_manifest(root)
        expected = render_manifest(manifest)
        if args.check:
            if not output.is_file() or output.read_text(encoding="utf-8") != expected:
                raise ThemeParkTtsManifestError(
                    f"Theme Park Date TTS manifest drift: {output}"
                )
            action = "verified"
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(expected, encoding="utf-8", newline="\n")
            action = "wrote"
    except (OSError, json.JSONDecodeError, ThemeParkTtsManifestError) as error:
        print(f"ERROR: {error}")
        return 1
    print(
        f"OK: {action} {output} with {manifest['count']} exact cache requests"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
