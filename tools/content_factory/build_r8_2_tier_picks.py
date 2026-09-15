#!/usr/bin/env python3
"""R8-2 (Fable, 2026-09-15) -- replace uniform OPEN_SLOT_WAIVER with a
two-tier scheme: Tier A (default) same-POS/same-form semantically
INCOMPATIBLE distractors (Jin's standing rule: distractors should test
vocabulary, not grammar -- "배분어는 같은 품사, 같은 활용형의 의미 불성립형
>=2/3; 비문형은 학습 가치가 낮아 최후 수단"); Tier B (OPEN_SLOT_WAIVER) is a
last resort, ONLY for frames with no selectional restriction at all.

Key finding from the R8 read that drives Tier A's design: an ABSTRACT
same-topic-avoiding noun (관점/느낌/비용/가능성/...) still reads as a
perfectly natural filler for most frames -- abstract nouns are too
semantically flexible to create a genuine clash. A CONCRETE, narrow-domain
noun from an unrelated everyday-life topic (음식/옷/색깔/몸/자연 등) is a
much more reliable clash: "검침기 국물으로 요금이 청구됐습니다" (broth as a
billing method) is nonsense on inspection, but "검침기 가능성으로..."
(possibility as a billing method) is a much weaker clash. Same logic for
predicates: a same-ending ADJECTIVE from an unrelated sensory domain
(맛/가격/크기) clashes better against a social/emotional-register answer
than another same-domain word would.

Candidate pools:
  * Tier A noun slots (A1-B2 items): CONCRETE_TOPICS pool (food, clothing,
    colors, body, household, nature, position, transport, ...), same
    level-or-below, excluding the answer's own topic, respecting D1
    batchim / D2 particle-fold.
  * Tier A noun slots (C1-C2 items): full same-level-or-below Nomen pool
    excluding the answer's own topic (C1/C2 register already skews
    abstract/discourse, so cross-topic within that register is the
    working "clash", matching Fable's own register expectations there).
  * Tier A predicate slots: existing same-ending-signature reuse pool
    (other live cloze answers), additionally excluding same-topic
    candidates where resolvable.
  * Tier B (OPEN_SLOT_WAIVER): 2 dictionary-form verbs + 1 bare particle,
    reused verbatim from the R8 sweep, tagged waiverReason="open frame".
  * Mixed: 2 Tier-A + 1 Tier-B distractor when only 2 clashing candidates
    exist (Fable-approved).

This script GENERATES candidates only -- it does not decide Tier B vs
Tier A on its own beyond a first-pass heuristic (`likely_open_frame`);
the actual per-item tier and final distractor picks are the result of a
full sentence-by-sentence read (recorded in the audit doc's "R8-2 full
read"), which overrides this script's first-pass suggestion wherever the
substituted sentence still reads as plausible.

Usage:
    python tools/content_factory/build_r8_2_tier_picks.py > r8_2_candidates.json
"""
from __future__ import annotations

import hashlib
import json
import random
from pathlib import Path

import cloze_distractor_rules as R
from distractor_rules import DICTIONARY_FORM_VERBS, BARE_PARTICLES
from fix_cloze_distractors_c2c import gather_verbadj_candidates

ROOT = R.REPO_ROOT
CLOZE = ROOT / "assets/data/cloze.json"
IDS_FILE = Path(__file__).parent / "r8_all_waived_ids.json"

CONCRETE_TOPICS = {
    "Essen & Trinken", "Essen & Zutaten", "Kleidung", "Anziehen & Accessoires",
    "Farben", "Körper", "Haushalt & Zimmer", "Haushalt & Praktisches",
    "Natur & Draußen", "Position", "Verkehr", "Reise & Verkehr", "Zahlen",
    "Stadt & Orte", "Schultasche", "Apotheke", "Krankenhaus & Apotheke",
    "Handytarif", "Friseursalon", "Fitnesskurs", "Im Restaurant", "Postamt",
}

VERB_POOL = sorted(DICTIONARY_FORM_VERBS)
PARTICLE_POOL = sorted(BARE_PARTICLES)


def eojeol_count(sentence_ko: str) -> int:
    return len(sentence_ko.replace(R.BLANK, "X").split())


_COPULA_TAILS = ("예요", "이에요", "입니다", "이다")


