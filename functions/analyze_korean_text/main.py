"""Cloud Function — `analyze_korean_text`.

Phase 5 (stately-rising-jongga) — Hangul Sori 책 한 컷 backend.

**Deploy** (Jin):
    cd functions/
    firebase deploy --only functions:analyze_korean_text

**Env vars** — in `.env` (im selben Ordner, via .gitignore ausgeschlossen):
    DEEPL_API_KEY=...            # DeepL Übersetzung (DE/EN)
    URIMALSAEM_API_KEY=...       # 우리말샘 / NIKL — koreanische Definitionen
    Firebase liest `.env` beim Deploy automatisch in die Runtime.
    Vorlage: `.env.example`. Danach: firebase deploy --only functions

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
import urllib.parse
import urllib.request
from functools import lru_cache
from typing import Any

import functions_framework
from flask import Request, Response

# Lazy imports — nur initialisieren wenn aufgerufen.
_KIWI = None
_DEEPL = None


# ── .env Loader ──────────────────────────────────────────────────────────
# Firebase liest `.env` beim Deploy automatisch in die Runtime-Umgebung.
# Für lokale Ausführung / Emulator laden wir die Datei hier zusätzlich
# (best effort). `.env` ist via .gitignore ausgeschlossen — Keys NICHT committen.
def _load_dotenv() -> None:
    path = os.path.join(os.path.dirname(__file__), ".env")
    try:
        with open(path, encoding="utf-8") as f:
            for raw in f:
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                os.environ.setdefault(
                    key.strip(), value.strip().strip('"').strip("'")
                )
    except FileNotFoundError:
        pass


_load_dotenv()


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


# ── Kiwi word extraction (no Java needed) ────────────────────────────────

_POS_KEEP = {"NNG", "NNP", "VV", "VA"}
_POS_MAP = {"NNG": "Nomen", "NNP": "Nomen", "VV": "Verb", "VA": "Adjektiv"}


def _get_kiwi():
    global _KIWI
    if _KIWI is None:
        from kiwipiepy import Kiwi  # type: ignore

        _KIWI = Kiwi()
    return _KIWI


def extract_words(text: str, max_words: int = 30) -> list[dict[str, Any]]:
    kiwi = _get_kiwi()
    seen: dict[str, str] = {}
    ordered: list[str] = []
    for token in kiwi.tokenize(text, normalize_coda=True):
        tag = str(token.tag).split(".")[-1]  # "POS.NNG" → "NNG"
        if tag in _POS_KEEP and token.form not in seen:
            seen[token.form] = tag
            ordered.append(token.form)
            if len(ordered) >= max_words:
                break
    return [{"korean": w, "pos": _POS_MAP.get(seen[w], "Wort")} for w in ordered]


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


# ── 우리말샘 (Urimalsaem / NIKL Open Dictionary) Definitionen ─────────────
# Liefert eine kurze koreanische Definition (뜻풀이) pro Wort.
# Best effort: ohne Key oder bei Fehler einfach leer.

_URIMALSAEM_URL = "https://opendict.korean.go.kr/api/search"


def _fetch_definition(word: str, api_key: str) -> str:
    params = urllib.parse.urlencode({
        "key": api_key,
        "q": word,
        "req_type": "json",
        "num": "1",          # nur der erste Treffer
        "advanced": "n",
    })
    url = f"{_URIMALSAEM_URL}?{params}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "HangulSori/2.0"})
        with urllib.request.urlopen(req, timeout=2.5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception:  # pragma: no cover — best effort
        return ""
    try:
        items = data.get("channel", {}).get("item", [])
        if isinstance(items, dict):
            items = [items]
        if not items:
            return ""
        sense = items[0].get("sense", {})
        if isinstance(sense, list):
            sense = sense[0] if sense else {}
        definition = sense.get("definition", "")
        # HTML-Tags entfernen, die das Wörterbuch manchmal einbettet.
        return re.sub(r"<[^>]+>", "", definition).strip()
    except (KeyError, IndexError, AttributeError, TypeError):
        return ""


def enrich_definitions(words: list[dict[str, Any]], max_lookups: int = 20) -> None:
    """Fügt jedem Wort (in-place) `definitionKo` hinzu. Best effort."""
    api_key = os.environ.get("URIMALSAEM_API_KEY", "")
    if not api_key:
        for w in words:
            w["definitionKo"] = ""
        return
    for i, w in enumerate(words):
        w["definitionKo"] = (
            _fetch_definition(w["korean"], api_key) if i < max_lookups else ""
        )


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

    # Koreanische Definitionen via 우리말샘 (best effort, in-place).
    enrich_definitions(words)

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
            "definitionKo": w.get("definitionKo", ""),
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
