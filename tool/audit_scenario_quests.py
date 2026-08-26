"""시나리오 퀘스트 중복 감사.

`assets/data/scenarios_*.json` 샤드 전체를 훑어 **같은 시나리오 안**에서 같은
퀘스트가 두 번 이상 나타나는지 검출해 `docs/data/scenario_quest_report.md`
에 기록한다. `Hangul Sori 앱 점검 후 개선 사항 지시서.md` §4.15("시나리오공부쪽에
Bau satz 중복되는거 있는지 확인해줘")가 직접적인 동기다 — 이 스크립트는 그
질문에 재현 가능하게 답한다. 수정은 W4 소유(이 태스크 범위 밖) — 여기선
리포트만 만든다. exit code 는 항상 0(리포트 전용 도구, 실패해도 파이프라인을
막지 않는다).

퀘스트 중복 판정 키
--------------------
"같은 퀘스트"란 `type` 이 같고 그 타입의 **prompt/정답 payload** 가 같은 것으로
정의한다(distractor 순서·설명 텍스트·conceptIds 등 부수 필드는 비교 대상에서
제외 — 학습자가 실제로 푸는 문제가 동일한지가 기준이다). 타입별 payload:

  - `hoerverstehen` : 듣기 오디오(`audioKo`) + 정답 선택지
  - `luecken`       : 빈칸 문장(`sentence`) + 정답 선택지
  - `uebersetzen`   : 번역 프롬프트(`promptDe`/`promptEn`) + 정답 선택지(`ko`)
  - `satzBauen`     : 목표 문장(`targetKo`) — §4.15 가 지목한 "Bau satz" 자체
  - `diktat`        : 받아쓰기 목표 문장(`targetKo`)
  - `particlePop`   : 빈칸 틀(`prefix`+`suffix`) + 정답 조사 선택지
  - `batchimDrop`   : 오디오(`audioKo`) + 대상 단어/음절 위치 + 정답 선택지

`options[correctIndex]` 로 뽑는 "정답 선택지"만 쓰고 오답(distractor) 선택지는
비교 대상에서 뺀다 — 같은 문제를 오답 순서만 바꿔 재배치한 카피는 여전히
"같은 퀘스트"이고, 반대로 정답이 다르면 문제 의도 자체가 다르므로 중복이
아니다. payload 의 모든 구성요소가 비어 있으면(예: `data` 자체가 없거나
`correctIndex` 가 선택지 범위 밖) 그 퀘스트는 비교에서 제외한다 — 빈 payload
끼리 우연히 뭉쳐 "중복"으로 오탐되는 것을 막기 위함이다(그런 항목은 그 자체로
별도의 데이터 결함이지만 이 스크립트의 범위인 "중복 검출"과는 다른 문제).

새 퀘스트 타입이 추가되면(이 7종 밖) payload 키가 없어 비교에서 조용히
빠지지 않도록, 미지원 타입은 별도로 세어 리포트 "미지원 퀘스트 타입" 절에
낸다 — 침묵하는 누락을 막기 위한 장치.
"""

from __future__ import annotations

import json
import os
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from typing import Iterable, Optional

# ---------------------------------------------------------------------------
# 경로
# ---------------------------------------------------------------------------

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(ROOT, "assets", "data")
REPORT_PATH = os.path.join(ROOT, "docs", "data", "scenario_quest_report.md")

# ---------------------------------------------------------------------------
# 순수 함수 — payload 정규화/서명. 파일 I/O 없음.
# ---------------------------------------------------------------------------


def normalize_text(text: Optional[str]) -> str:
    """앞뒤 공백 제거 + 내부 연속 공백을 1칸으로 압축.

    데이터 자체는 정제돼 있을 가능성이 높지만, 순수 공백 차이만으로 진짜
    중복을 놓치는 걸 막기 위해 가볍게 정규화한다(형태소·구두점은 손대지
    않는다 — 그 이상은 오탐 위험이 더 커진다).
    """
    if not text:
        return ""
    return " ".join(str(text).split())


def option_payload(option) -> str:
    """선택지 하나(문자열 또는 `{ko,de,en}` 류 dict)를 비교용 문자열로 직렬화."""
    if isinstance(option, dict):
        parts = []
        for key in ("ko", "de", "en"):
            value = option.get(key)
            if value:
                parts.append(f"{key}={normalize_text(value)}")
        return "|".join(parts)
    return normalize_text(option if isinstance(option, str) else "")


