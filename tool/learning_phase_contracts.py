"""Content and reference contracts for the authored Learning Phase data.

NIKL identity is (grade, exact form), not the printed form alone. Legacy unique
form references remain readable; ambiguous references must name a sense key.
These checks establish structural integrity, not linguistic or human approval.
"""
from collections import defaultdict
from collections.abc import Mapping


def has_text(value):
    return isinstance(value, str) and bool(value.strip())


def ko_text(value):
    return has_text(value.get("ko")) if isinstance(value, Mapping) else has_text(value)


def grammar_key(item):
    grade, form = item.get("niklGrade"), item.get("form")
    if isinstance(grade, int) and not isinstance(grade, bool) and has_text(form):
        return f"G{grade}:{form.strip()}"
    # Explicitly authored, non-inventory contrasts have a separate namespace.
    key = item.get("grammarKey")
    return key if isinstance(key, str) and key.startswith("P:") else None


class GrammarIndex:
    def __init__(self, phases):
        self.intro = {}
        self.forms = defaultdict(set)
        self.items = {}
        self.occurrences = defaultdict(list)
        for phase in phases:
            for offset, item in enumerate(phase.get("koreanGrammar") or []):
                key = grammar_key(item)
                if not key:
                    continue
                self.forms[item["form"]].add(key)
                self.items.setdefault(key, item)
                self.occurrences[key].append((phase["id"], (phase["no"], offset)))
                if item.get("role") == "new":
                    self.intro.setdefault(key, (phase["no"], offset))

    def resolve(self, raw, explicit, report, context):
        key = explicit or (raw if isinstance(raw, str) and raw.startswith(("G", "P:")) and ":" in raw else None)
        if key:
            if not isinstance(key, str) or key not in self.items:
                report(context, f"알 수 없는 문법 키 {key!r}")
                return None
            if raw and raw not in (key, self.items[key]["form"]):
                report(context, f"표시 형태 {raw!r} 와 문법 키 {key!r} 가 다른 항목을 가리킨다")
                return None
            return key
        senses = self.forms.get(raw, set()) if isinstance(raw, str) else set()
        if len(senses) != 1:
            report(context, f"형태 {raw!r} 의 sense가 {'모호하다' if senses else '없다'} — 급·형태 키가 필요하다")
            return None
        return next(iter(senses))

    def refs(self, container, raw_field, report, context):
        raws = container.get(raw_field) or []
        keys = container.get("grammarKeys")
        if keys is not None:
            if not isinstance(keys, list) or any(not has_text(k) for k in keys):
                report(context, "grammarKeys 는 비어 있지 않은 문자열의 목록이어야 한다")
                return []
            if len(keys) != len(set(keys)):
                report(context, "grammarKeys 에 중복된 키가 있다")
            if raws and len(raws) != len(keys):
                report(context, f"{raw_field} 와 grammarKeys 의 길이가 다르다")
            return [k for i, key in enumerate(keys)
                    if (k := self.resolve(raws[i] if i < len(raws) else None, key, report, context))]
        return [k for raw in raws if (k := self.resolve(raw, None, report, context))]