def likely_open_frame(sentence_ko: str, answer: str) -> bool:
    """First-pass heuristic only -- the real classification happens via
    the sentence-by-sentence read. True for bare existential/generic-
    adjective/copula frames with no anchoring content (<=3 eojeol, or a
    "다양한 X이 있어요"-shaped quantifier-existential), or a very short
    (<=4 eojeol) sentence where the blank sits right at the sentence's
    end (the whole predicate/response, PREDICATE_SLOT_WAIVER's shape but
    not yet curated -- a bare copula "X예요." is maximally open, same as
    a bare existential, since almost any noun can be "described as" X)."""
    n = eojeol_count(sentence_ko)
    open_pred = R.is_open_noun_slot(sentence_ko, answer)
    if open_pred and (n <= 3 or "다양한" in sentence_ko):
        return True
    tail = sentence_ko.rstrip(" .!?")
    blank_near_end = tail.endswith(R.BLANK) or any(
        tail.endswith(R.BLANK + suf) for suf in _COPULA_TAILS
    )
    if n <= 4 and blank_near_end:
        return True
    # Bare "그냥 주어/목적어 + 최소 서술" 프레임: 빈칸이 문두이고 문장이
    # 짧으며(<=4어절) 그 사이에 구체적 상황을 고정하는 앵커(장소/사물/행위
    # 명사)가 전혀 없는 경우 -- "＿＿＿ 뭐예요?"/"＿＿＿ 주세요"/"＿＿＿ 어디
    # 있어요?"/"＿＿＿ 같이 가요" 류. 문두 빈칸 + 간단한 요청/정체 서술은
    # 거의 모든 명사가 자연스럽게 들어맞는다.
    if n <= 4 and sentence_ko.startswith(R.BLANK):
        return True
    return False


def waiver_pick(cloze_id: str, remainder: str, n: int) -> list[str]:
    seed = int(hashlib.sha1((cloze_id + "-t2waiver").encode()).hexdigest(), 16)
    rng = random.Random(seed)
    verbs = [v for v in VERB_POOL if v not in remainder]
    particles = [p for p in PARTICLE_POOL if p not in remainder]
    rng.shuffle(verbs)
    rng.shuffle(particles)
    if n <= 2:
        return (verbs or VERB_POOL)[:n]
    return (verbs or VERB_POOL)[:2] + (particles or PARTICLE_POOL)[:1]


def concrete_noun_candidates(answer, level_rank, vocab, answer_topic, use_full_pool):
    cands = []
    pool_topics = None if use_full_pool else CONCRETE_TOPICS
    for lv in R.LEVEL_ORDER[: level_rank + 1]:
        for row in vocab.by_level.get(lv, []):
            w = row["korean"].strip()
            if not w or w == answer or " " in w:
                continue
            if row.get("pos_de") != "Nomen":
                continue
            if pool_topics is not None and row.get("topic") not in pool_topics:
                continue
            if answer_topic and row.get("topic") == answer_topic:
                continue
            cands.append(w)
    return sorted(set(cands))


_PRONOUN_SUBJECT_PREFIXES = ("저는", "제가", "저희는", "우리는", "제 친구는", "이것은", "그것은", "저것은")


def _is_pronoun_subject_phrase(word: str) -> bool:
    """True for a self-referential subject/topic phrase ("저는", "제
    친구는", ...) pulled from some OTHER cloze item's own answer. These
    are individually correct answers for THEIR OWN item, but reused as a
    Tier-A distractor for a DIFFERENT item they are a D7 trap: "저는
    좋아하지만..." reads as a fully valid alternate sentence regardless of
    which item's frame they're dropped into (Fable's R8 finding,
    cloze_a1_0314). Excluded from the general cross-item predicate pool
    entirely -- never a safe Tier-A candidate for another item."""
    return word.startswith(_PRONOUN_SUBJECT_PREFIXES)


def predicate_candidates(answer, a_sig, level_rank, answer_snapshot, vocab, answer_topic):
    base = gather_verbadj_candidates(answer, a_sig, level_rank, answer_snapshot)
    base = [w for w in base if not _is_pronoun_subject_phrase(w)]
    cross_topic = [w for w in base if vocab.pos_of(w) is None or (vocab.by_word.get(w) and vocab.by_word[w][0].get("topic") != answer_topic)]
    return cross_topic or base


