# Listening lesson catalog: content contract and QA

## Scope and source authority

`assets/data/listening_lessons.json` contains all 178 canonical scenarios as
individual lessons, with 712 questions. Counts by level are A1 29, A2 28, B1 31,
B2 30, C1 30, C2 30. Every lesson contains situation, meaning, sentence and
response practice in that order. Its topic ID is the scenario shelf, and both
content IDs and question source IDs are scenario IDs.

The canonical inputs are `assets/data/scenarios_a1.json` through
`scenarios_c2.json` at source checkout `63937f12f0bfd7d3f735fa4834edcb0365592ac8`.
Those six files were not edited. Titles, introductions and source utterances
retain their canonical KO/DE/EN text. New instructions and contrastive choices
are model-authored directly against the Korean scene. No external corpus was
copied; no current slang or native-speaker approval is asserted.

## Scene and task lock

Mode: AUTHOR+AUDIT using beyond-humanizer. Source scene, participants, speech
style, purpose, factual commitments and information source remain authoritative.
No audience is inferred solely from a relationship label. Hypothetical follow-up
speakers in advanced response tasks are explicitly hypothetical, not new source
dialogue. Wrong alternatives are intentional counterfactual choices, not claims
about what the source speaker said.

| Skill | Task and uniqueness boundary |
| --- | --- |
| Situation, A1–B1 | Recognize the source scene; two authored alternatives alter an object, cause, purpose or sequence within the same scene. |
| Situation, B2–C2 | 90 authored inferences distinguish intent, concession, condition, evidence, responsibility or implication. Options do not merely name unrelated topics. |
| Meaning | Interpret one exact source utterance. Other options come from different turns within the same conversation, with distinct content or speech acts. |
| Sentence | Reconstruct the exact recorded word order, not an unrestricted paraphrase. Targets contain 2–18 space-delimited units. |
| Response, A1–B1 | 88 application tasks specify a communicative goal and actual interlocutor cue. The correct utterance is canonical; both authored alternatives violate the requested goal, fact or condition. A different preference is not declared universally unnatural. |
| Response, B2–C2 | 90 hypothetical follow-up tasks ask learners to correct an explicitly mistaken summary while preserving the dialogue's conditions and intentions. The correct corrective proposition is authored from the Korean scene; source evidence remains an exact canonical quotation. False alternatives distort the same distinction. This is application, not next-turn recall. |

Correct choices are unique within each displayed set. Each choice has all three
locales. Answer index 0 is the authoring convention; the player can shuffle while
preserving answer identity. Explanations quote exact Korean evidence and retain
its canonical DE/EN interpretation. They explain the task boundary and contrasts,
without claiming that every alternative is ungrammatical or impossible elsewhere.

All `audioKo`, `evidenceKo` and `targetKo` values are **complete exact dialogue
utterances**. Advanced hypothetical follow-ups have no generated audio field.
They require no new recordings. Two lower-level responses continue their own
speaker's turn; their cues explicitly select the earlier interlocutor utterance
(`introduce_yourself`, `secondhand_hidden_defect`) rather than calling a speaker's
own words the other person's cue.

## Legacy quest issues avoided

Nine legacy listening/order quests use a substring or paraphrase rather than an
exact dialogue turn. The new catalog uses the complete canonical turn instead:

- `a2_theme_park_date_break`: meaning.
- `a2_w10_apt`: sentence (`궁금한 게`, not legacy `모르는 게`).
- `b1_theme_park_date_thrill`: meaning and sentence.
- `b1_w10_repair`: sentence (request to book, not legacy statement of booking).
- `b2_theme_park_date_safety`: sentence (original causal ending retained).
- `c1_theme_park_date_next_time`: meaning and sentence.
- `c2_theme_park_date_reflection`: sentence.

The one-word legacy order targets for `taxi_kakao` and
`convenience_parcel_pickup` would not provide a meaningful ordering task; they
were replaced with multiword requests from the same source dialogues.

## Reproduction and validation

```powershell
python tool/author_listening_lessons.py
python tool/validate_listening_lessons.py
```

