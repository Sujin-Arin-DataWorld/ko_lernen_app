"""Cloud Function — `analyze_korean_text`.

Phase 5 (stately-rising-jongga) — Hangul Sori 책 한 컷 backend.

**Deploy** (Google Cloud Gen2 source directory):
    See `docs/store/cloud-function-deploy.md` for the supported
    `gcloud functions deploy analyze_korean_text --gen2 ...` command.

**Env vars** — in `.env` (im selben Ordner, via .gitignore ausgeschlossen):
    DEEPL_API_KEY=...            # DeepL Übersetzung (DE/EN)
    URIMALSAEM_API_KEY=...       # 우리말샘 / NIKL — koreanische Definitionen
    Vorlage: `.env.example`. Pass secrets through the supported gcloud
    deployment flow described in the runbook; do not commit `.env`.

**Request**:
    POST <function-url>
    Content-Type: application/json
    Body: { "text": "...", "lang": "de" }

**Response** (success):
    { "words": [...], "grammar": [...], "sentences": [...], "warnings": [...] }

**Status**: deployable Python Gen2 source directory; it is not a named Firebase
Functions codebase in `firebase.json`. The Flutter client keeps a local fallback
when the deployed endpoint is unavailable.
"""

from __future__ import annotations

import hashlib
import html
import json
import os
import re
import urllib.parse
import urllib.request
from typing import Any

import functions_framework
from flask import Request, Response
from grammar_analysis import detect_grammar, localize_pos_tag, normalize_language

# Lazy imports — nur initialisieren wenn aufgerufen.
_KIWI = None
_DEEPL = None
_FS_CLIENT = None
_FS_TRIED = False


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


# ── Sentence split ───────────────────────────────────────────────────────


def split_sentences(text: str) -> list[str]:
    """KSS would be more accurate but adds ~200MB cold-start.
    Fallback: simple split on terminal punctuation + line breaks."""
    parts = re.split(r"(?<=[.!?。！？])\s+|\n+", text)
    return [p.strip() for p in parts if p.strip()]


# ── Kiwi word extraction (no Java needed) ────────────────────────────────

_POS_KEEP = {"NNG", "NNP", "VV", "VA"}
def _get_kiwi():
    global _KIWI
    if _KIWI is None:
        from kiwipiepy import Kiwi  # type: ignore

        _KIWI = Kiwi()
    return _KIWI


def extract_words(
    text: str,
    max_words: int = 30,
    language: object = "de",
) -> list[dict[str, Any]]:
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
            "pos": localize_pos_tag(tag, language),
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


# ── DeepL-Übersetzungs-Cache (Firestore) ──────────────────────────────────
# Gleiches Wort+Ziel geht nur einmal an DeepL → spart Kontingent (Free 500k
# Zeichen/Monat). Server-only Collection `translation_cache` (CF läuft mit
# Ambient-Credentials, Security Rules gelten für den Server nicht). Jeder
# Firestore-Fehler degradiert **still** zu direkter DeepL-Übersetzung —
# der P0-Pfad (Übersetzung) bricht durch den Cache niemals.
_CACHE_COLLECTION = "translation_cache"


def _get_firestore():
    """Lazy Firestore-Client (Ambient-CF-Credentials). None bei Fehler."""
    global _FS_CLIENT, _FS_TRIED
    if _FS_TRIED:
        return _FS_CLIENT
    _FS_TRIED = True
    try:
        from google.cloud import firestore  # type: ignore
        _FS_CLIENT = firestore.Client()
    except Exception:
        _FS_CLIENT = None
    return _FS_CLIENT


def _cache_key(text: str, target: str) -> str:
    return hashlib.sha256(f"{target}\n{text}".encode("utf-8")).hexdigest()


