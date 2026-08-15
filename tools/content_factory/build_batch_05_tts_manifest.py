#!/usr/bin/env python3
"""Build and verify the exact immutable TTS plan for content Batch 05.

The promoted cloze and sentence-building records intentionally reuse the
vocabulary example sentences. They therefore resolve to the same immutable
cache objects and must not be synthesized twice.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DRAFTS = ROOT / "tools" / "content_factory" / "drafts"
OUTPUT = ROOT / "tools" / "content_factory" / "tts_batch_05_manifest.json"
REVISION = "v3"
VOICE = "female"
VOICE_NAME = "ko-KR-Chirp3-HD-Zephyr"


def _cache_path(text: str) -> str:
    normalized = text.strip()
    digest = hashlib.sha1(f"{VOICE}|{normalized}".encode("utf-8")).hexdigest()
    return f"tts/{REVISION}/{VOICE}/{digest}.mp3"


def _add(
    entries: dict[tuple[str, str], dict[str, Any]],
    *,
    text: str,
    source_type: str,
    source_id: str,
    field: str,
) -> None:
    normalized = text.strip()
    if not normalized:
        raise ValueError(f"empty TTS text: {source_type}/{source_id}/{field}")
    key = (VOICE, normalized)
    source_ref = {"type": source_type, "id": source_id, "field": field}
    if key in entries:
        entries[key]["sourceRefs"].append(source_ref)
        return
    entries[key] = {
        "voice": VOICE,
        "voiceName": VOICE_NAME,
        "text": normalized,
        "cachePath": _cache_path(normalized),
        "sourceRefs": [source_ref],
    }


def _build_entries() -> list[dict[str, Any]]:
    entries: dict[tuple[str, str], dict[str, Any]] = {}

    vocab_path = DRAFTS / "c3_batch05_vocab_b2_c1_c2.csv"
    with vocab_path.open(encoding="utf-8-sig", newline="") as handle:
        vocab_rows = list(csv.DictReader(handle))
    if len(vocab_rows) != 144:
        raise ValueError(f"expected 144 Batch 05 vocab rows, got {len(vocab_rows)}")
    for row in vocab_rows:
        _add(
            entries,
            text=row["korean"],
            source_type="vocab",
            source_id=row["id"],
            field="korean",
        )
        _add(
            entries,
            text=row["example_korean"],
            source_type="vocab",
            source_id=row["id"],
            field="example_korean",
        )

    grammar_path = DRAFTS / "c4_batch05_grammar_b2_c1_c2.csv"
    with grammar_path.open(encoding="utf-8-sig", newline="") as handle:
        grammar_rows = list(csv.DictReader(handle))
    if len(grammar_rows) != 24:
        raise ValueError(
            f"expected 24 Batch 05 grammar rows, got {len(grammar_rows)}"
        )
    for row in grammar_rows:
        _add(
            entries,
            text=row["example_korean"],
            source_type="grammar",
            source_id=row["id"],
            field="example_korean",
        )

    smalltalk_path = DRAFTS / "c2_batch05_smalltalk_b2_c1_c2.json"
    smalltalk = json.loads(smalltalk_path.read_text(encoding="utf-8"))
    phrases = smalltalk.get("phrases", [])
    if len(phrases) != 48:
        raise ValueError(f"expected 48 Batch 05 smalltalk rows, got {len(phrases)}")
    for phrase in phrases:
        phrase_id = phrase["id"]
        _add(
            entries,
            text=phrase["ko"],
            source_type="smalltalk",
            source_id=phrase_id,
            field="ko",
        )
        _add(
            entries,
            text=phrase["reply"]["ko"],
            source_type="smalltalk",
            source_id=phrase_id,
            field="reply.ko",
        )
        alternatives = phrase.get("safeAlternativeQuestions", [])
        if len(alternatives) != 1:
            raise ValueError(
                f"expected one safe alternative for {phrase_id}, got {len(alternatives)}"
            )
        _add(
            entries,
            text=alternatives[0]["ko"],
            source_type="smalltalk",
            source_id=phrase_id,
            field="safeAlternativeQuestions[0].ko",
        )
        _add(
            entries,
            text=phrase["followUp"]["ko"],
            source_type="smalltalk",
            source_id=phrase_id,
            field="followUp.ko",
        )

    result = list(entries.values())
    if len(result) != 504:
        raise ValueError(f"expected 504 unique Batch 05 TTS objects, got {len(result)}")
    return result


def build_manifest() -> dict[str, Any]:
    entries = _build_entries()
    return {
        "version": 1,
        "batch": "05",
        "createdAt": "2026-08-15",
        "status": "awaiting_credentials",
        "statusReason": (
            "The corpus and immutable paths are verified, but synthesis and upload "
            "require an authorized Google TTS API key and gcloud Storage session."
        ),
        "provider": "Google Cloud Text-to-Speech",
        "bucket": "ko-lernen-app.firebasestorage.app",
        "cacheRevision": REVISION,
        "voiceMap": {VOICE: VOICE_NAME},
        "authorization": {
            "approvedBy": "Jin",
            "approvedAt": "2026-08-15",
            "scope": "synthesize, verify, upload, and publish Batch 05 audio",
        },
        "counts": {
            "vocabHeadwords": 144,
            "vocabExamples": 144,
            "grammarExamples": 24,
            "smalltalkTurns": 192,
            "uniqueAudioObjects": 504,
            "corpusBeforeBatch": 5817,
            "corpusAfterBatch": 6321,
        },
        "deduplication": {
            "rule": "sha1(voice + '|' + trimmed text)",
            "note": (
                "The 144 cloze prompts and 144 sentence-building targets reuse "
                "vocabulary example audio and do not create extra cache objects."
            ),
        },
        "entries": entries,
    }


def _load_generator_module():
    path = ROOT / "tool" / "generate_tts.py"
    spec = importlib.util.spec_from_file_location("hangul_sori_generate_tts", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify(manifest: dict[str, Any]) -> None:
    expected = build_manifest()
    if manifest != expected:
        raise ValueError(
            "TTS manifest is stale; run build_batch_05_tts_manifest.py --write"
        )

    generator = _load_generator_module()
    corpus = generator.collect()
    corpus_paths = {
        generator.cache_relative_path(voice, text) for voice, text in corpus
    }
    if len(corpus) != 6321 or len(corpus_paths) != 6321:
        raise ValueError(
            f"expected integrated corpus of 6321, got {len(corpus)} pairs and "
            f"{len(corpus_paths)} unique paths"
        )
    planned_paths = {entry["cachePath"] for entry in manifest["entries"]}
    missing = sorted(planned_paths - corpus_paths)
    if missing:
        raise ValueError(f"{len(missing)} Batch 05 cache paths missing from live corpus")
    print(
        "Batch 05 TTS manifest verified: 504 immutable objects; "
        "integrated corpus 6321."
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--write", action="store_true")
    modes.add_argument("--check", action="store_true")
    args = parser.parse_args()

    if args.write:
        manifest = build_manifest()
        OUTPUT.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {OUTPUT} with {len(manifest['entries'])} entries.")
        verify(manifest)
        return 0

    manifest = json.loads(OUTPUT.read_text(encoding="utf-8"))
    verify(manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