def check_nested_fields(ps, findings):
    def require(condition, context, detail, phase, check="C2_fields"):
        if not condition:
            findings.error(check, context, detail, "실제 내용과 올바른 자료형을 채운다", phase.get("level", ""), phase.get("id", ""))

    for p in ps.phases:
        pid = p["id"]
        for field in ("listening", "speaking", "reading", "writing"):
            for n, row in enumerate(p.get(field) or []):
                where = f"{pid}.{field}[{n}]"
                require(isinstance(row, Mapping) and ko_text(row.get("objective")), where, "수행 목표 objective가 비어 있다", p)
                require(isinstance(row, Mapping) and has_text(row.get("taskType")), where, "taskType이 비어 있다", p)
        for field, key in (("topics", "focus"), ("functions", "realisation")):
            for n, row in enumerate(p.get(field) or []):
                require(isinstance(row, Mapping) and ko_text(row.get(key)), f"{pid}.{field}[{n}]", f"{key}의 실제 텍스트가 필요하다", p)
        for n, row in enumerate(p.get("phonology") or []):
            require(isinstance(row, Mapping) and ko_text(row.get("focus")) and has_text(row.get("drill")),
                    f"{pid}.phonology[{n}]", "발음 focus와 실행 가능한 drill이 필요하다", p)
        for n, row in enumerate(p.get("masteryCheck") or []):
            require(isinstance(row, Mapping) and ko_text(row.get("task")) and ko_text(row.get("criterion")),
                    f"{pid}.masteryCheck[{n}]", "숙달 task·criterion의 실제 텍스트가 필요하다", p, "C10_mastery")
        for n, row in enumerate(p.get("koreanGrammar") or []):
            example = row.get("example") or {}
            require(ko_text(row.get("functionUse")) and isinstance(example, Mapping)
                    and has_text(example.get("ko")) and has_text(example.get("en")),
                    f"{pid}.koreanGrammar[{n}]", "문법의 기능과 KO 예문·EN 의미 풀이가 필요하다", p)
            expected = grammar_key(row)
            require(expected is not None and row.get("grammarKey", expected) == expected,
                    f"{pid}.{row.get('form')}", "grammarKey가 form·niklGrade와 일치하지 않는다", p, "C3_grammar")
        for row in p.get("textTypes") or []:
            require(row.get("use") in ("R", "P", "R/P"), f"{pid}.{row.get('id')}", "텍스트 use는 R|P|R/P여야 한다", p)
            require(has_text(row.get("note")), f"{pid}.{row.get('id')}", "장르를 어떻게 읽거나 생산할지 note가 필요하다", p)
        for row in p.get("vocabDomains") or []:
            lexis = row.get("sampleLexis")
            require(isinstance(lexis, list) and bool(lexis) and all(ko_text(x) for x in lexis),
                    f"{pid}.{row.get('id')}", "어휘 영역에 비어 있지 않은 실제 예시 어휘가 필요하다", p)
        for row in p.get("transferWarnings") or []:
            require(ko_text(row.get("warning")), f"{pid}.transferWarnings", "전이 경고의 설명이 비어 있다", p, "C15_warning")
        pre = p.get("prerequisites") or {}
        require(ko_text(pre.get("why")), f"{pid}.prerequisites", "선수 조건의 이유가 필요하다(첫 Phase는 입문 조건)", p)
        prag = p.get("pragmaticsRegister") or {}
        for field in ("politeness", "faceWork"):
            require(ko_text(prag.get(field)), f"{pid}.pragmaticsRegister.{field}", "관계·화행에 대한 실제 지침이 필요하다", p)


def check_reference_order(ps, findings):
    index = GrammarIndex(ps.phases)
    phase_order = {p["id"]: p["no"] for p in ps.phases}
    for p in ps.phases:
        pid, no, lv = p["id"], p["no"], p["level"]
        def report(context, detail, check="C7_prereq"):
            findings.error(check, context, detail, "급·의미·실제 도입 순서를 확인한다", lv, pid)
        pre = p.get("prerequisites") or {}
        for ref in pre.get("phaseIds") or []:
            if ref not in phase_order or phase_order[ref] >= no:
                report(f"{pid} → {ref}", "선수 Phase는 존재하는 이전 Phase여야 한다")
        for key in index.refs(pre, "forms", report, pid):
            pos = index.intro.get(key)
            if pos is None or pos[0] >= no:
                report(f"{pid} · {key}", "동일 sense가 아직 이전 Phase에 도입되지 않았다")
        for item in p.get("koreanGrammar") or []:
            if item.get("role") == "spiral":
                key = grammar_key(item)
                pos = index.intro.get(key)
                if pos is None or pos[0] >= no:
                    report(f"{pid} · {key}", "spiral의 동일 sense가 이전 Phase에 도입되지 않았다", "C4_spiral")
        for task in p.get("masteryCheck") or []:
            def task_report(context, detail):
                report(context, detail, "C10_mastery")
            for key in index.refs(task, "formsUsed", task_report, pid):
                pos = index.intro.get(key)
                if pos is None or pos[0] > no:
                    task_report(f"{pid} · {key}", "숙달 점검이 아직 도입하지 않은 동일 sense를 요구한다")
    return index


def check_dependency_order(ps, findings):
    index = GrammarIndex(ps.phases)
    def report(context, detail):
        findings.error("C17_depmap", context, detail, "실제 도입·재사용 위치와 같은 문법 키로 연결한다")
    if not ps.dependency_map:
        report("dependencyMap", "문법 의존 지도가 비어 있다")
    for row in ps.dependency_map:
        context = f"{row.get('prerequisite')} → {row.get('target')}"
        keys = [index.resolve(row.get(field), row.get(field + "Key"), report, context)
                for field in ("prerequisite", "target", "advancedReuse")]
        if not has_text(row.get("why")):
            report(context, "선수·목표·상위 재활용의 연결 이유가 필요하다")
        if not all(keys):
            continue
        pre, target, advanced = keys
        a, b = index.intro.get(pre), index.intro.get(target)
        phase_ids = {p["no"]: p["id"] for p in ps.phases}
        for field, pos in (("prerequisitePhase", a), ("targetPhase", b)):
            if field in row and (pos is None or row[field] != phase_ids.get(pos[0])):
                report(context, f"{field}가 동일 sense의 실제 도입 Phase와 다르다")
        if a is None or b is None or a >= b:
            report(context, "선수는 목표보다 먼저 도입되어야 한다(같은 Phase 안의 순서도 검사)")
        reuse_phase = row.get("advancedReusePhase")
        positions = [pos for pid, pos in index.occurrences[advanced] if not reuse_phase or pid == reuse_phase]
        if b is not None and not any(pos > b for pos in positions):
            report(context, "상위 재활용은 목표 뒤에 실제로 배치된 문법 항목이어야 한다")


