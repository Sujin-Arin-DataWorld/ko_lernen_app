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

## Editorial repair closeout

Second-pass resolution is complete.

Final resolved counts over 5,961 source rows:
- KEEP 5,914
- REWRITE 37 (37/37 replacement materialized)
- RELEVEL 2
- REJECT 8 (8/8 replacement concepts prepared)

Confirmed level moves:
- smalltalk.c1.theme_park_date.return -> B2
- smalltalk.c2.partner_family.decisions -> C1

The urgent repair queue is closed. Next executable phase is 1A–6B allocation with explicit core/recycling/optional roles.

## Tier-1 native-usage research checkpoint — Batch 01

Completed broad-pass evidence packs for:
- family_relationships
- house_home
- food_drink

KO/EN/DE all meet:
- 3+ source contexts
- 8+ normalized patterns
- 2+ register lanes
- translationese warning
- spoken/display note

Validation:
- validate_tier1_native_usage_batch.py PASS
- textbook reuse regression PASS
- content validation PASS

Next recommended Tier-1 batch:
shopping_consumption, transport_wayfinding, health_body, work_career.

## Tier-1 native-usage research checkpoint — Batch 02

Completed broad-pass multi-genre evidence packs for:
- shopping_consumption
- transport_wayfinding
- health_body
- work_career

Research now distinguishes service/casual/blog-review/community/news/authoritative lanes instead of treating a topic as one undifferentiated native corpus.

Health uses a strict split:
- community/blog sources for natural symptom wording
- KDCA/NHS/gesund.bund authoritative sources for factual terminology and safety boundaries

Validation:
- Batch 02 native-usage validator PASS
- Batch 01 validator PASS
- textbook reuse regression PASS
- content validation PASS

A cross-language genre map was added:
research/SOURCE_GENRE_DISCOURSE_MAP_KO_EN_DE_20261006.md

Next 1A-readiness research batch:
personal_identification, communication_phone_digital, language_learning_communication_repair, social_etiquette_customs.

## Phase 2 — 1A Publishing Readiness checkpoint

Completed on 2026-10-06:

### Native usage / multi-genre research
Batch 01:
- family_relationships
- house_home
- food_drink

Batch 02:
- shopping_consumption
- transport_wayfinding
- health_body
- work_career
- source-genre discourse map added for KO/EN/DE

Batch 03 / 1A readiness:
- personal_identification
- communication_phone_digital
- language_learning_communication_repair
- social_etiquette_customs

Research lanes now explicitly distinguish:
- news/institutional
- blog/personal experience
- review
- community/Reddit
- service/casual speech

Korean source sampling includes Naver/blog/review/community materials where accessible.
English and German are independently sampled from their own news/editorial/review/community ecosystems.

### Learner transfer
A1 EN/DE learner-error matrix complete:
- 8 English-L1 priority risks
- 8 German-L1 priority risks
- evidence tiers A/B/C
- direct unit links

### Hangul onboarding
Hangul Zero contract complete:
- principle/assembly before full alphabet inventory
- real-world decoding
- selective batchim
- pronunciation awareness
- romanization sunset
- EN/DE-specific pronunciation risks

### 1A unit contracts
All 8 1A units now have machine-readable + rendered contracts:
- can-do
- communicative problem
- relationship/register
- authoritative scenarios
- productive vs recognition-only grammar
- native-usage references
- EN/DE learner risks
- input/output/interaction/assessment
- recycling links

Validation:
PASS book=1A units=8 native_topics=11 error_ids=16

### Publishing vertical slice
Pilot unit:
a1_04_order_request_object — 음식과 수량 주문하기

Created:
- STUDENT_MASTER.md
- WORKBOOK.md
- TEACHER_GUIDE.md
- PUBLISHING_QA.md
- UNIT04_AUDIO_SCRIPT.json
- UNIT04_PUBLISHING_MANIFEST.json

Audio is script-only; no TTS generated. TTS remains Jin-owned.

Pilot validation:
PASS unit04 files=6 dialogue_lines=12 selected_practice=6

### Next recommended execution
1. Run human/editorial pass on Unit 04 pilot (KO + EN + DE pedagogy).
2. Use Unit 04 findings to adjust the 1A template.
3. Materialize the remaining seven 1A units from their locked contracts.
4. Add print-layout/page-budget schema and teacher answer-key schema.
5. Start learner pilot instrumentation before mass-authoring 1B.

