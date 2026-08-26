"""콘텐츠 자연성 프리필터.

결정적 규칙(정규식·문자열 포함·받침 유무) 기반 마커로 부자연스러운 한국어
문장 후보를 코퍼스 7종에서 검출해 `docs/data/naturalness_candidates.md` 에
기록한다. Task 12(LLM 심사)의 입력 — 여기서 잡히는 것은 전부 "후보"이며
실제 어색함 여부는 사람/LLM 판단이 필요하다.

임포트 계약 (Task 4 등 tools/content_factory 배치 생성기용)
--------------------------------------------------------------
이 파일 상단의 `check_*` / `find_particle_after_blank` / `has_batchim` /
`MARKER_NAMES` 는 **순수 함수** 다 — 파일 I/O 가 전혀 없고, 텍스트(와 필요한
경우 level/answer 등 스칼라)를 받아 마커 히트 여부/목록만 돌려준다. 생성
파이프라인은 문장을 만든 직후 이 함수들을 게이트로 바로 호출할 수 있다.

`scan_*` 함수들은 I/O(assets/data 하위 JSON·CSV 읽기)를 수행하는 별도 계층이고,
`main()` 이 `if __name__ == "__main__":` 가드 아래에서만 코퍼스 전체 스캔과
리포트 파일 쓰기를 수행한다 — 즉 `import audit_content_naturalness` 만으로는
아무 파일도 건드리지 않는다.

형제 트리 임포트 (tools/content_factory 쪽에서):
    import os, sys
    sys.path.insert(0, os.path.join(REPO_ROOT, "tool"))
    import audit_content_naturalness as naturalness_audit
    hits = naturalness_audit.check_generic_markers(text, level)

`tool/` 를 `sys.path` 에 추가하는 한 줄이 필요한 최소한의 sys.path 조작이다 —
패키지화(`tool/__init__.py` 추가)는 이 저장소의 다른 `tool/*.py` 스크립트들과
레이아웃을 깨뜨리므로 하지 않았다.
"""

from __future__ import annotations

import csv
import json
import os
import re
import sys
from collections import Counter
from dataclasses import dataclass
from typing import Iterable, Iterator, Optional

# ---------------------------------------------------------------------------
# 경로
# ---------------------------------------------------------------------------

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(ROOT, "assets", "data")
REPORT_PATH = os.path.join(ROOT, "docs", "data", "naturalness_candidates.md")

# ---------------------------------------------------------------------------
# 상수 — 코드포인트로 명시해 소스 인코딩에 무관하게 항상 같은 문자를 가리키게 함
# ---------------------------------------------------------------------------

BLANK = chr(0xFF3F) * 3  # cloze 빈칸 마커 "＿＿＿" (fullwidth low line x3, 정확히 3자)
CIRCLE = chr(0x25EF)  # silben_puzzles exampleKo 마스킹 문자 "◯" (LARGE CIRCLE)

_HANGUL_SYLLABLE_RE = re.compile(r"[가-힣]")

# 조사 → 요구되는 받침 유무 (True=받침 있어야 자연스러움, False=받침 없어야 자연스러움)
PARTICLE_BATCHIM = {
    "이": True,
    "은": True,
    "을": True,
    "가": False,
    "는": False,
    "를": False,
}

MARKER_NAMES = (
    "dangling_stem",
    "particle_mismatch",
    "passive_pileup",
    "e_daehae",
    "josa_dup",
    "formality_mix",
    "level_length",
    "answer_repeat",
)


# ---------------------------------------------------------------------------
# 순수 마커 함수 — text/item 입력, 마커 히트 출력. 파일 I/O 없음.
# ---------------------------------------------------------------------------


def has_batchim(word: str) -> Optional[bool]:
    """`word` 마지막 글자의 받침 유무. 완성형 한글 음절이 아니면 None.

    유니코드 한글 음절 분해식: (코드포인트 - 0xAC00) % 28 == 0 이면 받침 없음.
    """
    word = (word or "").strip()
    if not word:
        return None
    code = ord(word[-1]) - 0xAC00
    if 0 <= code < 11172:
        return (code % 28) != 0
    return None


def check_passive_pileup(text: str) -> bool:
    """`되어지`·`지게 되` 이중 피동/사동 겹침 포함 여부."""
    return "되어지" in text or "지게 되" in text


