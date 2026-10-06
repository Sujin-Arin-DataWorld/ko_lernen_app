#!/usr/bin/env python3
"""Reproducible, read-only source audit; writes only docs/design/c_content_audit.

This does not execute Flutter, discover runtime user data, or certify artwork.
No network, package installation, asset rewriting, Git mutation, or graph update.
Python standard library only. Run `build`, `check`, or `self-test` from any cwd.
"""
from __future__ import annotations

import argparse
import collections
import csv
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any

SCHEMA = 2
OUTPUT = Path("docs/design/c_content_audit")
SCENARIO_LINEAGE_COMMIT = "37afe400dc1b8bde735d4cbbe36c2622beaf10a7"
SCENARIO_PROMOTION_COMMIT = "ca00acad2ff0d1470dc241bfdfb8d15685a7d1a0"
CONTEXT_LINEAGE_COMMIT = "a1d798bda6a36ff4dd95faa16e14484ad7b1a2f5"
ARTIFACT_FOLDERS = {
    "c_reference": "einleitung-reward-abc-20261004",
    "intro_exact": "c-einstieg-concept-20261005-01a10981/exact-assets-20261005",
    "intro_rejected_pack": "c-einstieg-concept-20261005-01a10981/asset-pack-20261005",
    "scholar_handoff": "scholar-fan-integration-20261003/design-handoff-20261005",
    "dokkaebi_intro_handoff": "dokkaebi-design-handoff-20261005",
    "chest_handoff": "reward-chest-handoff-20261005",
}
MEDIA_SUFFIXES = {
    ".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg", ".mp4", ".webm",
    ".m4a", ".mp3", ".wav", ".ogg", ".riv", ".ttf", ".otf", ".glb",
    ".gltf", ".blend", ".zip", ".pdf", ".frag",
}
TABLE_SUFFIXES = {".json", ".jsonl", ".csv"}
TEXT_SUFFIXES = {".dart", ".json", ".jsonl", ".csv", ".md", ".yaml", ".html", ".js", ".arb"}
ASSET_RE = re.compile(
    r"(?<!docs/)(?:assets(?:_unused)?|fonts|shaders)/[^\s'\"<>]+?\.(?:png|jpe?g|webp|gif|svg|mp4|webm|m4a|mp3|wav|ogg|riv|ttf|otf|glb|json|csv|frag)\b"
)
DIRECTORY_RE = re.compile(r"['\"]((?:assets(?:_unused)?|fonts)/[^'\"\s]*?/)['\"]")
QUOTED_ASSET_DIRECTORY_RE = re.compile(r"['\"]((?:assets(?:_unused)?|fonts|shaders)/[^'\"\s$]+)['\"]")
INTERPOLATED_ASSET_DIRECTORY_RE = re.compile(r"['\"]((?:assets(?:_unused)?|fonts|shaders)/(?:[^'\"\s/$]+/)*)(?=\$)")
LEVELS = {"a1", "a2", "b1", "b2", "c1", "c2"}
EXPECTED = {
    "course_units": 48, "learning_phases": 30, "phase_tasks": 902,
    "smalltalk_native_lessons": 209, "smalltalk_phrases": 590,
    "smalltalk_categories": 24, "smalltalk_context_cases": 10,
    "listening_native_lessons": 186, "scenarios": 186,
    "learn_entries": 13, "game_entries": 8, "production_tabs": 5,
}


def canonical(value: Any) -> bytes:
    # Same sorted-map / UTF-8 / compact JSON rule as phaseFingerprint in Dart.
    return json.dumps(value, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":"), allow_nan=False).encode("utf-8")


def digest(value: Any) -> str:
    return hashlib.sha256(canonical(value)).hexdigest()


def file_hash(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   encoding="utf-8", errors="replace").strip()


def exact_record_span(blob: bytes, identity: str) -> tuple[dict[str, Any], bytes, int, int]:
    """Return an authored JSON object with its unchanged UTF-8 byte span.

    JSON redumping would lose whitespace and cannot preserve original bytes.
    Decoding candidate object openings also works when id is not its first field.
    """
    text = blob.decode("utf-8")
    decoder = json.JSONDecoder()
    for opening in re.finditer(r"\{", text):
        start = opening.start()
        try:
            value, length = decoder.raw_decode(text, start)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict) and value.get("id") == identity:
            # raw_decode returns the absolute character end when idx is given.
            byte_start = len(text[:start].encode("utf-8"))
            byte_end = len(text[:length].encode("utf-8"))
            preserved = text[start:length].encode("utf-8")
            if preserved != blob[byte_start:byte_end]:
                raise ValueError("Historical JSON UTF-8 byte-span mismatch")
            return value, preserved, byte_start, byte_end
    raise ValueError("Historical record not found: " + identity)


def unique_partition(actual: list[str], expected: set[str]) -> bool:
    return len(actual) == len(set(actual)) and set(actual) == expected


def compact_record(record: dict[str, Any]) -> dict[str, Any]:
    """Lossless source/binding references instead of 218k repeated metadata blocks."""
    common = {"source_sha256", "revision_policy", "access", "asset_paths", "asset_bindings"}
    result = {key: value for key, value in record.items()
              if key not in common and value is not None and value != []}
    if record["asset_paths"]:
        result["asset_ids"] = record["asset_paths"]
    if record["revision"] is None:
        result["revision"] = None
    if record["access"]["status"].startswith("archive_only"):
        result["access_override"] = "historical_archive_not_live"
    if result.get("references"):
        result["references"] = [{key: value for key, value in reference.items()
                                 if key != "resolution" and (key != "candidate_uids" or value)}
                                for reference in result["references"]]
    return result


def pointer_token(value: Any) -> str:
    return str(value).replace("~", "~0").replace("/", "~1")


def balanced(text: str, start: int) -> str:
    """Extract a parenthesized Dart expression, preserving nested expressions."""
    depth = 0
    quote = None
    escaped = False
    for pos in range(start, len(text)):
        char = text[pos]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in "'\"":
            quote = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[start:pos + 1]
    raise ValueError("Unbalanced source expression")


def literal_field(block: str, name: str) -> str | None:
    match = re.search(r"\b" + re.escape(name) + r":\s*(['\"])(.*?)\1", block, re.S)
    return match.group(2) if match else None


def reference_values(value: Any) -> list[tuple[str, str]]:
    """Reference declarations, including nested packet/objective references."""
    singular = {"courseUnitId", "parentCourseUnitId", "phaseId", "taskId", "contentId",
                "contentLinkId", "sourceSeedId", "sourceVocabId", "objectiveId",
                "scenarioId", "releaseTrackId", "trackEditionId", "assessmentItemId", "stepId",
                "canDoSegmentId", "missionContentLinkId", "projectId"}
    plural = {"contentIds", "sourceIds", "sourcePhraseIds", "conceptIds", "requiredConceptIds",
              "checkpointContentIds", "taskIds", "prerequisiteTaskIds", "practiceUnitIds",
              "sourceSeedIds", "contentClusterIds", "segmentIds", "editionIds",
              "surfaceFormIds", "grammarIds", "grammar_ids", "vocab_ids",
              "ownedAssessmentItemIds", "participantIds", "buildingIds", "materialIds", "assessmentItemIds",
              "snippetIds", "prerequisiteStepIds", "prerequisiteAssessmentItemIds", "grammarReferenceIds"}
    found: list[tuple[str, str]] = []
    def visit(item: Any, ptr: str) -> None:
        if isinstance(item, dict):
            for key, child in item.items():
                at = ptr + "/" + pointer_token(key)
                if key in singular and isinstance(child, str):
                    found.append((at, child))
                elif key in plural and isinstance(child, list):
                    found.extend((at + "/" + str(i), v) for i, v in enumerate(child)
                                 if isinstance(v, str))
                visit(child, at)
        elif isinstance(item, list):
            for i, child in enumerate(item):
                visit(child, ptr + "/" + str(i))
    visit(value, "")
    return found


# Every binding is a product contract with current source evidence, not a QA pass.
# Per-record binding IDs reference these definitions, avoiding ambiguous totals.
MODULE_DEFINITIONS = {
    "foundation": (["lib/models/foundation_progress.dart", "lib/services/foundation_progress_service.dart",
                    "lib/services/foundation_progress_storage.dart", "lib/services/today_learning_snapshot.dart",
                    "lib/features/onboarding_v2/onboarding_learning_start.dart"],
                   ["lib/screens/foundation_learning_screen.dart", "lib/screens/foundation_learning_widgets.dart",
                    "lib/screens/foundation_practice_screen.dart"], ["/foundation"],
                   "Four independent starter steps and twelve stable tasks. Resume validated per-account progress; opening is not practicing. Today admission uses production scheduledReviewCount=today.reviewCount; newly assigned cards do not imply prior learning. Public dueCount still includes new+review.",
                   "FoundationStep -> direct FoundationPracticeScreen(step, service, captured FoundationLearningLease), route name /foundation/${step.id}; explicit Continue A1 uses existing course entry.",
                   ["loading", "empty", "step_opened", "practice", "audio_pending", "audio_failure_retry", "composition_wrong", "stroke_feedback", "actual_action_and_confirmation", "save_pending", "save_failure_retry", "resume", "account_stale", "reset_stale", "continue_A1"],
                   "FoundationPracticeEvidence requires successful playback/read composition/matched strokes plus confirmation. Schema1, 16KB cap, stable merge and lease lifetime guards; no CEFR mastery, course assessment, XP or money."),
    "course": (["lib/services/curriculum_catalog.dart", "lib/services/course_progress_service.dart",
                "lib/services/course_mission_navigation.dart", "lib/services/canonical_course_segment_loader.dart"],
               ["lib/screens/learning_path_screen.dart", "lib/screens/course_mission_screen.dart",
                "lib/screens/course_mission_path_overview.dart", "lib/screens/course_reassessment_screen.dart"],
               ["/path", "/course/mission", "/course/reassessment"],
               "Placement/current/completed unit and frozen graph links; no first-in-level fallback.",
               "String courseUnitId; CoursePracticeContext.fromLink; VocabPackRouteArguments; CourseReassessmentRouteArguments.",
               ["placement", "loading", "source_failure_retry", "current", "locked", "completed", "read_only", "practice", "assessment", "save_pending", "save_failure_retry", "resume"],
               "CourseProgressService; provenance revalidation and account lifetime before evidence writes."),
    "phases": (["lib/services/learning_phase_catalog.dart", "lib/services/phase_task_catalog.dart", "lib/services/phase_task_drafts.dart"],
               ["lib/screens/learning_phases_screen.dart", "lib/screens/phase_task_screen.dart", "lib/widgets/phase_task_panel.dart"],
               ["/course/phases", "/course/phase", "/learning-phase/task"],
               "Level -> phase -> published taskIds; prerequisite/mode/structured evaluator checks; related practice is not course completion.",
               "Level String; LearningPhase; PhaseTaskRoute (practice and assessment distinct).",
               ["level_selection", "phase", "task_list", "practice", "assessment", "draft", "recording_local", "unavailable", "save_pending", "retry", "result"],
               "Phase draft/evidence hash and contentRevision/rubricVersion binding; productive work not auto-certified."),
    "productive_draft": (["lib/services/productive_assessment_service.dart", "lib/services/canonical_course_segment_loader.dart"],
                         ["lib/screens/course_mission_screen.dart", "lib/screens/phase_task_screen.dart"], ["/course/mission", "/learning-phase/task"],
                         "118 assessment definitions / eight projects / 32 source snippets / 16 bundles exist in authoring draft only. runtimeContentApproved=false; canonical segment loader requires an approved injected catalog.",
                         "ProductiveAssessmentCatalog.fromJson and approved injection; draft fixtures are injected by tests, never automatically packaged for the learner.",
                         ["draft", "per_ID_review_pending", "runtime_closed", "unavailable", "practice_only", "source_missing", "history_preserved"],
                         "Draft/source consistency is not human copy approval, assessed mastery or XP. Content owner must complete the per-ID review ledger and deliberate promotion before enabling executable assessment."),
    "hangul": (["lib/services/tts_recorded_jamo.dart", "lib/services/hangul_util.dart"],
               ["lib/screens/hangul_screen.dart"], ["/hangul"],
               "HangulTarget overview/cards/writing; consonant/vowel/compound letter source.",
               "HangulTarget overview/cards/writing or retained direct entry as dispatched in main.",
               ["overview", "cards", "sound_loading", "sound_failure", "writing", "stroke_feedback", "completion"],
               "FeedbackCompletion and LearningJourneyObserver; visiting is not alphabet mastery."),
    "calligraphy": (["lib/services/daily_char_service.dart", "lib/services/storage_service.dart"], ["lib/screens/daily_char_sheet.dart"], ["/calligraphy"],
                    "Today's character and existing letter/stroke contract.", "Existing daily-character route.",
                    ["letter", "audio", "trace", "completion", "failure_retry"], "Existing stored daily state; no fabricated course completion."),
    "pronunciation": (["lib/services/pronunciation_phrase_loader.dart", "lib/services/pronunciation_progress_service.dart",
                      "lib/services/pronunciation_assessment_client.dart"],
                      ["lib/screens/pronunciation_studio_screen.dart"], ["/pronunciation"],
                      "Level/focus phrase selection; recording consent and assessment availability.", "Existing phrase/level route.",
                      ["phrase", "listen", "permission", "recording", "assessment_pending", "result", "failure_retry"],
                      "PronunciationProgressService; actual assessment result only."),
    "vocab_packs": (["lib/services/data_loader.dart", "lib/services/vocab_pack_service.dart", "lib/services/pack_progress_service.dart"],
                    ["lib/screens/vocab_packs_screen.dart", "lib/screens/vocab_pack_screen.dart", "lib/screens/vocab_pack_recall_screen.dart"],
                    ["/vocab", "/vocab/pack", "/vocab/result", "/vocab/recall"],
                    "CSV pack_id/level/order; matching mission content ID only; direct library remains browse.",
                    "String packId or VocabPackRouteArguments(packId, courseContext).",
                    ["pack_grid", "learn", "quiz", "boss", "recall", "locked", "resume", "result", "save_failure_retry"],
                    "PackProgressService and checkpoint evidence; confirmed rewards only."),
    "srs": (["lib/services/storage_service.dart"], ["lib/screens/review_hub_screen.dart", "lib/screens/review_session_screen.dart"],
            ["/review", "/review/hub"], "Due/hard words and saved review queues.", "Existing review session request.",
            ["due", "empty", "loading", "review", "result", "save_failure_retry"], "Stored review scheduling and account lifetime."),
    "my_words": (["lib/services/bookshelf_service.dart", "lib/services/storage_service.dart"],
                 ["lib/screens/my_words_screen.dart", "lib/screens/custom_pack_play_screen.dart", "lib/screens/custom_pack_edit_screen.dart"],
                 ["/my_words", "/bookshelf", "/wordbook/search", "/hard_words", "/bookshelf/page",
                  "/custom_pack/play", "/custom_pack/edit", "/custom_pack/quiz", "/custom_pack/matching", "/custom_pack/typing"],
                 "Real saved pack/page IDs, search/type and usable translated word count; aliases share current hub.",
                 "Existing String packId/pageId and custom practice requests.",
                 ["empty", "list", "search", "edit", "save_pending", "save_failed", "conflict", "play", "restore"],
                 "Bookshelf/custom-pack stores and LocalDataLifetime; user records are not enumerated by this static audit."),
    "grammar": (["lib/services/data_loader.dart", "lib/services/grammar_plan_service.dart"],
                ["lib/screens/grammar_screen.dart", "lib/screens/grammar_choice_quiz_screen.dart"],
                ["/grammar", "/grammar_choice_quiz"],
                "Level/plan and optional mission-linked grammar ID; CSV quiz_enabled and distractor IDs.",
                "CoursePracticeContext for grammar or direct library request.",
                ["plan", "list", "explanation", "examples", "quiz", "result", "save_pending", "conflict", "retry"],
                "GrammarPlanService; valid course question/evidence only, legacy viewing not assessment."),
    "book_capture": (["lib/services/book_image_service.dart", "lib/services/bookshelf_service.dart", "lib/services/vocab_notebook_parser.dart"],
                     ["lib/screens/book_capture_screen.dart", "lib/screens/book_preview_screen.dart", "lib/screens/book_result_screen.dart",
                      "lib/screens/vocab_notebook_result_screen.dart", "lib/screens/vocab_notebook_practice_screen.dart"],
                     ["/book", "/book/preview", "/book/result", "/vocab_notebook", "/vocab_notebook/result", "/vocab_notebook/practice", "/vocab_notebook/studio", "/vocab_notebook/nuance"],
                     "Book/notebook capture mode and actual OCR/page/pack result; permissions on requested capture only.",
                     "Existing capture preview/result and pageId/packId request types in main.",
                     ["permission", "capture", "OCR_pending", "OCR_failure", "preview_edit", "empty", "analysis", "save_pending", "save_retry", "saved"],
                     "Real saved page/custom pack; no onboarding camera permission or example pack creation."),
    "listening": (["lib/features/content_learning/content_learning_catalog.dart", "lib/services/scenario_loader.dart",
                  "lib/features/content_learning/content_learning_service.dart"],
                  ["lib/features/content_learning/content_learning_hub.dart", "lib/features/content_learning/content_lesson_screen.dart"],
                  ["/listening", "/listening/play", "/content/goals"],
                  "Authored 186 lessons, level/topic/goal/day/current/review; lesson.contentIds -> actual scenario IDs.",
                  "ContentLessonScreen(lesson, scope, reviewQueue); existing deep-link scenario/content ID adaptation in main.",
                  ["goal_setup", "level", "topic", "continue", "listen", "transcript", "question", "review", "result", "save_pending", "retry"],
                  "ContentLearningService goal/progress/answer/review stores and source IDs; old ListeningScreen is retained legacy, not the route target."),
    "scenarios": (["lib/services/scenario_loader.dart", "lib/services/course_mastery_service.dart"],
                  ["lib/screens/scenarios_list_screen.dart", "lib/screens/scenario_player_screen.dart"],
                  ["/scenarios", "/scenario"],
                  "Six level shards, shelf/scene/current mission; dialogs, quests and checkpoints retain identity.",
                  "String scenarioId or scoped CoursePracticeContext validated by scenario route adapter.",
                  ["shelf", "intro", "audio_loading", "audio_failure", "dialog", "quest", "checkpoint", "result", "save_pending", "retry"],
                  "Scenario completion/checkpoint and reward claim services; direct practice is not fabricated mission evidence."),
    "smalltalk": (["lib/features/content_learning/content_learning_catalog.dart", "lib/services/smalltalk_loader.dart",
                  "lib/features/content_learning/content_learning_service.dart"],
                  ["lib/features/content_learning/content_learning_hub.dart", "lib/features/content_learning/content_lesson_screen.dart", "lib/screens/smalltalk_screen.dart"],
                  ["/smalltalk", "/content/goals"],
                  "209 authored lessons -> all 590 phrases/24 categories; level/topic/goal/continue/review. Scoped courseContext uses SmalltalkScreen.",
                  "No course context -> native ContentLearningHub; CoursePracticeContext -> SmalltalkScreen; ContentLessonScreen(lesson, scope, reviewQueue) internally.",
                  ["goal", "level", "category", "continue", "phrase", "audio", "relationship_check", "review", "like", "save_pending", "retry", "result"],
                  "ContentLearningService plus liked content and course relationship evidence; never replace catalog with the ten supplemental cases."),
    "talsunbi_context": (["lib/services/smalltalk_context_catalog.dart", "lib/services/practice_history_store.dart"],
                         ["lib/screens/smalltalk_context_screen.dart", "lib/widgets/smalltalk_practice_entry.dart", "lib/screens/hanok_practice_screen.dart"],
                         ["/smalltalk/context", "/hanok/practice"],
                         "Supplemental ten cases by level/caseId, base or transfer; case revision preserved in history.",
                         "SmalltalkContextRequest(caseId, transfer, level); PracticeSourceReference includes revision.",
                         ["case", "relation", "intent", "expression", "effect", "follow_up_partial", "wrong", "saved", "save_failure_retry", "history", "transfer"],
                         "PracticeHistoryStore real save; silent fan response only; revision1 history not rewritten as invite_friend revision2."),
    "word_web": (["lib/services/word_relation_service.dart", "lib/services/vocab_nuance_service.dart"],
                 ["lib/screens/word_web_screen.dart", "lib/screens/word_web_quiz_screen.dart", "lib/screens/vocab_nuance_screen.dart"],
                 ["/word_web", "/vocab_notebook/nuance"],
                 "Learned sourceVocabId/level with explicit browse fallback; synonyms/antonyms/related expressions.",
                 "Existing word relation/custom-pack nuance selection.",
                 ["source", "empty", "relation", "examples", "quiz", "save_pending", "retry"], "Existing seen IDs and nuance/custom-pack stores."),
    "games": (["lib/services/cloze_loader.dart", "lib/services/satz_loader.dart", "lib/services/silben_puzzle_loader.dart", "lib/services/kkeunmari_engine.dart", "lib/services/kkeunmari_dictionary_service.dart", "lib/services/korean_noun_lexicon.dart", "lib/services/storage_service.dart"],
              ["lib/screens/daily_challenge_screen.dart", "lib/screens/chosung_quiz_screen.dart", "lib/screens/silben_kreuz_screen.dart",
               "lib/screens/cloze_game_screen.dart", "lib/screens/speed_match_screen.dart", "lib/screens/satz_arcade_screen.dart", "lib/screens/kkeunmari_screen.dart"],
              ["/daily", "/chosung", "/wordle", "/cloze", "/speed_match", "/satz_arcade", "/kkeunmari"],
              "Actual per-game rules and level pools; crossword hints 1/2/3 and direct tile placement; custom pack modes keep minimum-word requirements.",
              "CoursePracticeContext only for matching family; direct games and custom String packId preserve practice scope.",
              ["level", "question", "selected", "hint1", "hint2", "hint3", "tile", "wrong", "complete", "record", "reward_pending", "retry", "replay"],
              "Per-game completion/best and YeopjeonLearningCheckpoint; actual media contact 100+150+900ms outline, no reward fabricated by animation."),
    "onboarding": (["lib/features/onboarding_v2/onboarding_journey_repository.dart", "lib/features/onboarding_v2/onboarding_journey_state.dart", "lib/features/onboarding_v2/onboarding_learning_start.dart"],
                   ["lib/screens/onboarding_v2/onboarding_setup_screen.dart", "lib/screens/onboarding_v2/onboarding_story_screen.dart", "lib/screens/onboarding_v2/onboarding_companion_screen.dart"],
                   ["/onboarding", "/quick_onboarding", "/character_selection", "/onboarding/start", "/intro"],
                   "Existing seven steps, beginnerDraft versus A1 placement, purpose and Taego/Joy IDs; previews do not write course/rewards.",
                   "Existing coordinator/journey request; draft and final commit journal.",
                   ["load", "resume", "level", "purpose", "story2_6", "back", "sound_preview", "companion", "committing", "save_retry"],
                   "Onboarding journal and account-safe final commit; one Hangul route launch is not literacy completion."),
    "hanok": (["lib/services/sori_stage_progression_service.dart", "lib/services/hanok_competence_projection_service.dart", "lib/services/yeopjeon_service.dart"],
              ["lib/screens/sori_stage/sori_stage_hanok_screen.dart", "lib/screens/sarangbang_screen.dart"],
              ["/hanok", "/hanok/construction", "/sarangbang", "/sarangbang/furnish", "/quests", "/dojangcheop"],
              "Real build stage/ownership/ledger and approved canonical art; dormant IlDu world separately classified.",
              "Existing house/stage/room requests; actual quote/purchase validation.",
              ["loading", "stage", "locked", "price", "insufficient_funds", "purchase_pending", "retry", "owned", "furnish", "opened_receipt_resume", "account_invalidated", "pending_data_not_previous_account"],
              "Yeopjeon construction ledger; Dancheong culture collection is a different economy."),
    "dancheong": (["lib/features/dancheong/dancheong_store.dart", "lib/features/dancheong/dancheong_connections.dart"],
                  ["lib/screens/dojangcheop_screen.dart"],
                  ["/dojangcheop", "/dancheong-studio", "/dancheong-entry", "/dancheong-studio/edit", "/dancheong-artwork", "/dancheong-share"],
                  "Real motif/stamp ownership, draft/artwork IDs; artwork does not repaint canonical architecture.",
                  "Dancheong editor/artwork request types dispatched in main.",
                  ["collection", "locked", "motif", "draft", "editor", "save_pending", "retry", "artwork", "share"],
                  "DancheongStore; collection and personal expression separate from construction currency."),
    "rewards": (["lib/services/decoration_reward_service.dart", "lib/services/sori_stage_reward_receipt_service.dart", "lib/services/yeopjeon_learning_checkpoint.dart"],
                ["lib/screens/bojagi_screen.dart", "lib/screens/sori_stage/sori_stage_reward_receipt_sheet.dart"], ["/bojagi"],
                "Confirmed/pending moments, account lifetime, journal/queue/idempotent claim; source ownership before display.",
                "Existing claim/receipt/itemAsset adapter; approved single-item flow replaces old selection UI.",
                ["closed", "claim_pending", "opening", "one_item_reveal", "explanation", "actual_saved_XP", "placement", "culture_story", "failure_retry", "skip", "return", "opened_unacknowledged_resume", "strict_read_failure", "account_invalidated"],
                "Pending persisted receipt is separate from unopened boxes. Today/Hanok resume /bojagi with the same item and existing claim; no extra item, XP or pool change. Old maximum-three-candidate screen is not an acceptance requirement."),
    "gye": (["lib/services/gye_service.dart", "lib/services/sori_stage_progression_service.dart"],
            ["lib/screens/sori_stage/sori_stage_gye_screen.dart", "lib/screens/gye_screen.dart", "lib/screens/gye_members_screen.dart"],
            ["/gye/hub", "/gye/create", "/gye/join", "/gye", "/gye/members"],
            "Actual membership/groupId and server weekly projection; 16+ birth-year gate and six-digit code/nickname.",
            "Existing String groupId/join requests.",
            ["loading", "unjoined", "age_gate", "create", "join", "invalid_code", "joined", "weekly_goal", "members", "report", "leave", "failure_retry"],
            "GyeService backend membership and promise records; no invented member or completion numbers."),
    "support": (["lib/services/account/account_switch_coordinator.dart", "lib/services/local_data_lifetime.dart", "lib/services/auth_service.dart"],
                ["lib/screens/profile_screen.dart", "lib/screens/settings_screen.dart", "lib/screens/stats_screen.dart", "lib/screens/practice_hub_screen.dart", "lib/screens/hanok_practice_screen.dart"],
                ["/profile", "/settings", "/stats", "/guide", "/study-library", "/practice", "/hanok/practice"],
                "Actual guest/account/local/cloud/consent/history states; support aliases and direct modals tracked individually.",
                "Existing account operation and history source requests; no static enumeration of personal data.",
                ["guest", "linked", "offline", "pending_sync", "switch", "conflict", "reauth", "export", "delete", "history_empty", "history", "retry"],
                "Existing account operations and local lifetime guards; cloud/device QA unverified."),
    "c_roots": (["lib/services/learning_focus.dart", "lib/services/sori_stage_progression_service.dart", "lib/models/home_navigation_art.dart"],
                ["lib/screens/sori_stage/sori_stage_shell.dart", "lib/screens/sori_stage/sori_stage_today_screen.dart",
                 "lib/screens/sori_stage/sori_stage_catalog_screen.dart", "lib/screens/sori_stage/sori_stage_hanok_screen.dart", "lib/screens/sori_stage/sori_stage_gye_screen.dart"],
                ["/"], "Five production tabs, shared focus, IndexedStack/scroll/controller/account/TickerMode contracts.",
                "Existing TodayLearningDestination route and typed arguments; preview action IDs do not certify production connections.",
                ["today", "learn", "games", "hanok", "gye", "selected", "focus", "reselect", "loading", "error", "empty", "return", "hidden_tab_account_change", "done_without_error_data", "opened_receipt_resume"],
                "Existing shell _open / LearningAttempt.unshown / receipt and account lifetime guards. Active and hidden tabs invalidate on account change; previous account data must not survive pending/error snapshots."),
}

