from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
REGISTRY_PATH = (
    ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "trilingual_native_usage_registry_20261006.json"
)
REPORT_PATH = (
    ROOT
    / "tools"
    / "content_factory"
    / "review"
    / "trilingual_native_usage_progress_20261006.json"
)
LANGS = ("ko", "en", "de")


def _load() -> dict[str, Any]:
    return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))


def _profile_metrics(
    topic: dict[str, Any],
    lang: str,
    minimum: dict[str, int],
) -> dict[str, Any]:
    profile = topic[lang]
    source_contexts = profile.get("sourceContexts") or []
    phrase_bank = profile.get("phraseBank") or []
    avoid = profile.get("avoidTranslationese") or []
    registers = sorted(
        {
            str(row.get("registerLane"))
            for row in phrase_bank
            if isinstance(row, dict) and row.get("registerLane")
        }
    )
    source_ids = {
        str(row.get("sourceId"))
        for row in source_contexts
        if isinstance(row, dict) and row.get("sourceId")
    }
    broad_requirements = {
        "sourceContexts": len(source_ids) >= minimum["independentSourceContexts"],
        "patterns": len(phrase_bank) >= minimum["normalizedUsagePatterns"],
        "registerLanes": len(registers) >= minimum["registerLanes"],
        "translationeseWarnings": len(avoid)
        >= minimum["translationeseAvoidNotes"],
    }
    broad_complete = all(broad_requirements.values())

    deep_register_target = int(profile.get("deepRegisterLaneTarget", 3))
    deep_requirements = {
        "sourceContexts": len(source_ids) >= 4,
        "patterns": len(phrase_bank) >= 15,
        "registerLanes": len(registers) >= deep_register_target,
        "translationeseWarnings": len(avoid) >= 1,
        "researchDate": bool(profile.get("researchDate")),
        "authoritativeTermChecks": (
            bool(profile.get("authoritativeTermChecks"))
            if topic.get("requiresAuthoritativeTermCheckForDeepPass")
            else True
        ),
    }
    deep_complete = all(deep_requirements.values())

    return {
        "sourceContextCount": len(source_ids),
        "phrasePatternCount": len(phrase_bank),
        "registerLanes": registers,
        "registerLaneCount": len(registers),
        "translationeseWarningCount": len(avoid),
        "speechSurfaceNoteCount": len(profile.get("speechSurfaceNotes") or []),
        "authoritativeTermCheckCount": len(
            profile.get("authoritativeTermChecks") or []
        ),
        "researchDate": profile.get("researchDate"),
        "broadRequirements": broad_requirements,
        "broadPassComplete": broad_complete,
        "deepRequirements": deep_requirements,
        "deepPassComplete": deep_complete,
    }


def build_report() -> dict[str, Any]:
    registry = _load()
    minimum = registry["researchProtocol"]["hardMinimumPerTopicLanguage"]
    rows = []
    broad_profiles = 0
    deep_profiles = 0
    fully_broad_topics = 0
    fully_deep_topics = 0
    for topic in registry["topics"]:
        langs = {
            lang: _profile_metrics(topic, lang, minimum)
            for lang in LANGS
        }
        broad_profiles += sum(
            metrics["broadPassComplete"] for metrics in langs.values()
        )
        deep_profiles += sum(
            metrics["deepPassComplete"] for metrics in langs.values()
        )
        topic_broad = all(
            metrics["broadPassComplete"] for metrics in langs.values()
        )
        topic_deep = all(
            metrics["deepPassComplete"] for metrics in langs.values()
        )
        fully_broad_topics += int(topic_broad)
        fully_deep_topics += int(topic_deep)
        rows.append(
            {
                "topicId": topic["topicId"],
                "researchStatus": topic["researchStatus"],
                "allLanguagesBroadPassComplete": topic_broad,
                "allLanguagesDeepPassComplete": topic_deep,
                "languages": langs,
            }
        )

    return {
        "schemaVersion": 1,
        "generatedBy": (
            "tools/content_factory/"
            "audit_trilingual_native_usage_progress.py"
        ),
        "generatedDate": "2026-10-06",
        "registryPath": REGISTRY_PATH.relative_to(ROOT).as_posix(),
        "hardMinimumPerTopicLanguage": minimum,
        "summary": {
            "topicCount": len(rows),
            "profileCount": len(rows) * len(LANGS),
            "broadPassCompleteProfileCount": broad_profiles,
            "deepPassCompleteProfileCount": deep_profiles,
            "allLanguagesBroadPassCompleteTopicCount": fully_broad_topics,
            "allLanguagesDeepPassCompleteTopicCount": fully_deep_topics,
        },
        "topics": rows,
    }


def _sync_registry_status(report: dict[str, Any]) -> None:
    registry = _load()
    report_by_topic = {row["topicId"]: row for row in report["topics"]}
    for topic in registry["topics"]:
        metrics = report_by_topic[topic["topicId"]]
        for lang in LANGS:
            p = topic[lang]
            m = metrics["languages"][lang]
            if m["deepPassComplete"]:
                p["nativeUsageProfileStatus"] = "deep_pass_complete"
            elif m["broadPassComplete"]:
                p["nativeUsageProfileStatus"] = "broad_pass_complete"
            else:
                p["nativeUsageProfileStatus"] = "pending_broad_pass"
        if metrics["allLanguagesDeepPassComplete"]:
            topic["researchStatus"] = "deep_pass_complete"
        elif metrics["allLanguagesBroadPassComplete"]:
            topic["researchStatus"] = "broad_pass_complete_deep_pass_pending"
        else:
            topic["researchStatus"] = "corpus_collection_in_progress"

    REGISTRY_PATH.write_text(
        json.dumps(registry, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write report and synchronize computed statuses into registry.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail if the generated report or computed registry statuses are stale.",
    )
    args = parser.parse_args()

    report = build_report()
    if args.write:
        _sync_registry_status(report)
        # Recompute after status sync so report reflects canonical states.
        report = build_report()
        REPORT_PATH.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(json.dumps(report["summary"], ensure_ascii=False, indent=2))
        return

    if args.check:
        if not REPORT_PATH.is_file():
            raise SystemExit(f"missing progress report: {REPORT_PATH}")
        expected = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
        current = REPORT_PATH.read_text(encoding="utf-8")
        if current != expected:
            raise SystemExit(
                "trilingual native-usage progress report is stale; "
                "run audit_trilingual_native_usage_progress.py --write"
            )

        registry = _load()
        by_topic = {row["topicId"]: row for row in report["topics"]}
        for topic in registry["topics"]:
            metrics = by_topic[topic["topicId"]]
            for lang in LANGS:
                m = metrics["languages"][lang]
                expected_status = (
                    "deep_pass_complete"
                    if m["deepPassComplete"]
                    else (
                        "broad_pass_complete"
                        if m["broadPassComplete"]
                        else "pending_broad_pass"
                    )
                )
                if topic[lang].get("nativeUsageProfileStatus") != expected_status:
                    raise SystemExit(
                        f"{topic['topicId']}/{lang}: status is stale "
                        f"(expected {expected_status})"
                    )
        print(
            "progress report current:",
            report["summary"]["broadPassCompleteProfileCount"],
            "broad profiles,",
            report["summary"]["deepPassCompleteProfileCount"],
            "deep profiles",
        )
        return

    print(json.dumps(report["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
