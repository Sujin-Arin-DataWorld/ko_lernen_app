#!/usr/bin/env python3
"""Review-only Gemini audit for the canonical 120-scenario corpus.

The runner batches one level (20 scenarios) per request, records token usage,
and writes review evidence only. It never edits candidates, records approval,
promotes runtime shards, calls TTS, or writes Firebase data.
"""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time
from typing import Any, Mapping, Sequence
import urllib.error
import urllib.request

import scenario_corpus_pipeline as pipeline


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CANDIDATES = ROOT / "tools/content_factory/review/canonical_120_v1/candidates"
DEFAULT_OUTPUT_DIR = ROOT / "tools/content_factory/review/canonical_120_v1/gemini_audit"
DEFAULT_MODEL = "gemini-3.1-pro-preview"
DEFAULT_THINKING_LEVEL = "medium"
DEFAULT_MAX_OUTPUT_TOKENS = 12_288
DEFAULT_MAX_ESTIMATED_USD = 2.0
DEFAULT_PRICING_TIER = "paid"
FREE_TIER_MODELS = frozenset(("gemini-3.5-flash", "gemini-3.7-flash"))
AUDIT_RECEIPT_SCHEMA_VERSION = 2
API_ROOT = "https://generativelanguage.googleapis.com/v1beta"
RETRYABLE_STATUS = frozenset((429, 500, 502, 503, 504))
PERMANENT_QUOTA_MARKERS = (
    "prepayment credits are depleted",
    "billing account",
    "billing is not enabled",
)
ERROR_CODES = (
    "ACC",
    "PRAG",
    "REL",
    "REF",
    "INDEX",
    "DEIX",
    "TAM",
    "EVID",
    "FORCE",
    "PRESUP",
    "CULT",
    "NAT",
    "TERM",
    "CEFR",
    "ITEM",
    "INT",
    "DATA",
)
VERDICTS = ("pass", "review", "reject")
FINDING_SEVERITIES = ("critical", "major", "minor")
FINDING_SCOPES = ("ko", "de", "en", "multi", "pedagogy", "data")
SCORE_KEYS = (
    "koreanNaturalness",
    "levelFit",
    "germanLocalization",
    "englishLocalization",
    "pragmaticAlignment",
)