## 1A full materialization checkpoint — 2026-10-06

All 8 Korean 1A units now exist as learner-facing packages.

Reference vertical slice:
- Unit 04: PILOT_VERTICAL_SLICE_DRAFT

Materialized/no dedicated unit editorial pass yet:
- Unit 01
- Unit 02
- Unit 03
- Unit 05
- Unit 06
- Unit 07
- Unit 08

Package language surfaces:
- STUDENT_EN x 8
- STUDENT_DE x 8
- WORKBOOK_EN x 8
- WORKBOOK_DE x 8
- teacher guide x 8
- audio-script surface x 8

Validation:
PASS 1A_packages=8 localized_student_editions=16 localized_workbooks=16 dialogue_lines=55

Localization correction completed:
- no Korean editorial Can-do/problem prose in EN/DE student pages
- German learner-risk explanations rendered in German
- raw internal speaker IDs removed from learner-facing dialogue labels
- assessment target strings cleaned of editor shorthand
- display/spoken audio surfaces remain separated
- TTS generation remains Jin-owned and disabled here

Detailed report:
docs/textbook_project/ONE_A_MATERIALIZATION_REPORT_20261006.md

Next phase:
unit-specific editorial passes for 01/02/08/03/06/07/05, then page-budget + pilot instrumentation.

## 1A model editorial pass + time evidence closeout — 2026-10-06

Native-usage Batch 04 added:
- numbers_time_dates
- KO / EN / DE independent scheduling language
- ask → propose → confirm/correct → delay/status interaction model
- dedicated Unit 05 evidence gap is now closed

Native topic coverage referenced by 1A contracts: 12 topics.

Seven previously materialized units now have a model editorial pass:
- 01 / 02 / 03 / 05 / 06 / 07 / 08

Unit 04 remains the reference vertical slice.

Major progression decisions:
- Unit 01: Hangul Zero prerequisite; copula active work deferred to Unit 02; 감사합니다 formulaic.
- Unit 02: N에서 왔어요 lexical frame; simpler productive 어디에서 왔어요?
- Unit 03: 저기요 core; 이/가 appears in active production.
- Unit 05: dedicated numbers/time corpus; N시 어때요? formulaic proposal.
- Unit 06: reduce active spatial grammar to 에; 어디서 갈아타요? formulaic; (으)로 distributed later.
- Unit 07: explicit productive grammar / formulaic production / recognition-only three-layer model.
- Unit 08: dense confirmation phrase moved to optional recognition; repair core simplified.

Model editorial audit:
- docs/textbook_project/ONE_A_MODEL_EDITORIAL_AUDIT_20261006.md
- docs/textbook_project/data/ONE_A_MODEL_EDITORIAL_AUDIT_20261006.json

Human approval remains open:
- Korean educator
- EN pedagogy
- DE pedagogy
- adult learner pilot
- final layout/audio

Next phase:
Phase 2C — page budget, exercise density, answer-key schema, pilot logging, print/app cross-links.

## Phase 2C production architecture checkpoint — 2026-10-06

Production architecture now locked as an editorial target:

Student book:
- 144 pages
- Hangul Zero 12 pages
- 8 units x 14 pages
- pair reviews + final review + appendix

Workbook:
- 96 pages
- 8 units x 10 pages
- pair reviews
- compact answer key

Exercise-density rules:
- student closed-format max ~40%
- student productive min ~35%
- interaction/retrieval min ~25%
- workbook 24–32 micro-items/unit
- free production + delayed retrieval + L1 diagnostic required

Structured schemas added:
- schemas/ANSWER_KEY_ENTRY.schema.json
- schemas/LEARNER_PILOT_EVENT.schema.json
- schemas/PRINT_APP_CROSSLINK.schema.json

Unit 04 answer-key seed:
- 6 model-reviewed entries

Learner pilot framework:
- baseline
- guided
- immediate post
- delayed 24h
- delayed 7d
- transfer
- pseudonymous participant codes
- error type + transfer risk + self-correction + prompt level + delayed retention

Print/app crosslinks:
- 29 verified content-ID links
- all 8 units have core dialogue + listening + recycling link
- print remains offline-complete
- app route/deeplink intentionally not invented; Flutter resolver pending