def check_e_daehae(text: str) -> bool:
    """`에 대해` 가 한 문장에 2회 이상."""
    return text.count("에 대해") >= 2


def check_josa_dup(text: str) -> bool:
    """조사 연쇄 오타 `을를`·`이가`·`은는` 포함 여부."""
    return ("을를" in text) or ("이가" in text) or ("은는" in text)


# 종결 어미 뒤에 문장부호/닫는 인용부호/공백/문자열 끝이 와야 "종결"로 인정한다.
# (예: "습니다만" 은 종결이 아니므로 제외, "필요해요." 는 종결로 인정)
_NIDA_END_RE = re.compile(r"니다(?=$|[.!?…」』\"'\s])")
_YO_END_RE = re.compile(r"요(?=$|[.!?…」』\"'\s])")

_JONGSEONG_BIEUP_INDEX = 17  # 28개 종성 표에서 ㅂ 받침의 인덱스


def _is_bnida_formal_ending(text: str, nida_start: int) -> bool:
    """`니다` 바로 앞 음절이 ㅂ받침으로 끝나는지 — `-습니다`/`-ㅂ니다` 계열
    formal 종결어미 전부(습니다·합니다·갑니다·됩니다 등)를 하나의 규칙으로
    판정한다.

    `습니다` 자체도 습(스+ㅂ받침)+니+다 이므로 이 규칙의 특수한 한 사례일
    뿐이다 — 브리프 표기는 `~습니다` 지만 문자열 그대로만 찾으면 `합니다`·
    `감사합니다`처럼 아주 흔한 -하다 동사의 formal 종결(하+ㅂ니다→합니다)을
    전부 놓친다. 한글 음절 분해식으로 일반화해 이 계열 전체를 잡는다.
    """
    if nida_start <= 0:
        return False
    prev = text[nida_start - 1]
    code = ord(prev) - 0xAC00
    if not (0 <= code < 11172):
        return False
    return (code % 28) == _JONGSEONG_BIEUP_INDEX


def check_formality_mix(text: str) -> bool:
    """한 문장(텍스트) 안에 `~습니다`(및 `~ㅂ니다` 계열) 종결과 `~요` 종결이
    혼재하는지."""
    has_formal = any(
        _is_bnida_formal_ending(text, m.start()) for m in _NIDA_END_RE.finditer(text)
    )
    return has_formal and bool(_YO_END_RE.search(text))


_LEVEL_LENGTH_LIMITS = {"a1": 40, "a2": 60}


def check_level_length(text: str, level: Optional[str]) -> bool:
    """a1 문장 40자 초과, a2 문장 60자 초과 (그 외 레벨은 이 마커 대상 아님)."""
    if not level:
        return False
    limit = _LEVEL_LENGTH_LIMITS.get(level.strip().lower())
    if limit is None:
        return False
    return len(text) > limit


def check_answer_repeat(full_ko: str, answer: str) -> bool:
    """fullKo 안에 answer 가 2회 이상 등장 (cloze 전용)."""
    answer = (answer or "").strip()
    if not answer:
        return False
    return full_ko.count(answer) >= 2


def check_dangling_stem(answer: str, vocab_headwords: Iterable[str]) -> bool:
    """cloze answer 절단(dangling stem) 검출 (cloze 전용).

    규칙: answer 가 `하`/`되` 로 끝나고, `answer + "다"` 가 실제로
    korean_vocab.csv 표제어(korean 열)로 존재하면 — 그 표제어가 원래
    `~하다`/`~되다` 동사인데 cloze 생성 시 answer 가 어간에서 절단됐을
    가능성이 높다 (예: "절하다" 의 answer 가 "절하" 로 잘림).

    `vocab_headwords` 는 멤버십 테스트가 O(1) 이면 무엇이든 된다 — 스캔 쪽은
    set 을 넘기지만, 순수 함수 자체는 set 타입에 의존하지 않는다.
    """
    answer = (answer or "").strip()
    if not (answer.endswith("하") or answer.endswith("되")):
        return False
    return (answer + "다") in vocab_headwords


def find_particle_after_blank(sentence_ko: str, blank: str = BLANK) -> Optional[str]:
    """`sentence_ko` 에서 빈칸(`blank`) 바로 뒤에 오는 조사 1글자.

    조사 후보(이/가·은/는·을/를)가 아니면 None 을 돌려준다 — 그 경우
    particle_mismatch 는 검사 대상이 아니다(해당 문장 구조가 아니므로).
    """
    idx = sentence_ko.find(blank)
    if idx < 0:
        return None
    rest = sentence_ko[idx + len(blank):]
    if not rest:
        return None
    ch = rest[0]
    return ch if ch in PARTICLE_BATCHIM else None


