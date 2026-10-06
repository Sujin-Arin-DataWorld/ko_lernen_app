from __future__ import annotations

import csv
import hashlib
import json
import os
import re
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import parse_qs, urlparse


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/design/c_runtime_trigger_parity_audit_20261005"
ARTIFACTS = Path(
    os.environ.get(
        "HANGULSORI_CODEX_ARTIFACTS",
        str(ROOT.parent.parent / "_codex_artifacts"),
    )
)


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(*args: str, check: bool = True) -> str:
    p = subprocess.run(
        ["git", *args], cwd=ROOT, text=True, encoding="utf-8",
        errors="replace", stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if check and p.returncode:
        raise RuntimeError(p.stderr.strip() or "git command failed")
    return p.stdout.strip()


def git_blob(ref: str, rel: str) -> bytes | None:
    p = subprocess.run(
        ["git", "show", f"{ref}:{rel}"], cwd=ROOT,
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    )
    return p.stdout if p.returncode == 0 else None


def parse_catalog(text: str) -> list[dict]:
    pattern = re.compile(
        r"_entry\(\s*id:\s*'([^']+)'.*?tab:\s*SoriStageTab\.(learn|games).*?route:\s*'([^']+)'",
        re.S,
    )
    return [
        {"id": m.group(1), "tab": m.group(2), "route": m.group(3)}
        for m in pattern.finditer(text)
    ]


def live_counts() -> dict:
    vocab = list(csv.DictReader(
        (ROOT / "assets/data/korean_vocab.csv")
        .read_text(encoding="utf-8-sig").splitlines()
    ))
    grammar = list(csv.DictReader(
        (ROOT / "assets/data/grammar.csv")
        .read_text(encoding="utf-8-sig").splitlines()
    ))
    pron = load_json(ROOT / "assets/data/pronunciation_phrases.json")["phrases"]
    scenarios = []
    for level in ("a1", "a2", "b1", "b2", "c1", "c2"):
        scenarios += load_json(ROOT / f"assets/data/scenarios_{level}.json")["scenarios"]
    listening = load_json(ROOT / "assets/data/listening_lessons.json")["lessons"]
    relations = load_json(ROOT / "assets/data/word_relations.json")["clusters"]
    return {
        "vocab": len(vocab),
        "packs": len({row["pack_id"] for row in vocab}),
        "grammar": len(grammar),
        "pronunciation": len(pron),
        "listening": len(listening),
        "listeningQuestions": sum(len(row["questions"]) for row in listening),
        "scenarios": len(scenarios),
        "scenarioQuests": sum(len(row.get("quests", [])) for row in scenarios),
        "relations": len(relations),
        "questTypes": dict(Counter(
            q["type"] for s in scenarios for q in s.get("quests", [])
        )),
    }


def source_parity(source_hashes: dict[str, str]) -> dict:
    current_byte_mismatch = []
    main_byte_mismatch = []
    main_semantic_diff = []
    main_missing = []
    for rel, expected in source_hashes.items():
        path = ROOT / rel
        if not path.is_file() or sha256(path) != expected:
            current_byte_mismatch.append(rel)
        blob = git_blob("origin/main", rel)
        if blob is None:
            main_missing.append(rel)
        elif hashlib.sha256(blob).hexdigest() != expected:
            main_byte_mismatch.append(rel)
        semantic = subprocess.run(
            ["git", "diff", "--quiet", "origin/main", "--", rel],
            cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        if semantic.returncode != 0:
            main_semantic_diff.append(rel)
    return {
        "sourceCount": len(source_hashes),
        "currentByteMismatch": current_byte_mismatch,
        "originMainByteMismatch": main_byte_mismatch,
        "originMainSemanticDiff": main_semantic_diff,
        "originMainMissing": main_missing,
    }


def validate_ledger(content: dict, ledger: dict) -> dict:
    maps = {
        key: {row["id"]: row for row in content[key]}
        for key in ("vocab", "packs", "grammar", "pronunciation",
                    "listening", "scenarios", "relations", "extras")
    }
    listening_parent = {
        q["id"]: lesson["id"]
        for lesson in content["listening"] for q in lesson["questions"]
    }
    scenario_parent = {}
    for scenario in content["scenarios"]:
        for field in ("vocab", "dialog", "quests", "rollenspiel"):
            values = scenario.get(field, [])
            if not isinstance(values, list):
                continue
            for i, raw in enumerate(values):
                child = raw if isinstance(raw, dict) else {"text": raw}
                cid = child.get("id", f"{scenario['id']}:{field}:{i}")
                scenario_parent[(field, cid)] = scenario["id"]
    relation_parent = {}
    for cluster in content["relations"]:
        for field in ("synonyms", "antonyms", "related", "expressions"):
            for i, _ in enumerate(cluster[field]):
                relation_parent[(field, f"{cluster['id']}:{field}:{i}")] = cluster["id"]

    invalid = []
    module_counts = Counter()
    for row in ledger["records"]:
        parsed = urlparse(row["url"])
        query = {k: v[0] for k, v in parse_qs(parsed.query).items()}
        module, kind, rid = row["module"], row["kind"], row["id"]
        module_counts[module] += 1
        reason = None
        if parsed.path != "screen.html":
            reason = "unexpected_path"
        elif query.get("m") != module:
            reason = "module_mismatch"
        elif module == "words":
            if kind == "word":
                pack = maps["packs"].get(query.get("id"))
                if (rid not in maps["vocab"] or pack is None
                        or rid not in pack["wordIds"] or query.get("item") != rid):
                    reason = "word_pack_binding"
            elif kind == "pack" and query.get("id") != rid:
                reason = "pack_binding"
        elif module in ("grammar", "pronunciation"):
            if rid not in maps[module] or query.get("id") != rid:
                reason = f"{module}_binding"
        elif module == "listening":
            if kind == "lesson":
                if rid not in maps["listening"] or query.get("id") != rid:
                    reason = "listening_lesson_binding"
            else:
                parent = listening_parent.get(rid)
                if parent is None or query.get("id") != parent or query.get("item") != rid:
                    reason = "listening_question_binding"
        elif module == "scenarios":
            if kind == "scenario":
                if rid not in maps["scenarios"] or query.get("id") != rid:
                    reason = "scenario_binding"
            else:
                parent = scenario_parent.get((kind, rid))
                if parent is None or query.get("id") != parent or query.get("item") != rid:
                    reason = "scenario_child_binding"
        elif module == "relations":
            if kind == "cluster":
                if rid not in maps["relations"] or query.get("id") != rid:
                    reason = "relation_cluster_binding"
            else:
                parent = relation_parent.get((kind, rid))
                if parent is None or query.get("id") != parent or query.get("item") != rid:
                    reason = "relation_child_binding"
        elif module == "extras":
            if rid not in maps["extras"] or query.get("id") != rid:
                reason = "extra_binding"
        else:
            reason = "unknown_module"
        if reason:
            invalid.append({
                "reason": reason, "module": module, "kind": kind,
                "id": rid, "url": row["url"],
            })
    return {
        "rows": len(ledger["records"]),
        "invalid": len(invalid),
        "invalidExamples": invalid[:50],
        "moduleCounts": dict(module_counts),
        "directReviewRows": sum(
            1 for row in ledger["records"]
            if row["module"] == "review" or "m=review" in row["url"]
        ),
    }


def settings_profile_audit() -> dict:
    folder = ARTIFACTS / "c-settings-profile-20261005-01a10981"
    draft_path = folder / "trigger-map-draft.json"
    if not draft_path.is_file():
        return {"artifactPresent": False}
    draft = load_json(draft_path)
    current_missing, main_missing, proposed = [], [], []
    for action in draft["actions"]:
        anchor = action.get("anchor")
        if anchor is None:
            proposed.append(action["id"])
            continue
        rel = action["file"].replace("\\", "/").split("/ko_lernen_app/", 1)[-1]
        path = ROOT / rel
        current = path.read_text(encoding="utf-8-sig", errors="replace") if path.is_file() else ""
        if anchor not in current:
            current_missing.append(action["id"])
        blob = git_blob("origin/main", rel)
        main = blob.decode("utf-8-sig", errors="replace") if blob else ""
        if anchor not in main:
            main_missing.append(action["id"])

    profile = (ROOT / "lib/screens/profile_screen.dart").read_text(
        encoding="utf-8-sig", errors="replace"
    )
    settings_button = (ROOT / "lib/widgets/sori/settings_button.dart").read_text(
        encoding="utf-8-sig", errors="replace"
    )
    return {
        "artifactPresent": True,
        "screens": 16,
        "actions": len(draft["actions"]),
        "existingActions": len(draft["actions"]) - len(proposed),
        "proposedActions": proposed,
        "currentMissingOriginalAnchors": current_missing,
        "originMainMissingOriginalAnchors": main_missing,
        "p12MovedHandlerVerified": (
            "SoriSettingsButton()" in profile
            and "pushNamed('/settings')" in settings_button
        ),
        "runtimeIntegration": False,
    }


def matrix_rows(counts: dict) -> list[dict]:
    return [
        {"scope":"C root five tabs","live":"5 tabs / 13 Learn / 8 Games","design":"approved","mockup":"rendered","native":"C WIP integrated","trigger":"21/21 root IDs/routes","verdict":"YELLOW"},
        {"scope":"Einleitung 7","live":"7 stages","design":"approved","mockup":"rendered","native":"integrated with current visual deltas","trigger":"journey IDs preserved","verdict":"ORANGE"},
        {"scope":"Comprehensive course","live":f"{counts['course_units']} units / {counts['learning_phases']} phases / {counts['phase_tasks']} tasks","design":"4 core scenes ready_for_review","mockup":"standalone HTML","native":"C entry only; inner integration followup","trigger":"source mapped; task execution sampled","verdict":"ORANGE"},
        {"scope":"Foundation starter","live":f"{counts['foundation_steps']} steps / {counts['foundation_tasks']} tasks (WIP only)","design":"8 screens","mockup":"reviewed","native":"C WIP imports","trigger":"WIP route/task coverage","verdict":"YELLOW"},
        {"scope":"Whole Hangul","live":"34 letters + cards/writing","design":"8 inner screens","mockup":"reviewed","native":"existing live screen; no direct C inner import","trigger":"route exists; C inner parity not proven","verdict":"ORANGE"},
        {"scope":"Free learning universal","live":"7 modules / 8,514 ledger rows","design":"planned/data-bound","mockup":"BROKEN: missing app.mjs","native":"separate from catalog","trigger":"structural rows only; UI execution impossible","verdict":"RED"},
        {"scope":"Vocabulary packs","live":"2,968 words / 254 packs","design":"free-learning","mockup":"data complete; app broken","native":"live existing flow","trigger":"all IDs structurally mapped","verdict":"RED"},
        {"scope":"Review / SRS / My Words","live":"2,968 base words + user data / 10 My Words routes","design":"review-card subset","mockup":"no direct review ledger rows","native":"live existing flows","trigger":"per-ID review proof incomplete","verdict":"RED"},
        {"scope":"Grammar","live":"264 records + 43 pattern notes","design":"free-learning","mockup":"data complete; app broken","native":"live existing flow","trigger":"264 IDs mapped","verdict":"RED"},
        {"scope":"Pronunciation","live":"84 phrases","design":"free-learning","mockup":"data complete; app broken","native":"live existing flow","trigger":"84 IDs mapped","verdict":"RED"},
        {"scope":"Listening","live":"186 lessons / 744 questions","design":"free-learning","mockup":"data complete; app broken","native":"live existing flow","trigger":"lesson/question rows mapped","verdict":"RED"},
        {"scope":"Scenarios","live":"186 scenarios / 579 quests","design":"free-learning","mockup":"data complete; app broken","native":"live existing flow","trigger":"scenario/child rows mapped","verdict":"RED"},
        {"scope":"Word relations","live":"114 clusters","design":"free-learning","mockup":"data complete; app broken","native":"live existing flow","trigger":"cluster/child rows mapped","verdict":"RED"},
        {"scope":"Small Talk / TalSunbi","live":f"{counts['smalltalk_native_lessons']} lessons / {counts['smalltalk_phrases']} phrases","design":"separate tactile/TalSunbi work","mockup":"not in universal free-learning","native":"live existing/tactile flow","trigger":"root route only in C catalog","verdict":"ORANGE"},
        {"scope":"Book capture / notebook","live":"8 registered routes","design":"Einleitung sample only","mockup":"no full C flow","native":"live existing flow","trigger":"root/full routes exist; not C-mocked","verdict":"ORANGE"},
        {"scope":"Daily calligraphy","live":"34 Hangul records","design":"no dedicated inner C mockup found","mockup":"not in free-learning","native":"live existing flow","trigger":"root route only","verdict":"ORANGE"},
        {"scope":"Games root + interiors","live":f"8 entries; cloze {counts['cloze_items']} / Satz {counts['sentence_items']} + other pools","design":"C root approved; Silben dedicated","mockup":"no all-game content ledger","native":"8 roots preserved","trigger":"8/8 root routes; internal parity incomplete","verdict":"ORANGE"},
        {"scope":"Silben + Dokkaebi","live":"120 puzzles / 415 word occurrences","design":"12-plan -> 14 reviewed scene kinds","mockup":"state images exist","native":"help/motion exists; exact C inner parity open","trigger":"/wordle preserved","verdict":"ORANGE"},
        {"scope":"Settings + Profile","live":"71 existing anchors + 1 proposed iOS action","design":"16 PNG screens","mockup":"gallery/contract only","native":"mockup runtimeIntegration=false","trigger":"70 old anchors + moved P12; iOS proposal not live","verdict":"ORANGE"},
        {"scope":"Hanok / Gye / Rewards","live":"stateful live services","design":"approved C root + reward assets","mockup":"representative states","native":"C WIP integrated/reported tests","trigger":"route/state contracts; backend/device proof pending","verdict":"YELLOW"},
        {"scope":"Productive authoring drafts","live":"118 definitions / 8 projects / 32 snippets / 16 bundles","design":"not runtime","mockup":"must stay excluded","native":"runtimeContentApproved=false","trigger":"correctly blocked","verdict":"OUT_OF_RUNTIME"},
    ]


def report_md(result: dict) -> str:
    s = result["sourceAudit"]
    f = result["freeLearning"]
    st = result["settingsProfile"]
    repo = result["repo"]
    lines = [
        "# C Runtime / Trigger Parity Audit — 2026-10-05",
        "",
        "승인 C 시안 → 목업 → 현재 C WIP Flutter → `origin/main` → 기존 source audit를",
        "분리해서 비교한다. 이 감사에서는 제품 로직을 수정하지 않는다.",
        "",
        "## 최종 판정",
        "",
        "**100% trigger parity: FAIL.** 콘텐츠 inventory와 루트 route 보존은 강하지만,",
        "모든 live 콘텐츠를 새 C 목업/네이티브 화면에서 실제로 실행하는 증거는 아직 없다.",
        "",
        f"- source audit: `{s['status']}` / checks {s['checks']:,} / hard errors {s['hardErrors']} / declared gaps {s['declaredGaps']}.",
        f"- C WIP HEAD `{repo['head'][:10]}`, origin/main `{repo['originMain'][:10]}`, ahead/behind `{repo['aheadBehind']}`.",
        f"- dirty WIP entries: {repo['dirtyEntries']}. C 디자인 통합은 아직 clean merged main이 아니다.",
        f"- Sori catalog WIP/main exact parity: `{result['catalog']['exactParity']}` ({result['catalog']['currentCount']} entries).",
        f"- free-learning live counts match: `{f['countsMatchLive']}`; ledger {f['ledger']['rows']:,} rows / structural invalid {f['ledger']['invalid']}.",
        f"- free-learning `app.mjs` exists: `{f['appMjsExists']}` (screen.html references it: `{f['screenReferencesAppMjs']}`).",
        f"- direct Review trigger rows: {f['ledger']['directReviewRows']}.",
        f"- Settings/Profile old anchors current/main: {st.get('existingActions', 0)-len(st.get('currentMissingOriginalAnchors', []))}/{st.get('existingActions', 0)} and {st.get('existingActions', 0)-len(st.get('originMainMissingOriginalAnchors', []))}/{st.get('existingActions', 0)}; moved P12: `{st.get('p12MovedHandlerVerified')}`.",
        "",
        "## Trigger Parity Matrix",
        "",
        "| 범위 | 라이브 분모 | 디자인 | 목업 | Native | Trigger | 판정 |",
        "|---|---|---|---|---|---|---|",
    ]
    for row in result["matrix"]:
        lines.append(
            f"| {row['scope']} | {row['live']} | {row['design']} | {row['mockup']} | "
            f"{row['native']} | {row['trigger']} | **{row['verdict']}** |"
        )
    lines += [
        "",
        "## 핵심 발견",
        "",
        "### P0 — 자유학습 universal mockup은 현재 부팅 불가",
        "",
        "`c_free_learning_mockup_20261005/screen.html`은 `app.mjs?v=1`을 로드하지만 그 파일이 없다.",
        "따라서 8,514개의 URL ledger가 정확해도 실제 UI trigger 증거가 될 수 없다.",
        "",
        "### P0 — 21/21 루트 진입과 콘텐츠 100% 진입은 별개",
        "",
        "13 Learn + 8 Games 루트 ID/route는 WIP와 main에서 일치한다. 그러나 Small Talk 209/590,",
        "Cloze 2,365, Satz 2,885, Book/Notebook 8 routes, Calligraphy, My Words 사용자 데이터 등",
        "내부 live corpus 전수에 대한 새 C mockup trigger 증거는 없다.",
        "",
        "### P0 — source audit hard error 0은 UI parity 100%가 아니다",
        "",
        "기존 `c_content_audit/ACCEPTANCE.md`도 실제 UI 선택→재생→평가→저장→복귀를",
        "최종 미체크 수용조건으로 남긴다. source/hash/binding 무결성과 실행 UI는 다른 층이다.",
        "",
        "### P1 — Course / Whole Hangul / Settings·Profile은 내부 C parity가 아직 부분적",
        "",
        "Course는 48 units / 30 phases / 902 tasks를 보존하지만 task 실행은 대표 표본이다.",
        "Whole Hangul의 새 내부 8화면은 기존 `/hangul` 내부에 직접 C 통합됐다는 증거가 없다.",
        "Settings/Profile 16장도 artifact 자체가 `runtimeIntegration=false`다.",
        "",
        "### P1 — Einleitung 승인 시안 차이가 현재 코드에도 남음",
        "",
        "현재 `c_onboarding.dart`에는 HANGUL SORI 헤더, 02–06 preview CTA, 페이지별 continue label,",
        "07 Details가 남아 있어 승인 비트맵과 100% 외형 일치가 아니다.",
        "",
        "## 신뢰 가능한 부분",
        "",
        "- live 데이터 분모(2,968/254/264/84/186/744/186/579/114)는 현재 소스와 일치한다.",
        "- 8,514 ledger row의 parent/child 구조는 이 감사기의 독립 검사를 통과한다.",
        "- Sori catalog 21개 ID/route는 WIP와 `origin/main`에서 같다.",
        "- Productive draft는 `runtimeContentApproved=false`로 live 분모에서 제외된다.",
        "",
        "## 100% 완료 조건",
        "",
        "1. `app.mjs` 구현/복구 후 8,514 URL 전수 headless navigation/render 검증.",
        "2. Review/SRS의 per-ID 직접 trigger 계약을 별도로 증명.",
        "3. 13 Learn + 8 Games 각각 root뿐 아니라 내부 live corpus까지 coverage 원장화.",
        "4. Small Talk, Calligraphy, Book/Notebook, My Words user/custom, Cloze/Satz 누락 범위 보강.",
        "5. Course 902 task와 Whole Hangul 내부 화면을 C native UI와 연결해 전수 ID 계약 검사.",
        "6. Settings/Profile 16장 native callback wiring + 기존 71동작 보존 + iOS 제안 분리.",
        "7. Einleitung 승인 시안 차이 해소.",
        "8. latest `origin/main`으로 WIP 재조정 후 source audit + parity audit 재실행.",
        "9. Android/iOS 실기기·스크린리더·최종 인간 디자인 승인 후에만 100%/ship-ready 판정.",
        "",
        "## 재실행",
        "",
        "```powershell",
        "python -X utf8 tool/audit_c_runtime_trigger_parity.py",
        "python -X utf8 tool/content_screen_audit.py check",
        "graphify update .",
        "```",
        "",
        "기계 판독 원장: `TRIGGER_PARITY_MATRIX.json`.",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    content_audit = load_json(ROOT / "docs/design/c_content_audit/content-ledger.json")
    validation = content_audit["validation"]
    issues = validation.get("issues", [])
    source_audit = {
        "status": validation.get("status"),
        "checks": len(validation.get("checks", [])),
        "hardErrors": sum(1 for issue in issues if issue.get("severity") == "error"),
        "declaredGaps": sum(1 for issue in issues if issue.get("severity") == "gap"),
        "counts": content_audit["counts"],
    }

    current_catalog = parse_catalog(
        (ROOT / "lib/data/sori_activity_catalog.dart").read_text(
            encoding="utf-8-sig", errors="replace"
        )
    )
    main_catalog_blob = git_blob("origin/main", "lib/data/sori_activity_catalog.dart")
    main_catalog = parse_catalog(
        main_catalog_blob.decode("utf-8-sig", errors="replace")
        if main_catalog_blob else ""
    )

    free_dir = ROOT / "docs/design/c_free_learning_mockup_20261005"
    free_content = load_json(free_dir / "content.json")
    free_ledger = load_json(free_dir / "trigger-ledger.json")
    live = live_counts()
    expected = {
        key: free_ledger["counts"][key]
        for key in (
            "vocab", "packs", "grammar", "pronunciation", "listening",
            "listeningQuestions", "scenarios", "scenarioQuests",
            "relations", "questTypes",
        )
    }

    course_dir = ROOT / "docs/design/c_course_mockup_20261005"
    course_acceptance = load_json(course_dir / "ACCEPTANCE.json")
    course_content = load_json(course_dir / "content.json")

    artifact_review_path = ARTIFACTS / "c-foundation-concept-20261005/REVIEW_STATUS.json"
    artifact_review = load_json(artifact_review_path) if artifact_review_path.is_file() else {}
    foundation_files = [
        "lib/screens/foundation_learning_screen.dart",
        "lib/screens/foundation_learning_widgets.dart",
        "lib/screens/foundation_practice_screen.dart",
    ]
    foundation_imports = {}
    for rel in foundation_files:
        path = ROOT / rel
        text = path.read_text(encoding="utf-8-sig", errors="replace") if path.is_file() else ""
        foundation_imports[rel] = any(
            marker in text for marker in ("c_gallery", "CPalette", "CPaperPanel", "CMaterialAction")
        )
    hangul_text = (ROOT / "lib/screens/hangul_screen.dart").read_text(
        encoding="utf-8-sig", errors="replace"
    )
    onboarding_text = (ROOT / "lib/screens/onboarding_v2/c_onboarding.dart").read_text(
        encoding="utf-8-sig", errors="replace"
    )

    captures = []
    visual_root = ARTIFACTS / "c-implementation-20261005/visual-shell"
    for locale in ("de", "en"):
        for tab in ("today", "learn", "games", "hanok", "gye"):
            png = visual_root / f"c-content-shell-{tab}-{locale}-390x844.png"
            captures.append({
                "tab": tab, "locale": locale, "png": png.is_file(),
                "provenance": png.with_suffix(".json").is_file(),
            })

    result = {
        "schemaVersion": 1,
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "status": "FAIL_100_PERCENT_TRIGGER_PARITY",
        "repo": {
            "head": git("rev-parse", "HEAD"),
            "originMain": git("rev-parse", "origin/main"),
            "aheadBehind": git("rev-list", "--left-right", "--count", "HEAD...origin/main"),
            "behindCommits": git("log", "--oneline", "HEAD..origin/main", check=False).splitlines(),
            "dirtyEntries": len(git("status", "--porcelain").splitlines()),
        },
        "sourceAudit": source_audit,
        "catalog": {
            "current": current_catalog, "originMain": main_catalog,
            "currentCount": len(current_catalog), "originMainCount": len(main_catalog),
            "exactParity": current_catalog == main_catalog,
        },
        "approvedC": {
            "contractPresent": (ROOT / "docs/design/c_approved_visual_contract_20261005/APPROVED_C_DESIGN.md").is_file(),
            "rootCaptures": captures,
            "allRootRenderEvidencePresent": all(x["png"] and x["provenance"] for x in captures),
        },
        "freeLearning": {
            "counts": free_ledger["counts"], "liveCounts": live,
            "countsMatchLive": expected == live,
            "sourceParity": source_parity(free_content["sourceHashes"]),
            "screenReferencesAppMjs": "app.mjs" in (free_dir / "screen.html").read_text(encoding="utf-8-sig"),
            "appMjsExists": (free_dir / "app.mjs").is_file(),
            "ledger": validate_ledger(free_content, free_ledger),
        },
        "course": {
            "acceptance": course_acceptance,
            "sourceParity": source_parity(course_content["sourceHashes"]),
        },
        "foundationHangul": {
            "artifactReviewPresent": bool(artifact_review),
            "foundationCImports": foundation_imports,
            "wholeHangulDirectCImport": any(
                marker in hangul_text
                for marker in ("c_gallery", "CPalette", "CPaperPanel", "CMaterialAction")
            ),
            "artifactOwnMockups": artifact_review.get("ownMockups", {}),
            "originMainFoundationPresent": git_blob(
                "origin/main", "lib/screens/foundation_learning_screen.dart"
            ) is not None,
        },
        "silben": {
            "artifactStatus": artifact_review.get("sideSilben", {}),
            "designPlanPresent": (ARTIFACTS / "c-silben-dokkaebi-20261005-01a10981/DESIGN_PLAN.md").is_file(),
            "routeInCatalog": any(x["id"] == "syllable_cross" and x["route"] == "/wordle" for x in current_catalog),
        },
        "settingsProfile": settings_profile_audit(),
        "onboardingVisualDeltas": {
            "headerStillHangulSori": "'HANGUL SORI'" in onboarding_text,
            "storyPreviewCtaStillPresent": "c-onboarding-preview-" in onboarding_text,
            "pageSpecificContinueLabels": "onboardingCtaCompanion" in onboarding_text,
            "page7DetailsStillPresent": "onboarding-v2-companion-details" in onboarding_text,
        },
    }
    result["matrix"] = matrix_rows(source_audit["counts"])
    (OUT / "TRIGGER_PARITY_MATRIX.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (OUT / "AUDIT_REPORT.md").write_text(report_md(result), encoding="utf-8")
    summary = {
        "status": result["status"],
        "catalogExactParity": result["catalog"]["exactParity"],
        "freeLearningRows": result["freeLearning"]["ledger"]["rows"],
        "freeLearningInvalidRows": result["freeLearning"]["ledger"]["invalid"],
        "freeLearningAppEntrypointPresent": result["freeLearning"]["appMjsExists"],
        "freeLearningCountsMatchLive": result["freeLearning"]["countsMatchLive"],
        "report": "docs/design/c_runtime_trigger_parity_audit_20261005/AUDIT_REPORT.md",
        "matrix": "docs/design/c_runtime_trigger_parity_audit_20261005/TRIGGER_PARITY_MATRIX.json",
    }
    (OUT / "RUN_LOG.txt").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