DATA_MODULES = {
    "curriculum_manifest.json": ["course"], "can_do_segments.json": ["course"],
    "can_do_content_authorities.json": ["course"], "learning_phases.json": ["phases"],
    "phase_tasks.json": ["phases"], "korean_vocab.csv": ["vocab_packs", "my_words", "games", "word_web"],
    "grammar.csv": ["grammar"], "grammar_patterns.json": ["book_capture", "grammar"],
    "smalltalk.json": ["smalltalk"], "smalltalk_lessons.json": ["smalltalk"],
    "smalltalk_context_cases.json": ["talsunbi_context"], "listening_lessons.json": ["listening"],
    "pronunciation_phrases.json": ["pronunciation"], "silben_puzzles.json": ["games"],
    "cloze.json": ["games", "course"], "satz_sentences.json": ["games", "course"],
    "kkeunmari_pool.json": ["games"], "kkeunmari_nouns.json": ["games"],
    "media_phrases.json": ["book_capture", "support"], "usage_notes.json": ["vocab_packs", "word_web"],
    "word_relations.json": ["word_web"], "culture_notes.json": ["book_capture", "rewards"],
    "onboarding_journey_paths.json": ["onboarding"], "onboarding_v3_demo_content.json": ["onboarding"],
    "tts_canonical_manifest.json": ["scenarios", "listening", "smalltalk"],
    "tts_first_line_manifest.json": ["scenarios", "listening"],
    "ildu_world_manifest_v1.json": ["hanok"], "ildu_construction_art_v1.json": ["hanok"],
    "sarangchae_construction_v3.json": ["hanok"], "hanok_download_manifest.json": ["hanok"],
}
DART_TABLE_MODULES = {
    "lib/data/sticker_catalog.dart": ["gye"],
    "lib/data/quest_catalog.dart": ["hanok", "rewards", "support"],
    "lib/data/personal_room_catalog.dart": ["hanok"],
    "lib/data/pack_artwork_catalog.dart": ["vocab_packs"],
    "lib/data/curriculum_alignment_registry.dart": ["course", "phases"],
    "lib/data/cloze_topic_groups.dart": ["games"],
    "lib/data/gye_dedication_catalog.dart": ["gye"],
    "lib/data/hanja_lexicon.dart": ["book_capture", "word_web"],
    "lib/models/scenario_character.dart": ["scenarios", "listening"],
    "lib/models/discover_catalog.dart": ["support", "c_roots"],
    "lib/widgets/sori/placed_decoration.dart": ["hanok", "rewards"],
}


