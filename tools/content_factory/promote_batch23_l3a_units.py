#!/usr/bin/env python3
"""PR-L3a Batch 23 second wave (2026-09-09): loader-coverage fill for course
units a1_10 (a1_body cloze/satz) and a1_15 (new pack a1_first_class_1), plus
two Batch 23 defect fixes found by the full Flutter suite (single-syllable
cloze answer 값, distractors exposed in the sentence remainder).

Phases (run in order; each re-reads the live files):
  a  preflight + Batch 23 defect fixes
  b  new pack rows + curriculum/can-do registration + relevel_batch_005 --apply
  c  post-relevel copy, new cloze/satz, inherited rows, counts, drafts/review
"""
from __future__ import annotations

import bisect
import csv
import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data"
CF = ROOT / "tools" / "content_factory"
sys.path.insert(0, str(CF))
sys.path.insert(0, str(ROOT / "tool"))

VOCAB_CSV = DATA / "korean_vocab.csv"
CLOZE_JSON = DATA / "cloze.json"
SATZ_JSON = DATA / "satz_sentences.json"
CURRICULUM = DATA / "curriculum_manifest.json"
SEGMENTS = DATA / "can_do_segments.json"
AUTHORITIES = DATA / "can_do_content_authorities.json"
AUDIT_MANIFEST = CF / "content_audit_manifest.json"
COPY_LEDGER = CF / "review" / "promoted_copy_revisions_20260822.json"
PACK_JSON_POST = CF / "data" / "packs" / "a1_post_office_1.json"
BLANK = "＿＿＿"
TODAY = "2026-09-09"
MEMO = "Fable 직독 승인 2026-09-09 (PR-L3a Batch 23 2차); Jin 10% 표본 대기"
COLUMNS = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]

NEW_PACK = "a1_first_class_1"
NEW_PACK_BASE = "a1_first_class"
NEW_UNIT = "a1_15_first_class_work"
NEW_SEGMENT = "segment_a1_15_first_class_work"
NEW_CLUSTER = "cluster_a1_15_first_class_work_v1"
NEW_TOPIC = "첫 수업"
NEW_SEED = "seed_vocab_pack_a1_first_class_1_v1"
BODY_PACK = "a1_body"
BODY_UNIT = "a1_10_health_safety"
BODY_SEGMENT = "segment_a1_10_health_safety"


# ───────────────────────── io helpers ─────────────────────────
def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_vocab() -> list[dict[str, str]]:
    with VOCAB_CSV.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    assert list(rows[0].keys()) == COLUMNS, rows[0].keys()
    return rows


def write_vocab(rows: list[dict[str, str]]) -> None:
    with VOCAB_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        w.writerow(COLUMNS)
        for r in rows:
            w.writerow([r[c] for c in COLUMNS])


def fingerprint(value) -> str:
    canonical = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def syllables(s: str) -> int:
    return sum(1 for ch in s if 0xAC00 <= ord(ch) <= 0xD7A3)


def has_batchim(word: str):
    ch = word[-1]
    if not (0xAC00 <= ord(ch) <= 0xD7A3):
        return None
    return (ord(ch) - 0xAC00) % 28 != 0


PARTICLE_BATCHIM = {"은": True, "는": False, "이": True, "가": False, "을": True, "를": False, "과": True, "와": False}


def particle_after_blank(sentence: str):
    i = sentence.find(BLANK)
    if i < 0:
        return None
    rest = sentence[i + len(BLANK):]
    if not rest or rest[0] == " ":
        return None
    return rest[0] if rest[0] in PARTICLE_BATCHIM else None


def check_cloze_contract(items: list[dict], particle_ids: set | None = None) -> list[str]:
    """Dart game-contract mirror (test/cloze_test.dart, cloze_content_guard_test);
    the particle/batchim rule (audit_content_naturalness) is only applied to
    ``particle_ids`` because the legacy corpus carries known mismatches."""
    problems = []
    for it in items:
        s, a, full = it["sentenceKo"], it["answer"], it["fullKo"]
        ds = it["distractors"]
        if s.count(BLANK) != 1:
            problems.append(f"{it['id']}: blank count")
        if s.replace(BLANK, a, 1) != full:
            problems.append(f"{it['id']}: reassembly")
        if len(ds) != 3 or len(set(ds)) != 3 or a in ds:
            problems.append(f"{it['id']}: distractor set")
        if syllables(a) < 2:
            problems.append(f"{it['id']}: single-syllable answer {a}")
        for d in ds:
            if d in s:
                problems.append(f"{it['id']}: distractor {d} exposed in sentence")
        p = particle_after_blank(s)
        if p is not None and (particle_ids is None or it["id"] in particle_ids):
            for d in ds:
                bc = has_batchim(d)
                if bc is not None and bc != PARTICLE_BATCHIM[p]:
                    problems.append(f"{it['id']}: particle mismatch {d} before {p}")
        if not it.get("de", "").strip() or not it.get("en", "").strip():
            problems.append(f"{it['id']}: missing gloss")
        if full.count(a) >= 2:
            problems.append(f"{it['id']}: answer_repeat")
    return problems


