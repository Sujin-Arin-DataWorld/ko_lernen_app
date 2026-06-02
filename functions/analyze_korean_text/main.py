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

import html
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
    out: list[dict[str, Any]] = []
    for w in ordered:
        tag = seen[w]
        # 동사(VV)·형용사(VA)는 어간만 추출됨 → 사전 기본형(+다)으로 복원.
        # 예: "좋"→"좋다". stem 은 예문 매칭용으로 보존. 명사는 그대로.
        korean = f"{w}다" if tag in ("VV", "VA") else w
        out.append({
            "korean": korean,
            "stem": w,
            "pos": _POS_MAP.get(tag, "Wort"),
        })
    return out


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


# ── 표준국어대사전 (stdict / NIKL) Definitionen ───────────────────────────
# Liefert eine kurze koreanische Definition (뜻풀이) pro Wort. Best effort.
# Wichtig: NIKL-Wörterbücher ordnen Homonyme (먹다1=taub, 먹다2=essen) nach
# Etymologie, NICHT nach Häufigkeit — die "übliche" Bedeutung ist per API
# nicht erkennbar. Darum: bei mehreren Homonym-Einträgen lieber WEGLASSEN,
# statt eine falsche Bedeutung zu zeigen. Die DeepL-Übersetzung trägt ohnehin.
# Lizenz: stdict-Definitionen sind CC BY-SA 2.0 KR → Attribution in den
# Datenquellen (settingsDataSources / DATA_LICENSES.md) ergänzen.
_STDICT_URL = "https://stdict.korean.go.kr/api/search.do"


def _fetch_definition(word: str, api_key: str, pos_ko: str = "") -> str:
    params = urllib.parse.urlencode({
        "key": api_key,
        "q": word,
        "req_type": "json",
        "num": "10",         # stdict erlaubt nur 10–100
        "advanced": "n",
    })
    url = f"{_STDICT_URL}?{params}"
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
        # 표제어 정확 일치만 (복합어/파생어 제외).
        exact = [it for it in items if it.get("word") == word]
        if not exact:
            return ""
        # 품사가 주어지면 먼저 좁힌다 (명사/동사/형용사).
        if pos_ko:
            posed = [it for it in exact if it.get("pos") == pos_ko]
            if posed:
                exact = posed
        # 동음이의어(먹다1/먹다2 …)가 둘 이상이면 어떤 게 흔한 뜻인지 API 로
        # 알 수 없으므로 안전하게 생략 — 틀린 뜻을 절대 보여주지 않는다.
        if len(exact) != 1:
            return ""
        sense = exact[0].get("sense", {})
        if isinstance(sense, list):
            sense = sense[0] if sense else {}
        definition = sense.get("definition", "")
        # HTML 태그 + 엔티티(&lt; 등) 정리.
        return re.sub(r"<[^>]+>", "", html.unescape(definition)).strip()
    except (KeyError, IndexError, AttributeError, TypeError):
        return ""


def enrich_definitions(words: list[dict[str, Any]], max_lookups: int = 20) -> None:
    """Fügt jedem Wort (in-place) `definitionKo` hinzu. Best effort."""
    api_key = os.environ.get("STDICT_API_KEY") or os.environ.get(
        "URIMALSAEM_API_KEY", ""
    )
    if not api_key:
        for w in words:
            w["definitionKo"] = ""
        return
    pos_ko = {"Nomen": "명사", "Verb": "동사", "Adjektiv": "형용사"}
    for i, w in enumerate(words):
        w["definitionKo"] = (
            _fetch_definition(w["korean"], api_key, pos_ko.get(w.get("pos", ""), ""))
            if i < max_lookups
            else ""
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

    # 한국어 뜻풀이(definitionKo)는 v1.0 에서 비활성화.
    # NIKL 사전 API(우리말샘·표준국어대사전·krdict) 모두 동음이의어의 "대표 뜻"을
    # 안정적으로 주지 못함 (밥→형벌, 먹다→귀먹다, krdict 도 슬랭 다수). 독일 학습자에겐
    # 독일어 번역+예문이 핵심이라 가치 낮고, 호출 제거로 응답 속도도 향상.
    # 클라이언트는 definitionKo 빈 값이면 자동 숨김(isNotEmpty 가드). → definitionKo 는 "".
    # v1.1 재검토: 고정 단어장 큐레이션 또는 LLM 문맥 기반 sense 선택.
    # enrich_definitions(words)

    enriched_words = []
    sentence_lookup = {s: translations.get(s, "") for s in sentences}
    for w in words:
        kor = w["korean"]
        translation = translations.get(kor, "")
        example = next((s for s in sentences if w.get("stem", kor) in s), "")
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