def check_particle_mismatch(
    sentence_ko: str, distractors: Iterable[str]
) -> list:
    """빈칸 뒤 조사와 받침이 불합치하는 distractor 목록 (cloze 전용).

    빈 리스트 = 히트 없음(조사 자체가 대상 조사 집합 밖이거나, 모든
    distractor 의 받침이 조사와 합치).
    """
    particle = find_particle_after_blank(sentence_ko)
    if particle is None:
        return []
    required = PARTICLE_BATCHIM[particle]
    mismatched = []
    for d in distractors:
        bc = has_batchim(d)
        if bc is None:
            continue  # 완성형 한글 음절로 안 끝나면 판단 보류(오탐 방지)
        if bc != required:
            mismatched.append(d)
    return mismatched


# 공통 5종 마커 — (텍스트, 레벨) 을 받는 임의 corpus 텍스트에 전부 적용 가능.
_GENERIC_CHECKS = (
    ("passive_pileup", lambda text, level: check_passive_pileup(text)),
    ("e_daehae", lambda text, level: check_e_daehae(text)),
    ("josa_dup", lambda text, level: check_josa_dup(text)),
    ("formality_mix", lambda text, level: check_formality_mix(text)),
    ("level_length", lambda text, level: check_level_length(text, level)),
)


def check_generic_markers(text: str, level: Optional[str]) -> list:
    """공통 5종 마커(passive_pileup·e_daehae·josa_dup·formality_mix·level_length)
    를 모두 적용해 히트한 마커 이름의 리스트를 돌려준다(결정적 순서)."""
    if not text:
        return []
    return [name for name, fn in _GENERIC_CHECKS if fn(text, level)]


# ---------------------------------------------------------------------------
# 결과 레코드
# ---------------------------------------------------------------------------


@dataclass(frozen=True, order=True)
class Hit:
    source_file: str
    id: str
    marker: str
    sentence: str


# ---------------------------------------------------------------------------
# I/O 헬퍼 (스캔 계층 전용 — 순수 함수 아님)
# ---------------------------------------------------------------------------


def _load_json(name: str):
    with open(os.path.join(DATA_DIR, name), encoding="utf-8") as f:
        return json.load(f)


def _load_vocab_headwords() -> set:
    headwords = set()
    with open(
        os.path.join(DATA_DIR, "korean_vocab.csv"), encoding="utf-8", newline=""
    ) as f:
        for row in csv.DictReader(f):
            w = (row.get("korean") or "").strip()
            if w:
                headwords.add(w)
    return headwords


def _study_phrases(cell: Optional[str]) -> list:
    """grammar.csv 예문 셀을 발화 단위(구절)로 쪼갠다.

    tool/generate_tts.py:235-240 `_study_phrases` 와 동일 규칙(그 함수의
    docstring 코멘트 참고) — 앱이 화면에 읽어주는 단위와 맞추기 위해
    " / " 우선, 없으면 "|", 둘 다 없으면 셀 전체가 한 구절이다. 이 규칙을
    재사용하지 않으면 다예문 행(예: "갔어요. / 먹었어요. / 했어요.")이
    하나의 뭉친 문장으로 취급돼 level_length 등 문장 단위 마커가 왜곡된다.
    """
    raw = (cell or "").strip()
    if not raw:
        return []
    parts = raw.split(" / ") if " / " in raw else raw.split("|")
    return [p.strip() for p in parts if p.strip()]


def _walk_ko_paths(node, path: str = "") -> Iterator:
    """키가 정확히 `ko` 인 모든 문자열 리프를 (경로, 텍스트) 로 순회한다.

    tool/generate_tts.py:258-269 의 `_walk_ko` 재귀 규칙을 그대로 재사용
    (스몰토크 TTS 수집에 쓰이는 바로 그 로직) — 여기서는 TTS 캐시 키 대신
    리포트용 경로 문자열을 같이 만든다.
    """
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "ko" and isinstance(value, str):
                yield (path or "ko", value)
            else:
                child = f"{path}.{key}" if path else key
                yield from _walk_ko_paths(value, child)
    elif isinstance(node, list):
        for i, value in enumerate(node):
            child = f"{path}[{i}]" if path else f"[{i}]"
            yield from _walk_ko_paths(value, child)