def check_satz_contract(items: list[dict]) -> list[str]:
    import re
    strip = lambda t: re.sub(r"[ !?.,~()]", "", t).replace("…", "")
    problems = []
    for it in items:
        t = it["targetKo"]
        ds = it["distractors"]
        if len(t.split(" ")) < 3:
            problems.append(f"{it['id']}: too short {t}")
        if len(ds) != 2 or len(set(ds)) != 2:
            problems.append(f"{it['id']}: distractor count")
        own = {strip(x) for x in t.split(" ")}
        for d in ds:
            if strip(d) in own:
                problems.append(f"{it['id']}: distractor {d} in target")
        if not it.get("promptDe", "").strip() or not it.get("promptEn", "").strip():
            problems.append(f"{it['id']}: missing prompt")
    return problems


def by_id(items):
    return {it["id"]: it for it in items}


# ───────────────────────── content ─────────────────────────
# 9 new A1 headwords for a1_first_class_1 (all kiiq 1급; sentences profiled A1).
NEW_WORDS = [
    # korean, roman, german, pos_de, ko_example, de_example, topic, order, boss, english, pos_en, en_example
    ("수업", "sueop", "Unterricht", "Nomen", "한국어 수업은 월요일에 있어요.", "Der Koreanischunterricht ist am Montag.", "class, lesson", "Noun", "Korean class is on Monday."),
    ("처음", "cheoeum", "das erste Mal", "Nomen", "한국어 수업은 처음이에요.", "Koreanischunterricht habe ich zum ersten Mal.", "first time", "Noun", "It's my first time taking a Korean class."),
    ("전화번호", "jeonhwabeonho", "Telefonnummer", "Nomen", "전화번호를 알려 주세요.", "Sagen Sie mir bitte Ihre Telefonnummer.", "phone number", "Noun", "Please tell me your phone number."),
    ("대학", "daehak", "Universität, Hochschule", "Nomen", "무슨 대학에 다녀요?", "An welcher Universität studieren Sie?", "university, college", "Noun", "Which university do you go to?"),
    ("책상", "chaeksang", "Schreibtisch", "Nomen", "책상 위에 책이 있어요.", "Auf dem Schreibtisch liegt ein Buch.", "desk", "Noun", "There is a book on the desk."),
    ("연필", "yeonpil", "Bleistift", "Nomen", "연필로 이름을 써요.", "Ich schreibe meinen Namen mit Bleistift.", "pencil", "Noun", "I write my name with a pencil."),
    ("공부", "gongbu", "das Lernen, Studium", "Nomen", "저는 매일 한국어 공부를 해요.", "Ich lerne jeden Tag Koreanisch.", "study", "Noun", "I study Korean every day."),
    ("연습", "yeonseup", "Übung", "Nomen", "매일 발음 연습을 해요.", "Ich übe jeden Tag die Aussprache.", "practice", "Noun", "I practice pronunciation every day."),
    ("시작하다", "sijakhada", "anfangen, beginnen", "Verb", "수업은 아홉 시에 시작해요.", "Der Unterricht beginnt um neun Uhr.", "to start", "Verb", "Class starts at nine o'clock."),
]
ADOPTIONS = [
    # id, korean, old_level, source pack, reason
    ("vocab_b2_0060", "전공", "B2", "b2_education", "kiiq 1급 · a1_15 첫 수업(전공·번호) 유닛 보강 · 예문 A1로 교체(제 전공은 음악이에요.) · Fable 룰링 2026-09-09 PR-L3a Batch 23 2차"),
    ("vocab_b1_0214", "사귀다", "B1", "b1_verbs_daily_1", "kiiq 1급 · 예문 A1 판정(한국 친구를 많이 사귀었어요.) · a1_15 첫 수업 유닛 보강 · Fable 룰링 2026-09-09 PR-L3a Batch 23 2차"),
    ("vocab_b1_0242", "졸업하다", "B1", "b1_time_life_1", "kiiq 1(파생 졸업) · 예문 A1 판정(내년에 대학교를 졸업해요.) · a1_15 첫 수업 유닛 보강 · Fable 룰링 2026-09-09 PR-L3a Batch 23 2차"),
]
JEONGONG_EXAMPLE = ("제 전공은 음악이에요.", "Mein Studienfach ist Musik.", "My major is music.")