class Audit:
    def __init__(self, root: Path, artifacts: Path):
        self.root = root.resolve()
        self.artifacts = artifacts.resolve()
        self.generator_sha256 = file_hash(Path(__file__))
        self.sources: dict[str, dict[str, Any]] = {}
        self.text: dict[str, str] = {}
        self.paths: dict[str, Path] = {}
        self.records: list[dict[str, Any]] = []
        self.raw_records: dict[str, Any] = {}
        self.tables: dict[str, Any] = {}
        self.issues: list[dict[str, Any]] = []
        self.checks: list[dict[str, Any]] = []
        self.media: dict[str, dict[str, Any]] = {}
        self.scenario_lineage: list[dict[str, Any]] = []
        self.context_lineage: list[dict[str, Any]] = []
        self.legacy_reward_test_backup: dict[str, Any] | None = None
        self.execution_evidence: dict[str, Any] = {
            "status": "parent_task_execution_reports; no log receipt yet; generator does not run Flutter tests",
            "independently_verified_by_generator": False,
            "reported_passed_suites": [{"suite": "Foundation", "tests": 61},
                {"suite": "Dokkaebi intro", "tests": 15}, {"suite": "Intro clip", "tests": 12},
                {"suite": "Course/Hanok/Gye/support", "tests": 202}, {"suite": "Game/content flows", "tests": 110},
                {"suite": "Reward service", "tests": 73}, {"suite": "Runtime content", "tests": 16},
                {"suite": "Startup", "tests": 2}, {"suite": "Earlier broad pack/account", "tests": 275}],
            "other_owner_report": {"suite": "C Einleitung", "tests": 179, "status": "reported by current C task"},
            "root_Today_entry_Bojagi": "prior source passed; current five-tab C styling in progress; final receipt pending",
            "build": "earlier production-route web build reported passed; final C runtime source build pending",
            "rendered_visual": "earlier Foundation390 DE observed; final C runtime roots pending",
            "device": "Android physical devices0 reported; device QA not run", "final_user_approval": "not_inferred",
            "count_policy": "Suite reports can overlap; do not sum as independent tests or exact-SHA CI proof."}

    def issue(self, code: str, detail: Any, severity: str = "gap") -> None:
        self.issues.append({"code": code, "severity": severity, "detail": detail})

    def register(self, path: Path, key: str, scope: str) -> None:
        stat = path.stat()
        self.paths[key] = path
        self.sources[key] = {"id": key, "path": path.as_posix(), "scope": scope,
                             "bytes": stat.st_size, "sha256": file_hash(path)}
        if path.suffix.lower() in TEXT_SUFFIXES:
            try:
                self.text[key] = path.read_text(encoding="utf-8-sig")
            except UnicodeError:
                self.issue("non_utf8_source", key)

    def collect_sources(self) -> None:
        for folder in ("lib", "assets/data", "docs/data", "docs/assets", "tools/content_factory"):
            for path in sorted((self.root / folder).rglob("*")):
                if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES:
                    self.register(path, path.relative_to(self.root).as_posix(),
                                  "authoring_review_or_history_not_live" if folder == "tools/content_factory" else
                                  "visual_preview_not_production" if "ux_preview" in path.name else
                                  "current_runtime_source" if folder == "lib" else "source_table_or_reference")
        for name in ("pubspec.yaml", "tool/concept_c_preview.dart", "tool/canonical_ui_preview.dart", "tool/c_content_flow_preview.dart"):
            path = self.root / name
            if path.is_file():
                self.register(path, name, "packaging" if name == "pubspec.yaml" else "visual_preview_not_production")
        for package, folder in ARTIFACT_FOLDERS.items():
            base = self.artifacts / folder
            if not base.is_dir():
                self.issue("missing_handoff_package", {"id": package, "path": str(base)})
                continue
            for path in sorted(base.rglob("*")):
                if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES:
                    self.register(path, "handoff:" + package + "/" + path.relative_to(base).as_posix(),
                                  "historical_handoff_not_live_proof")
        receipt = self.artifacts / "c-implementation-20261005/pr446-import-receipt.json"
        if receipt.is_file():
            self.register(receipt, "handoff:pr446-import-receipt", "local_import_receipt_not_device_QA")
            for item in json.loads(receipt.read_text(encoding="utf-8"))["files"]:
                name = item["path"]
                if name.startswith("test/") and (self.root / name).is_file():
                    self.register(self.root / name, name, "test_source_present; execution_not_inferred")
        approved_import = self.artifacts / "c-implementation-20261005/approved-media-import.json"
        if approved_import.is_file():
            self.register(approved_import, "handoff:approved-media-import", "owner_selected_original_media_import_receipt_not_visual_QA")
        for pattern in ("foundation*test.dart", "bojagi*test.dart", "single_decoration_reward*test.dart", "decoration_reward_receipt*test.dart"):
            for path in sorted((self.root / "test").rglob(pattern)):
                self.register(path, path.relative_to(self.root).as_posix(), "test_source_present; execution_not_inferred")
        backup = self.artifacts / "c-implementation-20261005/bojagi-screen-tests-before.dart"
        if backup.is_file():
            key = "handoff:legacy-bojagi-candidate-tests"
            self.register(backup, key, "superseded_candidate_UI_test_source_preserved_not_current_acceptance")
            original = "test/bojagi_screen_test.dart"
            self.legacy_reward_test_backup = {"source_id": key, "backup_path": backup.as_posix(),
                "backup_sha256": self.sources[key]["sha256"], "backup_bytes": self.sources[key]["bytes"],
                "current_test_source_id": original, "current_test_sha256": self.sources.get(original, {}).get("sha256"),
                "status": "Previous candidate-selection UI tests retained in the owner's exact-byte backup. The approved current UI uses one item; preserved history is not a requirement to restore three-choice UI.",
                "automation_status": "test source receipt only; test execution not inferred"}
        execution_receipt = self.artifacts / "c-implementation-20261005/verification-status.json"
        if execution_receipt.is_file():
            key = "handoff:current-C-verification-status"
            self.register(execution_receipt, key, "current_owner_execution_receipt_not_source_fidelity_or_final_user_approval")
            self.execution_evidence = {"source_id": key, "source_sha256": self.sources[key]["sha256"],
                "independently_executed_by_generator": False,
                "receipt": json.loads(execution_receipt.read_text(encoding="utf-8")),
                "boundary": "Owner's reported executions retain distinct source/test/UI/build/visual/device/approval states; generator verifies receipt bytes, not rerun outcomes."}

    def add_record(self, source: str, ptr: str, value: Any, modules: list[str],
                   role: str, identity: str, parent: str | None = None,
                   inherited_level: str | None = None) -> str:
        uid = source + "#" + ptr
        revision = next((value[k] for k in ("revision", "contentRevision", "proofRevision")
                         if isinstance(value, dict) and k in value), None)
        own_assets = sorted(set(ASSET_RE.findall(json.dumps(value, ensure_ascii=False))))
        record = {
            "uid": uid, "id": identity, "identity_role": role, "source_id": source,
            "pointer": ptr, "source_sha256": self.sources[source]["sha256"],
            "record_sha256": digest(value), "revision": revision,
            "revision_policy": "authored_revision" if revision is not None else "not_authored; retain source and record hash",
            "module_binding_ids": modules, "parent_uid": parent,
            "access": {"binding_ids": modules,
                       "status": "source_table_to_loader/filter/typed_args_contract; runtime success unverified" if modules else "research/authoring/reference table; no product loader inferred"},
            "level": value.get("level", inherited_level) if isinstance(value, dict) else inherited_level,
            "asset_paths": own_assets,
            "references": [{"field_pointer": p, "id": v} for p, v in reference_values(value)],
        }
        if isinstance(value, dict):
            for field in ("kind", "contentKind", "topicId", "category", "pack_id", "phaseId", "mode", "role", "lifecycle", "rubricVersion", "contentHash", "status"):
                if field in value:
                    record[field] = value[field]
        self.records.append(record)
        self.raw_records[uid] = value
        return uid

    def enumerate_table(self, source: str, value: Any, modules: list[str]) -> None:
        def walk(item: Any, ptr: str, parent: str | None, depth: int,
                 collection: str, as_row: bool = False, level: str | None = None) -> None:
            next_parent = parent
            if isinstance(item, dict):
                level = item.get("level", level)
                fields = ("id", "stageId", "scenarioId", "buildingId", "assessmentItemId")
                field = next((k for k in fields
                              if isinstance(item.get(k), (str, int)) and str(item[k])), None)
                if field:
                    role = "authored_id" if field == "id" else "reference_or_scoped_id"
                    if field == "assessmentItemId":
                        role = "draft_assessment_definition_identity" if source.endswith("drafts/productive_assessments.json") and ptr.startswith("/definitions/") else "scoped_assessment_requirement_reference_not_primary_catalog_identity"
                    if field == "id" and (source.endswith("can_do_content_authorities.json") and ptr.startswith("/contentReferences/")
                                          or source.endswith("can_do_segments.json") and re.search(r"/contentClusters/\d+/contentReferences/", ptr)):
                        role = "canonical_content_reference_not_primary_library_identity"
                    next_parent = self.add_record(source, ptr, item, modules, role, str(item[field]), parent, level)
                elif as_row and depth <= 3:
                    natural = next((str(item[k]) for k in ("word", "ko", "phaseId", "contentId")
                                    if isinstance(item.get(k), str)), None)
                    next_parent = self.add_record(source, ptr, item, modules,
                                                 "natural_key" if natural else "source_row_without_authored_id",
                                                 natural or ptr, parent, level)
                for key, child in item.items():
                    walk(child, ptr + "/" + pointer_token(key), next_parent, depth + 1,
                         collection or key, level=level)
            elif isinstance(item, list):
                for i, child in enumerate(item):
                    child_level = level
                    if collection.lower() in LEVELS:
                        child_level = collection.lower()
                    at = ptr + "/" + str(i)
                    if isinstance(child, (str, int, float, bool)) and depth <= 2:
                        self.add_record(source, at, child, modules,
                                        "natural_word_key" if collection == "words" else "source_scalar_or_reference_row_not_authored_ID",
                                        str(child), parent, child_level)
                    else:
                        walk(child, at, parent, depth + 1, collection, True, child_level)
        walk(value, "", None, 0, "")

    def collect_records(self) -> None:
        for source, text in sorted(self.text.items()):
            if not source.startswith(("assets/data/", "docs/data/", "docs/assets/", "tools/content_factory/")):
                continue
            suffix = self.paths[source].suffix.lower()
            if suffix not in TABLE_SUFFIXES:
                continue
            modules = DATA_MODULES.get(Path(source).name, []) if source.startswith("assets/data/") else []
            if source == "tools/content_factory/drafts/productive_assessments.json":
                modules = ["productive_draft"]
            if source.startswith("assets/data/") and Path(source).name.startswith("scenarios_"):
                modules = ["scenarios", "listening"]
            try:
                if suffix == ".json":
                    table = json.loads(text)
                elif suffix == ".jsonl":
                    table = [json.loads(line) for line in text.splitlines() if line.strip()]
                else:
                    table = list(csv.DictReader(io.StringIO(text)))
                self.tables[source] = table
                self.enumerate_table(source, table, modules)
                if isinstance(table, dict):
                    self.sources[source]["authored_table_metadata"] = {
                        key: table[key] for key in ("schemaVersion", "version", "revision", "contentRevision", "reviewStatus", "status", "sourceAuthority")
                        if key in table and not isinstance(table[key], (dict, list))}
                consumers = [{"source_id": key, "lines": [i + 1 for i, line in enumerate(body.splitlines()) if source in line]}
                             for key, body in self.text.items() if key.startswith("lib/") and source in body]
                self.sources[source]["table_access"] = {
                    "module_binding_ids": modules, "exact_source_literal_consumers": consumers,
                    "dynamic_family_contract": "ScenarioLoader.shardPath(LearnerLevel)" if source.startswith("assets/data/") and Path(source).name.startswith("scenarios_") else None,
                    "status": "authoring_draft_only_runtime_closed" if modules == ["productive_draft"] else
                              "current_source_contract; no UI success inferred" if modules else "reference_or_authoring_only_not_live"}
            except (ValueError, csv.Error) as error:
                self.issue("table_parse_error", {"source": source, "error": str(error)},
                           "gap" if source.startswith("tools/content_factory/") else "error")
        vocab_source = "assets/data/korean_vocab.csv"
        packs: dict[str, list[dict[str, str]]] = collections.defaultdict(list)
        for row in self.tables[vocab_source]:
            if row["pack_id"]:
                packs[row["pack_id"]].append(row)
        for pack_id, rows in sorted(packs.items()):
            ordered = sorted(rows, key=lambda row: int(row["pack_order"] or 0))
            self.add_record(vocab_source, "/derived_pack/" + pointer_token(pack_id),
                            {"id": pack_id, "level": ordered[0]["level"],
                             "sourceIds": [row["id"] for row in ordered],
                             "loader_rule": "VocabPackService group by Vocab.packId, then packOrder"},
                            ["vocab_packs"], "derived_runtime_pack_id_from_CSV", pack_id)
        # Embedded stable IDs and alphabet rows are auditable, not silently omitted.
        source_modules: dict[str, list[str]] = collections.defaultdict(list)
        for identifier, spec in MODULE_DEFINITIONS.items():
            for source in spec[0] + spec[1]:
                source_modules[source].append(identifier)
        for source, text in sorted(self.text.items()):
            if not source.startswith("lib/"):
                continue
            preview = "ux_preview" in source
            modules = ([] if preview else DART_TABLE_MODULES.get(source,
                       ["hangul", "calligraphy"] if "hangul_" in source and source.startswith("lib/data/") else
                       source_modules.get(source, ["c_roots"] if source.startswith("lib/data/") else [])))
            for match in re.finditer(r"^[ \t]*id:\s*(['\"])([^\r\n]*?)\1", text, re.M):
                if not match.group(2) or "$" in match.group(2):
                    continue
                line = text.count("\n", 0, match.start()) + 1
                value = {"id": match.group(2), "line": line, "expression": match.group(0)}
                if source == "lib/models/scenario_character.dart":
                    opening = text.rfind("ScenarioCharacterProfile(", 0, match.start())
                    expression = balanced(text, text.index("(", opening))
                    value["expression"] = expression
                    for field in ("nameKo", "nameDe", "nameEn", "voice"):
                        value[field] = literal_field(expression, field)
                self.add_record(source, "/dart/id_literal/" + str(line),
                                value,
                                modules, "preview_literal_not_production" if preview else "dart_literal_identity_not_parsed_model", match.group(2))
            if source == "lib/data/sticker_catalog.dart":
                for match in re.finditer(r"StickerSpec\((\d+),\s*'([^']+)',\s*StickerCategory\.(\w+)\)", text):
                    line = text.count("\n", 0, match.start()) + 1
                    self.add_record(source, "/dart/StickerSpec/" + str(line),
                                    {"id": match.group(2), "wireCode": int(match.group(1)), "category": match.group(3),
                                     "asset": "assets/stickers/" + match.group(2) + ".png", "expression": match.group(0)},
                                    modules, "authored_sticker_slug_and_wire_code", match.group(2))
            if source == "lib/data/hangul_data.dart":
                for match in re.finditer(r"HangulChar\(\s*(['\"])(.*?)\1", text, re.S):
                    expr = balanced(text, text.index("(", match.start()))
                    line = text.count("\n", 0, match.start()) + 1
                    self.add_record(source, "/dart/HangulChar/" + str(line),
                                    {"letter": match.group(2), "expression": expr}, modules,
                                    "natural_letter_key", match.group(2))
        self.collect_revision_history()
        self.collect_scenario_lineage()
        self.collect_foundation_identities()
        self.collect_decoration_identities()
        writer_source = "tools/content_factory/canonical_scenarios/character_profiles.json"
        for role, value in self.tables.get(writer_source, {}).get("runtimeRoleProfiles", {}).items():
            ptr = "/runtimeRoleProfiles/" + pointer_token(role)
            if writer_source + "#" + ptr not in self.raw_records:
                self.add_record(writer_source, ptr, value, [], "authoring_role_profile_key_not_live_content", role)

    def collect_decoration_identities(self) -> None:
        for source, marker, modules, role in (
                ("lib/services/decoration_reward_service.dart", "kDecorationRewardPool", ["rewards", "hanok"], "ordered_live_reward_pool_identity"),
                ("lib/widgets/sori/placed_decoration.dart", "kAvailableDecorations", ["hanok", "rewards"], "authored_decoration_catalog_slug")):
            text = self.text[source]
            pattern = re.search(r"\b" + marker + r"\s*=\s*(?:<[^>]+>)?\s*[\[{](.*?)[\]}];", text, re.S)
            if not pattern:
                self.issue("embedded_identity_table_absent", {"source": source, "marker": marker})
                continue
            for match in re.finditer(r"'([^']+)'", pattern.group(1)):
                identity = match.group(1)
                if not identity.startswith("decoration_"):
                    continue
                line = text.count("\n", 0, pattern.start(1) + match.start()) + 1
                self.add_record(source, "/dart/" + marker + "/" + str(line),
                                {"id": identity, "asset": "assets/illustrations/decorations/" + identity + ".png",
                                 "table": marker, "line": line}, modules, role, identity)

    def collect_revision_history(self) -> None:
        path = "assets/data/smalltalk_context_cases.json"
        current = self.tables[path]
        history = []
        for commit in dict.fromkeys((CONTEXT_LINEAGE_COMMIT, git(self.root, "rev-parse", "HEAD"))):
            blob = subprocess.check_output(["git", "-C", str(self.root), "show", commit + ":" + path])
            historical = json.loads(blob.decode("utf-8"))
            key = "git:" + commit + ":" + path
            self.sources[key] = {"id": key, "path": key, "scope": "previous_revision_history_not_current_catalog",
                                 "git_commit": commit,
                                 "sha256": hashlib.sha256(blob).hexdigest(), "bytes": len(blob),
                                 "hash_encoding": "exact Git blob bytes"}
            previous = {c["id"]: c for c in historical["cases"]}
            for case in current["cases"]:
                old = previous.get(case["id"])
                if old and digest(old) != digest(case):
                    i = next(i for i, c in enumerate(historical["cases"]) if c["id"] == case["id"])
                    uid = self.add_record(key, "/cases/" + str(i), old, ["talsunbi_context"],
                                          "historical_revision_not_current", old["id"])
                    _, preserved, start, end = exact_record_span(blob, old["id"])
                    self.context_lineage.append({"id": old["id"], "revision": old["revision"],
                        "source_id": key, "historical_uid": uid, "source_commit": commit,
                        "original_record_utf8": preserved.decode("utf-8"), "original_record_bytes": len(preserved),
                        "original_record_sha256": hashlib.sha256(preserved).hexdigest(),
                        "original_blob_byte_start": start, "original_blob_byte_end_exclusive": end,
                        "parsed_record_sha256": digest(old), "status": "historical_revision_not_current"})
                    history.append({"id": case["id"], "previous_uid": uid,
                                    "previous_revision": old["revision"], "current_revision": case["revision"],
                                    "source_commit": commit, "current_record_sha256": digest(case),
                                    "history_policy": "Pinned pre-import revision remains after HEAD advances. Retain old PracticeSourceReference; never rewrite old attempts as new revision."})
        self.revision_history = history

    def collect_foundation_identities(self) -> None:
        source = "lib/models/foundation_progress.dart"
        text = self.text.get(source, "")
        steps: dict[str, str] = {}
        for enum in ("FoundationStep", "FoundationTask"):
            match = re.search(r"enum\s+" + enum + r"\s*\{(.*?)\n\s*const\s+" + enum, text, re.S)
            if not match:
                self.issue("foundation_enum_source_absent", {"source": source, "enum": enum}, "error")
                continue
            for row in re.finditer(r"\b(\w+)\('([^']+)'(?:,\s*FoundationStep\.(\w+))?\)", match.group(1)):
                identity = row.group(2)
                start = match.start(1) + row.start()
                line = text.count("\n", 0, start) + 1
                value = {"id": identity, "enum": enum, "enumMember": row.group(1),
                         "line": line, "sourceExpression": row.group(0)}
                if enum == "FoundationStep":
                    steps[row.group(1)] = identity
                else:
                    value["stepId"] = steps.get(row.group(3))
                self.add_record(source, "/dart/" + enum + "/" + str(line), value,
                                ["foundation"], "authored_enum_identity", identity)
        current = [r for r in self.records if r["source_id"] == source]
        for enum, expected in (("FoundationStep", 4), ("FoundationTask", 12)):
            values = [r for r in current if self.raw_records[r["uid"]].get("enum") == enum]
            passed = len(values) == expected and len({r["id"] for r in values}) == expected
            self.checks.append({"id": "foundation_identity_count:" + enum, "passed": passed,
                                "detail": {"expected": expected, "ids": [r["id"] for r in values]}})
            if not passed:
                self.issue("foundation_identity_count_changed", enum, "error")

    def collect_scenario_lineage(self) -> None:
        """Archive removed canonical identities without adding them to live lessons."""
        current = [s for name, table in self.tables.items() if name.startswith("assets/data/scenarios_") for s in table["scenarios"]]
        for identity, shard, analogous_id in (
                ("lost_phone", "assets/data/scenarios_a2.json", None),
                ("bank_account", "assets/data/scenarios_b1.json", "a2_w10_money")):
            git_source = SCENARIO_LINEAGE_COMMIT + ":" + shard
            try:
                blob = subprocess.check_output(["git", "-C", str(self.root), "show", git_source])
                value, preserved, start, end = exact_record_span(blob, identity)
            except (subprocess.CalledProcessError, ValueError) as error:
                self.issue("historical_canonical_record_unavailable", {"id": identity, "git_source": git_source,
                           "action": "Recover the selected pre-promotion Git record before resolving the canonical authority.",
                           "error": str(error)}, "error")
                continue
            key = "git:" + git_source
            self.sources[key] = {"id": key, "path": key, "scope": "historical_removed_scenario_not_live",
                                 "git_commit": SCENARIO_LINEAGE_COMMIT,
                                 "git_blob_oid": git(self.root, "rev-parse", git_source),
                                 "sha256": hashlib.sha256(blob).hexdigest(), "bytes": len(blob),
                                 "hash_encoding": "exact Git blob bytes"}
            table = json.loads(blob.decode("utf-8"))
            index = next(i for i, row in enumerate(table["scenarios"]) if row["id"] == identity)
            uid = self.add_record(key, "/scenarios/" + str(index), value, ["course", "scenarios"],
                                  "historical_removed_scenario_not_current_catalog", identity)
            record = self.records[-1]
            record["access"]["status"] = "archive_only; no current library selection, lesson, TTS or assessment inferred"
            unit = value.get("courseUnitId")
            unit_variants = [{"id": row["id"], "level": row.get("level"), "courseUnitId": row.get("courseUnitId"),
                              "record_sha256": digest(row), "status": "current_same_unit_variant; not a declared identity replacement"}
                             for row in current if row.get("courseUnitId") == unit]
            analogous = next((row for row in current if row["id"] == analogous_id), None)
            aliases = [{"source_id": source, "line": i + 1, "excerpt": line.strip()}
                       for source, body in self.text.items() if source.startswith("lib/")
                       for i, line in enumerate(body.splitlines()) if re.search(r"\b" + identity + r"\b", line)]
            current_exact = [row for row in current if row["id"] == identity]
            promotion_blob = subprocess.check_output(["git", "-C", str(self.root), "show", SCENARIO_PROMOTION_COMMIT + ":" + shard])
            promotion_source = "git:" + SCENARIO_PROMOTION_COMMIT + ":" + shard
            removed_in_promotion = all(row["id"] != identity for row in json.loads(promotion_blob)["scenarios"])
            self.sources[promotion_source] = {"id": promotion_source, "path": promotion_source,
                "scope": "historical_promotion_boundary_not_current_catalog", "git_commit": SCENARIO_PROMOTION_COMMIT,
                "sha256": hashlib.sha256(promotion_blob).hexdigest(), "bytes": len(promotion_blob),
                "hash_encoding": "exact Git blob bytes"}
            archive = {"id": identity, "historical_uid": uid, "source_id": key,
                       "last_observed_source_commit": SCENARIO_LINEAGE_COMMIT,
                       "corpus_promotion_commit": SCENARIO_PROMOTION_COMMIT,
                       "current_exact_id_present": bool(current_exact), "historical_level": value.get("level"),
                       "removal_verified_in_promotion": removed_in_promotion,
                       "promotion_source_id": promotion_source,
                       "historical_courseUnitId": unit, "historical_revision": value.get("revision"),
                       "original_record_utf8": preserved.decode("utf-8"),
                       "original_record_bytes": len(preserved), "original_record_sha256": hashlib.sha256(preserved).hexdigest(),
                       "original_blob_byte_start": start, "original_blob_byte_end_exclusive": end,
                       "parsed_record_sha256": digest(value),
                       "current_same_unit_variants": unit_variants,
                       "current_analogous_variant": {"id": analogous["id"], "level": analogous.get("level"),
                              "courseUnitId": analogous.get("courseUnitId"), "record_sha256": digest(analogous),
                              "status": "same banking theme at A2; different level/unit; no alias or replacement authority"} if analogous else None,
                       "current_runtime_ID_literal_evidence": aliases,
                       "resolution_status": "historical_source_preserved; current canonical reference unresolved; no declared replacement/alias",
                       "action": "Course/authority owner must review restoration, explicit lineage migration, or an archived authority. Preserve old saved IDs/revisions; never infer current lesson coverage, remap B1 evidence to A2, or grant assessment from a thematic match."}
            self.scenario_lineage.append(archive)
            for suffix, passed in (("byte_preservation", preserved == blob[start:end]),
                                   ("parsed_identity", json.loads(preserved)["id"] == identity),
                                   ("removed_in_promotion", removed_in_promotion),
                                   ("removed_from_current_catalog", not current_exact)):
                self.checks.append({"id": "historical_lineage:" + identity + ":" + suffix,
                                    "passed": passed, "detail": key})
                if not passed:
                    self.issue("historical_lineage_changed", {"id": identity, "check": suffix}, "error")

    def validate_content(self) -> dict[str, int]:
        def check(code: str, ok: bool, detail: Any) -> None:
            self.checks.append({"id": code, "passed": bool(ok), "detail": detail})
            if not ok:
                self.issue(code, detail, "error")
        manifest = self.tables["assets/data/curriculum_manifest.json"]
        phases = self.tables["assets/data/learning_phases.json"]
        packets = self.tables["assets/data/phase_tasks.json"]
        smalltalk = self.tables["assets/data/smalltalk.json"]
        scenarios = [s for key, table in self.tables.items() if key.startswith("assets/data/scenarios_")
                     for s in table["scenarios"]]
        content = {
            "vocab": self.tables["assets/data/korean_vocab.csv"],
            "grammar": self.tables["assets/data/grammar.csv"],
            "smalltalk": smalltalk["phrases"], "scenario": scenarios,
            "cloze": self.tables["assets/data/cloze.json"]["items"],
            "satz": self.tables["assets/data/satz_sentences.json"]["items"],
        }
        ids = {kind: {r["id"] for r in rows} for kind, rows in content.items()}
        for kind, rows in content.items():
            check("unique_" + kind + "_ids", len(ids[kind]) == len(rows), {"rows": len(rows), "unique": len(ids[kind])})
        profile_source = "lib/models/scenario_character.dart"
        profiles = {r["id"]: self.raw_records[r["uid"]] for r in self.records if r["source_id"] == profile_source}
        bible = self.tables.get("tools/content_factory/canonical_scenarios/character_profiles.json", {})
        writers = {row["id"]: row for row in bible.get("recurringCharacters", [])}
        role_profiles = bible.get("runtimeRoleProfiles", {})
        check("scenario_character_full_ID_partition", set(profiles) == set(writers) | set(role_profiles), sorted(profiles))
        for identity, profile in profiles.items():
            writer = writers.get(identity)
            role = role_profiles.get(identity)
            aligned = (profile["voice"] == writer["voice"] and
                       all(profile["name" + lang.capitalize()] == writer["displayNames"][lang] for lang in ("ko", "de", "en"))) if writer else (
                       role is not None and profile["voice"] == role["voice"] and profile["nameKo"] == role["displayNameKo"])
            check("scenario_character_display_TTS:" + identity, aligned, profile_source)
        for scenario in scenarios:
            check("scenario_character_references:" + scenario["id"], scenario["playerCharacterId"] in profiles
                  and set(scenario["participantIds"]) <= set(profiles), scenario["participantIds"])
        sticker_rows = [self.raw_records[r["uid"]] for r in self.records if r["identity_role"] == "authored_sticker_slug_and_wire_code"]
        check("sticker_wire_identity_partition", len(sticker_rows) == 30 and
              {r["wireCode"] for r in sticker_rows} == set(range(1, 31)) and len({r["id"] for r in sticker_rows}) == 30, len(sticker_rows))
        for r in self.records:
            if r["identity_role"] in {"authored_sticker_slug_and_wire_code", "ordered_live_reward_pool_identity", "authored_decoration_catalog_slug"}:
                value = self.raw_records[r["uid"]]
                check("compiled_asset_ID:" + r["uid"], (self.root / value["asset"]).is_file(), value["asset"])
        units = {u["id"] for u in manifest["courseUnits"]}
        concepts = {u["id"] for u in manifest["concepts"]}
        check("course_unit_unique", len(units) == len(manifest["courseUnits"]), len(units))
        for i, link in enumerate(manifest["contentLinks"]):
            check("curriculum_link:" + str(i), link["contentId"] in ids.get(link["contentKind"], set())
                  and link["courseUnitId"] in units and set(link["conceptIds"]) <= concepts,
                  {"contentKind": link["contentKind"], "contentId": link["contentId"], "courseUnitId": link["courseUnitId"]})
        for u in manifest["courseUnits"]:
            targets = [v.split(":", 1) for v in u["checkpointContentIds"]]
            check("unit_references:" + u["id"], set(u["requiredConceptIds"]) <= concepts
                  and all(v in ids.get(kind, set()) for kind, v in targets), u["checkpointContentIds"])
        for kind in ("smalltalk", "listening"):
            lessons = self.tables["assets/data/" + kind + "_lessons.json"]["lessons"]
            source_kind = "smalltalk" if kind == "smalltalk" else "scenario"
            used = []
            qids = []
            check(kind + "_lesson_unique", len({l["id"] for l in lessons}) == len(lessons), len(lessons))
            for lesson in lessons:
                used.extend(lesson["contentIds"])
                check("lesson_sources:" + lesson["id"], set(lesson["contentIds"]) <= ids[source_kind], lesson["contentIds"])
                for q in lesson["questions"]:
                    qids.append(q["id"])
                    valid = bool(q["sourceIds"]) and set(q["sourceIds"]) <= set(lesson["contentIds"])
                    if q["type"] == "choice":
                        valid &= len(q["options"]) >= 2 and 0 <= q["correctIndex"] < len(q["options"])
                    elif q["type"] == "order":
                        valid &= bool(q["targetKo"].strip())
                    else:
                        valid = False
                    check("lesson_question:" + q["id"], valid, q["sourceIds"])
            check(kind + "_all_sources_partitioned", unique_partition(used, ids[source_kind]),
                  {"used": len(used), "expected": len(ids[source_kind]), "missing": sorted(ids[source_kind] - set(used))})
            check(kind + "_question_ids_unique", len(qids) == len(set(qids)), len(qids))
        tasks = {t["id"]: t for t in packets["tasks"]}
        phase_ids = {p["id"] for p in phases["phases"]}
        check("phase_task_unique", len(tasks) == len(packets["tasks"]), len(tasks))
        check("phase_catalog_fingerprint", digest(packets) == phases["phaseTaskSourceSha256"], phases["phaseTaskSourceSha256"])
        linked = []
        for p in phases["phases"]:
            linked.extend(p["taskIds"])
            check("phase_links:" + p["id"], set(p["practiceUnitIds"]) <= units and
                  all(t in tasks and tasks[t]["phaseId"] == p["id"] and tasks[t]["level"] == p["level"] for t in p["taskIds"]), p["taskIds"])
        check("all_tasks_reachable_from_phase", unique_partition(linked, set(tasks)),
              {"linked": len(linked), "tasks": len(tasks)})
        for t in tasks.values():
            body = {k: v for k, v in t.items() if k != "contentHash"}
            check("task_hash:" + t["id"], digest(body) == t["contentHash"], t["contentHash"])
            check("task_dependencies:" + t["id"], t["phaseId"] in phase_ids and
                  set(t["prerequisiteTaskIds"]) <= set(tasks) and t["id"] not in t["prerequisiteTaskIds"], t["prerequisiteTaskIds"])
        active, visited = set(), set()
        def visit(task_id: str) -> None:
            if task_id in active:
                raise ValueError("cyclic task prerequisite: " + task_id)
            if task_id in visited:
                return
            active.add(task_id)
            for dependency in tasks[task_id]["prerequisiteTaskIds"]:
                if dependency in tasks:
                    visit(dependency)
            active.remove(task_id)
            visited.add(task_id)
        try:
            for task_id in tasks:
                visit(task_id)
            check("task_dependencies_acyclic", True, len(visited))
        except ValueError as error:
            check("task_dependencies_acyclic", False, str(error))
        for objective in packets["objectives"]:
            for binding in objective["bindings"]:
                t = tasks.get(binding["taskId"])
                check("objective_binding:" + objective["id"] + ":" + binding["taskId"],
                      t is not None and binding["taskHash"] == t["contentHash"], binding["taskId"])
        cases = self.tables["assets/data/smalltalk_context_cases.json"]["cases"]
        for case in cases:
            check("context_source:" + case["id"], set(case["sourcePhraseIds"]) <= ids["smalltalk"], case["sourcePhraseIds"])
        # Canonical authorities are a separate revision/lineage layer. Missing current
        # library identities are retained and reported, never falsely resolved via
        # the authority's own copy of that same ID.
        authorities = self.tables["assets/data/can_do_content_authorities.json"]
        pack_ids = {r["pack_id"] for r in content["vocab"] if r["pack_id"]}
        draft_source = "tools/content_factory/drafts/productive_assessments.json"
        productive = self.tables[draft_source]
        project_ids = {r["id"] for r in productive["projects"]}
        target_ids = {**ids, "vocabPack": pack_ids, "project": project_ids}
        self.productive_draft_status = {"source_id": draft_source, "source_sha256": self.sources[draft_source]["sha256"],
            "definition_ids": [r["assessmentItemId"] for r in productive["definitions"]],
            "project_ids": sorted(project_ids), "snippet_ids": [r["id"] for r in productive["sourceSnippets"]],
            "bundles": [{k: row[k] for k in ("canDoSegmentId", "projectId", "stepId", "assessmentItemIds")} for row in productive["bundles"]],
            "runtime_approved": False, "runtime_gate_source": self.evidence("lib/services/productive_assessment_service.dart", ["runtimeContentApproved"]),
            "loader_gate_source": self.evidence("lib/services/canonical_course_segment_loader.dart", ["Approved productive assessment"]),
            "action": "Complete owner per-ID content review and deliberate catalog promotion/injection. Keep unpublished draft IDs/history visible as provenance; no assessed mastery or economy grant."}
        check("productive_runtime_gate_closed", re.search(r"runtimeContentApproved\s*=\s*false", self.text["lib/services/productive_assessment_service.dart"]) is not None,
              "ProductiveAssessmentCatalog.runtimeContentApproved=false is preserved; deliberate promotion requires audit update.")
        self.issue("productive_catalog_authoring_draft_not_runtime", self.productive_draft_status)
        seeds = {s["id"] for s in authorities["sourceSeeds"]}
        for index, reference in enumerate(authorities["contentReferences"]):
            kind = reference["kind"]
            check("canonical_authority_source:" + str(index) + ":" + reference["id"],
                  reference["sourceSeedId"] in seeds and reference["courseUnitId"] in units and reference["level"] in LEVELS,
                  {"kind": kind, "id": reference["id"], "sourceSeedId": reference["sourceSeedId"], "courseUnitId": reference["courseUnitId"]})
            if kind in target_ids and reference["id"] in target_ids[kind]:
                check("canonical_library_target:" + str(index) + ":" + reference["id"], True,
                      {"kind": kind, "id": reference["id"], "status": "authoring_draft_only_runtime_closed" if kind == "project" else "current_source_identity"})
            if kind in target_ids and reference["id"] not in target_ids[kind]:
                self.issue("canonical_authority_without_current_library_record", {
                    "kind": kind, "id": reference["id"], "sourceSeedId": reference["sourceSeedId"],
                    "courseUnitId": reference["courseUnitId"],
                    "status": "historical source preserved; missing current target; requires loader/evaluator owner review",
                    "lineage_file": (OUTPUT / "lineage-records.json").as_posix(),
                    "lineage": {k: entry[k] for entry in self.scenario_lineage if entry["id"] == reference["id"]
                                for k in ("last_observed_source_commit", "corpus_promotion_commit", "historical_uid", "current_analogous_variant", "resolution_status", "action")}})
        segments = self.tables["assets/data/can_do_segments.json"]
        clusters = {c["id"] for c in segments["contentClusters"]}
        for cluster in segments["contentClusters"]:
            check("cluster_seeds:" + cluster["id"], set(cluster["sourceSeedIds"]) <= seeds, cluster["sourceSeedIds"])
            for i, reference in enumerate(cluster["contentReferences"]):
                valid = reference["id"] in target_ids.get(reference["kind"], set())
                self.checks.append({"id": "cluster_library_target:" + cluster["id"] + ":" + str(i),
                                    "passed": valid, "severity": "source_integrity" if valid else "declared_canonical_lineage_gap",
                                    "detail": {**reference, "status": "authoring_draft_only_runtime_closed" if reference["kind"] == "project" else "current_source_or_declared_lineage"}})
                if not valid and reference["id"] not in {row["id"] for row in self.scenario_lineage}:
                    self.issue("unresolved_canonical_cluster_target", {"cluster": cluster["id"], "reference": reference,
                               "action": "Resolve the explicit source identity or preserve a documented archive/draft status; never satisfy it with native corpus aggregate counts."})
        for segment in segments["segments"]:
            check("segment_links:" + segment["id"], segment["parentCourseUnitId"] in units
                  and set(segment["contentClusterIds"]) <= clusters
                  and set(segment["requiredConceptIds"]) <= concepts, segment["contentClusterIds"])
        segment_ids = {row["id"] for row in segments["segments"]}
        definitions = {row["assessmentItemId"]: row for row in productive["definitions"]}
        snippets = {row["id"] for row in productive["sourceSnippets"]}
        for row in productive["definitions"]:
            check("productive_draft_definition:" + row["assessmentItemId"], row["canDoSegmentId"] in segment_ids
                  and row["courseUnitId"] in units and set(row["conceptIds"]) <= concepts
                  and set(row.get("prerequisiteAssessmentItemIds", [])) <= set(definitions),
                  {"canDoSegmentId": row["canDoSegmentId"], "source_status": "draft; runtime closed"})
        project_steps = {row["id"]: {step["id"]: step for step in row["steps"]} for row in productive["projects"]}
        for project_id, steps in project_steps.items():
            for row in steps.values():
                check("productive_draft_step:" + project_id + ":" + row["id"],
                      set(row["snippetIds"]) <= snippets and set(row["prerequisiteStepIds"]) <= set(steps)
                      and set(row["assessmentItemIds"]) <= set(definitions), "draft; runtime closed")
        for index, row in enumerate(productive["bundles"]):
            check("productive_draft_bundle:" + str(index), row["canDoSegmentId"] in segment_ids
                  and row["stepId"] in project_steps.get(row["projectId"], {})
                  and set(row["assessmentItemIds"]) <= set(definitions), "draft; runtime closed")
        tts = self.tables["assets/data/tts_first_line_manifest.json"]
        scenario_map = {s["id"]: s for s in scenarios}
        for entry in tts["items"]:
            scenario = scenario_map.get(entry["scenarioId"])
            source = "assets/data/" + entry["sourceShard"]
            check("TTS_source:" + entry["scenarioId"], scenario is not None and
                  self.sources.get(source, {}).get("sha256") == entry["sourceSha256"], source)
            if entry["bundled"]:
                path = self.root / entry["bundledAssetPath"]
                check("TTS_bundle:" + entry["scenarioId"], path.is_file() and file_hash(path) == entry["bundledSha256"], entry["bundledAssetPath"])
        check("TTS_full_scenario_ID_coverage", {i["scenarioId"] for i in tts["items"]} == ids["scenario"], len(tts["items"]))
        # Resolve auditable identifiers for every record; unknown reference families stay explicit.
        candidates: dict[str, list[str]] = collections.defaultdict(list)
        for record in self.records:
            if record["source_id"].startswith(("assets/data/", "lib/")) and "preview" not in record["identity_role"] and record["identity_role"] not in {"canonical_content_reference_not_primary_library_identity", "scoped_assessment_requirement_reference_not_primary_catalog_identity"}:
                candidates[record["id"]].append(record["uid"])
        for record in self.records:
            for reference in record["references"]:
                raw_id = reference["id"]
                found = candidates.get(raw_id, [])
                if not found and ":" in raw_id and raw_id.split(":", 1)[0] in ids:
                    found = candidates.get(raw_id.split(":", 1)[1], [])
                reference["candidate_uids"] = found
                reference["resolution"] = "source_candidates; context must be validated by loader" if found else "not_a_catalog_id_or_external_or_unresolved"
        return {
            "course_units": len(units), "learning_phases": len(phases["phases"]),
            "phase_tasks": len(tasks), "phase_objectives": len(packets["objectives"]),
            "smalltalk_native_lessons": len(self.tables["assets/data/smalltalk_lessons.json"]["lessons"]),
            "smalltalk_phrases": len(smalltalk["phrases"]), "smalltalk_categories": len(smalltalk["categories"]),
            "smalltalk_context_cases": len(cases), "listening_native_lessons": len(self.tables["assets/data/listening_lessons.json"]["lessons"]),
            "scenarios": len(scenarios), "vocabulary_records": len(content["vocab"]),
            "grammar_records": len(content["grammar"]), "cloze_items": len(content["cloze"]),
            "sentence_items": len(content["satz"]),
            "vocabulary_packs": len(pack_ids), "can_do_segments": len(segments["segments"]),
            "canonical_content_clusters": len(clusters), "canonical_source_seeds": len(seeds),
        }

    def evidence(self, source: str, symbols: list[str] | None = None) -> dict[str, Any]:
        item = {"source_id": source, "exists": source in self.sources,
                "sha256": self.sources.get(source, {}).get("sha256")}
        if symbols:
            text = self.text.get(source, "")
            item["symbols"] = [{"name": symbol, "lines": [i + 1 for i, line in enumerate(text.splitlines()) if symbol in line]}
                               for symbol in symbols]
        return item

    def c_runtime_dependencies(self, sources: list[str]) -> list[dict[str, Any]]:
        """Follow current local imports to C components used by production sources.

        A gallery screenshot or a component existing on disk does not make it a
        production dependency. Keep each import edge and current component hash.
        """
        queue = list(sources)
        package_name = re.search(r"^name:\s*(\S+)", self.text.get("pubspec.yaml", ""), re.M)
        visited: set[str] = set()
        imported_by: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
        while queue:
            source = queue.pop()
            if source in visited or source not in self.text:
                continue
            visited.add(source)
            for match in re.finditer(r"^[ \t]*(?:import|export)\s+['\"]([^'\"]+)['\"]", self.text[source], re.M):
                path = match.group(1)
                if path.startswith("dart:"):
                    continue
                if path.startswith("package:"):
                    if not package_name or not path.startswith("package:" + package_name.group(1) + "/"):
                        continue
                    candidate = "lib/" + path.split("/", 1)[-1]
                else:
                    resolved = (self.root / source).parent.joinpath(path).resolve()
                    if not resolved.is_relative_to(self.root):
                        continue
                    candidate = resolved.relative_to(self.root).as_posix()
                if candidate not in self.text or not candidate.startswith("lib/"):
                    continue
                edge = {"source_id": source, "line": self.text[source].count("\n", 0, match.start()) + 1,
                        "import_expression": path}
                if edge not in imported_by[candidate]:
                    imported_by[candidate].append(edge)
                if candidate not in visited:
                    queue.append(candidate)
        return [{"source": self.evidence(source),
                 "declared_classes": re.findall(r"\bclass\s+([A-Za-z0-9_]+)", self.text[source]),
                 "reachable_import_edges": sorted(imported_by[source], key=lambda row: (row["source_id"], row["line"])),
                 "status": "current production import reachability; execution and visual approval are separate receipt states"}
                for source in sorted(visited)
                if "/c_gallery/" in source or Path(source).name.startswith("c_stage_")]

    def module_validation(self, identifier: str) -> dict[str, Any]:
        """Retain reported execution layers without deriving passes from source."""
        receipt = self.execution_evidence.get("receipt", {})
        reported = receipt.get("module_validation", {}) if isinstance(receipt, dict) else {}
        row = reported.get(identifier) if isinstance(reported, dict) else None
        if isinstance(reported, list):
            row = next((item for item in reported if isinstance(item, dict)
                        and item.get("module_id", item.get("id")) == identifier), None)
        row = row if isinstance(row, dict) else {}
        return {"source_observation": "current source/hash/import bindings recomputed by generator",
                "automation": row.get("automation", {"status": "not_reported_for_this_module"}),
                "rendered_visual": row.get("rendered_visual", {"status": "not_reported_for_this_module"}),
                "human_approval": row.get("human_approval", {"status": "not_inferred"}),
                "remaining": row.get("remaining", []), "owner_report": row,
                "evidence_boundary": "Owner-reported execution is distinct from generator source checks; no inferred cross-module pass or final user approval."}

    def routes_and_catalog(self) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
        main = self.text["lib/main.dart"]
        case_re = re.compile(r"^[ \t]*case\s+(['\"][^'\"]+['\"]|courseReassessmentRoute)\s*:", re.M)
        cases = list(case_re.finditer(main))
        routes = []
        for i, match in enumerate(cases):
            expression = match.group(1)
            path = "/course/reassessment" if expression == "courseReassessmentRoute" else expression[1:-1]
            end = cases[i + 1].start() if i + 1 < len(cases) else main.index("default:", match.end())
            body = main[match.end():end].strip()
            j = i
            while not body and j + 1 < len(cases):
                j += 1
                body = main[cases[j].end():cases[j + 1].start() if j + 1 < len(cases) else main.index("default:", cases[j].end())].strip()
            targets = sorted(set(re.findall(r"\b([A-Z][A-Za-z0-9]+(?:Screen|Hub|Shell))\s*\(", body)))
            routes.append({"path": path, "case_expression": expression,
                           "registration": self.evidence("lib/main.dart"),
                           "line": main.count("\n", 0, match.start()) + 1,
                           "target_classes": targets, "typed_arguments_and_dispatch": body,
                           "classification": "registered_source_route_not_click_QA",
                           "implementation_status": "source_present; automation/device not verified by audit"})
        catalog_source = "lib/data/sori_activity_catalog.dart"
        text = self.text[catalog_source]
        start = text.index("soriActivityCatalog =")
        entries = []
        for match in re.finditer(r"_entry\(", text[start:]):
            pos = start + match.start()
            block = balanced(text, text.index("(", pos))
            entries.append({"id": literal_field(block, "id"), "route": literal_field(block, "route"),
                            "de": literal_field(block, "de"), "en": literal_field(block, "en"),
                            "tab": (re.search(r"tab:\s*SoriStageTab\.(\w+)", block).group(1)),
                            "detail_route_aliases": re.findall(r"['\"](/[^'\"]+)['\"]", re.search(r"detailRouteAliases:\s*(?:const\s*)?(?:<[^>]+>\s*)?\[(.*?)\]", block, re.S).group(1)) if "detailRouteAliases:" in block else [],
                            "arguments_expression": re.search(r"arguments:\s*(.*)", block).group(1).strip() if "arguments:" in block else None,
                            "reward_contract_expression": block[block.index("reward:"):].split("\n  )", 1)[0] if "reward:" in block else None,
                            "owns_route": "ownsRoute: false" not in block,
                            "source": self.evidence(catalog_source),
                            "line": text.count("\n", 0, pos) + 1})
        return routes, entries

    def rebase(self, value: Any) -> Any:
        if isinstance(value, dict):
            return {k: self.rebase(v) for k, v in value.items()}
        if isinstance(value, list):
            return [self.rebase(v) for v in value]
        if isinstance(value, str):
            normalized = value.replace("\\", "/")
            marker = "/ko_lernen_app/"
            if marker in normalized and normalized.startswith("C:"):
                return (self.root / normalized.split(marker, 1)[1]).as_posix()
        return value

    def bindings(self, routes: list[dict[str, Any]], entries: list[dict[str, Any]]) -> dict[str, Any]:
        c_support_key = "handoff:c_reference/c-support-map.json"
        historical = json.loads(self.text[c_support_key]) if c_support_key in self.text else {"flows": []}
        activity_key = "handoff:c_reference/activity-flows.json"
        activities = json.loads(self.text[activity_key]).get("activities", []) if activity_key in self.text else []
        route_index = {r["path"]: r for r in routes}
        modules = []
        for identifier, spec in MODULE_DEFINITIONS.items():
            loaders, screens, paths, filters, args, states, save = spec
            present = [path for path in screens if path in self.text]
            c_markers = [path for path in present if "c_gallery" in self.text[path] or "CPaperPanel" in self.text[path]]
            modules.append({"id": identifier, "loader_evidence": [self.evidence(path) for path in loaders],
                            "screen_evidence": [self.evidence(path) for path in screens],
                            "filter_contract": filters, "typed_argument_contract": args,
                            "routes": [route_index.get(path, {"path": path, "classification": "missing_registration"}) for path in paths],
                            "required_states": states, "states_verification": "design/source contract; no UI execution in this generator",
                            "save_and_reward_contract": save,
                            "record_uids": [r["uid"] for r in self.records if identifier in r["module_binding_ids"]],
                            "c_source_markers": c_markers,
                            "c_runtime_component_evidence": self.c_runtime_dependencies(present),
                            "implementation_status": "C component references present in current source; executed coverage/approval remain receipt states" if c_markers else "existing current source; C execution/visual coverage remain receipt states",
                            "validation_layers": self.module_validation(identifier),
                            "automation_QA": "see validation_layers.automation; not_run_by_this_audit",
                            "device_QA": "see owner execution receipt; not_inferred_from_source",
                            "final_visual_approval": "see validation_layers.human_approval; not_inferred_from_source"})
        support_flows = []
        for flow in historical.get("flows", []):
            f = self.rebase(flow)
            source_files = []
            for value in flow.get("source_files", []):
                original = value.get("file", value.get("path", "")) if isinstance(value, dict) else value
                if not isinstance(original, str):
                    continue
                normalized = original.replace("\\", "/")
                relative = normalized.split("/ko_lernen_app/", 1)[-1]
                source_files.append(self.evidence(relative))
            f["current_source_evidence"] = source_files
            f["import_provenance"] = {"source_id": c_support_key, "source_sha256": self.sources.get(c_support_key, {}).get("sha256"),
                                       "status": "historical provenance from rejected atlas; not visual authority or runtime QA"}
            f["current_route_registration"] = [route_index.get(r.get("path") if isinstance(r, dict) else r,
                                              {"path": r, "classification": "not_registered"})
                                               for r in flow.get("native_named_routes", [])]
            f["native_backend_completion_verified"] = False
            f["source_trigger_coverage_verified"] = False
            if "reward" in f.get("flow_id", "") or "bojagi" in f.get("flow_id", ""):
                f["current_user_override"] = "Single item reveal; historical three-candidate selection is superseded, journal/idempotent claim retained."
            support_flows.append(f)
        aliases = {"/quick_onboarding": "/onboarding", "/character_selection": "/onboarding",
                   "/onboarding/start": "/onboarding", "/bookshelf": "/my_words",
                   "/wordbook/search": "/my_words", "/hard_words": "/my_words",
                   "/dancheong-share": "/dancheong-artwork"}
        for route in routes:
            if route["path"] in aliases:
                route["classification"] = "alias"
                route["canonical_route"] = aliases[route["path"]]
            if route["path"] in {"/vocab/legacy", "/onboarding/legacy-level"}:
                route["classification"] = "registered_legacy"
        module_index = {module["id"]: module for module in modules}
        for entry in entries:
            identifiers = ([entry["id"]] if entry["id"] in module_index else ["games"])
            if entry["id"] == "course":
                identifiers = ["course", "phases"]
            if entry["id"] == "custom_practice":
                identifiers = ["my_words", "games"]
            activity = next((a for a in activities if a["id"] == entry["id"]), None)
            evidence = []
            for source in activity.get("sourceFiles", []) if activity else []:
                normalized = source.replace("\\", "/")
                evidence.append(self.evidence(normalized.split("/ko_lernen_app/", 1)[-1]))
            entry["module_binding_ids"] = identifiers
            entry["current_route_registration"] = route_index.get(entry["route"])
            entry["required_module_states"] = {key: module_index[key]["required_states"] for key in identifiers}
            entry["current_source_evidence"] = evidence
            entry["historical_activity_contract"] = self.rebase(activity) if activity else None
            entry["historical_contract_status"] = "source/state reference only; not current visual authority or functioning UI proof"
            entry["save_and_reward_contracts"] = {key: module_index[key]["save_and_reward_contract"] for key in identifiers}
            entry["automation_QA"] = "not_run_by_this_audit"
            entry["module_validation_layers"] = {key: module_index[key]["validation_layers"] for key in identifiers}
            entry["device_QA"] = "not_run"
            entry["final_visual_approval"] = "not_inferred"
        return {
            "schema_version": SCHEMA, "workspace": self.root.as_posix(),
            "evidence_boundary": "Source registration/access/IDs are verified. None of these prove successful UI save, cloud sync, final approval, automated or device QA.",
            "production_roots": [{"tab": name, "route": "/", "source": self.evidence(source),
                                  "shell_dispatch": self.evidence("lib/screens/sori_stage/sori_stage_shell.dart", ["_select", "_open", "HomeNavigationArt." + name]),
                                  "navigation_art": self.evidence("lib/models/home_navigation_art.dart", [name]),
                                  "tab_identity": self.evidence("lib/models/sori_stage_progression.dart", ["SoriStageTab"]),
                                  "runtime_C_component_dependencies": self.c_runtime_dependencies([source, "lib/widgets/sori/adaptive_navigation.dart"]),
                                  "validation_layers": self.module_validation(name) if self.module_validation(name)["owner_report"] else self.module_validation("c_roots"),
                                  "tap_return_state_contract": "Shell destination selection, per-tab active flags and refresh generation; real route return refresh/focus. Source evidence does not certify click execution."} for name, source in
                                 [("today", "lib/screens/sori_stage/sori_stage_today_screen.dart"),
                                  ("learn", "lib/screens/sori_stage/sori_stage_catalog_screen.dart"),
                                  ("games", "lib/screens/sori_stage/sori_stage_catalog_screen.dart"),
                                  ("hanok", "lib/screens/sori_stage/sori_stage_hanok_screen.dart"),
                                  ("gye", "lib/screens/sori_stage/sori_stage_gye_screen.dart")]],
            "learn_structure": {"entry": ["foundation", "hangul", "pronunciation", "calligraphy"],
                                "entry_source": self.evidence("lib/widgets/sori/learning_entry_paths.dart"),
                                "comprehensive_course": ["course", "phases"],
                                "free_learning": [e["id"] for e in entries if e["tab"] == "learn" and e["id"] != "course"],
                                "readiness_policy": "Foundation four steps/twelve actual practice tasks retain per-account progress independently from CEFR placement and visits. Explicit Continue A1 is separate; no foundation course mastery or economy grant.",
                                "foundation_admission": {
                                    "production_source": self.evidence("lib/services/today_learning_snapshot.dart", ["_TodayReviewInput", "_loadReviewInput", "scheduledReviewCount", "today.reviewCount", "dueCount: today.words.length", "OnboardingLearningStart.shouldOfferHangul"]),
                                    "readiness_source": self.evidence("lib/features/onboarding_v2/onboarding_learning_start.dart", ["shouldOfferHangul", "continuedToA1", "course"]),
                                    "rule": "Fresh new daily cards, including the default ten, must not hide Foundation. Only the private production admission input separates scheduled review evidence; shared dueCount remains new+review and public reader-record/test contracts remain intact.",
                                    "verification": "Current source rule; production-purpose regression execution is reported in final owner receipt, never inferred from reader fixtures or source counts."},
                                "foundation_coverage": {"sound_samples": ["ㄱ", "ㄴ", "ㅏ", "ㅣ"],
                                    "syllable_samples": ["가", "나", "한"], "trace_samples": ["ㄱ", "ㅏ"],
                                    "first_word_sources": "Hangul syllables 가/나 existing exampleWord(가방/나무) and onboarding A1 Korean greeting copy",
                                    "source": self.evidence("lib/screens/foundation_practice_screen.dart"),
                                    "limits": "Twelve starter tasks are not full-alphabet, compound-vowel/double-consonant, batchim or sentence-decoding mastery. Existing Hangul cards/writing, pronunciation and daily-character tools remain available; completion must not be labelled a full literacy assessment."},
                                "catalog_policy": "Foundation is a separate entry path. The existing course + twelve tool entries remain thirteen; supplemental paths do not overwrite this catalog.",
                                "foundation_subroutes": [{"path": "/foundation/" + step,
                                    "classification": "direct_MaterialPageRoute_with_RouteSettings; not a named main route",
                                    "source": self.evidence("lib/screens/foundation_learning_screen.dart"),
                                    "target": "FoundationPracticeScreen", "argument": "FoundationStep." + member,
                                    "implementation_status": "source_present; automation/device not verified by audit"}
                                    for member, step in (("sounds", "sounds"), ("syllables", "syllables"),
                                                        ("tracing", "tracing"), ("firstWords", "first_words"))]},
            "catalog_entries": entries, "modules": modules, "registered_routes": routes,
            "support_flows": support_flows,
            "historical_activity_specs": self.rebase(activities),
            "historical_spec_status": "contract/reference only; source stamps above are refreshed, historical UI completion flags are not accepted",
            "legacy_surfaces": [
                {"source": "lib/screens/listening_screen.dart", "status": "legacy_preserved", "replacement": "ContentLearningHub/listening"},
                {"source": "lib/screens/listening_shelf_screen.dart", "status": "legacy_preserved", "replacement": "ContentLearningHub/listening"},
                {"source": "lib/screens/listening_play_screen.dart", "status": "legacy_preserved", "replacement": "ContentLearningHub/listening"},
                {"source": "lib/screens/ildu_world_screen.dart", "status": "dormant_preserved_not_registered"},
                {"source": "tool/concept_c_preview.dart", "status": "visual_preview_not_production"},
                {"source": "lib/screens/bojagi_screen.dart", "status": "source_present; candidate selection superseded by latest user-approved single-item flow"},
            ],
            "revision_history": self.revision_history,
            "legacy_reward_test_backup": self.legacy_reward_test_backup,
            "execution_evidence": self.execution_evidence,
            "productive_authoring_status": self.productive_draft_status,
            "reward_audio": {"runtime_policy": "mute without a provided approved sound file; no phantom asset lookup",
                             "handoff_source": self.evidence("handoff:chest_handoff/HANDOFF.md", ["오디오는 preview에서 꺼져 있다"]),
                             "sound_asset_status": "handoff code SFX paths do not prove files or licenses; audio file/device sound QA remains a separate gap",
                             "device_sound_QA": "not_verified"},
            "root_data_and_receipt_contract": {
                "data_gate": "Use current account data only when snapshot is done and has no error; loading/error must not expose cached previous-account values. Invalidate active and hidden IndexedStack tabs on account change.",
                "account_source_evidence": [self.evidence("lib/screens/sori_stage/sori_stage_shell.dart", ["_accountChanged", "cloudWriteSessionController.changes", "IndexedStack"]),
                    self.evidence("lib/services/catalog_history_lease.dart", ["capture", "isCurrent"])] +
                    [self.evidence(path, ["ConnectionState.done", "hasError", "_accountChanged", "didUpdateWidget"])
                     for path in MODULE_DEFINITIONS["c_roots"][1][1:]],
                "pending_receipt_evidence": [self.evidence("lib/models/sori_stage_progression.dart", ["hasPendingDecorationReceipt", "pendingBojagiCount"]),
                    self.evidence("lib/services/sori_stage_progression_service.dart", ["CatalogHistoryLease.capture", "assertCurrentRead", "readDecorationRewardReceiptRawJsonStrict", "DecorationRewardReceiptHistory.decode"]),
                    self.evidence("lib/services/storage_service.dart", ["readDecorationRewardReceiptRawJsonStrict"])],
                "resume_routes": [{"route": "/bojagi", "from": self.evidence(path, ["hasPendingDecorationReceipt", "'/bojagi'", "openBojagi"])}
                    for path in ("lib/screens/sori_stage/sori_stage_today_screen.dart", "lib/screens/sori_stage/sori_stage_hanok_screen.dart")],
                "resume_save_reward_contract": "An opened claimed item awaiting its final CTA remains discoverable independently from unopened box count. Resume the persisted same receipt/item without another claim, XP, gift or pool change.",
                "regression_requirements": ["A-to-B account change while current tab pending", "A-to-B account change in hidden tabs", "current account load failure does not show previous data", "reload/resume opened unacknowledged receipt", "return to actual AppShell with same Foundation state", "one Smalltalk title announcement with preserved typed route and no XP"],
                "verification": "Current source/hash/line evidence only; automation/render/approval are retained per-module owner receipt states."},
            "canonical_scenario_lineage": [{k: v for k, v in entry.items() if k != "original_record_utf8"}
                                           for entry in self.scenario_lineage],
            "review_entry_points": [{"source": self.evidence("tool/c_content_flow_preview.dart"),
                                     "status": "actual KoLernenApp route switch with isolated local Storage origin; Firebase startup omitted. Source seam is not build/render/UI/device QA proof."},
                                    {"source": self.evidence("tool/concept_c_preview.dart"),
                                     "status": "C style preview with local sample subactivities; production save/route success not certified"}],
            "reusable_components": [{"source": self.evidence(source),
                 "declared_classes": re.findall(r"\bclass\s+([A-Za-z0-9_]+)", self.text.get(source, "")),
                 "module_binding_ids": modules,
                 "current_import_consumers": [{"source_id": key, "line": i + 1}
                    for key, body in self.text.items() if key.startswith("lib/") and key != source
                    for i, line in enumerate(body.splitlines()) if line.lstrip().startswith("import ") and Path(source).name in line],
                 "status": "source component/consumer evidence; visual approval and executed state coverage not inferred"}
                for source, modules in (
                    ("lib/widgets/sori/c_gallery/c_materials.dart", ["c_roots", "foundation"]),
                    ("lib/widgets/sori/c_gallery/c_palette.dart", ["c_roots", "foundation"]),
                    ("lib/widgets/sori/c_gallery/c_objects.dart", ["c_roots"]),
                    ("lib/screens/sori_stage/c_stage_chrome.dart", ["c_roots"]),
                    ("lib/widgets/sori/adaptive_navigation.dart", ["c_roots"]),
                    ("lib/widgets/sori/learning_entry_paths.dart", ["c_roots", "foundation"]),
                    ("lib/widgets/practice_scholar_art.dart", ["talsunbi_context"]),
                    ("lib/widgets/practice_scholar_explanation.dart", ["talsunbi_context"]),
                    ("lib/widgets/practice_dokkaebi_canvas.dart", ["games"]),
                    ("lib/widgets/practice_dokkaebi_help.dart", ["games"]),
                    ("lib/widgets/sori/dokkaebi_flame_frame.dart", ["onboarding"]),
                    ("lib/widgets/sori/dokkaebi_intro.dart", ["onboarding"]),
                    ("lib/widgets/sori/bojagi_reveal.dart", ["rewards"]),
                    ("lib/widgets/sori/reward_chest/reward_chest_screen.dart", ["rewards"]),
                    ("lib/widgets/sori/reward_chest/reward_cultural_story.dart", ["rewards"]))],
        }

    def asset_reference_id(self, source: str, relative: str) -> str:
        """Resolve local handoff references without borrowing a runtime asset.

        Flutter asset keys stay relative to the application root. A handoff HTML
        or manifest has its own file/package base, and same-named images in two
        packages must retain separate IDs even if a workspace file also exists.
        Resolution is provenance only: it does not promote an external asset.
        """
        if not source.startswith("handoff:") or relative.startswith("handoff:"):
            return relative
        source_path = self.paths.get(source)
        if source_path is None:
            return relative
        package = source[len("handoff:"):].split("/", 1)[0]
        bases = [(name, (self.artifacts / folder).resolve())
                 for name, folder in ARTIFACT_FOLDERS.items()]
        candidates = [source_path.parent / relative]
        if package in ARTIFACT_FOLDERS:
            candidates.append(self.artifacts / ARTIFACT_FOLDERS[package] / relative)
        candidates.append(self.root / relative)
        for candidate in candidates:
            if not candidate.is_file():
                continue
            target = candidate.resolve()
            if target.is_relative_to(self.root):
                return target.relative_to(self.root).as_posix()
            for name, base in bases:
                if target.is_relative_to(base):
                    return "handoff:" + name + "/" + target.relative_to(base).as_posix()
        return relative

    def collect_assets(self, bindings: dict[str, Any]) -> None:
        literals: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
        directories: dict[str, list[str]] = collections.defaultdict(list)
        for source, text in self.text.items():
            for match in ASSET_RE.finditer(text):
                value = match.group(0)
                # A dynamic expression is preserved separately; it is not a missing exact file.
                if "$" in value or "{" in value:
                    continue
                line_no = text.count("\n", 0, match.start()) + 1
                line = text.splitlines()[line_no - 1].lstrip()
                comment = source.endswith((".dart", ".js")) and line.startswith(("//", "*", "/*"))
                pattern = any(token in value for token in ("*", "[", "]", "\\", "^"))
                asset_id = self.asset_reference_id(source, value)
                literals[asset_id].append({"source_id": source, "line": line_no,
                                        "declared_asset": value,
                                        "resolution": "source_or_package_relative_handoff" if asset_id != value else "application_key_or_unresolved_reference",
                                        "reference_kind": "source_comment" if comment else "dynamic_pattern" if pattern else "literal_in_source"})
            for directory in DIRECTORY_RE.findall(text):
                directories[directory].append(source)
            # Constant roots omit a trailing slash (PackArtworkCatalog), while
            # scene/listening selectors interpolate IDs after a literal folder.
            # These are source families only, never individual rendered assets.
            for directory in QUOTED_ASSET_DIRECTORY_RE.findall(text) + INTERPOLATED_ASSET_DIRECTORY_RE.findall(text):
                if (self.root / directory).is_dir():
                    directories[directory.rstrip("/") + "/"].append(source)
        declarations = []
        for line in self.text["pubspec.yaml"].splitlines():
            clean = line.split("#", 1)[0]
            match = re.match(r"\s*(?:-\s+|(?:-\s+)?asset:\s+)([^\s]+)\s*$", clean)
            if match and (self.root / match.group(1)).exists():
                declarations.append(match.group(1))
        def packaged(relative: str) -> bool:
            return any(relative == d or (d.endswith("/") and str(Path(relative).parent).replace("\\", "/") + "/" == d)
                       for d in declarations)
        module_sources = {m["id"]: {e["source_id"] for e in m["loader_evidence"] + m["screen_evidence"]}
                          for m in bindings["modules"]}
        helper_modules = {**DART_TABLE_MODULES,
            "lib/models/scenario.dart": ["scenarios", "listening"],
            "lib/services/scene_asset_resolver.dart": ["scenarios", "listening"],
            "lib/widgets/sori/pack_card.dart": ["vocab_packs"],
            "lib/features/content_learning/content_learning_widgets.dart": ["smalltalk", "listening"]}
        for source, identifiers in helper_modules.items():
            for identifier in identifiers:
                module_sources[identifier].add(source)
        for component in bindings["reusable_components"]:
            for identifier in component["module_binding_ids"]:
                module_sources[identifier].add(component["source"]["source_id"])
        scans = [("workspace", self.root / folder) for folder in ("assets", "assets_unused", "fonts", "shaders", "docs/assets") if (self.root / folder).is_dir()]
        scans += [(package, self.artifacts / folder) for package, folder in ARTIFACT_FOLDERS.items() if (self.artifacts / folder).is_dir()]
        for scope, base in scans:
            for path in sorted(base.rglob("*")):
                if not path.is_file():
                    continue
                if scope == "workspace" and base == self.root / "docs/assets" and path.suffix.lower() not in MEDIA_SUFFIXES:
                    continue
                if scope != "workspace" and path.suffix.lower() not in MEDIA_SUFFIXES:
                    continue
                relative = path.relative_to(self.root).as_posix() if scope == "workspace" else path.relative_to(base).as_posix()
                key = relative if scope == "workspace" else "handoff:" + scope + "/" + relative
                refs = literals.get(key, [])
                dynamic_refs = sorted({s for directory, consumers in directories.items()
                                       if relative.startswith(directory) for s in consumers}) if scope == "workspace" else []
                runtime_refs = [r for r in refs if r["source_id"].startswith("lib/") and r["reference_kind"] == "literal_in_source"]
                runtime_dynamic_refs = [s for s in dynamic_refs if s.startswith("lib/")]
                preview_refs = [r for r in refs if r["source_id"].startswith("tool/")]
                if "pending_review" in relative:
                    status = "pending_review_preserved_not_live"
                elif scope == "intro_rejected_pack" and relative.startswith(("derived/", "scenes/")):
                    status = "rejected_reconstruction_preserved_not_live"
                elif "rejected" in relative.lower():
                    status = "rejected_reference_preserved_not_live"
                elif scope != "workspace":
                    status = "external_handoff_reference_not_runtime_proof"
                elif relative.startswith("assets_unused/"):
                    status = "unused_or_legacy_preserved_not_live"
                elif packaged(relative) and runtime_refs:
                    status = "packaged_and_literal_source_referenced_not_UI_QA"
                elif packaged(relative) and runtime_dynamic_refs:
                    status = "packaged_dynamic_source_family_not_individual_click_QA"
                elif packaged(relative) and preview_refs:
                    status = "packaged_visual_preview_reference_not_production_proof"
                elif packaged(relative):
                    status = "packaged_without_detected_literal_or_directory_consumer"
                else:
                    status = "unpackaged_preserved; runtime_use_unproven"
                consumer_set = {r["source_id"] for r in refs} | set(dynamic_refs)
                modules = sorted(m for m, paths in module_sources.items() if paths & consumer_set)
                item = {"id": key, "path": path.as_posix(), "bytes": path.stat().st_size,
                        "sha256": file_hash(path), "scope": scope, "status": status,
                        "packaged": packaged(relative) if scope == "workspace" else False,
                        "literal_consumers": refs, "dynamic_family_consumers": dynamic_refs,
                        "module_binding_ids": modules, "approval": "not_inferred_from_filename_or_packaging",
                        "device_QA": "not_verified"}
                self.media[key] = item
        # Every literal that cannot resolve is kept with source/line, rather than dropped.
        for relative, refs in sorted(literals.items()):
            if relative not in self.media and relative not in self.sources and not (self.root / relative).is_file():
                runtime = [r for r in refs if r["source_id"].startswith("lib/") and r["reference_kind"] == "literal_in_source"]
                self.issue("unresolved_asset_literal", {"asset": relative, "consumers": refs,
                                                        "current_runtime_source_references": len(runtime),
                                                        "action": "restore the declared original source asset or correct the current runtime reference" if runtime else
                                                                  "retain historical/reference provenance; inspect before any deliberate promotion"},
                           "error" if runtime else "gap")
        # Attach record -> assets -> actual source consumers, with explicit absence.
        for record in self.records:
            record["asset_paths"] = sorted({self.asset_reference_id(record["source_id"], value)
                                             for value in record["asset_paths"]})
            record["asset_bindings"] = [{"id": value, "exists": value in self.media or value in self.sources,
                                         "status": self.media[value]["status"] if value in self.media else
                                                   "source_table_or_document_reference_not_media" if value in self.sources else "not_present_or_dynamic_reference"}
                                        for value in record["asset_paths"]]
            for asset_path in record["asset_paths"]:
                if asset_path in self.media:
                    asset = self.media[asset_path]
                    asset.setdefault("record_uids", []).append(record["uid"])
                    asset["module_binding_ids"] = sorted(set(asset["module_binding_ids"]) | set(record["module_binding_ids"]))
        for module in bindings["modules"]:
            module["asset_ids"] = [key for key, asset in self.media.items() if module["id"] in asset["module_binding_ids"]]
        for entry in bindings["catalog_entries"]:
            bound = set(entry["module_binding_ids"])
            entry_sources = {e["source_id"] for e in entry["current_source_evidence"]}
            entry["asset_ids"] = [key for key, asset in self.media.items()
                                  if bound & set(asset["module_binding_ids"])
                                  or entry_sources & {r["source_id"] for r in asset["literal_consumers"]}]
        self.verify_asset_manifests()

    def verify_asset_manifests(self) -> None:
        # Explicit approved source/destination copies and exact extraction status.
        for key in ("handoff:pr446-import-receipt", "handoff:approved-media-import"):
            if key not in self.text:
                continue
            receipt = json.loads(self.text[key])
            rows = receipt["files"] if isinstance(receipt, dict) else receipt
            for row in rows:
                name = row["path"]
                target = self.root / name
                expected = row["sha256"]
                if target.suffix.lower() in MEDIA_SUFFIXES and name.startswith("assets/"):
                    passed = target.is_file() and file_hash(target) == expected
                    self.checks.append({"id": "import_media_bytes:" + key + ":" + name,
                                        "passed": passed, "detail": {"asset": name, "receipt": key, "sha256": expected}})
                    if not passed:
                        self.issue("imported_original_media_changed_or_missing", {"asset": name, "receipt": key}, "error")
                    if name in self.media:
                        self.media[name].setdefault("import_receipt_ids", []).append(key)
                else:
                    if name not in self.sources and target.is_file():
                        self.register(target, name, "imported_runtime_or_shader_source; current hash separate from import receipt")
                    self.sources.get(name, {}).setdefault("import_lineage", []).append({"receipt_id": key,
                        "import_sha256": expected, "source_byte_equal_now": target.is_file() and file_hash(target) == expected,
                        "status": "mutable code/test/config import provenance; current source hash is stored separately"})
        source = "handoff:c_reference/native-c-assets.json"
        if source in self.text:
            for i, item in enumerate(json.loads(self.text[source])):
                expected = item.get("sha256")
                for field in ("source", "destination"):
                    name = item.get(field)
                    if not name:
                        continue
                    path = Path(name)
                    exists = path.is_file()
                    actual = file_hash(path) if exists else None
                    check = {"id": "native_asset_copy:" + str(i) + ":" + field,
                             "passed": exists and actual == expected, "detail": {"path": path.as_posix(), "expected": expected, "actual": actual,
                                                                                 "role": item.get("role"), "manifest_source": source}}
                    self.checks.append(check)
                    if not check["passed"]:
                        self.issue("external_source_copy_not_verified", check["detail"])
        exact = "handoff:intro_exact/manifest.json"
        if exact in self.text:
            value = json.loads(self.text[exact])
            self.exact_intro_manifest = {"source_id": exact, "sha256": self.sources[exact]["sha256"],
                                         "baked_text_entries": []}
            def walk(item: Any, ptr: str) -> None:
                if isinstance(item, dict):
                    if item.get("bakedUiText") is True:
                        self.exact_intro_manifest["baked_text_entries"].append({"pointer": ptr, "entry": item})
                    for k, v in item.items():
                        walk(v, ptr + "/" + pointer_token(k))
                elif isinstance(item, list):
                    for i, v in enumerate(item):
                        walk(v, ptr + "/" + str(i))
            walk(value, "")

    def build(self) -> tuple[dict[str, Any], dict[str, Any]]:
        self.collect_sources()
        self.collect_records()
        counts = self.validate_content()
        routes, entries = self.routes_and_catalog()
        tab_source = "lib/models/sori_stage_progression.dart"
        tab_match = re.search(r"enum\s+SoriStageTab\s*\{([^}]+)\}", self.text[tab_source])
        tab_ids = [part.strip() for part in tab_match.group(1).split(",") if part.strip()] if tab_match else []
        root_tabs = ["today", "learn", "games", "hanok", "gye"]
        self.checks.append({"id": "production_tab_IDs", "passed": tab_ids == root_tabs,
                            "detail": {"source": tab_source, "ids": tab_ids}})
        if tab_ids != root_tabs:
            self.issue("production_tab_IDs_changed", tab_ids, "error")
        counts.update(learn_entries=sum(e["tab"] == "learn" for e in entries),
                      game_entries=sum(e["tab"] == "games" for e in entries), production_tabs=len(tab_ids),
                      foundation_steps=sum(self.raw_records[r["uid"]].get("enum") == "FoundationStep"
                                           for r in self.records if r["source_id"] == "lib/models/foundation_progress.dart"),
                      foundation_tasks=sum(self.raw_records[r["uid"]].get("enum") == "FoundationTask"
                                           for r in self.records if r["source_id"] == "lib/models/foundation_progress.dart"))
        for key, expected in EXPECTED.items():
            passed = counts.get(key) == expected
            self.checks.append({"id": "approved_scope_count:" + key, "passed": passed,
                                "detail": {"expected": expected, "actual": counts.get(key)}})
            if not passed:
                self.issue("approved_scope_count_changed", {"key": key, "expected": expected, "actual": counts.get(key)}, "error")
        bindings = self.bindings(routes, entries)
        self.collect_assets(bindings)
        for module in bindings["modules"]:
            for evidence in module["loader_evidence"] + module["screen_evidence"]:
                if not evidence["exists"]:
                    self.issue("binding_source_absent", {"module": module["id"], "source": evidence["source_id"]})
        for entry in entries:
            if not any(r["path"] == entry["route"] for r in routes):
                self.issue("catalog_route_absent", entry["id"], "error")
        uids = [r["uid"] for r in self.records]
        if len(uids) != len(set(uids)):
            self.issue("duplicate_ledger_uid", [k for k, n in collections.Counter(uids).items() if n > 1], "error")
        # Files can change while parallel owners are implementing. Report that honestly.
        for key, path in self.paths.items():
            if file_hash(path) != self.sources[key]["sha256"]:
                self.issue("source_changed_during_audit_regenerate", key, "error")
        if file_hash(Path(__file__)) != self.generator_sha256:
            self.issue("generator_changed_during_audit_regenerate", Path(__file__).as_posix(), "error")
        scopes = collections.Counter(a["status"] for a in self.media.values())
        ledger = {
            "schema_version": SCHEMA, "workspace": self.root.as_posix(),
            "git_head": git(self.root, "rev-parse", "HEAD"), "origin_main_local_ref": git(self.root, "rev-parse", "origin/main"),
            "generator_sha256": self.generator_sha256,
            "scope": {"data_roots": ["assets/data", "docs/data", "docs/assets", "tools/content_factory (authoring/review/history only)"],
                      "asset_roots": ["assets", "assets_unused", "fonts", "shaders", "docs/assets (media only)"],
                      "external_packages": ARTIFACT_FOLDERS,
                      "asset_root": self.artifacts.as_posix(),
                      "table_enumeration": "All authored nested IDs plus top table rows/natural word keys. JSON pointer UID identifies scoped IDs; record hash binds every row. Not every scalar is a separate learning activity.",
                      "runtime_user_data": "not_read; private account/history/custom packs remain runtime projections",
                      "dynamic_assets": "directory family consumers captured; computed per-record runtime availability not proven"},
            "counts": counts, "record_count": len(self.records), "asset_file_count": len(self.media),
            "asset_status_counts": dict(sorted(scopes.items())),
            "record_defaults": {
                "source_hash": "sources[record.source_id].sha256 is the exact source-file/blob hash; record_sha256 uses sorted compact UTF-8 JSON",
                "missing_revision": "revision:null means no authored revision; source and record hash retain identity; never synthesize revision1",
                "empty_optional_fields": "Absent parent_uid/level/module_binding_ids/references/asset_ids are null/empty. Their prior repeated empty values contain no additional evidence.",
                "access": "module_binding_ids refer to screen-bindings modules for exact loader/filter/typed arguments/states/save/reward. No binding means authoring/review/reference only; source scope and identity_role retain preview/archive distinctions.",
                "reference_resolution": "candidate_uids are current-source ID candidates, requiring loader context validation. An absent list means non-catalog/external/unresolved, never automatic satisfaction by authoring/archive IDs.",
                "asset_resolution": "asset_ids resolve to the assets ID map containing hash/status/source consumers. A missing ID in that map remains absent/unresolved; source presence does not imply UI/approval."},
            "sources": {key: {k: v for k, v in value.items() if k != "id"} for key, value in self.sources.items()},
            "records": [compact_record(record) for record in self.records],
            "assets": {key: {k: v for k, v in value.items() if k != "id"} for key, value in self.media.items()},
            "revision_history": self.revision_history,
            "canonical_scenario_lineage": [{k: v for k, v in entry.items() if k != "original_record_utf8"}
                                           for entry in self.scenario_lineage],
            "legacy_reward_test_backup": self.legacy_reward_test_backup,
            "execution_evidence": self.execution_evidence,
            "productive_authoring_status": self.productive_draft_status,
            "intro_exact_baked_text": getattr(self, "exact_intro_manifest", None),
            "validation": {"status": "source_integrity_passed_with_declared_gaps" if not any(i["severity"] == "error" for i in self.issues) else "source_integrity_failed",
                           "checks": self.checks, "issues": self.issues,
                           "functioning_UI": "not_certified_by_generator; owner-reported per-module evidence is separate", "unit_test_execution": "not_run_by_generator; test source existence is separate",
                           "build": "not_run_by_generator", "rendered_visual_QA": "not_run_by_generator",
                           "automation_QA": "not_run_by_generator", "device_QA": "not_run_by_generator; see owner receipt", "final_approval": "not_inferred"},
        }
        bindings["ledger_source_fingerprint"] = digest([{k: s[k] for k in ("id", "sha256")} for s in self.sources.values()])
        bindings["validation_issues"] = self.issues
        return ledger, bindings