def translate_batch(items: list[str], target: str) -> dict[str, str]:
    if not items:
        return {}
    target_code = target.upper()
    if target_code == "EN":
        target_code = "EN-US"

    out: dict[str, str] = {}
    pending = list(dict.fromkeys(items))  # dedup, Reihenfolge erhalten
    fs = _get_firestore()

    # 1) Cache-Treffer einsammeln (best-effort).
    if fs is not None:
        try:
            key_to_item = {_cache_key(it, target_code): it for it in pending}
            refs = [fs.collection(_CACHE_COLLECTION).document(k)
                    for k in key_to_item]
            for snap in fs.get_all(refs):
                if snap.exists:
                    item = key_to_item.get(snap.id)
                    val = (snap.to_dict() or {}).get("t", "")
                    if item and val:
                        out[item] = val
            pending = [it for it in pending if it not in out]
        except Exception:  # Cache-Lesefehler → alles übersetzen
            out, pending = {}, list(dict.fromkeys(items))

    # 2) Nur Misses an DeepL.
    if pending:
        translator = _get_deepl()
        if translator is None:
            for it in pending:
                out.setdefault(it, "")
        else:
            try:
                results = translator.translate_text(
                    pending, target_lang=target_code)
                fresh = {src: r.text for src, r in zip(pending, results)}
            except Exception:  # pragma: no cover — best-effort
                fresh = {it: "" for it in pending}
            out.update(fresh)
            # 3) Neue Übersetzungen cachen (best-effort, nur nicht-leere).
            if fs is not None:
                try:
                    batch = fs.batch()
                    n = 0
                    for src, txt in fresh.items():
                        if not txt:
                            continue
                        batch.set(
                            fs.collection(_CACHE_COLLECTION).document(
                                _cache_key(src, target_code)),
                            {"t": txt, "src": src, "lang": target_code},
                        )
                        n += 1
                        if n % 400 == 0:
                            batch.commit()
                            batch = fs.batch()
                    if n % 400 != 0:
                        batch.commit()
                except Exception:
                    pass

    # Alle Eingabe-Keys garantieren.
    return {it: out.get(it, "") for it in items}


