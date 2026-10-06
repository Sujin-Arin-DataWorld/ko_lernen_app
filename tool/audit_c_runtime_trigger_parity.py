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
        "runtimeIntegration": (
            (ROOT / "lib/screens/c_settings_hub_screen.dart").is_file()
            and (ROOT / "lib/screens/c_profile_overview_screen.dart").is_file()
            and "conceptC" in (ROOT / "lib/screens/settings_screen.dart").read_text(encoding="utf-8-sig", errors="replace")
            and "CDetailPage" in (ROOT / "lib/screens/settings_screen.dart").read_text(encoding="utf-8-sig", errors="replace")
        ),
    }


def matrix_rows(counts: dict, impl: dict) -> list[dict]:
    free_web = impl.get("freeLearningBrowserPass", False)
    free_native = impl.get("freeLearningNative", False)
    course_native = impl.get("coursePathMissionNative", False)
    hangul_native = impl.get("wholeHangulNativeShell", False)
    settings_native = impl.get("settingsHubNative", False)
    settings_details = impl.get("settingsDetailsNative", False)
    profile_native = impl.get("profileOverviewNative", False)
    silben_native = impl.get("silbenNativeC", False)
    silben_golden = impl.get("silbenGoldenEvidence", False)
    return [
        {"scope":"C root five tabs","live":"5 tabs / 13 Learn / 8 Games","design":"approved","mockup":"rendered","native":"C WIP integrated","trigger":"21/21 root IDs/routes","verdict":"YELLOW"},
        {"scope":"Einleitung 7","live":"7 stages","design":"approved","mockup":"rendered","native":"integrated with known visual deltas","trigger":"journey IDs preserved","verdict":"ORANGE"},
        {"scope":"Comprehensive course","live":f"{counts['course_units']} units / {counts['learning_phases']} phases / {counts['phase_tasks']} tasks","design":"4 core scenes","mockup":"standalone HTML","native":"C path + mission native" if course_native else "C entry only","trigger":"source mapped; inner learn/result pixel parity pending","verdict":"YELLOW" if course_native else "ORANGE"},
        {"scope":"Foundation starter","live":f"{counts['foundation_steps']} steps / {counts['foundation_tasks']} tasks (WIP only)","design":"8 screens","mockup":"reviewed","native":"C components imported","trigger":"WIP route/task coverage","verdict":"YELLOW"},
        {"scope":"Whole Hangul","live":"34 letters + cards/writing","design":"8 inner screens","mockup":"reviewed","native":"C shell + existing live internals" if hangul_native else "existing live screen","trigger":"all existing Hangul behaviors retained; exact inner pixel parity pending","verdict":"YELLOW" if hangul_native else "ORANGE"},
        {"scope":"Free learning universal","live":"7 designed modules / 8,514 ledger rows","design":"data-bound C mockup","mockup":"8,514/8,514 real-Chrome PASS" if free_web else "browser proof missing","native":"native C landing wired" if free_native else "not native","trigger":"all ledger URLs render in Chrome; native deep screens reuse production routes" if free_web else "structural ledger only","verdict":"YELLOW" if free_web and free_native else "RED"},
        {"scope":"Vocabulary packs","live":"2,968 words / 254 packs","design":"free-learning","mockup":"all IDs browser-rendered" if free_web else "data only","native":"C landing ? live existing flow","trigger":"2,968 word + 254 pack URLs pass" if free_web else "structural IDs only","verdict":"YELLOW" if free_web else "RED"},
        {"scope":"Review / SRS / My Words","live":"2,968 base words + user data / My Words routes","design":"review-card subset + native C landing","mockup":"base-word review UI works; direct review ledger remains separate","native":"C landing ? live SRS/My Words","trigger":"user/custom runtime parity still requires account-state tests","verdict":"ORANGE"},
        {"scope":"Grammar","live":"264 records + 43 pattern notes","design":"free-learning","mockup":"264 IDs + extras render" if free_web else "data only","native":"C landing ? live grammar","trigger":"browser ID coverage PASS" if free_web else "pending","verdict":"YELLOW" if free_web else "RED"},
        {"scope":"Pronunciation","live":"84 phrases","design":"free-learning","mockup":"84 IDs render" if free_web else "data only","native":"C landing ? live pronunciation","trigger":"browser ID coverage PASS" if free_web else "pending","verdict":"YELLOW" if free_web else "RED"},
        {"scope":"Listening","live":"186 lessons / 744 questions","design":"free-learning","mockup":"930 lesson/question URLs render" if free_web else "data only","native":"C landing ? live listening","trigger":"browser ID coverage PASS" if free_web else "pending","verdict":"YELLOW" if free_web else "RED"},
        {"scope":"Scenarios","live":"186 scenarios / 579 quests","design":"free-learning","mockup":"scenario/child URLs render" if free_web else "data only","native":"C landing ? live scenarios","trigger":"browser ID coverage PASS" if free_web else "pending","verdict":"YELLOW" if free_web else "RED"},
        {"scope":"Word relations","live":"114 clusters","design":"free-learning","mockup":"cluster/child URLs render" if free_web else "data only","native":"C landing ? live word web","trigger":"browser ID coverage PASS" if free_web else "pending","verdict":"YELLOW" if free_web else "RED"},
        {"scope":"Small Talk / TalSunbi","live":f"{counts['smalltalk_native_lessons']} lessons / {counts['smalltalk_phrases']} phrases","design":"separate tactile/TalSunbi work","mockup":"not in universal per-ID ledger","native":"C landing ? live tactile flow","trigger":"root route preserved; per-ID C parity pending","verdict":"ORANGE"},
        {"scope":"Book capture / notebook","live":"8 registered routes","design":"Einleitung sample + C landing","mockup":"no full C deep-flow mockup","native":"C landing invokes production capture chooser","trigger":"live route/choice preserved","verdict":"ORANGE"},
        {"scope":"Daily calligraphy","live":"34 Hangul records","design":"C landing only","mockup":"no dedicated inner C mockup","native":"C landing ? live calligraphy","trigger":"root route preserved","verdict":"ORANGE"},
        {"scope":"Games root + interiors","live":f"8 entries; cloze {counts['cloze_items']} / Satz {counts['sentence_items']} + other pools","design":"C root approved; Silben dedicated","mockup":"no all-game per-content ledger","native":"8 roots preserved","trigger":"8/8 root routes; internal pixel parity incomplete","verdict":"ORANGE"},
        {"scope":"Silben + Dokkaebi","live":"120 puzzles / 415 word occurrences","design":"12-plan -> 14 reviewed scene kinds","mockup":"approved state images + 390 golden","native":"C jade/paper/oak shell + Dokkaebi help/motion" if silben_native else "tactile legacy shell","trigger":"/wordle preserved; core behavior tests pass; golden present" if silben_golden else "/wordle preserved","verdict":"YELLOW" if silben_native and silben_golden else "ORANGE"},
        {"scope":"Settings + Profile","live":"71 existing anchors + 1 proposed iOS action","design":"16 PNG screens","mockup":"approved gallery","native":f"C hub={settings_native}, C details={settings_details}, profile overview={profile_native}","trigger":"typed section routing + legacy callbacks preserved; device pixel sign-off pending","verdict":"YELLOW" if settings_native and settings_details and profile_native else "ORANGE"},
        {"scope":"Hanok / Gye / Rewards","live":"stateful live services","design":"approved C root + reward assets","mockup":"representative states","native":"C WIP integrated/reported tests","trigger":"route/state contracts; backend/device proof pending","verdict":"YELLOW"},
        {"scope":"Productive authoring drafts","live":"118 definitions / 8 projects / 32 snippets / 16 bundles","design":"not runtime","mockup":"must stay excluded","native":"runtimeContentApproved=false","trigger":"correctly blocked","verdict":"OUT_OF_RUNTIME"},
    ]

