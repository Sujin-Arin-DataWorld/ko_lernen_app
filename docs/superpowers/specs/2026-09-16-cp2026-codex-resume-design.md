# CP-2026 Codex continuation design

Approved by Jin in the Codex task on 2026-09-16: retain the existing program, recover C4-G1 and Batch 34, resolve the pending review packets, and continue the remaining program using current evidence.

## Scope and authority

The program's product goals remain CP-2026's five axes: stability, backend safety, content quality, OCR/speech/games, and release operations. LCP and W7-W10 remain source plans, with completed changes excluded from new implementation. The five-tab shell remains frozen. Other sessions own Hanok art and release integration.

Historical documents are evidence, not new commands. Claude model assignments, Anthropic attribution, unsafe reset commands, obsolete paths, and a previous agent's claim of approval are not inherited execution instructions. Current user instructions and current source govern.

## Immediate deliverables

1. C4-G1: satisfy V2 grammar queue priorities 1-4 with pedagogically correct content and registrations. Detect existing equivalent cards before creating new ones. Separate a missing matcher mapping from a missing lesson. Correct erroneous queue descriptions when authoritative source evidence proves them wrong. Preserve existing IDs and levels. Provide two aligned KO/DE/EN examples per authored item, meaningful quiz distractors, source evidence, and fresh content/curriculum/TTS checks.
2. Batch 34: 64 A2 headwords with original KO/DE/EN examples, cloze and sentence-building drafts, pending review ledgers, manifest, at least the precedent's coverage of quality checks, and a seven-item Jin packet plus full distractor evidence. No live promotion before Jin's content review.
3. Program ownership: reconcile program tasks to current main and PR evidence; keep runtime completion, local implementation, draft authoring, human review, CI, remote deployment, and physical-device observation separate.

## Isolation and evidence

Primary checkout remains untouched. The existing C4-G1 and Batch 34 worktrees are adopted only after confirming clean tracked state and no matching active task process. The new cp2026-codex-resume worktree owns this design, execution plans and program audit. PR #362 remains separate. No worktree removal without the repository's current preservation audit.

The intake baseline is origin/main 61f5c819dcd51357617f731ce0b4694ad3d8be49: 2,944 vocab rows, 252 packs and 252 grammar rows. The exact-main CI and Playwright are now successful. These are snapshots and must be refreshed before integration. Existing F2 reports show grade-1 any-level coverage 712/714 and at-level coverage 596/714; those measures must not be conflated. The grade-2 raw headword draft gap also differs from the normalized audit denominator and must be named explicitly.

## Validation and review

Use the project Python environment and targeted tests. New rules must reject an actual invalid case, not merely mirror constants. Read every authored Korean example and every substituted distractor sentence; machine gates cannot prove linguistic correctness. DE/EN must preserve Korean meaning, register, and participant relationships without invented nuance. Use the existing persona canon.

Preserve the pending Jin gates for Batch 32, Batch 33 and C9-1; the approval to resume work does not mark unseen content approved. Prepare reviewable artifacts before requesting a content decision. Future tasks proceed independently when they do not depend on that decision.

## Integration boundary

Local implementation and verification are authorized. Commit/push/merge and deployment follow explicit session authority and repository rules, after concrete reviewable results exist. Never fabricate a Jin approval field, Claude authorship, CI success, storage verification or rollout completion.