def translate_words_with_context(
    words: list[dict[str, Any]],
    sentences: list[str],
    target: str,
) -> dict[str, str]:
    """단어를 그 단어가 등장한 문장을 context 로 실어 번역 → 다의어 해소.

    "걸리다" 처럼 문맥에 따라 뜻이 갈리는 단어를, DeepL `context` 파라미터에
    예문을 함께 보내 올바른 의미로 번역한다(시간이 걸리다→dauern,
    경찰에 걸리다→erwischt werden). context 텍스트는 DeepL 과금 글자수에 미포함.

    효율: 같은 예문의 단어들은 한 요청으로 묶어 호출 수를 문장 수로 제한.
    캐시: 키 = sha256(target, "단어\\x1e예문") → 같은 문맥 재등장 시 재사용,
          문맥이 다르면 별도 번역(의미가 다를 수 있으므로 정당).
    반환: {korean: translation}. 오프라인/실패 시 빈 문자열.
    """
    target_code = target.upper()
    if target_code == "EN":
        target_code = "EN-US"

    # 전체 텍스트를 공통 context 로 사용. 단어별 예문(stem 부분문자열) 매칭은
    # 한국어 동사 활용(걸리다→걸려요, "걸리"가 "걸려요"에 없음) 때문에 자주
    # 실패해 context 가 비고 다의어 해소가 안 됐다. 짧은 책-한-컷 텍스트 전체를
    # 문맥으로 주면 모든 단어가 같은 context 라 DeepL 호출 1회로 묶이고 문맥도
    # 최대가 된다.
    full_context = " ".join(s for s in sentences if s).strip()
    word_example: dict[str, str] = {
        kor: full_context
        for kor in dict.fromkeys(w["korean"] for w in words)
    }

    result: dict[str, str] = {}
    fs = _get_firestore()

    # 1) 캐시 일괄 조회 (단어+예문 키).
    pending = dict(word_example)  # korean -> example
    if fs is not None:
        try:
            id_to_word = {
                _cache_key(f"{kor}\x1e{ex}", target_code): kor
                for kor, ex in word_example.items()
            }
            refs = [
                fs.collection(_CACHE_COLLECTION).document(cid)
                for cid in id_to_word
            ]
            for snap in fs.get_all(refs):
                if snap.exists:
                    kor = id_to_word.get(snap.id)
                    val = (snap.to_dict() or {}).get("t", "")
                    if kor and val:
                        result[kor] = val
            pending = {
                kor: ex for kor, ex in word_example.items()
                if kor not in result
            }
        except Exception:  # Cache-Lesefehler → alles neu übersetzen
            result, pending = {}, dict(word_example)

    if not pending:
        return result

    translator = _get_deepl()
    if translator is None:
        for kor in pending:
            result.setdefault(kor, "")
        return result

    # 2) 미스를 예문(context)별로 묶어 DeepL 호출 (예문당 1회).
    by_context: dict[str, list[str]] = {}
    for kor, ex in pending.items():
        by_context.setdefault(ex, []).append(kor)

    fresh: dict[str, str] = {}
    for ex, kors in by_context.items():
        try:
            results = translator.translate_text(
                kors, target_lang=target_code, context=(ex or None)
            )
            for kor, r in zip(kors, results):
                fresh[kor] = r.text
        except Exception:  # pragma: no cover — best-effort
            for kor in kors:
                fresh[kor] = ""
    result.update(fresh)

    # 3) 새 번역 캐시 저장 (단어+예문 키, 비어있지 않은 것만).
    if fs is not None:
        try:
            batch = fs.batch()
            n = 0
            for kor, ex in pending.items():
                txt = fresh.get(kor, "")
                if not txt:
                    continue
                batch.set(
                    fs.collection(_CACHE_COLLECTION).document(
                        _cache_key(f"{kor}\x1e{ex}", target_code)
                    ),
                    {"t": txt, "src": kor, "lang": target_code},
                )
                n += 1
                if n % 400 == 0:
                    batch.commit()
                    batch = fs.batch()
            if n % 400 != 0:
                batch.commit()
        except Exception:
            pass

    return result


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
    lang = normalize_language(body.get("lang"))
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

    grammar = detect_grammar(text, lang)
    sentences = split_sentences(text)
    words = extract_words(text, language=lang)

    # 문장은 batch 번역(문장 자체가 문맥), 단어는 그 단어가 든 예문을 DeepL
    # context 로 실어 번역 → 다의어 해소("걸리다"=시간이면 dauern / 경찰이면
    # erwischt werden). 단어 단독 번역의 문맥 부재 오역을 막는다.
    target = "DE" if lang == "de" else "EN-US"
    sentence_translations = translate_batch(sentences, target)
    word_translations = translate_words_with_context(words, sentences, target)

    # 한국어 뜻풀이(definitionKo)는 v1.0 에서 비활성화.
    # NIKL 사전 API(우리말샘·표준국어대사전·krdict) 모두 동음이의어의 "대표 뜻"을
    # 안정적으로 주지 못함 (밥→형벌, 먹다→귀먹다, krdict 도 슬랭 다수). 독일 학습자에겐
    # 독일어 번역+예문이 핵심이라 가치 낮고, 호출 제거로 응답 속도도 향상.
    # 클라이언트는 definitionKo 빈 값이면 자동 숨김(isNotEmpty 가드). → definitionKo 는 "".
    # v1.1 재검토: 고정 단어장 큐레이션 또는 LLM 문맥 기반 sense 선택.
    # enrich_definitions(words)

    # 단어의 예문 찾기 — 동사 활용(걸리다→걸려요) 때문에 stem 부분문자열 매칭이
    # 실패하므로, 문장을 형태소 분석해 form→대표문장 역인덱스를 만든다(문장당 1회).
    kiwi = _get_kiwi()
    form_to_sentence: dict[str, str] = {}
    for s in sentences:
        try:
            for token in kiwi.tokenize(s, normalize_coda=True):
                form_to_sentence.setdefault(token.form, s)
        except Exception:  # pragma: no cover — best-effort
            pass

    enriched_words = []
    sentence_lookup = {s: sentence_translations.get(s, "") for s in sentences}
    for w in words:
        kor = w["korean"]
        translation = word_translations.get(kor, "")
        stem = w.get("stem", kor)
        # 1) 형태소 역인덱스(활용형 정확) → 2) 부분문자열 fallback.
        example = form_to_sentence.get(stem) or next(
            (s for s in sentences if stem in s or kor in s), ""
        )
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
