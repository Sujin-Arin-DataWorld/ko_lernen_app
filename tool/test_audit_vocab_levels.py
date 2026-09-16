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

# 2026-09-07 T2.3-R1 실측 고정 (PR-L2a relevel 17건 적용 후, 시아버지 A1→B1
# 재분류 및 KNOWN_TOPIC_TIE_SUSPECT_IDS 제외한 "core" 의심/차단 건수). 이
# relevel이 옮긴 a1_partner_* 팩 다수가 아래 "Partnerschaft & koreanische
# Familie" 토픽 자체였으므로 topic-tie 캡도 함께 떨어졌다 (다음 상수 참고).
# 내리는 것만 허용.
#
# 2026-09-07 T2.5 실측 고정 (PR-L2a Part A/B/C: level_exceptions.csv +
# relevel_bundle_L2a3.json 4개 팩 이동 + relevel_batch_003.csv 18단어
# 이동). core_suspects/core_blocked 모두 더 낮은 실측치로 하향.
# topic-tie 캡은 24로 변화 없음(이번 라운드는 이 토픽 팩을 옮기지 않음).
#
# 2026-09-08 PR-L3a 실측 고정 (Batch 23): `find_suspects()`의 sino3_low가
# 이제 NIKL 등급표(tool/cefr_lexicon.py)를 먼저 본다 -- 목록이 앱 레벨
# 이하로 매기는 표제어(선생님·지하철·비행기·외국인 등 1급 3음절 명사)는
# 더 이상 의심이 아니다(127건 해소). core 205→81, blocked 171→68 로 하향.
# topic-tie 캡 24 변화 없음.
KNOWN_SUSPECTS_CAP = 81
KNOWN_BLOCKED_SUSPECTS_CAP = 68

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
KNOWN_TOPIC_TIE_SUSPECT_CAP = 24  # 2026-09-07 T2.3-R1 실측 고정 (relevel로 이
# 토픽의 a1_partner_* 팩들이 옮겨가며 대부분 해소됨). 내리는 것만 허용.

# 2026-09-16 (C3-T3, Fable review of #352): Batch 26/27/28's 192 new A1
# words landed 12 new suspects, ALL confirmed heuristic false positives
# (not real level errors) via a direct tool/cefr_lexicon.py word_grade()
# check on each -- see the fix commit for the full table. All 12 are
# "below_topic": the word's own NIKL kiiq grade is 1 (A1), confirmed
# correct. "below_topic" only fires because these words share a broad
# topic label (Technologie/Kommunikation) whose STATISTICAL mode is
# pulled to a higher level by unrelated existing B1+ content under the
# same label -- the exact same "최빈값이 특정 라벨의 기존 상위-레벨
# 콘텐츠에 쏠려 있다" class of false positive KNOWN_TOPIC_TIE_SUSPECT_IDS
# above already documents, just a different topic/cause.
#
# (2026-09-16 round 2, Fable review of bd84de97: an earlier version of
# this set also carried vocab_a1_0667 for a "sino3_low" flag -- that
# was a side effect of a since-reverted content regression (가요 ->
# 인기가요) done to route around an OCR gloss-resolver bug instead of
# fixing the resolver; 가요 itself is NIKL grade 1 and was never a real
# suspect, restored, removed here. The resolver bug is fixed at its own
# source in lib/services/book_word_gloss_resolver.dart instead.)
#
# Lower-only, like every cap in this file: if a future relevel genuinely
# moves one of these words, remove its id here and lower the cap.
KNOWN_C3T3_HEURISTIC_SUSPECT_IDS: frozenset[str] = frozenset(
    {
        "vocab_a1_0524",  # 텔레비전, below_topic (NIKL grade 1)
        "vocab_a1_0595",  # 카메라, below_topic (NIKL grade 1)
        "vocab_a1_0649",  # 대답, below_topic (NIKL grade 1)
        "vocab_a1_0650",  # 소개, below_topic (NIKL grade 1)
        "vocab_a1_0653",  # 묻다, below_topic (NIKL grade 1)
        "vocab_a1_0654",  # 맞다, below_topic (NIKL grade 1)
        "vocab_a1_0663",  # 에어컨, below_topic (NIKL grade 1)
        "vocab_a1_0665",  # 사용, below_topic (NIKL grade 1)
        "vocab_a1_0675",  # 프로그램, below_topic (NIKL grade 1)
        "vocab_a1_0677",  # 사진, below_topic (NIKL grade 1)
        "vocab_a1_0697",  # 안내, below_topic (NIKL grade 1)
        "vocab_a1_0702",  # 이야기, below_topic (NIKL grade 1)
    }
)
KNOWN_C3T3_HEURISTIC_SUSPECT_CAP = 12


