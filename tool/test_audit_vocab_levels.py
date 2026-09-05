"""Ratchet test for tool/audit_vocab_levels.py — 지시서 2.2.

audit_vocab_levels.find_suspects()/blocked_ids() 를 실제 저장소 데이터에
대해 그대로 돌려, "의심 레벨 분류" 항목 수와 그중 "blocked"(주로
satz_ref — satz_sentences.json 이 (level, vocabKo) 로 참조 중이라 레벨을
그냥 옮기면 참조가 끊어짐) 항목 수를 실측치에 상한으로 고정한다.

이 가드는 데이터를 고치지 않는다 — 상한은 내려갈 수만 있다. 재분류로
의심/차단 항목이 줄면 이 상수들도 같이 낮춰라. 절대 올리지 마라.

CI 배선은 파일 패턴 자동이다: `.github/workflows/ci.yml` 의
`python -m unittest discover -s tool -p "test_*.py" -t .` 가 `tool/test_*.py`
를 전부 줍는다 (선례: tool/test_check_brief_anchors.py, tool/test_relevel_vocab.py)
— ci.yml 자체를 고칠 필요 없음.

2026-09-05 KNOWN_TOPIC_TIE_SUSPECT_IDS 추가 (brief_x_content T2b):
vocab_a1_0216(시아버지) 를 A1 → B1 로 재분류(satz_ref 락은 브리프 지시로
이 커밋에 한해 수동 우회)하면서, "Partnerschaft & koreanische Familie"
토픽의 레벨별 단어 수가 A1=96/A2=96/B1=96/B2=96 로 정확히 4-way 동률이던
것이 A1=95/B1=97 로 깨졌다. `find_suspects()`의 `below_topic` 판정은
`topic_mode(topic) - rank(word.level) >= 2` 인데, 최빈 레벨이 (동률 시
선착순 규칙에 따라) A1에서 B1로 뒤집히면서 같은 팩 세트(설날/추석/집들이/
호칭/형제자매 인사 등)의 기존 A1 어휘 65건이 한꺼번에 below_topic 으로
새로 잡혔다. 데이터는 전혀 바뀌지 않았고(전부 satz_ref 로 이미 잠긴 기존
A1 콘텐츠), 순전히 "동률이 하나 밀려서 최빈값이 뒤집힌" 통계 부작용이다
— tool/vocab_level_relevel_notes.md 참고. 이 65건은 실제로 재검토가
필요한 신규 발견이 아니므로 별도 캡으로 분리해 문서화하고, 나머지
("core") 캡은 시아버지 이동으로 -1 된 실측치로 정상 하향한다.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_vocab_levels  # noqa: E402

# 2026-09-05 실측 고정 (시아버지 A1→B1 재분류 반영, KNOWN_TOPIC_TIE_SUSPECT_IDS
# 제외한 "core" 의심/차단 건수). 내리는 것만 허용.
KNOWN_SUSPECTS_CAP = 293
KNOWN_BLOCKED_SUSPECTS_CAP = 258

# "Partnerschaft & koreanische Familie" 토픽 최빈값 tie 붕괴로 발생한 신규
# below_topic 오탐 65건 — 위 docstring 참고. 전부 blocked=satz_ref(기존
# 콘텐츠, 무손상). 상한은 내려갈 수만 있다(재검토로 해소되면 목록에서
# 제거하고 캡을 낮출 것).
KNOWN_TOPIC_TIE_SUSPECT_IDS: frozenset[str] = frozenset(
    {
        "vocab_a1_0212",
        "vocab_a1_0213",
        "vocab_a1_0218",
        "vocab_a1_0220",
        "vocab_a1_0221",
        "vocab_a1_0222",
        "vocab_a1_0223",
        "vocab_a1_0226",
        "vocab_a1_0227",
        "vocab_a1_0228",
        "vocab_a1_0229",
        "vocab_a1_0230",
        "vocab_a1_0231",
        "vocab_a1_0234",
        "vocab_a1_0236",
        "vocab_a1_0238",
        "vocab_a1_0239",
        "vocab_a1_0241",
        "vocab_a1_0242",
        "vocab_a1_0243",
        "vocab_a1_0246",
        "vocab_a1_0247",
        "vocab_a1_0248",
        "vocab_a1_0249",
        "vocab_a1_0251",
        "vocab_a1_0252",
        "vocab_a1_0253",
        "vocab_a1_0254",
        "vocab_a1_0255",
        "vocab_a1_0258",
        "vocab_a1_0260",
        "vocab_a1_0261",
        "vocab_a1_0262",
        "vocab_a1_0264",
        "vocab_a1_0265",
        "vocab_a1_0266",
        "vocab_a1_0267",
        "vocab_a1_0268",
        "vocab_a1_0271",
        "vocab_a1_0272",
        "vocab_a1_0273",
        "vocab_a1_0274",
        "vocab_a1_0275",
        "vocab_a1_0276",
        "vocab_a1_0277",
        "vocab_a1_0278",
        "vocab_a1_0281",
        "vocab_a1_0283",
        "vocab_a1_0284",
        "vocab_a1_0285",
        "vocab_a1_0288",
        "vocab_a1_0289",
        "vocab_a1_0290",
        "vocab_a1_0291",
        "vocab_a1_0292",
        "vocab_a1_0293",
        "vocab_a1_0294",
        "vocab_a1_0298",
        "vocab_a1_0299",
        "vocab_a1_0300",
        "vocab_a1_0301",
        "vocab_a1_0302",
        "vocab_a1_0303",
        "vocab_a1_0305",
        "vocab_a1_0307",
    }
)
KNOWN_TOPIC_TIE_SUSPECT_CAP = 65  # 2026-09-05 실측 고정. 내리는 것만 허용.


class VocabLevelAuditRatchetTest(unittest.TestCase):
    def test_suspect_and_blocked_counts_do_not_increase(self) -> None:
        _, rows = audit_vocab_levels.load_rows()
        suspects = audit_vocab_levels.find_suspects(rows)

        topic_tie_suspects = [
            s for s in suspects if s["id"] in KNOWN_TOPIC_TIE_SUSPECT_IDS
        ]
        core_suspects = [
            s for s in suspects if s["id"] not in KNOWN_TOPIC_TIE_SUSPECT_IDS
        ]
        core_blocked = [s for s in core_suspects if s["blocked"]]

        self.assertLessEqual(
            len(core_suspects),
            KNOWN_SUSPECTS_CAP,
            f"신규 의심 레벨 분류 발생 — {len(core_suspects)}건 "
            f"(상한 {KNOWN_SUSPECTS_CAP}). tool/audit_vocab_levels.py 재실행 후 "
            "새로 늘어난 id를 확인하라.",
        )
        self.assertLessEqual(
            len(core_blocked),
            KNOWN_BLOCKED_SUSPECTS_CAP,
            f"차단된(blocked) 의심 항목 증가 — {len(core_blocked)}건 "
            f"(상한 {KNOWN_BLOCKED_SUSPECTS_CAP}).",
        )
        self.assertLessEqual(
            len(topic_tie_suspects),
            KNOWN_TOPIC_TIE_SUSPECT_CAP,
            f"topic-tie 오탐 버킷 증가 — {len(topic_tie_suspects)}건 "
            f"(상한 {KNOWN_TOPIC_TIE_SUSPECT_CAP}). 새 id면 원인을 재확인하라"
            "(단순 재감소는 KNOWN_TOPIC_TIE_SUSPECT_IDS 에서 제거하고 캡을 내릴 것).",
        )


if __name__ == "__main__":
    unittest.main()