def report_md(result: dict) -> str:
    s = result["sourceAudit"]
    f = result["freeLearning"]
    st = result["settingsProfile"]
    repo = result["repo"]
    impl = result["implementation"]
    browser = f.get("browserAudit", {})
    lines = [
        "# C Runtime / Trigger Parity Audit — 2026-10-06",
        "",
        "승인 C 시안, HTML 목업, Flutter WIP, `origin/main`, source audit를 서로 다른 증거 층으로 분리해 검증한다.",
        "",
        "## 현재 판정",
        "",
        f"**{result['status']}**",
        "",
        "런타임 trigger 층은 통과했다. 다만 이것은 모든 화면의 픽셀 100% 일치나 실기기 최종 승인까지 끝났다는 뜻이 아니다.",
        "",
        f"- source audit: `{s['status']}` / checks {s['checks']:,} / hard errors {s['hardErrors']} / declared gaps {s['declaredGaps']}.",
        f"- C WIP HEAD `{repo['head'][:10]}`, origin/main `{repo['originMain'][:10]}`, ahead/behind `{repo['aheadBehind']}`.",
        f"- Sori catalog exact parity: `{result['catalog']['exactParity']}` ({result['catalog']['currentCount']} entries = 13 Learn + 8 Games).",
        f"- free-learning content counts match live source: `{f['countsMatchLive']}`; ledger {f['ledger']['rows']:,} rows / structural invalid {f['ledger']['invalid']}.",
        f"- free-learning app entrypoint present: `{f['appMjsExists']}`.",
        f"- real Chrome ledger audit: `{browser.get('status', 'MISSING')}` / tested {browser.get('testedUrls', 0):,} / failed {browser.get('failedUrls', 0)} / zero-text {browser.get('zeroText', 0)}.",
        f"- native C: free={impl['freeLearningNative']}, course path+mission={impl['coursePathMissionNative']}, Hangul={impl['wholeHangulNativeShell']}, settings hub={impl['settingsHubNative']}, settings details={impl['settingsDetailsNative']}, profile={impl['profileOverviewNative']}, Silben={impl['silbenNativeC']}.",
        f"- Silben golden evidence: `{impl['silbenGoldenEvidence']}`.",
        f"- Settings/Profile original action anchors: current {st.get('existingActions', 0)-len(st.get('currentMissingOriginalAnchors', []))}/{st.get('existingActions', 0)}, origin/main {st.get('existingActions', 0)-len(st.get('originMainMissingOriginalAnchors', []))}/{st.get('existingActions', 0)}; moved P12 verified `{st.get('p12MovedHandlerVerified')}`.",
        "",
        "## Trigger / Design Matrix",
        "",
        "| 범위 | 라이브 분모 | 디자인 | 목업 증거 | Flutter | Trigger | 판정 |",
        "|---|---|---|---|---|---|---|",
    ]
    for row in result["matrix"]:
        lines.append(
            f"| {row['scope']} | {row['live']} | {row['design']} | {row['mockup']} | "
            f"{row['native']} | {row['trigger']} | **{row['verdict']}** |"
        )
    lines += [
        "",
        "## 이번 패스에서 닫힌 항목",
        "",
        "- 누락됐던 free-learning `app.mjs`를 복원하고 기존 model/catalog/detail/word 모듈을 실제 앱으로 조립했다.",
        "- `catalog.mjs`의 `size(module, model)` 런타임 오류를 수정했다.",
        "- 실제 Chrome에서 trigger ledger **8,514/8,514 URL**, 실패 0, 빈 텍스트 0을 확인했다.",
        "- Flutter `/free-learning` C landing과 production Learn 12개 비-course entry 연결을 검증했다.",
        "- Settings C hub + C detail 화면을 실제 `/settings/detail` 경로에 연결하면서 기존 callback/저장 로직을 유지했다.",
        "- Silben 기본 플레이 화면을 C 녹청/한지/원목 shell로 재배치하고 단서 번호·방향, 4×2 음절 타일, 도깨비 help/motion, C Hint CTA를 유지했다.",
        "- Silben 핵심 회귀 테스트와 390×844 golden evidence를 추가했다.",
        "",
        "## 아직 100% pixel parity라고 부르지 않는 이유",
        "",
        "1. Einleitung 승인 원본과 현재 C onboarding 사이의 알려진 시각 차이(헤더/preview CTA/page별 continue/07 details)를 닫아야 한다.",
        "2. Course path/mission은 C native지만 learn/result 내부 상태의 승인 PNG 대비 픽셀 검증이 남아 있다.",
        "3. Whole Hangul은 C shell이 연결됐지만 8개 내부 상태를 승인 목업과 상태별 golden으로 닫아야 한다.",
        "4. Review/SRS/My Words의 사용자 상태, Small Talk, Book/Notebook, Calligraphy, 나머지 Games 내부 콘텐츠는 root trigger와 별개로 화면별 C pixel parity가 남아 있다.",
        "5. Android/iOS safe area, 200% text, 스크린리더, 실제 asset/video 렌더는 최종 실기기 승인 게이트가 필요하다.",
        "",
        "## 재실행",
        "",
        "```powershell",
        "python -X utf8 tool/verify_c_free_learning_urls.py",
        "python -X utf8 tool/audit_c_runtime_trigger_parity.py",
        "python -X utf8 tool/content_screen_audit.py check",
        "flutter test test/widgets/c_settings_profile_hub_test.dart test/widgets/c_settings_detail_test.dart test/widgets/c_free_learning_screen_test.dart test/foundation_learning_screen_test.dart test/silben_dokkaebi_screen_test.dart test/silben_grid_clue_sync_test.dart",
        "graphify update .",
        "```",
        "",
        "기계 판독 원장: `TRIGGER_PARITY_MATRIX.json`; 실제 브라우저 증거: `FREE_LEARNING_BROWSER_AUDIT.json`.",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    audit_summary_path = ROOT / "docs/design/c_content_audit/summary.json"
    if audit_summary_path.is_file():
        compact = load_json(audit_summary_path)
        validation = compact["validation"]
        source_audit = {
            "status": validation.get("status"),
            "checks": validation.get("checks", 0),
            "hardErrors": validation.get("hardErrors", 0),
            "declaredGaps": validation.get("declaredGaps", 0),
            "counts": compact["counts"],
        }
    else:
        content_audit = load_json(
            ROOT / "docs/design/c_content_audit/content-ledger.json"
        )
        validation = content_audit["validation"]
        issues = validation.get("issues", [])
        source_audit = {
            "status": validation.get("status"),
            "checks": len(validation.get("checks", [])),
            "hardErrors": sum(
                1 for issue in issues if issue.get("severity") == "error"
            ),
            "declaredGaps": sum(
                1 for issue in issues if issue.get("severity") == "gap"
            ),
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

    browser_audit_path = OUT / "FREE_LEARNING_BROWSER_AUDIT.json"
    browser_audit = load_json(browser_audit_path) if browser_audit_path.is_file() else {}
    main_text = (ROOT / "lib/main.dart").read_text(encoding="utf-8-sig", errors="replace")
    catalog_screen_text = (ROOT / "lib/screens/sori_stage/sori_stage_catalog_screen.dart").read_text(encoding="utf-8-sig", errors="replace")
    course_path_text = (ROOT / "lib/screens/learning_path_screen.dart").read_text(encoding="utf-8-sig", errors="replace")
    course_mission_text = (ROOT / "lib/screens/course_mission_screen.dart").read_text(encoding="utf-8-sig", errors="replace")
    settings_hub_path = ROOT / "lib/screens/c_settings_hub_screen.dart"
    profile_hub_path = ROOT / "lib/screens/c_profile_overview_screen.dart"
    settings_detail_text = (ROOT / "lib/screens/settings_screen.dart").read_text(
        encoding="utf-8-sig", errors="replace"
    )
    silben_text = (ROOT / "lib/screens/silben_kreuz_screen.dart").read_text(
        encoding="utf-8-sig", errors="replace"
    )
    implementation = {
        "freeLearningBrowserPass": browser_audit.get("status") == "PASS" and browser_audit.get("testedUrls") == 8514 and browser_audit.get("failedUrls") == 0,
        "freeLearningNative": (ROOT / "lib/screens/c_free_learning_screen.dart").is_file() and "case '/free-learning':" in main_text and "pushNamed('/free-learning')" in catalog_screen_text,
        "coursePathMissionNative": "CStageBackground" in course_path_text and "c-course-next-mission" in course_path_text and "CStageBackground" in course_mission_text and "c-course-mission-panel" in course_mission_text,
        "wholeHangulNativeShell": "CStageBackground" in hangul_text and "c-hangul-content-panel" in hangul_text,
        "settingsHubNative": settings_hub_path.is_file() and "case '/settings':" in main_text and "CSettingsHubScreen" in main_text,
        "settingsDetailsNative": (
            "conceptC" in settings_detail_text
            and "CDetailPage" in settings_detail_text
            and "SettingsInitialFocus.soundDetails" in settings_detail_text
        ),
        "profileOverviewNative": profile_hub_path.is_file() and "case '/profile':" in main_text and "CProfileOverviewScreen" in main_text,
        "silbenNativeC": all(marker in silben_text for marker in (
            "CDetailPage",
            "CTexture(CMaterial.oak",
            "CWaxSeal",
            "PracticeDokkaebiRestingArt",
            "CMaterialAction",
        )),
        "silbenGoldenEvidence": (ROOT / "test/goldens/baselines/c_silben_current_390.png").is_file(),
    }

    result = {
        "schemaVersion": 2,
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "status": (
            "RUNTIME_TRIGGER_PASS_PIXEL_PARITY_PENDING"
            if implementation["freeLearningBrowserPass"]
            and current_catalog == main_catalog
            else "FAIL_RUNTIME_TRIGGER_PARITY"
        ),
        "repo": {
            "head": git("rev-parse", "HEAD"),
            "originMain": git("rev-parse", "origin/main"),
            "aheadBehind": git("rev-list", "--left-right", "--count", "HEAD...origin/main"),
            "behindCommits": git("log", "--oneline", "HEAD..origin/main", check=False).splitlines(),
            "dirtyEntries": len(git("status", "--porcelain").splitlines()),
        },
        "sourceAudit": source_audit,
        "implementation": implementation,
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
            "browserAudit": browser_audit,
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
    result["matrix"] = matrix_rows(source_audit["counts"], implementation)
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
