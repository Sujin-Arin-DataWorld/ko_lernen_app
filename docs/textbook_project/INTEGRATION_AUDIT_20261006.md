# Textbook + Living Korea / Trilingual Corpus Integration Audit

Date: 2026-10-06
Branch: session/textbook-publishing-20261006
Base checkpoint: 452b740bc — docs(localization): checkpoint trilingual corpus and TTS surfaces

## What was integrated

The publishing project now consumes, rather than duplicates, the Living Korea and trilingual-native-usage contracts.

Integrated canonical sources:
- 23-scene / 138-turn Living Korea reviewed checkpoint
- relationship-first dialogue authoring contract
- 32-topic KO/EN/DE native-usage registry
- broad/deep corpus evidence thresholds
- approval-state independence
- display vs spoken vs TTS/performance surface policy
- current source/rights policy
- canonical A1–C2 Level Bible and 32-topic taxonomy

## New publishing bridge

Added:
- source-of-truth map
- Korean 1–6 / 1A–6B alignment
- trilingual usage integration contract
- display/spoken/TTS publishing policy
- shared KO/EN/DE data model
- app-to-textbook mapping plan
- publication quality gates
- curated cross-domain topic alias bridge
- executable content inventory
- deduplicated manual topic-review queue
- inventory regression tests

## Content inventory checkpoint

Total tracked learning items: 5,961

Surface counts:
- live scenarios: 191
- canonical authored scenarios: 120
- smalltalk lessons: 209
- listening lessons: 191
- cloze: 2,365
- sentence building: 2,885

32-topic mapping:
- mapped automatically: 5,634
- unresolved / intentionally ambiguous: 327
- sentence-building mapped: 2,885 / 2,885
- deduplicated manual review decisions: 193

The remaining items are not silently forced into a category.
They retain unmappedReason and enter manual review.

## Validation

Passed on this branch:
- dialogue authoring contract tests: 8 / 8
- Living Korea program manifest tests: 9 / 9
- trilingual native-usage registry tests: 6 / 6
- textbook inventory regression: PASS
- content validation: PASS

Total inherited targeted tests: 23 / 23 PASS.

## TTS rule preserved

Display != spoken != performance cue.

Korean ㅋㅋ/ㅎㅎ, English typed reaction forms such as lol/lmao, German chat spellings, emoji and repeated punctuation are not automatically lexical TTS input.

TTS remains Jin-owned.

## Git isolation

The user's original main worktree was not modified.
It still contains its own Graphify changes and myproject/ state.

This integration was performed in:
C:\dev\hangulsori\ko_lernen_textbook_worktree

## Next audit

1. Resolve 193 manual topic decisions.
2. Generate KEEP / REWRITE / RELEVEL / REJECT textbook-reuse decisions.
3. Build stable 1A–6B unit matrix from current Level Bible and topic coverage.
4. Run Tier-1 KO/EN/DE native-usage deep pass.
5. Add EN-L1 / DE-L1 learner-error evidence matrix.
6. Pilot one 1A unit family only after the above gates.

## Graphify status

- graphify check-update .: exit 0
- full graphify update . attempted: process entered input-wait with no output
- graphify update . --no-cluster attempted: same input-wait behavior
- graphify-out/ changed files: none
- both waiting sessions were terminated safely
- no Graphify output is claimed or committed by this textbook integration

A future session can diagnose the Graphify CLI interaction separately without blocking the textbook work.
