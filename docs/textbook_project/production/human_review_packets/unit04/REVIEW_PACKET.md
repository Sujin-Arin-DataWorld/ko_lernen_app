# Unit 04 Human Review Packet
# 음식과 수량 주문하기

Status: **READY_FOR_HUMAN_REVIEW**

This packet is a frozen review entry point for the 1A reference vertical slice.

It does **not** claim human approval.

## Review order

### 1. Korean educator

Read:
- ../../../pilot_1A/unit04/STUDENT_MASTER.md
- ../../../pilot_1A/unit04/data/UNIT04_AUDIO_SCRIPT.json
- ../../../data/ONE_A_UNIT_CONTRACTS_20261006.json
- ../../../ONE_A_MODEL_EDITORIAL_AUDIT_20261006.md

Decide:
- Is the Korean natural for the exact service relationship?
- Are productive targets truly A1?
- Are staff-side forms correctly kept recognition-first?
- Does the unit teach service pragmatics without stereotypes?
- Is the pronunciation focus proportionate?

### 2. English pedagogy

Read:
- ../../../pilot_1A/unit04/STUDENT_EN.md
- ../../../pilot_1A/unit04/WORKBOOK_EN.md
- ../../../A1_LEARNER_ERROR_MATRIX_EN_DE_20261006.md

Check:
- 주세요 is not forced to one English translation.
- “Give me...” is not taught as the default.
- Counter explanation is useful without becoming a classifier lecture.
- English explanations are idiomatic and concise.
- Valid natural English alternatives are accepted in the answer key.

### 3. German pedagogy

Read:
- ../../../pilot_1A/unit04/STUDENT_DE.md
- ../../../pilot_1A/unit04/WORKBOOK_DE.md
- ../../../A1_LEARNER_ERROR_MATRIX_EN_DE_20261006.md

Check:
- 주세요 is not reduced to one German formula.
- Ich hätte gern / Einmal ..., bitte / Ich nehme are contextual alternatives.
- Counter explanation does not import German case/article logic.
- German instructions sound native and adult-appropriate.
- Valid German alternatives are accepted.

### 4. Assessment

Read:
- ../../UNIT04_ANSWER_KEY_SEED_20261006.json
- ../../ONE_A_ANSWER_KEY_REGISTRY_20261006.json
- ../../../pilot_1A/unit04/TEACHER_GUIDE.md

Check:
- closed items have deterministic answers;
- open tasks use rubrics;
- interaction success is scored by communicative accomplishment;
- recognition-only staff grammar is not required for learner production.

### 5. Audio / spoken surface

Read:
- ../../../pilot_1A/unit04/data/UNIT04_AUDIO_SCRIPT.json
- ../../../SPOKEN_DISPLAY_TTS_POLICY.md

Check:
- displaySurfaceKo and spokenSurfaceKo are correct;
- performance cues are sufficient;
- no display-only marker is read mechanically;
- intonation distinguishes question / confirmation / service tone;
- final TTS/audio remains Jin-owned.

## Required decisions

Each reviewer chooses:

- APPROVE
- APPROVE_WITH_EDITS
- HOLD

No reviewer may set another lane’s approval.

## Review packet versioning

The generated MANIFEST.json contains:
- current Git commit;
- SHA-256 hashes of the files under review;
- generation date.

If any reviewed file changes, regenerate the packet before relying on previous decisions.

## Current open gates

- Korean educator: OPEN
- English pedagogy: OPEN
- German pedagogy: OPEN
- audio/spoken: OPEN
- learner pilot: OPEN

A model/editorial pass is already complete, but it is not a substitute for these gates.

## Operational review forms

Use the lane-specific forms rather than editing this overview directly:

- `KO_REVIEW_FORM.md`
- `EN_REVIEW_FORM.md`
- `DE_REVIEW_FORM.md`
- `AUDIO_REVIEW_FORM.md`

Then enter the reviewer identity/code, date, check results, notes and final lane decision in:

`REVIEW_DECISIONS.json`

The decision record is schema-validated and tied to this packet's frozen manifest SHA-256.

## Pilot handoff after human review

When the human-review gate is ready, use:

`../../pilot_packets/unit04/FACILITATOR_GUIDE.md`

Cohort templates:
- `../../pilot_packets/unit04/EN_COHORT_TEMPLATE.json`
- `../../pilot_packets/unit04/DE_COHORT_TEMPLATE.json`

Stage sheets are intentionally separated so learners cannot preview delayed tasks:
- baseline
- immediate post
- delayed 24h
- delayed 7d
- transfer

Do not mark `HUMAN_REVIEWED_READY_FOR_PILOT` until the required review lanes have non-empty reviewer codes, dates, completed checks and no HOLD decision.
