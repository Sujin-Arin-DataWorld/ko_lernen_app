"""Read the live persona bible and runtime corpus; write review artifacts only."""
from __future__ import annotations
import collections
import hashlib
import json
import subprocess
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent
REPO = OUTPUT.parents[2]
PROFILE = REPO / "tools/content_factory/canonical_scenarios/character_profiles.json"

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    profiles = json.loads(PROFILE.read_text(encoding="utf-8"))
    chars = profiles["recurringCharacters"]
    by_id = {c["id"]: c for c in chars}
    fixed_facts = profiles["relationshipGraph"]["consistencyRules"]["fixedFacts"]
    counts = {cid: collections.Counter() for cid in by_id}
    scenes_by_id = {cid: [] for cid in by_id}
    corpus = []
    source_files = [PROFILE]
    for path in sorted((REPO / "assets/data").glob("scenarios_*.json")):
        source_files.append(path)
        for scene in json.loads(path.read_text(encoding="utf-8")).get("scenarios", []):
            corpus.append(scene)
            player = scene.get("playerCharacterId", "")
            participants = set(scene.get("participantIds", []))
            speakers = {player if line.get("speaker") == "user" else line.get("speaker")
                        for line in scene.get("dialog", [])}
            for cid in by_id:
                if cid in participants:
                    counts[cid]["participantScenes"] += 1
                if cid == player:
                    counts[cid]["learnerRoleScenes"] += 1
                if cid in speakers:
                    counts[cid]["speakingScenes"] += 1
                if cid in participants or cid in speakers:
                    counts[cid][scene.get("level", "?")] += 1
                    scenes_by_id[cid].append({"id": scene["id"], "level": scene.get("level"),
                        "titleKo": scene.get("title", {}).get("ko"),
                        "relationshipContext": scene.get("relationshipContext", {})})
    edges = profiles["relationshipGraph"]["edges"]
    graph_pairs = {frozenset([e["a"], e["b"]]) for e in edges}
    profile_pairs = {frozenset([c["id"], target]) for c in chars
                     for target in c.get("relationships", {}) if target in by_id}
    one_way = [{"a": c["id"], "b": target, "description": description,
                "inGraph": frozenset([c["id"], target]) in graph_pairs}
               for c in chars for target, description in c.get("relationships", {}).items()
               if target in by_id and c["id"] not in by_id[target].get("relationships", {})]
    review_chars = [{**c, "fixedFacts": fixed_facts[c["id"]], "runtimeUsage": dict(counts[c["id"]]),
                     "runtimeScenes": scenes_by_id[c["id"]]} for c in chars]
    unused = [c["id"] for c in chars if not scenes_by_id[c["id"]]]
    report = {
        "status": "audit; persona redesign decisions pending; no runtime or profile writes",
        "baselineHead": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip(),
        "storyBaselineYear": 2026,
        "sceneCount": len(corpus), "recurringCharacterCount": len(chars),
        "genericRoleCount": len(profiles["runtimeRoleProfiles"]),
        "characters": review_chars, "relationshipGraph": profiles["relationshipGraph"],
        "zeroRuntimeUse": unused, "oneWayProfileDeclarations": one_way,
        "profilePairsMissingFromGraph": [sorted(pair) for pair in profile_pairs - graph_pairs],
        "graphPairsMissingFromProfiles": [sorted(pair) for pair in graph_pairs - profile_pairs],
        "sources": [{"path": str(p.relative_to(REPO)).replace("\\", "/"), "sha256": sha(p)}
                    for p in source_files],
    }
    (OUTPUT / "persona_usage.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n",
                                                encoding="utf-8")
    lines = [
        "# 한글소리 페르소나·관계 현황 감사", "",
        "현재 파일에서 확인한 사실과 정리 제안입니다. 연령 변경이나 새 관계는 아직 정본에 적용하지 않았습니다.", "",
        f"- 기준 HEAD: `{report['baselineHead']}`",
        f"- 실제 대화 시나리오: {len(corpus)}개 (A1–C2)",
        f"- 반복 인물: {len(chars)}명 / 일반 역할: {len(profiles['runtimeRoleProfiles'])}종 / 관계 그래프: {len(edges)}개 연결", "",
        "## 인물별 현재 설정과 사용량", "",
        "| 인물 | 현재 연령 설정 | 역할 | 등장 장면 | 학습자 역할 장면 |",
        "|---|---|---|---:|---:|",
    ]
    for c in chars:
        age = str(fixed_facts[c["id"]]["age"]) + "세"
        role = c.get("background", {}).get("role", "").replace("|", "/")
        lines.append(f"| {c['displayNames']['ko']} | {age} | {role} | {len(scenes_by_id[c['id']])} | {counts[c['id']]['learnerRoleScenes']} |")
    lines += ["", "## 확인한 정리 과제", "",
        "1. 실제 주연 7명과 아직 등장하지 않는 가족 인물 4명의 역할을 구분해야 합니다.",
        "2. 준은 현재 9세·초3이며, 안드레아·민호의 아들입니다. 실제 대화 등장 0건이므로 연령 재검토가 기존 준 대사와 충돌하지는 않습니다. 프로필·관계·작가 지침·음성 계약은 함께 검토해야 합니다.",
        "3. 정확한 나이는 relationshipGraph.consistencyRules.fixedFacts에 11명 모두 기록돼 있습니다. 인물 설명에는 상대 나이 또는 연령대만 있어, 읽는 위치에 따라 설정을 놓치기 쉽습니다. 한 인물 표에서 정확한 나이와 역할을 함께 보여 주는 방식으로 정리해야 합니다.",
        "4. 관계를 인물별 설명과 relationshipGraph에 중복 기록하고 있어 아래 연결이 어긋나 있습니다. 단방향 호감과 인물별 인지 차이는 의도된 서사로 구분해야 합니다.", ""]
    for item in one_way:
        a, b = (by_id[item[k]]["displayNames"]["ko"] for k in ("a", "b"))
        lines.append(f"- {a} → {b}: 상대 프로필에 대응 설명 없음. 그래프에는 {'존재' if item['inGraph'] else '없음'}.")
    for pair in report["profilePairsMissingFromGraph"]:
        lines.append("- 관계 그래프 누락: " + " ↔ ".join(by_id[x]["displayNames"]["ko"] for x in pair))
    lines += ["", "## 정리 방향 제안", "",
        "- 현재 11명과 안정된 캐릭터 ID를 유지하면서 주연 7명·가족 조연 4명으로 역할을 명확히 합니다.",
        "- 연령·직업·거주·언어 능력·주요 목표·약점을 각 인물의 한 표로 정리하고, 외형은 그 표를 따라 제작합니다.",
        "- 관계를 가족, 연애, 친구/동거, 직장/협업으로 정리합니다. 모든 관계에는 서로를 아는 경로와 현재 거리감을 기록합니다.",
        "- 양쪽 프로필의 설명과 관계 그래프를 일치시키되, 짝사랑이나 숨겨진 연결의 정보 차이는 별도로 유지합니다.",
        "- 기존 학습자를 특정 페르소나와 동일시하지 않고, 장면에서 맡는 역할과 인물의 정체성을 구분합니다.",
        "- 준의 연령대와 관계 서사의 강도를 확정한 뒤 상세 재배치안과 대표 대화 예시를 작성합니다.", "",
        "## 현재 관계 지도", "", "```mermaid", "graph LR"]
    for c in chars:
        lines.append(f'  {c["id"]}["{c["displayNames"]["ko"]} · {len(scenes_by_id[c["id"]])}장면"]')
    for e in edges:
        label = e["koLabel"].split(";")[0].replace('"', "'")
        lines.append(f'  {e["a"]} ---|"{label}"| {e["b"]}')
    lines += ["```", "", "## 검증 범위", "",
        "사용량은 현재 assets/data/scenarios_a1–c2.json의 participantIds와 실제 dialog 화자를 기준으로 집계했습니다. 사용자 화자는 playerCharacterId로 해석했습니다.",
        "카드·단어 예문·미승격 후보의 이름 언급까지 0건이라는 뜻은 아닙니다. 상세 장면 목록과 원본 SHA-256은 persona_usage.json에 있습니다.",
        "앱 코드·현재 페르소나 정본·콘텐츠·TTS·진도·보상·실사용 에셋은 이 감사로 변경하지 않았습니다.", ""]
    (OUTPUT / "PERSONA_AUDIT.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"scenes": len(corpus), "people": len(chars), "relationships": len(edges),
                      "zeroRuntimeUse": unused, "oneWayLinks": len(one_way),
                      "missingGraphPairs": report["profilePairsMissingFromGraph"]}))
    assert len({s["id"] for s in corpus}) == len(corpus), "duplicate runtime scenario IDs"

if __name__ == "__main__":
    main()
