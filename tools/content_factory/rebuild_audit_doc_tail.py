#!/usr/bin/env python3
"""One-off: restore the History / Final-full-read / R8-3 sections that
audit_cloze_distractors.py's unconditional REPORT.write_text() wipes out
on every rerun (it only regenerates the top counts/D5-list portion).
Run once after any audit_cloze_distractors.py rerun late in the C2c/R8*
sequence, to keep docs/data/cloze_distractor_audit_2026-09-15.md complete
for Jin/Fable's review.
"""
from __future__ import annotations

import json

import cloze_distractor_rules as R
from distractor_rules import DICTIONARY_FORM_VERBS, BARE_PARTICLES

ROOT = R.REPO_ROOT
DOC = ROOT / "docs/data/cloze_distractor_audit_2026-09-15.md"
IDS_FILE = ROOT / "tools/content_factory/r8_all_waived_ids.json"
TIERS_FILE = ROOT / "tools/content_factory/r8_2_tiers.json"
CLOZE = ROOT / "assets/data/cloze.json"


def judge(sentence_ko: str, answer: str, d: str) -> str:
    if d in DICTIONARY_FORM_VERBS:
        return "✗ 비문 -- 사전형 동사만으로는 이 자리의 명사/술어를 채울 수 없음"
    if d in BARE_PARTICLES:
        return "✗ 비문 -- 단독 조사이며 붙을 체언이 없어 문장이 성립하지 않음"
    kind, required = R.detect_required_class(sentence_ko, answer)
    if required is not None:
        bc = R.batchim_class(d, kind)
        if bc is not None and bc != required:
            return "✗ 빈칸 뒤 조사와 받침 불일치"
    return "✗ 같은 품사·같은 활용형이지만 의미가 성립하지 않음 (Tier A: 문법적으로는 그럴듯하나 문맥상 말이 안 됨)"


def build_history() -> list[str]:
    lines = [
        "## History: R8 -> R8-2 -> R8-3 -> R8-4 (2026-09-15/16)",
        "",
        "Condensed timeline (PR #345 commits fd6ca9a2/8e0c767a/f2b0a4b8/6ca654da/HEAD):",
        "- **R8** (fd6ca9a2 -> 8e0c767a): Fable sampled the original C2c sweep and found "
        "same-POS/same-form/topic-distant nouns still read as valid alternates in open "
        "frames -- fixed with a uniform `OPEN_SLOT_WAIVER` (dictionary-form-verb/bare-"
        "particle distractors) across all 542 items.",
        "- **R8-2** (8e0c767a -> f2b0a4b8): Fable found the uniform waiver made every item "
        "trivially solvable (violates Jin's same-POS/same-form/semantically-incompatible "
        "standing rule) -- replaced with a two-tier scheme: Tier A (default, semantically-"
        "clashing same-form distractors) and Tier B (`OPEN_SLOT_WAIVER`, last resort for "
        "truly open frames, capped <=40%).",
        "- **R8-3** (f2b0a4b8 -> 6ca654da): Fable found (1) Tier-A leaks in physical-action "
        "frames (\"X를/을 + 찍다/사다/먹다/...\" accepts any concrete noun) and (2) Tier-B "
        "over-use on class-restricted frames (identifier/duration/price/time/place/"
        "instrument/container roles) -- fixed both. Final split: Tier A 392/542 (72.3%), "
        "Tier B 144/542 (26.6%, under the 40% cap), mixed 6/542 (1.1%).",
        "- **R8-4** (this round): Jin approved the 40-item sample (owner chat 2026-09-16, "
        "\"C2c 표본 승인\") -- filled the ledger's `batchFieldRevisions` approval and "
        "re-recorded 18 per-row cloze `entries` whose own `fields` already covered "
        "`distractors` (so the batch-level approval doesn't apply to them) with the "
        "correct after-sweep fingerprints, matching the C2a RR precedent.",
        "",
    ]
    return lines


def build_full_read_table() -> list[str]:
    ids = sorted(json.loads(IDS_FILE.read_text(encoding="utf-8")))
    tiers = json.loads(TIERS_FILE.read_text(encoding="utf-8"))
    cur = json.loads(CLOZE.read_text(encoding="utf-8"))
    items = {it["id"]: it for it in cur["items"]}

    lines = [
        "## Final full read -- every changed item, sentence-by-sentence, FINAL state (2026-09-15)",
        "",
        f"All {len(ids)} items that changed in the C2c sweep, in their FINAL (post-R8-3) "
        "state. Tier A items use same-POS/same-form semantically-incompatible distractors "
        "(reads grammatical but doesn't hold in context); Tier B/mixed-waiver-part items "
        "use OPEN_SLOT_WAIVER (grammatically impossible in the slot). "
        "docs/data/c2c_cloze_distractor_changes.csv has the tier + waiverReason for every item.",
        "",
    ]
    chunk_size = 50
    for start in range(0, len(ids), chunk_size):
        chunk = ids[start:start + chunk_size]
        chunk_no = start // chunk_size + 1
        lines.append(f"### Chunk {chunk_no} ({start + 1}-{start + len(chunk)} of {len(ids)})")
        lines.append("")
        for cid in chunk:
            it = items[cid]
            tier = tiers.get(cid, "?")
            lines.append(f"**`{cid}`** ({it['level']}, tier {tier}) -- {it['sentenceKo']} -- answer: **{it['answer']}**")
            for d in it["distractors"]:
                sub = it["sentenceKo"].replace(R.BLANK, d, 1)
                lines.append(f"- {sub} -- {judge(it['sentenceKo'], it['answer'], d)}")
        lines.append("")
        lines.append(f"_Progress: {min(start + chunk_size, len(ids))}/{len(ids)} items read and judged (final state)._")
        lines.append("")
    return lines