The validator passed with 178 lessons, 712 stable unique question IDs, exact
once-only coverage of all source scenarios and 178 questions for each skill.
It checks the version/schema, nonempty locale triplets, choice distinctness,
valid answer indices, source links, shelf/level/title/intro alignment, NFC,
replacement/control characters, duplicate JSON keys, exact dialogue grounding,
multiword order targets, response-speaker direction and absence of the retired
chronological-recall task. Regenerating produces an identical catalog.

The catalog at this check is 2,025,936 bytes, SHA-256
`d300e61c183b4dc6dfb9f76db7518cb131c0a739c1fb7a47d752b902cb1965c8`.
Scoped whitespace validation passed. No canonical scenario files changed.

## Independent model-review repairs

All **90** stable `listening.b2.*.response`, `listening.c1.*.response` and
`listening.c2.*.response` IDs were repaired after a separate model review found
that transplanting a source utterance could affirm a hypothetical false summary
or fail to address it. Correct answers now directly state the corrective
proposition; agreement prefixes such as `네`, `맞습니다`, `Yes`, `That's right`,
`Ja` and `Das stimmt` are not transplanted into the new interaction. No authored
follow-up was labeled as source audio. The source itself was not rewritten.

Source evidence was also strengthened for `filming_permission` (restricted
location and duration), `library_quiet_zone_conflict` (moving immediately),
`recycling_policy_pilot` (resident usability concerns) and `c2_w10_record`
(indirect evidence can reconstruct the record). `ai_image_disclosure` and
`c1_w10_clinical` now correct the misconception without carrying the source's
context-dependent affirmative opening into the answer.

Seven meaning items excluded alternative source turns with equivalent or
overlapping meanings; textual distinctness was insufficient to guarantee a
unique answer:

- `listening.a1.clarify_repeat.meaning`: spoken/written 13 and repeated confirmation.
- `listening.a1.subway_step_apology.meaning`: equivalent reassurance variants.
- `listening.a1.meeting_time.meaning`: repeated confirmation of seven o'clock.
- `listening.a1.a1_w10_repeat.meaning`: equivalent dosage instructions.
- `listening.a1.introduce_yourself.meaning`: repeated identification as Sujin.
- `listening.c1.c1_w10_uncertainty.meaning`: overlapping recommendations to give a range.
- `listening.c1.tradition_reinterpreted_stage.meaning`: overlapping recommendation to distinguish reinterpretation from tradition.

Validation again passed after these repairs. The response-prefix regression
guard recognizes acknowledgement punctuation; it does not reject substantive
phrases such as “Good intentions”.

Two further independent review findings were repaired:

- `listening.b2.b2_w10_hiring.situation` and `.response`: German `Dissertation`
  was changed to `Abschlussarbeit`, matching the source without inventing a
  doctorate. Related explanations were regenerated.
- `listening.a2.pharmacy_cold_medicine.response`: the negative confirmation
  question about evening use could still accomplish the requested permission
  check. Its replacement asks about treatment duration, which clearly differs
  from the specified evening-use task.

The independent model reviewer checked all 90 advanced KO/DE/EN contrast sets
and the seven revised meaning sets. This is separate model review, not human or
native-speaker approval.

## Review status and limits

Structural status: **PASS**. Model authoring and a source-grounded self-audit were
completed across all 178 scenes. The Korean dialogue for all levels was read,
and the additional KO/DE/EN option sets were checked for their intended contrast.
The catalog is complete, not a sampled or placeholder corpus.

This is model QA, not independent native-speaker or educator approval. Automated
checks cannot establish CEFR calibration, all pragmatic ambiguities, or native
naturalness. Source DE/EN dialogue translations are reused, so any pre-existing
source translation problem remains a separate canonical-source issue. The
response transfer tasks deliberately have explicit goals; they do not measure
unrestricted spontaneous speaking. Advanced situation and follow-up correction
tasks reinforce the same critical distinction and are not independent measures
of mastery. The root integration task owns independent review, runtime loading,
rendered phone/tablet checks and any follow-up fixes.
