# Textbook Project State — 2026-10-06

## Git/worktree

- branch: session/textbook-publishing-20261006
- worktree: C:\dev\hangulsori\ko_lernen_textbook_worktree
- base checkpoint: 452b740bc
- original main worktree intentionally untouched

## Integrated source programs

- canonical A1–C2 Level Bible
- canonical 32-topic taxonomy
- Living Korea 23-scene / 138-turn reviewed Korean checkpoint
- relationship-first dialogue authoring contract
- trilingual native-usage corpus program
- display/spoken/TTS surface policy
- culture/source/rights governance

## New textbook project layer

- Korean 1–6 master seed
- grammar/vocabulary syllabus seeds
- 1A–6B alignment contract
- source-of-truth bridge
- trilingual native-usage bridge
- display/spoken/performance audio policy
- publishing data model
- app-to-textbook mapping plan
- publication quality gates
- cross-domain topic alias overrides
- executable content inventory + tests

## Current inventory

Tracked: 5,961
Mapped to 32-topic axis: 5,634
Unmapped/ambiguous: 327
Deduplicated manual decisions: 193
Sentence-building mapped: 2,885 / 2,885

Generated:
- docs/textbook_project/data/APP_CONTENT_INVENTORY.csv
- docs/textbook_project/data/APP_CONTENT_INVENTORY_SUMMARY.json
- docs/textbook_project/data/MANUAL_TOPIC_REVIEW_QUEUE.csv
- docs/textbook_project/APP_CONTENT_INVENTORY_REPORT.md

## Validation checkpoint

- 8 dialogue contract tests PASS
- 9 Living Korea manifest tests PASS
- 6 trilingual registry tests PASS
- textbook inventory regression PASS
- validate_content.py PASS

## Important decisions

Research coverage != content approval.
Automatic taxonomy != publication approval.
Uncertain mapping stays explicit, never silently forced.
EN and DE are independently authored from KO semantic intent + native evidence.
TTS remains Jin-owned.
Display text and spoken text are separate fields.

## Next executable phase

1. manually resolve the 193 deduplicated topic decisions;
2. generate textbook reuse decisions: KEEP / REWRITE / RELEVEL / REJECT;
3. build 1A–6B unit matrix against live coverage and Level Bible ceilings;
4. deep-research Tier-1 topic language independently in KO/EN/DE;
5. build EN-L1 and DE-L1 learner-error evidence tables;
6. create one 1A pilot unit family and test it with adult learners.

## Graphify

check-update exited successfully.
Full update and --no-cluster update both entered silent input-wait state and produced no graphify-out changes; sessions were terminated safely.
No Graphify reindex completion is claimed for this branch.

## First-pass reuse audit checkpoint

Completed 2026-10-06 for all 5,961 tracked items.

Decisions:
- KEEP 5,813
- REWRITE 128
- RELEVEL 12
- REJECT 8

Validation:
- textbook reuse audit regression PASS
- textbook inventory regression PASS
- content validation PASS

Key audit rule:
Current Level Bible/current live vocab placement outranks historical relevel candidate sheets. Historical conflicts are advisory unless the current exercise actually places a target above its current canonical level.

The 327 unresolved topic-map rows are a separate taxonomy-review issue and do not automatically reduce reuse quality.

Next:
1. work REJECT 8 replacements first;
2. resolve RELEVEL 12;
3. rewrite 128 in priority order;
4. then run second-pass editorial review on KEEP exercise-bank candidates before publication.