def correct_option_payload(
    data: dict, options_key: str = "options", index_key: str = "correctIndex"
) -> Optional[str]:
    """`data[options_key][data[index_key]]` 를 직렬화한 문자열, 인덱스가 범위
    밖이거나 없으면 None."""
    options = data.get(options_key) or []
    raw_index = data.get(index_key)
    try:
        index = int(raw_index)
    except (TypeError, ValueError):
        return None
    if not (0 <= index < len(options)):
        return None
    return option_payload(options[index])


# 퀘스트 타입 → (data) -> payload 튜플. 튜플 원소가 전부 falsy(빈 문자열/None)면
# quest_signature() 가 "비교 대상 아님" 으로 처리한다.
_SIGNATURE_BUILDERS = {
    "hoerverstehen": lambda data: (
        normalize_text(data.get("audioKo")),
        correct_option_payload(data),
    ),
    "luecken": lambda data: (
        normalize_text(data.get("sentence")),
        correct_option_payload(data),
    ),
    "uebersetzen": lambda data: (
        normalize_text(data.get("promptDe")),
        normalize_text(data.get("promptEn")),
        correct_option_payload(data),
    ),
    "satzBauen": lambda data: (normalize_text(data.get("targetKo")),),
    "diktat": lambda data: (normalize_text(data.get("targetKo")),),
    "particlePop": lambda data: (
        normalize_text(data.get("prefix")),
        normalize_text(data.get("suffix")),
        correct_option_payload(data),
    ),
    "batchimDrop": lambda data: (
        normalize_text(data.get("audioKo")),
        normalize_text(data.get("targetWord")),
        data.get("targetSyllableIndex"),
        correct_option_payload(data),
    ),
}

SUPPORTED_QUEST_TYPES = tuple(sorted(_SIGNATURE_BUILDERS))


def quest_signature(quest_type: Optional[str], data: dict) -> Optional[tuple]:
    """`(quest_type, data)` 의 prompt/정답 payload 서명.

    None 을 돌려주는 두 경우 — 호출측은 둘 다 "이 퀘스트는 비교에서 제외"로
    다뤄야 하지만 리포트에서는 구분해서 센다(미지원 타입 vs 빈 payload):
      - `quest_type` 이 `_SIGNATURE_BUILDERS` 밖(미지원 타입)
      - payload 튜플의 모든 원소가 비어 있음(빈 데이터)
    """
    builder = _SIGNATURE_BUILDERS.get(quest_type or "")
    if builder is None:
        return None
    signature = builder(data or {})
    if all((part is None or part == "") for part in signature):
        return None
    return signature


def format_signature(signature: Iterable) -> str:
    """서명 튜플을 리포트 셀에 넣을 사람이 읽는 문자열로."""
    parts = ["∅" if p is None or p == "" else str(p) for p in signature]
    return " / ".join(parts)


# ---------------------------------------------------------------------------
# 결과 레코드
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class DuplicateGroup:
    shard: str
    scenario_id: str
    level: str
    quest_type: str
    quest_ids: tuple
    signature: tuple


# ---------------------------------------------------------------------------
# I/O 헬퍼 (스캔 계층 전용 — 순수 함수 아님)
# ---------------------------------------------------------------------------


def _scenario_shard_names() -> list:
    return sorted(
        name
        for name in os.listdir(DATA_DIR)
        if name.startswith("scenarios_") and name.endswith(".json")
    )


def _load_json(name: str):
    with open(os.path.join(DATA_DIR, name), encoding="utf-8") as f:
        return json.load(f)


