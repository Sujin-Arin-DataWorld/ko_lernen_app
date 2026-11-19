from __future__ import annotations

import argparse
import collections
import csv
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
TAXONOMY_PATH = ROOT / "tools/content_factory/cefr_matrix/taxonomy.json"
OUT_PATH = (
    ROOT
    / "tools/content_factory/review"
    / "trilingual_content_topic_coverage_20261006.json"
)
NATIVE_USAGE_REGISTRY_PATH = (
    ROOT
    / "tools/content_factory/canonical_scenarios"
    / "trilingual_native_usage_registry_20261006.json"
)

LIVE_SCENARIO_PATHS = [
    ROOT / f"assets/data/scenarios_{level}.json"
    for level in ("a1", "a2", "b1", "b2", "c1", "c2")
]
LISTENING_PATH = ROOT / "assets/data/listening_lessons.json"
SMALLTALK_PATH = ROOT / "assets/data/smalltalk_lessons.json"
CLOZE_PATH = ROOT / "assets/data/cloze.json"
SATZ_PATH = ROOT / "assets/data/satz_sentences.json"
VOCAB_PATH = ROOT / "assets/data/korean_vocab.csv"
SCENARIO_BRIEFS_PATH = (
    ROOT / "tools/content_factory/canonical_scenarios/scenario_briefs.json"
)
CULTURE_LINKS_PATH = ROOT / "assets/data/scenario_culture_links.json"
CULTURE_ARCS_PATH = ROOT / "assets/data/culture_story_arcs.json"
LIVING_KOREA_PATHS = [
    ROOT
    / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json",
    ROOT
    / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json",
]
DRAFT_DIR = ROOT / "tools/content_factory/drafts"

LIVING_KOREA_TOPIC_MAP: dict[str, tuple[str, list[str], str]] = {
    "cyber_privacy_credentials_2026": (
        "technology_digital_ai",
        ["communication_phone_digital"],
        "cyber_privacy_credentials",
    ),
    "ai_transparency_2026": (
        "technology_digital_ai",
        ["media_entertainment_culture_pop"],
        "ai_transparency",
    ),
    "school_smartphone_rules_2026": (
        "education_study",
        ["technology_digital_ai"],
        "school_smartphone_rules",
    ),
    "reduced_work_hours_45_2026": (
        "work_career",
        ["economy_business_labour"],
        "shorter_working_week",
    ),
    "work_family_demography_2025_2026": (
        "society_current_affairs",
        ["family_relationships", "work_career"],
        "work_family_demography",
    ),
    "minimum_wage_small_business_2026": (
        "economy_business_labour",
        ["money_finance_contracts", "work_career"],
        "minimum_wage_small_business",
    ),
    "tourism_local_life_2026": (
        "neighbourhood_environment",
        ["travel_accommodation", "society_current_affairs"],
        "tourism_local_life",
    ),
    "hallyu_diversification_2026": (
        "media_entertainment_culture_pop",
        ["intercultural_globalisation_migration"],
        "hallyu_diversification",
    ),
    "apec_gyeongju_2025": (
        "arts_literature_history",
        ["society_current_affairs"],
        "gyeongju_after_apec",
    ),
    "voice_phishing_digital_safety_2026": (
        "technology_digital_ai",
        ["communication_phone_digital"],
        "delivery_voice_phishing",
    ),
    "heatwave_electricity_safety_2026": (
        "weather_nature_climate",
        ["health_body", "technology_digital_ai"],
        "heatwave_electricity_safety",
    ),
}


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _norm(value: object) -> str:
    text = str(value or "").strip().lower()
    text = re.sub(r"[_/\\-]+", " ", text)
    return re.sub(r"\s+", " ", text)


def _contains_keyword(text: str, keyword: str) -> bool:
    text = _norm(text)
    keyword = _norm(keyword)
    if not keyword:
        return False
    if all(ord(ch) < 128 for ch in keyword):
        # ASCII pack/title keywords such as "ai" must match a token/phrase,
        # never an arbitrary substring such as the "ai" inside "train".
        return f" {keyword} " in f" {text} "
    return keyword in text


