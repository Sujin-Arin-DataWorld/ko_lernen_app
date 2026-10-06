# Korean 1A Materialization Report — 2026-10-06

## Result

All eight Korean 1A unit contracts now have learner-facing publishing packages.

### Reference vertical slice

**Unit 04 — 음식과 수량 주문하기**

Status:
`PILOT_VERTICAL_SLICE_DRAFT`

This remains the deepest reference package and includes:
- STUDENT_MASTER.md
- STUDENT_EN.md
- STUDENT_DE.md
- WORKBOOK.md
- WORKBOOK_EN.md
- WORKBOOK_DE.md
- TEACHER_GUIDE.md
- PUBLISHING_QA.md
- MODEL_EDITORIAL_AUDIT_20261006.md
- audio script + publishing manifest

### Model-editorial-pass units

- Unit 01 — 첫 인사와 다시 묻기
- Unit 02 — 이름과 출신 말하기
- Unit 03 — 가게에서 물건 찾기
- Unit 05 — 시간 확인하기
- Unit 06 — 교통에서 내릴 곳 말하기
- Unit 07 — 자연스럽게 연락 방법 정하기
- Unit 08 — 못 들었을 때 다시 묻기

Each has:
- STUDENT_EN.md
- STUDENT_DE.md
- WORKBOOK.md (internal master)
- WORKBOOK_EN.md
- WORKBOOK_DE.md
- TEACHER_GUIDE.md
- data/UNIT_MANIFEST.json
- data/AUDIO_SCRIPT.json

Status for these seven:
`MODEL_EDITORIAL_PASS_COMPLETE_HUMAN_REVIEW_OPEN`

Model/editorial decisions are documented in:
- `ONE_A_MODEL_EDITORIAL_AUDIT_20261006.md`
- `data/ONE_A_MODEL_EDITORIAL_AUDIT_20261006.json`

## Localization architecture

Learner-facing metadata is no longer generated from Korean editorial prose.

A dedicated source now supplies:
- EN can-do
- DE can-do
- EN/DE communicative-problem explanation
- EN/DE pragmatics
- EN/DE culture note
- EN/DE input/output tasks
- EN/DE interaction task
- EN/DE success criterion
- EN/DE production ceiling

Source:
`docs/textbook_project/data/ONE_A_LEARNER_FACING_META_EN_DE_20261006.json`

German transfer-risk notes are also rendered in German rather than leaking English editorial labels.

## Assessment cleanup

Unit-contract assessment fields were normalized so learner-facing fields contain actual Korean target forms rather than editorial shorthand.

Examples:
- `13번이요?` instead of “echo confirmation”
- `뭐라고요?` instead of “tone risk”
- `주문하시겠어요?` instead of “staff 주문하시겠어요?”
- `카카오톡으로 연락할까요?` instead of “or equivalent safe chunk”

Editorial nuance remains in teacher/contract metadata rather than in the learner target string.

## Package validation

Current full-package regression:

- 1A packages: **8**
- localized student editions: **16**
- localized workbooks: **16**
- core dialogue lines checked: **55**
- display/spoken audio surfaces present: PASS
- TTS owner remains Jin: PASS
- audio generation disabled: PASS
- raw Korean editorial meta leaking into EN/DE student pages: none detected
- raw internal speaker IDs leaking into student pages: none detected

Validator:
`tools/textbook_project/validate_one_a_materialized_packages.py`

## Important quality boundary

Materialized does **not** mean publication-ready.

All eight units now have a model/editorial pass.

This does **not** replace:
1. human Korean educator review;
2. native EN pedagogy review;
3. native DE pedagogy review;
4. unit-specific practice-bank selection;
5. adult learner pilot;
6. page design and final audio review.

Unit 04 remains the deepest vertical-slice reference.

## Next recommended phase

### Phase 2C — production architecture + pilot instrumentation

Lock:
- page budget per unit;
- exercise density per skill;
- answer-key schema;
- learner-pilot logging;
- print/app cross-links;
- human-review checklist.

After those system constraints are fixed, refine all eight 1A units without allowing page count, exercise count or review evidence to drift.
