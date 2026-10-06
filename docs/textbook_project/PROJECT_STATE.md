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