class TopicResolver:
    def __init__(self, taxonomy: dict[str, Any]) -> None:
        self.topics = taxonomy["topics"]
        self.topic_ids = {row["id"] for row in self.topics}
        self.exact: dict[str, dict[str, set[str]]] = {
            key: collections.defaultdict(set)
            for key in ("vocabTopics", "shelfSlugs", "smalltalkCategories")
        }
        self.title_keywords: list[tuple[str, str]] = []
        self.pack_keywords: list[tuple[str, str]] = []
        for topic in self.topics:
            aliases = topic.get("appAliases", {})
            for key in self.exact:
                for alias in aliases.get(key, []):
                    self.exact[key][_norm(alias)].add(topic["id"])
            for alias in aliases.get("titleKeywords", []):
                self.title_keywords.append((_norm(alias), topic["id"]))
            for alias in aliases.get("packKeywords", []):
                self.pack_keywords.append((_norm(alias), topic["id"]))

    def exact_one(self, kind: str, value: object) -> str | None:
        candidates = self.exact[kind].get(_norm(value), set())
        if len(candidates) == 1:
            return next(iter(candidates))
        return None

    def keyword_resolution(
        self,
        *,
        title_text: str = "",
        context_text: str = "",
    ) -> tuple[str | None, dict[str, Any]]:
        scores: collections.Counter[str] = collections.Counter()
        hits: dict[str, list[str]] = collections.defaultdict(list)

        for keyword, topic_id in self.title_keywords:
            if _contains_keyword(title_text, keyword):
                scores[topic_id] += 6
                hits[topic_id].append(f"title:{keyword}")
            elif _contains_keyword(context_text, keyword):
                scores[topic_id] += 3
                hits[topic_id].append(f"context:{keyword}")

        for keyword, topic_id in self.pack_keywords:
            if _contains_keyword(context_text, keyword):
                scores[topic_id] += 2
                hits[topic_id].append(f"pack:{keyword}")

        if not scores:
            return None, {
                "reason": "no_taxonomy_alias_or_keyword_match",
                "hits": {},
            }

        ranked = scores.most_common()
        if len(ranked) > 1 and ranked[0][1] == ranked[1][1]:
            return None, {
                "reason": "top_topic_score_tie",
                "scores": dict(scores),
                "hits": dict(hits),
            }

        topic_id, score = ranked[0]
        runner_up = ranked[1][1] if len(ranked) > 1 else 0
        # For weak ASCII-only evidence, keep the row explicit-unmapped rather
        # than making a confident-looking guess.
        if score < 3 or score - runner_up < 2:
            return None, {
                "reason": "topic_score_margin_too_small",
                "scores": dict(scores),
                "hits": dict(hits),
            }
        return topic_id, {
            "reason": "weighted_taxonomy_keyword_match",
            "score": score,
            "runnerUpScore": runner_up,
            "hits": dict(hits),
        }


def _register_lane(row: dict[str, Any], kind: str) -> str:
    register = str(row.get("register") or row.get("speechStyle") or "").lower()
    if register in {"formal", "deferential"}:
        return "professional_or_institutional"
    if register in {"casual", "banmal", "informal"}:
        return "everyday_casual"
    if register in {"polite", "haeyo"}:
        return "relationship_or_service"
    if kind in {"cloze", "satz", "vocab", "listening", "smalltalk"}:
        return "pedagogical_or_mixed"
    return "mixed_or_unspecified"


def _record(
    *,
    kind: str,
    item_id: str,
    source_path: Path,
    approval_state: str,
    topic_id: str | None,
    mapping_method: str,
    mapping_evidence: dict[str, Any] | None = None,
    secondary_topic_ids: list[str] | None = None,
    subtopic_id: str | None = None,
    register_lane: str = "mixed_or_unspecified",
    unmapped_reason: str | None = None,
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "kind": kind,
        "itemId": item_id,
        "sourcePath": source_path.relative_to(ROOT).as_posix(),
        "approvalState": approval_state,
        "canonicalTopicId": topic_id,
        "secondaryCanonicalTopicIds": sorted(set(secondary_topic_ids or [])),
        "subtopicId": subtopic_id,
        "registerLane": register_lane,
        "mappingMethod": mapping_method,
        "mappingEvidence": mapping_evidence or {},
        "researchCoverageStatus": (
            "topic_profile_pending_deep_pass"
            if topic_id
            else "manual_topic_review_required"
        ),
    }
    if topic_id is None:
        row["unmappedReason"] = unmapped_reason or "no_confident_mapping"
    return row


