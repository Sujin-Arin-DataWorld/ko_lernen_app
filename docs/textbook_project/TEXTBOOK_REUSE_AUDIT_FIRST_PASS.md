# Textbook Reuse Audit — First Pass

Date: 2026-10-06

This is a reuse triage, not a publication-ready claim.

Total audited: **5,961**

## Decisions

| Decision | Count | Meaning |
|---|---:|---|
| KEEP | 5,813 | Keep in textbook source pool; no known blocking reuse issue. Not a publication-ready claim. |
| REWRITE | 128 | Keep the learning intent/topic but rewrite wording, distractors, localization, pragmatics, or exercise realization. |
| RELEVEL | 12 | Content is reusable but current instructional level needs reassessment/reassignment. |
| REJECT | 8 | Do not reuse this exact learning target/item as a textbook source; replace or retire it. |

## By surface

| Surface | KEEP | REWRITE | RELEVEL | REJECT |
|---|---:|---:|---:|---:|
| canonical_scenario | 120 | 0 | 0 | 0 |
| cloze | 2,330 | 26 | 5 | 4 |
| listening_lesson | 178 | 13 | 0 | 0 |
| live_scenario | 178 | 13 | 0 | 0 |
| sentence_building | 2,833 | 48 | 0 | 4 |
| smalltalk_lesson | 174 | 28 | 7 | 0 |

## By level

| Level | KEEP | REWRITE | RELEVEL | REJECT |
|---|---:|---:|---:|---:|
| A1 | 1,398 | 11 | 6 | 0 |
| A2 | 948 | 15 | 1 | 0 |
| B1 | 1,174 | 15 | 0 | 0 |
| B2 | 1,082 | 21 | 0 | 0 |
| C1 | 583 | 31 | 2 | 4 |
| C2 | 628 | 35 | 3 | 4 |

## Main blocking signals

| Signal | Count |
|---|---:|
| LEXICAL_UNIT_REWRITE_BEFORE_LEVELING | 80 |
| SMALLTALK_PENDING_ROUTING_FLAG | 19 |
| SCENARIO_DIRECT_REVIEW_PENDING | 13 |
| LISTENING_SOURCE_SCENARIO_REVIEW_PENDING | 13 |
| SMALLTALK_PENDING_EDITORIAL_OR_CONTEXT_FLAG | 9 |
| TARGET_LEXEME_MARKED_FOR_REPLACEMENT | 8 |
| SMALLTALK_PENDING_LEVEL_ROUTING_FLAG | 7 |
| TARGET_VOCAB_ABOVE_EXERCISE_LEVEL | 5 |

## Important interpretation

- KEEP means preserve in the textbook source pool, not publish unchanged.
- App cloze/sentence-building items remain second-pass-required even when KEEP.
- Topic ambiguity does not automatically downgrade content quality.
- REJECT is intentionally narrow and reserved for source targets that should be replaced, not merely polished.

## Outputs

- data/TEXTBOOK_REUSE_AUDIT_FIRST_PASS.csv
- data/TEXTBOOK_REUSE_AUDIT_FIRST_PASS_SUMMARY.json
- data/TEXTBOOK_REUSE_KEEP_QUEUE.csv
- data/TEXTBOOK_REUSE_REWRITE_QUEUE.csv
- data/TEXTBOOK_REUSE_RELEVEL_QUEUE.csv
- data/TEXTBOOK_REUSE_REJECT_QUEUE.csv