# cloze for a1_10 from a1_body examples: (vocab korean, sentenceKo, answer, distractors)
BODY_CLOZE = [
    ("코", "코가 ＿＿＿.", "아파요", ["먹어요", "읽어요", "자요"]),
    ("입", "입을 ＿＿＿.", "열어요", ["먹어요", "읽어요", "사요"]),
    ("손", "손을 ＿＿＿.", "씻어요", ["읽어요", "마셔요", "자요"]),
    ("발", "발이 ＿＿＿.", "아파요", ["읽어요", "먹어요", "와요"]),
    ("몸", "몸이 좀 안 ＿＿＿.", "좋아요", ["먹어요", "읽어요", "가요"]),
    ("배고프다", "아, 진짜 ＿＿＿.", "배고파요", ["읽어요", "입어요", "사요"]),
]
# satz for a1_10: new 3-4 token A1 sentences (vocabKo routes them to a1_body → a1_10)
BODY_SATZ = [
    ("머리", "어제부터 머리가 아파요.", "Seit gestern habe ich Kopfschmerzen.", "I've had a headache since yesterday.", ["학교", "커피"]),
    ("코", "코가 많이 아파요.", "Meine Nase tut sehr weh.", "My nose hurts a lot.", ["어제", "친구"]),
    ("손", "먼저 손을 씻으세요.", "Waschen Sie sich zuerst die Hände.", "Please wash your hands first.", ["커피", "주말"]),
    ("발", "많이 걸어서 발이 아파요.", "Ich bin viel gelaufen, deshalb tun mir die Füße weh.", "My feet hurt because I walked a lot.", ["학교", "오늘"]),
]
# cloze for the new pack: keyed by korean → (sentenceKo, answer, distractors)
PACK_CLOZE = {
    "수업": ("한국어 ＿＿＿은 월요일에 있어요.", "수업", ["책상", "연필", "집"]),
    "처음": ("한국어 수업은 ＿＿＿이에요.", "처음", ["책상", "연필", "지하철"]),
    "전화번호": ("＿＿＿를 알려 주세요.", "전화번호", ["의자", "사과", "커피"]),
    "대학": ("무슨 ＿＿＿에 다녀요?", "대학", ["사과", "커피", "주말"]),
    "책상": ("＿＿＿ 위에 책이 있어요.", "책상", ["주말", "월요일", "어제"]),
    "연필": ("＿＿＿로 이름을 써요.", "연필", ["사과", "지하철", "커피"]),
    "공부": ("저는 매일 한국어 ＿＿＿를 해요.", "공부", ["사과", "의자", "커피"]),
    "연습": ("매일 발음 ＿＿＿을 해요.", "연습", ["책상", "월요일", "집"]),
    "시작하다": ("수업은 아홉 시에 ＿＿＿.", "시작해요", ["먹어요", "읽어요", "자요"]),
    "전공": ("제 ＿＿＿은 음악이에요.", "전공", ["이름", "고향", "주말"]),
    "사귀다": ("한국 친구를 많이 ＿＿＿.", "사귀었어요", ["먹었어요", "읽었어요", "샀어요"]),
    "졸업하다": ("내년에 대학교를 ＿＿＿.", "졸업해요", ["먹어요", "마셔요", "입어요"]),
}
PACK_SATZ_DISTRACTORS = {
    "수업": ["어제", "커피"], "처음": ["학교", "커피"], "전화번호": ["학교", "오늘"], "대학": ["커피", "어제"],
    "책상": ["학교", "오늘"], "연필": ["커피", "주말"], "공부": ["의자", "어제"], "연습": ["학교", "커피"],
    "시작하다": ["어제", "친구"],
}
MOVED_SATZ_DISTRACTORS = {
    "satz_b2_0383": ["학교", "커피"],   # 제 전공은 음악이에요.
    "satz_b1_0425": ["학교", "커피"],   # 한국 친구를 많이 사귀었어요.
    "satz_b1_0450": ["어제", "커피"],   # 내년에 대학교를 졸업해요.
}
PACK_METADATA = {
    "version": 1,
    "batch": "23",
    "note": "PR-L3a Batch 23 2차 (2026-09-09): a1_15_first_class_work 로더 커버리지 결손(cloze 2·satz 0 → 목표 8) 해소용 신규 A1 팩. plan_pack_assignments.validate_plan 프리플라이트 통과 후 적용.",
    "vocabPacks": [
        {
            "packId": NEW_PACK,
            "level": "a1",
            "orderRange": [1, 12],
            "reviewBossOrders": [11, 12],
            "displayLabel": {"ko": "첫 수업", "de": "Erster Kurstag", "en": "First Day of Class"},
            "motif": "lotus",
            "curriculum": {"courseUnitId": NEW_UNIT, "conceptIds": ["concept_a1_first_meeting"]},
        }
    ],
}


def new_row(korean, roman, german, pos_de, ko_ex, de_ex, english, pos_en, en_ex, order, boss, ident):
    return {
        "korean": korean, "romanization": roman, "german": german, "level": "A1", "pos_de": pos_de,
        "example_korean": ko_ex, "example_german": de_ex, "topic": NEW_TOPIC, "pack_id": NEW_PACK,
        "pack_order": str(order), "is_review_boss": "true" if boss else "false", "english": english,
        "pos_en": pos_en, "example_english": en_ex, "id": ident,
    }