def build() -> dict[str, Any]:
    taxonomy = _load_json(TAXONOMY_PATH)
    resolver = TopicResolver(taxonomy)
    records: list[dict[str, Any]] = []

    # Live scenarios first so downstream surfaces can inherit exact scenario
    # mappings instead of independently guessing from translated copy.
    live_scenario_topic: dict[str, str | None] = {}
    live_scenario_evidence: dict[str, dict[str, Any]] = {}
    for path in LIVE_SCENARIO_PATHS:
        payload = _load_json(path)
        for row in payload["scenarios"]:
            title = " ".join(str(v) for v in (row.get("title") or {}).values())
            context = " ".join(
                [
                    row.get("id", ""),
                    row.get("shelf", ""),
                    row.get("courseUnitId", ""),
                    row.get("intent", ""),
                    *[str(v) for v in (row.get("intro") or {}).values()],
                ]
            )
            topic_id, evidence = resolver.keyword_resolution(
                title_text=title,
                context_text=context,
            )
            if topic_id is None:
                stripped_shelf = re.sub(
                    r"^[abc][12]_",
                    "",
                    _norm(row.get("shelf")),
                )
                shelf_topic = resolver.exact_one("shelfSlugs", stripped_shelf)
                if shelf_topic:
                    topic_id = shelf_topic
                    evidence = {
                        "reason": "unique_stripped_shelf_alias",
                        "shelf": row.get("shelf"),
                        "normalizedShelf": stripped_shelf,
                    }

            live_scenario_topic[row["id"]] = topic_id
            live_scenario_evidence[row["id"]] = evidence
            records.append(
                _record(
                    kind="scenario",
                    item_id=row["id"],
                    source_path=path,
                    approval_state="live",
                    topic_id=topic_id,
                    mapping_method=evidence.get("reason", "unknown"),
                    mapping_evidence=evidence,
                    register_lane=_register_lane(row, "scenario"),
                    unmapped_reason=evidence.get("reason"),
                )
            )

    # Listening lessons inherit their source scenario's taxonomy where possible.
    for row in _load_json(LISTENING_PATH)["lessons"]:
        candidates = {
            live_scenario_topic.get(source_id)
            for source_id in row.get("contentIds", [])
            if live_scenario_topic.get(source_id)
        }
        topic_id = next(iter(candidates)) if len(candidates) == 1 else None
        if topic_id:
            evidence = {
                "reason": "source_scenario_topic_inheritance",
                "contentIds": row.get("contentIds", []),
            }
        else:
            title = " ".join(str(v) for v in (row.get("title") or {}).values())
            context = " ".join(
                [
                    row.get("id", ""),
                    row.get("topicId", ""),
                    *[str(v) for v in (row.get("intro") or {}).values()],
                ]
            )
            topic_id, evidence = resolver.keyword_resolution(
                title_text=title,
                context_text=context,
            )
        records.append(
            _record(
                kind="listening",
                item_id=row["id"],
                source_path=LISTENING_PATH,
                approval_state="live",
                topic_id=topic_id,
                mapping_method=evidence.get("reason", "unknown"),
                mapping_evidence=evidence,
                register_lane="pedagogical_or_mixed",
                unmapped_reason=evidence.get("reason"),
            )
        )

    # Smalltalk lessons primarily have compact category ids. Fall back to title
    # / intro evidence only when the category is not in the taxonomy aliases.
    for row in _load_json(SMALLTALK_PATH)["lessons"]:
        topic_id = resolver.exact_one("smalltalkCategories", row.get("topicId"))
        if topic_id:
            evidence = {
                "reason": "exact_smalltalk_category_alias",
                "topicId": row.get("topicId"),
            }
        else:
            title = " ".join(str(v) for v in (row.get("title") or {}).values())
            context = " ".join(
                [
                    row.get("id", ""),
                    row.get("topicId", ""),
                    *[str(v) for v in (row.get("intro") or {}).values()],
                ]
            )
            topic_id, evidence = resolver.keyword_resolution(
                title_text=title,
                context_text=context,
            )
        records.append(
            _record(
                kind="smalltalk",
                item_id=row["id"],
                source_path=SMALLTALK_PATH,
                approval_state="live",
                topic_id=topic_id,
                mapping_method=evidence.get("reason", "unknown"),
                mapping_evidence=evidence,
                register_lane="pedagogical_or_mixed",
                unmapped_reason=evidence.get("reason"),
            )
        )

    # Vocab rows provide the strongest topic metadata for cloze and Satz.
    vocab_rows: list[dict[str, str]] = []
    vocab_topic_by_korean: dict[str, set[str]] = collections.defaultdict(set)
    with VOCAB_PATH.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            vocab_rows.append(row)
            topic_id = resolver.exact_one("vocabTopics", row.get("topic"))
            if topic_id:
                evidence = {
                    "reason": "exact_vocab_topic_alias",
                    "topic": row.get("topic"),
                }
            else:
                title = row.get("korean", "")
                context = " ".join(
                    [
                        row.get("topic", ""),
                        row.get("pack_id", ""),
                        row.get("german", ""),
                        row.get("english", ""),
                    ]
                )
                topic_id, evidence = resolver.keyword_resolution(
                    title_text=title,
                    context_text=context,
                )
            if topic_id:
                vocab_topic_by_korean[_norm(row.get("korean"))].add(topic_id)
            records.append(
                _record(
                    kind="vocab",
                    item_id=row["id"],
                    source_path=VOCAB_PATH,
                    approval_state="live",
                    topic_id=topic_id,
                    mapping_method=evidence.get("reason", "unknown"),
                    mapping_evidence=evidence,
                    register_lane="pedagogical_or_mixed",
                    unmapped_reason=evidence.get("reason"),
                )
            )

    for row in _load_json(CLOZE_PATH)["items"]:
        topic_id = resolver.exact_one("vocabTopics", row.get("topic"))
        if topic_id:
            evidence = {
                "reason": "exact_cloze_topic_alias",
                "topic": row.get("topic"),
            }
        else:
            topic_id, evidence = resolver.keyword_resolution(
                title_text=row.get("fullKo", ""),
                context_text=" ".join(
                    [
                        row.get("topic", ""),
                        row.get("de", ""),
                        row.get("en", ""),
                    ]
                ),
            )
        records.append(
            _record(
                kind="cloze",
                item_id=row["id"],
                source_path=CLOZE_PATH,
                approval_state="live",
                topic_id=topic_id,
                mapping_method=evidence.get("reason", "unknown"),
                mapping_evidence=evidence,
                register_lane="pedagogical_or_mixed",
                unmapped_reason=evidence.get("reason"),
            )
        )

    for row in _load_json(SATZ_PATH)["items"]:
        candidates = vocab_topic_by_korean.get(_norm(row.get("vocabKo")), set())
        if len(candidates) == 1:
            topic_id = next(iter(candidates))
            evidence = {
                "reason": "exact_vocabKo_topic_inheritance",
                "vocabKo": row.get("vocabKo"),
            }
        else:
            topic_id, evidence = resolver.keyword_resolution(
                title_text=row.get("targetKo", ""),
                context_text=" ".join(
                    [
                        row.get("vocabKo", ""),
                        row.get("promptDe", ""),
                        row.get("promptEn", ""),
                    ]
                ),
            )
            if len(candidates) > 1 and topic_id is None:
                evidence = {
                    **evidence,
                    "reason": "vocabKo_maps_to_multiple_topics",
                    "candidateTopics": sorted(candidates),
                }
        records.append(
            _record(
                kind="satz",
                item_id=row["id"],
                source_path=SATZ_PATH,
                approval_state="live",
                topic_id=topic_id,
                mapping_method=evidence.get("reason", "unknown"),
                mapping_evidence=evidence,
                register_lane="pedagogical_or_mixed",
                unmapped_reason=evidence.get("reason"),
            )
        )

    # Canonical 120 review-only briefs inherit the live scenario mapping where
    # the same scenario id already exists; otherwise use the same taxonomy
    # resolver on the Korean brief.
    for row in _load_json(SCENARIO_BRIEFS_PATH)["scenarios"]:
        topic_id = live_scenario_topic.get(row["id"])
        if topic_id:
            evidence = {
                "reason": "canonical_brief_inherits_live_scenario_topic",
                "scenarioId": row["id"],
            }
        else:
            topic_id, evidence = resolver.keyword_resolution(
                title_text=row.get("titleKo", ""),
                context_text=" ".join(
                    [
                        row.get("portfolioBucket", ""),
                        row.get("setting", ""),
                        row.get("event", ""),
                        row.get("playerGoal", ""),
                        row.get("counterpartGoal", ""),
                        row.get("courseUnitId", ""),
                    ]
                ),
            )
        records.append(
            _record(
                kind="canonical_scenario_brief",
                item_id=row["id"],
                source_path=SCENARIO_BRIEFS_PATH,
                approval_state="review_only",
                topic_id=topic_id,
                mapping_method=evidence.get("reason", "unknown"),
                mapping_evidence=evidence,
                register_lane=_register_lane(row, "scenario"),
                unmapped_reason=evidence.get("reason"),
            )
        )

    # Culture links inherit the linked live scenario topic.
    for row in _load_json(CULTURE_LINKS_PATH)["links"]:
        topic_id = live_scenario_topic.get(row["scenarioId"])
        evidence = {
            "reason": (
                "linked_scenario_topic_inheritance"
                if topic_id
                else "linked_scenario_has_no_confident_topic"
            ),
            "scenarioId": row["scenarioId"],
            "termIds": row.get("termIds", []),
        }
        records.append(
            _record(
                kind="scenario_culture_link",
                item_id=row["scenarioId"],
                source_path=CULTURE_LINKS_PATH,
                approval_state="live",
                topic_id=topic_id,
                mapping_method=evidence["reason"],
                mapping_evidence=evidence,
                register_lane="cultural_reference",
                unmapped_reason=evidence["reason"],
            )
        )

    # Culture arcs may legitimately span several canonical topics. Use the
    # first mapped step as the primary only when every mapped step agrees;
    # otherwise leave the arc primary explicit-unmapped and record candidate
    # topics rather than flattening a multi-topic arc.
    for arc in _load_json(CULTURE_ARCS_PATH)["arcs"]:
        candidate_topics = {
            live_scenario_topic.get(step["scenarioId"])
            for step in arc.get("steps", [])
            if live_scenario_topic.get(step["scenarioId"])
        }
        topic_id = (
            next(iter(candidate_topics))
            if len(candidate_topics) == 1
            else None
        )
        evidence = {
            "reason": (
                "all_arc_steps_share_one_topic"
                if topic_id
                else "culture_arc_spans_multiple_or_unmapped_topics"
            ),
            "candidateTopics": sorted(candidate_topics),
            "scenarioIds": [step["scenarioId"] for step in arc.get("steps", [])],
        }
        records.append(
            _record(
                kind="culture_story_arc",
                item_id=arc["arcId"],
                source_path=CULTURE_ARCS_PATH,
                approval_state="live",
                topic_id=topic_id,
                mapping_method=evidence["reason"],
                mapping_evidence=evidence,
                secondary_topic_ids=(
                    sorted(candidate_topics - {topic_id})
                    if topic_id
                    else sorted(candidate_topics)
                ),
                register_lane="cultural_reference",
                unmapped_reason=evidence["reason"],
            )
        )

    # Living Korea user-reviewed/not-live dialogue uses a deliberate mapping
    # from its contemporary issue registry to the stable 32-topic taxonomy.
    for path in LIVING_KOREA_PATHS:
        payload = _load_json(path)
        for arc in payload["arcs"]:
            for scene in arc["scenes"]:
                mapped = [
                    LIVING_KOREA_TOPIC_MAP[topic_id]
                    for topic_id in scene.get("topicIds", [])
                    if topic_id in LIVING_KOREA_TOPIC_MAP
                ]
                primary = mapped[0][0] if mapped else None
                secondaries: list[str] = []
                subtopics: list[str] = []
                for topic_id, secondary_ids, subtopic in mapped:
                    if topic_id != primary:
                        secondaries.append(topic_id)
                    secondaries.extend(secondary_ids)
                    subtopics.append(subtopic)
                evidence = {
                    "reason": (
                        "living_korea_topic_registry_bridge"
                        if primary
                        else "living_korea_topic_has_no_taxonomy_bridge"
                    ),
                    "livingKoreaTopicIds": scene.get("topicIds", []),
                }
                records.append(
                    _record(
                        kind="living_korea_scene",
                        item_id=scene["id"],
                        source_path=path,
                        approval_state="user_reviewed_not_live",
                        topic_id=primary,
                        secondary_topic_ids=secondaries,
                        subtopic_id=("+".join(sorted(set(subtopics))) if subtopics else None),
                        mapping_method=evidence["reason"],
                        mapping_evidence=evidence,
                        register_lane=(
                            "relationship_or_service"
                            if scene.get("relationshipContextKo")
                            else "mixed_or_unspecified"
                        ),
                        unmapped_reason=evidence["reason"],
                    )
                )

    # Parse repeatable draft schemas at item level without changing their
    # approval state. Unsupported manifests/one-off schemas remain explicitly
    # tracked at file level below instead of being guessed.
    parsed_draft_names = {path.name for path in LIVING_KOREA_PATHS}
    draft_paths = [
        path
        for path in sorted(DRAFT_DIR.glob("*"))
        if path.is_file()
        and path.suffix.lower() in {".json", ".csv", ".md"}
        and path.name not in parsed_draft_names
    ]
    draft_vocab_topic_by_id: dict[str, str | None] = {}
    draft_vocab_topic_by_korean: dict[str, set[str]] = collections.defaultdict(set)
    draft_scenario_topic: dict[str, str | None] = {}

    def _draft_localized_text(value: object) -> str:
        if isinstance(value, dict):
            return " ".join(str(part) for part in value.values())
        return str(value or "")

    # Vocab CSVs are the strongest reusable draft owner for downstream cloze
    # and Satz rows. Grammar CSVs do not carry korean/topic/id together and are
    # intentionally left file-level until a grammar-specific adapter exists.
    for path in draft_paths:
        if path.suffix.lower() != ".csv":
            continue
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            if not {"id", "korean", "topic"}.issubset(set(reader.fieldnames or [])):
                continue
            rows = list(reader)
        if not all(row.get("id") for row in rows):
            continue
        parsed_draft_names.add(path.name)
        for row in rows:
            topic_id = resolver.exact_one("vocabTopics", row.get("topic"))
            if topic_id:
                evidence = {
                    "reason": "exact_vocab_topic_alias",
                    "topic": row.get("topic"),
                }
            else:
                topic_id, evidence = resolver.keyword_resolution(
                    title_text=row.get("korean", ""),
                    context_text=" ".join(
                        [
                            row.get("topic", ""),
                            row.get("pack_id", ""),
                            row.get("german", ""),
                            row.get("english", ""),
                        ]
                    ),
                )
            draft_vocab_topic_by_id[row["id"]] = topic_id
            if topic_id:
                draft_vocab_topic_by_korean[_norm(row.get("korean"))].add(topic_id)
            records.append(
                _record(
                    kind="vocab",
                    item_id=row["id"],
                    source_path=path,
                    approval_state="draft_or_review_artifact",
                    topic_id=topic_id,
                    mapping_method=evidence.get("reason", "unknown"),
                    mapping_evidence=evidence,
                    register_lane="pedagogical_or_mixed",
                    unmapped_reason=evidence.get("reason"),
                )
            )

    # Scenario draft families share the live scenario structure closely enough
    # to reuse the same conservative resolver. Their approval state remains
    # draft/review-only even when a topic is confidently mapped.
    for path in draft_paths:
        if path.name in parsed_draft_names or path.suffix.lower() != ".json":
            continue
        try:
            payload = _load_json(path)
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        if isinstance(payload, dict) and isinstance(payload.get("scenarios"), list):
            rows = payload["scenarios"]
        elif isinstance(payload, list):
            rows = payload
        else:
            continue
        if not all(isinstance(row, dict) and row.get("id") for row in rows):
            continue
        parsed_draft_names.add(path.name)
        for row in rows:
            title = _draft_localized_text(row.get("title"))
            context = " ".join(
                [
                    str(row.get("id") or ""),
                    str(row.get("shelf") or ""),
                    str(row.get("courseUnitId") or ""),
                    str(row.get("intent") or ""),
                    _draft_localized_text(row.get("intro")),
                ]
            )
            topic_id, evidence = resolver.keyword_resolution(
                title_text=title,
                context_text=context,
            )
            if topic_id is None:
                stripped_shelf = re.sub(
                    r"^[abc][12]_",
                    "",
                    _norm(row.get("shelf")),
                )
                shelf_topic = resolver.exact_one("shelfSlugs", stripped_shelf)
                if shelf_topic:
                    topic_id = shelf_topic
                    evidence = {
                        "reason": "unique_stripped_shelf_alias",
                        "shelf": row.get("shelf"),
                        "normalizedShelf": stripped_shelf,
                    }
            draft_scenario_topic[row["id"]] = topic_id
            records.append(
                _record(
                    kind="scenario",
                    item_id=row["id"],
                    source_path=path,
                    approval_state="draft_or_review_artifact",
                    topic_id=topic_id,
                    mapping_method=evidence.get("reason", "unknown"),
                    mapping_evidence=evidence,
                    register_lane=_register_lane(row, "scenario"),
                    unmapped_reason=evidence.get("reason"),
                )
            )

    # Remaining repeatable JSON families: cloze/Satz items, listening lessons,
    # and smalltalk phrases. Pronunciation phrase files intentionally do not
    # match the smalltalk category gate and remain file-level.
    for path in draft_paths:
        if path.name in parsed_draft_names or path.suffix.lower() != ".json":
            continue
        try:
            payload = _load_json(path)
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        if not isinstance(payload, dict):
            continue

        rows = payload.get("items")
        if isinstance(rows, list) and all(
            isinstance(row, dict) and row.get("id") for row in rows
        ):
            first = rows[0] if rows else {}
            if not rows:
                parsed_draft_names.add(path.name)
                continue
            if "answer" in first and ("fullKo" in first or "sentenceKo" in first):
                parsed_draft_names.add(path.name)
                for row in rows:
                    topic_id = resolver.exact_one("vocabTopics", row.get("topic"))
                    evidence: dict[str, Any]
                    source_vocab_id = str(row.get("sourceVocabId") or "")
                    inherited = draft_vocab_topic_by_id.get(source_vocab_id)
                    if topic_id:
                        evidence = {
                            "reason": "exact_cloze_topic_alias",
                            "topic": row.get("topic"),
                        }
                    elif inherited:
                        topic_id = inherited
                        evidence = {
                            "reason": "draft_source_vocab_topic_inheritance",
                            "sourceVocabId": source_vocab_id,
                        }
                    else:
                        topic_id, evidence = resolver.keyword_resolution(
                            title_text=str(
                                row.get("fullKo") or row.get("sentenceKo") or ""
                            ),
                            context_text=" ".join(
                                [
                                    str(row.get("topic") or ""),
                                    str(row.get("de") or ""),
                                    str(row.get("en") or ""),
                                ]
                            ),
                        )
                    records.append(
                        _record(
                            kind="cloze",
                            item_id=row["id"],
                            source_path=path,
                            approval_state="draft_or_review_artifact",
                            topic_id=topic_id,
                            mapping_method=evidence.get("reason", "unknown"),
                            mapping_evidence=evidence,
                            register_lane="pedagogical_or_mixed",
                            unmapped_reason=evidence.get("reason"),
                        )
                    )
                continue

            if "targetKo" in first and (
                "vocabKo" in first or "sourceVocabId" in first
            ):
                parsed_draft_names.add(path.name)
                for row in rows:
                    candidates: set[str] = set()
                    source_vocab_id = str(row.get("sourceVocabId") or "")
                    source_topic = draft_vocab_topic_by_id.get(source_vocab_id)
                    if source_topic:
                        candidates.add(source_topic)
                    norm_vocab = _norm(row.get("vocabKo"))
                    candidates.update(vocab_topic_by_korean.get(norm_vocab, set()))
                    candidates.update(
                        draft_vocab_topic_by_korean.get(norm_vocab, set())
                    )
                    if len(candidates) == 1:
                        topic_id = next(iter(candidates))
                        evidence = {
                            "reason": "draft_vocab_topic_inheritance",
                            "sourceVocabId": source_vocab_id,
                            "vocabKo": row.get("vocabKo"),
                        }
                    else:
                        topic_id, evidence = resolver.keyword_resolution(
                            title_text=str(row.get("targetKo") or ""),
                            context_text=" ".join(
                                [
                                    str(row.get("vocabKo") or ""),
                                    str(row.get("promptDe") or ""),
                                    str(row.get("promptEn") or ""),
                                ]
                            ),
                        )
                        if len(candidates) > 1 and topic_id is None:
                            evidence = {
                                **evidence,
                                "reason": "draft_vocab_maps_to_multiple_topics",
                                "candidateTopics": sorted(candidates),
                            }
                    records.append(
                        _record(
                            kind="satz",
                            item_id=row["id"],
                            source_path=path,
                            approval_state="draft_or_review_artifact",
                            topic_id=topic_id,
                            mapping_method=evidence.get("reason", "unknown"),
                            mapping_evidence=evidence,
                            register_lane="pedagogical_or_mixed",
                            unmapped_reason=evidence.get("reason"),
                        )
                    )
                continue

        lessons = payload.get("lessons")
        if isinstance(lessons, list) and all(
            isinstance(row, dict) and row.get("id") for row in lessons
        ):
            parsed_draft_names.add(path.name)
            for row in lessons:
                candidates = {
                    topic
                    for source_id in row.get("contentIds", [])
                    for topic in (
                        draft_scenario_topic.get(source_id),
                        live_scenario_topic.get(source_id),
                    )
                    if topic
                }
                topic_id = next(iter(candidates)) if len(candidates) == 1 else None
                if topic_id:
                    evidence = {
                        "reason": "source_scenario_topic_inheritance",
                        "contentIds": row.get("contentIds", []),
                    }
                else:
                    topic_id, evidence = resolver.keyword_resolution(
                        title_text=_draft_localized_text(row.get("title")),
                        context_text=" ".join(
                            [
                                str(row.get("id") or ""),
                                str(row.get("topicId") or ""),
                                _draft_localized_text(row.get("intro")),
                            ]
                        ),
                    )
                records.append(
                    _record(
                        kind="listening",
                        item_id=row["id"],
                        source_path=path,
                        approval_state="draft_or_review_artifact",
                        topic_id=topic_id,
                        mapping_method=evidence.get("reason", "unknown"),
                        mapping_evidence=evidence,
                        register_lane="pedagogical_or_mixed",
                        unmapped_reason=evidence.get("reason"),
                    )
                )
            continue

        phrases = payload.get("phrases")
        payload_category = payload.get("category")
        if (
            isinstance(phrases, list)
            and all(isinstance(row, dict) and row.get("id") for row in phrases)
            and (
                payload_category
                or any(row.get("category") or row.get("topicId") for row in phrases)
            )
        ):
            parsed_draft_names.add(path.name)
            for row in phrases:
                category = row.get("category") or row.get("topicId") or payload_category
                topic_id = resolver.exact_one("smalltalkCategories", category)
                if topic_id:
                    evidence = {
                        "reason": "exact_smalltalk_category_alias",
                        "topicId": category,
                    }
                else:
                    topic_id, evidence = resolver.keyword_resolution(
                        title_text=str(row.get("ko") or ""),
                        context_text=" ".join(
                            [
                                str(category or ""),
                                str(row.get("de") or ""),
                                str(row.get("en") or ""),
                                _draft_localized_text(row.get("reply")),
                            ]
                        ),
                    )
                records.append(
                    _record(
                        kind="smalltalk",
                        item_id=row["id"],
                        source_path=path,
                        approval_state="draft_or_review_artifact",
                        topic_id=topic_id,
                        mapping_method=evidence.get("reason", "unknown"),
                        mapping_evidence=evidence,
                        register_lane=_register_lane(row, "smalltalk"),
                        unmapped_reason=evidence.get("reason"),
                    )
                )

    # Keep every unsupported draft schema visible at file level instead of
    # silently dropping it from the research scope.
    unparsed_draft_sources = []
    for path in draft_paths:
        if path.name in parsed_draft_names:
            continue
        unparsed_draft_sources.append(
            {
                "sourcePath": path.relative_to(ROOT).as_posix(),
                "approvalState": "draft_or_review_artifact",
                "trackingStatus": "file_level_explicit_unmapped",
                "unmappedReason": "legacy_or_batch_specific_draft_schema_not_registered_for_item_level_topic_mapping",
            }
        )

    # Research coverage status is derived from the native-usage registry rather
    # than frozen in the ledger. This keeps the coverage ledger truthful after
    # a topic moves from broad/pass-in-progress to deep-pass complete.
    native_registry = _load_json(NATIVE_USAGE_REGISTRY_PATH)
    native_topic_status = {
        row["topicId"]: row.get("researchStatus")
        for row in native_registry["topics"]
    }
    for row in records:
        topic_id = row["canonicalTopicId"]
        if topic_id is None:
            continue
        row["researchCoverageStatus"] = (
            "topic_profile_deep_pass_complete"
            if native_topic_status.get(topic_id) == "deep_pass_complete"
            else "topic_profile_pending_deep_pass"
        )

    by_kind: dict[str, dict[str, int]] = {}
    for kind in sorted({row["kind"] for row in records}):
        subset = [row for row in records if row["kind"] == kind]
        mapped = sum(row["canonicalTopicId"] is not None for row in subset)
        by_kind[kind] = {
            "total": len(subset),
            "mapped": mapped,
            "explicitUnmapped": len(subset) - mapped,
        }

    topic_counts = collections.Counter(
        row["canonicalTopicId"]
        for row in records
        if row["canonicalTopicId"] is not None
    )

    payload = {
        "schemaVersion": 1,
        "generatedBy": "tools/content_factory/build_trilingual_content_topic_coverage.py",
        "generatedDate": "2026-10-06",
        "status": "CONTENT_TOPIC_MAPPING_LEDGER_ACTIVE",
        "taxonomyPath": TAXONOMY_PATH.relative_to(ROOT).as_posix(),
        "nativeUsageRegistryPath": NATIVE_USAGE_REGISTRY_PATH.relative_to(
            ROOT
        ).as_posix(),
        "policy": {
            "researchCoverageDoesNotImplyApproval": True,
            "noSilentUnmappedItems": True,
            "ambiguousMappingsRemainExplicitlyUnmapped": True,
            "secondaryTopicsAllowedForCrossDomainScenes": True,
            "legacyDraftSchemasTrackedAtFileLevelUntilAdapterExists": True,
            "mappedCoverageStatusDerivedFromNativeUsageRegistry": True,
        },
        "summary": {
            "trackedItemCount": len(records),
            "mappedItemCount": sum(
                row["canonicalTopicId"] is not None for row in records
            ),
            "explicitUnmappedItemCount": sum(
                row["canonicalTopicId"] is None for row in records
            ),
            "unparsedDraftSourceCount": len(unparsed_draft_sources),
            "byKind": by_kind,
            "mappedCountsByCanonicalTopic": {
                topic["id"]: topic_counts.get(topic["id"], 0)
                for topic in taxonomy["topics"]
            },
        },
        "records": records,
        "unparsedDraftSources": unparsed_draft_sources,
    }
    return payload


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Compare the generated ledger with the checked-in canonical ledger.",
    )
    args = parser.parse_args()
    payload = build()
    rendered = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not OUT_PATH.is_file():
            raise SystemExit(f"missing generated ledger: {OUT_PATH}")
        current = OUT_PATH.read_text(encoding="utf-8")
        if current != rendered:
            raise SystemExit(
                "trilingual content-topic coverage ledger is stale; "
                "run build_trilingual_content_topic_coverage.py"
            )
        print(
            "coverage ledger current:",
            payload["summary"]["trackedItemCount"],
            "items",
        )
        return
    OUT_PATH.write_text(rendered, encoding="utf-8")
    print(
        "wrote",
        OUT_PATH.relative_to(ROOT),
        payload["summary"]["trackedItemCount"],
        "items",
    )
    print(json.dumps(payload["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