def scan_all() -> tuple:
    """전체 샤드를 스캔해 `(groups, diagnostics)` 를 돌려준다.

    `groups` 는 결정적으로 정렬된 `DuplicateGroup` 리스트. `diagnostics` 는
    `{"unsupported_types": Counter, "skipped_empty_payload": int,
    "scenarios_scanned": int, "quests_scanned": int}`.
    """
    groups = []
    unsupported_types = Counter()
    skipped_empty_payload = 0
    scenarios_scanned = 0
    quests_scanned = 0

    for shard in _scenario_shard_names():
        data = _load_json(shard)
        scenarios = data.get("scenarios", []) if isinstance(data, dict) else data
        for sc in scenarios or []:
            scenarios_scanned += 1
            sc_id = sc.get("id") or "?"
            level = sc.get("level") or "?"

            by_signature: dict = defaultdict(list)
            for qi, quest in enumerate(sc.get("quests", [])):
                quests_scanned += 1
                quest_type = quest.get("type")
                quest_id = quest.get("id") or f"quest[{qi:02d}]"
                qdata = quest.get("data") or {}

                signature = quest_signature(quest_type, qdata)
                if signature is None:
                    if (quest_type or "") not in _SIGNATURE_BUILDERS:
                        unsupported_types[quest_type or "(없음)"] += 1
                    else:
                        skipped_empty_payload += 1
                    continue

                by_signature[(quest_type, signature)].append(quest_id)

            for (quest_type, signature), quest_ids in by_signature.items():
                if len(quest_ids) > 1:
                    groups.append(
                        DuplicateGroup(
                            shard=shard,
                            scenario_id=sc_id,
                            level=level,
                            quest_type=quest_type,
                            quest_ids=tuple(quest_ids),
                            signature=signature,
                        )
                    )

    groups.sort(
        key=lambda g: (g.shard, g.scenario_id, g.quest_type, g.quest_ids)
    )
    diagnostics = {
        "unsupported_types": unsupported_types,
        "skipped_empty_payload": skipped_empty_payload,
        "scenarios_scanned": scenarios_scanned,
        "quests_scanned": quests_scanned,
    }
    return groups, diagnostics


# ---------------------------------------------------------------------------
# 리포트 작성
# ---------------------------------------------------------------------------


def _escape_cell(text: str) -> str:
    text = text.replace("|", "\\|")
    text = text.replace("\r\n", " ").replace("\n", " ").replace("\r", " ")
    return text