def check_transfer_targets(ps, findings):
    index = GrammarIndex(ps.phases)
    table, coverage = {}, defaultdict(set)
    valid_functions = {a['id'] for p in ps.phases for a in p.get('functions') or []}
    for lang in ("EN", "DE"):
        for level, pack in (ps.transfer.get(lang) or {}).items():
            for item in pack.get("items") or []:
                context = f"{lang}:{level}:{item.get('id')}"
                def report(where, detail):
                    findings.error("C13_transfer", where, detail, "전이 항목의 식별자·대상·분석을 고친다", level)
                ident = (lang, level, item.get("id"))
                if not has_text(item.get("id")) or ident in table:
                    report(context, "전이 id가 비어 있거나 같은 언어·레벨 안에서 중복됐다")
                table[ident] = item
                for field, expected in (("sourceLanguage", lang), ("koreanLevel", level)):
                    if field in item and item[field] != expected:
                        report(context, f"{field}가 전이 항목의 언어·레벨 컨테이너와 다르다")
                for field in ("sourceRealisation", "koreanRealisation", "why", "teachingMove"):
                    if not has_text(item.get(field)):
                        report(context, f"전이 분석 {field}가 비어 있다")
                if item.get("sourceLevel") not in ("A1", "A2", "B1", "B2", "C1", "C2", "none"):
                    report(context, "sourceLevel은 모어 쪽 CEFR 또는 none이어야 한다")
                if "sourceLevelEvidence" in item:
                    if item["sourceLevelEvidence"] != "PEDAGOGICAL" or not has_text(item.get("sourceLevelNote")):
                        report(context, "현재 sourceLevel 배정은 PEDAGOGICAL이며 추정 범위를 설명하는 sourceLevelNote가 필요하다")
                keys = index.refs(item, "relevantKoreanForms", report, context)
                functions = item.get("functionIds") or []
                for function in functions:
                    if function not in valid_functions:
                        report(context, f"알 수 없는 화행 대상 {function!r}")
                analyses = item.get("functionAnalysis") or []
                if {a.get("id") for a in analyses} != set(functions):
                    report(context, "functionAnalysis가 functionIds의 각 화행을 설명해야 한다")
                for analysis in analyses:
                    if not all(has_text(analysis.get(k)) for k in ("targetAction", "l1TeachingMove", "context")):
                        report(context, "화행별 목표·모어 전이 설명·문맥이 필요하다")
                if not keys and not functions:
                    report(context, "분석 대상 문법 또는 화행이 하나도 없다")
                for key in keys:
                    grade = index.items[key].get("niklGrade")
                    if grade is not None and grade != ("A1", "A2", "B1", "B2", "C1", "C2").index(level) + 1:
                        report(context, f"{key}는 이 KO 레벨에 새로 도입되는 sense가 아니다")
                    coverage[(lang, level, "grammar")].add(key)
                coverage[(lang, level, "function")].update(functions)
    for p in ps.phases:
        lv, pid = p["level"], p["id"]
        own_keys = {grammar_key(g) for g in p.get("koreanGrammar") or []}
        own_functions = {g["id"] for g in p.get("functions") or []}
        for lang in ("EN", "DE"):
            new_keys = {grammar_key(g) for g in p.get("koreanGrammar") or [] if g.get("role") == "new"} - {None}
            for key in sorted(new_keys - coverage[(lang, lv, "grammar")]):
                findings.error("C13_transfer", f"{pid} · {lang} · {key}", "새 문법의 모어별 전이 분석이 없다", "대응 분석을 작성한다", lv, pid)
            for act in sorted(own_functions - coverage[(lang, lv, "function")]):
                findings.error("C13_transfer", f"{pid} · {lang} · {act}", "화행의 모어별 전이 분석이 없다", "대응 분석을 작성한다", lv, pid)
        for warning in p.get("transferWarnings") or []:
            lang, iid = warning.get("sourceLanguage"), warning.get("transferItemId")
            context = f"{pid} · {lang}:{iid}"
            def report(where, detail):
                findings.error("C15_warning", where, detail, "대상과 같은 레벨·문법·화행의 전이에 연결한다", lv, pid)
            transfer_level = warning.get("transferLevel", lv)
            item = table.get((lang, transfer_level, iid))
            if not item or transfer_level != lv:
                report(context, "전이 항목이 없거나 다른 KO 레벨을 가리킨다")
                continue
            keys = set(index.refs(item, "relevantKoreanForms", report, context))
            warning_keys = set(index.refs(warning, "forms", report, context))
            if not ((keys & own_keys) or (set(item.get("functionIds") or []) & own_functions)):
                report(context, "전이 항목과 Phase 사이에 관련 문법·화행이 없다")
            if warning_keys and not warning_keys <= keys & own_keys:
                report(context, "경고의 대상 문법이 연결한 전이 항목 또는 Phase와 다르다")
            if warning.get("verdict") != item.get("verdict") and not has_text(warning.get("sliceReason")):
                report(context, "전이 판정이 다르면 부분 상황을 설명하는 sliceReason이 필요하다")