def _walk_quest_ko(node, path: str = "") -> Iterator:
    """시나리오 퀘스트(`quest.data`) 안의 한국어 필드를 (경로, 텍스트) 로 순회한다.

    dialog 는 `_walk_ko_paths` 처럼 키가 정확히 `ko` 하나뿐이라 단순하지만,
    퀘스트 데이터는 엔진별로 필드 이름이 제각각이다(§ tool/generate_tts.py:299-325
    가 만든 엔진별 audioKo/targetKo 파생 규칙 참고). 이 리포트는 생성 로직을
    복제하는 대신 **필드 이름 규약**으로 한국어 필드를 인식한다:
      - 키가 정확히 `ko` (예: uebersetzen `options[].ko`)
      - 키가 `Ko` 로 끝남 (예: `audioKo`, `targetKo`)
      - 키가 정확히 `sentence` 이고 값에 한글 음절이 있음 (luecken 빈칸 문장,
        블랭크가 cloze 의 `＿＿＿` 가 아니라 `___` 라 복원하지 않고 그대로 검사)
    `particlePop` 퀘스트(`prefix`/`suffix`/`options[correctIndex]`)는 이 규약
    밖이라 `scan_scenarios` 가 `_particle_pop_sentence` 로 별도 재구성해
    처리한다 — 호출측에서 그 타입은 이 함수로 넘기지 않는다.
    한계는 리포트 요약에 명시한다(예: luecken 블랭크 미복원).
    """
    if isinstance(node, dict):
        for key, value in node.items():
            if isinstance(value, str):
                is_ko_field = (
                    key == "ko"
                    or key.endswith("Ko")
                    or (key == "sentence" and _HANGUL_SYLLABLE_RE.search(value))
                )
                if is_ko_field:
                    yield (f"{path}.{key}" if path else key, value)
                    continue
            child = f"{path}.{key}" if path else key
            yield from _walk_quest_ko(value, child)
    elif isinstance(node, list):
        for i, value in enumerate(node):
            child = f"{path}[{i}]" if path else f"[{i}]"
            yield from _walk_quest_ko(value, child)


def _restore_silben_example(example_ko: str, answer: str) -> str:
    """silben_puzzles exampleKo 의 `◯` 연속을 answer 로 복원한 완성 문장.

    ◯ 가 없으면(마스킹 없이 원문 그대로 저장된 항목, 415건 중 51건 확인)
    example_ko 를 그대로 돌려준다.
    """
    if CIRCLE not in example_ko or not answer:
        return example_ko
    return re.sub(re.escape(CIRCLE) + "+", lambda _m: answer, example_ko, count=1)


# ---------------------------------------------------------------------------
# 스캔 함수 — 코퍼스 7종. 전부 Hit 을 yield 하는 제너레이터.
# ---------------------------------------------------------------------------


def scan_korean_vocab() -> Iterator[Hit]:
    source = "korean_vocab.csv"
    with open(
        os.path.join(DATA_DIR, source), encoding="utf-8", newline=""
    ) as f:
        for row in csv.DictReader(f):
            text = (row.get("example_korean") or "").strip()
            if not text:
                continue
            item_id = row.get("id") or row.get("korean") or "?"
            level = row.get("level")
            for marker in check_generic_markers(text, level):
                yield Hit(source, item_id, marker, text)


def scan_grammar() -> Iterator[Hit]:
    source = "grammar.csv"
    with open(
        os.path.join(DATA_DIR, source), encoding="utf-8", newline=""
    ) as f:
        for row in csv.DictReader(f):
            phrases = _study_phrases(row.get("example_korean"))
            if not phrases:
                continue
            row_id = row.get("id") or row.get("pattern") or "?"
            level = row.get("level")
            multi = len(phrases) > 1
            for i, text in enumerate(phrases):
                item_id = f"{row_id}#{i}" if multi else row_id
                for marker in check_generic_markers(text, level):
                    yield Hit(source, item_id, marker, text)