def markdown(ledger: dict[str, Any], bindings: dict[str, Any]) -> dict[str, str]:
    def status(value: Any) -> str:
        if isinstance(value, dict):
            value = value.get("status", "reported details; see JSON")
        value = str(value)
        return {"not_reported_for_this_module": "module별 보고 없음", "not_inferred": "최종 승인 추론 안 함"}.get(value, value).replace("|", "\\|").replace("\n", " ")

    def validation_row(module: dict[str, Any]) -> str:
        layers = module["validation_layers"]
        return (f"| {module['id']} | 소스/hash 연결, C refs {len(module['c_source_markers'])} | "
                + " | ".join(status(layers[key]) for key in ("automation", "rendered_visual", "human_approval")) + " |")

    counts = ledger["counts"]
    sources = collections.Counter(r["source_id"] for r in ledger["records"])
    content = ["# C 콘텐츠 원장", "", "이 원장은 현재 파일을 읽어 생성한 소스 감사입니다. 실제 학습 성공·저장·동기화·최종 승인·기기 QA를 증명하지 않습니다.", "",
               f"현재 runtime 학습 범위: **{counts['course_units']}코스 유닛 / {counts['learning_phases']}phase / {counts['phase_tasks']}task**, Lernen **{counts['learn_entries']}개**, Spiele **{counts['game_entries']}개**, Small Talk **{counts['smalltalk_native_lessons']} native lesson**, 듣기 **{counts['listening_native_lessons']} native lesson / {counts['scenarios']}시나리오**입니다.", "",
               "확장 원장의 authoring/review/archive 행 수는 라이브 수업 수와 별개입니다. 이 자료를 라이브 runtime 선택으로 승격하지 않습니다.", "",
               f"- 작업 공간: `{ledger['workspace']}`", f"- HEAD: `{ledger['git_head']}`", f"- 로컬 origin/main ref: `{ledger['origin_main_local_ref']}` (원격 조회 아님)",
               f"- ID/행 원장: {ledger['record_count']:,}개. 에셋 파일 원장: {ledger['asset_file_count']:,}개.",
               "- 모든 항목은 source ID/JSON pointer 또는 CSV 행, 파일 SHA-256, record SHA-256, revision, module binding, 참조 ID와 에셋 연결을 가집니다.",
               "- schema2의 sources/assets는 ID별 한 번만 저장합니다. 개별 record는 source_id·record_sha256·revision·module/ref/asset IDs를 참조하며 생략된 빈/default 필드는 record_defaults에서 정의합니다.",
               "- revision이 없는 소스에 임의 revision1을 만들지 않습니다. 파생 행·자연키·참조 ID는 authored ID와 구분합니다.", "",
               "| 소스 범위 | 현재 수 |", "|---|---:|"]
    content += [f"| {k} | {v:,} |" for k, v in counts.items()]
    content += ["", "48유닛/30phase/902task의 총합만 비교하지 않습니다. 각 유닛 checkpoint/graph link, 각 phase taskIds, 각 task hash·prerequisite, 각 native lesson contentIds·question sourceIds를 검사합니다.",
                "", "| 표/소스 | 개별 원장 행 |", "|---|---:|"]
    content += [f"| `{key}` | {value:,} |" for key, value in sorted(sources.items())]
    content += ["", "| 에셋 상태 | 파일 수 |", "|---|---:|"]
    content += [f"| {key} | {value:,} |" for key, value in ledger["asset_status_counts"].items()]
    content += ["", "`assets_unused`·pending·거절된 intro 재구성본·외부 handoff 자료는 지우지 않고 해시와 상태로 기록합니다. 번들/코드 참조는 인간 승인이나 실제 화면 노출 증거가 아닙니다.",
                "", "tools/content_factory의 authoring/review/과거 원장·원문도 개별 ID/행과 해시로 기록합니다. 이 자료의 승인/초안 상태와 current runtime loader 상태를 구분하며 과거·초안 행을 라이브 수업 수에 합산하지 않습니다.",
                "", "원본이 없는 외부 참조와 계산된 에셋 경로는 validation issues 및 dynamic_family_consumers에 남습니다. 앱의 사용자 저장 팩·계정 기록은 읽지 않습니다.",
                "", "`invite_friend` 현재 revision2와 기준 커밋a1d798bd의 revision1을 각각 원장에 남깁니다. 원본 record bytes도 lineage-records.json에 보존하고 HEAD가 앞으로 이동해도 기준 revision1을 없애지 않습니다. 이전 저장 이력의 revision을 새 revision으로 덮어쓰지 않습니다.",
                "", "`lost_phone`·`bank_account`는 ca00acad2 canonical corpus 승격 전의 실제 Git 원본 record bytes를 lineage-records.json에 보존합니다. 현재 186개 라이브 시나리오에 합산하지 않으며 소스/원본 byte span/원본·parsed hash/현재 변형을 구분합니다.",
                "", "재생성: `python -X utf8 tool/content_screen_audit.py build`", "", "무변경 검증: `python -X utf8 tool/content_screen_audit.py check`", "", "부정 사례 검증: `python -X utf8 tool/content_screen_audit.py self-test`", ""]
    screen = ["# C 화면 바인딩", "", "소스 등록/필터/typed arguments/상태/저장/보상/에셋/지원 경로를 연결한 원장입니다. 기존 atlas 기록은 경로·상태의 과거 근거로만 보존하고 C 시각 권위나 현재 QA 증거로 사용하지 않습니다.", "",
              "Lernen은 입문 + 종합코스 + 자유학습입니다. 한글 읽기 준비도는 CEFR A1과 방문 이력에서 분리합니다. 3개 탐색 영역을 의무적인 순서로 진행하게 만들지 않습니다.",
              "", "Small Talk 첫 경로는 209 native lesson/590 phrase/24category입니다. TalSunbi 10case는 별도 보조 연습이며 실제 저장 뒤 사랑방 기록으로 연결합니다. 일반 진입과 CoursePracticeContext 진입을 합치지 않습니다.",
              "", "보상은 개봉 한 번 → 단일 itemAsset 등장/확대 → 설명·실제 저장 XP·CTA → 문화 이야기입니다. 최대3후보 선택 UI 보존 문구는 최신 사용자 지시로 대체됐습니다. claim journal/queue/중복 지급 방지는 유지합니다.", "",
              "| module | 경로 | 소스 관찰 | 자동검사 | 렌더 증거 | 인간 승인 |", "|---|---|---|---|---|---|"]
    screen += [validation_row(m).replace(f"| {m['id']} |", f"| {m['id']} | {' / '.join('`'+r['path']+'`' for r in m['routes'])} |", 1) for m in bindings["modules"]]
    screen += ["", "자동검사·렌더·인간 승인 열은 verification-status.json의 module_validation에 명시된 결과만 표시합니다. source/hash/C component 참조는 매번 재계산하며, 명시되지 않은 module의 QA 결과를 다른 module 검사에서 추론하지 않습니다.", ""]
    screen += ["", "## 입문 범위와 게임별 유지 계약", "",
               "실제 shell의 active/hidden 탭은 계정 변경 시 진행·이력·focus를 무효화하고 done&&!error 상태에서만 현재 데이터를 표시해야 합니다. A→B pending/error 회귀 검사 상태는 실행 receipt에 따로 보존합니다.", "",
               "hasPendingDecorationReceipt는 미개봉 상자 수와 별개입니다. 개봉 후 마지막 CTA를 확인하지 않은 실제 item은 Today/Hanok→/bojagi에서 같은 저장 receipt로 재개하고 추가 아이템·XP·pool 변경을 만들지 않습니다. 관련 strict/native 저장 읽기·계정 lease·모델·화면 source 줄과 해시는 root_data_and_receipt_contract에 있습니다.", "",
               "Foundation은 소리ㄱ·ㄴ·ㅏ·ㅣ, 조합가·나·한, 획ㄱ·ㅏ, 기존가방·나무·첫 인사까지의4단계/12과제입니다. 전체 자모·쌍자음·복합모음·받침·문장 독해를 모두 평가한 것이 아닙니다. 기존 Hangul 카드/쓰기·발음·오늘의 글자 경로를 유지합니다. 실제 행동+사용자 확인이 과제 진행이며, 전체 한글 읽기 인증으로 표시하지 않습니다.", "",
               "Today의 새 일일 카드10개는 기존 학습 증거가 아닙니다. 공개 dueCount=new+review 계약을 유지하고, 입문 admission에만 private scheduledReviewCount=today.reviewCount를 사용합니다. 실제 예약 복습/명시적 A1 계속/코스 증거와 새 과제 배정을 구분합니다.", "",
               "| 게임 | 유지할 기존 mechanics/state |", "|---|---|"]
    for entry in bindings["catalog_entries"]:
        if entry["tab"] != "games":
            continue
        activity = entry["historical_activity_contract"] or {}
        actions = [row["action"] for row in activity.get("screens", []) if row.get("stage") in {"play", "learning"} and "action" in row]
        screen.append(f"| {entry['id']} | " + " / ".join(actions).replace("|", "\\|") + " |")
    screen += ["", "위 동작 계약의 원문·불가/오류 상태·저장/보상 규칙은 각 catalog entry의 historical_activity_contract에 보존되어 있습니다. 현재 source 파일·route dispatch를 별도로 해시 검증하며 과거 samples를 현재 라이브 데이터로 부르지 않습니다. Silben은 실제 음절 교차격자/동일 카드/힌트3단계/직접 타일 배치를 유지하고, 게임 접촉의100+150+900ms 파란1→3dp를 소개16불꽃 효과와 구분합니다.", ""]
    screen += ["", "## 개별 module 계약", ""]
    for m in bindings["modules"]:
        screen += [f"### {m['id']}", "", f"- 필터: {m['filter_contract']}",
                   f"- 인자: {m['typed_argument_contract']}", f"- 상태: {', '.join(m['required_states'])}",
                   f"- 저장/보상: {m['save_and_reward_contract']}",
                   f"- 연결된 개별 source record: {len(m['record_uids']):,}; 에셋: {len(m.get('asset_ids', [])):,}.",
                   "- 로더: " + ", ".join('`' + e['source_id'] + '`' for e in m['loader_evidence']),
                   "- 화면: " + ", ".join('`' + e['source_id'] + '`' for e in m['screen_evidence']), ""]
    screen += ["## 실제 등록 경로와 별칭/legacy", "", "각 경로의 current main.dart 줄·해시·dispatch 원문과 typed arguments는 screen-bindings.json에 있습니다. 이름이 같은 과거 Listening 화면을 현재 native 듣기 루트로 계산하지 않습니다.", "",
               "| 경로 | 분류 | 실제 source target |", "|---|---|---|"]
    screen += [f"| `{r['path']}` | {r['classification']} | {', '.join(r['target_classes']) or 'dispatch excerpt 참조'} |" for r in bindings["registered_routes"]]
    screen += ["", "## 지원/계정/이력·직접 모달", "", "과거 97flow 목록의 개별 source 파일과 현재 등록 경로를 재확인합니다. 개별 상태·visible action·preserve contract·mockup variant는 JSON 원장에 보존하며 완료 플래그를 승계하지 않습니다.", "",
               "| flow | 현재 source 증거 |", "|---|---:|"]
    screen += [f"| {f['flow_id']} | {sum(e['exists'] for e in f['current_source_evidence'])}/{len(f['current_source_evidence'])} |" for f in bindings["support_flows"]]
    screen += ["", "## 재사용 컴포넌트와 검토 진입점", "",
               "각 컴포넌트의 실제 파일 해시·현재 import consumer를 JSON 원장에 남깁니다. 사용된다는 소스 증거는 실제 상태 실행/시각 승인이 아닙니다.", "",
               "| 컴포넌트 소스 | 현재 import consumer 수 |", "|---|---:|"]
    screen += [f"| `{c['source']['source_id']}` | {len(c['current_import_consumers'])} |" for c in bindings["reusable_components"]]
    screen += ["", "tool/c_content_flow_preview.dart는 실제 KoLernenApp route switch를 별도 origin의 로컬 Storage로 검토하는 진입점입니다. concept_c_preview.dart의 하위 로컬 샘플 상태와 구분합니다. 이 원장 자체는 preview 실행·build·렌더 QA를 수행하지 않습니다.",
               "", "과거 보자기 후보 UI 테스트는 소유 세션의 bojagi-screen-tests-before.dart에 정확한 바이트로 보존되어 있습니다. 그 보존은 최신 단일 아이템 UI를 3후보로 되돌릴 요구가 아닙니다.",
               "", "상자 오디오는 HANDOFF.md:215의 mute preview 계약과 파일 부재를 따릅니다. SFX 경로만으로 파일·라이선스·기기 소리 QA 완료를 주장하지 않습니다."]
    screen.append("")
    issues = ledger["validation"]["issues"]
    reported_modules = [m for m in bindings["modules"] if m["validation_layers"]["owner_report"]]
    execution_rows = [validation_row(m) for m in reported_modules] or ["| receipt 대기 | 현재 원장에 source/hash만 있음 | module별 보고 없음 | module별 보고 없음 | 최종 승인 추론 안 함 |"]
    remaining_rows = [f"| {m['id']} | " + "; ".join(str(item).replace("|", "\\|").replace("\n", " ")
                      for item in m["validation_layers"]["remaining"]) + " |"
                      for m in reported_modules if m["validation_layers"]["remaining"]]
    acceptance = ["# C 수용조건과 검증 경계", "", "이 문서는 ID/해시/경로 감사의 결과와 아직 요구되는 UI 수용조건을 구분합니다.", "",
                  "라이브48유닛/30phase/902task, Lernen13+Spiele8, Small Talk209/듣기186과 authoring/history 확장 원장을 구분합니다.", "",
                  f"소스 검사 결과: **{ledger['validation']['status']}**. 검사항목 {len(ledger['validation']['checks']):,}개; hard error {sum(i['severity']=='error' for i in issues)}개; 명시된 gap {sum(i['severity']!='error' for i in issues)}개.", "",
                  "## 실행 증거가 있는 subset", "", "각 열은 독립적인 검증 층입니다. 테스트 통과와 실제 렌더 관찰, 원본 에셋 승인, 최종 화면 인간 승인을 서로 대체하지 않습니다. 개별 로그/캡처 경로·범위는 JSON의 module validation 원문에 있습니다.", "",
                  "| module | 소스 관찰 | 자동검사 | 렌더 증거 | 인간 승인 |", "|---|---|---|---|---|",
                  *execution_rows, "", "## 남은 범위와 승인 경계", "",
                  "| 범위 | 남은 조건 |", "|---|---|",
                  *remaining_rows,
                  "| Intro baked DE | 승인 원화의 독일어 baked 영역은 native EN/200% 대응으로 바뀌지 않음. 원본 bytes를 보존하고 별도 해결. |",
                  "| 실기기 | physical Android devices0 보고. Android/iOS 실기기 QA 미실행; web 캡처와 Flutter 테스트로 대체하지 않음. |",
                  "| 인간 승인 | 기존 C 스타일/원본 에셋 승인은 현재 모든 runtime 화면의 최종 인간 승인과 별개. |",
                  "| Foundation 범위 | 12 starter 과제는 전체 자모·받침·문장 해독 평가가 아님. 부족 범위와 기존 학습 경로 유지. |",
                  "| canonical lineage | lost_phone/bank_account authority의 현재 대상 누락과 과거 기록 migration 결정 대기. |",
                  "| productive catalog | per-ID review 미완료, runtimeContentApproved=false. 구조 검사를 학습 평가 승인으로 바꾸지 않음. |", "",
                  "## 전체 수용조건", "", "위 검증 subset이 모든 조건 충족을 뜻하지 않습니다. 소스 감사 완료와 아직 남은 UI/기기/승인 조건을 구분합니다.", "",
                  "체크박스는 최종 수용 여부입니다. 미체크를 미구현 또는 자동검사 미실행으로 해석하지 않습니다. 구현·자동검사·로컬 렌더의 완료 범위는 위 module별 실행 증거와 영수증의 실제 로그를 따르며, 기기 검수와 최종 인간 승인까지 충족했을 때 최종 체크합니다.", "",
                  "- [x] 모든 조사 대상 표·소스 파일의 SHA-256, 개별 ID/행·revision·record hash를 원장에 기록.",
                  "- [x] native Small Talk/듣기의 실제 lesson -> source ID -> question binding 검사.",
                  "- [x] phase/task/hash/prerequisite/objective binding 및 코스의 개별 checkpoint/graph link 검사.",
                  "- [x] 모든 조사 대상 에셋 파일과 rejected/pending/legacy/외부 자료의 상태·해시 보존.",
                  "- [ ] 실제 UI에서 현재 runtime 학습 기록이 loader/filter/typed args로 선택·재생·평가·저장·복귀됨을 확인. authoring/archive 행은 라이브 UI에 승격하지 않음.",
                  "- [ ] 자유연습과 scoped assessment를 분리하고 레벨/이전 기록/계정 전환으로 잘못된 evidence를 만들지 않음.",
                  "- [ ] 한글 미독해 신규 사용자의 입문 진행·재개·읽기 준비도를 방문 이력과 분리하여 확인.",
                  "- [ ] production 새 일일 카드10개가 입문을 숨기지 않음. dueCount=new+review 공개 계약을 보존하고 실제 예약 복습 수만 입문 admission 판단에 사용.",
                  "- [ ] Foundation12 starter 과제 완료를 전체 한글 문해력 인증으로 표시하지 않음. 쌍자음·복합모음·받침·문장 독해 등 부족 범위와 기존 Hangul/발음/오늘의 글자 경로를 구분.",
                  "- [ ] 86 canonical segment/118 productive definition/8project/32snippet/16bundle는 draft/runtime gate 상태를 표시. source 구조 검사를 콘텐츠 승인이나 실행 가능한 평가/XP로 바꾸지 않음.",
                  "- [ ] 첫 실행7페이지는 기존 draft/final journal·이전/재개·오류 재시도 유지. 소개 예시는 실제 경제/학습을 지급하지 않음.",
                  "- [ ] exact intro baked German 글자 영역은 native EN/200% 대응 완료로 주장하지 않음. 기존 승인 bytes를 보존하고 제한을 별도 해결.",
                  "- [ ] TalSunbi 6포즈는 상황→관계/의도→표현→효과→후속문장→실제 저장/사랑방. 209레슨을 가리지 않음.",
                  "- [ ] Silben은 실제 음절 크로스워드, 같은 카드의 도깨비/격자, 힌트3단계, 사용자 직접 타일 배치. 실제 접촉에만100+150+900ms 파랑1→3dp.",
                  "- [ ] 소개의 큰 고정 액자16불꽃/기존영상은 게임 테두리 효과와 구분. media fail/hidden/reduced motion은 정적 폴백.",
                  "- [ ] 상자 개봉→단일 아이템 확대→설명·저장 XP·CTA→문화 이야기. 3후보/이중 개봉 없음; busy/error/retry/skip/account lifetime/중복 claim 검사.",
                  "- [ ] C 녹청·한지·원목·황동, Paperlogy UI/Noto Sans KR 학습, 이미지 nav5개와 승인 원화/비율/접지 유지.",
                  "- [ ] 320/390dp·100/130/200%·DE/EN·OS safe area·48dp target·스크린리더/키보드·reduced motion·Android/iOS 기기 QA.",
                  "- [ ] 실제 잔액·가격·소유권·그룹/서버 등불·저장 팩만 사용. loading/error 상태를 샘플 숫자로 대체하지 않음.",
                  "- [ ] A→B 계정 변경 시 active/hidden 탭의 오래된 데이터 무효화. done&&!error 전에는 현재 데이터 표시/보상 CTA를 허용하지 않음. pending/error에서 이전 계정 값이 남지 않는 실제 회귀 검사.",
                  "- [ ] opened-but-unacknowledged 보상은 unopened count와 분리한 실제 receipt로 Today/Hanok에서 재개. 같은 아이템·동일 claim·추가 XP 없음.",
                  "- [ ] Smalltalk 제목은 스크린리더에 한 번만 발표하고 typed route·저장·XP 계약 유지.",
                  "- [ ] 승인 이미지/정적 시제품/소스 연결/로컬 자동검사/정확한 SHA CI/실기기/배포/최종 인간 승인 구분.", "",
                  "## 병렬 소유 세션의 실행 검사", "",
                  "아래 실행 receipt의 suite별 결과·로그와 소유 세션 보고를 그대로 구분합니다. 서로 겹칠 수 있는 묶음이므로 합산 총검사 수를 만들지 않으며, 이전 수치가 최종 실행 결과를 덮어쓰지 않습니다.",
                  "", "최종 실행 receipt가 있으면 JSON 원장의 execution_evidence에 원문·파일 해시를 보존합니다. 생성기는 Flutter 검사/실행/build/렌더/기기 QA를 재실행하지 않으며 source fidelity를 시각 승인으로 바꾸지 않습니다.",
                  "", "최종 execution evidence:", "", "```json", json.dumps(ledger["execution_evidence"], ensure_ascii=False, indent=2), "```", "",
                  "## 원장에 남아 있는 gap/error", "", "세부 경로·참조 source/line·현재 해시는 content-ledger.json의 validation.issues에서 확인합니다.", "",
                  "| code | 건수 |", "|---|---:|"]
    acceptance += [f"| {k} | {v} |" for k, v in sorted(collections.Counter(i['code'] for i in issues).items())]
    acceptance += ["", "## 승인 대기인 productive catalog", "",
                   "tools/content_factory/drafts/productive_assessments.json에118 definition,8project,32source snippet,16bundle가 있습니다. ProductiveAssessmentCatalog.runtimeContentApproved=false이고 CanonicalCourseSegmentLoader.load는 승인 catalog 주입 없이는 차단됩니다. draft를 자동으로 Flutter assets에 넣거나 UI 평가 완료/문화·학습 보상으로 부르지 않습니다.",
                   "", "canonical의 project8종 개별 ID:", ""]
    acceptance += ["- `" + identity + "` — authoring source에 존재; current learner runtime은 닫힘." for identity in ledger["productive_authoring_status"]["project_ids"]]
    acceptance += ["", "조치: 콘텐츠 담당자가 각 ID의 review ledger와 필요한 TTS/평가·provenance를 검토한 뒤 명시적으로 catalog를 승격/주입해야 합니다. 현재 감사는 원본과 source 구조만 보존하며 승인 gate를 변경하지 않습니다.", ""]
    acceptance += ["", "## 누락된 canonical 시나리오의 실제 계보", "",
                   "native 듣기186개와 질문/TTS 연결 검사는 현재 corpus의 무결성입니다. 다음 두 canonical authority의 현재 대상 누락을 해결한 증거가 아닙니다.", ""]
    for entry in ledger["canonical_scenario_lineage"]:
        analogous = entry["current_analogous_variant"]
        acceptance += [f"- `{entry['id']}`: `{entry['last_observed_source_commit'][:8]}`의 `{entry['source_id'].split(':', 2)[-1]}`에 실제 원본 존재; `{entry['corpus_promotion_commit'][:8]}` corpus 승격 후 현재 ID 없음.",
                       f"  과거 `{entry['historical_level']}` / `{entry['historical_courseUnitId']}`. 원본 byte SHA-256 `{entry['original_record_sha256']}`; lineage-records.json에 정확한 UTF-8 record bytes 보존.",
                       "  현재 같은 유닛 항목: " + ", ".join("`" + row["id"] + "`" for row in entry["current_same_unit_variants"]) + ". 이 항목들은 ID 대체 계약이 아닙니다.",
                       (f"  현재 유사 주제 `{analogous['id']}`는 `{analogous['level']}` / `{analogous['courseUnitId']}`입니다. B1 은행계좌 기록을 A2 증거로 자동 이전할 수 없습니다." if analogous else "  현재 선언된 동일 주제 대체/ID alias를 찾지 못했습니다."),
                       "  조치: 코스/authority 담당자가 원본 복원, 명시적 lineage migration, authority의 archive 전환 중 하나를 검토해야 합니다. 과거 저장 ID/revision을 보존하며 새 평가·TTS·레벨 검토 없이 alias나 새 콘텐츠를 만들지 않습니다.", ""]
    acceptance += ["", "미해결 literal은 삭제하지 않습니다. 과거 handoff/source 스냅샷·동적 경로·개발/legacy 참조를 함께 보존한 결과이며, 실제 runtime 참조 수를 각 항목에 따로 표시합니다.",
                   "", "동시 구현 중 source가 바뀌면 check는 실패합니다. 최종 구현 뒤 build를 다시 실행하고 check로 같은 ID/해시/바인딩이 남는지 확인합니다.", ""]
    return {"CONTENT_LEDGER.md": "\n".join(content), "SCREEN_BINDINGS.md": "\n".join(screen),
            "ACCEPTANCE.md": "\n".join(acceptance)}


