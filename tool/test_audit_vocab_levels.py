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
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_vocab_levels  # noqa: E402

# 2026-09-05 실측 고정 (tool/vocab_level_suspects.csv 재생성 후 294행,
# 그중 blocked 비어있지 않은 행 259개). 내리는 것만 허용.
KNOWN_SUSPECTS_CAP = 294
KNOWN_BLOCKED_SUSPECTS_CAP = 259


class VocabLevelAuditRatchetTest(unittest.TestCase):
    def test_suspect_and_blocked_counts_do_not_increase(self) -> None:
        _, rows = audit_vocab_levels.load_rows()
        suspects = audit_vocab_levels.find_suspects(rows)
        blocked_suspects = [s for s in suspects if s["blocked"]]

        self.assertLessEqual(
            len(suspects),
            KNOWN_SUSPECTS_CAP,
            f"신규 의심 레벨 분류 발생 — {len(suspects)}건 "
            f"(상한 {KNOWN_SUSPECTS_CAP}). tool/audit_vocab_levels.py 재실행 후 "
            "새로 늘어난 id를 확인하라.",
        )
        self.assertLessEqual(
            len(blocked_suspects),
            KNOWN_BLOCKED_SUSPECTS_CAP,
            f"차단된(blocked) 의심 항목 증가 — {len(blocked_suspects)}건 "
            f"(상한 {KNOWN_BLOCKED_SUSPECTS_CAP}).",
        )


if __name__ == "__main__":
    unittest.main()