def scan_cloze() -> Iterator[Hit]:
    source = "cloze.json"
    data = _load_json(source)
    vocab_headwords = _load_vocab_headwords()
    for item in data.get("items", []):
        item_id = item.get("id") or "?"
        level = item.get("level")
        full_ko = (item.get("fullKo") or "").strip()
        sentence_ko = item.get("sentenceKo") or ""
        answer = item.get("answer") or ""
        distractors = item.get("distractors") or []

        for marker in check_generic_markers(full_ko, level):
            yield Hit(source, item_id, marker, full_ko)

        if check_dangling_stem(answer, vocab_headwords):
            yield Hit(source, item_id, "dangling_stem", f'{full_ko} (answer="{answer}")')

        if check_answer_repeat(full_ko, answer):
            yield Hit(source, item_id, "answer_repeat", f'{full_ko} (answer="{answer}")')

        mismatched = check_particle_mismatch(sentence_ko, distractors)
        if mismatched:
            yield Hit(
                source,
                item_id,
                "particle_mismatch",
                f"{sentence_ko} (distractor: {', '.join(mismatched)})",
            )


def scan_satz() -> Iterator[Hit]:
    source = "satz_sentences.json"
    data = _load_json(source)
    for item in data.get("items", []):
        text = (item.get("targetKo") or "").strip()
        if not text:
            continue
        item_id = item.get("id") or "?"
        for marker in check_generic_markers(text, item.get("level")):
            yield Hit(source, item_id, marker, text)


def scan_smalltalk() -> Iterator[Hit]:
    source = "smalltalk.json"
    data = _load_json(source)
    for phrase in data.get("phrases", []):
        phrase_id = phrase.get("id") or "?"
        level = phrase.get("level")
        for path, text in _walk_ko_paths(phrase):
            text = text.strip()
            if not text:
                continue
            item_id = phrase_id if path == "ko" else f"{phrase_id}#{path}"
            for marker in check_generic_markers(text, level):
                yield Hit(source, item_id, marker, text)


def _load_scenario_shards() -> list:
    return sorted(
        name
        for name in os.listdir(DATA_DIR)
        if name.startswith("scenarios_") and name.endswith(".json")
    )


def _particle_pop_sentence(qdata: dict) -> str:
    """particlePop 퀘스트의 완성 문장 = prefix + options[correctIndex] + suffix.

    tool/generate_tts.py:307-308 (particle_pop_quest.dart:59 `_fullSentence` 와
    동일 파생 규칙)을 그대로 재사용 — `prefix`/`suffix` 는 `ko`/`*Ko`/`sentence`
    필드명 규약 밖이라 `_walk_quest_ko` 만으로는 안 잡히므로 별도 처리한다.
    """
    options = qdata.get("options") or []
    try:
        idx = int(qdata.get("correctIndex") or 0)
    except (TypeError, ValueError):
        return ""
    if not (0 <= idx < len(options)):
        return ""
    prefix = qdata.get("prefix") or ""
    suffix = qdata.get("suffix") or ""
    return f"{prefix}{options[idx]}{suffix}"


def scan_scenarios() -> Iterator[Hit]:
    source = "scenarios_*.json"
    for shard_name in _load_scenario_shards():
        data = _load_json(shard_name)
        scenarios = data.get("scenarios", []) if isinstance(data, dict) else data
        for sc in scenarios or []:
            sc_id = sc.get("id") or "?"
            level = sc.get("level")

            for i, turn in enumerate(sc.get("dialog", [])):
                text = (turn.get("ko") or "").strip()
                if not text:
                    continue
                item_id = f"{sc_id}#dialog[{i:02d}]"
                for marker in check_generic_markers(text, level):
                    yield Hit(source, item_id, marker, text)

            for qi, quest in enumerate(sc.get("quests", [])):
                quest_id = quest.get("id") or f"quest[{qi:02d}]"
                qdata = quest.get("data") or {}

                if quest.get("type") == "particlePop":
                    text = _particle_pop_sentence(qdata).strip()
                    if text:
                        item_id = f"{sc_id}#{quest_id}.particlePop"
                        for marker in check_generic_markers(text, level):
                            yield Hit(source, item_id, marker, text)
                    continue  # prefix/suffix 는 _walk_quest_ko 규약 밖이라 중복 스캔 없음

                # 리뷰 라운드 1 Important: satzBauen/diktat 류는 targetKo 와
                # audioKo 가 같은 문장을 그대로 반복해서 담는 경우가 흔하다
                # (예: audioKo = targetKo 그대로 복사, TTS 재생용). 필드명이
                # 달라 _walk_quest_ko 는 둘 다 별개 항목으로 yield 하므로,
                # 같은 퀘스트 안에서 이미 나온 문자열과 완전히 같으면 두 번째
                # 이후는 건너뛴다 — 같은 마커 히트가 같은 문장으로 두 번 실려
                # Task 12 LLM 심사가 같은 후보를 중복 처리하는 걸 막는다.
                # (JSON 필드 순서상 targetKo 가 audioKo 보다 먼저 나와 보통
                # targetKo 쪽이 남고 audioKo 쪽이 스킵된다.)
                seen_texts = set()
                for path, text in _walk_quest_ko(qdata):
                    text = text.strip()
                    if not text or text in seen_texts:
                        continue
                    seen_texts.add(text)
                    item_id = f"{sc_id}#{quest_id}.{path}"
                    for marker in check_generic_markers(text, level):
                        yield Hit(source, item_id, marker, text)


