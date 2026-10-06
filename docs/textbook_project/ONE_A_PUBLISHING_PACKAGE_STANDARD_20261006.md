# Korean 1A Publishing Package Standard — 2026-10-06

Every materialized 1A unit package must contain:

1. **STUDENT_EN.md**
   - English-first explanation for English-speaking adult learners.
   - Korean examples remain the target language.
   - EN transfer traps come from the A1 learner-error matrix.
   - No translation chain through German.

2. **STUDENT_DE.md**
   - German-first explanation for German-speaking adult learners.
   - Korean examples remain the target language.
   - DE transfer traps come from the A1 learner-error matrix.
   - No translation chain through English.

3. **WORKBOOK_EN.md / WORKBOOK_DE.md**
   - learner-facing instructions are independently localized for EN and DE.
   - recognition → controlled production → interaction → delayed retrieval.
   - app practice bank may be reused selectively, never dumped wholesale.
   - an internal WORKBOOK.md master may coexist, but it is not the learner-facing edition.

4. **TEACHER_GUIDE.md**
   - can-do and production ceiling.
   - productive vs recognition-only grammar.
   - anticipated EN/DE learner risks.
   - pragmatics/culture cautions.
   - assessment rubric and recycling.

5. **data/UNIT_MANIFEST.json**
   - unit contract reference.
   - authoritative/supplementary sources.
   - native-usage topics.
   - selected language targets.
   - materialization status.

6. **data/AUDIO_SCRIPT.json**
   - displaySurfaceKo.
   - spokenSurfaceKo.
   - performanceCue.
   - EN/DE meaning surfaces.
   - no generated audio.
   - TTS owner remains Jin.

## Required pedagogical order

1. scene/input
2. meaning task
3. useful chunk noticing
4. minimal form explanation
5. native-use variation
6. EN/DE transfer-aware note
7. pronunciation/sound
8. reading/writing
9. interaction
10. retrieval assessment
11. recycling pointer

## Hard rules

- Dialogue occurrence does not automatically become productive grammar.
- A1 explanations are written in learner L1, not advanced Korean.
- Romanization is absent after Hangul Zero except exceptional teacher-side note.
- Trend/slang is recognition-first and dated.
- Service/staff-side morphology may remain comprehension-only.
- Culture claims must describe choices/context rather than "Koreans always...".
- Community evidence supports usage/register, not medical/legal factual authority.
- Unit packages remain DRAFT_MATERIALIZED until dedicated editorial pass.