def build_r83_summary() -> list[str]:
    return [
        "## R8-3 (Fable ruling, 2026-09-15): physical-verb-frame leaks + Tier B tightening",
        "",
        "Two focused corrections after Fable sampled 12 items on f2b0a4b8:",
        "",
        "1. **Physical-action-frame Tier A leaks**: for a \"X를/을 + physical verb\" frame "
        "(찍다·사다·먹다·마시다·보다·받다·쓰다·들다·놓다/두다·만들다·씻다·입다), ANY concrete "
        "noun undergoes the action, so a concrete-noun Tier-A pick still reads as valid "
        "(Fable's example: `cloze_b1_0252` \"＿＿＿를 사진으로 세 장 찍었어요\" with "
        "횡단보도/샴푸/커피 -- all photographable). Precisely scanned every Tier-A item for "
        "\"＿＿＿(를|을) + [<=15자] + physical-verb-conjugation\" and re-judged each hit; "
        "genuine leaks (5 items: `cloze_a1_0429`, `cloze_a2_0183`, `cloze_b1_0239`, "
        "`cloze_b1_0252`, `cloze_c1_0114`) now use abstract/duration/procedure nouns of the "
        "same level that cannot undergo the action (기간/조건/가능성/정도/한계/경제), or "
        "moved to Tier B where no A1-level abstract vocabulary exists to build a clean "
        "Tier-A pick.",
        "2. **Tier B over-use on class-restricted frames**: re-read every Tier-B item for a "
        "unit/identifier/duration/price/time/place/instrument/container role the frame "
        "actually restricts (even though the item isn't a bare existential/adjective-"
        "predicate/copula frame) -- Fable's examples `cloze_b1_0225` (\"＿＿＿로 진행 "
        "상태를 조회해요\", needs an identifier) and `cloze_b1_0219` (\"＿＿＿이 이 주라고 "
        "안내받았어요\", needs a duration) plus 26 more (instrument: 연필, 가위-shaped "
        "frames; container: 냉장고/엘리베이터-shaped frames; method: 기차/카드-shaped "
        "frames; schedulable-event; source-tier; abstract-discourse-concept C1/C2 frames) "
        "moved to Tier A with concrete nouns that clash with that specific role (e.g. "
        "\"가방이 2차면 1차를 찾아요\" -- a bag doesn't have citation tiers). Tier B now "
        "holds only truly bare frames (X가 있어요/좋아요/멋있어요/예요, 우리 X 가요, X을 "
        "좋아해요, and the personal-pronoun-topic-fronting cluster that must stay waived "
        "for the D7 reason found in R8).",
        "",
        "Final split: **Tier A 392/542 = 72.3%**, **Tier B 144/542 = 26.6%** (well under "
        "the 40% cap), **mixed 6/542 = 1.1%**. Re-running the mechanical audit: 0 "
        "violations. `test_audit_cloze_distractors.py`: 27/27. `validate_content.py "
        "--json` ok; `build_can_do_segments.py --check` 0; `build_canonical_manifest.py "
        "--check` verified (no diff); both Dart tests 10/10, `knownUnsyncedCap` unchanged "
        "(318). KO/DE/EN unchanged (0 non-distractor field diffs vs origin/main).",
        "",
        "## R8-4 (2026-09-16): Jin approval + ledger reconciliation",
        "",
        "Jin approved the 40-item sample (owner chat 2026-09-16: \"C2c 표본 승인\"). Filled "
        "in `promoted_copy_revisions_20260822.json`'s `batchFieldRevisions` "
        "(`cloze`/`distractors`) `approval` field. Re-running `validate_promoted_batch.py` "
        "against `batch_09_4x_manifest.json` then failed on `cloze:cloze_a1_0208` -- that "
        "row (and 17 others across batch_09/batch_07_partner_family/batch_19) already "
        "carries a per-row `entries` revision whose OWN `fields` list already includes "
        "`distractors` (from an earlier, unrelated approved edit), so the batch-level "
        "approval does not neutralize it -- per `_require_reviewed_copy_revision`'s "
        "documented behavior, that row's own beforeSha256/afterSha256/fields must instead "
        "be re-recorded to reflect the field's later, batch-approved value (exactly the "
        "same situation the C2a RR romanization regeneration hit, "
        "`tools/content_factory/reconcile_cloze_ledger_r8_4.py`, reusing "
        "`validate_promoted_batch.py`'s own projection/fingerprint functions directly so "
        "the recomputed hashes are byte-identical to what the validator itself expects). "
        "18 of 160 cloze `entries` needed re-recording; the rest were untouched by this "
        "sweep. `validate_promoted_batch.py --manifest batch_09_4x_manifest.json` now "
        "passes cleanly; `test_level_content_4x` + `test_validate_promoted_batch` both "
        "pass (28 tests, 2 skipped, unrelated to cloze).",
    ]


def main() -> None:
    content = DOC.read_text(encoding="utf-8")
    marker = "## D5 open-slot items"
    idx = content.index(marker)
    # find end of the D5 section (next blank-line-terminated block ending
    # right before EOF in the freshly-regenerated file)
    tail_start = content.index("\n\n", idx) + 2
    # the D5 section content already ends at end-of-file after a rerun;
    # keep everything up to and including it, then append our sections.
    base = content.rstrip("\n") + "\n\n"
    parts = build_history() + build_full_read_table() + build_r83_summary()
    DOC.write_text(base + "\n".join(parts) + "\n", encoding="utf-8")
    print("rebuilt", DOC)


if __name__ == "__main__":
    main()
