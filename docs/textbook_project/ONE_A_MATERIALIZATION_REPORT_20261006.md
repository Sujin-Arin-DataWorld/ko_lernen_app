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

### Materialized draft units

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
`DRAFT_MATERIALIZED_NO_UNIT_EDITORIAL_PASS`

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

Unit 04 has a model/editorial pass.

Units 01/02/03/05/06/07/08 still require:
1. unit-specific Korean editorial review;
2. EN pedagogy review;
3. DE pedagogy review;
4. practice-bank selection beyond the generic workbook scaffold;
5. adult learner pilot;
6. page design and final audio review.

## Next recommended phase

### Phase 2B — editorialize the seven materialized units

Priority order:
1. Unit 01 — because it establishes first-contact register and repair norms.
2. Unit 02 — because topic/subject and identity explanation sets the grammatical voice of the book.
3. Unit 08 — because repair strategy is a core learner-autonomy feature.
4. Unit 03 — because 은/는 vs 이/가 and location particles are high-transfer-risk.
5. Unit 06 — because EN/DE spatial transfer risks are strong.
6. Unit 07 — because contact exchange and boundaries require pragmatic care.
7. Unit 05 — because number-system design depends on page/visual treatment.

After those editorial passes, lock:
- page budget;
- exercise density;
- answer-key schema;
- learner-pilot logging;
- print/app cross-links.