def scan_silben() -> Iterator[Hit]:
    source = "silben_puzzles.json"
    data = _load_json(source)
    for level_key, puzzles in (data.get("levels") or {}).items():
        level = (level_key or "").lower()
        for puzzle in puzzles:
            puzzle_id = puzzle.get("id") or "?"
            for word in puzzle.get("words", []):
                answer = word.get("answer") or ""
                example = word.get("exampleKo") or ""
                restored = _restore_silben_example(example, answer)
                if not restored:
                    continue
                item_id = f"{puzzle_id}#{word.get('dir')}{word.get('row')}{word.get('col')}"
                for marker in check_generic_markers(restored, level):
                    yield Hit(source, item_id, marker, restored)


# 브리프 Step 1 이 나열한 코퍼스 7종 — 히트가 0건이어도 리포트에 섹션을
# 낸다(스캔은 됐지만 후보가 없었다는 사실 자체가 정보다).
SOURCE_FILES = (
    "cloze.json",
    "grammar.csv",
    "korean_vocab.csv",
    "satz_sentences.json",
    "scenarios_*.json",
    "silben_puzzles.json",
    "smalltalk.json",
)


def scan_all() -> list:
    hits = []
    hits.extend(scan_korean_vocab())
    hits.extend(scan_cloze())
    hits.extend(scan_satz())
    hits.extend(scan_smalltalk())
    hits.extend(scan_scenarios())
    hits.extend(scan_silben())
    hits.extend(scan_grammar())
    hits.sort(key=lambda h: (h.source_file, h.id, h.marker, h.sentence))
    return hits


# ---------------------------------------------------------------------------
# 리포트 작성
# ---------------------------------------------------------------------------

