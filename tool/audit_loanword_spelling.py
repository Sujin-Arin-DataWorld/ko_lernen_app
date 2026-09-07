#!/usr/bin/env python3
"""kornorms 외래어 표기법·로마자 표기법 감사 (승인 플랜 §4.9, §6 T1.9).

앱 표제어(`assets/data/korean_vocab.csv`) 중 외래어 후보(2023 국어 기초
어휘 목록 `origin=외래어` 또는 표제어에 라틴 문자 포함)를 뽑아 국립국어원
어문 규범 오픈 API(`exampleReqList.do`, langType=0003 외래어 표기법)로 표준
표기를 대조하고, 고유명사 화이트리스트(§4.9: 서울·부산·제주·한강·경복궁)는
langType=0004 로마자 표기법으로 앱의 romanization 열을 대조한다.

키 규칙: `KORNORMS_API_KEY` 환경변수만 사용한다. 키는 어떤 파일·캐시 파일명·
로그·리포트에도 절대 쓰지 않는다(플랜 Global Constraints "비밀" 항). 키가
없으면 네트워크를 전혀 시도하지 않고 "KORNORMS_API_KEY not set — skipping"을
출력한 뒤 exit 0으로 끝난다(선택 도구, 안전하게 무동작).

캐시: 각 API 응답을 `tool/.cache/kornorms/<sha1(langType|keyword)>.json`에
저장한다(`.gitignore`에 이미 등록됨). 캐시 키는 langType과 검색어만으로
만들어지므로 구조적으로 API 키가 파일명에 들어갈 수 없다. 캐시 히트 시
네트워크를 다시 부르지 않는다. 호출 사이 0.3초 레이트리밋, HTTP 오류는 1회
재시도 후 'error'로 표시한다.

실행 (키가 있을 때만 실제로 호출):
    python tool/audit_loanword_spelling.py
    python tool/audit_loanword_spelling.py --offline   # 캐시만 사용, 네트워크 안 함
    python tool/audit_loanword_spelling.py --limit 50   # 후보 상한

리포트는 키가 있을 때만 `docs/data/loanword_spelling_report.md`에 쓴다.
테스트는 주입된 fetcher로 네트워크 없이 돈다:
    python -m unittest tool.test_audit_loanword_spelling -v
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Callable, Iterable

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_VOCAB_CSV = REPO_ROOT / "assets" / "data" / "korean_vocab.csv"
DEFAULT_LEXICON_CSV = (
    REPO_ROOT / "tools" / "content_factory" / "lexicon" / "nikl_basic_2023_vocab.csv"
)
DEFAULT_CACHE_DIR = REPO_ROOT / "tool" / ".cache" / "kornorms"
DEFAULT_REPORT_PATH = REPO_ROOT / "docs" / "data" / "loanword_spelling_report.md"
API_URL = "https://korean.go.kr/kornorms/exampleReqList.do"

LOANWORD_LANG_TYPE = "0003"  # 외래어 표기법
ROMANIZATION_LANG_TYPE = "0004"  # 로마자 표기법

# 앱에 등장하는 고유명사 중 로마자 표기법 대조 대상 화이트리스트 (§4.9).
PLACE_NAME_WHITELIST = ("서울", "부산", "제주", "한강", "경복궁")

_LATIN_LETTER_RE = re.compile(r"[A-Za-z]")

Fetcher = Callable[[str, str, str, str], dict]


# --------------------------------------------------------------------------
# 데이터 로딩
# --------------------------------------------------------------------------


def load_vocab_rows(path: Path) -> list[dict]:
    """`assets/data/korean_vocab.csv`를 읽어 행 딕셔너리 리스트를 반환한다."""
    with Path(path).open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def load_lexicon_origin(path: Path) -> dict[str, set[str]]:
    """headword -> {origin, ...} 매핑. 동형어가 여러 origin을 가질 수 있어 set."""
    origin_map: dict[str, set[str]] = {}
    with Path(path).open("r", encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            headword = row.get("headword", "").strip()
            origin = row.get("origin", "").strip()
            if not headword or not origin:
                continue
            origin_map.setdefault(headword, set()).add(origin)
    return origin_map


# --------------------------------------------------------------------------
# 후보 선정
# --------------------------------------------------------------------------


def select_loanword_candidates(
    vocab_rows: Iterable[dict], origin_map: dict[str, set[str]]
) -> list[str]:
    """외래어 감사 후보 표제어를 정렬·중복 제거해 반환한다.

    후보 조건: 사전 origin=외래어(어종 = 2023 국어 기초 어휘 목록) 또는
    표제어에 라틴 문자가 포함(예: 앱 표기 오류로 로마자가 섞인 경우).
    """
    candidates: set[str] = set()
    for row in vocab_rows:
        word = (row.get("korean") or "").strip()
        if not word:
            continue
        if "외래어" in origin_map.get(word, set()):
            candidates.add(word)
        elif _LATIN_LETTER_RE.search(word):
            candidates.add(word)
    return sorted(candidates)


def select_romanization_candidates(vocab_rows: Iterable[dict]) -> list[dict]:
    """로마자 표기법 대조 후보(화이트리스트 고유명사)를 반환한다.

    각 항목은 {'korean': ..., 'app_romanization': ...} 형태이며 표제어당
    첫 등장 romanization 값을 사용한다(중복 행이 있어도 1회만 대조).
    """
    seen: dict[str, str] = {}
    for row in vocab_rows:
        word = (row.get("korean") or "").strip()
        if word in PLACE_NAME_WHITELIST and word not in seen:
            seen[word] = (row.get("romanization") or "").strip()
    return [
        {"korean": word, "app_romanization": seen[word]}
        for word in PLACE_NAME_WHITELIST
        if word in seen
    ]


# --------------------------------------------------------------------------
# 캐시 + 네트워크 (fetcher 주입 가능)
# --------------------------------------------------------------------------


def _cache_key(lang_type: str, keyword: str) -> str:
    """캐시 파일명 = sha1(langType|keyword). API 키는 절대 관여하지 않는다."""
    return hashlib.sha1(f"{lang_type}|{keyword}".encode("utf-8")).hexdigest()


def _cache_file(cache_dir: Path, lang_type: str, keyword: str) -> Path:
    return Path(cache_dir) / f"{_cache_key(lang_type, keyword)}.json"


def _load_cache(cache_dir: Path, lang_type: str, keyword: str) -> dict | None:
    path = _cache_file(cache_dir, lang_type, keyword)
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def _save_cache(cache_dir: Path, lang_type: str, keyword: str, response: dict) -> None:
    path = _cache_file(cache_dir, lang_type, keyword)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(response, ensure_ascii=False, sort_keys=True), encoding="utf-8")


def http_fetcher(api_key: str, lang_type: str, keyword: str, search_equals: str) -> dict:
    """실제 kornorms API 호출. 테스트에서는 이 함수 대신 mock fetcher를 주입한다."""
    params = {
        "serviceKey": api_key,
        "pageNo": "1",
        "numOfRows": "20",
        "langType": lang_type,
        "resultType": "json",
        "searchKeyword": keyword,
        "searchCondition": "korean_mark",
        "searchEquals": search_equals,
    }
    url = f"{API_URL}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read()
    return json.loads(body.decode("utf-8"))


def query_kornorms(
    keyword: str,
    lang_type: str,
    *,
    cache_dir: Path,
    fetcher: Fetcher,
    api_key: str,
    search_equals: str = "equal",
    rate_limit_seconds: float = 0.3,
    offline: bool = False,
) -> dict:
    """캐시를 먼저 확인하고, 없으면 fetcher를 호출해 캐시에 저장한다.

    캐시 히트 시 fetcher는 절대 호출하지 않는다. `offline=True`이고 캐시가
    없으면 네트워크를 시도하지 않고 `{'offline_skip': True, 'items': []}`를
    반환한다. fetcher가 예외를 던지면 1회 재시도 후에도 실패하면
    `{'error': True, 'items': []}`를 반환한다(캐시하지 않음 — 다음 실행에서
    재시도 가능하도록).
    """
    cached = _load_cache(cache_dir, lang_type, keyword)
    if cached is not None:
        return cached

    if offline:
        return {"offline_skip": True, "items": []}

    response: dict | None = None
    last_error: Exception | None = None
    for _attempt in range(2):
        try:
            response = fetcher(api_key, lang_type, keyword, search_equals)
            last_error = None
            break
        except Exception as exc:  # noqa: BLE001 — 네트워크/파싱 오류 전부 재시도 대상
            last_error = exc
            response = None

    if rate_limit_seconds:
        time.sleep(rate_limit_seconds)

    if response is None:
        return {"error": True, "items": [], "error_message": str(last_error)}

    _save_cache(cache_dir, lang_type, keyword, response)
    return response


# --------------------------------------------------------------------------
# 분류
# --------------------------------------------------------------------------


def classify_loanword(keyword: str, response: dict) -> str:
    """'standard' | 'not_found' | 'error'. korean_mark 완전 일치를 표준으로 본다."""
    if response.get("error"):
        return "error"
    items = response.get("items") or []
    for item in items:
        if item.get("korean_mark") == keyword:
            return "standard"
    return "not_found"


def classify_romanization(korean: str, app_value: str, response: dict) -> str:
    """'match' | 'mismatch' | 'not_found' | 'error'. 대소문자 무시 비교."""
    if response.get("error"):
        return "error"
    items = response.get("items") or []
    matches = [item for item in items if item.get("korean_mark") == korean]
    if not matches:
        return "not_found"
    app_norm = (app_value or "").strip().lower()
    for item in matches:
        api_value = (item.get("lang_nm") or "").strip().lower()
        if api_value and api_value == app_norm:
            return "match"
    return "mismatch"


# --------------------------------------------------------------------------
# 리포트
# --------------------------------------------------------------------------


def build_report(loanword_results: list[dict], romanization_results: list[dict]) -> str:
    """docs/data/loanword_spelling_report.md 본문 (카운트 + 표). API 키 미포함."""
    lines: list[str] = []
    lines.append("# 외래어 표기법·로마자 표기법 감사 리포트")
    lines.append("")
    lines.append(
        "국립국어원 어문 규범 오픈 API(`exampleReqList.do`)로 앱 표제어를 대조한 결과다. "
        "승인 플랜 §4.9 / §6 T1.9."
    )
    lines.append("")

    lines.append("## 외래어 표기법 (langType 0003)")
    lines.append("")
    counts: dict[str, int] = {}
    for r in loanword_results:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    total = len(loanword_results)
    lines.append(f"- 총 후보: {total}")
    for status in ("standard", "not_found", "error"):
        lines.append(f"- {status}: {counts.get(status, 0)}")
    lines.append("")
    lines.append("| 표제어 | 판정 |")
    lines.append("|---|---|")
    for r in sorted(loanword_results, key=lambda x: x["keyword"]):
        lines.append(f"| {r['keyword']} | {r['status']} |")
    lines.append("")

    lines.append("## 로마자 표기법 (langType 0004, 고유명사 화이트리스트)")
    lines.append("")
    lines.append("| 표제어 | 앱 표기 | API 표기 | 판정 |")
    lines.append("|---|---|---|---|")
    for r in sorted(romanization_results, key=lambda x: x["korean"]):
        lines.append(
            f"| {r['korean']} | {r.get('app_value', '')} | {r.get('api_value', '')} "
            f"| {r['status']} |"
        )
    lines.append("")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------


def _run_audit(
    api_key: str,
    *,
    vocab_csv: Path,
    lexicon_csv: Path,
    cache_dir: Path,
    report_path: Path,
    fetcher: Fetcher,
    offline: bool,
    limit: int | None,
    rate_limit_seconds: float,
) -> None:
    vocab_rows = load_vocab_rows(vocab_csv)
    origin_map = load_lexicon_origin(lexicon_csv)

    loanword_candidates = select_loanword_candidates(vocab_rows, origin_map)
    if limit is not None:
        loanword_candidates = loanword_candidates[:limit]

    loanword_results = []
    for keyword in loanword_candidates:
        response = query_kornorms(
            keyword,
            LOANWORD_LANG_TYPE,
            cache_dir=cache_dir,
            fetcher=fetcher,
            api_key=api_key,
            rate_limit_seconds=rate_limit_seconds,
            offline=offline,
        )
        if response.get("offline_skip"):
            status = "offline_skip"
        else:
            status = classify_loanword(keyword, response)
        loanword_results.append({"keyword": keyword, "status": status})

    romanization_candidates = select_romanization_candidates(vocab_rows)
    romanization_results = []
    for cand in romanization_candidates:
        korean = cand["korean"]
        app_value = cand["app_romanization"]
        response = query_kornorms(
            korean,
            ROMANIZATION_LANG_TYPE,
            cache_dir=cache_dir,
            fetcher=fetcher,
            api_key=api_key,
            rate_limit_seconds=rate_limit_seconds,
            offline=offline,
        )
        if response.get("offline_skip"):
            status = "offline_skip"
            api_value = ""
        else:
            status = classify_romanization(korean, app_value, response)
            items = [
                item
                for item in (response.get("items") or [])
                if item.get("korean_mark") == korean
            ]
            api_value = items[0].get("lang_nm", "") if items else ""
        romanization_results.append(
            {
                "korean": korean,
                "app_value": app_value,
                "api_value": api_value,
                "status": status,
            }
        )

    report = build_report(loanword_results, romanization_results)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(report, encoding="utf-8")
    print(f"Report written to {report_path}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--offline", action="store_true", help="캐시만 사용, 네트워크 호출 안 함"
    )
    parser.add_argument(
        "--limit", type=int, default=None, help="외래어 후보 처리 상한 (기본: 전체)"
    )
    parser.add_argument("--vocab-csv", type=Path, default=DEFAULT_VOCAB_CSV)
    parser.add_argument("--lexicon-csv", type=Path, default=DEFAULT_LEXICON_CSV)
    parser.add_argument("--cache-dir", type=Path, default=DEFAULT_CACHE_DIR)
    parser.add_argument("--report-path", type=Path, default=DEFAULT_REPORT_PATH)
    args = parser.parse_args(argv)

    api_key = os.environ.get("KORNORMS_API_KEY")
    if not api_key:
        print("KORNORMS_API_KEY not set — skipping")
        return 0

    _run_audit(
        api_key,
        vocab_csv=args.vocab_csv,
        lexicon_csv=args.lexicon_csv,
        cache_dir=args.cache_dir,
        report_path=args.report_path,
        fetcher=http_fetcher,
        offline=args.offline,
        limit=args.limit,
        rate_limit_seconds=0.3,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