def self_test() -> None:
    # Negative fixtures ensure the audit rejects real data loss, not just matching implementation output.
    assert canonical({"b": 1, "a": "한글"}) == b'{"a":"\xed\x95\x9c\xea\xb8\x80","b":1}'
    sample = "(id: 'a', args: const Request(values: ['x)', 'y']), label: 'it\\'s') trailing"
    assert balanced(sample, 0).endswith("label: 'it\\'s')")
    original = {"id": "task", "contentRevision": 1, "assessment": {"answer": "1"}}
    correct = digest(original)
    altered = json.loads(json.dumps(original)); altered["assessment"]["answer"] = "0"
    assert digest(altered) != correct, "Changed answer must invalidate task evidence hash"
    assert digest({"revision": 1, "id": "invite_friend"}) != digest({"revision": 2, "id": "invite_friend"})
    assert reference_values({"practice": {"sourceIds": ["known", "missing"]}}) == [
        ("/practice/sourceIds/0", "known"), ("/practice/sourceIds/1", "missing")]
    assert pointer_token("KP01:grammar/이다") == "KP01:grammar~1이다"
    assert QUOTED_ASSET_DIRECTORY_RE.findall("const root = 'assets/illustrations/packs';") == ["assets/illustrations/packs"]
    assert INTERPOLATED_ASSET_DIRECTORY_RE.findall("'assets/illustrations/scenes/${s.id}.png'") == ["assets/illustrations/scenes/"]
    assert INTERPOLATED_ASSET_DIRECTORY_RE.findall("'assets/illustrations/listening/$art.webp'") == ["assets/illustrations/listening/"]
    assert unique_partition(["a", "b"], {"a", "b"})
    assert not unique_partition(["a", "a", "b"], {"a", "b"}), "Repeated coverage must fail even when set IDs match"
    assert not unique_partition(["a"], {"a", "b"}), "Dropped source ID must fail"
    blob = '[ {"label":"한글", "id":"old", "nested":{"id":"inside"}}, {"id":"next"} ]'.encode("utf-8")
    old, preserved, start, end = exact_record_span(blob, "old")
    assert preserved == blob[start:end] and json.loads(preserved) == old
    assert digest(old) == digest(json.loads(preserved))
    try:
        exact_record_span(blob, "missing")
    except ValueError:
        pass
    else:
        raise AssertionError("Missing historic identity must not produce an invented record")
    record = {"uid": "source#/0", "id": "item", "source_id": "source", "source_sha256": "source_hash",
              "record_sha256": correct, "revision": 2, "revision_policy": "authored_revision",
              "access": {"status": "archive_only; no runtime access"}, "module_binding_ids": ["games"],
              "asset_paths": ["assets/item.png"], "asset_bindings": [{"id": "assets/item.png", "exists": True}],
              "references": [{"field_pointer": "/sourceIds/0", "id": "known", "candidate_uids": ["known-source#/1"], "resolution": "context required"}]}
    projected = compact_record(record)
    assert projected["record_sha256"] == correct and projected["revision"] == 2 and projected["source_id"] == "source"
    assert projected["asset_ids"] == record["asset_paths"] and projected["references"][0]["candidate_uids"] == ["known-source#/1"]
    assert projected["access_override"] == "historical_archive_not_live" and record["references"][0]["resolution"] == "context required"
    fixture = Audit(Path.cwd(), Path.cwd())
    fixture.text = {"pubspec.yaml": "name: fixture",
        "lib/screens/root.dart": "\n\nimport '../widgets/c_gallery/c_materials.dart';\nimport 'package:other/widgets/c_gallery/c_unrelated.dart';",
        "lib/widgets/c_gallery/c_materials.dart": "import '../../screens/root.dart';\nclass CPaperPanel {}",
        "lib/widgets/c_gallery/c_unrelated.dart": "class CUnrelated {}",
        "lib/widgets/c_gallery/gallery_only.dart": "class CGalleryOnly {}"}
    fixture.sources = {key: {"sha256": digest(text)} for key, text in fixture.text.items()}
    reachable = fixture.c_runtime_dependencies(["lib/screens/root.dart"])
    assert [row["source"]["source_id"] for row in reachable] == ["lib/widgets/c_gallery/c_materials.dart"], "Gallery-only and external package sources must not become production C bindings; cycles terminate."
    assert reachable[0]["reachable_import_edges"][0]["line"] == 3, "Blank lines must not shift actual import evidence lines."
    fixture.execution_evidence = {"receipt": {"module_validation": {
        "foundation": {"automation": {"status": "passed", "tests": 61}, "human_approval": {"status": "pending"}}}}}
    assert fixture.module_validation("foundation")["automation"]["status"] == "passed"
    assert fixture.module_validation("foundation")["human_approval"]["status"] == "pending"
    assert fixture.module_validation("games")["automation"]["status"] == "not_reported_for_this_module", "A known Foundation pass must not turn unrelated modules or final human approval green."
    import tempfile
    with tempfile.TemporaryDirectory(prefix="c-audit-relative-assets-") as temporary:
        temporary_root = Path(temporary)
        reference_fixture = Audit(temporary_root / "app", temporary_root / "handoffs")
        for package in ("intro_exact", "intro_rejected_pack"):
            base = reference_fixture.artifacts / ARTIFACT_FOLDERS[package]
            (base / "assets").mkdir(parents=True)
            (base / "assets" / "same.png").write_bytes(package.encode("utf-8"))
            index = base / "index.html"
            index.write_text('<img src="assets/same.png">', encoding="utf-8")
            reference_fixture.paths["handoff:" + package + "/index.html"] = index
            nested = base / "proof" / "nested.json"
            nested.parent.mkdir()
            nested.write_text('{"asset":"assets/same.png"}', encoding="utf-8")
            reference_fixture.paths["handoff:" + package + "/proof/nested.json"] = nested
        (reference_fixture.root / "assets").mkdir(parents=True)
        (reference_fixture.root / "assets" / "same.png").write_bytes(b"runtime-original")
        for package in ("intro_exact", "intro_rejected_pack"):
            expected = "handoff:" + package + "/assets/same.png"
            assert reference_fixture.asset_reference_id("handoff:" + package + "/index.html", "assets/same.png") == expected
            assert reference_fixture.asset_reference_id("handoff:" + package + "/proof/nested.json", "assets/same.png") == expected
        assert reference_fixture.asset_reference_id("lib/screen.dart", "assets/same.png") == "assets/same.png"
        assert reference_fixture.asset_reference_id("lib/screen.dart", "assets/missing.png") == "assets/missing.png", "A handoff image must not repair a missing Flutter bundle key."
        assert reference_fixture.asset_reference_id("handoff:intro_exact/index.html", "assets/missing.png") == "assets/missing.png", "Missing references must stay visible."
    print("Self-test: canonical hash, nested Dart, changed assessment, revisions, references, unique/missing coverage, exact historical UTF-8 bytes, compact identity, production import isolation, per-module verification boundaries and package-relative asset identity passed.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "check", "self-test"))
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--artifacts-root", type=Path, default=Path("C:/dev/hangulsori/_codex_artifacts"))
    args = parser.parse_args()
    if args.command == "self-test":
        self_test(); return 0
    audit = Audit(args.root, args.artifacts_root)
    ledger, bindings = audit.build()
    outputs: dict[str, str] = {
        "content-ledger.json": json.dumps(ledger, ensure_ascii=False, separators=(",", ":")) + "\n",
        "screen-bindings.json": json.dumps(bindings, ensure_ascii=False, indent=2) + "\n",
        "lineage-records.json": json.dumps({"schema_version": SCHEMA,
            "status": "historical evidence only; no additions to current runtime catalog",
            "encoding": "original_record_utf8 re-encodes to the exact preserved UTF-8 Git blob byte span",
            "records": audit.scenario_lineage, "context_revision_records": audit.context_lineage,
            "legacy_reward_test_backup": audit.legacy_reward_test_backup}, ensure_ascii=False, indent=2) + "\n",
        **markdown(ledger, bindings),
    }
    target = args.root / OUTPUT
    if args.command == "build":
        target.mkdir(parents=True, exist_ok=True)
        for name, body in outputs.items():
            (target / name).write_text(body, encoding="utf-8", newline="\n")
    else:
        stale = [name for name, body in outputs.items() if not (target / name).is_file()
                 or (target / name).read_text(encoding="utf-8") != body]
        if stale:
            print("Audit stale/missing; rerun build after owner changes: " + ", ".join(stale))
            return 2
    errors = [i for i in ledger["validation"]["issues"] if i["severity"] == "error"]
    print(json.dumps({"command": args.command, "status": ledger["validation"]["status"],
                      "counts": ledger["counts"], "records": len(ledger["records"]),
                      "asset_files": len(ledger["assets"]), "checks": len(ledger["validation"]["checks"]),
                      "hard_errors": len(errors), "declared_gaps": len(ledger["validation"]["issues"]) - len(errors),
                      "artifact_total_bytes": sum(len(body.encode("utf-8")) for body in outputs.values()),
                      "output": target.as_posix()}, ensure_ascii=False, indent=2))
    for error in errors[:12]:
        print(json.dumps(error, ensure_ascii=False))
    return 1 if errors else 0


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