Human review checklist added for:
- Korean educator
- EN pedagogy
- DE pedagogy
- audio/spoken surface
- visual/print
- assessment
- rights/provenance
- pilot readiness

Production validator:
PASS student_pages=144 workbook_pages=96 answer_entries=6 pilot_examples=2 crosslinks=29 units=8

Next:
Phase 2D — assign stable task IDs, full answer-key coverage, pair-review contracts, pilot task registry, then human Unit04 review + small EN/DE adult pilot.

## Phase 2D complete — stable tasks / full keys / reviews / pilot registry

Date: 2026-10-06
Status: PHASE_2D_COMPLETE_READY_FOR_HUMAN_REVIEW_AND_PILOT

Stable task system:
- 190 task IDs total
- 160 unit tasks
- 24 pair-review tasks
- 6 final-review tasks
- page slot is metadata; task identity survives layout changes

Answer-key system:
- 196 entries total
- all 190 stable tasks covered
- 16 closed tasks
- 16/16 closed tasks have exact answers
- Unit 04 detailed six sub-item keys retained
- open production uses rubric/sample/multiple-answer policy rather than fake single answers

Review architecture:
- R12 / R34 / R56 / R78
- 6 tasks per pair review
- EN and DE rendered review editions
- final 6-task cross-unit transfer review

Pilot registry:
- 50 tasks
- baseline 8
- immediate_post 8
- delayed_24h 8
- delayed_7d 8
- transfer 18

Unit 04 human-review packet:
- Korean educator lane
- EN pedagogy lane
- DE pedagogy lane
- assessment lane
- spoken/audio lane
- decision template
- allowed decisions: APPROVE / APPROVE_WITH_EDITS / HOLD
- final SHA-256 manifest generated after Phase 2D main commit

Key files:
- production/ONE_A_TASK_REGISTRY_20261006.json
- production/ONE_A_PAGE_TASK_MAP_20261006.csv
- production/ONE_A_ANSWER_KEY_REGISTRY_20261006.json
- production/ONE_A_REVIEW_CONTRACTS_20261006.json
- production/ONE_A_PILOT_TASK_REGISTRY_20261006.json
- production/ONE_A_PHASE2D_CLOSEOUT_20261006.md
- production/human_review_packets/unit04/

Validator:
- tools/textbook_project/validate_one_a_phase2d.py

Next phase:
Phase 3 = real human evidence.
Human review Unit04 -> EN/DE adult pilot -> 24h/7d retrieval -> template revision -> propagate to all 1A -> then 1B.

## Unit 04 human-review packet frozen — 2026-10-06

Snapshot source commit:
- 3df150a08001...

Reviewed file count:
- 13

Packet:
- production/human_review_packets/unit04/REVIEW_PACKET.md
- production/human_review_packets/unit04/REVIEW_DECISIONS.json
- production/human_review_packets/unit04/MANIFEST.json

Manifest protection:
- SHA-256 per reviewed file
- file size check
- source commit ancestry check
- validator fails if any reviewed file changes after the frozen source commit

Validator:
- tools/textbook_project/validate_unit04_human_review_packet.py

Human decisions remain OPEN.

## Phase 3A operational readiness — 2026-10-06

Status:
OPERATIONALLY_READY / REAL_HUMAN_EVIDENCE_NOT_YET_COLLECTED

Unit 04 human-review operations:
- KO review form
- EN review form
- DE review form
- audio/spoken review form
- structured decision schema
- snapshot-bound decision record
- decision validator

Current human lanes:
OPEN / OPEN / OPEN / OPEN

Pilot operations:
- EN cohort template (5 starter pseudonymous codes)
- DE cohort template (5 starter pseudonymous codes)
- separate baseline / immediate / 24h / 7d / transfer sheets for EN and DE
- shared facilitator guide
- stable pilot task IDs
- sample pilot log corrected to canonical IDs/schema
- automatic log validator + summary report

Phase 3 operational validation:
PASS review_forms=4 cohorts=2 stage_sheets=10 pilot_registry=50 sample_events=2

Important:
No human approval and no real learner result is claimed.
Next substantive evidence must come from real reviewers/learners.

Closeout:
docs/textbook_project/production/PHASE3A_OPERATIONAL_READINESS_CLOSEOUT_20261006.md