# ───────────────────────── phase a ─────────────────────────
def phase_a() -> None:
    from plan_pack_assignments import validate_plan
    scratch = Path(__file__).resolve().parent
    rows = read_vocab()
    vid = {r["id"]: r for r in rows}
    # 1. preflight: synthetic 12-row draft of the final pack shape.
    draft_rows = []
    for i, (ko, rom, de, pos_de, ko_ex, de_ex, en, pos_en, en_ex) in enumerate(NEW_WORDS, start=1):
        draft_rows.append(new_row(ko, rom, de, pos_de, ko_ex, de_ex, en, pos_en, en_ex, i, False, f"vocab_a1_{435 + i:04d}"))
    for i, (ident, ko, *_rest) in enumerate(ADOPTIONS, start=10):
        r = dict(vid[ident]); r["level"] = "A1"; r["pack_id"] = NEW_PACK; r["pack_order"] = str(i)
        # preflight-only placeholder: the planner expects level-segment ids for
        # a new pack; the real move keeps the original ids (relevel_batch_005).
        r["id"] = f"vocab_a1_{435 + i:04d}"
        r["is_review_boss"] = "true" if i >= 11 else "false"; r["topic"] = NEW_TOPIC
        if ko == "전공":
            r["example_korean"], r["example_german"], r["example_english"] = JEONGONG_EXAMPLE
        draft_rows.append(r)
    pre_draft = scratch / "preflight_a1_first_class_draft.csv"
    with pre_draft.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator="\n"); w.writeheader(); w.writerows(draft_rows)
    meta_path = CF / "drafts" / "batch_23_pack_metadata.json"
    write_json(meta_path, PACK_METADATA)
    # The planner models a pack of brand-new rows, so run it against a temp
    # root whose CSV no longer holds the three rows relevel_batch_005 moves.
    import shutil, tempfile
    tmp = Path(tempfile.mkdtemp(prefix="preflight_"))
    for rel in ("assets/data/curriculum_manifest.json", "lib/widgets/sori/dancheong_stamp.dart", "lib/services/vocab_pack_service.dart"):
        (tmp / rel).parent.mkdir(parents=True, exist_ok=True); shutil.copy(ROOT / rel, tmp / rel)
    moved = {a[0] for a in ADOPTIONS}
    with (tmp / "assets/data/korean_vocab.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator="\n"); w.writeheader(); w.writerows([r for r in rows if r["id"] not in moved])
    plans = validate_plan(pre_draft, meta_path, root=tmp)
    shutil.rmtree(tmp)
    print("preflight OK:", [(p.pack_id_base, p.level, p.order_in_level, p.label_de, p.motif, p.curriculum_unit_id) for p in plans])

    # 2. Batch 23 defect fixes.
    cloze = read_json(CLOZE_JSON); satz = read_json(SATZ_JSON)
    ci = by_id(cloze["items"]); si = by_id(satz["items"])
    ci["cloze_a1_0199"]["distractors"] = ["우표", "소포", "주소"]
    ci["cloze_a1_0352"]["distractors"] = ["학교", "서울", "부산"]
    ci["cloze_a1_0353"]["distractors"] = ["밥", "물", "책"]
    # 값 → 가격 (single-syllable answer is unfair: test/cloze_test.dart)
    r = vid["vocab_a1_0318"]
    assert r["korean"] == "값" and r["example_korean"] == "우표 값이 얼마예요?", r
    r["korean"] = "가격"; r["romanization"] = "gagyeok"; r["example_korean"] = "우표 가격이 얼마예요?"
    c = ci["cloze_a1_0206"]
    assert c["answer"] == "값", c
    c["answer"] = "가격"; c["sentenceKo"] = "우표 ＿＿＿이 얼마예요?"; c["fullKo"] = "우표 가격이 얼마예요?"
    s = si["satz_a1_0170"]
    assert s["vocabKo"] == "값", s
    s["targetKo"] = "우표 가격이 얼마예요?"; s["vocabKo"] = "가격"
    # authoring pack json
    pack = read_json(PACK_JSON_POST)
    hit = [w for w in pack["words"] if w[0] == "값"]
    assert len(hit) == 1, hit
    hit[0][0] = "가격"; hit[0][5] = "우표 가격이 얼마예요?"
    # copy-revision ledger: recompute the three entries against the batch_09 drafts
    ledger = read_json(COPY_LEDGER)
    manifest_rel = "tools/content_factory/drafts/batch_09_4x_manifest.json"
    with (CF / "drafts" / "c3_batch09_vocab_a1_c2.csv").open(encoding="utf-8-sig", newline="") as f:
        draft_vocab = {row["id"]: dict(row) for row in csv.DictReader(f)}
    draft_cloze = by_id(read_json(CF / "drafts" / "c2_batch09_cloze_a1_c2.json")["items"])
    draft_satz = by_id(read_json(CF / "drafts" / "c2_batch09_satz_a1_c2.json")["items"])
    live_map = {("vocab", "vocab_a1_0318"): dict(r), ("cloze", "cloze_a1_0206"): dict(c), ("satz", "satz_a1_0170"): dict(s)}
    draft_map = {("vocab", "vocab_a1_0318"): draft_vocab["vocab_a1_0318"], ("cloze", "cloze_a1_0206"): draft_cloze["cloze_a1_0206"], ("satz", "satz_a1_0170"): draft_satz["satz_a1_0170"]}
    replaced = 0
    for e in ledger["entries"]:
        key = (e["kind"], e["id"])
        if e["manifest"] == manifest_rel and key in live_map:
            d, l = draft_map[key], live_map[key]
            assert e["beforeSha256"] == fingerprint(d), key
            e["fields"] = sorted(k for k in {*d, *l} if d.get(k) != l.get(k))
            e["afterSha256"] = fingerprint(l)
            replaced += 1
    assert replaced == 3, replaced
    ledger["amendments"].append({
        "date": TODAY, "scope": "PR-L3a Batch 23 2차",
        "method": "vocab_a1_0318 headword 값→가격 (test/cloze_test.dart: single-syllable answer is unfair) with the same example/DE/EN meaning; cloze_a1_0206/satz_a1_0170 follow the new headword; entries re-fingerprinted with the validate_promoted_batch projection",
        "added": 0, "replaced": 3,
    })
    # review packet row
    packet = ROOT / "docs" / "data" / "review_packets" / "batch_23_jin_sample.md"
    text = packet.read_text(encoding="utf-8")
    assert "포장지 → 값" in text and "우표 값이 얼마예요?" in text
    text = text.replace("포장지 → 값", "포장지 → 가격").replace("우표 값이 얼마예요?", "우표 가격이 얼마예요?")
    packet.write_text(text, encoding="utf-8")
    # contract checks before writing
    probs = check_cloze_contract(cloze["items"], particle_ids={"cloze_a1_0199", "cloze_a1_0352", "cloze_a1_0353", "cloze_a1_0206"}); probs = [p for p in probs if not any(k in p for k in KNOWN_CLOZE_EXPOSED)]
    print("cloze contract problems (excluding known allowlisted):", probs[:10], len(probs))
    sp = check_satz_contract(satz["items"]); print("satz contract problems:", sp[:10], len(sp))
    write_vocab(rows); write_json(CLOZE_JSON, cloze); write_json(SATZ_JSON, satz); write_json(PACK_JSON_POST, pack); write_json(COPY_LEDGER, ledger)
    print("phase a written")


KNOWN_CLOZE_EXPOSED = {
    "cloze_a1_0159", "cloze_a1_0200", "cloze_a1_0244", "cloze_a1_0274", "cloze_a2_0122", "cloze_a2_0172", "cloze_a2_0213",
    "cloze_a2_0250", "cloze_a2_0259", "cloze_a2_0264", "cloze_b1_0272", "cloze_b2_0067", "cloze_b2_0080", "cloze_c1_0113",
    "cloze_c2_0135", "cloze_c2_0159",
}


# ───────────────────────── phase b ─────────────────────────
def insert_sorted(lst: list, item: dict, key):
    keys = [key(x) for x in lst]
    if keys == sorted(keys):
        pos = bisect.bisect_left(keys, key(item)); lst.insert(pos, item)
    else:
        lst.append(item)


def phase_b() -> None:
    rows = read_vocab()
    assert not any(r["pack_id"] == NEW_PACK for r in rows)
    ids = {r["id"] for r in rows}
    for i, (ko, rom, de, pos_de, ko_ex, de_ex, en, pos_en, en_ex) in enumerate(NEW_WORDS, start=1):
        ident = f"vocab_a1_{435 + i:04d}"
        assert ident not in ids, ident
        rows.append(new_row(ko, rom, de, pos_de, ko_ex, de_ex, en, pos_en, en_ex, i, i in (8, 9), ident))
    cur = read_json(CURRICULUM)
    assert NEW_PACK_BASE not in cur["vocabPackUnitMap"]
    cur["vocabPackUnitMap"][NEW_PACK_BASE] = NEW_UNIT
    assert f"a1:{NEW_TOPIC}" not in cur["clozeTopicUnitMap"]
    cur["clozeTopicUnitMap"][f"a1:{NEW_TOPIC}"] = NEW_UNIT
    seg = read_json(SEGMENTS)
    cl = [c for c in seg["contentClusters"] if c["id"] == NEW_CLUSTER][0]
    assert NEW_SEED not in cl["sourceSeedIds"]
    cl["sourceSeedIds"].append(NEW_SEED)
    cl["contentReferences"].append({"kind": "vocabPack", "id": NEW_PACK})
    cl["revision"] = int(cl["revision"]) + 1
    auth = read_json(AUTHORITIES)
    assert not any(s["id"] == NEW_SEED for s in auth["sourceSeeds"])
    insert_sorted(auth["sourceSeeds"], {"id": NEW_SEED, "level": "a1"}, key=lambda s: s["id"])
    ref = {"kind": "vocabPack", "id": NEW_PACK, "level": "a1", "sourceSeedId": NEW_SEED, "courseUnitId": NEW_UNIT}
    refs = auth["contentReferences"]
    # keep vocabPack references grouped: insert after the last vocabPack row if the list is grouped by kind
    last = max((i for i, r in enumerate(refs) if r["kind"] == "vocabPack"), default=None)
    kinds_order = [r["kind"] for r in refs]
    if last is not None and kinds_order == sorted(kinds_order, key=kinds_order.index):
        vp = [r for r in refs if r["kind"] == "vocabPack"]
        vp_ids = [r["id"] for r in vp]
        if vp_ids == sorted(vp_ids):
            first = kinds_order.index("vocabPack")
            pos = first + bisect.bisect_left(vp_ids, NEW_PACK)
            refs.insert(pos, ref)
        else:
            refs.insert(last + 1, ref)
    else:
        refs.append(ref)
    auth["coverage"]["directReferenceCounts"]["vocabPack"] += 1
    write_vocab(rows); write_json(CURRICULUM, cur); write_json(SEGMENTS, seg); write_json(AUTHORITIES, auth)
    batch = ROOT / "tool" / "relevel" / "relevel_batch_005.csv"
    with batch.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n"); w.writerow(["id", "korean", "old_level", "new_level", "target_pack", "reason"])
        for ident, ko, old, _src, reason in ADOPTIONS:
            w.writerow([ident, ko, old, "A1", NEW_PACK, reason])
    print("phase b registry written; running relevel_vocab --apply")
    proc = subprocess.run([sys.executable, "tool/relevel_vocab.py", str(batch.relative_to(ROOT)), "--apply"], cwd=ROOT, capture_output=True, text=True)
    print(proc.stdout[-3000:]); print(proc.stderr[-3000:])
    if proc.returncode != 0:
        raise SystemExit(f"relevel failed rc={proc.returncode}")
    print("phase b done")


# ───────────────────────── phase c ─────────────────────────
def phase_c() -> None:
    from relevel_bundle import _refresh_game_meta
    rows = read_vocab(); vid = {r["id"]: r for r in rows}
    pack_rows = sorted([r for r in rows if r["pack_id"] == NEW_PACK], key=lambda r: int(r["pack_order"]))
    assert [r["korean"] for r in pack_rows] == [w[0] for w in NEW_WORDS] + [a[1] for a in ADOPTIONS], [r["korean"] for r in pack_rows]
    for r in pack_rows:
        r["topic"] = NEW_TOPIC
        r["is_review_boss"] = "true" if int(r["pack_order"]) >= 11 else "false"
    j = vid["vocab_b2_0060"]; assert j["korean"] == "전공" and j["level"] == "A1"
    j["example_korean"], j["example_german"], j["example_english"] = JEONGONG_EXAMPLE
    cloze = read_json(CLOZE_JSON); satz = read_json(SATZ_JSON)
    ci = by_id(cloze["items"]); si = by_id(satz["items"])
    s = si["satz_b2_0383"]; assert s["level"] == "a1" and s["vocabKo"] == "전공", s
    s["targetKo"], s["promptDe"], s["promptEn"] = JEONGONG_EXAMPLE
    for sid, ds in MOVED_SATZ_DISTRACTORS.items():
        assert si[sid]["level"] == "a1", sid
        si[sid]["distractors"] = ds
    # new cloze / satz
    def next_id(prefix, items):
        n = max(int(it["id"].rsplit("_", 1)[1]) for it in items if it["id"].startswith(prefix))
        return n + 1
    body = {r["korean"]: r for r in rows if r["pack_id"] == BODY_PACK}
    pack = {r["korean"]: r for r in pack_rows}
    n_c = next_id("cloze_a1_", cloze["items"]); n_s = next_id("satz_a1_", satz["items"])
    new_cloze, new_satz, inh = [], [], []
    def add_cloze(vrow, sentence, answer, ds, topic, unit, segment, source_pack):
        nonlocal n_c
        item = {"id": f"cloze_a1_{n_c:04d}", "level": "a1", "topic": topic, "fullKo": vrow["example_korean"], "answer": answer,
                "sentenceKo": sentence, "de": vrow["example_german"], "en": vrow["example_english"], "distractors": ds, "courseUnitId": unit}
        n_c += 1
        assert sentence.replace(BLANK, answer, 1) == vrow["example_korean"], (sentence, answer, vrow["example_korean"])
        new_cloze.append(item)
        inh.append({"kind": "cloze", "id": item["id"], "sourceKind": "vocabPack", "sourceId": source_pack, "sourceVocabId": vrow["id"],
                    "sourceVocabFingerprintSha256": "0" * 64, "level": "a1", "canDoSegmentId": segment, "courseUnitId": unit})
    def add_satz(vrow, target, de, en, ds, unit, segment, source_pack):
        nonlocal n_s
        item = {"id": f"satz_a1_{n_s:04d}", "level": "a1", "targetKo": target, "promptDe": de, "promptEn": en, "vocabKo": vrow["korean"], "distractors": ds, "courseUnitId": unit}
        n_s += 1
        new_satz.append(item)
        inh.append({"kind": "satz", "id": item["id"], "sourceKind": "vocabPack", "sourceId": source_pack, "sourceVocabId": vrow["id"],
                    "sourceVocabFingerprintSha256": "0" * 64, "level": "a1", "canDoSegmentId": segment, "courseUnitId": unit})
    for ko, sentence, answer, ds in BODY_CLOZE:
        add_cloze(body[ko], sentence, answer, ds, "Körper", BODY_UNIT, BODY_SEGMENT, BODY_PACK)
    for ko, target, de, en, ds in BODY_SATZ:
        add_satz(body[ko], target, de, en, ds, BODY_UNIT, BODY_SEGMENT, BODY_PACK)
    for r in pack_rows:
        sentence, answer, ds = PACK_CLOZE[r["korean"]]
        add_cloze(r, sentence, answer, ds, NEW_TOPIC, NEW_UNIT, NEW_SEGMENT, NEW_PACK)
    for r in pack_rows[:9]:
        add_satz(r, r["example_korean"], r["example_german"], r["example_english"], PACK_SATZ_DISTRACTORS[r["korean"]], NEW_UNIT, NEW_SEGMENT, NEW_PACK)
    cloze["items"].extend(new_cloze); satz["items"].extend(new_satz)
    _refresh_game_meta(cloze, "items"); _refresh_game_meta(satz, "items")
    probs = [p for p in check_cloze_contract(cloze["items"], particle_ids={it["id"] for it in new_cloze}) if not any(k in p for k in KNOWN_CLOZE_EXPOSED)]
    sp = check_satz_contract(satz["items"])
    print("cloze problems:", probs, "\nsatz problems:", sp)
    if probs or sp:
        raise SystemExit("contract problems — nothing written")
    # inherited rows
    auth = read_json(AUTHORITIES)
    lst = auth["coverage"]["inheritedContentReferences"]
    existing = {(r["kind"], r["id"]) for r in lst}
    for row in inh:
        assert (row["kind"], row["id"]) not in existing
        insert_sorted(lst, row, key=lambda x: (x["kind"], x["id"]))
    for kind in ("cloze", "satz"):
        auth["coverage"]["inheritedReferenceCounts"][kind] = sum(1 for r in lst if r["kind"] == kind)
    # moved satz rows must now point at the new pack (relevel step 3)
    for sid in ("satz_b2_0383", "satz_b1_0425", "satz_b1_0450"):
        r = [x for x in lst if x["kind"] == "satz" and x["id"] == sid][0]
        assert r["sourceId"] == NEW_PACK and r["courseUnitId"] == NEW_UNIT and r["canDoSegmentId"] == NEW_SEGMENT and r["level"] == "a1", r
    # audit manifest counts
    man = read_json(AUDIT_MANIFEST)
    counts = {"vocab": len(rows), "cloze": len(cloze["items"]), "satz": len(satz["items"])}
    for src in man["sources"]:
        if src["kind"] in counts:
            src["count"] = counts[src["kind"]]
    write_vocab(rows); write_json(CLOZE_JSON, cloze); write_json(SATZ_JSON, satz); write_json(AUTHORITIES, auth); write_json(AUDIT_MANIFEST, man)
    print("counts:", counts, "new cloze", len(new_cloze), "new satz", len(new_satz))
    # drafts + review ledgers
    drafts = CF / "drafts"; review = CF / "review"
    with (drafts / "c3_batch23_first_class_a1.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator="\n"); w.writeheader(); w.writerows(pack_rows)
    with (review / "c3_batch23_first_class_a1.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n"); w.writerow(["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"])
        for r in pack_rows:
            moved = r["id"] in {a[0] for a in ADOPTIONS}
            note = (f"rights: original_clean_room; pack={NEW_PACK}; order={r['pack_order']}; boss={r['is_review_boss']}; "
                    + ("relevel_batch_005 이동(B1/B2→A1, id 불변)" + ("; 예문 교체(제 전공은 음악이에요.)" if r["korean"] == "전공" else "; 예문 불변") if moved
                       else "seed: NIKL 1급 목록(KOGL 1유형) 표제어 선택만"))
            w.writerow([r["id"], "A1", r["korean"], r["german"], r["english"], note, "approved", MEMO])
    write_json(drafts / "c2_batch23_cloze_a1_units.json", {"items": new_cloze})
    with (review / "c2_batch23_cloze_a1_units.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n"); w.writerow(["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"])
        for it, row in zip(new_cloze, [x for x in inh if x["kind"] == "cloze"]):
            w.writerow([it["id"], "a1", it["fullKo"], it["de"], it["en"], f"answer={it['answer']}; topic={it['topic']}; unit={it['courseUnitId']}; derived from {row['sourceVocabId']}", "approved", MEMO])
    write_json(drafts / "c2_batch23_satz_a1_units.json", {"items": new_satz})
    with (review / "c2_batch23_satz_a1_units.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n"); w.writerow(["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"])
        for it, row in zip(new_satz, [x for x in inh if x["kind"] == "satz"]):
            w.writerow([it["id"], "a1", it["targetKo"], it["promptDe"], it["promptEn"], f"vocabKo={it['vocabKo']}; unit={it['courseUnitId']}; source {row['sourceVocabId']}", "approved", MEMO])
    print("phase c written; refreshing fingerprints")
    proc = subprocess.run([sys.executable, "tool/refresh_can_do_vocab_fingerprints.py"], cwd=ROOT, capture_output=True, text=True)
    print(proc.stdout[-1500:], proc.stderr[-1500:])
    if proc.returncode != 0:
        raise SystemExit("fingerprint refresh failed")
    from relevel_bundle import check_can_do_consistency
    issues = check_can_do_consistency(ROOT)
    print("can-do consistency issues:", issues)
    from relevel_vocab import write_pack_map
    write_pack_map(read_vocab(), ROOT / "docs" / "data" / "vocab_pack_map.md")
    print("phase c done")


BODY_CLOZE_EXTRA = [
    # course cloze target is 10 per unit (COURSE_TARGETS), so a1_10 needs two
    # more a1_body-derived items after the first six.
    ("귀", "귀가 좀 ＿＿＿.", "아파요", ["마셔요", "읽어요", "사요"]),
    ("눈", "오늘 눈이 좀 ＿＿＿.", "피곤하네요", ["먹어요", "읽어요", "가요"]),
]


def phase_c2() -> None:
    """Incremental: two more a1_10 cloze items on top of phase c."""
    from relevel_bundle import _refresh_game_meta, check_can_do_consistency
    rows = read_vocab()
    body = {r["korean"]: r for r in rows if r["pack_id"] == BODY_PACK}
    cloze = read_json(CLOZE_JSON)
    n = max(int(it["id"].rsplit("_", 1)[1]) for it in cloze["items"] if it["id"].startswith("cloze_a1_")) + 1
    new_items, inh = [], []
    for ko, sentence, answer, ds in BODY_CLOZE_EXTRA:
        v = body[ko]
        assert sentence.replace(BLANK, answer, 1) == v["example_korean"], (sentence, v["example_korean"])
        item = {"id": f"cloze_a1_{n:04d}", "level": "a1", "topic": "Körper", "fullKo": v["example_korean"], "answer": answer,
                "sentenceKo": sentence, "de": v["example_german"], "en": v["example_english"], "distractors": ds, "courseUnitId": BODY_UNIT}
        n += 1
        new_items.append(item)
        inh.append({"kind": "cloze", "id": item["id"], "sourceKind": "vocabPack", "sourceId": BODY_PACK, "sourceVocabId": v["id"],
                    "sourceVocabFingerprintSha256": "0" * 64, "level": "a1", "canDoSegmentId": BODY_SEGMENT, "courseUnitId": BODY_UNIT})
    cloze["items"].extend(new_items)
    _refresh_game_meta(cloze, "items")
    probs = [p for p in check_cloze_contract(cloze["items"], particle_ids={it["id"] for it in new_items}) if not any(k in p for k in KNOWN_CLOZE_EXPOSED)]
    if probs:
        raise SystemExit(f"contract problems: {probs}")
    auth = read_json(AUTHORITIES)
    lst = auth["coverage"]["inheritedContentReferences"]
    for row in inh:
        insert_sorted(lst, row, key=lambda x: (x["kind"], x["id"]))
    auth["coverage"]["inheritedReferenceCounts"]["cloze"] = sum(1 for r in lst if r["kind"] == "cloze")
    man = read_json(AUDIT_MANIFEST)
    for src in man["sources"]:
        if src["kind"] == "cloze":
            src["count"] = len(cloze["items"])
    write_json(CLOZE_JSON, cloze); write_json(AUTHORITIES, auth); write_json(AUDIT_MANIFEST, man)
    drafts = CF / "drafts"; review = CF / "review"
    d = read_json(drafts / "c2_batch23_cloze_a1_units.json"); d["items"].extend(new_items); write_json(drafts / "c2_batch23_cloze_a1_units.json", d)
    with (review / "c2_batch23_cloze_a1_units.csv").open("a", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        for it, row in zip(new_items, inh):
            w.writerow([it["id"], "a1", it["fullKo"], it["de"], it["en"], f"answer={it['answer']}; topic={it['topic']}; unit={it['courseUnitId']}; derived from {row['sourceVocabId']}", "approved", MEMO])
    proc = subprocess.run([sys.executable, "tool/refresh_can_do_vocab_fingerprints.py"], cwd=ROOT, capture_output=True, text=True)
    print(proc.stdout[-500:], proc.stderr[-500:])
    print("can-do consistency issues:", check_can_do_consistency(ROOT))
    print("cloze total:", len(cloze["items"]), "new:", [it["id"] for it in new_items])


def phase_relevel() -> None:
    """Registry files are already written by phase b; the validator pins the
    audit-manifest vocab count to the CSV row count, so bump it first and then
    apply relevel_batch_005."""
    rows = read_vocab()
    man = read_json(AUDIT_MANIFEST)
    for src in man["sources"]:
        if src["kind"] == "vocab":
            src["count"] = len(rows)
    write_json(AUDIT_MANIFEST, man)
    batch = ROOT / "tool" / "relevel" / "relevel_batch_005.csv"
    proc = subprocess.run([sys.executable, "tool/relevel_vocab.py", str(batch.relative_to(ROOT)), "--apply"], cwd=ROOT, capture_output=True, text=True)
    print(proc.stdout[-4000:]); print(proc.stderr[-3000:])
    if proc.returncode != 0:
        raise SystemExit(f"relevel failed rc={proc.returncode}")
    print("relevel applied")


if __name__ == "__main__":
    {"a": phase_a, "b": phase_b, "r": phase_relevel, "c": phase_c, "c2": phase_c2}[sys.argv[1]]()