def render_report(groups: list, diagnostics: dict) -> str:
    by_shard: dict = defaultdict(list)
    for g in groups:
        by_shard[g.shard].append(g)

    shard_names = _scenario_shard_names()

    lines = []
    lines.append("# 시나리오 퀘스트 중복 감사 리포트")
    lines.append("")
    lines.append(
        "`python tool/audit_scenario_quests.py` 로 생성 — 직접 편집 금지,"
        " 스크립트 재실행으로 갱신한다."
    )
    lines.append("")
    lines.append(
        "`Hangul Sori 앱 점검 후 개선 사항 지시서.md` §4.15(\"시나리오공부쪽에"
        " Bau satz 중복되는거 있는지 확인해줘\")에 대한 답. **같은 시나리오"
        " 안**에서 같은 `type` + 같은 prompt/정답 payload 를 가진 퀘스트가"
        " 2개 이상이면 중복으로 본다(정답 payload = `options[correctIndex]`,"
        " 오답 순서·설명 텍스트는 비교 제외). 수정은 이 스크립트 범위 밖"
        "(W4) — 여기선 검출·리포트만 한다."
    )
    lines.append("")
    lines.append("## 판정 키 (타입별)")
    lines.append("")
    lines.append("| 퀘스트 타입 | payload |")
    lines.append("|---|---|")
    lines.append("| hoerverstehen | audioKo + 정답 선택지 |")
    lines.append("| luecken | sentence + 정답 선택지 |")
    lines.append("| uebersetzen | promptDe + promptEn + 정답 선택지(ko) |")
    lines.append("| satzBauen | targetKo (§4.15 가 지목한 Bau-satz 본체) |")
    lines.append("| diktat | targetKo |")
    lines.append("| particlePop | prefix + suffix + 정답 선택지 |")
    lines.append("| batchimDrop | audioKo + targetWord + targetSyllableIndex + 정답 선택지 |")
    lines.append("")

    total = 0
    total_instances = 0
    for shard in shard_names:
        rows = sorted(
            by_shard.get(shard, []),
            key=lambda g: (g.scenario_id, g.quest_type, g.quest_ids),
        )
        lines.append(f"## {shard}")
        lines.append("")
        if not rows:
            lines.append("0건 — 스캔했으나 중복 없음.")
            lines.append("")
            continue
        lines.append(f"{len(rows)}개 그룹.")
        lines.append("")
        lines.append("| 시나리오 id | 레벨 | 퀘스트 타입 | 중복 퀘스트 id | payload |")
        lines.append("|---|---|---|---|---|")
        for g in rows:
            lines.append(
                f"| {_escape_cell(g.scenario_id)} | {_escape_cell(g.level)} |"
                f" {g.quest_type} | {_escape_cell(', '.join(g.quest_ids))} |"
                f" {_escape_cell(format_signature(g.signature))} |"
            )
        lines.append("")
        total += len(rows)
        total_instances += sum(len(g.quest_ids) for g in rows)

    unsupported = diagnostics["unsupported_types"]
    lines.append("## 미지원 퀘스트 타입")
    lines.append("")
    if not unsupported:
        lines.append(
            f"0건 — 스캔된 모든 퀘스트 타입이 지원 목록"
            f"({', '.join(SUPPORTED_QUEST_TYPES)}) 안에 있음."
        )
        lines.append("")
    else:
        lines.append(
            "아래 타입은 판정 키가 없어 중복 비교에서 제외됐다 — 새 퀘스트"
            " 타입이 추가된 것일 수 있으니 이 스크립트의 `_SIGNATURE_BUILDERS`"
            " 확장이 필요하다."
        )
        lines.append("")
        lines.append("| 퀘스트 타입 | 건수 |")
        lines.append("|---|---|")
        for qtype in sorted(unsupported):
            lines.append(f"| {_escape_cell(qtype)} | {unsupported[qtype]} |")
        lines.append("")

    lines.append("## 요약")
    lines.append("")
    lines.append(
        f"- 스캔한 시나리오: **{diagnostics['scenarios_scanned']}개**"
        f" (샤드 {len(shard_names)}개: {', '.join(shard_names)})"
    )
    lines.append(f"- 스캔한 퀘스트: **{diagnostics['quests_scanned']}개**")
    lines.append(
        f"- 빈 payload 로 비교 제외된 퀘스트: **{diagnostics['skipped_empty_payload']}개**"
        " (data 누락 또는 correctIndex 가 선택지 범위 밖 — 중복과는 별개의"
        " 데이터 결함이라 이 리포트에서는 세기만 하고 나열하지 않음)"
    )
    lines.append(f"- 미지원 퀘스트 타입으로 제외된 퀘스트: **{sum(unsupported.values())}개**")
    lines.append(f"- 중복 그룹: **{total}개** (중복 퀘스트 인스턴스 합계 {total_instances}개)")
    lines.append("")
    lines.append("### 샤드별 중복 그룹 수")
    lines.append("")
    for shard in shard_names:
        lines.append(f"- {shard}: {len(by_shard.get(shard, []))}개")
    lines.append("")
    lines.append("### 퀘스트 타입별 중복 그룹 수")
    lines.append("")
    type_counts = Counter(g.quest_type for g in groups)
    for qtype in SUPPORTED_QUEST_TYPES:
        lines.append(f"- {qtype}: {type_counts.get(qtype, 0)}개")
    lines.append("")
    lines.append(
        "### §4.15 결론"
        if total == 0
        else "### §4.15 결론 — 발견됨"
    )
    lines.append("")
    satz_bauen_count = type_counts.get("satzBauen", 0)
    if total == 0:
        lines.append(
            "이번 스캔에서는 `satzBauen`(Bau-satz) 을 포함해 7개 퀘스트 타입"
            " 전부 시나리오 내 중복이 **0건**이었다 — §4.15 가 우려한 상황은"
            " 이 콘텐츠 스냅샷 시점에는 재현되지 않는다. 판정 키가 정답"
            " payload 만 보고 오답/설명 텍스트를 무시하므로, 오답만 바꿔"
            " 복붙한 위장 중복도 여기 포함되면 잡혔을 것이다."
        )
    else:
        lines.append(
            f"`satzBauen` 중복 그룹 {satz_bauen_count}개 포함 총 {total}개"
            " 그룹 발견 — 위 표 참고. 수정은 W4 담당."
        )
    lines.append("")

    return "\n".join(lines) + "\n"


def write_report(groups: list, diagnostics: dict, out_path: str = REPORT_PATH) -> str:
    text = render_report(groups, diagnostics)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return text


# ---------------------------------------------------------------------------
# CLI 진입점
# ---------------------------------------------------------------------------


def main(argv=None) -> int:
    groups, diagnostics = scan_all()
    write_report(groups, diagnostics)
    rel = os.path.relpath(REPORT_PATH, ROOT).replace(os.sep, "/")
    print(f"[audit_scenario_quests] 중복 그룹 {len(groups)}개 -> {rel}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
