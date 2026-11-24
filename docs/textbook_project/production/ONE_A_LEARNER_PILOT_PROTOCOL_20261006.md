# Korean 1A Adult Learner Pilot Protocol — 2026-10-06

Status: DRAFT RESEARCH / QA PROTOCOL

Purpose:
validate whether the 1A explanations and tasks actually help adult EN- and DE-speaking learners **understand, retrieve, produce, interact and retain** Korean.

This is not a clinical or academic-study protocol. It is a product/editorial pilot framework.

## Core principle

Do not collect only:
> right / wrong

Also collect:
- what kind of error occurred;
- whether the learner self-corrected;
- how much prompting was needed;
- whether the learner maintained the interaction;
- whether the same target survives delayed retrieval;
- whether an EN/DE transfer trap actually appears.

## Cohorts

Pilot EN and DE independently.

Recommended first pass:
- 5–8 English-L1 adults
- 5–8 German-L1 adults

The goal is **problem discovery**, not population-level statistical claims.

Do not present small-pilot percentages as universal learner facts.

## Participant coding

Use pseudonymous codes only.

Example:
- EN01
- EN02
- DE01
- DE02

The event log must not require:
- full name;
- email;
- home address;
- account ID.

If audio/video is recorded, manage consent and retention separately. Do not place raw media inside the event log.

## Pilot stages

### 1. Baseline

Before teaching the target:
- one recognition item;
- one simple production attempt where feasible.

Purpose:
identify prior knowledge and avoid crediting the lesson for language already known.

### 2. Guided learning

Observe:
- confusion point;
- question asked;
- first successful use;
- transfer error;
- whether explanation resolves the error.

### 3. Immediate post-task

Without copying:
- produce target chunk;
- solve interaction task;
- complete one transfer item.

### 4. Delayed 24h retrieval

Minimal support.

Ask the learner to:
- recall one or two core chunks;
- solve the same function with changed content.

### 5. Delayed 7d retrieval

Use a new context.

Do not simply repeat the identical sentence.

### 6. Transfer task

Move the language into another unit or scene.

Example:
Unit 04 주세요
→ later café / shop / request context.

## Prompt levels

0 — no help  
1 — meaning/context cue  
2 — first word / visual / choice cue  
3 — model shown or repeated

A response that only succeeds at prompt level 3 is not independent retrieval.

## Error taxonomy

- form
- meaning
- particle
- word_order
- pronunciation
- register
- pragmatics
- vocabulary
- listening_segmentation
- number
- repair_failure
- other

For EN/DE-specific risks, also store:
`transferRiskRef`

Examples:
- EN-A1-PARTICLES-OMIT-REPLACE
- DE-A1-DU-SIE

## Interaction success

For interactive tasks, log whether the learner:

1. understood the partner’s goal;
2. produced a relevant turn;
3. repaired a misunderstanding if needed;
4. continued the interaction.

A grammatically imperfect response may still be communicatively successful.

## Unit 04 pilot example

### Baseline

Show menu.

Prompt:
order one coffee.

Observe:
- Does learner use 주세요?
- Does learner use a counter?
- Does learner translate from EN/DE?

### Immediate post

New menu.

Require:
- item
- quantity
- one condition

### 24h

No explanation.

Prompt:
“You want one tteokbokki, mild.”

### 7d transfer

Different café/shop context.

Prompt:
order a drink to go.

## Decision rules after pilot

### KEEP explanation
Use when:
- most learners understand the explanation;
- transfer errors reduce after feedback;
- delayed retrieval is reasonable.

### REWRITE explanation
Use when:
- learners repeatedly misunderstand the same explanation;
- EN/DE note creates a new misconception;
- the rule is technically correct but pedagogically unusable.

### REORDER
Use when:
- learners need a prerequisite not yet introduced.

### MOVE_TO_RECOGNITION
Use when:
- production creates excessive load but comprehension is useful.

### PROMOTE_FORMULAIC
Use when:
- learners successfully use a high-value chunk without needing the full grammar system.

## Pilot review packet per unit

After a cohort, produce:

- participant count by L1;
- task completion summary;
- top 5 error types;
- transfer-risk observations;
- self-correction rate;
- prompt-level distribution;
- immediate vs delayed performance;
- qualitative confusion notes;
- recommended content changes;
- decision: KEEP / REWRITE / REORDER / SCOPE_CHANGE.

## Privacy / minimization rule

Store only what is needed to improve the learning material.

Do not embed:
- names;
- contact details;
- unrelated personal background;
- raw recordings

in the structured event log.

Machine event schema:
`schemas/LEARNER_PILOT_EVENT.schema.json`
