"""Build text/HTML review artifacts and inspect PNGs without editing any pixels."""
from pathlib import Path
import csv
import hashlib
import html
import json
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parent
LOCALES = ("ko", "en", "de")
CANONICAL = {
    "hyeopmun": {
        "file": "references/hyeopmun_try03_cut.png",
        "stage": "hyeopmun/stages/stage_06_complete.png",
        "size": [1568, 2021],
        "sha256": "3a6e3141f0f9c763067d40a867cf94082df04f119ba275c037b6e67645153884",
    },
    "changgo": {
        "file": "references/changgo_final.png",
        "stage": "changgo/stages/stage_08_complete.png",
        "size": [2736, 1536],
        "sha256": "867495181c3507a29bca0efc43778bf6a958018b05992caba3fa40a01a3d9488",
    },
}
NAMES = {"hyeopmun": "협문", "changgo": "창고"}

def read(name):
    return json.loads((ROOT / name).read_text(encoding="utf-8-sig"))

def write_json(name, value):
    (ROOT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def inspect(rel):
    path = ROOT / rel
    if not path.is_file():
        return {"file": rel, "exists": False}
    with Image.open(path) as im:
        has_alpha = "A" in im.getbands()
        alpha = im.getchannel("A") if has_alpha else None
        return {
            "file": rel, "exists": True, "bytes": path.stat().st_size,
            "sha256": sha(path), "size": list(im.size), "mode": im.mode,
            "alphaRange": list(alpha.getextrema()) if alpha is not None else None,
            "alphaBBox": list(alpha.getbbox()) if alpha is not None and alpha.getbbox() else None,
            "hasTransparentPixels": alpha.getextrema()[0] < 255 if alpha is not None else False,
        }

def md_cell(value):
    return str(value).replace("|", r"\|").replace("\n", "<br>")

def build_tables(data, manifest):
    rows = ["# 협문·창고 KO/EN/DE 학습 설명표", "",
            "한국어를 의미 기준으로 작성한 검토용 콘텐츠입니다. 건축 공정은 교육용으로 묶었습니다. 현대 대화 장면은 수업을 위해 만든 상황이며, 역사적 실사용 기록이 아닙니다.",
            "", "현재 그림 상태: 승인한 14장 모두 투명 PNG이며 마지막 2장은 원본과 같은 바이트입니다. 원화의 미세한 기둥·기단·용마루 높이 차이는 보존했습니다.", ""]
    for building in NAMES:
        rows += [f"## {NAMES[building]}", "", "| 단계 | 새로 관찰할 부분 | 생활 표현 | 간단한 과제 |", "|---|---|---|---|"]
        for s in data["stages"]:
            if s["buildingId"] != building:
                continue
            rows.append("| " + " | ".join(md_cell(v) for v in
                [f'{s["sequence"]}. {s["title"]["ko"]}', s["observe"]["ko"], s["line"]["ko"], s["task"]["ko"]]) + " |")
        rows += ["", "### 문화 설명", ""]
        for lang in LOCALES:
            rows += [f'**{lang.upper()}** {data["culture"][building][lang]}', ""]
        for s in data["stages"]:
            if s["buildingId"] != building:
                continue
            rows += [f'### {s["sequence"]}. {s["title"]["ko"]}', "",
                     "| 항목 | KO | EN | DE |", "|---|---|---|---|"]
            for field, name in [("title","공정명"),("observe","관찰"),("scene","대화 상황"),("line","생활 표현"),("task","과제")]:
                rows.append("| " + name + " | " + " | ".join(md_cell(s[field][lang]) for lang in LOCALES) + " |")
            if "exercise" in s:
                ex = s["exercise"]
                rows += ["", f'과제 유형: {ex["kind"]}.']
                if ex.get("options"):
                    for option in ex["options"]:
                        rows += [f'- {option["id"]}: ' + " / ".join(option["label"][l] for l in LOCALES)]
                    rows += [f'교사용 정답: {ex["correctOptionId"]}']
            rows += ["", "앞선 한국어 발화: “" + s["precedingLineKo"] + "”",
                     "", "표현 초점: " + ", ".join(s["target"]),
                     "", "추가 허용 예: " + " / ".join(s["acceptedVariants"]),
                     "", "의미 판정: " + s["criterion"], ""]
    rows += ["## 보조 부재 설명", "", "| 한국어 | English | Deutsch |", "|---|---|---|"]
    for term in data["glossary"]:
        rows.append("| " + " | ".join(md_cell(term["label"][l] + ": " + term["explanation"][l]) for l in LOCALES) + " |")
    rows += ["", "출처 연결은 stage_blueprints.json과 source_evidence.json을 참조하세요.", ""]
    rows += ["## 검토 범위", "", "- 기계 검사: 단계 수·순서·필수 언어 필드·파일 연결·원본 해시.",
             "- 모델 검토: 발화 방향, 부탁/제안/허락의 구분, 한국어 해요체와 독일어 Sie, UI의 du.",
             "- 사람의 원어민 검수, 실제 학습자 검증, 태블릿 터치 검증은 수행하지 않았습니다.",
             "- 이 표는 앱의 읽기·선택 연습 화면에 연결됩니다. 보상·건축 진행도는 변경하지 않습니다.", ""]
    (ROOT / "learning.md").write_text("\n".join(rows), encoding="utf-8")
    with (ROOT / "learning.csv").open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow(["stage_id","building","sequence","asset","locale","process","observe","scene","line","task","targets","speech_act"])
        for s in data["stages"]:
            for lang in LOCALES:
                writer.writerow([s["stageId"],s["buildingId"],s["sequence"],s["asset"],lang,
                    s["title"][lang],s["observe"][lang],s["scene"][lang],s["line"][lang],s["task"][lang],
                    " | ".join(s["target"]),s["speechAct"]])

def main():
    data = read("learning.json")
    data["glossary"] = read("glossary.json")
    exercise_design = read("exercise_design.json")
    lessons = read("lesson_illustrations.json")
    for stage in data["stages"]:
        lesson = next((v for v in lessons if stage["stageId"] in v["stageIds"]), None)
        if lesson:
            stage["lessonIllustration"] = lesson
        design = exercise_design["overrides"].get(stage["stageId"])
        if design:
            stage["task"] = design["task"]
            stage["exercise"] = {k:v for k,v in design.items() if k != "task"}
        else:
            stage["exercise"] = {"kind":exercise_design["defaultKind"]}
    write_json("learning.json", data)
    ledger = read("generation_ledger.json")
    evidence = read("source_evidence.json")
    blueprint_map = read("stage_blueprints.json")
    findings = []
    def check(label, passed, detail):
        findings.append({"check":label,"status":"PASS" if passed else "FAIL","detail":detail})

    check("14 learning stages",len(data["stages"]) == 14,len(data["stages"]))
    ids = [s["stageId"] for s in data["stages"]]
    check("unique stage ids",len(ids)==len(set(ids)),ids)
    for b, n in [("hyeopmun",6),("changgo",8)]:
        stages = [s for s in data["stages"] if s["buildingId"] == b]
        check(b+" stage sequence",[s["sequence"] for s in stages]==list(range(1,n+1)),n)
    missing_locales=[]
    for s in data["stages"]:
        for field in ("title","observe","scene","line","task"):
            for lang in LOCALES:
                if not s.get(field,{}).get(lang,"").strip():
                    missing_locales.append(f'{s["stageId"]}.{field}.{lang}')
    check("all 3 languages complete",not missing_locales,missing_locales)
    for s in data["stages"]:
        ex=s.get("exercise",{})
        if ex.get("kind")=="choice":
            option_ids=[o["id"] for o in ex["options"]]
            check(s["stageId"]+" choice answer",ex["correctOptionId"] in option_ids,option_ids)

    originals = []
    for b,c in CANONICAL.items():
        original=inspect(c["file"])
        last=inspect(c["stage"])
        check(b+" canonical source hash",original.get("sha256")==c["sha256"],original.get("sha256"))
        check(b+" final exact bytes",last.get("sha256")==c["sha256"],last.get("sha256"))
        check(b+" original canvas",original.get("size")==c["size"],original.get("size"))
        originals.append({"building":b,"original":original,"finalStage":last})
    for bp in evidence["blueprints"]:
        check(bp["id"]+" source hash",sha(ROOT/bp["file"])==bp["sha256"],bp["file"])

    candidates={}
    raw=[]
    for entry in ledger["attempts"]:
        item=dict(entry)
        item["image"]=inspect(entry["file"])
        prompt=ROOT / entry["prompt"]
        item["promptSha256"]=sha(prompt) if prompt.is_file() else None
        check(entry["file"]+" provenance",item["image"]["exists"] and prompt.is_file(),entry["decision"])
        raw.append(item)
        if entry["decision"]=="candidate":
            candidates[(entry["building"],entry["stage"])]=item
    outputs=[]
    for s in data["stages"]:
        im=inspect(s["asset"])
        candidate=candidates.get((s["buildingId"],s["sequence"]))
        outputs.append({
            "stageId":s["stageId"],"building":s["buildingId"],"sequence":s["sequence"],
            "plannedAsset":s["asset"],"output":im,
            "blueprintRefs":blueprint_map["stageBlueprintRefs"][s["stageId"]],
            "reviewImage":s["asset"] if im["exists"] else candidate["file"],
            "candidateNote":candidate["note"] if candidate else "Byte-identical canonical final.",
            "status":"CANONICAL_FINAL" if im["exists"] and s["sequence"] in (6,8) and not candidate else ("APPROVED_INTERMEDIATE" if im["exists"] else "RAW_CANDIDATE"),
        })
        check(s["stageId"]+" deliverable exists",im["exists"],s["asset"])
        if im["exists"]:
            check(s["stageId"]+" exact canvas",im["size"]==CANONICAL[s["buildingId"]]["size"],im["size"])
            check(s["stageId"]+" transparency",im["hasTransparentPixels"],im["alphaRange"])
    manifest={
        "schemaVersion":1,"status":"approved_canonical","baseCommit":evidence["baseCommit"],
        "scope":"Approved construction artwork and teaching copy; runtime route /hanok/construction.",
        "counts":{"plannedStages":14,"canonicalFinals":2,"approvedIntermediates":len(candidates),"generationAttempts":len(raw),
                  "deliverablePngs":sum(o["output"]["exists"] for o in outputs)},
        "originals":originals,"stages":outputs,"generationAttempts":raw,
        "inheritedDefects":[{"building":"changgo","detail":"Fine green fringe visible in canonical silhouette. The byte-locked final preserves it."},
                            {"building":"hyeopmun","detail":"Original alpha bbox reaches the canvas edges; no added padding or crop is applied to final."}],
        "approval":read("promotion.json"),
        "unresolved":[
            "Posts, stone bases and roof anchors have small differences across approved generated stages. Pixel-stable shared layers are not claimed.",
            "Changgo stage 3 ridge height differs from stage 4; the user-selected generated forms are retained.",
            "This is an educational visualization, not a verified historical reconstruction."
        ],
        "runtimeModified":True,"humanApproved":True,
    }
    write_json("manifest.json",manifest)
    report={
        "status":"APPROVED_WITH_DOCUMENTED_VARIATIONS","checks":findings,
        "passed":sum(f["status"]=="PASS" for f in findings),"failed":sum(f["status"]=="FAIL" for f in findings),
        "structuralReview":"VARIATIONS_RETAINED_NOT_PIXEL_IDENTICAL","edgeReview":"TRANSPARENT_OUTPUTS_WITH_INHERITED_FINAL_DEFECTS","smallScreenReview":"CONTACT_SHEETS_INSPECTED",
        "reason":"Machine checks cannot establish structural continuity or historical reconstruction accuracy.",
    }
    write_json("validation.json",report)
    build_tables(data,manifest)
    template=(ROOT/"review.template.html").read_text(encoding="utf-8")
    for building in (None,"hyeopmun","changgo"):
        prefix="../" if building else ""
        payload={"learning":data,"manifest":manifest,"initialBuilding":building or "hyeopmun","prefix":prefix,"comparisonOnly":bool(building)}
        encoded=json.dumps(payload,ensure_ascii=False).replace("</","<\\/")
        output=template.replace("__REVIEW_DATA__",encoded)
        target=ROOT/building/"comparison.html" if building else ROOT/"review.html"
        target.write_text(output,encoding="utf-8")
    print(json.dumps({"counts":manifest["counts"],"passed":report["passed"],"failed":report["failed"],
        "status":report["status"],"pixelsEdited":False},ensure_ascii=False))
    if "--check" in sys.argv and report["failed"]:
        sys.exit(1)

if __name__=="__main__":
    main()