def main() -> None:
    ids = json.loads(IDS_FILE.read_text(encoding="utf-8"))
    data = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = {it["id"]: it for it in data["items"]}
    vocab = R.VocabIndex(R.load_vocab_rows())
    # Every answer that is itself likely a fully droppable, self-contained
    # phrase (a bare predicate-slot response, a personal/temporal topic-
    # fronting subject, a greeting) is excluded from every OTHER item's
    # Tier-A candidate pool globally -- reusing one such answer as another
    # item's distractor is exactly the D7 leak Fable's R8 sample caught
    # (cloze_a1_0314: "저는"/"제 친구는" pulled in from other items'
    # answers "read" as valid alternate subjects regardless of the host
    # sentence). Not just the 502/40 R8 items -- ANY live cloze answer,
    # since the candidate pool draws on the whole corpus.
    open_frame_answers = {
        it2["answer"]
        for it2 in data["items"]
        if likely_open_frame(it2["sentenceKo"], it2["answer"])
    }
    answer_snapshot = [
        (it2["answer"], it2["level"])
        for it2 in data["items"]
        if it2["answer"] not in open_frame_answers
    ]

    out = {}
    for cid in ids:
        it = items[cid]
        answer, sentence, level = it["answer"], it["sentenceKo"], it["level"]
        level_rank = R.level_rank(level)
        remainder = R.sentence_remainder(sentence)
        d1_kind, required_class = R.detect_required_class(sentence, answer)
        particle_suffix = R.matching_particle_suffix(answer, vocab)
        a_sig = R.ending_signature(answer)
        # A bare noun that happens to END in a syllable also used as a
        # grammatical suffix (연고 "ointment", 사고/신고/창고 "accident/
        # report/warehouse" all end in the same "고" as the -고
        # connective) must route to the NOMINAL pool, not the predicate
        # pool -- ending_signature() is purely structural and has no way
        # to know "연고" is a whole exact-match vocab headword, not
        # headword+conjugation. Deliberately narrow: ONLY the "고" suffix
        # specifically (the one confirmed coincidental-noun-tail pattern
        # in this corpus) -- "다"/"요" are NOT included even though they
        # are also single characters, because a word ending there is
        # overwhelmingly a genuine dictionary-form verb or -요 predicate
        # (Korean nouns essentially never end in bare "다"), unlike "고"
        # which is common on ordinary Sino-Korean nouns. Applying this to
        # "다"/"요" broke genuine predicate/phrase answers like "같이
        # 웃다" and "인사드리겠습니다" (both pos_de=Ausdruck, both
        # genuinely conjugated) -- see the R8-2 mechanical-audit fixup.
        arow_exact = vocab.by_word.get(answer)
        if (
            arow_exact
            and arow_exact[0].get("pos_de") in ("Nomen", "Ausdruck", "Phrase", "Pronomen")
            and a_sig == "고"
        ):
            a_sig = None

        open_guess = likely_open_frame(sentence, answer)

        if particle_suffix:
            arow = vocab.by_word.get(answer)
            answer_topic = arow[0].get("topic") if arow else None
            use_full = level_rank >= R.level_rank("c1")
            base = concrete_noun_candidates(answer.rstrip(particle_suffix), level_rank, vocab, answer_topic, use_full)
            cands = sorted({w + particle_suffix for w in base})
            kind = "nominal-particle"
        elif a_sig is not None:
            cands = predicate_candidates(answer, a_sig, level_rank, answer_snapshot, vocab, None)
            kind = "predicate"
        else:
            coarse = R.coarse_pos(answer, vocab)
            arow = vocab.by_word.get(answer)
            answer_topic = arow[0].get("topic") if arow else None
            if coarse == "NOUN":
                use_full = level_rank >= R.level_rank("c1")
                cands = concrete_noun_candidates(answer, level_rank, vocab, answer_topic, use_full)
                kind = "nominal"
            else:
                # bare adverb/expression answer -- pool of other same-level
                # adverbs from a different topic (a different discourse
                # stance/domain reads as a clean semantic clash for these:
                # "결국"(eventually) vs "아마"(maybe)/"거의"(almost)).
                cands = []
                for lv in R.LEVEL_ORDER[: level_rank + 1]:
                    for row in vocab.by_level.get(lv, []):
                        w = row["korean"].strip()
                        if w == answer or row.get("pos_de") != "Adverb":
                            continue
                        if answer_topic and row.get("topic") == answer_topic:
                            continue
                        cands.append(w)
                cands = sorted(set(cands)) or sorted(R.CLOSED_ADV_WORDS - {answer})
                kind = "adverb"
                # Read-verified finding (R8-2 full read, chunk 3): a bare
                # frequency/manner/degree adverb modifying an otherwise
                # unconstrained verb ("저는 지금 ___ 가요.", "저희 가게에
                # ___ 오세요!") accepts almost any other adverb of the same
                # shape too (항상/다시/꼭/천천히 all fit "오세요" equally
                # well) -- cross-domain adverb swapping is NOT a reliable
                # Tier-A clash technique the way cross-domain NOUN swapping
                # is, so these default to Tier B.
                open_guess = True

        def viable(c):
            if c == answer or c in remainder:
                return False
            if required_class is not None:
                bc = R.batchim_class(c, d1_kind)
                if bc is not None and bc != required_class:
                    return False
            return True

        cands = [c for c in cands if viable(c)]
        seed = int(hashlib.sha1((cid + "-t2cands").encode()).hexdigest(), 16)
        rng = random.Random(seed)
        rng.shuffle(cands)

        out[cid] = {
            "kind": kind,
            "open_guess": open_guess,
            "candidates": cands[:12],
        }

    print(json.dumps(out, ensure_ascii=False))


if __name__ == "__main__":
    main()
