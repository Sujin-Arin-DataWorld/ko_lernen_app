# Phase 3A Closeout — Human Review & Pilot Operational Readiness

Date: 2026-10-06

Status: **OPERATIONALLY_READY / REAL_HUMAN_EVIDENCE_NOT_YET_COLLECTED**

Phase 3A prepares the workflow for real human evidence.
It does not fabricate reviewer approval or learner results.

## 1. Unit 04 human-review lanes

Independent review forms now exist for:

- Korean educator
- English pedagogy
- German pedagogy
- audio / spoken surface

Each reviewer marks:
- PASS
- EDIT
- HOLD

and then gives a lane decision:
- APPROVE
- APPROVE_WITH_EDITS
- HOLD

The structured decision record is tied to:
- frozen source commit
- review manifest SHA-256

Current lane state:
**OPEN / OPEN / OPEN / OPEN**

## 2. Review decision integrity

Schema:
`schemas/HUMAN_REVIEW_DECISION.schema.json`

Validator:
`tools/textbook_project/validate_unit04_human_review_decisions.py`

The validator prevents:
- ready-for-pilot state with blank reviewers;
- ready-for-pilot state with missing dates;
- ready-for-pilot state with blank checks;
- ready-for-pilot state with HOLD;
- decision record drifting away from the frozen manifest.

## 3. EN / DE pilot cohorts

Two cohort templates:

- `1A_U04_EN_PILOT_01`
- `1A_U04_DE_PILOT_01`

Initial template size:
5 pseudonymous participants each.

Suggested discovery range remains 5–8 adults per L1.

No name/email is required in the structured event log.

## 4. Stage isolation

Each edition has separate participant/facilitator sheets for:

1. baseline
2. immediate post
3. delayed 24h
4. delayed 7d
5. transfer

Future-stage prompts are not shown early.

This prevents delayed retrieval from turning into simple rehearsal.

## 5. Changed-context retrieval

Unit 04 examples:

Baseline:
- one Americano

Immediate:
- one tteokbokki + spicy/mild decision

24h:
- one juice + takeaway

7d:
- one tea + iced + staff follow-up

Transfer:
- bakery sandwich + takeaway

The communicative function remains related while lexical/context details change.

## 6. Pilot log validation

The original sample log was normalized to the stable pilot IDs.

Old temporary ID:
`u04_exit_interaction`

Current stable IDs:
- `1A.PILOT.U04.B0`
- `1A.PILOT.U04.I0`
- `1A.PILOT.U04.D1`
- `1A.PILOT.U04.D7`
- `1A.PILOT.U04.TR`

A previous sample error label `counters` was also corrected to:
- `errorType=form`
- `transferRiskRef=EN-A1-COUNTERS`

This keeps the event log consistent with the canonical schema.

## 7. Automated pilot summary

Tool:
`tools/textbook_project/summarize_one_a_pilot_log.py`

It validates:
- event schema
- pilot task ID
- task stage
- unit
- cohort ID
- participant membership
- L1/edition match
- scheduled tasks

Then summarizes:
- results by stage
- results by L1
- error types
- transfer-risk references
- prompt levels
- self-correction
- comprehension breakdown
- independent correct responses
- delayed independent retrieval

Small discovery-pilot results must not be generalized to all EN/DE learners.

## 8. Operational readiness validator

Tool:
`tools/textbook_project/validate_phase3_operational_readiness.py`

Current result:

- review forms: 4
- cohort templates: 2
- stage sheets: 10
- pilot registry: 50
- sample events: 2

PASS.

## 9. What remains genuinely external

Still not complete:

- real Korean educator decision
- real English pedagogy decision
- real German pedagogy decision
- Jin final audio/spoken decision
- real EN learner events
- real DE learner events
- 24h learner data
- 7d learner data
- human-driven revision decisions

These are intentionally left open.

## 10. Next action when people are available

1. Korean educator reviews Unit 04.
2. EN reviewer reviews Unit 04 EN edition.
3. DE reviewer reviews Unit 04 DE edition.
4. Jin reviews audio/spoken surface.
5. Apply required edits.
6. Freeze a new review snapshot if reviewed files changed.
7. Mark human review ready for pilot.
8. Run EN cohort.
9. Run DE cohort.
10. Summarize immediate / 24h / 7d / transfer evidence.
11. Revise the 1A template before expanding 1B.

This is the first point at which progress depends on real human evidence rather than additional model-authored curriculum.