RETRO_NOTE = """### 시드 5건 회고 노트 (Task 2 에서 교정 완료, 교정 전 상태 기준)

Task 2(커밋 `55b703cc`/`1a2c67eb`/`2a235db5`)가 이미 고친 시드 5건은 이제
코퍼스에 없으므로 아래 표에는 나타나지 않는다. 어떤 마커가 교정 *전* 형태를
잡았을지 회고:

- **절하 (cloze_a1_0154)**: 교정 전 answer `절하` (완결 어절 아님, "절하다"
  절단) → **dangling_stem** 이 잡았을 것 (`절하` 가 `하` 로 끝나고
  `절하다` 가 CSV 표제어로 존재). 부수적으로 당시 distractor `성함을 묻`
  (조각, "묻"=받침 있음)도 당시 sentenceKo 조사 `는`(받침 없음 요구)과
  불합치해 **particle_mismatch** 가 함께 잡았을 것 — 다만 이건 "조각 오답"
  이라는 진짜 결함과는 별개의 우연한 포착.
- **이모티콘 (cloze_a1_0192)**: 교정 전 distractor `형부`(모음 끝) vs
  sentenceKo `＿＿＿은`(받침 필요) → **particle_mismatch** 가 잡았을 것.
  이후 1차 교정에서 대체 후보로 잘못 고른 `소포`(역시 모음 끝, 리뷰
  라운드 1에서 재수정됨)도 같은 이유로 **particle_mismatch** 가 잡았을
  것 — 이 마커가 리뷰에서 발견된 재발 결함까지 커버함을 보여준다.
- **층간소음 (cloze_a1_0239)**: 교정 전 distractor `복도`(모음 끝) vs
  sentenceKo `＿＿＿을`(받침 필요) → **particle_mismatch** 가 잡았을 것.
- **시아버지 (cloze_a1_0104)**: 교정 전 결함은 두 가지 — (a) 문맥 없이는
  어떤 웃어른도 답이 되는 **모호성**, (b) "현관까지 나오셨어요"라는 서술의
  **어투 이질감**(지시서 항목 7). 둘 다 이번 8개 마커 중 어느 것도 잡지
  못한다 — 결정적 패턴/받침 규칙으로는 검출 불가능한 의미·화용 층위의
  결함이라 Task 12 LLM 심사가 필요한 전형적 사례로 남겨둔다.
- **일정 충돌 (cloze_b1_0172)**: 교정 전 "충돌이 나자"→"충돌이 생겨서"
  (어색한 연어), "전화했어요"→"전화드렸어요"(존대 일관성 — `습니다`/`요`
  혼재가 아니라 같은 `-요` 등급 안에서의 압존법 불일치)는 둘 다 8개 마커
  범위 밖이다. formality_mix 는 `습니다`/`ㅂ니다` 계열 vs `요` **종결형
  혼재**만 잡도록 설계돼 있어 이 사례처럼 같은 종결형(`-요`) 안에서 존대
  대상이 달라지는 결함은 검출하지 못한다 — 마찬가지로 Task 12 심사 대상.
  **다만 이 항목은 이번 스캔이 별도로 살아있는 결함 1건을 새로 찾아냈다**:
  당시 distractor `방문 순서`(받침 없는 "서"로 끝남)가 빈칸 뒤 조사
  `이`(받침 필요)와 불합치 — Task 2 는 이 세 distractor 를 "형태 가능·
  문맥 불가 충족"으로 판단해 그대로 뒀지만 받침 정합은 별도로 검토되지
  않았었다. 즉 이 마커는 "교정 전" 회고용일 뿐 아니라 **Task 2 가 놓친
  결함**도 실제로 찾아냈다 — 이 리포트 최초 발행 직후 커밋 `319db213`
  (`fix(content): cloze_b1_0172 distractor 조사 정합 — 방문 순서 교체`,
  Task 3 가 아닌 별도 세션이 이 리포트를 보고 바로 반영)으로 이미 교정돼
  `방문 순서`→`명절 당번`(받침 있음)이 됐다 — 그래서 이 코퍼스를 다시
  스캔하면 더는 particle_mismatch 로 잡히지 않는다. 프리필터→즉시 수정
  이라는 의도된 순환이 실제로 작동한 사례로 남겨둔다.

결론: 8개 마커 중 정량적(받침·문자열·길이) 판정이 가능한 절하·이모티콘·
층간소음 3건은 재현 가능하게 잡히고(그리고 일정충돌도 별도 결함으로
잡힌다), 의미·화용 판단이 필요한 시아버지·일정충돌의 존대/연어 이슈는
설계상 이 프리필터의 범위 밖이다 — 이는 결함이 아니라 "결정적 프리필터 +
LLM 심사"라는 2단 구조가 의도한 분업이다.

### 마커 정밀도에 대한 정직한 경고 (오탐 상시 발생, 의도된 설계)

- **josa_dup**: `을를`·`이가`·`은는` 은 단순 부분 문자열 검사라, "이"로
  끝나는 명사(나이·아이·차이·넥타이…) 뒤에 주격 조사 `가` 가 붙으면
  (`나이가`·`아이가`·`차이가`) 오타 없이도 문자열 `이가` 가 그대로
  나타난다 — 브리프가 지정한 규칙 자체가 이런 합성어형 오탐을 걸러내지
  않는 단순 문자열 매칭이라, 아래 "마커별 건수"의 josa_dup 후보 중
  상당수가 이 유형이다. 의도적으로 필터링하지 않았다(정밀도를 높이려 예외 사전을
  만들면 결정성은 유지되지만 "간단한 규칙"이라는 브리프 취지를 벗어나고,
  진짜 오타도 우연히 걸러낼 위험이 있다) — Task 12 심사에서 대부분
  기각될 것으로 예상한다.
- **formality_mix**: `잘 먹었습니다`·`처음 뵙겠습니다`·`감사합니다` 같은
  고정 인사/관용구가 캐주얼한 서술 문장 안에 삽입 인용된 경우
  (`"...하고 인사했어요"` 류) 도 이 마커에 걸린다 — 화자가 실제로 발화한
  formal 문장을 casual 서술이 감싸는 구조는 한국어에서 완전히 자연스러우므로
  이런 경우는 대개 오탐이다. 반대로 한 화자의 연속된 두 문장이 문맥 전환
  없이 formal→casual 로 튀는 경우(예: `smalltalk_b1_0043#followUp`
  `알겠습니다. 바로 가 볼게요.`)는 진짜 후보로 보인다 — 두 패턴이 문자열
  수준에서는 구분 불가능해 마커 하나로 합쳐 냈다.

### 알려진 커버리지 공백 (리뷰 라운드 1 Minor)

- **particle_mismatch 가 시나리오 `luecken` 퀘스트의 fill-in 옵션까지
  확장되지 않는다.** `luecken` 퀘스트(`data.sentence`+`data.options`)는
  cloze 와 거의 동형이다 — 빈칸 뒤 조사와 각 옵션의 받침 유무를 대조하는
  게 원리상 가능하지만, 이번 스캔은 `sentence` 필드를 공통 5종 마커로만
  검사하고 `options`(정답+오답 조사/어미 후보)는 검사하지 않는다. 마커
  8종 중 가장 값진 발견을 낸 것이 particle_mismatch(835건, cloze 항목의
  46%)라는 점을 감안하면, 같은 구조의 `luecken` 도 비슷한 비율로 결함을
  숨기고 있을 가능성이 있다 — Task 12/13 에서 우선순위 있게 다룰 후보로
  남겨둔다(이번 태스크 범위 밖, 별도 확장 필요).
"""


