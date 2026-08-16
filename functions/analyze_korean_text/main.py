"""Cloud Function — `analyze_korean_text`.

Phase 5 (stately-rising-jongga) — Hangul Sori 책 한 컷 backend.

**Deploy** (Google Cloud Gen2 source directory):
    See `docs/store/cloud-function-deploy.md` for the supported
    `gcloud functions deploy analyze_korean_text --gen2 ...` command.

**Runtime environment** — injected by the supported Secret Manager deploy flow:
    DEEPL_API_KEY=...            # DeepL Übersetzung (DE/EN)
    The function never reads a source-local dotenv file.

**Request**:
    POST <function-url>
    Content-Type: application/json
    Body: { "text": "...", "lang": "de", "schemaVersion": 2,
            "units": [{"id": "unit:0", "kind": "sentence",
                       "korean": "..."}] }

**Response** (success):
    {
      "words": [...], "expressions": [...], "grammar": [...],
      "sentences": [...],
      "warnings": [...], "analysisLanguage": "de"
    }

**Status**: deployable Python Gen2 source directory; it is not a named Firebase
Functions codebase in `firebase.json`. The Flutter client keeps a local fallback
when the deployed endpoint is unavailable.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
import re
from collections.abc import Sequence
from datetime import datetime, timedelta, timezone
from typing import Any

import functions_framework
from flask import Request, Response

from dictionary_validation import validate_exact_noun
from grammar_analysis import detect_grammar, localize_pos_tag, normalize_language
from security import (
    KKEUNMARI_DICTIONARY_QUOTA_POLICY,
    KKEUNMARI_QUOTA_SCOPE,
    AuthenticationFailed,
    FirestoreQuotaGate,
    QuotaExceeded,
    QuotaStoreUnavailable,
    verify_caller,
)
from text_quality import prepare_korean_analysis_text, split_korean_sentences

# Lazy imports — nur initialisieren wenn aufgerufen.
_KIWI = None
_DEEPL = None
_FS_CLIENT = None
_FS_TRIED = False
_QUOTA_GATE: FirestoreQuotaGate | None = None
_DICTIONARY_QUOTA_GATE: FirestoreQuotaGate | None = None
_MAX_REQUEST_BYTES = 20_000
_LOGGER = logging.getLogger(__name__)


def _quota_gate() -> FirestoreQuotaGate:
    global _QUOTA_GATE
    if _QUOTA_GATE is None:
        _QUOTA_GATE = FirestoreQuotaGate()
    return _QUOTA_GATE


def _dictionary_quota_gate() -> FirestoreQuotaGate:
    global _DICTIONARY_QUOTA_GATE
    if _DICTIONARY_QUOTA_GATE is None:
        _DICTIONARY_QUOTA_GATE = FirestoreQuotaGate(
            scope=KKEUNMARI_QUOTA_SCOPE,
            policy=KKEUNMARI_DICTIONARY_QUOTA_POLICY,
        )
    return _DICTIONARY_QUOTA_GATE


def _warning_response(
    warning: str,
    status: int,
    *,
    retry_after_seconds: int | None = None,
) -> Response:
    response = Response(
        json.dumps({"warnings": [warning]}),
        status=status,
        mimetype="application/json",
    )
    if retry_after_seconds is not None:
        response.headers["Retry-After"] = str(retry_after_seconds)
    return response


def _analysis_response(
    language: str,
    *,
    words: list[dict[str, Any]] | None = None,
    expressions: list[dict[str, Any]] | None = None,
    grammar: list[dict[str, Any]] | None = None,
    sentences: list[dict[str, Any]] | None = None,
    warnings: Sequence[str] = (),
) -> Response:
    """Return the complete success schema, including empty quality results."""

    return Response(
        json.dumps(
            {
                "words": words or [],
                "expressions": expressions or [],
                "grammar": grammar or [],
                "sentences": sentences or [],
                "warnings": list(dict.fromkeys(warnings)),
                "analysisLanguage": language,
            },
            ensure_ascii=False,
        ),
        status=200,
        mimetype="application/json",
    )


def _log_analysis_result(
    status: str,
    language: str,
    *,
    character_count: int,
    word_count: int = 0,
    grammar_count: int = 0,
    sentence_count: int = 0,
    warnings: Sequence[str] = (),
) -> None:
    """Emit operational counts and machine codes, never OCR text or user IDs."""

    _LOGGER.info(
        "book_analysis status=%s lang=%s chars=%d words=%d grammar=%d "
        "sentences=%d warnings=%s",
        status,
        language,
        character_count,
        word_count,
        grammar_count,
        sentence_count,
        ",".join(dict.fromkeys(warnings)) or "none",
    )


# ── Grammar patterns ─────────────────────────────────────────────────────


# ── Sentence split ───────────────────────────────────────────────────────


def split_sentences(text: str) -> list[str]:
    """Split reflowed Korean source without treating OCR wraps as sentences."""
    return split_korean_sentences(text)


_STRUCTURED_UNIT_KINDS = {"sentence", "expression", "headword"}
_STRUCTURED_UNIT_SEPARATOR = "。\n"
_STRUCTURED_UNIT_KEYS = {
    "id",
    "kind",
    "korean",
    "sourceLineIds",
    "bbox",
    "confidence",
}


def _structured_analysis_units(body: dict[str, Any]) -> list[dict[str, str]] | None:
    """Validate the v2 OCR scene payload without accepting printed glosses."""

    if "schemaVersion" not in body and "units" not in body:
        return None
    if body.get("schemaVersion") != 2 or not isinstance(body.get("units"), list):
        raise ValueError("invalid_structured_schema")
    raw_units = body["units"]
    if len(raw_units) > 120:
        raise ValueError("too_many_units")

    units: list[dict[str, str]] = []
    seen_ids: set[str] = set()
    for raw_unit in raw_units:
        if not isinstance(raw_unit, dict) or not set(raw_unit).issubset(
            _STRUCTURED_UNIT_KEYS
        ):
            raise ValueError("invalid_unit")
        unit_id = raw_unit.get("id")
        kind = raw_unit.get("kind")
        korean = raw_unit.get("korean")
        if (
            not isinstance(unit_id, str)
            or not re.fullmatch(r"unit:\d{1,4}", unit_id)
            or unit_id in seen_ids
            or kind not in _STRUCTURED_UNIT_KINDS
            or not isinstance(korean, str)
            or len(korean) > 600
        ):
            raise ValueError("invalid_unit")
        source_line_ids = raw_unit.get("sourceLineIds")
        if not isinstance(source_line_ids, list) or any(
            not isinstance(item, str) or len(item) > 80 for item in source_line_ids
        ):
            raise ValueError("invalid_unit_source")
        bbox = raw_unit.get("bbox")
        if not isinstance(bbox, dict) or set(bbox) != {
            "left",
            "top",
            "right",
            "bottom",
        }:
            raise ValueError("invalid_unit_bbox")
        if any(
            isinstance(value, bool)
            or not isinstance(value, (int, float))
            or abs(float(value)) > 1_000_000
            for value in bbox.values()
        ):
            raise ValueError("invalid_unit_bbox")
        confidence = raw_unit.get("confidence")
        if confidence is not None and (
            isinstance(confidence, bool)
            or not isinstance(confidence, (int, float))
            or not 0 <= float(confidence) <= 1
        ):
            raise ValueError("invalid_unit_confidence")

        prepared = prepare_korean_analysis_text(korean)
        if not prepared.text:
            raise ValueError("invalid_unit_text")
        seen_ids.add(unit_id)
        units.append({"id": unit_id, "kind": str(kind), "korean": prepared.text})
    return units


def _sentence_spans(
    text: str,
    sentences: Sequence[str],
) -> list[tuple[int, int, str]]:
    """Locate prepared sentences without another morphology pass."""

    spans: list[tuple[int, int, str]] = []
    cursor = 0
    for sentence in sentences:
        start = text.find(sentence, cursor)
        if start < 0:
            start = text.find(sentence)
        if start < 0:
            continue
        end = start + len(sentence)
        spans.append((start, end, sentence))
        cursor = end
    return spans


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
    *,
    tokens: Sequence[object] | None = None,
) -> list[dict[str, Any]]:
    if tokens is None:
        tokens = _get_kiwi().tokenize(text, normalize_coda=True)
    seen: dict[str, str] = {}
    ordered: list[str] = []
    for token in tokens:
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
_CACHE_VERSION = "ko-source-v3-ttl"
_CACHE_TTL = timedelta(days=30)


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
        _LOGGER.warning("translation_cache_unavailable")
    return _FS_CLIENT


def _cache_key(text: str, target: str) -> str:
    return hashlib.sha256(
        f"{_CACHE_VERSION}\nKO\n{target}\n{text}".encode("utf-8")
    ).hexdigest()


def _cache_expires_at() -> datetime:
    """Return a Firestore TTL timestamp based on the runtime server clock."""

    return datetime.now(timezone.utc) + _CACHE_TTL


def _cached_translation(
    data: object,
    target: str,
    *,
    now: datetime | None = None,
) -> str:
    """Return a current cache value, treating legacy/expired entries as misses."""

    if not isinstance(data, dict):
        return ""
    if data.get("version") != _CACHE_VERSION or data.get("lang") != target:
        return ""
    expires_at = data.get("expiresAt")
    if not isinstance(expires_at, datetime):
        return ""
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    current_time = now or datetime.now(timezone.utc)
    if expires_at <= current_time:
        return ""
    translation = data.get("t")
    if isinstance(translation, str) and translation.strip():
        return translation
    return ""


def _cache_payload(translation: str, target: str) -> dict[str, object]:
    """Build the source-free cache document allowed by the privacy contract."""

    return {
        "t": translation,
        "lang": target,
        "version": _CACHE_VERSION,
        "expiresAt": _cache_expires_at(),
    }


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
                    val = _cached_translation(snap.to_dict(), target_code)
                    if item and val:
                        out[item] = val
            pending = [it for it in pending if it not in out]
        except Exception:  # Cache-Lesefehler → alles übersetzen
            _LOGGER.warning("translation_cache_read_failed")
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
                    pending, target_lang=target_code, source_lang="KO")
                fresh = {src: r.text for src, r in zip(pending, results)}
            except Exception:  # pragma: no cover — best-effort
                _LOGGER.warning("deepl_sentence_translation_failed")
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
                            _cache_payload(txt, target_code),
                        )
                        n += 1
                        if n % 400 == 0:
                            batch.commit()
                            batch = fs.batch()
                    if n % 400 != 0:
                        batch.commit()
                except Exception:
                    _LOGGER.warning("translation_cache_write_failed")

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
                    val = _cached_translation(snap.to_dict(), target_code)
                    if kor and val:
                        result[kor] = val
            pending = {
                kor: ex for kor, ex in word_example.items()
                if kor not in result
            }
        except Exception:  # Cache-Lesefehler → alles neu übersetzen
            _LOGGER.warning("translation_cache_read_failed")
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
                kors,
                target_lang=target_code,
                source_lang="KO",
                context=(ex or None),
            )
            for kor, r in zip(kors, results):
                fresh[kor] = r.text
        except Exception:  # pragma: no cover — best-effort
            _LOGGER.warning("deepl_word_translation_failed")
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
                    _cache_payload(txt, target_code),
                )
                n += 1
                if n % 400 == 0:
                    batch.commit()
                    batch = fs.batch()
            if n % 400 != 0:
                batch.commit()
        except Exception:
            _LOGGER.warning("translation_cache_write_failed")

    return result


# ── Cloud Function entrypoint ────────────────────────────────────────────


@functions_framework.http
def analyze_korean_text(request: Request) -> Response:
    if request.method != "POST":
        return Response("POST only", status=405)
    if request.content_length is not None and request.content_length > _MAX_REQUEST_BYTES:
        return _warning_response("request_too_large", 413)
    try:
        caller = verify_caller(request)
    except AuthenticationFailed:
        return _warning_response("unauthenticated", 401)

    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        body = {}
    lang = normalize_language(body.get("lang"))
    requested_analysis_language = body.get("analysisLanguage")
    if requested_analysis_language is not None and requested_analysis_language != lang:
        return _warning_response("wrong_analysis_language", 400)
    try:
        structured_units = _structured_analysis_units(body)
    except ValueError:
        return _warning_response("invalid_units", 400)

    raw_text = body.get("text")
    if raw_text is None:
        raw_text = ""
    if not isinstance(raw_text, str):
        return _warning_response("invalid_text", 400)
    text = (
        _STRUCTURED_UNIT_SEPARATOR.join(
            unit["korean"] for unit in structured_units
        )
        if structured_units is not None
        else raw_text.strip()
    )
    if not text:
        return _analysis_response(
            lang,
            warnings=("empty_text",),
        )
    if len(text) > 5000:
        return Response(
            json.dumps({"warnings": ["text_too_long"]}),
            status=400,
            mimetype="application/json",
        )

    prepared = prepare_korean_analysis_text(text)
    quality_warnings = list(prepared.warnings)
    if not prepared.text:
        _log_analysis_result(
            "rejected_no_korean",
            lang,
            character_count=len(text),
            warnings=quality_warnings,
        )
        return _analysis_response(
            lang,
            warnings=quality_warnings,
        )
    text = prepared.text

    try:
        _quota_gate().consume(caller.uid)
    except QuotaExceeded as error:
        return _warning_response(
            "rate_limited",
            429,
            retry_after_seconds=error.retry_after_seconds,
        )
    except QuotaStoreUnavailable:
        return _warning_response("service_unavailable", 503)

    sentence_sources: list[tuple[str, str]] = []
    expression_sources: list[tuple[str, str]] = []
    if structured_units is None:
        sentence_sources = [(sentence, "") for sentence in split_sentences(text)]
    else:
        for unit in structured_units:
            if unit["kind"] == "sentence":
                sentence_sources.extend(
                    (sentence, unit["id"])
                    for sentence in split_sentences(unit["korean"])
                )
            elif unit["kind"] == "expression":
                expression_sources.append((unit["korean"], unit["id"]))
    sentences = [sentence for sentence, _ in sentence_sources]
    try:
        tokens = list(_get_kiwi().tokenize(text, normalize_coda=True))
    except Exception:  # pragma: no cover - runtime dependency failure
        tokens = []
        quality_warnings.append("morphology_unavailable")
        _LOGGER.warning("book_analysis_morphology_unavailable")
    grammar = detect_grammar(text, lang, tokens=tokens)
    if structured_units is not None:
        for hit in grammar:
            matched = str(hit.get("matched", ""))
            hit["sourceUnitId"] = next(
                (
                    unit["id"]
                    for unit in structured_units
                    if matched and matched in unit["korean"]
                ),
                "",
            )
    words = extract_words(text, language=lang, tokens=tokens)

    # 문장은 batch 번역(문장 자체가 문맥), 단어는 그 단어가 든 예문을 DeepL
    # context 로 실어 번역 → 다의어 해소("걸리다"=시간이면 dauern / 경찰이면
    # erwischt werden). 단어 단독 번역의 문맥 부재 오역을 막는다.
    target = "DE" if lang == "de" else "EN-US"
    translation_inputs = list(
        dict.fromkeys(
            sentences + [expression for expression, _ in expression_sources]
        )
    )
    sentence_translations = translate_batch(translation_inputs, target)
    word_translations = translate_words_with_context(words, sentences, target)
    if (
        any(not sentence_translations.get(source) for source in translation_inputs)
        or any(not word_translations.get(word["korean"]) for word in words)
    ):
        quality_warnings.append("translation_unavailable")

    # 단어의 예문 찾기 — 위에서 만든 한 번의 Kiwi 결과와 문자 offset을 재사용한다.
    # 동사 활용(걸리다→걸려요)도 stem form으로 대표 문장을 찾을 수 있다.
    form_to_sentence: dict[str, str] = {}
    sentence_spans = _sentence_spans(text, sentences)
    for token in tokens:
        token_start = getattr(token, "start", None)
        if not isinstance(token_start, int):
            continue
        sentence = next(
            (
                sentence_text
                for start, end, sentence_text in sentence_spans
                if start <= token_start < end
            ),
            "",
        )
        token_form = str(getattr(token, "form", ""))
        if token_form and sentence:
            form_to_sentence.setdefault(token_form, sentence)

    enriched_words = []
    sentence_lookup = {s: sentence_translations.get(s, "") for s in sentences}
    sentence_source_lookup = dict(sentence_sources)
    for w in words:
        kor = w["korean"]
        translation = word_translations.get(kor, "")
        stem = w.get("stem", kor)
        # 1) 형태소 역인덱스(활용형 정확) → 2) 부분문자열 fallback.
        example = form_to_sentence.get(stem) or next(
            (s for s in sentences if stem in s or kor in s), ""
        )
        source_unit_id = sentence_source_lookup.get(example, "")
        if not source_unit_id and structured_units is not None:
            source_unit_id = next(
                (
                    unit["id"]
                    for unit in structured_units
                    if stem in unit["korean"] or kor in unit["korean"]
                ),
                "",
            )
        enriched_words.append({
            "korean": kor,
            "romanization": "",  # could add hangul-romanization fallback later
            "pos": w["pos"],
            "translation": translation,
            "definitionKo": w.get("definitionKo", ""),
            "example": example,
            "exampleTranslation": sentence_lookup.get(example, ""),
            **({"sourceUnitId": source_unit_id} if source_unit_id else {}),
        })

    sentence_results = [
        {
            "korean": sentence,
            "translation": sentence_lookup[sentence],
            **({"sourceUnitId": source_unit_id} if source_unit_id else {}),
        }
        for sentence, source_unit_id in sentence_sources
    ]
    expression_results = [
        {
            "korean": expression,
            "translation": sentence_translations.get(expression, ""),
            "sourceUnitId": source_unit_id,
        }
        for expression, source_unit_id in expression_sources
    ]
    _log_analysis_result(
        "complete",
        lang,
        character_count=len(text),
        word_count=len(enriched_words),
        grammar_count=len(grammar),
        sentence_count=len(sentence_results),
        warnings=quality_warnings,
    )
    return _analysis_response(
        lang,
        words=enriched_words,
        expressions=expression_results,
        grammar=grammar,
        sentences=sentence_results,
        warnings=quality_warnings,
    )


@functions_framework.http
def validate_kkeunmari_word(request: Request) -> Response:
    """Checks one exact noun headword for the word-chain fallback.

    This is deliberately separate from book analysis: it has its own quota and
    does not consume a learner's daily book-scan allowance.
    """
    if request.method != "POST":
        return Response("POST only", status=405)
    try:
        caller = verify_caller(request)
    except AuthenticationFailed:
        return _warning_response("unauthenticated", 401)

    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        body = {}
    word = str(body.get("word") or "").strip()
    if not re.fullmatch(r"[\uac00-\ud7a3]{1,20}", word):
        return Response(
            json.dumps({"valid": False, "warnings": ["invalid_word_shape"]}),
            status=200,
            mimetype="application/json",
        )

    try:
        _dictionary_quota_gate().consume(caller.uid)
    except QuotaExceeded as error:
        return _warning_response(
            "rate_limited",
            429,
            retry_after_seconds=error.retry_after_seconds,
        )
    except QuotaStoreUnavailable:
        return _warning_response("service_unavailable", 503)

    valid = validate_exact_noun(word)
    if valid is None:
        return _warning_response("dictionary_unavailable", 503)
    return Response(
        json.dumps({"valid": valid}, ensure_ascii=False),
        status=200,
        mimetype="application/json",
    )
