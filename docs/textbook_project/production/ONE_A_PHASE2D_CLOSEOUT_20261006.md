# Phase 2D Closeout — Korean 1A Pilot-Ready System

Date: 2026-10-06

Status: **PHASE_2D_COMPLETE_READY_FOR_HUMAN_REVIEW_AND_PILOT**

Phase 2D does not claim that human review or real learner pilot has already happened.

It means the 1A system now contains everything needed to run those processes reproducibly.

---

# 1. Stable task IDs

Created:
**190 stable task IDs**

- unit tasks: 160
- pair-review tasks: 24
- final-review tasks: 6

The ID is stable across layout changes.

Page location is metadata, not identity.

Outputs:
- `ONE_A_TASK_REGISTRY_20261006.json`
- `ONE_A_PAGE_TASK_MAP_20261006.csv`
- `ONE_A_TASK_REGISTRY_20261006.md`

---

# 2. Full answer-key coverage

Answer entries:
**196**

The extra six are detailed Unit 04 sub-item keys preserved from the reference vertical slice.

Closed tasks:
**16**

Closed tasks with exact answers:
**16 / 16**

Open tasks use:
- accepted variants;
- sample-only guidance;
- rubrics;
- self-check policy.

The answer key therefore does not pretend that a speaking task has one fake “correct sentence.”

Output:
`ONE_A_ANSWER_KEY_REGISTRY_20261006.json`

Schema:
`schemas/ANSWER_KEY_ENTRY.schema.json`

---

# 3. Pair reviews

Created four two-page review contracts:

- R12 — Units 1–2
- R34 — Units 3–4
- R56 — Units 5–6
- R78 — Units 7–8

Each contains six stable tasks.

Total pair-review tasks:
**24**

Rendered learner editions:
- EN × 4
- DE × 4

The reviews combine content from two units rather than repeating one chapter’s exercises.

---

# 4. Final transfer review

Created:
**6 final transfer tasks**

These deliberately remove unit labels.

Learners must combine:
- greeting + identity + contact;
- shopping + ordering;
- time + transport;
- repair;
- messaging;
- cross-unit reading.

---

# 5. Pilot task registry

Pilot tasks:
**50**

Breakdown:
- baseline: 8
- immediate post: 8
- delayed 24h: 8
- delayed 7d: 8
- transfer: 18

Each of the eight units has:
- baseline
- immediate
- 24h
- 7d
- transfer

Pair reviews and final review add cross-unit transfer tasks.

Output:
`ONE_A_PILOT_TASK_REGISTRY_20261006.json`

Schema:
`schemas/PILOT_TASK_ENTRY.schema.json`

---

# 6. Learner-pilot logging

Already available from Phase 2C:

- pseudonymous participant code
- L1
- task ID
- stage
- result
- error type
- transfer-risk reference
- self-correction
- prompt level
- comprehension breakdown
- completion time
- confidence
- teacher note

The pilot therefore measures more than right/wrong.

---

# 7. Unit 04 human-review packet

Unit 04 is the first human-review target.

Packet contains:
- review order
- Korean educator lane
- English pedagogy lane
- German pedagogy lane
- assessment lane
- audio/spoken lane
- decision template

Allowed decisions:
- APPROVE
- APPROVE_WITH_EDITS
- HOLD

No model process may set these human decisions automatically.

The final packet manifest is SHA-256 versioned against the reviewed files.

---

# 8. Review / answer / pilot linkage

The core chain is now:

`taskId`
→ answer-key entry
→ pilot source task
→ learner event
→ error / transfer-risk observation
→ revision decision

This is the foundation for evidence-based revision.

Example:

`1A.U04.WB.T06`
→ EN/DE transfer diagnostic
→ answer policy
→ learner pilot
→ EN-A1-COUNTERS or DE-A1-COUNTERS observation
→ keep/rewrite explanation.

---

# 9. What Phase 2D deliberately does not fake

Still open:
- real Korean educator approval;
- real EN pedagogy approval;
- real DE pedagogy approval;
- actual adult learner data;
- final page typography;
- final audio/TTS;
- Flutter route verification for print↔app links.

Those are external/human/product gates.

Their absence is explicit rather than silently treated as complete.

---

# 10. Exit criteria

Phase 2D is complete when all of the following pass:

- 190 stable task IDs
- 190/190 task answer coverage
- 16/16 closed-task exact-answer coverage
- 24 pair-review tasks
- 6 final-review tasks
- 50 pilot tasks
- human-review packet present
- schemas validate
- existing 1A package validation passes
- existing 5,961-item content regression passes

These criteria are enforced by:
`tools/textbook_project/validate_one_a_phase2d.py`

---

# Next phase

## Phase 3 — evidence from real humans

Recommended sequence:

1. human review Unit 04;
2. fix approved edits;
3. run small EN adult pilot;
4. run small DE adult pilot;
5. inspect 24h and 7d retrieval;
6. revise the 1A template;
7. propagate validated changes to all eight units;
8. only then begin 1B mass production.

This is the boundary between a sophisticated authored curriculum and a tested instructional product.