def _escape_cell(text: str) -> str:
    text = text.replace("|", "\\|")
    text = text.replace("\r\n", " ").replace("\n", " ").replace("\r", " ")
    return text


def render_report(hits: list) -> str:
    by_file = {}
    for h in hits:
        by_file.setdefault(h.source_file, []).append(h)

    lines = []
    lines.append("# 콘텐츠 자연성 프리필터 후보 리포트")
    lines.append("")
    lines.append(
        "`python tool/audit_content_naturalness.py` 로 생성 — 직접 편집 금지,"
        " 스크립트 재실행으로 갱신한다."
    )
    lines.append("")
    lines.append(
        "마커는 전부 결정적 규칙(정규식/문자열 포함/받침 유무) 기반이다."
        " 여기 실리는 항목은 \"후보\"이며, 실제 어색함 여부는 Task 12 의"
        " 사람/LLM 심사가 판단한다."
    )
    lines.append("")

    total = 0
    for source in SOURCE_FILES:
        rows = sorted(by_file.get(source, []), key=lambda h: (h.id, h.marker))
        lines.append(f"## {source}")
        lines.append("")
        if not rows:
            lines.append("0건 — 스캔했으나 후보 없음.")
            lines.append("")
            continue
        lines.append(f"{len(rows)}건.")
        lines.append("")
        lines.append("| id | 마커 | 문장 |")
        lines.append("|---|---|---|")
        for h in rows:
            lines.append(
                f"| {_escape_cell(h.id)} | {h.marker} | {_escape_cell(h.sentence)} |"
            )
        lines.append("")
        total += len(rows)

    lines.append("## 요약")
    lines.append("")
    lines.append(
        f"- 총 후보: **{total}건** (대상 파일 {len(SOURCE_FILES)}개 전부 스캔,"
        f" 후보 있는 파일 {len(by_file)}개)"
    )
    lines.append("")
    lines.append("### 파일별 건수")
    lines.append("")
    for source in SOURCE_FILES:
        lines.append(f"- {source}: {len(by_file.get(source, []))}건")
    lines.append("")
    lines.append("### 마커별 건수")
    lines.append("")
    marker_counts = Counter(h.marker for h in hits)
    for marker in MARKER_NAMES:
        lines.append(f"- {marker}: {marker_counts.get(marker, 0)}건")
    lines.append("")
    lines.append(RETRO_NOTE.rstrip())
    lines.append("")

    return "\n".join(lines) + "\n"


def write_report(hits: list, out_path: str = REPORT_PATH) -> str:
    text = render_report(hits)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return text


# ---------------------------------------------------------------------------
# CLI 진입점
# ---------------------------------------------------------------------------


def main(argv=None) -> int:
    hits = scan_all()
    write_report(hits)
    rel = os.path.relpath(REPORT_PATH, ROOT).replace(os.sep, "/")
    print(f"[audit_content_naturalness] {len(hits)}건 후보 -> {rel}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
