#!/usr/bin/env python3
"""Deterministic editorial pre-audit for the canonical 120-scenario corpus.

This script never approves content and never writes runtime assets.  It checks
structural, level, pragmatic-localization, address-form, extraction and locked
anchor contracts, then emits review evidence for Jin.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
import statistics
from typing import Any, Iterable, Mapping, Sequence

import scenario_corpus_pipeline as pipeline


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CANDIDATES = ROOT / "tools/content_factory/review/canonical_120_v1/candidates"
DEFAULT_JSON = ROOT / "tools/content_factory/review/canonical_120_v1/editorial_audit.json"
DEFAULT_MARKDOWN = ROOT / "tools/content_factory/review/canonical_120_v1/editorial_audit.md"

HANGUL_RE = re.compile(r"[가-힣ㄱ-ㅎㅏ-ㅣ]")
DE_DU_RE = re.compile(
    r"\b(?:du|dich|dir|dein(?:e|en|em|er|es)?|euch|euer(?:e|en|em|er|es)?)\b",
    re.IGNORECASE,
)
DE_SIE_RE = re.compile(
    r"\b(?:Sie|Ihnen|Ihr(?:e|en|em|er|es)?)\b"
)
DE_NEGATION_RE = re.compile(
    r"\b(?:nicht|kein(?:e|en|em|er|es)?|nein|nie|niemals|ohne|weder|fehlt|fehlte|"
    r"unmöglich|ausverkauft|vergess\w*|falsch|überseh\w*|schlecht|kaum|nur|statt|"
    r"verbot\w*|sonst|frei|müss\w*|unsichtbar\w*|schwierig|unvollständig\w*|unterlass\w*|"
    r"verhinder\w*|weniger|abgebroch\w*|schließ\w*|verdräng\w*|beschränk\w*|"
    r"verlier\w*|funktionier\w*|beeinträchtig\w*|neu\w*|ungewiss|unbekannt|nirgends|"
    r"nichts|bald|nervös|könnt\w*|transparent|lange|ungesichert\w*)\b",
    re.IGNORECASE,
)
EN_NEGATION_RE = re.compile(
    r"\b(?:not|no|none|never|without|missing|cannot|can't|won't|wouldn't|isn't|aren't|"
    r"wasn't|weren't|doesn't|don't|didn't|hasn't|haven't|hadn't|couldn't|out|forgot|lost|misread|"
    r"missed|instead|unable|hard|difficult|affect|worked|ban|need|only|remove|disappear|"
    r"cutting|review|incorrect|transparent|rather|delayed|incomplete|prevent|less|uncertain|"
    r"failed|recurr\w*|visible|seriously|left|afford|wrong|different|closed|restrict\w*|non-?urgent|"
    r"remov\w*|inconvenien\w*|nothing|more than|push\w*|took|soon|nervous|shouldn't)\b",
    re.IGNORECASE,
)

LOW_LEVEL_ABSTRACT_MARKERS = (
    "이해관계",
    "제도",
    "담론",
    "정당성",
    "프레이밍",
    "구조적",
    "비례성",
    "대표성",
    "책임 주체",
    "권한",
    "근거를 비교",
)
LOW_LEVEL_COMPLEX_PATTERNS = {
    "a1": (
        re.compile(r"(?:계신|있는|없는|하는|했는|됐는|왔는|갈|올|될)지"),
        re.compile(r"느라고|기 때문에|는 바람에|더라도|뿐만 아니라|다고 해서"),
    ),
    "a2": (
        re.compile(r"느라고|기 때문에|는 바람에|더라도|뿐만 아니라|다고 해서"),
        re.compile(r"전제로|환원(?:하|할|해서)"),
    ),
}
LOW_LEVEL_LOCKED_FORMULAS = frozenset(
    ("아, 죄송합니다. 줄 서 계신지 몰랐어요.",)
)
REJECTED_KO = (
    "대리 수치가 느껴",
    "전화번호",
    "한국인은 원래",
    "한국 사람들은 원래",
    "한국에서는 항상",
)
KNOWN_ARTIFICIAL_LINES = (
    "빨리 가 드릴까요?",
    "자동 결제 확인",
    "주소가 어떻게 되세요?",
)
METALINGUISTIC_SCENE_IDS = frozenset(
    ("dance_class_register", "partner_family_titles", "we_translation_identity")
)
EXPLAINING_KNOWN_FACT_PATTERNS = (
    "아시다시피",
    "이미 알고 계시겠지만",
    "전에 말씀드린 것처럼",
)

KO_PRESUPPOSITION = {
    "또": {
        "de": re.compile(r"\b(?:wieder|erneut|noch einmal|schon wieder|auch)\b", re.IGNORECASE),
        "en": re.compile(r"\b(?:again|another|once more|too|also)\b", re.IGNORECASE),
    },
    "다시": {
        "de": re.compile(r"\b(?:wieder|erneut|noch einmal|zurück|zweiten|neu\w*|Prüfung|überprüf\w*|zeigen|Lieferung)\b", re.IGNORECASE),
        "en": re.compile(r"\b(?:again|once more|back|repeat|redo\w*|reshoot\w*|redeliver\w*|review\w*|recheck\w*|reopen\w*|check\w*|show\w*)\b", re.IGNORECASE),
    },
    "아직": {
        "de": re.compile(r"\b(?:noch|bisher|Nichtwissen\w*|offen\w*|ungewiss|unbekannt)\b", re.IGNORECASE),
        "en": re.compile(r"\b(?:still|yet|so far|haven't|hasn't|unknown|remains|open|unidentified|identified)\b", re.IGNORECASE),
    },
    "벌써": {
        "de": re.compile(r"\b(?:schon|bereits)\b", re.IGNORECASE),
        "en": re.compile(r"\b(?:already|so soon)\b", re.IGNORECASE),
    },
    "계속": {
        "de": re.compile(r"\b(?:weiter|weiterhin|ständig|immer|bleibt|durchgehend|eine Weile)\b", re.IGNORECASE),
        "en": re.compile(r"\b(?:keep|continu\w*|still|constantly|kept|remains|throughout|for a while)\b", re.IGNORECASE),
    },
}

LOCKED_ANCHOR_BEATS = {
    "bakery_queue": (
        "여기 줄 서 있는데요",
        "아, 죄송합니다. 줄 서 계신지 몰랐어요",
    ),
    "email_attachment_twice": ("첨부파일을 또 안 붙였어요",),
    "company_instagram_wrong_account": ("회사 인스타그램 계정",),
    "filming_permission": ("촬영", "괜찮"),
    "fremdschaemen_live": ("내가 다 민망", "보는 내가 다 부끄러"),
    "after_hours_messages": ("언제 답해야 한다고 기대하는지가 더 중요합니다",),
    "hidden_gem_local_impact": ("숨은 명소",),
    "taxi_slow_down": ("기사님, 천천히 좀 가 주실 수 있을까요?",),
}


def _map(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise pipeline.CorpusError(f"{label} must be an object")
    return value


def _finding(
    severity: str,
    code: str,
    scenario_id: str,
    path: str,
    message: str,
    evidence: str = "",
) -> dict[str, str]:
    return {
        "severity": severity,
        "code": code,
        "scenarioId": scenario_id,
        "path": path,
        "message": message,
        "evidence": evidence,
    }


def _percentile(values: Sequence[int], fraction: float) -> int:
    if not values:
        return 0
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, round((len(ordered) - 1) * fraction)))
    return ordered[index]


def _resolved_speaker(speaker: str, brief: pipeline.ScenarioBrief) -> str:
    return brief.player_character_id if speaker == "user" else speaker


def _contains_ko_negation(text: str) -> bool:
    if "안녕" in text:
        text = text.replace("안녕", "")
    return bool(re.search(r"(?:\b안\b|못|없|아니|않|말아|금지)", text))


def _localized_option_text(option: Any, language: str) -> str:
    return str(option.get(language) or "") if isinstance(option, dict) else str(option or "")


def _quest_findings(
    scenario_id: str,
    scenario: Mapping[str, Any],
) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    dialog = [
        _map(line, f"{scenario_id}.dialog") for line in scenario.get("dialog", [])
    ]
    ko_lines = {str(line.get("ko") or "") for line in dialog}
    localized_pairs = {
        (str(line.get("de") or ""), str(line.get("en") or "")): str(line.get("ko") or "")
        for line in dialog
    }
    for index, raw_quest in enumerate(scenario.get("quests", [])):
        quest = _map(raw_quest, f"{scenario_id}.quests[{index}]")
        data = _map(quest.get("data"), f"{scenario_id}.quests[{index}].data")
        quest_type = str(quest.get("type") or "")
        path = f"/scenario/quests/{index}"
        if quest_type == "hoerverstehen":
            audio = str(data.get("audioKo") or "")
            if audio not in ko_lines:
                findings.append(_finding("error", "quest_not_extracted", scenario_id, path, "Listening audio is not an attested dialogue line.", audio))
            options = data.get("options", [])
            correct = data.get("correctIndex")
            if isinstance(options, list) and isinstance(correct, int) and 0 <= correct < len(options):
                option = options[correct]
                pair = (_localized_option_text(option, "de"), _localized_option_text(option, "en"))
                if localized_pairs.get(pair) != audio:
                    findings.append(_finding("error", "quest_answer_drift", scenario_id, path, "Listening answer does not match the same localized dialogue turn.", json.dumps(option, ensure_ascii=False)))
        elif quest_type == "uebersetzen":
            pair = (str(data.get("promptDe") or ""), str(data.get("promptEn") or ""))
            expected_ko = localized_pairs.get(pair)
            if expected_ko is None:
                findings.append(_finding("error", "quest_not_extracted", scenario_id, path, "Translation prompt is not an attested DE/EN dialogue pair.", str(pair)))
            options = data.get("options", [])
            correct = data.get("correctIndex")
            if isinstance(options, list) and isinstance(correct, int) and 0 <= correct < len(options):
                actual_ko = _localized_option_text(options[correct], "ko")
                if expected_ko != actual_ko:
                    findings.append(_finding("error", "quest_answer_drift", scenario_id, path, "Translation answer is not the Korean source of its prompt.", actual_ko))
        elif quest_type == "satzBauen":
            target = str(data.get("targetKo") or "")
            if target not in ko_lines:
                findings.append(_finding("error", "quest_not_extracted", scenario_id, path, "Sentence-building target is not an attested dialogue line.", target))
    return findings


def audit_corpus(
    candidate_directory: Path = DEFAULT_CANDIDATES,
    *,
    root: Path = ROOT,
) -> dict[str, Any]:
    sources = pipeline.load_sources(root)
    candidates = pipeline.load_corpus_candidates(candidate_directory, root=root)
    findings: list[dict[str, str]] = []
    level_lengths: dict[str, list[int]] = defaultdict(list)
    level_turns: Counter[str] = Counter()
    opener_counts: Counter[str] = Counter()
    script_fingerprints: dict[str, str] = {}
    culture_note_count = 0
    german_address_observations: dict[str, dict[str, Any]] = {}

    for payload in candidates:
        scenario_id = str(payload["scenarioId"])
        brief = next(item for item in sources.briefs if item.scenario_id == scenario_id)
        scenario = _map(payload.get("scenario"), f"{scenario_id}.scenario")
        level = brief.level
        dialog = [_map(line, f"{scenario_id}.dialog") for line in scenario.get("dialog", [])]
        level_turns[level] += len(dialog)
        if len(dialog) < 6:
            findings.append(_finding("error", "dialogue_too_short", scenario_id, "/scenario/dialog", "A canonical scene needs at least six turns to establish an event and repair."))

        resolved_counts: Counter[str] = Counter()
        ko_lines: list[str] = []
        previous_speaker = ""
        same_speaker_run = 0
        speaker_address: dict[str, set[str]] = defaultdict(set)
        for index, line in enumerate(dialog):
            speaker = str(line.get("speaker") or "")
            resolved = _resolved_speaker(speaker, brief)
            resolved_counts[resolved] += 1
            ko = str(line.get("ko") or "").strip()
            de = str(line.get("de") or "").strip()
            en = str(line.get("en") or "").strip()
            ko_lines.append(ko)
            level_lengths[level].append(len(ko))
            if index == 0:
                opener = re.split(r"[.!?…]", ko, maxsplit=1)[0].strip()
                if opener:
                    opener_counts[opener] += 1

            if speaker == previous_speaker:
                same_speaker_run += 1
            else:
                same_speaker_run = 1
                previous_speaker = speaker
            if same_speaker_run >= 3:
                findings.append(_finding("warning", "turn_taking_run", scenario_id, f"/scenario/dialog/{index}", "The same speaker has three consecutive turns; verify that this is a real exchange.", ko))
            if index and ko == ko_lines[index - 1]:
                findings.append(_finding("error", "adjacent_duplicate_turn", scenario_id, f"/scenario/dialog/{index}", "Adjacent Korean turns are identical.", ko))

            for phrase in REJECTED_KO + KNOWN_ARTIFICIAL_LINES:
                if phrase in ko:
                    findings.append(_finding("error", "rejected_korean", scenario_id, f"/scenario/dialog/{index}/ko", "Rejected or artificial Korean wording is present.", phrase))
            for phrase in EXPLAINING_KNOWN_FACT_PATTERNS:
                if phrase in ko:
                    findings.append(_finding("warning", "explains_known_fact", scenario_id, f"/scenario/dialog/{index}/ko", "Verify that the speaker is not explaining something both participants already know.", ko))
            if level in ("a1", "a2"):
                for marker in LOW_LEVEL_ABSTRACT_MARKERS:
                    if marker in ko:
                        findings.append(_finding("error", "low_level_abstract_scope", scenario_id, f"/scenario/dialog/{index}/ko", f"{level.upper()} contains an abstract-scope marker.", marker))
                for expression in LOW_LEVEL_COMPLEX_PATTERNS[level]:
                    if expression.search(ko) and ko not in LOW_LEVEL_LOCKED_FORMULAS:
                        findings.append(_finding("warning", "low_level_complex_form", scenario_id, f"/scenario/dialog/{index}/ko", f"Review whether this structure is necessary at {level.upper()}; natural formulaic input may be retained, but learner production should stay within the level profile.", ko))
                warning_limit = int(sources.level_profiles[level].allowed_language["maxKoCharsWarning"])
                if len(ko) > warning_limit:
                    findings.append(_finding("warning", "low_level_length", scenario_id, f"/scenario/dialog/{index}/ko", f"Korean turn length {len(ko)} exceeds the {warning_limit}-character review warning; length alone is not a rejection.", ko))

            if ko.endswith("?") and ("?" not in de or "?" not in en):
                findings.append(_finding("error", "question_force_drift", scenario_id, f"/scenario/dialog/{index}", "A Korean question is not a question in both localizations.", f"KO={ko} | DE={de} | EN={en}"))
            if ("죄송" in ko or "미안" in ko) and not (
                re.search(r"(?:Entschuld|leid)", de, re.IGNORECASE)
                and re.search(r"(?:sorry|apolog|excuse me)", en, re.IGNORECASE)
            ):
                findings.append(_finding("error", "apology_force_drift", scenario_id, f"/scenario/dialog/{index}", "The Korean apology is not preserved in both localizations.", f"KO={ko} | DE={de} | EN={en}"))
            if ("감사" in ko or "고마" in ko) and not (
                re.search(r"\bdanke\b", de, re.IGNORECASE)
                and re.search(r"\bthank", en, re.IGNORECASE)
            ):
                findings.append(_finding("warning", "thanks_force_review", scenario_id, f"/scenario/dialog/{index}", "Review whether gratitude is preserved naturally in both localizations.", f"KO={ko} | DE={de} | EN={en}"))
            if _contains_ko_negation(ko) and not DE_NEGATION_RE.search(de):
                findings.append(_finding("warning", "de_polarity_review", scenario_id, f"/scenario/dialog/{index}/de", "Korean contains a negative proposition but German has no obvious negative marker.", f"KO={ko} | DE={de}"))
            if _contains_ko_negation(ko) and not EN_NEGATION_RE.search(en):
                findings.append(_finding("warning", "en_polarity_review", scenario_id, f"/scenario/dialog/{index}/en", "Korean contains a negative proposition but English has no obvious negative marker.", f"KO={ko} | EN={en}"))
            for marker, patterns in KO_PRESUPPOSITION.items():
                if marker in ko:
                    if not patterns["de"].search(de):
                        findings.append(_finding("warning", "de_presupposition_review", scenario_id, f"/scenario/dialog/{index}/de", f"Review whether Korean presupposition marker {marker!r} is preserved.", f"KO={ko} | DE={de}"))
                    if not patterns["en"].search(en):
                        findings.append(_finding("warning", "en_presupposition_review", scenario_id, f"/scenario/dialog/{index}/en", f"Review whether Korean presupposition marker {marker!r} is preserved.", f"KO={ko} | EN={en}"))
            if (
                (HANGUL_RE.search(de) or HANGUL_RE.search(en))
                and scenario_id not in METALINGUISTIC_SCENE_IDS
            ):
                findings.append(_finding("warning", "localization_hangul_review", scenario_id, f"/scenario/dialog/{index}", "DE or EN retains Korean wording; verify that the scene is intentionally metalinguistic.", f"DE={de} | EN={en}"))

            address_text = re.sub(r"[„\"«][^“\"»]*[“\"»]", "", de)
            if DE_DU_RE.search(address_text):
                speaker_address[resolved].add("du")
            if DE_SIE_RE.search(address_text):
                speaker_address[resolved].add("Sie")

        expected_participants = set(brief.participant_ids)
        missing_participants = sorted(expected_participants - set(resolved_counts))
        if missing_participants:
            findings.append(_finding("error", "missing_participant_voice", scenario_id, "/scenario/dialog", "A locked participant never speaks.", ", ".join(missing_participants)))
        if resolved_counts[brief.player_character_id] < 2:
            findings.append(_finding("error", "player_has_no_exchange", scenario_id, "/scenario/dialog", "The player character needs at least two turns.", str(resolved_counts[brief.player_character_id])))
        if not any(count >= 2 for participant, count in resolved_counts.items() if participant != brief.player_character_id):
            findings.append(_finding("error", "counterpart_has_no_exchange", scenario_id, "/scenario/dialog", "At least one counterpart needs two turns.", str(dict(resolved_counts))))

        for speaker, modes in speaker_address.items():
            if modes == {"du", "Sie"}:
                findings.append(_finding("warning", "de_mixed_address_by_speaker", scenario_id, "/scenario/dialog", "The same speaker uses both du and Sie forms; verify addressee and relationship.", speaker))
        scene_modes = set().union(*speaker_address.values()) if speaker_address else set()
        german_address_observations[scenario_id] = {
            "relationship": str(brief.raw.get("relationship") or ""),
            "koreanRegister": str(scenario.get("register") or ""),
            "observedModes": sorted(scene_modes) if scene_modes else ["neutral"],
            "bySpeaker": {
                speaker: sorted(modes)
                for speaker, modes in sorted(speaker_address.items())
            },
            "status": "review_required",
        }
        if len(brief.participant_ids) == 2 and scene_modes == {"du", "Sie"}:
            findings.append(_finding("warning", "de_two_person_address_switch", scenario_id, "/scenario/dialog", "A two-person scene contains both du and Sie address markers.", json.dumps({key: sorted(value) for key, value in speaker_address.items()}, ensure_ascii=False)))

        fingerprint = "\n".join(ko_lines)
        previous = script_fingerprints.get(fingerprint)
        if previous is not None:
            findings.append(_finding("error", "duplicate_scene_script", scenario_id, "/scenario/dialog", "Two release scenarios have identical Korean scripts.", previous))
        script_fingerprints[fingerprint] = scenario_id

        joined_ko = "\n".join(ko_lines)
        for beat in LOCKED_ANCHOR_BEATS.get(scenario_id, ()):
            if beat not in joined_ko:
                findings.append(_finding("error", "anchor_beat_missing", scenario_id, "/scenario/dialog", "A user-locked anchor beat is missing.", beat))
        if scenario_id == "taxi_slow_down":
            for unwanted in ("자동", "결제", "빨리 가", "주소", "전화", "핸드폰 번호"):
                if unwanted in joined_ko:
                    findings.append(_finding("error", "taxi_artificial_content", scenario_id, "/scenario/dialog", "The taxi scene contains content explicitly excluded by Jin.", unwanted))

        dialog_ko = set(ko_lines)
        for index, raw_vocab in enumerate(scenario.get("vocab", [])):
            vocab = _map(raw_vocab, f"{scenario_id}.vocab[{index}]")
            korean = str(vocab.get("korean") or "")
            if korean not in dialog_ko:
                findings.append(_finding("error", "vocab_not_extracted", scenario_id, f"/scenario/vocab/{index}", "Vocabulary was not extracted from an attested dialogue turn.", korean))
        findings.extend(_quest_findings(scenario_id, scenario))

        culture_note = scenario.get("culturalNote")
        if culture_note is not None:
            culture_note_count += 1
            note_text = json.dumps(culture_note, ensure_ascii=False)
            for phrase in REJECTED_KO:
                if phrase in note_text:
                    findings.append(_finding("error", "culture_generalization", scenario_id, "/scenario/culturalNote", "Culture note makes a fixed national generalization.", phrase))

    repeated_openers = [
        {"text": text, "count": count}
        for text, count in opener_counts.most_common()
        if count >= 4 and text != "안녕하세요"
    ]
    for row in repeated_openers:
        findings.append(_finding("warning", "repeated_scene_opener", "_corpus", "/scenario/dialog/0", "The same scene opener appears four or more times; review for formulaic generation.", f"{row['text']} × {row['count']}"))

    errors = [item for item in findings if item["severity"] == "error"]
    warnings = [item for item in findings if item["severity"] == "warning"]
    length_metrics = {
        level: {
            "turnCount": len(level_lengths[level]),
            "meanKoChars": round(statistics.mean(level_lengths[level]), 2),
            "p95KoChars": _percentile(level_lengths[level], 0.95),
            "maxKoChars": max(level_lengths[level], default=0),
        }
        for level in pipeline.LEVELS
    }
    return {
        "schemaVersion": 1,
        "kind": "canonical_scenario_editorial_audit",
        "generationId": sources.manifest.generation_id,
        "candidateSetSha256": pipeline.candidate_set_hash(candidates),
        "humanApprovalRequired": True,
        "humanApprovalRecorded": False,
        "automatedAuditIsApproval": False,
        "summary": {
            "ok": not errors,
            "scenarioCount": len(candidates),
            "levelScenarioCounts": dict(Counter(str(item["scenario"]["level"]) for item in candidates)),
            "dialogTurnCounts": dict(level_turns),
            "cultureNoteCount": culture_note_count,
            "errorCount": len(errors),
            "warningCount": len(warnings),
        },
        "lengthMetrics": length_metrics,
        "repeatedOpeners": repeated_openers,
        "germanAddressPolicy": {
            "scope": "scene_relationship_not_global_brand_voice",
            "mixedSpeakerCount": sum(
                1
                for row in german_address_observations.values()
                if any(set(modes) == {"du", "Sie"} for modes in row["bySpeaker"].values())
            ),
            "scenes": german_address_observations,
        },
        "errors": errors,
        "warnings": warnings,
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    summary = _map(report.get("summary"), "audit.summary")
    lines = [
        "# 정본 120개 자동 편집 감사",
        "",
        "> 이 문서는 Jin 승인이 아닙니다. 자동 검사는 검토 대상을 좁히고 계약 위반을 잡을 뿐입니다.",
        "",
        f"- 후보 해시: `{report.get('candidateSetSha256')}`",
        f"- 시나리오: {summary.get('scenarioCount')}개",
        f"- 오류: {summary.get('errorCount')}개",
        f"- 검토 경고: {summary.get('warningCount')}개",
        f"- 문화 노트: {summary.get('cultureNoteCount')}개",
        "",
        "## 레벨별 길이 지표",
        "",
        "| 레벨 | 대사 수 | 평균 글자 | 95% | 최대 |",
        "|---|---:|---:|---:|---:|",
    ]
    for level in pipeline.LEVELS:
        row = report["lengthMetrics"][level]
        lines.append(
            f"| {level.upper()} | {row['turnCount']} | {row['meanKoChars']} | {row['p95KoChars']} | {row['maxKoChars']} |"
        )
    for title, key in (("오류", "errors"), ("검토 경고", "warnings")):
        lines.extend(("", f"## {title}", ""))
        items = report.get(key, [])
        if not items:
            lines.append("- 없음")
            continue
        grouped: dict[str, list[Mapping[str, Any]]] = defaultdict(list)
        for item in items:
            grouped[str(item.get("code"))].append(item)
        for code in sorted(grouped):
            lines.extend((f"### `{code}` ({len(grouped[code])})", ""))
            for item in grouped[code]:
                evidence = str(item.get("evidence") or "")
                suffix = f" — {evidence}" if evidence else ""
                lines.append(
                    f"- `{item.get('scenarioId')}` `{item.get('path')}`: {item.get('message')}{suffix}"
                )
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    result.add_argument("--json-output", type=Path, default=DEFAULT_JSON)
    result.add_argument("--markdown-output", type=Path, default=DEFAULT_MARKDOWN)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    report = audit_corpus(args.candidates, root=ROOT)
    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    args.markdown_output.parent.mkdir(parents=True, exist_ok=True)
    args.json_output.write_text(pipeline.json_text(report), encoding="utf-8")
    args.markdown_output.write_text(render_markdown(report), encoding="utf-8")
    print(
        json.dumps(
            {
                "ok": report["summary"]["ok"],
                "scenarioCount": report["summary"]["scenarioCount"],
                "errorCount": report["summary"]["errorCount"],
                "warningCount": report["summary"]["warningCount"],
                "json": str(args.json_output),
                "markdown": str(args.markdown_output),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0 if report["summary"]["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