class GeminiAuditError(RuntimeError):
    """Raised when the audit cannot produce trustworthy review evidence."""


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _gcloud_output(executable: str, arguments: Sequence[str]) -> str:
    completed = subprocess.run(
        [executable, *arguments],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip()[:800]
        raise GeminiAuditError(f"gcloud verification failed: {detail}")
    return completed.stdout.strip()


def verify_free_tier_project(
    api_key: str,
    project_id: str,
    *,
    gcloud_executable: str | None = None,
) -> dict[str, Any]:
    """Prove that the supplied key belongs to a billing-disabled project."""
    if not api_key.strip():
        raise GeminiAuditError("GEMINI_API_KEY is empty")
    if not project_id.strip():
        raise GeminiAuditError("--free-tier-project-id is required for free mode")
    executable = gcloud_executable or shutil.which("gcloud")
    if executable is None:
        raise GeminiAuditError("gcloud is required to verify free-tier provenance")

    try:
        billing = json.loads(
            _gcloud_output(
                executable,
                (
                    "billing",
                    "projects",
                    "describe",
                    project_id,
                    "--format=json",
                ),
            )
        )
        keys = json.loads(
            _gcloud_output(
                executable,
                (
                    "services",
                    "api-keys",
                    "list",
                    "--project",
                    project_id,
                    "--format=json",
                ),
            )
        )
    except json.JSONDecodeError as error:
        raise GeminiAuditError("gcloud returned invalid verification JSON") from error
    if not isinstance(billing, dict) or billing.get("billingEnabled") is not False:
        raise GeminiAuditError(
            f"project {project_id!r} is not verified as billing-disabled"
        )
    if not isinstance(keys, list):
        raise GeminiAuditError("gcloud API key list must be an array")

    matched_uid: str | None = None
    for key in keys:
        if not isinstance(key, dict) or not isinstance(key.get("uid"), str):
            continue
        uid = key["uid"]
        key_string = _gcloud_output(
            executable,
            (
                "services",
                "api-keys",
                "get-key-string",
                uid,
                "--project",
                project_id,
                "--format=value(keyString)",
            ),
        )
        if hmac.compare_digest(key_string, api_key.strip()):
            matched_uid = uid
            break
    if matched_uid is None:
        raise GeminiAuditError(
            "GEMINI_API_KEY does not belong to the declared free-tier project"
        )
    return {
        "projectId": project_id,
        "billingEnabled": False,
        "apiKeyUid": matched_uid,
        "verifiedAt": _utc_now(),
        "verificationMethod": "gcloud billing projects describe + api-keys key match",
    }


def _read_response_json(response: Any) -> dict[str, Any]:
    payload = json.load(response)
    if not isinstance(payload, dict):
        raise GeminiAuditError("Gemini response must be a JSON object")
    return payload


class GeminiClient:
    def __init__(
        self,
        api_key: str,
        *,
        api_root: str = API_ROOT,
        timeout_seconds: int = 300,
        max_attempts: int = 3,
    ) -> None:
        if not api_key.strip():
            raise GeminiAuditError("GEMINI_API_KEY is empty")
        self._api_key = api_key.strip()
        self._api_root = api_root.rstrip("/")
        self._timeout_seconds = timeout_seconds
        self._max_attempts = max_attempts

    def _post(self, path: str, body: Mapping[str, Any]) -> dict[str, Any]:
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        request = urllib.request.Request(
            f"{self._api_root}/{path.lstrip('/')}",
            data=data,
            headers={
                "Content-Type": "application/json; charset=utf-8",
                "x-goog-api-key": self._api_key,
            },
            method="POST",
        )
        for attempt in range(1, self._max_attempts + 1):
            retry_delay = min(2 ** (attempt - 1), 8)
            try:
                with urllib.request.urlopen(
                    request, timeout=self._timeout_seconds
                ) as response:
                    return _read_response_json(response)
            except urllib.error.HTTPError as error:
                detail = error.read().decode("utf-8", errors="replace")[:800]
                permanent_quota_error = error.code == 429 and any(
                    marker in detail.lower() for marker in PERMANENT_QUOTA_MARKERS
                )
                if (
                    error.code not in RETRYABLE_STATUS
                    or permanent_quota_error
                    or attempt == self._max_attempts
                ):
                    raise GeminiAuditError(
                        f"Gemini HTTP {error.code}: {detail}"
                    ) from error
                if error.code == 429:
                    retry_delay = retry_delay_seconds(detail, attempt=attempt)
            except (urllib.error.URLError, TimeoutError) as error:
                if attempt == self._max_attempts:
                    raise GeminiAuditError(f"Gemini request failed: {error}") from error
            time.sleep(retry_delay)
        raise GeminiAuditError("Gemini request exhausted retries")

    def count_tokens(self, model: str, contents: Sequence[Mapping[str, Any]]) -> int:
        response = self._post(
            f"models/{model}:countTokens",
            {"contents": list(contents)},
        )
        value = response.get("totalTokens")
        if not isinstance(value, int) or value <= 0:
            raise GeminiAuditError(f"invalid countTokens response: {response}")
        return value

    def generate(
        self,
        *,
        model: str,
        contents: Sequence[Mapping[str, Any]],
        schema: Mapping[str, Any],
        thinking_level: str,
        max_output_tokens: int,
    ) -> dict[str, Any]:
        return self._post(
            f"models/{model}:generateContent",
            {
                "contents": list(contents),
                "generationConfig": {
                    "thinkingConfig": {"thinkingLevel": thinking_level},
                    "maxOutputTokens": max_output_tokens,
                    "responseMimeType": "application/json",
                    "responseJsonSchema": schema,
                },
            },
        )


def audit_schema(*, relaxed: bool = False) -> dict[str, Any]:
    object_constraints = {} if relaxed else {"additionalProperties": False}

    def enum_string(values: Sequence[str]) -> dict[str, Any]:
        return {"type": "string", "enum": list(values)}

    finding = {
        "type": "object",
        **object_constraints,
        "properties": {
            "severity": enum_string(FINDING_SEVERITIES),
            "code": enum_string(ERROR_CODES),
            "scope": enum_string(FINDING_SCOPES),
            "path": {"type": "string"},
            "evidence": {"type": "string"},
            "analysisKo": {"type": "string"},
            "recommendationKo": {"type": "string"},
        },
        "required": [
            "severity",
            "code",
            "scope",
            "path",
            "evidence",
            "analysisKo",
            "recommendationKo",
        ],
    }
    score = {"type": "integer", "minimum": 1, "maximum": 5}
    scenario = {
        "type": "object",
        **object_constraints,
        "properties": {
            "scenarioId": {"type": "string"},
            "verdict": enum_string(VERDICTS),
            "scores": {
                "type": "object",
                **object_constraints,
                "properties": {key: score for key in SCORE_KEYS},
                "required": list(SCORE_KEYS),
            },
            "findings": {"type": "array", "items": finding},
            "strengthsKo": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["scenarioId", "verdict", "scores", "findings", "strengthsKo"],
    }
    return {
        "type": "object",
        **object_constraints,
        "properties": {
            "level": enum_string(pipeline.LEVELS),
            "scenarios": {
                "type": "array",
                "items": scenario,
            },
            "summaryKo": {"type": "string"},
        },
        "required": ["level", "scenarios", "summaryKo"],
    }


def _audit_instructions(level: str) -> str:
    return f"""당신은 한국어 교육 전문가이자 한국어·독일어·영어 화용론 및 현지화 감사자다.
아래 {level.upper()} 시나리오 20개를 검토하되 콘텐츠를 다시 쓰거나 승인하지 말고, 검토 증거만 JSON으로 반환하라.

권위와 범위
- 한국어가 유일한 의미 원문이다. DE와 EN은 서로를 거치지 않고 같은 의사소통 사건을 독립적으로 재구성해야 한다.
- 이 후보들은 generated/editorial 상태이며 Jin의 인간 승인을 받지 않았다. pass도 자동 승인이나 출시 허가가 아니다.
- 기존 ID, 화자, 인물 관계, 사건, 퀘스트 계약을 바꾸지 말라. 전체 대체 대본을 만들지 말라.

감사 기준
1. 한국어 자연성: 2026년 실제 장면에서 인물의 목적과 사건이 살아 있고, 이미 아는 사실을 학습자에게 설명하는 대사나 사전식 문장이 없는가.
2. 레벨 적합성: 레벨은 문장 길이뿐 아니라 내용 범위, 사회적 거리, 인지 과제로 판정한다. A1/A2는 정말 쉽되 비문·유아어·억지 축약을 허용하지 않는다. 공식적 관용구는 장면상 필요하면 입력으로 남길 수 있으나 학습자 산출 부담은 낮아야 한다.
3. 화용 보존: 사실, 극성, 인과, 화행, 선택권, 높임, 관계, 시제·상, 정보 출처, 확신, 양태 강도, 전제를 점검한다. 없는 인물·성별·직책·절차·감정을 만들지 않는다.
4. DE/EN 자연성: 한국어 어순을 모사하지 말고 목표어 장면에서 실제 발화처럼 읽혀야 한다. 번역투가 유창해 보여도 의미나 관계가 이동하면 실패다.
5. 독일어 호칭: 앱 UI의 기본 du와 대화 속 인물 관계를 혼동하지 않는다. 한국어의 -요체는 독일어 Sie의 자동 근거가 아니다. scenario brief의 relationship을 우선하며, 친구·친한 사이·연애 관계는 한국어가 -요체여도 독일어에서는 자연스럽게 du를 쓴다. 낯선 사람·서비스·업무상 처음 만난 관계는 Sie일 수 있다. 같은 화자-청자 관계 안에서 du/Sie, 동사형, 소유사, 명령형이 섞이면 REL로 기록한다.
6. 문화·교육: 문화 노트는 이 장면의 기능만 설명하고 국민성 일반화를 하지 않는다. 어휘·문법·퀘스트는 실제 대사에서 추출되어야 하며 정답이 유일해야 한다.

오탐 방지
- 분석상 번역이 자연스럽고 관계에도 맞는다면 주석·설명 추가 같은 선택적 제안만으로 finding이나 review를 만들지 않는다.
- REL은 실제 du/Sie 혼용, 잘못된 관계 선택, 호칭·동사형 불일치가 입력 증거로 확인될 때만 쓴다. 대명사가 없는 중립 문장, `Könnte ich ...?` 같은 자체로 공손한 문장, 단순한 문체 취향은 REL이 아니다.
- 한국어의 높임·반말 대조를 DE/EN에서 기계적으로 Sie/du나 별도 형태 대조로 재현할 필요는 없다. 목표 문화의 실제 관계에서 자연스러운 호칭을 선택하고, 의미와 관계가 보존되면 pass다.
- 자연스러운 혼잣말, 상황상 가능한 복수 표현, 구어체와 문어체 중 어느 쪽도 허용 가능한 선택을 억지로 오류화하지 않는다.
- analysisKo에서 `올바르다`, `자연스럽다`, `관계에 부합한다`, `큰 위반은 없다`고 판단했다면 그 항목은 findings=[]와 pass여야 한다.

판정 규칙
- critical: ACC/REL/REF/INDEX/DEIX/TAM/EVID/FORCE/PRESUP/CULT/ITEM/INT/DATA 중 학습 의미나 관계를 깨는 오류. 하나라도 있으면 reject.
- major: 출시 전 반드시 사람이 고쳐야 하는 NAT/CEFR/TERM/PRAG 또는 비치명적 정합성 오류. 있으면 review 이상.
- minor: 선택적 다듬기. 문제를 억지로 만들지 말고 실제로 수정 가치가 있을 때만 기록한다.
- 각 finding의 evidence는 입력에서 짧게 인용하고 path는 가능한 JSON Pointer로 쓴다. recommendationKo는 수정 방향만 1~2문장으로 쓰고 전체 대본을 재작성하지 않는다.
- 모든 20개 ID를 정확히 한 번씩 반환한다. 문제가 없으면 findings=[]와 pass를 사용한다.
"""


def level_payload(
    level: str,
    *,
    candidate_directory: Path = DEFAULT_CANDIDATES,
    root: Path = ROOT,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    sources = pipeline.load_sources(root)
    candidates = pipeline.load_level_candidates(candidate_directory, level, root=root)
    briefs = {brief.scenario_id: brief for brief in sources.briefs}
    scenes: list[dict[str, Any]] = []
    for candidate in candidates:
        scenario_id = str(candidate["scenarioId"])
        brief = briefs[scenario_id]
        characters = []
        for character_id in brief.participant_ids:
            profile = sources.characters.get(character_id)
            if profile is not None:
                characters.append(profile.raw)
                continue
            characters.append(
                {
                    "id": character_id,
                    "displayNames": {
                        "ko": sources.role_names_ko.get(character_id, character_id)
                    },
                    "voice": sources.role_voices.get(character_id, "unknown"),
                    "roleOnly": True,
                }
            )
        scenes.append(
            {
                "brief": brief.raw,
                "characters": characters,
                "candidate": candidate,
            }
        )
    payload = {
        "authority": "generated_editorial_candidate_not_approved",
        "levelProfile": sources.level_profiles[level].raw,
        "scenes": scenes,
    }
    return candidates, payload


def contents_for_level(level: str, payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    compact = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    return [
        {
            "role": "user",
            "parts": [
                {
                    "text": _audit_instructions(level)
                    + "\n\n감사 입력 JSON:\n"
                    + compact
                }
            ],
        }
    ]


def audit_request_hash(
    *,
    generation_id: str,
    model: str,
    thinking_level: str,
    max_output_tokens: int,
    contents: Sequence[Mapping[str, Any]],
    schema: Mapping[str, Any],
) -> str:
    contract = {
        "generationId": generation_id,
        "model": model,
        "thinkingLevel": thinking_level,
        "maxOutputTokens": max_output_tokens,
        "contents": list(contents),
        "responseMimeType": "application/json",
        "responseJsonSchema": schema,
    }
    encoded = json.dumps(
        contract, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _extract_text(response: Mapping[str, Any]) -> str:
    candidates = response.get("candidates")
    if not isinstance(candidates, list) or not candidates:
        raise GeminiAuditError(f"Gemini returned no candidate: {response}")
    content = candidates[0].get("content")
    if not isinstance(content, dict):
        raise GeminiAuditError("Gemini candidate has no content")
    parts = content.get("parts")
    if not isinstance(parts, list):
        raise GeminiAuditError("Gemini candidate has no parts")
    text = "".join(
        str(part.get("text") or "") for part in parts if isinstance(part, dict)
    )
    if not text.strip():
        raise GeminiAuditError("Gemini candidate contains no output text")
    return text


def validate_model_audit(
    result: Mapping[str, Any],
    *,
    level: str,
    expected_ids: Sequence[str],
) -> dict[str, Any]:
    if result.get("level") != level:
        raise GeminiAuditError(
            f"model returned level {result.get('level')!r}; expected {level!r}"
        )
    scenarios = result.get("scenarios")
    if not isinstance(scenarios, list) or len(scenarios) != 20:
        raise GeminiAuditError("model audit must contain exactly 20 scenarios")
    ids = [str(item.get("scenarioId")) for item in scenarios if isinstance(item, dict)]
    if len(ids) != 20 or len(ids) != len(set(ids)):
        raise GeminiAuditError("model audit contains missing or duplicate scenario IDs")
    if set(ids) != set(expected_ids):
        missing = sorted(set(expected_ids) - set(ids))
        extras = sorted(set(ids) - set(expected_ids))
        raise GeminiAuditError(f"model audit ID mismatch; missing={missing}, extras={extras}")
    by_id = {str(item["scenarioId"]): item for item in scenarios}
    for scenario_id, item in by_id.items():
        if not isinstance(item, dict):
            raise GeminiAuditError(f"{scenario_id} must be an object")
        if item.get("verdict") not in VERDICTS:
            raise GeminiAuditError(f"{scenario_id} has an invalid verdict")
        scores = item.get("scores")
        if not isinstance(scores, dict) or set(scores) != set(SCORE_KEYS):
            raise GeminiAuditError(f"{scenario_id} has invalid score fields")
        if any(
            isinstance(scores[key], bool)
            or not isinstance(scores[key], int)
            or not 1 <= scores[key] <= 5
            for key in SCORE_KEYS
        ):
            raise GeminiAuditError(f"{scenario_id} has a score outside 1..5")
        findings = item.get("findings")
        if not isinstance(findings, list) or len(findings) > 6:
            raise GeminiAuditError(f"{scenario_id} has invalid findings")
        for finding in findings:
            if not isinstance(finding, dict):
                raise GeminiAuditError(f"{scenario_id} has a non-object finding")
            if finding.get("severity") not in FINDING_SEVERITIES:
                raise GeminiAuditError(f"{scenario_id} has invalid finding severity")
            if finding.get("code") not in ERROR_CODES:
                raise GeminiAuditError(f"{scenario_id} has invalid finding code")
            if finding.get("scope") not in FINDING_SCOPES:
                raise GeminiAuditError(f"{scenario_id} has invalid finding scope")
            for key in (
                "path",
                "evidence",
                "analysisKo",
                "recommendationKo",
            ):
                if not isinstance(finding.get(key), str):
                    raise GeminiAuditError(
                        f"{scenario_id} finding {key} must be text"
                    )
        strengths = item.get("strengthsKo")
        if (
            not isinstance(strengths, list)
            or len(strengths) > 3
            or any(not isinstance(value, str) for value in strengths)
        ):
            raise GeminiAuditError(f"{scenario_id} has invalid strengthsKo")
        critical = any(
            isinstance(finding, dict) and finding.get("severity") == "critical"
            for finding in findings
        )
        if critical and item.get("verdict") != "reject":
            raise GeminiAuditError(
                f"{scenario_id} has a critical finding without reject verdict"
            )
        if findings and item.get("verdict") == "pass":
            raise GeminiAuditError(
                f"{scenario_id} has findings but a pass verdict"
            )
    normalized = dict(result)
    normalized["scenarios"] = [by_id[scenario_id] for scenario_id in expected_ids]
    return normalized


def reusable_resume_audit(
    receipt: Any,
    *,
    expected_fields: Mapping[str, Any],
    level: str,
    expected_ids: Sequence[str],
) -> dict[str, Any] | None:
    """Return a verified cached audit, or None so the caller regenerates it."""

    if not isinstance(receipt, dict):
        return None
    if any(receipt.get(key) != expected for key, expected in expected_fields.items()):
        return None
    if not receipt.get("modelVersion") or not receipt.get("responseId"):
        return None
    model_result = receipt.get("audit")
    if not isinstance(model_result, dict):
        return None
    try:
        return validate_model_audit(
            model_result,
            level=level,
            expected_ids=expected_ids,
        )
    except GeminiAuditError:
        return None


def retry_delay_seconds(detail: str, *, attempt: int) -> float:
    match = re.search(r"retry\s+in\s+([0-9]+(?:\.[0-9]+)?)s", detail, re.IGNORECASE)
    if match:
        return min(max(float(match.group(1)) + 1.0, 1.0), 60.0)
    return float(min(2 ** (attempt - 1), 8))


def prompt_token_count_for_estimate(
    client: GeminiClient,
    *,
    model: str,
    contents: Sequence[Mapping[str, Any]],
    pricing_tier: str,
) -> int:
    if pricing_tier == "free":
        return 0
    return client.count_tokens(model, contents)


def price_for_prompt(input_tokens: int) -> tuple[float, float]:
    if input_tokens <= 200_000:
        return 2.0, 12.0
    return 4.0, 18.0


def estimate_cost(
    token_counts: Mapping[str, int],
    *,
    max_output_tokens: int,
    pricing_tier: str = DEFAULT_PRICING_TIER,
) -> dict[str, Any]:
    if pricing_tier == "free":
        rows = {
            level: {
                "inputTokens": token_counts[level],
                "inputUsdPerMillion": 0.0,
                "outputUsdPerMillion": 0.0,
                "maxOutputTokens": max_output_tokens,
                "estimatedUpperUsd": 0.0,
            }
            for level in pipeline.LEVELS
        }
        return {
            "levels": rows,
            "totalInputTokens": sum(token_counts.values()),
            "estimatedUpperUsd": 0.0,
            "basis": "Gemini Developer API free tier; the API key must belong to a billing-disabled project.",
        }
    rows: dict[str, Any] = {}
    total = 0.0
    for level in pipeline.LEVELS:
        input_tokens = token_counts[level]
        input_rate, output_rate = price_for_prompt(input_tokens)
        upper = (
            input_tokens * input_rate / 1_000_000
            + max_output_tokens * output_rate / 1_000_000
        )
        rows[level] = {
            "inputTokens": input_tokens,
            "inputUsdPerMillion": input_rate,
            "outputUsdPerMillion": output_rate,
            "maxOutputTokens": max_output_tokens,
            "estimatedUpperUsd": round(upper, 6),
        }
        total += upper
    return {
        "levels": rows,
        "totalInputTokens": sum(token_counts.values()),
        "estimatedUpperUsd": round(total, 6),
        "basis": "Gemini 3.1 Pro Preview standard list price; output estimate uses the configured per-request maximum and includes thinking/output billing within that allowance.",
    }


def actual_cost(
    usage: Mapping[str, Any], *, pricing_tier: str = DEFAULT_PRICING_TIER
) -> float:
    if pricing_tier == "free":
        return 0.0
    prompt = int(usage.get("promptTokenCount") or 0)
    output = int(usage.get("candidatesTokenCount") or 0)
    thoughts = int(usage.get("thoughtsTokenCount") or 0)
    input_rate, output_rate = price_for_prompt(prompt)
    return prompt * input_rate / 1_000_000 + (output + thoughts) * output_rate / 1_000_000


def _usage(response: Mapping[str, Any]) -> dict[str, Any]:
    value = response.get("usageMetadata")
    return dict(value) if isinstance(value, dict) else {}


def generate_validated_audit(
    client: GeminiClient,
    *,
    model: str,
    contents: Sequence[Mapping[str, Any]],
    schema: Mapping[str, Any],
    thinking_level: str,
    max_output_tokens: int,
    level: str,
    expected_ids: Sequence[str],
    validation_attempts: int = 2,
) -> tuple[dict[str, Any], dict[str, Any]]:
    last_error: Exception | None = None
    for attempt in range(1, validation_attempts + 1):
        response = client.generate(
            model=model,
            contents=contents,
            schema=schema,
            thinking_level=thinking_level,
            max_output_tokens=max_output_tokens,
        )
        try:
            model_result = json.loads(_extract_text(response))
            if not isinstance(model_result, dict):
                raise GeminiAuditError(f"{level.upper()} result must be an object")
            normalized = validate_model_audit(
                model_result, level=level, expected_ids=expected_ids
            )
            return response, normalized
        except (GeminiAuditError, json.JSONDecodeError) as error:
            last_error = error
            if attempt == validation_attempts:
                break
    raise GeminiAuditError(
        f"{level.upper()} failed structured-output validation after "
        f"{validation_attempts} attempts: {last_error}"
    ) from last_error


def render_summary(report: Mapping[str, Any]) -> str:
    summary = report["summary"]
    lines = [
        "# Gemini 정본 120개 다국어·레벨 감사",
        "",
        "> 이 결과는 자동 승인이나 런타임 승격 근거가 아닙니다. Jin의 120개 전체 검토가 필요합니다.",
        "",
        f"- 모델: `{report['model']}` (`{report['thinkingLevel']}` thinking)",
        f"- API 요금 모드: `{report['pricingTier']}`",
        f"- 후보 해시: `{report['candidateSetSha256']}`",
        f"- API 호출: {summary['requestCount']}회",
        f"- 입력 토큰: {summary['promptTokenCount']:,}",
        f"- 출력 토큰: {summary['candidatesTokenCount']:,}",
        f"- 사고 토큰: {summary['thoughtsTokenCount']:,}",
        f"- 추정 실제 비용: ${summary['estimatedActualUsd']:.4f}",
        f"- 판정: pass {summary['verdictCounts'].get('pass', 0)}, review {summary['verdictCounts'].get('review', 0)}, reject {summary['verdictCounts'].get('reject', 0)}",
        f"- findings: critical {summary['severityCounts'].get('critical', 0)}, major {summary['severityCounts'].get('major', 0)}, minor {summary['severityCounts'].get('minor', 0)}",
        "",
        "## 레벨별 결과",
        "",
        "| 레벨 | pass | review | reject | critical | major | minor | 비용(추정) |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    provenance = report.get("freeTierProvenance")
    if (
        isinstance(provenance, dict)
        and provenance.get("projectId")
        and provenance.get("apiKeyUid")
    ):
        lines[6:6] = [
            f"- 무료 프로젝트: `{provenance['projectId']}` (billing disabled 확인)",
            f"- API 키 UID: `{provenance['apiKeyUid']}`",
        ]
    for level in pipeline.LEVELS:
        row = report["levels"][level]
        lines.append(
            f"| {level.upper()} | {row['verdictCounts'].get('pass', 0)} | "
            f"{row['verdictCounts'].get('review', 0)} | {row['verdictCounts'].get('reject', 0)} | "
            f"{row['severityCounts'].get('critical', 0)} | {row['severityCounts'].get('major', 0)} | "
            f"{row['severityCounts'].get('minor', 0)} | ${row['estimatedActualUsd']:.4f} |"
        )
    lines.extend(("", "## 다음 게이트", "", "- 모델 findings를 Jin이 원문과 대조한다.", "- 수정할 후보만 별도 편집하고 DE/EN·퀘스트·TTS 해시를 함께 갱신한다.", "- 후보가 바뀌면 기존 TTS readiness 영수증은 다시 생성한다.", "- 자동 감사만으로 approval 또는 runtime promotion을 실행하지 않는다."))
    return "\n".join(lines).rstrip() + "\n"


def run(
    client: GeminiClient,
    *,
    candidate_directory: Path,
    output_directory: Path,
    model: str,
    thinking_level: str,
    max_output_tokens: int,
    max_estimated_usd: float,
    pricing_tier: str,
    estimate_only: bool,
    resume: bool,
    free_tier_provenance: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    if pricing_tier == "free" and model not in FREE_TIER_MODELS:
        raise GeminiAuditError(
            f"free-tier mode does not allow model {model!r}; "
            f"allowed={sorted(FREE_TIER_MODELS)}"
        )
    if pricing_tier == "free" and (
        not isinstance(free_tier_provenance, Mapping)
        or free_tier_provenance.get("billingEnabled") is not False
        or not free_tier_provenance.get("projectId")
        or not free_tier_provenance.get("apiKeyUid")
    ):
        raise GeminiAuditError("free-tier mode requires verified billing provenance")
    level_provenance = (
        {
            "freeTierProjectId": str(free_tier_provenance["projectId"]),
            "freeTierApiKeyUid": str(free_tier_provenance["apiKeyUid"]),
        }
        if pricing_tier == "free" and free_tier_provenance is not None
        else {}
    )
    sources = pipeline.load_sources(ROOT)
    all_candidates = pipeline.load_corpus_candidates(candidate_directory, root=ROOT)
    response_schema = audit_schema(relaxed=pricing_tier == "free")
    prepared: dict[
        str, tuple[list[dict[str, Any]], list[dict[str, Any]], str]
    ] = {}
    token_counts: dict[str, int] = {}
    for level in pipeline.LEVELS:
        candidates, payload = level_payload(
            level, candidate_directory=candidate_directory, root=ROOT
        )
        contents = contents_for_level(level, payload)
        request_hash = audit_request_hash(
            generation_id=sources.manifest.generation_id,
            model=model,
            thinking_level=thinking_level,
            max_output_tokens=max_output_tokens,
            contents=contents,
            schema=response_schema,
        )
        prepared[level] = (candidates, contents, request_hash)
        token_counts[level] = prompt_token_count_for_estimate(
            client,
            model=model,
            contents=contents,
            pricing_tier=pricing_tier,
        )

    estimate = estimate_cost(
        token_counts,
        max_output_tokens=max_output_tokens,
        pricing_tier=pricing_tier,
    )
    if estimate["estimatedUpperUsd"] > max_estimated_usd:
        raise GeminiAuditError(
            "cost gate rejected the run: "
            f"${estimate['estimatedUpperUsd']:.4f} > ${max_estimated_usd:.4f}"
        )
    if estimate_only:
        return {
            "schemaVersion": AUDIT_RECEIPT_SCHEMA_VERSION,
            "kind": "gemini_canonical_scenario_audit_estimate",
            "createdAt": _utc_now(),
            "model": model,
            "thinkingLevel": thinking_level,
            "pricingTier": pricing_tier,
            "freeTierProvenance": dict(free_tier_provenance or {}),
            "candidateSetSha256": pipeline.candidate_set_hash(all_candidates),
            "estimate": estimate,
            "paidGenerationCalls": 0,
        }

    output_directory.mkdir(parents=True, exist_ok=True)
    level_reports: dict[str, Any] = {}
    all_scenarios: list[dict[str, Any]] = []
    total_usage: Counter[str] = Counter()
    estimated_actual = 0.0
    for level in pipeline.LEVELS:
        candidates, contents, request_hash = prepared[level]
        expected_ids = [str(item["scenarioId"]) for item in candidates]
        level_path = output_directory / f"{level}.json"
        current_hash = pipeline.candidate_set_hash(candidates)
        existing: dict[str, Any] | None = None
        if resume and level_path.exists():
            value = pipeline.read_json(level_path)
            expected_fields = {
                "schemaVersion": AUDIT_RECEIPT_SCHEMA_VERSION,
                "kind": "gemini_canonical_scenario_level_audit",
                "model": model,
                "thinkingLevel": thinking_level,
                "pricingTier": pricing_tier,
                "level": level,
                "generationId": sources.manifest.generation_id,
                "candidateSetSha256": current_hash,
                "auditRequestSha256": request_hash,
                **level_provenance,
            }
            normalized = reusable_resume_audit(
                value,
                expected_fields=expected_fields,
                level=level,
                expected_ids=expected_ids,
            )
            if normalized is not None:
                existing = value
        if existing is not None:
            usage_value = existing.get("usageMetadata")
            usage = dict(usage_value) if isinstance(usage_value, dict) else {}
            level_cost = float(existing.get("estimatedActualUsd") or 0.0)
        else:
            response, normalized = generate_validated_audit(
                client,
                model=model,
                contents=contents,
                schema=response_schema,
                thinking_level=thinking_level,
                max_output_tokens=max_output_tokens,
                level=level,
                expected_ids=expected_ids,
            )
            usage = _usage(response)
            level_cost = actual_cost(usage, pricing_tier=pricing_tier)
        for key in (
            "promptTokenCount",
            "candidatesTokenCount",
            "thoughtsTokenCount",
            "totalTokenCount",
            "cachedContentTokenCount",
        ):
            total_usage[key] += int(usage.get(key) or 0)
        estimated_actual += level_cost
        verdict_counts = Counter(
            str(item["verdict"]) for item in normalized["scenarios"]
        )
        severity_counts = Counter(
            str(finding["severity"])
            for item in normalized["scenarios"]
            for finding in item["findings"]
        )
        if existing is None:
            level_report = {
                "schemaVersion": AUDIT_RECEIPT_SCHEMA_VERSION,
                "kind": "gemini_canonical_scenario_level_audit",
                "createdAt": _utc_now(),
                "model": model,
                "modelVersion": response.get("modelVersion"),
                "responseId": response.get("responseId"),
                "thinkingLevel": thinking_level,
                "pricingTier": pricing_tier,
                "level": level,
                "generationId": sources.manifest.generation_id,
                "candidateSetSha256": current_hash,
                "auditRequestSha256": request_hash,
                **level_provenance,
                "automatedAuditIsApproval": False,
                "humanApprovalRequired": True,
                "usageMetadata": usage,
                "estimatedActualUsd": round(level_cost, 6),
                "verdictCounts": dict(verdict_counts),
                "severityCounts": dict(severity_counts),
                "audit": normalized,
            }
            level_path.write_text(
                pipeline.json_text(level_report), encoding="utf-8"
            )
        else:
            level_report = existing
        level_reports[level] = {
            key: level_report[key]
            for key in (
                "candidateSetSha256",
                "auditRequestSha256",
                "modelVersion",
                "responseId",
                "usageMetadata",
                "estimatedActualUsd",
                "verdictCounts",
                "severityCounts",
            )
        }
        all_scenarios.extend(normalized["scenarios"])

    verdict_counts = Counter(str(item["verdict"]) for item in all_scenarios)
    severity_counts = Counter(
        str(finding["severity"])
        for item in all_scenarios
        for finding in item["findings"]
    )
    report = {
        "schemaVersion": AUDIT_RECEIPT_SCHEMA_VERSION,
        "kind": "gemini_canonical_scenario_corpus_audit",
        "createdAt": _utc_now(),
        "model": model,
        "thinkingLevel": thinking_level,
        "pricingTier": pricing_tier,
        "freeTierProvenance": dict(free_tier_provenance or {}),
        "generationId": sources.manifest.generation_id,
        "candidateSetSha256": pipeline.candidate_set_hash(all_candidates),
        "automatedAuditIsApproval": False,
        "humanApprovalRequired": True,
        "costEstimateBeforeRun": estimate,
        "summary": {
            "scenarioCount": len(all_scenarios),
            "requestCount": len(pipeline.LEVELS),
            "promptTokenCount": total_usage["promptTokenCount"],
            "candidatesTokenCount": total_usage["candidatesTokenCount"],
            "thoughtsTokenCount": total_usage["thoughtsTokenCount"],
            "totalTokenCount": total_usage["totalTokenCount"],
            "estimatedActualUsd": round(estimated_actual, 6),
            "verdictCounts": dict(verdict_counts),
            "severityCounts": dict(severity_counts),
        },
        "levels": level_reports,
    }
    (output_directory / "summary.json").write_text(
        pipeline.json_text(report), encoding="utf-8"
    )
    (output_directory / "summary.md").write_text(
        render_summary(report), encoding="utf-8"
    )
    return report


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    result.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    result.add_argument("--model", default=DEFAULT_MODEL)
    result.add_argument(
        "--pricing-tier",
        choices=("free", "paid"),
        default=DEFAULT_PRICING_TIER,
    )
    result.add_argument(
        "--free-tier-project-id",
        help="Billing-disabled Google Cloud project owning GEMINI_API_KEY",
    )
    result.add_argument(
        "--thinking-level",
        choices=("low", "medium", "high"),
        default=DEFAULT_THINKING_LEVEL,
    )
    result.add_argument(
        "--max-output-tokens", type=int, default=DEFAULT_MAX_OUTPUT_TOKENS
    )
    result.add_argument(
        "--max-estimated-usd", type=float, default=DEFAULT_MAX_ESTIMATED_USD
    )
    result.add_argument("--estimate-only", action="store_true")
    result.add_argument("--resume", action="store_true")
    return result


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    api_key = os.environ.get("GEMINI_API_KEY", "")
    client = GeminiClient(api_key)
    free_tier_provenance = None
    if args.pricing_tier == "free":
        free_tier_provenance = verify_free_tier_project(
            api_key, args.free_tier_project_id or ""
        )
    report = run(
        client,
        candidate_directory=args.candidates,
        output_directory=args.output_dir,
        model=args.model,
        thinking_level=args.thinking_level,
        max_output_tokens=args.max_output_tokens,
        max_estimated_usd=args.max_estimated_usd,
        pricing_tier=args.pricing_tier,
        estimate_only=args.estimate_only,
        resume=args.resume,
        free_tier_provenance=free_tier_provenance,
    )
    if args.estimate_only:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0
    print(
        json.dumps(
            {
                "scenarioCount": report["summary"]["scenarioCount"],
                "requestCount": report["summary"]["requestCount"],
                "estimatedActualUsd": report["summary"]["estimatedActualUsd"],
                "verdictCounts": report["summary"]["verdictCounts"],
                "severityCounts": report["summary"]["severityCounts"],
                "output": str(args.output_dir),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
