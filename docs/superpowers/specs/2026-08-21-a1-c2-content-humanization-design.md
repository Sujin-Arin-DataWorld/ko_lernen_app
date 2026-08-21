# A1-C2 Content Humanization Design

## Goal

Audit every learner-facing text value shipped from `assets/data` and improve diagnosed Korean, German, and English copy without changing IDs, levels, learning targets, answer contracts, course links, or loader behavior. The work also closes the C-level lower-level-card leak and leaves reproducible proof of what was inspected, changed, or intentionally preserved.

## Approved Scope

- Levels: A1, A2, B1, B2, C1, C2.
- Runtime surfaces: all 22 CSV/JSON files classified by `tools/content_factory/audit_content_text.py`.
- Authoring lineage: matching files under `tools/content_factory/data`, `drafts`, and `review` whenever runtime copy changes.
- Selection behavior: daily challenge, today/review deck, and personalized lesson level filtering.
- Completion flow: modify, verify, commit and push the task branch, integrate into `main`, verify the integrated head, remove the task worktree, and delete the local and remote task branch.

## Interpretation of “Full Update”

Full coverage means every learner-copy leaf is enumerated and receives a reproducible disposition. It does not mean rewriting correct text merely to make a diff. Each leaf is classified as:

1. `preserved`: schema-valid, level-appropriate, and free of a diagnosed Beyond Humanizer defect.
2. `changed`: corrected for `ACC`, `PRAG`, `REL`, `CULT`, `NAT`, `TERM`, `CEFR`, `ITEM`, or `DATA`.
3. `human_gate`: structurally safe but requiring Korean-language educator or native-speaker judgment that automation cannot truthfully claim.

The shipped result must have no unresolved critical `ACC`, `REL`, `CULT`, `ITEM`, or `DATA` defects. Human review remains a release-quality gate and is never fabricated by changing an approval hash.

## Data Flow and Authority

```text
factory source -> schema-complete draft -> review ledger -> runtime asset -> Dart loader
```

- Canonical/Jin-locked Korean remains unchanged unless the existing source itself proves a defect.
- Generated or human-editable Korean may receive a minimal correction after target grammar and required surface form are locked.
- German and English are reconstructed independently from the same PIVOT.
- IDs, keys, array ordering contracts, levels, `courseUnitId`, `conceptIds`, grammar IDs, placeholders, accepted answers, distractor contracts, and TTS voice roles remain stable.
- PDF wording, page numbers, IDs, and unit order never enter app data.

## Coverage Ledger

The audit tool will expose a deterministic leaf ledger containing file, record identity, level, field path, language, content hash, and disposition. The ledger is generated during validation rather than committed as a 73,000-line artifact. A compact Markdown report records totals per file and level, changed IDs, human-gate counts, and commands used.

Legitimate optional blanks in legacy A1-B2 scenario metadata are counted separately from missing required text. Unclassified files, duplicate keys/IDs, replacement characters, unresolved markers, broken multilingual triplets, or missing required learner copy fail the gate.

## Humanization Strategy

For each diagnosed record:

1. Lock fact, time, polarity, modality, causality, participants, speech act, relationship, culture, and learning target.
2. Create the PIVOT: proposition, speech act, stance/affect, relationship, information, culture, pedagogy, and forbidden invention.
3. Judge Korean authority and make the smallest justified edit.
4. Rebuild EN and DE independently, respecting level and channel.
5. Triangulate KO-DE, KO-EN, and DE-EN.
6. Update every authoritative source/draft/review/runtime copy of the record.

## Level Standard

- A1-A2: concrete situations, one principal burden, short usable utterances; natural language is not sacrificed for artificial simplicity.
- B1-B2: explicit causes, results, comparisons, conditions, and relationship-appropriate workplace/media/social language.
- C1-C2: precise control of viewpoint, evidence, institutional causality, responsibility, authority, implication, and mediation without gratuitous bureaucratic vocabulary.
- Exact-level selection applies to new and due-review content. A shorter C-level round is preferable to filling it with A1 cards.

## Quality Gates

- Structure: all 22 shipped files classified; UTF-8 clean; no duplicate JSON keys or record IDs; no unresolved markers.
- Pedagogy: Cloze has exactly one contextually correct answer; Satz prompts preserve the target and token assembly; scenario roles/register remain continuous.
- Synchronization: every changed runtime record matches its source and draft/review lineage where such lineage exists.
- Runtime: all relevant loaders and level-routing tests pass.
- Regression: C1/C2 today/review/personalized pools exclude lower-level overdue cards.
- TTS: changed Korean speech text is listed as stale and verified against the TTS manifest; synthesis/upload requires separate explicit authorization if credentials or billable calls are involved.
- Git: only task-owned files are staged. Main integration happens from a clean detached merge worktree so concurrent main-checkout work is untouched.

## Git Completion

After fresh local verification, commit and push `codex/content-humanization-20260821`. Fetch `origin/main`, integrate the exact task head in a clean temporary worktree, rerun the required final gates, and push the verified integrated head to `main`. Then remove both temporary worktrees, delete the local task branch, and delete the remote task branch. If `origin/main` moves during integration, fetch and rebuild the merge result rather than force-pushing.

## Non-Goals

- No PDF text copying.
- No fabricated native-speaker or educator approval.
- No direct Firebase, store, or TTS synthesis/upload without a separately satisfied operational gate.
- No unrelated UI, architecture, asset, or localization refactor.