class VocabLevelAuditRatchetTest(unittest.TestCase):
    def test_suspect_and_blocked_counts_do_not_increase(self) -> None:
        _, rows = audit_vocab_levels.load_rows()
        suspects = audit_vocab_levels.find_suspects(rows)

        topic_tie_suspects = [
            s for s in suspects if s["id"] in KNOWN_TOPIC_TIE_SUSPECT_IDS
        ]
        c3t3_suspects = [
            s for s in suspects if s["id"] in KNOWN_C3T3_HEURISTIC_SUSPECT_IDS
        ]
        core_suspects = [
            s
            for s in suspects
            if s["id"] not in KNOWN_TOPIC_TIE_SUSPECT_IDS
            and s["id"] not in KNOWN_C3T3_HEURISTIC_SUSPECT_IDS
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
        self.assertLessEqual(
            len(c3t3_suspects),
            KNOWN_C3T3_HEURISTIC_SUSPECT_CAP,
            f"C3-T3 오탐 버킷 증가 — {len(c3t3_suspects)}건 "
            f"(상한 {KNOWN_C3T3_HEURISTIC_SUSPECT_CAP}). 새 id면 각각 "
            "tool/cefr_lexicon.py word_grade()로 NIKL 등급을 직접 확인해 "
            "진짜 오류인지 재검토하라.",
        )


class AuthoritativeLevelExemptionTest(unittest.TestCase):
    """Fable R8 2차(2026-09-16): `below_topic`은 "설명되지 않는" 레벨 하락을
    잡는 휴리스틱이므로, 레벨이 권위 있는 근거(F9 룰링 또는 NIKL kiiq
    정확 등급)로 이미 설명되는 행에는 붙으면 안 된다. 합성 fixture로 두
    방향을 고정한다: 같은 행이라도 표제어에 권위 근거가 있으면 의심에서
    빠지고, 없으면(가짜 표제어) 그대로 의심에 남는다."""

    @staticmethod
    def _fixture_rows(headword: str) -> list[dict[str, str]]:
        # "B1_modal_topic"의 최빈 레벨은 B1(4건) — A1 표제어 1건은
        # topic_mode(B1=2) - rank(A1=0) = 2 로 below_topic 원 조건을 satisfies.
        columns = {
            "romanization": "x", "german": "x", "pos_de": "Nomen",
            "example_korean": "", "example_german": "", "pack_order": "1",
            "is_review_boss": "false", "english": "", "pos_en": "",
            "example_english": "",
        }
        rows = [
            {
                **columns, "korean": f"단어{i}", "level": "B1",
                "topic": "B1_modal_topic", "pack_id": "b1_test_pack",
                "id": f"vocab_b1_test{i}",
            }
            for i in range(4)
        ]
        rows.append(
            {
                **columns, "korean": headword, "level": "A1",
                "topic": "B1_modal_topic", "pack_id": "a1_test_pack",
                "id": "vocab_a1_test",
            }
        )
        return rows

    def test_word_with_authoritative_nikl_grade_is_not_a_suspect(self) -> None:
        # "가게"는 nikl_kiiq_2017_vocab.csv 에 grade=1(A1)로 직접 등재된
        # 표제어다(homograph 없이 단일 등급) -- 권위 근거 있음.
        rows = self._fixture_rows("가게")
        suspects = {s["id"] for s in audit_vocab_levels.find_suspects(rows)}
        self.assertNotIn("vocab_a1_test", suspects)
        skips = {s["id"]: s for s in audit_vocab_levels.find_authoritative_skips(rows)}
        self.assertIn("vocab_a1_test", skips)
        self.assertEqual(skips["vocab_a1_test"]["authority"], "nikl_grade")

    def test_same_row_without_authority_is_a_suspect(self) -> None:
        # 실재하지 않는 표제어 -- F9 룰링도, NIKL kiiq 등재도 없다.
        rows = self._fixture_rows("존재하지않는가짜표제어0")
        suspects = {s["id"] for s in audit_vocab_levels.find_suspects(rows)}
        self.assertIn("vocab_a1_test", suspects)
        flagged = next(
            s for s in audit_vocab_levels.find_suspects(rows) if s["id"] == "vocab_a1_test"
        )
        self.assertIn("below_topic", flagged["reasons"])


if __name__ == "__main__":
    unittest.main()