def check_declared_metadata(mx, ps, findings):
    """Declared authority and redundant reference labels must match their source."""
    index = GrammarIndex(ps.phases)
    inventory = {(grade, row["form"]): row
                 for grade, level in enumerate(("A1", "A2", "B1", "B2", "C1", "C2"), 1)
                 for row in mx.nikl_forms[level]}
    for p in ps.phases:
        genre_goals = defaultdict(set)
        for skill, use in (("listening", "R"), ("reading", "R"), ("speaking", "P"), ("writing", "P")):
            for goal in p.get(skill) or []:
                tid = goal.get("textTypeId")
                if not tid:
                    continue
                tt = mx.text_types.get(tid)
                expected_skill = ("listening" if use == "R" else "speaking") if tt and tt.get("mode", "").startswith("spoken") else ("reading" if use == "R" else "writing")
                if not tt or skill != expected_skill:
                    findings.error("C6_coverage", f"{p['id']} · {tid}", "장르의 매체와 기술 목표의 채널이 다르다", "구어 장르는 듣기·말하기에, 문어 장르는 읽기·쓰기에 연결한다", p["level"], p["id"])
                else:
                    genre_goals[tid].add(use)
        if ps.phases_doc.get("schemaVersion", 1) >= 2:
            for tt in p.get("textTypes") or []:
                needed = set(tt.get("use", "").split("/"))
                if not needed <= genre_goals[tt["id"]]:
                    findings.error("C6_coverage", f"{p['id']} · {tt['id']}", "요구 장르의 R/P를 수행하는 명시적 기술 목표가 없다", "장르별 수용·산출 과제를 실제 기술 목표에 연결한다", p["level"], p["id"])
        for g in p.get("koreanGrammar") or []:
            context = f"{p['id']} · {grammar_key(g)}"
            def report(detail):
                findings.error("C12_evidence", context, detail, "보유 인벤토리와 집필 내용의 근거를 구별한다", p["level"], p["id"])
            source = inventory.get((g.get("niklGrade"), g.get("form")))
            if source and "category" in g and g["category"] != source.get("category"):
                report("문법 범주가 해당 급·형태의 원 인벤토리와 다르다")
            if "authoredContentEvidence" in g and g["authoredContentEvidence"] != "PEDAGOGICAL":
                report("새로 집필한 기능·예문은 PEDAGOGICAL이어야 한다")
            expected_ref = {"sourceId": "nikl_kiiq_2017", "grade": g.get("niklGrade"), "form": g.get("form")}
            if "inventoryRef" in g and (not source or g["inventoryRef"] != expected_ref):
                report("inventoryRef가 실제 보유 인벤토리의 급·형태를 가리키지 않는다")
            if "evidenceScope" in g and g["evidenceScope"] != ["inventory_form", "native_grade", "category"]:
                report("공식성 범위는 보유 인벤토리의 형태·원 등급·범주에 한정한다")
        for contrast in p.get("supplementaryContrasts") or []:
            if contrast.get("evidence") != "PEDAGOGICAL" or not all(ko_text(contrast.get(k)) for k in ("note", "task", "criterion")):
                findings.error("C2_fields", p["id"], "보조 문법 대비에는 교수 근거·과제·판정 기준이 필요하다", "실제 대비 과제를 채운다", p["level"], p["id"])
    for level, pack in ps.crossmap.items():
        if level not in ("A1", "A2", "B1", "B2", "C1", "C2"):
            continue
        for row in pack.get("rows") or []:
            def report(where, detail):
                findings.error("C14_crossmap", where, detail, "같은 KO 레벨의 실제 문법 키와 연결한다", level)
            context = f"{level} · {row.get('id')}"
            if row.get("koreanLevel") != level:
                report(context, "koreanLevel이 교차표의 레벨 컨테이너와 다르다")
            for key in index.refs(row, "relevantKoreanForms", report, context):
                expected_grade = ("A1", "A2", "B1", "B2", "C1", "C2").index(level) + 1
                if index.items[key].get("niklGrade") != expected_grade:
                    report(context, f"{key}는 이 KO 레벨의 문법이 아니다")
