"""Cloud Function — `analyze_korean_text`.

Phase 5 (stately-rising-jongga) — Hangul Sori 책 한 컷 backend.

**Deploy** (Jin):
    cd functions/
    firebase deploy --only functions:analyze_korean_text

**Env vars** (Firebase Functions config):
    firebase functions:config:set \
        deepl.api_key="..." \
        nikl.api_key="..."   # optional, definitions enrichment
    firebase deploy --only functions

**Request**:
    POST <function-url>
    Content-Type: application/json
    Body: { "text": "...", "lang": "de" }

**Response** (success):
    { "words": [...], "grammar": [...], "sentences": [...], "warnings": [...] }

**Status**: skeleton — Jin muss `requirements.txt` installieren + Deploy
ausführen. Lokaler Stub im Flutter-Client (`book_analysis_service.dart`)
arbeitet bis dahin als Fallback.
"""

from __future__ import annotations

import json
import os
import re
from functools import lru_cache
from typing import Any

import functions_framework
from flask import Request, Response

# Lazy imports — OKT braucht Java; nur initialisieren wenn aufgerufen.
_OKT = None
_DEEPL = None


# ── Grammar patterns ─────────────────────────────────────────────────────


@lru_cache(maxsize=1)
def _load_grammar_patterns() -> list[dict[str, Any]]:
    path = os.path.join(os.path.dirname(__file__), "grammar_patterns.json")
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return []


def detect_grammar(text: str) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for p in _load_grammar_patterns():
        pid = p.get("id", "")
        if pid in seen:
            continue
        regex = p.get("regex", "")
        if not regex:
            continue
        try:
            m = re.search(regex, text)
        except re.error:
            continue
        if m:
            seen.add(pid)
            out.append({
                "id": pid,
                "nameDe": p.get("name_de", pid),
                "matched": m.group(0),
                "level": p.get("level", "A2"),
                "explanationDe": p.get("explanation_de", ""),
            })
    return out


# ── Sentence split ───────────────────────────────────────────────────────


def split_sentences(text: str) -> list[str]:
    """KSS would be more accurate but adds ~200MB cold-start.
    Fallback: simple split on terminal punctuation + line breaks."""
    parts = re.split(r"(?<=[.!?。！？])\s+|\n+", text)
    return [p.strip() for p in parts if p.strip()]


# ── OKT word extraction ──────────────────────────────────────────────────


def _get_okt():
    global _OKT
    if _OKT is None:
        from konlpy.tag import Okt  # type: ignore

        _OKT = Okt()
    return _OKT


def extract_words(text: str, max_words: int = 30) -> list[dict[str, Any]]:
    okt = _get_okt()
    morphs = okt.pos(text, norm=True, stem=True)
    seen: dict[str, str] = {}
    ordered: list[str] = []
    for word, pos in morphs:
        if pos in ("Noun", "Verb", "Adjective") and word not in seen:
            seen[word] = pos
            ordered.append(word)
            if len(ordered) >= max_words:
                break
    pos_map = {"Noun": "Nomen", "Verb": "Verb", "Adjective": "Adjektiv"}
    return [{"korean": w, "pos": pos_map.get(seen[w], "Wort")} for w in ordered]


# ── DeepL translation ────────────────────────────────────────────────────


def _get_deepl():
    global _DEEPL
    if _DEEPL is None:
        import deepl  # type: ignore

        api_key = os.environ.get("DEEPL_API_KEY", "")
        if not api_key:
            return None
        _DEEPL = deepl.Translator(api_key)
    return _DEEPL


def translate_batch(items: list[str], target: str) -> dict[str, str]:
    if not items:
        return {}
    translator = _get_deepl()
    if translator is None:
        return {it: "" for it in items}
    target_code = target.upper()
    if target_code == "EN":
        target_code = "EN-US"
    try:
        results = translator.translate_text(items, target_lang=target_code)
        return {src: r.text for src, r in zip(items, results)}
    except Exception:  # pragma: no cover — best-effort
        return {it: "" for it in items}


# ── Cloud Function entrypoint ────────────────────────────────────────────


@functions_framework.http
def analyze_korean_text(request: Request) -> Response:
    if request.method != "POST":
        return Response("POST only", status=405)
    body = request.get_json(silent=True) or {}
    text = (body.get("text") or "").strip()
    lang = (body.get("lang") or "de").lower()
    if not text:
        return Response(
            json.dumps({"warnings": ["empty_text"]}),
            status=200,
            mimetype="application/json",
        )
    if len(text) > 5000:
        return Response(
            json.dumps({"warnings": ["text_too_long"]}),
            status=400,
            mimetype="application/json",
        )

    grammar = detect_grammar(text)
    sentences = split_sentences(text)
    words = extract_words(text)

    # Translate words + sentences together (DeepL batched).
    to_translate = [w["korean"] for w in words] + sentences
    target = "DE" if lang == "de" else "EN-US"
    translations = translate_batch(to_translate, target)

    enriched_words = []
    sentence_lookup = {s: translations.get(s, "") for s in sentences}
    for w in words:
        kor = w["korean"]
        translation = translations.get(kor, "")
        example = next((s for s in sentences if kor in s), "")
        enriched_words.append({
            "korean": kor,
            "romanization": "",  # could add hangul-romanization fallback later
            "pos": w["pos"],
            "translation": translation,
            "example": example,
            "exampleTranslation": sentence_lookup.get(example, ""),
        })

    return Response(
        json.dumps({
            "words": enriched_words,
            "grammar": grammar,
            "sentences": [
                {"korean": s, "translation": sentence_lookup[s]}
                for s in sentences
            ],
            "warnings": [],
        }, ensure_ascii=False),
        status=200,
        mimetype="application/json",
    )
